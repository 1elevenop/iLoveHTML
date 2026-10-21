import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('html2apk_app_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('shows the empty state without projects', (tester) async {
    final controller = AppController(workspaceDir: p.join(tmp.path, 'ws'));
    await tester.pumpWidget(Html2ApkApp(controller: controller));
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('Import ZIP'), findsOneWidget);
  });

  testWidgets('lists imported projects and opens settings and build tabs', (tester) async {
    final controller = AppController(workspaceDir: p.join(tmp.path, 'ws'));
    final zip = File(p.join(tmp.path, 'site.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(Archive()
        ..add(ArchiveFile.bytes('index.html', utf8.encode('<h1>Hi</h1>')))
        ..add(ArchiveFile.bytes('about.html', utf8.encode('<p>About</p>')))));
    await tester.runAsync(() => controller.importZip(zip.path, 'Shop App', 'com.example.shop'));

    await tester.pumpWidget(Html2ApkApp(controller: controller));
    expect(find.text('Shop App'), findsOneWidget);
    expect(find.text('com.example.shop'), findsOneWidget);
    expect(find.textContaining('not built yet'), findsOneWidget);

    await tester.tap(find.text('Shop App'));
    await tester.pumpAndSettle();
    expect(find.text('Start page'), findsOneWidget);
    expect(find.text('index.html'), findsOneWidget);

    await tester.tap(find.text('Build'));
    await tester.pumpAndSettle();
    // No engine is wired in tests (as on desktop for now): the button is disabled with an explanation.
    expect(find.text('Building is not available on this platform yet.'), findsOneWidget);
  });

  test('suggests valid application IDs', () {
    expect(suggestApplicationId('My Shop!'), 'com.example.myshop');
    expect(suggestApplicationId('123'), 'com.example.app123');
    expect(suggestApplicationId(''), 'com.example.app');
  });
}
