import 'dart:async';
import 'dart:io';

import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The test server is plain http on loopback, so these probes relax the
/// https and private-address rules; [UrlProbe]'s defaults are tested separately.
String? _allowLocalHttp(String url) => Uri.tryParse(url)?.scheme == 'http' ? null : 'not http';

void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((req) async {
      final res = req.response;
      switch (req.uri.path) {
        case '/start':
          res.redirect(Uri.parse('/middle'), status: HttpStatus.movedPermanently);
        case '/middle':
          res.redirect(Uri.parse('$base/home'), status: HttpStatus.found);
        case '/home':
          res.headers.contentType = ContentType.html;
          res.write('<html><head><title>\n  Shop &amp; Co  </title></head><body>hi</body></html>');
          await res.close();
        case '/loop':
          res.redirect(Uri.parse('/loop'));
        case '/to-https-private':
          res.redirect(Uri.parse('https://10.0.0.1/admin'));
        case '/slow':
          await Future<void>.delayed(const Duration(seconds: 3));
          await res.close();
        case '/missing':
          res.statusCode = 404;
          await res.close();
        default:
          res.statusCode = 500;
          await res.close();
      }
    });
  });

  tearDown(() => server.close(force: true));

  UrlProbe relaxed({Duration timeout = const Duration(seconds: 5)}) =>
      UrlProbe(validate: _allowLocalHttp, isBlockedAddress: (_) => false, timeout: timeout);

  test('follows redirects and reads the title', () async {
    final r = await relaxed().probe('$base/start');
    expect(r.finalUrl.path, '/home');
    expect(r.redirects.map((u) => u.path), ['/start', '/middle']);
    expect(r.title, 'Shop & Co');
    expect(r.ok, isTrue);
  });

  test('reports error statuses without throwing', () async {
    final r = await relaxed().probe('$base/missing');
    expect(r.statusCode, 404);
    expect(r.ok, isFalse);
  });

  test('stops redirect loops', () async {
    await expectLater(relaxed().probe('$base/loop'), throwsA(isA<UrlProbeException>()));
  });

  test('validates every redirect hop', () async {
    final probe = UrlProbe(
      validate: (u) => u.startsWith('http://127.0.0.1') ? null : validateRemoteUrl(u),
      isBlockedAddress: (a) => !a.isLoopback && isPrivateAddress(a),
    );
    await expectLater(
        probe.probe('$base/to-https-private'),
        throwsA(isA<UrlProbeException>().having((e) => e.message, 'message', contains('blocked URL'))));
  });

  test('times out', () async {
    await expectLater(relaxed(timeout: const Duration(milliseconds: 500)).probe('$base/slow'),
        throwsA(isA<UrlProbeException>().having((e) => e.message, 'message', contains('respond'))));
  });

  test('default rules block loopback and non-https', () async {
    await expectLater(UrlProbe().probe('$base/home'), throwsA(isA<UrlProbeException>()));
    // https to a host that resolves to loopback is blocked after DNS lookup.
    await expectLater(
        UrlProbe(validate: (_) => null).probe('https://localhost.:${server.port}/'),
        throwsA(isA<UrlProbeException>().having((e) => e.message, 'message', contains('private or local'))));
  });

  test('extractTitle handles missing and empty titles', () {
    expect(extractTitle('<p>no title</p>'), isNull);
    expect(extractTitle('<TITLE>  </TITLE>'), isNull);
    expect(extractTitle('<title lang="en">A&lt;B</title>'), 'A<B');
  });

  test('creates URL projects that need internet and no local files', () {
    final tmp = Directory.systemTemp.createTempSync('url_project');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final store = ProjectStore(p.join(tmp.path, 'ws'));
    final project = store.createFromUrl(url: 'https://example.com/app', name: 'Example', applicationId: 'com.example.web');
    expect(project.manifest.source.type, SourceType.url);
    expect(project.manifest.requiresInternet, isTrue);
    expect(AndroidGenerator.permissionsFor(project.manifest), ['android.permission.INTERNET']);
    expect(AndroidGenerator.runtimeConfig(project.manifest)['source'], {'type': 'remote', 'entry': 'https://example.com/app'});
    expect(Directory(project.sourceDir).existsSync(), isTrue);
    expect(store.listProjects().$1.single.manifest.name, 'Example');
    expect(() => store.createFromUrl(url: 'http://example.com', name: 'X', applicationId: 'com.example.x'),
        throwsA(isA<InvalidProjectException>()));
  });
}
