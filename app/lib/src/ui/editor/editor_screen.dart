import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html2apk_core/html2apk_core.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';

import '../../app_controller.dart';
import '../brutal.dart';
import '../browser_preview.dart';
import '../l10n.dart';
import '../preview_screen.dart';
import '../theme.dart';
import 'code_pane.dart';
import 'mini_preview.dart';

/// An open file: its editor state and the text last saved to disk.
class _OpenFile {
  _OpenFile(this.path, String text) : saved = text, code = CodeLineEditingController.fromText(text) {
    find = CodeFindController(code);
  }

  String path;
  String saved;
  final CodeLineEditingController code;
  late final CodeFindController find;

  bool get dirty => code.text != saved;

  void dispose() {
    find.dispose();
    code.dispose();
  }
}

/// Edits the HTML, CSS and JavaScript of a local project, with a live preview.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.controller, required this.projectId});

  final AppController controller;
  final String projectId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _open = <_OpenFile>[];
  final _dirty = <String>{};
  final _reloads = ValueNotifier(0);
  List<String> _files = const [];
  int _current = -1;
  bool _preview = false;
  String? _previewPage;

  ProjectHandle get _project => widget.controller.project(widget.projectId)!;
  ProjectStore get _store => widget.controller.store;
  _OpenFile? get _file => _current < 0 ? null : _open[_current];

  @override
  void initState() {
    super.initState();
    _refreshFiles();
    final start = _project.manifest.source.entry;
    if (_files.contains(start)) _openFile(start);
  }

  @override
  void dispose() {
    for (final f in _open) {
      f.dispose();
    }
    _reloads.dispose();
    super.dispose();
  }

  void _refreshFiles() => _files = _store.listSourceFiles(_project);

  void _report(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is SourceFileException ? e.message : '$e')));
  }

  void _openFile(String path) {
    final i = _open.indexWhere((f) => f.path == path);
    if (i >= 0) {
      setState(() => _current = i);
      return;
    }
    try {
      final file = _OpenFile(path, _store.readSourceFile(_project, path));
      file.code.addListener(() {
        // Rebuild only when the file flips between saved and unsaved.
        if (file.dirty != _dirty.contains(file.path)) {
          setState(() => file.dirty ? _dirty.add(file.path) : _dirty.remove(file.path));
        }
      });
      setState(() {
        _open.add(file);
        _current = _open.length - 1;
      });
    } on SourceFileException catch (e) {
      _report(e);
    }
  }

  /// Saves [file] (the current one by default); true when it is on disk.
  bool _save([_OpenFile? file]) {
    final f = file ?? _file;
    if (f == null || !f.dirty) return true;
    try {
      final text = f.code.text;
      _store.writeSourceFile(_project, f.path, text);
      setState(() {
        f.saved = text;
        _dirty.remove(f.path);
      });
      _reloads.value++;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.fileSaved(f.path)), duration: const Duration(seconds: 1)));
      return true;
    } on SourceFileException catch (e) {
      _report(e);
      return false;
    }
  }

  Future<bool> _confirmDiscard(String what) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.l10n.unsavedChangesQ),
          content: Text(context.l10n.discardChangesBody(what)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.discard)),
          ],
        ),
      ) ==
      true;

  Future<void> _close(int i) async {
    final f = _open[i];
    if (f.dirty && !await _confirmDiscard(f.path)) return;
    setState(() {
      _open.removeAt(i);
      _dirty.remove(f.path);
      if (_current >= _open.length) _current = _open.length - 1;
      if (_current > i) _current--;
    });
    f.dispose();
  }

  Future<String?> _askPath(String title, {String initial = ''}) {
    final text = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: text,
          autofocus: true,
          autocorrect: false,
          style: monoStyle(c, size: 14),
          decoration: InputDecoration(labelText: context.l10n.fileName, hintText: 'about.html, css/extra.css'),
          onSubmitted: (v) => Navigator.pop(c, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, text.text.trim()), child: Text(context.l10n.ok)),
        ],
      ),
    ).whenComplete(text.dispose);
  }

  Future<void> _newFile() async {
    final path = await _askPath(context.l10n.newFile);
    if (path == null || path.isEmpty) return;
    try {
      _store.createSourceFile(_project, path);
      final rel = normalizeRelativePath(path);
      setState(_refreshFiles);
      widget.controller.refresh();
      _openFile(rel);
      _closeDrawer();
    } on Object catch (e) {
      _report(e);
    }
  }

  Future<void> _rename(String path) async {
    final i = _open.indexWhere((f) => f.path == path);
    if (i >= 0 && _open[i].dirty && !_save(_open[i])) return;
    final to = await _askPath(context.l10n.rename, initial: path);
    if (to == null || to.isEmpty || to == path) return;
    try {
      _store.renameSourceFile(_project, path, to);
      final rel = normalizeRelativePath(to);
      setState(() {
        _refreshFiles();
        if (i >= 0) _open[i].path = rel;
      });
      widget.controller.refresh();
    } on Object catch (e) {
      _report(e);
    }
  }

  Future<void> _delete(String path) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.deleteFileQ),
        content: Text(context.l10n.deleteFileBody(path)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      _store.deleteSourceFile(_project, path);
      final i = _open.indexWhere((f) => f.path == path);
      setState(() {
        _refreshFiles();
        if (i >= 0) {
          _open.removeAt(i).dispose();
          _dirty.remove(path);
          if (_current >= _open.length) _current = _open.length - 1;
        }
      });
      widget.controller.refresh();
      _reloads.value++;
    } on SourceFileException catch (e) {
      _report(e);
    }
  }

  void _closeDrawer() {
    if (_scaffold.currentState?.isEndDrawerOpen ?? false) Navigator.pop(context);
  }

  Future<void> _showPreview() async {
    if (_dirty.isNotEmpty) {
      for (final f in [..._open]) {
        if (f.dirty && !_save(f)) return;
      }
    }
    if (Platform.isAndroid) {
      final current = _file?.path;
      setState(() {
        _previewPage = current != null && RegExp(r'\.html?$').hasMatch(current) ? current : null;
        _preview = true;
      });
    } else {
      await openBrowserPreview(context, _project);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final fileList = _FileList(
      files: _files,
      current: _file?.path,
      dirty: _dirty,
      startPage: _project.manifest.source.entry,
      onOpen: (f) {
        _openFile(f);
        _closeDrawer();
      },
      onNew: _newFile,
      onRename: _rename,
      onDelete: _delete,
    );
    return PopScope(
      canPop: _dirty.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(_dirty.join(', ')) && context.mounted) {
          _dirty.clear();
          Navigator.pop(context);
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        },
        child: Scaffold(
          key: _scaffold,
          appBar: AppBar(
            title: Text(_project.manifest.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: l.find,
                onPressed: _file == null ? null : () => _file!.find.findMode(),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: l.save,
                onPressed: _file?.dirty ?? false ? _save : null,
                icon: const Icon(Icons.save_outlined),
              ),
              if (!wide)
                IconButton(
                  tooltip: l.files,
                  onPressed: () => _scaffold.currentState?.openEndDrawer(),
                  icon: const Icon(Icons.folder_open),
                ),
            ],
          ),
          endDrawer: wide ? null : Drawer(child: SafeArea(child: fileList)),
          floatingActionButton: _preview
              ? null
              : FloatingActionButton.extended(
                  onPressed: _showPreview,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.preview),
                ),
          body: Stack(
            children: [
              Row(
                children: [
                  if (wide) ...[
                    SizedBox(width: 260, child: fileList),
                    Container(width: Eleven.stroke, color: context.eleven.ink),
                  ],
                  Expanded(child: _editorColumn(context)),
                ],
              ),
              if (_preview)
                Positioned.fill(
                  child: MiniPreview(
                    key: ValueKey(_previewPage),
                    project: _project,
                    page: _previewPage,
                    reloads: _reloads,
                    onClose: () => setState(() => _preview = false),
                    onExpand: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PreviewScreen(project: _project))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editorColumn(BuildContext context) {
    final e = context.eleven;
    final file = _file;
    return Column(
      children: [
        if (_open.isNotEmpty)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: e.bg,
              border: Border(bottom: e.strokeSide),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              children: [
                for (final (i, f) in _open.indexed)
                  _Tab(
                    label: p.basename(f.path),
                    tooltip: f.path,
                    selected: i == _current,
                    dirty: f.dirty,
                    onTap: () => setState(() => _current = i),
                    onClose: () => _close(i),
                  ),
              ],
            ),
          ),
        Expanded(
          child: file == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.l10n.noFileOpen, textAlign: TextAlign.center),
                  ),
                )
              : CodePane(key: ObjectKey(file), path: file.path, controller: file.code, findController: file.find),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.dirty,
    required this.onTap,
    required this.onClose,
  });

  final String label, tooltip;
  final bool selected, dirty;
  final VoidCallback onTap, onClose;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final fg = selected ? e.onBlock : e.fg;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          selected: selected,
          label: dirty ? '$label, ${context.l10n.unsaved}' : label,
          child: Material(
            color: selected ? e.block : e.panel,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: e.ink, width: 2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Eleven.radius)),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: monoStyle(context, size: 13).copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                    if (dirty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                      ),
                    ],
                    IconButton(
                      tooltip: context.l10n.close,
                      onPressed: onClose,
                      icon: Icon(Icons.close, size: 16, color: fg),
                      style: IconButton.styleFrom(minimumSize: const Size(32, 32)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.files,
    required this.current,
    required this.dirty,
    required this.startPage,
    required this.onOpen,
    required this.onNew,
    required this.onRename,
    required this.onDelete,
  });

  final List<String> files;
  final String? current;
  final Set<String> dirty;
  final String startPage;
  final ValueChanged<String> onOpen;
  final VoidCallback onNew;
  final ValueChanged<String> onRename, onDelete;

  static IconData _icon(String f) => switch (p.extension(f).toLowerCase()) {
    '.html' || '.htm' => Icons.html,
    '.css' => Icons.css,
    '.js' || '.mjs' => Icons.javascript,
    '.json' || '.webmanifest' => Icons.data_object,
    '.svg' => Icons.image_outlined,
    _ => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = context.eleven;
    return Material(
      color: e.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l.files, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final f in files)
                  ListTile(
                    dense: true,
                    selected: f == current,
                    selectedTileColor: e.accSoft,
                    selectedColor: e.fg,
                    leading: Icon(_icon(f), size: 20),
                    title: Text(f, style: monoStyle(context, size: 12.5), overflow: TextOverflow.ellipsis),
                    subtitle: f == startPage ? Text(l.startPage) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dirty.contains(f)) Icon(Icons.circle, size: 8, color: e.fg),
                        PopupMenuButton<String>(
                          tooltip: l.moreOptions,
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (v) => v == 'rename' ? onRename(f) : onDelete(f),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'rename', child: Text(l.rename)),
                            PopupMenuItem(value: 'delete', child: Text(l.delete)),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => onOpen(f),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: BrutalButton(label: l.newFile, icon: Icons.add, expand: true, onPressed: onNew),
          ),
        ],
      ),
    );
  }
}
