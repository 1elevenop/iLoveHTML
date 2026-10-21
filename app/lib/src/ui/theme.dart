import 'package:flutter/material.dart';

const _seed = Color(0xFF4FC3F7);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final dark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: scheme.copyWith(
      surface: dark ? const Color(0xFF12161F) : null,
      surfaceContainerLow: dark ? const Color(0xFF181D28) : null,
      surfaceContainer: dark ? const Color(0xFF1C2230) : null,
    ),
    useMaterial3: true,
    cardTheme: const CardThemeData(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}

/// Monospace style for build logs and package IDs.
TextStyle monoStyle(BuildContext context, {double size = 12.5}) =>
    TextStyle(fontFamily: 'monospace', fontSize: size, color: Theme.of(context).colorScheme.onSurface);
