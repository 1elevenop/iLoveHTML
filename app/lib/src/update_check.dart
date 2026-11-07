import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where iLoveHTML releases are published.
const releasesRepo = '1elevenop/iLoveHTML';
const releasesPage = 'https://github.com/$releasesRepo/releases/latest';

/// A published release newer than the running app.
@immutable
class UpdateInfo {
  const UpdateInfo({required this.version, required this.pageUrl, required this.downloadUrl, required this.notes});

  final String version;

  /// The release page on GitHub.
  final String pageUrl;

  /// The file for this platform (APK on Android, Windows ZIP on Windows),
  /// or the release page when there is none.
  final String downloadUrl;
  final String notes;

  Map<String, Object> toJson() => {'version': version, 'page': pageUrl, 'download': downloadUrl, 'notes': notes};

  static UpdateInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final v = j['version'], page = j['page'], dl = j['download'], notes = j['notes'];
    if (v is! String || page is! String || dl is! String || notes is! String) return null;
    if (!isTrustedUrl(page) || !isTrustedUrl(dl)) return null;
    return UpdateInfo(version: v, pageUrl: page, downloadUrl: dl, notes: notes);
  }
}

/// Only links into this project's own GitHub releases are opened.
bool isTrustedUrl(String url) {
  final u = Uri.tryParse(url);
  return u != null &&
      u.scheme == 'https' &&
      u.host == 'github.com' &&
      u.path.startsWith('/$releasesRepo/releases/');
}

/// "v1.10.2" -> [1, 10, 2]; null when it is not a plain version.
List<int>? parseVersion(String s) {
  final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(s.trim());
  return m == null ? null : [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
}

/// Whether [latest] is a higher version than [current].
bool isNewer(String latest, String current) {
  final a = parseVersion(latest), b = parseVersion(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Reads GitHub's "latest release" (drafts and pre-releases are never
/// "latest") and turns it into an [UpdateInfo] when it is newer.
@visibleForTesting
UpdateInfo? parseLatestRelease(String body, {required String currentVersion, required String platform}) {
  final j = jsonDecode(body);
  if (j is! Map || j['draft'] == true || j['prerelease'] == true) return null;
  final tag = j['tag_name'], page = j['html_url'];
  if (tag is! String || page is! String || !isTrustedUrl(page)) return null;
  if (!isNewer(tag, currentVersion)) return null;
  bool wanted(String name) => switch (platform) {
        'android' => name.endsWith('.apk'),
        'windows' => name.endsWith('-windows-x64.zip'),
        _ => false,
      };
  var download = page;
  for (final a in (j['assets'] as List? ?? const [])) {
    if (a is! Map) continue;
    final name = a['name'], url = a['browser_download_url'];
    if (name is String && url is String && wanted(name) && isTrustedUrl(url)) {
      download = url;
      break;
    }
  }
  final notes = j['body'] is String ? (j['body'] as String).trim() : '';
  return UpdateInfo(
    version: parseVersion(tag)!.join('.'),
    pageUrl: page,
    downloadUrl: download,
    // Enough for a dialog; the full notes are on the release page.
    notes: notes.length > 4000 ? '${notes.substring(0, 4000)}…' : notes,
  );
}

enum UpdateCheckState { idle, checking, upToDate, failed }

/// Checks for a new iLoveHTML release at most every [interval], keeps the
/// answer between launches, and tells listeners when one is available.
class UpdateChecker extends ChangeNotifier {
  UpdateChecker({
    required Future<String> Function() readVersion,
    required Future<String> Function() fetchLatest,
    required this.platform,
    SharedPreferences? storage,
    DateTime Function()? clock,
    this.interval = const Duration(hours: 12),
  })  : _currentVersion = readVersion,
        _fetch = fetchLatest,
        _prefs = storage,
        _now = clock ?? DateTime.now {
    _available = UpdateInfo.fromJson(_read(_kInfo));
  }

  /// The real checker: GitHub's API over HTTPS, this app's version.
  static Future<UpdateChecker> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    return UpdateChecker(
      readVersion: () async => (await PackageInfo.fromPlatform()).version,
      fetchLatest: fetchFromGitHub,
      platform: Platform.isAndroid ? 'android' : (Platform.isWindows ? 'windows' : Platform.operatingSystem),
      storage: prefs,
    );
  }

  /// Without network or storage, for tests and as the default.
  UpdateChecker.disabled() : this(readVersion: () async => '0.0.0', fetchLatest: () async => '{}', platform: 'none');

  static const _kInfo = 'update.info', _kLast = 'update.lastCheck';

  final Future<String> Function() _currentVersion;
  final Future<String> Function() _fetch;
  final String platform;
  final SharedPreferences? _prefs;
  final DateTime Function() _now;
  final Duration interval;

  UpdateInfo? _available;
  UpdateCheckState _state = UpdateCheckState.idle;
  String? _current;

  /// A newer release, if one was found.
  UpdateInfo? get available => _available;
  UpdateCheckState get state => _state;

  /// The running version, once known.
  String? get currentVersion => _current;

  Object? _read(String key) {
    final s = _prefs?.getString(key);
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  /// Checks unless one ran recently. Never throws.
  Future<void> checkIfDue() async {
    final last = _prefs?.getInt(_kLast);
    if (last != null && _now().difference(DateTime.fromMillisecondsSinceEpoch(last)) < interval) {
      // Still drop a saved update once this version has caught up with it.
      await _refreshCurrent();
      return;
    }
    await checkNow();
  }

  /// Checks now (the "Check now" button). Never throws.
  Future<void> checkNow() async {
    if (_state == UpdateCheckState.checking) return;
    _state = UpdateCheckState.checking;
    notifyListeners();
    try {
      final current = await _currentVersion();
      _current = current;
      final info = parseLatestRelease(await _fetch(), currentVersion: current, platform: platform);
      _available = info;
      _state = info == null ? UpdateCheckState.upToDate : UpdateCheckState.idle;
      await _prefs?.setInt(_kLast, _now().millisecondsSinceEpoch);
      info == null ? await _prefs?.remove(_kInfo) : await _prefs?.setString(_kInfo, jsonEncode(info.toJson()));
    } catch (_) {
      _state = UpdateCheckState.failed;
    }
    notifyListeners();
  }

  Future<void> _refreshCurrent() async {
    try {
      _current = await _currentVersion();
    } catch (_) {
      return;
    }
    final a = _available;
    if (a != null && !isNewer(a.version, _current!)) {
      _available = null;
      await _prefs?.remove(_kInfo);
    }
    notifyListeners();
  }

  /// Forgets a found update, e.g. when update checks are turned off.
  Future<void> clear() async {
    _available = null;
    _state = UpdateCheckState.idle;
    await _prefs?.remove(_kInfo);
    notifyListeners();
  }
}

/// GET `https://api.github.com/repos/<repo>/releases/latest`. No account, no
/// cookies, nothing about the user is sent.
Future<String> fetchFromGitHub() async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..userAgent = 'iLoveHTML-update-check';
  try {
    final req = await client.getUrl(Uri.parse('https://api.github.com/repos/$releasesRepo/releases/latest'));
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    // A release's JSON is a few KB; refuse anything absurd.
    final bytes = <int>[];
    await for (final chunk in res.timeout(const Duration(seconds: 15))) {
      bytes.addAll(chunk);
      if (bytes.length > 1024 * 1024) throw const HttpException('response too large');
    }
    return utf8.decode(bytes);
  } finally {
    client.close(force: true);
  }
}
