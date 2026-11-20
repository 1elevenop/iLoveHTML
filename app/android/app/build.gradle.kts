import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// iLoveHTML's own release key (never committed). Without android/key.properties a
// release build fails, unless allowDebugSigning is set (see the check at the end).
// Opt-out for local experiments: -PallowDebugSigning=true, or the environment
// variable HTML2APK_ALLOW_DEBUG_SIGNING=true (works through `flutter build`).
val allowDebugSigning = providers.gradleProperty("allowDebugSigning").orNull == "true" ||
    providers.environmentVariable("HTML2APK_ALLOW_DEBUG_SIGNING").orNull == "true"

val releaseKey = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "com.html2apk.html2apk_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.html2apk.html2apk_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 29 // Android 10+, same as the apps it builds.
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKey.containsKey("storeFile")) {
            create("release") {
                storeFile = file(releaseKey.getProperty("storeFile"))
                storePassword = releaseKey.getProperty("storePassword")
                keyAlias = releaseKey.getProperty("keyAlias")
                keyPassword = releaseKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            val release = signingConfigs.findByName("release")
            if (release != null) {
                signingConfig = release
            } else if (allowDebugSigning) {
                logger.warn("android/key.properties not found: signing the release build with the debug key (allowDebugSigning)")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

// A release build without android/key.properties must not quietly ship with the
// debug key (see allowDebugSigning above).
if (!releaseKey.containsKey("storeFile") && !allowDebugSigning) {
    tasks.matching { it.name == "preReleaseBuild" }.configureEach {
        doFirst {
            throw GradleException(
                "android/key.properties is missing, so the release build cannot be signed. " +
                    "Add it, or set HTML2APK_ALLOW_DEBUG_SIGNING=true to sign with the debug key for local testing."
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

android {
    androidResources {
        // The prebuilt base APK is already compressed.
        noCompress += listOf("apk", "aab")
    }
    // Shared on-device engine sources (ADR 0002), also used by the prototype.
    sourceSets.getByName("main").java.srcDir("../../../android_engine/src/main/kotlin")
}

dependencies {
    // Google's pure-Java APK signer/verifier; runs on ART.
    implementation("com.android.tools.build:apksig:9.4.1")
    implementation("androidx.core:core:1.17.0")
}
