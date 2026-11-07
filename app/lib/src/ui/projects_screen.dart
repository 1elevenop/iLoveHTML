import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import '../app_settings.dart';
import 'ascii.dart';
import 'app_settings_screen.dart';
import 'project_screen.dart';
import 'l10n.dart';
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
        title: Text(context.l10n.projects),
        actions: [
          IconButton(
            tooltip: context.l10n.restoreBackup,
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: () => restoreBackup(context, controller),
          ),
          IconButton(
            tooltip: context.l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => AppSettingsScreen(controller: controller))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newProject(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newApp),
      ),
      body: projects.isEmpty && controller.brokenProjects.isEmpty
          ? _EmptyState(
              buildsWindowsApps: controller.desktopEngine != null,
              animate: animationsOn(context, controller.settings),
            )
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
                      title: Text(context.l10n.unreadableProject(p.basename(broken.directory))),
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
            leading: const Icon(Icons.html),
            title: Text(context.l10n.htmlFiles),
            subtitle: Text(context.l10n.htmlFilesHint),
            onTap: () => Navigator.pop(c, 'files'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: Text(context.l10n.websiteZip),
            subtitle: Text(context.l10n.websiteZipHint),
            onTap: () => Navigator.pop(c, 'zip'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.l10n.websiteUrl),
            subtitle: Text(context.l10n.websiteUrlHint),
            onTap: () => Navigator.pop(c, 'url'),
          ),
        ]),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'files') {
      await importHtmlFiles(context, controller);
    } else if (choice == 'zip') {
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
  const _EmptyState({required this.buildsWindowsApps, required this.animate});

  final bool animate;

  /// On Windows, projects also build Windows apps (.exe and .msix).
  final bool buildsWindowsApps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AsciiEmptyArt(animate: animate),
            const SizedBox(height: 16),
            Text(context.l10n.noProjectsYet, style: t.titleLarge),
            const SizedBox(height: 8),
            Text(
              buildsWindowsApps ? context.l10n.emptyHintWindows : context.l10n.emptyHintAndroid,
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
                          ? context.l10n.building
                          : last == null
                              ? context.l10n.notBuiltYet(m.android.versionName)
                              : context.l10n.lastBuild(m.android.versionName, last.status, _ago(context, last.time)),
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

String _ago(BuildContext context, DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return context.l10n.justNow;
  if (d.inHours < 1) return context.l10n.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return context.l10n.hoursAgo(d.inHours);
  return context.l10n.daysAgo(d.inDays);
}

/// Picks a .ilovehtml backup, restores it as a new project and opens it.
Future<void> restoreBackup(BuildContext context, AppController controller) async {
  // FileType.any: Android has no MIME type for .ilovehtml.
  final file = await FilePicker.pickFile();
  if (file == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  if (!file.name.toLowerCase().endsWith(backupExtension)) {
    messenger.showSnackBar(SnackBar(content: Text(l.chooseBackupFile(backupExtension))));
    return;
  }
  final tmp = Directory.systemTemp.createTempSync('restore');
  try {
    final path = p.join(tmp.path, 'backup$backupExtension');
    await file.xFile.saveTo(path);
    final project = await controller.restoreBackup(path);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l.restored(project.manifest.name))));
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProjectScreen(controller: controller, projectId: project.manifest.id)));
  } on Object catch (e) {
    final text = switch (e) {
      ArchiveRejectedException(:final message) => l.notUsableBackup(message),
      InvalidProjectException(:final issues) => issues.join('\n'),
      _ => l.restoreFailed('$e'),
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// Picks a ZIP, asks for name and package ID, imports it, and opens the project.
Future<void> importZip(BuildContext context, AppController controller) async {
  final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['zip']);
  if (file == null || !context.mounted) return;
  await _importFlow(context, controller, [file], (dir, paths, name, id) => controller.importZip(paths.single, name, id));
}

/// Picks one or more website files (an .html page plus, optionally, CSS,
/// JavaScript, images, fonts), asks for name and package ID, and imports them.
Future<void> importHtmlFiles(BuildContext context, AppController controller) async {
  // FileType.any: Android's MIME filters miss common web types such as .js and .woff2.
  final files = await FilePicker.pickFiles();
  if (files.isEmpty || !context.mounted) return;
  if (!files.any((f) => RegExp(r'\.html?$', caseSensitive: false).hasMatch(f.name))) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectHtmlFile)));
    await FilePicker.clearTemporaryFiles();
    return;
  }
  await _importFlow(context, controller, files, (dir, paths, name, id) => controller.importFiles(paths, name, id));
}

Future<void> _importFlow(
  BuildContext context,
  AppController controller,
  List<PlatformFile> files,
  Future<ImportReport> Function(String dir, List<String> paths, String name, String id) run,
) async {
  final tmp = Directory.systemTemp.createTempSync('import');
  try {
    final paths = <String>[];
    for (final f in files) {
      // Keep the original names: they decide where linked files end up.
      final target = p.join(tmp.path, p.basename(f.name));
      await f.xFile.saveTo(target);
      paths.add(target);
    }
    if (!context.mounted) return;
    final main = files.firstWhere((f) => RegExp(r'\.(zip|html?)$', caseSensitive: false).hasMatch(f.name),
        orElse: () => files.first);
    var baseName = p.basenameWithoutExtension(main.name).replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (baseName.toLowerCase() == 'index') baseName = '';
    final details = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _ImportDialog(initialName: baseName.isEmpty ? context.l10n.defaultAppName : baseName),
    );
    if (details == null || !context.mounted) return;
    final ImportReport report;
    try {
      report = await run(tmp.path, paths, details.$1, details.$2);
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.importFailed('$e'))));
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
      title: Text(context.l10n.newApp),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.appName),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.enterName : null,
              onChanged: (v) {
                if (!_idEdited) _id.text = suggestApplicationId(v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _id,
              decoration: InputDecoration(
                labelText: context.l10n.packageId,
                helperText: context.l10n.packageIdHelp,
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
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) Navigator.pop(context, (_name.text.trim(), _id.text.trim()));
          },
          child: Text(context.l10n.importButton),
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
            Text(context.l10n.importedFiles(report.fileCount), style: t.titleLarge),
            const SizedBox(height: 12),
            Text(context.l10n.startPageIs(report.project.manifest.source.entry)),
            if (report.entryCandidates.length > 1)
              Text(context.l10n.htmlPagesFound(report.entryCandidates.length)),
            const SizedBox(height: 12),
            if (missing.isEmpty)
              Row(children: [Icon(Icons.check_circle_outline, size: 18), SizedBox(width: 8), Text(context.l10n.noMissingFiles)])
            else ...[
              Text(context.l10n.filesMissing(missing.length), style: t.titleSmall),
              const SizedBox(height: 4),
              for (final m in missing.take(8)) Text('• $m', style: monoStyle(context, size: 12)),
              if (missing.length > 8) Text(context.l10n.andMore(missing.length - 8)),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.openProject)),
            ),
          ],
        ),
      ),
    );
  }
}
