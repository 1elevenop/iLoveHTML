import 'dart:io';

import 'package:path/path.dart' as p;

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
  ProjectHandle(this.directory, this.manifest);

  final String directory;
  final ProjectManifest manifest;

  String get sourceDir => p.join(directory, 'source');
  String get brandingDir => p.join(directory, 'branding');
  String get exportsDir => p.join(directory, 'exports');
  String? get iconFile => manifest.iconPath == null ? null : p.join(directory, manifest.iconPath!);
}

class ImportReport {
  ImportReport(this.project, this.entryCandidates, this.missingAssets, this.fileCount);

  final ProjectHandle project;
  final List<String> entryCandidates;
  final List<MissingAsset> missingAssets;
  final int fileCount;
}

/// Creates, loads and saves projects inside an app-controlled workspace.
class ProjectStore {
  ProjectStore(this.workspaceDir, {this.migrator = const ManifestMigrator()});

  final String workspaceDir;
  final ManifestMigrator migrator;

  String get projectsDir => p.join(workspaceDir, 'projects');

  ProjectHandle load(String projectDir) {
    final text = File(p.join(projectDir, 'project.json')).readAsStringSync();
    return ProjectHandle(projectDir, migrator.load(text));
  }

  void save(ProjectHandle project) {
    final file = File(p.join(project.directory, 'project.json'));
    final tmp = File('${file.path}.tmp')..writeAsStringSync(project.manifest.toJsonString());
    tmp.renameSync(file.path);
  }

  /// Imports a website ZIP as a new local project.
  Future<ImportReport> importZip({
    required String zipPath,
    required String name,
    required String applicationId,
    String? iconPng,
  }) async {
    final id = newProjectId();
    final dir = p.join(projectsDir, id);
    Directory(dir).createSync(recursive: true);
    try {
      final extraction = await extractWebsiteZip(zipPath, p.join(dir, 'source'));
      final candidates = findEntryCandidates(extraction.files);
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
      return ImportReport(handle, candidates,
          findMissingAssets(handle.sourceDir, extraction.files), extraction.files.length);
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
