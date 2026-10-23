# ADR 0007: Websites as Windows .exe apps

Status: accepted (2026-10-22)

## Context

Users want the same project to become a Windows program, not only an
Android app. iLoveHTML on Windows must build it locally, quickly, and
without asking users to install a compiler.

## Decision

Same pattern as the on-device APK engine (ADR 0002): a **prebuilt
wrapper** is copied and personalised; nothing is compiled per app.

- **Wrapper** (`windows_template/`, C++17, Win32 + Microsoft Edge
  WebView2): built once by `tools/build_windows_wrapper.ps1` (Release,
  static C runtime, CFG/ASLR/DEP), installed next to the iLoveHTML exe.
  It depends only on DLLs that ship with Windows; WebView2 is loaded
  through `WebView2LoaderStatic.lib`.
- **Build** (`app/lib/src/engine/exe_builder.dart`): copy the wrapper
  and write resources with `BeginUpdateResourceW`/`UpdateResourceW`
  (`dart:ffi`):
  - `RCDATA "CONFIG"`: `key TAB value` lines (no JSON parser in the
    wrapper; tabs and newlines in values are replaced);
  - `RCDATA "INDEX"`: `id TAB mime TAB path` per website file;
  - `RCDATA 1000+`: the website files;
  - `GROUP_ICON 1` / `ICON 1–4`: the project icon as 256/48/32/16 px PNG
    images (resized with Flutter's codec).
  The result is **one .exe**; the output is written to a temp file and
  renamed only after the resource update succeeded.
- **Runtime rules** (mirroring the Android wrapper):
  - Website files are served from memory through `WebResourceRequested`
    under `https://app.html2apk.invalid/` (`.invalid` never resolves), with
    `nosniff`; missing files get 404. Nothing is extracted to disk.
  - Top-level navigation stays in the app only for https on the app's site
    (with/without `www.`), listed hosts and bundled pages; other links open
    in the default browser for http/https/mailto/tel after a user action,
    or nothing when external links are blocked.
  - Frames may load https only. `file://` is refused (WebView2 itself
    refuses it from https pages; verified).
  - Permission requests (camera, microphone, location, notifications…)
    are denied. Host objects and web messages are off.
  - DevTools and browser shortcuts (F12, Ctrl+U…) only in the
    "Developer tools" build.
  - URL apps show the project's offline page, or a built-in one with
    "Try again", when the site cannot be reached.
  - Per-app browser data in `%LOCALAPPDATA%\iLoveHTML Apps\<applicationId>`.
  - If WebView2 is missing, the app explains and offers Microsoft's
    download page.
  - `HTML2APK_CONSOLE_LOG=<file>` makes the app log navigations and
    console output to that file; tests use it.
- **New dependency:** Microsoft.Web.WebView2 NuGet package 1.0.2903.40
  (MIT-style license, signed by Microsoft), downloaded by the build
  script into `.tools/` and checked against a pinned SHA-256. It is a
  build-time dependency of the wrapper only.

## Trade-offs

- Prebuilt wrapper + resources: builds take about a second and need no
  Visual Studio; the cost is a fixed feature set per iLoveHTML version.
- Resources are memory-mapped by Windows; very large sites make large
  exes (limit: 1 GB of website files).
- **Not code-signed.** Downloaded copies trigger SmartScreen ("Windows
  protected your PC" → More info → Run anyway) until signed with an
  Authenticode certificate, which must be bought from a certificate
  authority.

## Verified (2026-10-22)

- `app/test/exe_builder_test.dart` builds and runs real exes:
  page and JS load from the exe; its CSS loads; a missing file is 404;
  XHR, iframe and navigation to `file:///C:/Windows/win.ini` are refused
  and the page stays; the icon group (4 sizes) is found by Windows; a URL
  app whose host cannot be reached shows the offline page; config values
  cannot inject extra keys.
- `integration_test/windows_ui_test.dart`: Build tab → "Build .exe" in
  the real iLoveHTML Windows app, then the exe runs the page's JavaScript.
- Wrapper imports only system DLLs (`dumpbin /dependents`).

## Not done

- Code signing with the user's certificate; installer/MSIX.
- Windows-specific project settings (window size, single instance,
  title bar colour); fixed at 1280×800, resizable.
- Version info resource (file properties show no product version).
- Building .exe files on the phone.
