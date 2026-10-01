import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_choice.dart';
import 'map_library_tree.dart';
import 'map_library_row_actions.dart';

class MapLibraryRowTile extends StatelessWidget {
  const MapLibraryRowTile({
    super.key,
    required this.row,
    required this.collapsed,
    required this.selected,
    required this.selecting,
    required this.dirty,
    required this.onToggleFolder,
    required this.onMap,
    this.actions = const [],
    this.disabledReasons = const {},
    this.onAction,
  });

  final MapLibraryRow row;
  final bool collapsed, selected, selecting, dirty;
  final VoidCallback onToggleFolder;
  final ValueChanged<ProjectMapEntry> onMap;
  final List<MapLibraryAction> actions;
  final Map<MapLibraryAction, String> disabledReasons;
  final ValueChanged<MapLibraryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final map = row.map;
    final choice = row.isFolder
        ? StudioChoice(
            label: row.label,
            subtitle: '${row.count}',
            dense: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 16,
                ),
                const Icon(Icons.folder_outlined, size: 17),
              ],
            ),
            onTap: onToggleFolder,
          )
        : StudioChoice(
            key: ValueKey('map-library-${map!.id}'),
            label: '${dirty ? '• ' : ''}${map.name}',
            dense: true,
            leading: Icon(
              selecting && selected ? Icons.check_box : Icons.map_outlined,
              size: 18,
            ),
            selected: selected,
            onTap: () => onMap(map),
          );
    return Padding(
      padding: EdgeInsets.only(left: row.depth * 14.0),
      child: actions.isEmpty
          ? choice
          : MapLibraryRowActions(
              id: map?.id ?? row.group!.id,
              targetName: row.label,
              folder: row.isFolder,
              actions: actions,
              disabledReasons: disabledReasons,
              onAction: onAction,
              child: choice,
            ),
    );
  }
}
