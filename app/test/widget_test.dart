import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/l10n/gen/app_localizations.dart';
import 'package:html2apk_app/src/ui/theme.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/ui/url_import_dialog.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('html2apk_app_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('shows the empty state without projects', (tester) async {
    final controller = AppController(workspaceDir: p.join(tmp.path, 'ws'));
    await tester.pumpWidget(Html2ApkApp(controller: controller));
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('New app'), findsOneWidget);
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

  test('normalizes URL input', () {
    expect(normalizeUrlInput(' example.com '), 'https://example.com');
    expect(normalizeUrlInput('https://a.example/x'), 'https://a.example/x');
  });

  testWidgets('URL dialog checks the site and creates a URL project', (tester) async {
    final controller = AppController(workspaceDir: p.join(tmp.path, 'ws'));
    String? created;
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => created = await showDialog<String>(
              context: context, builder: (_) => UrlImportDialog(controller: controller, probe: _FakeProbe())),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'shop.example');
    await tester.tap(find.text('Check website'));
    await tester.pumpAndSettle();
    expect(find.text('Website reachable'), findsOneWidget);
    expect(find.text('https://www.shop.example/'), findsOneWidget);
    expect(find.textContaining('Redirected 1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Example Shop'), findsOneWidget);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    final project = controller.project(created!)!;
    expect(project.manifest.source.entry, 'https://www.shop.example/');
    expect(project.manifest.android.applicationId, 'com.example.exampleshop');
  });

  testWidgets('URL dialog shows check failures', (tester) async {
    final controller = AppController(workspaceDir: p.join(tmp.path, 'ws'));
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: UrlImportDialog(controller: controller, probe: _FakeProbe()))));
    await tester.enterText(find.byType(TextField).first, 'https://down.example');
    await tester.tap(find.text('Check website'));
    await tester.pumpAndSettle();
    expect(find.text('Could not connect: refused'), findsOneWidget);
    expect(find.text('Create'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'http://insecure.example');
    await tester.tap(find.text('Check website'));
    await tester.pumpAndSettle();
    expect(find.text('Only https:// URLs are supported'), findsOneWidget);
  });
}

class _FakeProbe extends UrlProbe {
  @override
  Future<UrlProbeResult> probe(String input) async {
    if (input.contains('down')) throw UrlProbeException('Could not connect: refused');
    return UrlProbeResult(
      finalUrl: Uri.parse('https://www.shop.example/'),
      redirects: [Uri.parse(input)],
      statusCode: 200,
      title: 'Example Shop',
    );
  }
}
