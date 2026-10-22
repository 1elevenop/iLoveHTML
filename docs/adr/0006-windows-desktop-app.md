# ADR 0006: Windows desktop app

Status: accepted (2026-10-22)

## Context

The spec asks for the same Flutter UI on Windows and Android. Phase 1
already built APKs on Windows through the CLI (generator + Gradle); the
UI only had the Android engine (ADR 0002) and Android-only features
(Android Keystore keys, Install/Share, embedded WebView preview).

## Decision

- **Engine:** `DesktopBuildEngine` wraps `GradleProjectBuildEngine` from
  `html2apk_core` with the JDK and Android SDK found by
  `discoverToolchain()`. The wrapper template is copied next to the
  executable by `windows/CMakeLists.txt` (`android_template/`, without
  `build/`, `.gradle/` or `local.properties`).
- **Release keys:** same `KeyManager` interface and screen as Android.
  Keystores are copied into `<app support>/workspace/keys/` (PKCS12 when
  created, any format when imported); passwords are encrypted with
  **DPAPI** (`CryptProtectData`, current Windows user, extra entropy)
  through `dart:ffi`, the counterpart of Android Keystore in ADR 0004.
  Key operations use the JDK's `keytool` with passwords passed only as
  environment variables (`-storepass:env`). For PKCS12 the key password
  must equal the store password (keytool ignores `-keypass` there), so a
  different one is rejected at import; JKS key passwords are checked with
  `keytool -certreq`.
- **Results:** "Save as…" (system save dialog) and "Show in folder".
  No Install button: there is no phone attached by default.
- **Preview:** `webview_flutter` has no Windows implementation. The
  preview opens in the default browser, served by the same loopback-only,
  token-protected `PreviewServer`; it stops when the dialog closes.
  Missing files are listed in the dialog; the console is the browser's
  developer tools.
- **New dependency:** `ffi` (Dart team, already a transitive dependency
  of `path_provider_windows`) for the DPAPI calls. No WebView2 plugin was
  added; an embedded preview can come later if the browser is not enough.

## Requirements on the PC

- Visual Studio 2022 (Build Tools is enough) with "Desktop development
  with C++".
- Windows Developer Mode, because Flutter links plugins with symlinks.
- The repo on an NTFS drive (exFAT has no symlinks). The repo moved from
  `E:` (exFAT) to `D:\Build HTML Android App`.
- JDK 17+ and Android SDK as for the CLI (Phase 1).

## Verified (2026-10-22)

- `test/desktop_engine_test.dart` (5 tests): DPAPI round trip and
  tamper rejection; create/list/inspect/delete keys; wrong PKCS12 and
  JKS key passwords rejected; legacy JKS import; Gradle debug and release
  builds with the release signed by the stored key and no password in
  the log.
- `integration_test/windows_ui_test.dart` drives the real Windows app:
  project list → project → browser preview (page served from
  127.0.0.1, server stopped when the dialog closes) → debug APK (Gradle)
  → release APK signed with a stored key (certificate pinned to the
  project) → App Bundle with the same version refused → App Bundle at
  version 1.0.1. "Save as…" and "Show in folder" appear after builds.
- The Android app still passes its on-device build test after the
  `KeyManager` refactor.
- Not clicked by hand: the native file dialogs (import, Save as, key
  backup) — the test calls the same controller/engine methods they use.

## Not done

- Embedded preview with console on Windows (WebView2).
- Installing to a connected phone from Windows (adb).
- A Windows installer/MSIX; the app runs from the build folder.
