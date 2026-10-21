# ADR 0002: Building APKs on the Android device

Status: **proposed — needs approval and a physical-device prototype**

Nothing in this document has been run on an Android device yet. Figures
marked *estimate* are not measurements.

## Constraints

1. **No execution from writable storage (W^X).** Apps targeting API 29+
   cannot `execve` files in their data directory. Native executables must
   ship inside the APK as `lib*.so` and run from `nativeLibraryDir`
   (`extractNativeLibs="true"`). Termux avoids this by targeting API 28,
   which Google Play no longer accepts for new apps.
2. **No official Android builds of the toolchain.** Google ships JDK-free
   SDK tools; `aapt2` exists only for Linux/macOS/Windows on x86_64/arm64
   desktop. Running Gradle needs a full JDK built for Android/bionic
   (e.g. from Termux packages) plus an Android-built `aapt2`, all
   repackaged as `lib*.so`.
3. **Gradle and AGP cost.** On Windows the template build runs with a
   2 GB Gradle heap, and the Gradle cache after the first build is 654 MB
   (Gradle distribution, AGP, AndroidX; measured 2026-10-21). On a phone this means
   high RAM pressure, low-memory kills while backgrounded, and multi-minute
   builds (*estimate: 3–10 min, 4–6 GB RAM devices, 1.5–2.5 GB storage*).
4. **Dependency resolution needs Maven repositories** unless the converter
   ships a pre-seeded offline repository with every artifact AGP needs.

## Options

### A. Full JDK + Gradle + AGP on the device

Same pipeline as Windows. Highest fidelity, but high risk on every point
above: arm64 only in practice, large download, slow, fragile across Android
versions and OEM process killers, and it depends on unofficial JDK/aapt2
ports that the project would have to maintain.

### B. Template-APK assembly on the device (recommended)

Because the wrapper runtime is fixed code configured by
`app_config.json` (ADR 0001), the compilation output (`classes.dex`,
compiled resources) is identical for every user project. So:

1. At **converter release time**, build the wrapper once from
   `android_template/` with Gradle (on the developer's machine) and embed
   the unsigned base APK (and a proto-format base module for AAB) in the
   Android converter app.
2. On the device, for each project, in Kotlin on ART with no external
   processes:
   - copy the base APK, replace `assets/www/**` and `assets/app_config.json`;
   - rewrite the binary `AndroidManifest.xml` (package/applicationId,
     versionCode, versionName, label, permissions, orientation) with a
     binary-XML writer;
   - replace the icon entry (`res/drawable-nodpi-v4/app_icon.png`);
   - zip-align and sign with `apksig` (Google's pure-Java signer, runs on
     Android) using a key from Android Keystore-protected storage.
3. AAB: same edits on the protobuf base module, packaged with the bundle
   layout and signed with JAR signing.

Limits of B:

- No per-project native code; every feature must be in the prebuilt
  runtime and toggled by config. This already matches the design.
- Manifest edits are limited to what the binary-XML writer supports
  (package, version, label, permissions, orientation, theme colors).
- The Windows engine (Gradle) and Android engine (assembly) are different
  code paths; both must produce equivalent apps. A shared test suite will
  diff `aapt2 dump badging` and the asset tree of both outputs.

*Estimates for B (unmeasured):* Android 8.0+ (API 26), arm64/armv7/x86_64,
2 GB RAM, ~100 MB free storage, builds in seconds.

This is not cloud compilation: everything runs on the user's device. The
only off-device step is compiling the converter app itself.

## Proposed next steps

1. Approve B as the primary Android engine (A stays documented, not built).
2. Prototype B as a small Kotlin library + test activity: patch the base APK
   built in Phase 1, sign with apksig, install via `PackageInstaller`.
3. Run it on at least one physical device; measure time, peak RAM, storage;
   install the result and confirm the site renders. Only then claim
   Android-side builds work.
