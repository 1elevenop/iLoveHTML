# ADR 0005: Android App Bundles (AAB) for Google Play

Status: accepted (2026-10-22)

## Decision

Release builds can produce `.aab` files on both engines.

- **Windows:** Gradle `bundleRelease` with the release keystore from
  ADR 0004 (signing via environment variables). The bundle's JAR
  signature is checked with `keytool -printcert -jarfile`, and the
  certificate SHA-256 is recorded in build history.
- **Android (on-device):** same approach as APKs (ADR 0002). A base bundle
  of the wrapper (`base.aab`, from `bundleRelease` at converter build time,
  shipped next to `base.apk`) is edited:
  - `base/manifest/AndroidManifest.xml` is aapt2's **protobuf** XmlNode,
    not binary XML. `ProtoMessage` is a minimal wire-format reader/writer
    that keeps unknown fields, and re-encoding an unchanged manifest is
    byte-identical (tested). `ProtoManifest` changes package, versionCode,
    versionName, label (reference → literal), screenOrientation, and
    inserts `<uses-permission>` elements.
  - Website, `app_config.json`, splash and icon are swapped as in APKs.
  - Signing is **JAR (v1) with SHA-256** via apksig with v2/v3 off, which
    is what jarsigner/Gradle produce and Play requires for uploads.
    `META-INF/` is moved to the front of the zip (apksig appends it) so
    streaming readers (`JarInputStream`) see the signature, like jarsigner.
  - The result is verified on the device (every entry signed by the
    release certificate) before it is kept.
- **Release-only.** Debug bundles are refused: Play does not accept them
  and they cannot be installed directly. The UI offers "Save to device"
  (system save screen) and Share instead of Install for `.aab`.
- `bundletool` (Google, 1.18.3, checksum-verified) is a PC-side developer
  tool in `.tools/` for validation only; it is not shipped in the app.

## Verified (2026-10-22)

Android 16 x86_64 emulator and Windows, same imported `upload.jks` key:

- Bundle built inside the emulator, saved via the system save screen:
  `jarsigner -verify` → "jar verified"; `bundletool validate` passes;
  `bundletool build-apks` + `install-apks` install base + config splits
  (`config.en`, `config.xxhdpi`) and the app runs.
- Same app built on Windows with `--release --aab`: same certificate
  SHA-256 (`D6:FC:03…5F:F2`), identical entry list, same package,
  version, orientation and permissions. Label differs only in form
  (string resource vs literal "Loose Files").
- 12 JVM engine tests (protobuf round trip, manifest edits, signed bundle
  verified with `JarFile` and `JarInputStream`), 68 core tests.

## Not done

- Uploading to Play Console (needs the user's developer account).
- Physical-device run of the in-app AAB build (emulator only so far).
- Play App Signing guidance in the UI (this key is the *upload* key).
