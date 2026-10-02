import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'resource_catalog.dart';

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
    final actions = <(String, IconData, ValueChanged<ResourceItem>)>[
      if (item.terrain != null && onTerrainEdit != null)
        ('Modifier les raccords', Icons.edit_outlined, onTerrainEdit!),
      if (item.terrain != null && onInformation != null)
        (
          'Renommer le terrain…',
          Icons.drive_file_rename_outline,
          onInformation!,
        ),
      if (item.tileset != null && onInformation != null)
        ('Modifier les informations', Icons.edit_outlined, onInformation!),
      if (onMove != null)
        ('Déplacer vers…', Icons.drive_file_move_outlined, onMove!),
      if (onUsages != null)
        (
          'Voir les usages dans le projet',
          Icons.account_tree_outlined,
          onUsages!,
        ),
      if (item.tileset != null && onReplace != null)
        ('Remplacer l’image source…', Icons.compare_outlined, onReplace!),
      if (item.terrain != null && onDuplicate != null)
        ('Dupliquer le terrain…', Icons.copy_outlined, onDuplicate!),
      if (item.terrain != null && onRemove != null)
        ('Supprimer le terrain…', Icons.delete_outline, onRemove!),
      if (item.element != null && onDuplicate != null)
        ('Dupliquer la définition…', Icons.copy_outlined, onDuplicate!),
      if (onRemove != null && (item.tileset != null || item.element != null))
        (
          item.element == null
              ? 'Supprimer la planche…'
              : 'Supprimer la définition…',
          Icons.delete_outline,
          onRemove!,
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
