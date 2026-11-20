import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/app_settings.dart';
import 'package:html2apk_app/src/ui/editor/code_pane.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('editor'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('edits a file: unsaved mark, save writes to disk', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller =
        AppController(workspaceDir: p.join(tmp.path, 'ws'), settings: AppSettings.memory(animate: false));
    final report = await tester.runAsync(() => controller.createBlank('Blank Site', 'com.example.blank'));
    final css = File(p.join(report!.project.sourceDir, 'style.css'));

    await tester.pumpWidget(Html2ApkApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blank Site'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit code'));
    await tester.pumpAndSettle();

    // The start page opens; all starter files are listed on a wide screen.
    expect(find.text('index.html'), findsWidgets);
    expect(find.text('style.css'), findsOneWidget);
    expect(find.text('script.js'), findsOneWidget);

    await tester.tap(find.text('style.css'));
    await tester.pumpAndSettle();
    final pane = tester.widget<CodePane>(find.byType(CodePane));
    expect(pane.path, 'style.css');
    expect(find.bySemanticsLabel(RegExp(r'style\.css, unsaved')), findsNothing);

    pane.controller.text = 'body { color: red; }';
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'style\.css, unsaved')), findsOneWidget);
    expect(css.readAsStringSync(), isNot(contains('red')));

    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(css.readAsStringSync(), 'body { color: red; }');
    expect(find.bySemanticsLabel(RegExp(r'style\.css, unsaved')), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller =
        AppController(workspaceDir: p.join(tmp.path, 'ws'), settings: AppSettings.memory(animate: false));
    final report = await tester.runAsync(() => controller.createBlank('Blank Site', 'com.example.blank'));
    final html = File(p.join(report!.project.sourceDir, 'index.html')).readAsStringSync();

    await tester.pumpWidget(Html2ApkApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blank Site'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit code'));
    await tester.pumpAndSettle();

    tester.widget<CodePane>(find.byType(CodePane)).controller.text = '<p>changed</p>';
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(CodePane), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(CodePane), findsNothing);
    expect(File(p.join(report.project.sourceDir, 'index.html')).readAsStringSync(), html);
  });
}
