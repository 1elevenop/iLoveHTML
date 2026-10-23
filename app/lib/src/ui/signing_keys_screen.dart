import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../engine/signing_keys.dart';
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
        title: const Text('Back up this key now'),
        content: const Text(
            'Every update of an app must be signed with the same key. If this device is lost or iLoveHTML is '
            'uninstalled, the key is gone unless you have a backup.\n\n'
            'Save the .jks file somewhere safe (not only on this device) and keep the password separately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Later')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save backup')),
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
        _snack('Imported "${key.alias}"');
      }
    } finally {
      tmp.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  Future<void> _export(SigningKey key) async {
    try {
      final where = await widget.keys.exportKey(key.id);
      if (mounted && where != null) _snack('Backup saved as ${key.alias}.jks. Keep the password with it, separately.');
    } on PlatformException catch (e) {
      if (mounted) _snack('Backup failed: ${e.message}');
    } on KeyManagerException catch (e) {
      if (mounted) _snack('Backup failed: ${e.message}');
    }
  }

  Future<void> _delete(SigningKey key) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _DeleteKeyDialog(keyInfo: key));
    if (ok != true) return;
    try {
      await widget.keys.deleteKey(key.id);
      await _load();
      if (mounted) _snack('Deleted "${key.alias}" from this device');
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
            _Field('Certificate', key.subject),
            _Field('SHA-256 fingerprint', key.sha256, mono: true),
            _Field('SHA-1 fingerprint', key.sha1, mono: true),
            _Field('Valid until', _date(key.notAfter)),
            _Field('Added', '${_date(key.createdAt)} (${key.origin})'),
            const SizedBox(height: 16),
            Row(children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  _export(key);
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Save backup (.jks)'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  _delete(key);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
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
      appBar: AppBar(title: const Text('Release keys')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.key),
        label: const Text('Create key'),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : keys == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Text(
                      'Release builds are signed with one of these keys. Google Play and Android only accept '
                      'updates signed with the same key as the first release. '
                      '${Platform.isWindows ? 'Keys stay on this PC, with passwords encrypted for your Windows account' : 'Keys stay on this phone, encrypted with Android Keystore'}'
                      '; a backup is a password-protected .jks file that works with iLoveHTML on a phone or a '
                      'computer, Gradle and keytool.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Import .jks / .keystore / .p12'),
                    ),
                    const SizedBox(height: 12),
                    if (keys.isEmpty)
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No release keys yet'))),
                    for (final k in keys)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.vpn_key_outlined),
                          title: Text(k.alias),
                          subtitle: Text('${k.subject}\nSHA-256 ${k.shortSha256} · valid until ${_date(k.notAfter)}'),
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

String? _validatePassword(String? v) => (v ?? '').length < 8 ? 'At least 8 characters' : null;

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
      title: const Text('Create release key'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _alias,
            decoration: const InputDecoration(labelText: 'Key alias'),
            autocorrect: false,
            validator: (v) => RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(v ?? '')
                ? null
                : 'Letters, digits, dots, dashes, underscores',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Your name or app publisher'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _org, decoration: const InputDecoration(labelText: 'Organization (optional)')),
          const SizedBox(height: 12),
          TextFormField(
            controller: _country,
            decoration: const InputDecoration(labelText: 'Country code (optional)', hintText: 'IN'),
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
            validator: (v) => (v ?? '').isEmpty || RegExp(r'^[A-Za-z]{2}$').hasMatch(v!) ? null : 'Two letters',
          ),
          TextFormField(
            controller: _pw,
            decoration: const InputDecoration(labelText: 'Password', helperText: 'Used for the keystore and the key'),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            validator: _validatePassword,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pw2,
            decoration: const InputDecoration(labelText: 'Repeat password'),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            validator: (v) => v == _pw.text ? null : 'Passwords do not match',
          ),
          const SizedBox(height: 8),
          Text('RSA 2048-bit, valid for 30 years. You will need this password to use the backup on a computer.',
              style: Theme.of(context).textTheme.bodySmall),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
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

  Future<void> _unlock() => _run(() async {
        final aliases = await widget.engine.inspectKeystore(widget.path, _storePw.text);
        if (aliases.isEmpty) throw const KeyManagerException('No private keys in this file');
        setState(() {
          _aliases = aliases;
          _alias = aliases.first;
        });
      });

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
      title: const Text('Import keystore'),
      scrollable: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.fileName, style: monoStyle(context, size: 13)),
        const SizedBox(height: 12),
        TextField(
          controller: _storePw,
          decoration: const InputDecoration(labelText: 'Keystore password'),
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
            decoration: const InputDecoration(labelText: 'Key alias'),
            items: [for (final a in aliases) DropdownMenuItem(value: a, child: Text(a))],
            onChanged: (v) => setState(() => _alias = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyPw,
            decoration: const InputDecoration(
              labelText: 'Key password',
              helperText: 'Leave empty if it is the same as the keystore password',
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 8),
          Text('iLoveHTML keeps a copy protected by the keystore password. Your original file is not changed.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : (aliases == null ? _unlock : _import),
          child: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(aliases == null ? 'Open' : 'Import'),
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
      title: const Text('Delete release key?'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Apps signed with "${widget.keyInfo.alias}" can only be updated with this exact key. '
            'Without a backup, you will never be able to update them again.'),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          decoration: InputDecoration(labelText: 'Type "${widget.keyInfo.alias}" to confirm'),
          autocorrect: false,
          onChanged: (_) => setState(() {}),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: match ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete key'),
        ),
      ],
    );
  }
}
