import 'dart:async';

import 'package:flutter/material.dart' hide Orientation;
import 'package:html2apk_core/html2apk_core.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'l10n.dart';
import 'theme.dart';

/// Viewport sizes in logical pixels; the preview is scaled to fit the screen.
enum Viewport {
  device('This device', null),
  phone('Phone 412', 412),
  tablet('Tablet 800', 800),
  desktop('Desktop 1280', 1280);

  const Viewport(this.label, this.width);

  final String label;
  final double? width;

  String labelFor(BuildContext context) => this == device ? context.l10n.thisDevice : label;
}

class _Entry {
  _Entry(this.kind, this.text);

  final String kind; // log, warn, error, missing, blocked, http
  final String text;
}

/// Previews a project with the same navigation rules as the generated app:
/// pages on the project's own site load in place; links elsewhere would open
/// in the browser, so the preview blocks and reports them instead.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.project});

  final ProjectHandle project;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  WebViewController? _web;
  PreviewServer? _server;
  StreamSubscription<String>? _missingSub;
  String? _startError;
  String _currentUrl = '';
  int _progress = 0;
  bool _canBack = false;
  bool _canForward = false;
  Viewport _viewport = Viewport.device;
  final List<_Entry> _entries = [];

  ProjectManifest get _m => widget.project.manifest;
  bool get _local => _m.source.type == SourceType.local;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final l = context.l10n;
    try {
      final Uri start;
      if (_local) {
        final server = await PreviewServer.start(widget.project.sourceDir);
        _server = server;
        _missingSub = server.onMissing.listen((path) => _add('missing', l.fileNotFound(path)));
        start = server.urlFor(_m.source.entry);
      } else {
        start = Uri.parse(_m.source.entry);
      }
      final web = WebViewController()
        ..setJavaScriptMode(_m.webView.javaScriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
        ..setOnConsoleMessage((msg) => _add(switch (msg.level) {
              JavaScriptLogLevel.error => 'error',
              JavaScriptLogLevel.warning => 'warn',
              _ => 'log',
            }, msg.message))
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            if (uri != null && _isInternal(uri, start)) return NavigationDecision.navigate;
            _add('blocked', context.l10n.wouldOpenOutside(req.url));
            return NavigationDecision.prevent;
          },
          onProgress: (p) => setState(() => _progress = p),
          onUrlChange: (c) => _onUrl(c.url),
          onPageFinished: _onUrl,
          onHttpError: (e) => _add('http', 'HTTP ${e.response?.statusCode}: ${e.request?.uri ?? ''}'),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) _add('error', context.l10n.pageFailedToLoad(e.description, e.url ?? ''));
          },
        ));
      // The previewed site is untrusted and runs inside iLoveHTML, whose private
      // files include release keystores. WebView allows file:// access by
      // default on Android 10 and older, so turn it (and content://) off.
      final platform = web.platform;
      if (platform is AndroidWebViewController) {
        await platform.setAllowFileAccess(false);
        await platform.setAllowContentAccess(false);
      }
      await web.loadRequest(start);
      if (mounted) setState(() => _web = web);
    } on Object catch (e) {
      if (mounted) setState(() => _startError = context.l10n.couldNotStartPreview('$e'));
    }
  }

  bool _isInternal(Uri uri, Uri start) {
    if (_local) return uri.scheme == start.scheme && uri.host == start.host && uri.port == start.port;
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    final startHost = start.host.toLowerCase();
    return host == startHost || host == 'www.$startHost' || 'www.$host' == startHost || _m.webView.allowedHosts.contains(host);
  }

  Future<void> _onUrl(String? url) async {
    final web = _web;
    if (!mounted) return;
    final back = await web?.canGoBack() ?? false;
    final forward = await web?.canGoForward() ?? false;
    if (!mounted) return;
    setState(() {
      if (url != null) _currentUrl = _displayUrl(url);
      _canBack = back;
      _canForward = forward;
    });
  }

  /// Shows project-relative paths for local previews instead of the loopback address.
  String _displayUrl(String url) {
    final base = _server?.baseUri.toString();
    return base != null && url.startsWith(base) ? '/${url.substring(base.length)}' : url;
  }

  void _add(String kind, String text) {
    if (!mounted) return;
    setState(() => _entries.add(_Entry(kind, text)));
  }

  @override
  void dispose() {
    _missingSub?.cancel();
    _server?.stop();
    super.dispose();
  }

  int get _problemCount => _entries.where((e) => e.kind != 'log').length;

  void _showConsole() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (c, scroll) => _entries.isEmpty
            ? Center(child: Text(context.l10n.noConsoleMessages))
            : ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (c, i) {
                  final e = _entries[i];
                  final scheme = Theme.of(c).colorScheme;
                  final (icon, color) = switch (e.kind) {
                    'error' || 'http' => (Icons.error_outline, scheme.error),
                    'missing' => (Icons.broken_image_outlined, scheme.error),
                    'warn' => (Icons.warning_amber, scheme.tertiary),
                    'blocked' => (Icons.open_in_new, scheme.secondary),
                    _ => (Icons.chevron_right, scheme.onSurfaceVariant),
                  };
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: color, size: 20),
                    title: SelectableText(e.text, style: monoStyle(c, size: 12)),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final web = _web;
    final problems = _problemCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.previewTitle(_m.name), overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<Viewport>(
            tooltip: context.l10n.viewport,
            icon: const Icon(Icons.aspect_ratio),
            initialValue: _viewport,
            onSelected: (v) => setState(() => _viewport = v),
            itemBuilder: (_) => [for (final v in Viewport.values) PopupMenuItem(value: v, child: Text(v.labelFor(context)))],
          ),
          IconButton(
            tooltip: context.l10n.consoleAndIssues,
            onPressed: _showConsole,
            icon: Badge(
              isLabelVisible: _entries.isNotEmpty,
              label: Text('${problems > 0 ? problems : _entries.length}'),
              // Red only for real problems; plain console output gets a neutral badge.
              backgroundColor: problems > 0
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.secondaryContainer,
              textColor: problems > 0 ? null : Theme.of(context).colorScheme.onSecondaryContainer,
              child: const Icon(Icons.terminal),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(children: [
            IconButton(onPressed: _canBack ? () => web?.goBack() : null, icon: const Icon(Icons.arrow_back)),
            IconButton(onPressed: _canForward ? () => web?.goForward() : null, icon: const Icon(Icons.arrow_forward)),
            IconButton(onPressed: web == null ? null : () => web.reload(), icon: const Icon(Icons.refresh)),
            Expanded(
              child: Text(_currentUrl, style: monoStyle(context, size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
          ]),
        ),
      ),
      body: Column(children: [
        if (_progress > 0 && _progress < 100) LinearProgressIndicator(value: _progress / 100, minHeight: 2),
        Expanded(
          child: _startError != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_startError!)))
              : web == null
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(builder: (context, box) {
                      final w = _viewport.width;
                      final view = WebViewWidget(controller: web);
                      if (w == null || w <= box.maxWidth) {
                        return Center(child: SizedBox(width: w ?? box.maxWidth, child: view));
                      }
                      // Lay out at the chosen width, then scale down to fit the screen.
                      final scale = box.maxWidth / w;
                      return FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: SizedBox(width: w, height: box.maxHeight / scale, child: view),
                      );
                    }),
        ),
      ]),
    );
  }
}
