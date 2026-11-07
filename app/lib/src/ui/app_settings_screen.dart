import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart' show formatBytes;
import 'package:package_info_plus/package_info_plus.dart';

import '../app_controller.dart';
import '../app_settings.dart';
import 'about_screens.dart';
import 'lock_screens.dart';
import 'update_ui.dart';
import 'l10n.dart';
import 'signing_keys_screen.dart';
import 'theme.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final Future<Map<String, Object?>> _engineInfo =
      widget.controller.deviceEngine?.info() ?? Future.value(widget.controller.desktopEngine?.info() ?? const {});
  late final int _storage = widget.controller.storageBytes();
  late final Future<PackageInfo?> _package = PackageInfo.fromPlatform().then<PackageInfo?>((i) => i, onError: (_) => null);

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.settings;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([c, s, c.updates]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NewUpdateTile(updates: c.updates, settings: s),
            Text(l.sectionAppearance, style: t.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem), icon: const Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.light), icon: const Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.dark), icon: const Icon(Icons.dark_mode_outlined)),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => s.themeMode = v.single,
            ),
            const SizedBox(height: 12),
            Text(l.accentColour, style: t.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final a in AccentPreset.values) _AccentSwatch(accent: a, settings: s)],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.animations),
              subtitle: Text(l.animationsHint),
              value: s.animations,
              onChanged: (v) => s.animations = v,
            ),
            const SizedBox(height: 16),
            Text(l.language, style: t.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.translate),
              title: Text(s.locale == null ? l.languageSystem : AppSettings.languageNames[s.locale!.languageCode]!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, s),
            ),
            const SizedBox(height: 16),
            Text(l.sectionSecurity, style: t.titleSmall),
            AppLockSettings(lock: c.lock),
            const SizedBox(height: 16),
            if (c.keys != null) ...[
              Text(l.signing, style: t.titleSmall),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.vpn_key_outlined),
                title: Text(l.releaseKeys),
                subtitle: Text(l.releaseKeysSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SigningKeysScreen(keys: c.keys!))),
              ),
              const SizedBox(height: 16),
            ],
            Text(l.storage, style: t.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.projectsAndSize(c.projects.length, formatBytes(_storage))),
              subtitle: Text(c.workspaceDir, style: monoStyle(context, size: 11)),
            ),
            const SizedBox(height: 8),
            Text(l.buildEngine, style: t.titleSmall),
            FutureBuilder(
              future: _engineInfo,
              builder: (context, snap) {
                if (c.engine == null) {
                  return ListTile(contentPadding: EdgeInsets.zero, title: Text(l.notAvailablePlatform));
                }
                final i = snap.data;
                if (i == null) return const LinearProgressIndicator();
                if (c.desktopEngine case final desktop?) {
                  final problems = desktop.problems;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(problems.isEmpty ? l.gradleReady : l.gradleNotReady),
                    subtitle: Text(problems.isEmpty
                        ? 'JDK: ${i['javaHome']}\nAndroid SDK: ${i['androidSdk']}\n${l.buildsRunOnPc}'
                        : problems.join('\n')),
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(i['baseAvailable'] == true ? l.onDeviceReady : l.onDeviceMissing),
                  subtitle: Text('${i['device']} · Android ${i['android']} (API ${i['sdkInt']}) · ${i['abi']}\n'
                      '${l.buildsRunOnDevice}'),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(l.about, style: t.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l.howToUse),
              subtitle: Text(l.howToUseSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HowToUseScreen())),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel_outlined),
              title: Text(l.termsOfUse),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => LegalScreen(title: l.termsOfUse, body: l.termsBody))),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l.privacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => LegalScreen(title: l.privacyPolicy, body: l.privacyBody))),
            ),
            FutureBuilder(
              future: _package,
              builder: (context, snap) {
                final info = snap.data;
                final version = info == null ? '…' : 'iLoveHTML ${info.version} (${info.buildNumber})';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.version),
                  subtitle: Text(version, style: monoStyle(context, size: 12)),
                  onLongPress: info == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: version));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.versionCopied)));
                        },
                );
              },
            ),
            UpdateSettings(updates: c.updates, settings: s),
            const SizedBox(height: 8),
            const CreditCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, AppSettings s) async {
    final l = context.l10n;
    // '' stands for "follow the system".
    final picked = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(l.language),
        children: [
          for (final code in ['', ...AppSettings.languageNames.keys])
            ListTile(
              title: Text(code.isEmpty ? l.languageSystem : AppSettings.languageNames[code]!),
              trailing: (s.locale?.languageCode ?? '') == code ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, code),
            ),
        ],
      ),
    );
    if (picked == null) return;
    s.locale = picked.isEmpty ? null : Locale(picked);
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({required this.accent, required this.settings});

  final AccentPreset accent;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colour = dark ? accent.dark : accent.light;
    final selected = settings.accent == accent;
    final e = context.eleven;
    return Semantics(
      selected: selected,
      button: true,
      label: _accentName(context, accent),
      child: Tooltip(
        message: _accentName(context, accent),
        child: InkWell(
          onTap: () => settings.accent = accent,
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: settings.animations ? const Duration(milliseconds: 200) : Duration.zero,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? e.fg : e.line2, width: selected ? 2 : 1),
            ),
            child: selected ? Icon(Icons.check, color: dark ? accent.darkOn : Colors.white, size: 20) : null,
          ),
        ),
      ),
    );
  }
}

String _accentName(BuildContext context, AccentPreset a) {
  final l = context.l10n;
  return switch (a) {
    AccentPreset.orange => l.accentOrange,
    AccentPreset.green => l.accentGreen,
    AccentPreset.cyan => l.accentCyan,
    AccentPreset.violet => l.accentViolet,
    AccentPreset.pink => l.accentPink,
  };
}
