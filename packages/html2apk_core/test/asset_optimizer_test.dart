import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('minifyCss', () {
    test('removes comments and spaces CSS ignores', () {
      expect(minifyCss('a {\n  color: red;\n  margin : 0 auto ;\n}\n/* note */\nb , i { x: y }'),
          'a{color: red;margin : 0 auto}b,i{x: y}');
    });

    test('keeps spaces that change meaning', () {
      expect(minifyCss('a :hover { width: calc(100% - 2px) }'), 'a :hover{width: calc(100% - 2px)}');
      expect(minifyCss('div   p { }'), 'div p{}');
      expect(minifyCss('a/**/b{}'), 'ab{}', reason: 'a comment is not a space in CSS');
    });

    test('copies strings, url() and escapes as they are', () {
      expect(minifyCss('a::after { content: "  /* x */  ; " }'), 'a::after{content: "  /* x */  ; "}');
      expect(minifyCss('a { background: url(a b;c.png) }'), 'a{background: url(a b;c.png)}');
      expect(minifyCss(r'.a\ b { }'), r'.a\ b{}');
    });

    test('keeps licence comments', () {
      expect(minifyCss('/*! MIT */ a { }'), '/*! MIT */ a{}');
    });

    test('gives up on CSS it cannot follow', () {
      expect(minifyCss('a { /* open'), isNull);
      expect(minifyCss('a { content: "open }'), isNull);
    });
  });

  group('images', () {
    Uint8List noisy(int w, int h) {
      final image = img.Image(width: w, height: h);
      var seed = 7;
      for (final px in image) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        px
          ..r = (px.x * 3) & 255
          ..g = (px.y * 5) & 255
          ..b = seed & 255;
      }
      return img.encodeJpg(image, quality: 100);
    }

    test('PNG is made smaller without changing pixels', () {
      final image = img.Image(width: 64, height: 64);
      for (final px in image) {
        px
          ..r = px.x * 4
          ..g = px.y * 4
          ..b = 0;
      }
      final loose = img.encodePng(image, level: 0);
      final out = recompressPng(loose)!;
      expect(out.length, lessThan(loose.length));
      final back = img.decodePng(out)!;
      expect(back.getBytes(order: img.ChannelOrder.rgba), image.getBytes(order: img.ChannelOrder.rgba));
    });

    test('PNG with a colour profile chunk is left alone', () {
      final loose = img.encodePng(img.Image(width: 8, height: 8), level: 0);
      // Insert a gAMA chunk after IHDR (8-byte signature + 25-byte IHDR chunk).
      final gama = [0, 0, 0, 4, ...ascii.encode('gAMA'), 0, 0, 0xb1, 0x8f, 0, 0, 0, 0];
      final withGamma = Uint8List.fromList([...loose.sublist(0, 33), ...gama, ...loose.sublist(33)]);
      expect(recompressPng(withGamma), isNull);
    });

    test('large JPEG is saved at 85%; small ones are kept', () {
      final big = noisy(400, 400);
      expect(big.length, greaterThan(minJpegBytes));
      expect(recompressJpeg(big)!.length, lessThan(big.length * 0.9));
      expect(recompressJpeg(noisy(40, 40)), isNull);
    });
  });

  test('optimizeSite copies everything and only replaces smaller files', () {
    final tmp = Directory.systemTemp.createTempSync('opt');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final src = Directory(p.join(tmp.path, 'src'))..createSync();
    File(p.join(src.path, 'index.html')).writeAsStringSync('<html>  <body>  hi  </body></html>');
    File(p.join(src.path, 'app.js')).writeAsStringSync('let a = 1;   // keep\n');
    Directory(p.join(src.path, 'css')).createSync();
    File(p.join(src.path, 'css', 'site.css')).writeAsStringSync('body {\n  margin: 0;\n}\n');
    File(p.join(src.path, 'manifest.json')).writeAsStringSync('{\n  "name": "A",\n  "x": [1, 2]\n}\n');
    File(p.join(src.path, 'broken.css')).writeAsStringSync('a { /* open');
    File(p.join(src.path, 'fake.png')).writeAsStringSync('not a png');

    final out = p.join(tmp.path, 'out');
    final r = optimizeSite(src.path, out);
    String read(String rel) => File(p.join(out, rel)).readAsStringSync();
    expect(read('index.html'), '<html>  <body>  hi  </body></html>');
    expect(read('app.js'), 'let a = 1;   // keep\n');
    expect(read('css/site.css'), 'body{margin: 0}');
    expect(read('manifest.json'), '{"name":"A","x":[1,2]}');
    expect(read('broken.css'), 'a { /* open');
    expect(read('fake.png'), 'not a png');
    expect(r.changed.map((f) => f.path), unorderedEquals(['css/site.css', 'manifest.json']));
    expect(r.savedBytes, greaterThan(0));
  });

  test('size report totals by kind and warns about big images', () {
    final tmp = Directory.systemTemp.createTempSync('size');
    addTearDown(() => tmp.deleteSync(recursive: true));
    File(p.join(tmp.path, 'a.html')).writeAsStringSync('x' * 10);
    File(p.join(tmp.path, 'big.png')).writeAsBytesSync(Uint8List(largeImageBytes + 1));
    final r = SiteSizeReport.scan(tmp.path);
    expect(r.totalBytes, largeImageBytes + 11);
    expect(r.bytesByKind[AssetKind.page], 10);
    expect(r.largest(1).single.path, 'big.png');
    expect(r.warnings.single, contains('big.png'));
  });

  test('stageForBuild leaves the project alone unless optimizing is on', () async {
    final tmp = Directory.systemTemp.createTempSync('stage');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final dir = p.join(tmp.path, 'proj');
    Directory(p.join(dir, 'source')).createSync(recursive: true);
    File(p.join(dir, 'source', 'a.css')).writeAsStringSync('a {  }');
    const m = ProjectManifest(
      id: 'p1',
      name: 'P',
      source: ProjectSource.local('index.html'),
      android: AndroidSettings(applicationId: 'com.example.p'),
    );
    final off = await stageForBuild(ProjectHandle(dir, m), stagingRoot: p.join(tmp.path, 'staging'));
    expect(off.project.sourceDir, p.join(dir, 'source'));
    expect(off.result, isNull);

    final on = await stageForBuild(ProjectHandle(dir, m.copyWith(optimizeAssets: true)),
        stagingRoot: p.join(tmp.path, 'staging'));
    expect(File(p.join(on.project.sourceDir, 'a.css')).readAsStringSync(), 'a{}');
    expect(File(p.join(dir, 'source', 'a.css')).readAsStringSync(), 'a {  }');
    expect(ProjectManifest.fromJson(on.project.manifest.toJson()).optimizeAssets, isTrue);
    on.dispose();
    expect(Directory(on.project.sourceDir).existsSync(), isFalse);
  });
}
