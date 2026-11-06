import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart' show formatBytes;

import '../app_controller.dart';
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
            if (c.keys != null) ...[
              Text('Signing', style: t.titleSmall),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.vpn_key_outlined),
                title: const Text('Release keys'),
                subtitle: const Text('Create, import and back up the keys that sign your releases'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SigningKeysScreen(keys: c.keys!))),
              ),
              const SizedBox(height: 16),
            ],
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
                if (c.desktopEngine case final desktop?) {
                  final problems = desktop.problems;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(problems.isEmpty ? 'Gradle on this PC (ready)' : 'Gradle on this PC: not ready'),
                    subtitle: Text(problems.isEmpty
                        ? 'JDK: ${i['javaHome']}\nAndroid SDK: ${i['androidSdk']}\n'
                            'Builds run entirely on this PC. No files are uploaded.'
                        : problems.join('\n')),
                  );
                }
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
