package com.html2apk.engine

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
    /** Written to assets/branding/splash.png when present. */
    val splashPng: ByteArray? = null,
)

/** Metadata recorded when the base APK was built with Gradle. */
data class BaseInfo(val basePackage: String, val iconEntry: String)

/** One website file, opened lazily so large sites are streamed, not buffered. */
class WebsiteFile(val path: String, val size: Long, val open: () -> InputStream)

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

    /** Writes an unsigned APK with [site] and [spec] applied. */
    fun assembleUnsigned(site: List<WebsiteFile>, spec: AppSpec, out: File, timings: Timings) {
        validateWebsite(site)

        ZipFile(base).use { zip ->
            ZipOutputStream(out.outputStream().buffered()).use { zos ->
                for (entry in zip.entries()) {
                    val name = entry.name
                    when {
                        name.startsWith("assets/www/") -> continue
                        name.startsWith("assets/branding/") -> continue
                        name == "assets/app_config.json" -> continue
                        name.startsWith("META-INF/") && (name.endsWith(".SF") || name.endsWith(".RSA") ||
                            name.endsWith(".EC") || name.endsWith(".DSA") || name == "META-INF/MANIFEST.MF") -> continue
                        name == "AndroidManifest.xml" -> {
                            val bytes = zip.getInputStream(entry).use { it.readBytes() }
                            val patched = timings.step("patch manifest") { patchManifest(bytes, spec) }
                            putBytes(zos, name, patched, ZipEntry.DEFLATED)
                        }
                        name == baseInfo.iconEntry && spec.iconPng != null ->
                            putBytes(zos, name, spec.iconPng, entry.method)
                        entry.method == ZipEntry.STORED ->
                            putBytes(zos, name, zip.getInputStream(entry).use { it.readBytes() }, ZipEntry.STORED)
                        else -> putStream(zos, name) { zip.getInputStream(entry) }
                    }
                }
                putBytes(zos, "assets/app_config.json", spec.configJson.toByteArray(), ZipEntry.DEFLATED)
                spec.splashPng?.let { putBytes(zos, "assets/$SPLASH_ASSET", it, ZipEntry.STORED) }
                timings.step("add website") {
                    for (f in site) putStream(zos, "assets/www/${f.path}", f.open)
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
    fun sign(unsigned: File, out: File, key: PrivateKey, chain: List<X509Certificate>, timings: Timings): ApkVerifier.Result {
        timings.step("sign") {
            @Suppress("DEPRECATION") // Replacement takes a KeyConfig; migrate with the Phase 3 signing manager.
            val signer = ApkSigner.SignerConfig.Builder("CERT", key, chain).build()
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

    private fun putBytes(zos: ZipOutputStream, name: String, bytes: ByteArray, method: Int) {
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

    private fun putStream(zos: ZipOutputStream, name: String, open: () -> InputStream) {
        zos.putNextEntry(ZipEntry(name).apply { method = ZipEntry.DEFLATED })
        open().use { it.copyTo(zos) }
        zos.closeEntry()
    }

    companion object {
        const val MIN_SDK = 24

        /** Must match AndroidGenerator.splashAssetPath on the Dart side. */
        const val SPLASH_ASSET = "branding/splash.png"
        private const val MAX_FILES = 10_000
        private const val MAX_TOTAL_BYTES = 500L * 1024 * 1024

        /** Rejects unsafe, duplicate (case-insensitive) or oversized website file sets. */
        fun validateWebsite(site: List<WebsiteFile>) {
            val paths = HashSet<String>()
            for (f in site) {
                val normalized = normalize(f.path) ?: throw IllegalArgumentException("Unsafe path: ${f.path}")
                require(normalized == f.path) { "Path not normalized: ${f.path}" }
                require(paths.add(f.path.lowercase())) { "Duplicate: ${f.path}" }
            }
            require(site.size <= MAX_FILES && site.sumOf { it.size } <= MAX_TOTAL_BYTES) { "Website too large" }
        }

        /** Lists a website directory as normalized relative paths. */
        fun websiteFromDirectory(root: File): List<WebsiteFile> =
            root.walkTopDown().filter { it.isFile }.map { f ->
                val rel = f.relativeTo(root).invariantSeparatorsPath
                WebsiteFile(rel, f.length()) { f.inputStream() }
            }.sortedBy { it.path }.toList()

        /** Reads a website ZIP into memory (prototype input only). */
        fun websiteFromZip(input: InputStream): List<WebsiteFile> {
            val files = linkedMapOf<String, ByteArray>()
            ZipInputStream(input).use { zis ->
                while (true) {
                    val e = zis.nextEntry ?: break
                    if (e.isDirectory) continue
                    val path = normalize(e.name) ?: throw IllegalArgumentException("Unsafe path: ${e.name}")
                    if (path.startsWith("__MACOSX/") || path.endsWith(".DS_Store")) continue
                    files[path] = zis.readBytes()
                }
            }
            val tops = files.keys.map { it.substringBefore('/', "") }.toSet()
            val prefix = if (tops.size == 1 && tops.single().isNotEmpty()) tops.single() + "/" else ""
            return files.map { (p, b) -> WebsiteFile(p.removePrefix(prefix), b.size.toLong()) { b.inputStream() } }
        }

        /** Same rules as the Dart importer's normalizeRelativePath, minus Windows-only names. */
        fun normalize(raw: String): String? {
            val unified = raw.replace('\\', '/')
            if (unified.startsWith("/") || Regex("^[A-Za-z]:").containsMatchIn(unified)) return null
            val parts = unified.split('/').filter { it.isNotEmpty() && it != "." }
            if (parts.isEmpty() || parts.any { it == ".." || it.any { c -> c < ' ' } }) return null
            return parts.joinToString("/")
        }
    }
}
