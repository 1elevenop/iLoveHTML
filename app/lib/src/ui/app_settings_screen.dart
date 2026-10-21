import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'theme.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final Future<Map<String, Object?>> _engineInfo =
      widget.controller.engine?.info() ?? Future.value(const {});
  late final int _storage = widget.controller.storageBytes();

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Theme', style: t.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ],
              selected: {c.themeMode},
              onSelectionChanged: (s) => c.setThemeMode(s.single),
            ),
            const SizedBox(height: 24),
            Text('Storage', style: t.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${c.projects.length} projects · ${formatBytes(_storage)}'),
              subtitle: Text(c.workspaceDir, style: monoStyle(context, size: 11)),
            ),
            const SizedBox(height: 8),
            Text('Build engine', style: t.titleSmall),
            FutureBuilder(
              future: _engineInfo,
              builder: (context, snap) {
                if (c.engine == null) {
                  return const ListTile(contentPadding: EdgeInsets.zero, title: Text('Not available on this platform yet'));
                }
                final i = snap.data;
                if (i == null) return const LinearProgressIndicator();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(i['baseAvailable'] == true ? 'On-device assembly (ready)' : 'On-device assembly: base APK missing'),
                  subtitle: Text('${i['device']} · Android ${i['android']} (API ${i['sdkInt']}) · ${i['abi']}\n'
                      'Builds run entirely on this device. No files are uploaded.'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
