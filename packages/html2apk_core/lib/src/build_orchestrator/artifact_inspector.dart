import 'package:archive/archive.dart';

import 'build_adapter.dart';

class ArtifactReport {
  ArtifactReport(this.entries, this.problems);

  final Set<String> entries;
  final List<String> problems;
}

/// Structural check of an APK or AAB. APKs keep AndroidManifest.xml (binary)
/// and dex at the root; AABs keep them under `base/`.
ArtifactReport inspectArtifact(String path, ArtifactFormat format) {
  final problems = <String>[];
  final input = InputFileStream(path);
  final Set<String> names;
  try {
    names = ZipDecoder().decodeStream(input).files.map((f) => f.name).toSet();
  } on FormatException catch (e) {
    return ArtifactReport({}, ['not a ZIP container: ${e.message}']);
  } finally {
    input.closeSync();
  }
  final required = format == ArtifactFormat.apk
      ? ['AndroidManifest.xml', 'classes.dex', 'resources.arsc', 'assets/app_config.json']
      : ['BundleConfig.pb', 'base/manifest/AndroidManifest.xml', 'base/dex/classes.dex', 'base/assets/app_config.json'];
  for (final r in required) {
    if (!names.contains(r)) problems.add('missing $r');
  }
  return ArtifactReport(names, problems);
}
