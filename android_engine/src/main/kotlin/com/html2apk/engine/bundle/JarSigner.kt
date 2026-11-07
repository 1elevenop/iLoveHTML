package com.html2apk.engine.bundle

import com.html2apk.engine.signing.Der
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.Signature
import java.security.cert.X509Certificate
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

/**
 * JAR (v1) signing with SHA-256, the scheme Google Play requires for App
 * Bundles, as written by jarsigner: META-INF/MANIFEST.MF with a digest per
 * entry, META-INF/<NAME>.SF with digests of the manifest, and a detached
 * PKCS#7 signature of the .SF in META-INF/<NAME>.RSA (or .EC).
 *
 * Self-contained (it once had to run on Android 7, which lacks
 * java.util.Base64). Signature files are written first, as jarsigner does,
 * so streaming readers see them.
 */
object JarSigner {
    private const val SIGNER = "UPLOAD"
    private const val CREATED_BY = "1.0 (HTML2APK)"
    private const val OID_SHA256 = "2.16.840.1.101.3.4.2.1"
    private const val OID_RSA = "1.2.840.113549.1.1.1"
    private const val OID_ECDSA_SHA256 = "1.2.840.10045.4.3.2"
    private const val OID_SIGNED_DATA = "1.2.840.113549.1.7.2"
    private const val OID_DATA = "1.2.840.113549.1.7.1"

    fun sign(input: File, output: File, key: PrivateKey, chain: List<X509Certificate>) {
        require(chain.isNotEmpty()) { "Certificate chain is empty" }
        val rsa = key.algorithm.equals("RSA", ignoreCase = true)
        require(rsa || key.algorithm.equals("EC", ignoreCase = true)) { "Only RSA and EC keys can sign bundles" }

        ZipFile(input).use { zip ->
            val entries = zip.entries().toList().filter { !it.isDirectory && !isSignatureFile(it.name) }
            require(entries.map { it.name }.toSet().size == entries.size) { "Duplicate zip entries" }

            // MANIFEST.MF: main section plus one section per entry.
            val mainSection = section(listOf("Manifest-Version" to "1.0", "Created-By" to CREATED_BY))
            val entrySections = entries.map { e ->
                val digest = zip.getInputStream(e).use { sha256(it.readBytes()) }
                e.name to section(listOf("Name" to e.name, "SHA-256-Digest" to base64(digest)))
            }
            val manifest = ByteArrayOutputStream().apply {
                write(mainSection)
                entrySections.forEach { write(it.second) }
            }.toByteArray()

            // .SF: digests of the whole manifest, its main section and each entry section.
            val sf = ByteArrayOutputStream().apply {
                write(section(listOf(
                    "Signature-Version" to "1.0",
                    "Created-By" to CREATED_BY,
                    "SHA-256-Digest-Manifest" to base64(sha256(manifest)),
                    "SHA-256-Digest-Manifest-Main-Attributes" to base64(sha256(mainSection)),
                )))
                for ((name, bytes) in entrySections) {
                    write(section(listOf("Name" to name, "SHA-256-Digest" to base64(sha256(bytes)))))
                }
            }.toByteArray()

            val signature = Signature.getInstance(if (rsa) "SHA256withRSA" else "SHA256withECDSA").run {
                initSign(key)
                update(sf)
                sign()
            }
            val block = pkcs7(signature, chain, rsa)

            ZipOutputStream(output.outputStream().buffered()).use { zos ->
                put(zos, "META-INF/MANIFEST.MF", manifest)
                put(zos, "META-INF/$SIGNER.SF", sf)
                put(zos, "META-INF/$SIGNER.${if (rsa) "RSA" else "EC"}", block)
                for (e in entries) {
                    zos.putNextEntry(ZipEntry(e.name).apply { method = ZipEntry.DEFLATED })
                    zip.getInputStream(e).use { it.copyTo(zos) }
                    zos.closeEntry()
                }
            }
        }
    }

    /** Detached PKCS#7 SignedData without signed attributes, as jarsigner writes. */
    private fun pkcs7(signature: ByteArray, chain: List<X509Certificate>, rsa: Boolean): ByteArray {
        val cert = chain.first()
        val digestAlg = Der.seq(Der.oid(OID_SHA256), Der.nul())
        val sigAlg = if (rsa) Der.seq(Der.oid(OID_RSA), Der.nul()) else Der.seq(Der.oid(OID_ECDSA_SHA256))
        val signerInfo = Der.seq(
            Der.int(1),
            Der.seq(cert.issuerX500Principal.encoded, Der.int(cert.serialNumber)),
            digestAlg,
            sigAlg,
            Der.octets(signature),
        )
        val certificates = Der.tlv(0xA0, chain.fold(ByteArray(0)) { acc, c -> acc + c.encoded })
        val signedData = Der.seq(
            Der.int(1),
            Der.set(digestAlg),
            Der.seq(Der.oid(OID_DATA)),
            certificates,
            Der.set(signerInfo),
        )
        return Der.seq(Der.oid(OID_SIGNED_DATA), Der.explicit(0, signedData))
    }

    private fun isSignatureFile(name: String): Boolean {
        if (!name.startsWith("META-INF/") || name.indexOf('/', 9) >= 0) return false
        val upper = name.uppercase()
        return upper == "META-INF/MANIFEST.MF" || upper.endsWith(".SF") || upper.endsWith(".RSA") ||
            upper.endsWith(".DSA") || upper.endsWith(".EC") || upper.startsWith("META-INF/SIG-")
    }

    /** A manifest section: "Key: value" lines (wrapped at 72 bytes) followed by a blank line. */
    private fun section(attributes: List<Pair<String, String>>): ByteArray {
        val out = ByteArrayOutputStream()
        for ((k, v) in attributes) writeWrapped(out, "$k: $v".toByteArray(Charsets.UTF_8))
        out.write(CRLF)
        return out.toByteArray()
    }

    /** Manifest lines may be at most 72 bytes; continuation lines start with one space. */
    private fun writeWrapped(out: ByteArrayOutputStream, line: ByteArray) {
        var pos = 0
        var first = true
        while (pos < line.size) {
            val room = if (first) 72 else 71
            var end = minOf(pos + room, line.size)
            // Do not split a UTF-8 sequence.
            while (end < line.size && end > pos && (line[end].toInt() and 0xC0) == 0x80) end--
            if (!first) out.write(' '.code)
            out.write(line, pos, end - pos)
            out.write(CRLF)
            pos = end
            first = false
        }
    }

    private fun put(zos: ZipOutputStream, name: String, bytes: ByteArray) {
        zos.putNextEntry(ZipEntry(name).apply { method = ZipEntry.DEFLATED })
        zos.write(bytes)
        zos.closeEntry()
    }

    private fun sha256(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes)

    private val CRLF = byteArrayOf('\r'.code.toByte(), '\n'.code.toByte())
    private const val ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    internal fun base64(data: ByteArray): String {
        val sb = StringBuilder((data.size + 2) / 3 * 4)
        var i = 0
        while (i < data.size) {
            val b0 = data[i].toInt() and 0xff
            val b1 = if (i + 1 < data.size) data[i + 1].toInt() and 0xff else 0
            val b2 = if (i + 2 < data.size) data[i + 2].toInt() and 0xff else 0
            sb.append(ALPHABET[b0 shr 2])
            sb.append(ALPHABET[((b0 and 3) shl 4) or (b1 shr 4)])
            sb.append(if (i + 1 < data.size) ALPHABET[((b1 and 0xf) shl 2) or (b2 shr 6)] else '=')
            sb.append(if (i + 2 < data.size) ALPHABET[b2 and 0x3f] else '=')
            i += 3
        }
        return sb.toString()
    }
}
