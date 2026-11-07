package com.html2apk.html2apk_app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import com.html2apk.engine.ApkAssembler
import com.html2apk.engine.AppSpec
import com.html2apk.engine.BaseInfo
import com.html2apk.engine.DeviceSigningKey
import com.html2apk.engine.SigningKeyStore
import com.html2apk.engine.bundle.BundleAssembler
import com.html2apk.engine.signing.DistinguishedName
import com.html2apk.engine.signing.KeystoreException
import com.html2apk.engine.signing.ReleaseKeystore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors

/**
 * Bridges the Flutter UI to the on-device build engine (ADR 0002) and to
 * Android install/share handoff. Only files inside the app's workspace
 * can be built from, written to, installed or shared.
 */
class EngineChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val workspace: File get() = File(activity.filesDir, "workspace").canonicalFile
    private val keys by lazy { SigningKeyStore(File(activity.filesDir, "signing")) }

    /** Save waiting for the user to pick a destination in the system "save" screen. */
    private var pendingSave: Pair<() -> java.io.InputStream, MethodChannel.Result>? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "engineInfo" -> result.success(engineInfo())
                "assemble" -> executor.execute {
                    val reply = runCatching { assemble(call) }
                    main.post {
                        reply.fold(result::success) { result.error("BUILD_FAILED", it.message ?: it.toString(), null) }
                    }
                }
                "keysList" -> result.success(keys.list().map { it.toMap() })
                "keysCreate", "keysInspect", "keysImport", "keysDelete" -> executor.execute {
                    // Key generation and keystore decryption are slow; keep them off the UI thread.
                    val reply = runCatching { keyOperation(call) }
                    main.post {
                        reply.fold(result::success) { e ->
                            result.error(if (e is KeystoreException) "KEYSTORE" else "KEY_ERROR", e.message ?: e.toString(), null)
                        }
                    }
                }
                "keysExport" -> exportKey(call.argument<String>("id")!!, result)
                "saveFile" -> {
                    val file = insideWorkspace(call.argument<String>("path")!!)
                    saveAs(file.name, call.argument<String>("mimeType")!!, { file.inputStream() }, result)
                }
                "installApk" -> result.success(install(insideWorkspace(call.argument<String>("path")!!)))
                "shareApk" -> { share(insideWorkspace(call.argument<String>("path")!!)); result.success(null) }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ENGINE_ERROR", e.message ?: e.toString(), null)
        }
    }

    private fun engineInfo(): Map<String, Any?> {
        val info = baseInfo()
        return mapOf(
            "engine" to "on-device",
            "basePackage" to info?.basePackage,
            "baseAvailable" to (info != null),
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "android" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "abi" to Build.SUPPORTED_ABIS.firstOrNull(),
        )
    }

    private fun baseInfo(): BaseInfo? = try {
        val j = JSONObject(activity.assets.open("base/base_info.json").bufferedReader().use { it.readText() })
        BaseInfo(j.getString("basePackage"), j.getString("iconEntry"), j.optString("bannerEntry").ifEmpty { null })
    } catch (_: java.io.IOException) {
        null
    }

    private fun assemble(call: MethodCall): Map<String, Any?> {
        val info = baseInfo() ?: error("This build of the app has no base APK. Run tools/build_ondevice_base.ps1.")
        val sourceDir = insideWorkspace(call.argument<String>("sourceDir")!!)
        val output = insideWorkspace(call.argument<String>("outputPath")!!)
        val iconPath = call.argument<String>("iconPath")
        val splashPath = call.argument<String>("splashPath")
        val spec = AppSpec(
            applicationId = call.argument<String>("applicationId")!!,
            label = call.argument<String>("label")!!,
            versionCode = call.argument<Int>("versionCode")!!,
            versionName = call.argument<String>("versionName")!!,
            screenOrientation = call.argument<Int>("screenOrientation")!!,
            permissions = call.argument<List<String>>("permissions")!!,
            configJson = call.argument<String>("configJson")!!,
            iconPng = iconPath?.let { insideWorkspace(it).readBytes() },
            splashPng = splashPath?.let { insideWorkspace(it).readBytes() },
            androidTv = call.argument<Boolean>("androidTv") ?: false,
            // Made by the Dart side from the icon and name; small (one 320x180 PNG).
            bannerPng = call.argument<ByteArray>("bannerPng"),
        )
        val timings = ApkAssembler.Timings()
        val work = File(activity.cacheDir, "assembler").apply { deleteRecursively(); mkdirs() }
        try {
            val base = File(work, "base.apk")
            timings.step("extract base") {
                activity.assets.open("base/base.apk").use { i -> base.outputStream().use { i.copyTo(it) } }
            }
            val site = timings.step("list website") { ApkAssembler.websiteFromDirectory(sourceDir) }
            val releaseKeyId = call.argument<String>("signingKeyId")
            if (call.argument<String>("format") == "aab") {
                return assembleBundle(work, site, spec, releaseKeyId, output, info, timings)
            }
            val unsigned = File(work, "unsigned.apk")
            val assembler = ApkAssembler(base, info)
            timings.step("assemble") { assembler.assembleUnsigned(site, spec, unsigned, timings) }
            val (key, chain) = timings.step("signing key") {
                if (releaseKeyId != null) keys.unlock(releaseKeyId).let { it.key to it.chain }
                else DeviceSigningKey.getOrCreate(DEBUG_KEY_ALIAS, "HTML2APK Debug (on-device)").let { it.first to listOf(it.second) }
            }
            val cert = chain.first()
            output.parentFile?.mkdirs()
            val tmp = File(output.path + ".tmp")
            val verify = assembler.sign(unsigned, tmp, key, chain, timings)
            if (!verify.isVerified) {
                tmp.delete()
                error("Signature verification failed: ${verify.errors.joinToString()}")
            }
            if (!tmp.renameTo(output)) { output.delete(); check(tmp.renameTo(output)) { "Could not write output" } }
            return mapOf(
                "outputPath" to output.path,
                "bytes" to output.length(),
                "files" to site.size,
                "timingsMs" to timings.steps.mapValues { it.value.toInt() },
                "signer" to cert.subjectX500Principal.name,
                "signerSha256" to ReleaseKeystore.fingerprint(cert),
                "v2" to verify.isVerifiedUsingV2Scheme,
                "v3" to verify.isVerifiedUsingV3Scheme,
            )
        } finally {
            work.deleteRecursively()
        }
    }

    /** Release App Bundle for Google Play: same inputs as an APK, JAR-signed with the release key. */
    private fun assembleBundle(
        work: File,
        site: List<com.html2apk.engine.WebsiteFile>,
        spec: AppSpec,
        releaseKeyId: String?,
        output: File,
        info: BaseInfo,
        timings: ApkAssembler.Timings,
    ): Map<String, Any?> {
        requireNotNull(releaseKeyId) { "App Bundles are for publishing and need a release key" }
        val base = File(work, "base.aab")
        timings.step("extract base") {
            activity.assets.open("base/base.aab").use { i -> base.outputStream().use { i.copyTo(it) } }
        }
        val assembler = BundleAssembler(base, info.basePackage)
        val unsigned = File(work, "unsigned.aab")
        timings.step("assemble") { assembler.assembleUnsigned(site, spec, unsigned, timings) }
        val key = timings.step("signing key") { keys.unlock(releaseKeyId) }
        output.parentFile?.mkdirs()
        val tmp = File(output.path + ".tmp")
        assembler.sign(unsigned, tmp, key.key, key.chain, timings)
        val signer = timings.step("verify") { assembler.verify(tmp) }
        check(ReleaseKeystore.fingerprint(signer) == ReleaseKeystore.fingerprint(key.certificate)) { "Bundle signed by an unexpected key" }
        if (!tmp.renameTo(output)) { output.delete(); check(tmp.renameTo(output)) { "Could not write output" } }
        return mapOf(
            "outputPath" to output.path,
            "bytes" to output.length(),
            "files" to site.size,
            "timingsMs" to timings.steps.mapValues { it.value.toInt() },
            "signer" to signer.subjectX500Principal.name,
            "signerSha256" to ReleaseKeystore.fingerprint(signer),
            "v2" to false,
            "v3" to false,
            "v1" to true,
        )
    }

    private fun keyOperation(call: MethodCall): Any? {
        fun password(name: String) = call.argument<String>(name)!!.toCharArray()
        return when (call.method) {
            "keysCreate" -> {
                val dn = try {
                    DistinguishedName(
                        commonName = call.argument<String>("commonName")!!.trim(),
                        organization = call.argument<String>("organization")?.trim()?.takeIf { it.isNotEmpty() },
                        country = call.argument<String>("country")?.trim()?.uppercase()?.takeIf { it.isNotEmpty() },
                    )
                } catch (e: IllegalArgumentException) {
                    throw KeystoreException(e.message ?: "Invalid name")
                }
                val pw = password("password")
                try { keys.create(call.argument<String>("alias")!!.trim(), dn, pw).toMap() } finally { pw.fill('\u0000') }
            }
            "keysInspect" -> {
                val pw = password("storePassword")
                try { keys.inspect(insideCache(call.argument<String>("path")!!), pw) } finally { pw.fill('\u0000') }
            }
            "keysImport" -> {
                val store = password("storePassword")
                val key = password("keyPassword")
                try {
                    keys.import(insideCache(call.argument<String>("path")!!), store, call.argument<String>("alias")!!, key).toMap()
                } finally {
                    store.fill('\u0000'); key.fill('\u0000')
                }
            }
            "keysDelete" -> { keys.delete(call.argument<String>("id")!!); null }
            else -> throw IllegalArgumentException(call.method)
        }
    }

    /** Opens the system "save as" screen; the keystore is written where the user chooses. */
    private fun exportKey(id: String, result: MethodChannel.Result) {
        val info = keys.info(id)
        val bytes = keys.exportBytes(id)
        saveAs("${info.alias}.jks", "application/octet-stream", { bytes.inputStream() }, result)
    }

    /** Lets the user choose where to save a file (e.g. Downloads or Drive). Result: the URI, or null if cancelled. */
    private fun saveAs(name: String, mimeType: String, source: () -> java.io.InputStream, result: MethodChannel.Result) {
        pendingSave?.second?.error("CANCELLED", "Another save started", null)
        pendingSave = source to result
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(mimeType)
            .putExtra(Intent.EXTRA_TITLE, name)
        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, REQUEST_EXPORT)
    }

    /** Called from MainActivity. Returns true when the result belonged to this channel. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_EXPORT) return false
        val (source, result) = pendingSave ?: return true
        pendingSave = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        executor.execute {
            val reply = runCatching {
                activity.contentResolver.openOutputStream(uri, "wt")!!.use { out -> source().use { it.copyTo(out) } }
                uri.toString()
            }
            main.post { reply.fold(result::success) { result.error("EXPORT_FAILED", it.message ?: it.toString(), null) } }
        }
        return true
    }

    /** Returns "started", or "needsPermission" after opening the settings page for the user. */
    private fun install(apk: File): String {
        if (!activity.packageManager.canRequestPackageInstalls()) {
            activity.startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}"))
            )
            return "needsPermission"
        }
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uriFor(apk), APK_MIME)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            activity.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            error("No installer available")
        }
        return "started"
    }

    private fun share(apk: File) {
        val send = Intent(Intent.ACTION_SEND)
            .setType(APK_MIME)
            .putExtra(Intent.EXTRA_STREAM, uriFor(apk))
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.startActivity(Intent.createChooser(send, apk.name))
    }

    private fun uriFor(file: File): Uri =
        FileProvider.getUriForFile(activity, "${activity.packageName}.files", file)

    private fun insideWorkspace(path: String): File {
        val f = File(path).canonicalFile
        require(f.path.startsWith(workspace.path + File.separator)) { "Path is outside the app workspace" }
        return f
    }

    /** Files picked for import are copied into the cache by the file picker. */
    private fun insideCache(path: String): File {
        val f = File(path).canonicalFile
        require(f.path.startsWith(activity.cacheDir.canonicalPath + File.separator)) { "Path is outside the app cache" }
        return f
    }

    fun dispose() = executor.shutdown()

    companion object {
        const val CHANNEL = "html2apk/engine"
        private const val APK_MIME = "application/vnd.android.package-archive"
        private const val DEBUG_KEY_ALIAS = "html2apk-debug-signing"
        private const val REQUEST_EXPORT = 4301
    }
}
