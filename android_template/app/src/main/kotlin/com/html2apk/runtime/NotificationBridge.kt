package com.html2apk.runtime

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.webkit.WebView
import androidx.core.app.NotificationCompat
import androidx.webkit.JavaScriptReplyProxy
import androidx.webkit.ScriptHandler
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONObject

/**
 * The web `Notification` API for pages inside the app, shown as Android
 * notifications. Works while the app is open; there is no push and no
 * service-worker `showNotification`.
 *
 * Like [PageBridge], the page can only reach this through a
 * WebMessageListener limited to the app's own [origins]. On Android 13+ the
 * first `Notification.requestPermission()` asks for POST_NOTIFICATIONS; a
 * "no" is remembered as `denied` until the user allows it in Settings.
 * Tapping a notification brings the app to the front and fires `click` on
 * the page that made it, if that page is still open.
 */
class NotificationBridge(
    private val activity: Activity,
    private val webView: WebView,
    private val origins: Set<String>,
) {
    private class Shown(val reply: JavaScriptReplyProxy, val pageId: Int, val tag: String?, val id: Int)

    private val manager = activity.getSystemService(NotificationManager::class.java)
    private val prefs = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private var script: ScriptHandler? = null
    private var injectedState: String? = null
    private val waiting = mutableListOf<Pair<JavaScriptReplyProxy, Int>>()
    private var lastShownAt = 0L
    private var nextKey = 1

    /** Keys restart at 1 each run; this stops a tap on an older run's notification matching a new one. */
    private val session = java.util.UUID.randomUUID().toString()

    /** Notifications shown in this run, by key, oldest first; kept small. */
    private val shown = object : LinkedHashMap<Int, Shown>() {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Int, Shown>?) = size > MAX_TRACKED
    }

    /** Call before the first page load. */
    fun install() {
        if (manager == null ||
            !WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER) ||
            !WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)
        ) return
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Notifications", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
        WebViewCompat.addWebMessageListener(webView, JS_OBJECT, origins) { _, message, _, _, reply ->
            onMessage(message, reply)
        }
        injectScript()
    }

    /** The user may have changed the setting in Android's Settings meanwhile. */
    fun onResume() {
        if (script != null && state() != injectedState) injectScript()
    }

    fun onPermissionResult(granted: Boolean, answered: Boolean) {
        if (answered && !granted) prefs.edit().putBoolean(KEY_DENIED, true).apply()
        val s = state()
        waiting.forEach { (reply, id) -> post(reply, JSONObject().put("type", "permission").put("id", id).put("state", s)) }
        waiting.clear()
        injectScript()
    }

    /** A tap on one of our notifications ([ACTION_CLICK] intent). */
    fun onClick(intent: Intent) {
        if (intent.getStringExtra(EXTRA_SESSION) != session) return
        val entry = shown[intent.getIntExtra(EXTRA_KEY, 0)] ?: return
        post(entry.reply, JSONObject().put("type", "click").put("id", entry.pageId))
    }

    private fun granted(): Boolean {
        val m = manager ?: return false
        if (!m.areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 33 ||
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    /** `Notification.permission` for the page: granted, denied or default. */
    private fun state(): String = when {
        granted() -> "granted"
        // Before Android 13 there is no prompt: off means the user turned it off in Settings.
        Build.VERSION.SDK_INT < 33 -> "denied"
        prefs.getBoolean(KEY_DENIED, false) -> "denied"
        else -> "default"
    }

    private fun injectScript() {
        script?.remove()
        val s = state()
        injectedState = s
        script = WebViewCompat.addDocumentStartJavaScript(webView, PAGE_JS.replace("__STATE__", s), origins)
    }

    private fun onMessage(message: WebMessageCompat, reply: JavaScriptReplyProxy) {
        val json = try {
            JSONObject(message.data ?: return)
        } catch (_: org.json.JSONException) {
            return
        }
        val id = json.optInt("id")
        when (json.optString("type")) {
            "permission" -> requestPermission(reply, id)
            "show" -> show(reply, id, json)
            "close" -> shown.remove(json.optInt("key"))?.let { manager?.cancel(it.tag, it.id) }
        }
    }

    private fun requestPermission(reply: JavaScriptReplyProxy, id: Int) {
        val s = state()
        if (s != "default" || Build.VERSION.SDK_INT < 33) {
            post(reply, JSONObject().put("type", "permission").put("id", id).put("state", s))
            return
        }
        waiting += reply to id
        if (waiting.size == 1) activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_PERMISSION)
    }

    private fun show(reply: JavaScriptReplyProxy, pageId: Int, json: JSONObject) {
        val now = SystemClock.uptimeMillis()
        val title = json.optString("title").take(MAX_TITLE)
        if (!granted() || now - lastShownAt < MIN_INTERVAL_MS || title.isBlank()) {
            post(reply, JSONObject().put("type", "error").put("id", pageId))
            return
        }
        lastShownAt = now
        val tag = json.optString("tag").take(MAX_TAG).ifBlank { null }
        val key = nextKey++
        // With a tag, a new notification replaces the old one with the same tag, as on the web.
        val notificationId = if (tag != null) 0 else key
        val open = Intent(activity, activity.javaClass)
            .setAction(ACTION_CLICK)
            .putExtra(EXTRA_KEY, key)
            .putExtra(EXTRA_SESSION, session)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pending = PendingIntent.getActivity(
            activity, key, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val body = json.optString("body").take(MAX_BODY)
        val notification = NotificationCompat.Builder(activity, CHANNEL)
            .setSmallIcon(activity.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pending)
            .setAutoCancel(true)
            .build()
        try {
            manager?.notify(tag, notificationId, notification)
        } catch (_: SecurityException) {
            post(reply, JSONObject().put("type", "error").put("id", pageId))
            return
        }
        shown[key] = Shown(reply, pageId, tag, notificationId)
        post(reply, JSONObject().put("type", "shown").put("id", pageId).put("key", key))
    }

    private fun post(reply: JavaScriptReplyProxy, json: JSONObject) {
        try {
            reply.postMessage(json.toString())
        } catch (_: IllegalStateException) {
            // The page that asked has gone.
        }
    }

    companion object {
        const val REQUEST_PERMISSION = 4203
        const val ACTION_CLICK = "com.html2apk.runtime.NOTIFICATION_CLICK"
        private const val EXTRA_KEY = "key"
        private const val EXTRA_SESSION = "session"
        private const val JS_OBJECT = "html2apkNotify"
        private const val CHANNEL = "html2apk_default"
        private const val PREFS = "html2apk"
        private const val KEY_DENIED = "notificationsDenied"
        private const val MIN_INTERVAL_MS = 500L
        private const val MAX_TRACKED = 50
        private const val MAX_TITLE = 200
        private const val MAX_BODY = 2000
        private const val MAX_TAG = 100

        /** Defines window.Notification; __STATE__ is the permission when the page starts. */
        private const val PAGE_JS = """
(function () {
  var b = window.html2apkNotify;
  if (!b || typeof EventTarget === 'undefined') return;
  var state = '__STATE__', seq = 0, waits = {}, live = {};
  var fire = function (n, type) {
    var e = new Event(type);
    n.dispatchEvent(e);
    var h = n['on' + type];
    if (typeof h === 'function') { try { h.call(n, e); } catch (x) { setTimeout(function () { throw x; }); } }
  };
  class Notification extends EventTarget {
    constructor(title, options) {
      super();
      if (arguments.length === 0) throw new TypeError("Failed to construct 'Notification': 1 argument required");
      var o = options || {};
      this.title = String(title);
      this.body = o.body == null ? '' : String(o.body);
      this.tag = o.tag == null ? '' : String(o.tag);
      this.icon = o.icon == null ? '' : String(o.icon);
      this.data = o.data === undefined ? null : o.data;
      this.onclick = null; this.onshow = null; this.onclose = null; this.onerror = null;
      var self = this, id = ++seq;
      Object.defineProperty(this, '_id', { value: id });
      this._key = 0;
      if (state !== 'granted') { setTimeout(function () { fire(self, 'error'); }); return; }
      live[id] = self;
      b.postMessage(JSON.stringify({ type: 'show', id: id, title: this.title, body: this.body, tag: this.tag }));
    }
    close() { if (this._key) b.postMessage(JSON.stringify({ type: 'close', key: this._key })); }
    static get permission() { return state; }
    static requestPermission(callback) {
      return new Promise(function (resolve) {
        var done = function (s) { if (typeof callback === 'function') callback(s); resolve(s); };
        if (state !== 'default') return done(state);
        var id = ++seq;
        waits[id] = done;
        b.postMessage(JSON.stringify({ type: 'permission', id: id }));
      });
    }
  }
  Notification.maxActions = 0;
  window.Notification = Notification;
  b.onmessage = function (e) {
    var m; try { m = JSON.parse(e.data); } catch (x) { return; }
    if (m.type === 'permission') {
      state = m.state;
      var w = waits[m.id]; if (w) { delete waits[m.id]; w(m.state); }
      return;
    }
    var n = live[m.id]; if (!n) return;
    if (m.type === 'shown') { n._key = m.key; fire(n, 'show'); }
    else if (m.type === 'error') { delete live[m.id]; fire(n, 'error'); }
    else if (m.type === 'click') { fire(n, 'click'); }
  };
})();
"""
    }
}
