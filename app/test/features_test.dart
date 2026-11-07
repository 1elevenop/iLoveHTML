import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/app_settings.dart';
import 'package:html2apk_app/src/ui/about_screens.dart';
import 'package:html2apk_app/src/ui/ascii.dart';
import 'package:html2apk_app/src/ui/theme.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('html2apk_features_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  AppController controllerWith(AppSettings settings) =>
      AppController(workspaceDir: p.join(tmp.path, 'ws'), settings: settings);

  test('settings are saved and loaded again', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await AppSettings.load();
    expect(first.themeMode, ThemeMode.dark);
    expect(first.locale, isNull);
    first
      ..locale = const Locale('ja')
      ..themeMode = ThemeMode.light
      ..accent = AccentPreset.green
      ..animations = false;
    final second = await AppSettings.load();
    expect(second.locale, const Locale('ja'));
    expect(second.themeMode, ThemeMode.light);
    expect(second.accent, AccentPreset.green);
    expect(second.animations, isFalse);
    second.locale = null;
    expect((await AppSettings.load()).locale, isNull);
  });

  test('unknown saved values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({'locale': 'xx', 'themeMode': 'bogus', 'accent': 'nope'});
    final s = await AppSettings.load();
    expect(s.locale, isNull);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.accent, AccentPreset.orange);
  });

  testWidgets('the UI follows the chosen language', (tester) async {
    final settings = AppSettings.memory(language: const Locale('es'), animate: false);
    await tester.pumpWidget(Html2ApkApp(controller: controllerWith(settings)));
    await tester.pumpAndSettle();
    expect(find.text('Proyectos'), findsOneWidget);
    settings.locale = const Locale('ja');
    await tester.pumpAndSettle();
    expect(find.text('プロジェクト'), findsOneWidget);
    settings.locale = const Locale('en');
    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsOneWidget);
  });

  testWidgets('light and dark mode change the background', (tester) async {
    final settings = AppSettings.memory(animate: false);
    await tester.pumpWidget(Html2ApkApp(controller: controllerWith(settings)));
    await tester.pumpAndSettle();
    Color bg() => tester.widget<Material>(find.descendant(of: find.byType(Scaffold), matching: find.byType(Material)).first).color!;
    expect(bg(), const Color(0xFF000000));
    settings.themeMode = ThemeMode.light;
    await tester.pumpAndSettle();
    expect(bg(), ElevenPalette.of(Brightness.light, AccentPreset.orange).bg);
  });

  testWidgets('accent presets recolour the primary colour', (tester) async {
    final settings = AppSettings.memory(animate: false);
    late ThemeData theme;
    await tester.pumpWidget(Html2ApkApp(controller: controllerWith(settings)));
    theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.colorScheme.primary, AccentPreset.orange.dark);
    settings.accent = AccentPreset.violet;
    await tester.pumpAndSettle();
    theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.colorScheme.primary, AccentPreset.violet.dark);
  });

  testWidgets('splash is skipped when animations are off', (tester) async {
    final settings = AppSettings.memory(animate: false);
    await tester.pumpWidget(Html2ApkApp(controller: controllerWith(settings), showSplash: true));
    await tester.pump();
    expect(find.text('Projects'), findsOneWidget);
  });

  testWidgets('splash types the logo, then shows the projects', (tester) async {
    final settings = AppSettings.memory();
    await tester.pumpWidget(Html2ApkApp(controller: controllerWith(settings), showSplash: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Projects'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Projects'), findsOneWidget);
  });

  testWidgets('build progress draws an ASCII bar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(body: AsciiBuildProgress(label: 'Building…', animate: false)),
    ));
    expect(find.textContaining('['), findsOneWidget);
    expect(find.textContaining('Building…'), findsOneWidget);
  });

  testWidgets('settings has About with version, guide, legal pages and credit', (tester) async {
    final settings = AppSettings.memory(animate: false);
    await tester.pumpWidget(Html2ApkApp(controller: controllerWith(settings)));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Buy me a coffee'), 200);
    expect(find.text('How to use'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Made with <3 by 1elevenop'), findsOneWidget);
    expect(buyMeACoffeeUrl, 'https://buymeacoffee.com/1elevenop');

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no analytics'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('How to use'), -200);
    await tester.tap(find.text('How to use'));
    await tester.pumpAndSettle();
    expect(find.text('Create a project'), findsOneWidget);
  });
}
