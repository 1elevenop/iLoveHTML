import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

/// True for IPv4 addresses that only exist inside a home or office network.
bool isPrivateIPv4(InternetAddress a) {
  if (a.type != InternetAddressType.IPv4) return false;
  final b = a.rawAddress;
  return b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || (b[0] == 192 && b[1] == 168);
}

/// True when [a] and [b] are IPv4 addresses in the same /24 network.
bool sameSubnet24(InternetAddress a, InternetAddress b) {
  if (a.type != InternetAddressType.IPv4 || b.type != InternetAddressType.IPv4) return false;
  final x = a.rawAddress, y = b.rawAddress;
  return x[0] == y[0] && x[1] == y[1] && x[2] == y[2];
}

/// This computer's Wi-Fi/Ethernet addresses that a phone on the same network can reach.
Future<List<InternetAddress>> lanAddresses() async => [
      for (final nic in await NetworkInterface.list(type: InternetAddressType.IPv4))
        for (final a in nic.addresses)
          if (isPrivateIPv4(a)) a,
    ];

/// Serves one file to phones on the local network, so a built APK can be
/// installed by scanning a QR code.
///
/// * Only `GET`/`HEAD` of one secret path (128-bit random token) works;
///   everything else is 404.
/// * Only devices in the same /24 network as [address] are served.
/// * Each device may make [requestsPerMinute] requests a minute (then 429), and
///   the file is served at most [maxDownloads] times in total (then 410).
/// * It stops by itself after [lifetime].
///
/// The link is plain HTTP, so use it only on a network you trust.
class LanFileServer {
  LanFileServer._(this._server, this.filePath, this._path, this.address, Duration lifetime, this._allowLoopback,
      this.requestsPerMinute, this.maxDownloads) {
    url; // Read the port while the server is open.
    _timer = Timer(lifetime, stop);
    _server.listen(_handle, onDone: _finish);
  }

  static Future<LanFileServer> start(
    String filePath, {
    required InternetAddress address,
    Duration lifetime = const Duration(minutes: 10),
    int requestsPerMinute = 10,
    int maxDownloads = 20,
    // Tests only: machines without a network card have no private address.
    bool allowLoopbackForTests = false,
  }) async {
    if (!isPrivateIPv4(address) && !(allowLoopbackForTests && address.isLoopback)) {
      throw ArgumentError.value(address.address, 'address', 'Must be a private network address');
    }
    if (!File(filePath).existsSync()) throw FileSystemException('File not found', filePath);
    final server = await HttpServer.bind(address, 0);
    final r = Random.secure();
    final token = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final name = _safeName(p.basename(filePath));
    return LanFileServer._(
        server, filePath, '/$token/$name', address, lifetime, allowLoopbackForTests, requestsPerMinute, maxDownloads);
  }

  final HttpServer _server;
  final String filePath;
  final String _path;
  final InternetAddress address;
  final bool _allowLoopback;
  final int requestsPerMinute;
  final int maxDownloads;
  final _buckets = <String, ({double tokens, DateTime at})>{};
  var _started = 0;
  late final Timer _timer;
  final _done = Completer<void>();
  final _downloads = StreamController<int>.broadcast();
  var _count = 0;

  /// The link to put in the QR code.
  // Built once: HttpServer.port throws after the server is closed.
  late final Uri url = Uri.parse('http://${address.address}:${_server.port}$_path');

  /// Completes when the server has stopped (by [stop] or after its lifetime).
  Future<void> get done => _done.future;

  bool get isRunning => !_done.isCompleted;

  /// Number of finished downloads, each time one ends.
  Stream<int> get onDownload => _downloads.stream;

  Future<void> stop() async {
    _timer.cancel();
    await _server.close(force: true);
    _finish();
  }

  void _finish() {
    if (_done.isCompleted) return;
    _done.complete();
    unawaited(_downloads.close());
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    res.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Content-Security-Policy', "default-src 'none'")
      ..set('Referrer-Policy', 'no-referrer')
      ..set('X-Frame-Options', 'DENY')
      ..set('Cross-Origin-Resource-Policy', 'same-origin');
    try {
      final remote = req.connectionInfo?.remoteAddress;
      if (remote == null || !(sameSubnet24(remote, address) || (_allowLoopback && remote.isLoopback))) {
        res.statusCode = HttpStatus.forbidden;
        return;
      }
      if (!_take(remote.address)) {
        res.statusCode = HttpStatus.tooManyRequests;
        res.headers.set(HttpHeaders.retryAfterHeader, '60');
        return;
      }
      if ((req.method != 'GET' && req.method != 'HEAD') || req.uri.path != _path) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      if (req.method == 'GET' && _started >= maxDownloads) {
        res.statusCode = HttpStatus.gone;
        return;
      }
      final file = File(filePath);
      final length = await file.length();
      res.headers
        ..contentType = ContentType.parse(_mimeType(filePath))
        ..contentLength = length
        ..set('Content-Disposition', 'attachment; filename="${p.basename(_path)}"');
      if (req.method == 'GET') {
        _started++;
        await res.addStream(file.openRead());
        _count++;
        if (!_downloads.isClosed) _downloads.add(_count);
      }
    } on Object {
      // A phone that disconnects half-way must not stop the server.
    } finally {
      try {
        await res.close();
      } on Object {
        // Already closed by the other side.
      }
    }
  }

  /// Token bucket per client address: [requestsPerMinute] tokens, refilled evenly over a minute.
  bool _take(String ip) {
    final now = DateTime.now();
    final b = _buckets[ip];
    final max = requestsPerMinute.toDouble();
    final refill = b == null ? max : b.tokens + now.difference(b.at).inMicroseconds / 60e6 * max;
    final tokens = refill > max ? max : refill;
    if (tokens < 1) {
      _buckets[ip] = (tokens: tokens, at: now);
      return false;
    }
    _buckets[ip] = (tokens: tokens - 1, at: now);
    return true;
  }

  static String _mimeType(String path) => switch (p.extension(path).toLowerCase()) {
        '.apk' => 'application/vnd.android.package-archive',
        _ => 'application/octet-stream',
      };

  /// File names in the link: letters, digits, dot, dash and underscore only.
  static String _safeName(String name) {
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safe.isEmpty ? 'app.apk' : safe;
  }
}

/// QR code modules for [text]: `rows[y][x]` is true for a dark square.
List<List<bool>> qrMatrix(String text) {
  final image = QrImage(QrCode(payload: QrPayload.fromString(text), errorCorrectLevel: QrErrorCorrectLevel.medium));
  return [
    for (var y = 0; y < image.moduleCount; y++) [for (var x = 0; x < image.moduleCount; x++) image.isDark(y, x)],
  ];
}
