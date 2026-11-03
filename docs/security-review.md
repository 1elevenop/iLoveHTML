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
| Native bridge restrictions | Done: one WebMessageListener (`html2apkBridge`) limited to the app's own origins (bundled assets, start host ± www, listed hosts). It only shares text through the system chooser (user gesture required, max one per second, 100 000 chars) returns blob:/data: bytes for downloads the runtime asked for (request ids, 20 MB), and (`shareFiles`) sends image/PDF files: only `image/*` and `application/pdf`, 1–10 files, 20 MB decoded in total, names sanitized and de-duplicated, one share per second, checked again natively in `ShareRules.kt`. Shared files go to MediaStore (`Pictures/<folder>`, `Download/<folder>`; Android 10+, no permission) or to `cacheDir/shared` behind a non-exported FileProvider (`<appId>.html2apk.files`, cache-path only, read grant per share; Android 7–9). `shareTarget` must be a package name; it is only used with `setPackage`. Downloads: https only via DownloadManager, saved to Downloads; file names sanitized. File uploads use the system picker (user chooses each file) | `PageBridge.kt`, `ShareRules.kt` |
| Signing-secret protection | Done: keystore passwords AES-GCM under a non-exportable Android Keystore key; app-private files; `allowBackup=false`; never in `project.json`, logs or exports; Windows passes them via environment variables; passwords zeroed after use on the Kotlin side | ADR 0004, `signing_test`, Device |
| Build log redaction | Done: password/secret/token/`--ks-pass` patterns | `log_redaction.dart` |
| Build process isolation | Windows: Gradle runs as a child process on a generated project (no user code compiles: the website is assets only). Phone: no compiler or external processes at all | ADR 0002 |
| Imported scripts never run in the converter | Done: website JS runs only in WebViews (preview, generated app), never in Dart/Kotlin | — |
| Temp cleanup | Done: picker copies and engine work dirs deleted in `finally` blocks | `projects_screen.dart`, `EngineChannel.kt` |
| Sensitive confirmations | Done: key delete needs the alias typed; different-key releases need confirmation; installs go through the system installer; project delete confirms | UI |
| Preview server | Done: loopback only, random port, 128-bit path token, read-only GET/HEAD, path-safe, `nosniff`, `no-store`; iLoveHTML allows cleartext only to 127.0.0.1 | `preview_server_test` |
| FileProvider | Done: not exported; grants are per-URI and per-intent; paths limited to `workspace/projects/` | `file_paths.xml` |
| Parsers of untrusted bytes | JKS, DER, protobuf readers are bounds-checked and covered by malformed-input tests | engine JVM tests |

## Known limitations (accepted for now)

- DNS rebinding after the URL check (see above).
- Files a user deliberately puts in a website are shipped as-is; iLoveHTML
  does not scan site JavaScript for malware.
- Play Protect may still warn on sideloaded debug/release builds; that is
  Google's check, outside iLoveHTML.
- Release keys can be used without re-entering a PIN/biometric once
  imported; optional unlock is listed as future work in ADR 0004.
