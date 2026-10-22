import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import 'engine/desktop_engine.dart';
import 'engine/on_device_engine.dart';

/// App-wide state: the workspace, the project list, the build engine and
/// the theme. Screens listen to it and call its methods.
class AppController extends ChangeNotifier {
  AppController({required this.workspaceDir, this.engine}) : store = ProjectStore(workspaceDir) {
    _loadSettings();
    refresh();
  }

  final String workspaceDir;
  final ProjectStore store;

  /// Null on platforms without a local build engine wired up yet.
  final ProjectBuildEngine? engine;

  /// The phone engine (Install, Share, Save via Android), when on Android.
  OnDeviceBuildEngine? get deviceEngine => switch (engine) { final OnDeviceBuildEngine e => e, _ => null };

  /// The Windows engine (Gradle, Save as, Show in folder), when on Windows.
  DesktopBuildEngine? get desktopEngine => switch (engine) { final DesktopBuildEngine e => e, _ => null };

  /// Release keys kept by the app, if this platform has a key store.
  KeyManager? get keys => switch (engine) { final KeyManager k => k, _ => null };

  List<ProjectHandle> projects = const [];
  List<BrokenProject> brokenProjects = const [];
  ThemeMode themeMode = ThemeMode.dark;

  /// Project ids with a build in progress.
  final Set<String> building = {};

  String get _settingsFile => p.join(workspaceDir, 'settings.json');

  void refresh() {
    final (ok, broken) = store.listProjects();
    projects = ok;
    brokenProjects = broken;
    notifyListeners();
  }

  ProjectHandle? project(String id) => projects.where((x) => x.manifest.id == id).firstOrNull;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    Directory(workspaceDir).createSync(recursive: true);
    File(_settingsFile).writeAsStringSync(jsonEncode({'themeMode': mode.name}));
    notifyListeners();
  }

  void _loadSettings() {
    try {
      final j = jsonDecode(File(_settingsFile).readAsStringSync()) as Map;
      themeMode = ThemeMode.values.byName(j['themeMode'] as String);
    } on Object {
      // Missing or unreadable settings: keep defaults.
    }
  }

  Future<ImportReport> importZip(String zipPath, String name, String applicationId) async {
    final report = await store.importZip(zipPath: zipPath, name: name, applicationId: applicationId);
    refresh();
    return report;
  }

  Future<ImportReport> importFiles(List<String> paths, String name, String applicationId) async {
    final report = await store.importFiles(paths: paths, name: name, applicationId: applicationId);
    refresh();
    return report;
  }

  ProjectHandle createFromUrl(String url, String name, String applicationId) {
    final project = store.createFromUrl(url: url, name: name, applicationId: applicationId);
    refresh();
    return project;
  }

  ProjectHandle update(ProjectHandle project, ProjectManifest manifest) {
    final updated = store.update(project, manifest);
    refresh();
    return updated;
  }

  ProjectHandle setIcon(ProjectHandle project, String pngPath) {
    final updated = store.setIcon(project, pngPath);
    refresh();
    return updated;
  }

  ProjectHandle setSplash(ProjectHandle project, String pngPath) => _refreshAfter(store.setSplash(project, pngPath));
  ProjectHandle clearSplash(ProjectHandle project) => _refreshAfter(store.clearSplash(project));
  ProjectHandle setOfflinePage(ProjectHandle project, String htmlPath) =>
      _refreshAfter(store.setOfflinePage(project, htmlPath));
  ProjectHandle clearOfflinePage(ProjectHandle project) => _refreshAfter(store.clearOfflinePage(project));

  ProjectHandle _refreshAfter(ProjectHandle project) {
    refresh();
    return project;
  }

  void delete(ProjectHandle project) {
    store.delete(project);
    refresh();
  }

  /// Builds a Windows .exe (Windows only) and records it in the project's history.
  Future<BuildResult> buildExe(ProjectHandle project, BuildLogSink log, {bool debug = false}) async {
    final desktop = desktopEngine;
    if (desktop == null) {
      return const BuildResult(BuildStatus.failed,
          message: 'Windows apps can be built on Windows only.', duration: Duration.zero);
    }
    building.add(project.manifest.id);
    notifyListeners();
    try {
      final result =
          await desktop.buildExe(project, outputPath: project.windowsExePath(debug: debug), log: log, debug: debug);
      final artifact = result.artifactPath;
      store.recordBuild(
        project,
        BuildRecord(
          time: DateTime.now(),
          engine: 'windows-exe',
          status: result.status.name,
          durationMs: result.duration.inMilliseconds,
          artifactPath: artifact,
          bytes: artifact == null ? null : File(artifact).lengthSync(),
          versionName: project.manifest.android.versionName,
          versionCode: project.manifest.android.versionCode,
          message: result.message,
          variant: debug ? BuildVariant.debug.name : BuildVariant.release.name,
          format: 'exe',
        ),
      );
      return result;
    } finally {
      building.remove(project.manifest.id);
      notifyListeners();
    }
  }

  /// Builds an APK and records the result in the project's history. For the
  /// first successful release, the signing certificate is remembered in the
  /// project so later releases can be checked against it.
  Future<BuildResult> build(ProjectHandle project, BuildLogSink log,
      {BuildVariant variant = BuildVariant.debug,
      ReleaseSigning? signing,
      ArtifactFormat format = ArtifactFormat.apk}) async {
    final engine = this.engine;
    if (engine == null) {
      return const BuildResult(BuildStatus.failed,
          message: 'Building on this platform is not available in this version.', duration: Duration.zero);
    }
    final release = variant == BuildVariant.release;
    if (release) {
      final blocker = store.releaseBlocker(project);
      if (blocker != null) return BuildResult(BuildStatus.failed, message: blocker, duration: Duration.zero);
    }
    building.add(project.manifest.id);
    notifyListeners();
    try {
      final result = await engine.buildProject(project,
          outputPath: format == ArtifactFormat.aab
              ? project.releaseAabPath
              : (release ? project.releaseApkPath : project.debugApkPath),
          log: log,
          variant: variant,
          signing: signing,
          format: format);
      final artifact = result.artifactPath;
      store.recordBuild(
        project,
        BuildRecord(
          time: DateTime.now(),
          engine: engine.id,
          status: result.status.name,
          durationMs: result.duration.inMilliseconds,
          artifactPath: artifact,
          bytes: artifact == null ? null : File(artifact).lengthSync(),
          versionName: project.manifest.android.versionName,
          versionCode: project.manifest.android.versionCode,
          message: result.message,
          variant: variant.name,
          signerSha256: result.signerSha256,
          format: format.name,
        ),
      );
      if (release && result.status == BuildStatus.succeeded && project.manifest.releaseCertSha256 == null) {
        store.update(project, project.manifest.copyWith(releaseCertSha256: () => result.signerSha256));
        refresh();
      }
      return result;
    } finally {
      building.remove(project.manifest.id);
      notifyListeners();
    }
  }

  /// Total bytes used by the workspace.
  int storageBytes() {
    final dir = Directory(workspaceDir);
    if (!dir.existsSync()) return 0;
    return dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .fold(0, (sum, f) => sum + f.lengthSync());
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}

/// Suggests a valid application ID from an app name, e.g. "My Shop!" -> com.example.myshop.
String suggestApplicationId(String name) {
  var slug = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  if (slug.isEmpty || !RegExp('^[a-z]').hasMatch(slug)) slug = 'app$slug';
  final id = 'com.example.$slug';
  return validateApplicationId(id) == null ? id : 'com.example.app';
}
