// On-device end-to-end test: runs inside iLoveHTML on an emulator or phone and
// drives the real Kotlin build engine through the platform channel.
//
//   flutter test integration_test -d emulator-5554
//
// It uses its own workspace and a throwaway release key, deletes both at the
// end, and never touches the user's projects or keys.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/engine/on_device_engine.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  late AppController controller;
  late OnDeviceBuildEngine engine;
  SigningKey? key;

  setUpAll(() async {
    // Inside files/workspace so the engine's path checks accept it.
    final support = await getApplicationSupportDirectory();
    workspace = Directory(p.join(support.path, 'workspace', 'projects', '_e2e_${DateTime.now().millisecondsSinceEpoch}'));
    engine = OnDeviceBuildEngine();
    controller = AppController(workspaceDir: workspace.path, engine: engine);
  });

  tearDownAll(() async {
    if (key != null) await engine.deleteKey(key!.id);
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  Map<String, String> entries(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    return {for (final f in archive.files) f.name: f.isFile ? 'file' : 'dir'};
  }

  testWidgets('import, configure, build debug, release APK and AAB on this device', (tester) async {
    final info = await engine.info();
    expect(info['baseAvailable'], isTrue, reason: 'app must ship base.apk/base.aab');
    debugPrint('E2E device: ${info['device']} Android ${info['android']} (API ${info['sdkInt']}) ${info['abi']}');

    // 1. Import loose files (page + flat CSS/JS) and check they were arranged.
    final picked = Directory(p.join(workspace.path, '..', '_e2e_picked_${DateTime.now().millisecondsSinceEpoch}'))
      ..createSync(recursive: true);
    addTearDown(() => picked.deleteSync(recursive: true));
    File(p.join(picked.path, 'index.html'))
        .writeAsStringSync('<link href="css/s.css"><h1>E2E</h1><script src="js/a.js"></script>');
    File(p.join(picked.path, 's.css')).writeAsStringSync('h1{color:red}');
    File(p.join(picked.path, 'a.js')).writeAsStringSync('console.log("e2e")');
    final report = await controller.importFiles(
        [for (final f in ['index.html', 's.css', 'a.js']) p.join(picked.path, f)], 'E2E App', 'com.html2apk.e2edevice');
    expect(report.missingAssets, isEmpty);
    var project = report.project;
    expect(File(p.join(project.sourceDir, 'css', 's.css')).existsSync(), isTrue);

    // 2. Configure: colours, splash, orientation, version.
    project = controller.update(project, project.manifest.copyWith(
      orientation: Orientation.portrait,
      appearance: const AppearanceSettings(statusBarColor: '#1A73E8', navigationBarColor: '#FFFFFF', splashEnabled: true),
      android: project.manifest.android.copyWith(versionCode: 5, versionName: '2.0.0'),
    ));

    // 3. Debug APK.
    final logs = <String>[];
    final debug = await controller.build(project, logs.add);
    expect(debug.status, BuildStatus.succeeded, reason: '${debug.message}\n${logs.join('\n')}');
    final apk = entries(debug.artifactPath!);
    for (final e in ['AndroidManifest.xml', 'classes.dex', 'resources.arsc', 'assets/www/index.html',
        'assets/www/css/s.css', 'assets/www/js/a.js', 'assets/app_config.json']) {
      expect(apk, contains(e));
    }
    final config = jsonDecode(utf8.decode(
        ZipDecoder().decodeBytes(File(debug.artifactPath!).readAsBytesSync()).findFile('assets/app_config.json')!.content));
    expect(config['statusBarColor'], '#1A73E8');
    expect(config['splash']['enabled'], isTrue);

    // 4. Release key (throwaway), release APK, release AAB.
    key = await engine.createKey(alias: 'e2e${DateTime.now().millisecondsSinceEpoch % 100000}',
        commonName: 'iLoveHTML E2E', password: 'e2e-password-${DateTime.now().microsecond}');
    final signing = DeviceKeySigning(key!);

    final release = await controller.build(project, logs.add, variant: BuildVariant.release, signing: signing);
    expect(release.status, BuildStatus.succeeded, reason: '${release.message}\n${logs.join('\n')}');
    expect(release.signerSha256, key!.sha256);
    expect(controller.project(project.manifest.id)!.manifest.releaseCertSha256, key!.sha256,
        reason: 'first release pins the certificate');

    // Same version code again: the APK release is refused, as Play would.
    final again = await controller.build(controller.project(project.manifest.id)!, logs.add,
        variant: BuildVariant.release, signing: signing);
    expect(again.status, BuildStatus.failed);
    expect(again.message, contains('not higher than the last release'));

    project = controller.update(controller.project(project.manifest.id)!,
        controller.project(project.manifest.id)!.manifest.copyWith(
            android: project.manifest.android.copyWith(versionCode: 6, versionName: '2.0.1')));
    final bundle = await controller.build(project, logs.add,
        variant: BuildVariant.release, signing: signing, format: ArtifactFormat.aab);
    expect(bundle.status, BuildStatus.succeeded, reason: '${bundle.message}\n${logs.join('\n')}');
    expect(bundle.artifactPath, endsWith('.aab'));
    expect(bundle.signerSha256, key!.sha256);
    final aab = entries(bundle.artifactPath!);
    for (final e in ['BundleConfig.pb', 'base/manifest/AndroidManifest.xml', 'base/dex/classes.dex',
        'base/assets/www/index.html', 'META-INF/MANIFEST.MF']) {
      expect(aab, contains(e));
    }

    // Debug App Bundles are refused.
    final debugAab = await controller.build(project, logs.add, format: ArtifactFormat.aab);
    expect(debugAab.status, BuildStatus.failed);

    final history = controller.store.buildHistory(project);
    expect(history.where((b) => b.succeeded).map((b) => '${b.variant}/${b.format}'),
        containsAll(['debug/apk', 'release/apk', 'release/aab']));
    debugPrint('E2E sizes: apk=${File(debug.artifactPath!).lengthSync()} '
        'release=${File(release.artifactPath!).lengthSync()} aab=${File(bundle.artifactPath!).lengthSync()}');
    debugPrint('E2E OK');
  });

  test('keeps the large ZIP limits on this device', () async {
    // A forged-size ZIP bomb is still rejected here (archive + streaming limit).
    final big = Archive()..add(ArchiveFile.bytes('index.html', utf8.encode('x')))..add(ArchiveFile.bytes('b.bin', Uint8List(8 << 20)));
    final zip = File(p.join(workspace.path, 'bomb.zip'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(ZipEncoder().encodeBytes(big));
    await expectLater(
      extractWebsiteZip(zip.path, p.join(workspace.path, 'bomb'), limits: const ExtractionLimits(maxFileBytes: 1 << 20)),
      throwsA(isA<ArchiveRejectedException>()),
    );
  });
}
