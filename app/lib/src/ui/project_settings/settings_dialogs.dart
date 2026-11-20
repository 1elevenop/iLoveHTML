part of 'settings_wizard.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• $w', style: text.bodySmall),
                      ),
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
                          context.l10n.optimizeResult(
                            o.changed.length,
                            formatBytes(o.savedBytes),
                            formatBytes(o.totalBefore),
                            formatBytes(o.totalAfter),
                          ),
                          style: text.bodyMedium,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.close))],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 12),
        Text(value),
      ],
    ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                items: [
                  for (final page in widget.pages)
                    DropdownMenuItem(
                      value: page,
                      child: Text(page, overflow: TextOverflow.ellipsis),
                    ),
                ],
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
          ],
        ),
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
