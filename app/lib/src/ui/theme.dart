import 'package:flutter/material.dart';

/// Fixed tokens of the iLoveHTML neo-brutalist design: thick ink strokes,
/// hard offset shadows and flat colour blocks. Colours live in
/// [ElevenPalette], which depends on light/dark mode and the accent preset.
abstract final class Eleven {
  /// Headings and body text.
  static const font = 'SpaceGrotesk';

  /// Code, package IDs, logs.
  static const mono = 'JetBrainsMono';

  /// Neither font has CJK glyphs; these system fonts fill them in.
  static const fallback = [
    'Microsoft YaHei UI',
    'Yu Gothic UI',
    'Malgun Gothic',
    'Noto Sans CJK SC',
    'Noto Sans CJK JP',
    'Noto Sans CJK KR',
    'sans-serif',
  ];

  static const stroke = 2.5;
  static const radius = 8.0;
  static const shadowOffset = Offset(4, 4);
}

/// The accent colour block. [block] fills buttons and tiles; [textLight] is a
/// darker shade that stays readable as text on the cream page.
enum AccentPreset {
  yellow(Color(0xFFFFD60A), Color(0xFF000000), Color(0xFF7A5F00)),
  pink(Color(0xFFFF5C8A), Color(0xFF000000), Color(0xFFC2185B)),
  purple(Color(0xFF7B61FF), Color(0xFFFFFFFF), Color(0xFF5B3FE0)),
  teal(Color(0xFF00C2CB), Color(0xFF000000), Color(0xFF00727A)),
  green(Color(0xFF3CCB4A), Color(0xFF000000), Color(0xFF1C7A29));

  const AccentPreset(this.block, this.onBlock, this.textLight);

  final Color block, onBlock, textLight;

  /// Saved names from before 1.2.5 map to the nearest new block colour.
  static AccentPreset byName(String? name) => switch (name) {
    'orange' => AccentPreset.yellow,
    'cyan' => AccentPreset.teal,
    'violet' => AccentPreset.purple,
    _ => AccentPreset.values.firstWhere((a) => a.name == name, orElse: () => AccentPreset.yellow),
  };
}

/// The other block colours, for icon tiles and step chips.
const brutalBlocks = [Color(0xFFFFD60A), Color(0xFFFF5C8A), Color(0xFF7B61FF), Color(0xFF00C2CB), Color(0xFF3CCB4A)];

/// Resolved colour tokens.
@immutable
class ElevenPalette extends ThemeExtension<ElevenPalette> {
  const ElevenPalette({
    required this.bg,
    required this.panel,
    required this.fg,
    required this.mute,
    required this.line,
    required this.line2,
    required this.ink,
    required this.acc,
    required this.accHi,
    required this.onAcc,
    required this.block,
    required this.onBlock,
  });

  factory ElevenPalette.of(Brightness brightness, AccentPreset accent) => brightness == Brightness.dark
      ? ElevenPalette(
          bg: const Color(0xFF0F0F0F),
          panel: const Color(0xFF1A1A1A),
          fg: const Color(0xFFFFFFFF),
          mute: const Color(0xFFB3AFA6),
          line: const Color(0xFF333333),
          line2: const Color(0xFFFFFFFF),
          ink: const Color(0xFFFFFFFF),
          acc: accent.block,
          accHi: Color.lerp(accent.block, Colors.white, 0.3)!,
          onAcc: accent.onBlock,
          block: accent.block,
          onBlock: accent.onBlock,
        )
      : ElevenPalette(
          bg: const Color(0xFFFFFDF5),
          panel: const Color(0xFFFFFFFF),
          fg: const Color(0xFF000000),
          mute: const Color(0xFF55514A),
          line: const Color(0xFFE6E0CC),
          line2: const Color(0xFF000000),
          ink: const Color(0xFF000000),
          acc: accent.textLight,
          accHi: Color.lerp(accent.textLight, Colors.black, 0.2)!,
          onAcc: const Color(0xFFFFFFFF),
          block: accent.block,
          onBlock: accent.onBlock,
        );

  /// [acc] is the accent for text and icons on [bg]; [block] is the flat fill.
  final Color bg, panel, fg, mute, line, line2, ink, acc, accHi, onAcc, block, onBlock;

  Color get accSoft => block.withAlpha(0x33);

  /// The hard offset shadow under raised blocks.
  List<BoxShadow> get shadow => [BoxShadow(color: ink, offset: Eleven.shadowOffset)];

  /// Kept for older call sites: now the same hard shadow.
  List<BoxShadow> get glow => shadow;

  BorderSide get strokeSide => BorderSide(color: ink, width: Eleven.stroke);

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
      ink: l(ink, other.ink),
      acc: l(acc, other.acc),
      accHi: l(accHi, other.accHi),
      onAcc: l(onAcc, other.onAcc),
      block: l(block, other.block),
      onBlock: l(onBlock, other.onBlock),
    );
  }
}

extension ElevenContext on BuildContext {
  ElevenPalette get eleven => Theme.of(this).extension<ElevenPalette>()!;
}

class _NoTransition extends PageTransitionsBuilder {
  const _NoTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

const _tabular = [FontFeature.tabularFigures()];
const _r = BorderRadius.all(Radius.circular(Eleven.radius));

/// iLoveHTML's neo-brutalist theme in light or dark, with the chosen accent.
ThemeData buildTheme({
  Brightness brightness = Brightness.light,
  AccentPreset accent = AccentPreset.yellow,
  bool animations = true,
}) {
  final e = ElevenPalette.of(brightness, accent);
  final dark = brightness == Brightness.dark;
  final ink = e.strokeSide;
  final shape = RoundedRectangleBorder(borderRadius: _r, side: ink);
  final scheme = (dark ? ColorScheme.dark : ColorScheme.light)(
    primary: e.block,
    onPrimary: e.onBlock,
    primaryContainer: e.accSoft,
    onPrimaryContainer: e.fg,
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
    outline: e.ink,
    outlineVariant: e.line,
    inverseSurface: e.fg,
    onInverseSurface: e.bg,
    inversePrimary: e.block,
    shadow: e.ink,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: Eleven.font,
    fontFamilyFallback: Eleven.fallback,
  );
  TextStyle ts(double size, FontWeight w, {double h = 1.4, double ls = 0, Color? c}) =>
      TextStyle(fontSize: size, height: h, fontWeight: w, letterSpacing: ls, color: c ?? e.fg);
  final text = base.textTheme
      .apply(bodyColor: e.fg, displayColor: e.fg)
      .copyWith(
        displaySmall: ts(36, FontWeight.w700, h: 1.1, ls: -1),
        headlineLarge: ts(32, FontWeight.w700, h: 1.1, ls: -0.8),
        headlineMedium: ts(26, FontWeight.w700, h: 1.15, ls: -0.5),
        headlineSmall: ts(22, FontWeight.w700, h: 1.2, ls: -0.3),
        titleLarge: ts(19, FontWeight.w700, h: 1.3, ls: -0.2),
        titleMedium: ts(16, FontWeight.w700, h: 1.4),
        titleSmall: ts(13, FontWeight.w700, h: 1.3, ls: 0.8, c: e.mute),
        bodyLarge: ts(16, FontWeight.w400, h: 1.5),
        bodyMedium: ts(15, FontWeight.w400, h: 1.5),
        bodySmall: ts(13, FontWeight.w400, h: 1.45, c: e.mute),
        labelLarge: ts(15, FontWeight.w700),
        labelMedium: ts(13, FontWeight.w700, ls: 0.4),
        labelSmall: ts(12, FontWeight.w700, ls: 0.4),
      )
      .apply(fontFamily: Eleven.font, fontFamilyFallback: Eleven.fallback);
  final tabular = text.copyWith(
    displayLarge: text.displayLarge?.copyWith(fontFeatures: _tabular),
    headlineMedium: text.headlineMedium?.copyWith(fontFeatures: _tabular),
    bodyMedium: text.bodyMedium?.copyWith(fontFeatures: _tabular),
    bodySmall: text.bodySmall?.copyWith(fontFeatures: _tabular),
  );

  const control = Size(44, 44);
  // Focus shows as a thicker stroke, so keyboard users always see where they are.
  WidgetStateProperty<BorderSide> sides() => WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.disabled)
        ? BorderSide(color: e.line, width: Eleven.stroke)
        : s.contains(WidgetState.focused)
        ? BorderSide(color: e.ink, width: Eleven.stroke + 1.5)
        : ink,
  );
  final outlined = OutlinedButton.styleFrom(
    foregroundColor: e.fg,
    backgroundColor: e.panel,
    minimumSize: control,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(borderRadius: _r),
    textStyle: tabular.labelLarge,
  ).copyWith(side: sides());

  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: animations ? const FadeForwardsPageTransitionsBuilder() : const _NoTransition(),
      },
    ),
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
      shape: Border(bottom: ink),
    ),
    cardTheme: CardThemeData(
      color: e.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: shape,
    ),
    dividerTheme: DividerThemeData(color: e.line, thickness: 1.5, space: 1.5),
    listTileTheme: ListTileThemeData(
      iconColor: e.fg,
      textColor: e.fg,
      minVerticalPadding: 10,
      titleTextStyle: tabular.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: tabular.bodySmall,
      shape: const RoundedRectangleBorder(borderRadius: _r),
    ),
    iconTheme: IconThemeData(color: e.fg),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: e.block,
        foregroundColor: e.onBlock,
        disabledBackgroundColor: e.line,
        disabledForegroundColor: e.mute,
        minimumSize: control,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const RoundedRectangleBorder(borderRadius: _r),
        textStyle: tabular.labelLarge,
        elevation: 0,
      ).copyWith(side: sides()),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: outlined),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlined),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: e.fg,
        minimumSize: control,
        shape: const RoundedRectangleBorder(borderRadius: _r),
        textStyle: tabular.labelLarge?.copyWith(decoration: TextDecoration.underline, decorationThickness: 2),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: e.fg,
        minimumSize: control,
        shape: const RoundedRectangleBorder(borderRadius: _r),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: e.block,
      foregroundColor: e.onBlock,
      elevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
      shape: shape,
      extendedTextStyle: tabular.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: _r)),
        side: WidgetStatePropertyAll(ink),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.block : e.panel),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.onBlock : e.fg),
        textStyle: WidgetStatePropertyAll(tabular.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: e.panel,
      labelStyle: tabular.bodyMedium?.copyWith(color: e.mute),
      floatingLabelStyle: tabular.labelMedium?.copyWith(color: e.fg),
      hintStyle: tabular.bodyMedium?.copyWith(color: e.mute),
      helperStyle: tabular.bodySmall,
      errorStyle: tabular.bodySmall?.copyWith(color: e.fg, fontWeight: FontWeight.w700),
      border: OutlineInputBorder(borderRadius: _r, borderSide: ink),
      enabledBorder: OutlineInputBorder(borderRadius: _r, borderSide: ink),
      focusedBorder: OutlineInputBorder(
        borderRadius: _r,
        borderSide: ink.copyWith(width: Eleven.stroke + 1.5),
      ),
      errorBorder: OutlineInputBorder(borderRadius: _r, borderSide: ink),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: _r,
        borderSide: ink.copyWith(width: Eleven.stroke + 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: _r,
        borderSide: BorderSide(color: e.line, width: Eleven.stroke),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
      side: BorderSide(color: e.ink, width: 2),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.block : null),
      checkColor: WidgetStatePropertyAll(e.onBlock),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.ink : e.mute),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.block : e.panel),
      trackOutlineColor: WidgetStatePropertyAll(e.ink),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? e.fg : e.mute),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: dark ? e.block : e.fg,
      linearTrackColor: e.line,
      circularTrackColor: e.line,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: e.panel,
      selectedColor: e.block,
      side: BorderSide(color: e.ink, width: 2),
      shape: const RoundedRectangleBorder(borderRadius: _r),
      labelStyle: tabular.bodySmall?.copyWith(color: e.fg, fontWeight: FontWeight.w500),
      secondaryLabelStyle: tabular.bodySmall?.copyWith(color: e.onBlock),
      checkmarkColor: e.onBlock,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: e.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
      titleTextStyle: tabular.titleLarge,
      contentTextStyle: tabular.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: e.panel,
      surfaceTintColor: Colors.transparent,
      shape: Border(top: ink),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: e.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
      textStyle: tabular.bodyMedium,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(e.panel),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(shape),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: e.panel,
      contentTextStyle: tabular.bodyMedium,
      actionTextColor: e.fg,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: shape,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: e.panel,
        border: Border.all(color: e.ink, width: 2),
        borderRadius: _r,
      ),
      textStyle: tabular.bodySmall?.copyWith(color: e.fg),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: e.onBlock,
      unselectedLabelColor: e.fg,
      indicator: BoxDecoration(
        color: e.block,
        border: Border.all(color: e.ink, width: 2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Eleven.radius)),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: tabular.labelMedium,
      unselectedLabelStyle: tabular.labelMedium,
      dividerColor: e.ink,
      dividerHeight: 2,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: e.fg,
      collapsedIconColor: e.fg,
      shape: const RoundedRectangleBorder(borderRadius: _r),
      collapsedShape: const RoundedRectangleBorder(borderRadius: _r),
    ),
  );
}

/// Monospace style for build logs and package IDs.
TextStyle monoStyle(BuildContext context, {double size = 12.5}) => TextStyle(
  fontFamily: Eleven.mono,
  fontFamilyFallback: Eleven.fallback,
  fontSize: size,
  fontFeatures: _tabular,
  color: Theme.of(context).colorScheme.onSurface,
);
