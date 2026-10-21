# ADR 0002: Building APKs on the Android device

Status: **accepted (2026-10-21)**. Option B was approved, prototyped and
verified on one physical device. More devices still need testing (see below).

## Constraints

1. **No execution from writable storage (W^X).** Apps targeting API 29+
   cannot `execve` files in their data directory. Native executables must
   ship inside the APK as `lib*.so` and run from `nativeLibraryDir`.
   Termux avoids this by targeting API 28, which Google Play no longer
   accepts for new apps.
2. **No official Android builds of the toolchain.** Running Gradle needs a
   full JDK built for Android/bionic plus an Android-built `aapt2`, all
   repackaged as `lib*.so` and maintained by this project.
3. **Gradle and AGP cost.** On Windows the template build runs with a
   2 GB Gradle heap, and the Gradle cache after the first build is 654 MB
   (Gradle distribution, AGP, AndroidX; measured 2026-10-21).
4. **Dependency resolution needs Maven repositories** unless an offline
   repository with every artifact AGP needs is shipped.

## Options

### A. Full JDK + Gradle + AGP on the device — rejected

Highest fidelity, but high risk on every constraint above. It is
documented here and not built.

### B. Template-APK assembly on the device — chosen

The wrapper runtime is fixed code configured by `app_config.json`
(ADR 0001), so its compiled output is identical for every project:

1. At **converter build time**, `tools/build_ondevice_base.ps1` runs
   Gradle on the template (`assembleRelease`, unsigned) and records the
   base package and the icon's resource path in `base_info.json`. This
   compiles the converter's own runtime, never a user project.
2. On the device, in Kotlin on ART with no external processes
   (`android_ondevice_prototype/`):
   - copy the base APK, drop `assets/www/**` and `assets/app_config.json`,
     add the user's website (same path rules as the desktop importer) and
     config;
   - rewrite the binary `AndroidManifest.xml` with `AxmlDocument`:
     package, versionCode, versionName, label (reference → literal string),
     screenOrientation, inserted `<uses-permission>` elements. Strings are
     only appended to the pool, so existing indices and the resource-ID
     map stay valid;
   - replace the icon PNG in place (`res/Fk.png` in the current base);
   - align and sign with `apksig` 9.4.1 (v2 + v3), then verify with
     `ApkVerifier`. The prototype's key is generated in Android Keystore
     and never leaves it.

Template rules this depends on (enforced in `android_template/`):

- The icon is a PNG (`res/drawable-nodpi/app_icon.png`), never a vector.
- The activity always declares `android:screenOrientation`, so it can be
  edited in place. Adding attributes that are not in the base manifest's
  resource map would need a full string-pool remap and is not supported.

## Prototype results (2026-10-21)

Device: Samsung Galaxy S25 Ultra (SM-S938B), Android 17 / API 37,
arm64-v8a, Android System WebView 155.

| Measurement | Result |
|---|---|
| End-to-end build time (demo site) | ≈ 0.3 s: assemble 127 ms, key 105 ms (first-time generation), sign 43 ms, verify 9 ms |
| Peak Java heap during build | 16 MB |
| Process peak RSS (VmHWM, whole app) | 175 MB |
| Base APK shipped in converter | 1,022,059 bytes |
| Generated APK | 1,031,738 bytes |
| Prototype app size (debug) | 2,154,103 bytes |

Verification of the device-built APK:

- On device: `ApkVerifier` verified, v2 and v3.
- On Windows: `apksigner verify` passes (v2); `zipalign -c -P 16 4` passes;
  `aapt2 dump badging` shows package `com.html2apk.ondevice.demo`,
  versionCode 7, versionName `2.0-ondevice`, label "On-Device Demo",
  `uses-permission` INTERNET, screenOrientation portrait; the swapped
  icon and all website files are present.
- Installed on the same phone next to the Gradle-built demo (different
  package, no conflicts). It launched in 139 ms and rendered the site with
  JavaScript. About → Back returned home, and a second Back left the app.
  No crashes.

## Limits and open work

- **Tested on one device only.** Before calling Android-side builds supported:
  Android 7–10, 32-bit armv7, x86_64, a low-RAM device (≤ 3 GB), and a large
  site (50+ MB) to measure memory with real assets.
- **Large websites:** the prototype reads each file into memory. Production
  code should stream entries from the ZIP into the output.
- **Install handoff:** tested via `adb install` only. The `PackageInstaller`
  flow (user confirmation on the device) is not built yet.
- **AAB on device:** not prototyped. It needs a proto-format base module and
  JAR signing, built the same way.
- **Signing keys:** Android Keystore keys cannot be exported, so an app
  signed on the phone cannot be updated from Windows with the same key. This
  needs a decision in the Phase 3 signing design (e.g. an importable keystore
  protected by Keystore-wrapped encryption).
- **Parity with Windows:** the Gradle engine and the assembly engine are
  different code paths. A shared test should compare `aapt2 dump badging`
  and the asset tree of both outputs for the same project.
- `ApkSigner.SignerConfig.Builder(name, key, certs)` is deprecated in
  apksig 9.4.1. Move to the replacement when this code leaves the prototype.

Estimated minimum requirements (to confirm on more devices): Android 7.0
(API 24), any ABI (no native code), about 50 MB free storage per build,
2 GB RAM.
