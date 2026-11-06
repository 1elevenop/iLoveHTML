package com.html2apk.runtime

import android.app.Activity
import android.app.AlertDialog
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.ConsoleMessage
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.Toast
import android.window.OnBackInvokedDispatcher
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import androidx.webkit.WebViewAssetLoader

class MainActivity : Activity() {

    private lateinit var webView: WebView
    private lateinit var progress: ProgressBar
    private lateinit var config: AppConfig
    private var refresh: SwipeRefreshLayout? = null
    private var splashView: View? = null
    private var splashShownAt = 0L
    private val main = Handler(Looper.getMainLooper())

    /** Last main-frame URL that failed to load; "Try again" and pull-to-refresh reload it. */
    private var failedUrl: String? = null
    private var showingErrorPage = false
    private var fileCallback: ValueCallback<Array<Uri>>? = null
    private lateinit var bridge: PageBridge
    /** Time of the first back press on the first page, for "press back twice to exit". */
    private var backPressedAt = 0L
    /** Set when the back button returns to the start page; that page then drops the old history. */
    private var clearHistoryOnLoad = false
    /** The dark/light choice this activity was created with. */
    private var darkThemeApplied = false
    private var appLock: AppLock? = null
    private var notifications: NotificationBridge? = null
    private val isDebuggable get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    // Bundled content is served from https://appassets.androidplatform.net/assets/...
    // so it gets a real https origin instead of file:// access.
    private val assetLoader by lazy {
        WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        config = AppConfig.load(this)
        // Before super.onCreate and any view, so the window and the WebView use it.
        // From targetSdk 33 the WebView's prefers-color-scheme follows this theme.
        darkThemeApplied = useDarkTheme()
        setTheme(if (darkThemeApplied) android.R.style.Theme_Material_NoActionBar else android.R.style.Theme_Material_Light_NoActionBar)
        super.onCreate(savedInstanceState)
        if (config.keepScreenOn) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        WebView.setWebContentsDebuggingEnabled(isDebuggable)

        webView = WebView(this)
        val root = createRootLayout(showSplash = config.splash.enabled && savedInstanceState == null)
        setContentView(root)
        if (config.appLock) {
            appLock = AppLock(
                this, root, webView,
                backgroundColor = if (darkThemeApplied) Color.rgb(18, 18, 18) else Color.WHITE,
                textColor = if (darkThemeApplied) Color.WHITE else Color.rgb(30, 36, 48),
            ).also { it.start(savedInstanceState) }
        }
        configureSettings(webView.settings)
        webView.webViewClient = WrapperWebViewClient()
        webView.webChromeClient = WrapperChromeClient()
        bridge = PageBridge(this, webView, bridgeOrigins(), config)
        bridge.install()
        if (config.notifications) notifications = NotificationBridge(this, webView, bridgeOrigins()).also { it.install() }

        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) { handleBack() }
        }

        publishShortcuts()
        if (savedInstanceState == null || webView.restoreState(savedInstanceState) == null) {
            webView.loadUrl(shortcutUrl(intent) ?: startUrl())
        }
    }

    /**
     * Shortcuts from app_config.json become the icon's long-press menu.
     * Pinned copies of removed shortcuts are disabled so they cannot open
     * a page that is no longer offered.
     */
    private fun publishShortcuts() {
        if (Build.VERSION.SDK_INT < 25) return
        val manager = getSystemService(ShortcutManager::class.java) ?: return
        try {
            val icon = Icon.createWithResource(this, applicationInfo.icon)
            val wanted = config.shortcuts.take(manager.maxShortcutCountPerActivity).map { s ->
                ShortcutInfo.Builder(this, shortcutId(s.page))
                    .setShortLabel(s.label)
                    .setLongLabel(s.label)
                    .setIcon(icon)
                    .setIntent(
                        Intent(this, MainActivity::class.java)
                            .setAction(ACTION_SHORTCUT)
                            .putExtra(EXTRA_PAGE, s.page)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    )
                    .build()
            }
            manager.setDynamicShortcuts(wanted)
            val ids = wanted.map { it.id }.toSet()
            val stale = manager.pinnedShortcuts.map { it.id }.filter { it !in ids }
            if (stale.isNotEmpty()) manager.disableShortcuts(stale)
        } catch (e: RuntimeException) {
            // Rate limits or launcher quirks must never stop the app from opening.
            Log.w(TAG, "Shortcuts not published: $e")
        }
    }

    /**
     * The page a shortcut asks for. The activity is exported, so any app can
     * send this intent: only pages listed in the config are accepted, and
     * the result must still be a page the app keeps inside the WebView.
     */
    private fun shortcutUrl(intent: Intent?): String? {
        if (intent?.action != ACTION_SHORTCUT) return null
        val page = intent.getStringExtra(EXTRA_PAGE) ?: return null
        if (config.shortcuts.none { it.page == page }) return null
        val url = when (config.sourceType) {
            AppConfig.SourceType.LOCAL -> {
                val file = page.split('?', '#').first()
                if (file.isEmpty() || file.startsWith("/") || ':' in file || ".." in file.split('/') || '\\' in page) return null
                "https://$ASSET_HOST/assets/www/$page"
            }
            AppConfig.SourceType.REMOTE -> try {
                java.net.URI(startUrl()).resolve(page).toString()
            } catch (_: IllegalArgumentException) {
                return null
            }
        }
        return url.takeIf { isInternal(Uri.parse(it)) }
    }

    private fun shortcutId(page: String) = "page:" + page.hashCode().toUInt().toString(16)

    /**
     * Builds: screen (navigation bar colour) > content (padded by system bar,
     * cutout and keyboard insets) > [pull-to-refresh >] WebView, with a
     * status bar strip on top and the optional splash covering everything.
     * Android 15+ forces edge-to-edge for targetSdk 35+, so on API 30+ we opt
     * in explicitly and colour the inset areas ourselves.
     */
    private fun createRootLayout(showSplash: Boolean): FrameLayout {
        val screen = FrameLayout(this)
        screen.setBackgroundColor(config.navigationBarColor)

        val content = FrameLayout(this)
        val page: View = if (config.pullToRefresh) {
            SwipeRefreshLayout(this).apply {
                addView(webView, MATCH_PARENT, MATCH_PARENT)
                setOnRefreshListener { refreshPage() }
                refresh = this
            }
        } else webView
        content.addView(page, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            visibility = View.GONE
        }
        content.addView(progress, FrameLayout.LayoutParams(MATCH_PARENT, dp(3), Gravity.TOP))
        screen.addView(content, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))

        val statusStrip = View(this).apply { setBackgroundColor(config.statusBarColor) }
        screen.addView(statusStrip, FrameLayout.LayoutParams(MATCH_PARENT, 0, Gravity.TOP))

        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false)
            var lightIcons = 0
            if (isLight(config.statusBarColor)) lightIcons = lightIcons or WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
            if (isLight(config.navigationBarColor)) lightIcons = lightIcons or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(
                lightIcons,
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS,
            )
            if (config.fullscreen) {
                window.insetsController?.apply {
                    systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    hide(WindowInsets.Type.systemBars())
                }
            }
            screen.setOnApplyWindowInsetsListener { _, insets ->
                val bars = insets.getInsets(
                    WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout() or WindowInsets.Type.ime()
                )
                content.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                statusStrip.layoutParams = (statusStrip.layoutParams as FrameLayout.LayoutParams).apply { height = bars.top }
                WindowInsets.CONSUMED
            }
        } else {
            // Before Android 11 the window is not drawn behind the bars; colour them directly.
            @Suppress("DEPRECATION")
            window.statusBarColor = config.statusBarColor
            // Dark navigation-bar buttons only exist from Android 8; on 7.x a
            // light bar would leave the white buttons invisible, so use black.
            val lightNavSupported = Build.VERSION.SDK_INT >= 26
            val navColor = if (!lightNavSupported && isLight(config.navigationBarColor)) Color.BLACK else config.navigationBarColor
            @Suppress("DEPRECATION")
            window.navigationBarColor = navColor
            var flags = 0
            if (isLight(config.statusBarColor)) flags = flags or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            if (lightNavSupported && isLight(navColor)) flags = flags or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            if (config.fullscreen) flags = flags or LEGACY_FULLSCREEN_FLAGS
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = flags
        }

        if (showSplash) screen.addView(createSplash(), FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
        return screen
    }

    private fun createSplash(): View {
        val image = ImageView(this).apply { scaleType = ImageView.ScaleType.FIT_CENTER }
        val path = config.splash.image
        val bitmap = path?.let { decodeAsset(it, resources.displayMetrics.widthPixels) }
        val splash = FrameLayout(this).apply {
            setBackgroundColor(config.splash.backgroundColor)
            // Swallow touches so the page underneath cannot be tapped while hidden.
            isClickable = true
        }
        if (bitmap != null) {
            image.setImageBitmap(bitmap)
            splash.addView(image, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT).apply { setMargins(dp(32), dp(32), dp(32), dp(32)) })
        } else {
            image.setImageDrawable(packageManager.getApplicationIcon(applicationInfo))
            splash.addView(image, FrameLayout.LayoutParams(dp(128), dp(128), Gravity.CENTER))
        }
        splashView = splash
        splashShownAt = SystemClock.uptimeMillis()
        // Never leave the user stuck behind the splash.
        main.postDelayed({ hideSplash() }, SPLASH_MAX_MS)
        return splash
    }

    /** Decodes a bundled image, downsampled to roughly [targetWidth] to bound memory. */
    private fun decodeAsset(path: String, targetWidth: Int): Bitmap? = try {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        assets.open(path).use { BitmapFactory.decodeStream(it, null, bounds) }
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= targetWidth) sample *= 2
        assets.open(path).use { BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample }) }
    } catch (e: java.io.IOException) {
        Log.w(TAG, "Splash image unavailable: $e")
        null
    }

    private fun hideSplash() {
        val splash = splashView ?: return
        val wait = SPLASH_MIN_MS - (SystemClock.uptimeMillis() - splashShownAt)
        if (wait > 0) {
            main.postDelayed({ hideSplash() }, wait)
            return
        }
        splashView = null
        splash.animate().alpha(0f).setDuration(200).withEndAction { splash.visibility = View.GONE }.start()
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

    private fun errorPageUrl(): String =
        config.offlinePage?.let { "https://$ASSET_HOST/assets/www/$it" } ?: "https://$ASSET_HOST/assets/html2apk/error.html"

    private val startHost: String by lazy { Uri.parse(startUrl()).host.orEmpty().lowercase() }

    private fun isInternal(uri: Uri): Boolean {
        if (uri.scheme != "https") return false
        val host = uri.host?.lowercase() ?: return false
        // example.com and www.example.com are treated as the same site, since
        // sites commonly redirect between the two. Bundled pages (such as the
        // offline page) always stay inside the app.
        return host == startHost || host == "www.$startHost" || "www.$host" == startHost ||
            host in config.allowedHosts || host == ASSET_HOST
    }

    /** Origin rules for the page bridge: the same sites [isInternal] keeps in the app. */
    private fun bridgeOrigins(): Set<String> = buildSet {
        add("https://$ASSET_HOST")
        if (config.sourceType == AppConfig.SourceType.REMOTE) {
            add("https://$startHost")
            add(if (startHost.startsWith("www.")) "https://${startHost.removePrefix("www.")}" else "https://www.$startHost")
        }
        config.allowedHosts.forEach { add("https://$it") }
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

    /** Pull-to-refresh: retry a failed load, otherwise reload the current page. */
    private fun refreshPage() {
        if (showingErrorPage) webView.loadUrl(failedUrl ?: startUrl()) else webView.reload()
    }

    private fun useDarkTheme(): Boolean = when (config.theme) {
        AppConfig.Theme.LIGHT -> false
        AppConfig.Theme.DARK -> true
        AppConfig.Theme.SYSTEM -> isNightMode(resources.configuration)
    }

    private fun isNightMode(c: Configuration) =
        (c.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // uiMode is in configChanges, so the activity is not recreated on its own.
        // Recreate it when the phone's dark theme changes; the page state is saved.
        if (config.theme == AppConfig.Theme.SYSTEM && isNightMode(newConfig) != darkThemeApplied) recreate()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Dialogs, the keyboard and the share sheet can bring the bars back on Android 7-10.
        if (hasFocus && config.fullscreen && Build.VERSION.SDK_INT < 30) {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = window.decorView.systemUiVisibility or LEGACY_FULLSCREEN_FLAGS
        }
    }

    override fun onStart() {
        super.onStart()
        appLock?.onStart()
    }

    override fun onResume() {
        super.onResume()
        appLock?.onResume()
        notifications?.onResume()
    }

    /** Taps on the page's notifications arrive here while the app is running. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == NotificationBridge.ACTION_CLICK) notifications?.onClick(intent)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NotificationBridge.REQUEST_PERMISSION) {
            // An empty result means the request was interrupted, not answered.
            notifications?.onPermissionResult(
                granted = grantResults.firstOrNull() == android.content.pm.PackageManager.PERMISSION_GRANTED,
                answered = grantResults.isNotEmpty(),
            )
        }
    }

    override fun onStop() {
        appLock?.onStop()
        super.onStop()
    }

    private fun handleBack() {
        if (appLock?.locked == true) {
            finish()
            return
        }
        if (config.backButton == AppConfig.BackButton.HOME) {
            // No history also counts as the start page, so a start URL that
            // redirects elsewhere cannot trap the user in a reload loop.
            if (!webView.canGoBack() || isOnStartPage()) finish() else goHome()
            return
        }
        if (webView.canGoBack()) {
            webView.goBack()
            return
        }
        when (config.backButton) {
            AppConfig.BackButton.PRESS_TWICE_TO_EXIT -> {
                val now = SystemClock.uptimeMillis()
                if (now - backPressedAt < EXIT_WINDOW_MS) {
                    finish()
                } else {
                    backPressedAt = now
                    Toast.makeText(this, "Press back again to exit", Toast.LENGTH_SHORT).show()
                }
            }
            AppConfig.BackButton.CONFIRM_EXIT -> confirmExit()
            else -> finish()
        }
    }

    private fun isOnStartPage(): Boolean {
        val current = webView.url ?: return true
        return !showingErrorPage && current.substringBefore('#').trimEnd('/') == startUrl().trimEnd('/')
    }

    private fun goHome() {
        clearHistoryOnLoad = true
        webView.loadUrl(startUrl())
    }

    private fun confirmExit() {
        AlertDialog.Builder(this)
            .setMessage("Close the app?")
            .setPositiveButton("Close") { _, _ -> finish() }
            .setNegativeButton("Cancel", null)
            .show()
    }

    @Deprecated("Used below API 33")
    override fun onBackPressed() {
        handleBack()
    }

    @Deprecated("Platform Activity API; this app does not use AndroidX Activity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == AppLock.REQUEST_UNLOCK) {
            appLock?.onUnlockResult(resultCode)
            return
        }
        if (requestCode != REQUEST_FILE) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val callback = fileCallback ?: return
        fileCallback = null
        val uris: Array<Uri>? = if (resultCode == RESULT_OK && data != null) {
            val clip = data.clipData
            if (clip != null && clip.itemCount > 0) Array(clip.itemCount) { clip.getItemAt(it).uri }
            else WebChromeClient.FileChooserParams.parseResult(resultCode, data)
        } else null
        callback.onReceiveValue(uris)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        webView.saveState(outState)
        appLock?.save(outState)
    }

    override fun onDestroy() {
        main.removeCallbacksAndMessages(null)
        appLock?.onDestroy()
        fileCallback?.onReceiveValue(null)
        bridge.destroy()
        webView.destroy()
        super.onDestroy()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun isLight(color: Int) = Color.luminance(color) > 0.5f

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
            showingErrorPage = url == errorPageUrl()
            if (isDebuggable) Log.d(TAG, "Loading $url")
        }

        override fun onPageFinished(view: WebView, url: String) {
            if (clearHistoryOnLoad) {
                clearHistoryOnLoad = false
                view.clearHistory()
            }
            refresh?.isRefreshing = false
            hideSplash()
        }

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
            if (request.isForMainFrame) {
                Log.w(TAG, "Main frame error ${error.errorCode}: ${error.description}")
                failedUrl = request.url.toString()
                refresh?.isRefreshing = false
                view.loadUrl(errorPageUrl())
            }
        }
    }

    private inner class WrapperChromeClient : WebChromeClient() {
        override fun onProgressChanged(view: WebView, newProgress: Int) {
            progress.progress = newProgress
            progress.visibility = if (newProgress in 1..99) View.VISIBLE else View.GONE
        }

        override fun onShowFileChooser(
            view: WebView,
            callback: ValueCallback<Array<Uri>>,
            params: FileChooserParams,
        ): Boolean {
            if (!config.fileUploads) return false
            fileCallback?.onReceiveValue(null)
            val intent = params.createIntent()
            if (params.mode == FileChooserParams.MODE_OPEN_MULTIPLE) intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            return try {
                @Suppress("DEPRECATION")
                startActivityForResult(intent, REQUEST_FILE)
                fileCallback = callback
                true
            } catch (_: ActivityNotFoundException) {
                Log.w(TAG, "No file picker available")
                false
            }
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
        private const val REQUEST_FILE = 4201
        private const val SPLASH_MIN_MS = 600L
        private const val SPLASH_MAX_MS = 8000L
        private const val EXIT_WINDOW_MS = 2000L
        private const val ACTION_SHORTCUT = "com.html2apk.runtime.OPEN_SHORTCUT"
        private const val EXTRA_PAGE = "page"
        @Suppress("DEPRECATION")
        private const val LEGACY_FULLSCREEN_FLAGS = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
        private val EXTERNAL_SCHEMES = setOf("https", "http", "mailto", "tel", "sms", "geo")
    }
}
