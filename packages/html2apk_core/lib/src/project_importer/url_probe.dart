import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../security/url_policy.dart';

class UrlProbeResult {
  UrlProbeResult({required this.finalUrl, required this.redirects, required this.statusCode, this.title, this.contentType});

  /// Where the site ended up after redirects; used as the app's start URL.
  final Uri finalUrl;

  /// Every URL visited before [finalUrl], in order.
  final List<Uri> redirects;
  final int statusCode;
  final String? title;
  final String? contentType;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

class UrlProbeException implements Exception {
  UrlProbeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Checks a live website before it becomes an app's start URL.
///
/// Redirects are followed manually so that every hop is validated: https
/// only, no credentials, and no host that resolves to a loopback, private
/// or link-local address. Only the start of the page is read, to find its
/// title. Limitation: the address is checked before connecting, so a host
/// whose DNS changes between the check and the request is not caught here;
/// the generated app never grants such pages native access either way.
class UrlProbe {
  UrlProbe({
    this.validate = validateRemoteUrl,
    this.isBlockedAddress = isPrivateAddress,
    this.timeout = const Duration(seconds: 10),
    this.maxRedirects = 5,
    this.maxBodyBytes = 256 * 1024,
  });

  final String? Function(String url) validate;
  final bool Function(InternetAddress address) isBlockedAddress;
  final Duration timeout;
  final int maxRedirects;
  final int maxBodyBytes;

  Future<UrlProbeResult> probe(String input) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'Mozilla/5.0 (Linux; Android) HTML2APK-UrlCheck';
    final visited = <Uri>[];
    var url = input.trim();
    try {
      for (var hop = 0;; hop++) {
        final error = validate(url);
        if (error != null) throw UrlProbeException(hop == 0 ? error : 'Redirected to a blocked URL ($url): $error');
        final uri = Uri.parse(url);
        await _checkAddresses(uri.host);

        final request = await client.getUrl(uri).timeout(timeout);
        request.followRedirects = false;
        final response = await request.close().timeout(timeout);

        if (response.isRedirect) {
          await response.drain<void>();
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null) throw UrlProbeException('Redirect without a Location header');
          if (hop >= maxRedirects) throw UrlProbeException('Too many redirects (more than $maxRedirects)');
          visited.add(uri);
          url = uri.resolve(location).toString();
          continue;
        }

        final type = response.headers.contentType;
        String? title;
        if (type?.mimeType == 'text/html') {
          title = extractTitle(await _readPrefix(response));
        } else {
          await response.drain<void>();
        }
        return UrlProbeResult(
          finalUrl: uri,
          redirects: visited,
          statusCode: response.statusCode,
          title: title,
          contentType: type?.mimeType,
        );
      }
    } on TimeoutException {
      throw UrlProbeException('The site did not respond within ${timeout.inSeconds} s');
    } on SocketException catch (e) {
      throw UrlProbeException('Could not connect: ${e.message}');
    } on HandshakeException {
      throw UrlProbeException('The site\'s HTTPS certificate is not valid');
    } on HttpException catch (e) {
      throw UrlProbeException('HTTP error: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _checkAddresses(String host) async {
    final literal = InternetAddress.tryParse(host.replaceAll(RegExp(r'^\[|\]$'), ''));
    final addresses = literal != null ? [literal] : await InternetAddress.lookup(host).timeout(timeout);
    if (addresses.isEmpty) throw UrlProbeException('Could not resolve $host');
    if (addresses.any(isBlockedAddress)) {
      throw UrlProbeException('$host points to a private or local network address');
    }
  }

  Future<String> _readPrefix(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length >= maxBodyBytes) break;
    }
    return utf8.decode(bytes.length > maxBodyBytes ? bytes.sublist(0, maxBodyBytes) : bytes, allowMalformed: true);
  }
}

/// The page's `<title>`, whitespace-collapsed with common entities decoded.
String? extractTitle(String html) {
  final m = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false).firstMatch(html);
  if (m == null) return null;
  final t = m
      .group(1)!
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .trim();
  return t.isEmpty ? null : t;
}
