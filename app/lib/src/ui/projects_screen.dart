import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import 'app_settings_screen.dart';
import 'project_screen.dart';
import 'theme.dart';
import 'url_import_dialog.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final projects = controller.projects;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => AppSettingsScreen(controller: controller))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newProject(context),
        icon: const Icon(Icons.add),
        label: const Text('New app'),
      ),
      body: projects.isEmpty && controller.brokenProjects.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final project in projects) ...[
                  _ProjectCard(controller: controller, project: project),
                  const SizedBox(height: 12),
                ],
                for (final broken in controller.brokenProjects)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text('Unreadable project: ${p.basename(broken.directory)}'),
                      subtitle: Text('${broken.error}'),
                    ),
                  ),
              ],
            ),
    );
  }
}

extension on ProjectsScreen {
  Future<void> _newProject(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: const Text('Website files (ZIP)'),
            subtitle: const Text('HTML, CSS, JavaScript and images bundled into the app. Works offline.'),
            onTap: () => Navigator.pop(c, 'zip'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Website URL'),
            subtitle: const Text('Wrap a live https website. Needs an internet connection.'),
            onTap: () => Navigator.pop(c, 'url'),
          ),
        ]),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'zip') {
      await importZip(context, controller);
    } else if (choice == 'url') {
      final id = await showDialog<String>(context: context, builder: (_) => UrlImportDialog(controller: controller));
      if (id != null && context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(controller: controller, projectId: id)));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.web_asset, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('No projects yet', style: t.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Turn a ZIP of your website (HTML, CSS, JavaScript, images) or a live https website '
              'into an Android app. Builds happen on this device.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.controller, required this.project});

  final AppController controller;
  final ProjectHandle project;

  @override
  Widget build(BuildContext context) {
    final m = project.manifest;
    final last = controller.store.buildHistory(project).firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    final icon = project.iconFile;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProjectScreen(controller: controller, projectId: m.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 48,
                  child: icon != null && File(icon).existsSync()
                      ? Image.file(File(icon), fit: BoxFit.cover)
                      : ColoredBox(color: scheme.primaryContainer, child: Icon(Icons.android, color: scheme.onPrimaryContainer)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(m.android.applicationId, style: monoStyle(context, size: 12), overflow: TextOverflow.ellipsis),
                    if (m.source.type == SourceType.url)
                      Text(Uri.parse(m.source.entry).host,
                          style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      controller.building.contains(m.id)
                          ? 'Building…'
                          : last == null
                              ? 'v${m.android.versionName} · not built yet'
                              : 'v${m.android.versionName} · last build ${last.status} ${_ago(last.time)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// Picks a ZIP, asks for name and package ID, imports it, and opens the project.
Future<void> importZip(BuildContext context, AppController controller) async {
  final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
  if (picked.isEmpty || !context.mounted) return;
  final file = picked.single;
  final tmp = Directory.systemTemp.createTempSync('import');
  try {
    final zipPath = p.join(tmp.path, 'site.zip');
    await file.xFile.saveTo(zipPath);
    if (!context.mounted) return;
    final baseName = p.basenameWithoutExtension(file.name).replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final details = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _ImportDialog(initialName: baseName.isEmpty ? 'My App' : baseName),
    );
    if (details == null || !context.mounted) return;
    final ImportReport report;
    try {
      report = await controller.importZip(zipPath, details.$1, details.$2);
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(context: context, builder: (_) => _ImportSummary(report: report));
    if (!context.mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProjectScreen(controller: controller, projectId: report.project.manifest.id)));
  } finally {
    tmp.deleteSync(recursive: true);
    await FilePicker.clearTemporaryFiles();
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.initialName});

  final String initialName;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _id = TextEditingController(text: suggestApplicationId(widget.initialName));
  bool _idEdited = false;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New app'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'App name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
              onChanged: (v) {
                if (!_idEdited) _id.text = suggestApplicationId(v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _id,
              decoration: const InputDecoration(
                labelText: 'Package ID',
                helperText: 'Unique ID on the device and in Play, e.g. com.yourname.app',
                helperMaxLines: 2,
              ),
              style: monoStyle(context, size: 14),
              autocorrect: false,
              validator: (v) => validateApplicationId((v ?? '').trim()),
              onChanged: (_) => _idEdited = true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) Navigator.pop(context, (_name.text.trim(), _id.text.trim()));
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.report});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final missing = report.missingAssets;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imported ${report.fileCount} files', style: t.titleLarge),
            const SizedBox(height: 12),
            Text('Start page: ${report.project.manifest.source.entry}'),
            if (report.entryCandidates.length > 1)
              Text('${report.entryCandidates.length} HTML pages found; you can change the start page in Settings.'),
            const SizedBox(height: 12),
            if (missing.isEmpty)
              const Row(children: [Icon(Icons.check_circle_outline, size: 18), SizedBox(width: 8), Text('No missing files found')])
            else ...[
              Text('${missing.length} referenced files are missing:', style: t.titleSmall),
              const SizedBox(height: 4),
              for (final m in missing.take(8)) Text('• $m', style: monoStyle(context, size: 12)),
              if (missing.length > 8) Text('…and ${missing.length - 8} more'),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Open project')),
            ),
          ],
        ),
      ),
    );
  }
}
