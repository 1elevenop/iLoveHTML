# HTML2APK — local HTML-to-Android app builder

Converts a website (ZIP of HTML/CSS/JS/assets, later folders and URLs) into
an Android WebView app, built entirely on the local machine.

**Status: Phase 1 (Windows pipeline prototype).** Working today, through a
CLI: ZIP import → project on disk → generated Gradle project → local
`assembleDebug` → validated, debug-signed APK. The Flutter UI, signing,
AAB and the Android on-device engine are not built yet. See
[docs/adr](docs/adr).

## Layout

| Path | What |
|---|---|
| `android_template/` | Native Kotlin WebView wrapper (Gradle project) used for every generated app |
| `packages/html2apk_core/` | Shared Dart core: project model, importer, security, generator, build orchestration |
| `samples/` | Demo site, icon and ZIP for the end-to-end test |
| `docs/adr/` | Architecture decisions |

## Requirements (Windows)

- Android SDK with accepted licenses (Android Studio installs both)
- JDK 17+ (Android Studio's bundled `jbr` is detected automatically)
- Flutter 3.47+ / Dart 3.13+ (for the Dart core; tested with Flutter 3.47.7 at `C:\src\flutter`)
- Internet on the first build only (Gradle, AGP, AndroidX go into `~/.gradle`)
- Later, for the Windows desktop UI: Visual Studio 2022 with "Desktop development with C++"

Pinned build versions are in [ADR 0003](docs/adr/0003-toolchain-versions.md).

## Build an APK from a ZIP

```bash
cd packages/html2apk_core
dart pub get
dart run bin/html2apk.dart --zip ../../samples/demo-site.zip --name "HTML2APK Demo" --id com.html2apk.demo --icon ../../samples/demo-icon.png --out ../../out
```

Projects go to `.workspace/projects/<id>/`, generated Gradle projects and
`build.log` to `.workspace/builds/<id>/`.

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
