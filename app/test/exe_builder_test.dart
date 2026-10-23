@TestOn('windows')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/engine/exe_builder.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

// Builds real .exe files from the prebuilt wrapper and runs them. Needs
// tools/build_windows_wrapper.ps1 to have been run and WebView2 installed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final wrapper = p.normalize(p.join(Directory.current.path, '..', 'windows_template', 'dist', 'html2apk_wrapper.exe'));
  final skip = File(wrapper).existsSync() ? false : 'Wrapper not built';
  late Directory tmp;
  late ProjectStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('h2a_exe_');
    store = ProjectStore(p.join(tmp.path, 'projects'));
  });
  tearDown(() {
    for (var i = 0; i < 20; i++) {
      try {
        tmp.deleteSync(recursive: true);
        return;
      } on FileSystemException {
        sleep(const Duration(milliseconds: 250)); // the app may still hold its files
      }
    }
  });

  /// Runs [exe] until [done] appears in its log (or 30 s), then closes it.
  Future<List<String>> run(String exe, bool Function(List<String>) done) async {
    final log = File(p.join(tmp.path, 'run-${DateTime.now().microsecondsSinceEpoch}.log'));
    final env = {'HTML2APK_CONSOLE_LOG': log.path};
    final proc = await Process.start(exe, [], environment: env);
    var lines = <String>[];
    final sw = Stopwatch()..start();
    while (sw.elapsed < const Duration(seconds: 30)) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      lines = log.existsSync() ? log.readAsLinesSync() : [];
      if (done(lines)) break;
    }
    proc.kill();
    await proc.exitCode;
    return lines;
  }

  Future<Uint8List> pngIcon(WidgetTester tester) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 512, 512), ui.Paint()..color = const ui.Color(0xFF1A73E8));
    final image = await recorder.endRecording().toImage(512, 512);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  testWidgets('local site: page and JS run from the exe, local files stay unreachable', (tester) async {
    await tester.runAsync(() async {
      final site = Directory(p.join(tmp.path, 'site'))..createSync();
      File(p.join(site.path, 'index.html')).writeAsStringSync('''
<!doctype html><meta charset="utf-8"><link rel="stylesheet" href="css/s.css"><h1>Exe ✓</h1>
<script src="js/app.js"></script>''');
      File(p.join(site.path, 's.css')).writeAsStringSync('h1{color:red}');
      File(p.join(site.path, 'app.js')).writeAsStringSync(r'''
console.log('html2apk demo loaded');
function report(n, r) { console.log('PROBE ' + n + ': ' + r); }
try { var x = new XMLHttpRequest(); x.open('GET', 'file:///C:/Windows/win.ini', false); x.send();
  report('xhr-file', x.responseText.length ? 'READ' : 'blocked'); } catch (e) { report('xhr-file', 'blocked'); }
fetch('css/s.css').then(function (r) { return r.text(); }).then(function (t) { report('own-css', t.indexOf('red') > 0 ? 'ok' : 'bad'); });
fetch('nope.png').then(function (r) { report('missing', r.status); });
var f = document.createElement('iframe'); f.src = 'file:///C:/Windows/win.ini'; document.body.appendChild(f);
setTimeout(function () { location.href = 'file:///C:/Windows/win.ini'; }, 1000);
setTimeout(function () { report('after-navigation', 'still on page'); }, 2500);
''');
      final report = await store.importFiles(
          paths: [for (final f in ['index.html', 's.css', 'app.js']) p.join(site.path, f)],
          name: 'Exe Test',
          applicationId: 'com.html2apk.exetest');
      var project = report.project;
      final iconPng = p.join(tmp.path, 'icon.png');
      File(iconPng).writeAsBytesSync(await pngIcon(tester));
      project = store.setIcon(project, iconPng);

      final log = <String>[];
      final out = project.windowsExePath();
      final result = await ExeBuilder(wrapper).build(project, outputPath: out, log: log.add);
      expect(result.status, BuildStatus.succeeded, reason: log.join('\n'));
      expect(log.join('\n'), isNot(contains('No app icon')));
      expect(iconEntries(out), 4, reason: 'Windows should find the icon group with 4 sizes');

      final lines = await run(out, (l) => l.any((x) => x.contains('after-navigation')));
      String probe(String name) =>
          lines.firstWhere((l) => l.contains('PROBE $name:'), orElse: () => '').split('PROBE $name: ').last;
      for (final l in lines) {
        debugPrint('EXE: ${l.length > 160 ? l.substring(0, 160) : l}');
      }
      expect(lines.any((l) => l.startsWith('LOADED https://app.html2apk.invalid/index.html')), isTrue);
      expect(lines.any((l) => l.contains('html2apk demo loaded')), isTrue);
      expect(probe('own-css'), startsWith('ok'));
      expect(probe('missing'), startsWith('404'));
      expect(probe('xhr-file'), startsWith('blocked'));
      // WebView2 refuses file:// frames and navigations from an https page
      // before the wrapper's own checks run; the page must simply stay.
      expect(probe('after-navigation'), startsWith('still on page'));
      expect(lines.where((l) => l.startsWith('LOADED file:')), isEmpty);
      expect(lines.where((l) => l.contains('READ')), isEmpty);
    });
  }, skip: skip != false);

  testWidgets('URL app shows the offline page when the site is unreachable', (tester) async {
    await tester.runAsync(() async {
      final project = store.createFromUrl(
          url: 'https://unreachable.html2apk.invalid/', name: 'Offline Test', applicationId: 'com.html2apk.offlinetest');
      final out = project.windowsExePath(debug: true);
      final result = await ExeBuilder(wrapper).build(project, outputPath: out, log: (_) {}, debug: true);
      expect(result.status, BuildStatus.succeeded, reason: result.message);
      final lines = await run(out, (l) => l.any((x) => x.contains('__html2apk/error.html')));
      expect(lines.any((l) => l.startsWith('FAILED https://unreachable.html2apk.invalid/')), isTrue, reason: '$lines');
      expect(lines.any((l) => l == 'LOADED https://app.html2apk.invalid/__html2apk/error.html'), isTrue,
          reason: '$lines');
    });
  }, skip: skip != false);

  testWidgets('URL app shows its own offline page, once', (tester) async {
    await tester.runAsync(() async {
      var project = store.createFromUrl(
          url: 'https://unreachable.html2apk.invalid/', name: 'Offline Test', applicationId: 'com.html2apk.offlinetest');
      final page = File(p.join(tmp.path, 'mine.html'))
        ..writeAsStringSync('<!doctype html><h1>Mine</h1><script>console.log("own offline page")</script>');
      project = store.setOfflinePage(project, page.path);
      final out = project.windowsExePath(debug: true);
      final result = await ExeBuilder(wrapper).build(project, outputPath: out, log: (_) {}, debug: true);
      expect(result.status, BuildStatus.succeeded, reason: result.message);
      const url = 'https://app.html2apk.invalid/offline.html';
      final lines = await run(out, (l) => l.contains('LOADED $url'));
      expect(lines.where((l) => l == 'LOADED $url'), hasLength(1), reason: '$lines');
      expect(lines.any((l) => l.contains('own offline page')), isTrue, reason: '$lines');
      expect(lines.where((l) => l == 'FAILED $url'), isEmpty, reason: '$lines');
    });
  }, skip: skip != false);

  testWidgets('a bundled error page that fails falls back to the built-in one, once', (tester) async {
    await tester.runAsync(() async {
      // The builder refuses this; write the resources directly to test the wrapper's own guard.
      final project = store.createFromUrl(
          url: 'https://unreachable.html2apk.invalid/', name: 'Offline Test', applicationId: 'com.html2apk.offlinetest');
      final m = project.manifest.copyWith(offlineFallbackPage: () => 'missing.html');
      final out = p.join(tmp.path, 'guard.exe');
      File(wrapper).copySync(out);
      ExeBuilder(wrapper).writeResources(out, config: ExeBuilder.exeConfig(m, debug: true), files: const {}, icon: null);
      final lines = await run(out, (l) => l.any((x) => x.contains('__html2apk/error.html')));
      expect(lines.where((l) => l == 'FAILED https://app.html2apk.invalid/missing.html'), hasLength(1), reason: '$lines');
      expect(lines.any((l) => l == 'LOADED https://app.html2apk.invalid/__html2apk/error.html'), isTrue, reason: '$lines');
    });
  }, skip: skip != false);

  test('builder refuses an offline page that is not in the project', () async {
    final project = store.createFromUrl(url: 'https://example.com/', name: 'X', applicationId: 'com.example.gone');
    final gone = project.withManifest(project.manifest.copyWith(offlineFallbackPage: () => 'gone.html'));
    final result = await ExeBuilder(wrapper).build(gone, outputPath: p.join(tmp.path, 'gone.exe'), log: (_) {});
    expect(result.status, BuildStatus.failed);
    expect(result.message, contains('Offline page "gone.html" is missing'));
  }, skip: skip != false);

  test('config lines cannot be broken by tabs or newlines in values', () {
    final project = store.createFromUrl(url: 'https://example.com/', name: 'X', applicationId: 'com.example.evil');
    final m = project.manifest.copyWith(name: 'Evil\tName\nentry\thttps://x');
    final lines = ExeBuilder.exeConfig(m, debug: false).trim().split('\n');
    expect(lines.where((l) => l.startsWith('entry\t')), hasLength(1));
    expect(lines.firstWhere((l) => l.startsWith('name\t')), 'name\tEvil Name entry https://x');
  });
}


/// Number of images in icon group 1 of [exe], read the way Explorer does.
int iconEntries(String exe) => using((arena) {
      final k32 = DynamicLibrary.open('kernel32.dll');
      final load = k32.lookupFunction<Pointer<Void> Function(Pointer<Utf16>, Pointer<Void>, Uint32),
          Pointer<Void> Function(Pointer<Utf16>, Pointer<Void>, int)>('LoadLibraryExW');
      final find = k32.lookupFunction<Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>, Pointer<Utf16>),
          Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>, Pointer<Utf16>)>('FindResourceW');
      final res = k32.lookupFunction<Pointer<Void> Function(Pointer<Void>, Pointer<Void>),
          Pointer<Void> Function(Pointer<Void>, Pointer<Void>)>('LoadResource');
      final lock = k32.lookupFunction<Pointer<Uint8> Function(Pointer<Void>), Pointer<Uint8> Function(Pointer<Void>)>(
          'LockResource');
      final free = k32.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('FreeLibrary');
      const loadAsImageResource = 0x20 | 0x2; // LOAD_LIBRARY_AS_IMAGE_RESOURCE | AS_DATAFILE
      final module = load(exe.toNativeUtf16(allocator: arena), nullptr, loadAsImageResource);
      if (module == nullptr) return -1;
      try {
        final r = find(module, Pointer.fromAddress(1), Pointer.fromAddress(14));
        if (r == nullptr) return 0;
        final data = lock(res(module, r));
        return data[4] | (data[5] << 8); // GRPICONDIR.idCount
      } finally {
        free(module);
      }
    });