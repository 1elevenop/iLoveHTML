# HTML2APK — local HTML-to-Android app builder

Converts a website (ZIP of HTML/CSS/JS/assets, later folders and URLs) into
an Android WebView app, built entirely on the local machine.

**Status: Phase 2 started.**

- **Android app (`app/`, Flutter):** project list; new apps from a website
  ZIP or a live https URL (checked first: redirects followed hop by hop,
  private/local addresses blocked, title used as the app name); project
  settings and icon; a preview with back/forward/reload, viewport presets,
  JavaScript console, missing-file and blocked-link reports; and an
  on-device Build tab that produces a debug-signed APK with Install and
  Share. Builds run on the phone without Gradle
  ([ADR 0002](docs/adr/0002-android-on-device-build.md)).
- **Generated apps:** loading bar, offline error page with a "Try again"
  that works without JavaScript, `example.com`/`www.example.com` treated as
  one site, other sites opened in the browser.
- **Windows:** the same pipeline through the CLI (ZIP → generated Gradle
  project → local `assembleDebug`). The Flutter desktop UI is not built
  yet (see Requirements).
- Not built yet: bar colours, splash screen, offline fallback page,
  pull-to-refresh, file upload, release signing, AAB, SQLite index,
  templates.

## Layout

| Path | What |
|---|---|
| `app/` | Flutter app (Android today, Windows later) on top of `html2apk_core` |
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
- For the Windows desktop UI (not built yet): Visual Studio 2022 with
  "Desktop development with C++", and the repo on an NTFS drive. Flutter's
  Windows plugin setup needs symlinks, which exFAT drives cannot hold.

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
dart run bin/html2apk.dart --zip ../../samples/demo-site.zip --name "HTML2APK Demo" --id com.html2apk.demo --icon ../../samples/demo-icon.png --out ../../out
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

## Tests

```bash
cd packages/html2apk_core
dart test
```

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
