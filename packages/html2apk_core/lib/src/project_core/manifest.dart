import 'dart:convert';
import 'dart:math';

/// Current version of the `project.json` schema written by this release.
const int currentSchemaVersion = 2;

enum SourceType { local, url }

enum Orientation { unspecified, portrait, landscape }

enum ExternalLinkPolicy { browser, block }

/// Light or dark theme for the generated app; sets the page's `prefers-color-scheme`.
enum AppTheme { light, dark, system }

/// What the back button does when the WebView has no page to go back to,
/// or (for [home]) on every page but the start page.
enum BackButtonMode {
  /// Go back through the page history, then close the app.
  history,

  /// Like [history], but on the first page the user must press back twice.
  pressTwiceToExit,

  /// Like [history], but on the first page the app asks before it closes.
  confirmExit,

  /// Go straight to the start page; on the start page, close the app.
  home,
}

/// Where the app's content comes from.
class ProjectSource {
  const ProjectSource.local(this.entry) : type = SourceType.local;
  const ProjectSource.url(this.entry) : type = SourceType.url;

  final SourceType type;

  /// Relative POSIX path inside `source/` for [SourceType.local],
  /// absolute https URL for [SourceType.url].
  final String entry;

  Map<String, Object?> toJson() => {'type': type.name, 'entry': entry};

  factory ProjectSource.fromJson(Map<String, Object?> json) {
    final entry = json['entry'] as String;
    return switch (json['type']) {
      'local' => ProjectSource.local(entry),
      'url' => ProjectSource.url(entry),
      final other => throw FormatException('Unknown source type: $other'),
    };
  }
}

class AndroidSettings {
  const AndroidSettings({
    required this.applicationId,
    this.versionName = '1.0.0',
    this.versionCode = 1,
  });

  final String applicationId;
  final String versionName;
  final int versionCode;

  Map<String, Object?> toJson() => {
        'applicationId': applicationId,
        'versionName': versionName,
        'versionCode': versionCode,
      };

  factory AndroidSettings.fromJson(Map<String, Object?> json) => AndroidSettings(
        applicationId: json['applicationId'] as String,
        versionName: json['versionName'] as String? ?? '1.0.0',
        versionCode: json['versionCode'] as int? ?? 1,
      );

  AndroidSettings copyWith({String? applicationId, String? versionName, int? versionCode}) =>
      AndroidSettings(
        applicationId: applicationId ?? this.applicationId,
        versionName: versionName ?? this.versionName,
        versionCode: versionCode ?? this.versionCode,
      );
}

class WebViewSettings {
  const WebViewSettings({
    this.javaScriptEnabled = true,
    this.domStorageEnabled = true,
    this.externalLinks = ExternalLinkPolicy.browser,
    this.allowedHosts = const [],
    this.userAgentSuffix,
    this.pullToRefresh = false,
    this.fileUploads = true,
    this.webShare = true,
    this.downloads = true,
    this.shareFiles = true,
    this.galleryFolder,
    this.shareTarget,
    this.backButton = BackButtonMode.history,
    this.notifications = false,
  });

  final bool javaScriptEnabled;
  final bool domStorageEnabled;
  final ExternalLinkPolicy externalLinks;

  /// Extra https hosts allowed to load inside the WebView.
  final List<String> allowedHosts;
  final String? userAgentSuffix;

  /// Swipe down at the top of a page to reload it (or retry after an error).
  final bool pullToRefresh;

  /// Lets `<input type="file">` open Android's file picker.
  final bool fileUploads;

  /// Adds `navigator.share` (text and links) using Android's share sheet.
  final bool webShare;

  /// Saves downloads (https, data: and blob: links) to the Downloads folder.
  final bool downloads;

  /// Lets `navigator.share({files})` share images and PDFs.
  final bool shareFiles;

  /// Gallery folder (`Pictures/<name>`) for shared and downloaded images;
  /// null means shared images use the app name and downloads stay in Downloads.
  final String? galleryFolder;

  /// Package opened directly for file shares (e.g. `com.whatsapp`) instead
  /// of the share sheet, when installed.
  final String? shareTarget;

  /// What the Android back button does.
  final BackButtonMode backButton;

  /// Adds the web `Notification` API: the page can show Android notifications
  /// while the app is open. Adds the POST_NOTIFICATIONS permission.
  final bool notifications;

  Map<String, Object?> toJson() => {
        'javaScriptEnabled': javaScriptEnabled,
        'domStorageEnabled': domStorageEnabled,
        'externalLinks': externalLinks.name,
        'allowedHosts': allowedHosts,
        'userAgentSuffix': userAgentSuffix,
        'pullToRefresh': pullToRefresh,
        'fileUploads': fileUploads,
        'webShare': webShare,
        'downloads': downloads,
        'shareFiles': shareFiles,
        'galleryFolder': galleryFolder,
        'shareTarget': shareTarget,
        'backButton': backButton.name,
        'notifications': notifications,
      };

  WebViewSettings copyWith({
    bool? javaScriptEnabled,
    bool? domStorageEnabled,
    ExternalLinkPolicy? externalLinks,
    List<String>? allowedHosts,
    String? Function()? userAgentSuffix,
    bool? pullToRefresh,
    bool? fileUploads,
    bool? webShare,
    bool? downloads,
    bool? shareFiles,
    String? Function()? galleryFolder,
    String? Function()? shareTarget,
    BackButtonMode? backButton,
    bool? notifications,
  }) =>
      WebViewSettings(
        javaScriptEnabled: javaScriptEnabled ?? this.javaScriptEnabled,
        domStorageEnabled: domStorageEnabled ?? this.domStorageEnabled,
        externalLinks: externalLinks ?? this.externalLinks,
        allowedHosts: allowedHosts ?? this.allowedHosts,
        userAgentSuffix: userAgentSuffix != null ? userAgentSuffix() : this.userAgentSuffix,
        pullToRefresh: pullToRefresh ?? this.pullToRefresh,
        fileUploads: fileUploads ?? this.fileUploads,
        webShare: webShare ?? this.webShare,
        downloads: downloads ?? this.downloads,
        shareFiles: shareFiles ?? this.shareFiles,
        galleryFolder: galleryFolder != null ? galleryFolder() : this.galleryFolder,
        shareTarget: shareTarget != null ? shareTarget() : this.shareTarget,
        backButton: backButton ?? this.backButton,
        notifications: notifications ?? this.notifications,
      );

  factory WebViewSettings.fromJson(Map<String, Object?> json) => WebViewSettings(
        javaScriptEnabled: json['javaScriptEnabled'] as bool? ?? true,
        domStorageEnabled: json['domStorageEnabled'] as bool? ?? true,
        externalLinks: ExternalLinkPolicy.values.byName(json['externalLinks'] as String? ?? 'browser'),
        allowedHosts: [...?(json['allowedHosts'] as List?)?.cast<String>()],
        userAgentSuffix: json['userAgentSuffix'] as String?,
        pullToRefresh: json['pullToRefresh'] as bool? ?? false,
        fileUploads: json['fileUploads'] as bool? ?? true,
        webShare: json['webShare'] as bool? ?? true,
        downloads: json['downloads'] as bool? ?? true,
        shareFiles: json['shareFiles'] as bool? ?? true,
        galleryFolder: json['galleryFolder'] as String?,
        shareTarget: json['shareTarget'] as String?,
        backButton: _byName(BackButtonMode.values, json['backButton'], BackButtonMode.history),
        notifications: json['notifications'] as bool? ?? false,
      );
}

/// One entry in the menu that opens when the user long-presses the app icon.
class AppShortcut {
  const AppShortcut({required this.label, required this.page});

  /// Text in the menu, at most [maxShortcutLabelLength] characters.
  final String label;

  /// For local projects: a path inside `source/`, e.g. `shop/cart.html#top`.
  /// For URL projects: a path on the site (`/cart`) or a full https URL on it.
  final String page;

  Map<String, Object?> toJson() => {'label': label, 'page': page};

  factory AppShortcut.fromJson(Map<String, Object?> json) =>
      AppShortcut(label: json['label'] as String? ?? '', page: json['page'] as String? ?? '');

  @override
  bool operator ==(Object other) => other is AppShortcut && other.label == label && other.page == page;

  @override
  int get hashCode => Object.hash(label, page);
}

/// Big screens: Android TV, tablets and foldables.
class DeviceSettings {
  const DeviceSettings({this.androidTv = false, this.rotateOnTablets = false, this.desktopSiteOnLargeScreens = false});

  /// Lists the app on Android TV with a banner, and lets the remote's arrow
  /// keys move between links and buttons.
  final bool androidTv;

  /// On tablets (600 dp and wider) the screen may rotate, even when
  /// [ProjectManifest.orientation] locks phones to one orientation.
  final bool rotateOnTablets;

  /// On tablets and TVs, ask sites for their desktop layout (no "Mobile" in the user agent).
  final bool desktopSiteOnLargeScreens;

  Map<String, Object?> toJson() => {
        'androidTv': androidTv,
        'rotateOnTablets': rotateOnTablets,
        'desktopSiteOnLargeScreens': desktopSiteOnLargeScreens,
      };

  factory DeviceSettings.fromJson(Map<String, Object?> json) => DeviceSettings(
        androidTv: json['androidTv'] as bool? ?? false,
        rotateOnTablets: json['rotateOnTablets'] as bool? ?? false,
        desktopSiteOnLargeScreens: json['desktopSiteOnLargeScreens'] as bool? ?? false,
      );

  DeviceSettings copyWith({bool? androidTv, bool? rotateOnTablets, bool? desktopSiteOnLargeScreens}) => DeviceSettings(
        androidTv: androidTv ?? this.androidTv,
        rotateOnTablets: rotateOnTablets ?? this.rotateOnTablets,
        desktopSiteOnLargeScreens: desktopSiteOnLargeScreens ?? this.desktopSiteOnLargeScreens,
      );
}

/// Launchers show about four shortcuts; more are ignored.
const int maxShortcuts = 4;
const int maxShortcutLabelLength = 25;

/// System bar colours and the in-app splash screen. Colours are `#RRGGBB`.
class AppearanceSettings {
  const AppearanceSettings({
    this.statusBarColor = '#000000',
    this.navigationBarColor = '#000000',
    this.splashEnabled = false,
    this.splashBackgroundColor = '#FFFFFF',
    this.theme = AppTheme.light,
    this.fullscreen = false,
    this.keepScreenOn = false,
  });

  final String statusBarColor;
  final String navigationBarColor;

  /// Shows a full-screen splash (the splash image, or the app icon) until
  /// the first page has loaded.
  final bool splashEnabled;
  final String splashBackgroundColor;

  /// Light, dark, or follow the phone's dark theme setting.
  final AppTheme theme;

  /// Hides the status and navigation bars; a swipe from the edge shows them for a moment.
  final bool fullscreen;

  /// Stops the screen from turning off while the app is open.
  final bool keepScreenOn;

  Map<String, Object?> toJson() => {
        'statusBarColor': statusBarColor,
        'navigationBarColor': navigationBarColor,
        'splashEnabled': splashEnabled,
        'splashBackgroundColor': splashBackgroundColor,
        'theme': theme.name,
        'fullscreen': fullscreen,
        'keepScreenOn': keepScreenOn,
      };

  factory AppearanceSettings.fromJson(Map<String, Object?> json) => AppearanceSettings(
        statusBarColor: json['statusBarColor'] as String? ?? '#000000',
        navigationBarColor: json['navigationBarColor'] as String? ?? '#000000',
        splashEnabled: json['splashEnabled'] as bool? ?? false,
        splashBackgroundColor: json['splashBackgroundColor'] as String? ?? '#FFFFFF',
        theme: _byName(AppTheme.values, json['theme'], AppTheme.light),
        fullscreen: json['fullscreen'] as bool? ?? false,
        keepScreenOn: json['keepScreenOn'] as bool? ?? false,
      );

  AppearanceSettings copyWith({
    String? statusBarColor,
    String? navigationBarColor,
    bool? splashEnabled,
    String? splashBackgroundColor,
    AppTheme? theme,
    bool? fullscreen,
    bool? keepScreenOn,
  }) =>
      AppearanceSettings(
        statusBarColor: statusBarColor ?? this.statusBarColor,
        navigationBarColor: navigationBarColor ?? this.navigationBarColor,
        splashEnabled: splashEnabled ?? this.splashEnabled,
        splashBackgroundColor: splashBackgroundColor ?? this.splashBackgroundColor,
        theme: theme ?? this.theme,
        fullscreen: fullscreen ?? this.fullscreen,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      );
}

/// The portable `project.json` manifest. Never contains signing secrets.
class ProjectManifest {
  const ProjectManifest({
    required this.id,
    required this.name,
    required this.source,
    required this.android,
    this.iconPath,
    this.splashPath,
    this.orientation = Orientation.unspecified,
    this.webView = const WebViewSettings(),
    this.appearance = const AppearanceSettings(),
    this.permissions = const [],
    this.internetAccess = false,
    this.offlineFallbackPage,
    this.buildProfiles = const ['debug'],
    this.exportFormats = const ['apk'],
    this.releaseCertSha256,
    this.shortcuts = const [],
    this.optimizeAssets = false,
    this.appLock = false,
    this.devices = const DeviceSettings(),
  });

  final String id;
  final String name;
  final ProjectSource source;
  final AndroidSettings android;

  /// Paths relative to the project directory, e.g. `branding/icon.png`.
  final String? iconPath;
  final String? splashPath;
  final Orientation orientation;
  final WebViewSettings webView;
  final AppearanceSettings appearance;

  /// Additional Android permissions explicitly requested by the user.
  final List<String> permissions;

  /// Network access for local projects. URL projects always require it.
  final bool internetAccess;

  /// Page inside `source/` shown when a URL project cannot load, e.g. `offline.html`.
  final String? offlineFallbackPage;
  final List<String> buildProfiles;
  final List<String> exportFormats;

  /// SHA-256 fingerprint of the certificate used for the first release.
  /// Only a reference: keys and passwords never go into project.json.
  /// Updates must be signed with the same key, so later releases are
  /// checked against it.
  final String? releaseCertSha256;

  /// Long-press menu on the app icon (Android 7.1+).
  final List<AppShortcut> shortcuts;

  /// Make CSS, JSON and images smaller in the built app (the project files stay as they are).
  final bool optimizeAssets;

  /// Asks for the fingerprint, face or screen lock (PIN, pattern, password)
  /// when the app opens and after 30 seconds in the background.
  final bool appLock;

  final DeviceSettings devices;

  bool get requiresInternet => internetAccess || source.type == SourceType.url;

  Map<String, Object?> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'id': id,
        'name': name,
        'source': source.toJson(),
        'android': android.toJson(),
        'branding': {'icon': iconPath, 'splash': splashPath},
        'orientation': orientation.name,
        'webView': webView.toJson(),
        'appearance': appearance.toJson(),
        'permissions': permissions,
        'network': {'internet': internetAccess},
        'offline': {'fallbackPage': offlineFallbackPage},
        'buildProfiles': buildProfiles,
        'exportFormats': exportFormats,
        'signing': {'releaseCertSha256': releaseCertSha256},
        'shortcuts': [for (final s in shortcuts) s.toJson()],
        'build': {'optimizeAssets': optimizeAssets},
        'security': {'appLock': appLock},
        'devices': devices.toJson(),
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Parses a manifest that is already at [currentSchemaVersion].
  /// Use [ManifestMigrator] for manifests read from disk.
  factory ProjectManifest.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version != currentSchemaVersion) {
      throw FormatException('Expected schema $currentSchemaVersion, got $version');
    }
    final branding = (json['branding'] as Map?)?.cast<String, Object?>() ?? const {};
    final network = (json['network'] as Map?)?.cast<String, Object?>() ?? const {};
    final offline = (json['offline'] as Map?)?.cast<String, Object?>() ?? const {};
    return ProjectManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      source: ProjectSource.fromJson((json['source'] as Map).cast()),
      android: AndroidSettings.fromJson((json['android'] as Map).cast()),
      iconPath: branding['icon'] as String?,
      splashPath: branding['splash'] as String?,
      orientation: Orientation.values.byName(json['orientation'] as String? ?? 'unspecified'),
      webView: WebViewSettings.fromJson((json['webView'] as Map?)?.cast() ?? const {}),
      appearance: AppearanceSettings.fromJson((json['appearance'] as Map?)?.cast() ?? const {}),
      permissions: [...?(json['permissions'] as List?)?.cast<String>()],
      internetAccess: network['internet'] as bool? ?? false,
      offlineFallbackPage: offline['fallbackPage'] as String?,
      buildProfiles: [...?(json['buildProfiles'] as List?)?.cast<String>()],
      exportFormats: [...?(json['exportFormats'] as List?)?.cast<String>()],
      releaseCertSha256: ((json['signing'] as Map?)?.cast<String, Object?>() ?? const {})['releaseCertSha256'] as String?,
      shortcuts: [
        for (final s in (json['shortcuts'] as List?) ?? const [])
          if (s is Map) AppShortcut.fromJson(s.cast()),
      ],
      optimizeAssets: ((json['build'] as Map?)?['optimizeAssets'] as bool?) ?? false,
      appLock: ((json['security'] as Map?)?['appLock'] as bool?) ?? false,
      devices: DeviceSettings.fromJson((json['devices'] as Map?)?.cast() ?? const {}),
    );
  }

  /// Nullable fields take a function so they can be cleared: `splashPath: () => null`.
  ProjectManifest copyWith({
    String? name,
    ProjectSource? source,
    AndroidSettings? android,
    String? iconPath,
    String? Function()? splashPath,
    Orientation? orientation,
    WebViewSettings? webView,
    AppearanceSettings? appearance,
    List<String>? permissions,
    bool? internetAccess,
    String? Function()? offlineFallbackPage,
    String? Function()? releaseCertSha256,
    List<AppShortcut>? shortcuts,
    bool? optimizeAssets,
    bool? appLock,
    DeviceSettings? devices,
  }) =>
      ProjectManifest(
        id: id,
        name: name ?? this.name,
        source: source ?? this.source,
        android: android ?? this.android,
        iconPath: iconPath ?? this.iconPath,
        splashPath: splashPath != null ? splashPath() : this.splashPath,
        orientation: orientation ?? this.orientation,
        webView: webView ?? this.webView,
        appearance: appearance ?? this.appearance,
        permissions: permissions ?? this.permissions,
        internetAccess: internetAccess ?? this.internetAccess,
        offlineFallbackPage: offlineFallbackPage != null ? offlineFallbackPage() : this.offlineFallbackPage,
        buildProfiles: buildProfiles,
        exportFormats: exportFormats,
        releaseCertSha256: releaseCertSha256 != null ? releaseCertSha256() : this.releaseCertSha256,
        shortcuts: shortcuts ?? this.shortcuts,
        optimizeAssets: optimizeAssets ?? this.optimizeAssets,
        appLock: appLock ?? this.appLock,
        devices: devices ?? this.devices,
      );
}

/// Random RFC 4122 version 4 identifier for stable project IDs.
String newProjectId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Reads an enum stored by name; unknown or missing values (e.g. from a newer
/// release) fall back to [fallback] instead of failing the whole project.
T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
