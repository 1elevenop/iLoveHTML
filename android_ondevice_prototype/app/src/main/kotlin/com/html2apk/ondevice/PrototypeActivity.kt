package com.html2apk.ondevice

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.html2apk.engine.ApkAssembler
import com.html2apk.engine.AppSpec
import com.html2apk.engine.BaseInfo
import com.html2apk.engine.DeviceSigningKey
import org.json.JSONObject
import java.io.File
import kotlin.concurrent.thread

/**
 * Feasibility prototype: builds an installable APK for the bundled demo site
 * entirely on this device and reports timings and memory.
 *
 * Start with `am start -n com.html2apk.ondevice/.PrototypeActivity --ez autorun true`.
 */
class PrototypeActivity : Activity() {

    private lateinit var output: TextView
    private val main = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        output = TextView(this).apply { setTextIsSelectable(true); setPadding(32, 32, 32, 32) }
        val button = Button(this).apply { text = "Build demo APK on this device" }
        button.setOnClickListener { run() }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            fitsSystemWindows = true
            addView(button)
            addView(ScrollView(context).apply { addView(output) })
        })
        if (savedInstanceState == null && intent.getBooleanExtra("autorun", false)) run()
    }

    private fun log(line: String) {
        Log.i(TAG, line)
        main.post { output.append(line + "\n") }
    }

    private fun run() = thread(name = "assembler") {
        val sampler = HeapSampler().also { it.start() }
        val timings = ApkAssembler.Timings()
        val result = JSONObject()
        try {
            log("Device: ${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT}), ${Build.SUPPORTED_ABIS.first()}")
            val work = File(cacheDir, "assembler").apply { deleteRecursively(); mkdirs() }
            val base = File(work, "base.apk")
            timings.step("extract base") { assets.open("base/base.apk").use { i -> base.outputStream().use { i.copyTo(it) } } }
            val info = JSONObject(assets.open("base/base_info.json").bufferedReader().readText())
            val baseInfo = BaseInfo(info.getString("basePackage"), info.getString("iconEntry"))

            val config = JSONObject()
                .put("schemaVersion", 1)
                .put("source", JSONObject().put("type", "local").put("entry", "index.html"))
                .put("javaScriptEnabled", true)
                .put("domStorageEnabled", true)
                .put("externalLinks", "browser")
                .put("allowedHosts", org.json.JSONArray())
                .put("userAgentSuffix", JSONObject.NULL)
            val spec = AppSpec(
                applicationId = "com.html2apk.ondevice.demo",
                label = "On-Device Demo",
                versionCode = 7,
                versionName = "2.0-ondevice",
                screenOrientation = 1,
                permissions = listOf("android.permission.INTERNET"),
                configJson = config.toString(2),
                iconPng = assets.open("input/icon.png").use { it.readBytes() },
            )

            val assembler = ApkAssembler(base, baseInfo)
            val unsigned = File(work, "unsigned.apk")
            timings.step("assemble total") {
                val site = timings.step("read website") { assets.open("input/demo-site.zip").use { ApkAssembler.websiteFromZip(it) } }
                assembler.assembleUnsigned(site, spec, unsigned, timings)
            }
            val (key, cert) = timings.step("signing key") { DeviceSigningKey.getOrCreate(KEY_ALIAS, "HTML2APK On-Device Prototype") }
            val outDir = getExternalFilesDir(null) ?: filesDir
            val signed = File(outDir, "generated.apk")
            val verify = assembler.sign(unsigned, signed, key, listOf(cert), timings)

            sampler.stop()
            log("Verified: ${verify.isVerified} (v2=${verify.isVerifiedUsingV2Scheme}, v3=${verify.isVerifiedUsingV3Scheme})")
            verify.errors.forEach { log("Verify error: $it") }
            for ((step, ms) in timings.steps) log("  $step: $ms ms")
            log("Output: ${signed.absolutePath} (${signed.length()} bytes)")
            log("Peak Java heap used: ${sampler.peak / 1024 / 1024} MB, process peak RSS (VmHWM): ${vmHwmKb() / 1024} MB")
            result.put("ok", verify.isVerified).put("output", signed.absolutePath).put("bytes", signed.length())
                .put("baseBytes", base.length()).put("peakHeapMb", sampler.peak / 1024 / 1024)
                .put("vmHwmMb", vmHwmKb() / 1024).put("timingsMs", JSONObject(timings.steps as Map<*, *>))
            unsigned.delete()
        } catch (t: Throwable) {
            sampler.stop()
            Log.e(TAG, "Build failed", t)
            log("FAILED: $t")
            result.put("ok", false).put("error", t.toString())
        }
        File(getExternalFilesDir(null) ?: filesDir, "result.json").writeText(result.toString(2))
        log("DONE")
    }

    private fun vmHwmKb(): Long = File("/proc/self/status").readLines()
        .firstOrNull { it.startsWith("VmHWM:") }?.split(Regex("\\s+"))?.get(1)?.toLong() ?: -1

    private class HeapSampler {
        @Volatile private var running = true
        @Volatile var peak = 0L
        fun start() = thread(isDaemon = true) {
            val rt = Runtime.getRuntime()
            while (running) {
                peak = maxOf(peak, rt.totalMemory() - rt.freeMemory())
                Thread.sleep(20)
            }
        }
        fun stop() { running = false }
    }

    companion object {
        private const val TAG = "H2A_PROTO"
        private const val KEY_ALIAS = "html2apk-prototype-signing"
    }
}
