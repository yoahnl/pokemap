import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_library_actions.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_tree_tiles.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';

part 'map_builder_map_tree_rows.dart';

const _unfiledFolder = '';

class MapBuilderMapTree extends StatefulWidget {
  const MapBuilderMapTree({
    super.key,
    required this.groups,
    required this.maps,
    required this.activeMapId,
    required this.onSelect,
    this.commands,
  });

  final List<ProjectMapGroup> groups;
  final List<ProjectMapEntry> maps;
  final String? activeMapId;
  final ValueChanged<ProjectMapEntry>? onSelect;
  final MapLibraryCommands? commands;

  @override
  State<MapBuilderMapTree> createState() => _MapBuilderMapTreeState();
}

class _MapBuilderMapTreeState extends State<MapBuilderMapTree> {
  final _search = TextEditingController();
  final _focus = FocusNode(debugLabel: 'map-library-tree');
  final _expanded = <String>{};
  String? _revealed;
  String? _selected;
  String? _renaming;
  String? _pendingRename;
  String? _notice;
  (String, Duration)? _lastDown;

  @override
  void didUpdateWidget(MapBuilderMapTree old) {
    super.didUpdateWidget(old);
    if (old.activeMapId != widget.activeMapId) _notice = null;
    final pending = _pendingRename;
    if (pending != null && widget.commands != null) {
      _pendingRename = null;
      _selected = pending;
      _renaming = pending;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  MapBuilderMapLibraryActions? get _actions {
    final commands = widget.commands;
    if (commands == null) return null;
    return MapBuilderMapLibraryActions(
      commands: commands,
      onOpen: widget.onSelect,
      onRename: _startRename,
      onFailure: (message) {
        if (mounted) setState(() => _notice = message);
      },
    );
  }

  String _folderKey(MapLibraryRow row) => row.folderId ?? _unfiledFolder;

  void _startRename(String key) {
    if (widget.commands == null) {
      _pendingRename = key;
      return;
    }
    setState(() {
      _selected = key;
      _renaming = key;
      _notice = null;
    });
  }

  void _pointerDown(String key) {
    final now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    final last = _lastDown;
    _lastDown = (key, now);
    if (_pendingRename != key) _pendingRename = null;
    _focus.requestFocus();
    if (_selected != key) setState(() => _selected = key);
    if (last != null && last.$1 == key && now - last.$2 < kDoubleTapTimeout) {
      _lastDown = null;
      if (key != 'folder:') _startRename(key);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final actions = _actions;
    if (event is! KeyDownEvent || _renaming != null || actions == null) {
      return KeyEventResult.ignored;
    }
    final key =
        _selected ??
        (widget.activeMapId == null ? null : 'map:${widget.activeMapId}');
    if (key == null || key == 'folder:') return KeyEventResult.ignored;
    final pressed = event.logicalKey;
    if (pressed == LogicalKeyboardKey.f2) {
      _startRename(key);
      return KeyEventResult.handled;
    }
    if (pressed != LogicalKeyboardKey.delete &&
        pressed != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    actions.deleteRow(context, key);
    return KeyEventResult.handled;
  }

  void _toggleFolder(String key, bool open) =>
      setState(() => open ? _expanded.remove(key) : _expanded.add(key));

  void _endRename() {
    setState(() => _renaming = null);
    _focus.requestFocus();
  }

  Future<void> _commitRename(String key, String name) async {
    final actions = _actions;
    _endRename();
    if (actions == null) return;
    await actions.rename(context, key, name);
  }

  void _revealActive(List<MapLibraryRow> rows) {
    final active = widget.activeMapId;
    if (active == null || active == _revealed) return;
    _revealed = active;
    _expanded.addAll(mapTreeFoldersAbove(rows, active, _folderKey));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = _actions;
    final query = _search.text.trim();
    final rows = MapLibraryTree(
      groups: widget.groups,
      maps: widget.maps,
      query: query,
    ).rows;
    _revealActive(rows);
    final visible = query.isNotEmpty
        ? rows
        : mapTreeVisibleRows(rows, _expanded, _folderKey);
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.commands?.busy == true)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StudioSpacing.l,
              StudioSpacing.l - 2,
              StudioSpacing.l,
              StudioSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: StudioSearchField(
                    key: const ValueKey('map-library-search'),
                    controller: _search,
                    label: l10n.mapSearch,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(width: StudioSpacing.s),
                  StudioContextMenuButton(
                    key: const ValueKey('map-library-add'),
                    tooltip: l10n.mapLibraryAdd,
                    icon: Icons.add,
                    items: () => actions.addItems(context),
                  ),
                ],
              ],
            ),
          ),
          if (_notice case final notice?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
              child: GestureDetector(
                onTap: () => setState(() => _notice = null),
                child: StudioNotice(
                  notice,
                  key: const ValueKey('map-library-notice'),
                  isError: true,
                ),
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(StudioSpacing.xl),
                    child: StudioEmptyState(
                      icon: Icons.map_outlined,
                      title: l10n.mapSearchEmpty,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(StudioSpacing.m),
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        _row(context, visible[index], query, actions),
                  ),
          ),
        ],
      ),
    );
  }
}
