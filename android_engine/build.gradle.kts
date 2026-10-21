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
        kotlin.include("com/html2apk/engine/signing/**")
    }
}

dependencies {
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}
