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
        BaseInfo(j.getString("basePackage"), j.getString("iconEntry"))
    } catch (_: java.io.IOException) {
        null
    }

    private fun assemble(call: MethodCall): Map<String, Any?> {
        val info = baseInfo() ?: error("This build of the app has no base APK. Run tools/build_ondevice_base.ps1.")
        val sourceDir = insideWorkspace(call.argument<String>("sourceDir")!!)
        val output = insideWorkspace(call.argument<String>("outputPath")!!)
        val iconPath = call.argument<String>("iconPath")
        val spec = AppSpec(
            applicationId = call.argument<String>("applicationId")!!,
            label = call.argument<String>("label")!!,
            versionCode = call.argument<Int>("versionCode")!!,
            versionName = call.argument<String>("versionName")!!,
            screenOrientation = call.argument<Int>("screenOrientation")!!,
            permissions = call.argument<List<String>>("permissions")!!,
            configJson = call.argument<String>("configJson")!!,
            iconPng = iconPath?.let { insideWorkspace(it).readBytes() },
        )
        val timings = ApkAssembler.Timings()
        val work = File(activity.cacheDir, "assembler").apply { deleteRecursively(); mkdirs() }
        try {
            val base = File(work, "base.apk")
            timings.step("extract base") {
                activity.assets.open("base/base.apk").use { i -> base.outputStream().use { i.copyTo(it) } }
            }
            val site = timings.step("list website") { ApkAssembler.websiteFromDirectory(sourceDir) }
            val unsigned = File(work, "unsigned.apk")
            val assembler = ApkAssembler(base, info)
            timings.step("assemble") { assembler.assembleUnsigned(site, spec, unsigned, timings) }
            val (key, cert) = timings.step("signing key") {
                DeviceSigningKey.getOrCreate(DEBUG_KEY_ALIAS, "HTML2APK Debug (on-device)")
            }
            output.parentFile?.mkdirs()
            val tmp = File(output.path + ".tmp")
            val verify = assembler.sign(unsigned, tmp, key, cert, timings)
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
                "v2" to verify.isVerifiedUsingV2Scheme,
                "v3" to verify.isVerifiedUsingV3Scheme,
            )
        } finally {
            work.deleteRecursively()
        }
    }

    /** Returns "started", or "needsPermission" after opening the settings page for the user. */
    private fun install(apk: File): String {
        if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
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

    fun dispose() = executor.shutdown()

    companion object {
        const val CHANNEL = "html2apk/engine"
        private const val APK_MIME = "application/vnd.android.package-archive"
        private const val DEBUG_KEY_ALIAS = "html2apk-debug-signing"
    }
}
