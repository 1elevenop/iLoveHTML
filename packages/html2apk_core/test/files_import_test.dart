import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory picked;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('files_import');
    picked = Directory(p.join(tmp.path, 'picked'))..createSync();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  String pick(String name, String content) {
    final f = File(p.join(picked.path, name))..writeAsStringSync(content);
    return f.path;
  }

  String out() => p.join(tmp.path, 'site');

  test('a single self-contained HTML file becomes the start page', () async {
    final store = ProjectStore(p.join(tmp.path, 'ws'));
    final report = await store.importFiles(
      paths: [pick('My Page.html', '<style>body{color:red}</style><h1>Hi</h1><script>1</script>')],
      name: 'One File',
      applicationId: 'com.example.onefile',
    );
    expect(report.project.manifest.source.entry, 'My Page.html');
    expect(report.fileCount, 1);
    expect(report.missingAssets, isEmpty);
  });

  test('picked files are moved into the folders the page links to', () {
    final paths = [
      pick('index.html', '<link href="css/style.css"><script src="js/app.js"></script>'
          '<img src="images/logo.png"><a href="about.html">About</a>'),
      pick('about.html', '<p>About</p>'),
      pick('style.css', 'body{background:url("../images/bg.png")}'),
      pick('app.js', 'console.log(1)'),
      pick('logo.png', 'png'),
      pick('bg.png', 'png'),
    ];
    final r = importLooseFiles(paths, out());
    expect(r.files..sort(), ['about.html', 'css/style.css', 'images/bg.png', 'images/logo.png', 'index.html', 'js/app.js']);
    expect(r.moved, containsPair('style.css', 'css/style.css'));
    // bg.png is only found after style.css moved into css/ (second pass).
    expect(r.moved, containsPair('bg.png', 'images/bg.png'));
    expect(findMissingAssets(out(), r.files), isEmpty);
  });

  test('a file used at the root and in a folder keeps both copies', () {
    final r = importLooseFiles([
      pick('index.html', '<img src="logo.png"><img src="img/logo.png">'),
      pick('logo.png', 'png'),
    ], out());
    expect(r.files..sort(), ['img/logo.png', 'index.html', 'logo.png']);
  });

  test('missing files are still reported', () async {
    final store = ProjectStore(p.join(tmp.path, 'ws'));
    final report = await store.importFiles(
      paths: [pick('index.html', '<link href="css/site.css"><img src="photo.jpg">')],
      name: 'A',
      applicationId: 'com.example.a',
    );
    expect(report.missingAssets.map((m) => m.reference), unorderedEquals(['css/site.css', 'photo.jpg']));
  });

  test('rejects selections without HTML, duplicates and oversized files', () {
    expect(() => importLooseFiles([pick('a.css', 'x')], out()), throwsA(isA<ArchiveRejectedException>()));
    final sub = Directory(p.join(tmp.path, 'other'))..createSync();
    final dup = File(p.join(sub.path, 'INDEX.html'))..writeAsStringSync('y');
    expect(() => importLooseFiles([pick('index.html', 'x'), dup.path], p.join(tmp.path, 'o2')),
        throwsA(isA<ArchiveRejectedException>()));
    expect(
      () => importLooseFiles([pick('big.html', 'x' * 2000)], p.join(tmp.path, 'o3'),
          limits: const ExtractionLimits(maxFileBytes: 1000)),
      throwsA(isA<ArchiveRejectedException>()),
    );
    expect(() => importLooseFiles([], p.join(tmp.path, 'o4')), throwsA(isA<ArchiveRejectedException>()));
  });

  test('links that escape the site are never followed', () {
    final r = importLooseFiles([
      pick('index.html', '<img src="../../secret/logo.png"><img src="/abs/logo.png">'),
      pick('logo.png', 'png'),
    ], out());
    expect(r.files, contains('abs/logo.png'), reason: 'root-relative links are site paths');
    expect(r.files.where((f) => f.startsWith('..')), isEmpty);
    expect(Directory(p.join(tmp.path, 'secret')).existsSync(), isFalse);
  });

  test('failed imports leave no project behind', () async {
    final store = ProjectStore(p.join(tmp.path, 'ws'));
    await expectLater(
      store.importFiles(paths: [pick('notes.txt', 'x')], name: 'A', applicationId: 'com.example.a'),
      throwsA(isA<ArchiveRejectedException>()),
    );
    expect(store.listProjects().$1, isEmpty);
  });
}
