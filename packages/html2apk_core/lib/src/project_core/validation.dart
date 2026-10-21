import '../security/url_policy.dart';
import 'manifest.dart';

enum IssueSeverity { error, warning }

class ValidationIssue {
  const ValidationIssue(this.field, this.message, [this.severity = IssueSeverity.error]);

  final String field;
  final String message;
  final IssueSeverity severity;

  @override
  String toString() => '${severity.name}: $field: $message';
}

const _javaKeywords = {
  'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 'class', 'const', //
  'continue', 'default', 'do', 'double', 'else', 'enum', 'extends', 'final', 'finally', 'float',
  'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'int', 'interface', 'long', 'native',
  'new', 'package', 'private', 'protected', 'public', 'return', 'short', 'static', 'strictfp',
  'super', 'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 'try', 'void',
  'volatile', 'while', 'true', 'false', 'null',
};

final _segment = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');

/// Returns null when [id] is a valid Android application ID, otherwise the reason.
String? validateApplicationId(String id) {
  if (id.isEmpty) return 'Application ID is required';
  if (id.length > 150) return 'Application ID is too long (max 150 characters)';
  final parts = id.split('.');
  if (parts.length < 2) return 'Application ID needs at least two segments, e.g. com.example.app';
  for (final part in parts) {
    if (!_segment.hasMatch(part)) {
      return 'Segment "$part" must start with a letter and contain only letters, digits or _';
    }
    if (_javaKeywords.contains(part)) return 'Segment "$part" is a reserved Java keyword';
  }
  return null;
}

/// Highest versionCode accepted by Google Play.
const maxVersionCode = 2100000000;

List<ValidationIssue> validateManifest(ProjectManifest m) {
  final issues = <ValidationIssue>[];
  if (m.name.trim().isEmpty) issues.add(const ValidationIssue('name', 'App name is required'));
  if (m.name.length > 50) {
    issues.add(const ValidationIssue('name', 'App name longer than 50 characters may be truncated',
        IssueSeverity.warning));
  }
  final idError = validateApplicationId(m.android.applicationId);
  if (idError != null) issues.add(ValidationIssue('android.applicationId', idError));
  if (m.android.versionCode < 1 || m.android.versionCode > maxVersionCode) {
    issues.add(const ValidationIssue('android.versionCode', 'Must be between 1 and $maxVersionCode'));
  }
  final vn = m.android.versionName;
  if (vn.trim().isEmpty || vn.length > 100 || vn.contains(RegExp(r'[\x00-\x1f]'))) {
    issues.add(const ValidationIssue('android.versionName', 'Must be 1-100 printable characters'));
  }
  switch (m.source.type) {
    case SourceType.local:
      final e = m.source.entry;
      if (e.isEmpty || e.startsWith('/') || e.contains('\\') || e.split('/').contains('..')) {
        issues.add(const ValidationIssue('source.entry', 'Entry must be a relative path inside source/'));
      } else if (!RegExp(r'\.html?$', caseSensitive: false).hasMatch(e)) {
        issues.add(const ValidationIssue('source.entry', 'Entry should be an .html file', IssueSeverity.warning));
      }
    case SourceType.url:
      final urlError = validateRemoteUrl(m.source.entry);
      if (urlError != null) issues.add(ValidationIssue('source.entry', urlError));
  }
  for (final host in m.webView.allowedHosts) {
    if (!RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$').hasMatch(host)) {
      issues.add(ValidationIssue('webView.allowedHosts', 'Invalid host "$host"'));
    }
  }
  final ua = m.webView.userAgentSuffix;
  if (ua != null && (ua.length > 200 || ua.contains(RegExp(r'[\x00-\x1f]')))) {
    issues.add(const ValidationIssue('webView.userAgentSuffix', 'Must be at most 200 printable characters'));
  }
  return issues;
}
