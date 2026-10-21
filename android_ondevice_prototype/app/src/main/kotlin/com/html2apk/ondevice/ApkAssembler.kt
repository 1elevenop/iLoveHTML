package com.html2apk.ondevice

import com.android.apksig.ApkSigner
import com.android.apksig.ApkVerifier
import java.io.File
import java.io.InputStream
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/** What changes between the prebuilt base APK and a user's app. */
data class AppSpec(
    val applicationId: String,
    val label: String,
    val versionCode: Int,
    val versionName: String,
    /** -1 unspecified, 0 landscape, 1 portrait (ActivityInfo constants). */
    val screenOrientation: Int,
    val permissions: List<String>,
    val configJson: String,
    val iconPng: ByteArray?,
)

/** Metadata recorded when the base APK was built with Gradle. */
data class BaseInfo(val basePackage: String, val iconEntry: String)

/**
 * Turns the prebuilt wrapper APK into a user's app without a compiler:
 * swap website assets and config, rewrite the binary manifest, replace
 * the icon, then align + sign with apksig.
 */
class ApkAssembler(private val base: File, private val baseInfo: BaseInfo) {

    class Timings {
        val steps = linkedMapOf<String, Long>()
        inline fun <T> step(name: String, block: () -> T): T {
            val t0 = System.nanoTime()
            return block().also { steps[name] = (System.nanoTime() - t0) / 1_000_000 }
        }
    }

    /** Writes an unsigned APK with the website from [siteZip] and [spec] applied. */
    fun assembleUnsigned(siteZip: InputStream, spec: AppSpec, out: File, timings: Timings) {
        val site = timings.step("read website") { readWebsite(siteZip) }
        ZipFile(base).use { zip ->
            ZipOutputStream(out.outputStream().buffered()).use { zos ->
                for (entry in zip.entries()) {
                    val name = entry.name
                    when {
                        name.startsWith("assets/www/") -> continue
                        name == "assets/app_config.json" -> continue
                        // Old signatures would no longer match.
                        name.startsWith("META-INF/") && (name.endsWith(".SF") || name.endsWith(".RSA") ||
                            name.endsWith(".EC") || name.endsWith(".DSA") || name == "META-INF/MANIFEST.MF") -> continue
                        name == "AndroidManifest.xml" -> {
                            val bytes = zip.getInputStream(entry).use { it.readBytes() }
                            val patched = timings.step("patch manifest") { patchManifest(bytes, spec) }
                            put(zos, name, patched, ZipEntry.DEFLATED)
                        }
                        name == baseInfo.iconEntry && spec.iconPng != null ->
                            put(zos, name, spec.iconPng, entry.method)
                        else -> put(zos, name, zip.getInputStream(entry).use { it.readBytes() }, entry.method)
                    }
                }
                put(zos, "assets/app_config.json", spec.configJson.toByteArray(), ZipEntry.DEFLATED)
                timings.step("add website") {
                    for ((path, bytes) in site) put(zos, "assets/www/$path", bytes, ZipEntry.DEFLATED)
                }
            }
        }
    }

    fun patchManifest(bytes: ByteArray, spec: AppSpec): ByteArray {
        val doc = AxmlDocument.parse(bytes)
        val manifest = doc.elements("manifest").single()
        val pkg = requireNotNull(doc.plainAttribute(manifest, "package")) { "manifest@package missing" }
        check(doc.strings[pkg.rawValue] == baseInfo.basePackage) { "Unexpected base package" }
        doc.setString(pkg, spec.applicationId)
        doc.setInt(requireNotNull(doc.attribute(manifest, AxmlDocument.ATTR_VERSION_CODE)), spec.versionCode)
        doc.setString(requireNotNull(doc.attribute(manifest, AxmlDocument.ATTR_VERSION_NAME)), spec.versionName)

        val app = doc.elements("application").single()
        doc.setString(requireNotNull(doc.attribute(app, AxmlDocument.ATTR_LABEL)), spec.label)

        val activity = doc.elements("activity").single()
        doc.setInt(requireNotNull(doc.attribute(activity, AxmlDocument.ATTR_SCREEN_ORIENTATION)) {
            "Base manifest must declare android:screenOrientation"
        }, spec.screenOrientation)

        val manifestIndex = doc.nodes.indexOf(manifest)
        for (permission in spec.permissions.sortedDescending()) {
            doc.insertChildWithName(manifestIndex, "uses-permission", permission)
        }
        return doc.toByteArray()
    }

    /** Signs and aligns with apksig, then verifies the result. */
    fun sign(unsigned: File, out: File, key: PrivateKey, cert: X509Certificate, timings: Timings): ApkVerifier.Result {
        timings.step("sign") {
            val signer = ApkSigner.SignerConfig.Builder("CERT", key, listOf(cert)).build()
            ApkSigner.Builder(listOf(signer))
                .setInputApk(unsigned)
                .setOutputApk(out)
                .setMinSdkVersion(MIN_SDK)
                .setV1SigningEnabled(false)
                .setV2SigningEnabled(true)
                .setV3SigningEnabled(true)
                .build()
                .sign()
        }
        return timings.step("verify") { ApkVerifier.Builder(out).setMinCheckedPlatformVersion(MIN_SDK).build().verify() }
    }

    private fun put(zos: ZipOutputStream, name: String, bytes: ByteArray, method: Int) {
        val e = ZipEntry(name)
        e.method = method
        if (method == ZipEntry.STORED) {
            e.size = bytes.size.toLong()
            e.compressedSize = bytes.size.toLong()
            e.crc = CRC32().apply { update(bytes) }.value
        }
        zos.putNextEntry(e)
        zos.write(bytes)
        zos.closeEntry()
    }

    companion object {
        const val MIN_SDK = 24
        private const val MAX_FILES = 10_000
        private const val MAX_TOTAL_BYTES = 200L * 1024 * 1024

        /** Reads a website ZIP with the same path rules as the desktop importer. */
        fun readWebsite(input: InputStream): Map<String, ByteArray> {
            val files = linkedMapOf<String, ByteArray>()
            var total = 0L
            ZipInputStream(input).use { zis ->
                while (true) {
                    val e = zis.nextEntry ?: break
                    if (e.isDirectory) continue
                    val path = normalize(e.name) ?: throw IllegalArgumentException("Unsafe path: ${e.name}")
                    if (path.startsWith("__MACOSX/") || path.endsWith(".DS_Store")) continue
                    val bytes = zis.readBytes()
                    total += bytes.size
                    require(total <= MAX_TOTAL_BYTES && files.size < MAX_FILES) { "Website too large" }
                    require(files.keys.none { it.equals(path, ignoreCase = true) }) { "Duplicate: $path" }
                    files[path] = bytes
                }
            }
            // Strip a single top-level folder, as the desktop importer does.
            val tops = files.keys.map { it.substringBefore('/', "") }.toSet()
            return if (tops.size == 1 && tops.single().isNotEmpty()) {
                val prefix = tops.single() + "/"
                files.mapKeys { it.key.removePrefix(prefix) }
            } else files
        }

        private fun normalize(raw: String): String? {
            val unified = raw.replace('\\', '/')
            if (unified.startsWith("/") || Regex("^[A-Za-z]:").containsMatchIn(unified)) return null
            val parts = unified.split('/').filter { it.isNotEmpty() && it != "." }
            if (parts.isEmpty() || parts.any { it == ".." || it.any { c -> c < ' ' } }) return null
            return parts.joinToString("/")
        }
    }
}
