@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/engine/desktop_engine.dart';
import 'package:html2apk_app/src/engine/dpapi.dart';
import 'package:html2apk_app/src/engine/signing_keys.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

// Windows engine: DPAPI, keytool-based key store and a real Gradle build.
void main() {
  late Directory tmp;
  late DesktopBuildEngine engine;
  final repo = p.normalize(p.join(Directory.current.path, '..'));
  final report = discoverToolchain();

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('h2a_desktop_');
    engine = DesktopBuildEngine(
        workspaceDir: tmp.path, toolchainReport: report, templateDir: p.join(repo, 'android_template'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('DPAPI round trip, ciphertext does not contain the secret', () {
    const secret = 'pässwörd-✓-123';
    final enc = protectString(secret);
    expect(enc, isNot(contains('123')));
    expect(unprotectString(enc), secret);
    // Corrupt the encrypted data (the header near the start is not authenticated).
    final other = protectString('x');
    final pos = other.length - 30;
    final tampered = other.replaceRange(pos, pos + 4, other.substring(pos, pos + 4) == 'AAAA' ? 'BBBB' : 'AAAA');
    expect(() => unprotectString(tampered), throwsStateError);
  });

  test('parses keytool aliases and dates', () {
    expect(parseKeytoolAliases('Keystore type: PKCS12\n\nupload, Oct 22, 2026, PrivateKeyEntry, \nca, x, trustedCertEntry,\n'),
        ['upload']);
    expect(parseKeytoolDate('Tue Mar 09 13:21:05 IST 2054'), DateTime(2054, 3, 9, 13, 21, 5));
  });

  test('create, list, inspect, import (wrong passwords rejected), delete', () async {
    final created = await engine.createKey(alias: 'upload', commonName: 'Desk, Test', country: 'IN', password: 'secret-pw-1');
    expect(created.subject, 'CN="Desk, Test", C=IN');
    expect(created.sha256.split(':'), hasLength(32));
    expect(created.notAfter.year, greaterThan(DateTime.now().year + 20));
    expect((await engine.listKeys()).single.id, created.id);

    // The registry never holds the plain password.
    final registry = File(p.join(tmp.path, 'keys', 'keys.json')).readAsStringSync();
    expect(registry, isNot(contains('secret-pw-1')));

    final jks = p.join(tmp.path, 'keys', '${created.id}.jks');
    await expectLater(engine.inspectKeystore(jks, 'wrong'), throwsA(isA<KeyManagerException>()));
    expect(await engine.inspectKeystore(jks, 'secret-pw-1'), ['upload']);
    await expectLater(engine.importKey(path: jks, storePassword: 'secret-pw-1', alias: 'upload', keyPassword: 'nope'),
        throwsA(isA<KeyManagerException>().having((e) => e.message, 'message', startsWith('Wrong key password'))));
    await expectLater(
        engine.importKey(path: jks, storePassword: 'secret-pw-1', alias: 'upload', keyPassword: 'secret-pw-1'),
        throwsA(isA<KeyManagerException>().having((e) => e.message, 'message', contains('already'))));

    await engine.deleteKey(created.id);
    expect(await engine.listKeys(), isEmpty);
    expect(File(jks).existsSync(), isFalse);
  });

  test('imports a legacy JKS with a separate key password', () async {
    final jks = p.join(tmp.path, 'legacy.jks');
    final keytool = p.join(report.toolchain!.javaHome, 'bin', 'keytool.exe');
    final r = await Process.run(keytool, [
      '-genkeypair', '-keystore', jks, '-storetype', 'JKS', '-alias', 'old', '-keyalg', 'RSA', '-keysize', '2048',
      '-validity', '400', '-dname', 'CN=Legacy', '-storepass:env', 'SP', '-keypass:env', 'KP',
    ], environment: {'SP': 'store-pw-1', 'KP': 'key-pw-22'});
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');

    expect(await engine.inspectKeystore(jks, 'store-pw-1'), ['old']);
    await expectLater(engine.importKey(path: jks, storePassword: 'store-pw-1', alias: 'old', keyPassword: 'store-pw-1'),
        throwsA(isA<KeyManagerException>().having((e) => e.message, 'message', 'Wrong key password')));
    final key = await engine.importKey(path: jks, storePassword: 'store-pw-1', alias: 'old', keyPassword: 'key-pw-22');
    expect(key.origin, 'imported');
    expect(key.subject, 'CN=Legacy');
  }, skip: report.ok ? false : 'No JDK');

  test('keys made here need 8 characters; imported keys keep their own password', () async {
    await expectLater(engine.createKey(alias: 'upload', commonName: 'Short', password: 'seven77'),
        throwsA(isA<KeyManagerException>().having((e) => e.message, 'message', contains('8 characters'))));
    expect(await engine.listKeys(), isEmpty);

    // keytool's own minimum is 6 characters, the same rule as on the phone.
    final p12 = p.join(tmp.path, 'short.p12');
    final keytool = p.join(report.toolchain!.javaHome, 'bin', 'keytool.exe');
    final r = await Process.run(keytool, [
      '-genkeypair', '-keystore', p12, '-storetype', 'PKCS12', '-alias', 'short', '-keyalg', 'RSA', '-keysize', '2048',
      '-validity', '400', '-dname', 'CN=Short', '-storepass:env', 'SP', '-keypass:env', 'SP',
    ], environment: {'SP': 'abc123'});
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    final key = await engine.importKey(path: p12, storePassword: 'abc123', alias: 'short', keyPassword: 'abc123');
    expect(key.subject, 'CN=Short');
  }, skip: report.ok ? false : 'No JDK');

  test('builds debug and release APKs with Gradle', () async {
    final store = ProjectStore(p.join(tmp.path, 'projects'));
    final site = Directory(p.join(tmp.path, 'site'))..createSync();
    File(p.join(site.path, 'index.html')).writeAsStringSync('<h1>Desktop</h1>');
    final project = (await store.importFiles(
            paths: [p.join(site.path, 'index.html')], name: 'Desk', applicationId: 'com.html2apk.desktoptest'))
        .project;
    final log = <String>[];

    final debug = await engine.buildProject(project, outputPath: project.debugApkPath, log: log.add);
    expect(debug.status, BuildStatus.succeeded, reason: log.join('\n'));
    expect(File(project.debugApkPath).existsSync(), isTrue);

    final key = await engine.createKey(alias: 'upload', commonName: 'Desk', password: 'secret-pw-2');
    final release = await engine.buildProject(project,
        outputPath: project.releaseApkPath,
        log: log.add,
        variant: BuildVariant.release,
        signing: DeviceKeySigning(key));
    expect(release.status, BuildStatus.succeeded, reason: log.join('\n'));
    expect(release.signerSha256?.toUpperCase(), key.sha256.toUpperCase(),
        reason: log.where((l) => l.contains('apksigner')).join('\n'));
    expect(log.join('\n'), isNot(contains('secret-pw-2')));
  }, skip: report.ok ? false : 'No JDK/Android SDK', timeout: const Timeout(Duration(minutes: 10)));
}
