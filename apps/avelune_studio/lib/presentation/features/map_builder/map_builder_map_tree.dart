import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';

const _unfiledFolder = '';

class MapBuilderMapTree extends StatefulWidget {
  const MapBuilderMapTree({
    super.key,
    required this.groups,
    required this.maps,
    required this.activeMapId,
    required this.onSelect,
  });

  final List<ProjectMapGroup> groups;
  final List<ProjectMapEntry> maps;
  final String? activeMapId;
  final ValueChanged<ProjectMapEntry>? onSelect;

  @override
  State<MapBuilderMapTree> createState() => _MapBuilderMapTreeState();
}

class _MapBuilderMapTreeState extends State<MapBuilderMapTree> {
  final _search = TextEditingController();
  final _expanded = <String>{};
  String? _revealed;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _folderKey(MapLibraryRow row) => row.folderId ?? _unfiledFolder;

  void _revealActive(List<MapLibraryRow> rows) {
    final active = widget.activeMapId;
    if (active == null || active == _revealed) return;
    _revealed = active;
    final index = rows.indexWhere((row) => row.map?.id == active);
    if (index < 0) return;
    var depth = rows[index].depth;
    for (var i = index - 1; i >= 0 && depth > 0; i--) {
      if (rows[i].isFolder && rows[i].depth < depth) {
        _expanded.add(_folderKey(rows[i]));
        depth = rows[i].depth;
      }
    }
  }

  List<MapLibraryRow> _visible(List<MapLibraryRow> rows, bool searching) {
    if (searching) return rows;
    final visible = <MapLibraryRow>[];
    int? hiddenBelow;
    for (final row in rows) {
      if (hiddenBelow != null && row.depth > hiddenBelow) continue;
      hiddenBelow = null;
      visible.add(row);
      if (row.isFolder && !_expanded.contains(_folderKey(row))) {
        hiddenBelow = row.depth;
      }
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final rows = MapLibraryTree(
      groups: widget.groups,
      maps: widget.maps,
      query: query,
    ).rows;
    _revealActive(rows);
    final visible = _visible(rows, query.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.l,
            StudioSpacing.l,
            StudioSpacing.l,
            StudioSpacing.s,
          ),
          child: StudioSearchField(
            key: const ValueKey('map-library-search'),
            controller: _search,
            label: context.l10n.mapSearch,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(StudioSpacing.xl),
                  child: StudioEmptyState(
                    icon: Icons.map_outlined,
                    title: context.l10n.mapSearchEmpty,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(StudioSpacing.m),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final row = visible[index];
                    final map = row.map;
                    if (map == null) {
                      final key = _folderKey(row);
                      final open = query.isNotEmpty || _expanded.contains(key);
                      return _FolderTile(
                        row: row,
                        open: open,
                        onTap: query.isNotEmpty
                            ? null
                            : () => setState(
                                () => open
                                    ? _expanded.remove(key)
                                    : _expanded.add(key),
                              ),
                      );
                    }
                    return _MapTile(
                      row: row,
                      map: map,
                      active: map.id == widget.activeMapId,
                      onSelect: widget.onSelect,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.row, required this.open, this.onTap});

  final MapLibraryRow row;
  final bool open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      key: ValueKey('map-library-folder-${row.folderId ?? 'unfiled'}'),
      dense: true,
      contentPadding: EdgeInsets.only(
        left: StudioSpacing.s + row.depth * StudioSpacing.xl,
        right: StudioSpacing.m,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      ),
      leading: Icon(
        open ? Icons.folder_open_outlined : Icons.folder_outlined,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(
        row.label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        '${row.count}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MapTile extends StatelessWidget {
  const _MapTile({
    required this.row,
    required this.map,
    required this.active,
    required this.onSelect,
  });

  final MapLibraryRow row;
  final ProjectMapEntry map;
  final bool active;
  final ValueChanged<ProjectMapEntry>? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSelect = this.onSelect;
    return ListTile(
      key: ValueKey('map-library-map-${map.id}'),
      dense: true,
      selected: active,
      selectedTileColor: scheme.primaryContainer,
      selectedColor: scheme.onPrimaryContainer,
      contentPadding: EdgeInsets.only(
        left: StudioSpacing.s + row.depth * StudioSpacing.xl,
        right: StudioSpacing.m,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      ),
      leading: const Icon(Icons.map_outlined, size: 18),
      title: Text(map.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(context.l10n.mapRole(map.role)),
      onTap: onSelect == null || active ? null : () => onSelect(map),
    );
  }
}
