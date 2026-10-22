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
    this.environment = const {},
  });

  /// Generated Gradle project produced by AndroidGenerator.
  final String projectDir;
  final BuildVariant variant;
  final ArtifactFormat format;

  /// Extra environment for the build process, e.g. signing configuration.
  /// Passed through the environment rather than command-line arguments so
  /// passwords do not appear in process listings or logs.
  final Map<String, String> environment;

  String get gradleTask => switch ((variant, format)) {
        (BuildVariant.debug, ArtifactFormat.apk) => 'assembleDebug',
        (BuildVariant.release, ArtifactFormat.apk) => 'assembleRelease',
        (BuildVariant.debug, ArtifactFormat.aab) => 'bundleDebug',
        (BuildVariant.release, ArtifactFormat.aab) => 'bundleRelease',
      };
}

enum BuildStatus { succeeded, failed, cancelled }

class BuildResult {
  const BuildResult(this.status,
      {this.artifactPath, this.exitCode, this.message, required this.duration, this.signerSha256});

  final BuildStatus status;
  final String? artifactPath;

  /// SHA-256 fingerprint of the signing certificate, when the engine reports it.
  final String? signerSha256;
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

/// How a release build is signed. Each engine accepts its own kind.
abstract interface class ReleaseSigning {}

/// A keystore file on disk (desktop engines). PKCS12 and JKS are both read by Gradle.
class KeystoreFileSigning implements ReleaseSigning {
  const KeystoreFileSigning({
    required this.path,
    required this.alias,
    required this.storePassword,
    required this.keyPassword,
  });

  final String path;
  final String alias;
  final String storePassword;
  final String keyPassword;

  @override
  String toString() => 'KeystoreFileSigning($path, $alias)';
}

/// Builds a project into an installable artifact on this device.
///
/// This is the interface the UI and project system use. Windows composes
/// the generator with Gradle ([GradleProjectBuildEngine]); Android assembles
/// a prebuilt base APK in Kotlin (ADR 0002).
abstract interface class ProjectBuildEngine {
  /// Short identifier stored in build history, e.g. `gradle` or `on-device`.
  String get id;

  /// Writes an APK or AAB for [project] to [outputPath]: debug-signed, or
  /// for [BuildVariant.release] signed with [signing], which is then
  /// required. App Bundles ([ArtifactFormat.aab]) are release-only.
  Future<BuildResult> buildProject(
    ProjectHandle project, {
    required String outputPath,
    required BuildLogSink log,
    CancellationToken? cancel,
    BuildVariant variant = BuildVariant.debug,
    ReleaseSigning? signing,
    ArtifactFormat format = ArtifactFormat.apk,
  });
}

/// Runs Gradle on a generated project. Used by [GradleProjectBuildEngine].
abstract interface class AndroidBuildAdapter {
  Future<BuildResult> build(BuildRequest request, {required BuildLogSink log, CancellationToken? cancel});
}
