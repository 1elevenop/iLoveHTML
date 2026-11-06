import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Size Android TV launchers expect for an app banner.
const int tvBannerWidth = 320;
const int tvBannerHeight = 180;

/// Makes a TV launcher banner: the app icon on the left and the app name on
/// the right, on [backgroundHex] (`#RRGGBB`). Without an icon the name is
/// centred. Names the built-in font cannot draw (not plain ASCII) are left
/// out, because the launcher shows the app name under the banner anyway.
Uint8List makeTvBanner({Uint8List? iconPng, required String backgroundHex, required String name}) {
  final bg = _parseHex(backgroundHex);
  final banner = img.Image(width: tvBannerWidth, height: tvBannerHeight, numChannels: 4);
  img.fill(banner, color: img.ColorRgba8(bg.$1, bg.$2, bg.$3, 255));

  final icon = iconPng == null ? null : img.decodePng(iconPng);
  const iconSize = 120;
  const pad = 24;
  if (icon != null) {
    final scaled = img.copyResize(icon, width: iconSize, height: iconSize, interpolation: img.Interpolation.average);
    img.compositeImage(banner, scaled, dstX: pad, dstY: (tvBannerHeight - iconSize) ~/ 2);
  }

  final text = name.trim();
  if (text.isNotEmpty && RegExp(r'^[\x20-\x7e]+$').hasMatch(text)) {
    final light = (0.299 * bg.$1 + 0.587 * bg.$2 + 0.114 * bg.$3) > 150;
    final color = light ? img.ColorRgba8(30, 36, 48, 255) : img.ColorRgba8(255, 255, 255, 255);
    final left = icon == null ? pad : pad + iconSize + 16;
    final room = tvBannerWidth - left - pad;
    final fit = _fit(text, room);
    if (fit != null) {
      final (font, line) = fit;
      final width = _width(font, line);
      final x = icon == null ? (tvBannerWidth - width) ~/ 2 : left;
      final y = (tvBannerHeight - font.lineHeight) ~/ 2;
      img.drawString(banner, line, font: font, x: x, y: y, color: color);
    }
  }
  return img.encodePng(banner, level: 9);
}

/// The largest font the name fits in, shortened with "..." when even the
/// smallest is too wide.
(img.BitmapFont, String)? _fit(String text, int room) {
  for (final font in [img.arial48, img.arial24]) {
    if (_width(font, text) <= room) return (font, text);
  }
  final font = img.arial24;
  for (var n = text.length - 1; n > 0; n--) {
    final line = '${text.substring(0, n).trimRight()}...';
    if (_width(font, line) <= room) return (font, line);
  }
  return null;
}

int _width(img.BitmapFont font, String s) {
  var w = 0;
  for (final c in s.codeUnits) {
    w += font.characters[c]?.xAdvance ?? 0;
  }
  return w;
}

(int, int, int) _parseHex(String hex) {
  final ok = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex);
  final v = ok ? int.parse(hex.substring(1), radix: 16) : 0xFFFFFF;
  return ((v >> 16) & 255, (v >> 8) & 255, v & 255);
}
