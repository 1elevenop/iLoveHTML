import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import 'dpapi.dart';
import 'signing_keys.dart';

/// Windows build engine: the generated Gradle project built with the local
/// JDK and Android SDK ([GradleProjectBuildEngine], Phase 1), plus release
/// keys kept in the workspace with DPAPI-encrypted passwords.
class DesktopBuildEngine implements ProjectBuildEngine, KeyManager {
  DesktopBuildEngine({required this.workspaceDir, required this.toolchainReport, required this.templateDir});

  final String workspaceDir;
  final ToolchainReport toolchainReport;

  /// The wrapper template, installed next to the executable.
  final String templateDir;

  @override
  String get id => 'gradle';

  Toolchain? get toolchain => toolchainReport.toolchain;

  String get _keysDir => p.join(workspaceDir, 'keys');
  String get _registry => p.join(_keysDir, 'keys.json');

  /// Problems that stop builds, for the settings screen and the Build tab.
  List<String> get problems => [
        if (toolchain == null)
          for (final pr in toolchainReport.problems) pr.toString(),
        if (!File(p.join(templateDir, 'settings.gradle.kts')).existsSync()) 'Wrapper template missing at $templateDir',
      ];

  Map<String, Object?> info() => {
        'engine': 'Gradle (local JDK + Android SDK)',
        'javaHome': toolchain?.javaHome,
        'androidSdk': toolchain?.androidSdk,
        'template': templateDir,
      };

  @override
  Future<BuildResult> buildProject(
    ProjectHandle project, {
    required String outputPath,
    required BuildLogSink log,
    CancellationToken? cancel,
    BuildVariant variant = BuildVariant.debug,
    ReleaseSigning? signing,
    ArtifactFormat format = ArtifactFormat.apk,
  }) async {
    final tc = toolchain;
    if (tc == null || problems.isNotEmpty) {
      for (final line in problems) {
        log(line);
      }
      return BuildResult(BuildStatus.failed, message: problems.join('\n'), duration: Duration.zero);
    }
    ReleaseSigning? resolved = signing;
    if (signing is DeviceKeySigning) {
      final entry = _entries().where((e) => e['id'] == signing.key.id).firstOrNull;
      if (entry == null) {
        return const BuildResult(BuildStatus.failed, message: 'Release key not found', duration: Duration.zero);
      }
      log('Release key: ${signing.key.alias} (${signing.key.shortSha256})');
      resolved = KeystoreFileSigning(
        path: p.join(_keysDir, entry['file']! as String),
        alias: entry['alias']! as String,
        storePassword: unprotectString(entry['storePassword']! as String),
        keyPassword: unprotectString(entry['keyPassword']! as String),
      );
    }
    final engine =
        GradleProjectBuildEngine(toolchain: tc, templateDir: templateDir, buildsDir: p.join(workspaceDir, 'builds'));
    return engine.buildProject(project,
        outputPath: outputPath, log: log, cancel: cancel, variant: variant, signing: resolved, format: format);
  }

  /// Lets the user save a copy of a built file. Returns null if cancelled.
  Future<String?> saveFile(String path) => _saveCopy(path, p.basename(path), 'Save ${p.basename(path)}');

  static Future<String?> _saveCopy(String source, String fileName, String title) async {
    final ext = p.extension(fileName).substring(1);
    final uri = await FilePicker.saveFile(
        dialogTitle: title,
        fileName: fileName,
        bytes: await File(source).readAsBytes(),
        type: FileType.custom,
        allowedExtensions: [ext]);
    return uri?.toFilePath();
  }
  /// Opens the folder containing [path] in Explorer.
  Future<void> showInFolder(String path) => Process.start('explorer.exe', [p.dirname(path)]);

  // ---- Release keys

  List<Map<String, Object?>> _entries() {
    final f = File(_registry);
    if (!f.existsSync()) return [];
    return [for (final e in jsonDecode(f.readAsStringSync()) as List) (e as Map).cast<String, Object?>()];
  }

  void _save(List<Map<String, Object?>> entries) {
    Directory(_keysDir).createSync(recursive: true);
    final tmp = File('$_registry.tmp')..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(entries));
    tmp.renameSync(_registry);
  }

  static SigningKey _keyOf(Map<String, Object?> e) => SigningKey.fromMap(e);

  String _newId() {
    final r = Random.secure();
    return List.generate(12, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  String get _keytool {
    final tc = toolchain;
    if (tc == null) throw const KeyManagerException('No JDK found, so keys cannot be managed. See Settings.');
    return p.join(tc.javaHome, 'bin', Platform.isWindows ? 'keytool.exe' : 'keytool');
  }

  /// Runs keytool in English with passwords passed only through the environment.
  Future<ProcessResult> _run(List<String> args, Map<String, String> secrets) => Process.run(
        _keytool,
        ['-J-Duser.language=en', '-J-Duser.country=US', ...args],
        environment: secrets,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

  static String _error(ProcessResult r) {
    final text = '${r.stdout}\n${r.stderr}';
    final line = text.split('\n').map((l) => l.trim()).firstWhere((l) => l.startsWith('keytool error'),
        orElse: () => text.trim().split('\n').last.trim());
    if (line.contains('password was incorrect') || line.contains('Keystore was tampered')) {
      return 'Wrong keystore password';
    }
    if (line.contains('Cannot recover key') || line.contains('Given final block')) return 'Wrong key password';
    return line.replaceFirst(RegExp(r'^keytool error: (java\.\S+: )?'), '');
  }

  /// Certificate details of [alias] in [path].
  Future<Map<String, Object?>> _certInfo(String path, String alias, String storePassword) async {
    final r = await _run(['-list', '-v', '-keystore', path, '-alias', alias, '-storepass:env', 'H2A_SP'],
        {'H2A_SP': storePassword});
    if (r.exitCode != 0) throw KeyManagerException(_error(r));
    final out = r.stdout as String;
    String field(String name) =>
        RegExp('^\\s*$name:\\s*(.+)\$', multiLine: true).firstMatch(out)?.group(1)?.trim() ??
        (throw KeyManagerException('Could not read $name from the certificate'));
    return {
      'subject': field('Owner'),
      'sha1': field('SHA1'),
      'sha256': field('SHA256'),
      'notAfter': parseKeytoolDate(field('Valid from').split(' until: ').last).millisecondsSinceEpoch,
    };
  }

  /// Checks that [keyPassword] unlocks the private key (keytool -list does not).
  Future<void> _checkKeyPassword(String path, String alias, String storePassword, String keyPassword) async {
    final r = await _run(
        ['-certreq', '-keystore', path, '-alias', alias, '-storepass:env', 'H2A_SP', '-keypass:env', 'H2A_KP'],
        {'H2A_SP': storePassword, 'H2A_KP': keyPassword});
    if (r.exitCode != 0) throw KeyManagerException(_error(r));
  }

  @override
  Future<List<SigningKey>> listKeys() async => [for (final e in _entries()) _keyOf(e)];

  @override
  Future<SigningKey> createKey({
    required String alias,
    required String commonName,
    String? organization,
    String? country,
    required String password,
  }) async {
    if (password.length < 6) throw const KeyManagerException('Use a password of at least 6 characters');
    String esc(String v) => v.replaceAll(r'\', r'\\').replaceAll(',', r'\,');
    final dname = [
      'CN=${esc(commonName)}',
      if (organization != null && organization.isNotEmpty) 'O=${esc(organization)}',
      if (country != null && country.isNotEmpty) 'C=${esc(country)}',
    ].join(', ');
    final id = _newId();
    final file = '$id.jks';
    Directory(_keysDir).createSync(recursive: true);
    final path = p.join(_keysDir, file);
    final r = await _run([
      '-genkeypair', '-keystore', path, '-storetype', 'PKCS12', '-alias', alias, '-keyalg', 'RSA', '-keysize', '4096',
      '-sigalg', 'SHA256withRSA', '-validity', '10000', '-dname', dname, //
      '-storepass:env', 'H2A_SP', '-keypass:env', 'H2A_SP',
    ], {'H2A_SP': password});
    if (r.exitCode != 0) {
      if (File(path).existsSync()) File(path).deleteSync();
      throw KeyManagerException(_error(r));
    }
    return _register(id, file, alias, password, password, 'created');
  }

  Future<SigningKey> _register(
      String id, String file, String alias, String storePassword, String keyPassword, String origin) async {
    final path = p.join(_keysDir, file);
    try {
      final cert = await _certInfo(path, alias, storePassword);
      final entry = <String, Object?>{
        'id': id,
        'alias': alias,
        ...cert,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'origin': origin,
        'file': file,
        'storePassword': protectString(storePassword),
        'keyPassword': protectString(keyPassword),
      };
      _save([..._entries(), entry]);
      return _keyOf(entry);
    } on Object {
      if (File(path).existsSync()) File(path).deleteSync();
      rethrow;
    }
  }

  @override
  Future<List<String>> inspectKeystore(String path, String storePassword) async =>
      parseKeytoolAliases(await _list(path, storePassword));

  Future<String> _list(String path, String storePassword) async {
    final r = await _run(['-list', '-keystore', path, '-storepass:env', 'H2A_SP'], {'H2A_SP': storePassword});
    if (r.exitCode != 0) throw KeyManagerException(_error(r));
    return r.stdout as String;
  }

  @override
  Future<SigningKey> importKey({
    required String path,
    required String storePassword,
    required String alias,
    required String keyPassword,
  }) async {
    // PKCS12 keys use the keystore password (keytool ignores -keypass there).
    if (RegExp(r'Keystore type: PKCS12', caseSensitive: false).hasMatch(await _list(path, storePassword))) {
      if (keyPassword != storePassword) {
        throw const KeyManagerException('Wrong key password: in a PKCS12 keystore it is the keystore password');
      }
    } else {
      await _checkKeyPassword(path, alias, storePassword, keyPassword);
    }
    final sha = (await _certInfo(path, alias, storePassword))['sha256'];
    if (_entries().any((e) => e['sha256'] == sha && e['alias'] == alias)) {
      throw const KeyManagerException('This key is already in the list');
    }
    final id = _newId();
    final ext = p.extension(path).toLowerCase();
    final file = '$id${ext.isEmpty ? '.jks' : ext}';
    Directory(_keysDir).createSync(recursive: true);
    File(path).copySync(p.join(_keysDir, file));
    return _register(id, file, alias, storePassword, keyPassword, 'imported');
  }

  @override
  Future<String?> exportKey(String id) async {
    final entry = _entries().where((e) => e['id'] == id).firstOrNull;
    if (entry == null) throw const KeyManagerException('Key not found');
    final file = entry['file']! as String;
    return _saveCopy(p.join(_keysDir, file), '${entry['alias']}${p.extension(file)}', 'Back up release key');
  }
  @override
  Future<void> deleteKey(String id) async {
    final entries = _entries();
    final entry = entries.where((e) => e['id'] == id).firstOrNull;
    if (entry == null) return;
    _save([for (final e in entries) if (e['id'] != id) e]);
    final f = File(p.join(_keysDir, entry['file']! as String));
    if (f.existsSync()) f.deleteSync();
  }
}

/// Aliases of private-key entries in `keytool -list` output.
List<String> parseKeytoolAliases(String out) => [
      for (final line in out.split('\n'))
        if (line.contains('PrivateKeyEntry')) line.substring(0, line.indexOf(',')).trim(),
    ];

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Parses keytool's English date, e.g. `Tue Mar 09 13:21:05 IST 2054`.
/// The time zone is ignored; the date is all the UI shows.
DateTime parseKeytoolDate(String s) {
  final m = RegExp(r'(\w{3}) (\d{1,2}) (\d{2}):(\d{2}):(\d{2}) \S+ (\d{4})').firstMatch(s);
  if (m == null) throw KeyManagerException('Unexpected date from keytool: $s');
  return DateTime(int.parse(m[6]!), _months.indexOf(m[1]!) + 1, int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!),
      int.parse(m[5]!));
}
