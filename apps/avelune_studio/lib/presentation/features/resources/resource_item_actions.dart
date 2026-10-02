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
    this.buttons = false,
  });
  final ResourceItem item;
  final ValueChanged<ResourceItem>? onInformation, onMove, onUsages;
  final bool buttons;

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, ValueChanged<ResourceItem>)>[
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
                      Icon(actions[index].$2, size: 18),
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
