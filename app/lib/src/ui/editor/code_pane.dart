import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/re_highlight.dart';

import '../l10n.dart';
import '../theme.dart';

/// The highlight grammar for a file, by extension; null for plain text.
(String, Mode)? languageFor(String path) => switch (p.extension(path).toLowerCase()) {
  '.html' || '.htm' || '.svg' => ('xml', langXml),
  '.css' => ('css', langCss),
  '.js' || '.mjs' => ('javascript', langJavascript),
  '.json' || '.webmanifest' => ('json', langJson),
  '.md' => ('markdown', langMarkdown),
  _ => null,
};

/// Syntax colours in the app's style: ink-dark tokens on the cream page,
/// light ones on the dark page.
Map<String, TextStyle> _codeColours(ElevenPalette e, bool dark) {
  Color c(int light, int darkC) => Color(dark ? darkC : light);
  TextStyle s(Color col, {bool bold = false, bool italic = false}) =>
      TextStyle(color: col, fontWeight: bold ? FontWeight.w700 : null, fontStyle: italic ? FontStyle.italic : null);
  final tag = s(c(0xFF5B3FE0, 0xFFB4A5FF), bold: true);
  final attr = s(c(0xFF00727A, 0xFF5EE6EC));
  final string = s(c(0xFFC2185B, 0xFFFF8FB0));
  final keyword = s(c(0xFF000000, 0xFFFFD60A), bold: true);
  final number = s(c(0xFF1C7A29, 0xFF7BE287));
  final comment = s(e.mute, italic: true);
  return {
    'root': TextStyle(color: e.fg, backgroundColor: e.panel),
    'tag': tag,
    'name': tag,
    'selector-tag': tag,
    'title': tag,
    'attr': attr,
    'attribute': attr,
    'property': attr,
    'selector-class': attr,
    'selector-id': attr,
    'selector-attr': attr,
    'selector-pseudo': attr,
    'string': string,
    'symbol': string,
    'regexp': string,
    'keyword': keyword,
    'built_in': keyword,
    'literal': keyword,
    'meta': keyword,
    'number': number,
    'variable': number,
    'comment': comment,
    'doctag': comment,
    'section': s(e.fg, bold: true),
    'strong': s(e.fg, bold: true),
    'emphasis': s(e.fg, italic: true),
  };
}

/// A code editor for one file, styled to match the app.
class CodePane extends StatelessWidget {
  const CodePane({
    super.key,
    required this.path,
    required this.controller,
    required this.findController,
    this.focusNode,
  });

  final String path;
  final CodeLineEditingController controller;
  final CodeFindController findController;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lang = languageFor(path);
    return CodeEditor(
      controller: controller,
      findController: findController,
      focusNode: focusNode,
      wordWrap: false,
      // Don't pop up the phone keyboard until the user taps into the code.
      autofocus: false,
      style: CodeEditorStyle(
        fontFamily: Eleven.mono,
        fontFamilyFallback: Eleven.fallback,
        fontSize: 13.5,
        textColor: e.fg,
        backgroundColor: e.panel,
        cursorColor: e.fg,
        cursorLineColor: e.accSoft,
        selectionColor: e.block.withAlpha(0x66),
        highlightColor: e.block.withAlpha(0x55),
        chunkIndicatorColor: e.mute,
        codeTheme: lang == null
            ? null
            : CodeHighlightTheme(
                languages: {lang.$1: CodeHighlightThemeMode(mode: lang.$2)},
                theme: _codeColours(e, dark),
              ),
      ),
      indicatorBuilder: (context, editing, chunk, notifier) => Row(
        children: [
          DefaultCodeLineNumber(
            controller: editing,
            notifier: notifier,
            textStyle: monoStyle(context, size: 12).copyWith(color: e.mute),
            focusedTextStyle: monoStyle(context, size: 12).copyWith(color: e.fg, fontWeight: FontWeight.w700),
          ),
          DefaultCodeChunkIndicator(width: 18, controller: chunk, notifier: notifier),
        ],
      ),
      leadingDivider: Container(width: 2, color: e.ink),
      findBuilder: (context, controller, readOnly) => _FindBar(controller: controller),
      toolbarController: const _EditMenu(),
    );
  }
}

/// Find (and replace) bar shown above the code.
class _FindBar extends StatelessWidget implements PreferredSizeWidget {
  const _FindBar({required this.controller});

  final CodeFindController controller;

  @override
  Size get preferredSize => Size.fromHeight(controller.value == null ? 0 : (controller.value!.replaceMode ? 112 : 60));

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (value == null) return const SizedBox.shrink();
    final l = context.l10n;
    final e = context.eleven;
    final result = value.result;
    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: e.bg,
        border: Border(bottom: e.strokeSide),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.findInputController,
                  focusNode: controller.findInputFocusNode,
                  style: monoStyle(context, size: 13),
                  decoration: deco(l.find),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                result == null ? '0/0' : '${result.index + 1}/${result.matches.length}',
                style: monoStyle(context, size: 12),
              ),
              IconButton(
                tooltip: l.findPrevious,
                onPressed: result == null ? null : controller.previousMatch,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: l.findNext,
                onPressed: result == null ? null : controller.nextMatch,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: l.replace,
                onPressed: value.replaceMode ? controller.findMode : controller.replaceMode,
                icon: Icon(value.replaceMode ? Icons.unfold_less : Icons.find_replace),
              ),
              IconButton(tooltip: l.close, onPressed: controller.close, icon: const Icon(Icons.close)),
            ],
          ),
          if (value.replaceMode) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.replaceInputController,
                    focusNode: controller.replaceInputFocusNode,
                    style: monoStyle(context, size: 13),
                    decoration: deco(l.replaceWith),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: result == null ? null : controller.replaceMatch, child: Text(l.replace)),
                TextButton(onPressed: result == null ? null : controller.replaceAllMatches, child: Text(l.replaceAll)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Cut / copy / paste menu for touch selection.
class _EditMenu implements SelectionToolbarController {
  const _EditMenu();

  @override
  void hide(BuildContext context) {}

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) {
    final l = MaterialLocalizations.of(context);
    showMenu<void>(
      context: context,
      position: RelativeRect.fromSize(
        anchors.primaryAnchor & const Size(160, double.infinity),
        MediaQuery.sizeOf(context),
      ),
      items: [
        PopupMenuItem(onTap: controller.cut, child: Text(l.cutButtonLabel)),
        PopupMenuItem(onTap: controller.copy, child: Text(l.copyButtonLabel)),
        PopupMenuItem(onTap: controller.paste, child: Text(l.pasteButtonLabel)),
        PopupMenuItem(onTap: controller.selectAll, child: Text(l.selectAllButtonLabel)),
      ],
    );
  }
}
