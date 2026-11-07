// Drives the real Windows app: project list → project → preview (browser,
// served locally) → debug APK, release APK and App Bundle with Gradle.
//
//   flutter test integration_test/windows_ui_test.dart -d windows
//
// Native file dialogs cannot be driven, so files are imported through the
// same controller call the dialog uses. Uses its own workspace and key.
@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/engine/desktop_engine.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows: import, preview, build debug, release APK and AAB', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('h2a_win_ui_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final workspace = p.join(tmp.path, 'workspace');
    final engine = DesktopBuildEngine(
      workspaceDir: workspace,
      toolchainReport: discoverToolchain(),
      templateDir: p.join(p.dirname(Platform.resolvedExecutable), 'android_template'),
    );
    expect(engine.problems, isEmpty, reason: 'toolchain/template must be found next to the exe');
    final controller = AppController(workspaceDir: workspace, engine: engine);

    final site = Directory(p.join(tmp.path, 'picked'))..createSync();
    File(p.join(site.path, 'index.html')).writeAsStringSync(
        '<link rel="stylesheet" href="css/s.css"><h1>Windows UI</h1><script src="js/a.js"></script>');
    File(p.join(site.path, 's.css')).writeAsStringSync('h1{color:red}');
    File(p.join(site.path, 'a.js')).writeAsStringSync('console.log("html2apk demo loaded")');
    await controller.importFiles([for (final f in ['index.html', 's.css', 'a.js']) p.join(site.path, f)],
        'Windows UI', 'com.html2apk.windowsui');

    await tester.pumpWidget(Html2ApkApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Windows UI'), findsOneWidget);
    await tester.tap(find.text('Windows UI'));
    await tester.pumpAndSettle();

    // Preview: dialog with a loopback URL that serves the page; stops on close.
    await tester.tap(find.byTooltip('Preview'));
    await tester.pumpAndSettle();
    final urlText = tester.widget<SelectableText>(find.descendant(
        of: find.byType(AlertDialog), matching: find.byWidgetPredicate((w) => w is SelectableText)));
    final url = Uri.parse(urlText.data!);
    expect(url.host, '127.0.0.1');
    final client = HttpClient();
    final res = await (await client.getUrl(url)).close();
    expect(res.statusCode, 200);
    expect(await res.transform(const SystemEncoding().decoder).join(), contains('Windows UI'));
    await tester.tap(find.text('Stop preview'));
    await tester.pumpAndSettle();
    await expectLater(() async => (await client.getUrl(url)).close(), throwsA(isA<SocketException>()));
    client.close(force: true);
    debugPrint('E2E windows: preview OK ($url)');

    Future<void> waitForBuild() async {
      final sw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 300));
      while (controller.building.isNotEmpty && sw.elapsed < const Duration(minutes: 8)) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      final last = controller.store.buildHistory(controller.projects.single).firstOrNull;
      debugPrint('E2E windows: ${last?.variant} ${last?.format} ${last?.status} ${last?.message ?? ''}');
    }

    // The Build tab is a lazy list: result and error cards sit below the .exe and
    // .msix cards and are not built until scrolled to. Its list is the nearest
    // Scrollable above the Debug/Release switch (the build log has its own).
    // Pinned while the top of the tab is on screen, since scrolling disposes the switch.
    Finder buildTab() {
      final list = find.ancestor(of: find.text('Debug').first, matching: find.byType(Scrollable)).first.evaluate().first;
      return find.byElementPredicate((e) => identical(e, list));
    }

    // Scrolls [target] into view, runs [check], then returns to the top of the tab.
    Future<void> belowTheFold(Finder target, void Function() check) async {
      final tab = buildTab();
      await tester.scrollUntilVisible(target, 200, scrollable: tab);
      check();
      tester.state<ScrollableState>(tab).position.jumpTo(0);
      await tester.pumpAndSettle();
    }

    // Debug APK.
    await tester.tap(find.text('Build'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build debug APK'));
    await waitForBuild();
    expect(find.text('Build failed'), findsNothing);
    await belowTheFold(find.text('Save as…'), () {
      expect(find.text('Save as…'), findsOneWidget);
      expect(find.text('Show in folder'), findsOneWidget);
      expect(find.text('Install on phone'), findsOneWidget);
    });
    final project = controller.projects.single;
    expect(File(project.debugApkPath).existsSync(), isTrue);
    debugPrint('E2E windows: debug ${File(project.debugApkPath).lengthSync()} bytes');

    // Release key created through the Release keys screen's API, then picked in the Build tab.
    final key = await engine.createKey(alias: 'upload', commonName: 'Windows UI Test', password: 'win-ui-pw-1');
    await tester.tap(find.text('Release'));
    await tester.pumpAndSettle();
    // The tab loads keys when it opens; reopen the project so it sees the new key.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Windows UI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Release'));
    await tester.pumpAndSettle();
    expect(find.textContaining(key.shortSha256), findsOneWidget);
    await tester.tap(find.text('Build release APK'));
    await waitForBuild();
    expect(find.text('Build failed'), findsNothing);
    final released = controller.projects.single;
    expect(File(released.releaseApkPath).existsSync(), isTrue);
    expect(released.manifest.releaseCertSha256?.toUpperCase(), key.sha256.toUpperCase());

    await tester.tap(find.text('App Bundle (Play)'));
    await tester.pumpAndSettle();
    // Same version code as the release just built: refused before building.
    await tester.tap(find.text('Build App Bundle'));
    await tester.pumpAndSettle();
    await belowTheFold(find.text('Build failed'), () => expect(find.text('Build failed'), findsOneWidget));
    debugPrint('E2E windows: same version refused');
    final m = controller.projects.single.manifest;
    controller.update(controller.projects.single,
        m.copyWith(android: m.android.copyWith(versionCode: m.android.versionCode + 1, versionName: '1.0.1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build App Bundle'));
    await waitForBuild();
    expect(find.text('Build failed'), findsNothing);
    // The file name carries the new version.
    final aab = controller.projects.single.releaseAabPath;
    expect(File(aab).existsSync(), isTrue, reason: aab);
    debugPrint('E2E windows: release ${File(released.releaseApkPath).lengthSync()} bytes, '
        'aab ${p.basename(aab)} ${File(aab).lengthSync()} bytes');

    // Windows .exe from the same project, then run it.
    await tester.scrollUntilVisible(find.text('Build .exe'), 200, scrollable: buildTab());
    await tester.tap(find.text('Build .exe'));
    await waitForBuild();
    expect(find.text('Build failed'), findsNothing);
    final exe = controller.projects.single.windowsExePath();
    expect(File(exe).existsSync(), isTrue, reason: exe);
    expect(find.text(p.basename(exe)), findsOneWidget);
    final runLog = File(p.join(tmp.path, 'exe.log'));
    final proc = await Process.start(exe, [], environment: {'HTML2APK_CONSOLE_LOG': runLog.path});
    final sw = Stopwatch()..start();
    var lines = <String>[];
    while (sw.elapsed < const Duration(seconds: 30) && !lines.any((l) => l.contains('html2apk demo loaded'))) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      lines = runLog.existsSync() ? runLog.readAsLinesSync() : [];
    }
    proc.kill();
    await proc.exitCode;
    expect(lines.any((l) => l.contains('html2apk demo loaded')), isTrue, reason: lines.join('\n'));
    debugPrint('E2E windows: exe ${File(exe).lengthSync()} bytes, page JS ran');
    debugPrint('E2E windows OK');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
