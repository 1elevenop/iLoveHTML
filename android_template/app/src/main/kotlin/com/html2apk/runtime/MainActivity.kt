package com.html2apk.runtime

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.window.OnBackInvokedDispatcher
import androidx.webkit.WebViewAssetLoader

class MainActivity : Activity() {

    private lateinit var webView: WebView
    private lateinit var progress: ProgressBar
    private lateinit var config: AppConfig

    /** Last main-frame URL that failed to load; the error page's "Try again" reloads it. */
    private var failedUrl: String? = null
    private val isDebuggable get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    // Bundled content is served from https://appassets.androidplatform.net/assets/...
    // so it gets a real https origin instead of file:// access.
    private val assetLoader by lazy {
        WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        config = AppConfig.load(this)
        WebView.setWebContentsDebuggingEnabled(isDebuggable)

        webView = WebView(this)
        setContentView(createRootLayout(webView))
        configureSettings(webView.settings)
        webView.webViewClient = WrapperWebViewClient()
        webView.webChromeClient = WrapperChromeClient()

        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) { handleBack() }
        }

        if (savedInstanceState == null || webView.restoreState(savedInstanceState) == null) {
            webView.loadUrl(startUrl())
        }
    }

    /**
     * Keeps web content clear of the status bar, navigation bar, display cutout
     * and keyboard. Android 15+ forces edge-to-edge for targetSdk 35+, so on
     * API 30+ we opt in explicitly and pad the root by the insets; the padding
     * area shows the root's background behind the system bars.
     */
    private fun createRootLayout(content: View): View {
        val root = FrameLayout(this)
        root.setBackgroundColor(SYSTEM_BAR_BACKGROUND)
        root.addView(content, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            visibility = View.GONE
        }
        val barHeight = (3 * resources.displayMetrics.density).toInt()
        root.addView(progress, FrameLayout.LayoutParams(MATCH_PARENT, barHeight, Gravity.TOP))
        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false)
            // Light icons on the dark bar background.
            window.insetsController?.setSystemBarsAppearance(
                0,
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                    WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS,
            )
            root.setOnApplyWindowInsetsListener { v, insets ->
                val bars = insets.getInsets(
                    WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout() or WindowInsets.Type.ime()
                )
                v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                WindowInsets.CONSUMED
            }
        }
        return root
    }

    private fun configureSettings(s: WebSettings) {
        s.javaScriptEnabled = config.javaScriptEnabled
        s.domStorageEnabled = config.domStorageEnabled
        // Secure defaults: no direct filesystem or content-provider access.
        s.allowFileAccess = false
        s.allowContentAccess = false
        s.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
        s.javaScriptCanOpenWindowsAutomatically = false
        s.setSupportMultipleWindows(false)
        config.userAgentSuffix?.let { s.userAgentString = "${s.userAgentString} $it" }
    }

    private fun startUrl(): String = when (config.sourceType) {
        AppConfig.SourceType.LOCAL -> "https://$ASSET_HOST/assets/www/${config.entry}"
        AppConfig.SourceType.REMOTE -> config.entry
    }

    private val startHost: String by lazy { Uri.parse(startUrl()).host.orEmpty().lowercase() }

    private fun isInternal(uri: Uri): Boolean {
        if (uri.scheme != "https") return false
        val host = uri.host?.lowercase() ?: return false
        // example.com and www.example.com are treated as the same site, since
        // sites commonly redirect between the two.
        return host == startHost || host == "www.$startHost" || "www.$host" == startHost ||
            host in config.allowedHosts
    }

    private fun openExternally(uri: Uri) {
        if (config.externalLinks == AppConfig.ExternalLinks.BLOCK) return
        if (uri.scheme !in EXTERNAL_SCHEMES) return
        try {
            startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
        } catch (_: ActivityNotFoundException) {
            Log.w(TAG, "No activity for ${uri.scheme} link")
        }
    }

    private fun handleBack() {
        if (webView.canGoBack()) webView.goBack() else finish()
    }

    @Deprecated("Used below API 33")
    override fun onBackPressed() {
        handleBack()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        webView.saveState(outState)
    }

    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }

    private inner class WrapperWebViewClient : WebViewClient() {
        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? =
            assetLoader.shouldInterceptRequest(request.url)

        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            val url = request.url
            // The bundled error page links here so "Try again" works even with JavaScript off.
            if (url.scheme == "https" && url.host == ASSET_HOST && url.path == RETRY_PATH) {
                view.loadUrl(failedUrl ?: startUrl())
                return true
            }
            if (isInternal(url)) return false
            if (request.isForMainFrame || request.hasGesture()) openExternally(url)
            return true
        }

        override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
            if (isDebuggable) Log.d(TAG, "Loading $url")
        }

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
            if (request.isForMainFrame) {
                Log.w(TAG, "Main frame error ${error.errorCode}: ${error.description}")
                failedUrl = request.url.toString()
                view.loadUrl("https://$ASSET_HOST/assets/html2apk/error.html")
            }
        }
    }

    private inner class WrapperChromeClient : WebChromeClient() {
        override fun onProgressChanged(view: WebView, newProgress: Int) {
            progress.progress = newProgress
            progress.visibility = if (newProgress in 1..99) View.VISIBLE else View.GONE
        }

        override fun onConsoleMessage(message: ConsoleMessage): Boolean {
            if (isDebuggable) {
                Log.i(TAG, "console ${message.messageLevel()}: ${message.message()} (${message.sourceId()}:${message.lineNumber()})")
            }
            return true
        }
    }

    companion object {
        private const val TAG = "HTML2APK"
        private const val ASSET_HOST = WebViewAssetLoader.DEFAULT_DOMAIN
        private const val RETRY_PATH = "/html2apk/retry"
        // Becomes configurable with status/navigation bar colors in the configuration editor.
        private const val SYSTEM_BAR_BACKGROUND = Color.BLACK
        private val EXTERNAL_SCHEMES = setOf("https", "http", "mailto", "tel", "sms", "geo")
    }
}
