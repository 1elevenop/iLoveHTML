import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// What kind of file a site file is, for the size report.
enum AssetKind { page, script, style, image, font, media, data, other }

AssetKind assetKindOf(String path) => switch (p.extension(path).toLowerCase()) {
      '.html' || '.htm' => AssetKind.page,
      '.js' || '.mjs' => AssetKind.script,
      '.css' => AssetKind.style,
      '.png' || '.jpg' || '.jpeg' || '.gif' || '.webp' || '.svg' || '.bmp' || '.ico' || '.avif' => AssetKind.image,
      '.woff' || '.woff2' || '.ttf' || '.otf' || '.eot' => AssetKind.font,
      '.mp3' || '.mp4' || '.webm' || '.ogg' || '.wav' || '.m4a' || '.mov' => AssetKind.media,
      '.json' || '.webmanifest' || '.xml' || '.txt' || '.csv' => AssetKind.data,
      _ => AssetKind.other,
    };

/// Images larger than this get a warning in the size report.
const int largeImageBytes = 500 * 1024;

/// Any file larger than this gets a warning in the size report.
const int largeFileBytes = 5 * 1024 * 1024;

class SiteFile {
  const SiteFile(this.path, this.bytes);

  /// POSIX path relative to the site folder.
  final String path;
  final int bytes;
}

/// Sizes of a site folder by kind, its largest files and advice.
class SiteSizeReport {
  SiteSizeReport(this.files) {
    files.sort((a, b) => b.bytes.compareTo(a.bytes));
  }

  /// All files, largest first.
  final List<SiteFile> files;

  int get totalBytes => files.fold(0, (sum, f) => sum + f.bytes);

  Map<AssetKind, int> get bytesByKind {
    final totals = <AssetKind, int>{};
    for (final f in files) {
      totals.update(assetKindOf(f.path), (v) => v + f.bytes, ifAbsent: () => f.bytes);
    }
    return totals;
  }

  List<SiteFile> largest([int count = 10]) => files.take(count).toList();

  List<String> get warnings => [
        for (final f in files)
          if (f.bytes > largeFileBytes)
            '${f.path} is ${formatBytes(f.bytes)}. Large files make the app slow to download.'
          else if (assetKindOf(f.path) == AssetKind.image && f.bytes > largeImageBytes)
            '${f.path} is ${formatBytes(f.bytes)}. Make it smaller or save it as WebP.',
      ];

  static SiteSizeReport scan(String siteDir) {
    final root = Directory(siteDir);
    if (!root.existsSync()) return SiteSizeReport([]);
    return SiteSizeReport([
      for (final e in root.listSync(recursive: true, followLinks: false))
        if (e is File) SiteFile(p.posix.joinAll(p.split(p.relative(e.path, from: siteDir))), e.lengthSync()),
    ]);
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// One file the optimizer made smaller.
class OptimizedFile {
  const OptimizedFile(this.path, this.before, this.after);

  final String path;
  final int before;
  final int after;
}

class OptimizeResult {
  const OptimizeResult(this.changed, this.totalBefore, this.totalAfter);

  final List<OptimizedFile> changed;
  final int totalBefore;
  final int totalAfter;

  int get savedBytes => totalBefore - totalAfter;
}

/// Copies [fromDir] to [toDir], making files smaller where that is safe:
///
/// * CSS: comments (except `/*! … */` licence notes) and extra spaces removed.
/// * JSON and web manifests: written without spaces.
/// * PNG: compressed again without loss; skipped for animated PNGs and
///   images with a colour profile.
/// * JPEG over 100 KB: saved at 85% quality when that saves at least 10%;
///   skipped for photos with a rotation flag or a colour profile.
///
/// HTML and JavaScript are copied unchanged: making them smaller safely
/// needs a full parser. A file is only replaced when the result is smaller,
/// and any file that cannot be read as expected is copied as it is.
OptimizeResult optimizeSite(String fromDir, String toDir) {
  final changed = <OptimizedFile>[];
  var before = 0;
  var after = 0;
  final root = Directory(fromDir);
  Directory(toDir).createSync(recursive: true);
  if (!root.existsSync()) return OptimizeResult(changed, 0, 0);
  for (final e in root.listSync(recursive: true, followLinks: false)) {
    final rel = p.relative(e.path, from: fromDir);
    final target = p.join(toDir, rel);
    if (e is Directory) {
      Directory(target).createSync(recursive: true);
      continue;
    }
    if (e is! File) continue;
    final original = e.readAsBytesSync();
    final smaller = _optimizeBytes(rel, original);
    File(target)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(smaller ?? original);
    before += original.length;
    after += (smaller ?? original).length;
    if (smaller != null) changed.add(OptimizedFile(p.posix.joinAll(p.split(rel)), original.length, smaller.length));
  }
  return OptimizeResult(changed, before, after);
}

/// The smaller version of a file, or null to keep the original.
Uint8List? _optimizeBytes(String path, Uint8List bytes) {
  Uint8List? out;
  try {
    out = switch (p.extension(path).toLowerCase()) {
      '.css' => _text(bytes, minifyCss),
      '.json' || '.webmanifest' => _text(bytes, (s) => jsonEncode(jsonDecode(s))),
      '.png' => recompressPng(bytes),
      '.jpg' || '.jpeg' => recompressJpeg(bytes),
      _ => null,
    };
  } on Object {
    // Damaged or unusual files are copied unchanged.
    out = null;
  }
  return out != null && out.length < bytes.length ? out : null;
}

Uint8List? _text(Uint8List bytes, String? Function(String) transform) {
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    return null;
  }
  final result = transform(text);
  return result == null ? null : Uint8List.fromList(utf8.encode(result));
}

/// Removes comments and extra spaces from CSS. Strings, `url(...)` values
/// and escapes are copied as they are, and a space is only removed next to
/// `{ } ; ,`, where CSS ignores it. Returns null for CSS it cannot follow
/// (an unclosed comment or string), so the original is kept.
String? minifyCss(String css) {
  final out = <int>[];
  String last() => out.isEmpty ? '' : String.fromCharCode(out.last);
  void emit(String s) => out.addAll(s.codeUnits);
  bool endsWithUrl() {
    if (out.length < 3) return false;
    final t = String.fromCharCodes(out.sublist(out.length - 3)).toLowerCase();
    return t == 'url';
  }

  const tight = '{};,';
  var space = false;
  var i = 0;
  final n = css.length;
  while (i < n) {
    final c = css[i];
    if (c == '/' && i + 1 < n && css[i + 1] == '*') {
      final end = css.indexOf('*/', i + 2);
      if (end < 0) return null;
      if (i + 2 < n && css[i + 2] == '!') {
        if (space && out.isNotEmpty) emit(' ');
        space = false;
        emit(css.substring(i, end + 2));
      }
      i = end + 2;
      continue;
    }
    if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f') {
      space = true;
      i++;
      continue;
    }
    if (space) {
      if (out.isNotEmpty && !tight.contains(last()) && !tight.contains(c)) emit(' ');
      space = false;
    }
    if (c == '"' || c == "'") {
      var j = i + 1;
      while (j < n && css[j] != c) {
        if (css[j] == '\n') return null;
        j += css[j] == '\\' ? 2 : 1;
      }
      if (j >= n) return null;
      emit(css.substring(i, j + 1));
      i = j + 1;
      continue;
    }
    if (c == '\\') {
      emit(css.substring(i, i + 2 > n ? n : i + 2));
      i += 2;
      continue;
    }
    if (c == '(' && endsWithUrl()) {
      var j = i + 1;
      while (j < n && (css[j] == ' ' || css[j] == '\t' || css[j] == '\n')) {
        j++;
      }
      if (j < n && css[j] != '"' && css[j] != "'") {
        final end = css.indexOf(')', j);
        if (end < 0) return null;
        emit(css.substring(i, end + 1));
        i = end + 1;
        continue;
      }
    }
    if (c == '}' && last() == ';') out.removeLast();
    emit(c);
    i++;
  }
  return String.fromCharCodes(out);
}

/// PNG chunk types in the file, in order.
List<String> _pngChunks(Uint8List b) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (b.length < 8) return const [];
  for (var i = 0; i < 8; i++) {
    if (b[i] != signature[i]) return const [];
  }
  final chunks = <String>[];
  var pos = 8;
  final data = ByteData.sublistView(b);
  while (pos + 8 <= b.length) {
    final len = data.getUint32(pos);
    chunks.add(String.fromCharCodes(b.sublist(pos + 4, pos + 8)));
    pos += 12 + len;
  }
  return chunks;
}

/// Compresses a PNG again without changing a pixel; null to keep the original.
Uint8List? recompressPng(Uint8List bytes) {
  final chunks = _pngChunks(bytes);
  // Animated PNGs would lose their frames; colour profiles and gamma would be dropped.
  if (chunks.isEmpty || chunks.any((c) => const {'acTL', 'iCCP', 'gAMA', 'cHRM', 'sRGB'}.contains(c))) return null;
  final image = img.decodePng(bytes);
  if (image == null || image.numFrames > 1) return null;
  final out = img.encodePng(image, level: 9);
  final check = img.decodePng(out);
  if (check == null || check.width != image.width || check.height != image.height) return null;
  final a = image.getBytes(order: img.ChannelOrder.rgba);
  final b = check.getBytes(order: img.ChannelOrder.rgba);
  if (a.length != b.length) return null;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return null;
  }
  return out;
}

/// JPEGs smaller than this are left alone: the saving is not worth the quality loss.
const int minJpegBytes = 100 * 1024;

/// Saves a large JPEG at 85% quality if that saves at least 10%; null to keep it.
Uint8List? recompressJpeg(Uint8List bytes) {
  if (bytes.length < minJpegBytes) return null;
  final image = img.decodeJpg(bytes);
  if (image == null) return null;
  final ifd = image.exif.imageIfd;
  if (ifd.hasOrientation && ifd.orientation != 1) return null;
  if (image.iccProfile != null) return null;
  final out = img.encodeJpg(image, quality: 85);
  return out.length <= bytes.length * 0.9 ? out : null;
}
