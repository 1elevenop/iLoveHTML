import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../engine/signing_keys.dart';
import 'l10n.dart';
import 'theme.dart';

/// Lists release keys and lets the user create, import, back up and delete them.
class SigningKeysScreen extends StatefulWidget {
  const SigningKeysScreen({super.key, required this.keys});

  final KeyManager keys;

  @override
  State<SigningKeysScreen> createState() => _SigningKeysScreenState();
}

class _SigningKeysScreenState extends State<SigningKeysScreen> {
  List<SigningKey>? _keys;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final keys = await widget.keys.listKeys();
      if (mounted) setState(() => _keys = keys);
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on KeyManagerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _create() async {
    final key = await showDialog<SigningKey>(context: context, builder: (_) => _CreateKeyDialog(engine: widget.keys));
    if (key == null || !mounted) return;
    await _load();
    if (!mounted) return;
    final backUp = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.backUpKeyNow),
        content: Text(
            context.l10n.backUpKeyBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.later)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.saveBackup)),
        ],
      ),
    );
    if (backUp == true) await _export(key);
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty || !mounted) return;
    // The Kotlin side only reads keystores from the app's cache directory
    // (Directory.systemTemp is a different folder on Android).
    final cache = await getTemporaryDirectory();
    final tmp = Directory(p.join(cache.path, 'key-import-${DateTime.now().microsecondsSinceEpoch}'))
      ..createSync(recursive: true);
    try {
      final path = p.join(tmp.path, 'keystore');
      await picked.single.xFile.saveTo(path);
      if (!mounted) return;
      final key = await showDialog<SigningKey>(
        context: context,
        builder: (_) => _ImportKeyDialog(engine: widget.keys, path: path, fileName: picked.single.name),
      );
      if (key != null) {
        await _load();
        if (!mounted) return;
        _snack(context.l10n.importedKey(key.alias));
      }
    } finally {
      tmp.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  Future<void> _export(SigningKey key) async {
    try {
      final where = await widget.keys.exportKey(key.id);
      if (mounted && where != null) _snack(context.l10n.backupSavedAs(key.alias));
    } on PlatformException catch (e) {
      if (mounted) _snack(context.l10n.backupFailed(e.message ?? ''));
    } on KeyManagerException catch (e) {
      if (mounted) _snack(context.l10n.backupFailed(e.message));
    }
  }

  Future<void> _delete(SigningKey key) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _DeleteKeyDialog(keyInfo: key));
    if (ok != true) return;
    try {
      await widget.keys.deleteKey(key.id);
      await _load();
      if (mounted) _snack(context.l10n.deletedKey(key.alias));
    } on PlatformException catch (e) {
      if (mounted) _snack('${e.message}');
    } on KeyManagerException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _details(SigningKey key) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(key.alias, style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 12),
            _Field(context.l10n.certificate, key.subject),
            _Field(context.l10n.sha256Fingerprint, key.sha256, mono: true),
            _Field(context.l10n.sha1Fingerprint, key.sha1, mono: true),
            _Field(context.l10n.validUntil, _date(key.notAfter)),
            _Field(context.l10n.added, '${_date(key.createdAt)} (${key.origin})'),
            const SizedBox(height: 16),
            Row(children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  _export(key);
                },
                icon: const Icon(Icons.save_alt),
                label: Text(context.l10n.saveBackupJks),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  _delete(key);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l10n.delete),
                style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.releaseKeys)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.key),
        label: Text(context.l10n.createKey),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : keys == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Text(
                      Platform.isWindows ? context.l10n.releaseKeysIntroWindows : context.l10n.releaseKeysIntroAndroid,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(context.l10n.importKeystoreFile),
                    ),
                    const SizedBox(height: 12),
                    if (keys.isEmpty)
                      Padding(padding: EdgeInsets.all(24), child: Center(child: Text(context.l10n.noReleaseKeys))),
                    for (final k in keys)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.vpn_key_outlined),
                          title: Text(k.alias),
                          subtitle: Text('${k.subject}\nSHA-256 ${k.shortSha256} · ${context.l10n.validUntilDate(_date(k.notAfter))}'),
                          isThreeLine: true,
                          onTap: () => _details(k),
                        ),
                      ),
                  ],
                ),
    );
  }
}

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          SelectableText(value, style: mono ? monoStyle(context, size: 12) : null),
        ]),
      );
}

String? _validatePassword(BuildContext context, String? v) => (v ?? '').length < 8 ? context.l10n.atLeast8 : null;

class _CreateKeyDialog extends StatefulWidget {
  const _CreateKeyDialog({required this.engine});

  final KeyManager engine;

  @override
  State<_CreateKeyDialog> createState() => _CreateKeyDialogState();
}

class _CreateKeyDialogState extends State<_CreateKeyDialog> {
  final _form = GlobalKey<FormState>();
  final _alias = TextEditingController(text: 'upload');
  final _name = TextEditingController();
  final _org = TextEditingController();
  final _country = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_alias, _name, _org, _country, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final key = await widget.engine.createKey(
        alias: _alias.text.trim(),
        commonName: _name.text.trim(),
        organization: _org.text.trim(),
        country: _country.text.trim(),
        password: _pw.text,
      );
      if (mounted) Navigator.pop(context, key);
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on KeyManagerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.createReleaseKey),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _alias,
            decoration: InputDecoration(labelText: context.l10n.keyAlias),
            autocorrect: false,
            validator: (v) => RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(v ?? '')
                ? null
                : context.l10n.keyAliasHelp,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: context.l10n.publisherNameField),
            validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _org, decoration: InputDecoration(labelText: context.l10n.organizationOptional)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _country,
            decoration: InputDecoration(labelText: context.l10n.countryCodeOptional, hintText: 'IN'),
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
            validator: (v) => (v ?? '').isEmpty || RegExp(r'^[A-Za-z]{2}$').hasMatch(v!) ? null : context.l10n.twoLetters,
          ),
          TextFormField(
            controller: _pw,
            decoration: InputDecoration(labelText: context.l10n.password, helperText: context.l10n.passwordHelp),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            validator: (v) => _validatePassword(context, v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pw2,
            decoration: InputDecoration(labelText: context.l10n.repeatPassword),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            validator: (v) => v == _pw.text ? null : context.l10n.passwordsDoNotMatch,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.createKeyNote,
              style: Theme.of(context).textTheme.bodySmall),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.l10n.create),
        ),
      ],
    );
  }
}

class _ImportKeyDialog extends StatefulWidget {
  const _ImportKeyDialog({required this.engine, required this.path, required this.fileName});

  final KeyManager engine;
  final String path;
  final String fileName;

  @override
  State<_ImportKeyDialog> createState() => _ImportKeyDialogState();
}

class _ImportKeyDialogState extends State<_ImportKeyDialog> {
  final _storePw = TextEditingController();
  final _keyPw = TextEditingController();
  List<String>? _aliases;
  String? _alias;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _storePw.dispose();
    _keyPw.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on KeyManagerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlock() {
    final noKeys = context.l10n.noPrivateKeys;
    return _run(() async {
        final aliases = await widget.engine.inspectKeystore(widget.path, _storePw.text);
        if (aliases.isEmpty) throw KeyManagerException(noKeys);
        setState(() {
          _aliases = aliases;
          _alias = aliases.first;
        });
      });
  }

  Future<void> _import() => _run(() async {
        final key = await widget.engine.importKey(
          path: widget.path,
          storePassword: _storePw.text,
          alias: _alias!,
          keyPassword: _keyPw.text.isEmpty ? _storePw.text : _keyPw.text,
        );
        if (mounted) Navigator.pop(context, key);
      });

  @override
  Widget build(BuildContext context) {
    final aliases = _aliases;
    return AlertDialog(
      title: Text(context.l10n.importKeystore),
      scrollable: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.fileName, style: monoStyle(context, size: 13)),
        const SizedBox(height: 12),
        TextField(
          controller: _storePw,
          decoration: InputDecoration(labelText: context.l10n.keystorePassword),
          obscureText: true,
          enabled: aliases == null && !_busy,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => _unlock(),
        ),
        if (aliases != null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _alias,
            decoration: InputDecoration(labelText: context.l10n.keyAlias),
            items: [for (final a in aliases) DropdownMenuItem(value: a, child: Text(a))],
            onChanged: (v) => setState(() => _alias = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyPw,
            decoration: InputDecoration(
              labelText: context.l10n.keyPassword,
              helperText: context.l10n.keyPasswordHelp,
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.importKeystoreNote,
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: _busy ? null : (aliases == null ? _unlock : _import),
          child: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(aliases == null ? context.l10n.open : context.l10n.importButton),
        ),
      ],
    );
  }
}

/// Deleting a release key is irreversible; require typing its alias.
class _DeleteKeyDialog extends StatefulWidget {
  const _DeleteKeyDialog({required this.keyInfo});

  final SigningKey keyInfo;

  @override
  State<_DeleteKeyDialog> createState() => _DeleteKeyDialogState();
}

class _DeleteKeyDialogState extends State<_DeleteKeyDialog> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = _confirm.text == widget.keyInfo.alias;
    return AlertDialog(
      title: Text(context.l10n.deleteReleaseKey),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.deleteKeyBody(widget.keyInfo.alias)),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          decoration: InputDecoration(labelText: context.l10n.typeToConfirm(widget.keyInfo.alias)),
          autocorrect: false,
          onChanged: (_) => setState(() {}),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: match ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: Text(context.l10n.deleteKey),
        ),
      ],
    );
  }
}
