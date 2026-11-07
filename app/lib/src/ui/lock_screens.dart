import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../app_lock.dart';
import 'l10n.dart';
import 'theme.dart';

/// The device's own fingerprint, face or screen lock. Replaceable in tests.
class DeviceAuth {
  const DeviceAuth();

  static final _auth = LocalAuthentication();

  /// Fingerprint or face is enrolled.
  Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// A fingerprint, face or screen lock (PIN, pattern, password) is set up.
  Future<bool> hasDeviceLock() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason, {required bool biometricOnly}) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: biometricOnly);
    } catch (_) {
      return false;
    }
  }
}

/// Covers the whole app with the lock screen while [lock] is locked, and
/// relocks after the app has been in the background for a while.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.lock, required this.child, this.deviceAuth = const DeviceAuth()});

  final AppLock lock;
  final Widget child;
  final DeviceAuth deviceAuth;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.lock.addListener(_changed);
  }

  @override
  void dispose() {
    widget.lock.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      widget.lock.wentToBackground();
    } else if (state == AppLifecycleState.resumed) {
      widget.lock.cameToForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.lock.locked;
    return Stack(children: [
      // The app stays alive underneath but cannot be seen, touched or read out.
      Offstage(
        offstage: locked,
        child: TickerMode(enabled: !locked, child: ExcludeSemantics(excluding: locked, child: widget.child)),
      ),
      if (locked)
        Positioned.fill(
          // Its own navigator (for "Forgot PIN"), with its own hero scope:
          // the app's navigator keeps the app's.
          child: HeroControllerScope(
            controller: MaterialApp.createMaterialHeroController(),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => LockScreen(lock: widget.lock, deviceAuth: widget.deviceAuth),
              ),
            ),
          ),
        ),
    ]);
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.lock, required this.deviceAuth});

  final AppLock lock;
  final DeviceAuth deviceAuth;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _busy = false;
  bool _showHint = false;
  bool _obscure = true;
  bool _canBio = false;
  Timer? _tick;

  AppLock get _lock => widget.lock;
  bool get _pin => _lock.kind == LockKind.pin;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _lock.waitUntil != null) setState(() {});
    });
    if (_lock.biometrics) {
      widget.deviceAuth.hasBiometrics().then((ok) {
        if (!mounted || !ok) return;
        setState(() => _canBio = true);
        // Ask straight away, like the phone's own lock screen.
        WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (_busy || _lock.waitUntil != null) return;
    final l = context.l10n;
    final ok = await widget.deviceAuth.authenticate(l.unlockReason, biometricOnly: true);
    if (ok) await _lock.unlock();
  }

  Future<void> _submit() async {
    final secret = _field.text;
    if (secret.isEmpty || _busy) return;
    setState(() => _busy = true);
    final r = await _lock.unlockWithSecret(secret);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _field.clear();
      _error = switch (r) {
        Unlocked() => null,
        WrongSecret(:final attemptsLeft) => context.l10n.wrongSecret(attemptsLeft),
        MustWait() => null,
      };
      // After a wrong try, offer the hint.
      if (r is WrongSecret && _lock.hint != null) _showHint = true;
    });
    if (r is WrongSecret) HapticFeedback.heavyImpact();
  }

  void _digit(String d) {
    if (_field.text.length >= AppLock.maxPinLength) return;
    setState(() {
      _field.text += d;
      _error = null;
    });
  }

  void _backspace() {
    if (_field.text.isEmpty) return;
    setState(() => _field.text = _field.text.substring(0, _field.text.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final e = context.eleven;
    final wait = _lock.waitUntil;
    final waitSeconds = wait == null ? 0 : wait.difference(DateTime.now()).inSeconds + 1;
    final blocked = wait != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 40, color: e.acc),
                  const SizedBox(height: 12),
                  Text('iLoveHTML', style: t.titleLarge),
                  const SizedBox(height: 4),
                  Text(_pin ? l.enterPin : l.enterPassword, style: t.bodyMedium),
                  const SizedBox(height: 20),
                  if (_pin)
                    _PinDots(length: _field.text.length, error: _error != null)
                  else
                    TextField(
                      key: const ValueKey('lockPassword'),
                      controller: _field,
                      focusNode: _focus,
                      autofocus: !blocked,
                      enabled: !blocked,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l.password,
                        suffixIcon: IconButton(
                          tooltip: _obscure ? l.showPassword : l.hidePassword,
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        blocked ? l.tooManyTries(waitSeconds) : (_error ?? ''),
                        textAlign: TextAlign.center,
                        style: t.bodySmall?.copyWith(color: e.acc),
                      ),
                    ),
                  ),
                  if (_showHint && _lock.hint != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l.hintIs(_lock.hint!), textAlign: TextAlign.center, style: t.bodyMedium),
                    ),
                  if (_pin)
                    _PinPad(
                      enabled: !blocked && !_busy,
                      onDigit: _digit,
                      onBackspace: _backspace,
                      onDone: _submit,
                      onBiometric: _canBio ? _biometric : null,
                      backspaceLabel: l.deleteDigit,
                      doneLabel: l.unlock,
                      biometricLabel: l.useFingerprint,
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(onPressed: blocked || _busy ? null : _submit, child: Text(l.unlock)),
                    ),
                    if (_canBio) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: blocked ? null : _biometric,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(l.useFingerprint),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      if (_lock.hint != null && !_showHint)
                        TextButton(onPressed: () => setState(() => _showHint = true), child: Text(l.showHint)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ForgotSecretScreen(lock: _lock, deviceAuth: widget.deviceAuth)),
                        ),
                        child: Text(_pin ? l.forgotPin : l.forgotPassword),
                      ),
                    ],
                  ),
                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, required this.error});

  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final shown = length < AppLock.minPinLength ? AppLock.minPinLength : length;
    return Semantics(
      label: context.l10n.digitsEntered(length),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < shown; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < length ? (error ? e.fg : e.acc) : Colors.transparent,
                border: Border.all(color: i < length ? Colors.transparent : e.line2, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onDone,
    required this.onBiometric,
    required this.backspaceLabel,
    required this.doneLabel,
    required this.biometricLabel,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace, onDone;
  final VoidCallback? onBiometric;
  final String backspaceLabel, doneLabel, biometricLabel;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback? onTap, {String? label}) => Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: 72,
            height: 60,
            child: Semantics(
              button: true,
              label: label,
              child: OutlinedButton(onPressed: enabled ? onTap : null, child: child),
            ),
          ),
        );
    Widget digit(String d) => key(Text(d, style: monoStyle(context, size: 22)), () => onDigit(d));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
        Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) digit(d)]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        onBiometric != null
            ? key(const Icon(Icons.fingerprint), onBiometric, label: biometricLabel)
            : key(const Icon(Icons.backspace_outlined), onBackspace, label: backspaceLabel),
        digit('0'),
        key(const Icon(Icons.arrow_forward), onDone, label: doneLabel),
      ]),
      if (onBiometric != null)
        TextButton.icon(
          onPressed: enabled ? onBackspace : null,
          icon: const Icon(Icons.backspace_outlined, size: 18),
          label: Text(backspaceLabel),
        ),
    ]);
  }
}

/// "Forgot PIN / password": prove it is you with the device's own lock or
/// the recovery code, then choose a new secret.
class ForgotSecretScreen extends StatefulWidget {
  const ForgotSecretScreen({super.key, required this.lock, required this.deviceAuth});

  final AppLock lock;
  final DeviceAuth deviceAuth;

  @override
  State<ForgotSecretScreen> createState() => _ForgotSecretScreenState();
}

class _ForgotSecretScreenState extends State<ForgotSecretScreen> {
  final _code = TextEditingController();
  late final Future<bool> _hasDeviceLock = widget.deviceAuth.hasDeviceLock();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verified() async {
    if (!mounted) return;
    // Proven: choose a new PIN or password right away.
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SetUpLockScreen(lock: widget.lock, deviceAuth: widget.deviceAuth, reset: true)),
    );
  }

  Future<void> _withDevice() async {
    final ok = await widget.deviceAuth.authenticate(context.l10n.resetReason, biometricOnly: false);
    if (ok) await _verified();
  }

  Future<void> _withCode() async {
    setState(() => _busy = true);
    final lock = widget.lock;
    // Checked without unlocking: the app opens only after a new secret is set.
    final r = await lock.checkRecoveryCode(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (r) {
        Unlocked() => null,
        WrongSecret(:final attemptsLeft) => context.l10n.wrongRecoveryCode(attemptsLeft),
        MustWait(:final until) => context.l10n.tooManyTries(until.difference(DateTime.now()).inSeconds + 1),
      };
    });
    if (r is Unlocked) await _verified();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.lock.kind == LockKind.pin ? l.forgotPin : l.forgotPassword)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder(
            future: _hasDeviceLock,
            builder: (context, snap) => snap.data == true
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.forgotWithDevice, style: t.titleSmall),
                    const SizedBox(height: 4),
                    Text(l.forgotWithDeviceHint, style: t.bodySmall),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _withDevice,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l.verifyWithDevice),
                    ),
                    const SizedBox(height: 24),
                  ])
                : const SizedBox.shrink(),
          ),
          Text(l.forgotWithCode, style: t.titleSmall),
          const SizedBox(height: 4),
          Text(l.forgotWithCodeHint, style: t.bodySmall),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            style: monoStyle(context, size: 16),
            decoration: InputDecoration(labelText: l.recoveryCode, hintText: 'XXXX-XXXX-XXXX-XXXX', errorText: _error),
            onSubmitted: (_) => _withCode(),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _busy ? null : _withCode, child: Text(l.useRecoveryCode)),
          const SizedBox(height: 24),
          Text(l.forgotNoWay, style: t.bodySmall),
        ],
      ),
    );
  }
}

/// Chooses PIN or password, the secret (twice), a hint and fingerprint,
/// then shows the recovery code once.
class SetUpLockScreen extends StatefulWidget {
  const SetUpLockScreen({super.key, required this.lock, required this.deviceAuth, this.reset = false});

  final AppLock lock;
  final DeviceAuth deviceAuth;

  /// After "forgot": the lock is currently locked and unlocks when done.
  final bool reset;

  @override
  State<SetUpLockScreen> createState() => _SetUpLockScreenState();
}

class _SetUpLockScreenState extends State<SetUpLockScreen> {
  final _form = GlobalKey<FormState>();
  late LockKind _kind = widget.lock.kind == LockKind.password ? LockKind.password : LockKind.pin;
  final _secret = TextEditingController();
  final _repeat = TextEditingController();
  late final _hint = TextEditingController(text: widget.lock.hint ?? '');
  late bool _bio = widget.lock.biometrics;
  late final Future<bool> _hasBio = widget.deviceAuth.hasBiometrics();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_secret, _repeat, _hint]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _secretError(String? v) {
    final l = context.l10n;
    return switch (AppLock.secretProblem(_kind, v ?? '')) {
      'digits' => l.pinDigitsOnly,
      'pinLength' => l.pinLength(AppLock.minPinLength, AppLock.maxPinLength),
      'passwordLength' => l.passwordMinLength(AppLock.minPasswordLength),
      _ => null,
    };
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final lock = widget.lock;
    final code = await lock.setUp(kind: _kind, secret: _secret.text, hint: _hint.text, biometrics: _bio);
    if (!mounted) return;
    setState(() => _busy = false);
    await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => RecoveryCodeDialog(code: code));
    if (widget.reset) {
      await lock.unlock();
    } else if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final pin = _kind == LockKind.pin;
    return Scaffold(
      appBar: AppBar(title: Text(widget.reset ? l.chooseNewSecret : l.setUpAppLock)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<LockKind>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: LockKind.pin, label: Text(l.pin), icon: const Icon(Icons.pin_outlined)),
                ButtonSegment(value: LockKind.password, label: Text(l.password), icon: const Icon(Icons.password)),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() {
                _kind = v.single;
                _secret.clear();
                _repeat.clear();
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('newSecret'),
              controller: _secret,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: pin ? TextInputType.number : TextInputType.visiblePassword,
              inputFormatters: pin ? [FilteringTextInputFormatter.digitsOnly] : null,
              maxLength: pin ? AppLock.maxPinLength : null,
              decoration: InputDecoration(
                labelText: pin ? l.newPin : l.newPassword,
                helperText: pin ? l.pinLength(AppLock.minPinLength, AppLock.maxPinLength) : l.passwordMinLength(AppLock.minPasswordLength),
                suffixIcon: IconButton(
                  tooltip: _obscure ? l.showPassword : l.hidePassword,
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: _secretError,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('repeatSecret'),
              controller: _repeat,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: pin ? TextInputType.number : TextInputType.visiblePassword,
              inputFormatters: pin ? [FilteringTextInputFormatter.digitsOnly] : null,
              maxLength: pin ? AppLock.maxPinLength : null,
              decoration: InputDecoration(labelText: pin ? l.repeatPin : l.repeatPassword),
              validator: (v) => v == _secret.text ? null : (pin ? l.pinsDoNotMatch : l.passwordsDoNotMatch),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('hint'),
              controller: _hint,
              maxLength: 60,
              decoration: InputDecoration(labelText: l.hintOptional, helperText: l.hintHelp, helperMaxLines: 3),
              validator: (v) => AppLock.hintProblem(v, _secret.text) == null ? null : l.hintGivesAway,
            ),
            FutureBuilder(
              future: _hasBio,
              builder: (context, snap) => snap.data == true
                  ? SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(l.unlockWithFingerprint),
                      subtitle: Text(l.unlockWithFingerprintHint),
                      value: _bio,
                      onChanged: (v) => setState(() => _bio = v),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Text(l.appLockNote, style: t.bodySmall),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _save, child: Text(l.saveAndContinue)),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

/// Shows the recovery code once, and only closes after the user confirms
/// they saved it.
class RecoveryCodeDialog extends StatefulWidget {
  const RecoveryCodeDialog({super.key, required this.code});

  final String code;

  @override
  State<RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<RecoveryCodeDialog> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l.recoveryCodeTitle),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.recoveryCodeBody),
            const SizedBox(height: 16),
            Center(
              child: SelectableText(widget.code,
                  key: const ValueKey('recoveryCode'), style: monoStyle(context, size: 18).copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: widget.code)),
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l.copy),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _saved,
              onChanged: (v) => setState(() => _saved = v ?? false),
              title: Text(l.iSavedTheCode),
            ),
          ]),
        ),
        actions: [
          FilledButton(onPressed: _saved ? () => Navigator.pop(context) : null, child: Text(l.done)),
        ],
      ),
    );
  }
}

/// The App lock part of Settings.
class AppLockSettings extends StatelessWidget {
  const AppLockSettings({super.key, required this.lock, this.deviceAuth = const DeviceAuth()});

  final AppLock lock;
  final DeviceAuth deviceAuth;

  Future<bool> _confirmCurrent(BuildContext context) async {
    final l = context.l10n;
    final field = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        String? error;
        return StatefulBuilder(
          builder: (c, setState) => AlertDialog(
            title: Text(lock.kind == LockKind.pin ? l.enterCurrentPin : l.enterCurrentPassword),
            content: TextField(
              controller: field,
              autofocus: true,
              obscureText: true,
              keyboardType: lock.kind == LockKind.pin ? TextInputType.number : TextInputType.visiblePassword,
              decoration: InputDecoration(errorText: error),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
              FilledButton(
                onPressed: () async {
                  if (await lock.verify(field.text)) {
                    if (c.mounted) Navigator.pop(c, true);
                  } else {
                    setState(() => error = lock.kind == LockKind.pin ? l.wrongPin : l.wrongPassword);
                  }
                },
                child: Text(l.ok),
              ),
            ],
          ),
        );
      },
    );
    field.dispose();
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        if (!lock.enabled) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_open_outlined),
            title: Text(l.appLock),
            subtitle: Text(l.appLockOffHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SetUpLockScreen(lock: lock, deviceAuth: deviceAuth))),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: Text(l.appLock),
            subtitle: Text(lock.kind == LockKind.pin ? l.appLockOnPin : l.appLockOnPassword),
          ),
          FutureBuilder(
            future: deviceAuth.hasBiometrics(),
            builder: (context, snap) => snap.data == true
                ? SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.fingerprint),
                    title: Text(l.unlockWithFingerprint),
                    value: lock.biometrics,
                    onChanged: lock.setBiometrics,
                  )
                : const SizedBox.shrink(),
          ),
          DropdownButtonFormField<RelockAfter>(
            initialValue: lock.relockAfter,
            decoration: InputDecoration(labelText: l.lockAgainAfter),
            items: [
              DropdownMenuItem(value: RelockAfter.immediately, child: Text(l.relockImmediately)),
              DropdownMenuItem(value: RelockAfter.oneMinute, child: Text(l.relockMinutes(1))),
              DropdownMenuItem(value: RelockAfter.fiveMinutes, child: Text(l.relockMinutes(5))),
              DropdownMenuItem(value: RelockAfter.launchOnly, child: Text(l.relockLaunchOnly)),
            ],
            onChanged: (v) => lock.setRelockAfter(v!),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton.icon(
              onPressed: () async {
                if (!await _confirmCurrent(context) || !context.mounted) return;
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SetUpLockScreen(lock: lock, deviceAuth: deviceAuth)));
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.changePinOrHint),
            ),
            OutlinedButton.icon(onPressed: lock.lockNow, icon: const Icon(Icons.lock_outline), label: Text(l.lockNow)),
            TextButton(
              onPressed: () async {
                if (await _confirmCurrent(context)) await lock.disable();
              },
              child: Text(l.turnOffLock),
            ),
          ]),
          Text(l.appLockNote, style: t.bodySmall),
        ]);
      },
    );
  }
}
