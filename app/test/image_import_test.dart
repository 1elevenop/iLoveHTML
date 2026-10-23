import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/image_import.dart';
import 'package:html2apk_core/html2apk_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> png(int w, int h) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFFFF7A1A));
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  (int, int) size(Uint8List b) {
    final info = readPngInfo(b)!;
    return (info.width, info.height);
  }

  // A 2x1 BMP (24-bit), the smallest non-PNG format the engine decodes.
  final bmp = Uint8List.fromList([
    0x42, 0x4D, 0x3E, 0, 0, 0, 0, 0, 0, 0, 0x36, 0, 0, 0, 0x28, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 24, 0, //
    0, 0, 0, 0, 8, 0, 0, 0, 0x13, 0x0B, 0, 0, 0x13, 0x0B, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0x1A, 0x7A, 0xFF, 0x1A, 0x7A, 0xFF, 0, 0,
  ]);

  testWidgets('a square PNG within limits is kept byte for byte', (tester) async {
    await tester.runAsync(() async {
      final b = await png(64, 64);
      expect(identical(await toPng(b, isSvg: false, square: true), b), isTrue);
    });
  });

  testWidgets('a wide PNG icon is centred on a transparent square', (tester) async {
    await tester.runAsync(() async {
      expect(size(await toPng(await png(200, 100), isSvg: false, square: true)), (200, 200));
      expect(size(await toPng(await png(200, 100), isSvg: false)), (200, 100), reason: 'splash keeps its shape');
    });
  });

  testWidgets('large images are scaled down to maxSide', (tester) async {
    await tester.runAsync(() async {
      expect(size(await toPng(await png(2048, 1024), isSvg: false, square: true, maxSide: 1024)), (1024, 1024));
    });
  });

  testWidgets('other raster formats become PNG', (tester) async {
    await tester.runAsync(() async {
      final out = await toPng(bmp, isSvg: false);
      expect(size(out), (2, 1));
    });
  });

  testWidgets('SVG is drawn at svgSize, square for icons', (tester) async {
    await tester.runAsync(() async {
      final svg = Uint8List.fromList(utf8.encode(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10"><rect width="20" height="10" fill="#FF7A1A"/></svg>'));
      expect(size(await toPng(svg, isSvg: true, square: true)), (1024, 1024));
      expect(size(await toPng(svg, isSvg: true, svgSize: 400)), (400, 200));
    });
  });

  testWidgets('unreadable files give a clear error', (tester) async {
    await tester.runAsync(() async {
      final junk = Uint8List.fromList(utf8.encode('not an image'));
      await expectLater(toPng(junk, isSvg: false), throwsA(isA<ImageImportException>()));
      await expectLater(toPng(junk, isSvg: true), throwsA(isA<ImageImportException>()));
    });
  });
}
