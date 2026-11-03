package com.html2apk.runtime

import android.app.Activity
import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.SystemClock
import android.provider.MediaStore
import android.util.Base64
import android.util.Log
import android.webkit.CookieManager
import android.webkit.MimeTypeMap
import android.webkit.URLUtil
import android.webkit.WebView
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import androidx.webkit.JavaScriptReplyProxy
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONObject
import java.io.File
import java.net.URLDecoder
import java.util.concurrent.Executors

/**
 * Web Share (`navigator.share`) and file downloads for the page.
 *
 * The only page-to-native channel is a WebMessageListener limited to the
 * app's own origins ([origins]); there is no addJavascriptInterface. Text
 * shares send text/plain through the system chooser. File shares accept only
 * images and PDFs: on Android 10+ they are saved to the gallery
 * (`Pictures/<folder>`, PDFs to `Download/<folder>`) and shared from there;
 * on Android 7-9 they are shared from the cache through a FileProvider.
 * Downloads use DownloadManager for https, and are written directly for
 * data: and blob: URLs.
 */
class PageBridge(
    private val activity: Activity,
    private val webView: WebView,
    private val origins: Set<String>,
    private val config: AppConfig,
) {
    private val share = config.webShare
    private val downloads = config.downloads
    private val shareFiles = config.shareFiles
    private val io = Executors.newSingleThreadExecutor()
    private var lastShareAt = 0L
    private var nextBlobId = 0

    /** blob: downloads waiting for the page to send their bytes, by request id. */
    private val pendingBlobs = mutableMapOf<Int, String>()

    /** Gallery folder for shared files: the project's choice, else the app name. */
    private val shareFolder: String by lazy {
        config.galleryFolder ?: ShareRules.folderName(activity.applicationInfo.loadLabel(activity.packageManager).toString()) ?: "Shared"
    }

    private class SharedFile(val name: String, val mime: String, val base64: String)

    /** Call before the first page load. */
    fun install() {
        if (!share && !downloads && !shareFiles) return
        if (downloads) {
            webView.setDownloadListener { url, _, disposition, mime, _ -> onDownload(url, disposition, mime) }
        }
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) return
        WebViewCompat.addWebMessageListener(webView, JS_OBJECT, origins) { _, message, _, _, reply ->
            onMessage(message, reply)
        }
        if (WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) {
            WebViewCompat.addDocumentStartJavaScript(webView, pageScript(), origins)
        }
    }

    fun destroy() {
        io.shutdownNow()
    }

    private fun onMessage(message: WebMessageCompat, reply: JavaScriptReplyProxy) {
        val json = try {
            JSONObject(message.data ?: return)
        } catch (_: org.json.JSONException) {
            return
        }
        when (json.optString("type")) {
            "share" -> if (share) {
                replyTo(reply, json.optInt("id"), shareText(json.optString("title"), json.optString("text"), json.optString("url")))
            }
            "shareFiles" -> {
                val id = json.optInt("id")
                val error = if (shareFiles) startFileShare(json, id, reply) else "NotAllowedError"
                if (error != null) replyTo(reply, id, error)
            }
            "blob" -> if (downloads) {
                val url = pendingBlobs.remove(json.optInt("id")) ?: return
                if (json.has("error")) {
                    toast("Download failed")
                    return
                }
                val name = fileName(json.optString("name").ifEmpty { null }, url, null, json.optString("mime"))
                saveDataUrl(json.optString("data"), name)
            }
        }
    }

    private fun replyTo(reply: JavaScriptReplyProxy, id: Int, error: String?) =
        reply.postMessage(JSONObject().put("id", id).put("error", error ?: JSONObject.NULL).toString())

    /** Returns null when the chooser opened, otherwise a DOMException name. */
    private fun shareText(title: String, text: String, url: String): String? {
        val now = SystemClock.uptimeMillis()
        if (now - lastShareAt < SHARE_INTERVAL_MS) return "NotAllowedError"
        val body = listOf(text, url).filter { it.isNotBlank() }.joinToString("\n")
        if (body.isEmpty() && title.isBlank()) return "DataError"
        if (body.length + title.length > MAX_SHARE_CHARS) return "DataError"
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, body.ifEmpty { title })
        if (title.isNotBlank()) send.putExtra(Intent.EXTRA_SUBJECT, title).putExtra(Intent.EXTRA_TITLE, title)
        return try {
            activity.startActivity(Intent.createChooser(send, title.ifBlank { null }))
            lastShareAt = now
            null
        } catch (_: ActivityNotFoundException) {
            "AbortError"
        }
    }

    /**
     * Checks a "shareFiles" message and stores the files off the UI thread.
     * Returns a DOMException name when it fails straight away; otherwise null,
     * and the reply is sent once the share sheet (or [AppConfig.shareTarget]) opened.
     */
    private fun startFileShare(json: JSONObject, id: Int, reply: JavaScriptReplyProxy): String? {
        val now = SystemClock.uptimeMillis()
        if (now - lastShareAt < SHARE_INTERVAL_MS) return "NotAllowedError"
        val list = json.optJSONArray("files") ?: return "DataError"
        if (list.length() !in 1..ShareRules.MAX_FILES) return "DataError"
        val files = mutableListOf<SharedFile>()
        var total = 0L
        for (i in 0 until list.length()) {
            val f = list.optJSONObject(i) ?: return "DataError"
            val mime = f.optString("mime").lowercase()
            if (!ShareRules.isShareable(mime)) return "NotAllowedError"
            val (_, isBase64, payload) = ShareRules.parseDataUrl(f.optString("data")) ?: return "DataError"
            if (!isBase64) return "DataError"
            total += ShareRules.base64Size(payload)
            if (total > ShareRules.MAX_BYTES) return "DataError"
            files += SharedFile(fileName(f.optString("name").ifEmpty { null }, "data:", null, mime), mime, payload)
        }
        val names = ShareRules.uniqueNames(files.map { it.name })
        val unique = files.mapIndexed { i, f -> SharedFile(names[i], f.mime, f.base64) }
        val title = json.optString("title")
        val body = listOf(json.optString("text"), json.optString("url")).filter { it.isNotBlank() }.joinToString("\n")
        if (body.length + title.length > MAX_SHARE_CHARS) return "DataError"
        lastShareAt = now
        io.execute {
            val uris = try {
                storeForShare(unique)
            } catch (e: Exception) {
                Log.w(TAG, "Saving shared files failed: $e")
                null
            }
            activity.runOnUiThread {
                if (activity.isDestroyed) return@runOnUiThread
                replyTo(reply, id, if (uris == null) "DataError" else openFileShare(uris, unique, title, body))
            }
        }
        return null
    }

    /** Runs on [io]. Returns content:// URIs the receiving app may read. */
    private fun storeForShare(files: List<SharedFile>): List<Uri> {
        if (Build.VERSION.SDK_INT >= 29) {
            return files.map { saveToGallery(it.name, it.mime, Base64.decode(it.base64, Base64.DEFAULT), shareFolder) }
        }
        val root = File(activity.cacheDir, "shared")
        // Earlier shares: the receiving apps have had a day to read them.
        val cutoff = System.currentTimeMillis() - SHARED_CACHE_MS
        root.listFiles()?.filter { it.lastModified() < cutoff }?.forEach { it.deleteRecursively() }
        val dir = File(root, System.currentTimeMillis().toString())
        if (!dir.mkdirs() && !dir.isDirectory) throw java.io.IOException("Cannot create $dir")
        return files.map {
            val file = File(dir, it.name)
            file.writeBytes(Base64.decode(it.base64, Base64.DEFAULT))
            FileProvider.getUriForFile(activity, "${activity.packageName}$PROVIDER_SUFFIX", file)
        }
    }

    /** Returns null when the target app or chooser opened, otherwise a DOMException name. */
    private fun openFileShare(uris: List<Uri>, files: List<SharedFile>, title: String, body: String): String? {
        val type = when {
            files.all { ShareRules.isImage(it.mime) } -> "image/*"
            files.all { it.mime == "application/pdf" } -> "application/pdf"
            else -> "*/*"
        }
        val send = if (uris.size == 1) Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
        else Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
        send.type = type
        send.clipData = ClipData("files", arrayOf(type), ClipData.Item(uris[0])).apply { uris.drop(1).forEach { addItem(ClipData.Item(it)) } }
        send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (body.isNotEmpty()) send.putExtra(Intent.EXTRA_TEXT, body)
        if (title.isNotBlank()) send.putExtra(Intent.EXTRA_SUBJECT, title)
        config.shareTarget?.let { target ->
            try {
                activity.startActivity(Intent(send).setPackage(target))
                return null
            } catch (_: ActivityNotFoundException) {
                // Not installed (or cannot receive these files): use the share sheet.
            }
        }
        return try {
            activity.startActivity(Intent.createChooser(send, title.ifBlank { null }))
            null
        } catch (_: ActivityNotFoundException) {
            "AbortError"
        }
    }

    private fun onDownload(url: String, disposition: String?, mime: String?) {
        val uri = Uri.parse(url)
        when (uri.scheme) {
            "https" -> enqueue(uri, disposition, mime)
            // The page knows the link's download name, so it sends the bytes.
            "data", "blob" -> requestBlob(url, mime)
            // http (no TLS) and anything else: not downloaded.
            else -> toast("This file can't be downloaded")
        }
    }

    private fun enqueue(uri: Uri, disposition: String?, mime: String?) {
        val url = uri.toString()
        val name = fileName(null, url, disposition, mime)
        val request = DownloadManager.Request(uri)
            .setTitle(name)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .addRequestHeader("User-Agent", webView.settings.userAgentString)
        CookieManager.getInstance().getCookie(url)?.let { request.addRequestHeader("Cookie", it) }
        if (!mime.isNullOrBlank()) request.setMimeType(mime)
        // Public Downloads needs no permission from Android 10; before that
        // the file goes to the app's own Downloads folder.
        if (Build.VERSION.SDK_INT >= 29) request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, name)
        else request.setDestinationInExternalFilesDir(activity, Environment.DIRECTORY_DOWNLOADS, name)
        try {
            (activity.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager).enqueue(request)
            toast("Downloading $name")
        } catch (e: RuntimeException) {
            // SecurityException without INTERNET, IllegalStateException without storage.
            Log.w(TAG, "Download not started: $e")
            toast("Download failed")
        }
    }

    /** Asks the page for a blob: or data: URL's bytes; it answers with a "blob" message. */
    private fun requestBlob(url: String, mime: String?) {
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) {
            if (url.startsWith("data:")) saveDataUrl(url, fileName(null, url, null, mime))
            else toast("This file can't be downloaded")
            return
        }
        val id = ++nextBlobId
        pendingBlobs[id] = url
        val args = listOf(JSONObject.quote(url), id.toString(), JSONObject.quote(mime.orEmpty()), ShareRules.MAX_BYTES.toString())
        webView.evaluateJavascript("window.$JS_OBJECT && window.$JS_OBJECT.sendBlob && window.$JS_OBJECT.sendBlob(${args.joinToString(",")})", null)
    }

    private fun saveDataUrl(dataUrl: String, name: String) {
        if (dataUrl.length > ShareRules.MAX_BYTES / 3 * 4 + 1024) {
            toast("File is too large to download")
            return
        }
        val (parsedMime, isBase64, payload) = ShareRules.parseDataUrl(dataUrl) ?: run {
            toast("Download failed")
            return
        }
        val mime = parsedMime.ifBlank { "application/octet-stream" }
        // With a gallery folder set, images go there instead of Downloads (Android 10+).
        val folder = config.galleryFolder?.takeIf { ShareRules.isImage(mime) && Build.VERSION.SDK_INT >= 29 }
        toast("Downloading $name")
        io.execute {
            val ok = try {
                val bytes = if (isBase64) Base64.decode(payload, Base64.DEFAULT)
                else URLDecoder.decode(payload.replace("+", "%2B"), "UTF-8").toByteArray()
                if (folder != null && Build.VERSION.SDK_INT >= 29) {
                    saveToGallery(name, mime, bytes, folder)
                    true
                } else writeToDownloads(name, mime, bytes)
            } catch (e: Exception) {
                Log.w(TAG, "Saving download failed: $e")
                false
            }
            activity.runOnUiThread { toast(if (ok) "Saved $name to ${folder ?: "Downloads"}" else "Download failed") }
        }
    }

    private fun writeToDownloads(name: String, mime: String, bytes: ByteArray): Boolean {
        if (Build.VERSION.SDK_INT >= 29) {
            insertMedia(MediaStore.Downloads.EXTERNAL_CONTENT_URI, null, name, mime, bytes)
            return true
        }
        val dir = activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: return false
        var file = File(dir, name)
        var n = 1
        while (file.exists()) file = File(dir, "${name.substringBeforeLast('.')} (${n++})" +
            (name.substringAfterLast('.', "").let { if (it.isEmpty()) "" else ".$it" }))
        file.writeBytes(bytes)
        return true
    }

    /**
     * Images to `Pictures/<folder>`, PDFs (and images the gallery refuses,
     * such as SVG) to `Download/<folder>`. Needs no storage permission.
     */
    @RequiresApi(29)
    private fun saveToGallery(name: String, mime: String, bytes: ByteArray, folder: String): Uri {
        if (ShareRules.isImage(mime)) {
            try {
                return insertMedia(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "${Environment.DIRECTORY_PICTURES}/$folder", name, mime, bytes)
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "Gallery refused $mime, saving to Downloads: $e")
            }
        }
        return insertMedia(MediaStore.Downloads.EXTERNAL_CONTENT_URI, "${Environment.DIRECTORY_DOWNLOADS}/$folder", name, mime, bytes)
    }

    /** Writes [bytes] as a new MediaStore item; null [relativePath] keeps the collection's default folder. */
    @RequiresApi(29)
    private fun insertMedia(collection: Uri, relativePath: String?, name: String, mime: String, bytes: ByteArray): Uri {
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            if (relativePath != null) put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val item = resolver.insert(collection, values) ?: throw java.io.IOException("MediaStore insert failed")
        try {
            resolver.openOutputStream(item)?.use { it.write(bytes) } ?: throw java.io.IOException("No output stream")
        } catch (e: Exception) {
            resolver.delete(item, null, null)
            throw e
        }
        resolver.update(item, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        return item
    }

    /**
     * Runs at document start in the app's own origins. Adds navigator.share
     * (text and links, plus image and PDF files), records the file name of
     * download links, and delays URL.revokeObjectURL so a blob is still
     * readable when the download starts.
     */
    private fun pageScript(): String = """
(function () {
  var bridge = window.$JS_OBJECT;
  if (!bridge) return;
  var pending = {}, seq = 0, names = {};
  bridge.onmessage = function (e) {
    var m; try { m = JSON.parse(e.data); } catch (x) { return; }
    var p = pending[m.id]; if (!p) return;
    delete pending[m.id];
    if (m.error) p.reject(new DOMException('Share failed', m.error)); else p.resolve();
  };
  ${if (share || shareFiles) "var TEXT = $share, FILES = $shareFiles, MAX_FILES = ${ShareRules.MAX_FILES}, MAX_BYTES = ${ShareRules.MAX_BYTES};$SHARE_JS" else ""}
  ${if (downloads) DOWNLOAD_JS else ""}
})();
"""

    private fun toast(text: String) = Toast.makeText(activity, text, Toast.LENGTH_SHORT).show()

    companion object {
        private const val TAG = "HTML2APK"
        private const val JS_OBJECT = "html2apkBridge"
        private const val SHARE_INTERVAL_MS = 1000L
        private const val MAX_SHARE_CHARS = 100_000
        private const val SHARED_CACHE_MS = 24 * 60 * 60 * 1000L

        /** Matches the FileProvider authority in the manifest: `<applicationId>.html2apk.files`. */
        private const val PROVIDER_SUFFIX = ".html2apk.files"

        /** A safe display name: no path separators or control characters. */
        fun fileName(suggested: String?, url: String, disposition: String?, mime: String?): String {
            // guessFileName would turn a data: or blob: URL's contents into the name.
            val opaque = url.startsWith("data:") || url.startsWith("blob:")
            val guessed = suggested ?: if (opaque) "download" else URLUtil.guessFileName(url, disposition, mime?.ifBlank { null })
            var name = ShareRules.sanitizeName(guessed)
            if ('.' !in name && !mime.isNullOrBlank()) {
                MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)?.let { name = ShareRules.sanitizeName("$name.$it") }
            }
            return name
        }

        private const val SHARE_JS = """
  var str = function (v) { return v == null ? '' : String(v); };
  var okFiles = function (files) {
    if (!FILES || files.length > MAX_FILES) return false;
    var total = 0;
    for (var i = 0; i < files.length; i++) {
      var f = files[i];
      if (!(f instanceof Blob) || !/^(image\/[a-z0-9][a-z0-9.+-]*|application\/pdf)$/.test(String(f.type).toLowerCase())) return false;
      total += f.size;
    }
    return total <= MAX_BYTES;
  };
  var nativeFiles = function () {
    try { return !!(navigator.canShare && navigator.canShare({ files: [new File([''], 'x.png', { type: 'image/png' })] })); } catch (x) { return false; }
  };
  var read = function (f) {
    return new Promise(function (resolve, reject) {
      var fr = new FileReader();
      fr.onload = function () { resolve({ name: str(f.name), mime: String(f.type).toLowerCase(), data: fr.result }); };
      fr.onerror = function () { reject(fr.error); };
      fr.readAsDataURL(f);
    });
  };
  if (!navigator.share || (FILES && !nativeFiles())) {
    navigator.canShare = function (d) {
      d = d || {};
      if (d.files && d.files.length) return okFiles(d.files);
      return TEXT && !!(d.title || d.text || d.url);
    };
    navigator.share = function (d) {
      return new Promise(function (resolve, reject) {
        d = d || {};
        var files = d.files && d.files.length ? Array.prototype.slice.call(d.files) : null;
        if (files ? !okFiles(files) : !TEXT) return reject(new DOMException(files ? 'These files cannot be shared' : 'Sharing is turned off', 'NotAllowedError'));
        var url = str(d.url);
        if (url) { try { url = new URL(url, location.href).href; } catch (x) { return reject(new TypeError('Invalid URL')); } }
        if (!files && !d.title && !d.text && !url) return reject(new TypeError('Nothing to share'));
        if (navigator.userActivation && !navigator.userActivation.isActive) return reject(new DOMException('Share needs a user gesture', 'NotAllowedError'));
        var id = ++seq;
        pending[id] = { resolve: resolve, reject: reject };
        var msg = { type: files ? 'shareFiles' : 'share', id: id, title: str(d.title), text: str(d.text), url: url };
        if (!files) return bridge.postMessage(JSON.stringify(msg));
        Promise.all(files.map(read)).then(function (list) {
          msg.files = list;
          bridge.postMessage(JSON.stringify(msg));
        }, function () {
          delete pending[id];
          reject(new DOMException('Could not read the files', 'DataError'));
        });
      });
    };
  }"""

        private const val DOWNLOAD_JS = """
  var remember = function (a) {
    if (a && a.href && /^(blob|data):/.test(a.href) && a.hasAttribute('download')) names[a.href] = a.getAttribute('download');
  };
  var click = HTMLAnchorElement.prototype.click;
  HTMLAnchorElement.prototype.click = function () { remember(this); return click.apply(this, arguments); };
  document.addEventListener('click', function (e) { remember(e.target && e.target.closest && e.target.closest('a')); }, true);
  var revoke = URL.revokeObjectURL;
  URL.revokeObjectURL = function (u) { setTimeout(function () { revoke.call(URL, u); }, 60000); };
  bridge.sendBlob = function (u, id, mime, max) {
    var fail = function () { bridge.postMessage(JSON.stringify({ type: 'blob', id: id, error: true })); };
    fetch(u).then(function (r) { return r.blob(); }).then(function (b) {
      if (b.size > max) return fail();
      var fr = new FileReader();
      fr.onload = function () {
        bridge.postMessage(JSON.stringify({ type: 'blob', id: id, name: names[u] || '', mime: b.type || mime, data: fr.result }));
      };
      fr.onerror = fail;
      fr.readAsDataURL(b);
    }).catch(fail);
  };"""
    }
}
