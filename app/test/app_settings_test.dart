@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/ui/app_settings_screen.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('html2apk_settings_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('storage total counts files past 260 characters (Gradle build folders)', (tester) async {
    final ws = p.join(tmp.path, 'workspace');
    // Like workspace\builds\<id>\android\app\build\intermediates\..., which
    // passes MAX_PATH; only a \\?\ path can create it.
    final deep = p.joinAll([ws, 'builds', 'id', 'android', for (final c in 'abcd'.split('')) c * 60]);
    expect(deep.length, greaterThan(260));
    Directory('\\\\?\\$deep').createSync(recursive: true);
    File('\\\\?\\${p.join(deep, 'classes.jar')}').writeAsBytesSync(List.filled(1234, 0));
    File(p.join(ws, 'top.txt')).writeAsBytesSync(List.filled(10, 0));

    final controller = AppController(workspaceDir: ws);
    expect(controller.storageBytes(), 1244);
    await tester.pumpWidget(MaterialApp(home: AppSettingsScreen(controller: controller)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('0 projects · 1.2 KB'), findsOneWidget);
  });

  test('storage total of a missing workspace is zero', () {
    expect(AppController(workspaceDir: p.join(tmp.path, 'none')).storageBytes(), 0);
  });
}
