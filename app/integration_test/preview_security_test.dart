// On-device check that a previewed (untrusted) page cannot read local files:
// it tries file:// via XHR, an iframe and a top-level navigation, and reports
// what happened through console.log, which the preview's console shows.
//
//   flutter test integration_test/preview_security_test.dart -d emulator-5558
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/engine/on_device_engine.dart';
import 'package:html2apk_app/src/ui/preview_screen.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _probePage = r'''
<!doctype html><meta charset="utf-8"><h1>probe</h1>
<script>
function report(name, result) { console.log('PROBE ' + name + ': ' + result); }
function xhr(name, url) {
  try {
    var r = new XMLHttpRequest();
    r.open('GET', url, false);
    r.send();
    report(name, r.responseText && r.responseText.length ? 'READ' : 'blocked');
  } catch (e) { report(name, 'blocked'); }
}
xhr('xhr-system', 'file:///system/etc/hosts');
xhr('xhr-app', 'file:///data/data/com.html2apk.html2apk_app/shared_prefs/');
xhr('xhr-content', 'content://com.html2apk.html2apk_app.fileprovider/');
var f = document.createElement('iframe');
f.src = 'file:///system/etc/hosts';
f.onload = function () {
  try { report('iframe', f.contentDocument.body.innerText.length ? 'READ' : 'blocked'); }
  catch (e) { report('iframe', 'blocked'); }
};
document.body.appendChild(f);
setTimeout(function () { report('iframe-timeout', 'done'); location.href = 'file:///system/etc/hosts'; }, 2000);
// Only runs if the file:// navigation above did not replace this page.
setTimeout(function () { report('after-navigation', 'still on page'); }, 3500);
</script>
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('previewed page cannot read file:// or content://', (tester) async {
    final support = await getApplicationSupportDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final workspace = Directory(p.join(support.path, 'workspace', 'projects', '_e2e_preview_$stamp'));
    final picked = Directory(p.join(support.path, 'workspace', 'projects', '_e2e_preview_picked_$stamp'))
      ..createSync(recursive: true);
    addTearDown(() {
      if (workspace.existsSync()) workspace.deleteSync(recursive: true);
      picked.deleteSync(recursive: true);
    });
    File(p.join(picked.path, 'index.html')).writeAsStringSync(_probePage);
    final controller = AppController(workspaceDir: workspace.path, engine: OnDeviceBuildEngine());
    final report = await controller.importFiles([p.join(picked.path, 'index.html')], 'Probe', 'com.html2apk.probe');

    await tester.pumpWidget(MaterialApp(home: PreviewScreen(project: report.project)));
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.byTooltip('Console and issues'));
    await tester.pumpAndSettle();

    // The console list is lazy, so collect while scrolling through it.
    final seen = <String>{};
    void collect() => seen.addAll([
          ...tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? ''),
          ...tester.widgetList<SelectableText>(find.byType(SelectableText)).map((t) => t.data ?? ''),
        ]);
    collect();
    for (var i = 0; i < 15; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      collect();
    }
    final texts = seen.toList();
    final probes = texts
        .where((t) => t.contains('PROBE ') || t.contains('outside the app') || t.contains('file://'))
        .toList();
    if (probes.isEmpty) debugPrint('E2E preview texts: $texts');
    for (final t in probes) {
      debugPrint('E2E preview: $t');
    }
    expect(probes.where((t) => t.contains('READ')), isEmpty, reason: 'a local file was readable');
    // 'after-navigation' only logs if the file:// navigation was refused
    // (by the preview's link rules or by WebView itself).
    for (final name in ['xhr-system', 'xhr-app', 'xhr-content', 'iframe-timeout', 'after-navigation']) {
      expect(probes.any((t) => t.contains('PROBE $name:')), isTrue, reason: '$name did not run');
    }
    debugPrint('E2E preview OK');
  });
}
