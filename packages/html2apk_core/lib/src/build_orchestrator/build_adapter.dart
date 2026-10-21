import 'dart:async';

import '../project_core/project_store.dart';

/// Output formats a build can produce. An APK is never renamed to an AAB.
enum ArtifactFormat { apk, aab }

enum BuildVariant { debug, release }

class BuildRequest {
  const BuildRequest({
    required this.projectDir,
    this.variant = BuildVariant.debug,
    this.format = ArtifactFormat.apk,
  });

  /// Generated Gradle project produced by AndroidGenerator.
  final String projectDir;
  final BuildVariant variant;
  final ArtifactFormat format;

  String get gradleTask => switch ((variant, format)) {
        (BuildVariant.debug, ArtifactFormat.apk) => 'assembleDebug',
        (BuildVariant.release, ArtifactFormat.apk) => 'assembleRelease',
        (BuildVariant.debug, ArtifactFormat.aab) => 'bundleDebug',
        (BuildVariant.release, ArtifactFormat.aab) => 'bundleRelease',
      };
}

enum BuildStatus { succeeded, failed, cancelled }

class BuildResult {
  const BuildResult(this.status, {this.artifactPath, this.exitCode, this.message, required this.duration});

  final BuildStatus status;
  final String? artifactPath;
  final int? exitCode;
  final String? message;
  final Duration duration;
}

class CancellationToken {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

typedef BuildLogSink = void Function(String line);

/// Builds a project into an installable artifact on this device.
///
/// This is the interface the UI and project system use. Windows composes
/// the generator with Gradle ([GradleProjectBuildEngine]); Android assembles
/// a prebuilt base APK in Kotlin (ADR 0002).
abstract interface class ProjectBuildEngine {
  /// Short identifier stored in build history, e.g. `gradle` or `on-device`.
  String get id;

  /// Writes a debug-signed APK for [project] to [outputPath].
  Future<BuildResult> buildProject(
    ProjectHandle project, {
    required String outputPath,
    required BuildLogSink log,
    CancellationToken? cancel,
  });
}

/// Runs Gradle on a generated project. Used by [GradleProjectBuildEngine].
abstract interface class AndroidBuildAdapter {
  Future<BuildResult> build(BuildRequest request, {required BuildLogSink log, CancellationToken? cancel});
}
