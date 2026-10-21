import 'dart:convert';

import 'manifest.dart';

typedef ManifestMigration = Map<String, Object?> Function(Map<String, Object?> json);

/// Upgrades shipped with this release, keyed by the version they upgrade from.
const Map<int, ManifestMigration> builtInMigrations = {1: migrateV1ToV2};

/// Schema 2 adds `appearance` and the WebView `pullToRefresh` / `fileUploads`
/// switches. Values chosen to keep existing apps behaving as before, except
/// URL apps get pull-to-refresh on, which is what new URL projects default to.
Map<String, Object?> migrateV1ToV2(Map<String, Object?> json) {
  final webView = Map<String, Object?>.of((json['webView'] as Map?)?.cast<String, Object?>() ?? const {});
  final source = (json['source'] as Map?)?.cast<String, Object?>() ?? const {};
  webView.putIfAbsent('pullToRefresh', () => source['type'] == 'url');
  webView.putIfAbsent('fileUploads', () => true);
  return {
    ...json,
    'webView': webView,
    'appearance': json['appearance'] ?? const AppearanceSettings().toJson(),
  };
}

/// Upgrades raw `project.json` content step by step to [currentSchemaVersion].
///
/// Each entry in [migrations] upgrades from its key version to key + 1.
/// Manifests written by a newer release are rejected rather than guessed at.
class ManifestMigrator {
  const ManifestMigrator({this.migrations = builtInMigrations, this.targetVersion = currentSchemaVersion});

  final Map<int, ManifestMigration> migrations;
  final int targetVersion;

  Map<String, Object?> migrate(Map<String, Object?> json) {
    final declared = json['schemaVersion'];
    if (declared is! int || declared < 1) {
      throw const FormatException('project.json is missing a valid schemaVersion');
    }
    var version = declared;
    if (version > targetVersion) {
      throw FormatException(
          'project.json uses schema $version, newer than supported $targetVersion. Update the app.');
    }
    var current = Map<String, Object?>.of(json);
    while (version < targetVersion) {
      final step = migrations[version];
      if (step == null) throw FormatException('No migration from schema $version');
      current = step(current);
      version = version + 1;
      current['schemaVersion'] = version;
    }
    return current;
  }

  ProjectManifest load(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('project.json must be a JSON object');
    return ProjectManifest.fromJson(migrate(decoded.cast<String, Object?>()));
  }
}
