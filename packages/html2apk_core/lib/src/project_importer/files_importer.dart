import 'dart:io';

import 'package:path/path.dart' as p;

import '../security/path_safety.dart';
import 'site_analysis.dart';
import 'zip_importer.dart';

class PlacementResult {
  PlacementResult(this.files, this.moved);

  /// Final site-relative paths.
  final List<String> files;

  /// Picked file name -> folder path it was moved to, e.g. `style.css` -> `css/style.css`.
  final Map<String, String> moved;
}

/// Copies individually picked files (an HTML page plus, optionally, its CSS,
/// JavaScript, images and fonts) into [destination], which must be empty.
///
/// Pickers return plain files without folders, while pages usually link
/// `css/style.css` or `images/logo.png`. After copying, any reference that
/// does not resolve but whose file name matches a picked file is satisfied by
/// moving that file to the referenced path, repeated so CSS moved into a
/// folder can pull in the images it references relative to its new place.
PlacementResult importLooseFiles(
  List<String> paths,
  String destination, {
  ExtractionLimits limits = const ExtractionLimits(),
}) {
  if (paths.isEmpty) throw ArchiveRejectedException('no files selected');
  if (paths.length > limits.maxEntries) throw ArchiveRejectedException('more than ${limits.maxEntries} files');
  final dest = Directory(destination);
  if (dest.existsSync() && dest.listSync().isNotEmpty) {
    throw ArgumentError.value(destination, 'destination', 'must be empty');
  }

  final names = <String, String>{}; // lower-case name -> source path
  var total = 0;
  for (final path in paths) {
    final name = p.basename(path);
    try {
      normalizeRelativePath(name);
    } on UnsafePathException catch (e) {
      throw ArchiveRejectedException(e.toString());
    }
    if (names.containsKey(name.toLowerCase())) throw ArchiveRejectedException('two files are named "$name"');
    final size = File(path).lengthSync();
    if (size > limits.maxFileBytes) throw ArchiveRejectedException('"$name" is too large');
    total += size;
    if (total > limits.maxTotalBytes) throw ArchiveRejectedException('selection too large');
    names[name.toLowerCase()] = path;
  }
  if (!names.keys.any((n) => n.endsWith('.html') || n.endsWith('.htm'))) {
    throw ArchiveRejectedException('select at least one .html file');
  }

  dest.createSync(recursive: true);
  for (final path in paths) {
    File(path).copySync(p.join(dest.path, p.basename(path)));
  }

  final moved = <String, String>{};
  // Paths are matched exactly, as in the built app. Where the disk ignores
  // letter case, a second spelling of a placed path lands on the same file;
  // remembering it stops the copy repeating every pass, and the import
  // report then lists it as a case mismatch.
  final placed = <String>{};
  for (var pass = 0; pass < 4; pass++) {
    final files = listRelativeFiles(dest.path);
    final existing = {...files, ...placed};
    var changed = false;
    for (final ref in collectLocalReferences(dest.path, files)) {
      final target = ref.target;
      if (existing.contains(target) || target.startsWith('..') || !target.contains('/')) continue;
      final name = p.posix.basename(target);
      final rootCopy = files.firstWhere((f) => f.toLowerCase() == name.toLowerCase(), orElse: () => '');
      if (rootCopy.isEmpty) continue;
      final String safe;
      try {
        safe = normalizeRelativePath(target);
      } on UnsafePathException {
        continue;
      }
      final out = File(resolveWithin(dest.path, safe));
      out.parent.createSync(recursive: true);
      File(p.join(dest.path, rootCopy)).copySync(out.path);
      existing.add(safe);
      placed.add(safe);
      moved[rootCopy] = safe;
      changed = true;
    }
    if (!changed) break;
  }

  // Remove root copies that were moved and are not also referenced at the
  // root, in any letter case (a case mismatch is reported, not deleted).
  final files = listRelativeFiles(dest.path);
  final referenced = collectLocalReferences(dest.path, files).map((r) => r.target.toLowerCase()).toSet();
  for (final name in moved.keys) {
    final lower = name.toLowerCase();
    if (!referenced.contains(lower) && !lower.endsWith('.html') && !lower.endsWith('.htm')) {
      File(p.join(dest.path, name)).deleteSync();
    }
  }
  return PlacementResult(listRelativeFiles(dest.path), moved);
}
