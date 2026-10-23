import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

/// Builds a Windows .exe for a project by copying the prebuilt WebView2
/// wrapper and embedding the website, its settings and the icon as
/// resources (ADR 0007). No compiler runs at build time.
class ExeBuilder {
  ExeBuilder(this.wrapperPath);

  /// `html2apk_wrapper.exe`, installed next to iLoveHTML.
  final String wrapperPath;

  static const _rtIcon = 3;
  static const _rtRcdata = 10;
  static const _rtGroupIcon = 14;
  static const _firstFileId = 1000;

  /// Website files beyond this total are refused (resources live in memory).
  static const maxSiteBytes = 1024 * 1024 * 1024;

  Future<BuildResult> build(ProjectHandle project,
      {required String outputPath, required BuildLogSink log, bool debug = false}) async {
    final sw = Stopwatch()..start();
    final m = project.manifest;
    final errors = validateManifest(m).where((i) => i.severity == IssueSeverity.error).toList();
    if (errors.isNotEmpty) return BuildResult(BuildStatus.failed, message: errors.join('\n'), duration: sw.elapsed);
    if (!File(wrapperPath).existsSync()) {
      return BuildResult(BuildStatus.failed,
          message: 'Windows wrapper missing at $wrapperPath (run tools/build_windows_wrapper.ps1)', duration: sw.elapsed);
    }
    log('Engine: Windows .exe (WebView2 wrapper, ${debug ? 'developer tools on' : 'developer tools off'})');

    final files = m.source.type == SourceType.local ? siteFiles(project.sourceDir) : <String, String>{};
    final total = files.values.fold<int>(0, (n, f) => n + File(f).lengthSync());
    if (total > maxSiteBytes) {
      return BuildResult(BuildStatus.failed, message: 'Website is larger than 1 GB', duration: sw.elapsed);
    }
    log('Website files: ${files.length} (${(total / 1024 / 1024).toStringAsFixed(1)} MB)');

    final icon = project.iconFile == null ? null : await iconFromPng(File(project.iconFile!).readAsBytesSync());
    if (icon == null) log('No app icon set: Windows shows its default program icon');

    Directory(p.dirname(outputPath)).createSync(recursive: true);
    final tmp = '$outputPath.tmp';
    File(wrapperPath).copySync(tmp);
    try {
      _writeResources(tmp, config: exeConfig(m, debug: debug), files: files, icon: icon);
      if (File(outputPath).existsSync()) File(outputPath).deleteSync();
      File(tmp).renameSync(outputPath);
    } on Object catch (e) {
      if (File(tmp).existsSync()) File(tmp).deleteSync();
      log('Error: $e');
      return BuildResult(BuildStatus.failed, message: '$e', duration: sw.elapsed);
    }
    log('Output: $outputPath (${File(outputPath).lengthSync()} bytes)');
    log('Not code-signed: Windows SmartScreen may warn people who download it.');
    return BuildResult(BuildStatus.succeeded, artifactPath: outputPath, duration: sw.elapsed);
  }

  /// Website files by URL path (forward slashes), symlinks skipped.
  static Map<String, String> siteFiles(String sourceDir) {
    final out = <String, String>{};
    for (final e in Directory(sourceDir).listSync(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      out[p.relative(e.path, from: sourceDir).replaceAll(r'\', '/')] = e.path;
    }
    return out;
  }

  /// The wrapper's CONFIG resource: `key TAB value` lines.
  static String exeConfig(ProjectManifest m, {required bool debug}) {
    String clean(String v) => v.replaceAll(RegExp(r'[\t\r\n]'), ' ');
    final values = {
      'name': m.name,
      'appId': m.android.applicationId,
      'version': m.android.versionName,
      'type': m.source.type == SourceType.local ? 'local' : 'remote',
      'entry': m.source.entry,
      'javaScript': m.webView.javaScriptEnabled ? '1' : '0',
      'externalLinks': m.webView.externalLinks.name,
      'allowedHosts': m.webView.allowedHosts.join(','),
      'userAgentSuffix': m.webView.userAgentSuffix ?? '',
      'offlinePage': m.offlineFallbackPage ?? '',
      'devtools': debug ? '1' : '0',
      'width': '1280',
      'height': '800',
      'resizable': '1',
    };
    return values.entries.map((e) => '${e.key}\t${clean(e.value)}\n').join();
  }

  void _writeResources(String exe,
      {required String config, required Map<String, String> files, required ExeIcon? icon}) {
    using((arena) {
      final handle = _begin(exe.toNativeUtf16(allocator: arena), 0);
      if (handle == nullptr) throw StateError('Could not open $exe for resource update');
      var ok = false;
      try {
        void put(int type, Pointer<Utf16> name, List<int> data) {
          final buf = malloc<Uint8>(data.isEmpty ? 1 : data.length);
          try {
            buf.asTypedList(data.length).setAll(0, data);
            if (_update(handle, Pointer.fromAddress(type), name, 0, buf.cast(), data.length) == 0) {
              throw StateError('UpdateResource failed for type $type');
            }
          } finally {
            malloc.free(buf);
          }
        }

        put(_rtRcdata, 'CONFIG'.toNativeUtf16(allocator: arena), utf8.encode(config));
        final index = StringBuffer();
        var id = _firstFileId;
        for (final MapEntry(key: path, value: file) in files.entries) {
          put(_rtRcdata, Pointer.fromAddress(id), File(file).readAsBytesSync());
          index.write('$id\t${contentTypeFor(path)}\t$path\n');
          id++;
        }
        // Windows refuses empty resources; URL apps have no files.
        if (files.isNotEmpty) put(_rtRcdata, 'INDEX'.toNativeUtf16(allocator: arena), utf8.encode(index.toString()));
        if (icon != null) {
          for (var i = 0; i < icon.images.length; i++) {
            put(_rtIcon, Pointer.fromAddress(i + 1), icon.images[i]);
          }
          put(_rtGroupIcon, Pointer.fromAddress(1), icon.group);
        }
        ok = true;
      } finally {
        if (_end(handle, ok ? 0 : 1) == 0 && ok) throw StateError('EndUpdateResource failed');
      }
    });
  }

  /// PNG-compressed icon images at Windows' standard sizes plus the group
  /// directory that lists them. Null if [png] cannot be decoded.
  static Future<ExeIcon?> iconFromPng(Uint8List png) async {
    const sizes = [256, 48, 32, 16];
    final images = <Uint8List>[];
    try {
      for (final size in sizes) {
        final codec = await ui.instantiateImageCodec(png, targetWidth: size, targetHeight: size);
        final frame = await codec.getNextFrame();
        final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        frame.image.dispose();
        codec.dispose();
        images.add(data!.buffer.asUint8List());
      }
    } on Object {
      return null;
    }
    // GRPICONDIR + GRPICONDIRENTRY (14 bytes each), little-endian.
    final group = BytesBuilder();
    final header = ByteData(6)
      ..setUint16(0, 0, Endian.little)
      ..setUint16(2, 1, Endian.little)
      ..setUint16(4, images.length, Endian.little);
    group.add(header.buffer.asUint8List());
    for (var i = 0; i < images.length; i++) {
      final s = sizes[i];
      final e = ByteData(14)
        ..setUint8(0, s == 256 ? 0 : s)
        ..setUint8(1, s == 256 ? 0 : s)
        ..setUint8(2, 0)
        ..setUint8(3, 0)
        ..setUint16(4, 1, Endian.little)
        ..setUint16(6, 32, Endian.little)
        ..setUint32(8, images[i].length, Endian.little)
        ..setUint16(12, i + 1, Endian.little);
      group.add(e.buffer.asUint8List());
    }
    return ExeIcon(images, group.toBytes());
  }
}

/// Windows icon resources: PNG images and their group directory.
class ExeIcon {
  ExeIcon(this.images, this.group);

  final List<Uint8List> images;
  final Uint8List group;
}

final _kernel32 = DynamicLibrary.open('kernel32.dll');
final _begin = _kernel32.lookupFunction<Pointer<Void> Function(Pointer<Utf16>, Int32),
    Pointer<Void> Function(Pointer<Utf16>, int)>('BeginUpdateResourceW');
final _update = _kernel32.lookupFunction<
    Int32 Function(Pointer<Void>, Pointer<Utf16>, Pointer<Utf16>, Uint16, Pointer<Void>, Uint32),
    int Function(Pointer<Void>, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Void>, int)>('UpdateResourceW');
final _end = _kernel32.lookupFunction<Int32 Function(Pointer<Void>, Int32), int Function(Pointer<Void>, int)>(
    'EndUpdateResourceW');
