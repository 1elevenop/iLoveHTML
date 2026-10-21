import 'dart:async';

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

/// Platform-specific engine that turns a generated Gradle project into an
/// artifact on this device. Windows uses [GradleProcessBuildAdapter]; the
/// Android on-device engine will implement this same interface.
abstract interface class AndroidBuildAdapter {
  Future<BuildResult> build(BuildRequest request, {required BuildLogSink log, CancellationToken? cancel});
}
