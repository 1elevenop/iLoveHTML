import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import 'preview_screen.dart';
import 'theme.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key, required this.controller, required this.projectId});

  final AppController controller;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final project = controller.project(projectId);
        if (project == null) return const Scaffold(body: Center(child: Text('Project not found')));
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(project.manifest.name, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Preview',
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => PreviewScreen(project: controller.project(projectId)!))),
                ),
              ],
              bottom: const TabBar(tabs: [
                Tab(icon: Icon(Icons.tune), text: 'Settings'),
                Tab(icon: Icon(Icons.build_outlined), text: 'Build'),
              ]),
            ),
            body: TabBarView(children: [
              _SettingsTab(key: ValueKey('settings-$projectId'), controller: controller, project: project),
              _BuildTab(controller: controller, project: project),
            ]),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Settings

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({super.key, required this.controller, required this.project});

  final AppController controller;
  final ProjectHandle project;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> with AutomaticKeepAliveClientMixin {
  final _form = GlobalKey<FormState>();
  late ProjectManifest _m = widget.project.manifest;
  late final _name = TextEditingController(text: _m.name);
  late final _id = TextEditingController(text: _m.android.applicationId);
  late final _versionName = TextEditingController(text: _m.android.versionName);
  late final _versionCode = TextEditingController(text: '${_m.android.versionCode}');
  late final _ua = TextEditingController(text: _m.webView.userAgentSuffix ?? '');
  late final _siteUrl = TextEditingController(text: _m.source.type == SourceType.url ? _m.source.entry : '');
  late final _hosts = TextEditingController(text: _m.webView.allowedHosts.join(', '));
  late final List<String> _pages = findEntryCandidates(listRelativeFiles(widget.project.sourceDir));
  bool _dirty = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_name, _id, _versionName, _versionCode, _ua, _siteUrl, _hosts]) {
      c.dispose();
    }
    super.dispose();
  }

  void _change(ProjectManifest m) => setState(() {
        _m = m;
        _dirty = true;
      });

  void _save() {
    if (!_form.currentState!.validate()) return;
    final ua = _ua.text.trim();
    final m = _m.copyWith(
      name: _name.text.trim(),
      source: _m.source.type == SourceType.url ? ProjectSource.url(_siteUrl.text.trim()) : null,
      android: AndroidSettings(
        applicationId: _id.text.trim(),
        versionName: _versionName.text.trim(),
        versionCode: int.parse(_versionCode.text.trim()),
      ),
      webView: _m.webView.copyWith(
        userAgentSuffix: () => ua.isEmpty ? null : ua,
        allowedHosts: _parseHosts(_hosts.text),
      ),
    );
    try {
      final saved = widget.controller.update(widget.controller.project(m.id)!, m);
      setState(() {
        _m = saved.manifest;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } on InvalidProjectException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.issues.join('\n'))));
    }
  }

  Future<void> _pickIcon() async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['png']);
    if (picked.isEmpty) return;
    final tmp = Directory.systemTemp.createTempSync('icon');
    try {
      final path = p.join(tmp.path, 'icon.png');
      await picked.single.xFile.saveTo(path);
      widget.controller.setIcon(widget.controller.project(_m.id)!, path);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Icon updated')));
    } on InvalidProjectException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.issues.join('\n'))));
    } finally {
      tmp.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('This deletes "${_m.name}", its website files and built APKs from this device. '
            'Apps already installed are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    widget.controller.delete(widget.controller.project(_m.id)!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final icon = widget.controller.project(_m.id)?.iconFile;
    final local = _m.source.type == SourceType.local;
    return Scaffold(
      floatingActionButton: _dirty
          ? FloatingActionButton.extended(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save'))
          : null,
      body: Form(
        key: _form,
        onChanged: () => setState(() => _dirty = true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const _Section('App'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'App name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _id,
              decoration: const InputDecoration(labelText: 'Package ID'),
              style: monoStyle(context, size: 14),
              autocorrect: false,
              validator: (v) => validateApplicationId((v ?? '').trim()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _versionName,
                  decoration: const InputDecoration(labelText: 'Version name'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _versionCode,
                  decoration: const InputDecoration(labelText: 'Version code'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n < 1 || n > maxVersionCode ? '1 – $maxVersionCode' : null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 64,
                  child: icon != null && File(icon).existsSync()
                      ? Image.file(File(icon), fit: BoxFit.cover, key: ValueKey(File(icon).lastModifiedSync()))
                      : ColoredBox(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.android, size: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(icon == null ? 'Default icon' : 'Custom icon', style: Theme.of(context).textTheme.bodyMedium)),
              OutlinedButton.icon(onPressed: _pickIcon, icon: const Icon(Icons.image_outlined), label: const Text('Choose PNG')),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Square PNG, at least 48 px; 512 × 512 recommended.', style: Theme.of(context).textTheme.bodySmall),
            ),
            const _Section('Content'),
            if (local)
              DropdownButtonFormField<String>(
                initialValue: _pages.contains(_m.source.entry) ? _m.source.entry : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Start page'),
                items: [for (final page in _pages) DropdownMenuItem(value: page, child: Text(page, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => _change(_m.copyWith(source: ProjectSource.local(v!))),
              )
            else ...[
              TextFormField(
                controller: _siteUrl,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  helperText: 'Loaded live; the app needs an internet connection.',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: monoStyle(context, size: 14),
                validator: (v) => validateRemoteUrl((v ?? '').trim()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hosts,
                decoration: const InputDecoration(
                  labelText: 'Other sites that open inside the app (optional)',
                  hintText: 'login.example.com, cdn.example.com',
                  helperText: 'Comma-separated. Links to any other site open in the browser.',
                  helperMaxLines: 2,
                ),
                autocorrect: false,
                validator: (v) {
                  for (final h in _parseHosts(v ?? '')) {
                    if (validateRemoteUrl('https://$h/') != null || h.contains('/')) return 'Invalid host "$h"';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            Text('Orientation', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<Orientation>(
              segments: const [
                ButtonSegment(value: Orientation.unspecified, label: Text('Auto')),
                ButtonSegment(value: Orientation.portrait, label: Text('Portrait')),
                ButtonSegment(value: Orientation.landscape, label: Text('Landscape')),
              ],
              selected: {_m.orientation},
              onSelectionChanged: (s) => _change(_m.copyWith(orientation: s.single)),
            ),
            const _Section('WebView'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('JavaScript'),
              subtitle: const Text('Most sites need this. Turn off for static pages.'),
              value: _m.webView.javaScriptEnabled,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(javaScriptEnabled: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Local storage'),
              subtitle: const Text('localStorage and sessionStorage'),
              value: _m.webView.domStorageEnabled,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(domStorageEnabled: v))),
            ),
            if (local)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Internet access'),
                subtitle: const Text('Adds the INTERNET permission, for CDNs, APIs or fonts loaded from the web.'),
                value: _m.internetAccess,
                onChanged: (v) => _change(_m.copyWith(internetAccess: v)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open other sites in the browser'),
              subtitle: const Text('When off, links to other sites do nothing.'),
              value: _m.webView.externalLinks == ExternalLinkPolicy.browser,
              onChanged: (v) => _change(_m.copyWith(
                  webView: _m.webView.copyWith(externalLinks: v ? ExternalLinkPolicy.browser : ExternalLinkPolicy.block))),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ua,
              decoration: const InputDecoration(labelText: 'User agent suffix (optional)', hintText: 'e.g. MyApp/1.0'),
              validator: (v) => (v ?? '').length > 200 ? 'At most 200 characters' : null,
            ),
            const _Section('Danger zone'),
            OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete project'),
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _parseHosts(String text) => text
    .split(RegExp(r'[,\s]+'))
    .map((h) => h.trim().toLowerCase())
    .where((h) => h.isNotEmpty)
    .toSet()
    .toList();

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary, letterSpacing: 1.1)),
      );
}

// ---------------------------------------------------------------- Build

class _BuildTab extends StatefulWidget {
  const _BuildTab({required this.controller, required this.project});

  final AppController controller;
  final ProjectHandle project;

  @override
  State<_BuildTab> createState() => _BuildTabState();
}

class _BuildTabState extends State<_BuildTab> with AutomaticKeepAliveClientMixin {
  final List<String> _log = [];
  BuildResult? _result;

  @override
  bool get wantKeepAlive => true;

  bool get _building => widget.controller.building.contains(widget.project.manifest.id);

  Future<void> _build() async {
    setState(() {
      _log.clear();
      _result = null;
    });
    final result = await widget.controller.build(widget.project, (line) {
      if (mounted) setState(() => _log.add(line));
    });
    if (mounted) setState(() => _result = result);
  }

  Future<void> _install(String path) async {
    final engine = widget.controller.engine!;
    try {
      if (!await engine.install(path) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Allow "Install unknown apps" for HTML2APK in the screen that opened, then tap Install again.'),
        ));
      }
    } on PlatformException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final m = widget.project.manifest;
    final history = widget.controller.store.buildHistory(widget.project);
    final latestApk = history.where((b) => b.succeeded && b.artifactPath != null).firstOrNull;
    final apkPath = _result?.artifactPath ?? latestApk?.artifactPath;
    final apkExists = apkPath != null && File(apkPath).existsSync();
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Debug APK', style: t.titleMedium),
                const SizedBox(height: 4),
                Text('${m.android.applicationId} · v${m.android.versionName} (${m.android.versionCode})',
                    style: monoStyle(context, size: 12)),
                const SizedBox(height: 4),
                Text('Built on this device and signed with a debug key kept in Android Keystore. '
                    'Release signing comes later.',
                    style: t.bodySmall),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _building || widget.controller.engine == null ? null : _build,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_building ? 'Building…' : 'Build APK'),
                ),
                if (widget.controller.engine == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Building is not available on this platform yet.', style: t.bodySmall),
                  ),
                if (_building) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
              ],
            ),
          ),
        ),
        if (_result != null && _result!.status != BuildStatus.succeeded) ...[
          const SizedBox(height: 12),
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
              title: Text('Build failed', style: TextStyle(color: scheme.onErrorContainer)),
              subtitle: Text(_result!.message ?? '', style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ),
        ],
        if (apkExists) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.check_circle, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.basename(apkPath), style: t.titleSmall, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text(formatBytes(File(apkPath).lengthSync()), style: t.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _install(apkPath),
                      icon: const Icon(Icons.install_mobile),
                      label: const Text('Install'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.controller.engine!.share(apkPath),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
        if (_log.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Build log', style: t.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(_log.join('\n'), style: monoStyle(context, size: 11.5)),
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('History', style: t.titleSmall),
          for (final b in history.take(10))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(b.succeeded ? Icons.check_circle_outline : Icons.highlight_off,
                  color: b.succeeded ? scheme.primary : scheme.error),
              title: Text('v${b.versionName ?? '?'} · ${b.status} · ${b.durationMs} ms'),
              subtitle: Text('${_fmtTime(b.time)}${b.bytes == null ? '' : ' · ${formatBytes(b.bytes!)}'}'
                  '${b.message == null ? '' : '\n${b.message}'}'),
            ),
        ],
      ],
    );
  }
}

String _fmtTime(DateTime t) {
  final l = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}
