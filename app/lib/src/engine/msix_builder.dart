import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;

import 'exe_builder.dart';

/// `makeappx.exe` and `signtool.exe` from the Windows SDK (ADR 0008).
class WindowsSdkTools {
  const WindowsSdkTools({required this.makeAppx, required this.signTool});

  final String makeAppx;
  final String signTool;

  /// The newest SDK under `Windows Kits\10\bin` that has both tools, or null.
  static WindowsSdkTools? find({String? kitsBin}) {
    final root = kitsBin ??
        p.join(Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)', 'Windows Kits', '10', 'bin');
    final dir = Directory(root);
    if (!dir.existsSync()) return null;
    final versions = [
      for (final d in dir.listSync().whereType<Directory>())
        if (RegExp(r'^\d+(\.\d+){3}$').hasMatch(p.basename(d.path))) d.path,
    ]..sort((a, b) => _compareVersions(p.basename(b), p.basename(a)));
    for (final v in versions) {
      final makeAppx = p.join(v, 'x64', 'makeappx.exe');
      final signTool = p.join(v, 'x64', 'signtool.exe');
      if (File(makeAppx).existsSync() && File(signTool).existsSync()) {
        return WindowsSdkTools(makeAppx: makeAppx, signTool: signTool);
      }
    }
    return null;
  }

  static int _compareVersions(String a, String b) {
    final x = a.split('.').map(int.parse).toList(), y = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 4; i++) {
      if (x[i] != y[i]) return x[i].compareTo(y[i]);
    }
    return 0;
  }
}

/// The certificate that signs a package. [subject] must be the
/// certificate's subject exactly as Windows prints it (`CN=…`).
class MsixSigning {
  const MsixSigning({required this.pfxPath, required this.password, required this.subject, required this.thumbprint});

  final String pfxPath;
  final String password;
  final String subject;

  /// SHA-1 thumbprint of the certificate, as Windows prints it.
  final String thumbprint;
}

/// signtool accepts a .pfx password only on its command line, where every
/// process on the PC can read it. So the certificate is put in the user's
/// certificate store for the length of the signing (password through the
/// environment, key not exportable), signtool picks it by thumbprint, and
/// whatever was added is removed again. A certificate that was already in
/// the store is used as it is and left alone.
const _signScript = r'''
$ErrorActionPreference = 'Stop'
$my = 'Cert:\CurrentUser\My'
$added = @()
$code = 1
try {
  $had = @(Get-ChildItem $my | ForEach-Object { $_.Thumbprint })
  if (-not (Get-ChildItem $my | Where-Object { $_.Thumbprint -eq $env:H2A_THUMB -and $_.HasPrivateKey })) {
    $inPfx = New-Object Security.Cryptography.X509Certificates.X509Certificate2Collection
    $inPfx.Import($env:H2A_PFX, $env:H2A_PW, [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
    $added = @($inPfx | ForEach-Object { $_.Thumbprint } | Where-Object { $had -notcontains $_ })
    Import-PfxCertificate -FilePath $env:H2A_PFX -CertStoreLocation $my `
      -Password (ConvertTo-SecureString $env:H2A_PW -AsPlainText -Force) | Out-Null
  }
  & $env:H2A_SIGNTOOL sign /fd SHA256 /s My /sha1 $env:H2A_THUMB $env:H2A_FILE
  $code = $LASTEXITCODE
} finally {
  foreach ($t in $added) { Remove-Item -LiteralPath "$my\$t" -DeleteKey -ErrorAction SilentlyContinue }
}
exit $code
''';

/// Builds a signed .msix installer for a project: the .exe from
/// [ExeBuilder], tile images and an AppxManifest, packed with makeappx and
/// signed with signtool (ADR 0008).
class MsixBuilder {
  MsixBuilder(this.exeBuilder, this.tools);

  final ExeBuilder exeBuilder;
  final WindowsSdkTools tools;

  Future<BuildResult> build(ProjectHandle project,
      {required String outputPath, required BuildLogSink log, required MsixSigning signing}) async {
    final sw = Stopwatch()..start();
    final m = project.manifest;
    BuildResult fail(String message) {
      log('Error: $message');
      return BuildResult(BuildStatus.failed, message: message, duration: sw.elapsed);
    }

    final version = msixVersion(m.android.versionName);
    if (version == null) {
      return fail('Version "${m.android.versionName}" cannot be an installer version: use up to three numbers '
          'from 0 to 65535, like 1.2.3');
    }
    log('Engine: Windows installer (MSIX, version $version)');
    log('Publisher: ${signing.subject}');

    final stage = Directory.systemTemp.createTempSync('ilovehtml_msix_');
    // signtool recognises packages by their extension.
    final tmp = '${p.withoutExtension(outputPath)}.part.msix';
    try {
      final exeName = '${msixFileName(m.name)}.exe';
      final exe = await exeBuilder.build(project,
          outputPath: p.join(stage.path, 'App', exeName),
          // The .exe inside is covered by the package signature.
          log: (line) {
            if (!line.startsWith('Output:') && !line.startsWith('Not code-signed')) log(line);
          });
      if (exe.status != BuildStatus.succeeded) return fail(exe.message ?? 'Building the .exe failed');

      final icon = project.iconFile == null ? null : File(project.iconFile!).readAsBytesSync();
      Directory(p.join(stage.path, 'Assets')).createSync();
      for (final (file, size) in _logos) {
        File(p.join(stage.path, 'Assets', file)).writeAsBytesSync(await logoPng(icon, size, m.name));
      }
      File(p.join(stage.path, 'AppxManifest.xml'))
          .writeAsStringSync(appxManifest(m, publisher: signing.subject, version: version, exeName: exeName));

      Directory(p.dirname(outputPath)).createSync(recursive: true);
      final pack = await Process.run(tools.makeAppx, ['pack', '/o', '/h', 'SHA256', '/d', stage.path, '/p', tmp]);
      if (pack.exitCode != 0) return fail('makeappx failed:\n${_tail(pack)}');
      log('Packed ${p.basename(outputPath)}');

      final run = signInvocation(tmp, signing);
      final sign = await Process.run(run.executable, run.arguments,
          environment: run.environment, stdoutEncoding: utf8, stderrEncoding: utf8);
      if (sign.exitCode != 0) return fail('signtool failed:\n${_tail(sign).replaceAll(signing.password, '***')}');
      log('Signed with ${signing.subject}');

      if (File(outputPath).existsSync()) File(outputPath).deleteSync();
      File(tmp).renameSync(outputPath);
      log('Output: $outputPath (${File(outputPath).lengthSync()} bytes)');
      return BuildResult(BuildStatus.succeeded, artifactPath: outputPath, duration: sw.elapsed);
    } on Object catch (e) {
      return fail('$e');
    } finally {
      if (File(tmp).existsSync()) File(tmp).deleteSync();
      stage.deleteSync(recursive: true);
    }
  }

  /// The process that signs [file]. Secrets travel only in the environment.
  @visibleForTesting
  ({String executable, List<String> arguments, Map<String, String> environment}) signInvocation(
          String file, MsixSigning signing) =>
      (
        executable: 'powershell.exe',
        arguments: ['-NoProfile', '-NonInteractive', '-Command', _signScript],
        environment: {
          'H2A_SIGNTOOL': tools.signTool,
          'H2A_PFX': signing.pfxPath,
          'H2A_PW': signing.password,
          'H2A_THUMB': signing.thumbprint,
          'H2A_FILE': file,
        },
      );

  static const _logos = [('StoreLogo.png', 50), ('Square44x44Logo.png', 44), ('Square150x150Logo.png', 150)];

  static String _tail(ProcessResult r) {
    final lines = '${r.stdout}\n${r.stderr}'.split('\n').map((l) => l.trimRight()).where((l) => l.isNotEmpty).toList();
    return lines.skip(lines.length > 8 ? lines.length - 8 : 0).join('\n');
  }

  /// `1.2.3` → `1.2.3.0`; null unless every part is a number up to 65535.
  /// The fourth part stays 0, as the Microsoft Store requires.
  static String? msixVersion(String versionName) {
    final parts = versionName.trim().split('.');
    if (parts.length > 3 || parts.any((s) => !RegExp(r'^\d{1,5}$').hasMatch(s))) return null;
    final nums = parts.map(int.parse).toList();
    if (nums.any((n) => n > 65535)) return null;
    while (nums.length < 4) {
      nums.add(0);
    }
    return nums.join('.');
  }

  /// Package identity name from an application ID: letters, digits, `.`
  /// and `-`, 3–50 characters.
  static String msixIdentityName(String applicationId) {
    final name = applicationId.replaceAll(RegExp(r'[^A-Za-z0-9.-]'), '-');
    final cut = name.length > 50 ? name.substring(0, 50) : name;
    return cut.length < 3 ? '$cut-app' : cut;
  }

  /// A file name for the app's .exe inside the package.
  static String msixFileName(String appName) {
    final s = appName.replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), '').trim().replaceAll(RegExp(r'^\.+|\.+$'), '');
    return s.isEmpty ? 'App' : (s.length > 64 ? s.substring(0, 64).trim() : s);
  }

  /// The CN of a certificate subject, for the publisher's display name.
  static String commonName(String subject) =>
      RegExp(r'(?:^|,\s*)CN=("(?:[^"]|"")*"|[^,]*)').firstMatch(subject)?.group(1)?.replaceAll('"', '').trim() ??
      subject;

  static String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  static String appxManifest(ProjectManifest m,
      {required String publisher, required String version, required String exeName}) {
    final name = _xml(m.name);
    return '''
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  IgnorableNamespaces="uap rescap">
  <Identity Name="${msixIdentityName(m.android.applicationId)}" Publisher="${_xml(publisher)}" Version="$version" ProcessorArchitecture="x64"/>
  <Properties>
    <DisplayName>$name</DisplayName>
    <PublisherDisplayName>${_xml(commonName(publisher))}</PublisherDisplayName>
    <Logo>Assets\\StoreLogo.png</Logo>
  </Properties>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.26100.0"/>
  </Dependencies>
  <Resources>
    <Resource Language="en-us"/>
  </Resources>
  <Applications>
    <Application Id="App" Executable="App\\${_xml(exeName)}" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="$name" Description="$name" BackgroundColor="transparent"
        Square150x150Logo="Assets\\Square150x150Logo.png" Square44x44Logo="Assets\\Square44x44Logo.png"/>
    </Application>
  </Applications>
  <Capabilities>
    <Capability Name="internetClient"/>
    <rescap:Capability Name="runFullTrust"/>
  </Capabilities>
</Package>
''';
  }

  /// [icon] resized to [size], or the app's first letter on a dark tile.
  static Future<Uint8List> logoPng(Uint8List? icon, int size, String appName) async {
    if (icon != null) {
      try {
        final codec = await ui.instantiateImageCodec(icon, targetWidth: size, targetHeight: size);
        final frame = await codec.getNextFrame();
        final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        frame.image.dispose();
        codec.dispose();
        return data!.buffer.asUint8List();
      } on Object {
        // Fall through to the letter tile.
      }
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final s = size.toDouble();
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, s, s), ui.Paint()..color = const ui.Color(0xFF1F1D1B));
    final letter = appName.trim().isEmpty ? '?' : String.fromCharCode(appName.trim().runes.first).toUpperCase();
    final para = (ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center, fontSize: s * 0.55))
          ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFF2EFEA)))
          ..addText(letter))
        .build()
      ..layout(ui.ParagraphConstraints(width: s));
    canvas.drawParagraph(para, ui.Offset(0, (s - para.height) / 2));
    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }
}

/// The certificate iLoveHTML signs installers with, as shown in the UI.
class MsixCertificate {
  const MsixCertificate(
      {required this.subject, required this.thumbprint, required this.notAfter, required this.origin});

  factory MsixCertificate.fromMap(Map<String, Object?> m) => MsixCertificate(
        subject: m['subject']! as String,
        thumbprint: m['thumbprint']! as String,
        notAfter: DateTime.parse(m['notAfter']! as String),
        origin: m['origin']! as String,
      );

  final String subject;
  final String thumbprint;
  final DateTime notAfter;

  /// `created` (a test certificate made here) or `imported` (the user's own).
  final String origin;

  bool get isTest => origin == 'created';
  String get publisherName => MsixBuilder.commonName(subject);
}
