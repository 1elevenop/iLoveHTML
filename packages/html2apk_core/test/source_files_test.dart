import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late ProjectStore store;
  late ProjectHandle project;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('src_files');
    store = ProjectStore(p.join(tmp.path, 'projects'));
    project = (await store.createBlank(name: 'My <App>', applicationId: 'com.example.blank')).project;
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Matcher refused([String? text]) =>
      throwsA(isA<SourceFileException>().having((e) => e.message, 'message', text == null ? anything : contains(text)));

  test('a blank project has a starter page, stylesheet and script', () {
    expect(project.manifest.source.entry, 'index.html');
    expect(store.listSourceFiles(project), ['index.html', 'script.js', 'style.css']);
    final html = store.readSourceFile(project, 'index.html');
    expect(html, contains('<title>My &lt;App&gt;</title>'));
    expect(html, contains('href="style.css"'));
  });

  test('write, create, rename and delete', () {
    store.writeSourceFile(project, 'style.css', 'body{color:red}');
    expect(store.readSourceFile(project, 'style.css'), 'body{color:red}');
    store.createSourceFile(project, 'pages/about.html', '<p>About</p>');
    expect(store.listSourceFiles(project), contains('pages/about.html'));
    store.renameSourceFile(project, 'pages/about.html', 'about.html');
    expect(store.readSourceFile(project, 'about.html'), '<p>About</p>');
    store.deleteSourceFile(project, 'about.html');
    expect(store.listSourceFiles(project), isNot(contains('about.html')));
    // No temporary files left behind by the atomic writes.
    expect(listRelativeFiles(project.sourceDir).where((f) => f.endsWith('.tmp')), isEmpty);
  });

  test('create refuses to overwrite', () {
    expect(() => store.createSourceFile(project, 'style.css'), refused('already exists'));
    expect(() => store.renameSourceFile(project, 'script.js', 'style.css'), refused('already exists'));
  });

  test('paths cannot leave the site folder', () {
    for (final bad in [
      '../project.json',
      '../../x.html',
      '/etc/passwd.txt',
      r'C:\Windows\x.html',
      'a/../../b.html',
      'con.html',
      '',
    ]) {
      expect(() => store.readSourceFile(project, bad), refused(), reason: bad);
      expect(() => store.createSourceFile(project, bad), refused(), reason: bad);
    }
    expect(File(p.join(project.directory, 'project.json')).existsSync(), isTrue);
  });

  test('only text file types', () {
    for (final bad in ['logo.png', 'app.exe', 'notes', 'x.html.bak']) {
      expect(() => store.createSourceFile(project, bad), refused('can be edited'), reason: bad);
    }
    File(p.join(project.sourceDir, 'logo.png')).writeAsBytesSync([137, 80, 78, 71]);
    expect(store.listSourceFiles(project), isNot(contains('logo.png')));
  });

  test('files over 2 MB are refused', () {
    final big = 'x' * (maxEditableBytes + 1);
    expect(() => store.writeSourceFile(project, 'style.css', big), refused('2 MB'));
    File(p.join(project.sourceDir, 'big.txt')).writeAsStringSync(big);
    expect(() => store.readSourceFile(project, 'big.txt'), refused('2 MB'));
  });

  test('binary data is not opened as text', () {
    File(p.join(project.sourceDir, 'data.json')).writeAsBytesSync([0xff, 0xfe, 0x00, 0x81]);
    expect(() => store.readSourceFile(project, 'data.json'), refused('UTF-8'));
  });

  test('links are never followed', () {
    final outside = Directory(p.join(tmp.path, 'outside'))..createSync();
    File(p.join(outside.path, 'secret.txt')).writeAsStringSync('secret');
    try {
      Link(p.join(project.sourceDir, 'linked')).createSync(outside.path);
    } on FileSystemException {
      markTestSkipped('this machine does not allow creating links');
      return;
    }
    expect(() => store.readSourceFile(project, 'linked/secret.txt'), refused('Links'));
    expect(() => store.createSourceFile(project, 'linked/new.txt'), refused('Links'));
    expect(File(p.join(outside.path, 'new.txt')).existsSync(), isFalse);
  });

  test('the start page cannot be deleted or renamed', () {
    expect(() => store.deleteSourceFile(project, 'index.html'), refused('start page'));
    expect(() => store.deleteSourceFile(project, 'INDEX.HTML'), refused('start page'));
    expect(() => store.renameSourceFile(project, 'index.html', 'home.html'), refused('start page'));
    expect(File(p.join(project.sourceDir, 'index.html')).existsSync(), isTrue);
  });

  test('URL projects have no files to edit', () async {
    final url = store.createFromUrl(url: 'https://example.com/', name: 'Live', applicationId: 'com.example.live');
    expect(() => store.listSourceFiles(url), refused('website files'));
  });
}
