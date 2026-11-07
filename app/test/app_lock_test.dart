import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/main.dart';
import 'package:html2apk_app/src/app_controller.dart';
import 'package:html2apk_app/src/app_lock.dart';
import 'package:html2apk_app/src/app_settings.dart';
import 'package:html2apk_app/src/ui/lock_screens.dart';
import 'package:path/path.dart' as p;

class FakeDeviceAuth extends DeviceAuth {
  FakeDeviceAuth({this.bio = false, this.device = false, this.succeed = true});
  final bool bio, device, succeed;
  int calls = 0;
  @override
  Future<bool> hasBiometrics() async => bio;
  @override
  Future<bool> hasDeviceLock() async => device;
  @override
  Future<bool> authenticate(String reason, {required bool biometricOnly}) async {
    calls++;
    return succeed;
  }
}

void main() {
  var now = DateTime(2026, 11, 7, 12);
  AppLock newLock([LockStorage? s]) => AppLock(s ?? MemoryLockStorage(), iterations: 50, clock: () => now);

  setUp(() => now = DateTime(2026, 11, 7, 12));

  test('pbkdf2 matches the RFC 7914 PBKDF2-HMAC-SHA256 test vector', () {
    final out = pbkdf2('passwd', utf8.encode('salt'), 1);
    expect(out.length, 32);
    expect(
      out.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
    );
    // Sanity: one iteration equals a single HMAC over salt||INT(1).
    expect(Hmac(sha256, utf8.encode('passwd')).convert([...utf8.encode('salt'), 0, 0, 0, 1]).bytes, out);
  });

  test('setting up stores only hashes, then the PIN unlocks', () async {
    final storage = MemoryLockStorage();
    final lock = newLock(storage);
    expect(lock.enabled, isFalse);
    final code = await lock.setUp(kind: LockKind.pin, secret: '2580', hint: 'door code');
    expect(code, matches(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$')));
    expect(lock.enabled, isTrue);
    expect(lock.locked, isFalse, reason: 'setting up does not lock you out right away');
    expect(storage.getString('lock.hash'), isNot(contains('2580')));
    expect(lock.hint, 'door code');

    // A fresh start (same storage) is locked.
    final again = newLock(storage);
    expect(again.locked, isTrue);
    expect(await again.unlockWithSecret('1111'), isA<WrongSecret>());
    expect(again.locked, isTrue);
    expect(await again.unlockWithSecret('2580'), isA<Unlocked>());
    expect(again.locked, isFalse);
  });

  test('rejects weak secrets and hints that give the secret away', () async {
    final lock = newLock();
    expect(AppLock.secretProblem(LockKind.pin, '12'), 'pinLength');
    expect(AppLock.secretProblem(LockKind.pin, '12a4'), 'digits');
    expect(AppLock.secretProblem(LockKind.password, 'abc'), 'passwordLength');
    expect(AppLock.secretProblem(LockKind.pin, '123456'), isNull);
    expect(AppLock.hintProblem('it is 2580!', '2580'), 'hintContainsSecret');
    expect(AppLock.hintProblem('my door', '2580'), isNull);
    expect(() => lock.setUp(kind: LockKind.pin, secret: '2580', hint: 'pin 2580'), throwsArgumentError);
  });

  test('five wrong tries start a wait that doubles', () async {
    final lock = newLock();
    await lock.setUp(kind: LockKind.password, secret: 'correct horse');
    lock.lockNow();
    for (var left = 4; left >= 1; left--) {
      final r = await lock.unlockWithSecret('nope');
      expect((r as WrongSecret).attemptsLeft, left);
    }
    final fifth = await lock.unlockWithSecret('nope');
    expect((fifth as MustWait).until, now.add(const Duration(seconds: 30)));
    // Even the right password is refused while waiting.
    expect(await lock.unlockWithSecret('correct horse'), isA<MustWait>());
    now = now.add(const Duration(seconds: 31));
    final sixth = await lock.unlockWithSecret('nope');
    expect((sixth as MustWait).until, now.add(const Duration(seconds: 60)));
    now = now.add(const Duration(seconds: 61));
    expect(await lock.unlockWithSecret('correct horse'), isA<Unlocked>());
    // Success resets the count.
    lock.lockNow();
    expect((await lock.unlockWithSecret('nope') as WrongSecret).attemptsLeft, 4);
  });

  test('recovery code is checked without unlocking, ignoring case and dashes', () async {
    final lock = newLock();
    final code = await lock.setUp(kind: LockKind.pin, secret: '2580');
    lock.lockNow();
    expect(await lock.checkRecoveryCode('AAAA-BBBB-CCCC-DDDD'), isA<WrongSecret>());
    expect(await lock.checkRecoveryCode(code.toLowerCase().replaceAll('-', ' ')), isA<Unlocked>());
    expect(lock.locked, isTrue, reason: 'opens only after a new secret is chosen');
    final newCode = await lock.setUp(kind: LockKind.pin, secret: '1357');
    expect(newCode, isNot(code));
    expect(lock.locked, isTrue);
    await lock.unlock();
    expect(lock.locked, isFalse);
    lock.lockNow();
    expect(await lock.checkRecoveryCode(code), isA<WrongSecret>(), reason: 'old code no longer works');
  });

  test('relocks after the chosen time in the background', () async {
    final lock = newLock();
    await lock.setUp(kind: LockKind.pin, secret: '2580');
    await lock.setRelockAfter(RelockAfter.oneMinute);
    lock.wentToBackground();
    now = now.add(const Duration(seconds: 30));
    lock.cameToForeground();
    expect(lock.locked, isFalse);
    lock.wentToBackground();
    now = now.add(const Duration(minutes: 2));
    lock.cameToForeground();
    expect(lock.locked, isTrue);

    await lock.unlockWithSecret('2580');
    await lock.setRelockAfter(RelockAfter.launchOnly);
    lock.wentToBackground();
    now = now.add(const Duration(hours: 5));
    lock.cameToForeground();
    expect(lock.locked, isFalse);
  });

  test('turning the lock off removes everything', () async {
    final storage = MemoryLockStorage();
    final lock = newLock(storage);
    await lock.setUp(kind: LockKind.pin, secret: '2580', hint: 'x');
    await lock.disable();
    expect(lock.enabled, isFalse);
    expect(storage.getString('lock.hash'), isNull);
    expect(storage.getString('lock.hint'), isNull);
    expect(newLock(storage).locked, isFalse);
  });

  group('screens', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('lock_ui'));
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<AppLock> lockedApp(WidgetTester tester, {LockKind kind = LockKind.pin, String secret = '2580', String? hint}) async {
      final storage = MemoryLockStorage();
      await tester.runAsync(() => newLock(storage).setUp(kind: kind, secret: secret, hint: hint));
      final lock = newLock(storage);
      final controller = AppController(
        workspaceDir: p.join(tmp.path, 'ws'),
        settings: AppSettings.memory(animate: false),
        lock: lock,
      );
      await tester.pumpWidget(Html2ApkApp(controller: controller));
      await tester.pump();
      return lock;
    }

    Future<void> tapDigits(WidgetTester tester, String digits) async {
      for (final d in digits.split('')) {
        await tester.tap(find.widgetWithText(OutlinedButton, d));
        await tester.pump();
      }
    }

    testWidgets('the app is hidden until the right PIN is entered; the hint shows after a wrong one', (tester) async {
      final lock = await lockedApp(tester, hint: 'front door');
      expect(find.text('Enter your PIN'), findsOneWidget);
      expect(find.text('Projects'), findsNothing);

      await tapDigits(tester, '1111');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.textContaining('4 tries left'), findsOneWidget);
      expect(find.text('Hint: front door'), findsOneWidget);
      expect(lock.locked, isTrue);

      await tapDigits(tester, '2580');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(lock.locked, isFalse);
      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('password lock with Forgot password using the recovery code', (tester) async {
      await lockedApp(tester, kind: LockKind.password, secret: 'open sesame');
      expect(find.text('Enter your password'), findsOneWidget);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Use your recovery code'), findsOneWidget);
      // No device lock in this fake: only the recovery code is offered.
      expect(find.text('Verify with device lock'), findsNothing);
      expect(find.textContaining('clearing iLoveHTML'), findsOneWidget);
    });
  });
}
