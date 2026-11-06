import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../project_importer/zip_importer.dart';
import '../security/path_safety.dart';
import 'manifest.dart';
import 'project_store.dart';

/// File extension of project backups.
const String backupExtension = '.ilovehtml';

/// Marks a ZIP as an iLoveHTML backup and records its format version.
const String _markerName = 'ilovehtml-backup.json';
const int _backupFormat = 1;

/// Folders of a project that go into a backup. Builds, exports and signing
/// keys stay out: keys live in the app's key store, never in a project.
const _includedFolders = ['source', 'branding'];

/// A file name for [project]'s backup, e.g. `My Shop.ilovehtml`.
String backupFileName(ProjectHandle project) {
  final safe = project.manifest.name.replaceAll(RegExp(r'[^\w .-]'), '_').trim();
  return '${safe.isEmpty ? 'project' : safe}$backupExtension';
}

/// Writes [project] (settings, site files, icon and splash) to one ZIP file
/// at [outPath], to move it to another device or keep it safe.
Future<void> exportProjectBackup(ProjectHandle project, String outPath) async {
  File(outPath).parent.createSync(recursive: true);
  final tmp = '$outPath.tmp';
  final zip = ZipFileEncoder()..create(tmp);
  try {
    zip.addArchiveFile(ArchiveFile.string(_markerName, jsonEncode({'format': _backupFormat})));
    zip.addArchiveFile(ArchiveFile.string('project.json', project.manifest.toJsonString()));
    for (final folder in _includedFolders) {
      final dir = Directory(p.join(project.directory, folder));
      if (!dir.existsSync()) continue;
      for (final e in dir.listSync(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final rel = p.posix.joinAll(p.split(p.relative(e.path, from: project.directory)));
        await zip.addFile(e, rel);
      }
    }
    await zip.close();
    File(tmp).renameSync(outPath);
  } on Object {
    final f = File(tmp);
    if (f.existsSync()) f.deleteSync();
    rethrow;
  }
}

/// Restores a backup made by [exportProjectBackup] as a new project.
///
/// The archive is extracted with the same checks as website ZIPs (no paths
/// outside the folder, no links, size and ZIP-bomb limits). The project gets
/// a new id, so restoring twice gives two projects. Only `source/` and
/// `branding/` files are kept, and icon and splash paths must point inside
/// `branding/`. Throws [ArchiveRejectedException] or [InvalidProjectException].
Future<ProjectHandle> importProjectBackup(ProjectStore store, String backupPath) async {
  Directory(store.projectsDir).createSync(recursive: true);
  // Outside projects/, so a half-restored backup never shows up as a project.
  final workRoot = Directory(p.join(store.workspaceDir, 'restore'))..createSync(recursive: true);
  final work = workRoot.createTempSync('backup-');
  final id = newProjectId();
  final dir = p.join(store.projectsDir, id);
  try {
    final unpacked = p.join(work.path, 'x');
    await extractWebsiteZip(backupPath, unpacked);

    final marker = File(p.join(unpacked, _markerName));
    if (!marker.existsSync()) throw ArchiveRejectedException('not an iLoveHTML backup');
    final format = (jsonDecode(marker.readAsStringSync()) as Map)['format'];
    if (format is! int || format > _backupFormat) {
      throw ArchiveRejectedException('backup made by a newer iLoveHTML; update the app');
    }
    final manifestFile = File(p.join(unpacked, 'project.json'));
    if (!manifestFile.existsSync()) throw ArchiveRejectedException('project.json missing');
    final decoded = jsonDecode(manifestFile.readAsStringSync());
    if (decoded is! Map) throw ArchiveRejectedException('project.json must be a JSON object');
    final json = store.migrator.migrate(decoded.cast<String, Object?>())..['id'] = id;

    Directory(dir).createSync();
    for (final folder in _includedFolders) {
      final from = Directory(p.join(unpacked, folder));
      if (from.existsSync()) from.renameSync(p.join(dir, folder));
    }
    final branding = Map<String, Object?>.of((json['branding'] as Map?)?.cast<String, Object?>() ?? const {});
    for (final key in ['icon', 'splash']) {
      branding[key] = _brandingPath(dir, branding[key]);
    }
    json['branding'] = branding;
    final manifest = ProjectManifest.fromJson(json);
    // update() runs the same checks as saving settings and writes project.json.
    return store.update(ProjectHandle(dir, manifest), manifest);
  } on Object {
    final d = Directory(dir);
    if (d.existsSync()) d.deleteSync(recursive: true);
    rethrow;
  } finally {
    if (work.existsSync()) work.deleteSync(recursive: true);
  }
}

/// [value] if it is a file inside `branding/` that exists, otherwise null.
String? _brandingPath(String projectDir, Object? value) {
  if (value is! String) return null;
  try {
    final rel = normalizeRelativePath(value);
    if (!rel.startsWith('branding/')) return null;
    return File(resolveWithin(projectDir, rel)).existsSync() ? rel : null;
  } on UnsafePathException {
    return null;
  }
}
