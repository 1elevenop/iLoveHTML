# iLoveHTML — Next Features & Roadmap

## 🧠 Desktop .exe Converter — Gap Analysis

The `.exe` output via `windows_template/` (C++ + Edge WebView2) already works.
Here's what's needed to make it a polished **standalone desktop product**:

| Gap | What's Needed |
|---|---|
| 🔏 Code signing | Buy Authenticode cert → no SmartScreen warning |
| 📦 Installer / MSIX | ✅ Done ([ADR 0008](adr/0008-windows-msix-installers.md)): signed `.msix` with a test certificate or your own `.pfx` |
| 🪟 Window settings | Size, title bar color, min/max size, single-instance |
| 📋 Version info | File properties show product version |
| 📱 Build .exe from phone | Currently Windows-only |
| 🌐 Mac/Linux support | Electron or Tauri alternative wrappers |

---

## ✅ Done in 1.1.1 (2026-11-06)

| Feature | Notes |
|---|---|
| Theme (light / dark / follow phone) | Sets the page's `prefers-color-scheme` |
| Fullscreen and keep screen on | Immersive mode, swipe to show the bars |
| Back-button modes | History then exit, press twice, ask, or go to start page |
| App shortcuts | Up to 4 pages on the icon's long-press menu |
| Asset optimizer + size report | CSS, JSON, PNG, JPEG; project files never change |
| Install by QR code (Windows) | One secret URL, private network only, 10-minute limit |
| Project backup and restore | `.ilovehtml` ZIP, without builds or signing keys |
| App lock | Biometric or screen lock (adds `USE_BIOMETRIC`) |
| Web notifications | `Notification` API while the app is open (adds `POST_NOTIFICATIONS`) |
| Android TV and tablets | TV banner and remote focus; free rotation and desktop layout on tablets |

Checked on a real Samsung phone (Android 17, 2026-11-07): app lock with
fingerprint and face, notifications, follow-phone and dark theme, and QR
install from a Windows PC. Still to check on real hardware: the TV remote,
and an Android 10 phone.

---

## 🚀 Feature Ideas — Ranked by Impact

### 🔥 High Impact (Build These First)

**1. macOS & Linux `.app` / binary output**
- Use **Tauri** (Rust + WebView) as the wrapper — cross-platform, tiny output (~3MB)
- Currently locked to Windows (WebView2) and Android. Opening Mac/Linux = 3x the market

**2. Code Signing + MSIX Installer**
- ✅ MSIX installer done (ADR 0008): Start menu entry, clean uninstall, in-place updates
- Still open: a certificate from a certificate authority. With the built-in test
  certificate, every PC must trust the `.cer` once; bare `.exe` files still trigger SmartScreen
- Next: bundle `makeappx`/`signtool` so the Windows SDK is not needed; Microsoft Store submission

**3. PWA → App Converter**
- If the site has a `manifest.json`, auto-read name, icons, theme color
- Detect `service-worker.js` and warn users about offline behavior differences

**4. Template Library**
- Let users pick a starter template (blog, portfolio, shop, dashboard)
- Huge for non-developers who want to create apps from scratch

**5. Google Play Publisher Integration**
- Google Play Console API: auto-upload AABs after build
- Makes this a true end-to-end pipeline

---

### 💡 Medium Impact

**6. Visual App Customizer**
- Let users visually preview status bar colors, splash screen, theme — live WYSIWYG
- Currently UI exists but is form-based only

**7. Custom JavaScript Bridge (Native APIs)**
- Inject a `window.iLoveHTML` JS object exposing native features: camera, GPS, notifications, contacts, biometrics
- The #1 feature gap vs Capacitor / Cordova
- ✅ Started: web notifications and app lock (biometrics) are done; camera, GPS and contacts are open

**8. Multi-page / Deep Linking Support**
- Generate Android App Links so `https://yoursite.com/page` opens directly in the app
- Improves the "real app" experience significantly

**9. Auto-update for URL Apps**
- For URL-based apps, add a background version check + notification when the site updates

**10. Analytics Integration (Optional)**
- Let users add Firebase Analytics or a privacy-friendly alternative (Plausible, Umami) without touching code

---

### 🛠️ Polish / Quality of Life

**11. Drag & Drop Import**
- Drop a ZIP or folder directly onto the app window

**12. Batch Build**
- Build multiple projects to APK / AAB / EXE in one click

**13. Build History & Logs UI**
- Logs exist in `.workspace/builds/` — surface them in the UI with color-coded status

**14. Diff / Version Tracking**
- Track which version of HTML was used for each build — useful for debugging regressions

**15. CLI `--watch` Mode**
- Auto-rebuild whenever source HTML/CSS/JS changes — huge for developer workflows

---

## 🤖 For people who build with AI (added 2026-11-10)

Most new users arrive with HTML an AI wrote for them. What gets in their way:

| Problem today | Feature |
|---|---|
| AI gives code in a chat, not files; import takes only files, a ZIP or a URL | **Paste HTML → app**, and "Open with iLoveHTML" for `.html`/`.zip` from the share sheet |
| AI code loads Tailwind, React, Chart.js and fonts from CDNs; local apps have no internet permission, so the page is blank | **Make it work offline**: find CDN links at import, download them into the project, rewrite the links, record their hashes |
| Fixing is manual: read the console, retype the error for the AI, import again | **Copy errors as an AI prompt** from the preview console, **Copy builder prompt** (what works inside iLoveHTML), **Update from clipboard** with snapshots and rollback |
| An API key pasted into the JavaScript ships inside the APK, where anyone can read it | **Secret scanner** that warns at build time, and a **key vault**: the person using the app enters their own key once, it is stored in Android Keystore / DPAPI and added natively to requests for the hosts the project lists |
| Nobody can see what an AI-written app talks to | **"What does this app talk to?" report**, then an allowlist enforced in the app |
| AI-made trackers and notes apps lose their data on reinstall; a phone-built APK cannot update a PC-built one (different keys) | **Export / import app data** as one file |
| Voice and camera are denied; WebView has no speech recognition | **Microphone, camera and speech-to-text** as opt-in permissions; on phones that have it, an **on-device AI bridge** (Gemini Nano) for apps that need no key and no network |
| "Send this article to my summarizer" is impossible | **Share into the app** (Web Share Target) |
| Reminders only fire while the app is open | **Scheduled notifications** |
| Coding agents cannot drive iLoveHTML | **MCP server on the CLI**: an agent creates the project, builds it and shows the install QR |

Security work still open is listed in [security-review.md](security-review.md)
(signed updates, release keys behind the app lock, QR install fingerprint).

---

## 🗺️ Suggested Milestones

### Milestone 7: Polish & Distribution
- [ ] Code signing (Authenticode certificate)
- [x] MSIX installer (ADR 0008)
- [ ] Window size / titlebar color settings
- [ ] Version info resource in .exe

### Milestone 8: Cross-Platform .exe
- [ ] Tauri wrapper for macOS + Linux
- [ ] Mac .app build from Windows
- [ ] Mac/Linux build from phone

### Milestone 9: Native API Bridge
- [x] Web notifications (no push)
- [ ] JS ↔ native bridge (camera, GPS, contacts)
- [ ] PWA manifest auto-import
- [ ] Android App Links / deep linking

### Milestone 10: Ecosystem
- [ ] Template library
- [ ] Google Play auto-upload integration
- [ ] Batch build + build history UI

---

## 💬 Key Insight

> 🏆 **iLoveHTML uniquely builds for Android (APK + AAB) AND Windows (.exe) from a single HTML project.**
> No other tool does all three in one place. The MSIX installer is in; the biggest lever now is
> a **real code-signing certificate**, so installers and `.exe` files are trusted without extra steps.
