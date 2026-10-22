import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

const _usage = '''
Usage: dart run html2apk_core:html2apk --zip <site.zip> --name <App name> --id <com.example.app>
         [--icon <icon.png>] [--workspace <dir>] [--template <dir>] [--out <dir>]
         [--release --keystore <file.jks> --alias <alias> [--aab]]

Imports a website ZIP, generates the Android wrapper project and builds a
debug APK locally with Gradle. With --release the APK is signed with the
given keystore; passwords are read from the environment variables
HTML2APK_KEYSTORE_PASSWORD and HTML2APK_KEY_PASSWORD (defaults to the
keystore password), never from the command line. --aab builds an App
Bundle for Google Play instead of an APK.''';

Future<void> main(List<String> args) async {
  final opts = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--')) break;
    final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
    opts[args[i].substring(2)] = hasValue ? args[++i] : 'true';
  }
  final release = opts['release'] == 'true';
  final aab = opts['aab'] == 'true';
  if (aab && !release) {
    stderr.writeln('--aab needs --release (App Bundles are for publishing).');
    exitCode = 64;
    return;
  }
  ReleaseSigning? signing;
  if (release) {
    final keystore = opts['keystore'], alias = opts['alias'];
    final storePassword = Platform.environment['HTML2APK_KEYSTORE_PASSWORD'];
    if (keystore == null || alias == null || storePassword == null || storePassword.isEmpty) {
      stderr.writeln('--release needs --keystore, --alias and HTML2APK_KEYSTORE_PASSWORD in the environment.');
      exitCode = 64;
      return;
    }
    signing = KeystoreFileSigning(
      path: keystore,
      alias: alias,
      storePassword: storePassword,
      keyPassword: Platform.environment['HTML2APK_KEY_PASSWORD'] ?? storePassword,
    );
  }
  final zip = opts['zip'], name = opts['name'], id = opts['id'];
  if (zip == null || name == null || id == null) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  final repoRoot = p.normalize(p.join(p.dirname(Platform.script.toFilePath()), '..', '..', '..'));
  final template = opts['template'] ?? p.join(repoRoot, 'android_template');
  final workspace = opts['workspace'] ?? p.join(repoRoot, '.workspace');

  final tc = discoverToolchain();
  for (final problem in tc.problems) {
    stderr.writeln(problem);
  }
  if (!tc.ok) {
    exitCode = 69;
    return;
  }
  final toolchain = tc.toolchain!;
  stdout.writeln('JDK: ${toolchain.javaHome}\nSDK: ${toolchain.androidSdk}');

  final store = ProjectStore(workspace);
  final ImportReport report;
  try {
    report = await store.importZip(zipPath: zip, name: name, applicationId: id, iconPng: opts['icon']);
  } on Exception catch (e) {
    stderr.writeln(e);
    exitCode = 65;
    return;
  }
  final project = report.project;
  stdout.writeln('Imported ${report.fileCount} files into ${project.directory}');
  stdout.writeln('Entry point: ${project.manifest.source.entry}');
  for (final m in report.missingAssets) {
    stdout.writeln('Warning: missing asset $m');
  }

  final buildsDir = p.join(workspace, 'builds');
  final engine = GradleProjectBuildEngine(toolchain: toolchain, templateDir: template, buildsDir: buildsDir);
  final outDir = opts['out'];
  final apkPath = aab ? project.releaseAabPath : (release ? project.releaseApkPath : project.debugApkPath);
  final dest = outDir == null ? apkPath : p.join(outDir, p.basename(apkPath));

  Directory(p.join(buildsDir, project.manifest.id)).createSync(recursive: true);
  final logFile = File(p.join(buildsDir, project.manifest.id, 'build.log')).openWrite();
  final cancel = CancellationToken();
  final sub = ProcessSignal.sigint.watch().listen((_) => cancel.cancel());
  final result = await engine.buildProject(
    project,
    outputPath: dest,
    cancel: cancel,
    variant: release ? BuildVariant.release : BuildVariant.debug,
    signing: signing,
    format: aab ? ArtifactFormat.aab : ArtifactFormat.apk,
    log: (line) {
      logFile.writeln(line);
      if (line.startsWith('> Task') || line.contains('BUILD') || line.contains('error') ||
          line.startsWith('Generated') || line.startsWith('Signed by')) {
        stdout.writeln(line);
      }
    },
  );
  await sub.cancel();
  await logFile.close();
  store.recordBuild(project, BuildRecord(
    time: DateTime.now(),
    engine: engine.id,
    status: result.status.name,
    durationMs: result.duration.inMilliseconds,
    artifactPath: result.artifactPath,
    bytes: result.artifactPath == null ? null : File(result.artifactPath!).lengthSync(),
    versionName: project.manifest.android.versionName,
    versionCode: project.manifest.android.versionCode,
    message: result.message,
    variant: release ? 'release' : 'debug',
    signerSha256: result.signerSha256,
    format: aab ? 'aab' : 'apk',
  ));

  stdout.writeln('Status: ${result.status.name} in ${result.duration.inSeconds}s');
  if (result.status != BuildStatus.succeeded) {
    stderr.writeln(result.message ?? 'Build did not succeed');
    exitCode = 1;
    return;
  }
  stdout.writeln('${aab ? 'AAB' : 'APK'}: $dest (${File(dest).lengthSync()} bytes)');
}
