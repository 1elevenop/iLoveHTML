import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';

import 'l10n.dart';
import 'theme.dart';

/// Windows has no embedded WebView plugin here, so the preview opens in the
/// default browser. Local sites are served by the same loopback-only,
/// token-protected [PreviewServer] the phone uses; it stops when the dialog closes.
Future<void> openBrowserPreview(BuildContext context, ProjectHandle project) async {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(url.toString(), style: monoStyle(c, size: 12)),
              const SizedBox(height: 12),
              Text(server == null ? context.l10n.liveSiteOpened : context.l10n.servedFromPc),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(context.l10n.missingFiles, style: Theme.of(c).textTheme.titleSmall),
                for (final f in missing.take(8)) Text(f, style: monoStyle(c, size: 12)),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: Text(server == null ? context.l10n.close : context.l10n.stopPreview),
            ),
          ],
        );
      },
    ),
  );
  await sub?.cancel();
  await server?.stop();
}
