# Changelog

Older release notes. The newest release is described in the [README](README.md).
Every release: [GitHub releases](https://github.com/1elevenop/iLoveHTML/releases).

## What's new in 1.2.3

A security release ([what was reviewed](docs/security-review.md)).
**Rebuild your apps with 1.2.3** to get the fixes that live inside them.

- **Apps you build (Android):** a page that crashes no longer closes the
  app; apps with app lock no longer show their page in the recent-apps
  screen on Android 10–12 (screenshots are blocked there); app data is
  left out of backups and phone-to-phone transfers.
- **Apps you build (Windows):** the Downloads, File uploads and Local
  storage switches now work in .exe and .msix apps too.
- **URL apps:** "Other sites that open inside the app" no longer lets
  those sites share, save files or send notifications. A new field,
  "Sites that can also share, save files and notify", lists the ones that
  may. Projects you already have keep working as before; check the new
  field and remove login or payment sites.
- **Windows installers:** the certificate password is no longer passed on
  a command line.
- **Fixed:** the signer fingerprint was missing after Windows builds on
  PCs with Android build-tools 37.

Full notes: [release 1.2.3](https://github.com/1elevenop/iLoveHTML/releases/tag/v1.2.3).

## What's new in 1.2.2

- **Updates install from inside the app (Android):** NEW UPDATE → Download
  now fetches the APK in iLoveHTML with a progress bar, checks it against
  the release's `SHA256SUMS.txt`, and opens Android's installer. Browsers
  hold APK downloads behind a "File might be harmful" prompt, which made
  downloads look stuck at 100%.

Full notes: [release 1.2.2](https://github.com/1elevenop/iLoveHTML/releases/tag/v1.2.2).

## What's new in 1.2.1

- **Update notice:** when a new iLoveHTML is released, Settings shows a
  glowing **NEW UPDATE** (and a dot on the Settings button) with the
  release notes and a direct download for your device. iLoveHTML asks
  GitHub about twice a day; turn it off in Settings → About → Check for
  updates. The Privacy Policy explains what this sends.

Full notes: [release 1.2.1](https://github.com/1elevenop/iLoveHTML/releases/tag/v1.2.1).

## What's new in 1.2.0

- **8 languages:** English, Español, Français, Deutsch, Português, 日本語,
  中文 and 한국어. iLoveHTML follows the system language, or pick one in
  Settings → Language.
- **Themes:** dark (the original New ELEVEN look), light or follow the
  system, with five accent colours (orange, terminal green, cyan, violet,
  pink) in Settings → Appearance.
- **Animation and ASCII art:** an ASCII logo typed out at launch, ASCII art
  on the empty project list, an ASCII progress bar while building, and page
  transitions. Turn them off in Settings → Animations (the system's
  reduce-motion setting is respected too).
- **About** in Settings: How to use, Terms of Use, Privacy Policy, app
  version and credit, with a link to
  [Buy Me a Coffee](https://buymeacoffee.com/1elevenop).
- **App lock for iLoveHTML:** a PIN, password and/or fingerprint/face before
  the app opens, with an optional hint and "Forgot PIN?" (verify with the
  device's own lock or a one-time recovery code). Settings → Security.
- **Replace website files:** swap a project's HTML files or ZIP for new
  ones; name, package ID, icon, settings, release key and history stay.
  Project → Settings → Content.

Full notes: [release 1.2.0](https://github.com/1elevenop/iLoveHTML/releases/tag/v1.2.0).

## What's new in 1.1.1

- Apps you build: light/dark/follow-phone theme, fullscreen, keep screen
  on, back-button choices, app shortcuts, app lock (fingerprint, face or
  screen lock), web notifications, Android TV and tablet support, and
  smaller builds with "Optimize files when building".
- iLoveHTML: install on a phone by QR code from Windows, and project backup
  and restore (`.ilovehtml` files).
- Android 10 is now the minimum.

Full notes: [release 1.1.1](https://github.com/1elevenop/iLoveHTML/releases/tag/v1.1.1).
