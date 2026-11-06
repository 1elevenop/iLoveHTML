import 'package:html2apk_core/html2apk_core.dart';
import 'package:test/test.dart';

ProjectManifest _manifest({AppearanceSettings? appearance, WebViewSettings? webView}) => ProjectManifest(
      id: 'id',
      name: 'Demo',
      source: const ProjectSource.local('index.html'),
      android: const AndroidSettings(applicationId: 'com.example.demo'),
      appearance: appearance ?? const AppearanceSettings(),
      webView: webView ?? const WebViewSettings(),
    );

void main() {
  test('defaults keep the old behaviour', () {
    final config = AndroidGenerator.runtimeConfig(_manifest());
    expect(config['theme'], 'light');
    expect(config['fullscreen'], isFalse);
    expect(config['keepScreenOn'], isFalse);
    expect(config['backButton'], 'history');
  });

  test('projects saved before these settings load with defaults', () {
    final a = AppearanceSettings.fromJson({'statusBarColor': '#112233'});
    expect(a.theme, AppTheme.light);
    expect(a.fullscreen, isFalse);
    expect(a.keepScreenOn, isFalse);
    expect(WebViewSettings.fromJson({}).backButton, BackButtonMode.history);
  });

  test('unknown values from a newer release fall back instead of failing', () {
    expect(AppearanceSettings.fromJson({'theme': 'sepia'}).theme, AppTheme.light);
    expect(WebViewSettings.fromJson({'backButton': 'swipe'}).backButton, BackButtonMode.history);
  });

  for (final mode in BackButtonMode.values) {
    test('back button ${mode.name} round-trips and reaches the runtime config', () {
      final w = const WebViewSettings().copyWith(backButton: mode);
      expect(WebViewSettings.fromJson(w.toJson()).backButton, mode);
      expect(AndroidGenerator.runtimeConfig(_manifest(webView: w))['backButton'], mode.name);
    });
  }

  test('theme, fullscreen and keep screen on round-trip and reach the runtime config', () {
    final a = const AppearanceSettings().copyWith(theme: AppTheme.system, fullscreen: true, keepScreenOn: true);
    final back = AppearanceSettings.fromJson(a.toJson());
    expect(back.theme, AppTheme.system);
    expect(back.fullscreen, isTrue);
    expect(back.keepScreenOn, isTrue);
    final config = AndroidGenerator.runtimeConfig(_manifest(appearance: a));
    expect(config['theme'], 'system');
    expect(config['fullscreen'], isTrue);
    expect(config['keepScreenOn'], isTrue);
  });
}
