import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('only private IPv4 addresses count as LAN', () {
    for (final ok in ['10.0.0.5', '172.16.1.1', '172.31.255.1', '192.168.1.20']) {
      expect(isPrivateIPv4(InternetAddress(ok)), isTrue, reason: ok);
    }
    for (final bad in ['8.8.8.8', '172.32.0.1', '127.0.0.1', '169.254.1.1', '::1', 'fd00::1']) {
      expect(isPrivateIPv4(InternetAddress(bad)), isFalse, reason: bad);
    }
  });

  test('refuses to listen on a public or loopback address', () async {
    final tmp = Directory.systemTemp.createTempSync('lan');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final f = File(p.join(tmp.path, 'a.apk'))..writeAsStringSync('x');
    await expectLater(LanFileServer.start(f.path, address: InternetAddress.loopbackIPv4), throwsArgumentError);
  });

  test('QR matrix is square with finder patterns in three corners', () {
    final m = qrMatrix('http://192.168.1.20:51234/0123456789abcdef0123456789abcdef/app-debug.apk');
    expect(m.length, greaterThanOrEqualTo(21));
    expect(m.every((row) => row.length == m.length), isTrue);
    final n = m.length;
    for (final (y, x) in [(0, 0), (0, n - 7), (n - 7, 0)]) {
      expect(m[y][x], isTrue);
      expect(m[y + 1][x + 1], isFalse);
      expect(m[y + 3][x + 3], isTrue);
    }
  });

  group('serving', () {
    late Directory tmp;
    // Loopback stands in for the LAN when this machine has no private address.
    late InternetAddress lan;
    late bool loopback;
    LanFileServer? server;

    setUp(() async {
      final addresses = await lanAddresses();
      loopback = addresses.isEmpty;
      lan = loopback ? InternetAddress.loopbackIPv4 : addresses.first;
      tmp = Directory.systemTemp.createTempSync('lan');
      File(p.join(tmp.path, 'my app.apk')).writeAsBytesSync(List.generate(5000, (i) => i % 256));
    });

    tearDown(() async {
      await server?.stop();
      server = null;
      tmp.deleteSync(recursive: true);
    });

    Future<HttpClientResponse> get(Uri url, {String method = 'GET'}) async {
      final client = HttpClient()..findProxy = (_) => 'DIRECT';
      final req = await client.openUrl(method, url);
      final res = await req.close();
      client.close();
      return res;
    }

    test('serves the file at the secret link only', () async {
      final s = server = await LanFileServer.start(p.join(tmp.path, 'my app.apk'),
          address: lan, allowLoopbackForTests: loopback);
      expect(s.url.path, endsWith('/my_app.apk'));
      final counts = <int>[];
      s.onDownload.listen(counts.add);

      final ok = await get(s.url);
      expect(ok.statusCode, 200);
      expect(ok.headers.contentType?.mimeType, 'application/vnd.android.package-archive');
      expect((await ok.fold<List<int>>([], (a, b) => a..addAll(b))).length, 5000);

      final wrongToken = s.url.replace(path: '/${'0' * 32}/my_app.apk');
      final notFound = await get(wrongToken);
      expect(notFound.statusCode, 404);
      await notFound.drain<void>();
      final post = await get(s.url, method: 'POST');
      expect(post.statusCode, 404);
      await post.drain<void>();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(counts, [1]);
    });

    test('stops by itself after its lifetime', () async {
      final s = server = await LanFileServer.start(p.join(tmp.path, 'my app.apk'),
          address: lan, lifetime: const Duration(milliseconds: 100), allowLoopbackForTests: loopback);
      await s.done.timeout(const Duration(seconds: 5));
      expect(s.isRunning, isFalse);
      await expectLater(get(s.url), throwsA(isA<SocketException>()));
    });
  });
}
