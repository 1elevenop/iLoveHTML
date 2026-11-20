import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../../app_controller.dart';
import '../../image_import.dart';
import '../brutal.dart';
import '../l10n.dart';
import '../theme.dart';

part 'settings_dialogs.dart';

// ---------------------------------------------------------------- Settings

class ProjectSettingsWizard extends StatefulWidget {
  const ProjectSettingsWizard({super.key, required this.controller, required this.project});

  final AppController controller;
  final ProjectHandle project;

  @override
  State<ProjectSettingsWizard> createState() => _ProjectSettingsWizardState();
}

class _ProjectSettingsWizardState extends State<ProjectSettingsWizard> with AutomaticKeepAliveClientMixin {
  /// One form per step, all kept mounted so Save validates every step.
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  var _step = 0;
  var _flagged = <int>{};
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
    for (final c in [
      _name,
      _id,
      _versionName,
      _versionCode,
      _ua,
      _galleryFolder,
      _shareTarget,
      _siteUrl,
      _hosts,
      _bridgeHosts,
      _statusColor,
      _navColor,
      _splashColor,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _change(ProjectManifest m) => setState(() {
    _m = m;
    _dirty = true;
  });

  /// The manifest the form describes now; [versionCode] falls back while it is being typed.
  ProjectManifest _collect() {
    final ua = _ua.text.trim();
    final folder = _galleryFolder.text.trim();
    final target = _shareTarget.text.trim();
    return _m.copyWith(
      name: _name.text.trim(),
      source: _m.source.type == SourceType.url ? ProjectSource.url(_siteUrl.text.trim()) : null,
      android: AndroidSettings(
        applicationId: _id.text.trim(),
        versionName: _versionName.text.trim(),
        versionCode: int.tryParse(_versionCode.text.trim()) ?? _m.android.versionCode,
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
  }

  void _save() {
    // Validate every step (not just the visible one) and jump to the first with an error.
    final failed = {
      for (final (i, f) in _forms.indexed)
        if (!f.currentState!.validate()) i,
    };
    setState(() => _flagged = failed);
    if (failed.isNotEmpty) {
      setState(() => _step = failed.reduce((a, b) => a < b ? a : b));
      return;
    }
    final m = _collect();
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
    setState(
      () => _m = _m.copyWith(
        iconPath: s.iconPath,
        splashPath: () => s.splashPath,
        offlineFallbackPage: () => s.offlineFallbackPage,
      ),
    );
  }

  ProjectHandle get _current => widget.controller.project(_m.id)!;

  /// Picks a new ZIP or HTML files and swaps them in for the website.
  Future<void> _replaceWebsite() async {
    final l = context.l10n;
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
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
        _m = _m.copyWith(source: s.source, shortcuts: s.shortcuts, offlineFallbackPage: () => s.offlineFallbackPage);
      });
      await showDialog<void>(
        context: context,
        builder: (_) => _ReplaceSummary(report: r),
      );
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
  Future<void> _pickFile(
    List<String> extensions,
    ProjectHandle Function(String path) apply,
    String done, {
    Future<Uint8List> Function(Uint8List bytes, String extension)? convert,
  }) async {
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
    pickableImageExtensions,
    (f) => widget.controller.setIcon(_current, f),
    context.l10n.iconUpdated,
    convert: (b, ext) => toPng(b, isSvg: ext == 'svg', square: true, maxSide: 1024),
  );

  Future<void> _pickSplash() => _pickFile(
    pickableImageExtensions,
    (f) => widget.controller.setSplash(_current, f),
    context.l10n.splashUpdated,
    convert: (b, ext) => toPng(b, isSvg: ext == 'svg', maxSide: 1440),
  );

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
    final l = context.l10n;
    final labels = [l.stepBasics, l.stepLook, l.stepFeatures, l.stepFinish];
    final steps = [_basicsStep, _lookStep, _featuresStep, _finishStep];
    return Scaffold(
      floatingActionButton: _dirty
          ? FloatingActionButton.extended(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(l.save))
          : null,
      body: LayoutBuilder(
        builder: (context, box) {
          // Readable line length on wide windows.
          final side = box.maxWidth > 792 ? (box.maxWidth - 760) / 2 : 16.0;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(side, 16, side, 8),
                child: StepProgressBar(labels: labels, current: _step, flagged: _flagged, onSelect: _go),
              ),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    for (final (i, build) in steps.indexed)
                      Form(
                        key: _forms[i],
                        onChanged: () => setState(() => _dirty = true),
                        child: ListView(
                          key: PageStorageKey('settings-step-$i'),
                          padding: EdgeInsets.fromLTRB(side, 8, side, 96),
                          children: [
                            ...build(context),
                            const SizedBox(height: 24),
                            _stepNav(context, i, labels.length),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _go(int step) => setState(() => _step = step);

  Widget _stepNav(BuildContext context, int i, int count) {
    final l = context.l10n;
    return Row(
      children: [
        if (i > 0)
          OutlinedButton.icon(onPressed: () => _go(i - 1), icon: const Icon(Icons.arrow_back), label: Text(l.back)),
        const Spacer(),
        if (i < count - 1) BrutalButton(label: l.next, icon: Icons.arrow_forward, onPressed: () => _go(i + 1)),
      ],
    );
  }

  /// A titled block of related settings.
  Widget _group(BuildContext context, String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: BrutalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  /// Changed manifest values, as "path: old → new" lines.
  List<String> _changes() {
    final before = _flatten(_current.manifest.toJson());
    final after = _flatten(_collect().toJson());
    return [
      for (final k in {...before.keys, ...after.keys})
        if ('${before[k]}' != '${after[k]}') '$k: ${before[k] ?? '–'} → ${after[k] ?? '–'}',
    ];
  }

  static Map<String, Object?> _flatten(Map<String, Object?> json, [String prefix = '']) => {
    for (final MapEntry(:key, :value) in json.entries)
      if (value is Map<String, Object?>) ..._flatten(value, '$prefix$key.') else '$prefix$key': value,
  };

  List<Widget> _basicsStep(BuildContext context) {
    final l = context.l10n;
    final local = _m.source.type == SourceType.local;
    final icon = widget.controller.project(_m.id)?.iconFile;
    return [
      _group(context, l.sectionApp, [
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
        Row(
          children: [
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
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.square(
                dimension: 64,
                child: icon != null && File(icon).existsSync()
                    ? Image.file(File(icon), fit: BoxFit.cover, key: ValueKey(File(icon).lastModifiedSync()))
                    : ColoredBox(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.android, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                icon == null ? context.l10n.defaultIcon : context.l10n.customIcon,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickIcon,
              icon: const Icon(Icons.image_outlined),
              label: Text(context.l10n.chooseImage),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(context.l10n.iconHint, style: Theme.of(context).textTheme.bodySmall),
        ),
      ]),
      _group(context, l.sectionContent, [
        if (local) ...[
          DropdownButtonFormField<String>(
            // Rebuilt when the website is replaced and the pages change.
            key: ValueKey(_pages.join('|')),
            initialValue: _pages.contains(_m.source.entry) ? _m.source.entry : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.l10n.startPage),
            items: [
              for (final page in _pages)
                DropdownMenuItem(
                  value: page,
                  child: Text(page, overflow: TextOverflow.ellipsis),
                ),
            ],
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
            decoration: InputDecoration(labelText: context.l10n.websiteUrl, helperText: context.l10n.loadedLive),
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
      ]),
    ];
  }

  List<Widget> _lookStep(BuildContext context) {
    final l = context.l10n;
    return [
      _group(context, l.sectionAppearance, [
        _ColorField(
          label: context.l10n.statusBarColour,
          controller: _statusColor,
          onChanged: () => setState(() => _dirty = true),
        ),
        const SizedBox(height: 12),
        _ColorField(
          label: context.l10n.navBarColour,
          controller: _navColor,
          onChanged: () => setState(() => _dirty = true),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.splashScreen),
          subtitle: Text(_m.splashPath == null ? context.l10n.splashIconHint : context.l10n.splashImageHint),
          value: _m.appearance.splashEnabled,
          onChanged: (v) => _change(_m.copyWith(appearance: _m.appearance.copyWith(splashEnabled: v))),
        ),
        if (_m.appearance.splashEnabled) ...[
          _ColorField(
            label: context.l10n.splashBackground,
            controller: _splashColor,
            onChanged: () => setState(() => _dirty = true),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickSplash,
                icon: const Icon(Icons.image_outlined),
                label: Text(_m.splashPath == null ? context.l10n.chooseSplash : context.l10n.replaceSplash),
              ),
              if (_m.splashPath != null)
                TextButton(
                  onPressed: () => _clearFile(widget.controller.clearSplash),
                  child: Text(context.l10n.useAppIcon),
                ),
            ],
          ),
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
          child: Text(context.l10n.themeHint, style: Theme.of(context).textTheme.bodySmall),
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
      ]),
      _group(context, l.sectionDevices, [
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
      ]),
    ];
  }

  List<Widget> _featuresStep(BuildContext context) {
    final l = context.l10n;
    final local = _m.source.type == SourceType.local;
    return [
      _group(context, l.groupCore, [
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
      ]),
      _group(context, l.groupNavigation, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.openOtherSites),
          subtitle: Text(context.l10n.openOtherSitesHint),
          value: _m.webView.externalLinks == ExternalLinkPolicy.browser,
          onChanged: (v) => _change(
            _m.copyWith(
              webView: _m.webView.copyWith(externalLinks: v ? ExternalLinkPolicy.browser : ExternalLinkPolicy.block),
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.pullToRefresh),
          subtitle: Text(context.l10n.pullToRefreshHint),
          value: _m.webView.pullToRefresh,
          onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(pullToRefresh: v))),
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
      ]),
      _group(context, l.groupMediaFiles, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.fileUploads),
          subtitle: Text(context.l10n.fileUploadsHint),
          value: _m.webView.fileUploads,
          onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(fileUploads: v))),
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
      ]),
      _group(context, l.groupEngagement, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.notifications),
          subtitle: Text(context.l10n.notificationsHint),
          value: _m.webView.notifications,
          onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(notifications: v))),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.share),
          subtitle: Text(context.l10n.shareHint),
          value: _m.webView.webShare,
          onChanged: (v) => _change(_m.copyWith(webView: _m.webView.copyWith(webShare: v))),
        ),
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
      ]),
      _group(context, l.sectionShortcuts, [
        Text(context.l10n.shortcutsHint, style: Theme.of(context).textTheme.bodySmall),
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
      ]),
      if (!local)
        _group(context, l.sectionOffline, [
          Text(
            _m.offlineFallbackPage == null
                ? context.l10n.offlineBuiltIn
                : context.l10n.offlinePageShown(_m.offlineFallbackPage!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickOfflinePage,
                icon: const Icon(Icons.cloud_off_outlined),
                label: Text(
                  _m.offlineFallbackPage == null ? context.l10n.chooseOfflinePage : context.l10n.replaceOfflinePage,
                ),
              ),
              if (_m.offlineFallbackPage != null)
                TextButton(
                  onPressed: () => _clearFile(widget.controller.clearOfflinePage),
                  child: Text(context.l10n.useBuiltInPage),
                ),
            ],
          ),
        ]),
    ];
  }

  List<Widget> _finishStep(BuildContext context) {
    final l = context.l10n;
    final local = _m.source.type == SourceType.local;
    return [
      _group(context, l.sectionSecurity, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.appLock),
          subtitle: Text(context.l10n.appLockHint),
          value: _m.appLock,
          onChanged: (v) => _change(_m.copyWith(appLock: v)),
        ),
      ]),
      if (local)
        _group(context, l.sectionAppSize, [
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
        ]),
      _group(context, l.groupAdvanced, [
        TextFormField(
          controller: _ua,
          decoration: InputDecoration(
            labelText: context.l10n.userAgentSuffix,
            hintText: context.l10n.example('MyApp/1.0'),
          ),
          validator: (v) => (v ?? '').length > 200 ? context.l10n.atMost200 : null,
        ),
      ]),
      _group(context, l.changesTitle, [
        if (_changes() case final changes when changes.isNotEmpty)
          for (final c in changes.take(20)) Text(c, style: monoStyle(context, size: 12))
        else
          Text(l.noChanges, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: BrutalButton(label: l.save, icon: Icons.save_outlined, onPressed: _dirty ? _save : null),
        ),
      ]),
      _group(context, l.sectionDanger, [
        OutlinedButton.icon(
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
          label: Text(context.l10n.deleteProject),
          style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        ),
      ]),
    ];
  }
}

List<String> _parseHosts(String text) =>
    text.split(RegExp(r'[,\s]+')).map((h) => h.trim().toLowerCase()).where((h) => h.isNotEmpty).toSet().toList();

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  color: current ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: outline),
                ),
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
        Wrap(
          spacing: 8,
          children: [
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
                      color: widget.controller.text.trim().toUpperCase() == hex
                          ? Theme.of(context).colorScheme.primary
                          : outline,
                      width: widget.controller.text.trim().toUpperCase() == hex ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
