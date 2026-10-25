import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_element_catalog.dart';
import 'map_workspace_view_state.dart';

class MapElementsPanel extends StatefulWidget {
  const MapElementsPanel({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
    this.onReorder,
    this.onInspect,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback? onInspect;
  final Future<bool> Function(
    String kind,
    List<String> frontFirstIds,
    String? layerId,
  )?
  onReorder;

  @override
  State<MapElementsPanel> createState() => _MapElementsPanelState();
}

class _MapElementsPanelState extends State<MapElementsPanel> {
  final _search = TextEditingController();
  final _collapsed = <String>{};
  MapData? _map;
  ProjectManifest? _project;
  late MapElementResourceIndex _resources;
  late MapElementCatalog _catalog;
  bool _stacking = false;
  bool _ordering = false;
  int? _dragStart;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    final view = widget.view;
    final target = view.target;
    if (target != null) {
      final entry = _catalog.entries
          .where(
            (entry) =>
                entry.id == target.id &&
                switch (entry.kind) {
                  'decor' ||
                  'model' => target.family == MapSelectionFamily.decor,
                  'entity' =>
                    target.family ==
                        (entry.isCharacter
                            ? MapSelectionFamily.character
                            : MapSelectionFamily.marker),
                  'warp' => target.family == MapSelectionFamily.warp,
                  'zone' => target.family == MapSelectionFamily.zone,
                  'trigger' => target.family == MapSelectionFamily.trigger,
                  _ => false,
                },
          )
          .firstOrNull;
      if (entry != null &&
          (widget.document.isElementLocked(entry.kind, entry.id) ||
              widget.document.isElementHidden(entry.kind, entry.id))) {
        view.clearSelection(widget.document);
      }
    }
    widget.onChanged();
    if (mounted) setState(() {});
  }

  Future<void> _lock(Iterable<MapElementListEntry> entries, bool locked) async {
    try {
      final editor = widget.document.editor;
      if (editor == null || !editor.canWrite) return;
      if (!locked &&
          entries.any(
            (entry) =>
                widget.document.isElementLocked(entry.kind, entry.id) &&
                !editor.current.isLocked(entry.kind, entry.id),
          )) {
        widget.document.error = 'Des éléments sont verrouillés par leur calque. Déverrouillez ce calque dans Calques.';
        _changed();
        return;
      }
      final save = editor.setGroupLocked(
        entries.map((entry) => (entry.kind, entry.id)),
        locked,
      );
      _changed();
      await save;
      if (mounted) setState(() {});
    } on Object catch (error) {
      widget.document.error = '$error';
      _changed();
    }
  }

  Future<void> _hide(Iterable<MapElementListEntry> entries, bool hidden) async {
    try {
      final editor = widget.document.editor;
      if (editor == null || !editor.canWrite) return;
      if (!hidden &&
          entries.any(
            (entry) =>
                widget.document.isElementHiddenInherited(entry.kind, entry.id),
          )) {
        widget.document.error = 'Des éléments sont masqués par leur calque ou leur famille. Réaffichez le calque ou utilisez Tout afficher.';
        _changed();
        return;
      }
      final save = editor.setGroupHidden(
        entries.map((entry) => (entry.kind, entry.id)),
        hidden,
      );
      _changed();
      await save;
      if (mounted) setState(() {});
    } on Object catch (error) {
      widget.document.error = '$error';
      _changed();
    }
  }

  void _select(MapElementListEntry entry) {
    if (widget.document.isElementLocked(entry.kind, entry.id) ||
        widget.document.isElementHidden(entry.kind, entry.id)) {
      return;
    }
    final family = switch (entry.kind) {
      'decor' || 'model' => MapSelectionFamily.decor,
      'entity' =>
        entry.isCharacter
            ? MapSelectionFamily.character
            : MapSelectionFamily.marker,
      'warp' => MapSelectionFamily.warp,
      'zone' => MapSelectionFamily.zone,
      'trigger' => MapSelectionFamily.trigger,
      _ => null,
    };
    if (family == null) return;
    widget.view.tool = StudioMapTool.select;
    widget.view.select(widget.document, family, entry.id);
    _changed();
  }

  Widget _entry(MapElementListEntry entry, {int? index}) {
    final locked = widget.document.isElementLocked(entry.kind, entry.id);
    final hidden = widget.document.isElementHidden(entry.kind, entry.id);
    final hiddenInherited = widget.document.isElementHiddenInherited(
      entry.kind,
      entry.id,
    );
    final inherited =
        locked &&
        !widget.document.editorState.lockedElements.contains(entry.key);
    final target = widget.view.target;
    final selected =
        target != null &&
        target.id == entry.id &&
        switch (entry.kind) {
          'decor' || 'model' => target.family == MapSelectionFamily.decor,
          'entity' =>
            target.family ==
                (entry.isCharacter
                    ? MapSelectionFamily.character
                    : MapSelectionFamily.marker),
          'warp' => target.family == MapSelectionFamily.warp,
          'zone' => target.family == MapSelectionFamily.zone,
          'trigger' => target.family == MapSelectionFamily.trigger,
          _ => false,
        };
    return StudioChoice(
      key: ValueKey('map-element-${entry.kind}-${entry.id}'),
      label: entry.label,
      subtitle: hidden ? '${entry.detail} · Masqué' : entry.detail,
      selected: selected,
      onTap: locked || hidden || entry.kind == 'layer'
          ? null
          : () => _select(entry),
      leading: index == null
          ? Icon(switch (entry.kind) {
              'layer' => Icons.layers_outlined,
              'model' => Icons.view_in_ar_outlined,
              'entity' =>
                entry.isCharacter ? Icons.person_outline : Icons.place_outlined,
              'warp' => Icons.door_front_door_outlined,
              'zone' || 'trigger' => Icons.crop_free,
              _ => Icons.park_outlined,
            }, size: 20)
          : ReorderableDragStartListener(
              index: index,
              enabled:
                  !locked &&
                  !_ordering &&
                  widget.document.editor?.canWrite == true,
              child: const Tooltip(
                message: 'Glisser vers le haut pour passer devant',
                child: Icon(Icons.drag_indicator, size: 20),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected && widget.onInspect != null)
            StudioTool(
              label: 'Propriétés',
              icon: Icons.tune,
              onPressed: widget.onInspect,
            ),
          StudioTool(
            key: ValueKey('map-element-hide-${entry.kind}-${entry.id}'),
            label: hiddenInherited
                ? 'Masqué par son calque ou sa famille. Réaffichez le calque ou utilisez Tout afficher.'
                : hidden
                ? 'Afficher ${entry.label}'
                : 'Masquer ${entry.label}',
            icon: hidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            selected: hidden,
            onPressed:
                widget.document.editor?.canWrite != true || hiddenInherited
                ? null
                : () => unawaited(_hide([entry], !hidden)),
          ),
          StudioTool(
            key: ValueKey('map-element-lock-${entry.kind}-${entry.id}'),
            label: inherited
                ? 'Verrouillé par son calque ou sa famille. Déverrouillez le calque ou utilisez Tout déverrouiller.'
                : locked
                ? 'Déverrouiller ${entry.label}'
                : 'Verrouiller ${entry.label}',
            icon: locked ? Icons.lock_outline : Icons.lock_open_outlined,
            selected: locked,
            onPressed: widget.document.editor?.canWrite != true || inherited
                ? null
                : () => unawaited(_lock([entry], !locked)),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(String name, List<MapElementListEntry> entries) {
    final editor = widget.document.editor;
    final locked = entries.every(
      (entry) => widget.document.isElementLocked(entry.kind, entry.id),
    );
    final inheritedOnly =
        locked &&
        entries.every(
          (entry) =>
              !widget.document.editorState.lockedElements.contains(entry.key),
        );
    final hidden = entries.every(
      (entry) => widget.document.isElementHidden(entry.kind, entry.id),
    );
    final hiddenInherited =
        hidden &&
        entries.any(
          (entry) =>
              widget.document.isElementHiddenInherited(entry.kind, entry.id),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: StudioButton(
              label: '$name (${entries.length})',
              icon: _collapsed.contains(name)
                  ? Icons.chevron_right
                  : Icons.expand_more,
              secondary: true,
              onPressed: () => setState(() {
                if (!_collapsed.add(name)) _collapsed.remove(name);
              }),
            ),
          ),
          StudioTool(
            key: ValueKey('map-family-hide-$name'),
            label: hiddenInherited
                ? 'Ce groupe est masqué par son calque ou sa famille. Réaffichez le calque ou utilisez Tout afficher.'
                : hidden
                ? 'Afficher $name'
                : 'Masquer $name',
            icon: hidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            selected: hidden,
            onPressed: editor?.canWrite != true || hiddenInherited
                ? null
                : () => unawaited(_hide(entries, !hidden)),
          ),
          StudioTool(
            label: inheritedOnly
                ? 'Ce groupe est verrouillé par son calque ou sa famille. Déverrouillez le calque ou utilisez Tout déverrouiller.'
                : 'Verrouiller ou déverrouiller $name',
            icon: locked ? Icons.lock_outline : Icons.lock_open_outlined,
            onPressed: editor?.canWrite != true || inheritedOnly
                ? null
                : () => unawaited(_lock(entries, !locked)),
          ),
        ],
      ),
    );
  }

  Future<void> _reorder(
    List<MapElementListEntry> entries,
    int from,
    int to,
  ) async {
    if (widget.onReorder == null ||
        widget.document.editor?.canWrite != true ||
        _ordering ||
        _search.text.isNotEmpty) {
      return;
    }
    final source = entries[from];
    if (widget.document.isElementLocked(source.kind, source.id)) return;
    if (to == from) return;
    final reordered = entries.toList();
    reordered.insert(to, reordered.removeAt(from));
    setState(() => _ordering = true);
    try {
      await widget.onReorder!(
        source.kind == 'layer' ? 'layers' : 'decor',
        reordered.map((entry) => entry.id).toList(),
        source.layerId,
      );
      _changed();
    } finally {
      if (mounted) setState(() => _ordering = false);
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioSearchField(
                  key: const ValueKey('map-elements-search'),
                  controller: _search,
                  label: 'Rechercher un élément',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StudioButton(
                      label: 'Par famille',
                      icon: Icons.folder_outlined,
                      secondary: _stacking,
                      onPressed: () => setState(() => _stacking = false),
                    ),
                    StudioButton(
                      label: 'Superposition',
                      icon: Icons.layers_outlined,
                      secondary: !_stacking,
                      onPressed: () => setState(() => _stacking = true),
                    ),
                  ],
                ),
                if (editor != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          editor.saving
                              ? 'Enregistrement de l’affichage et des cadenas…'
                              : editor.dirty
                              ? 'Affichage et cadenas non enregistrés'
                              : 'Affichage et cadenas enregistrés',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      StudioTool(
                        label: 'Annuler l’affichage ou le verrouillage',
                        icon: Icons.undo,
                        onPressed: editor.canWrite && editor.canUndo
                            ? () {
                                unawaited(editor.undo());
                                _changed();
                              }
                            : null,
                      ),
                      StudioTool(
                        label: 'Rétablir l’affichage ou le verrouillage',
                        icon: Icons.redo,
                        onPressed: editor.canWrite && editor.canRedo
                            ? () {
                                unawaited(editor.redo());
                                _changed();
                              }
                            : null,
                      ),
                    ],
                  ),
                if (editor != null &&
                    (editor.current.hiddenElements.isNotEmpty ||
                        editor.current.hiddenFamilies.isNotEmpty))
                  StudioButton(
                    key: const ValueKey('map-elements-show-all'),
                    label: 'Tout afficher',
                    icon: Icons.visibility_outlined,
                    secondary: true,
                    onPressed: editor.canWrite
                        ? () {
                            unawaited(editor.showAll());
                            _changed();
                          }
                        : null,
                  ),
                if (editor != null &&
                    (editor.current.lockedElements.isNotEmpty ||
                        editor.current.lockedFamilies.isNotEmpty))
                  StudioButton(
                    label: 'Tout déverrouiller',
                    icon: Icons.lock_open_outlined,
                    secondary: true,
                    onPressed: editor.canWrite
                        ? () {
                            unawaited(editor.unlockAll());
                            _changed();
                          }
                        : null,
                  ),
                if (_stacking)
                  const Text(
                    'En haut = devant. Glissez la poignée pour changer l’ordre.',
                  ),
                if (_stacking && widget.document.current.spatialScene != null)
                  const StudioNotice(
                    'Les volumes 3D gardent leur profondeur. La liste réordonne les calques superposables.',
                  ),
                if (_stacking && widget.document.dirty)
                  const StudioNotice(
                    'Enregistrez les modifications de la carte avant de réordonner ses éléments.',
                  ),
                if (editor == null)
                  const StudioNotice(
                    'La visibilité et le verrouillage persistants sont indisponibles dans cette session.',
                  ),
                if (editor != null && !editor.canWrite)
                  const StudioNotice(
                    'Ce projet est en lecture seule. Créez une copie de travail pour modifier son affichage et ses cadenas.',
                  ),
                if (editor?.error != null) ...[
                  StudioNotice(editor!.error!, isError: true),
                  StudioButton(
                    label: 'Réessayer l’enregistrement',
                    icon: Icons.refresh,
                    onPressed: editor.canWrite
                        ? () => unawaited(editor.save())
                        : null,
                  ),
                ],
                if (widget.document.error != null)
                  StudioNotice(widget.document.error!, isError: true),
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
                  if (query.isEmpty ||
                      group.value.any(
                        (entry) =>
                            '${entry.label} ${entry.id} ${entry.family} ${entry.detail}'
                                .toLowerCase()
                                .contains(query),
                      )) ...[
                    SliverToBoxAdapter(
                      child: _groupHeader(group.key, group.value),
                    ),
                    if (!_collapsed.contains(group.key))
                      if (_stacking &&
                          query.isEmpty &&
                          widget.onReorder != null &&
                          editor?.canWrite == true &&
                          !widget.document.dirty &&
                          !_ordering)
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
                          itemCount: group.value
                              .where(
                                (entry) =>
                                    query.isEmpty ||
                                    '${entry.label} ${entry.id} ${entry.family} ${entry.detail}'
                                        .toLowerCase()
                                        .contains(query),
                              )
                              .length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _entry(
                              group.value
                                  .where(
                                    (entry) =>
                                        query.isEmpty ||
                                        '${entry.label} ${entry.id} ${entry.family} ${entry.detail}'
                                            .toLowerCase()
                                            .contains(query),
                                  )
                                  .elementAt(index),
                            ),
                          ),
                        ),
                  ],
                if (_catalog.entries.isEmpty)
                  const SliverToBoxAdapter(
                    child: StudioNotice(
                      'Cette carte ne contient aucun élément.',
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return editor == null
        ? content()
        : ListenableBuilder(
            listenable: editor,
            builder: (context, _) => content(),
          );
  }
}
