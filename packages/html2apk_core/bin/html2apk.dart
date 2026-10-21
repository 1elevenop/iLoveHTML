import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

const _usage = '''
Usage: dart run html2apk_core:html2apk --zip <site.zip> --name <App name> --id <com.example.app>
         [--icon <icon.png>] [--workspace <dir>] [--template <dir>] [--out <dir>]

Imports a website ZIP, generates the Android wrapper project and builds a
debug APK locally with Gradle.''';

Future<void> main(List<String> args) async {
  final opts = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    if (!args[i].startsWith('--')) break;
    opts[args[i].substring(2)] = args[i + 1];
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

  final buildDir = p.join(workspace, 'builds', project.manifest.id, 'android');
  try {
    AndroidGenerator(templateDir: template).generate(project, buildDir, androidSdkDir: toolchain.androidSdk);
  } on Exception catch (e) {
    stderr.writeln(e);
    exitCode = 65;
    return;
  }
  stdout.writeln('Generated Android project: $buildDir');

  final logFile = File(p.join(workspace, 'builds', project.manifest.id, 'build.log')).openWrite();
  final cancel = CancellationToken();
  final sub = ProcessSignal.sigint.watch().listen((_) => cancel.cancel());
  final result = await GradleProcessBuildAdapter(toolchain).build(
    BuildRequest(projectDir: buildDir),
    cancel: cancel,
    log: (line) {
      logFile.writeln(line);
      if (line.startsWith('> Task') || line.contains('BUILD') || line.contains('error')) stdout.writeln(line);
    },
  );
  await sub.cancel();
  await logFile.close();

  stdout.writeln('Status: ${result.status.name} in ${result.duration.inSeconds}s');
  if (result.status != BuildStatus.succeeded) {
    stderr.writeln(result.message ?? 'Build did not succeed');
    exitCode = 1;
    return;
  }
  final outDir = opts['out'] ?? project.exportsDir;
  Directory(outDir).createSync(recursive: true);
  final dest = p.join(outDir, '${id}-${project.manifest.android.versionName}-debug.apk');
  File(result.artifactPath!).copySync(dest);
  stdout.writeln('APK: $dest (${File(dest).lengthSync()} bytes)');
}
