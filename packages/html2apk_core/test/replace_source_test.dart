import 'dart:io';

import 'package:archive/archive.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late ProjectStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('replace');
    store = ProjectStore(p.join(tmp.path, 'ws'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  String zip(String name, Map<String, String> files) {
    final a = Archive();
    files.forEach((k, v) => a.addFile(ArchiveFile.string(k, v)));
    final path = p.join(tmp.path, name);
    File(path).writeAsBytesSync(ZipEncoder().encode(a));
    return path;
  }

  Future<ProjectHandle> sample() async {
    final z = zip('v1.zip', {
      'index.html': '<html>v1</html>',
      'cart.html': '<html>cart</html>',
      'old.css': 'a{}',
    });
    final project = (await store.importZip(zipPath: z, name: 'Shop', applicationId: 'com.example.shop')).project;
    return store.update(
      project,
      project.manifest.copyWith(
        shortcuts: const [AppShortcut(label: 'Cart', page: 'cart.html')],
        android: project.manifest.android.copyWith(versionCode: 4),
      ),
    );
  }

  test('replaces the files and keeps settings, start page and shortcuts', () async {
    final project = await sample();
    final z = zip('v2.zip', {'index.html': '<html>v2</html>', 'cart.html': '<html>cart 2</html>'});
    final r = await store.replaceWithZip(project, z);
    final m = r.import.project.manifest;
    expect(m.id, project.manifest.id);
    expect(m.name, 'Shop');
    expect(m.android.applicationId, 'com.example.shop');
    expect(m.android.versionCode, 4);
    expect(m.source.entry, 'index.html');
    expect(m.shortcuts.single.page, 'cart.html');
    expect(r.startPageChanged, isFalse);
    expect(r.droppedShortcuts, isEmpty);
    expect(File(p.join(project.sourceDir, 'index.html')).readAsStringSync(), '<html>v2</html>');
    // Old files are gone, and no temp folders are left behind.
    expect(File(p.join(project.sourceDir, 'old.css')).existsSync(), isFalse);
    expect(Directory('${project.sourceDir}.old').existsSync(), isFalse);
    expect(Directory('${project.sourceDir}.new').existsSync(), isFalse);
    expect(store.load(project.directory).manifest.source.entry, 'index.html');
  });

  test('picks a new start page and drops shortcuts whose pages are gone', () async {
    final project = await sample();
    final z = zip('v2.zip', {'home.html': '<html>home</html>'});
    final r = await store.replaceWithZip(project, z);
    expect(r.import.project.manifest.source.entry, 'home.html');
    expect(r.startPageChanged, isTrue);
    expect(r.previousStartPage, 'index.html');
    expect(r.droppedShortcuts, ['cart.html']);
    expect(r.import.project.manifest.shortcuts, isEmpty);
  });

  test('a ZIP without HTML leaves the old website untouched', () async {
    final project = await sample();
    final z = zip('bad.zip', {'readme.txt': 'hi'});
    await expectLater(store.replaceWithZip(project, z), throwsA(isA<ArchiveRejectedException>()));
    expect(File(p.join(project.sourceDir, 'index.html')).readAsStringSync(), '<html>v1</html>');
    expect(Directory('${project.sourceDir}.new').existsSync(), isFalse);
  });

  test('replaces from picked files', () async {
    final project = await sample();
    final page = File(p.join(tmp.path, 'pick', 'index.html'))
      ..createSync(recursive: true)
      ..writeAsStringSync('<html>picked</html>');
    final r = await store.replaceWithFiles(project, [page.path]);
    expect(r.import.fileCount, 1);
    expect(File(p.join(project.sourceDir, 'index.html')).readAsStringSync(), '<html>picked</html>');
  });

  test('URL projects cannot have files replaced', () async {
    final project = store.createFromUrl(url: 'https://example.com/', name: 'Web', applicationId: 'com.example.web');
    final z = zip('v2.zip', {'index.html': '<html></html>'});
    await expectLater(store.replaceWithZip(project, z), throwsA(isA<InvalidProjectException>()));
  });
}
