import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

late Directory tmp;

String writeZip(Map<String, String> files, {String name = 'site.zip'}) {
  final archive = Archive();
  files.forEach((path, content) => archive.add(ArchiveFile.bytes(path, utf8.encode(content))));
  final path = p.join(tmp.path, name);
  File(path).writeAsBytesSync(ZipEncoder().encodeBytes(archive));
  return path;
}

ProjectManifest manifest({String id = 'com.example.app', ProjectSource? source}) => ProjectManifest(
      id: newProjectId(),
      name: 'Demo',
      source: source ?? const ProjectSource.local('index.html'),
      android: AndroidSettings(applicationId: id),
    );

void main() {
  setUp(() => tmp = Directory.systemTemp.createTempSync('html2apk_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('application ID', () {
    test('accepts valid IDs', () {
      expect(validateApplicationId('com.example.app'), isNull);
      expect(validateApplicationId('io.my_co.App2'), isNull);
    });
    test('rejects invalid IDs', () {
      for (final bad in ['', 'app', 'com.1app', 'com.example.', 'com..x', 'com.class.app', 'com.ex-ample.app', 'com.é.app']) {
        expect(validateApplicationId(bad), isNotNull, reason: bad);
      }
    });
  });

  group('manifest', () {
    test('round-trips through JSON and the migrator', () {
      final m = manifest().copyWith(iconPath: 'branding/icon.png');
      final loaded = const ManifestMigrator().load(m.toJsonString());
      expect(loaded.toJson(), m.toJson());
    });
    test('rejects newer and missing schema versions', () {
      final json = manifest().toJson()..['schemaVersion'] = currentSchemaVersion + 1;
      expect(() => const ManifestMigrator().migrate(json), throwsFormatException);
      expect(() => const ManifestMigrator().migrate({'name': 'x'}), throwsFormatException);
    });
    test('applies migrations in order', () {
      final migrator = ManifestMigrator(targetVersion: 3, migrations: {
        1: (j) => {...j, 'a': 1},
        2: (j) => {...j, 'b': (j['a'] as int) + 1},
      });
      final out = migrator.migrate({'schemaVersion': 1});
      expect(out, {'schemaVersion': 3, 'a': 1, 'b': 2});
    });
    test('validation flags bad fields', () {
      final m = ProjectManifest(
        id: 'x',
        name: ' ',
        source: const ProjectSource.local('../secret.html'),
        android: const AndroidSettings(applicationId: 'bad', versionCode: 0),
      );
      final fields = validateManifest(m).map((i) => i.field).toSet();
      expect(fields, containsAll(['name', 'android.applicationId', 'android.versionCode', 'source.entry']));
    });
  });

  group('URL policy', () {
    test('accepts public https URLs', () {
      expect(validateRemoteUrl('https://example.com/app'), isNull);
    });
    test('rejects unsafe URLs', () {
      for (final bad in [
        'http://example.com', 'file:///etc/passwd', 'javascript:alert(1)', 'https://localhost/',
        'https://127.0.0.1/', 'https://10.0.0.5/', 'https://192.168.1.1/', 'https://169.254.169.254/',
        'https://[::1]/', 'https://[fd00::1]/', 'https://user:pw@example.com/', 'example.com',
      ]) {
        expect(validateRemoteUrl(bad), isNotNull, reason: bad);
      }
    });
  });

  group('path safety', () {
    test('normalizes ordinary paths', () {
      expect(normalizeRelativePath('css\\site.css'), 'css/site.css');
      expect(normalizeRelativePath('./a//b.js'), 'a/b.js');
    });
    test('rejects traversal and non-portable names', () {
      for (final bad in ['../x', 'a/../../x', '/etc/passwd', 'C:/win.ini', 'C:x', 'a/CON.txt', 'a\u0000b', 'a/b.', 'a?b']) {
        expect(() => normalizeRelativePath(bad), throwsA(isA<UnsafePathException>()), reason: bad);
      }
    });
  });

  group('ZIP extraction', () {
    test('extracts and strips a single top-level folder', () async {
      final zip = writeZip({'site/index.html': '<h1>x</h1>', 'site/css/a.css': 'body{}', '__MACOSX/site/._index.html': ''});
      final r = await extractWebsiteZip(zip, p.join(tmp.path, 'out'));
      expect(r.strippedPrefix, 'site');
      expect(r.files..sort(), ['css/a.css', 'index.html']);
      expect(File(p.join(tmp.path, 'out', 'css', 'a.css')).existsSync(), isTrue);
    });
    test('rejects path traversal entries without writing outside', () async {
      final zip = writeZip({'index.html': 'x', '../../evil.txt': 'pwned'});
      await expectLater(extractWebsiteZip(zip, p.join(tmp.path, 'out')), throwsA(isA<ArchiveRejectedException>()));
      expect(File(p.join(tmp.path, 'evil.txt')).existsSync(), isFalse);
      expect(File(p.join(tmp.parent.path, 'evil.txt')).existsSync(), isFalse);
    });
    test('rejects absolute and drive-letter entries', () async {
      for (final bad in ['/abs.txt', 'C:\\x.txt']) {
        final zip = writeZip({'index.html': 'x', bad: 'y'}, name: 'b${bad.length}.zip');
        await expectLater(extractWebsiteZip(zip, p.join(tmp.path, 'o${bad.length}')),
            throwsA(isA<ArchiveRejectedException>()), reason: bad);
      }
    });
    test('enforces size limits', () async {
      final zip = writeZip({'index.html': 'x' * 2000});
      await expectLater(
          extractWebsiteZip(zip, p.join(tmp.path, 'out'), limits: const ExtractionLimits(maxFileBytes: 1000)),
          throwsA(isA<ArchiveRejectedException>()));
    });
    test('stops ZIP bombs with forged sizes while decompressing', () async {
      // 40 MB of zeros compresses to ~40 KB; then claim it is only 1000 bytes
      // in both the local and central headers.
      final archive = Archive()
        ..add(ArchiveFile.bytes('index.html', utf8.encode('<p>x</p>')))
        ..add(ArchiveFile.bytes('bomb.bin', Uint8List(40 * 1024 * 1024)));
      final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));
      expect(bytes.length, lessThan(1024 * 1024));
      final d = ByteData.sublistView(bytes);
      var patched = 0;
      for (var i = 0; i + 30 < bytes.length; i++) {
        final sig = d.getUint32(i, Endian.little);
        if (sig == 0x04034b50 && utf8.decode(bytes.sublist(i + 30, i + 38), allowMalformed: true) == 'bomb.bin') {
          d.setUint32(i + 22, 1000, Endian.little); // local header: uncompressed size
          patched++;
        } else if (sig == 0x02014b50 && utf8.decode(bytes.sublist(i + 46, i + 54), allowMalformed: true) == 'bomb.bin') {
          d.setUint32(i + 24, 1000, Endian.little); // central directory: uncompressed size
          patched++;
        }
      }
      expect(patched, 2);
      final zip = File(p.join(tmp.path, 'bomb.zip'))..writeAsBytesSync(bytes);
      final out = p.join(tmp.path, 'out');
      // Rejected either by the decompressor (data larger than declared) or by
      // our streaming size limit; both stop before the real 40 MB is written.
      await expectLater(
        extractWebsiteZip(zip.path, out, limits: const ExtractionLimits(maxFileBytes: 5 * 1024 * 1024)),
        throwsA(isA<ArchiveRejectedException>()),
      );
      final partial = File(p.join(out, 'bomb.bin'));
      expect(!partial.existsSync() || partial.lengthSync() <= 5 * 1024 * 1024 + 64 * 1024, isTrue,
          reason: 'never writes far past the limit');
    });

    test('honest but oversized entries are cut off by the streaming limit', () async {
      // Headers tell the truth here, so the per-entry limit must stop it.
      final zip = writeZip({'index.html': 'x', 'big.bin': 'z' * (3 * 1024 * 1024)});
      await expectLater(
        extractWebsiteZip(zip, p.join(tmp.path, 'out'),
            limits: const ExtractionLimits(maxFileBytes: 1024 * 1024, maxCompressionRatio: 1 << 30)),
        throwsA(isA<ArchiveRejectedException>().having((e) => e.message, 'message', contains('too large'))),
      );
    });

    test('total size limit counts real bytes', () async {
      final zip = writeZip({'index.html': 'x' * 600, 'b.html': 'y' * 600});
      await expectLater(
        extractWebsiteZip(zip, p.join(tmp.path, 'out'), limits: const ExtractionLimits(maxTotalBytes: 1000)),
        throwsA(isA<ArchiveRejectedException>().having((e) => e.message, 'message', contains('too large'))),
      );
    });

    test('rejects case-insensitive duplicates', () async {
      final zip = writeZip({'index.html': 'x', 'INDEX.html': 'y'});
      await expectLater(extractWebsiteZip(zip, p.join(tmp.path, 'out')), throwsA(isA<ArchiveRejectedException>()));
    });
    test('rejects non-ZIP input', () async {
      final f = File(p.join(tmp.path, 'x.zip'))..writeAsStringSync('not a zip');
      await expectLater(extractWebsiteZip(f.path, p.join(tmp.path, 'out')), throwsA(isA<ArchiveRejectedException>()));
    });
  });

  group('site analysis', () {
    test('prefers shallow index.html', () {
      expect(findEntryCandidates(['docs/index.html', 'about.html', 'index.html', 'a.css']).first, 'index.html');
      expect(findEntryCandidates(['pages/home.html', 'main.htm']).first, 'main.htm');
      expect(findEntryCandidates(['a.css']), isEmpty);
    });
    test('detects missing relative assets', () {
      final root = Directory(p.join(tmp.path, 's'))..createSync();
      File(p.join(root.path, 'index.html')).writeAsStringSync(
          '<link href="css/a.css"><script src="js/missing.js"></script>'
          '<img src="https://cdn.example.com/x.png"><a href="#top">t</a><img src="data:image/png;base64,AA">');
      Directory(p.join(root.path, 'css')).createSync();
      File(p.join(root.path, 'css', 'a.css')).writeAsStringSync('body{background:url("../img/bg.png")}');
      final missing = findMissingAssets(root.path, ['index.html', 'css/a.css']);
      expect(missing.map((m) => m.reference), unorderedEquals(['js/missing.js', '../img/bg.png']));
    });
    test('letter case must match exactly, as in the APK and the Windows app', () {
      final root = Directory(p.join(tmp.path, 's'))..createSync();
      File(p.join(root.path, 'index.html'))
          .writeAsStringSync('<img src="img/Logo.png"><link href="CSS/a.css"><img src="img/logo.png">');
      Directory(p.join(root.path, 'img')).createSync();
      File(p.join(root.path, 'img', 'logo.png')).writeAsStringSync('png');
      Directory(p.join(root.path, 'css')).createSync();
      File(p.join(root.path, 'css', 'a.css')).writeAsStringSync('');
      final missing = findMissingAssets(root.path, ['css/a.css', 'img/logo.png', 'index.html']);
      expect({for (final m in missing) m.reference: m.differentCase},
          {'img/Logo.png': 'img/logo.png', 'CSS/a.css': 'css/a.css'});
      expect(missing.first.toString(), contains('letter case must match'));
    });
  });

  group('resource writers', () {
    test('escapes Android strings', () {
      expect(androidStringEscape("Tom's <App> & \"Co\""), r"Tom\'s &lt;App&gt; &amp; \" + '"Co\\"');
      expect(androidStringEscape('@home'), r'\@home');
    });
    test('escapes properties', () {
      expect(encodeProperties({'sdk.dir': r'C:\Android\Sdk'}), contains(r'sdk.dir=C\:\\Android\\Sdk'));
      expect(encodeProperties({'v': '1.0 é'}), contains(r'v=1.0 \u00e9'));
    });
    test('reads PNG dimensions', () {
      final b = Uint8List(24)
        ..setAll(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13])
        ..setAll(12, 'IHDR'.codeUnits);
      ByteData.sublistView(b)
        ..setUint32(16, 512)
        ..setUint32(20, 256);
      final info = readPngInfo(b)!;
      expect((info.width, info.height), (512, 256));
      expect(readPngInfo(Uint8List.fromList(utf8.encode('GIF89a' * 5))), isNull);
    });
  });

  group('android generator', () {
    test('manifest adds INTERNET only when needed', () {
      expect(AndroidGenerator.buildAndroidManifest(manifest()), isNot(contains('INTERNET')));
      final remote = manifest(source: const ProjectSource.url('https://example.com'));
      expect(AndroidGenerator.buildAndroidManifest(remote), contains('android.permission.INTERNET'));
      expect(AndroidGenerator.runtimeConfig(remote)['source'], {'type': 'remote', 'entry': 'https://example.com'});
    });
    test('file sharing options: defaults, round trip, validation and output', () {
      final m = manifest();
      expect(m.webView.shareFiles, isTrue);
      expect(m.webView.galleryFolder, isNull);
      expect(m.webView.shareTarget, isNull);
      // Projects saved before these options existed get the defaults.
      final old = Map<String, Object?>.of(m.webView.toJson())
        ..remove('shareFiles')
        ..remove('galleryFolder')
        ..remove('shareTarget');
      expect(WebViewSettings.fromJson(old).shareFiles, isTrue);

      final set = m.copyWith(
          webView: m.webView.copyWith(shareFiles: false, galleryFolder: () => 'Kishor G', shareTarget: () => 'com.whatsapp'));
      final back = WebViewSettings.fromJson(jsonDecode(jsonEncode(set.webView.toJson())) as Map<String, Object?>);
      expect([back.shareFiles, back.galleryFolder, back.shareTarget], [false, 'Kishor G', 'com.whatsapp']);
      expect(validateManifest(set), isEmpty);
      final config = AndroidGenerator.runtimeConfig(set);
      expect([config['shareFiles'], config['galleryFolder'], config['shareTarget']], [false, 'Kishor G', 'com.whatsapp']);
      expect(set.webView.copyWith(galleryFolder: () => null).galleryFolder, isNull);

      for (final bad in ['a/b', r'a\b', '../x', ' x', '.hidden', 'x' * 61, 'a:b']) {
        final issues = validateManifest(m.copyWith(webView: m.webView.copyWith(galleryFolder: () => bad)));
        expect(issues.map((i) => i.field), contains('webView.galleryFolder'), reason: bad);
      }
      for (final bad in ['whatsapp', 'com..x', 'com.x;y', '1com.x']) {
        final issues = validateManifest(m.copyWith(webView: m.webView.copyWith(shareTarget: () => bad)));
        expect(issues.map((i) => i.field), contains('webView.shareTarget'), reason: bad);
      }
    });
    test('manifest has no FileProvider (Android 10+ shares through MediaStore)', () {
      final xml = AndroidGenerator.buildAndroidManifest(manifest());
      expect(xml, isNot(contains('<provider')));
      expect(xml, isNot(contains('html2apk_file_paths')));
    });
    test('generates a project from the template', () async {
      final template = p.normalize(p.join(Directory.current.path, '..', '..', 'android_template'));
      final store = ProjectStore(p.join(tmp.path, 'ws'));
      final zip = writeZip({'index.html': '<p>hi</p>', 'img/logo.svg': '<svg/>'});
      final report = await store.importZip(zipPath: zip, name: "Bob's App", applicationId: 'com.example.bob');
      final out = p.join(tmp.path, 'gen');
      AndroidGenerator(templateDir: template).generate(report.project, out, androidSdkDir: r'C:\sdk');
      final main = p.join(out, 'app', 'src', 'main');
      expect(File(p.join(main, 'assets', 'www', 'img', 'logo.svg')).existsSync(), isTrue);
      expect(File(p.join(main, 'res', 'values', 'app_strings.xml')).readAsStringSync(), contains(r"Bob\'s App"));
      expect(File(p.join(out, 'wrapper.properties')).readAsStringSync(), contains('applicationId=com.example.bob'));
      expect(Directory(p.join(out, 'app', 'build')).existsSync(), isFalse);
      final config = jsonDecode(File(p.join(main, 'assets', 'app_config.json')).readAsStringSync());
      expect(config['source'], {'type': 'local', 'entry': 'index.html'});
    });
    test('rejects non-square icons', () async {
      final template = p.normalize(p.join(Directory.current.path, '..', '..', 'android_template'));
      final icon = File(p.join(tmp.path, 'icon.png'));
      final b = Uint8List(24)
        ..setAll(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13])
        ..setAll(12, 'IHDR'.codeUnits);
      ByteData.sublistView(b)
        ..setUint32(16, 100)
        ..setUint32(20, 50);
      icon.writeAsBytesSync(b);
      final store = ProjectStore(p.join(tmp.path, 'ws'));
      final report = await store.importZip(
          zipPath: writeZip({'index.html': 'x'}), name: 'A', applicationId: 'com.example.a', iconPng: icon.path);
      expect(() => AndroidGenerator(templateDir: template).generate(report.project, p.join(tmp.path, 'g'), androidSdkDir: 'x'),
          throwsA(isA<InvalidProjectException>()));
    });
  });

  group('project store', () {
    Uint8List png(int w, int h) {
      final b = Uint8List(24)
        ..setAll(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13])
        ..setAll(12, 'IHDR'.codeUnits);
      ByteData.sublistView(b)
        ..setUint32(16, w)
        ..setUint32(20, h);
      return b;
    }

    test('lists projects and reports broken ones', () async {
      final store = ProjectStore(p.join(tmp.path, 'ws'));
      expect(store.listProjects().$1, isEmpty);
      final a = await store.importZip(zipPath: writeZip({'index.html': 'a'}, name: 'a.zip'), name: 'A', applicationId: 'com.example.a');
      await store.importZip(zipPath: writeZip({'index.html': 'b'}, name: 'b.zip'), name: 'B', applicationId: 'com.example.b');
      Directory(p.join(store.projectsDir, 'junk')).createSync();
      File(p.join(store.projectsDir, 'junk', 'project.json')).writeAsStringSync('{"schemaVersion": 99}');
      final (projects, broken) = store.listProjects();
      expect(projects.map((x) => x.manifest.name).toSet(), {'A', 'B'});
      expect(broken.single.directory, endsWith('junk'));
      store.delete(a.project);
      expect(store.listProjects().$1.single.manifest.name, 'B');
    });

    test('update validates and persists', () async {
      final store = ProjectStore(p.join(tmp.path, 'ws'));
      final r = await store.importZip(
          zipPath: writeZip({'index.html': 'a', 'b.html': 'b'}), name: 'A', applicationId: 'com.example.a');
      final m = r.project.manifest;
      final updated = store.update(r.project,
          m.copyWith(source: const ProjectSource.local('b.html'), orientation: Orientation.portrait));
      expect(store.load(updated.directory).manifest.source.entry, 'b.html');
      expect(store.load(updated.directory).manifest.orientation, Orientation.portrait);
      expect(() => store.update(r.project, m.copyWith(source: const ProjectSource.local('missing.html'))),
          throwsA(isA<InvalidProjectException>()));
      expect(() => store.update(r.project, m.copyWith(android: m.android.copyWith(applicationId: 'bad'))),
          throwsA(isA<InvalidProjectException>()));
    });

    test('setIcon accepts square PNGs only', () async {
      final store = ProjectStore(p.join(tmp.path, 'ws'));
      final r = await store.importZip(zipPath: writeZip({'index.html': 'a'}), name: 'A', applicationId: 'com.example.a');
      final bad = File(p.join(tmp.path, 'bad.png'))..writeAsBytesSync(png(100, 50));
      expect(() => store.setIcon(r.project, bad.path), throwsA(isA<InvalidProjectException>()));
      final good = File(p.join(tmp.path, 'good.png'))..writeAsBytesSync(png(512, 512));
      final updated = store.setIcon(r.project, good.path);
      expect(updated.manifest.iconPath, 'branding/icon.png');
      expect(File(updated.iconFile!).existsSync(), isTrue);
    });

    test('records build history newest first', () async {
      final store = ProjectStore(p.join(tmp.path, 'ws'));
      final r = await store.importZip(zipPath: writeZip({'index.html': 'a'}), name: 'A', applicationId: 'com.example.a');
      for (final s in ['failed', 'succeeded']) {
        store.recordBuild(r.project, BuildRecord(time: DateTime.now(), engine: 'test', status: s, durationMs: 5));
      }
      final h = store.buildHistory(r.project);
      expect(h.map((b) => b.status), ['succeeded', 'failed']);
      expect(h.first.succeeded, isTrue);
    });

    test('permissions and orientation mapping', () {
      expect(AndroidGenerator.permissionsFor(manifest()), isEmpty);
      expect(AndroidGenerator.permissionsFor(manifest().copyWith(internetAccess: true)), ['android.permission.INTERNET']);
      expect(AndroidGenerator.screenOrientationValue(Orientation.portrait), 1);
      expect(AndroidGenerator.screenOrientationValue(Orientation.unspecified), -1);
    });
  });

  group('build orchestration', () {
    test('maps variants and formats to Gradle tasks', () {
      expect(const BuildRequest(projectDir: '.').gradleTask, 'assembleDebug');
      expect(const BuildRequest(projectDir: '.', variant: BuildVariant.release, format: ArtifactFormat.aab).gradleTask,
          'bundleRelease');
    });
    test('locates only the requested artifact type', () {
      final dir = Directory(p.join(tmp.path, 'app', 'build', 'outputs', 'apk', 'debug'))..createSync(recursive: true);
      File(p.join(dir.path, 'app-debug.apk')).writeAsStringSync('');
      File(p.join(dir.path, 'output-metadata.json')).writeAsStringSync('{}');
      expect(GradleProcessBuildAdapter.locateArtifact(BuildRequest(projectDir: tmp.path)), endsWith('app-debug.apk'));
      expect(GradleProcessBuildAdapter.locateArtifact(BuildRequest(projectDir: tmp.path, format: ArtifactFormat.aab)), isNull);
    });
    test('artifact inspector flags incomplete APKs', () {
      final path = writeZip({'AndroidManifest.xml': 'x'}, name: 'fake.apk');
      final problems = inspectArtifact(path, ArtifactFormat.apk).problems;
      expect(problems, contains('missing classes.dex'));
    });
    test('redacts secrets from logs', () {
      expect(redactSecrets('-Pandroid.injected.signing.store.password=hunter2 ok'), isNot(contains('hunter2')));
      expect(redactSecrets('keyPassword: "s3cr3t"'), isNot(contains('s3cr3t')));
      expect(redactSecrets('apksigner --ks-pass pass:abc123'), isNot(contains('abc123')));
      expect(redactSecrets('> Task :app:assembleDebug'), '> Task :app:assembleDebug');
    });
    test('reads JDK versions', () {
      File(p.join(tmp.path, 'release')).writeAsStringSync('JAVA_VERSION="1.8.0_392"\n');
      expect(readJdkFeatureVersion(tmp.path), 8);
      File(p.join(tmp.path, 'release')).writeAsStringSync('IMPLEMENTOR="x"\nJAVA_VERSION="21.0.3"\n');
      expect(readJdkFeatureVersion(tmp.path), 21);
    });
  });
}
