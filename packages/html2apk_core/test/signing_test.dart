import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late ProjectStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('signing');
    store = ProjectStore(p.join(tmp.path, 'ws'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ProjectHandle> project() async {
    final zip = File(p.join(tmp.path, 's.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(Archive()..add(ArchiveFile.bytes('index.html', utf8.encode('x')))));
    return (await store.importZip(zipPath: zip.path, name: 'A', applicationId: 'com.example.a')).project;
  }

  BuildRecord record({required String variant, required int code, String status = 'succeeded'}) => BuildRecord(
      time: DateTime.now(), engine: 'test', status: status, durationMs: 1, versionCode: code, variant: variant);

  test('release needs a higher version code than the last release', () async {
    var pr = await project();
    expect(store.releaseBlocker(pr), isNull);
    store.recordBuild(pr, record(variant: 'debug', code: 5));
    expect(store.releaseBlocker(pr), isNull, reason: 'debug builds do not count');
    store.recordBuild(pr, record(variant: 'release', code: 1, status: 'failed'));
    expect(store.releaseBlocker(pr), isNull, reason: 'failed releases do not count');
    store.recordBuild(pr, record(variant: 'release', code: 1));
    expect(store.releaseBlocker(pr), contains('not higher than the last release (1)'));
    pr = store.update(pr, pr.manifest.copyWith(android: pr.manifest.android.copyWith(versionCode: 2)));
    expect(store.releaseBlocker(pr), isNull);
  });

  test('build history keeps variant and signer', () async {
    final pr = await project();
    store.recordBuild(pr, BuildRecord(
        time: DateTime.now(), engine: 'gradle', status: 'succeeded', durationMs: 9, variant: 'release', signerSha256: 'AB:CD'));
    final r = store.buildHistory(pr).single;
    expect((r.variant, r.isRelease, r.signerSha256), ('release', true, 'AB:CD'));
  });

  test('manifest stores only the release certificate fingerprint', () async {
    final pr = await project();
    final updated = store.update(pr, pr.manifest.copyWith(releaseCertSha256: () => 'AA:BB'));
    final json = jsonDecode(File(p.join(updated.directory, 'project.json')).readAsStringSync()) as Map;
    expect(json['signing'], {'releaseCertSha256': 'AA:BB'});
    expect(store.load(updated.directory).manifest.releaseCertSha256, 'AA:BB');
    final text = File(p.join(updated.directory, 'project.json')).readAsStringSync().toLowerCase();
    expect(text, isNot(contains('password')));
  });

  test('parses apksigner certificate output', () {
    const out = 'Signer #1 certificate DN: CN=Jane\n'
        'Signer #1 certificate SHA-256 digest: 0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9\n';
    expect(parseSignerSha256(out), startsWith('0A:1B:2C:3D'));
    expect(parseSignerSha256(out)!.split(':'), hasLength(32));
    expect(parseSignerSha256('nothing here'), isNull);
  });

  test('Gradle engine refuses release builds without a keystore', () async {
    final pr = await project();
    final engine = GradleProjectBuildEngine(
      toolchain: const Toolchain(javaHome: 'x', androidSdk: 'x'),
      templateDir: 'x',
      buildsDir: p.join(tmp.path, 'b'),
    );
    final none = await engine.buildProject(pr, outputPath: 'o.apk', log: (_) {}, variant: BuildVariant.release);
    expect(none.message, contains('need a keystore'));
    final missing = await engine.buildProject(pr,
        outputPath: 'o.apk',
        log: (_) {},
        variant: BuildVariant.release,
        signing: const KeystoreFileSigning(path: 'nope.jks', alias: 'a', storePassword: 'x', keyPassword: 'x'));
    expect(missing.message, contains('Keystore not found'));
  });

  test('App Bundles are release-only and recorded as aab', () async {
    final pr = await project();
    final engine = GradleProjectBuildEngine(
      toolchain: const Toolchain(javaHome: 'x', androidSdk: 'x'),
      templateDir: 'x',
      buildsDir: p.join(tmp.path, 'b'),
    );
    final debugAab = await engine.buildProject(pr, outputPath: 'o.aab', log: (_) {}, format: ArtifactFormat.aab);
    expect(debugAab.message, contains('release-only'));
    expect(pr.releaseAabPath, endsWith('com.example.a-1.0.0-release.aab'));
    expect(const BuildRequest(projectDir: '.', variant: BuildVariant.release, format: ArtifactFormat.aab).gradleTask,
        'bundleRelease');
    store.recordBuild(pr, BuildRecord(
        time: DateTime.now(), engine: 'x', status: 'succeeded', durationMs: 1, variant: 'release', format: 'aab'));
    expect(store.buildHistory(pr).single.format, 'aab');
  });

  test('signing passwords are redacted from logs', () {
    expect(redactSecrets('HTML2APK_KEYSTORE_PASSWORD=hunter22'), isNot(contains('hunter22')));
    expect(redactSecrets('storePassword: s3cret'), isNot(contains('s3cret')));
  });
}
