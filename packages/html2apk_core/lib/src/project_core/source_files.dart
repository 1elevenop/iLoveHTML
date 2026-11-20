import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../project_importer/zip_importer.dart' show listRelativeFiles;
import '../security/path_safety.dart';
import 'manifest.dart';
import 'project_store.dart';
import 'validation.dart' show shortcutFilePath;

/// File types the in-app editor opens: text formats of a website.
const editableExtensions = {'html', 'htm', 'css', 'js', 'mjs', 'json', 'svg', 'txt', 'md', 'webmanifest'};

/// Largest file the editor reads or writes.
const maxEditableBytes = 2 * 1024 * 1024;

bool isEditablePath(String path) => editableExtensions.contains(p.extension(path).replaceFirst('.', '').toLowerCase());

/// Why a source-file operation was refused. [message] is shown to the user.
class SourceFileException implements Exception {
  const SourceFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reading and changing a local project's website files from the in-app
/// editor. Every path is untrusted: it is normalized, kept inside `source/`,
/// never followed through a link, limited to text types and to 2 MB.
extension SourceFiles on ProjectStore {
  /// Editable files of the site, sorted, as POSIX paths relative to `source/`.
  List<String> listSourceFiles(ProjectHandle project) {
    _requireLocal(project);
    final dir = Directory(project.sourceDir);
    if (!dir.existsSync()) return const [];
    return [
      for (final f in listRelativeFiles(project.sourceDir))
        if (isEditablePath(f)) f,
    ];
  }

  String readSourceFile(ProjectHandle project, String path) {
    final file = File(_resolve(project, path, mustExist: true));
    if (file.lengthSync() > maxEditableBytes) throw const SourceFileException('File is larger than 2 MB');
    try {
      return utf8.decode(file.readAsBytesSync());
    } on FormatException {
      throw const SourceFileException('File is not UTF-8 text');
    }
  }

  /// Replaces an existing file's text. Written to a temporary file first and
  /// then renamed, so a crash never leaves half a file.
  void writeSourceFile(ProjectHandle project, String path, String content) =>
      _write(_resolve(project, path, mustExist: true), content);

  /// Adds a new file (and its folders). Refuses to overwrite.
  void createSourceFile(ProjectHandle project, String path, [String content = '']) {
    final target = _resolve(project, path, mustExist: false);
    if (FileSystemEntity.typeSync(target, followLinks: false) != FileSystemEntityType.notFound) {
      throw const SourceFileException('A file with that name already exists');
    }
    Directory(p.dirname(target)).createSync(recursive: true);
    _write(target, content);
  }

  void deleteSourceFile(ProjectHandle project, String path) {
    final rel = normalizeRelativePath(path);
    _requireNotInUse(project, rel);
    File(_resolve(project, rel, mustExist: true)).deleteSync();
  }

  void renameSourceFile(ProjectHandle project, String from, String to) {
    final rel = normalizeRelativePath(from);
    _requireNotInUse(project, rel);
    final source = _resolve(project, rel, mustExist: true);
    final target = _resolve(project, to, mustExist: false);
    if (FileSystemEntity.typeSync(target, followLinks: false) != FileSystemEntityType.notFound) {
      throw const SourceFileException('A file with that name already exists');
    }
    Directory(p.dirname(target)).createSync(recursive: true);
    File(source).renameSync(target);
  }

  void _requireLocal(ProjectHandle project) {
    if (project.manifest.source.type != SourceType.local) {
      throw const SourceFileException('Only projects with website files can be edited');
    }
  }

  /// The start page, offline page and shortcut pages must keep existing.
  void _requireNotInUse(ProjectHandle project, String rel) {
    final m = project.manifest;
    final used = {
      m.source.entry,
      if (m.offlineFallbackPage != null) m.offlineFallbackPage!,
      for (final s in m.shortcuts) shortcutFilePath(s.page),
    };
    if (used.any((u) => u.toLowerCase() == rel.toLowerCase())) {
      throw SourceFileException(
        rel.toLowerCase() == m.source.entry.toLowerCase()
            ? 'This is the start page. Choose another start page first.'
            : 'This page is used by a shortcut or as the offline page.',
      );
    }
  }

  String _resolve(ProjectHandle project, String raw, {required bool mustExist}) {
    _requireLocal(project);
    final String rel;
    final String target;
    try {
      rel = normalizeRelativePath(raw);
      target = resolveWithin(project.sourceDir, rel);
    } on UnsafePathException catch (e) {
      throw SourceFileException('Not a valid file name: ${e.reason}');
    }
    if (!isEditablePath(rel)) {
      throw SourceFileException('Only ${(editableExtensions.toList()..sort()).join(', ')} files can be edited');
    }
    // No component of the path may be a link (symlink or Windows junction).
    var current = p.normalize(p.absolute(project.sourceDir));
    for (final part in rel.split('/')) {
      current = p.join(current, part);
      if (FileSystemEntity.typeSync(current, followLinks: false) == FileSystemEntityType.link) {
        throw const SourceFileException('Links are not followed');
      }
    }
    final exists = FileSystemEntity.typeSync(target, followLinks: false) == FileSystemEntityType.file;
    if (mustExist && !exists) throw SourceFileException('File not found: $rel');
    return target;
  }

  void _write(String target, String content) {
    final bytes = utf8.encode(content);
    if (bytes.length > maxEditableBytes) throw const SourceFileException('File is larger than 2 MB');
    final tmp = File('$target.${Random.secure().nextInt(1 << 32).toRadixString(16)}.tmp');
    try {
      tmp.writeAsBytesSync(bytes, flush: true);
      tmp.renameSync(target);
    } finally {
      if (tmp.existsSync()) tmp.deleteSync();
    }
  }
}

/// Files of a new blank site: a page, a stylesheet and a script.
Map<String, String> starterSite(String appName) {
  final title = const HtmlEscape().convert(appName);
  return {
    'index.html':
        '''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>$title</h1>
    <p>Edit <code>index.html</code>, <code>style.css</code> and <code>script.js</code> to make it yours.</p>
    <button id="hello">Say hello</button>
    <p id="out"></p>
  </main>
  <script src="script.js"></script>
</body>
</html>
''',
    'style.css': '''* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, sans-serif;
  background: #fffdf5;
  color: #000;
}

main {
  max-width: 40rem;
  margin: 0 auto;
  padding: 2rem 1rem;
}

button {
  font: inherit;
  font-weight: 700;
  padding: 0.6rem 1rem;
  background: #ffd60a;
  border: 2.5px solid #000;
  border-radius: 8px;
  box-shadow: 4px 4px 0 #000;
}

button:active {
  transform: translate(4px, 4px);
  box-shadow: none;
}
''',
    'script.js': '''document.getElementById('hello').addEventListener('click', () => {
  document.getElementById('out').textContent = 'Hello from your app!';
});
''',
  };
}
