package com.html2apk.engine.bundle

import com.html2apk.engine.ApkAssembler
import com.html2apk.engine.AppSpec
import com.html2apk.engine.WebsiteFile
import com.html2apk.engine.providerAuthority
import java.io.File
import java.io.InputStream
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

/**
 * Builds an Android App Bundle (.aab) for Google Play from a prebuilt base
 * bundle of the wrapper (made once by Gradle's bundleRelease), the same way
 * [ApkAssembler] builds APKs: swap website, config, icon and splash; edit
 * the protobuf manifest; then JAR-sign ([JarSigner]), which is what Play
 * expects for AABs.
 */
class BundleAssembler(private val baseBundle: File, private val basePackage: String) {

    fun assembleUnsigned(site: List<WebsiteFile>, spec: AppSpec, out: File, timings: ApkAssembler.Timings) {
        // Same path rules and limits as APK assembly.
        ApkAssembler.validateWebsite(site)
        ZipFile(baseBundle).use { zip ->
            val iconEntry = zip.entries().asSequence().map { it.name }
                .firstOrNull { ICON_PATTERN.matches(it) }
            ZipOutputStream(out.outputStream().buffered()).use { zos ->
                for (entry in zip.entries()) {
                    val name = entry.name
                    when {
                        name.startsWith("base/assets/www/") || name.startsWith("base/assets/branding/") -> continue
                        name == "base/assets/app_config.json" -> continue
                        name.startsWith("META-INF/") -> continue // old signatures
                        name == MANIFEST -> {
                            val bytes = zip.getInputStream(entry).use { it.readBytes() }
                            put(zos, name, timings.step("patch manifest") { patchManifest(bytes, spec) })
                        }
                        name == iconEntry && spec.iconPng != null -> put(zos, name, spec.iconPng)
                        else -> putStream(zos, name) { zip.getInputStream(entry) }
                    }
                }
                put(zos, "base/assets/app_config.json", spec.configJson.toByteArray())
                spec.splashPng?.let { put(zos, "base/assets/${ApkAssembler.SPLASH_ASSET}", it) }
                timings.step("add website") {
                    for (f in site) putStream(zos, "base/assets/www/${f.path}", f.open)
                }
            }
        }
    }

    fun patchManifest(bytes: ByteArray, spec: AppSpec): ByteArray {
        val m = ProtoManifest(bytes)
        check(m.packageName == basePackage) { "Unexpected base package ${m.packageName}" }
        m.setPackage(spec.applicationId)
        m.setVersionCode(spec.versionCode)
        m.setVersionName(spec.versionName)
        m.setLabel(spec.label)
        m.setScreenOrientation(spec.screenOrientation)
        m.setProviderAuthority(providerAuthority(spec.applicationId))
        if (spec.permissions.isNotEmpty()) m.addPermissions(spec.permissions.sorted())
        return m.encode()
    }

    /** JAR (v1) signature with SHA-256, as produced by jarsigner and required for Play uploads. */
    fun sign(unsigned: File, out: File, key: PrivateKey, chain: List<X509Certificate>, timings: ApkAssembler.Timings) {
        timings.step("sign") { JarSigner.sign(unsigned, out, key, chain) }
    }

    /**
     * Verifies the JAR signature on every entry (as JarFile and streaming
     * readers see it) and returns the signing certificate.
     */
    fun verify(bundle: File): X509Certificate {
        var signer: X509Certificate? = null
        java.util.jar.JarInputStream(bundle.inputStream().buffered(), true).use { jis ->
            check(jis.manifest != null) { "Bundle has no JAR manifest" }
            while (true) {
                val entry = jis.nextJarEntry ?: break
                if (entry.isDirectory || entry.name.startsWith("META-INF/")) continue
                jis.readBytes() // signers are known only after the entry is read
                val cert = entry.codeSigners?.firstOrNull()?.signerCertPath?.certificates?.firstOrNull() as? X509Certificate
                    ?: throw SecurityException("${entry.name} is not signed")
                if (signer == null) signer = cert else check(cert == signer) { "Mixed signers in bundle" }
            }
        }
        return signer ?: throw SecurityException("Bundle has no signed entries")
    }

    private fun put(zos: ZipOutputStream, name: String, bytes: ByteArray) {
        zos.putNextEntry(ZipEntry(name).apply { method = ZipEntry.DEFLATED })
        zos.write(bytes)
        zos.closeEntry()
    }

    private fun putStream(zos: ZipOutputStream, name: String, open: () -> InputStream) {
        zos.putNextEntry(ZipEntry(name).apply { method = ZipEntry.DEFLATED })
        open().use { it.copyTo(zos) }
        zos.closeEntry()
    }

    companion object {
        const val MANIFEST = "base/manifest/AndroidManifest.xml"
        private val ICON_PATTERN = Regex("^base/res/drawable-nodpi[^/]*/app_icon\\.png$")
    }
}
