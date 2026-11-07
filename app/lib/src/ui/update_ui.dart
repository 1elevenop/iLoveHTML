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
  const NewUpdateTile({super.key, required this.updates, required this.settings});

  final UpdateChecker updates;
  final AppSettings settings;

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
            onTap: () => showUpdateDialog(context, updates),
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

Future<void> showUpdateDialog(BuildContext context, UpdateChecker updates) {
  final info = updates.available;
  if (info == null) return Future.value();
  return showDialog<void>(context: context, builder: (_) => _UpdateDialog(info: info, current: updates.currentVersion));
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.info, required this.current});

  final UpdateInfo info;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final direct = info.downloadUrl != info.pageUrl;
    final howTo = Platform.isAndroid ? l.updateAndroidHint : (Platform.isWindows ? l.updateWindowsHint : null);
    return AlertDialog(
      title: Text(l.updateTitle(info.version)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420, maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (current != null) Text(l.youHaveVersion(current!), style: t.bodySmall),
            if (howTo != null && direct) ...[
              const SizedBox(height: 8),
              Text(howTo, style: t.bodyMedium),
            ],
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l.whatsNew, style: t.titleSmall),
              const SizedBox(height: 6),
              SelectableText(info.notes, style: monoStyle(context, size: 11.5)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.later)),
        TextButton(onPressed: () => openExternal(context, info.pageUrl), child: Text(l.releasePage)),
        FilledButton.icon(
          onPressed: () {
            openExternal(context, info.downloadUrl);
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
