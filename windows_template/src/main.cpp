// HTML2APK Windows wrapper: shows a website with Microsoft Edge WebView2.
//
// HTML2APK copies this prebuilt exe and embeds the app into its resources
// (ADR 0007), so no compiler is needed when apps are built:
//   RT_RCDATA "CONFIG"  key<TAB>value lines (UTF-8)
//   RT_RCDATA "INDEX"   id<TAB>mime<TAB>path lines, one per website file
//   RT_RCDATA <id>      the bytes of each website file
//   RT_GROUP_ICON 1     the app icon
// Website files are served from memory under https://app.html2apk.invalid/
// (".invalid" never resolves, so nothing can answer for it on a network).
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <wininet.h>
#include <wrl.h>

#include <WebView2.h>

#include <algorithm>
#include <cstdio>
#include <share.h>
#include <map>
#include <string>
#include <vector>

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace {

const wchar_t kAppHost[] = L"app.html2apk.invalid";
const wchar_t kAppOrigin[] = L"https://app.html2apk.invalid/";
const wchar_t kErrorPath[] = L"__html2apk/error.html";
const wchar_t kWebView2Download[] = L"https://go.microsoft.com/fwlink/p/?LinkId=2124703";

struct Resource {
  const BYTE* data = nullptr;
  DWORD size = 0;
};

struct Entry {
  int id;
  std::wstring mime;
};

std::wstring Widen(const std::string& s) {
  if (s.empty()) return {};
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), w.data(), n);
  return w;
}

std::string Narrow(const std::wstring& w) {
  if (w.empty()) return {};
  int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), static_cast<int>(w.size()), nullptr, 0, nullptr, nullptr);
  std::string s(n, '\0');
  WideCharToMultiByte(CP_UTF8, 0, w.data(), static_cast<int>(w.size()), s.data(), n, nullptr, nullptr);
  return s;
}

std::wstring Lower(std::wstring s) {
  std::transform(s.begin(), s.end(), s.begin(), [](wchar_t c) { return static_cast<wchar_t>(towlower(c)); });
  return s;
}

Resource LoadData(LPCWSTR name) {
  HRSRC r = FindResourceW(nullptr, name, RT_RCDATA);
  if (!r) return {};
  HGLOBAL g = LoadResource(nullptr, r);
  if (!g) return {};
  return {static_cast<const BYTE*>(LockResource(g)), SizeofResource(nullptr, r)};
}

std::vector<std::string> Lines(const Resource& r) {
  std::vector<std::string> out;
  std::string all(reinterpret_cast<const char*>(r.data), r.size);
  size_t start = 0;
  while (start < all.size()) {
    size_t end = all.find('\n', start);
    if (end == std::string::npos) end = all.size();
    std::string line = all.substr(start, end - start);
    if (!line.empty() && line.back() == '\r') line.pop_back();
    if (!line.empty()) out.push_back(line);
    start = end + 1;
  }
  return out;
}

std::vector<std::wstring> Split(const std::wstring& s, wchar_t sep) {
  std::vector<std::wstring> out;
  size_t start = 0;
  while (start <= s.size()) {
    size_t end = s.find(sep, start);
    if (end == std::wstring::npos) end = s.size();
    if (end > start) out.push_back(s.substr(start, end - start));
    start = end + 1;
  }
  return out;
}

// Decodes %XX sequences as UTF-8.
std::wstring PercentDecode(const std::wstring& s) {
  std::string bytes;
  std::string in = Narrow(s);
  for (size_t i = 0; i < in.size(); ++i) {
    if (in[i] == '%' && i + 2 < in.size() && isxdigit(static_cast<unsigned char>(in[i + 1])) &&
        isxdigit(static_cast<unsigned char>(in[i + 2]))) {
      bytes.push_back(static_cast<char>(std::stoi(in.substr(i + 1, 2), nullptr, 16)));
      i += 2;
    } else {
      bytes.push_back(in[i]);
    }
  }
  return Widen(bytes);
}

std::wstring HtmlEscape(const std::wstring& s) {
  std::wstring out;
  for (wchar_t c : s) {
    switch (c) {
      case L'&': out += L"&amp;"; break;
      case L'<': out += L"&lt;"; break;
      case L'>': out += L"&gt;"; break;
      case L'"': out += L"&quot;"; break;
      default: out += c;
    }
  }
  return out;
}

class App {
 public:
  bool Load() {
    Resource config = LoadData(L"CONFIG");
    if (!config.data) return false;
    for (const auto& line : Lines(config)) {
      size_t tab = line.find('\t');
      if (tab == std::string::npos) continue;
      config_[line.substr(0, tab)] = Widen(line.substr(tab + 1));
    }
    for (const auto& line : Lines(LoadData(L"INDEX"))) {
      size_t a = line.find('\t');
      size_t b = a == std::string::npos ? a : line.find('\t', a + 1);
      if (b == std::string::npos) continue;
      files_[Widen(line.substr(b + 1))] = {std::stoi(line.substr(0, a)), Widen(line.substr(a + 1, b - a - 1))};
    }
    for (const auto& h : Split(Get("allowedHosts"), L',')) allowedHosts_.push_back(Lower(h));
    return true;
  }

  std::wstring Get(const char* key, const std::wstring& fallback = L"") const {
    auto it = config_.find(key);
    return it == config_.end() ? fallback : it->second;
  }
  bool Flag(const char* key) const { return Get(key) == L"1"; }
  int Int(const char* key, int fallback) const {
    std::wstring v = Get(key);
    return v.empty() ? fallback : _wtoi(v.c_str());
  }
  bool IsLocal() const { return Get("type") == L"local"; }

  std::wstring StartUrl() const {
    return IsLocal() ? std::wstring(kAppOrigin) + Get("entry") : Get("entry");
  }

  std::wstring StartHost() const {
    if (IsLocal()) return kAppHost;
    return HostOf(Get("entry"));
  }

  static std::wstring HostOf(const std::wstring& url) {
    URL_COMPONENTSW parts{sizeof(parts)};
    wchar_t host[256] = {};
    parts.lpszHostName = host;
    parts.dwHostNameLength = ARRAYSIZE(host);
    if (!InternetCrackUrlW(url.c_str(), 0, 0, &parts)) return {};
    return Lower(host);
  }

  static std::wstring SchemeOf(const std::wstring& url) {
    size_t colon = url.find(L':');
    return colon == std::wstring::npos ? L"" : Lower(url.substr(0, colon));
  }

  // Same rules as the Android wrapper: https on the app's own site (with or
  // without www), listed hosts, and the bundled pages.
  bool IsInternal(const std::wstring& url) const {
    if (SchemeOf(url) != L"https") return false;
    std::wstring host = HostOf(url);
    std::wstring start = StartHost();
    if (host == kAppHost || host == start || host == L"www." + start || L"www." + host == start) return true;
    return std::find(allowedHosts_.begin(), allowedHosts_.end(), host) != allowedHosts_.end();
  }

  void OpenExternally(const std::wstring& url) const {
    if (Get("externalLinks") == L"block") return;
    static const wchar_t* kSchemes[] = {L"http", L"https", L"mailto", L"tel"};
    std::wstring scheme = SchemeOf(url);
    for (auto s : kSchemes) {
      if (scheme == s) {
        ShellExecuteW(nullptr, L"open", url.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
        return;
      }
    }
  }

  // A bundled file for a URL path, or nullptr.
  const Entry* Find(std::wstring path) const {
    size_t cut = path.find_first_of(L"?#");
    if (cut != std::wstring::npos) path = path.substr(0, cut);
    path = PercentDecode(path);
    if (path.empty() || path.back() == L'/') path += L"index.html";
    auto it = files_.find(path);
    return it == files_.end() ? nullptr : &it->second;
  }

  std::wstring ErrorPage() const {
    std::wstring retry = HtmlEscape(StartUrl());
    return L"<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" "
           L"content=\"width=device-width\"><title>Offline</title><style>body{font-family:'Segoe UI',sans-serif;"
           L"display:flex;align-items:center;justify-content:center;height:90vh;margin:0;text-align:center;"
           L"color:#222;background:#fafafa}@media(prefers-color-scheme:dark){body{color:#eee;background:#1e1e1e}}"
           L"a{display:inline-block;margin-top:16px;padding:10px 22px;border-radius:20px;background:#1a73e8;"
           L"color:#fff;text-decoration:none}</style></head><body><div><h1>Can't reach the site</h1>"
           L"<p>Check your internet connection and try again.</p><a href=\"" +
           retry + L"\">Try again</a></div></body></html>";
  }

  std::wstring ErrorUrl() const {
    std::wstring offline = Get("offlinePage");
    return std::wstring(kAppOrigin) + (offline.empty() ? kErrorPath : offline);
  }

 private:
  std::map<std::string, std::wstring> config_;
  std::map<std::wstring, Entry> files_;
  std::vector<std::wstring> allowedHosts_;
};

App g_app;
HWND g_window = nullptr;
ComPtr<ICoreWebView2Environment> g_env;
ComPtr<ICoreWebView2Controller> g_controller;
ComPtr<ICoreWebView2> g_webview;
FILE* g_log = nullptr;  // only when HTML2APK_CONSOLE_LOG is set (tests)

void Log(const std::wstring& line) {
  if (!g_log) return;
  std::string s = Narrow(line);
  fprintf(g_log, "%s\n", s.c_str());
  fflush(g_log);
}

std::wstring Take(LPWSTR s) {
  std::wstring out = s ? s : L"";
  CoTaskMemFree(s);
  return out;
}

void Fail(const wchar_t* message) {
  MessageBoxW(g_window, message, g_app.Get("name", L"App").c_str(), MB_ICONERROR);
  PostQuitMessage(1);
}

void ResizeWebView() {
  if (!g_controller) return;
  RECT r;
  GetClientRect(g_window, &r);
  g_controller->put_Bounds(r);
}

HRESULT ServeResource(ICoreWebView2WebResourceRequestedEventArgs* args) {
  ComPtr<ICoreWebView2WebResourceRequest> request;
  args->get_Request(&request);
  LPWSTR raw = nullptr;
  request->get_Uri(&raw);
  std::wstring uri = Take(raw);
  std::wstring path = uri.substr(wcslen(kAppOrigin));

  ComPtr<ICoreWebView2WebResourceResponse> response;
  const wchar_t* headers = L"Content-Type: text/html; charset=utf-8\r\nX-Content-Type-Options: nosniff\r\n"
                           L"Cache-Control: no-cache";
  if (path == kErrorPath) {
    std::string html = Narrow(g_app.ErrorPage());
    ComPtr<IStream> stream;
    stream.Attach(SHCreateMemStream(reinterpret_cast<const BYTE*>(html.data()), static_cast<UINT>(html.size())));
    g_env->CreateWebResourceResponse(stream.Get(), 200, L"OK", headers, &response);
  } else if (const Entry* e = g_app.Find(path)) {
    Resource r = LoadData(MAKEINTRESOURCEW(e->id));
    ComPtr<IStream> stream;
    stream.Attach(SHCreateMemStream(r.data, r.size));
    std::wstring h = L"Content-Type: " + e->mime + L"\r\nX-Content-Type-Options: nosniff\r\nCache-Control: no-cache";
    g_env->CreateWebResourceResponse(stream.Get(), 200, L"OK", h.c_str(), &response);
  } else {
    Log(L"MISSING " + path);
    g_env->CreateWebResourceResponse(nullptr, 404, L"Not Found", headers, &response);
  }
  return args->put_Response(response.Get());
}

void SetUpWebView() {
  ComPtr<ICoreWebView2Settings> settings;
  g_webview->get_Settings(&settings);
  bool devtools = g_app.Flag("devtools");
  settings->put_IsScriptEnabled(g_app.Get("javaScript", L"1") == L"1");
  settings->put_IsWebMessageEnabled(FALSE);
  settings->put_AreHostObjectsAllowed(FALSE);
  settings->put_AreDevToolsEnabled(devtools);
  settings->put_IsStatusBarEnabled(FALSE);
  settings->put_IsZoomControlEnabled(TRUE);
  ComPtr<ICoreWebView2Settings3> settings3;
  if (SUCCEEDED(settings.As(&settings3))) settings3->put_AreBrowserAcceleratorKeysEnabled(devtools);
  ComPtr<ICoreWebView2Settings2> settings2;
  std::wstring suffix = g_app.Get("userAgentSuffix");
  if (!suffix.empty() && SUCCEEDED(settings.As(&settings2))) {
    LPWSTR ua = nullptr;
    settings2->get_UserAgent(&ua);
    settings2->put_UserAgent((Take(ua) + L" " + suffix).c_str());
  }

  std::wstring filter = std::wstring(kAppOrigin) + L"*";
  g_webview->AddWebResourceRequestedFilter(filter.c_str(), COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
  g_webview->add_WebResourceRequested(
      Callback<ICoreWebView2WebResourceRequestedEventHandler>(
          [](ICoreWebView2*, ICoreWebView2WebResourceRequestedEventArgs* args) { return ServeResource(args); })
          .Get(),
      nullptr);

  g_webview->add_NavigationStarting(
      Callback<ICoreWebView2NavigationStartingEventHandler>(
          [](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) -> HRESULT {
            LPWSTR raw = nullptr;
            args->get_Uri(&raw);
            std::wstring uri = Take(raw);
            if (g_app.IsInternal(uri)) return S_OK;
            args->put_Cancel(TRUE);
            Log(L"BLOCKED " + uri);
            BOOL user = FALSE;
            args->get_IsUserInitiated(&user);
            if (user) g_app.OpenExternally(uri);
            return S_OK;
          })
          .Get(),
      nullptr);

  // Frames may embed other https sites (videos, maps), never local files.
  g_webview->add_FrameNavigationStarting(
      Callback<ICoreWebView2NavigationStartingEventHandler>(
          [](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) -> HRESULT {
            LPWSTR raw = nullptr;
            args->get_Uri(&raw);
            std::wstring uri = Take(raw);
            std::wstring scheme = App::SchemeOf(uri);
            if (scheme != L"https" && scheme != L"about") {
              args->put_Cancel(TRUE);
              Log(L"BLOCKED FRAME " + uri);
            }
            return S_OK;
          })
          .Get(),
      nullptr);

  g_webview->add_NewWindowRequested(
      Callback<ICoreWebView2NewWindowRequestedEventHandler>(
          [](ICoreWebView2* sender, ICoreWebView2NewWindowRequestedEventArgs* args) -> HRESULT {
            args->put_Handled(TRUE);
            LPWSTR raw = nullptr;
            args->get_Uri(&raw);
            std::wstring uri = Take(raw);
            if (g_app.IsInternal(uri)) {
              sender->Navigate(uri.c_str());
            } else {
              Log(L"EXTERNAL " + uri);
              g_app.OpenExternally(uri);
            }
            return S_OK;
          })
          .Get(),
      nullptr);

  // Camera, microphone, location, notifications etc. are not offered yet.
  g_webview->add_PermissionRequested(
      Callback<ICoreWebView2PermissionRequestedEventHandler>(
          [](ICoreWebView2*, ICoreWebView2PermissionRequestedEventArgs* args) -> HRESULT {
            args->put_State(COREWEBVIEW2_PERMISSION_STATE_DENY);
            return S_OK;
          })
          .Get(),
      nullptr);

  g_webview->add_NavigationCompleted(
      Callback<ICoreWebView2NavigationCompletedEventHandler>(
          [](ICoreWebView2* sender, ICoreWebView2NavigationCompletedEventArgs* args) -> HRESULT {
            BOOL ok = FALSE;
            args->get_IsSuccess(&ok);
            COREWEBVIEW2_WEB_ERROR_STATUS status = COREWEBVIEW2_WEB_ERROR_STATUS_UNKNOWN;
            args->get_WebErrorStatus(&status);
            LPWSTR raw = nullptr;
            sender->get_Source(&raw);
            std::wstring source = Take(raw);
            Log(std::wstring(ok ? L"LOADED " : L"FAILED ") + source);
            if (!ok && status != COREWEBVIEW2_WEB_ERROR_STATUS_OPERATION_CANCELED &&
                status != COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_ABORTED && !g_app.IsLocal()) {
              sender->Navigate(g_app.ErrorUrl().c_str());
            }
            return S_OK;
          })
          .Get(),
      nullptr);

  if (g_log) {
    g_webview->CallDevToolsProtocolMethod(L"Runtime.enable", L"{}", nullptr);
    ComPtr<ICoreWebView2DevToolsProtocolEventReceiver> receiver;
    g_webview->GetDevToolsProtocolEventReceiver(L"Runtime.consoleAPICalled", &receiver);
    receiver->add_DevToolsProtocolEventReceived(
        Callback<ICoreWebView2DevToolsProtocolEventReceivedEventHandler>(
            [](ICoreWebView2*, ICoreWebView2DevToolsProtocolEventReceivedEventArgs* args) -> HRESULT {
              LPWSTR json = nullptr;
              args->get_ParameterObjectAsJson(&json);
              Log(L"CONSOLE " + Take(json));
              return S_OK;
            })
            .Get(),
        nullptr);
  }

  g_webview->Navigate(g_app.StartUrl().c_str());
}

std::wstring UserDataFolder() {
  PWSTR base = nullptr;
  std::wstring dir;
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &base))) dir = base;
  CoTaskMemFree(base);
  return dir + L"\\HTML2APK Apps\\" + g_app.Get("appId", L"app");
}

void CreateWebView() {
  std::wstring data = UserDataFolder();
  HRESULT hr = CreateCoreWebView2EnvironmentWithOptions(
      nullptr, data.c_str(), nullptr,
      Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
          [](HRESULT result, ICoreWebView2Environment* env) -> HRESULT {
            if (FAILED(result)) {
              Fail(L"Could not start Microsoft Edge WebView2.");
              return result;
            }
            g_env = env;
            return env->CreateCoreWebView2Controller(
                g_window, Callback<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                              [](HRESULT result, ICoreWebView2Controller* controller) -> HRESULT {
                                if (FAILED(result)) {
                                  Fail(L"Could not create the web view.");
                                  return result;
                                }
                                g_controller = controller;
                                g_controller->get_CoreWebView2(&g_webview);
                                ResizeWebView();
                                SetUpWebView();
                                return S_OK;
                              })
                              .Get());
          })
          .Get());
  if (FAILED(hr)) {
    std::wstring message = g_app.Get("name", L"This app") +
                           L" needs the Microsoft Edge WebView2 Runtime, which is not installed on this PC.\n\n"
                           L"Open Microsoft's download page now?";
    if (MessageBoxW(g_window, message.c_str(), g_app.Get("name", L"App").c_str(), MB_ICONWARNING | MB_YESNO) == IDYES) {
      ShellExecuteW(nullptr, L"open", kWebView2Download, nullptr, nullptr, SW_SHOWNORMAL);
    }
    PostQuitMessage(1);
  }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
  switch (msg) {
    case WM_SIZE:
      ResizeWebView();
      return 0;
    case WM_DPICHANGED: {
      auto* r = reinterpret_cast<RECT*>(lp);
      SetWindowPos(hwnd, nullptr, r->left, r->top, r->right - r->left, r->bottom - r->top, SWP_NOZORDER);
      return 0;
    }
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
  }
  return DefWindowProcW(hwnd, msg, wp, lp);
}

}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int show) {
  if (!g_app.Load()) {
    MessageBoxW(nullptr, L"This is the HTML2APK Windows wrapper. Build an app with HTML2APK to use it.", L"HTML2APK",
                MB_ICONINFORMATION);
    return 2;
  }
  wchar_t logPath[MAX_PATH] = {};
  if (GetEnvironmentVariableW(L"HTML2APK_CONSOLE_LOG", logPath, MAX_PATH) > 0) g_log = _wfsopen(logPath, L"a", _SH_DENYNO);

  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  WNDCLASSEXW wc{sizeof(wc)};
  wc.lpfnWndProc = WndProc;
  wc.hInstance = instance;
  wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
  wc.hIcon = LoadIconW(instance, MAKEINTRESOURCEW(1));
  wc.hIconSm = wc.hIcon;
  wc.lpszClassName = L"HTML2APKApp";
  RegisterClassExW(&wc);

  UINT dpi = GetDpiForSystem();
  int width = MulDiv(g_app.Int("width", 1280), dpi, 96);
  int height = MulDiv(g_app.Int("height", 800), dpi, 96);
  DWORD style = g_app.Flag("resizable") || g_app.Get("resizable").empty()
                    ? WS_OVERLAPPEDWINDOW
                    : WS_OVERLAPPEDWINDOW & ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  g_window = CreateWindowExW(0, wc.lpszClassName, g_app.Get("name", L"App").c_str(), style, CW_USEDEFAULT,
                             CW_USEDEFAULT, width, height, nullptr, nullptr, instance, nullptr);
  ShowWindow(g_window, show);
  UpdateWindow(g_window);
  CreateWebView();

  MSG msg;
  while (GetMessageW(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
  }
  g_controller = nullptr;
  g_webview = nullptr;
  g_env = nullptr;
  if (g_log) fclose(g_log);
  CoUninitialize();
  return static_cast<int>(msg.wParam);
}
