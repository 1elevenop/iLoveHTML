package com.html2apk.engine

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import com.html2apk.engine.signing.DistinguishedName
import com.html2apk.engine.signing.KeystoreException
import com.html2apk.engine.signing.ReleaseKeystore
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.ByteBuffer
import java.nio.CharBuffer
import java.security.KeyStore
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Release keys kept on the phone, in the app's private storage:
 *
 *  - `<id>.p12`: the keystore itself (PKCS12, protected by the user's password);
 *    this exact file is what Export writes, so it can be used on Windows.
 *  - `keys.json`: certificate details plus the keystore password encrypted with
 *    an AES-GCM key that lives in Android Keystore and cannot be exported.
 *
 * Passwords are never written in plain text and never logged.
 */
class SigningKeyStore(private val dir: File) {

    data class KeyInfo(
        val id: String,
        val alias: String,
        val subject: String,
        val sha256: String,
        val sha1: String,
        val notAfter: Long,
        val createdAt: Long,
        val origin: String,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "id" to id, "alias" to alias, "subject" to subject, "sha256" to sha256, "sha1" to sha1,
            "notAfter" to notAfter, "createdAt" to createdAt, "origin" to origin,
        )
    }

    private val index = File(dir, "keys.json")

    fun list(): List<KeyInfo> = readIndex().map { it.first }

    fun create(alias: String, subject: DistinguishedName, password: CharArray): KeyInfo {
        if (list().any { it.alias.equals(alias, ignoreCase = true) }) throw KeystoreException("A key named \"$alias\" already exists")
        val bytes = ReleaseKeystore.generate(alias, subject, password)
        return save(bytes, password, alias, "created")
    }

    /** Aliases inside a keystore file the user picked, after checking its password. */
    fun inspect(file: File, storePassword: CharArray): List<String> =
        ReleaseKeystore.aliases(readLimited(file), storePassword)

    /**
     * Imports one key from a .jks / .keystore / .p12 file. The stored copy is
     * PKCS12 using [storePassword] for both the file and the key.
     */
    fun import(file: File, storePassword: CharArray, alias: String, keyPassword: CharArray): KeyInfo {
        val unlocked = ReleaseKeystore.unlockForImport(readLimited(file), storePassword, alias, keyPassword)
        val sha256 = ReleaseKeystore.fingerprint(unlocked.certificate)
        if (list().any { it.sha256 == sha256 }) throw KeystoreException("This key has already been imported")
        if (list().any { it.alias.equals(unlocked.alias, ignoreCase = true) }) {
            throw KeystoreException("A key named \"${unlocked.alias}\" already exists")
        }
        val p12 = ReleaseKeystore.toPkcs12(unlocked, storePassword, storePassword)
        return save(p12, storePassword, unlocked.alias, "imported")
    }

    /** Bytes of the stored keystore, exactly as it should be backed up. */
    fun exportBytes(id: String): ByteArray = keystoreFile(id).readBytes()

    fun info(id: String): KeyInfo = list().firstOrNull { it.id == id } ?: throw KeystoreException("Unknown key")

    fun unlock(id: String): ReleaseKeystore.Unlocked {
        val (info, secret) = readIndex().firstOrNull { it.first.id == id } ?: throw KeystoreException("Unknown key")
        val password = SecretBox.decrypt(secret)
        try {
            return ReleaseKeystore.unlock(exportBytes(id), password, info.alias, password)
        } finally {
            password.fill('\u0000')
        }
    }

    fun delete(id: String) {
        val entries = readIndex()
        if (entries.none { it.first.id == id }) throw KeystoreException("Unknown key")
        keystoreFile(id).delete()
        writeIndex(entries.filter { it.first.id != id })
    }

    private fun save(p12: ByteArray, password: CharArray, alias: String, origin: String): KeyInfo {
        dir.mkdirs()
        val unlocked = ReleaseKeystore.unlock(p12, password, alias, password)
        val cert = unlocked.certificate
        val info = KeyInfo(
            id = UUID.randomUUID().toString(),
            alias = unlocked.alias,
            subject = cert.subjectX500Principal.name,
            sha256 = ReleaseKeystore.fingerprint(cert),
            sha1 = ReleaseKeystore.fingerprint(cert, "SHA-1"),
            notAfter = cert.notAfter.time,
            createdAt = System.currentTimeMillis(),
            origin = origin,
        )
        val tmp = File(dir, "${info.id}.p12.tmp")
        tmp.writeBytes(p12)
        check(tmp.renameTo(keystoreFile(info.id))) { "Could not store keystore" }
        writeIndex(readIndex() + (info to SecretBox.encrypt(password)))
        return info
    }

    private fun keystoreFile(id: String): File {
        require(Regex("^[0-9a-f-]{36}$").matches(id)) { "Bad key id" }
        return File(dir, "$id.p12")
    }

    private fun readLimited(file: File): ByteArray {
        if (file.length() > MAX_KEYSTORE_BYTES) throw KeystoreException("That file is too large to be a keystore")
        return file.readBytes()
    }

    private fun readIndex(): List<Pair<KeyInfo, String>> {
        if (!index.exists()) return emptyList()
        val arr = JSONArray(index.readText())
        return List(arr.length()) { i ->
            val o = arr.getJSONObject(i)
            KeyInfo(
                o.getString("id"), o.getString("alias"), o.getString("subject"), o.getString("sha256"), o.getString("sha1"),
                o.getLong("notAfter"), o.getLong("createdAt"), o.getString("origin"),
            ) to o.getString("secret")
        }
    }

    private fun writeIndex(entries: List<Pair<KeyInfo, String>>) {
        val arr = JSONArray()
        for ((info, secret) in entries) arr.put(JSONObject(info.toMap()).put("secret", secret))
        val tmp = File(dir, "keys.json.tmp")
        tmp.writeText(arr.toString(2))
        check(tmp.renameTo(index)) { "Could not save key list" }
    }

    /** AES-GCM with a non-exportable Android Keystore key. Output: base64(iv || ciphertext). */
    private object SecretBox {
        private const val ALIAS = "html2apk-keystore-passwords"

        private fun key(): SecretKey {
            val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            (ks.getKey(ALIAS, null) as? SecretKey)?.let { return it }
            val spec = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply { init(spec) }.generateKey()
        }

        fun encrypt(chars: CharArray): String {
            val plain = Charsets.UTF_8.encode(CharBuffer.wrap(chars)).let { b -> ByteArray(b.remaining()).also { b.get(it) } }
            try {
                val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
                return Base64.encodeToString(cipher.iv + cipher.doFinal(plain), Base64.NO_WRAP)
            } finally {
                plain.fill(0)
            }
        }

        fun decrypt(blob: String): CharArray {
            val data = Base64.decode(blob, Base64.NO_WRAP)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, data, 0, 12))
            val plain = cipher.doFinal(data, 12, data.size - 12)
            try {
                val chars = Charsets.UTF_8.decode(ByteBuffer.wrap(plain))
                return CharArray(chars.remaining()).also { chars.get(it) }
            } finally {
                plain.fill(0)
            }
        }
    }

    companion object {
        private const val MAX_KEYSTORE_BYTES = 1024 * 1024
    }
}
