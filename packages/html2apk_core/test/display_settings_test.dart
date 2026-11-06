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

  group('shortcuts', () {
    ProjectManifest withShortcuts(List<AppShortcut> list, {SourceType type = SourceType.local}) => ProjectManifest(
          id: 'id',
          name: 'Demo',
          source: type == SourceType.local
              ? const ProjectSource.local('index.html')
              : const ProjectSource.url('https://example.com/'),
          android: const AndroidSettings(applicationId: 'com.example.demo'),
          shortcuts: list,
        );
    List<String> errors(ProjectManifest m) =>
        [for (final i in validateManifest(m)) if (i.field == 'shortcuts') i.message];

    test('round-trip through project.json and reach the runtime config', () {
      final m = withShortcuts(const [AppShortcut(label: ' Cart ', page: 'shop/cart.html#top')]);
      final back = ProjectManifest.fromJson(m.toJson());
      expect(back.shortcuts, const [AppShortcut(label: ' Cart ', page: 'shop/cart.html#top')]);
      expect(AndroidGenerator.runtimeConfig(m)['shortcuts'], [
        {'label': 'Cart', 'page': 'shop/cart.html#top'}
      ]);
      expect(errors(m), isEmpty);
    });

    test('old projects have none', () {
      final json = withShortcuts(const []).toJson()..remove('shortcuts');
      expect(ProjectManifest.fromJson(json).shortcuts, isEmpty);
    });

    test('local pages must stay inside source/', () {
      for (final bad in ['../secret.html', '/etc/passwd', 'a/../../b.html', 'file:x.html', 'a b.html', r'a\b.html', '']) {
        expect(errors(withShortcuts([AppShortcut(label: 'X', page: bad)])), isNotEmpty, reason: bad);
      }
    });

    test('URL pages must be a path or an https address', () {
      final ok = withShortcuts(const [
        AppShortcut(label: 'A', page: '/cart'),
        AppShortcut(label: 'B', page: 'https://example.com/b'),
      ], type: SourceType.url);
      expect(errors(ok), isEmpty);
      for (final bad in ['cart', '//evil.com/x', 'http://example.com/', 'javascript:alert(1)']) {
        expect(errors(withShortcuts([AppShortcut(label: 'X', page: bad)], type: SourceType.url)), isNotEmpty, reason: bad);
      }
    });

    test('names, count and duplicates are checked', () {
      expect(errors(withShortcuts(const [AppShortcut(label: ' ', page: 'a.html')])), isNotEmpty);
      expect(errors(withShortcuts([AppShortcut(label: 'x' * 26, page: 'a.html')])), isNotEmpty);
      expect(errors(withShortcuts(const [AppShortcut(label: 'A', page: 'a.html'), AppShortcut(label: 'B', page: 'a.html')])),
          isNotEmpty);
      expect(errors(withShortcuts([for (var i = 0; i < 5; i++) AppShortcut(label: 'S$i', page: 'p$i.html')])), isNotEmpty);
    });
  });

  group('app lock and notifications', () {
    test('off by default, with no extra permissions', () {
      final m = _manifest();
      final config = AndroidGenerator.runtimeConfig(m);
      expect(config['appLock'], isFalse);
      expect(config['notifications'], isFalse);
      expect(AndroidGenerator.permissionsFor(m), isNot(contains('android.permission.USE_BIOMETRIC')));
      expect(AndroidGenerator.permissionsFor(m), isNot(contains('android.permission.POST_NOTIFICATIONS')));
    });

    test('turning them on adds the config and the permissions they need', () {
      final m = _manifest(webView: const WebViewSettings(notifications: true)).copyWith(appLock: true);
      final config = AndroidGenerator.runtimeConfig(m);
      expect(config['appLock'], isTrue);
      expect(config['notifications'], isTrue);
      expect(AndroidGenerator.permissionsFor(m),
          containsAll(['android.permission.USE_BIOMETRIC', 'android.permission.POST_NOTIFICATIONS']));
      expect(validateManifest(m).where((i) => i.severity == IssueSeverity.error), isEmpty);
    });

    test('round-trip through project.json', () {
      final m = _manifest(webView: const WebViewSettings(notifications: true)).copyWith(appLock: true);
      final back = ProjectManifest.fromJson(m.toJson());
      expect(back.appLock, isTrue);
      expect(back.webView.notifications, isTrue);
      expect(ProjectManifest.fromJson(_manifest().toJson()..remove('security')).appLock, isFalse);
    });
  });
}
