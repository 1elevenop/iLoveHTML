package com.html2apk.engine.signing

import java.io.ByteArrayOutputStream
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.cert.X509Certificate
import java.util.Calendar
import java.util.Date
import java.util.TimeZone
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class ReleaseKeystoreTest {
    private val password = "correct horse".toCharArray()
    private val subject = DistinguishedName("Jane Developer", "Example Co", country = "IN")

    @Test
    fun generatedKeystoreLoadsWithTheJdk() {
        val bytes = ReleaseKeystore.generate("upload", subject, password)
        val ks = KeyStore.getInstance("PKCS12").apply { load(bytes.inputStream(), password) }
        assertEquals(listOf("upload"), ks.aliases().toList())
        val cert = ks.getCertificate("upload") as X509Certificate
        cert.verify(cert.publicKey)
        assertEquals("CN=Jane Developer,O=Example Co,C=IN", cert.subjectX500Principal.name)
        assertEquals(cert.subjectX500Principal, cert.issuerX500Principal)
        assertEquals(3, cert.version)
        assertEquals("SHA256withRSA", cert.sigAlgName)
        // Play requires validity past 22 October 2033; 30 years is well beyond.
        val notAfter = Calendar.getInstance().apply { time = cert.notAfter }.get(Calendar.YEAR)
        assertTrue(notAfter >= Calendar.getInstance().get(Calendar.YEAR) + 29)
    }

    @Test
    fun unlockReturnsTheSigningKey() {
        val bytes = ReleaseKeystore.generate("upload", subject, password)
        val unlocked = ReleaseKeystore.unlock(bytes, password, "UPLOAD", password)
        assertEquals("upload", unlocked.alias)
        val sig = java.security.Signature.getInstance("SHA256withRSA")
        sig.initSign(unlocked.key); sig.update(byteArrayOf(1, 2, 3))
        val s = sig.sign()
        sig.initVerify(unlocked.certificate); sig.update(byteArrayOf(1, 2, 3))
        assertTrue(sig.verify(s))
    }

    @Test
    fun wrongPasswordsAndAliasesAreReported() {
        val bytes = ReleaseKeystore.generate("upload", subject, password)
        assertFailsWith<KeystoreException> { ReleaseKeystore.aliases(bytes, "wrong-password".toCharArray()) }
        assertFailsWith<KeystoreException> { ReleaseKeystore.unlock(bytes, password, "other", password) }
        assertFailsWith<KeystoreException> { ReleaseKeystore.aliases("not a keystore".toByteArray(), password) }
    }

    @Test
    fun inputsAreValidated() {
        assertFailsWith<KeystoreException> { ReleaseKeystore.generate("upload", subject, "short".toCharArray()) }
        assertFailsWith<KeystoreException> { ReleaseKeystore.generate("bad alias!", subject, password) }
        assertFailsWith<IllegalArgumentException> { DistinguishedName("x", country = "India") }
        assertFailsWith<IllegalArgumentException> { DistinguishedName(" ") }
    }

    @Test
    fun datesAfter2049UseGeneralizedTime() {
        val utc = TimeZone.getTimeZone("UTC")
        val d2049 = Calendar.getInstance(utc).apply { set(2049, 0, 1, 0, 0, 0) }.time
        val d2056 = Calendar.getInstance(utc).apply { set(2056, 5, 1, 12, 0, 0) }.time
        assertEquals(0x17, Der.time(d2049)[0].toInt())
        assertEquals(0x18, Der.time(d2056)[0].toInt())
        val pair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        val cert = ReleaseKeystore.selfSignedCertificate(pair, subject, Date(), d2056)
        assertEquals(d2056.time / 1000, cert.notAfter.time / 1000)
    }

    @Test
    fun oidEncodingMatchesKnownValues() {
        // sha256WithRSAEncryption, from RFC 4055.
        assertContentEquals(
            byteArrayOf(0x06, 0x09, 0x2A, 0x86.toByte(), 0x48, 0x86.toByte(), 0xF7.toByte(), 0x0D, 0x01, 0x01, 0x0B),
            Der.oid("1.2.840.113549.1.1.11"),
        )
    }

    @Test
    fun legacyJksKeystoresImportViaTheReader() {
        // Build a genuine JKS with the JDK's own provider (not available on Android).
        val source = ReleaseKeystore.unlock(ReleaseKeystore.generate("legacy", subject, password), password, "legacy", password)
        val keyPassword = "different key pw".toCharArray()
        val jks = KeyStore.getInstance("JKS").apply { load(null, null) }
        jks.setKeyEntry("legacy", source.key, keyPassword, source.chain.toTypedArray())
        jks.setCertificateEntry("trusted-ca", source.certificate)
        val bytes = ByteArrayOutputStream().also { jks.store(it, password) }.toByteArray()

        assertEquals(ReleaseKeystore.Format.JKS, ReleaseKeystore.detectFormat(bytes))
        assertEquals(listOf("legacy"), ReleaseKeystore.aliases(bytes, password))
        val unlocked = ReleaseKeystore.unlock(bytes, password, "legacy", keyPassword)
        assertContentEquals(source.key.encoded, unlocked.key.encoded)
        assertEquals(source.certificate, unlocked.certificate)

        assertFailsWith<KeystoreException> { ReleaseKeystore.aliases(bytes, "nope-nope".toCharArray()) }
        assertFailsWith<KeystoreException> { ReleaseKeystore.unlock(bytes, password, "legacy", password) }

        // Converted copies keep the same key and certificate.
        val p12 = ReleaseKeystore.toPkcs12(unlocked, password, password)
        assertEquals(ReleaseKeystore.Format.PKCS12, ReleaseKeystore.detectFormat(p12))
        assertEquals(
            ReleaseKeystore.fingerprint(source.certificate),
            ReleaseKeystore.fingerprint(ReleaseKeystore.unlock(p12, password, "legacy", password).certificate),
        )
    }

    @Test
    fun importAcceptsPasswordsShorterThanTheCreateMinimum() {
        val source = ReleaseKeystore.unlock(ReleaseKeystore.generate("upload", subject, password), password, "upload", password)
        // keytool's minimum is 6 characters; Android's debug keystore uses "android".
        val p12Password = "abc123".toCharArray()
        val p12 = ReleaseKeystore.toPkcs12(source, p12Password, p12Password)
        val debugPassword = "android".toCharArray()
        val jks = KeyStore.getInstance("JKS").apply { load(null, null) }
        jks.setKeyEntry("androiddebugkey", source.key, debugPassword, source.chain.toTypedArray())
        val jksBytes = ByteArrayOutputStream().also { jks.store(it, debugPassword) }.toByteArray()

        for ((bytes, pw, alias) in listOf(Triple(p12, p12Password, "upload"), Triple(jksBytes, debugPassword, "androiddebugkey"))) {
            val unlocked = ReleaseKeystore.unlockForImport(bytes, pw, alias, pw)
            // The stored copy is PKCS12 under the same password.
            val stored = ReleaseKeystore.toPkcs12(unlocked, pw, pw)
            assertEquals(
                ReleaseKeystore.fingerprint(source.certificate),
                ReleaseKeystore.fingerprint(ReleaseKeystore.unlock(stored, pw, alias, pw).certificate),
            )
        }
        assertFailsWith<KeystoreException> { ReleaseKeystore.unlockForImport(p12, CharArray(0), "upload", CharArray(0)) }
        assertFailsWith<KeystoreException> { ReleaseKeystore.generate("upload", subject, debugPassword) }
    }

    @Test
    fun truncatedJksIsRejectedCleanly() {
        val source = ReleaseKeystore.unlock(ReleaseKeystore.generate("k", subject, password), password, "k", password)
        val jks = KeyStore.getInstance("JKS").apply { load(null, null) }
        jks.setKeyEntry("k", source.key, password, source.chain.toTypedArray())
        val bytes = ByteArrayOutputStream().also { jks.store(it, password) }.toByteArray()
        for (cut in listOf(10, bytes.size / 2, bytes.size - 5)) {
            assertFailsWith<KeystoreException> { JksReader.read(bytes.copyOf(cut), password) }
        }
    }
}
