import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'artifact_inspector.dart';
import 'build_adapter.dart';
import 'log_redaction.dart';
import 'toolchain.dart';

/// Runs the generated project's pinned Gradle wrapper as a local child process.
class GradleProcessBuildAdapter implements AndroidBuildAdapter {
  GradleProcessBuildAdapter(this.toolchain, {this.gradleUserHome});

  final Toolchain toolchain;

  /// Shared Gradle cache; defaults to the user's ~/.gradle.
  final String? gradleUserHome;

  @override
  Future<BuildResult> build(BuildRequest request, {required BuildLogSink log, CancellationToken? cancel}) async {
    final sw = Stopwatch()..start();
    final wrapper = p.join(request.projectDir, Platform.isWindows ? 'gradlew.bat' : 'gradlew');
    if (!File(wrapper).existsSync()) {
      return BuildResult(BuildStatus.failed, message: 'Gradle wrapper missing in generated project', duration: sw.elapsed);
    }
    final env = {
      'JAVA_HOME': toolchain.javaHome,
      'ANDROID_HOME': toolchain.androidSdk,
      'GRADLE_USER_HOME': ?gradleUserHome,
    };
    final args = [request.gradleTask, '--no-daemon', '--console=plain', '--stacktrace'];
    log('> gradlew ${args.join(' ')}');

    final process = await Process.start(wrapper, args,
        workingDirectory: request.projectDir, environment: env, runInShell: Platform.isWindows);
    var cancelled = false;
    unawaited(cancel?.whenCancelled.then((_) async {
      cancelled = true;
      log('Cancelling build...');
      await _killTree(process.pid);
    }));

    final out = process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((l) => log(redactSecrets(l)));
    final err = process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((l) => log(redactSecrets(l)));
    final exitCode = await process.exitCode;
    // Background JVMs (Gradle/Kotlin daemons) can inherit the pipes on
    // Windows and keep them open after the build exits; don't wait forever.
    await Future.wait([out.asFuture<void>(), err.asFuture<void>()])
        .timeout(const Duration(seconds: 10), onTimeout: () => const []);
    await Future.wait([out.cancel(), err.cancel()]);

    if (cancelled) return BuildResult(BuildStatus.cancelled, exitCode: exitCode, duration: sw.elapsed);
    if (exitCode != 0) {
      return BuildResult(BuildStatus.failed, exitCode: exitCode, message: 'Gradle exited with code $exitCode', duration: sw.elapsed);
    }

    final artifact = locateArtifact(request);
    if (artifact == null) {
      return BuildResult(BuildStatus.failed, exitCode: exitCode, message: 'Build succeeded but no ${request.format.name} was produced', duration: sw.elapsed);
    }
    final problems = inspectArtifact(artifact, request.format).problems;
    if (problems.isNotEmpty) {
      return BuildResult(BuildStatus.failed, artifactPath: artifact, exitCode: exitCode,
          message: 'Artifact failed validation: ${problems.join('; ')}', duration: sw.elapsed);
    }
    return BuildResult(BuildStatus.succeeded, artifactPath: artifact, exitCode: exitCode, duration: sw.elapsed);
  }

  /// Finds the output for [request] under the app module's build/outputs.
  static String? locateArtifact(BuildRequest request) {
    final variant = request.variant.name;
    final dir = request.format == ArtifactFormat.apk
        ? p.join(request.projectDir, 'app', 'build', 'outputs', 'apk', variant)
        : p.join(request.projectDir, 'app', 'build', 'outputs', 'bundle', variant);
    final ext = '.${request.format.name}';
    final d = Directory(dir);
    if (!d.existsSync()) return null;
    final files = d.listSync().whereType<File>().where((f) => f.path.endsWith(ext)).toList();
    return files.length == 1 ? files.single.path : null;
  }

  static Future<void> _killTree(int pid) async {
    if (Platform.isWindows) {
      // gradlew.bat starts java as a child; kill the whole tree.
      await Process.run('taskkill', ['/PID', '$pid', '/T', '/F']);
    } else {
      Process.killPid(pid, ProcessSignal.sigterm);
    }
  }
}
