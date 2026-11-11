# ADR 0003: Pinned build toolchain for generated apps

Status: accepted (2026-10-21); versions updated 2026-11-11

| Component | Version | Where pinned |
|---|---|---|
| Gradle (wrapper) | 9.9.0, SHA-256 verified | `android_template/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.5.1 | `android_template/build.gradle.kts` |
| Kotlin | AGP 9 built-in Kotlin (no separate plugin) | — |
| compileSdk / targetSdk | 36 / 36 | `android_template/app/build.gradle.kts` |
| minSdk | 29 (Android 10; was 24 until 2026-11-07, ADR 0010) | same |
| androidx.webkit | 1.17.1 | same |
| JDK | 17+ required; verified with JetBrains Runtime 25.0.3 (Android Studio) | discovered at runtime |
| Build-tools | 36.0.0 (apksigner/aapt2 for verification) | discovered at runtime |

Notes:

- AGP auto-installs the `android-36` platform when SDK licenses are
  accepted. The first build needs internet access to download Gradle,
  AGP and AndroidX into the local Gradle cache. This is dependency
  resolution on the user's machine, not remote compilation; later builds
  work offline from the cache.
- Kotlin compiles in-process (`kotlin.compiler.execution.strategy=in-process`)
  so no Kotlin daemon lingers after a build or holds the output pipes.
- Upgrades are done deliberately: bump, rebuild the template, rerun the
  end-to-end test, update this table.

## Upgrade log

| Date | Change | Checked by |
|---|---|---|
| 2026-11-11 | Gradle 9.8.2 → 9.9.0 (SHA-256 checked against services.gradle.org), AGP 9.4.1 → 9.5.1 | Base APK rebuilt with `tools/build_ondevice_base.ps1`; prototype and `flutter build apk` build; on a Galaxy S25 Ultra (Android 17) the prototype built an app from the new base (3.13 MB, `apksigner verify` passes), which installed, opened and ran its JavaScript with no crash. androidx.core 1.19.1 for `app/android` left out: it needs compileSdk 37 |
