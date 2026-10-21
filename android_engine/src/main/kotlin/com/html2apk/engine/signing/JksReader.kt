package com.html2apk.engine.signing

import java.io.ByteArrayInputStream
import java.io.DataInputStream
import java.io.EOFException
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec

/**
 * Reads Sun's legacy JKS keystore format, which Android has no provider for,
 * so existing upload keys can be imported on the phone.
 *
 * Format: magic, version, entries (private keys protected with Sun's
 * SHA-1 XOR "key protector", certificate chains), then a SHA-1 integrity
 * digest keyed with the store password and the constant "Mighty Aphrodite".
 */
object JksReader {
    const val MAGIC = 0xFEEDFEED.toInt()
    private const val KEY_PROTECTOR_OID = "1.3.6.1.4.1.42.2.17.1.1"
    private const val MAX_ENTRIES = 1000

    class Entry(val alias: String, val protectedKey: ByteArray?, val chain: List<X509Certificate>)

    fun read(bytes: ByteArray, storePassword: CharArray): List<Entry> {
        val input = DataInputStream(ByteArrayInputStream(bytes))
        val entries = mutableListOf<Entry>()
        val dataEnd: Int
        try {
            if (input.readInt() != MAGIC) throw KeystoreException("Not a JKS keystore")
            val version = input.readInt()
            if (version != 1 && version != 2) throw KeystoreException("Unsupported JKS version $version")
            val count = input.readInt()
            if (count !in 0..MAX_ENTRIES) throw KeystoreException("Corrupt JKS keystore")
            val cf = CertificateFactory.getInstance("X.509")
            fun readCert(): X509Certificate {
                if (version == 2) input.readUTF() // certificate type, "X.509"
                val der = ByteArray(checkedLength(input.readInt(), bytes.size)).also { input.readFully(it) }
                return cf.generateCertificate(ByteArrayInputStream(der)) as X509Certificate
            }
            repeat(count) {
                val tag = input.readInt()
                val alias = input.readUTF()
                input.readLong() // creation date
                when (tag) {
                    1 -> {
                        val key = ByteArray(checkedLength(input.readInt(), bytes.size)).also { input.readFully(it) }
                        val n = input.readInt()
                        if (n !in 0..MAX_ENTRIES) throw KeystoreException("Corrupt JKS keystore")
                        entries.add(Entry(alias, key, List(n) { readCert() }))
                    }
                    2 -> entries.add(Entry(alias, null, listOf(readCert())))
                    else -> throw KeystoreException("Corrupt JKS keystore")
                }
            }
            dataEnd = bytes.size - input.available()
        } catch (e: EOFException) {
            throw KeystoreException("Truncated JKS keystore")
        }
        if (bytes.size - dataEnd != 20) throw KeystoreException("Corrupt JKS keystore")
        val md = MessageDigest.getInstance("SHA-1")
        md.update(utf16be(storePassword))
        md.update("Mighty Aphrodite".toByteArray(Charsets.UTF_8))
        md.update(bytes, 0, dataEnd)
        if (!MessageDigest.isEqual(md.digest(), bytes.copyOfRange(dataEnd, bytes.size))) {
            throw KeystoreException("Wrong keystore password, or the file is damaged")
        }
        return entries
    }

    /** Decrypts a JKS-protected private key (EncryptedPrivateKeyInfo with Sun's key protector). */
    fun decryptKey(protectedKey: ByteArray, password: CharArray): PrivateKey {
        val outer = DerReader(protectedKey)
        val epki = outer.inside(outer.next())
        val algSeq = epki.next()
        if (epki.inside(algSeq).let { it.oid(it.next()) } != KEY_PROTECTOR_OID) {
            throw KeystoreException("Unsupported key protection in JKS file")
        }
        val data = epki.bytes(epki.next())
        if (data.size < 41) throw KeystoreException("Corrupt JKS key entry")
        val salt = data.copyOfRange(0, 20)
        val encrypted = data.copyOfRange(20, data.size - 20)
        val check = data.copyOfRange(data.size - 20, data.size)
        val pw = utf16be(password)
        val sha1 = MessageDigest.getInstance("SHA-1")
        val plain = ByteArray(encrypted.size)
        var digest = salt
        var i = 0
        while (i < encrypted.size) {
            sha1.update(pw)
            sha1.update(digest)
            digest = sha1.digest()
            for (j in digest.indices) if (i + j < encrypted.size) plain[i + j] = (encrypted[i + j].toInt() xor digest[j].toInt()).toByte()
            i += 20
        }
        sha1.update(pw)
        sha1.update(plain)
        if (!MessageDigest.isEqual(sha1.digest(), check)) throw KeystoreException("Wrong key password")
        return KeyFactory.getInstance(keyAlgorithm(plain)).generatePrivate(PKCS8EncodedKeySpec(plain))
    }

    /** Algorithm of a PKCS#8 PrivateKeyInfo: RSA or EC. */
    private fun keyAlgorithm(pkcs8: ByteArray): String {
        val r = DerReader(pkcs8)
        val info = r.inside(r.next())
        info.next() // version
        val alg = info.inside(info.next())
        return when (alg.oid(alg.next())) {
            "1.2.840.113549.1.1.1" -> "RSA"
            "1.2.840.10045.2.1" -> "EC"
            else -> throw KeystoreException("Only RSA and EC keys are supported")
        }
    }

    private fun checkedLength(n: Int, max: Int): Int {
        if (n < 0 || n > max) throw KeystoreException("Corrupt JKS keystore")
        return n
    }

    private fun utf16be(chars: CharArray): ByteArray {
        val out = ByteArray(chars.size * 2)
        for ((i, c) in chars.withIndex()) {
            out[2 * i] = (c.code shr 8).toByte()
            out[2 * i + 1] = c.code.toByte()
        }
        return out
    }
}
