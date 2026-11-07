package com.html2apk.engine.bundle

import com.html2apk.engine.ApkAssembler
import com.html2apk.engine.AppSpec
import com.html2apk.engine.WebsiteFile
import com.html2apk.engine.signing.DistinguishedName
import com.html2apk.engine.signing.ReleaseKeystore
import java.io.File
import java.util.jar.JarFile
import java.util.zip.ZipFile
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/**
 * Uses the real base bundle produced by `gradlew bundleRelease` in
 * android_template. The signed output is left in build/test-output for
 * bundletool validation and device installs.
 */
class BundleAssemblerTest {
    private val baseBundle = File("../android_template/app/build/outputs/bundle/release/app-release.aab")
    private val outDir = File("build/test-output").apply { mkdirs() }

    private fun manifestBytes(bundle: File) =
        ZipFile(bundle).use { z -> z.getInputStream(z.getEntry(BundleAssembler.MANIFEST)).readBytes() }

    private fun requireBase() = check(baseBundle.exists()) {
        "Run gradlew bundleRelease in android_template first (${baseBundle.absolutePath})"
    }

    @Test
    fun protobufRoundTripIsByteIdentical() {
        requireBase()
        val bytes = manifestBytes(baseBundle)
        assertContentEquals(bytes, ProtoMessage.parse(bytes).encode())
        assertContentEquals(bytes, ProtoManifest(bytes).encode())
    }

    @Test
    fun manifestEditsAreApplied() {
        requireBase()
        val m = ProtoManifest(manifestBytes(baseBundle))
        assertEquals("com.html2apk.template", m.packageName)
        m.setPackage("com.example.bundle")
        m.setVersionCode(42)
        m.setVersionName("4.2")
        m.setLabel("Bundle Test")
        m.setScreenOrientation(1)
        m.addPermissions(listOf("android.permission.INTERNET"))
        val text = String(m.encode(), Charsets.UTF_8)
        assertTrue("provider" !in text, "base bundle should not declare a FileProvider (Android 10+)")
        assertEquals("com.example.bundle", ProtoManifest(m.encode()).packageName)
        for (s in listOf("Bundle Test", "4.2", "uses-permission", "android.permission.INTERNET")) {
            assertTrue(s in text, "missing $s")
        }
        assertTrue("@string/app_name" !in text)
    }

    @Test
    fun rejectsMalformedProtobuf() {
        assertFailsWith<IllegalArgumentException> { ProtoMessage.parse(byteArrayOf(0x0A, 0x7F, 0x01)) }
        assertFailsWith<IllegalArgumentException> { ProtoManifest(byteArrayOf()) }
    }

    @Test
    fun buildsASignedBundle() {
        requireBase()
        val site = listOf(
            "index.html" to "<!doctype html><title>B</title><h1>Bundle test</h1><script src=\"js/app.js\"></script>",
            "js/app.js" to "document.title = 'ok'",
        ).map { (path, text) -> WebsiteFile(path, text.length.toLong()) { text.byteInputStream() } }
        val spec = AppSpec(
            applicationId = "com.html2apk.bundletest",
            label = "Bundle Test",
            versionCode = 3,
            versionName = "1.2.0",
            screenOrientation = 1,
            permissions = listOf("android.permission.INTERNET"),
            configJson = """{"schemaVersion":1,"source":{"type":"local","entry":"index.html"},"javaScriptEnabled":true}""",
            iconPng = File("../samples/splash.png").readBytes(),
        )
        val password = "bundle-test-pw".toCharArray()
        val ks = ReleaseKeystore.generate("upload", DistinguishedName("Bundle Test"), password)
        File(outDir, "bundle-test.p12").writeBytes(ks)
        val key = ReleaseKeystore.unlock(ks, password, "upload", password)

        val assembler = BundleAssembler(baseBundle, "com.html2apk.template")
        val unsigned = File(outDir, "bundle-test-unsigned.aab")
        val signed = File(outDir, "bundle-test.aab")
        val timings = ApkAssembler.Timings()
        assembler.assembleUnsigned(site, spec, unsigned, timings)
        assembler.sign(unsigned, signed, key.key, key.chain, timings)

        ZipFile(signed).use { z ->
            val names = z.entries().asSequence().map { it.name }.toSet()
            for (n in listOf("BundleConfig.pb", "base/resources.pb", "base/dex/classes.dex", "base/assets/www/index.html",
                "base/assets/www/js/app.js", "base/assets/app_config.json", "META-INF/MANIFEST.MF")) {
                assertTrue(n in names, "missing $n")
            }
            assertTrue("base/assets/www/index.html" in names && names.none { it == "base/assets/www/" })
        }
        // The JAR signature must verify and cover every entry.
        JarFile(signed, true).use { jar ->
            for (e in jar.entries()) {
                if (e.isDirectory || e.name.startsWith("META-INF/")) continue
                jar.getInputStream(e).use { it.readBytes() }
                val signers = e.codeSigners
                assertTrue(signers != null && signers.isNotEmpty(), "${e.name} is not signed")
                assertEquals(
                    ReleaseKeystore.fingerprint(key.certificate),
                    ReleaseKeystore.fingerprint(signers.first().signerCertPath.certificates.first() as java.security.cert.X509Certificate),
                )
            }
        }
        // Streaming readers must see the signature too (META-INF first, like jarsigner).
        java.util.jar.JarInputStream(signed.inputStream(), true).use { jis ->
            assertTrue(jis.manifest != null, "JarInputStream sees no manifest")
            var checked = 0
            while (true) {
                val entry = jis.nextJarEntry ?: break
                if (entry.isDirectory || entry.name.startsWith("META-INF/")) continue
                jis.readBytes() // signers are known only after the entry is fully read
                assertTrue(!entry.codeSigners.isNullOrEmpty(), "${entry.name} unsigned in JarInputStream")
                checked++
            }
            assertTrue(checked > 10)
        }
        println("Signed bundle: ${signed.absolutePath}")
    }
}
