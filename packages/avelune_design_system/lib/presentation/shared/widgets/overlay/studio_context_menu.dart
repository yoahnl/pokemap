import 'package:flutter/material.dart';

import 'studio_context_menu_panel.dart';

export 'studio_context_menu_panel.dart'
    show StudioContextMenuPanel, StudioContextMenuSeparatorLine;

sealed class StudioContextMenuItem {
  const StudioContextMenuItem();
}

final class StudioContextMenuEntry extends StudioContextMenuItem {
  const StudioContextMenuEntry({
    required this.label,
    this.onSelected,
    this.icon,
    this.shortcut,
    this.disabledReason,
    this.destructive = false,
    this.key,
  });

  final String label;
  final VoidCallback? onSelected;
  final IconData? icon;
  final String? shortcut;
  final String? disabledReason;
  final bool destructive;
  final Key? key;

  bool get enabled => onSelected != null && disabledReason == null;
}

final class StudioContextMenuSeparator extends StudioContextMenuItem {
  const StudioContextMenuSeparator();
}

abstract final class StudioContextMenu {
  static Future<void> showAt(
    BuildContext context, {
    required Offset position,
    required List<StudioContextMenuItem> items,
  }) => _show(context, Rect.fromLTWH(position.dx, position.dy, 0, 0), items);

  static Future<void> showBelow(
    BuildContext anchorContext, {
    required List<StudioContextMenuItem> items,
  }) {
    final box = anchorContext.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    return _show(anchorContext, topLeft & box.size, items);
  }

  static Future<void> _show(
    BuildContext context,
    Rect anchor,
    List<StudioContextMenuItem> items,
  ) async {
    if (items.isEmpty) return;
    final navigator = Navigator.of(context);
    final origin = navigator.context.findRenderObject() as RenderBox?;
    final localAnchor = origin == null
        ? anchor
        : Rect.fromPoints(
            origin.globalToLocal(anchor.topLeft),
            origin.globalToLocal(anchor.bottomRight),
          );
    final selected = await navigator.push<StudioContextMenuEntry>(
      StudioContextMenuRoute(
        anchor: localAnchor,
        items: items,
        barrierLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
      ),
    );
    if (selected != null && selected.enabled) selected.onSelected!();
  }
}

class StudioContextMenuButton extends StatelessWidget {
  const StudioContextMenuButton({
    super.key,
    required this.tooltip,
    required this.items,
    this.icon = Icons.more_horiz,
  });

  final String tooltip;
  final List<StudioContextMenuItem> Function() items;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchorContext) => IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () =>
          StudioContextMenu.showBelow(anchorContext, items: items()),
    ),
  );
}
