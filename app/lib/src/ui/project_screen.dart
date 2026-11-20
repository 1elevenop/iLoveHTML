import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import '../engine/msix_builder.dart';
import '../engine/on_device_engine.dart';
import '../app_settings.dart';
import 'ascii.dart';
import 'browser_preview.dart';
import 'editor/editor_screen.dart';
import 'preview_screen.dart';
import 'project_settings/settings_wizard.dart';
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
                if (project.manifest.source.type == SourceType.local)
                  IconButton(
                    tooltip: context.l10n.editCode,
                    icon: const Icon(Icons.code),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditorScreen(controller: controller, projectId: projectId))),
                  ),
                IconButton(
                  tooltip: context.l10n.backUpProject,
                  icon: const Icon(Icons.backup_outlined),
                  onPressed: () => _backUp(context, controller.project(projectId)!),
                ),
                IconButton(
                  tooltip: context.l10n.preview,
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => Platform.isWindows
                      ? openBrowserPreview(context, controller.project(projectId)!)
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
              ProjectSettingsWizard(key: ValueKey('settings-$projectId'), controller: controller, project: project),
              _BuildTab(controller: controller, project: project),
            ]),
          ),
        );
      },
    );
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
