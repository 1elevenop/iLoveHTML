plugins {
    id("com.android.application")
}

android {
    namespace = "com.html2apk.ondevice"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.html2apk.ondevice"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0-prototype"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    androidResources {
        // base.apk is already compressed; storing it avoids double work.
        noCompress += "apk"
    }
}

dependencies {
    // Google's pure-Java APK signer/verifier; runs on ART.
    implementation("com.android.tools.build:apksig:9.4.1")
}

// Shared on-device engine sources (also used by the Flutter app).
android.sourceSets.getByName("main").kotlin.srcDir("../../android_engine/src/main/kotlin")
