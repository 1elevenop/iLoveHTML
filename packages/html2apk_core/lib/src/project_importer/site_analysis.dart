import 'dart:io';

import 'package:path/path.dart' as p;

/// Picks the most likely HTML entry point from a list of relative POSIX paths.
///
/// Returns candidates ordered by preference; the first one is the default.
/// The user can still choose another one manually.
List<String> findEntryCandidates(List<String> files) {
  final html = files.where((f) => RegExp(r'\.html?$', caseSensitive: false).hasMatch(f)).toList();
  int score(String f) {
    final depth = '/'.allMatches(f).length;
    final base = p.posix.basename(f).toLowerCase();
    final isIndex = base == 'index.html' || base == 'index.htm';
    return depth * 10 + (isIndex ? 0 : 5);
  }

  html.sort((a, b) {
    final c = score(a).compareTo(score(b));
    return c != 0 ? c : a.compareTo(b);
  });
  return html;
}

class MissingAsset {
  const MissingAsset(this.referencedFrom, this.reference);

  final String referencedFrom;
  final String reference;

  @override
  String toString() => '$referencedFrom -> $reference';
}

final _attrRef = RegExp(r'''\b(?:src|href|poster)\s*=\s*(?:"([^"]*)"|'([^']*)')''', caseSensitive: false);
final _cssUrl = RegExp(r'''url\(\s*(?:"([^"]*)"|'([^']*)'|([^)'"]*))\s*\)''', caseSensitive: false);

/// Finds relative references in HTML and CSS files that do not resolve to a
/// file under [root]. This is a lexical scan: references built at runtime
/// by JavaScript are not detected.
List<MissingAsset> findMissingAssets(String root, List<String> files) {
  final existing = files.map((f) => f.toLowerCase()).toSet();
  final missing = <MissingAsset>[];
  for (final file in files) {
    final lower = file.toLowerCase();
    final isHtml = lower.endsWith('.html') || lower.endsWith('.htm');
    final isCss = lower.endsWith('.css');
    if (!isHtml && !isCss) continue;
    final text = File(p.join(root, file)).readAsStringSync();
    final refs = <String>[
      if (isHtml) ..._attrRef.allMatches(text).map((m) => m.group(1) ?? m.group(2)!),
      ..._cssUrl.allMatches(text).map((m) => (m.group(1) ?? m.group(2) ?? m.group(3)!).trim()),
    ];
    for (final ref in refs) {
      final target = _resolveLocalRef(file, ref);
      if (target != null && !existing.contains(target.toLowerCase())) {
        missing.add(MissingAsset(file, ref));
      }
    }
  }
  return missing;
}

String? _resolveLocalRef(String fromFile, String ref) {
  if (ref.isEmpty || ref.startsWith('#') || ref.startsWith('//')) return null;
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(ref)) return null; // http:, data:, mailto: ...
  var path = ref.split(RegExp('[?#]')).first;
  if (path.isEmpty) return null;
  path = Uri.decodeFull(path);
  final joined = path.startsWith('/')
      ? path.substring(1)
      : p.posix.join(p.posix.dirname(fromFile), path);
  final normalized = p.posix.normalize(joined);
  if (normalized.startsWith('..')) return normalized;
  return normalized.endsWith('/') || normalized == '.' ? p.posix.join(normalized, 'index.html') : normalized;
}
