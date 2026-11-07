import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How iLoveHTML itself is locked.
enum LockKind { none, pin, password }

/// When the lock comes back after the app was in the background.
enum RelockAfter {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5)),
  launchOnly(null);

  const RelockAfter(this.delay);

  /// Null: only when the app starts.
  final Duration? delay;
}

/// Key-value storage for the lock, so tests can run without plugins.
abstract class LockStorage {
  String? getString(String key);
  int? getInt(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

class PrefsLockStorage implements LockStorage {
  PrefsLockStorage(this._p);
  final SharedPreferences _p;
  @override
  String? getString(String key) => _p.getString(key);
  @override
  int? getInt(String key) => _p.getInt(key);
  @override
  bool? getBool(String key) => _p.getBool(key);
  @override
  Future<void> setString(String key, String value) => _p.setString(key, value);
  @override
  Future<void> setInt(String key, int value) => _p.setInt(key, value);
  @override
  Future<void> setBool(String key, bool value) => _p.setBool(key, value);
  @override
  Future<void> remove(String key) => _p.remove(key);
}

class MemoryLockStorage implements LockStorage {
  final _m = <String, Object>{};
  @override
  String? getString(String key) => _m[key] as String?;
  @override
  int? getInt(String key) => _m[key] as int?;
  @override
  bool? getBool(String key) => _m[key] as bool?;
  @override
  Future<void> setString(String key, String value) async => _m[key] = value;
  @override
  Future<void> setInt(String key, int value) async => _m[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => _m[key] = value;
  @override
  Future<void> remove(String key) async => _m.remove(key);
}

/// Result of a PIN, password or recovery code attempt.
sealed class UnlockResult {
  const UnlockResult();
}

class Unlocked extends UnlockResult {
  const Unlocked();
}

class WrongSecret extends UnlockResult {
  const WrongSecret(this.attemptsLeft);

  /// Tries left before a wait; 0 means a wait has started.
  final int attemptsLeft;
}

class MustWait extends UnlockResult {
  const MustWait(this.until);
  final DateTime until;
}

/// The lock that guards iLoveHTML's projects and keys from people who pick
/// up the device. It hides the app; it does not encrypt project files.
///
/// Only a salted PBKDF2-SHA256 hash of the PIN or password is stored, and
/// likewise for the one-time recovery code.
class AppLock extends ChangeNotifier {
  AppLock(this._s, {this.iterations = defaultIterations, DateTime Function()? clock}) : _now = clock ?? DateTime.now {
    _locked = enabled;
  }

  static Future<AppLock> load() async {
    try {
      return AppLock(PrefsLockStorage(await SharedPreferences.getInstance()));
    } catch (_) {
      return AppLock(MemoryLockStorage());
    }
  }

  static const defaultIterations = 120000;
  static const freeAttempts = 5;
  static const minPinLength = 4, maxPinLength = 8, minPasswordLength = 6;

  final LockStorage _s;
  final int iterations;
  final DateTime Function() _now;
  bool _locked = false;
  DateTime? _backgroundedAt;

  static const _kKind = 'lock.kind',
      _kSalt = 'lock.salt',
      _kHash = 'lock.hash',
      _kHint = 'lock.hint',
      _kBio = 'lock.biometrics',
      _kRecSalt = 'lock.recoverySalt',
      _kRecHash = 'lock.recoveryHash',
      _kFails = 'lock.failures',
      _kUntil = 'lock.waitUntil',
      _kRelock = 'lock.relock',
      _kIter = 'lock.iterations';

  LockKind get kind => LockKind.values.firstWhere((k) => k.name == _s.getString(_kKind), orElse: () => LockKind.none);
  bool get enabled => kind != LockKind.none && _s.getString(_kHash) != null;
  bool get locked => _locked && enabled;
  String? get hint => _s.getString(_kHint);
  bool get biometrics => _s.getBool(_kBio) ?? false;
  bool get hasRecoveryCode => _s.getString(_kRecHash) != null;
  RelockAfter get relockAfter =>
      RelockAfter.values.firstWhere((r) => r.name == _s.getString(_kRelock), orElse: () => RelockAfter.oneMinute);

  /// When a wait after too many wrong tries ends, if one is running.
  DateTime? get waitUntil {
    final ms = _s.getInt(_kUntil);
    if (ms == null) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    return t.isAfter(_now()) ? t : null;
  }

  /// Sets up the lock (or replaces the secret). Returns the new recovery
  /// code, which is shown once; only its hash is kept.
  Future<String> setUp({required LockKind kind, required String secret, String? hint, bool biometrics = false}) async {
    assert(kind != LockKind.none);
    final problem = secretProblem(kind, secret) ?? hintProblem(hint, secret);
    if (problem != null) throw ArgumentError(problem);
    final salt = _randomBytes(16);
    final hash = await _hash(secret, salt, iterations);
    final code = newRecoveryCode();
    final recSalt = _randomBytes(16);
    final recHash = await _hash(_normalizeCode(code), recSalt, iterations);
    await _s.setString(_kSalt, base64Encode(salt));
    await _s.setString(_kHash, base64Encode(hash));
    await _s.setInt(_kIter, iterations);
    await _s.setString(_kRecSalt, base64Encode(recSalt));
    await _s.setString(_kRecHash, base64Encode(recHash));
    await _setHint(hint);
    await _s.setBool(_kBio, biometrics);
    await _s.setString(_kKind, kind.name);
    await _clearFailures();
    // A reset after "forgot" stays locked until the caller has shown the
    // recovery code and calls [unlock].
    notifyListeners();
    return code;
  }

  Future<void> setHint(String? hint) async {
    await _setHint(hint);
    notifyListeners();
  }

  Future<void> _setHint(String? hint) async {
    final h = hint?.trim() ?? '';
    h.isEmpty ? await _s.remove(_kHint) : await _s.setString(_kHint, h);
  }

  Future<void> setBiometrics(bool on) async {
    await _s.setBool(_kBio, on);
    notifyListeners();
  }

  Future<void> setRelockAfter(RelockAfter r) async {
    await _s.setString(_kRelock, r.name);
    notifyListeners();
  }

  Future<void> disable() async {
    for (final k in [_kKind, _kSalt, _kHash, _kHint, _kBio, _kRecSalt, _kRecHash, _kFails, _kUntil, _kIter]) {
      await _s.remove(k);
    }
    _locked = false;
    notifyListeners();
  }

  /// Checks [secret]; too many wrong tries start a growing wait.
  Future<UnlockResult> unlockWithSecret(String secret) => _attempt(() => _matches(secret, _kSalt, _kHash));

  /// Checks a recovery code ("forgot PIN") without unlocking: the app opens
  /// only after a new secret is chosen. Counts against the same tries.
  Future<UnlockResult> checkRecoveryCode(String code) =>
      _attempt(() => _matches(_normalizeCode(code), _kRecSalt, _kRecHash), unlock: false);

  /// Call after the device's fingerprint, face or screen lock succeeded, or
  /// when a reset has finished.
  Future<void> unlock() async {
    await _clearFailures();
    _locked = false;
    notifyListeners();
  }

  /// Checks the secret without changing the lock state, e.g. before turning the lock off.
  Future<bool> verify(String secret) => _matches(secret, _kSalt, _kHash);

  Future<UnlockResult> _attempt(Future<bool> Function() check, {bool unlock = true}) async {
    final until = waitUntil;
    if (until != null) return MustWait(until);
    if (await check()) {
      await _clearFailures();
      if (unlock) _locked = false;
      notifyListeners();
      return const Unlocked();
    }
    final fails = (_s.getInt(_kFails) ?? 0) + 1;
    await _s.setInt(_kFails, fails);
    if (fails < freeAttempts) {
      notifyListeners();
      return WrongSecret(freeAttempts - fails);
    }
    // 30 s after 5 wrong tries, doubling each time after that, at most 1 hour.
    final seconds = min(30 * pow(2, fails - freeAttempts).toInt(), 3600);
    final t = _now().add(Duration(seconds: seconds));
    await _s.setInt(_kUntil, t.millisecondsSinceEpoch);
    notifyListeners();
    return MustWait(t);
  }

  Future<void> _clearFailures() async {
    await _s.remove(_kFails);
    await _s.remove(_kUntil);
  }

  Future<bool> _matches(String secret, String saltKey, String hashKey) async {
    final salt = _s.getString(saltKey), hash = _s.getString(hashKey);
    if (salt == null || hash == null) return false;
    final got = await _hash(secret, base64Decode(salt), _s.getInt(_kIter) ?? iterations);
    return _constantTimeEquals(got, base64Decode(hash));
  }

  /// Locks now (e.g. the "Lock now" button).
  void lockNow() {
    if (!enabled) return;
    _locked = true;
    notifyListeners();
  }

  /// Lifecycle hooks: remember when the app left, relock when it comes back late.
  void wentToBackground() => _backgroundedAt ??= _now();

  void cameToForeground() {
    final left = _backgroundedAt;
    _backgroundedAt = null;
    final delay = relockAfter.delay;
    if (left == null || delay == null || !enabled || _locked) return;
    if (_now().difference(left) >= delay) lockNow();
  }

  static String? secretProblem(LockKind kind, String secret) => switch (kind) {
        LockKind.pin when !RegExp(r'^\d+$').hasMatch(secret) => 'digits',
        LockKind.pin when secret.length < minPinLength || secret.length > maxPinLength => 'pinLength',
        LockKind.password when secret.length < minPasswordLength => 'passwordLength',
        _ => null,
      };

  /// A hint must not give the secret away.
  static String? hintProblem(String? hint, String secret) {
    final h = hint?.trim().toLowerCase() ?? '';
    if (h.isEmpty) return null;
    return h.contains(secret.toLowerCase()) ? 'hintContainsSecret' : null;
  }

  /// 16 characters from an alphabet without look-alikes, shown as XXXX-XXXX-XXXX-XXXX.
  static String newRecoveryCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final chars = List.generate(16, (_) => alphabet[r.nextInt(alphabet.length)]).join();
    return [for (var i = 0; i < 16; i += 4) chars.substring(i, i + 4)].join('-');
  }

  static String _normalizeCode(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static Future<Uint8List> _hash(String secret, List<int> salt, int iterations) =>
      iterations > 20000 ? Isolate.run(() => pbkdf2(secret, salt, iterations)) : Future.value(pbkdf2(secret, salt, iterations));
}

/// PBKDF2-HMAC-SHA256 with a 32-byte output (one block).
@visibleForTesting
Uint8List pbkdf2(String secret, List<int> salt, int iterations) {
  final mac = Hmac(sha256, utf8.encode(secret));
  var u = mac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = mac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}
