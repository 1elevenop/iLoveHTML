import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import '../engine/msix_builder.dart';
import '../engine/on_device_engine.dart';
import '../image_import.dart';
import 'preview_screen.dart';
import 'signing_keys_screen.dart';
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
                  onPressed: () => Platform.isWindows
                      ? _browserPreview(context, controller.project(projectId)!)
                      : Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PreviewScreen(project: controller.project(projectId)!))),
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
          title: const Text('Preview in your browser'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(url.toString(), style: monoStyle(c, size: 12)),
            const SizedBox(height: 12),
            Text(server == null
                ? 'The live site opened in your default browser.'
                : 'Served from this PC only, while this window is open. The phone app adds a console and '
                    'link checks; here use the browser\'s developer tools (F12).'),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Missing files:', style: Theme.of(c).textTheme.titleSmall),
              for (final f in missing.take(8)) Text(f, style: monoStyle(c, size: 12)),
            ],
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(server == null ? 'Close' : 'Stop preview'))],
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
  late final _statusColor = TextEditingController(text: _m.appearance.statusBarColor);
  late final _navColor = TextEditingController(text: _m.appearance.navigationBarColor);
  late final _splashColor = TextEditingController(text: _m.appearance.splashBackgroundColor);
  late final List<String> _pages = findEntryCandidates(listRelativeFiles(widget.project.sourceDir));
  bool _dirty = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_name, _id, _versionName, _versionCode, _ua, _galleryFolder, _shareTarget, _siteUrl, _hosts, _statusColor,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
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
      pickableImageExtensions, (f) => widget.controller.setIcon(_current, f), 'Icon updated',
      convert: (b, ext) => toPng(b, isSvg: ext == 'svg', square: true, maxSide: 1024));

  Future<void> _pickSplash() => _pickFile(
      pickableImageExtensions, (f) => widget.controller.setSplash(_current, f), 'Splash image updated',
      convert: (b, ext) => toPng(b, isSvg: ext == 'svg', maxSide: 1440));

  Future<void> _pickOfflinePage() =>
      _pickFile(['html', 'htm'], (f) => widget.controller.setOfflinePage(_current, f), 'Offline page added');

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
              OutlinedButton.icon(onPressed: _pickIcon, icon: const Icon(Icons.image_outlined), label: const Text('Choose image')),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('PNG, JPEG, WebP, GIF, BMP or SVG, at least 48 px; 512 × 512 recommended. Non-square images are centred.', style: Theme.of(context).textTheme.bodySmall),
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
            const _Section('Appearance'),
            _ColorField(label: 'Status bar colour', controller: _statusColor, onChanged: () => setState(() => _dirty = true)),
            const SizedBox(height: 12),
            _ColorField(label: 'Navigation bar colour', controller: _navColor, onChanged: () => setState(() => _dirty = true)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Splash screen'),
              subtitle: Text(_m.splashPath == null
                  ? 'Shows the app icon until the first page has loaded.'
                  : 'Shows your splash image until the first page has loaded.'),
              value: _m.appearance.splashEnabled,
              onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(splashEnabled: v))),
            ),
            if (_m.appearance.splashEnabled) ...[
              _ColorField(label: 'Splash background', controller: _splashColor, onChanged: () => setState(() => _dirty = true)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                OutlinedButton.icon(
                  onPressed: _pickSplash,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_m.splashPath == null ? 'Choose splash image' : 'Replace splash image'),
                ),
                if (_m.splashPath != null)
                  TextButton(onPressed: () => _clearFile(widget.controller.clearSplash), child: const Text('Use app icon')),
              ]),
            ],
            const SizedBox(height: 12),
            Text('Theme', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<AppTheme>(
              segments: const [
                ButtonSegment(value: AppTheme.light, label: Text('Light')),
                ButtonSegment(value: AppTheme.dark, label: Text('Dark')),
                ButtonSegment(value: AppTheme.system, label: Text('Follow phone')),
              ],
              selected: {_m.appearance.theme},
              onSelectionChanged: (s) => _change(_m.copyWith(appearance: _m.appearance.copyWith(theme: s.single))),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Sets prefers-color-scheme, so pages with dark-mode CSS switch to it.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fullscreen'),
              subtitle: const Text('Hides the status and navigation bars. Swipe from the edge to show them for a moment.'),
              value: _m.appearance.fullscreen,
              onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(fullscreen: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep screen on'),
              subtitle: const Text('The screen does not turn off while the app is open.'),
              value: _m.appearance.keepScreenOn,
              onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(keepScreenOn: v))),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pull to refresh'),
              subtitle: const Text('Swipe down at the top of a page to reload it, or to retry after an error.'),
              value: _m.webView.pullToRefresh,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(pullToRefresh: v))),
            ),
            DropdownButtonFormField<BackButtonMode>(
              initialValue: _m.webView.backButton,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Back button'),
              items: const [
                DropdownMenuItem(value: BackButtonMode.history, child: Text('Go back, then close the app')),
                DropdownMenuItem(value: BackButtonMode.pressTwiceToExit, child: Text('Go back, then press twice to close')),
                DropdownMenuItem(value: BackButtonMode.confirmExit, child: Text('Go back, then ask before closing')),
                DropdownMenuItem(value: BackButtonMode.home, child: Text('Go to the start page, then close')),
              ],
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(backButton: v))),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('File uploads'),
              subtitle: const Text('Lets file inputs open Android\'s file picker. The user chooses each file.'),
              value: _m.webView.fileUploads,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(fileUploads: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share'),
              subtitle: const Text('navigator.share opens Android\'s share sheet for text and links.'),
              value: _m.webView.webShare,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(webShare: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Downloads'),
              subtitle: const Text('Download links and generated files are saved to the Downloads folder.'),
              value: _m.webView.downloads,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(downloads: v))),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share images and PDFs'),
              subtitle: const Text('navigator.share({files}) sends images and PDFs to other apps. '
                  'On Android 10+ shared images are also saved to the gallery.'),
              value: _m.webView.shareFiles,
              onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(shareFiles: v))),
            ),
            TextFormField(
              controller: _galleryFolder,
              decoration: const InputDecoration(
                labelText: 'Gallery folder (optional)',
                hintText: 'e.g. Kishor G',
                helperText: 'Pictures/<folder> for shared and downloaded images. Empty: the app name for shares, '
                    'Downloads for downloads.',
                helperMaxLines: 2,
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? null : galleryFolderError((v ?? '').trim()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _shareTarget,
              decoration: const InputDecoration(
                labelText: 'Share straight to app (optional)',
                hintText: 'e.g. com.whatsapp',
                helperText: 'Package that file shares open directly when installed, instead of the share sheet.',
                helperMaxLines: 2,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                return t.isEmpty || isPackageName(t) ? null : 'Use a package name like com.whatsapp';
              },
            ),
            if (!local) ...[
              const _Section('Offline'),
              Text(
                _m.offlineFallbackPage == null
                    ? 'When the site cannot load, a built-in "Page unavailable" screen is shown.'
                    : 'When the site cannot load, your page "${_m.offlineFallbackPage}" is shown. '
                        'Link to https://appassets.androidplatform.net/html2apk/retry for a "Try again" button.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: _pickOfflinePage,
                  icon: const Icon(Icons.cloud_off_outlined),
                  label: Text(_m.offlineFallbackPage == null ? 'Choose offline page (.html)' : 'Replace offline page'),
                ),
                if (_m.offlineFallbackPage != null)
                  TextButton(
                    onPressed: () => _clearFile(widget.controller.clearOfflinePage),
                    child: const Text('Use built-in page'),
                  ),
              ]),
            ],
            const SizedBox(height: 16),
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
        validator: (v) => isHexColor((v ?? '').trim()) ? null : 'Use a colour like #1A73E8',
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
      if (mounted) setState(() => _log.add('Could not load release keys: ${e.message}'));
    } on KeyManagerException catch (e) {
      if (mounted) setState(() => _log.add('Could not load release keys: ${e.message}'));
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
            title: const Text('Different release key'),
            content: Text('This app was first released with a different key (SHA-256 ${pinned.substring(0, 8)}…). '
                'Phones that installed that release cannot update to an APK signed with "${key.alias}", '
                'and Google Play will reject it as an update.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Build anyway')),
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
            Text('Windows app (.exe)', style: t.titleSmall),
          ]),
          const SizedBox(height: 8),
          Text('One .exe file that opens this site in its own window with Microsoft Edge WebView2 '
              '(built into Windows 11 and updated Windows 10). It is not code-signed, so Windows may show '
              '"Windows protected your PC" until people choose More info → Run anyway.',
              style: t.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Developer tools (for testing)'),
            subtitle: const Text('F12 and Inspect work in the app; leave off for the version you share'),
            value: _exeDebug,
            onChanged: (v) => setState(() => _exeDebug = v),
          ),
          FilledButton.tonalIcon(
            onPressed: _building ? null : _buildExe,
            icon: const Icon(Icons.play_arrow),
            label: Text(_building ? 'Building…' : 'Build .exe'),
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
        Text('Windows installer (.msix)', style: t.titleSmall),
      ]),
      const SizedBox(height: 8),
      Text('Installs the app like other Windows software: Start menu entry, clean uninstall, and updates when '
          'you share a higher version. Every installer is signed with a certificate.',
          style: t.bodySmall),
      const SizedBox(height: 12),
      if (_sdk == null)
        Text('Needs the Windows SDK. Install it with:\nwinget install Microsoft.WindowsSDK.10.0.26100',
            style: monoStyle(context, size: 12))
      else ...[
        if (cert == null)
          Text('No certificate yet. Use your own code-signing certificate, or create a test certificate to try it.',
              style: t.bodySmall)
        else ...[
          Text('Publisher: ${cert.publisherName} · valid until $until', style: monoStyle(context, size: 12)),
          if (cert.isTest)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  'Test certificate: Windows installs the app only after people trust it once. Share the .cer '
                  'file next to the installer; people double-click it → Install Certificate → Local Machine → '
                  '"Trusted People". A certificate bought from a certificate authority needs no such step.',
                  style: t.bodySmall),
            ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _building ? null : () => _replaceCert(cert, _createCert),
            icon: const Icon(Icons.add_moderator_outlined),
            label: const Text('Create test certificate'),
          ),
          OutlinedButton.icon(
            onPressed: _building ? null : () => _replaceCert(cert, _importCert),
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Use my .pfx'),
          ),
          if (cert != null)
            OutlinedButton.icon(
              onPressed: () => _certAction(desktop.saveMsixCer, 'Saved the certificate'),
              icon: const Icon(Icons.save_alt),
              label: const Text('Save .cer'),
            ),
        ]),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _building || cert == null ? null : _buildMsix,
          icon: const Icon(Icons.play_arrow),
          label: Text(_building ? 'Building…' : 'Build installer'),
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
          title: const Text('Replace the certificate?'),
          content: Text('Apps installed from installers signed by "${current.publisherName}" update only from '
              'installers with the same publisher name. Back up the current certificate first if you may need it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Replace')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await action();
  }

  Future<void> _createCert() async {
    final name = await _askText('Create test certificate', 'Publisher name',
        initial: Platform.environment['USERNAME'] ?? '',
        help: 'Shown as the publisher when people install your apps.');
    if (name == null) return;
    await _certAction(() => widget.controller.desktopEngine!.createMsixCertificate(name), 'Test certificate created');
  }

  Future<void> _importCert() async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pfx', 'p12']);
    if (picked.isEmpty || !mounted) return;
    final tmp = Directory.systemTemp.createTempSync('pfx');
    try {
      final path = p.join(tmp.path, 'certificate.pfx');
      await picked.single.xFile.saveTo(path);
      final password = await _askText('Use my certificate', 'Password of ${picked.single.name}', obscure: true);
      if (password == null) return;
      await _certAction(
          () => widget.controller.desktopEngine!.importMsixCertificate(path, password), 'Certificate added');
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
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, field.text), child: const Text('OK')),
        ],
      ),
    ).whenComplete(field.dispose);
  }

  Future<void> _save(String path) async {
    try {
      final c = widget.controller;
      final where = await (c.desktopEngine?.saveFile(path) ?? c.deviceEngine!.saveFile(path));
      if (mounted && where != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${p.basename(path)}')));
      }
    } on PlatformException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    } on FileSystemException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Allow "Install unknown apps" for iLoveHTML in the screen that opened, then tap Install again.'),
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
                  segments: const [
                    ButtonSegment(value: BuildVariant.debug, label: Text('Debug'), icon: Icon(Icons.bug_report_outlined)),
                    ButtonSegment(value: BuildVariant.release, label: Text('Release'), icon: Icon(Icons.verified_outlined)),
                  ],
                  selected: {_variant},
                  onSelectionChanged: (s) => setState(() => _variant = s.single),
                ),
                const SizedBox(height: 12),
                Text('${m.android.applicationId} · v${m.android.versionName} (${m.android.versionCode})',
                    style: monoStyle(context, size: 12)),
                const SizedBox(height: 4),
                if (_variant == BuildVariant.debug)
                  Text('For testing. Signed with a debug key that stays on this device; '
                      'not for publishing.',
                      style: t.bodySmall)
                else ...[
                  Text('For publishing. Signed with your release key; every later update must use the same key '
                      'and a higher version code.',
                      style: t.bodySmall),
                  const SizedBox(height: 12),
                  SegmentedButton<ArtifactFormat>(
                    segments: const [
                      ButtonSegment(value: ArtifactFormat.apk, label: Text('APK')),
                      ButtonSegment(value: ArtifactFormat.aab, label: Text('App Bundle (Play)')),
                    ],
                    selected: {_format},
                    onSelectionChanged: (s) => setState(() => _format = s.single),
                  ),
                  if (_format == ArtifactFormat.aab)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Upload the .aab to Google Play Console. It cannot be installed directly; '
                          'use an APK to test on a phone.',
                          style: t.bodySmall),
                    ),
                  const SizedBox(height: 12),
                  if (_keys == null)
                    const LinearProgressIndicator()
                  else if (_keys!.isEmpty)
                    OutlinedButton.icon(
                      onPressed: _openKeys,
                      icon: const Icon(Icons.key),
                      label: const Text('Create or import a release key'),
                    )
                  else
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _keyId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Release key'),
                          items: [
                            for (final k in _keys!)
                              DropdownMenuItem(value: k.id, child: Text('${k.alias} · ${k.shortSha256}', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _keyId = v),
                        ),
                      ),
                      IconButton(tooltip: 'Manage keys', onPressed: _openKeys, icon: const Icon(Icons.settings_outlined)),
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
                      ? 'Building…'
                      : _variant == BuildVariant.debug
                          ? 'Build debug APK'
                          : _format == ArtifactFormat.aab
                              ? 'Build App Bundle'
                              : 'Build release APK'),
                ),
                if (widget.controller.engine == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Building is not available on this platform yet.', style: t.bodySmall),
                  ),
                if (widget.controller.desktopEngine?.problems case final problems? when problems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Cannot build yet:\n${problems.join('\n')}',
                        style: t.bodySmall?.copyWith(color: scheme.error)),
                  ),
                if (_building) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
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
                    if (widget.controller.desktopEngine case final desktop?) ...[
                      FilledButton.tonalIcon(
                        onPressed: () => _save(apkPath),
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save as…'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => desktop.showInFolder(apkPath),
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('Show in folder'),
                      ),
                    ] else ...[
                    if (!apkPath.endsWith('.aab'))
                      FilledButton.tonalIcon(
                        onPressed: () => _install(apkPath),
                        icon: const Icon(Icons.install_mobile),
                        label: const Text('Install'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _save(apkPath),
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save to device'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.controller.deviceEngine!.share(apkPath),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
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
              title: Text('v${b.versionName ?? '?'} (${b.versionCode ?? '?'}) · ${b.variant} ${b.format.toUpperCase()} · '
                  '${b.status} · ${b.durationMs} ms'),
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
