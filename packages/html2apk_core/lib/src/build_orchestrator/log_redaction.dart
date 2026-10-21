final _patterns = <RegExp>[
  // -Pandroid.injected.signing.store.password=..., storePassword=..., keyPassword: ...
  RegExp(r'((?:password|passwd|pwd|secret|token)[\w.-]*\s*[=:]\s*)("[^"]*"|\S+)', caseSensitive: false),
  RegExp(r'(--(?:ks|key)-pass\s+(?:pass:)?)(\S+)', caseSensitive: false),
];

/// Removes likely credentials from a build log line before it is stored or shown.
String redactSecrets(String line) {
  var out = line;
  for (final re in _patterns) {
    out = out.replaceAllMapped(re, (m) => '${m.group(1)}****');
  }
  return out;
}
