import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../android_generator/android_generator.dart';
import '../android_generator/resource_writers.dart';
import '../project_importer/files_importer.dart';
import '../project_importer/site_analysis.dart';
import '../project_importer/zip_importer.dart';
import 'manifest.dart';
import 'migration.dart';
import 'validation.dart';

/// A project directory on disk:
///
///     <project>/project.json
///     <project>/source/...      website files
///     <project>/branding/...    icon, splash
///     <project>/exports/...     built artifacts
class ProjectHandle {
  ProjectHandle(this.directory, this.manifest, {String? sourceDir}) : _sourceDir = sourceDir;

  final String directory;
  final ProjectManifest manifest;

  /// Set for a build copy whose site files were optimized elsewhere.
  final String? _sourceDir;

  String get sourceDir => _sourceDir ?? p.join(directory, 'source');
  String get brandingDir => p.join(directory, 'branding');
  String get exportsDir => p.join(directory, 'exports');
  String? get iconFile => manifest.iconPath == null ? null : p.join(directory, manifest.iconPath!);
  String? get splashFile => manifest.splashPath == null ? null : p.join(directory, manifest.splashPath!);

  /// Default location for a debug APK of the current version.
  String get debugApkPath =>
      p.join(exportsDir, '${manifest.android.applicationId}-${manifest.android.versionName}-debug.apk');

  /// Default location for a release APK of the current version.
  String get releaseApkPath =>
      p.join(exportsDir, '${manifest.android.applicationId}-${manifest.android.versionName}-release.apk');

  /// Default location for a release App Bundle (Google Play upload) of the current version.
  String get releaseAabPath =>
      p.join(exportsDir, '${manifest.android.applicationId}-${manifest.android.versionName}-release.aab');

  /// Default location for a Windows .exe of the current version (ADR 0007).
  String windowsExePath({bool debug = false}) => p.join(
      exportsDir, '${manifest.android.applicationId}-${manifest.android.versionName}-windows${debug ? '-debug' : ''}.exe');

  /// Default location for a Windows installer of the current version (ADR 0008).
  String windowsMsixPath() =>
      p.join(exportsDir, '${manifest.android.applicationId}-${manifest.android.versionName}-windows.msix');

  ProjectHandle withManifest(ProjectManifest m) => ProjectHandle(directory, m, sourceDir: _sourceDir);

  /// The same project, reading its site files from [dir] (used for optimized builds).
  ProjectHandle withSourceDir(String dir) => ProjectHandle(directory, manifest, sourceDir: dir);
}

/// A project directory that could not be loaded, kept so the UI can report it.
class BrokenProject {
  BrokenProject(this.directory, this.error);

  final String directory;
  final Object error;
}

class BuildRecord {
  BuildRecord({
    required this.time,
    required this.engine,
    required this.status,
    required this.durationMs,
    this.artifactPath,
    this.bytes,
    this.versionName,
    this.versionCode,
    this.message,
    this.variant = 'debug',
    this.signerSha256,
    this.format = 'apk',
  });

  final DateTime time;
  final String engine;

  /// `succeeded`, `failed` or `cancelled`.
  final String status;
  final int durationMs;
  final String? artifactPath;
  final int? bytes;
  final String? versionName;
  final int? versionCode;
  final String? message;

  /// `debug` or `release`.
  final String variant;
  final String? signerSha256;

  /// `apk` or `aab`.
  final String format;

  bool get succeeded => status == 'succeeded';
  bool get isRelease => variant == 'release';

  /// An APK or AAB, as opposed to a Windows `exe` or `msix`.
  bool get isAndroid => format == 'apk' || format == 'aab';

  Map<String, Object?> toJson() => {
        'time': time.toUtc().toIso8601String(),
        'engine': engine,
        'status': status,
        'durationMs': durationMs,
        'artifactPath': artifactPath,
        'bytes': bytes,
        'versionName': versionName,
        'versionCode': versionCode,
        'message': message,
        'variant': variant,
        'signerSha256': signerSha256,
        'format': format,
      };

  factory BuildRecord.fromJson(Map<String, Object?> j) => BuildRecord(
        time: DateTime.parse(j['time'] as String),
        engine: j['engine'] as String,
        status: j['status'] as String,
        durationMs: j['durationMs'] as int,
        artifactPath: j['artifactPath'] as String?,
        bytes: j['bytes'] as int?,
        versionName: j['versionName'] as String?,
        versionCode: j['versionCode'] as int?,
        message: j['message'] as String?,
        variant: j['variant'] as String? ?? 'debug',
        signerSha256: j['signerSha256'] as String?,
        format: j['format'] as String? ?? 'apk',
      );
}

class ImportReport {
  ImportReport(this.project, this.entryCandidates, this.missingAssets, this.fileCount);

  final ProjectHandle project;
  final List<String> entryCandidates;
  final List<MissingAsset> missingAssets;
  final int fileCount;
}

/// Result of replacing a project's website files.
class ReplaceReport {
  ReplaceReport(
    this.import, {
    required this.startPageChanged,
    required this.previousStartPage,
    required this.droppedShortcuts,
  });

  final ImportReport import;

  /// The old start page is not in the new files, so the first page found is used.
  final bool startPageChanged;
  final String previousStartPage;

  /// Shortcut pages that no longer exist and were removed.
  final List<String> droppedShortcuts;
}

/// Creates, loads and saves projects inside an app-controlled workspace.
class ProjectStore {
  ProjectStore(this.workspaceDir, {this.migrator = const ManifestMigrator()});

  final String workspaceDir;
  final ManifestMigrator migrator;

  String get projectsDir => p.join(workspaceDir, 'projects');

  /// Scratch space of desktop builds (generated Gradle projects, logs), one
  /// folder per project id. Removed together with the project.
  String get buildsDir => p.join(workspaceDir, 'builds');

  ProjectHandle load(String projectDir) {
    final text = File(p.join(projectDir, 'project.json')).readAsStringSync();
    return ProjectHandle(projectDir, migrator.load(text));
  }

  void save(ProjectHandle project) {
    final file = File(p.join(project.directory, 'project.json'));
    final tmp = File('${file.path}.tmp')..writeAsStringSync(project.manifest.toJsonString());
    tmp.renameSync(file.path);
  }

  /// Validates and saves [manifest] for [project]. Throws on validation errors.
  ProjectHandle update(ProjectHandle project, ProjectManifest manifest) {
    final errors = validateManifest(manifest).where((i) => i.severity == IssueSeverity.error).toList();
    if (errors.isNotEmpty) throw InvalidProjectException(errors);
    if (manifest.source.type == SourceType.local &&
        !File(p.join(project.sourceDir, manifest.source.entry)).existsSync()) {
      throw InvalidProjectException(
          [ValidationIssue('source.entry', 'Entry file "${manifest.source.entry}" does not exist')]);
    }
    final offline = manifest.offlineFallbackPage;
    if (offline != null && !File(p.join(project.sourceDir, offline)).existsSync()) {
      throw InvalidProjectException([ValidationIssue('offline.fallbackPage', 'Offline page "$offline" does not exist')]);
    }
    if (manifest.source.type == SourceType.local) {
      for (final s in manifest.shortcuts) {
        if (!File(p.join(project.sourceDir, shortcutFilePath(s.page))).existsSync()) {
          throw InvalidProjectException([ValidationIssue('shortcuts', 'Shortcut page "${s.page}" does not exist')]);
        }
      }
    }
    final updated = project.withManifest(manifest);
    save(updated);
    return updated;
  }

  /// All projects in the workspace, newest first. Unreadable ones are
  /// returned separately instead of hiding them.
  (List<ProjectHandle>, List<BrokenProject>) listProjects() {
    final dir = Directory(projectsDir);
    if (!dir.existsSync()) return (const [], const []);
    final ok = <(ProjectHandle, DateTime)>[];
    final broken = <BrokenProject>[];
    for (final d in dir.listSync().whereType<Directory>()) {
      final file = File(p.join(d.path, 'project.json'));
      if (!file.existsSync()) continue;
      try {
        ok.add((load(d.path), file.lastModifiedSync()));
      } on Object catch (e) {
        broken.add(BrokenProject(d.path, e));
      }
    }
    ok.sort((a, b) => b.$2.compareTo(a.$2));
    return ([for (final e in ok) e.$1], broken);
  }

  void delete(ProjectHandle project) {
    final dir = Directory(project.directory);
    if (!p.isWithin(p.absolute(projectsDir), p.absolute(dir.path))) {
      throw ArgumentError.value(project.directory, 'project', 'is outside the workspace');
    }
    // Build scratch first: if it is locked (a build still running), the
    // project stays and the delete can be retried.
    final builds = Directory(p.join(buildsDir, project.manifest.id));
    if (p.isWithin(p.absolute(buildsDir), p.absolute(builds.path)) && builds.existsSync()) {
      builds.deleteSync(recursive: true);
    }
    dir.deleteSync(recursive: true);
  }

  /// Copies a validated square PNG into `branding/icon.png` and saves the manifest.
  ProjectHandle setIcon(ProjectHandle project, String pngPath) {
    final bytes = File(pngPath).readAsBytesSync();
    final info = readPngInfo(bytes);
    if (info == null) {
      throw InvalidProjectException([const ValidationIssue('branding.icon', 'Icon must be a PNG file')]);
    }
    if (info.width != info.height || info.width < AndroidGenerator.minIconSize) {
      throw InvalidProjectException([ValidationIssue('branding.icon',
          'Icon must be square and at least ${AndroidGenerator.minIconSize}px (got ${info.width}x${info.height})')]);
    }
    Directory(project.brandingDir).createSync(recursive: true);
    File(p.join(project.brandingDir, 'icon.png')).writeAsBytesSync(bytes);
    return update(project, project.manifest.copyWith(iconPath: 'branding/icon.png'));
  }

  static const maxSplashPixels = 4096;
  static const maxSplashBytes = 2 * 1024 * 1024;

  /// Copies a PNG into `branding/splash.png` and saves the manifest.
  ProjectHandle setSplash(ProjectHandle project, String pngPath) {
    final bytes = File(pngPath).readAsBytesSync();
    final info = readPngInfo(bytes);
    if (info == null) {
      throw InvalidProjectException([const ValidationIssue('branding.splash', 'Splash image must be a PNG file')]);
    }
    if (bytes.length > maxSplashBytes || info.width > maxSplashPixels || info.height > maxSplashPixels) {
      throw InvalidProjectException([const ValidationIssue('branding.splash',
          'Splash image must be at most $maxSplashPixels px per side and 2 MB')]);
    }
    Directory(project.brandingDir).createSync(recursive: true);
    File(p.join(project.brandingDir, 'splash.png')).writeAsBytesSync(bytes);
    return update(project, project.manifest.copyWith(splashPath: () => 'branding/splash.png'));
  }

  ProjectHandle clearSplash(ProjectHandle project) {
    final f = File(p.join(project.brandingDir, 'splash.png'));
    if (f.existsSync()) f.deleteSync();
    return update(project, project.manifest.copyWith(splashPath: () => null));
  }

  static const offlinePageName = 'offline.html';
  static const maxOfflinePageBytes = 2 * 1024 * 1024;

  /// Copies a single, self-contained HTML file into `source/offline.html`
  /// and uses it as the page shown when a URL app cannot load.
  ProjectHandle setOfflinePage(ProjectHandle project, String htmlPath) {
    final file = File(htmlPath);
    if (file.lengthSync() > maxOfflinePageBytes) {
      throw InvalidProjectException([const ValidationIssue('offline.fallbackPage', 'Offline page must be at most 2 MB')]);
    }
    final text = file.readAsStringSync();
    if (!RegExp(r'<(html|body|!doctype)', caseSensitive: false).hasMatch(text)) {
      throw InvalidProjectException([const ValidationIssue('offline.fallbackPage', 'That file does not look like HTML')]);
    }
    Directory(project.sourceDir).createSync(recursive: true);
    File(p.join(project.sourceDir, offlinePageName)).writeAsStringSync(text);
    return update(project, project.manifest.copyWith(offlineFallbackPage: () => offlinePageName));
  }

  ProjectHandle clearOfflinePage(ProjectHandle project) {
    final page = project.manifest.offlineFallbackPage;
    if (page != null && project.manifest.source.type == SourceType.url) {
      final f = File(p.join(project.sourceDir, page));
      if (f.existsSync()) f.deleteSync();
    }
    return update(project, project.manifest.copyWith(offlineFallbackPage: () => null));
  }

  /// Problems that should stop a release build, e.g. a version code that
  /// is not higher than the last release (Android refuses such updates and
  /// Google Play rejects the upload). Windows builds don't count: they
  /// share the version but never reach Android.
  String? releaseBlocker(ProjectHandle project) {
    final last = buildHistory(project).where((b) => b.isAndroid && b.isRelease && b.succeeded).firstOrNull;
    final code = project.manifest.android.versionCode;
    if (last?.versionCode != null && code <= last!.versionCode!) {
      return 'Version code $code is not higher than the last release (${last.versionCode}). '
          'Increase it in Settings before building a new release.';
    }
    return null;
  }

  static const _historyLimit = 50;

  List<BuildRecord> buildHistory(ProjectHandle project) {
    final f = File(p.join(project.exportsDir, 'builds.json'));
    if (!f.existsSync()) return const [];
    final list = jsonDecode(f.readAsStringSync()) as List;
    return [for (final e in list) BuildRecord.fromJson((e as Map).cast())];
  }

  void recordBuild(ProjectHandle project, BuildRecord record) {
    final history = [record, ...buildHistory(project)].take(_historyLimit).toList();
    Directory(project.exportsDir).createSync(recursive: true);
    File(p.join(project.exportsDir, 'builds.json'))
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert([for (final r in history) r.toJson()]));
  }

  /// Creates a project that wraps a live website. [url] should already have
  /// been checked with UrlProbe; it is validated again here.
  ProjectHandle createFromUrl({
    required String url,
    required String name,
    required String applicationId,
    List<String> allowedHosts = const [],
  }) {
    final manifest = ProjectManifest(
      id: newProjectId(),
      name: name,
      source: ProjectSource.url(url),
      android: AndroidSettings(applicationId: applicationId),
      webView: WebViewSettings(allowedHosts: allowedHosts, pullToRefresh: true),
    );
    final errors = validateManifest(manifest).where((i) => i.severity == IssueSeverity.error).toList();
    if (errors.isNotEmpty) throw InvalidProjectException(errors);
    final dir = p.join(projectsDir, manifest.id);
    Directory(p.join(dir, 'source')).createSync(recursive: true);
    final handle = ProjectHandle(dir, manifest);
    save(handle);
    return handle;
  }

  /// Imports a website ZIP as a new local project.
  Future<ImportReport> importZip({
    required String zipPath,
    required String name,
    required String applicationId,
    String? iconPng,
  }) =>
      _importInto(name, applicationId, iconPng, (source) async => (await extractWebsiteZip(zipPath, source)).files);

  /// Imports individually picked files (an .html page and optionally its CSS,
  /// JavaScript, images, fonts) as a new local project. Files are moved into
  /// the folders the pages link to; see [importLooseFiles].
  Future<ImportReport> importFiles({
    required List<String> paths,
    required String name,
    required String applicationId,
    String? iconPng,
  }) =>
      _importInto(name, applicationId, iconPng, (source) async {
        final placed = importLooseFiles(paths, source);
        return placed.files;
      });

  /// Replaces the website of an existing local project with a ZIP, keeping
  /// the app's name, package ID, icon, settings, keys and build history.
  Future<ReplaceReport> replaceWithZip(ProjectHandle project, String zipPath) =>
      _replaceSource(project, (source) async => (await extractWebsiteZip(zipPath, source)).files);

  /// Like [replaceWithZip], from individually picked files.
  Future<ReplaceReport> replaceWithFiles(ProjectHandle project, List<String> paths) =>
      _replaceSource(project, (source) async => importLooseFiles(paths, source).files);

  /// Fills a fresh folder next to `source/`, then swaps it in. If anything
  /// fails before the swap, the old website is untouched.
  Future<ReplaceReport> _replaceSource(
    ProjectHandle project,
    Future<List<String>> Function(String sourceDir) fill,
  ) async {
    if (project.manifest.source.type != SourceType.local) {
      throw InvalidProjectException(
          [const ValidationIssue('source', 'Only projects made from HTML files or a ZIP can have their files replaced')]);
    }
    final current = p.normalize(project.sourceDir);
    final fresh = '$current.new';
    final old = '$current.old';
    for (final d in [fresh, old]) {
      if (Directory(d).existsSync()) Directory(d).deleteSync(recursive: true);
    }
    final List<String> files;
    try {
      files = await fill(fresh);
    } catch (_) {
      if (Directory(fresh).existsSync()) Directory(fresh).deleteSync(recursive: true);
      rethrow;
    }
    final candidates = findEntryCandidates(files);
    if (candidates.isEmpty) {
      Directory(fresh).deleteSync(recursive: true);
      throw ArchiveRejectedException('no .html file found');
    }
    final m = project.manifest;
    // Keep the start page when the new website still has it.
    final entry = files.contains(m.source.entry) ? m.source.entry : candidates.first;
    final keptShortcuts = [
      for (final s in m.shortcuts)
        if (files.contains(shortcutFilePath(s.page))) s
    ];
    final droppedShortcuts = [
      for (final s in m.shortcuts)
        if (!files.contains(shortcutFilePath(s.page))) s.page
    ];
    final offline = m.offlineFallbackPage;
    final keepOffline = offline != null && files.contains(offline);

    Directory(current).renameSync(old);
    try {
      Directory(fresh).renameSync(current);
    } catch (_) {
      Directory(old).renameSync(current);
      rethrow;
    }
    final ProjectHandle updated;
    try {
      updated = update(
        project,
        m.copyWith(
          source: ProjectSource.local(entry),
          shortcuts: keptShortcuts,
          offlineFallbackPage: () => keepOffline ? offline : null,
        ),
      );
    } catch (_) {
      // Put the old website back.
      Directory(current).deleteSync(recursive: true);
      Directory(old).renameSync(current);
      rethrow;
    }
    Directory(old).deleteSync(recursive: true);
    return ReplaceReport(
      ImportReport(updated, candidates, findMissingAssets(updated.sourceDir, files), files.length),
      startPageChanged: entry != m.source.entry,
      previousStartPage: m.source.entry,
      droppedShortcuts: droppedShortcuts,
    );
  }

  Future<ImportReport> _importInto(
    String name,
    String applicationId,
    String? iconPng,
    Future<List<String>> Function(String sourceDir) fill,
  ) async {
    final id = newProjectId();
    final dir = p.join(projectsDir, id);
    Directory(dir).createSync(recursive: true);
    try {
      final files = await fill(p.join(dir, 'source'));
      final candidates = findEntryCandidates(files);
      if (candidates.isEmpty) throw ArchiveRejectedException('no .html file found');
      String? iconRel;
      if (iconPng != null) {
        Directory(p.join(dir, 'branding')).createSync();
        File(iconPng).copySync(p.join(dir, 'branding', 'icon.png'));
        iconRel = 'branding/icon.png';
      }
      final manifest = ProjectManifest(
        id: id,
        name: name,
        source: ProjectSource.local(candidates.first),
        android: AndroidSettings(applicationId: applicationId),
        iconPath: iconRel,
      );
      final errors = validateManifest(manifest).where((i) => i.severity == IssueSeverity.error);
      if (errors.isNotEmpty) throw InvalidProjectException(errors.toList());
      final handle = ProjectHandle(dir, manifest);
      save(handle);
      return ImportReport(handle, candidates, findMissingAssets(handle.sourceDir, files), files.length);
    } catch (_) {
      Directory(dir).deleteSync(recursive: true);
      rethrow;
    }
  }
}

class InvalidProjectException implements Exception {
  InvalidProjectException(this.issues);

  final List<ValidationIssue> issues;

  @override
  String toString() => 'Invalid project:\n${issues.join('\n')}';
}
