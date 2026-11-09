# Security review (milestone 6, 2026-10-22)

Scope: everything in this repository as of milestone 6, checked against
section 13 of the product brief. "Test" names the automated test that
covers the item; "Device" means verified on an emulator or phone.

## Findings fixed in this review

| # | Finding | Fix | Test |
|---|---|---|---|
| 1 | ZIP entries were decompressed fully into memory before the real size was checked. | Decompress straight to disk through `LimitedFileOutput`, which stops at the per-file / total limit. (archive 4.5.2 also refuses data larger than a forged header claims; this is defence in depth.) | `core_test` ZIP bomb (40 MB, forged to 1000 B), `limited_output_test` |
| 2 | The in-app preview WebView kept Android's default `file://`/`content://` access on Android ≤ 10, while previewing untrusted pages inside the app that holds release keystores. | `setAllowFileAccess(false)`, `setAllowContentAccess(false)` on the preview controller. | Device: `preview_security_test` on API 24, 29, 36 emulators (XHR, iframe and navigation to `file://`/`content://` all refused; WebView's origin rules already refuse most of this, so the flags are defence in depth) |
| 3 | `project.json` could list any permission (e.g. `SEND_SMS`); an imported or edited project would pass it straight into the generated manifest. | Allowlist (`supportedPermissions`): INTERNET, ACCESS_NETWORK_STATE, VIBRATE. Checked by `validateManifest`, which every build path runs. | `appearance_test` permissions |

## Checklist

| Requirement | Status | Where |
|---|---|---|
| ZIP path traversal | Done: `..`, absolute, drive letters, control chars, Windows device names, trailing dots rejected; resolved paths must stay in the destination; symlink entries rejected | `path_safety.dart`, `core_test` |
| Archive extraction limits | Done: 10 000 files, 100 MB per file, 500 MB total (real bytes), compression ratio, case-insensitive duplicates | `zip_importer.dart` |
| Loose-file import | Done: names normalized, duplicates rejected, references outside the site never followed | `files_importer.dart`, `files_import_test` |
| URL scheme validation | Done: https only, no credentials, no localhost/.local, private/loopback/link-local/CGNAT IPs | `url_policy.dart` |
| Redirect validation | Done: redirects followed manually, every hop re-validated, max 5, 10 s timeout | `url_probe.dart` |
| Private-network protection | Done for literal IPs and DNS results at check time. Known gap: DNS rebinding between check and use (documented in `UrlProbe`); generated apps grant remote pages no native access either way | `url_probe_test` |
| Secure WebView defaults (generated apps) | Done: no file/content access, assets via `WebViewAssetLoader` https origin, mixed content blocked, cleartext off, no addJavascriptInterface, no multiple windows, debugging only in debuggable builds, Safe Browsing on (default), geolocation/camera prompts denied (no handlers) | `MainActivity.kt` |
| External links | Done: only same site (+www) and listed hosts stay in-app; others go to the browser with `CATEGORY_BROWSABLE`, and only for http(s)/mailto/tel/sms/geo; `file:`, `intent:`, `javascript:` dropped | `MainActivity.kt`, Device |
| Explicit permissions | Done: INTERNET only when needed; allowlist above; no runtime-dangerous permissions | `android_generator.dart` |
| Native bridge restrictions | Done: one WebMessageListener (`html2apkBridge`) limited to the app's own origins (bundled assets, start host ± www, listed hosts). It only shares text through the system chooser (user gesture required, max one per second, 100 000 chars) returns blob:/data: bytes for downloads the runtime asked for (request ids, 20 MB), and (`shareFiles`) sends image/PDF files: only `image/*` and `application/pdf`, 1–10 files, 20 MB decoded in total, names sanitized and de-duplicated, one share per second, checked again natively in `ShareRules.kt`. Shared files go to MediaStore (`Pictures/<folder>`, `Download/<folder>`; no permission). No FileProvider since Android 10 became the minimum (ADR 0010). `shareTarget` must be a package name; it is only used with `setPackage`. Downloads: https only via DownloadManager, saved to Downloads; file names sanitized. File uploads use the system picker (user chooses each file) | `PageBridge.kt`, `ShareRules.kt` |
| Signing-secret protection | Done: keystore passwords AES-GCM under a non-exportable Android Keystore key; app-private files; `allowBackup=false`; never in `project.json`, logs or exports; Windows passes them via environment variables; passwords zeroed after use on the Kotlin side | ADR 0004, `signing_test`, Device |
| Build log redaction | Done: password/secret/token/`--ks-pass` patterns | `log_redaction.dart` |
| Build process isolation | Windows: Gradle runs as a child process on a generated project (no user code compiles: the website is assets only). Phone: no compiler or external processes at all | ADR 0002 |
| Imported scripts never run in the converter | Done: website JS runs only in WebViews (preview, generated app), never in Dart/Kotlin | — |
| Temp cleanup | Done: picker copies and engine work dirs deleted in `finally` blocks | `projects_screen.dart`, `EngineChannel.kt` |
| Sensitive confirmations | Done: key delete needs the alias typed; different-key releases need confirmation; installs go through the system installer; project delete confirms | UI |
| Preview server | Done: loopback only, random port, 128-bit path token, read-only GET/HEAD, path-safe, `nosniff`, `no-store`; iLoveHTML allows cleartext only to 127.0.0.1 | `preview_server_test` |
| FileProvider | Done: not exported; grants are per-URI and per-intent; paths limited to `workspace/projects/` | `file_paths.xml` |
| Parsers of untrusted bytes | JKS, DER, protobuf readers are bounds-checked and covered by malformed-input tests | engine JVM tests |

## Review of 2026-11-10

Scope: the code added since milestone 6 (MSIX installers, iLoveHTML's app
lock, the update check and in-app update, QR install, app lock and
notifications in generated apps) and a second read of both wrappers.
Findings come from reading the code; "Test" names what now covers the fix.

### Fixed

| # | Finding | Fix | Test |
|---|---|---|---|
| 1 | `signtool` got the `.pfx` password on its command line, which process-creation logs record (ADR 0008 had accepted this for live processes of the same user). | Signing goes through PowerShell: certificate imported into `CurrentUser\My` for the length of the signing (password through the environment), `signtool /sha1`, then removed. | `msix_builder_test`: no password in the arguments; a real signed build leaves nothing in the store |
| 2 | Windows apps ignored the project's Downloads, File uploads and Local storage switches; any file type could be downloaded. | `exeConfig` passes the switches. Downloads: cancelled in `DownloadStarting` when off, and only https/`blob:`/`data:` when on. Uploads off: the file picker is intercepted (`Page.setInterceptFileChooserDialog`). Local storage off: `localStorage`/`sessionStorage` are `null`, set before the first page loads. | `exe_builder_test`: config lines; a real .exe blocks a download and shows `null` storage. The upload switch has no automated test (a file picker needs a real click). |
| 3 | Every host in "Other sites that open inside the app" also got the native bridge (share, saving files, notifications). A login or payment site listed there could save files to the gallery or post notifications as the app. | New `webView.bridgeHosts` (a subset of `allowedHosts`, checked by `validateManifest` and again in `AppConfig`). New projects: empty. Projects saved earlier keep their behaviour and show the hosts in the new field. TV navigation still runs on every in-app site. | `bridge_hosts_test`, `AppOriginsTest` |
| 4 | The update file's name came from the URL's last segment, percent-decoded, so `..%5Cx.apk` named a file outside the updates folder. Reachable only through GitHub's answer or saved preferences. | Names must match `[A-Za-z0-9][A-Za-z0-9._-]*`. | `update_check_test` |
| 5 | Generated apps had no `onRenderProcessGone`: a page that crashes or runs out of memory killed the app. | The activity starts over with a new WebView on the start page; a second crash within 10 s closes the app instead of looping. | Device: Android 10 emulator, renderer killed with `kill -9` (app survives and reloads; a second kill 2 s later closes it) |
| 6 | With app lock on, Android 10–12 showed the page in the recent-apps screen (`setRecentsScreenshotEnabled` is API 33+). | `FLAG_SECURE` below API 33 (this also stops screenshots there). | Device: Android 10 emulator, `dumpsys window` shows `SECURE` on the app's window |
| 7 | `allowBackup="false"` alone: on Android 12+ some device-to-device transfers still copy app data. | `dataExtractionRules` excluding everything, in iLoveHTML and every generated app. | Both build with it; `tools/e2e_windows.ps1` passes on the Android 10 emulator. The transfer itself was not tried. |
| 8 | The FileProvider's paths cover whole project folders, not only built files. | `EngineChannel.uriFor` refuses anything outside `<project>/exports/` and `workspace/updates/`. | Not run on a device yet |
| 9 | No CI, no dependency updates, no way to report a problem privately. | `.github/workflows/ci.yml` (tests, analysis, Gradle wrapper validation), `.github/dependabot.yml`, `SECURITY.md`. | Runs on the first push |

### Open

| Finding | Why it is open | Planned fix |
|---|---|---|
| Updates are checked against `SHA256SUMS.txt` from the same release, which proves the download is intact, not who published it. Android still refuses an APK signed with another key; the Windows ZIP has no such check. | Needs a signing key kept outside GitHub and a release-process change. | Sign `SHA256SUMS.txt` (Ed25519), embed the public key, verify before installing. |
| iLoveHTML's app lock hides the app but does not protect release keys: the PIN hash is in SharedPreferences (a plain file on Windows), a 4-digit PIN can be tried offline, and the retry wait trusts the clock. | Changes how keys are stored (ADR 0004 lists it as future work). | Android: Keystore key that requires user authentication. Windows: wrap the DPAPI blob with a key derived from the PIN. |
| QR install is plain HTTP: someone who can intercept the Wi-Fi can swap the APK. | Phones cannot verify a download from a browser. | Show the APK's SHA-256 and signer next to the QR; stop serving after one download. |
| The Windows wrapper checks hosts with `InternetCrackUrlW` while the page runs in Chromium. No bypass was found (WebView2 hands over normalized URLs). | Hardening, not a known hole. | Parse with `CreateUri`. |

## Known limitations (accepted for now)

- DNS rebinding after the URL check (see above).
- Files a user deliberately puts in a website are shipped as-is; iLoveHTML
  does not scan site JavaScript for malware.
- Play Protect may still warn on sideloaded debug/release builds; that is
  Google's check, outside iLoveHTML.
- Release keys can be used without re-entering a PIN/biometric once
  imported; optional unlock is listed as future work in ADR 0004.
