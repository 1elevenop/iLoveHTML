package com.html2apk.engine

import java.io.File
import java.util.zip.ZipFile
import kotlin.test.Test
import kotlin.test.assertEquals

/** Uses the real base APK produced by `gradlew assembleRelease` in android_template. */
class ApkManifestTest {
    private val baseApk = File("../android_template/app/build/outputs/apk/release/app-release-unsigned.apk")

    @Test
    fun fileProviderAuthorityFollowsTheApplicationId() {
        check(baseApk.exists()) { "Run gradlew assembleRelease in android_template first (${baseApk.absolutePath})" }
        val bytes = ZipFile(baseApk).use { z -> z.getInputStream(z.getEntry("AndroidManifest.xml")).readBytes() }
        val spec = AppSpec(
            applicationId = "com.example.share",
            label = "Share Test",
            versionCode = 1,
            versionName = "1.0",
            screenOrientation = -1,
            permissions = emptyList(),
            configJson = "{}",
            iconPng = ByteArray(0),
        )
        val patched = AxmlDocument.parse(ApkAssembler(baseApk, BaseInfo("com.html2apk.template", "")).patchManifest(bytes, spec))
        val provider = patched.elements("provider").single()
        val authorities = patched.attribute(provider, AxmlDocument.ATTR_AUTHORITIES)!!
        assertEquals("com.example.share.html2apk.files", patched.strings[authorities.rawValue])
        assertEquals(providerAuthority("com.example.share"), patched.strings[authorities.data])
    }
}
