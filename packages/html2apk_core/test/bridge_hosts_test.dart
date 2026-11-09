import 'package:html2apk_core/html2apk_core.dart';
import 'package:test/test.dart';

ProjectManifest urlApp(WebViewSettings webView) => ProjectManifest(
      id: newProjectId(),
      name: 'Shop',
      source: const ProjectSource.url('https://example.com/'),
      android: const AndroidSettings(applicationId: 'com.example.shop'),
      webView: webView,
    );

void main() {
  test('new projects give the native bridge to no extra site', () {
    const w = WebViewSettings(allowedHosts: ['login.example.net']);
    expect(w.bridgeHosts, isEmpty);
    expect(WebViewSettings.fromJson(w.toJson()).bridgeHosts, isEmpty);
    expect(AndroidGenerator.runtimeConfig(urlApp(w))['bridgeHosts'], isEmpty);
  });

  test('projects saved before bridgeHosts existed keep working as they did', () {
    final legacy = const WebViewSettings(allowedHosts: ['a.example.com', 'b.example.com']).toJson()..remove('bridgeHosts');
    expect(WebViewSettings.fromJson(legacy).bridgeHosts, ['a.example.com', 'b.example.com']);
  });

  test('the choice survives saving and reaches the app', () {
    const w = WebViewSettings(allowedHosts: ['a.example.com', 'pay.example.net'], bridgeHosts: ['a.example.com']);
    final loaded = WebViewSettings.fromJson(w.toJson());
    expect(loaded.bridgeHosts, ['a.example.com']);
    expect(loaded.copyWith(bridgeHosts: const []).bridgeHosts, isEmpty);
    expect(AndroidGenerator.runtimeConfig(urlApp(w))['bridgeHosts'], ['a.example.com']);
    expect(validateManifest(urlApp(w)).where((i) => i.severity == IssueSeverity.error), isEmpty);
  });

  test('a bridge host must be one of the sites that open inside the app', () {
    const w = WebViewSettings(allowedHosts: ['a.example.com'], bridgeHosts: ['evil.example.net']);
    final issues = validateManifest(urlApp(w)).where((i) => i.severity == IssueSeverity.error).toList();
    expect(issues.map((i) => i.field), ['webView.bridgeHosts']);
  });
}
