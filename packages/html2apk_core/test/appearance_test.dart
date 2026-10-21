import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A schema-1 project.json exactly as written by the previous release.
const _v1 = '''
{
  "schemaVersion": 1,
  "id": "545b0b60-a1d0-41d1-a599-d9b0fd7fe407",
  "name": "Phone Demo",
  "source": {"type": "local", "entry": "index.html"},
  "android": {"applicationId": "com.html2apk.phonedemo", "versionName": "1.1.0", "versionCode": 2},
  "branding": {"icon": "branding/icon.png", "splash": null},
  "orientation": "portrait",
  "webView": {"javaScriptEnabled": true, "domStorageEnabled": true, "externalLinks": "browser",
              "allowedHosts": [], "userAgentSuffix": null},
  "permissions": [],
  "network": {"internet": false},
  "offline": {"fallbackPage": null},
  "buildProfiles": ["debug"],
  "exportFormats": ["apk"]
}''';

Uint8List png(int w, int h, {int padTo = 24}) {
  final b = Uint8List(padTo)
    ..setAll(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13])
    ..setAll(12, 'IHDR'.codeUnits);
  ByteData.sublistView(b)
    ..setUint32(16, w)
    ..setUint32(20, h);
  return b;
}

void main() {
  late Directory tmp;
  late ProjectStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('appearance');
    store = ProjectStore(p.join(tmp.path, 'ws'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ProjectHandle> localProject() async {
    final zip = File(p.join(tmp.path, 's.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(Archive()..add(ArchiveFile.bytes('index.html', utf8.encode('<p>x</p>')))));
    return (await store.importZip(zipPath: zip.path, name: 'A', applicationId: 'com.example.a')).project;
  }

  group('schema 1 -> 2 migration', () {
    test('keeps every v1 value and adds defaults', () {
      final m = const ManifestMigrator().load(_v1);
      expect(m.name, 'Phone Demo');
      expect(m.android.versionCode, 2);
      expect(m.orientation, Orientation.portrait);
      expect(m.iconPath, 'branding/icon.png');
      expect(m.webView.pullToRefresh, isFalse);
      expect(m.webView.fileUploads, isTrue);
      expect(m.appearance.statusBarColor, '#000000');
      expect(m.toJson()['schemaVersion'], 2);
    });

    test('turns on pull-to-refresh for URL projects', () {
      final json = jsonDecode(_v1) as Map<String, Object?>;
      json['source'] = {'type': 'url', 'entry': 'https://example.com/'};
      final m = const ManifestMigrator().load(jsonEncode(json));
      expect(m.webView.pullToRefresh, isTrue);
    });

    test('migrated projects load from disk and save as v2', () async {
      final project = await localProject();
      File(p.join(project.directory, 'project.json')).writeAsStringSync(_v1);
      final loaded = store.load(project.directory);
      store.save(loaded);
      expect(jsonDecode(File(p.join(project.directory, 'project.json')).readAsStringSync())['schemaVersion'], 2);
    });
  });

  test('validates colours and offline page paths', () async {
    final m = (await localProject()).manifest;
    expect(isHexColor('#1a73E8'), isTrue);
    for (final bad in ['1A73E8', '#FFF', '#GGGGGG', '#1A73E8FF', 'red']) {
      expect(isHexColor(bad), isFalse, reason: bad);
    }
    final issues = validateManifest(m.copyWith(
      appearance: m.appearance.copyWith(statusBarColor: 'blue'),
      offlineFallbackPage: () => '../x.html',
    ));
    expect(issues.map((i) => i.field), containsAll(['appearance.statusBarColor', 'offline.fallbackPage']));
  });

  test('splash image is validated, stored and cleared', () async {
    var project = await localProject();
    final big = File(p.join(tmp.path, 'big.png'))..writeAsBytesSync(png(5000, 100));
    expect(() => store.setSplash(project, big.path), throwsA(isA<InvalidProjectException>()));
    final ok = File(p.join(tmp.path, 'ok.png'))..writeAsBytesSync(png(1080, 1920));
    project = store.setSplash(project, ok.path);
    expect(project.manifest.splashPath, 'branding/splash.png');
    expect(File(project.splashFile!).existsSync(), isTrue);
    project = store.clearSplash(project);
    expect(project.manifest.splashPath, isNull);
    expect(File(p.join(project.brandingDir, 'splash.png')).existsSync(), isFalse);
  });

  test('offline page is copied into source and cleared for URL projects', () {
    var project = store.createFromUrl(url: 'https://example.com/', name: 'W', applicationId: 'com.example.w');
    expect(project.manifest.webView.pullToRefresh, isTrue);
    final notHtml = File(p.join(tmp.path, 'x.txt'))..writeAsStringSync('hello');
    expect(() => store.setOfflinePage(project, notHtml.path), throwsA(isA<InvalidProjectException>()));
    final page = File(p.join(tmp.path, 'mine.html'))..writeAsStringSync('<!doctype html><p>Offline</p>');
    project = store.setOfflinePage(project, page.path);
    expect(project.manifest.offlineFallbackPage, 'offline.html');
    expect(File(p.join(project.sourceDir, 'offline.html')).readAsStringSync(), contains('Offline'));
    project = store.clearOfflinePage(project);
    expect(project.manifest.offlineFallbackPage, isNull);
    expect(File(p.join(project.sourceDir, 'offline.html')).existsSync(), isFalse);
  });

  test('generator bundles splash, offline page and the new runtime config', () {
    var project = store.createFromUrl(url: 'https://example.com/', name: 'W', applicationId: 'com.example.w');
    project = store.setOfflinePage(project, (File(p.join(tmp.path, 'o.html'))..writeAsStringSync('<html>off</html>')).path);
    project = store.setSplash(project, (File(p.join(tmp.path, 's.png'))..writeAsBytesSync(png(512, 512))).path);
    project = store.update(project, project.manifest.copyWith(
      appearance: const AppearanceSettings(statusBarColor: '#1A73E8', navigationBarColor: '#FFFFFF', splashEnabled: true),
    ));
    final template = p.normalize(p.join(Directory.current.path, '..', '..', 'android_template'));
    final out = p.join(tmp.path, 'gen');
    AndroidGenerator(templateDir: template).generate(project, out, androidSdkDir: 'x');
    final assets = p.join(out, 'app', 'src', 'main', 'assets');
    expect(File(p.join(assets, 'www', 'offline.html')).existsSync(), isTrue);
    expect(File(p.join(assets, 'branding', 'splash.png')).existsSync(), isTrue);
    final config = jsonDecode(File(p.join(assets, 'app_config.json')).readAsStringSync()) as Map;
    expect(config['statusBarColor'], '#1A73E8');
    expect(config['navigationBarColor'], '#FFFFFF');
    expect(config['pullToRefresh'], isTrue);
    expect(config['fileUploads'], isTrue);
    expect(config['offlinePage'], 'offline.html');
    expect(config['splash'], {'enabled': true, 'backgroundColor': '#FFFFFF', 'image': 'branding/splash.png'});
  });
}
