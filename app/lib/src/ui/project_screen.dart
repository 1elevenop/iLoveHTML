import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import '../engine/msix_builder.dart';
import '../engine/on_device_engine.dart';
import '../image_import.dart';
import '../app_settings.dart';
import 'ascii.dart';
import 'preview_screen.dart';
import 'signing_keys_screen.dart';
import 'l10n.dart';
import 'theme.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key, required this.controller, required this.projectId});

  final AppController controller;
  final String projectId;

  /// Saves the project as one .ilovehtml file the user can keep or move to another device.
  Future<void> _backUp(BuildContext context, ProjectHandle project) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      final path = await controller.backUp(project);
      final where = await (controller.desktopEngine?.saveFile(path) ?? controller.deviceEngine?.saveFile(path));
      if (where != null) messenger.showSnackBar(SnackBar(content: Text(l.backupSaved(p.basename(path)))));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.backupFailed('${e is PlatformException ? e.message : e}'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final project = controller.project(projectId);
        if (project == null) return Scaffold(body: Center(child: Text(context.l10n.projectNotFound)));
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(project.manifest.name, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: context.l10n.backUpProject,
                  icon: const Icon(Icons.backup_outlined),
                  onPressed: () => _backUp(context, controller.project(projectId)!),
                ),
                IconButton(
                  tooltip: context.l10n.preview,
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => Platform.isWindows
                      ? _browserPreview(context, controller.project(projectId)!)
                      : Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PreviewScreen(project: controller.project(projectId)!))),
                ),
              ],
              bottom: TabBar(tabs: [
                Tab(icon: Icon(Icons.tune), text: context.l10n.settings),
                Tab(icon: Icon(Icons.build_outlined), text: context.l10n.build),
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

/// Windows has no embedded WebView plugin here, so the preview opens in the
/// default browser. Local sites are served by the same loopback-only,
/// token-protected [PreviewServer] the phone uses; it stops when the dialog closes.
Future<void> _browserPreview(BuildContext context, ProjectHandle project) async {
  final m = project.manifest;
  PreviewServer? server;
  final Uri url;
  if (m.source.type == SourceType.local) {
    server = await PreviewServer.start(project.sourceDir);
    url = server.urlFor(m.source.entry);
  } else {
    // FileProtocolHandler would also run a file: path, so only checked https URLs get there.
    final error = validateRemoteUrl(m.source.entry);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    url = Uri.parse(m.source.entry);
  }
  final missing = <String>[];
  final sub = server?.onMissing.listen(missing.add);
  // rundll32 hands the URL to the default browser without a shell.
  await Process.start('rundll32.exe', ['url.dll,FileProtocolHandler', url.toString()]);
  if (!context.mounted) {
    await sub?.cancel();
    await server?.stop();
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) {
        sub?.onData((path) => setState(() => missing.add(path)));
        return AlertDialog(
          title: Text(context.l10n.previewInBrowser),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(url.toString(), style: monoStyle(c, size: 12)),
            const SizedBox(height: 12),
            Text(server == null
                ? context.l10n.liveSiteOpened
                : context.l10n.servedFromPc),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(context.l10n.missingFiles, style: Theme.of(c).textTheme.titleSmall),
              for (final f in missing.take(8)) Text(f, style: monoStyle(c, size: 12)),
            ],
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(server == null ? context.l10n.close : context.l10n.stopPreview))],
        );
      },
    ),
  );
  await sub?.cancel();
  await server?.stop();
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
  late final _galleryFolder = TextEditingController(text: _m.webView.galleryFolder ?? '');
  late final _shareTarget = TextEditingController(text: _m.webView.shareTarget ?? '');
  late final _siteUrl = TextEditingController(text: _m.source.type == SourceType.url ? _m.source.entry : '');
  late final _hosts = TextEditingController(text: _m.webView.allowedHosts.join(', '));
  late final _bridgeHosts = TextEditingController(text: _m.webView.bridgeHosts.join(', '));
  late final _statusColor = TextEditingController(text: _m.appearance.statusBarColor);
  late final _navColor = TextEditingController(text: _m.appearance.navigationBarColor);
  late final _splashColor = TextEditingController(text: _m.appearance.splashBackgroundColor);
  late List<String> _pages = findEntryCandidates(listRelativeFiles(widget.project.sourceDir));
  bool _dirty = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_name, _id, _versionName, _versionCode, _ua, _galleryFolder, _shareTarget, _siteUrl, _hosts, _bridgeHosts, _statusColor,
      _navColor, _splashColor]) {
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
    final folder = _galleryFolder.text.trim();
    final target = _shareTarget.text.trim();
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
        galleryFolder: () => folder.isEmpty ? null : folder,
        shareTarget: () => target.isEmpty ? null : target,
        allowedHosts: _parseHosts(_hosts.text),
        bridgeHosts: _parseHosts(_bridgeHosts.text),
      ),
      // Set by release builds, not by this form: always keep the stored value.
      releaseCertSha256: () => _current.manifest.releaseCertSha256,
      appearance: _m.appearance.copyWith(
        statusBarColor: _statusColor.text.trim().toUpperCase(),
        navigationBarColor: _navColor.text.trim().toUpperCase(),
        splashBackgroundColor: _splashColor.text.trim().toUpperCase(),
      ),
    );
    try {
      final saved = widget.controller.update(widget.controller.project(m.id)!, m);
      setState(() {
        _m = saved.manifest;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
    } on InvalidProjectException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.issues.join('\n'))));
    }
  }

  /// Icon, splash and offline page are saved immediately. Copy just those
  /// fields into the form's manifest so a later Save keeps them while still
  /// applying the user's other, unsaved edits.
  void _takeFileFields(ProjectHandle saved) {
    final s = saved.manifest;
    setState(() => _m = _m.copyWith(
          iconPath: s.iconPath,
          splashPath: () => s.splashPath,
          offlineFallbackPage: () => s.offlineFallbackPage,
        ));
  }

  ProjectHandle get _current => widget.controller.project(_m.id)!;

  /// Picks a new ZIP or HTML files and swaps them in for the website.
  Future<void> _replaceWebsite() async {
    final l = context.l10n;
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: Text(l.websiteZip),
            subtitle: Text(l.replaceWithZipHint),
            onTap: () => Navigator.pop(c, 'zip'),
          ),
          ListTile(
            leading: const Icon(Icons.html),
            title: Text(l.htmlFiles),
            subtitle: Text(l.replaceWithFilesHint),
            onTap: () => Navigator.pop(c, 'files'),
          ),
        ]),
      ),
    );
    if (kind == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.replaceWebsiteQ),
        content: Text(l.replaceWebsiteBody(_m.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.replace)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final picked = kind == 'zip'
        ? await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip'])
        // FileType.any: Android's MIME filters miss common web types such as .js and .woff2.
        : await FilePicker.pickFiles();
    if (picked.isEmpty || !mounted) return;
    if (kind == 'files' && !picked.any((f) => RegExp(r'\.html?$', caseSensitive: false).hasMatch(f.name))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.selectHtmlFile)));
      await FilePicker.clearTemporaryFiles();
      return;
    }
    final tmp = Directory.systemTemp.createTempSync('replace');
    try {
      final paths = <String>[];
      for (final f in picked) {
        // Keep the original names: they decide where linked files end up.
        final target = p.join(tmp.path, p.basename(f.name));
        await f.xFile.saveTo(target);
        paths.add(target);
      }
      final r = kind == 'zip'
          ? await widget.controller.replaceWithZip(_current, paths.single)
          : await widget.controller.replaceWithFiles(_current, paths);
      final s = r.import.project.manifest;
      if (!mounted) return;
      setState(() {
        _pages = findEntryCandidates(listRelativeFiles(r.import.project.sourceDir));
        _m = _m.copyWith(
          source: s.source,
          shortcuts: s.shortcuts,
          offlineFallbackPage: () => s.offlineFallbackPage,
        );
      });
      await showDialog<void>(context: context, builder: (_) => _ReplaceSummary(report: r));
    } on InvalidProjectException catch (e) {
      _report(e);
    } on Exception catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.replaceFailed('$e'))));
    } finally {
      tmp.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  Future<void> _addShortcut() async {
    final l = context.l10n;
    final shortcut = await showDialog<AppShortcut>(
      context: context,
      builder: (_) => _ShortcutDialog(type: _m.source.type, pages: _pages),
    );
    if (shortcut == null) return;
    if (_m.shortcuts.any((s) => s.page == shortcut.page)) {
      _report(l.shortcutExists(shortcut.page));
      return;
    }
    _change(_m.copyWith(shortcuts: [..._m.shortcuts, shortcut]));
  }

  void _report(Object e) {
    if (!mounted) return;
    final text = e is InvalidProjectException ? e.issues.join('\n') : '$e';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// [convert] turns the picked file's bytes into what [apply] expects.
  Future<void> _pickFile(List<String> extensions, ProjectHandle Function(String path) apply, String done,
      {Future<Uint8List> Function(Uint8List bytes, String extension)? convert}) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: extensions);
    if (picked.isEmpty) return;
    final tmp = Directory.systemTemp.createTempSync('pick');
    try {
      final path = p.join(tmp.path, 'picked.${extensions.first}');
      await picked.single.xFile.saveTo(path);
      if (convert != null) {
        final ext = p.extension(picked.single.name).toLowerCase().replaceFirst('.', '');
        File(path).writeAsBytesSync(await convert(File(path).readAsBytesSync(), ext));
      }
      final updated = apply(path);
      // The new file replaces the old one at the same path; drop the cached picture.
      for (final rel in [updated.manifest.iconPath, updated.manifest.splashPath]) {
        if (rel != null) await FileImage(File(p.join(updated.directory, rel))).evict();
      }
      _takeFileFields(updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on InvalidProjectException catch (e) {
      _report(e);
    } on ImageImportException catch (e) {
      _report(e);
    } finally {
      tmp.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  // Android needs PNG: other formats are converted, icons centred on a square.
  Future<void> _pickIcon() => _pickFile(
      pickableImageExtensions, (f) => widget.controller.setIcon(_current, f), context.l10n.iconUpdated,
      convert: (b, ext) => toPng(b, isSvg: ext == 'svg', square: true, maxSide: 1024));

  Future<void> _pickSplash() => _pickFile(
      pickableImageExtensions, (f) => widget.controller.setSplash(_current, f), context.l10n.splashUpdated,
      convert: (b, ext) => toPng(b, isSvg: ext == 'svg', maxSide: 1440));

  Future<void> _pickOfflinePage() =>
      _pickFile(['html', 'htm'], (f) => widget.controller.setOfflinePage(_current, f), context.l10n.offlinePageAdded);

  void _clearFile(ProjectHandle Function(ProjectHandle) clear) {
    try {
      _takeFileFields(clear(_current));
    } on InvalidProjectException catch (e) {
      _report(e);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.deleteProjectQ),
        content: Text(context.l10n.deleteProjectBody(_m.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.delete)),
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
          ? FloatingActionButton.extended(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(context.l10n.save))
          : null,
      body: Form(
        key: _form,
        onChanged: () => setState(() => _dirty = true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _Section(context.l10n.sectionApp),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.appName),
              validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.enterName : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _id,
              decoration: InputDecoration(labelText: context.l10n.packageId),
              style: monoStyle(context, size: 14),
              autocorrect: false,
              validator: (v) => validateApplicationId((v ?? '').trim()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _versionName,
                  decoration: InputDecoration(labelText: context.l10n.versionName),
                  validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.required : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _versionCode,
                  decoration: InputDecoration(labelText: context.l10n.versionCode),
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
              Expanded(child: Text(icon == null ? context.l10n.defaultIcon : context.l10n.customIcon, style: Theme.of(context).textTheme.bodyMedium)),
              OutlinedButton.icon(onPressed: _pickIcon, icon: const Icon(Icons.image_outlined), label: Text(context.l10n.chooseImage)),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(context.l10n.iconHint, style: Theme.of(context).textTheme.bodySmall),
            ),
            _Section(context.l10n.sectionContent),
            if (local) ...[
              DropdownButtonFormField<String>(
                // Rebuilt when the website is replaced and the pages change.
                key: ValueKey(_pages.join('|')),
                initialValue: _pages.contains(_m.source.entry) ? _m.source.entry : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.l10n.startPage),
                items: [for (final page in _pages) DropdownMenuItem(value: page, child: Text(page, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => _change(_m.copyWith(source: ProjectSource.local(v!))),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _replaceWebsite,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(context.l10n.replaceWebsite),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(context.l10n.replaceWebsiteHint, style: Theme.of(context).textTheme.bodySmall),
              ),
            ] else ...[
              TextFormField(
                controller: _siteUrl,
                decoration: InputDecoration(
                  labelText: context.l10n.websiteUrl,
                  helperText: context.l10n.loadedLive,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: monoStyle(context, size: 14),
                validator: (v) => validateRemoteUrl((v ?? '').trim()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hosts,
                decoration: InputDecoration(
                  labelText: context.l10n.otherSites,
                  hintText: 'login.example.com, cdn.example.com',
                  helperText: context.l10n.otherSitesHelp,
                  helperMaxLines: 2,
                ),
                autocorrect: false,
                validator: (v) {
                  for (final h in _parseHosts(v ?? '')) {
                    if (validateRemoteUrl('https://$h/') != null || h.contains('/')) return context.l10n.invalidHost(h);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bridgeHosts,
                decoration: InputDecoration(
                  labelText: context.l10n.bridgeSites,
                  hintText: 'shop.example.com',
                  helperText: context.l10n.bridgeSitesHelp,
                  helperMaxLines: 3,
                ),
                autocorrect: false,
                validator: (v) {
                  final inApp = _parseHosts(_hosts.text);
                  for (final h in _parseHosts(v ?? '')) {
                    if (!inApp.contains(h)) return context.l10n.bridgeSiteNotListed(h);
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            Text(context.l10n.orientation, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<Orientation>(
              segments: [
                ButtonSegment(value: Orientation.unspecified, label: Text(context.l10n.orientationAuto)),
                ButtonSegment(value: Orientation.portrait, label: Text(context.l10n.portrait)),
                ButtonSegment(value: Orientation.landscape, label: Text(context.l10n.landscape)),
              ],
              selected: {_m.orientation},
              onSelectionChanged: (s) => _change(_m.copyWith(orientation: s.single)),
            ),
            _Section(context.l10n.sectionShortcuts),
            Text(context.l10n.shortcutsHint,
                style: Theme.of(context).textTheme.bodySmall),
            for (final (i, s) in _m.shortcuts.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shortcut),
                title: Text(s.label),
                subtitle: Text(s.page, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: context.l10n.removeShortcut,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _change(_m.copyWith(shortcuts: [..._m.shortcuts]..removeAt(i))),
                ),
              ),
            if (_m.shortcuts.length < maxShortcuts)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addShortcut,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addShortcut),
                ),
              ),
            if (local) ...[
              _Section(context.l10n.sectionAppSize),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.optimizeFiles),
                subtitle: Text(context.l10n.optimizeFilesHint),
                value: _m.optimizeAssets,
                onChanged: (v) => _change(_m.copyWith(optimizeAssets: v)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _SizeReportDialog(sourceDir: widget.project.sourceDir),
                  ),
                  icon: const Icon(Icons.pie_chart_outline),
                  label: Text(context.l10n.sizeReport),
                ),
              ),
            ],
            _Section(context.l10n.sectionAppearance),
            _ColorField(label: context.l10n.statusBarColour, controller: _statusColor, onChanged: () => setState(() => _dirty = true)),
            const SizedBox(height: 12),
            _ColorField(label: context.l10n.navBarColour, controller: _navColor, onChanged: () => setState(() => _dirty = true)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.splashScreen),
              subtitle: Text(_m.splashPath == null
                  ? context.l10n.splashIconHint
                  : context.l10n.splashImageHint),
              value: _m.appearance.splashEnabled,
              onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(splashEnabled: v))),
            ),
            if (_m.appearance.splashEnabled) ...[
              _ColorField(label: context.l10n.splashBackground, controller: _splashColor, onChanged: () => setState(() => _dirty = true)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                OutlinedButton.icon(
                  onPressed: _pickSplash,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_m.splashPath == null ? context.l10n.chooseSplash : context.l10n.replaceSplash),
                ),
                if (_m.splashPath != null)
                  TextButton(onPressed: () => _clearFile(widget.controller.clearSplash), child: Text(context.l10n.useAppIcon)),
              ]),
            ],
            const SizedBox(height: 12),
            Text(context.l10n.theme, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<AppTheme>(
              segments: [
                ButtonSegment(value: AppTheme.light, label: Text(context.l10n.light)),
                ButtonSegment(value: AppTheme.dark, label: Text(context.l10n.dark)),
                ButtonSegment(value: AppTheme.system, label: Text(context.l10n.followPhone)),
              ],
              selected: {_m.appearance.theme},
              onSelectionChanged: (s) => _change(_m.copyWith(appearance: _m.appearance.copyWith(theme: s.single))),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(context.l10n.themeHint,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.fullscreen),
              subtitle: Text(context.l10n.fullscreenHint),
              value: _m.appearance.fullscreen,
              onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(fullscreen: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.keepScreenOn),
              subtitle: Text(context.l10n.keepScreenOnHint),
              value: _m.appearance.keepScreenOn,
              onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(keepScreenOn: v))),
            ),
            _Section(context.l10n.sectionDevices),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Android TV'),
              subtitle: Text(context.l10n.tvHint),
              value: _m.devices.androidTv,
              onChanged: (v) => _change(_m.copyWith(devices: _m.devices.copyWith(androidTv: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.rotateTablets),
              subtitle: Text(context.l10n.rotateTabletsHint),
              value: _m.devices.rotateOnTablets,
              onChanged: (v) => _change(_m.copyWith(devices: _m.devices.copyWith(rotateOnTablets: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.desktopLayout),
              subtitle: Text(context.l10n.desktopLayoutHint),
              value: _m.devices.desktopSiteOnLargeScreens,
              onChanged: (v) => _change(_m.copyWith(devices: _m.devices.copyWith(desktopSiteOnLargeScreens: v))),
            ),
            _Section(context.l10n.sectionSecurity),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.appLock),
              subtitle: Text(context.l10n.appLockHint),
              value: _m.appLock,
              onChanged: (v) => _change(_m.copyWith(appLock: v)),
            ),
            const _Section('WebView'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('JavaScript'),
              subtitle: Text(context.l10n.javascriptHint),
              value: _m.webView.javaScriptEnabled,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(javaScriptEnabled: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.localStorage),
              subtitle: const Text('localStorage and sessionStorage'),
              value: _m.webView.domStorageEnabled,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(domStorageEnabled: v))),
            ),
            if (local)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.internetAccess),
                subtitle: Text(context.l10n.internetAccessHint),
                value: _m.internetAccess,
                onChanged: (v) => _change(_m.copyWith(internetAccess: v)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.openOtherSites),
              subtitle: Text(context.l10n.openOtherSitesHint),
              value: _m.webView.externalLinks == ExternalLinkPolicy.browser,
              onChanged: (v) => _change(_m.copyWith(
                  webView: _m.webView.copyWith(externalLinks: v ? ExternalLinkPolicy.browser : ExternalLinkPolicy.block))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.pullToRefresh),
              subtitle: Text(context.l10n.pullToRefreshHint),
              value: _m.webView.pullToRefresh,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(pullToRefresh: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.notifications),
              subtitle: Text(context.l10n.notificationsHint),
              value: _m.webView.notifications,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(notifications: v))),
            ),
            DropdownButtonFormField<BackButtonMode>(
              initialValue: _m.webView.backButton,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.l10n.backButton),
              items: [
                DropdownMenuItem(value: BackButtonMode.history, child: Text(context.l10n.backHistory)),
                DropdownMenuItem(value: BackButtonMode.pressTwiceToExit, child: Text(context.l10n.backTwice)),
                DropdownMenuItem(value: BackButtonMode.confirmExit, child: Text(context.l10n.backConfirm)),
                DropdownMenuItem(value: BackButtonMode.home, child: Text(context.l10n.backHome)),
              ],
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(backButton: v))),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.fileUploads),
              subtitle: Text(context.l10n.fileUploadsHint),
              value: _m.webView.fileUploads,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(fileUploads: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.share),
              subtitle: Text(context.l10n.shareHint),
              value: _m.webView.webShare,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(webShare: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.downloads),
              subtitle: Text(context.l10n.downloadsHint),
              value: _m.webView.downloads,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(downloads: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.shareFiles),
              subtitle: Text(context.l10n.shareFilesHint),
              value: _m.webView.shareFiles,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(shareFiles: v))),
            ),
            TextFormField(
              controller: _galleryFolder,
              decoration: InputDecoration(
                labelText: context.l10n.galleryFolder,
                hintText: context.l10n.galleryFolderExample,
                helperText: context.l10n.galleryFolderHelp,
                helperMaxLines: 2,
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? null : galleryFolderError((v ?? '').trim()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _shareTarget,
              decoration: InputDecoration(
                labelText: context.l10n.shareToApp,
                hintText: context.l10n.example('com.whatsapp'),
                helperText: context.l10n.shareToAppHelp,
                helperMaxLines: 2,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                return t.isEmpty || isPackageName(t) ? null : context.l10n.usePackageName;
              },
            ),
            if (!local) ...[
              _Section(context.l10n.sectionOffline),
              Text(
                _m.offlineFallbackPage == null
                    ? context.l10n.offlineBuiltIn
                    : context.l10n.offlinePageShown(_m.offlineFallbackPage!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: _pickOfflinePage,
                  icon: const Icon(Icons.cloud_off_outlined),
                  label: Text(_m.offlineFallbackPage == null ? context.l10n.chooseOfflinePage : context.l10n.replaceOfflinePage),
                ),
                if (_m.offlineFallbackPage != null)
                  TextButton(
                    onPressed: () => _clearFile(widget.controller.clearOfflinePage),
                    child: Text(context.l10n.useBuiltInPage),
                  ),
              ]),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _ua,
              decoration: InputDecoration(labelText: context.l10n.userAgentSuffix, hintText: context.l10n.example('MyApp/1.0')),
              validator: (v) => (v ?? '').length > 200 ? context.l10n.atMost200 : null,
            ),
            _Section(context.l10n.sectionDanger),
            OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.deleteProject),
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

const _presetColors = [
  '#000000', '#FFFFFF', '#12161F', '#1A73E8', '#0F9D58', '#D93025', '#F9AB00', '#6750A4', //
];

Color? _parseHex(String s) =>
    isHexColor(s.trim()) ? Color(0xFF000000 | int.parse(s.trim().substring(1), radix: 16)) : null;

/// Hex colour input with a live swatch and a row of presets.
class _ColorField extends StatefulWidget {
  const _ColorField({required this.label, required this.controller, required this.onChanged});

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  void _set(String hex) {
    widget.controller.text = hex;
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = _parseHex(widget.controller.text);
    final outline = Theme.of(context).colorScheme.outline;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: current ?? Colors.transparent, shape: BoxShape.circle, border: Border.all(color: outline)),
            ),
          ),
        ),
        style: monoStyle(context, size: 14),
        autocorrect: false,
        validator: (v) => isHexColor((v ?? '').trim()) ? null : context.l10n.useColourLike,
        onChanged: (_) {
          widget.onChanged();
          setState(() {});
        },
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final hex in _presetColors)
          InkWell(
            onTap: () => _set(hex),
            customBorder: const CircleBorder(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _parseHex(hex),
                shape: BoxShape.circle,
                border: Border.all(
                    color: widget.controller.text.trim().toUpperCase() == hex ? Theme.of(context).colorScheme.primary : outline,
                    width: widget.controller.text.trim().toUpperCase() == hex ? 3 : 1),
              ),
            ),
          ),
      ]),
    ]);
  }
}

/// Serves the APK on the local network and shows a QR code for the phone.
/// The server stops when the dialog closes, or after 10 minutes.
class _QrInstallDialog extends StatefulWidget {
  const _QrInstallDialog({required this.apkPath});

  final String apkPath;

  @override
  State<_QrInstallDialog> createState() => _QrInstallDialogState();
}

class _QrInstallDialogState extends State<_QrInstallDialog> {
  List<InternetAddress> _addresses = const [];
  InternetAddress? _address;
  LanFileServer? _server;
  List<List<bool>> _qr = const [];
  String? _error;
  int _downloads = 0;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final list = await lanAddresses();
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _error = context.l10n.noNetwork);
        return;
      }
      setState(() => _addresses = list);
      await _serve(list.first);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _serve(InternetAddress address) async {
    await _server?.stop();
    final server = await LanFileServer.start(widget.apkPath, address: address);
    if (!mounted) {
      await server.stop();
      return;
    }
    server.onDownload.listen((n) {
      if (mounted) setState(() => _downloads = n);
    });
    unawaited(server.done.then((_) {
      if (mounted && identical(_server, server)) setState(() => _expired = true);
    }));
    setState(() {
      _address = address;
      _server = server;
      _qr = qrMatrix(server.url.toString());
      _expired = false;
      _downloads = 0;
    });
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final server = _server;
    return AlertDialog(
      title: Text(context.l10n.installOnPhone),
      content: SizedBox(
        width: 360,
        child: _error != null
            ? Text(_error!)
            : server == null
                ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.l10n.installSteps),
                    const SizedBox(height: 16),
                    Center(
                      child: _expired
                          ? SizedBox(height: 240, child: Center(child: Text(context.l10n.linkStopped)))
                          : Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(12),
                              child: SizedBox.square(
                                dimension: 240,
                                child: CustomPaint(painter: _QrPainter(_qr)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(server.url.toString(), style: t.bodySmall),
                    if (_addresses.length > 1)
                      DropdownButtonFormField<InternetAddress>(
                        initialValue: _address,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: context.l10n.networkAddress),
                        items: [for (final a in _addresses) DropdownMenuItem(value: a, child: Text(a.address))],
                        onChanged: (a) {
                          if (a != null && a != _address) _serve(a);
                        },
                      ),
                    const SizedBox(height: 8),
                    Text(
                        _downloads == 0
                            ? context.l10n.linkWorks10Min
                            : context.l10n.downloadedTimes(_downloads),
                        style: t.bodySmall),
                    const SizedBox(height: 4),
                    Text(context.l10n.trustedNetworkOnly, style: t.bodySmall),
                  ]),
      ),
      actions: [
        if (_expired && _address != null)
          TextButton(onPressed: () => _serve(_address!), child: Text(context.l10n.startAgain)),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.done)),
      ],
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.modules);

  final List<List<bool>> modules;

  @override
  void paint(Canvas canvas, Size size) {
    final n = modules.length;
    final cell = size.width / n;
    final paint = Paint()..color = Colors.black;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        // A small overlap stops thin white lines between squares.
        if (modules[y][x]) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => !identical(old.modules, modules);
}

/// Shows what takes space in the site and how much the optimizer would save.
class _SizeReportDialog extends StatefulWidget {
  const _SizeReportDialog({required this.sourceDir});

  final String sourceDir;

  @override
  State<_SizeReportDialog> createState() => _SizeReportDialogState();
}

class _SizeReportDialogState extends State<_SizeReportDialog> {
  late final Future<SiteSizeReport> _report = _scan(widget.sourceDir);

  // Static, so the isolate closure captures only the path and not this State.
  static Future<SiteSizeReport> _scan(String dir) => Isolate.run(() => SiteSizeReport.scan(dir));
  Future<OptimizeResult>? _savings;

  static String _kindName(BuildContext context, AssetKind kind) => switch (kind) {
        AssetKind.page => context.l10n.kindPages,
        AssetKind.script => 'JavaScript',
        AssetKind.style => 'CSS',
        AssetKind.image => context.l10n.kindImages,
        AssetKind.font => context.l10n.kindFonts,
        AssetKind.media => context.l10n.kindMedia,
        AssetKind.data => context.l10n.kindData,
        AssetKind.other => context.l10n.kindOther,
      };

  /// Runs the optimizer on a temporary copy, only to count the savings.
  static Future<OptimizeResult> _trySavings(String sourceDir) => Isolate.run(() {
        final tmp = Directory.systemTemp.createTempSync('size');
        try {
          return optimizeSite(sourceDir, tmp.path);
        } finally {
          tmp.deleteSync(recursive: true);
        }
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(context.l10n.sizeReport),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<SiteSizeReport>(
          future: _report,
          builder: (context, snap) {
            final r = snap.data;
            if (snap.hasError) return Text(context.l10n.couldNotReadFiles('${snap.error}'));
            if (r == null) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
            final kinds = r.bytesByKind.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.filesAndSize(r.files.length, formatBytes(r.totalBytes)), style: text.titleMedium),
                const SizedBox(height: 8),
                for (final k in kinds) _row(_kindName(context, k.key), formatBytes(k.value)),
                const SizedBox(height: 16),
                Text(context.l10n.largestFiles, style: text.labelLarge),
                for (final f in r.largest(8)) _row(f.path, formatBytes(f.bytes)),
                if (r.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(context.l10n.advice, style: text.labelLarge),
                  for (final w in r.warnings)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $w', style: text.bodySmall)),
                ],
                const SizedBox(height: 16),
                if (_savings == null)
                  OutlinedButton(
                    onPressed: () => setState(() => _savings = _trySavings(widget.sourceDir)),
                    child: Text(context.l10n.checkOptimizing),
                  )
                else
                  FutureBuilder<OptimizeResult>(
                    future: _savings,
                    builder: (context, s) {
                      final o = s.data;
                      if (s.hasError) return Text(context.l10n.checkFailed('${s.error}'));
                      if (o == null) return const LinearProgressIndicator();
                      return Text(
                          context.l10n.optimizeResult(o.changed.length, formatBytes(o.savedBytes), formatBytes(o.totalBefore), formatBytes(o.totalAfter)),
                          style: text.bodyMedium);
                    },
                  ),
              ]),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.close))],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Text(value),
        ]),
      );
}

/// Asks for a shortcut's name and page; returns null when cancelled.
class _ShortcutDialog extends StatefulWidget {
  const _ShortcutDialog({required this.type, required this.pages});

  final SourceType type;
  final List<String> pages;

  @override
  State<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<_ShortcutDialog> {
  final _form = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _page = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.type == SourceType.local;
    return AlertDialog(
      title: Text(context.l10n.addShortcut),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _label,
            autofocus: true,
            maxLength: maxShortcutLabelLength,
            decoration: InputDecoration(labelText: context.l10n.name, hintText: context.l10n.exampleCart),
            validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.enterName : null,
          ),
          if (local && widget.pages.isNotEmpty)
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(labelText: context.l10n.page),
              items: [for (final page in widget.pages) DropdownMenuItem(value: page, child: Text(page, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => _page.text = v ?? '',
              validator: (v) => v == null ? context.l10n.choosePage : shortcutPageError(widget.type, v),
            )
          else
            TextFormField(
              controller: _page,
              autocorrect: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: context.l10n.page,
                hintText: context.l10n.example(local ? 'cart.html' : '/cart'),
              ),
              validator: (v) => shortcutPageError(widget.type, (v ?? '').trim()),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, AppShortcut(label: _label.text.trim(), page: _page.text.trim()));
          },
          child: Text(context.l10n.add),
        ),
      ],
    );
  }
}

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

  BuildVariant _variant = BuildVariant.debug;
  ArtifactFormat _format = ArtifactFormat.apk;
  List<SigningKey>? _keys;
  String? _keyId;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keyManager = widget.controller.keys;
    if (keyManager == null) return;
    try {
      final keys = await keyManager.listKeys();
      if (!mounted) return;
      final pinned = widget.project.manifest.releaseCertSha256;
      setState(() {
        _keys = keys;
        // Prefer the key this app was first released with.
        _keyId = keys.where((k) => k.sha256 == pinned).firstOrNull?.id ??
            (keys.any((k) => k.id == _keyId) ? _keyId : keys.firstOrNull?.id);
      });
    } on PlatformException catch (e) {
      if (mounted) setState(() => _log.add(context.l10n.couldNotLoadKeys(e.message ?? '')));
    } on KeyManagerException catch (e) {
      if (mounted) setState(() => _log.add(context.l10n.couldNotLoadKeys(e.message)));
    }
  }

  SigningKey? get _selectedKey => _keys?.where((k) => k.id == _keyId).firstOrNull;

  Future<void> _build() async {
    final release = _variant == BuildVariant.release;
    final key = _selectedKey;
    if (release) {
      if (key == null) return;
      final pinned = widget.project.manifest.releaseCertSha256;
      if (pinned != null && pinned != key.sha256) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(context.l10n.differentKey),
            content: Text(context.l10n.differentKeyBody(pinned.substring(0, 8), key.alias)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
              TextButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.buildAnyway)),
            ],
          ),
        );
        if (ok != true) return;
      }
    }
    setState(() {
      _log.clear();
      _result = null;
    });
    final result = await widget.controller.build(
      widget.project,
      (line) {
        if (mounted) setState(() => _log.add(line));
      },
      variant: _variant,
      signing: release ? DeviceKeySigning(key!) : null,
      format: release ? _format : ArtifactFormat.apk,
    );
    if (mounted) setState(() => _result = result);
  }

  bool _exeDebug = false;

  Future<void> _buildExe() async {
    setState(() {
      _log.clear();
      _result = null;
    });
    final result = await widget.controller.buildExe(widget.project, (line) {
      if (mounted) setState(() => _log.add(line));
    }, debug: _exeDebug);
    if (mounted) setState(() => _result = result);
  }

  Widget _exeCard(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.desktop_windows_outlined),
            const SizedBox(width: 8),
            Text(context.l10n.windowsExe, style: t.titleSmall),
          ]),
          const SizedBox(height: 8),
          Text(context.l10n.exeDescription,
              style: t.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.l10n.devTools),
            subtitle: Text(context.l10n.devToolsHint),
            value: _exeDebug,
            onChanged: (v) => setState(() => _exeDebug = v),
          ),
          FilledButton.tonalIcon(
            onPressed: _building ? null : _buildExe,
            icon: const Icon(Icons.play_arrow),
            label: Text(_building ? context.l10n.building : context.l10n.buildExe),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _msixSection(context),
        ]),
      ),
    );
  }

  // ---- Windows installer (ADR 0008)

  late final WindowsSdkTools? _sdk = widget.controller.desktopEngine?.sdkTools;

  Future<void> _buildMsix() async {
    setState(() {
      _log.clear();
      _result = null;
    });
    final result = await widget.controller.buildMsix(widget.project, (line) {
      if (mounted) setState(() => _log.add(line));
    });
    if (mounted) setState(() => _result = result);
  }

  Widget _msixSection(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final desktop = widget.controller.desktopEngine!;
    final cert = desktop.msixCertificate();
    final until = cert == null ? '' : MaterialLocalizations.of(context).formatMediumDate(cert.notAfter.toLocal());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Icon(Icons.install_desktop_outlined),
        const SizedBox(width: 8),
        Text(context.l10n.windowsMsix, style: t.titleSmall),
      ]),
      const SizedBox(height: 8),
      Text(context.l10n.msixDescription,
          style: t.bodySmall),
      const SizedBox(height: 12),
      if (_sdk == null)
        Text(context.l10n.needsWindowsSdk,
            style: monoStyle(context, size: 12))
      else ...[
        if (cert == null)
          Text(context.l10n.noCertificate,
              style: t.bodySmall)
        else ...[
          Text(context.l10n.publisherValidUntil(cert.publisherName, until), style: monoStyle(context, size: 12)),
          if (cert.isTest)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  context.l10n.testCertNote,
                  style: t.bodySmall),
            ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _building ? null : () => _replaceCert(cert, _createCert),
            icon: const Icon(Icons.add_moderator_outlined),
            label: Text(context.l10n.createTestCert),
          ),
          OutlinedButton.icon(
            onPressed: _building ? null : () => _replaceCert(cert, _importCert),
            icon: const Icon(Icons.file_open_outlined),
            label: Text(context.l10n.useMyPfx),
          ),
          if (cert != null)
            OutlinedButton.icon(
              onPressed: () => _certAction(desktop.saveMsixCer, context.l10n.savedCertificate),
              icon: const Icon(Icons.save_alt),
              label: Text(context.l10n.saveCer),
            ),
        ]),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _building || cert == null ? null : _buildMsix,
          icon: const Icon(Icons.play_arrow),
          label: Text(_building ? context.l10n.building : context.l10n.buildInstaller),
        ),
      ],
    ]);
  }

  /// Installed apps only update from installers with the same publisher.
  Future<void> _replaceCert(MsixCertificate? current, Future<void> Function() action) async {
    if (current != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.l10n.replaceCertQ),
          content: Text(context.l10n.replaceCertBody(current.publisherName)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.replace)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await action();
  }

  Future<void> _createCert() async {
    final l = context.l10n;
    final name = await _askText(l.createTestCert, l.publisherName,
        initial: Platform.environment['USERNAME'] ?? '', help: l.publisherNameHelp);
    if (name == null) return;
    await _certAction(() => widget.controller.desktopEngine!.createMsixCertificate(name), l.testCertCreated);
  }

  Future<void> _importCert() async {
    final l = context.l10n;
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pfx', 'p12']);
    if (picked.isEmpty || !mounted) return;
    final tmp = Directory.systemTemp.createTempSync('pfx');
    try {
      final path = p.join(tmp.path, 'certificate.pfx');
      await picked.single.xFile.saveTo(path);
      final password = await _askText(l.useMyCertificate, l.passwordOf(picked.single.name), obscure: true);
      if (password == null) return;
      await _certAction(
          () => widget.controller.desktopEngine!.importMsixCertificate(path, password), l.certificateAdded);
    } finally {
      tmp.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  Future<void> _certAction(Future<Object?> Function() action, String done) async {
    try {
      final r = await action();
      // A null result means the save dialog was cancelled.
      if (mounted && r != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      }
    } on KeyManagerException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on FileSystemException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() {});
  }

  Future<String?> _askText(String title, String label, {String initial = '', bool obscure = false, String? help}) {
    final field = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: field,
          autofocus: true,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label, helperText: help, helperMaxLines: 3),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, field.text), child: Text(context.l10n.ok)),
        ],
      ),
    ).whenComplete(field.dispose);
  }

  Future<void> _save(String path) async {
    try {
      final c = widget.controller;
      final where = await (c.desktopEngine?.saveFile(path) ?? c.deviceEngine!.saveFile(path));
      if (mounted && where != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.savedFile(p.basename(path)))));
      }
    } on PlatformException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('${e.message}'))));
    } on FileSystemException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed(e.message))));
    }
  }

  Future<void> _openKeys() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => SigningKeysScreen(keys: widget.controller.keys!)));
    await _loadKeys();
  }

  Future<void> _install(String path) async {
    final engine = widget.controller.deviceEngine!;
    try {
      if (!await engine.install(path) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 8),
          content: Text(context.l10n.allowUnknownApps),
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
                SegmentedButton<BuildVariant>(
                  segments: [
                    ButtonSegment(value: BuildVariant.debug, label: Text(context.l10n.debug), icon: Icon(Icons.bug_report_outlined)),
                    ButtonSegment(value: BuildVariant.release, label: Text(context.l10n.release), icon: Icon(Icons.verified_outlined)),
                  ],
                  selected: {_variant},
                  onSelectionChanged: (s) => setState(() => _variant = s.single),
                ),
                const SizedBox(height: 12),
                Text('${m.android.applicationId} · v${m.android.versionName} (${m.android.versionCode})',
                    style: monoStyle(context, size: 12)),
                const SizedBox(height: 4),
                if (_variant == BuildVariant.debug)
                  Text(context.l10n.debugHint,
                      style: t.bodySmall)
                else ...[
                  Text(context.l10n.releaseHint,
                      style: t.bodySmall),
                  const SizedBox(height: 12),
                  SegmentedButton<ArtifactFormat>(
                    segments: [
                      ButtonSegment(value: ArtifactFormat.apk, label: Text('APK')),
                      ButtonSegment(value: ArtifactFormat.aab, label: Text(context.l10n.appBundlePlay)),
                    ],
                    selected: {_format},
                    onSelectionChanged: (s) => setState(() => _format = s.single),
                  ),
                  if (_format == ArtifactFormat.aab)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(context.l10n.aabHint,
                          style: t.bodySmall),
                    ),
                  const SizedBox(height: 12),
                  if (_keys == null)
                    const LinearProgressIndicator()
                  else if (_keys!.isEmpty)
                    OutlinedButton.icon(
                      onPressed: _openKeys,
                      icon: const Icon(Icons.key),
                      label: Text(context.l10n.createOrImportKey),
                    )
                  else
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _keyId,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: context.l10n.releaseKey),
                          items: [
                            for (final k in _keys!)
                              DropdownMenuItem(value: k.id, child: Text('${k.alias} · ${k.shortSha256}', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _keyId = v),
                        ),
                      ),
                      IconButton(tooltip: context.l10n.manageKeys, onPressed: _openKeys, icon: const Icon(Icons.settings_outlined)),
                    ]),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _building ||
                          widget.controller.engine == null ||
                          (_variant == BuildVariant.release && _selectedKey == null)
                      ? null
                      : _build,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_building
                      ? context.l10n.building
                      : _variant == BuildVariant.debug
                          ? context.l10n.buildDebugApk
                          : _format == ArtifactFormat.aab
                              ? context.l10n.buildAppBundle
                              : context.l10n.buildReleaseApk),
                ),
                if (widget.controller.engine == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(context.l10n.buildingUnavailable, style: t.bodySmall),
                  ),
                if (widget.controller.desktopEngine?.problems case final problems? when problems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${context.l10n.cannotBuildYet}\n${problems.join('\n')}',
                        style: t.bodySmall?.copyWith(color: scheme.error)),
                  ),
                if (_building)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AsciiBuildProgress(
                      label: context.l10n.buildingLines(_log.length),
                      animate: animationsOn(context, widget.controller.settings),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.controller.desktopEngine != null) ...[
          const SizedBox(height: 12),
          _exeCard(context),
        ],
        if (_result != null && _result!.status != BuildStatus.succeeded) ...[
          const SizedBox(height: 12),
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
              title: Text(context.l10n.buildFailed, style: TextStyle(color: scheme.onErrorContainer)),
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
                    if (widget.controller.desktopEngine case final desktop?) ...[
                      FilledButton.tonalIcon(
                        onPressed: () => _save(apkPath),
                        icon: const Icon(Icons.save_alt),
                        label: Text(context.l10n.saveAs),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => desktop.showInFolder(apkPath),
                        icon: const Icon(Icons.folder_open_outlined),
                        label: Text(context.l10n.showInFolder),
                      ),
                      if (!apkPath.endsWith('.aab'))
                        OutlinedButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => _QrInstallDialog(apkPath: apkPath),
                          ),
                          icon: const Icon(Icons.qr_code_2),
                          label: Text(context.l10n.installOnPhone),
                        ),
                    ] else ...[
                    if (!apkPath.endsWith('.aab'))
                      FilledButton.tonalIcon(
                        onPressed: () => _install(apkPath),
                        icon: const Icon(Icons.install_mobile),
                        label: Text(context.l10n.install),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _save(apkPath),
                      icon: const Icon(Icons.save_alt),
                      label: Text(context.l10n.saveToDevice),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.controller.deviceEngine!.share(apkPath),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(context.l10n.share),
                    ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
        if (_log.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(context.l10n.buildLog, style: t.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(_log.join('\n'), style: monoStyle(context, size: 11.5)),
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(context.l10n.history, style: t.titleSmall),
          for (final b in history.take(10))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(b.succeeded ? Icons.check_circle_outline : Icons.highlight_off,
                  color: b.succeeded ? scheme.primary : scheme.error),
              title: Text('v${b.versionName ?? '?'} (${b.versionCode ?? '?'}) · ${b.variant} ${b.format.toUpperCase()} · ${b.status} · ${b.durationMs} ms'),
              subtitle: Text('${_fmtTime(b.time)}${b.bytes == null ? '' : ' · ${formatBytes(b.bytes!)}'}${b.message == null ? '' : '\n${b.message}'}'),
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

/// What changed after replacing a project's website files.
class _ReplaceSummary extends StatelessWidget {
  const _ReplaceSummary({required this.report});

  final ReplaceReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final r = report.import;
    final missing = r.missingAssets;
    return AlertDialog(
      title: Text(l.websiteReplaced),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.importedFiles(r.fileCount)),
            const SizedBox(height: 8),
            Text(l.startPageIs(r.project.manifest.source.entry)),
            if (report.startPageChanged) Text(l.startPageChanged(report.previousStartPage), style: t.bodySmall),
            if (report.droppedShortcuts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.shortcutsRemoved(report.droppedShortcuts.join(', ')), style: t.bodySmall),
            ],
            const SizedBox(height: 8),
            if (missing.isEmpty)
              Text(l.noMissingFiles)
            else ...[
              Text(l.filesMissing(missing.length), style: t.titleSmall),
              for (final m in missing.take(8)) Text('• $m', style: monoStyle(context, size: 12)),
              if (missing.length > 8) Text(l.andMore(missing.length - 8)),
            ],
            const SizedBox(height: 12),
            Text(l.rebuildAfterReplace, style: t.bodySmall),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done))],
    );
  }
}
