import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import 'map_library_tree.dart';

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
  });

  final MapLibraryRow row;
  final bool collapsed, selected, selecting, dirty;
  final VoidCallback onToggleFolder;
  final ValueChanged<ProjectMapEntry> onMap;

  @override
  Widget build(BuildContext context) {
    final map = row.map;
    return Padding(
      padding: EdgeInsets.only(left: row.depth * 10.0),
      child: row.isFolder
          ? Row(
              children: [
                StudioTool(
                  label: collapsed
                      ? 'Déplier ${row.label}'
                      : 'Replier ${row.label}',
                  icon: collapsed ? Icons.chevron_right : Icons.expand_more,
                  onPressed: onToggleFolder,
                ),
                Expanded(
                  child: StudioChoice(
                    label: row.label,
                    subtitle: '${row.count}',
                    onTap: onToggleFolder,
                  ),
                ),
              ],
            )
          : StudioChoice(
              key: ValueKey('map-library-${map!.id}'),
              label: '${dirty ? '• ' : ''}${map.name}',
              leading: Icon(
                selecting && selected ? Icons.check_box : Icons.map_outlined,
                size: 18,
              ),
              selected: selected,
              onTap: () => onMap(map),
            ),
    );
  }
}
