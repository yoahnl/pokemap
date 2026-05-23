import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../../../../features/editor/state/editor_notifier.dart';
import '../../../../../features/editor/state/editor_selectors.dart';
import '../../../../shared/cupertino_editor_widgets.dart';
import '../../../../../theme/theme.dart';
import '../../dialogs/world_group_dialogs.dart';

class GroupNode extends StatelessWidget {
  const GroupNode({
    super.key,
    required this.group,
    required this.project,
    required this.snapshot,
    required this.notifier,
    required this.depth,
  });

  final ProjectMapGroup group;
  final ProjectManifest project;
  final EditorProjectExplorerSnapshot snapshot;
  final EditorNotifier notifier;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final childrenGroups = project.groups
        .where((candidate) => candidate.parentGroupId == group.id)
        .toList();
    final childrenMaps = project.maps
        .where((candidate) => candidate.groupId == group.id)
        .toList();
    return CupertinoDisclosureTile(
      useEditorMacosSidebarDisclosureStyle: true,
      tilePadding:
          EdgeInsets.only(left: 8 + 16.0 * depth, right: 8, top: 4, bottom: 4),
      childrenPadding: EdgeInsets.zero,
      leading: MacosIcon(_groupIcon(group.type), size: 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _translateGroupType(group.type).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
      trailing: Builder(
        builder: (buttonContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Actions du groupe',
          iconSize: 16,
          onPressed: () => _showGroupContextMenu(
            context,
            group,
            notifier,
            snapshot,
            anchorGlobal: editorMenuAnchorBelowWidget(buttonContext),
          ),
        ),
      ),
      onSecondaryTapDown: (details) => _showGroupContextMenu(
        context,
        group,
        notifier,
        snapshot,
        anchorGlobal: details.globalPosition,
      ),
      children: [
        ...childrenGroups.map(
          (childGroup) => GroupNode(
            group: childGroup,
            project: project,
            snapshot: snapshot,
            notifier: notifier,
            depth: depth + 1,
          ),
        ),
        ...childrenMaps.map(
          (mapEntry) => MapNode(
            map: mapEntry,
            snapshot: snapshot,
            notifier: notifier,
            depth: depth + 1,
          ),
        ),
      ],
    );
  }

  IconData _groupIcon(MapGroupType type) {
    return switch (type) {
      MapGroupType.city => CupertinoIcons.building_2_fill,
      MapGroupType.village => CupertinoIcons.house_fill,
      MapGroupType.route => CupertinoIcons.map_fill,
      MapGroupType.dungeon => CupertinoIcons.lock_shield,
      MapGroupType.cave => CupertinoIcons.circle_grid_hex,
      MapGroupType.forest => CupertinoIcons.leaf_arrow_circlepath,
      MapGroupType.tower => CupertinoIcons.arrow_up_circle_fill,
      MapGroupType.facility => CupertinoIcons.briefcase_fill,
      MapGroupType.special => CupertinoIcons.star_fill,
    };
  }

  String _translateGroupType(MapGroupType type) {
    return switch (type) {
      MapGroupType.city => 'Ville',
      MapGroupType.village => 'Village',
      MapGroupType.route => 'Route',
      MapGroupType.dungeon => 'Donjon',
      MapGroupType.cave => 'Grotte',
      MapGroupType.forest => 'Forêt',
      MapGroupType.tower => 'Tour',
      MapGroupType.facility => 'Installation',
      MapGroupType.special => 'Spécial',
    };
  }

  Future<void> _showGroupContextMenu(
    BuildContext context,
    ProjectMapGroup group,
    EditorNotifier notifier,
    EditorProjectExplorerSnapshot snapshot, {
    required Offset anchorGlobal,
  }) async {
    final action = await showMacosEditorContextMenu<String>(
      context: context,
      globalPosition: anchorGlobal,
      actions: const [
        MacosEditorSheetAction(label: 'Ajouter une carte', value: 'add_map'),
        MacosEditorSheetAction(label: 'Ajouter un sous-groupe', value: 'add_subgroup'),
        MacosEditorSheetAction(label: 'Renommer le groupe', value: 'rename'),
        MacosEditorSheetAction(
          label: 'Supprimer le groupe',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'add_map':
        await showCreateMapInGroupDialog(context, group.id, notifier, snapshot);
      case 'add_subgroup':
        showCreateSubGroupDialog(context, group.id, notifier);
      case 'rename':
        await showRenameGroupDialog(context, group, notifier);
      case 'delete':
        notifier.deleteGroup(group.id);
    }
  }
}

class MapNode extends StatelessWidget {
  const MapNode({
    super.key,
    required this.map,
    required this.snapshot,
    required this.notifier,
    required this.depth,
  });

  final ProjectMapEntry map;
  final EditorProjectExplorerSnapshot snapshot;
  final EditorNotifier notifier;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final isSelected = snapshot.activeMapId == map.id;

    return EditorSidebarListRow(
      selected: isSelected,
      onTap: () => notifier.loadMap(map.relativePath),
      onSecondaryTapDown: (details) => _showMapContextMenu(
        context,
        details.globalPosition,
        map,
        notifier,
      ),
      leftIndent: 14 + 16.0 * depth,
      leading: MacosIcon(_roleIcon(map.role), size: 16),
      title: Text(map.name),
      trailing: isSelected
          ? MacosIcon(
              CupertinoIcons.pencil,
              size: 14,
              color: context.pokeMapColors.brandPrimary,
            )
          : null,
    );
  }

  IconData _roleIcon(MapRole role) {
    return switch (role) {
      MapRole.exterior => CupertinoIcons.sun_max,
      MapRole.interior => CupertinoIcons.house,
      MapRole.basement => CupertinoIcons.arrow_down_circle,
      MapRole.upper_floor => CupertinoIcons.arrow_up_circle,
      MapRole.connector => CupertinoIcons.link,
      MapRole.gate => CupertinoIcons.square_arrow_right,
      MapRole.section => CupertinoIcons.square_split_2x1,
      MapRole.room => CupertinoIcons.square_grid_2x2,
      MapRole.sub_area => CupertinoIcons.layers_alt,
    };
  }

  Future<void> _showMapContextMenu(
    BuildContext context,
    Offset position,
    ProjectMapEntry mapEntry,
    EditorNotifier notifier,
  ) async {
    final action = await showMacosEditorContextMenu<String>(
      context: context,
      globalPosition: position,
      actions: const [
        MacosEditorSheetAction(label: 'Renommer la carte', value: 'rename'),
        MacosEditorSheetAction(label: 'Dupliquer la carte', value: 'duplicate'),
        MacosEditorSheetAction(
          label: 'Supprimer la carte',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await showRenameMapDialog(context, mapEntry, notifier);
      case 'duplicate':
        notifier.duplicateMap(mapEntry.id);
      case 'delete':
        notifier.deleteMap(mapEntry.id);
    }
  }
}
