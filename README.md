# iLoveHTML — local HTML-to-Android app builder

Converts a website (ZIP of HTML/CSS/JS/assets, later folders and URLs) into
an Android WebView app, built entirely on the local machine.

**Status: Android app and Windows app working; websites build into APK, AAB and Windows .exe.**

- **Android app (`app/`, Flutter):** project list; new apps from one or
  more HTML files (CSS/JS/images picked alongside are moved into the
  folders the pages link to), a website ZIP, or a live https URL (checked first: redirects followed hop by hop,
  private/local addresses blocked, title used as the app name); project
  settings and icon; a preview with back/forward/reload, viewport presets,
  JavaScript console, missing-file and blocked-link reports; and an
  on-device Build tab that produces a debug-signed APK with Install and
  Share. Builds run on the phone without Gradle
  ([ADR 0002](docs/adr/0002-android-on-device-build.md)).
- **Generated apps:** loading bar, offline error page with a "Try again"
  that works without JavaScript (or your own offline page for URL apps),
  `example.com`/`www.example.com` treated as one site, other sites opened
  in the browser, status/navigation bar colours with readable icons,
  optional splash screen (your image or the app icon), pull-to-refresh
  (also retries after an error), and file uploads through Android's
  file picker.
- **Project format:** `project.json` schema 2; schema-1 projects are
  upgraded automatically when loaded.
- **Windows app** ([ADR 0006](docs/adr/0006-windows-desktop-app.md)): the
  same Flutter UI (projects, import, settings, release keys) building with
  the local JDK, Android SDK and Gradle. Debug/release APKs and App
  Bundles, "Save as…" and "Show in folder"; release keys with passwords
  encrypted for your Windows account (DPAPI); preview in your browser from
  a local-only server. The CLI still works too (see below).
- **Windows .exe apps** ([ADR 0007](docs/adr/0007-windows-exe-apps.md)):
  on Windows, Build → "Build .exe" turns the project into one .exe that
  opens the site in its own window with Microsoft Edge WebView2. Needs the
  wrapper built once: `powershell -File tools/build_windows_wrapper.ps1`.
  Not code-signed yet, so downloaded copies show a SmartScreen warning.
- **Windows installers** ([ADR 0008](docs/adr/0008-windows-msix-installers.md)):
  Build → "Build installer" makes a signed `.msix` (Start menu entry,
  clean uninstall, in-place updates). Signed with your own code-signing
  `.pfx` or a test certificate made in the app; a test certificate must be
  trusted once on each PC. Needs the Windows SDK
  (`winget install Microsoft.WindowsSDK.10.0.26100`).
- **Release signing** ([ADR 0004](docs/adr/0004-release-signing.md)):
  create or import release keys on the phone (.jks / .keystore / .p12,
  including legacy JKS), back them up as password-protected `.jks`,
  build release APKs. The same backup signs on Windows:
  `--release --keystore upload.jks --alias upload` with the password in
  `HTML2APK_KEYSTORE_PASSWORD`.
- **App Bundles for Google Play** ([ADR 0005](docs/adr/0005-app-bundles.md)):
  release `.aab` built on the phone (Build → Release → App Bundle, then
  Save to device) or on Windows (`--release --aab --keystore … --alias …`).
  Validate with `java -jar .tools/bundletool.jar validate --bundle app.aab`
  (bundletool is downloaded to `.tools/`, not committed).
- Not built yet: camera/location and other native features, SQLite index,
  templates.

## Layout

| Path | What |
|---|---|
| `app/` | Flutter app for Android and Windows on top of `html2apk_core` |
| `windows_template/` | C++ WebView2 wrapper for Windows .exe apps (ADR 0007) |
| `android_template/` | Native Kotlin WebView wrapper (Gradle project) used for every generated app |
| `android_engine/` | Kotlin on-device build engine (binary manifest editor, APK assembler, Keystore signing), shared by `app/` and the prototype |
| `packages/html2apk_core/` | Shared Dart core: project model, importer, security, generator, build orchestration |
| `android_ondevice_prototype/` | Minimal Android test app for the on-device engine |
| `tools/build_ondevice_base.ps1` | Builds the base APK and `base_info.json` for the on-device engine |
| `samples/` | Demo site, icon and ZIP for the end-to-end test |
| `docs/adr/` | Architecture decisions |

## Requirements (Windows)

- Android SDK with accepted licenses (Android Studio installs both)
- JDK 17+ (Android Studio's bundled `jbr` is detected automatically)
- Flutter 3.47+ / Dart 3.13+ (for the Dart core; tested with Flutter 3.47.7 at `C:\src\flutter`)
- Internet on the first build only (Gradle, AGP, AndroidX go into `~/.gradle`)
- For the Windows app: Visual Studio 2022 (Build Tools is enough) with
  "Desktop development with C++", Windows **Developer Mode** on, and the
  repo on an NTFS drive (this repo lives at D:\iLoveHTML).
  Flutter links plugins with symlinks, which need Developer Mode and
  which exFAT drives cannot hold.

## Run the Windows app

```bash
cd app
flutter run -d windows
```

Or `flutter build windows` and start
`app\build\windows\x64\runner\Release\iLoveHTML.exe`; the
`android_template` folder next to the exe must stay with it. Projects and
keys live in `%APPDATA%\com.html2apk\html2apk_app\workspace`.

## Run the Android app

```bash
powershell -File tools/build_ondevice_base.ps1
```

Then, with a phone connected over adb:

```bash
cd app
flutter run
```

The base APK must be rebuilt whenever `android_template/` changes.

Pinned build versions are in [ADR 0003](docs/adr/0003-toolchain-versions.md).

## Build an APK from a ZIP

```bash
cd packages/html2apk_core
dart pub get
dart run bin/html2apk.dart --zip ../../samples/demo-site.zip --name "iLoveHTML Demo" --id com.html2apk.demo --icon ../../samples/demo-icon.png --out ../../out
```

Projects go to `.workspace/projects/<id>/`, generated Gradle projects and
`build.log` to `.workspace/builds/<id>/`.

## On-device build prototype

```bash
powershell -File tools/build_ondevice_base.ps1
```

Then build `android_ondevice_prototype` with `gradlew.bat assembleDebug`,
install it, and start it with:

```bash
adb shell am start -n com.html2apk.ondevice/.PrototypeActivity --ez autorun true
```

The generated APK and `result.json` (timings, memory) are written to
`/sdcard/Android/data/com.html2apk.ondevice/files/`.

## Testing without a phone (emulator)

An Android 16 x86_64 emulator (`html2apk_test`, Pixel 7 profile) runs on
this PC with WHPX acceleration:

```bash
"%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd html2apk_test -no-window -no-audio -no-boot-anim
```

Drop `-no-window` to see it. The debug build of `app/` includes x86_64,
so `adb -s emulator-5554 install app\build\app\outputs\flutter-apk\app-debug.apk`
works. Physical-device checks are still done at the end of each milestone.
Android 10 (`html2apk_api29`) and 7.0 (`html2apk_api24`) emulators are
set up too; see [docs/testing.md](docs/testing.md) for all test layers.

## Milestone 6: hardening and testing (2026-10-22)

| Check | Android 7.0 (API 24) | Android 10 (API 29) | Android 16 (API 36) |
|---|---|---|---|
| Windows end-to-end (`tools/e2e_windows.ps1`: debug, release, AAB, install, page JS ran) | pass | pass | pass |
| On-device end-to-end (`integration_test/build_flow_test.dart`) | pass | pass | pass |
| Preview cannot read `file://`/`content://` (`integration_test/preview_security_test.dart`) | pass | pass | pass |
| Generated app: bar colours, page, pull-to-refresh | pass | pass | pass |

Bugs found and fixed:

- **AAB build failed on Android 7.x** (`java.util.Base64` missing, used by
  apksig's v1 signer). Bundles are now signed by our own `JarSigner`
  ([ADR 0005](docs/adr/0005-app-bundles.md)).
- **Invisible navigation-bar buttons on Android 7.x** with a light
  navigation-bar colour (dark buttons need API 26). The generated app now
  uses black there; Android 8.0+ keeps your colour.
- Security fixes from the [security review](docs/security-review.md): ZIP
  size limits now count bytes actually written to disk (not the sizes the
  ZIP claims), the preview WebView has `file://`/`content://` access off,
  and only allow-listed permissions can be requested.

Large site (42.5 MB ZIP, 2,142 files including 40 × 1 MB incompressible
images):

| | Import | Build | APK | Peak memory |
|---|---|---|---|---|
| Windows (Gradle) | — | 51 s | 44 MB | — |
| Android 16 emulator (in-app engine) | ~6 s | ~3.2 s engine time | 44 MB, runs | 603 MB peak RSS vs 487 MB before (debug build of the app) |

On the Android 7.0 emulator use `-gpu host`: with the software renderer
its WebView 53 draws some images as black boxes (an emulator artefact).

## Signing tests (desktop JVM)

```bash
cd android_engine
gradlew.bat test
```

## Tests

```bash
cd packages/html2apk_core
dart test
```

Widget tests: `cd app && flutter test`. On-device and Windows end-to-end
tests: [docs/testing.md](docs/testing.md).

## Verify an APK

```bash
"%LOCALAPPDATA%\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs out\com.html2apk.demo-1.0.0-debug.apk
```

## Troubleshooting

- *No JDK found*: set `JAVA_HOME` or install Android Studio.
- *SDK licenses not accepted*: open Android Studio > SDK Manager once.
- *First build slow*: it is downloading Gradle 9.8.2 and AGP 9.4.1; later builds take ~20 s.
- *Build log*: `.workspace/builds/<project-id>/build.log` (passwords and tokens are redacted).

## Security defaults of generated apps

No file or content-provider access from the WebView, bundled content
served from `https://appassets.androidplatform.net` through
`WebViewAssetLoader`, mixed content blocked, cleartext traffic disabled,
`INTERNET` permission only for URL projects or when explicitly enabled,
off-site links handed to the browser, WebView debugging only in debug builds.
