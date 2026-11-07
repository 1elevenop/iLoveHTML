import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/theme.dart';

/// App preferences (language, appearance, animations), saved between launches.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs)
      : _locale = _parseLocale(_prefs?.getString(_kLocale)),
        _themeMode = ThemeMode.values.firstWhere((m) => m.name == _prefs?.getString(_kTheme),
            orElse: () => ThemeMode.dark),
        _accent = AccentPreset.byName(_prefs?.getString(_kAccent)),
        _animations = _prefs?.getBool(_kAnimations) ?? true,
        _checkUpdates = _prefs?.getBool(_kUpdates) ?? true;

  /// Settings that are not saved, for tests and platforms without storage.
  AppSettings.memory({Locale? language, ThemeMode mode = ThemeMode.dark, bool animate = true})
      : _prefs = null,
        _locale = language,
        _themeMode = mode,
        _accent = AccentPreset.orange,
        _animations = animate,
        _checkUpdates = false;

  static Future<AppSettings> load() async {
    try {
      return AppSettings._(await SharedPreferences.getInstance());
    } catch (_) {
      // Storage unavailable: run with defaults rather than fail to start.
      return AppSettings._(null);
    }
  }

  static const _kLocale = 'locale', _kTheme = 'themeMode', _kAccent = 'accent', _kAnimations = 'animations', _kUpdates = 'checkUpdates';

  /// The UI languages, besides following the system.
  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
    Locale('ja'),
    Locale('zh'),
    Locale('ko'),
  ];

  /// Each language's name in that language, for the picker.
  static const languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ja': '日本語',
    'zh': '中文',
    'ko': '한국어',
  };

  final SharedPreferences? _prefs;
  Locale? _locale;
  ThemeMode _themeMode;
  AccentPreset _accent;
  bool _animations;
  bool _checkUpdates;

  /// Null follows the system language.
  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AccentPreset get accent => _accent;
  bool get animations => _animations;

  /// Ask GitHub now and then whether a newer iLoveHTML was released.
  bool get checkUpdates => _checkUpdates;

  set checkUpdates(bool value) {
    _checkUpdates = value;
    _prefs?.setBool(_kUpdates, value);
    notifyListeners();
  }

  set locale(Locale? value) {
    _locale = value;
    value == null ? _prefs?.remove(_kLocale) : _prefs?.setString(_kLocale, value.languageCode);
    notifyListeners();
  }

  set themeMode(ThemeMode value) {
    _themeMode = value;
    _prefs?.setString(_kTheme, value.name);
    notifyListeners();
  }

  set accent(AccentPreset value) {
    _accent = value;
    _prefs?.setString(_kAccent, value.name);
    notifyListeners();
  }

  set animations(bool value) {
    _animations = value;
    _prefs?.setBool(_kAnimations, value);
    notifyListeners();
  }

  static Locale? _parseLocale(String? code) =>
      code == null || !languageNames.containsKey(code) ? null : Locale(code);
}

/// Whether to play decorative animations here: the user setting, unless the
/// system asks for reduced motion.
bool animationsOn(BuildContext context, AppSettings settings) =>
    settings.animations && !MediaQuery.of(context).disableAnimations;
