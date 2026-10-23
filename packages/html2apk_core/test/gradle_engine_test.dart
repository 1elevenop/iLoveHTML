import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Real Gradle builds; skipped without a local JDK and Android SDK.
void main() {
  final report = discoverToolchain();
  final template = p.normalize(p.join(Directory.current.path, '..', '..', 'android_template'));
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('gradle_engine'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('APKs are verified when the SDK and output paths contain spaces', () async {
    final tc = report.toolchain!;
    // A copy of build-tools under a folder with a space, as on a PC whose
    // user name has one (the SDK and workspace both live under the profile).
    final bt = Directory(p.join(tmp.path, 'Android SDK', 'build-tools', p.basename(tc.buildToolsDir!)));
    Directory(p.join(bt.path, 'lib')).createSync(recursive: true);
    for (final f in ['apksigner.bat', 'apksigner', p.join('lib', 'apksigner.jar')]) {
      final src = File(p.join(tc.buildToolsDir!, f));
      if (src.existsSync()) src.copySync(p.join(bt.path, f));
    }
    final site = File(p.join(tmp.path, 'index.html'))..writeAsStringSync('<!doctype html><h1>spaces</h1>');
    final project = (await ProjectStore(p.join(tmp.path, 'ws'))
            .importFiles(paths: [site.path], name: 'Spaces', applicationId: 'com.example.spaces'))
        .project;

    final log = <String>[];
    final result = await GradleProjectBuildEngine(
      toolchain: Toolchain(javaHome: tc.javaHome, androidSdk: tc.androidSdk, buildToolsDir: bt.path),
      templateDir: template,
      buildsDir: p.join(tmp.path, 'builds'),
    ).buildProject(project, outputPath: p.join(tmp.path, 'My Apps', 'spaces-debug.apk'), log: log.add);

    expect(result.status, BuildStatus.succeeded, reason: '${result.message}\n${log.join('\n')}');
    expect(result.signerSha256, matches(RegExp(r'^([0-9A-F]{2}:){31}[0-9A-F]{2}$')));
    expect(log, isNot(contains('apksigner not found; signature not verified')));
  }, skip: report.ok && report.toolchain!.buildToolsDir != null ? false : 'No JDK/Android SDK build-tools',
      timeout: const Timeout(Duration(minutes: 10)));

  test('deleting a project removes its Gradle build folder', () async {
    final store = ProjectStore(p.join(tmp.path, 'ws'));
    final site = File(p.join(tmp.path, 'index.html'))..writeAsStringSync('<!doctype html><h1>delete</h1>');
    final project =
        (await store.importFiles(paths: [site.path], name: 'Delete', applicationId: 'com.example.delete')).project;
    final builds = Directory(p.join(store.workspaceDir, 'builds', project.manifest.id));

    final result = await GradleProjectBuildEngine(
      toolchain: report.toolchain!,
      templateDir: template,
      buildsDir: p.dirname(builds.path),
    ).buildProject(project, outputPath: p.join(project.exportsDir, 'delete-debug.apk'), log: (_) {});
    expect(result.status, BuildStatus.succeeded, reason: result.message);
    expect(builds.existsSync(), isTrue);

    store.delete(project);
    expect(Directory(project.directory).existsSync(), isFalse);
    expect(builds.existsSync(), isFalse, reason: 'build scratch (site copy, Gradle output) must go with the project');
  }, skip: report.ok ? false : 'No JDK/Android SDK', timeout: const Timeout(Duration(minutes: 10)));
}
