package com.html2apk.engine.bundle

import com.html2apk.engine.signing.DistinguishedName
import com.html2apk.engine.signing.ReleaseKeystore
import java.io.File
import java.security.cert.X509Certificate
import java.util.jar.JarFile
import java.util.jar.JarInputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class JarSignerTest {
    private val dir = File("build/test-output/jarsigner").apply { mkdirs() }

    @Test
    fun base64MatchesTheJdk() {
        val r = Random(7)
        for (n in 0..70) {
            val bytes = ByteArray(n) { r.nextInt().toByte() }
            assertEquals(java.util.Base64.getEncoder().encodeToString(bytes), JarSigner.base64(bytes), "length $n")
        }
    }

    @Test
    fun signsLongAndNonAsciiNamesThatJarsignerAccepts() {
        val names = listOf(
            "base/assets/www/" + "very-long-directory-name/".repeat(5) + "page.html",
            "base/assets/www/café/ünïcødé-✓-" + "x".repeat(60) + ".css",
            "base/assets/www/index.html",
            "META-INF/OLD.SF", // stale signature files are dropped
        )
        val unsigned = File(dir, "unsigned.zip")
        ZipOutputStream(unsigned.outputStream()).use { zos ->
            for (n in names) {
                zos.putNextEntry(ZipEntry(n)); zos.write("content of $n".toByteArray()); zos.closeEntry()
            }
        }
        val pw = "jar-signer-test".toCharArray()
        val key = ReleaseKeystore.unlock(ReleaseKeystore.generate("k", DistinguishedName("Jar Test"), pw), pw, "k", pw)
        val signed = File(dir, "signed.zip")
        JarSigner.sign(unsigned, signed, key.key, key.chain)

        JarFile(signed, true).use { jar ->
            val entries = jar.entries().toList().map { it.name }
            assertEquals(listOf("META-INF/MANIFEST.MF", "META-INF/UPLOAD.SF", "META-INF/UPLOAD.RSA"), entries.take(3))
            assertTrue("META-INF/OLD.SF" !in entries)
            for (n in names.dropLast(1)) {
                val e = jar.getJarEntry(n)
                jar.getInputStream(e).use { it.readBytes() }
                val cert = e.codeSigners!!.single().signerCertPath.certificates.first() as X509Certificate
                assertEquals(key.certificate, cert)
            }
            // Manifest lines must not exceed 72 bytes.
            val mf = jar.getInputStream(jar.getEntry("META-INF/MANIFEST.MF")).readBytes()
            for (line in String(mf, Charsets.UTF_8).split("\r\n")) assertTrue(line.toByteArray().size <= 72, line)
        }
        JarInputStream(signed.inputStream(), true).use { jis ->
            var count = 0
            while (true) {
                val e = jis.nextJarEntry ?: break
                jis.readBytes()
                if (e.name.startsWith("META-INF/")) continue // signature files themselves
                assertTrue(!e.codeSigners.isNullOrEmpty(), e.name)
                count++
            }
            assertEquals(3, count)
        }
        println("Signed jar for jarsigner: ${signed.absolutePath}")
    }
}
