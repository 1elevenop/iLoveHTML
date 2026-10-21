import 'dart:io';

/// Returns null when [url] is acceptable as a live-website entry point.
///
/// Only https is allowed (the wrapper disables cleartext traffic), and
/// literal loopback, private, link-local and similar addresses are rejected.
/// Host names are not resolved here; DNS-based checks belong to the
/// downloader, which must re-check every redirect target.
String? validateRemoteUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.isAbsolute) return 'Enter a full URL, e.g. https://example.com';
  if (uri.scheme != 'https') return 'Only https:// URLs are supported';
  if (uri.host.isEmpty) return 'URL has no host';
  if (uri.userInfo.isNotEmpty) return 'URLs with embedded credentials are not allowed';
  final host = uri.host.toLowerCase();
  if (host == 'localhost' || host.endsWith('.localhost') || host.endsWith('.local')) {
    return 'Local network hosts are not allowed';
  }
  final ip = InternetAddress.tryParse(host.replaceAll(RegExp(r'^\[|\]$'), ''));
  if (ip != null && isPrivateAddress(ip)) return 'Private or local IP addresses are not allowed';
  return null;
}

bool isPrivateAddress(InternetAddress a) {
  if (a.isLoopback || a.isLinkLocal || a.isMulticast) return true;
  final b = a.rawAddress;
  if (a.type == InternetAddressType.IPv4) {
    return b[0] == 0 ||
        b[0] == 10 ||
        (b[0] == 100 && b[1] >= 64 && b[1] <= 127) ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 169 && b[1] == 254) ||
        b[0] >= 224;
  }
  // IPv6: unspecified, unique-local fc00::/7, IPv4-mapped private ranges.
  if (b.every((x) => x == 0)) return true;
  if ((b[0] & 0xfe) == 0xfc) return true;
  final mapped = b.sublist(0, 10).every((x) => x == 0) && b[10] == 0xff && b[11] == 0xff;
  if (mapped) return isPrivateAddress(InternetAddress.fromRawAddress(b.sublist(12)));
  return false;
}
