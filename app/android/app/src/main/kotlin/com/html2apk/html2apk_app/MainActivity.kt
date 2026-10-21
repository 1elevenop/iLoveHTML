package com.html2apk.html2apk_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var engineChannel: EngineChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = EngineChannel(this).also { engineChannel = it }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EngineChannel.CHANNEL).setMethodCallHandler(handler)
    }

    override fun onDestroy() {
        engineChannel?.dispose()
        super.onDestroy()
    }
}
