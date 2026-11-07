package com.html2apk.engine

import java.io.File
import java.util.zip.ZipFile
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Uses the real base APK produced by `gradlew assembleRelease` in android_template. */
class ApkManifestTest {
    private val baseApk = File("../android_template/app/build/outputs/apk/release/app-release-unsigned.apk")

    @Test
    fun generatedAppsNeedAndroid10AndHaveNoFileProvider() {
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
        val usesSdk = patched.elements("uses-sdk").single()
        assertEquals(ApkAssembler.MIN_SDK, patched.attribute(usesSdk, ATTR_MIN_SDK_VERSION)!!.data)
        assertEquals(29, ApkAssembler.MIN_SDK)
        assertTrue(patched.elements("provider").isEmpty())
    }

    private companion object {
        const val ATTR_MIN_SDK_VERSION = 0x0101020c
    }
}
