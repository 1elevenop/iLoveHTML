// Desktop JVM build of the platform-independent signing code, for unit tests.
// Android apps compile these same sources directly (see app/ and the prototype).
plugins {
    kotlin("jvm") version "2.4.21"
}

kotlin {
    jvmToolchain(25)
}

sourceSets {
    main {
        kotlin.setSrcDirs(listOf("src/main/kotlin"))
        // Everything except the parts that need the Android framework.
        kotlin.exclude("com/html2apk/engine/SigningKeyStore.kt", "com/html2apk/engine/DeviceSigningKey.kt")
    }
    test {
        // The generated apps' share/download checks, which use no Android APIs.
        kotlin.srcDir("../android_template/app/src/main/kotlin")
        kotlin.include(
            "com/html2apk/engine/**",
            "com/html2apk/runtime/ShareRules.kt", "com/html2apk/runtime/ShareRulesTest.kt",
            "com/html2apk/runtime/AppOrigins.kt", "com/html2apk/runtime/AppOriginsTest.kt",
        )
    }
}

dependencies {
    implementation("com.android.tools.build:apksig:9.4.1")
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}
