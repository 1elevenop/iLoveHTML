# ADR 0009: Sharing images and PDFs from generated apps

Status: accepted (2026-11-04)

## Context

Generated apps already polyfill `navigator.share` for text and links
(`PageBridge.kt`), because Android's WebView has no Web Share API. Pages
that draw or edit pictures (cards, receipts, certificates) also need to
send the result to WhatsApp, Telegram, Gmail and so on, and users expect
the picture to stay in their gallery afterwards.

## Decision

- **Page API:** the standard one. `navigator.canShare({files})` is true
  only when the project allows it (`webView.shareFiles`, on by default),
  every file is `image/*` or `application/pdf`, there are at most 10
  files and they total at most 20 MB. `navigator.share({files, title,
  text})` reads the files with `FileReader` and sends one
  `{type: 'shareFiles', ...}` message over the existing origin-restricted
  WebMessageListener. Still no `addJavascriptInterface`.
- **Android checks it again** (`ShareRules.kt`, pure Kotlin so
  `android_engine` tests it on the JVM): mime type, count, decoded size,
  sanitized and de-duplicated file names, one share per second.
- **Android 10 and newer:** images are inserted into
  `MediaStore.Images` at `Pictures/<galleryFolder>`, PDFs into
  `MediaStore.Downloads` at `Download/<galleryFolder>`. The folder is the
  project's `galleryFolder`, or the app name. The returned `content://`
  URIs are shared directly, so the files also stay in the gallery. No
  storage permission is needed.
- **Android 7–9:** writing to the shared gallery would need
  `WRITE_EXTERNAL_STORAGE`, which we do not request. Files go to
  `cacheDir/shared/<time>/` (deleted after a day) and are shared through
  `androidx.core.content.FileProvider` (authority
  `<applicationId>.html2apk.files`, `res/xml/html2apk_file_paths.xml`).
  They are not kept in the gallery on these versions.
- **The provider is in the base manifest.** The on-device engine cannot
  add elements with new attributes to a compiled manifest (ADR 0002), but
  it can change existing attribute values. So `<provider>` is part of the
  template (and of the Gradle generator's manifest), and `ApkAssembler`
  / `ProtoManifest` rewrite `android:authorities` to the app's own ID.
  Without that, a second generated app would fail to install with a
  conflicting provider.
- **Sending:** `ACTION_SEND` (one file) or `ACTION_SEND_MULTIPLE`, type
  `image/*`, `application/pdf` or `*/*`, with `EXTRA_STREAM`, `ClipData`
  and `FLAG_GRANT_READ_URI_PERMISSION`. If the project sets
  `shareTarget` (a package name such as `com.whatsapp`), that app is
  started directly; if it is missing, the share sheet opens instead.
  No `<queries>` element is needed, because launching an explicit
  package is not limited by package visibility.
- **Downloads:** with `galleryFolder` set, downloaded `data:`/`blob:`
  images are saved to `Pictures/<galleryFolder>` instead of Downloads
  (Android 10+). Everything else is unchanged.

## Consequences

- Base APK grows by about 9 KB (FileProvider, `androidx.core` 1.1.0,
  which webkit already pulled in).
- Shares need a WebView with WebMessageListener and document-start
  scripts (about version 86+). Phones on Android 7–9 get WebView updates
  from Play; the stock Android 7 emulator image (WebView 53) does not, so
  no share or download features appear there.
- Rebuild the base APK (`tools/build_ondevice_base.ps1`) whenever the
  template changes, as before.
