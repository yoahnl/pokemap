import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import 'map_library_tree.dart';
import 'map_library_navigator_forms.dart';
import 'map_library_row_tile.dart';

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
    this.width = 230,
  });

  final ProjectManifest project;
  final String? activeMapId;
  final Set<String> dirtyMapIds;
  final ValueChanged<ProjectMapEntry> onActivate;
  final OrganizeMapLibrary? onOrganize;
  final double width;

  @override
  State<MapLibraryNavigator> createState() => _MapLibraryNavigatorState();
}

class _MapLibraryNavigatorState extends State<MapLibraryNavigator> {
  final _search = TextEditingController();
  final _collapsed = <String>{};
  final _selected = <String>{};
  var _creating = false;
  var _selecting = false;
  var _busy = false;
  var _name = '';
  var _parent = '';
  var _destination = '';
  String? _error;

  @override
  void didUpdateWidget(MapLibraryNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.project.maps.map((map) => map.id).toSet();
    _selected.removeWhere((id) => !ids.contains(id));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final name = _name.trim();
    final parentId = _parent.isEmpty ? null : _parent;
    if (name.isEmpty) {
      setState(() => _error = 'Donnez un nom au dossier.');
      return;
    }
    if (widget.project.groups.any(
      (group) =>
          group.parentGroupId == parentId &&
          group.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = 'Un dossier du même nom existe déjà ici.');
      return;
    }
    final id = 'studio_folder_${DateTime.now().microsecondsSinceEpoch}';
    await _organize(
      groups: [
        ...widget.project.groups,
        ProjectMapGroup(
          id: id,
          name: name,
          type: MapGroupType.special,
          parentGroupId: parentId,
          sortOrder: widget.project.groups.length,
        ),
      ],
      assignments: const [],
      onSuccess: () {
        _creating = false;
        _name = '';
        _parent = '';
      },
    );
  }

  Future<void> _moveSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    await _organize(
      assignments: [
        for (final id in ids)
          {'mapId': id, 'groupId': _destination.isEmpty ? null : _destination},
      ],
      onSuccess: () {
        _selected.clear();
        _selecting = false;
      },
    );
  }

  Future<void> _organize({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
    required VoidCallback onSuccess,
  }) async {
    final action = widget.onOrganize;
    if (_busy || action == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await action(groups: groups, assignments: assignments);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error == null) onSuccess();
    });
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
    final folders = {
      '': 'Sans dossier',
      for (final group in widget.project.groups) group.id: group.name,
    };
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
              StudioTool(
                label: 'Nouveau dossier',
                icon: Icons.create_new_folder_outlined,
                onPressed: _busy || widget.onOrganize == null
                    ? null
                    : () => setState(() => _creating = !_creating),
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
            ],
          ),
          const SizedBox(height: 8),
          StudioSearchField(
            controller: _search,
            label: 'Rechercher une carte',
            onChanged: (_) => setState(() {}),
          ),
          if (_creating) ...[
            const SizedBox(height: 8),
            MapFolderCreationForm(
              name: _name,
              parent: _parent,
              folders: folders,
              busy: _busy,
              onName: (value) => setState(() => _name = value),
              onParent: (value) => setState(() => _parent = value),
              onCancel: () => setState(() => _creating = false),
              onCreate: _createFolder,
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
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
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
                  dirty: map != null && widget.dirtyMapIds.contains(map.id),
                  onToggleFolder: () => setState(() {
                    if (!_collapsed.add(folderId)) _collapsed.remove(folderId);
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
