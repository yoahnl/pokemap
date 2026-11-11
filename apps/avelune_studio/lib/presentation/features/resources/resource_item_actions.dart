import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_item_action_matrix.dart';

const _actionIcons = {
  ResourceItemActionKind.terrainEdit: Icons.edit_outlined,
  ResourceItemActionKind.terrainRename: Icons.drive_file_rename_outline,
  ResourceItemActionKind.tilesetInformation: Icons.edit_outlined,
  ResourceItemActionKind.move: Icons.drive_file_move_outlined,
  ResourceItemActionKind.usages: Icons.account_tree_outlined,
  ResourceItemActionKind.replaceSource: Icons.compare_outlined,
  ResourceItemActionKind.duplicateTerrain: Icons.copy_outlined,
  ResourceItemActionKind.removeTerrain: Icons.delete_outline,
  ResourceItemActionKind.duplicateDefinition: Icons.copy_outlined,
  ResourceItemActionKind.remove: Icons.delete_outline,
};

class ResourceItemActions extends StatelessWidget {
  const ResourceItemActions({
    super.key,
    required this.item,
    this.onInformation,
    this.onMove,
    this.onUsages,
    this.onReplace,
    this.onRemove,
    this.onDuplicate,
    this.onTerrainEdit,
    this.buttons = false,
  });
  final ResourceItem item;
  final ValueChanged<ResourceItem>? onInformation, onMove, onUsages;
  final ValueChanged<ResourceItem>? onReplace, onRemove, onDuplicate;
  final ValueChanged<ResourceItem>? onTerrainEdit;
  final bool buttons;

  @override
  Widget build(BuildContext context) {
    final callbacks = {
      ResourceItemActionKind.terrainEdit: onTerrainEdit,
      ResourceItemActionKind.terrainRename: onInformation,
      ResourceItemActionKind.tilesetInformation: onInformation,
      ResourceItemActionKind.move: onMove,
      ResourceItemActionKind.usages: onUsages,
      ResourceItemActionKind.replaceSource: onReplace,
      ResourceItemActionKind.duplicateTerrain: onDuplicate,
      ResourceItemActionKind.removeTerrain: onRemove,
      ResourceItemActionKind.duplicateDefinition: onDuplicate,
      ResourceItemActionKind.remove: onRemove,
    };
    final actions = <(String, IconData, ValueChanged<ResourceItem>)>[
      for (final entry in resourceItemActionMatrix(
        item,
        onInformation: onInformation != null,
        onMove: onMove != null,
        onUsages: onUsages != null,
        onReplace: onReplace != null,
        onRemove: onRemove != null,
        onDuplicate: onDuplicate != null,
        onTerrainEdit: onTerrainEdit != null,
      ))
        (
          entry.label,
          _actionIcons[entry.kind]!,
          callbacks[entry.kind]!,
        ),
    ];
    if (actions.isEmpty) return const SizedBox();
    if (buttons) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, icon, action) in actions)
            StudioButton(
              label: label,
              icon: icon,
              secondary: true,
              variant: icon == Icons.delete_outline
                  ? StudioButtonVariant.destructive
                  : StudioButtonVariant.secondary,
              onPressed: () => action(item),
            ),
        ],
      );
    }
    return Builder(
      builder: (buttonContext) => StudioTool(
        key: ValueKey('resource-actions-${item.identity}'),
        label: 'Actions de ${item.name}',
        icon: Icons.more_horiz,
        onPressed: () async {
          final box = buttonContext.findRenderObject()! as RenderBox;
          final overlay =
              Overlay.of(context).context.findRenderObject()! as RenderBox;
          final position = box.localToGlobal(Offset(0, box.size.height));
          final action = await showMenu<int>(
            context: context,
            position: RelativeRect.fromRect(
              Rect.fromLTWH(position.dx, position.dy, 1, 1),
              Offset.zero & overlay.size,
            ),
            items: [
              for (var index = 0; index < actions.length; index++)
                PopupMenuItem(
                  value: index,
                  child: Row(
                    children: [
                      Icon(
                        actions[index].$2,
                        size: 18,
                        color: actions[index].$2 == Icons.delete_outline
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(actions[index].$1)),
                    ],
                  ),
                ),
            ],
          );
          if (context.mounted && action != null) actions[action].$3(item);
        },
      ),
    );
  }
}
