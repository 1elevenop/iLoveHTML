import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';

/// Android build engine: assembles the prebuilt wrapper APK in Kotlin on this
/// device (ADR 0002) through the `html2apk/engine` platform channel.
class OnDeviceBuildEngine implements ProjectBuildEngine {
  OnDeviceBuildEngine([MethodChannel? channel]) : _channel = channel ?? const MethodChannel('html2apk/engine');

  final MethodChannel _channel;

  @override
  String get id => 'on-device';

  Future<Map<String, Object?>> info() async =>
      (await _channel.invokeMapMethod<String, Object?>('engineInfo')) ?? const {};

  @override
  Future<BuildResult> buildProject(
    ProjectHandle project, {
    required String outputPath,
    required BuildLogSink log,
    CancellationToken? cancel,
  }) async {
    final sw = Stopwatch()..start();
    final m = project.manifest;
    final errors = validateManifest(m).where((i) => i.severity == IssueSeverity.error).toList();
    if (errors.isNotEmpty) {
      return BuildResult(BuildStatus.failed, message: errors.join('\n'), duration: sw.elapsed);
    }
    final permissions = AndroidGenerator.permissionsFor(m);
    log('Engine: on-device assembly');
    log('Package ${m.android.applicationId} ${m.android.versionName} (${m.android.versionCode})');
    if (permissions.isNotEmpty) log('Permissions: ${permissions.join(', ')}');
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('assemble', {
        'sourceDir': project.sourceDir,
        'outputPath': outputPath,
        'applicationId': m.android.applicationId,
        'label': m.name,
        'versionCode': m.android.versionCode,
        'versionName': m.android.versionName,
        'screenOrientation': AndroidGenerator.screenOrientationValue(m.orientation),
        'permissions': permissions,
        'configJson': jsonEncode(AndroidGenerator.runtimeConfig(m)),
        'iconPath': project.iconFile,
        'splashPath': project.splashFile,
      });
      final timings = (r!['timingsMs'] as Map).cast<String, int>();
      log('Website files: ${r['files']}');
      timings.forEach((step, ms) => log('  $step: $ms ms'));
      log('Signed by ${r['signer']} (v2: ${r['v2']}, v3: ${r['v3']}), verified');
      log('Output: ${r['outputPath']} (${r['bytes']} bytes)');
      return BuildResult(BuildStatus.succeeded, artifactPath: r['outputPath'] as String, duration: sw.elapsed);
    } on PlatformException catch (e) {
      log('Error: ${e.message}');
      return BuildResult(BuildStatus.failed, message: e.message, duration: sw.elapsed);
    }
  }

  /// Opens the system installer. Returns false if the user first has to allow
  /// installs from this app (the settings page is opened for them).
  Future<bool> install(String apkPath) async =>
      await _channel.invokeMethod<String>('installApk', {'path': apkPath}) == 'started';

  Future<void> share(String apkPath) => _channel.invokeMethod('shareApk', {'path': apkPath});
}
