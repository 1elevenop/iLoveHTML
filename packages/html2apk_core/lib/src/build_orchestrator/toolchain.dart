import 'dart:io';

import 'package:path/path.dart' as p;

/// Local build tools needed to run Gradle for the generated project.
class Toolchain {
  const Toolchain({required this.javaHome, required this.androidSdk, this.buildToolsDir});

  final String javaHome;
  final String androidSdk;

  /// Newest installed build-tools directory, used for apksigner verification.
  final String? buildToolsDir;

  String? get apksigner {
    if (buildToolsDir == null) return null;
    final f = p.join(buildToolsDir!, Platform.isWindows ? 'apksigner.bat' : 'apksigner');
    return File(f).existsSync() ? f : null;
  }
}

class ToolchainProblem {
  const ToolchainProblem(this.component, this.message, this.fix);

  final String component;
  final String message;
  final String fix;

  @override
  String toString() => '$component: $message\n  Fix: $fix';
}

class ToolchainReport {
  ToolchainReport(this.toolchain, this.problems);

  final Toolchain? toolchain;
  final List<ToolchainProblem> problems;

  bool get ok => toolchain != null;
}

/// Minimum JDK feature version for Android Gradle Plugin 9.x.
const minJdkVersion = 17;

/// Discovers JDK and Android SDK on a desktop host.
///
/// Order: explicit overrides, JAVA_HOME / ANDROID_HOME / ANDROID_SDK_ROOT,
/// then well-known install locations (Android Studio's bundled JBR, the
/// default SDK folder).
ToolchainReport discoverToolchain({
  String? javaHome,
  String? androidSdk,
  Map<String, String>? environment,
}) {
  final env = environment ?? Platform.environment;
  final problems = <ToolchainProblem>[];
  final exe = Platform.isWindows ? 'java.exe' : 'java';

  final jdkCandidates = [
    ?javaHome,
    ?env['JAVA_HOME'],
    if (Platform.isWindows) ...[
      r'C:\Program Files\Android\Android Studio\jbr',
      if (env['LOCALAPPDATA'] != null) p.join(env['LOCALAPPDATA']!, 'Programs', 'Android Studio', 'jbr'),
    ],
  ];
  String? jdk;
  for (final c in jdkCandidates) {
    if (!File(p.join(c, 'bin', exe)).existsSync()) continue;
    final version = readJdkFeatureVersion(c);
    if (version != null && version < minJdkVersion) {
      problems.add(ToolchainProblem('JDK', 'JDK at $c is version $version',
          'Install JDK $minJdkVersion or newer, or point JAVA_HOME at Android Studio\'s bundled JBR.'));
      continue;
    }
    jdk = c;
    break;
  }
  if (jdk == null && problems.isEmpty) {
    problems.add(const ToolchainProblem('JDK', 'No JDK found',
        'Install Android Studio (bundles a JDK) or a JDK 17+, then set JAVA_HOME.'));
  }

  final sdkCandidates = [
    ?androidSdk,
    ?env['ANDROID_HOME'],
    ?env['ANDROID_SDK_ROOT'],
    if (Platform.isWindows && env['LOCALAPPDATA'] != null) p.join(env['LOCALAPPDATA']!, 'Android', 'Sdk'),
  ];
  String? sdk;
  for (final c in sdkCandidates) {
    if (Directory(p.join(c, 'platforms')).existsSync() || Directory(p.join(c, 'build-tools')).existsSync()) {
      sdk = c;
      break;
    }
  }
  String? buildTools;
  if (sdk == null) {
    problems.add(const ToolchainProblem('Android SDK', 'No Android SDK found',
        'Install Android Studio and its SDK, or set ANDROID_HOME to an SDK directory.'));
  } else {
    if (!Directory(p.join(sdk, 'licenses')).existsSync()) {
      problems.add(ToolchainProblem('Android SDK', 'SDK licenses have not been accepted',
          'Open Android Studio > SDK Manager once, or run "sdkmanager --licenses".'));
    }
    final bt = Directory(p.join(sdk, 'build-tools'));
    if (bt.existsSync()) {
      final versions = bt.listSync().whereType<Directory>().map((d) => p.basename(d.path)).toList()
        ..sort(_compareVersions);
      if (versions.isNotEmpty) buildTools = p.join(bt.path, versions.last);
    }
  }

  final ok = jdk != null && sdk != null;
  return ToolchainReport(
    ok ? Toolchain(javaHome: jdk, androidSdk: sdk, buildToolsDir: buildTools) : null,
    problems,
  );
}

/// Reads JAVA_VERSION from `<jdk>/release`, e.g. "21.0.3" -> 21, "1.8.0" -> 8.
int? readJdkFeatureVersion(String jdkHome) {
  final f = File(p.join(jdkHome, 'release'));
  if (!f.existsSync()) return null;
  final m = RegExp(r'^JAVA_VERSION="([^"]+)"', multiLine: true).firstMatch(f.readAsStringSync());
  if (m == null) return null;
  final parts = m.group(1)!.split('.');
  final first = int.tryParse(parts.first);
  if (first == 1 && parts.length > 1) return int.tryParse(parts[1]);
  return first;
}

int _compareVersions(String a, String b) {
  final pa = a.split(RegExp(r'[.-]')).map((s) => int.tryParse(s) ?? -1).toList();
  final pb = b.split(RegExp(r'[.-]')).map((s) => int.tryParse(s) ?? -1).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return pa.length.compareTo(pb.length);
}
