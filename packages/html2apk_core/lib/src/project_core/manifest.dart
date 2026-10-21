import 'dart:convert';
import 'dart:math';

/// Current version of the `project.json` schema written by this release.
const int currentSchemaVersion = 1;

enum SourceType { local, url }

enum Orientation { unspecified, portrait, landscape }

enum ExternalLinkPolicy { browser, block }

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
  });

  final bool javaScriptEnabled;
  final bool domStorageEnabled;
  final ExternalLinkPolicy externalLinks;

  /// Extra https hosts allowed to load inside the WebView.
  final List<String> allowedHosts;
  final String? userAgentSuffix;

  Map<String, Object?> toJson() => {
        'javaScriptEnabled': javaScriptEnabled,
        'domStorageEnabled': domStorageEnabled,
        'externalLinks': externalLinks.name,
        'allowedHosts': allowedHosts,
        'userAgentSuffix': userAgentSuffix,
      };

  WebViewSettings copyWith({
    bool? javaScriptEnabled,
    bool? domStorageEnabled,
    ExternalLinkPolicy? externalLinks,
    List<String>? allowedHosts,
    String? Function()? userAgentSuffix,
  }) =>
      WebViewSettings(
        javaScriptEnabled: javaScriptEnabled ?? this.javaScriptEnabled,
        domStorageEnabled: domStorageEnabled ?? this.domStorageEnabled,
        externalLinks: externalLinks ?? this.externalLinks,
        allowedHosts: allowedHosts ?? this.allowedHosts,
        userAgentSuffix: userAgentSuffix != null ? userAgentSuffix() : this.userAgentSuffix,
      );

  factory WebViewSettings.fromJson(Map<String, Object?> json) => WebViewSettings(
        javaScriptEnabled: json['javaScriptEnabled'] as bool? ?? true,
        domStorageEnabled: json['domStorageEnabled'] as bool? ?? true,
        externalLinks: ExternalLinkPolicy.values.byName(json['externalLinks'] as String? ?? 'browser'),
        allowedHosts: [...?(json['allowedHosts'] as List?)?.cast<String>()],
        userAgentSuffix: json['userAgentSuffix'] as String?,
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
    this.permissions = const [],
    this.internetAccess = false,
    this.offlineFallbackPage,
    this.buildProfiles = const ['debug'],
    this.exportFormats = const ['apk'],
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

  /// Additional Android permissions explicitly requested by the user.
  final List<String> permissions;

  /// Network access for local projects. URL projects always require it.
  final bool internetAccess;
  final String? offlineFallbackPage;
  final List<String> buildProfiles;
  final List<String> exportFormats;

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
        'permissions': permissions,
        'network': {'internet': internetAccess},
        'offline': {'fallbackPage': offlineFallbackPage},
        'buildProfiles': buildProfiles,
        'exportFormats': exportFormats,
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
      permissions: [...?(json['permissions'] as List?)?.cast<String>()],
      internetAccess: network['internet'] as bool? ?? false,
      offlineFallbackPage: offline['fallbackPage'] as String?,
      buildProfiles: [...?(json['buildProfiles'] as List?)?.cast<String>()],
      exportFormats: [...?(json['exportFormats'] as List?)?.cast<String>()],
    );
  }

  ProjectManifest copyWith({
    String? name,
    ProjectSource? source,
    AndroidSettings? android,
    String? iconPath,
    Orientation? orientation,
    WebViewSettings? webView,
    List<String>? permissions,
    bool? internetAccess,
  }) =>
      ProjectManifest(
        id: id,
        name: name ?? this.name,
        source: source ?? this.source,
        android: android ?? this.android,
        iconPath: iconPath ?? this.iconPath,
        splashPath: splashPath,
        orientation: orientation ?? this.orientation,
        webView: webView ?? this.webView,
        permissions: permissions ?? this.permissions,
        internetAccess: internetAccess ?? this.internetAccess,
        offlineFallbackPage: offlineFallbackPage,
        buildProfiles: buildProfiles,
        exportFormats: exportFormats,
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
