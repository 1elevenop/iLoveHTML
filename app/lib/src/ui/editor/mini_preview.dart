import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../l10n.dart';
import '../theme.dart';

/// A small floating preview of a local site, drawn over the editor. It can
/// be dragged by its title bar and resized from its corner, and it reloads
/// whenever [reloads] changes (after each save).
///
/// The site is served by the same loopback-only, token-protected
/// [PreviewServer] and WebView settings as [PreviewScreen].
class MiniPreview extends StatefulWidget {
  const MiniPreview({
    super.key,
    required this.project,
    required this.reloads,
    required this.onClose,
    required this.onExpand,
    this.page,
  });

  final ProjectHandle project;
  final ValueListenable<int> reloads;
  final VoidCallback onClose;
  final VoidCallback onExpand;

  /// The page to show; the start page when null.
  final String? page;

  @override
  State<MiniPreview> createState() => _MiniPreviewState();
}

class _MiniPreviewState extends State<MiniPreview> {
  static const _minSize = Size(180, 220);
  PreviewServer? _server;
  WebViewController? _web;
  String? _error;
  Offset? _offset;
  Size _size = const Size(240, 380);

  @override
  void initState() {
    super.initState();
    widget.reloads.addListener(_reload);
    _start();
  }

  Future<void> _start() async {
    try {
      final server = await PreviewServer.start(widget.project.sourceDir);
      if (!mounted) {
        await server.stop();
        return;
      }
      _server = server;
      final start = server.urlFor(widget.page ?? widget.project.manifest.source.entry);
      final web = WebViewController()
        ..setJavaScriptMode(
          widget.project.manifest.webView.javaScriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (req) {
              final uri = Uri.tryParse(req.url);
              final internal =
                  uri != null && uri.scheme == start.scheme && uri.host == start.host && uri.port == start.port;
              return internal ? NavigationDecision.navigate : NavigationDecision.prevent;
            },
          ),
        );
      // Same hardening as the full preview: the site is untrusted.
      final platform = web.platform;
      if (platform is AndroidWebViewController) {
        await platform.setAllowFileAccess(false);
        await platform.setAllowContentAccess(false);
      }
      await web.loadRequest(start);
      if (mounted) setState(() => _web = web);
    } on Object catch (e) {
      if (mounted) setState(() => _error = context.l10n.couldNotStartPreview('$e'));
    }
  }

  void _reload() => _web?.reload();

  @override
  void dispose() {
    widget.reloads.removeListener(_reload);
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final maxW = box.maxWidth - 16, maxH = box.maxHeight - 16;
        final size = Size(_size.width.clamp(_minSize.width, maxW), _size.height.clamp(_minSize.height, maxH));
        final offset = _offset ?? Offset(box.maxWidth - size.width - 16, box.maxHeight - size.height - 88);
        final pos = Offset(
          offset.dx.clamp(8, box.maxWidth - size.width - 8),
          offset.dy.clamp(8, box.maxHeight - size.height - 8),
        );
        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              width: size.width,
              height: size.height,
              child: Container(
                decoration: BoxDecoration(
                  color: e.panel,
                  borderRadius: BorderRadius.circular(Eleven.radius),
                  border: Border.all(color: e.ink, width: Eleven.stroke),
                  boxShadow: e.shadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    GestureDetector(
                      onPanUpdate: (d) => setState(() => _offset = pos + d.delta),
                      child: Container(
                        height: 40,
                        color: e.block,
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Icon(Icons.drag_indicator, size: 18, color: e.onBlock),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l.preview,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: e.onBlock),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _HeaderButton(icon: Icons.refresh, tooltip: l.reload, color: e.onBlock, onPressed: _reload),
                            _HeaderButton(
                              icon: Icons.open_in_full,
                              tooltip: l.fullPreview,
                              color: e.onBlock,
                              onPressed: widget.onExpand,
                            ),
                            _HeaderButton(
                              icon: Icons.close,
                              tooltip: l.close,
                              color: e.onBlock,
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 2, color: e.ink),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _error != null
                                ? Center(
                                    child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
                                  )
                                : _web == null
                                ? const Center(child: CircularProgressIndicator())
                                : WebViewWidget(controller: _web!),
                          ),
                          // Resize handle in the bottom-right corner.
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Semantics(
                              label: l.resize,
                              child: GestureDetector(
                                onPanUpdate: (d) =>
                                    setState(() => _size = Size(size.width + d.delta.dx, size.height + d.delta.dy)),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: e.block,
                                    border: Border(top: e.strokeSide, left: e.strokeSide),
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
                                  ),
                                  child: Icon(Icons.south_east, size: 16, color: e.onBlock),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.tooltip, required this.color, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 18, color: color),
    style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
  );
}
