import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/app_settings.dart';
import 'package:html2apk_app/src/update_check.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

String release(String tag, {bool prerelease = false, String host = 'github.com'}) => jsonEncode({
      'tag_name': tag,
      'html_url': 'https://github.com/1elevenop/iLoveHTML/releases/tag/$tag',
      'draft': false,
      'prerelease': prerelease,
      'body': 'Notes for $tag',
      'assets': [
        {'name': 'iLoveHTML-${tag.substring(1)}.apk', 'browser_download_url': 'https://$host/1elevenop/iLoveHTML/releases/download/$tag/iLoveHTML-${tag.substring(1)}.apk'},
        {'name': 'iLoveHTML-${tag.substring(1)}-windows-x64.zip', 'browser_download_url': 'https://$host/1elevenop/iLoveHTML/releases/download/$tag/iLoveHTML-${tag.substring(1)}-windows-x64.zip'},
      ],
    });

void main() {
  test('compares versions numerically', () {
    expect(isNewer('v1.2.1', '1.2.0'), isTrue);
    expect(isNewer('v1.10.0', '1.9.9'), isTrue);
    expect(isNewer('v2.0.0', '1.99.99'), isTrue);
    expect(isNewer('v1.2.0', '1.2.0'), isFalse);
    expect(isNewer('v1.1.9', '1.2.0'), isFalse);
    expect(isNewer('nightly', '1.2.0'), isFalse);
  });

  test('picks the file for this platform', () {
    final a = parseLatestRelease(release('v1.3.0'), currentVersion: '1.2.0', platform: 'android')!;
    expect(a.version, '1.3.0');
    expect(a.downloadUrl, endsWith('/iLoveHTML-1.3.0.apk'));
    final w = parseLatestRelease(release('v1.3.0'), currentVersion: '1.2.0', platform: 'windows')!;
    expect(w.downloadUrl, endsWith('-windows-x64.zip'));
    final other = parseLatestRelease(release('v1.3.0'), currentVersion: '1.2.0', platform: 'linux')!;
    expect(other.downloadUrl, other.pageUrl);
    expect(parseLatestRelease(release('v1.2.0'), currentVersion: '1.2.0', platform: 'android'), isNull);
    expect(parseLatestRelease(release('v1.3.0', prerelease: true), currentVersion: '1.2.0', platform: 'android'), isNull);
  });

  test('never links outside this project\'s releases', () {
    final r = parseLatestRelease(release('v1.3.0', host: 'evil.example'), currentVersion: '1.2.0', platform: 'android')!;
    expect(r.downloadUrl, r.pageUrl, reason: 'untrusted asset link is replaced by the release page');
    expect(isTrustedUrl('https://github.com/1elevenop/iLoveHTML/releases/download/v1/x.apk'), isTrue);
    expect(isTrustedUrl('http://github.com/1elevenop/iLoveHTML/releases/x'), isFalse);
    expect(isTrustedUrl('https://github.com/someone/else/releases/x'), isFalse);
    expect(isTrustedUrl('https://github.com.evil.example/1elevenop/iLoveHTML/releases/x'), isFalse);
  });

  test('remembers a found update and checks at most every 12 hours', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 11, 8, 9);
    var fetches = 0;
    var latest = release('v1.3.0');
    UpdateChecker make() => UpdateChecker(
          readVersion: () async => '1.2.0',
          fetchLatest: () async {
            fetches++;
            return latest;
          },
          platform: 'android',
          storage: prefs,
          clock: () => now,
        );
    final c = make();
    await c.checkIfDue();
    expect(fetches, 1);
    expect(c.available!.version, '1.3.0');

    // Next launch, an hour later: shown from storage, no new request.
    now = now.add(const Duration(hours: 1));
    final again = make();
    expect(again.available!.version, '1.3.0');
    await again.checkIfDue();
    expect(fetches, 1);

    now = now.add(const Duration(hours: 12));
    latest = release('v1.2.0');
    await again.checkIfDue();
    expect(fetches, 2);
    expect(again.available, isNull);
    expect(again.state, UpdateCheckState.upToDate);
  });

  test('network errors are quiet', () async {
    final c = UpdateChecker(
      readVersion: () async => '1.2.0',
      fetchLatest: () async => throw const SocketException('offline'),
      platform: 'android',
    );
    await c.checkNow();
    expect(c.state, UpdateCheckState.failed);
    expect(c.available, isNull);
  });

  group('screens', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('update_ui'));
    tearDown(() => tmp.deleteSync(recursive: true));

    testWidgets('a new release lights up Settings with NEW UPDATE and a download', (tester) async {
      final updates = UpdateChecker(
        readVersion: () async => '1.2.0',
        fetchLatest: () async => release('v1.3.0'),
        platform: 'android',
      );
      await tester.runAsync(updates.checkNow);
      final controller = AppController(
        workspaceDir: p.join(tmp.path, 'ws'),
        settings: AppSettings.memory(animate: false),
        updates: updates,
      );
      await tester.pumpWidget(Html2ApkApp(controller: controller));
      await tester.pump();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('NEW UPDATE'), findsOneWidget);
      expect(find.text('iLoveHTML 1.3.0 is available'), findsWidgets);
      await tester.tap(find.text('NEW UPDATE'));
      await tester.pumpAndSettle();
      expect(find.text('Update to 1.3.0'), findsOneWidget);
      expect(find.text('You have 1.2.0.'), findsOneWidget);
      expect(find.text('Notes for v1.3.0'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('no tile when up to date', (tester) async {
      final updates = UpdateChecker(
        readVersion: () async => '1.2.0',
        fetchLatest: () async => release('v1.2.0'),
        platform: 'android',
      );
      await tester.runAsync(updates.checkNow);
      final controller = AppController(
        workspaceDir: p.join(tmp.path, 'ws'),
        settings: AppSettings.memory(animate: false),
        updates: updates,
      );
      await tester.pumpWidget(Html2ApkApp(controller: controller));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('NEW UPDATE'), findsNothing);
    });
  });
}
