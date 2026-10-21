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

    buildTypes {
        release {
            isMinifyEnabled = false
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
