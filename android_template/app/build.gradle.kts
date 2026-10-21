import java.util.Properties

plugins {
    id("com.android.application")
}

// Values written by the converter's android_generator. Defaults let the
// template build standalone for development.
val wrapperProps = Properties().apply {
    val f = rootProject.file("wrapper.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun wrapperProp(key: String, default: String): String = wrapperProps.getProperty(key) ?: default

// Release signing comes from the environment (set by the converter's build
// engine), never from files in the project, so passwords stay out of logs.
val releaseKeystore: String? = System.getenv("HTML2APK_KEYSTORE")

android {
    namespace = "com.html2apk.runtime"
    compileSdk = 36

    defaultConfig {
        applicationId = wrapperProp("applicationId", "com.html2apk.template")
        minSdk = 24
        targetSdk = 36
        versionCode = wrapperProp("versionCode", "1").toInt()
        versionName = wrapperProp("versionName", "1.0.0")
    }

    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("HTML2APK_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("HTML2APK_KEY_ALIAS")
                keyPassword = System.getenv("HTML2APK_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            if (releaseKeystore != null) signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.webkit:webkit:1.17.1")
    implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.2.0")
}
