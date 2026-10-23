package com.html2apk.engine.signing

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.Date

/** Subject of a self-signed upload/release certificate. */
data class DistinguishedName(
    val commonName: String,
    val organization: String? = null,
    val organizationalUnit: String? = null,
    /** Two-letter ISO country code. */
    val country: String? = null,
) {
    init {
        require(commonName.isNotBlank() && commonName.length <= 64) { "Name must be 1-64 characters" }
        require(organization == null || organization.length <= 64) { "Organization is too long" }
        require(country == null || Regex("^[A-Z]{2}$").matches(country)) { "Country must be a two-letter code like IN" }
    }

    fun encode(): ByteArray {
        fun rdn(oid: String, value: ByteArray) = Der.set(Der.seq(Der.oid(oid), value))
        val parts = buildList {
            country?.let { add(rdn("2.5.4.6", Der.printable(it))) }
            organization?.takeIf { it.isNotBlank() }?.let { add(rdn("2.5.4.10", Der.utf8(it))) }
            organizationalUnit?.takeIf { it.isNotBlank() }?.let { add(rdn("2.5.4.11", Der.utf8(it))) }
            add(rdn("2.5.4.3", Der.utf8(commonName)))
        }
        return Der.seq(*parts.toTypedArray())
    }
}

class KeystoreException(message: String) : Exception(message)

/**
 * Release keystores in PKCS12 format: the format keytool and Android
 * Studio write by default (also under a .jks name), readable by Gradle on
 * any desktop and by Android. Legacy JKS files are imported through
 * [JksReader] and converted.
 */
object ReleaseKeystore {
    enum class Format { PKCS12, JKS, JCEKS }

    class Unlocked(val alias: String, val key: PrivateKey, val chain: List<X509Certificate>) {
        val certificate: X509Certificate get() = chain.first()
    }

    private const val SHA256_WITH_RSA = "1.2.840.113549.1.1.11"
    private const val SUBJECT_KEY_ID = "2.5.29.14"

    /** Generates an RSA key with a self-signed certificate and returns PKCS12 bytes. */
    fun generate(
        alias: String,
        subject: DistinguishedName,
        password: CharArray,
        validityYears: Int = 30,
        keySize: Int = 2048,
    ): ByteArray {
        validateAlias(alias)
        validatePassword(password)
        require(validityYears in 25..50) { "Validity must be 25-50 years" }
        require(keySize == 2048 || keySize == 4096) { "Key size must be 2048 or 4096" }
        val pair = KeyPairGenerator.getInstance("RSA").apply { initialize(keySize, SecureRandom()) }.generateKeyPair()
        val now = System.currentTimeMillis()
        val cert = selfSignedCertificate(pair, subject, Date(now - 86_400_000L), Date(now + validityYears * 365L * 86_400_000L))
        return toPkcs12(Unlocked(alias, pair.private, listOf(cert)), password, password)
    }

    fun selfSignedCertificate(pair: KeyPair, subject: DistinguishedName, notBefore: Date, notAfter: Date): X509Certificate {
        val sigAlg = Der.seq(Der.oid(SHA256_WITH_RSA), Der.nul())
        val name = subject.encode()
        val spki = pair.public.encoded
        val keyId = MessageDigest.getInstance("SHA-1").digest(spki)
        val extensions = Der.explicit(3, Der.seq(Der.seq(Der.oid(SUBJECT_KEY_ID), Der.octets(Der.octets(keyId)))))
        val serial = BigInteger(1, ByteArray(16).also { SecureRandom().nextBytes(it) }).setBit(127)
        val tbs = Der.seq(
            Der.explicit(0, Der.int(2)),
            Der.int(serial),
            sigAlg,
            name,
            Der.seq(Der.time(notBefore), Der.time(notAfter)),
            name,
            spki,
            extensions,
        )
        val signature = java.security.Signature.getInstance("SHA256withRSA").run {
            initSign(pair.private)
            update(tbs)
            sign()
        }
        val der = Der.seq(tbs, sigAlg, Der.bitString(signature))
        val cert = CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(der)) as X509Certificate
        cert.verify(pair.public)
        return cert
    }

    fun detectFormat(bytes: ByteArray): Format {
        if (bytes.size >= 4) {
            val magic = ((bytes[0].toInt() and 0xff) shl 24) or ((bytes[1].toInt() and 0xff) shl 16) or
                ((bytes[2].toInt() and 0xff) shl 8) or (bytes[3].toInt() and 0xff)
            if (magic == JksReader.MAGIC) return Format.JKS
            if (magic == 0xCECECECE.toInt()) return Format.JCEKS
        }
        return Format.PKCS12
    }

    /** Aliases of private-key entries. Throws [KeystoreException] on a wrong password or unreadable file. */
    fun aliases(bytes: ByteArray, storePassword: CharArray): List<String> = when (detectFormat(bytes)) {
        Format.JKS -> JksReader.read(bytes, storePassword).filter { it.protectedKey != null }.map { it.alias }
        Format.JCEKS -> throw KeystoreException("JCEKS keystores are not supported; convert with keytool -importkeystore")
        Format.PKCS12 -> {
            val ks = loadPkcs12(bytes, storePassword)
            ks.aliases().toList().filter { ks.isKeyEntry(it) }
        }
    }

    fun unlock(bytes: ByteArray, storePassword: CharArray, alias: String, keyPassword: CharArray): Unlocked =
        when (detectFormat(bytes)) {
            Format.JKS -> {
                val entry = JksReader.read(bytes, storePassword).firstOrNull { it.alias.equals(alias, ignoreCase = true) && it.protectedKey != null }
                    ?: throw KeystoreException("No key named \"$alias\" in this keystore")
                Unlocked(entry.alias, JksReader.decryptKey(entry.protectedKey!!, keyPassword), entry.chain)
            }
            Format.JCEKS -> throw KeystoreException("JCEKS keystores are not supported")
            Format.PKCS12 -> {
                val ks = loadPkcs12(bytes, storePassword)
                val real = ks.aliases().toList().firstOrNull { it.equals(alias, ignoreCase = true) && ks.isKeyEntry(it) }
                    ?: throw KeystoreException("No key named \"$alias\" in this keystore")
                val key = try {
                    ks.getKey(real, keyPassword) as? PrivateKey
                } catch (e: java.security.UnrecoverableKeyException) {
                    throw KeystoreException("Wrong key password")
                } ?: throw KeystoreException("\"$alias\" is not a private key")
                val chain = ks.getCertificateChain(real)?.map { it as X509Certificate }
                if (chain.isNullOrEmpty()) throw KeystoreException("\"$alias\" has no certificate")
                Unlocked(real, key, chain)
            }
        }

    /**
     * [unlock] for a keystore the user brings in. Unlike [generate] there is no
     * minimum length: the file keeps the password it was made with (keytool
     * allows 6 characters; Android's debug keystore uses "android").
     */
    fun unlockForImport(bytes: ByteArray, storePassword: CharArray, alias: String, keyPassword: CharArray): Unlocked {
        if (storePassword.isEmpty()) throw KeystoreException("Enter the keystore password")
        return unlock(bytes, storePassword, alias, keyPassword)
    }

    fun toPkcs12(unlocked: Unlocked, storePassword: CharArray, keyPassword: CharArray): ByteArray {
        val ks = KeyStore.getInstance("PKCS12").apply { load(null, null) }
        ks.setKeyEntry(unlocked.alias, unlocked.key, keyPassword, unlocked.chain.toTypedArray())
        return ByteArrayOutputStream().also { ks.store(it, storePassword) }.toByteArray()
    }

    fun fingerprint(cert: X509Certificate, algorithm: String = "SHA-256"): String =
        MessageDigest.getInstance(algorithm).digest(cert.encoded).joinToString(":") { "%02X".format(it) }

    fun validateAlias(alias: String) {
        if (!Regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$").matches(alias)) {
            throw KeystoreException("Alias must be 1-64 letters, digits, dots, dashes or underscores")
        }
    }

    /** For keys made in the app; imports use [unlockForImport]. */
    fun validatePassword(password: CharArray) {
        if (password.size < 8) throw KeystoreException("Password must be at least 8 characters")
    }

    private fun loadPkcs12(bytes: ByteArray, password: CharArray): KeyStore = try {
        KeyStore.getInstance("PKCS12").apply { load(ByteArrayInputStream(bytes), password) }
    } catch (e: java.io.IOException) {
        // Wrong passwords surface as IOException (often wrapping UnrecoverableKeyException).
        throw KeystoreException("Wrong keystore password, or not a keystore file")
    }
}
