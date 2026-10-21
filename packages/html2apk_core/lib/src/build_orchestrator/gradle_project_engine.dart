import 'dart:io';

import 'package:path/path.dart' as p;

import '../android_generator/android_generator.dart';
import '../project_core/project_store.dart';
import 'build_adapter.dart';
import 'gradle_adapter.dart';
import 'toolchain.dart';

/// Desktop engine: generate the wrapper Gradle project, run Gradle locally,
/// copy the validated APK to the requested output path.
class GradleProjectBuildEngine implements ProjectBuildEngine {
  GradleProjectBuildEngine({required this.toolchain, required this.templateDir, required this.buildsDir});

  final Toolchain toolchain;
  final String templateDir;

  /// Scratch space for generated Gradle projects, one folder per project.
  final String buildsDir;

  @override
  String get id => 'gradle';

  @override
  Future<BuildResult> buildProject(
    ProjectHandle project, {
    required String outputPath,
    required BuildLogSink log,
    CancellationToken? cancel,
  }) async {
    final sw = Stopwatch()..start();
    final projectDir = p.join(buildsDir, project.manifest.id, 'android');
    try {
      AndroidGenerator(templateDir: templateDir).generate(project, projectDir, androidSdkDir: toolchain.androidSdk);
    } on Exception catch (e) {
      return BuildResult(BuildStatus.failed, message: '$e', duration: sw.elapsed);
    }
    log('Generated Android project: $projectDir');
    final result = await GradleProcessBuildAdapter(toolchain)
        .build(BuildRequest(projectDir: projectDir), log: log, cancel: cancel);
    if (result.status != BuildStatus.succeeded) return result;
    File(outputPath).parent.createSync(recursive: true);
    File(result.artifactPath!).copySync(outputPath);
    return BuildResult(BuildStatus.succeeded,
        artifactPath: outputPath, exitCode: result.exitCode, duration: sw.elapsed);
  }
}
