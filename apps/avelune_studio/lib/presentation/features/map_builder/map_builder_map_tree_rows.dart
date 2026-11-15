part of 'map_builder_map_tree.dart';

extension _MapBuilderMapTreeRows on _MapBuilderMapTreeState {
  Widget _row(
    BuildContext context,
    MapLibraryRow row,
    String query,
    MapBuilderMapLibraryActions? actions,
  ) {
    final l10n = context.l10n;
    final map = row.map;
    if (map == null) {
      final key = _folderKey(row);
      final rowKey = 'folder:$key';
      final open = query.isNotEmpty || _expanded.contains(key);
      final group = widget.groups
          .where((g) => g.id == row.folderId)
          .firstOrNull;
      final menu = actions == null || group == null
          ? null
          : () => actions.folderItems(context, group);
      return MapBuilderTreeRow(
        rowKey: rowKey,
        menu: menu,
        onPointerDown: _pointerDown,
        tile: MapBuilderFolderTile(
          row: row,
          open: open,
          selected: _selected == rowKey && group != null,
          onTap: query.isNotEmpty ? null : () => _toggleFolder(key, open),
          rename: _renaming == rowKey && group != null
              ? MapBuilderRenameField(
                  initial: group.name,
                  label: l10n.mapLibraryName,
                  onCommit: (name) => _commitRename(rowKey, name),
                  onCancel: _endRename,
                )
              : null,
          trailing: menu == null
              ? null
              : StudioContextMenuButton(
                  key: ValueKey('map-library-folder-menu-${group!.id}'),
                  tooltip: l10n.mapLibraryFolderActions(group.name),
                  items: menu,
                ),
        ),
      );
    }
    final rowKey = 'map:${map.id}';
    final active = map.id == widget.activeMapId;
    final onSelect = widget.onSelect;
    final menu = actions == null
        ? null
        : () => actions.mapItems(context, map, active: active);
    return MapBuilderTreeRow(
      rowKey: rowKey,
      menu: menu,
      onPointerDown: _pointerDown,
      tile: MapBuilderMapTile(
        row: row,
        mapId: map.id,
        title: map.name,
        subtitle: l10n.mapRole(map.role),
        active: active,
        onTap: onSelect == null || active ? null : () => onSelect(map),
        rename: _renaming == rowKey
            ? MapBuilderRenameField(
                initial: map.name,
                label: l10n.mapLibraryName,
                onCommit: (name) => _commitRename(rowKey, name),
                onCancel: _endRename,
              )
            : null,
        trailing: menu == null
            ? null
            : StudioContextMenuButton(
                key: ValueKey('map-library-map-menu-${map.id}'),
                tooltip: l10n.mapLibraryMapActions(map.name),
                items: menu,
              ),
      ),
    );
  }
}
