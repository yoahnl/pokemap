import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import 'map_library_tree.dart';
import 'map_library_navigator_forms.dart';
import 'map_library_row_tile.dart';
import 'map_library_row_actions.dart';
import 'map_catalogue_form_dialog.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

part 'map_library_navigator_actions.dart';
part 'map_library_group_actions.dart';

typedef OrganizeMapLibrary =
    Future<String?> Function({
      List<ProjectMapGroup>? groups,
      required List<Map<String, Object?>> assignments,
    });

class MapLibraryNavigator extends StatefulWidget {
  const MapLibraryNavigator({
    super.key,
    required this.project,
    required this.activeMapId,
    required this.dirtyMapIds,
    required this.onActivate,
    required this.onOrganize,
    this.onCollapse,
    this.onCreateMap,
    this.onRenameMap,
    this.onLifecycleMap,
    this.onRetryCatalogue,
    this.width = 230,
  });

  final ProjectManifest project;
  final String? activeMapId;
  final Set<String> dirtyMapIds;
  final ValueChanged<ProjectMapEntry> onActivate;
  final OrganizeMapLibrary? onOrganize;
  final VoidCallback? onCollapse;
  final void Function(String? groupId)? onCreateMap;
  final ValueChanged<ProjectMapEntry>? onRenameMap;
  final void Function(ProjectMapEntry, MapLibraryAction)? onLifecycleMap;
  final VoidCallback? onRetryCatalogue;
  final double width;
  @override
  State<MapLibraryNavigator> createState() => _MapLibraryNavigatorState();
}

class _MapLibraryNavigatorState extends State<MapLibraryNavigator> {
  final _search = TextEditingController();
  final _collapsed = <String>{};
  final _selected = <String>{};
  var _creating = false,
      _selecting = false,
      _busy = false,
      _searchExpanded = false;
  var _name = '', _parent = '', _destination = '';
  String? _error;
  String? _folderSelection;
  String? _notice;
  final _createdMapIds = <String>{};
  void _update(VoidCallback action) => setState(action);

  @override
  void didUpdateWidget(MapLibraryNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.project.maps.map((map) => map.id).toSet();
    _selected.removeWhere((id) => !ids.contains(id));
    _createdMapIds.addAll(
      ids.difference(oldWidget.project.maps.map((map) => map.id).toSet()),
    );
    if (_createdMapIds.remove(widget.activeMapId)) {
      if (_search.text.isNotEmpty) {
        _search.clear();
        _notice = 'Recherche effacée pour afficher la nouvelle carte.';
      }
      final entry = widget.project.maps
          .where((map) => map.id == widget.activeMapId)
          .firstOrNull;
      if (entry != null) _revealFolder(entry.groupId ?? '');
    }
    if (_folderSelection != null &&
        !widget.project.groups.any((group) => group.id == _folderSelection)) {
      _folderSelection = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = MapLibraryTree(
      groups: widget.project.groups,
      maps: widget.project.maps,
      query: _search.text,
    );
    final rows = <MapLibraryRow>[];
    for (final row in tree.rows) {
      if (_search.text.isEmpty && row.depth > 0) {
        var folder = row.map?.groupId ?? row.group?.parentGroupId;
        var hidden = false;
        while (folder != null) {
          if (_collapsed.contains(folder)) {
            hidden = true;
            break;
          }
          folder = widget.project.groups
              .where((group) => group.id == folder)
              .firstOrNull
              ?.parentGroupId;
        }
        if (row.map != null && row.map!.groupId == null) {
          hidden = _collapsed.contains('__root__');
        }
        if (hidden) continue;
      }
      rows.add(row);
    }
    final folders = mapLibraryFolderLabels(widget.project.groups);
    return StudioSidebar(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cartes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StudioButton(
            key: const ValueKey('new-map'),
            label: 'Nouvelle carte',
            icon: Icons.add,
            onPressed: _busy || widget.onCreateMap == null
                ? null
                : () => widget.onCreateMap!(_folderSelection),
          ),
          Wrap(
            children: [
              StudioTool(
                label: 'Rechercher une carte',
                icon: _searchExpanded ? Icons.close : Icons.search,
                selected: _searchExpanded,
                onPressed: () {
                  setState(() => _searchExpanded = !_searchExpanded);
                  if (!_searchExpanded) _search.clear();
                },
              ),
              StudioTool(
                label: 'Nouveau dossier',
                icon: Icons.create_new_folder_outlined,
                onPressed: _busy || widget.onOrganize == null
                    ? null
                    : _createFolderDialog,
              ),
              StudioTool(
                label: 'Sélection multiple',
                icon: Icons.checklist,
                selected: _selecting,
                onPressed: _busy || widget.onOrganize == null
                    ? null
                    : () => setState(() {
                        _selecting = !_selecting;
                        if (!_selecting) _selected.clear();
                      }),
              ),
              if (widget.onCollapse != null)
                StudioTool(
                  label: 'Masquer les cartes',
                  icon: Icons.keyboard_double_arrow_left,
                  onPressed: widget.onCollapse,
                ),
            ],
          ),
          if (_searchExpanded) ...[
            const SizedBox(height: 8),
            StudioSearchField(
              controller: _search,
              label: 'Rechercher une carte',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_notice != null) Text(_notice!),
          if (widget.onRetryCatalogue != null)
            StudioButton(
              label: 'Relire le catalogue',
              secondary: true,
              onPressed: _busy ? null : widget.onRetryCatalogue,
            ),
          const SizedBox(height: 8),
          Expanded(
            child: rows.isEmpty && _search.text.trim().isNotEmpty
                ? MapLibrarySearchEmpty(onClear: () => setState(_search.clear))
                : ListView.builder(
                    key: const ValueKey('map-library-list'),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final map = row.map;
                      final folderId = row.group?.id ?? '__root__';
                      return MapLibraryRowTile(
                        row: row,
                        collapsed: _collapsed.contains(folderId),
                        selected: map == null
                            ? false
                            : _selecting
                            ? _selected.contains(map.id)
                            : widget.activeMapId == map.id,
                        selecting: _selecting,
                        dirty:
                            map != null && widget.dirtyMapIds.contains(map.id),
                        actions: map != null
                            ? const [
                                MapLibraryAction.rename,
                                MapLibraryAction.move,
                                MapLibraryAction.duplicate,
                                MapLibraryAction.resize,
                                MapLibraryAction.deleteMap,
                              ]
                            : row.group == null
                            ? const []
                            : const [
                                MapLibraryAction.createMap,
                                MapLibraryAction.rename,
                                MapLibraryAction.move,
                                MapLibraryAction.up,
                                MapLibraryAction.down,
                                MapLibraryAction.deleteFolder,
                              ],
                        disabledReasons: row.group == null
                            ? _mapDisabled()
                            : _groupDisabled(row.group!),
                        onAction: _busy
                            ? null
                            : (action) => _rowAction(row, action),
                        onToggleFolder: () => setState(() {
                          _folderSelection = row.group?.id;
                          if (!_collapsed.add(folderId)) {
                            _collapsed.remove(folderId);
                          }
                        }),
                        onMap: (entry) {
                          if (_selecting) {
                            setState(() {
                              if (!_selected.add(entry.id)) {
                                _selected.remove(entry.id);
                              }
                            });
                          } else {
                            widget.onActivate(entry);
                          }
                        },
                      );
                    },
                  ),
          ),
          if (_selecting && _selected.isNotEmpty) ...[
            const SizedBox(height: 8),
            MapFolderMoveForm(
              count: _selected.length,
              destination: _destination,
              folders: folders,
              busy: _busy,
              onDestination: (value) => setState(() => _destination = value),
              onMove: _moveSelected,
            ),
          ],
        ],
      ),
    );
  }
}
