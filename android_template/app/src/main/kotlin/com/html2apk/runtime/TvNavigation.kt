package com.html2apk.runtime

import android.webkit.WebView
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature

/**
 * Remote-control navigation for Android TV. The WebView sends the remote's
 * arrow keys to the page but does not move focus between links, so most
 * sites cannot be used with a remote. This script moves focus to the
 * nearest link, button or field in the pressed direction, scrolls it into
 * view and draws a clear focus ring; OK presses the focused element.
 *
 * Pages that handle arrow keys themselves (games, players) keep working:
 * the script listens last (bubble phase on document) and skips events the
 * page already handled with preventDefault(). Text fields keep their own
 * left/right keys.
 */
object TvNavigation {

    /** Adds the script to every page the app keeps inside the WebView. */
    fun install(webView: WebView, origins: Set<String>): Boolean {
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) return false
        WebViewCompat.addDocumentStartJavaScript(webView, SCRIPT, origins)
        return true
    }

    /** For WebViews without document-start scripts: run after each page load. */
    fun runAfterLoad(webView: WebView) = webView.evaluateJavascript(SCRIPT, null)

    const val SCRIPT = """
(function () {
  if (window.__html2apkTv) return;
  window.__html2apkTv = true;
  var SELECTOR = 'a[href],button,input:not([type=hidden]),select,textarea,summary,iframe,' +
    '[tabindex]:not([tabindex="-1"]),[role=button],[role=link],[role=tab],[role=menuitem],[contenteditable=""],[contenteditable=true]';
  var addStyle = function () {
    var s = document.createElement('style');
    s.textContent = ':focus{outline:3px solid #4C8BF5 !important;outline-offset:2px !important}';
    (document.head || document.documentElement).appendChild(s);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', addStyle); else addStyle();

  var usable = function (el) {
    if (el.disabled) return false;
    var r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) return false;
    var cs = getComputedStyle(el);
    return cs.visibility !== 'hidden' && cs.display !== 'none';
  };
  var onScreen = function (r) { return r.bottom > 0 && r.top < innerHeight && r.right > 0 && r.left < innerWidth; };

  var move = function (key) {
    var all = Array.prototype.filter.call(document.querySelectorAll(SELECTOR), usable);
    var cur = document.activeElement;
    if (!cur || cur === document.body || all.indexOf(cur) < 0) {
      var first = all.filter(function (el) { return onScreen(el.getBoundingClientRect()); })[0];
      if (first) { first.focus(); return true; }
      return false;
    }
    var a = cur.getBoundingClientRect();
    var ax = a.left + a.width / 2, ay = a.top + a.height / 2;
    var best = null, bestScore = Infinity;
    all.forEach(function (el) {
      if (el === cur || el.contains(cur) || cur.contains(el)) return;
      var b = el.getBoundingClientRect();
      var bx = b.left + b.width / 2, by = b.top + b.height / 2;
      var main, cross, overlap;
      if (key === 'ArrowRight') { if (b.left < a.right - 1 && bx <= ax) return; main = bx - ax; cross = by - ay; overlap = b.bottom > a.top && b.top < a.bottom; }
      else if (key === 'ArrowLeft') { if (b.right > a.left + 1 && bx >= ax) return; main = ax - bx; cross = by - ay; overlap = b.bottom > a.top && b.top < a.bottom; }
      else if (key === 'ArrowDown') { if (b.top < a.bottom - 1 && by <= ay) return; main = by - ay; cross = bx - ax; overlap = b.right > a.left && b.left < a.right; }
      else { if (b.bottom > a.top + 1 && by >= ay) return; main = ay - by; cross = bx - ax; overlap = b.right > a.left && b.left < a.right; }
      if (main <= 0) return;
      // Prefer elements in line with the current one, then the nearest.
      var score = main + Math.abs(cross) * (overlap ? 0.5 : 3);
      if (score < bestScore) { bestScore = score; best = el; }
    });
    if (best) {
      best.focus({ preventScroll: true });
      best.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      return true;
    }
    if (key === 'ArrowDown' || key === 'ArrowUp') {
      window.scrollBy(0, (key === 'ArrowDown' ? 1 : -1) * innerHeight * 0.4);
      return true;
    }
    return false;
  };

  document.addEventListener('keydown', function (e) {
    var key = e.key;
    if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey) return;
    if (key !== 'ArrowUp' && key !== 'ArrowDown' && key !== 'ArrowLeft' && key !== 'ArrowRight') return;
    var t = e.target, tag = t && t.tagName;
    var typing = (tag === 'INPUT' && !/^(button|submit|reset|checkbox|radio|color|file|image)$/i.test(t.type)) ||
      tag === 'TEXTAREA' || tag === 'SELECT' || (t && t.isContentEditable);
    if (typing && (key === 'ArrowLeft' || key === 'ArrowRight' || tag === 'TEXTAREA' || tag === 'SELECT' || t.isContentEditable)) return;
    if (move(key)) e.preventDefault();
  }, false);
})();
"""
}
