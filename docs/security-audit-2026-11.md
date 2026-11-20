# Security audit (2026-11, release 1.2.5)

A 20-item checklist run over the whole repository before release 1.2.5. Each item
is **Fixed** (changed in this audit), **Already OK** (checked, nothing to change)
or **N/A** (the app has no such surface), with the files that show it.

iLoveHTML is a local tool: it has no backend, no database, no user accounts and no
cloud API. Its only network listeners are two short-lived local HTTP servers (the
preview server on loopback and the LAN share server for QR installs), so several
web-service items do not apply.

| # | Item | Status | Details |
|---|---|---|---|
| 1 | No secrets in source code | Already OK | No API keys, tokens or passwords in tracked files. Signing passwords live in Android Keystore (`app/android/.../EngineChannel.kt`, ADR 0004) or DPAPI (`app/lib/src/engine/dpapi.dart`), never in `project.json`. Test files use throwaway passwords only. |
| 2 | `.env` and key files ignored by Git | Fixed | `.gitignore` already covered `*.jks`, `*.keystore`, `*.p12`, `*.pfx`, `key.properties`; added `.env`, `.env.*`, `*.env`. |
| 3 | No secrets in Git history | Already OK | Full-history pattern scan (`git log --all -p`, AWS/Google/GitHub/Slack/OpenAI key patterns, private-key blocks, password assignments) over all 91 commits: only test fixtures (`'hunter2-secret'`, `'win-ui-pw-1'`) and localized UI labels ("Keystore password"). No key or `.env` file was ever committed. CI now runs gitleaks over the full history on every push (item 20); `.gitleaks.toml` allow-lists test code and localizations. |
| 4 | Input validation | Already OK | ZIP/HTML import: path normalization, traversal, symlinks, size/count/ratio limits (`packages/html2apk_core/lib/src/security/path_safety.dart`, `zip_importer.dart`). URLs: https only, no credentials, private networks blocked, redirects re-checked (`security/url_policy.dart`, `url_probe.dart`). Manifest fields and permissions validated by `validateManifest`. |
| 5 | SQL / NoSQL injection | N/A | No database. Projects are plain JSON files (`project_core/project_store.dart`). |
| 6 | Authentication and sessions | N/A | No server accounts or sessions. The optional local app lock is item 7. |
| 7 | Password hashing | Already OK | App-lock PIN/password stored only as salted PBKDF2-SHA256, 120 000 iterations (`app/lib/src/app_lock.dart:97-112`), with lock-out after failed tries. |
| 8 | Authorization / admin routes | N/A | No server-side routes or roles. The two local servers serve one secret path each (128-bit random token) and nothing else. |
| 9 | CORS | N/A | Neither local server sends `Access-Control-Allow-*`, so browsers keep the same-origin default. The LAN server now also sends `Cross-Origin-Resource-Policy: same-origin`. |
| 10 | Rate limiting | Fixed | LAN share server: per-client token bucket (10 requests/minute, then `429` with `Retry-After`) and a total cap of 20 downloads (then `410`) (`build_orchestrator/lan_share_server.dart`, tests in `test/lan_share_server_test.dart`). The preview server is loopback-only. |
| 11 | Security headers | Fixed | LAN share server: `Content-Security-Policy: default-src 'none'`, `Referrer-Policy: no-referrer`, `X-Frame-Options: DENY`, `Cross-Origin-Resource-Policy: same-origin`, plus the existing `nosniff` and `no-store`. Preview server: added `Referrer-Policy: no-referrer` (a CSP there would break the user's own site, which it exists to show). |
| 12 | Network exposure / transport | Fixed | LAN share server now serves only clients in the bound interface's own /24 (before: any RFC 1918 address) (`sameSubnet24`). It is still plain HTTP by design (a phone cannot trust a local certificate); the UI says to use it only on a trusted network and it stops after 10 minutes. Generated apps block cleartext and mixed content (README "Security defaults of generated apps"). |
| 13 | File upload / import handling | Already OK | See item 4; imported site scripts never run in the converter, only inside WebViews (`docs/security-review.md`). |
| 14 | XSS | Already OK | Flutter UI renders text, not HTML. Generated apps load only the user's own site; the native bridge is limited to the app's own origins (`PageBridge.kt`, `ShareRules.kt`). |
| 15 | CSRF | N/A | No state-changing HTTP endpoints: both servers answer only `GET`/`HEAD` (everything else is 404). |
| 16 | Dependency vulnerabilities | Fixed | Took all compatible upgrades (`dart pub upgrade` in core: archive 4.7.1, image 4.13.1, coverage 1.16.1; `flutter pub upgrade` in app). Pinned `intl` from `any` to `^0.20.3`, the version `flutter_localizations` requires. CI now runs osv-scanner on every `pubspec.lock` (item 20). Gradle has no lockfiles, so Gradle dependencies stay covered by Dependabot (`.github/dependabot.yml`). |
| 17 | Unused dependencies | Already OK | Every direct dependency in `app/pubspec.yaml` and `packages/html2apk_core/pubspec.yaml` is imported by code. |
| 18 | Errors and logs don't leak secrets | Already OK | Build logs pass through `build_orchestrator/log_redaction.dart` (password/secret/token/`--ks-pass` patterns); signing passwords are zeroed after use on the Kotlin side. |
| 19 | No debug configuration in release | Fixed | `app/android/app/build.gradle.kts`: a release build without `android/key.properties` now fails instead of quietly signing with the debug key. Local experiments can opt in with `HTML2APK_ALLOW_DEBUG_SIGNING=true` (or `-PallowDebugSigning=true`). Generated apps enable WebView debugging only in debuggable builds; Windows apps enable DevTools only in debug .exe builds. The Windows wrapper's `HTML2APK_CONSOLE_LOG` variable (test logging, `windows_template/src/main.cpp:556`) is left as is: it only writes the page's console to a file chosen by whoever starts the process, so it crosses no privilege boundary, and the release-exe tests depend on it. |
| 20 | CI security checks | Fixed | `.github/workflows/ci.yml`: new `secrets` job (gitleaks over full history) and `dependencies` job (osv-scanner); every action pinned to a full commit SHA with the version in a comment. Dependabot's `github-actions` ecosystem keeps the SHAs current. |

## Verification

- `dart analyze` and `dart test` in `packages/html2apk_core`: no issues, all tests pass (including the new LAN server tests for /24, 429, 410 and headers).
- `flutter analyze` and `flutter test` in `app`: no issues, all tests pass.
- `flutter build apk --release` without `key.properties` fails at `:app:preReleaseBuild` with an explanation; with `HTML2APK_ALLOW_DEBUG_SIGNING=true` it builds.
