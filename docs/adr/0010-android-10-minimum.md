# ADR 0010: Android 10 is the minimum

Status: accepted (2026-11-07)

## Context

Generated apps and iLoveHTML for Android supported Android 7.0 (API 24).
That cost separate code paths and tests:

- Google stopped updating Chrome, and with it the WebView, on Android 7
  (around version 119, 2023) and on Android 8–9 (around version 138,
  2025). Apps on those phones show web content in an engine without
  security fixes.
- Old-version code: the confirm-credential screen for app lock, sharing
  files from the cache through a FileProvider (and the engine rewriting
  its authority per app), app-private downloads, black navigation bars
  on 7.x, and the shortcut and notification-channel version checks.
- Android 7-only bugs (ADR 0005's AAB signing, invisible navigation-bar
  buttons) and a third emulator in every test pass.

Google Play only requires a recent target SDK, not a recent minimum, so
this is our choice.

## Decision

- `minSdk = 29` (Android 10) for the template (`android_template`), the
  on-device engine (`ApkAssembler.MIN_SDK`, which also drives apksig's v1
  signing and verification), the on-device prototype, and iLoveHTML for
  Android (`app/android`).
- Removed: the FileProvider (template manifest, Gradle generator,
  `res/xml/html2apk_file_paths.xml`, the engine's authority patching for
  APKs and bundles), the confirm-credential unlock path, app-private
  download folders, the 7.x navigation-bar workaround and the API 25/26
  checks. File shares always go through MediaStore (ADR 0009).
- Kept: the Android 10 branches that differ from 11+ (legacy fullscreen
  flags, `setDeviceCredentialAllowed` in the biometric prompt) and the
  Android 13 notification permission prompt.
- `JarSigner` stays: it works and has no reason to change.

## Consequences

- Android 7–9 phones cannot install new builds (Play hides them, and a
  sideloaded APK fails with `INSTALL_FAILED_OLDER_SDK`). Apps already
  installed there keep working until they are updated.
- Cheap TV boxes and kiosk tablets on Android 7–9 are no longer covered.
- Tests run on Android 10 and 16 emulators; `html2apk_api24` is retired.
