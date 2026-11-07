import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ascii.dart';
import 'l10n.dart';
import 'theme.dart';

const buyMeACoffeeUrl = 'https://buymeacoffee.com/1elevenop';

/// Step-by-step guide from website to installed app.
class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final e = context.eleven;
    final steps = [
      (l.howToStep1Title, l.howToStep1Body),
      (l.howToStep2Title, l.howToStep2Body),
      (l.howToStep3Title, l.howToStep3Body),
      (l.howToStep4Title, l.howToStep4Body),
      (l.howToStep5Title, l.howToStep5Body),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.howToUse)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, (title, body)) in steps.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('[${i + 1}]', style: monoStyle(context, size: 14).copyWith(color: e.acc, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(body, style: t.bodyMedium),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          const Divider(),
          const SizedBox(height: 12),
          Text(l.howToTipsTitle, style: t.titleSmall),
          const SizedBox(height: 8),
          Text(l.howToTips, style: t.bodyMedium),
        ],
      ),
    );
  }
}

/// A Terms of Use or Privacy Policy page. In [body], paragraphs are separated
/// by blank lines and a paragraph starting with "## " is a heading.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.l10n.lastUpdated('2026-11-07'), style: t.bodySmall),
            const SizedBox(height: 12),
            for (final para in body.split('\n\n'))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: para.startsWith('## ')
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(para.substring(3), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      )
                    : Text(para, style: t.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

/// Who made iLoveHTML, with the Buy Me a Coffee link.
class CreditCard extends StatelessWidget {
  const CreditCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final e = context.eleven;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.credit, style: t.titleSmall),
            const SizedBox(height: 8),
            Text(asciiTagline, style: monoStyle(context, size: 13).copyWith(color: e.acc)),
            const SizedBox(height: 8),
            Text(l.madeBy('1elevenop'), style: t.titleMedium),
            const SizedBox(height: 4),
            Text(l.supportHint, style: t.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => openExternal(context, buyMeACoffeeUrl),
              icon: const Icon(Icons.coffee_outlined),
              label: Text(l.buyMeACoffee),
            ),
            const SizedBox(height: 6),
            Text('buymeacoffee.com/1elevenop', style: monoStyle(context, size: 11).copyWith(color: e.mute)),
          ],
        ),
      ),
    );
  }
}

/// Opens [url] in the browser; shows a message if nothing can open it.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.couldNotOpenLink(url);
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
}
