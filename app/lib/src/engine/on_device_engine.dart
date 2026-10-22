import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';

/// A release key stored on this phone (the keystore and its encrypted
/// password live in the Kotlin side; Dart only sees certificate details).
class SigningKey {
  SigningKey.fromMap(Map<Object?, Object?> m)
      : id = m['id']! as String,
        alias = m['alias']! as String,
        subject = m['subject']! as String,
        sha256 = m['sha256']! as String,
        sha1 = m['sha1']! as String,
        notAfter = DateTime.fromMillisecondsSinceEpoch(m['notAfter']! as int),
        createdAt = DateTime.fromMillisecondsSinceEpoch(m['createdAt']! as int),
        origin = m['origin']! as String;

  final String id;
  final String alias;
  final String subject;
  final String sha256;
  final String sha1;
  final DateTime notAfter;
  final DateTime createdAt;

  /// `created` or `imported`.
  final String origin;

  /// Short form for lists, e.g. `AB:CD:EF…12:34`.
  String get shortSha256 => '${sha256.substring(0, 8)}…${sha256.substring(sha256.length - 5)}';
}

/// Signs a release with a key from [OnDeviceBuildEngine.listKeys].
class DeviceKeySigning implements ReleaseSigning {
  const DeviceKeySigning(this.key);

  final SigningKey key;
}

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
    BuildVariant variant = BuildVariant.debug,
    ReleaseSigning? signing,
    ArtifactFormat format = ArtifactFormat.apk,
  }) async {
    final sw = Stopwatch()..start();
    if (format == ArtifactFormat.aab && variant != BuildVariant.release) {
      return BuildResult(BuildStatus.failed, message: 'App Bundles are release-only', duration: sw.elapsed);
    }
    final m = project.manifest;
    final errors = validateManifest(m).where((i) => i.severity == IssueSeverity.error).toList();
    if (errors.isNotEmpty) {
      return BuildResult(BuildStatus.failed, message: errors.join('\n'), duration: sw.elapsed);
    }
    if (variant == BuildVariant.release && signing is! DeviceKeySigning) {
      return BuildResult(BuildStatus.failed, message: 'Choose a release key first', duration: sw.elapsed);
    }
    final releaseKey = signing is DeviceKeySigning ? signing.key : null;
    final permissions = AndroidGenerator.permissionsFor(m);
    log('Engine: on-device assembly (${variant.name} ${format.name.toUpperCase()})');
    log('Package ${m.android.applicationId} ${m.android.versionName} (${m.android.versionCode})');
    if (permissions.isNotEmpty) log('Permissions: ${permissions.join(', ')}');
    if (releaseKey != null) log('Release key: ${releaseKey.alias} (${releaseKey.shortSha256})');
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
        'signingKeyId': releaseKey?.id,
        'format': format.name,
      });
      final timings = (r!['timingsMs'] as Map).cast<String, int>();
      log('Website files: ${r['files']}');
      timings.forEach((step, ms) => log('  $step: $ms ms'));
      log(format == ArtifactFormat.aab
          ? 'Signed by ${r['signer']} (JAR v1, as Google Play requires for bundles), verified'
          : 'Signed by ${r['signer']} (v2: ${r['v2']}, v3: ${r['v3']}), verified');
      log('Certificate SHA-256: ${r['signerSha256']}');
      log('Output: ${r['outputPath']} (${r['bytes']} bytes)');
      return BuildResult(BuildStatus.succeeded,
          artifactPath: r['outputPath'] as String, duration: sw.elapsed, signerSha256: r['signerSha256'] as String?);
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

  /// Lets the user save a built file (e.g. to Downloads or Drive). Returns null if cancelled.
  Future<String?> saveFile(String path) => _channel.invokeMethod<String>('saveFile', {
        'path': path,
        'mimeType': path.endsWith('.aab') ? 'application/octet-stream' : 'application/vnd.android.package-archive',
      });

  // ---- Release keys. Errors arrive as PlatformException with a readable message.

  Future<List<SigningKey>> listKeys() async =>
      [for (final m in await _channel.invokeListMethod<Map<Object?, Object?>>('keysList') ?? []) SigningKey.fromMap(m)];

  Future<SigningKey> createKey({
    required String alias,
    required String commonName,
    String? organization,
    String? country,
    required String password,
  }) async =>
      SigningKey.fromMap((await _channel.invokeMapMethod<Object?, Object?>('keysCreate', {
        'alias': alias,
        'commonName': commonName,
        'organization': organization,
        'country': country,
        'password': password,
      }))!);

  /// Key aliases inside a picked keystore file (checks the store password).
  Future<List<String>> inspectKeystore(String path, String storePassword) async =>
      await _channel.invokeListMethod<String>('keysInspect', {'path': path, 'storePassword': storePassword}) ?? [];

  Future<SigningKey> importKey({
    required String path,
    required String storePassword,
    required String alias,
    required String keyPassword,
  }) async =>
      SigningKey.fromMap((await _channel.invokeMapMethod<Object?, Object?>('keysImport', {
        'path': path,
        'storePassword': storePassword,
        'alias': alias,
        'keyPassword': keyPassword,
      }))!);

  /// Saves the keystore where the user chooses. Returns null if they cancelled.
  Future<String?> exportKey(String id) => _channel.invokeMethod<String>('keysExport', {'id': id});

  Future<void> deleteKey(String id) => _channel.invokeMethod('keysDelete', {'id': id});
}
