import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../project_core/project_store.dart';
import 'asset_optimizer.dart';
import 'build_adapter.dart';

/// The project a build engine should use, and the temporary copy behind it.
class StagedBuild {
  StagedBuild._(this.project, this._dir, this.result);

  /// Reads optimized site files when [result] is set; otherwise the original.
  final ProjectHandle project;
  final Directory? _dir;
  final OptimizeResult? result;

  /// Deletes the temporary copy. Safe to call more than once.
  void dispose() {
    final dir = _dir;
    if (dir != null && dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// Prepares [project] for a build. With "optimize assets" on, the site is
/// copied to a folder under [stagingRoot] and made smaller there, so the
/// project's own files never change. Runs in a background isolate, so a
/// large site does not freeze the UI.
Future<StagedBuild> stageForBuild(ProjectHandle project, {required String stagingRoot, BuildLogSink? log}) async {
  final source = project.sourceDir;
  if (!project.manifest.optimizeAssets || !Directory(source).existsSync()) {
    return StagedBuild._(project, null, null);
  }
  Directory(stagingRoot).createSync(recursive: true);
  final dir = Directory(stagingRoot).createTempSync('${project.manifest.id}-');
  try {
    final target = p.join(dir.path, 'source');
    final result = await Isolate.run(() => optimizeSite(source, target));
    log?.call('Optimized ${result.changed.length} files: ${formatBytes(result.totalBefore)} -> '
        '${formatBytes(result.totalAfter)} (saved ${formatBytes(result.savedBytes)})');
    return StagedBuild._(project.withSourceDir(target), dir, result);
  } on Object {
    dir.deleteSync(recursive: true);
    rethrow;
  }
}
