import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_list_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_visibility_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

class NeutralMapElementsPanel extends StatefulWidget {
  const NeutralMapElementsPanel({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
    this.onReorder,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapEditingViewportSession view;
  final VoidCallback onChanged;
  final MapElementReorder? onReorder;

  @override
  State<NeutralMapElementsPanel> createState() =>
      _NeutralMapElementsPanelState();
}

class _NeutralMapElementsPanelState extends State<NeutralMapElementsPanel> {
  final _search = TextEditingController();
  final _collapsed = <String>{};
  final _ordering = MapElementReorderSession();
  var _filter = MapContentFilter.all;
  var _stacking = false;
  MapData? _map;
  ProjectManifest? _project;
  late MapElementResourceIndex _resources;
  late MapElementCatalog _catalog;
  int? _dragStart;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  MapElementVisibilityCommands get _visibility => MapElementVisibilityCommands(
    widget.document,
    widget.view,
    catalog: () => _catalog,
    changed: () {
      if (!mounted) return;
      widget.onChanged();
      setState(() {});
    },
  );

  MapElementSelectionCommands get _selection => MapElementSelectionCommands(
    widget.document,
    widget.view,
    centerOn: widget.view.centerOn,
  );

  void _changed() {
    _visibility.reconcileSelection();
    widget.onChanged();
    if (mounted) setState(() {});
  }

  void _select(MapElementListEntry entry) {
    final keys = HardwareKeyboard.instance;
    if (_selection.select(
      entry,
      additive: keys.isShiftPressed || keys.isMetaPressed,
    )) {
      _changed();
    }
  }

  bool _isSelected(MapElementListEntry entry) => _selection.isSelected(entry);

  bool _isHidden(MapElementListEntry entry) =>
      widget.document.isElementHidden(entry.kind, entry.id);

  bool _isLocked(MapElementListEntry entry) =>
      widget.document.isElementLocked(entry.kind, entry.id);

  Widget _entry(MapElementListEntry entry, {int? index}) {
    final editor = widget.document.editor;
    final locked = _isLocked(entry);
    final hidden = _isHidden(entry);
    final hiddenInherited = widget.document.isElementHiddenInherited(
      entry.kind,
      entry.id,
    );
    final inherited =
        locked &&
        !widget.document.editorState.lockedElements.contains(entry.key);
    return ListTile(
      key: ValueKey('map-element-${entry.kind}-${entry.id}'),
      dense: true,
      selected: _isSelected(entry),
      title: Text(entry.label),
      subtitle: Text(
        hidden ? '${entry.detail} · Masqué pendant l’édition' : entry.detail,
      ),
      onTap: locked || hidden || entry.kind == 'layer'
          ? null
          : () => _select(entry),
      leading: index == null
          ? const Icon(Icons.circle_outlined, size: 20)
          : ReorderableDragStartListener(
              index: index,
              enabled: !locked && !_ordering.busy && editor?.canWrite == true,
              child: const Icon(Icons.drag_indicator, size: 20),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('map-element-hide-${entry.kind}-${entry.id}'),
            tooltip: hidden ? 'Afficher' : 'Masquer',
            icon: Icon(
              hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: editor?.canWrite != true || hiddenInherited
                ? null
                : () => unawaited(
                    _visibility
                        .setHidden([entry], !hidden)
                        .then((_) => mounted ? setState(() {}) : null),
                  ),
          ),
          IconButton(
            key: ValueKey('map-element-lock-${entry.kind}-${entry.id}'),
            tooltip: locked ? 'Déverrouiller' : 'Verrouiller',
            icon: Icon(
              locked ? Icons.lock_outline : Icons.lock_open_outlined,
            ),
            onPressed: editor?.canWrite != true || inherited
                ? null
                : () => unawaited(
                    _visibility
                        .setLocked([entry], !locked)
                        .then((_) => mounted ? setState(() {}) : null),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(String name, List<MapElementListEntry> entries) {
    final editor = widget.document.editor;
    final locked = entries.every(_isLocked);
    final inheritedOnly =
        locked &&
        entries.every(
          (entry) =>
              !widget.document.editorState.lockedElements.contains(entry.key),
        );
    final hidden = entries.every(_isHidden);
    final hiddenInherited =
        hidden &&
        entries.any(
          (entry) =>
              widget.document.isElementHiddenInherited(entry.kind, entry.id),
        );
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => setState(() {
              if (!_collapsed.add(name)) _collapsed.remove(name);
            }),
            icon: Icon(
              _collapsed.contains(name)
                  ? Icons.chevron_right
                  : Icons.expand_more,
            ),
            label: Text('$name (${entries.length})'),
          ),
        ),
        IconButton(
          key: ValueKey('map-family-hide-$name'),
          tooltip: hidden ? 'Afficher $name' : 'Masquer $name',
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: editor?.canWrite != true || hiddenInherited
              ? null
              : () => unawaited(
                  _visibility
                      .setHidden(entries, !hidden)
                      .then((_) => mounted ? setState(() {}) : null),
                ),
        ),
        IconButton(
          tooltip: 'Verrouiller ou déverrouiller $name',
          icon: Icon(locked ? Icons.lock_outline : Icons.lock_open_outlined),
          onPressed: editor?.canWrite != true || inheritedOnly
              ? null
              : () => unawaited(
                  _visibility
                      .setLocked(entries, !locked)
                      .then((_) => mounted ? setState(() {}) : null),
                ),
        ),
      ],
    );
  }

  Future<void> _reorder(
    List<MapElementListEntry> entries,
    int from,
    int to,
  ) async {
    final pending = _ordering.reorder(
      document: widget.document,
      entries: entries,
      from: from,
      to: to,
      apply: widget.onReorder,
      filter: _filter,
      query: _search.text,
    );
    setState(() {});
    try {
      await pending;
      if (mounted) _changed();
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!identical(_map, widget.document.current) ||
        !identical(_project, widget.project)) {
      if (!identical(_project, widget.project)) {
        _resources = MapElementResourceIndex(widget.project);
      }
      _map = widget.document.current;
      _project = widget.project;
      _catalog = MapElementCatalog(_map!, _project!, resources: _resources);
    }
    final editor = widget.document.editor;
    Widget content() {
      final query = _search.text.trim().toLowerCase();
      final groups = _stacking ? _catalog.stacking : _catalog.families;
      final unfiltered = query.isEmpty && _filter == MapContentFilter.all;
      bool visible(MapElementListEntry entry) =>
          (query.isEmpty ||
              '${entry.label} ${entry.id} ${entry.family} ${entry.detail}'
                  .toLowerCase()
                  .contains(query)) &&
          mapContentMatches(
            entry,
            _filter,
            isHidden: _isHidden,
            isLocked: _isLocked,
            isSelected: _isSelected,
          );
      final counts = mapContentCounts(
        _catalog,
        isHidden: _isHidden,
        isLocked: _isLocked,
        isSelected: _isSelected,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('map-elements-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un élément',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final filter in MapContentFilter.values)
                      ChoiceChip(
                        key: ValueKey('map-content-filter-${filter.name}'),
                        label: Text('${filter.name} · ${counts[filter]}'),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ChoiceChip(
                      label: const Text('Par famille'),
                      selected: !_stacking,
                      onSelected: (_) => setState(() => _stacking = false),
                    ),
                    ChoiceChip(
                      label: const Text('Superposition'),
                      selected: _stacking,
                      onSelected: (_) => setState(() => _stacking = true),
                    ),
                  ],
                ),
                if (editor != null)
                  Text(
                    editor.saving
                        ? 'Enregistrement de l’affichage et des cadenas…'
                        : editor.dirty
                        ? 'Affichage et cadenas non enregistrés'
                        : 'Affichage et cadenas enregistrés',
                  ),
                if (editor != null &&
                    (editor.current.hiddenElements.isNotEmpty ||
                        editor.current.hiddenFamilies.isNotEmpty))
                  OutlinedButton(
                    key: const ValueKey('map-elements-show-all'),
                    onPressed: editor.canWrite
                        ? () {
                            unawaited(editor.showAll());
                            _changed();
                          }
                        : null,
                    child: const Text('Tout afficher'),
                  ),
                if (editor?.error != null) Text(editor!.error!),
                if (widget.document.error != null)
                  Text(widget.document.error!),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              key: ValueKey(
                'map-elements-${_stacking ? 'stacking' : 'families'}',
              ),
              slivers: [
                for (final group in groups.entries)
                  if (unfiltered || group.value.any(visible)) ...[
                    SliverToBoxAdapter(
                      child: _groupHeader(group.key, group.value),
                    ),
                    if (!_collapsed.contains(group.key))
                      if (_stacking &&
                          unfiltered &&
                          widget.onReorder != null &&
                          editor?.canWrite == true &&
                          !widget.document.dirty &&
                          !_ordering.busy)
                        SliverReorderableList(
                          itemCount: group.value.length,
                          onReorderStart: (index) => _dragStart = index,
                          onReorderEnd: (index) {
                            final from = _dragStart;
                            _dragStart = null;
                            if (from == null) return;
                            unawaited(
                              _reorder(
                                group.value,
                                from,
                                index > from ? index - 1 : index,
                              ),
                            );
                          },
                          onReorderItem: (from, to) {},
                          itemBuilder: (context, index) => Padding(
                            key: ValueKey(group.value[index].key),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _entry(group.value[index], index: index),
                          ),
                        )
                      else
                        SliverList.builder(
                          itemCount: group.value.where(visible).length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _entry(
                              group.value.where(visible).elementAt(index),
                            ),
                          ),
                        ),
                  ],
              ],
            ),
          ),
        ],
      );
    }

    return Material(
      child: editor == null
          ? content()
          : ListenableBuilder(
              listenable: editor,
              builder: (context, _) => content(),
            ),
    );
  }
}
