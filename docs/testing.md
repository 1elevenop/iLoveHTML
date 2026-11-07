# Testing

## Layers

| Layer | Command | What it covers |
|---|---|---|
| Core unit tests (Dart) | `cd packages/html2apk_core && dart test` | Manifest + migrations, validation, ZIP/HTML-file import and limits, URL checks, preview server, generator, signing/AAB plumbing, CLI engine rules |
| Engine tests (desktop JVM) | `cd android_engine && gradlew.bat test` | Certificate building, PKCS12/JKS keystores, protobuf manifest editing, AAB assembly, JAR signer (checked against `JarFile` and `JarInputStream`) |
| Widget tests (Flutter) | `cd app && flutter test` | Project list, import dialogs, URL dialog, settings/build tabs |
| Windows end-to-end | `powershell -File tools/e2e_windows.ps1 -Device emulator-5554` | Demo ZIP → debug APK, release APK, release AAB with a throwaway key → apksigner, jarsigner, `bundletool validate` → install on a device and confirm the page ran its JavaScript |
| On-device end-to-end | `cd app && flutter test integration_test -d <device>` | Inside iLoveHTML with the real Kotlin engine: import HTML files, configure, debug APK, release key in Keystore, release APK, version-code rule, release AAB, debug-AAB refusal, ZIP bomb rejection |
| Windows engine (host) | `cd app && flutter test` (includes `test/desktop_engine_test.dart`) | DPAPI, keytool key store (create, import PKCS12/JKS, wrong passwords), Gradle debug + release builds |
| Windows .exe apps (host) | `powershell -File tools/build_windows_wrapper.ps1`, then `cd app && flutter test test/exe_builder_test.dart` | Builds and runs real exes: page/JS from the exe, 404s, `file://` refused, icon found by Windows, offline page for URL apps |
| Windows app UI | `cd app && flutter test integration_test/windows_ui_test.dart -d windows` | The real Windows app: project → browser preview → debug APK → release APK → version rule → App Bundle |
| Preview security (on device) | `cd app && flutter test integration_test/preview_security_test.dart -d <device>` | A previewed page tries `file://` and `content://` by XHR, iframe and navigation; nothing may be readable and the navigation must be blocked |

`flutter test integration_test` uninstalls iLoveHTML when it finishes,
which deletes the app's projects and saved signing keys on that device.
On a phone with real keys, back them up first (Signing keys → Back up).

Run every on-device test with a time limit. A stuck emulator adb
connection makes the install step hang without an error; if
`adb install` of the 155 MB debug app takes more than a minute, restart
that emulator (`adb -s <device> emu kill`, then start it again).

Emulators on this PC (WHPX acceleration), started headless:

```bash
"%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd html2apk_test  -port 5554 -no-window -no-audio
"%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd html2apk_api29 -port 5556 -no-window -no-audio
```

Android 10 (`html2apk_api29`) is the oldest supported version (ADR 0010).
Its stock WebView is 74, older than real Android 10 phones get from Play:
pages there have no `Notification` and no `prefers-color-scheme`.

## Results (2026-10-22)

See the milestone 6 section of the README for the device matrix and
large-site numbers.
