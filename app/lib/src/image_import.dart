import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

/// Image files people can pick for an icon or splash screen. Android needs
/// PNG, so everything else is converted with [toPng] first.
const pickableImageExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'svg'];

/// Thrown when a picked file cannot be read as an image.
class ImageImportException implements Exception {
  const ImageImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converts [bytes] (any of [pickableImageExtensions]) to PNG.
///
/// SVGs are drawn with their longest side at [svgSize] px. Other images keep
/// their pixels, scaled down if a side exceeds [maxSide]. With [square],
/// the image is centred on a transparent square. A square PNG that needs no
/// scaling is returned unchanged.
Future<Uint8List> toPng(Uint8List bytes,
    {required bool isSvg, bool square = false, int svgSize = 1024, int maxSide = 4096}) async {
  final ui.Image image;
  if (isSvg) {
    image = await _renderSvg(bytes, svgSize, square: square);
  } else {
    if (!square || _isSquarePng(bytes)) {
      if (_isPng(bytes) && !_pngExceeds(bytes, maxSide)) return bytes;
    }
    image = await _decode(bytes);
  }
  try {
    final w = image.width, h = image.height;
    final side = math.max(w, h);
    final scale = side > maxSide ? maxSide / side : 1.0;
    final cw = (square ? side : w) * scale, ch = (square ? side : h) * scale;
    if (cw == w && ch == h) return await _encode(image);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final dw = w * scale, dh = h * scale;
    canvas.drawImageRect(image, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Rect.fromLTWH((cw - dw) / 2, (ch - dh) / 2, dw, dh), ui.Paint()..filterQuality = ui.FilterQuality.high);
    final out = await recorder.endRecording().toImage(cw.round(), ch.round());
    try {
      return await _encode(out);
    } finally {
      out.dispose();
    }
  } finally {
    image.dispose();
  }
}

Future<ui.Image> _decode(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } on Object {
    throw const ImageImportException('This file is not an image this app can read (PNG, JPEG, WebP, GIF, BMP or SVG)');
  }
}

Future<ui.Image> _renderSvg(Uint8List bytes, int size, {required bool square}) async {
  final PictureInfo info;
  try {
    info = await vg.loadPicture(SvgBytesLoader(bytes), null);
  } on Object {
    throw const ImageImportException('This SVG could not be read');
  }
  try {
    final w = info.size.width, h = info.size.height;
    if (w <= 0 || h <= 0) throw const ImageImportException('This SVG has no size (add width/height or a viewBox)');
    final scale = size / math.max(w, h);
    final cw = square ? size.toDouble() : w * scale, ch = square ? size.toDouble() : h * scale;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..translate((cw - w * scale) / 2, (ch - h * scale) / 2)
      ..scale(scale);
    canvas.drawPicture(info.picture);
    return await recorder.endRecording().toImage(math.max(1, cw.round()), math.max(1, ch.round()));
  } finally {
    info.picture.dispose();
  }
}

Future<Uint8List> _encode(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

bool _isPng(Uint8List b) =>
    b.length > 24 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 && b[12] == 0x49 && b[13] == 0x48;

(int, int) _pngSize(Uint8List b) {
  final d = ByteData.sublistView(b);
  return (d.getUint32(16), d.getUint32(20));
}

bool _isSquarePng(Uint8List b) => _isPng(b) && _pngSize(b).$1 == _pngSize(b).$2;

bool _pngExceeds(Uint8List b, int maxSide) => math.max(_pngSize(b).$1, _pngSize(b).$2) > maxSide;
