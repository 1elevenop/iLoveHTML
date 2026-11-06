import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A PNG header is enough for setSplash's size check.
Uint8List png(int w, int h) {
  final b = Uint8List(24)
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
    tmp = Directory.systemTemp.createTempSync('backup');
    store = ProjectStore(p.join(tmp.path, 'ws'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ProjectHandle> sample() async {
    final zip = Archive()
      ..addFile(ArchiveFile.string('index.html', '<html><a href="cart.html">c</a></html>'))
      ..addFile(ArchiveFile.string('cart.html', '<html>cart</html>'))
      ..addFile(ArchiveFile.string('css/a.css', 'a{}'));
    final zipPath = p.join(tmp.path, 'site.zip');
    File(zipPath).writeAsBytesSync(ZipEncoder().encode(zip));
    var project = (await store.importZip(zipPath: zipPath, name: 'My Shop!', applicationId: 'com.example.shop')).project;
    project = store.setSplash(project, (File(p.join(tmp.path, 's.png'))..writeAsBytesSync(png(512, 512))).path);
    return store.update(
        project,
        project.manifest.copyWith(
          shortcuts: const [AppShortcut(label: 'Cart', page: 'cart.html')],
          appearance: project.manifest.appearance.copyWith(theme: AppTheme.dark),
        ));
  }

  Map<String, String> entries(String zipPath) => {
        for (final f in ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync()).files)
          if (f.isFile) f.name: utf8.decode(f.content, allowMalformed: true),
      };

  test('backup holds settings, site and branding, and nothing else', () async {
    final project = await sample();
    Directory(project.exportsDir).createSync(recursive: true);
    File(p.join(project.exportsDir, 'old.apk')).writeAsStringSync('apk');
    final out = p.join(tmp.path, backupFileName(project));
    expect(p.basename(out), 'My Shop_.ilovehtml');
    await exportProjectBackup(project, out);
    final names = entries(out).keys.toSet();
    expect(names, containsAll(['ilovehtml-backup.json', 'project.json', 'source/index.html', 'source/css/a.css']));
    expect(names.where((n) => n.startsWith('branding/')), isNotEmpty);
    expect(names.any((n) => n.startsWith('exports/')), isFalse);
    expect(File('$out.tmp').existsSync(), isFalse);
  });

  test('restore makes a new project with the same settings and files', () async {
    final original = await sample();
    final out = p.join(tmp.path, 'b.ilovehtml');
    await exportProjectBackup(original, out);

    final other = ProjectStore(p.join(tmp.path, 'other-ws'));
    final restored = await importProjectBackup(other, out);
    expect(restored.manifest.id, isNot(original.manifest.id));
    expect(restored.manifest.name, 'My Shop!');
    expect(restored.manifest.android.applicationId, 'com.example.shop');
    expect(restored.manifest.appearance.theme, AppTheme.dark);
    expect(restored.manifest.shortcuts.single.page, 'cart.html');
    expect(File(p.join(restored.sourceDir, 'css', 'a.css')).readAsStringSync(), 'a{}');
    expect(restored.splashFile, isNotNull);
    expect(File(restored.splashFile!).existsSync(), isTrue);
    final (listed, broken) = other.listProjects();
    expect(listed.map((x) => x.manifest.id), [restored.manifest.id]);
    expect(broken, isEmpty);

    // Restoring into the same workspace gives a second, separate project.
    final again = await importProjectBackup(store, out);
    expect(store.listProjects().$1, hasLength(2));
    expect(again.directory, isNot(original.directory));
  });

  test('rejects files that are not backups and leaves nothing behind', () async {
    final zip = Archive()..addFile(ArchiveFile.string('index.html', '<html></html>'));
    final path = p.join(tmp.path, 'site.ilovehtml');
    File(path).writeAsBytesSync(ZipEncoder().encode(zip));
    await expectLater(importProjectBackup(store, path), throwsA(isA<ArchiveRejectedException>()));
    expect(Directory(store.projectsDir).listSync(), isEmpty);
  });

  test('rejects newer formats and paths outside the project', () async {
    Future<void> expectRejected(Archive a) async {
      final path = p.join(tmp.path, 'x.ilovehtml');
      File(path).writeAsBytesSync(ZipEncoder().encode(a));
      await expectLater(importProjectBackup(store, path), throwsA(anything));
      expect(Directory(store.projectsDir).listSync(), isEmpty);
    }

    final project = await sample();
    final manifest = project.manifest.toJsonString();
    Directory(project.directory).deleteSync(recursive: true);
    await expectRejected(Archive()
      ..addFile(ArchiveFile.string('ilovehtml-backup.json', '{"format": 99}'))
      ..addFile(ArchiveFile.string('project.json', manifest))
      ..addFile(ArchiveFile.string('source/index.html', 'x')));
    await expectRejected(Archive()
      ..addFile(ArchiveFile.string('ilovehtml-backup.json', '{"format": 1}'))
      ..addFile(ArchiveFile.string('project.json', manifest))
      ..addFile(ArchiveFile.string('../evil.html', 'x')));
  });

  test('icon or splash paths outside branding/ are dropped', () async {
    final project = await sample();
    final json = project.manifest.toJson()
      ..['branding'] = {'icon': 'source/index.html', 'splash': '../../etc/passwd'};
    final path = p.join(tmp.path, 'y.ilovehtml');
    File(path).writeAsBytesSync(ZipEncoder().encode(Archive()
      ..addFile(ArchiveFile.string('ilovehtml-backup.json', '{"format": 1}'))
      ..addFile(ArchiveFile.string('project.json', jsonEncode(json)))
      ..addFile(ArchiveFile.string('source/index.html', '<html></html>'))
      ..addFile(ArchiveFile.string('source/cart.html', '<html></html>'))));
    final restored = await importProjectBackup(store, path);
    expect(restored.manifest.iconPath, isNull);
    expect(restored.manifest.splashPath, isNull);
  });
}
