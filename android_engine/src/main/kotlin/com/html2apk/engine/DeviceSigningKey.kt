package com.html2apk.engine

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.Date
import javax.security.auth.x500.X500Principal

/**
 * RSA signing key held in Android Keystore. The private key never leaves
 * the Keystore (and secure hardware where available), so it cannot be
 * exported or backed up: suitable for debug builds, not for Play releases.
 */
object DeviceSigningKey {
    fun getOrCreate(alias: String, commonName: String): Pair<PrivateKey, X509Certificate> {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!ks.containsAlias(alias)) {
            val now = System.currentTimeMillis()
            val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
                .setKeySize(2048)
                .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                .setCertificateSubject(X500Principal("CN=$commonName"))
                .setCertificateSerialNumber(BigInteger.valueOf(now))
                .setCertificateNotBefore(Date(now - 86_400_000L))
                .setCertificateNotAfter(Date(now + 25L * 365 * 86_400_000L))
                .build()
            KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore")
                .apply { initialize(spec) }
                .generateKeyPair()
        }
        val entry = ks.getEntry(alias, null) as KeyStore.PrivateKeyEntry
        return entry.privateKey to entry.certificate as X509Certificate
    }
}
