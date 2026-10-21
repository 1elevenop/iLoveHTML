import 'dart:convert';
import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late PreviewServer server;
  final client = HttpClient();

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('preview');
    final site = Directory(p.join(tmp.path, 'site'))..createSync();
    File(p.join(site.path, 'index.html')).writeAsStringSync('<h1>Home</h1>');
    Directory(p.join(site.path, 'my pages')).createSync();
    File(p.join(site.path, 'my pages', 'a b.html')).writeAsStringSync('<p>spaced</p>');
    File(p.join(site.path, 'style.css')).writeAsStringSync('body{}');
    File(p.join(tmp.path, 'secret.txt')).writeAsStringSync('outside root');
    server = await PreviewServer.start(site.path);
  });

  tearDown(() async {
    await server.stop();
    tmp.deleteSync(recursive: true);
  });

  Future<(int, String, String?)> get(Uri uri, {String method = 'GET'}) async {
    final req = await client.openUrl(method, uri);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return (res.statusCode, body, res.headers.contentType?.mimeType);
  }

  test('serves files with content types, including encoded paths', () async {
    expect(await get(server.urlFor('index.html')), (200, '<h1>Home</h1>', 'text/html'));
    expect((await get(server.urlFor('style.css'))).$3, 'text/css');
    expect((await get(server.urlFor('my pages/a b.html'))).$2, '<p>spaced</p>');
    expect((await get(server.baseUri)).$2, '<h1>Home</h1>');
  });

  test('requires the session token', () async {
    final noToken = Uri.parse('http://127.0.0.1:${server.baseUri.port}/index.html');
    expect((await get(noToken)).$1, 404);
  });

  test('does not serve files outside the root', () async {
    final base = server.baseUri.toString();
    for (final path in ['../secret.txt', '..%2Fsecret.txt', '%2e%2e/secret.txt']) {
      final (status, body, _) = await get(Uri.parse('$base$path'));
      expect(body, isNot(contains('outside root')), reason: path);
      expect(status, anyOf(400, 404), reason: path);
    }
  });

  test('records missing files once and rejects writes', () async {
    final events = <String>[];
    server.onMissing.listen(events.add);
    expect((await get(server.urlFor('js/app.js'))).$1, 404);
    expect((await get(server.urlFor('js/app.js'))).$1, 404);
    await Future<void>.delayed(Duration.zero);
    expect(server.missing, ['js/app.js']);
    expect(events, ['js/app.js']);
    expect((await get(server.urlFor('index.html'), method: 'POST')).$1, 405);
  });

  test('binds to loopback only', () {
    expect(server.baseUri.host, '127.0.0.1');
  });
}
