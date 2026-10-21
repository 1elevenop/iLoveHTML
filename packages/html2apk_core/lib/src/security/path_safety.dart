import 'package:path/path.dart' as p;

const _windowsReserved = {
  'con', 'prn', 'aux', 'nul', //
  'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
  'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
};

/// Normalizes an untrusted relative path (e.g. a ZIP entry name) to a
/// portable POSIX path, or throws [UnsafePathException].
///
/// Rejects absolute paths, drive letters, `..` traversal, NUL and control
/// characters, and names that cannot exist on Windows, so a project stays
/// portable between Windows and Android.
String normalizeRelativePath(String raw) {
  if (raw.isEmpty) throw UnsafePathException(raw, 'empty path');
  if (raw.contains(RegExp(r'[\x00-\x1f]'))) throw UnsafePathException(raw, 'control character');
  final unified = raw.replaceAll('\\', '/');
  if (unified.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(unified)) {
    throw UnsafePathException(raw, 'absolute path');
  }
  final parts = <String>[];
  for (final part in unified.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') throw UnsafePathException(raw, 'parent traversal');
    if (part.contains(RegExp(r'[<>:"|?*]'))) throw UnsafePathException(raw, 'invalid character');
    if (part.endsWith('.') || part.endsWith(' ')) throw UnsafePathException(raw, 'trailing dot or space');
    if (_windowsReserved.contains(part.split('.').first.toLowerCase())) {
      throw UnsafePathException(raw, 'reserved device name');
    }
    parts.add(part);
  }
  if (parts.isEmpty) throw UnsafePathException(raw, 'empty path');
  return parts.join('/');
}

/// Resolves [relative] (already normalized) under [root] and verifies the
/// result stays inside [root].
String resolveWithin(String root, String relative) {
  final rootAbs = p.normalize(p.absolute(root));
  final target = p.normalize(p.join(rootAbs, p.joinAll(relative.split('/'))));
  if (!p.isWithin(rootAbs, target)) throw UnsafePathException(relative, 'escapes destination');
  return target;
}

class UnsafePathException implements Exception {
  UnsafePathException(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'Unsafe path "$path": $reason';
}
