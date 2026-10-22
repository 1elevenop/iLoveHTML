import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../security/path_safety.dart';

/// Limits applied to untrusted archives.
class ExtractionLimits {
  const ExtractionLimits({
    this.maxEntries = 10000,
    this.maxFileBytes = 100 * 1024 * 1024,
    this.maxTotalBytes = 500 * 1024 * 1024,
    this.maxCompressionRatio = 200,
  });

  final int maxEntries;
  final int maxFileBytes;
  final int maxTotalBytes;

  /// Rejects entries whose uncompressed/compressed ratio suggests a ZIP bomb.
  final int maxCompressionRatio;
}

class ArchiveRejectedException implements Exception {
  ArchiveRejectedException(this.message);

  final String message;

  @override
  String toString() => 'Archive rejected: $message';
}

class ExtractionResult {
  ExtractionResult(this.files, this.totalBytes, this.strippedPrefix);

  /// Normalized POSIX paths relative to the destination.
  final List<String> files;
  final int totalBytes;

  /// Single top-level folder removed from all entries, if any.
  final String? strippedPrefix;
}

/// Safely extracts a website ZIP into [destination], which must be empty or absent.
///
/// When every entry lives under one top-level folder (common for zipped
/// folders), that folder is stripped so the site root lands in [destination].
Future<ExtractionResult> extractWebsiteZip(
  String zipPath,
  String destination, {
  ExtractionLimits limits = const ExtractionLimits(),
}) async {
  final dest = Directory(destination);
  if (dest.existsSync() && dest.listSync().isNotEmpty) {
    throw ArgumentError.value(destination, 'destination', 'must be empty');
  }
  final input = InputFileStream(zipPath);
  try {
    final archive = ZipDecoder().decodeStream(input);
    final entries = <(String, ArchiveFile)>[];
    for (final f in archive.files) {
      if (!f.isFile) continue;
      if (f.isSymbolicLink) throw ArchiveRejectedException('symbolic link entry "${f.name}"');
      final String name;
      try {
        name = normalizeRelativePath(f.name);
      } on UnsafePathException catch (e) {
        throw ArchiveRejectedException(e.toString());
      }
      if (_isJunk(name)) continue;
      entries.add((name, f));
    }
    if (entries.isEmpty) throw ArchiveRejectedException('no files found');
    if (entries.length > limits.maxEntries) {
      throw ArchiveRejectedException('more than ${limits.maxEntries} files');
    }

    var declaredTotal = 0;
    for (final (name, f) in entries) {
      if (f.size > limits.maxFileBytes) throw ArchiveRejectedException('"$name" is too large');
      declaredTotal += f.size;
      final compressed = f.rawContent?.length ?? f.size;
      if (f.size > 1024 * 1024 && compressed > 0 && f.size / compressed > limits.maxCompressionRatio) {
        throw ArchiveRejectedException('"$name" has a suspicious compression ratio');
      }
    }
    if (declaredTotal > limits.maxTotalBytes) throw ArchiveRejectedException('archive too large');

    final prefix = _commonTopFolder(entries.map((e) => e.$1));
    final seen = <String>{};
    final written = <String>[];
    var actualTotal = 0;
    dest.createSync(recursive: true);
    for (final (name, f) in entries) {
      final rel = prefix == null ? name : name.substring(prefix.length + 1);
      // Case-insensitive duplicates would collide on Windows.
      if (!seen.add(rel.toLowerCase())) throw ArchiveRejectedException('duplicate entry "$rel"');
      final out = File(resolveWithin(dest.path, rel));
      out.parent.createSync(recursive: true);
      // Declared sizes come from the archive and are not trusted: decompress
      // straight to disk and stop as soon as the real size passes a limit,
      // so a ZIP bomb with forged headers cannot exhaust memory or storage.
      final remaining = limits.maxTotalBytes - actualTotal;
      final sink = LimitedFileOutput(out.path,
          limit: remaining < limits.maxFileBytes ? remaining : limits.maxFileBytes,
          onLimit: () => ArchiveRejectedException(
              remaining < limits.maxFileBytes ? 'archive too large' : '"$rel" is too large'));
      try {
        f.writeContent(sink);
      } finally {
        sink.closeSync();
      }
      actualTotal += sink.length;
      written.add(rel);
    }
    return ExtractionResult(written, actualTotal, prefix);
  } on FormatException catch (e) {
    throw ArchiveRejectedException('not a valid ZIP file (${e.message})');
  } finally {
    await input.close();
  }
}

/// Archive output that writes to a file and throws once more than [limit]
/// bytes arrive. Public for tests; the library export hides it.
class LimitedFileOutput extends OutputStream {
  LimitedFileOutput(String path, {required this.limit, required this.onLimit})
      : _file = File(path).openSync(mode: FileMode.write),
        super(byteOrder: ByteOrder.littleEndian);

  final int limit;
  final Exception Function() onLimit;
  final RandomAccessFile _file;
  final _buffer = BytesBuilder(copy: false);
  int _length = 0;
  bool _closed = false;

  @override
  int get length => _length;

  void _count(int n) {
    _length += n;
    if (_length > limit) throw onLimit();
  }

  @override
  void writeByte(int value) {
    _count(1);
    _buffer.addByte(value);
    if (_buffer.length >= 64 * 1024) flush();
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    final n = length ?? bytes.length;
    _count(n);
    _buffer.add(n == bytes.length ? bytes : bytes.sublist(0, n));
    if (_buffer.length >= 64 * 1024) flush();
  }

  @override
  void writeStream(InputStream stream) {
    while (!stream.isEOS) {
      final chunk = stream.readBytes(stream.length < 65536 ? stream.length : 65536).toUint8List();
      writeBytes(chunk);
    }
  }

  @override
  void flush() {
    if (_buffer.isNotEmpty) _file.writeFromSync(_buffer.takeBytes());
  }

  /// Reads back already-written bytes (FileMode.write opens for read and write).
  @override
  Uint8List subset(int start, [int? end]) {
    flush();
    final from = start < 0 ? _length + start : start;
    final to = end == null ? _length : (end < 0 ? _length + end : end);
    if (from < 0 || to > _length || from > to) throw RangeError('subset($start, $end) outside 0..$_length');
    _file.setPositionSync(from);
    final bytes = _file.readSync(to - from);
    _file.setPositionSync(_length);
    return bytes;
  }

  @override
  void clear() {
    _buffer.clear();
    _length = 0;
  }

  @override
  void closeSync() {
    if (_closed) return;
    _closed = true;
    try {
      flush();
    } finally {
      _file.closeSync();
    }
  }
}

bool _isJunk(String path) {
  final parts = path.split('/');
  return parts.first == '__MACOSX' || parts.last == '.DS_Store' || parts.last == 'Thumbs.db';
}

String? _commonTopFolder(Iterable<String> paths) {
  String? top;
  for (final path in paths) {
    final i = path.indexOf('/');
    if (i < 0) return null;
    final first = path.substring(0, i);
    if (top == null) {
      top = first;
    } else if (top != first) {
      return null;
    }
  }
  return top;
}

/// Lists files under [root] as normalized POSIX relative paths.
List<String> listRelativeFiles(String root) => Directory(root)
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .map((f) => p.relative(f.path, from: root).replaceAll('\\', '/'))
    .toList()
  ..sort();
