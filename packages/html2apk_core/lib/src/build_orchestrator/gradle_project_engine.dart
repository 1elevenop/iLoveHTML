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
    BuildVariant variant = BuildVariant.debug,
    ReleaseSigning? signing,
    ArtifactFormat format = ArtifactFormat.apk,
  }) async {
    final sw = Stopwatch()..start();
    if (format == ArtifactFormat.aab && variant != BuildVariant.release) {
      return BuildResult(BuildStatus.failed, message: 'App Bundles are release-only', duration: sw.elapsed);
    }
    final env = <String, String>{};
    if (variant == BuildVariant.release) {
      if (signing is! KeystoreFileSigning) {
        return BuildResult(BuildStatus.failed, message: 'Release builds need a keystore file', duration: sw.elapsed);
      }
      if (!File(signing.path).existsSync()) {
        return BuildResult(BuildStatus.failed, message: 'Keystore not found: ${signing.path}', duration: sw.elapsed);
      }
      // Read by android_template/app/build.gradle.kts.
      env.addAll({
        'HTML2APK_KEYSTORE': File(signing.path).absolute.path,
        'HTML2APK_KEYSTORE_PASSWORD': signing.storePassword,
        'HTML2APK_KEY_ALIAS': signing.alias,
        'HTML2APK_KEY_PASSWORD': signing.keyPassword,
      });
    }
    final projectDir = p.join(buildsDir, project.manifest.id, 'android');
    try {
      AndroidGenerator(templateDir: templateDir).generate(project, projectDir, androidSdkDir: toolchain.androidSdk);
    } on Exception catch (e) {
      return BuildResult(BuildStatus.failed, message: '$e', duration: sw.elapsed);
    }
    log('Generated Android project: $projectDir');
    final result = await GradleProcessBuildAdapter(toolchain)
        .build(BuildRequest(projectDir: projectDir, variant: variant, format: format, environment: env),
            log: log, cancel: cancel);
    if (result.status != BuildStatus.succeeded) return result;
    File(outputPath).parent.createSync(recursive: true);
    File(result.artifactPath!).copySync(outputPath);

    String? signer;
    final apksigner = toolchain.apksignerJar;
    if (format == ArtifactFormat.aab) {
      // Bundles carry a JAR signature; keytool prints its certificate.
      final keytool = p.join(toolchain.javaHome, 'bin', Platform.isWindows ? 'keytool.exe' : 'keytool');
      final r = await Process.run(keytool, ['-printcert', '-jarfile', outputPath]);
      signer = RegExp(r'SHA256: ([0-9A-F:]{95})').firstMatch('${r.stdout}')?.group(1);
      if (r.exitCode != 0 || signer == null) {
        return BuildResult(BuildStatus.failed, message: 'App Bundle is not signed: ${r.stdout}'.trim(), duration: sw.elapsed);
      }
      log('Signed by certificate SHA-256 $signer');
    } else if (apksigner != null) {
      // Same JVM options as apksigner's own launcher script; no shell.
      final verify = await Process.run(
          toolchain.java, ['-Xmx1024M', '-Xss1m', '-jar', apksigner, 'verify', '--print-certs', outputPath]);
      if (verify.exitCode != 0) {
        return BuildResult(BuildStatus.failed,
            message: 'APK signature verification failed: ${verify.stderr}'.trim(), duration: sw.elapsed);
      }
      signer = parseSignerSha256('${verify.stdout}');
      if (signer != null) {
        log('Signed by certificate SHA-256 $signer');
      } else {
        // A different apksigner version may word its output differently.
        final out = '${verify.stdout}${verify.stderr}'.trim();
        log('apksigner printed no signer certificate: ${out.length > 600 ? out.substring(0, 600) : out}');
      }
    } else {
      log('apksigner not found; signature not verified');
    }
    return BuildResult(BuildStatus.succeeded,
        artifactPath: outputPath, exitCode: result.exitCode, duration: sw.elapsed, signerSha256: signer);
  }
}

/// Reads the first signer's `… certificate SHA-256 digest: ab12…` from
/// `apksigner verify --print-certs` and formats it like Android's
/// fingerprints: `AB:12:…`. Up to build-tools 36 the line starts with
/// `Signer #1`; build-tools 37 names the signature scheme (`V2 Signer:`).
String? parseSignerSha256(String output) {
  final m = RegExp(r'(?:Signer #1|V[0-9.]+ Signer:) certificate SHA-256 digest: ([0-9a-fA-F]{64})').firstMatch(output);
  if (m == null) return null;
  final hex = m.group(1)!.toUpperCase();
  return [for (var i = 0; i < hex.length; i += 2) hex.substring(i, i + 2)].join(':');
}
