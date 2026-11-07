import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_choice.dart';
import 'map_library_tree.dart';
import 'map_library_row_actions.dart';

class MapLibraryRowTile extends StatefulWidget {
  const MapLibraryRowTile({
    super.key,
    required this.row,
    required this.collapsed,
    required this.selected,
    required this.selecting,
    required this.dirty,
    required this.onToggleFolder,
    required this.onMap,
    this.folderPath = '',
    this.actions = const [],
    this.disabledReasons = const {},
    this.onAction,
  });

  final MapLibraryRow row;
  final bool collapsed, selected, selecting, dirty;
  final VoidCallback onToggleFolder;
  final ValueChanged<ProjectMapEntry> onMap;
  final String folderPath;
  final List<MapLibraryAction> actions;
  final Map<MapLibraryAction, String> disabledReasons;
  final ValueChanged<MapLibraryAction>? onAction;

  @override
  State<MapLibraryRowTile> createState() => _MapLibraryRowTileState();
}

class _MapLibraryRowTileState extends State<MapLibraryRowTile> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final map = row.map;
    final Widget choice = row.isFolder
        ? StudioChoice(
            label: row.label,
            subtitle: '${row.count}',
            dense: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 16,
                ),
                const Icon(Icons.folder_outlined, size: 17),
              ],
            ),
            onTap: widget.onToggleFolder,
          )
        : Tooltip(
            message: '${map!.name}\n${widget.folderPath}',
            waitDuration: const Duration(milliseconds: 500),
            child: StudioChoice(
              key: ValueKey('map-library-${map.id}'),
              label: '${widget.dirty ? '• ' : ''}${map.name}',
              dense: true,
              leading: Icon(
                widget.selecting && widget.selected
                    ? Icons.check_box
                    : Icons.map_outlined,
                size: 18,
              ),
              selected: widget.selected,
              onTap: () => widget.onMap(map),
            ),
          );
    final showDetail =
        map != null && ((widget.selected && !widget.selecting) || _focused);
    final body = widget.actions.isEmpty
        ? choice
        : MapLibraryRowActions(
            id: map?.id ?? row.group!.id,
            targetName: row.label,
            folder: row.isFolder,
            actions: widget.actions,
            disabledReasons: widget.disabledReasons,
            onAction: widget.onAction,
            child: choice,
          );
    return Padding(
      padding: EdgeInsets.only(left: row.depth * 14.0),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) {
          if (map != null && value != _focused) {
            setState(() => _focused = value);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            if (showDetail)
              _MapLibraryRowDetail(
                key: ValueKey('map-library-detail-${map.id}'),
                name: map.name,
                folderPath: widget.folderPath,
              ),
          ],
        ),
      ),
    );
  }
}

class _MapLibraryRowDetail extends StatelessWidget {
  const _MapLibraryRowDetail({
    super.key,
    required this.name,
    required this.folderPath,
  });
  final String name, folderPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 2, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, maxLines: 3, style: theme.textTheme.bodySmall),
            Text(
              'Dossier : $folderPath',
              maxLines: 3,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
