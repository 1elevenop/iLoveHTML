import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import 'app_lock.dart';
import 'app_settings.dart';
import 'update_check.dart';
import 'engine/desktop_engine.dart';
import 'engine/on_device_engine.dart';

/// App-wide state: the workspace, the project list and the build engine.
/// Screens listen to it and call its methods.
class AppController extends ChangeNotifier {
  AppController({required this.workspaceDir, this.engine, AppSettings? settings, AppLock? lock, UpdateChecker? updates})
      : store = ProjectStore(workspaceDir),
        settings = settings ?? AppSettings.memory(),
        lock = lock ?? AppLock(MemoryLockStorage()),
        updates = updates ?? UpdateChecker.disabled() {
    refresh();
  }

  final String workspaceDir;

  /// Language, appearance and animation preferences.
  final AppSettings settings;

  /// PIN, password or fingerprint lock in front of the whole app.
  final AppLock lock;

  /// Finds newer iLoveHTML releases on GitHub.
  final UpdateChecker updates;
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

  /// Project ids with a build in progress.
  final Set<String> building = {};

  void refresh() {
    final (ok, broken) = store.listProjects();
    projects = ok;
    brokenProjects = broken;
    notifyListeners();
  }

  ProjectHandle? project(String id) => projects.where((x) => x.manifest.id == id).firstOrNull;

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

  /// Swaps the website files of a local project; settings, icon and keys stay.
  Future<ReplaceReport> replaceWithZip(ProjectHandle project, String zipPath) async {
    final report = await store.replaceWithZip(project, zipPath);
    refresh();
    return report;
  }

  Future<ReplaceReport> replaceWithFiles(ProjectHandle project, List<String> paths) async {
    final report = await store.replaceWithFiles(project, paths);
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

  /// Writes a backup of [project] into its exports folder and returns its path.
  Future<String> backUp(ProjectHandle project) async {
    final out = p.join(project.exportsDir, backupFileName(project));
    await exportProjectBackup(project, out);
    return out;
  }

  /// Restores a backup file as a new project.
  Future<ProjectHandle> restoreBackup(String path) async {
    final project = await importProjectBackup(store, path);
    refresh();
    return project;
  }

  void delete(ProjectHandle project) {
    store.delete(project);
    refresh();
  }

  /// Builds a Windows .exe (Windows only) and records it in the project's history.
  Future<BuildResult> buildExe(ProjectHandle project, BuildLogSink log, {bool debug = false}) =>
      _buildWindows(project, 'exe', log, debug: debug,
          (d, staged) => d.buildExe(staged, outputPath: project.windowsExePath(debug: debug), log: log, debug: debug));

  /// Builds a signed Windows installer (.msix) and records it in the history.
  Future<BuildResult> buildMsix(ProjectHandle project, BuildLogSink log) => _buildWindows(
      project, 'msix', log, (d, staged) => d.buildMsix(staged, outputPath: project.windowsMsixPath(), log: log));

  /// Temporary copies of optimized sites live here during a build.
  String get _stagingRoot => p.join(workspaceDir, 'staging');

  Future<BuildResult> _buildWindows(ProjectHandle project, String format, BuildLogSink log,
      Future<BuildResult> Function(DesktopBuildEngine, ProjectHandle staged) run,
      {bool debug = false}) async {
    final desktop = desktopEngine;
    if (desktop == null) {
      return const BuildResult(BuildStatus.failed,
          message: 'Windows apps can be built on Windows only.', duration: Duration.zero);
    }
    building.add(project.manifest.id);
    notifyListeners();
    StagedBuild? staged;
    try {
      staged = await stageForBuild(project, stagingRoot: _stagingRoot, log: log);
      final result = await run(desktop, staged.project);
      final artifact = result.artifactPath;
      store.recordBuild(
        project,
        BuildRecord(
          time: DateTime.now(),
          engine: 'windows-$format',
          status: result.status.name,
          durationMs: result.duration.inMilliseconds,
          artifactPath: artifact,
          bytes: artifact == null ? null : File(artifact).lengthSync(),
          versionName: project.manifest.android.versionName,
          versionCode: project.manifest.android.versionCode,
          message: result.message,
          variant: debug ? BuildVariant.debug.name : BuildVariant.release.name,
          format: format,
        ),
      );
      return result;
    } finally {
      staged?.dispose();
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
    StagedBuild? staged;
    try {
      staged = await stageForBuild(project, stagingRoot: _stagingRoot, log: log);
      final result = await engine.buildProject(staged.project,
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
      staged?.dispose();
      building.remove(project.manifest.id);
      notifyListeners();
    }
  }

  /// Total bytes used by the workspace. Never throws: entries that cannot be
  /// read, or vanish while counting (a build is running), are skipped. On
  /// Windows the walk uses a `\\?\` path, because Gradle's build folders go
  /// past the 260 characters a plain path can reach.
  int storageBytes() {
    var root = p.normalize(p.absolute(workspaceDir));
    if (Platform.isWindows && !root.startsWith(r'\\')) root = '\\\\?\\$root';
    return _bytesUnder(Directory(root));
  }

  static int _bytesUnder(Directory dir) {
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      return 0;
    }
    var sum = 0;
    for (final e in entries) {
      try {
        if (e is File) {
          sum += e.lengthSync();
        } else if (e is Directory) {
          sum += _bytesUnder(e);
        }
      } on FileSystemException {
        // Removed while counting.
      }
    }
    return sum;
  }
}

/// Suggests a valid application ID from an app name, e.g. "My Shop!" -> com.example.myshop.
String suggestApplicationId(String name) {
  var slug = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  if (slug.isEmpty || !RegExp('^[a-z]').hasMatch(slug)) slug = 'app$slug';
  final id = 'com.example.$slug';
  return validateApplicationId(id) == null ? id : 'com.example.app';
}
