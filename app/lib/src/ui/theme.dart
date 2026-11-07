import 'package:flutter/material.dart';

/// Fixed tokens of the New ELEVEN design system. Colours live in
/// [ElevenPalette], which depends on light/dark mode and the accent preset.
abstract final class Eleven {
  static const font = 'JetBrainsMono';

  /// JetBrains Mono has no CJK glyphs; these system fonts fill them in.
  static const fallback = [
    'Microsoft YaHei UI',
    'Yu Gothic UI',
    'Malgun Gothic',
    'Noto Sans CJK SC',
    'Noto Sans CJK JP',
    'Noto Sans CJK KR',
    'sans-serif',
  ];
}

/// The accent ("signal") colour; orange is the original New ELEVEN accent.
enum AccentPreset {
  orange(Color(0xFFFF7A1A), Color(0xFFFFB37A), Color(0xFF120600), Color(0xFFB8480A), Color(0xFFD45A12)),
  green(Color(0xFF39FF88), Color(0xFF9DFFC4), Color(0xFF001A0A), Color(0xFF0F7A3D), Color(0xFF16994D)),
  cyan(Color(0xFF22D3EE), Color(0xFF8BE9F7), Color(0xFF001619), Color(0xFF0E7490), Color(0xFF1592B3)),
  violet(Color(0xFFA78BFA), Color(0xFFCFC0FD), Color(0xFF10061F), Color(0xFF6D28D9), Color(0xFF7C3AED)),
  pink(Color(0xFFFF4FA3), Color(0xFFFF9CCB), Color(0xFF1A0010), Color(0xFFBE185D), Color(0xFFDB2777));

  const AccentPreset(this.dark, this.darkHi, this.darkOn, this.light, this.lightHi);

  final Color dark, darkHi, darkOn, light, lightHi;

  static AccentPreset byName(String? name) =>
      AccentPreset.values.firstWhere((a) => a.name == name, orElse: () => AccentPreset.orange);
}

/// Resolved colour tokens: a terminal ground with one accent signal.
/// Orange-style accent only marks done, score or "act now".
@immutable
class ElevenPalette extends ThemeExtension<ElevenPalette> {
  const ElevenPalette({
    required this.bg,
    required this.panel,
    required this.fg,
    required this.mute,
    required this.line,
    required this.line2,
    required this.acc,
    required this.accHi,
    required this.onAcc,
  });

  factory ElevenPalette.of(Brightness brightness, AccentPreset accent) => brightness == Brightness.dark
      ? ElevenPalette(
          bg: const Color(0xFF000000),
          panel: const Color(0xFF090908),
          fg: const Color(0xFFF2EFEA),
          mute: const Color(0xFF8C8781),
          line: const Color(0xFF1F1D1B),
          line2: const Color(0xFF3A3531),
          acc: accent.dark,
          accHi: accent.darkHi,
          onAcc: accent.darkOn,
        )
      : ElevenPalette(
          bg: const Color(0xFFF7F5F1),
          panel: const Color(0xFFFFFFFF),
          fg: const Color(0xFF141210),
          mute: const Color(0xFF615B55),
          line: const Color(0xFFE4E0DA),
          line2: const Color(0xFFC4BDB4),
          acc: accent.light,
          accHi: accent.lightHi,
          onAcc: const Color(0xFFFFFFFF),
        );

  final Color bg, panel, fg, mute, line, line2, acc, accHi, onAcc;

  Color get accSoft => acc.withAlpha(0x1F);

  /// The system's signature glow; on accent things only.
  List<BoxShadow> get glow => [
        BoxShadow(color: acc.withAlpha(0xCC), blurRadius: 6),
        BoxShadow(color: acc.withAlpha(0x59), blurRadius: 20),
      ];

  @override
  ElevenPalette copyWith() => this;

  @override
  ElevenPalette lerp(ElevenPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ElevenPalette(
      bg: l(bg, other.bg),
      panel: l(panel, other.panel),
      fg: l(fg, other.fg),
      mute: l(mute, other.mute),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      acc: l(acc, other.acc),
      accHi: l(accHi, other.accHi),
      onAcc: l(onAcc, other.onAcc),
    );
  }
}

extension ElevenContext on BuildContext {
  ElevenPalette get eleven => Theme.of(this).extension<ElevenPalette>()!;
}

class _NoTransition extends PageTransitionsBuilder {
  const _NoTransition();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;
}

const _tabular = [FontFeature.tabularFigures()];
const _square = RoundedRectangleBorder();
const _sm = BorderRadius.all(Radius.circular(4));

/// New ELEVEN in light or dark, with the chosen accent.
ThemeData buildTheme({
  Brightness brightness = Brightness.dark,
  AccentPreset accent = AccentPreset.orange,
  bool animations = true,
}) {
  final e = ElevenPalette.of(brightness, accent);
  final dark = brightness == Brightness.dark;
  final scheme = (dark ? ColorScheme.dark : ColorScheme.light)(
    primary: e.acc,
    onPrimary: e.onAcc,
    primaryContainer: e.accSoft,
    onPrimaryContainer: e.acc,
    secondary: e.acc,
    onSecondary: e.onAcc,
    secondaryContainer: e.line,
    onSecondaryContainer: e.fg,
    tertiary: e.accHi,
    onTertiary: e.onAcc,
    // Missed or failed reads in fg on bg, never a warning red.
    error: e.fg,
    onError: e.bg,
    errorContainer: e.line,
    onErrorContainer: e.fg,
    surface: e.bg,
    onSurface: e.fg,
    onSurfaceVariant: e.mute,
    surfaceContainerLowest: e.bg,
    surfaceContainerLow: e.panel,
    surfaceContainer: e.panel,
    surfaceContainerHigh: e.panel,
    surfaceContainerHighest: e.line,
    outline: e.mute,
    outlineVariant: e.line,
    inverseSurface: e.fg,
    onInverseSurface: e.bg,
    inversePrimary: e.acc,
    shadow: e.acc,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: Eleven.font,
      fontFamilyFallback: Eleven.fallback);
  final text = base.textTheme
      .apply(bodyColor: e.fg, displayColor: e.fg, fontFamily: Eleven.font, fontFamilyFallback: Eleven.fallback)
      .copyWith(
        titleLarge: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: e.fg),
        titleMedium: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, letterSpacing: 0, color: e.fg),
        titleSmall: TextStyle(
            fontSize: 12, height: 1.33, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: e.mute),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0, color: e.fg),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0, color: e.fg),
        bodySmall: TextStyle(fontSize: 12.5, height: 1.44, letterSpacing: 0, color: e.mute),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0, color: e.fg),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: e.fg),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: e.fg),
      )
      .apply(fontFamily: Eleven.font, fontFamilyFallback: Eleven.fallback);
  final tabular = text.copyWith(
    displayLarge: text.displayLarge?.copyWith(fontFeatures: _tabular),
    headlineMedium: text.headlineMedium?.copyWith(fontFeatures: _tabular),
    bodyMedium: text.bodyMedium?.copyWith(fontFeatures: _tabular),
    bodySmall: text.bodySmall?.copyWith(fontFeatures: _tabular),
  );

  const control = Size(40, 40);
  final outlined = OutlinedButton.styleFrom(
    foregroundColor: e.fg,
    minimumSize: control,
    padding: EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: _sm),
    textStyle: tabular.labelLarge,
  ).copyWith(
    side: WidgetStateProperty.resolveWith((s) => BorderSide(
        color: s.contains(WidgetState.disabled)
            ? e.line
            : s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                ? e.acc
                : e.line2)),
  );

  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      for (final p in TargetPlatform.values)
        p: animations ? const FadeForwardsPageTransitionsBuilder() : const _NoTransition(),
    }),
    extensions: [e],
    scaffoldBackgroundColor: e.bg,
    canvasColor: e.bg,
    textTheme: tabular,
    primaryTextTheme: tabular,
    dividerColor: e.line,
    splashFactory: InkRipple.splashFactory,
    hoverColor: e.accSoft,
    focusColor: e.accSoft,
    highlightColor: e.accSoft,
    splashColor: e.accSoft,
    appBarTheme: AppBarTheme(
      backgroundColor: e.bg,
      foregroundColor: e.fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: tabular.titleLarge,
      shape: Border(bottom: BorderSide(color: e.line)),
    ),
    cardTheme: CardThemeData(
      color: e.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(side: BorderSide(color: e.line)),
    ),
    dividerTheme: DividerThemeData(color: e.line, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: e.mute,
      textColor: e.fg,
      minVerticalPadding: 9,
      subtitleTextStyle: tabular.bodySmall,
      shape: _square,
    ),
    iconTheme: IconThemeData(color: e.fg),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: e.acc,
        foregroundColor: e.onAcc,
        disabledBackgroundColor: e.line,
        disabledForegroundColor: e.mute,
        minimumSize: control,
        padding: EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: _sm),
        textStyle: tabular.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        elevation: 6,
        shadowColor: e.acc,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
            ? e.line
            : s.contains(WidgetState.hovered)
                ? e.accHi
                : e.acc),
        elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? 0 : 6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: outlined),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlined),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: e.acc,
        minimumSize: control,
        shape: RoundedRectangleBorder(borderRadius: _sm),
        textStyle: tabular.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: e.fg,
        minimumSize: control,
        shape: RoundedRectangleBorder(borderRadius: _sm),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: e.acc,
      foregroundColor: e.onAcc,
      elevation: 8,
      hoverElevation: 10,
      shape: RoundedRectangleBorder(borderRadius: _sm),
      extendedTextStyle: TextStyle(fontFamily: Eleven.font, fontFamilyFallback: Eleven.fallback, fontWeight: FontWeight.w700, letterSpacing: 0.4),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: _sm)),
        side: WidgetStatePropertyAll(BorderSide(color: e.line2)),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.acc : null),
        foregroundColor:
            WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.onAcc : e.fg),
        textStyle: WidgetStatePropertyAll(tabular.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: e.bg,
      labelStyle: tabular.bodyMedium?.copyWith(color: e.mute),
      floatingLabelStyle: tabular.labelMedium?.copyWith(color: e.acc),
      hintStyle: tabular.bodyMedium?.copyWith(color: e.mute),
      helperStyle: tabular.bodySmall,
      errorStyle: tabular.bodySmall?.copyWith(color: e.fg),
      border: OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: e.line2)),
      enabledBorder: OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: e.line2)),
      focusedBorder: OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: e.acc, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: e.fg)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: e.fg, width: 2)),
      disabledBorder: OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: e.line)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: _square,
      side: BorderSide(color: e.mute),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.acc : null),
      checkColor: WidgetStatePropertyAll(e.onAcc),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.onAcc : e.mute),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.acc : e.bg),
      trackOutlineColor:
          WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.acc : e.mute),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.acc : e.mute),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: e.acc,
      linearTrackColor: e.line,
      circularTrackColor: e.line,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: e.bg,
      selectedColor: e.acc,
      side: BorderSide(color: e.line2),
      shape: _square,
      labelStyle: tabular.bodySmall,
      secondaryLabelStyle: tabular.bodySmall?.copyWith(color: e.onAcc),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: e.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: e.line2)),
      titleTextStyle: tabular.titleLarge,
      contentTextStyle: tabular.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: e.panel,
      surfaceTintColor: Colors.transparent,
      shape: Border(top: BorderSide(color: e.line2)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: e.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: e.line2)),
      textStyle: tabular.bodyMedium,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(e.panel),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(side: BorderSide(color: e.line2))),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: e.bg,
      contentTextStyle: tabular.bodyMedium,
      actionTextColor: e.acc,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: e.acc)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: e.panel, border: Border.all(color: e.line2)),
      textStyle: tabular.bodySmall?.copyWith(color: e.fg),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: e.acc,
      unselectedLabelColor: e.mute,
      indicatorColor: e.acc,
      dividerColor: e.line,
      labelStyle: tabular.labelMedium,
      unselectedLabelStyle: tabular.labelMedium,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: e.acc,
      collapsedIconColor: e.mute,
      shape: _square,
      collapsedShape: _square,
    ),
  );
}

/// Monospace style for build logs and package IDs.
TextStyle monoStyle(BuildContext context, {double size = 12.5}) => TextStyle(
    fontFamily: Eleven.font,
    fontFamilyFallback: Eleven.fallback,
    fontSize: size,
    fontFeatures: _tabular,
    color: Theme.of(context).colorScheme.onSurface);
