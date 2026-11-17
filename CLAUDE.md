# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

iLoveHTML turns HTML files, a website ZIP or a live https URL into an Android app (APK/AAB) or a Windows app (.exe/.msix), built locally on the user's phone or PC. Development happens on Windows; toolchain versions are pinned in `docs/adr/0003-toolchain-versions.md` (CI uses Flutter 3.47.7).

## Commands

| What | Command |
|---|---|
| Dart core: analyze / test | `cd packages/html2apk_core && dart pub get && dart analyze && dart test` |
| One core test | `cd packages/html2apk_core && dart test test/<file>_test.dart` (add `--name "<substring>"` for one case) |
| Flutter app: analyze / test | `cd app && flutter pub get && flutter analyze && flutter test` |
| One app test | `cd app && flutter test test/<file>_test.dart` |
| Kotlin engine tests (JVM, Java 25 toolchain) | `cd android_engine && gradlew.bat test` — needs the base APK/AAB built from `android_template` first (CI: `cd android_template && gradlew.bat assembleRelease bundleRelease` with JDK 17) |
| Build base APK/AAB for the on-device engine | `powershell -File tools/build_ondevice_base.ps1` |
| Build the Windows .exe wrapper | `powershell -File tools/build_windows_wrapper.ps1` |
| Run the app | `cd app && flutter run -d windows` (Windows) or `flutter run` (Android, after building the base APK) |
| CLI build from a ZIP | `cd packages/html2apk_core && dart run bin/html2apk.dart --zip ../../samples/demo-site.zip --name "iLoveHTML Demo" --id com.html2apk.demo --icon ../../samples/demo-icon.png --out ../../out` |
| Windows end-to-end | `powershell -File tools/e2e_windows.ps1 -Device emulator-5554` |
| On-device integration tests | `cd app && flutter test integration_test -d <device>` |

Notes:
- **`flutter test integration_test` uninstalls iLoveHTML afterwards, deleting projects and saved signing keys on that device.** Don't run it on a phone with real keys. Run on-device tests with a time limit; a stuck emulator adb connection hangs `adb install` silently.
- App tests that need the prebuilt Windows wrapper or the Windows SDK skip themselves when those are missing.
- Emulators: `html2apk_test` (Android 16, port 5554) and `html2apk_api29` (Android 10, port 5556, the oldest supported version). All test layers are listed in `docs/testing.md`.
- Localization: ARB files in `app/lib/l10n/` (`app_en.arb` is the template), generated code in `app/lib/l10n/gen` (`generate: true`). Add new strings to every ARB file.

## Architecture

Modular monolith (`docs/adr/0001-architecture.md`); read the ADRs in `docs/adr/` before changing a subsystem.

- **`packages/html2apk_core/`** — pure Dart, no Flutter dependency. `project_core` (the `project.json` manifest, currently `currentSchemaVersion = 2`, with migrations, validation, `ProjectStore`, backups), `project_importer` (safe ZIP/HTML-file import, URL probe), `security` (path normalization, URL policy that blocks private networks), `android_generator` (template copy plus generated files), `build_orchestrator` (the `AndroidBuildAdapter` interface, the Gradle adapter, toolchain discovery, asset optimizer, log redaction, LAN share server), `web_preview`. `bin/html2apk.dart` is the CLI.
- **`app/`** — Flutter UI for both Android and Windows on top of the core. `lib/src/engine/` holds the build engines: `on_device_engine.dart` (Android, talks to Kotlin over the `html2apk/engine` MethodChannel, implemented in `app/android/.../EngineChannel.kt`), `desktop_engine.dart` (Windows: JDK/SDK/Gradle, keys protected with DPAPI), `exe_builder.dart`, `msix_builder.dart`.
- **`android_template/`** — native Kotlin WebView wrapper (`com.html2apk.runtime`) used for **every** generated Android app.
- **`android_engine/`** — Kotlin on-device build engine (binary-manifest editor `AxmlDocument`, `ApkAssembler`, `bundle/` for AAB + `JarSigner`, `signing/` for keystores). It has no module of its own in the app: `app/android/app/build.gradle.kts` adds its sources directly, and `android_ondevice_prototype/` shares them too.
- **`windows_template/`** — C++ WebView2 wrapper for Windows .exe apps.

Key design rules:
- **Runtime features are configuration, not code.** Every WebView feature is compiled into `android_template` and switched on or off by `assets/app_config.json`. Adding a feature means changing the template, the config schema and the core generator together.
- **No text substitution in generation.** Kotlin/Gradle sources are copied unchanged. Per-project data is written as complete files (`AndroidManifest.xml` built in code, `app_strings.xml`, `app_config.json`, `wrapper.properties`).
- **On-device builds don't use Gradle** (ADR 0002). A prebuilt base APK/AAB (from `tools/build_ondevice_base.ps1`, copied into `app/android/app/src/main/assets/base/` with `base_info.json`, not in Git) is patched on the phone: assets are replaced, the binary manifest is edited, the icon PNG is swapped in place, then it is signed with apksig. **Rebuild the base whenever `android_template/` changes.** Template constraints: the icon must stay a PNG (`res/drawable-nodpi/app_icon.png`), and the activity must always declare `android:screenOrientation`. Manifest attributes not already in the base manifest's resource map cannot be added.
- **Windows builds** run the template's pinned Gradle wrapper as a child process (`GradleProcessBuildAdapter`). The Android engine implements the same `AndroidBuildAdapter` interface.
- **Projects are plain portable directories** (`project.json`, `source/`, `branding/`, `exports/`) with POSIX paths. Signing secrets never go in `project.json`: they live in Android Keystore or in Windows DPAPI-protected storage. Build logs are redacted.
- Generated apps have strict security defaults (see the README section "Security defaults of generated apps" and `docs/security-review.md`). Permissions come from an allow-list, and share, file-saving and notifications answer only the app's own site plus the hosts a URL project lists explicitly. Keep these when you change the template.
- Minimum Android version is 10 (API 29) for both iLoveHTML and the apps it builds (ADR 0010).

## Releasing

Raise `version:` in `app/pubspec.yaml` (always increment the `+build` number), then `flutter build apk --release` and `flutter build windows --release` in `app/`. Release signing uses `app/android/key.properties`, which lives outside the repo. `release/` is not committed. The Windows build needs `android_template/` next to the exe.
