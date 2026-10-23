import 'package:flutter/material.dart';

/// Colour tokens from the New ELEVEN design system: a black terminal ground
/// with one orange signal. Orange only marks done, score or "act now".
abstract final class Eleven {
  static const bg = Color(0xFF000000);
  static const panel = Color(0xFF090908);
  static const fg = Color(0xFFF2EFEA);
  static const mute = Color(0xFF8C8781);
  static const line = Color(0xFF1F1D1B);
  static const line2 = Color(0xFF3A3531);
  static const acc = Color(0xFFFF7A1A);
  static const accHi = Color(0xFFFFB37A);
  static const accSoft = Color(0x1FFF7A1A);
  static const onAcc = Color(0xFF120600);

  static const font = 'JetBrainsMono';

  /// The system's signature glow; on orange things only.
  static const glow = [
    BoxShadow(color: Color(0xCCFF7A1A), blurRadius: 6),
    BoxShadow(color: Color(0x59FF7A1A), blurRadius: 20),
  ];
}

const _tabular = [FontFeature.tabularFigures()];
const _square = RoundedRectangleBorder();
const _sm = BorderRadius.all(Radius.circular(4));

/// New ELEVEN has one theme, dark.
ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Eleven.acc,
    onPrimary: Eleven.onAcc,
    primaryContainer: Eleven.accSoft,
    onPrimaryContainer: Eleven.acc,
    secondary: Eleven.acc,
    onSecondary: Eleven.onAcc,
    secondaryContainer: Eleven.line,
    onSecondaryContainer: Eleven.fg,
    tertiary: Eleven.accHi,
    onTertiary: Eleven.onAcc,
    // Missed or failed reads in fg on bg, never a warning red.
    error: Eleven.fg,
    onError: Eleven.bg,
    errorContainer: Eleven.line,
    onErrorContainer: Eleven.fg,
    surface: Eleven.bg,
    onSurface: Eleven.fg,
    onSurfaceVariant: Eleven.mute,
    surfaceContainerLowest: Eleven.bg,
    surfaceContainerLow: Eleven.panel,
    surfaceContainer: Eleven.panel,
    surfaceContainerHigh: Eleven.panel,
    surfaceContainerHighest: Eleven.line,
    outline: Eleven.mute,
    outlineVariant: Eleven.line,
    inverseSurface: Eleven.fg,
    onInverseSurface: Eleven.bg,
    inversePrimary: Eleven.acc,
    shadow: Eleven.acc,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: scheme, fontFamily: Eleven.font);
  final text = base.textTheme
      .apply(bodyColor: Eleven.fg, displayColor: Eleven.fg, fontFamily: Eleven.font)
      .copyWith(
        titleLarge: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Eleven.fg),
        titleMedium: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, letterSpacing: 0, color: Eleven.fg),
        titleSmall: const TextStyle(
            fontSize: 12, height: 1.33, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: Eleven.mute),
        bodyLarge: const TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0, color: Eleven.fg),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5, letterSpacing: 0, color: Eleven.fg),
        bodySmall: const TextStyle(fontSize: 12.5, height: 1.44, letterSpacing: 0, color: Eleven.mute),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0, color: Eleven.fg),
        labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: Eleven.fg),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: Eleven.fg),
      )
      .apply(fontFamily: Eleven.font);
  final tabular = text.copyWith(
    displayLarge: text.displayLarge?.copyWith(fontFeatures: _tabular),
    headlineMedium: text.headlineMedium?.copyWith(fontFeatures: _tabular),
    bodyMedium: text.bodyMedium?.copyWith(fontFeatures: _tabular),
    bodySmall: text.bodySmall?.copyWith(fontFeatures: _tabular),
  );

  const control = Size(40, 40);
  final outlined = OutlinedButton.styleFrom(
    foregroundColor: Eleven.fg,
    minimumSize: control,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shape: const RoundedRectangleBorder(borderRadius: _sm),
    textStyle: tabular.labelLarge,
  ).copyWith(
    side: WidgetStateProperty.resolveWith((s) => BorderSide(
        color: s.contains(WidgetState.disabled)
            ? Eleven.line
            : s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                ? Eleven.acc
                : Eleven.line2)),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Eleven.bg,
    canvasColor: Eleven.bg,
    textTheme: tabular,
    primaryTextTheme: tabular,
    dividerColor: Eleven.line,
    splashFactory: InkRipple.splashFactory,
    hoverColor: Eleven.accSoft,
    focusColor: Eleven.accSoft,
    highlightColor: Eleven.accSoft,
    splashColor: Eleven.accSoft,
    appBarTheme: AppBarTheme(
      backgroundColor: Eleven.bg,
      foregroundColor: Eleven.fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: tabular.titleLarge,
      shape: const Border(bottom: BorderSide(color: Eleven.line)),
    ),
    cardTheme: const CardThemeData(
      color: Eleven.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(side: BorderSide(color: Eleven.line)),
    ),
    dividerTheme: const DividerThemeData(color: Eleven.line, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: Eleven.mute,
      textColor: Eleven.fg,
      minVerticalPadding: 9,
      subtitleTextStyle: tabular.bodySmall,
      shape: _square,
    ),
    iconTheme: const IconThemeData(color: Eleven.fg),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Eleven.acc,
        foregroundColor: Eleven.onAcc,
        disabledBackgroundColor: Eleven.line,
        disabledForegroundColor: Eleven.mute,
        minimumSize: control,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const RoundedRectangleBorder(borderRadius: _sm),
        textStyle: tabular.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        elevation: 6,
        shadowColor: Eleven.acc,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
            ? Eleven.line
            : s.contains(WidgetState.hovered)
                ? Eleven.accHi
                : Eleven.acc),
        elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? 0 : 6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: outlined),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlined),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Eleven.acc,
        minimumSize: control,
        shape: const RoundedRectangleBorder(borderRadius: _sm),
        textStyle: tabular.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Eleven.fg,
        minimumSize: control,
        shape: const RoundedRectangleBorder(borderRadius: _sm),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Eleven.acc,
      foregroundColor: Eleven.onAcc,
      elevation: 8,
      hoverElevation: 10,
      shape: RoundedRectangleBorder(borderRadius: _sm),
      extendedTextStyle: TextStyle(fontFamily: Eleven.font, fontWeight: FontWeight.w700, letterSpacing: 0.4),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: _sm)),
        side: const WidgetStatePropertyAll(BorderSide(color: Eleven.line2)),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.acc : null),
        foregroundColor:
            WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.onAcc : Eleven.fg),
        textStyle: WidgetStatePropertyAll(tabular.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Eleven.bg,
      labelStyle: tabular.bodyMedium?.copyWith(color: Eleven.mute),
      floatingLabelStyle: tabular.labelMedium?.copyWith(color: Eleven.acc),
      hintStyle: tabular.bodyMedium?.copyWith(color: Eleven.mute),
      helperStyle: tabular.bodySmall,
      errorStyle: tabular.bodySmall?.copyWith(color: Eleven.fg),
      border: const OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: Eleven.line2)),
      enabledBorder: const OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: Eleven.line2)),
      focusedBorder: const OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: Eleven.acc, width: 2)),
      errorBorder: const OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: Eleven.fg)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: Eleven.fg, width: 2)),
      disabledBorder: const OutlineInputBorder(borderRadius: _sm, borderSide: BorderSide(color: Eleven.line)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: _square,
      side: const BorderSide(color: Eleven.mute),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.acc : null),
      checkColor: const WidgetStatePropertyAll(Eleven.onAcc),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.onAcc : Eleven.mute),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.acc : Eleven.bg),
      trackOutlineColor:
          WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.acc : Eleven.mute),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Eleven.acc : Eleven.mute),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Eleven.acc,
      linearTrackColor: Eleven.line,
      circularTrackColor: Eleven.line,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Eleven.bg,
      selectedColor: Eleven.acc,
      side: const BorderSide(color: Eleven.line2),
      shape: _square,
      labelStyle: tabular.bodySmall,
      secondaryLabelStyle: tabular.bodySmall?.copyWith(color: Eleven.onAcc),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Eleven.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Eleven.line2)),
      titleTextStyle: tabular.titleLarge,
      contentTextStyle: tabular.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Eleven.panel,
      surfaceTintColor: Colors.transparent,
      shape: Border(top: BorderSide(color: Eleven.line2)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Eleven.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Eleven.line2)),
      textStyle: tabular.bodyMedium,
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Eleven.panel),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(side: BorderSide(color: Eleven.line2))),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Eleven.bg,
      contentTextStyle: tabular.bodyMedium,
      actionTextColor: Eleven.acc,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Eleven.acc)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: Eleven.panel, border: Border.all(color: Eleven.line2)),
      textStyle: tabular.bodySmall?.copyWith(color: Eleven.fg),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Eleven.acc,
      unselectedLabelColor: Eleven.mute,
      indicatorColor: Eleven.acc,
      dividerColor: Eleven.line,
      labelStyle: tabular.labelMedium,
      unselectedLabelStyle: tabular.labelMedium,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Eleven.acc,
      collapsedIconColor: Eleven.mute,
      shape: _square,
      collapsedShape: _square,
    ),
  );
}

/// Monospace style for build logs and package IDs.
TextStyle monoStyle(BuildContext context, {double size = 12.5}) => TextStyle(
    fontFamily: Eleven.font,
    fontSize: size,
    fontFeatures: _tabular,
    color: Theme.of(context).colorScheme.onSurface);
