import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../security/path_safety.dart';

/// Serves a project's `source/` folder on the loopback interface so the
/// in-app preview gets real http URLs (relative paths, fetch and modules
/// work as in the built app) without enabling file:// access.
///
/// Bound to 127.0.0.1 on a random port, and every URL must start with a
/// random per-session token, so other apps on the device cannot guess it.
/// Read-only: GET and HEAD for files inside the root only.
class PreviewServer {
  PreviewServer._(this._server, this.root, this.token) {
    _server.listen(_handle);
  }

  static Future<PreviewServer> start(String root) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final r = Random.secure();
    final token = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return PreviewServer._(server, p.normalize(p.absolute(root)), token);
  }

  final HttpServer _server;
  final String root;
  final String token;

  /// Relative paths the page requested that do not exist.
  final List<String> missing = [];
  final _missingController = StreamController<String>.broadcast();
  Stream<String> get onMissing => _missingController.stream;

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}/$token/');

  Uri urlFor(String entry) => baseUri.resolve(entry.split('/').map(Uri.encodeComponent).join('/'));

  Future<void> stop() async {
    await _server.close(force: true);
    await _missingController.close();
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    res.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff');
    try {
      if (req.method != 'GET' && req.method != 'HEAD') {
        res.statusCode = HttpStatus.methodNotAllowed;
        return;
      }
      final segments = req.uri.pathSegments;
      if (segments.isEmpty || segments.first != token) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      var rel = segments.skip(1).join('/');
      if (rel.isEmpty || req.uri.path.endsWith('/')) rel = p.posix.join(rel, 'index.html');
      final String normalized;
      try {
        normalized = normalizeRelativePath(rel);
      } on UnsafePathException {
        res.statusCode = HttpStatus.badRequest;
        return;
      }
      final file = File(resolveWithin(root, normalized));
      if (!_existsExactly(file, normalized)) {
        res.statusCode = HttpStatus.notFound;
        if (!missing.contains(normalized)) {
          missing.add(normalized);
          _missingController.add(normalized);
        }
        return;
      }
      res.headers.contentType = contentTypeFor(normalized);
      res.contentLength = file.lengthSync();
      if (req.method == 'GET') await res.addStream(file.openRead());
    } finally {
      await res.close();
    }
  }

  late final String _realRoot = Directory(root).resolveSymbolicLinksSync();

  /// The built app looks files up with their exact letter case, so the
  /// preview does too, even on a disk that ignores case (Windows). The
  /// resolved path carries the name as stored on disk.
  bool _existsExactly(File file, String relative) {
    if (!file.existsSync()) return false;
    try {
      return p.relative(file.resolveSymbolicLinksSync(), from: _realRoot).replaceAll('\\', '/') == relative;
    } on FileSystemException {
      return false;
    }
  }
}

const _types = {
  'html': 'text/html; charset=utf-8',
  'htm': 'text/html; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'mjs': 'text/javascript; charset=utf-8',
  'json': 'application/json',
  'txt': 'text/plain; charset=utf-8',
  'xml': 'application/xml',
  'svg': 'image/svg+xml',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'avif': 'image/avif',
  'ico': 'image/x-icon',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'mp3': 'audio/mpeg',
  'ogg': 'audio/ogg',
  'wav': 'audio/wav',
  'mp4': 'video/mp4',
  'webm': 'video/webm',
  'wasm': 'application/wasm',
  'pdf': 'application/pdf',
};

ContentType contentTypeFor(String path) {
  final ext = p.posix.extension(path).replaceFirst('.', '').toLowerCase();
  return ContentType.parse(_types[ext] ?? 'application/octet-stream');
}
