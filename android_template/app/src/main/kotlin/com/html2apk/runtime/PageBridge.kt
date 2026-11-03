package com.html2apk.runtime

import android.app.Activity
import android.app.DownloadManager
import android.content.ActivityNotFoundException
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
 * app's own origins ([origins]); there is no addJavascriptInterface. Shares
 * send text/plain through the system chooser. Downloads use DownloadManager
 * for https, and are written to Downloads directly for data: and blob: URLs.
 */
class PageBridge(
    private val activity: Activity,
    private val webView: WebView,
    private val origins: Set<String>,
    private val share: Boolean,
    private val downloads: Boolean,
) {
    private val io = Executors.newSingleThreadExecutor()
    private var lastShareAt = 0L
    private var nextBlobId = 0

    /** blob: downloads waiting for the page to send their bytes, by request id. */
    private val pendingBlobs = mutableMapOf<Int, String>()

    /** Call before the first page load. */
    fun install() {
        if (!share && !downloads) return
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
                val error = shareText(json.optString("title"), json.optString("text"), json.optString("url"))
                reply.postMessage(JSONObject().put("id", json.optInt("id")).put("error", error ?: JSONObject.NULL).toString())
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
        val args = listOf(JSONObject.quote(url), id.toString(), JSONObject.quote(mime.orEmpty()), MAX_DOWNLOAD_BYTES.toString())
        webView.evaluateJavascript("window.$JS_OBJECT && window.$JS_OBJECT.sendBlob && window.$JS_OBJECT.sendBlob(${args.joinToString(",")})", null)
    }

    private fun saveDataUrl(dataUrl: String, name: String) {
        if (dataUrl.length > MAX_DOWNLOAD_BYTES / 3 * 4 + 1024) {
            toast("File is too large to download")
            return
        }
        val comma = dataUrl.indexOf(',')
        if (!dataUrl.startsWith("data:") || comma < 0) {
            toast("Download failed")
            return
        }
        val meta = dataUrl.substring(5, comma)
        val mime = meta.substringBefore(';').ifBlank { "application/octet-stream" }
        val payload = dataUrl.substring(comma + 1)
        toast("Downloading $name")
        io.execute {
            val ok = try {
                val bytes = if (meta.endsWith(";base64")) Base64.decode(payload, Base64.DEFAULT)
                else URLDecoder.decode(payload.replace("+", "%2B"), "UTF-8").toByteArray()
                writeToDownloads(name, mime, bytes)
            } catch (e: Exception) {
                Log.w(TAG, "Saving download failed: $e")
                false
            }
            activity.runOnUiThread { toast(if (ok) "Saved $name to Downloads" else "Download failed") }
        }
    }

    private fun writeToDownloads(name: String, mime: String, bytes: ByteArray): Boolean {
        if (Build.VERSION.SDK_INT >= 29) {
            val resolver = activity.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val item = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return false
            try {
                resolver.openOutputStream(item)?.use { it.write(bytes) } ?: throw java.io.IOException("No output stream")
            } catch (e: Exception) {
                resolver.delete(item, null, null)
                throw e
            }
            resolver.update(item, ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }, null, null)
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
     * Runs at document start in the app's own origins. Adds navigator.share
     * (text and links only), records the file name of download links, and
     * delays URL.revokeObjectURL so a blob is still readable when the
     * download starts.
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
  ${if (share) SHARE_JS else ""}
  ${if (downloads) DOWNLOAD_JS else ""}
})();
"""

    private fun toast(text: String) = Toast.makeText(activity, text, Toast.LENGTH_SHORT).show()

    companion object {
        private const val TAG = "HTML2APK"
        private const val JS_OBJECT = "html2apkBridge"
        private const val SHARE_INTERVAL_MS = 1000L
        private const val MAX_SHARE_CHARS = 100_000
        private const val MAX_DOWNLOAD_BYTES = 20 * 1024 * 1024

        /** A safe display name: no path separators or control characters. */
        fun fileName(suggested: String?, url: String, disposition: String?, mime: String?): String {
            // guessFileName would turn a data: or blob: URL's contents into the name.
            val opaque = url.startsWith("data:") || url.startsWith("blob:")
            val guessed = suggested ?: if (opaque) "download" else URLUtil.guessFileName(url, disposition, mime?.ifBlank { null })
            var name = guessed.replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_").trim().trimStart('.')
            if (name.isEmpty()) name = "download"
            if ('.' !in name && !mime.isNullOrBlank()) {
                MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)?.let { name += ".$it" }
            }
            return name.take(120)
        }

        private const val SHARE_JS = """
  if (!navigator.share) {
    var str = function (v) { return v == null ? '' : String(v); };
    navigator.canShare = function (d) {
      d = d || {};
      if (d.files && d.files.length) return false;
      return !!(d.title || d.text || d.url);
    };
    navigator.share = function (d) {
      return new Promise(function (resolve, reject) {
        d = d || {};
        if (d.files && d.files.length) return reject(new DOMException('Sharing files is not supported', 'NotAllowedError'));
        var url = str(d.url);
        if (url) { try { url = new URL(url, location.href).href; } catch (x) { return reject(new TypeError('Invalid URL')); } }
        if (!d.title && !d.text && !url) return reject(new TypeError('Nothing to share'));
        if (navigator.userActivation && !navigator.userActivation.isActive) return reject(new DOMException('Share needs a user gesture', 'NotAllowedError'));
        var id = ++seq;
        pending[id] = { resolve: resolve, reject: reject };
        bridge.postMessage(JSON.stringify({ type: 'share', id: id, title: str(d.title), text: str(d.text), url: url }));
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
