import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_tool.dart';

enum MapLibraryAction {
  rename,
  move,
  up,
  down,
  deleteFolder,
  createMap,
  duplicate,
  resize,
  deleteMap,
}

class MapLibraryRowActions extends StatelessWidget {
  const MapLibraryRowActions({
    super.key,
    required this.child,
    required this.id,
    required this.targetName,
    required this.folder,
    required this.actions,
    required this.onAction,
    this.disabledReasons = const {},
  });
  final Widget child;
  final String id;
  final String targetName;
  final bool folder;
  final List<MapLibraryAction> actions;
  final Map<MapLibraryAction, String> disabledReasons;
  final ValueChanged<MapLibraryAction>? onAction;

  Future<void> _menu(BuildContext context, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final result = await showMenu<MapLibraryAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            enabled: onAction != null && !disabledReasons.containsKey(action),
            child: Row(
              children: [
                Icon(
                  _icon(action),
                  size: 18,
                  color:
                      action == MapLibraryAction.deleteFolder ||
                          action == MapLibraryAction.deleteMap
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    disabledReasons[action] == null
                        ? _label(action)
                        : '${_label(action)} · ${disabledReasons[action]}',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (context.mounted && result != null) onAction?.call(result);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onSecondaryTapDown: (event) => _menu(context, event.globalPosition),
    child: Row(
      children: [
        Expanded(child: child),
        Builder(
          builder: (context) => SizedBox(
            width: 30,
            child: StudioTool(
              key: ValueKey('map-library-${folder ? 'group-' : ''}actions-$id'),
              label: 'Actions de ${folder ? 'dossier' : 'carte'} $targetName',
              icon: Icons.more_horiz,
              onPressed: () {
                final box = context.findRenderObject()! as RenderBox;
                _menu(context, box.localToGlobal(Offset(0, box.size.height)));
              },
            ),
          ),
        ),
      ],
    ),
  );
}

String _label(MapLibraryAction action) => switch (action) {
  MapLibraryAction.rename => 'Renommer…',
  MapLibraryAction.move => 'Déplacer…',
  MapLibraryAction.up => 'Monter',
  MapLibraryAction.down => 'Descendre',
  MapLibraryAction.deleteFolder => 'Supprimer le dossier',
  MapLibraryAction.createMap => 'Nouvelle carte…',
  MapLibraryAction.duplicate => 'Dupliquer…',
  MapLibraryAction.resize => 'Redimensionner…',
  MapLibraryAction.deleteMap => 'Supprimer la carte…',
};
IconData _icon(MapLibraryAction action) => switch (action) {
  MapLibraryAction.rename => Icons.edit_outlined,
  MapLibraryAction.move => Icons.drive_file_move_outlined,
  MapLibraryAction.up => Icons.arrow_upward,
  MapLibraryAction.down => Icons.arrow_downward,
  MapLibraryAction.deleteFolder => Icons.delete_outline,
  MapLibraryAction.createMap => Icons.add,
  MapLibraryAction.duplicate => Icons.copy_outlined,
  MapLibraryAction.resize => Icons.aspect_ratio,
  MapLibraryAction.deleteMap => Icons.delete_outline,
};
