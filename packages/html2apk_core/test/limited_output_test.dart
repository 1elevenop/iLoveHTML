import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html2apk_core/src/project_importer/zip_importer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('limited'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('writes through to disk and supports reading back', () {
    final path = p.join(tmp.path, 'out.bin');
    final out = LimitedFileOutput(path, limit: 1 << 20, onLimit: () => ArchiveRejectedException('limit'));
    out.writeBytes([1, 2, 3, 4, 5]);
    out.writeByte(6);
    out.writeStream(InputMemoryStream(Uint8List.fromList(List.generate(100000, (i) => i & 0xff))));
    expect(out.length, 100006);
    expect(out.subset(2, 6), [3, 4, 5, 6]);
    expect(out.subset(-2), [(99998) & 0xff, (99999) & 0xff]);
    out.closeSync();
    expect(File(path).lengthSync(), 100006);
  });

  test('throws as soon as the limit is passed, without buffering everything', () {
    final path = p.join(tmp.path, 'out.bin');
    final out = LimitedFileOutput(path, limit: 200000, onLimit: () => ArchiveRejectedException('too large'));
    expect(() {
      for (var i = 0; i < 100; i++) {
        out.writeBytes(Uint8List(65536));
      }
    }, throwsA(isA<ArchiveRejectedException>()));
    expect(out.length, lessThanOrEqualTo(200000 + 65536));
    out.closeSync();
    expect(File(path).lengthSync(), lessThanOrEqualTo(200000));
  });
}
