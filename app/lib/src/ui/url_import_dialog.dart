import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';

import '../app_controller.dart';
import 'theme.dart';

/// Adds https:// when the user typed only a host, e.g. "example.com".
String normalizeUrlInput(String input) {
  final t = input.trim();
  return t.contains('://') ? t : 'https://$t';
}

/// Checks a live website and collects the app name and package ID.
/// Pops with the new project's id, or null when cancelled.
class UrlImportDialog extends StatefulWidget {
  const UrlImportDialog({super.key, required this.controller, this.probe});

  final AppController controller;

  /// Injected in tests; defaults to the real network check.
  final UrlProbe? probe;

  @override
  State<UrlImportDialog> createState() => _UrlImportDialogState();
}

class _UrlImportDialogState extends State<UrlImportDialog> {
  final _form = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _name = TextEditingController();
  final _id = TextEditingController();
  bool _checking = false;
  bool _idEdited = false;
  String? _error;
  UrlProbeResult? _result;

  @override
  void dispose() {
    for (final c in [_url, _name, _id]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _check() async {
    final url = normalizeUrlInput(_url.text);
    final syntax = validateRemoteUrl(url);
    if (syntax != null) {
      setState(() => _error = syntax);
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await (widget.probe ?? UrlProbe()).probe(url);
      if (!mounted) return;
      setState(() {
        _result = r;
        final title = r.title ?? r.finalUrl.host;
        _name.text = title.length > 30 ? title.substring(0, 30).trim() : title;
        if (!_idEdited) _id.text = suggestApplicationId(_name.text);
      });
    } on UrlProbeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _create() {
    if (!_form.currentState!.validate()) return;
    try {
      final project = widget.controller.createFromUrl(_result!.finalUrl.toString(), _name.text.trim(), _id.text.trim());
      Navigator.pop(context, project.manifest.id);
    } on InvalidProjectException catch (e) {
      setState(() => _error = e.issues.join('\n'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final r = _result;
    return AlertDialog(
      title: const Text('Website URL'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'https://…', hintText: 'example.com'),
              keyboardType: TextInputType.url,
              autocorrect: false,
              enabled: !_checking,
              onSubmitted: (_) => _check(),
              onChanged: (_) {
                if (_result != null) setState(() => _result = null);
              },
            ),
            const SizedBox(height: 12),
            if (r == null)
              FilledButton.tonal(
                onPressed: _checking ? null : _check,
                child: _checking
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Check website'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            if (r != null) ...[
              Row(children: [
                Icon(r.ok ? Icons.check_circle_outline : Icons.warning_amber, size: 18,
                    color: r.ok ? scheme.primary : scheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(r.ok ? 'Website reachable' : 'Website answered with HTTP ${r.statusCode}')),
              ]),
              const SizedBox(height: 4),
              Text(r.finalUrl.toString(), style: monoStyle(context, size: 12)),
              if (r.redirects.isNotEmpty)
                Text('Redirected ${r.redirects.length}× — the app will start at this address.', style: t.bodySmall),
              const SizedBox(height: 8),
              Text('The app shows this site live and needs an internet connection. '
                  'It does not work offline.', style: t.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'App name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                onChanged: (v) {
                  if (!_idEdited) _id.text = suggestApplicationId(v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _id,
                decoration: const InputDecoration(labelText: 'Package ID'),
                style: monoStyle(context, size: 14),
                autocorrect: false,
                validator: (v) => validateApplicationId((v ?? '').trim()),
                onChanged: (_) => _idEdited = true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (r != null) FilledButton(onPressed: _create, child: const Text('Create')),
      ],
    );
  }
}
