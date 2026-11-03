import 'dart:io';

import 'package:path/path.dart' as p;

import '../project_core/manifest.dart';
import '../project_core/project_store.dart';
import '../project_core/validation.dart';
import 'resource_writers.dart';

/// Wrapper template contents that are never copied into a generated project.
const _templateExcludes = {'build', '.gradle', '.idea', '.kotlin', 'local.properties', 'wrapper.properties'};

/// Turns a project into a buildable Gradle project based on the maintained
/// wrapper template.
///
/// Kotlin sources and Gradle scripts are copied unchanged. Project-specific
/// data is written as whole, structured files (manifest XML, string
/// resources, JSON config, properties) rather than by text substitution.
class AndroidGenerator {
  AndroidGenerator({required this.templateDir});

  final String templateDir;

  static const minIconSize = 48;

  /// Generates into [outputDir], which is deleted first if present.
  void generate(ProjectHandle project, String outputDir, {required String androidSdkDir}) {
    final m = project.manifest;
    final errors = validateManifest(m).where((i) => i.severity == IssueSeverity.error).toList();
    if (errors.isNotEmpty) throw InvalidProjectException(errors);

    final out = Directory(outputDir);
    if (out.existsSync()) out.deleteSync(recursive: true);
    _copyTree(Directory(templateDir), out, top: true);

    final main = p.join(outputDir, 'app', 'src', 'main');
    File(p.join(outputDir, 'local.properties'))
        .writeAsStringSync(encodeProperties({'sdk.dir': androidSdkDir}));
    File(p.join(outputDir, 'wrapper.properties')).writeAsStringSync(encodeProperties({
      'applicationId': m.android.applicationId,
      'versionCode': '${m.android.versionCode}',
      'versionName': m.android.versionName,
    }));
    File(p.join(main, 'AndroidManifest.xml')).writeAsStringSync(buildAndroidManifest(m));
    File(p.join(main, 'res', 'values', 'app_strings.xml')).writeAsStringSync(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        '    <string name="app_name">${androidStringEscape(m.name)}</string>\n</resources>\n');
    File(p.join(main, 'assets', 'app_config.json')).writeAsStringSync(encodeJson(runtimeConfig(m)));

    final www = Directory(p.join(main, 'assets', 'www'));
    www.deleteSync(recursive: true);
    if (m.source.type == SourceType.local) {
      _copyTree(Directory(project.sourceDir), www);
      if (!File(p.join(www.path, m.source.entry)).existsSync()) {
        throw InvalidProjectException(
            [ValidationIssue('source.entry', 'Entry file "${m.source.entry}" does not exist')]);
      }
    } else {
      // URL projects only bundle extras such as the offline page.
      final source = Directory(project.sourceDir);
      source.existsSync() ? _copyTree(source, www) : www.createSync();
    }
    final offline = m.offlineFallbackPage;
    if (offline != null && !File(p.join(www.path, offline)).existsSync()) {
      throw InvalidProjectException([ValidationIssue('offline.fallbackPage', 'Offline page "$offline" does not exist')]);
    }

    final splash = project.splashFile;
    if (splash != null) {
      final target = File(p.join(main, 'assets', splashAssetPath));
      target.parent.createSync(recursive: true);
      File(splash).copySync(target.path);
    }

    final icon = project.iconFile;
    if (icon != null) {
      final bytes = File(icon).readAsBytesSync();
      final info = readPngInfo(bytes);
      if (info == null) throw InvalidProjectException([const ValidationIssue('branding.icon', 'Icon must be a PNG file')]);
      if (info.width != info.height || info.width < minIconSize) {
        throw InvalidProjectException([ValidationIssue('branding.icon',
            'Icon must be square and at least ${minIconSize}px (got ${info.width}x${info.height}); 512x512 recommended')]);
      }
      // The template ships a PNG default here; the on-device engine swaps the
      // same entry inside a prebuilt APK, so the icon must stay a PNG.
      File(p.join(main, 'res', 'drawable-nodpi', 'app_icon.png')).writeAsBytesSync(bytes);
    }
  }

  /// Contents of assets/app_config.json read by the Kotlin runtime.
  static Map<String, Object?> runtimeConfig(ProjectManifest m) => {
        'schemaVersion': 1,
        'source': {
          'type': m.source.type == SourceType.local ? 'local' : 'remote',
          'entry': m.source.entry,
        },
        'javaScriptEnabled': m.webView.javaScriptEnabled,
        'domStorageEnabled': m.webView.domStorageEnabled,
        'externalLinks': m.webView.externalLinks.name,
        'allowedHosts': m.webView.allowedHosts,
        'userAgentSuffix': m.webView.userAgentSuffix,
        'pullToRefresh': m.webView.pullToRefresh,
        'fileUploads': m.webView.fileUploads,
        'webShare': m.webView.webShare,
        'downloads': m.webView.downloads,
        'offlinePage': m.offlineFallbackPage,
        'statusBarColor': m.appearance.statusBarColor,
        'navigationBarColor': m.appearance.navigationBarColor,
        'splash': {
          'enabled': m.appearance.splashEnabled,
          'backgroundColor': m.appearance.splashBackgroundColor,
          'image': m.splashPath == null ? null : splashAssetPath,
        },
      };

  /// Where a custom splash image lives inside the APK's assets.
  static const splashAssetPath = 'branding/splash.png';

  /// Permissions the generated app declares, shared by every build engine.
  static List<String> permissionsFor(ProjectManifest m) => <String>{
        if (m.requiresInternet) 'android.permission.INTERNET',
        ...m.permissions,
      }.toList()
        ..sort();

  /// `android:screenOrientation` value (ActivityInfo constants).
  static int screenOrientationValue(Orientation o) => switch (o) {
        Orientation.unspecified => -1,
        Orientation.landscape => 0,
        Orientation.portrait => 1,
      };

  static String buildAndroidManifest(ProjectManifest m) {
    final permissions = permissionsFor(m);
    // Always written (even "unspecified") so prebuilt base APKs carry the
    // attribute and the on-device engine can change it in place.
    final orientation = switch (m.orientation) {
      Orientation.unspecified => 'unspecified',
      Orientation.portrait => 'portrait',
      Orientation.landscape => 'landscape',
    };
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="utf-8"?>')
      ..writeln('<!-- Generated by html2apk. Do not edit. -->')
      ..writeln('<manifest xmlns:android="http://schemas.android.com/apk/res/android">');
    for (final perm in permissions) {
      b.writeln('    <uses-permission android:name="${xmlEscape(perm)}" />');
    }
    b
      ..writeln('    <application')
      ..writeln('        android:allowBackup="false"')
      ..writeln('        android:icon="@drawable/app_icon"')
      ..writeln('        android:label="@string/app_name"')
      ..writeln('        android:supportsRtl="true"')
      ..writeln('        android:theme="@android:style/Theme.Material.Light.NoActionBar"')
      ..writeln('        android:usesCleartextTraffic="false">')
      ..writeln('        <activity')
      ..writeln('            android:name="com.html2apk.runtime.MainActivity"')
      ..writeln('            android:configChanges="orientation|screenSize|screenLayout|keyboardHidden|smallestScreenSize|uiMode"');
    b
      ..writeln('            android:screenOrientation="$orientation"')
      ..writeln('            android:exported="true">')
      ..writeln('            <intent-filter>')
      ..writeln('                <action android:name="android.intent.action.MAIN" />')
      ..writeln('                <category android:name="android.intent.category.LAUNCHER" />')
      ..writeln('            </intent-filter>')
      ..writeln('        </activity>')
      ..writeln('    </application>')
      ..writeln('</manifest>');
    return b.toString();
  }

  void _copyTree(Directory from, Directory to, {bool top = false}) {
    to.createSync(recursive: true);
    for (final entity in from.listSync(followLinks: false)) {
      final name = p.basename(entity.path);
      if (top && _templateExcludes.contains(name)) continue;
      final target = p.join(to.path, name);
      if (entity is Directory) {
        if (name == 'build' || name == '.gradle') continue;
        _copyTree(entity, Directory(target));
      } else if (entity is File) {
        entity.copySync(target);
      }
    }
  }
}
