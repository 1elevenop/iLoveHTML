import 'dart:io';

import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../update_check.dart';
import 'about_screens.dart';
import 'l10n.dart';
import 'theme.dart';

/// A slow accent glow around [child]; steady when animations are off.
class Glow extends StatefulWidget {
  const Glow({super.key, required this.child, required this.animate, this.radius = 4});

  final Widget child;
  final bool animate;
  final double radius;

  @override
  State<Glow> createState() => _GlowState();
}

class _GlowState extends State<Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(Glow old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = widget.animate ? Curves.easeInOut.transform(_c.value) : 0.6;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(color: e.acc.withValues(alpha: 0.35 + 0.45 * t), blurRadius: 6 + 10 * t),
              BoxShadow(color: e.acc.withValues(alpha: 0.12 + 0.2 * t), blurRadius: 18 + 18 * t),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// The glowing "NEW UPDATE" entry at the top of Settings.
class NewUpdateTile extends StatelessWidget {
  const NewUpdateTile({super.key, required this.updates, required this.settings, this.installer});

  final UpdateChecker updates;
  final AppSettings settings;

  /// Android: download and install inside the app.
  final UpdateInstaller? installer;

  @override
  Widget build(BuildContext context) {
    final info = updates.available;
    if (info == null) return const SizedBox.shrink();
    final l = context.l10n;
    final e = context.eleven;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Glow(
        animate: animationsOn(context, settings),
        child: Material(
          color: e.panel,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: e.acc, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showUpdateDialog(context, updates, installer: installer),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.system_update_alt, color: e.acc, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.newUpdate,
                        style: t.titleMedium?.copyWith(color: e.acc, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    const SizedBox(height: 2),
                    Text(l.updateAvailable(info.version), style: t.bodyMedium),
                  ]),
                ),
                Icon(Icons.chevron_right, color: e.acc),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small glowing dot on the Settings button while an update waits.
class UpdateDot extends StatelessWidget {
  const UpdateDot({super.key, required this.updates, required this.settings, required this.child});

  final UpdateChecker updates;
  final AppSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        if (updates.available == null) return child;
        return Stack(clipBehavior: Clip.none, children: [
          child,
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Glow(
                animate: animationsOn(context, settings),
                radius: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: context.eleven.acc, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Where to put a downloaded update APK and how to hand it to Android's installer.
class UpdateInstaller {
  const UpdateInstaller({required this.dir, required this.install});

  final String dir;

  /// Opens the system installer; false when the user must first allow
  /// installs from iLoveHTML (the settings page is opened for them).
  final Future<bool> Function(String apkPath) install;
}

Future<void> showUpdateDialog(BuildContext context, UpdateChecker updates, {UpdateInstaller? installer}) {
  final info = updates.available;
  if (info == null) return Future.value();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(info: info, current: updates.currentVersion, installer: installer),
  );
}

enum _Step { ready, downloading, checking, installing, needsPermission, failed }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info, required this.current, required this.installer});

  final UpdateInfo info;
  final String? current;
  final UpdateInstaller? installer;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  _Step _step = _Step.ready;
  int _received = 0;
  int? _total;
  String? _error;
  String? _apk;

  UpdateInfo get _info => widget.info;
  bool get _direct => _info.downloadUrl != _info.pageUrl;

  /// Android: fetch the APK here instead of in a browser, which would hold
  /// it behind a "File might be harmful" prompt.
  bool get _inApp => widget.installer != null && _direct;
  bool get _working => _step == _Step.downloading || _step == _Step.checking;

  Future<void> _download() async {
    setState(() {
      _step = _Step.downloading;
      _error = null;
      _received = 0;
      _total = null;
    });
    try {
      final path = await downloadUpdate(_info, widget.installer!.dir, onProgress: (r, t) {
        if (!mounted) return;
        // Repaint about every 256 KB, and at the end.
        if (r - _received < 256 * 1024 && r != t) return;
        setState(() {
          _received = r;
          _total = t;
          if (t != null && r == t) _step = _Step.checking;
        });
      });
      if (!mounted) return;
      _apk = path;
      await _install();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _error = '$e';
      });
    }
  }

  Future<void> _install() async {
    final apk = _apk;
    if (apk == null) return;
    final started = await widget.installer!.install(apk);
    if (!mounted) return;
    setState(() => _step = started ? _Step.installing : _Step.needsPermission);
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final howTo = _inApp ? l.updateInAppHint : (Platform.isWindows ? l.updateWindowsHint : null);
    final progress = _total == null || _total == 0 ? null : _received / _total!;
    return AlertDialog(
      title: Text(l.updateTitle(_info.version)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440, maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.current != null) Text(l.youHaveVersion(widget.current!), style: t.bodySmall),
            if (howTo != null && _direct && _step == _Step.ready) ...[
              const SizedBox(height: 8),
              Text(howTo, style: t.bodyMedium),
            ],
            if (_working) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _step == _Step.checking ? null : progress),
              const SizedBox(height: 6),
              Text(
                _step == _Step.checking
                    ? l.verifyingDownload
                    : (_total == null
                        ? l.downloadingMb(_mb(_received))
                        : l.downloadingOf(_mb(_received), _mb(_total!))),
                style: t.bodySmall,
              ),
            ],
            if (_step == _Step.installing) ...[
              const SizedBox(height: 16),
              Text(l.installerOpened, style: t.bodyMedium),
            ],
            if (_step == _Step.needsPermission) ...[
              const SizedBox(height: 16),
              Text(l.allowUnknownApps, style: t.bodyMedium),
            ],
            if (_step == _Step.failed) ...[
              const SizedBox(height: 16),
              Text(l.downloadFailed(_error ?? ''), style: t.bodyMedium?.copyWith(color: context.eleven.acc)),
            ],
            if (_info.notes.isNotEmpty && (_step == _Step.ready || _step == _Step.failed)) ...[
              const SizedBox(height: 16),
              Text(l.whatsNew, style: t.titleSmall),
              const SizedBox(height: 6),
              SelectableText(_info.notes, style: monoStyle(context, size: 11.5)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.pop(context),
          child: Text(_step == _Step.installing ? l.close : l.later),
        ),
        if (!_inApp || _step == _Step.failed)
          TextButton(
            onPressed: () {
              openExternal(context, _inApp ? _info.pageUrl : _info.downloadUrl);
              Navigator.pop(context);
            },
            child: Text(_inApp ? l.openInBrowser : l.releasePage),
          ),
        if (_inApp && (_step == _Step.ready || _step == _Step.failed))
          FilledButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download),
            label: Text(_step == _Step.failed ? l.tryAgain : l.downloadUpdate),
          ),
        if (_inApp && (_step == _Step.needsPermission || _step == _Step.installing))
          FilledButton.icon(onPressed: _install, icon: const Icon(Icons.install_mobile), label: Text(l.install)),
        if (!_inApp)
          FilledButton.icon(
            onPressed: () {
              openExternal(context, _info.downloadUrl);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.download),
            label: Text(l.downloadUpdate),
          ),
      ],
    );
  }
}

/// "Check for updates" switch and "Check now" in Settings → About.
class UpdateSettings extends StatelessWidget {
  const UpdateSettings({super.key, required this.updates, required this.settings});

  final UpdateChecker updates;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([updates, settings]),
      builder: (context, _) {
        final status = switch (updates.state) {
          UpdateCheckState.checking => l.checkingUpdates,
          UpdateCheckState.upToDate => l.upToDate,
          UpdateCheckState.failed => l.updateCheckFailed,
          UpdateCheckState.idle => updates.available != null ? l.updateAvailable(updates.available!.version) : null,
        };
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.update),
            title: Text(l.checkForUpdates),
            subtitle: Text(l.checkForUpdatesHint),
            value: settings.checkUpdates,
            onChanged: (v) {
              settings.checkUpdates = v;
              v ? updates.checkNow() : updates.clear();
            },
          ),
          Row(children: [
            OutlinedButton.icon(
              onPressed: updates.state == UpdateCheckState.checking ? null : updates.checkNow,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.checkNow),
            ),
            const SizedBox(width: 12),
            if (status != null) Expanded(child: Text(status, style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ]);
      },
    );
  }
}
