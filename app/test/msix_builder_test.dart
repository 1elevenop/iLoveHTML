@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html2apk_app/src/engine/desktop_engine.dart';
import 'package:html2apk_app/src/engine/exe_builder.dart';
import 'package:html2apk_app/src/engine/msix_builder.dart';
import 'package:html2apk_app/src/engine/signing_keys.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('package fields', () {
    test('versions become four numbers with the last one 0', () {
      expect(MsixBuilder.msixVersion('1'), '1.0.0.0');
      expect(MsixBuilder.msixVersion('1.2'), '1.2.0.0');
      expect(MsixBuilder.msixVersion('1.2.3'), '1.2.3.0');
      expect(MsixBuilder.msixVersion('65535.0.1'), '65535.0.1.0');
      for (final bad in ['', '1.2.3.4', '1.0-beta', '65536', 'v1', '1..2']) {
        expect(MsixBuilder.msixVersion(bad), isNull, reason: bad);
      }
    });

    test('identity names keep only allowed characters', () {
      expect(MsixBuilder.msixIdentityName('com.example.my_app'), 'com.example.my-app');
      expect(MsixBuilder.msixIdentityName('a.b'), 'a.b');
      expect(MsixBuilder.msixIdentityName('ab'), 'ab-app');
      expect(MsixBuilder.msixIdentityName('a' * 80).length, 50);
    });

    test('exe names are safe file names', () {
      expect(MsixBuilder.msixFileName('My App'), 'My App');
      expect(MsixBuilder.msixFileName(r'a/b\c:*?"<>|'), 'abc');
      expect(MsixBuilder.msixFileName('..'), 'App');
      expect(MsixBuilder.msixFileName('नमस्ते'), 'App');
    });

    test('publisher display name is the CN', () {
      expect(MsixBuilder.commonName('CN=Alex Example'), 'Alex Example');
      expect(MsixBuilder.commonName('CN=Acme Ltd, O=Acme, C=IN'), 'Acme Ltd');
      expect(MsixBuilder.commonName('O=Acme, CN="Acme, Inc."'), 'Acme, Inc.');
    });

    test('the certificate password never reaches a command line', () {
      final builder = MsixBuilder(ExeBuilder('wrapper.exe'), const WindowsSdkTools(makeAppx: 'm.exe', signTool: 's.exe'));
      final run = builder.signInvocation(
          'app.msix', const MsixSigning(pfxPath: 'c.pfx', password: 'hunter2-secret', subject: 'CN=X', thumbprint: 'AB12'));
      expect(run.arguments.join(' '), isNot(contains('hunter2-secret')));
      expect(run.environment['H2A_PW'], 'hunter2-secret');
      expect(run.environment['H2A_THUMB'], 'AB12');
      // Started from PowerShell 7, Windows PowerShell inherits its module
      // path and then has no Cert: drive; signing must not depend on that.
      expect(run.environment['PSModulePath'], endsWith(r'\System32\WindowsPowerShell\v1.0\Modules'));
      expect(run.environment['PSModulePath'], isNot(contains(';')));
    });

    test('manifest escapes the app name and publisher', () {
      final m = ProjectManifest(
          id: newProjectId(),
          name: 'A & <B> "C"',
          source: const ProjectSource.local('index.html'),
          android: const AndroidSettings(applicationId: 'com.example.app'));
      final xml = MsixBuilder.appxManifest(m, publisher: 'CN=X & Y', version: '1.0.0.0', exeName: 'A B.exe');
      expect(xml, contains('<DisplayName>A &amp; &lt;B&gt; &quot;C&quot;</DisplayName>'));
      expect(xml, contains('Publisher="CN=X &amp; Y"'));
      expect(xml, contains(r'Executable="App\A B.exe"'));
      expect(xml, isNot(contains('<B>')));
    });
  });

  // Creates a test certificate with keytool and builds a real signed .msix.
  // Needs the Windows SDK, a JDK and tools/build_windows_wrapper.ps1.
  final repo = p.normalize(p.join(Directory.current.path, '..'));
  final dist = p.join(repo, 'windows_template', 'dist');
  final toolchain = discoverToolchain();
  final sdk = WindowsSdkTools.find();
  final skip = sdk == null
      ? 'Windows SDK not installed'
      : toolchain.toolchain == null
          ? 'No JDK'
          : !File(p.join(dist, 'html2apk_wrapper.exe')).existsSync()
              ? 'Wrapper not built'
              : false;

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('h2a_msix_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('builds a signed installer with a test certificate', (tester) async {
    await tester.runAsync(() async {
      final engine = DesktopBuildEngine(
          workspaceDir: p.join(tmp.path, 'ws'), toolchainReport: toolchain, templateDir: p.join(dist, 'android_template'));
      expect(engine.msixCertificate(), isNull);
      await expectLater(engine.createMsixCertificate('Bad, Name'), throwsA(isA<KeyManagerException>()));

      final cert = await engine.createMsixCertificate('iLoveHTML Test');
      expect(cert.subject, 'CN=iLoveHTML Test');
      expect(cert.isTest, isTrue);
      expect(cert.notAfter.isAfter(DateTime.now().add(const Duration(days: 1000))), isTrue);
      expect(engine.msixCertificate()!.thumbprint, cert.thumbprint);

      final site = Directory(p.join(tmp.path, 'site'))..createSync();
      File(p.join(site.path, 'index.html')).writeAsStringSync('<!doctype html><h1>MSIX</h1>');
      final store = ProjectStore(p.join(tmp.path, 'projects'));
      final project = (await store.importFiles(
              paths: [p.join(site.path, 'index.html')], name: 'Msix & Test', applicationId: 'com.html2apk.msix_test'))
          .project;

      final log = <String>[];
      final out = project.windowsMsixPath();
      final result = await engine.buildMsix(project, outputPath: out, log: log.add);
      expect(result.status, BuildStatus.succeeded, reason: '${result.message}\n${log.join('\n')}');
      expect(File(out).existsSync(), isTrue);
      expect(File(p.setExtension(out, '.cer')).existsSync(), isTrue);
      expect(log.join('\n'), isNot(contains(RegExp('[0-9a-f]{48}'))), reason: 'no password in the log');
      // Signing borrows the user's certificate store; nothing may stay behind.
      final left = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        r'@(Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $env:H2A_THUMB }).Count',
      ], environment: {'H2A_THUMB': cert.thumbprint});
      expect((left.stdout as String).trim(), '0', reason: 'certificate left in the store');

      final unpacked = p.join(tmp.path, 'unpacked');
      final un = await Process.run(sdk!.makeAppx, ['unpack', '/p', out, '/d', unpacked, '/o']);
      expect(un.exitCode, 0, reason: '${un.stdout}');
      final xml = File(p.join(unpacked, 'AppxManifest.xml')).readAsStringSync();
      // The signature is a PKCS#7 blob after a 4-byte "PKCX" header.
      final sig = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        r'Add-Type -AssemblyName System.Security; $b = [IO.File]::ReadAllBytes($env:H2A_P7X); '
            r'$c = New-Object Security.Cryptography.Pkcs.SignedCms; $c.Decode($b[4..($b.Length - 1)]); '
            r'$c.SignerInfos[0].Certificate.Subject',
      ], environment: {'H2A_P7X': p.join(unpacked, 'AppxSignature.p7x')});
      expect((sig.stdout as String).trim(), 'CN=iLoveHTML Test', reason: '${sig.stderr}');
      expect(xml, contains('Name="com.html2apk.msix-test"'));
      expect(xml, contains('Publisher="CN=iLoveHTML Test"'));
      expect(xml, contains('Version="1.0.0.0"'));
      expect(xml, contains('<DisplayName>Msix &amp; Test</DisplayName>'));
      expect(File(p.join(unpacked, 'App', 'Msix  Test.exe')).existsSync(), isTrue);
      for (final logo in ['StoreLogo.png', 'Square44x44Logo.png', 'Square150x150Logo.png']) {
        expect(File(p.join(unpacked, 'Assets', logo)).lengthSync(), greaterThan(100), reason: logo);
      }

      // A wrong .pfx password is reported and keeps the current certificate.
      final pfx = p.join(tmp.path, 'ws', 'windows-signing', 'certificate.pfx');
      await expectLater(engine.importMsixCertificate(pfx, 'wrong'), throwsA(isA<KeyManagerException>()));
      expect(engine.msixCertificate()!.thumbprint, cert.thumbprint);

      engine.removeMsixCertificate();
      expect(engine.msixCertificate(), isNull);
      final again = await engine.buildMsix(project, outputPath: out, log: log.add);
      expect(again.status, BuildStatus.failed);
    });
  }, skip: skip != false, timeout: const Timeout(Duration(minutes: 3)));
}

