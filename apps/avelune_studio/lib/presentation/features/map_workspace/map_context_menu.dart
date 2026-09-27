import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';

class MapContextMenuRequest {
  const MapContextMenuRequest({
    required this.position,
    required this.targets,
    required this.selected,
    required this.actions,
  });
  final Offset position;
  final List<MapContextTarget> targets;
  final MapContextTarget? selected;
  final List<MapContextAction> actions;
}

/// The map context menu: compact, keyboard reachable, and always naming the
/// element it will act on.
class MapContextMenu extends StatefulWidget {
  const MapContextMenu({
    super.key,
    required this.request,
    required this.onTarget,
    required this.onCommand,
    required this.onDismiss,
  });
  final MapContextMenuRequest request;
  final ValueChanged<MapContextTarget> onTarget;
  final ValueChanged<MapContextCommand> onCommand;
  final VoidCallback onDismiss;

  @override
  State<MapContextMenu> createState() => _MapContextMenuState();
}

class _MapContextMenuState extends State<MapContextMenu> {
  final _focus = FocusScopeNode(debugLabel: 'map-context-menu');
  FocusNode? _restoreTo;

  @override
  void initState() {
    super.initState();
    _restoreTo = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _focus.nextFocus();
    });
  }

  @override
  void dispose() {
    final restore = _restoreTo;
    if (restore != null && restore.context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (restore.context != null) restore.requestFocus();
      });
    }
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final request = widget.request;
    final selected = request.selected;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              key: const ValueKey('map-context-scrim'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => widget.onDismiss(),
            ),
          ),
          CustomSingleChildLayout(
            delegate: _MenuLayout(request.position),
            child: FocusScope(
              node: _focus,
              autofocus: true,
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    widget.onDismiss();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Material(
                  key: const ValueKey('map-context-menu'),
                  color: colors.surfaceContainerHigh,
                  elevation: 3,
                  shadowColor: colors.shadow.withValues(alpha: .35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colors.outlineVariant),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                      maxHeight: 420,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(context, selected),
                          if (request.targets.length > 1)
                            ..._targets(context, request),
                          const Divider(height: 9),
                          for (final action in request.actions)
                            _ActionRow(
                              action: action,
                              onPressed: () => widget.onCommand(action.command),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, MapContextTarget? selected) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected?.kindLabel ?? 'Case de la carte',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          selected?.label ?? 'Aucun élément ici',
          key: const ValueKey('map-context-target'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    ),
  );

  List<Widget> _targets(BuildContext context, MapContextMenuRequest request) =>
      [
        const Divider(height: 9),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
          child: Text(
            'Éléments à cet endroit',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        for (final target in request.targets)
          _ActionRow(
            action: MapContextAction(
              MapContextCommand.properties,
              '${target.label} · ${target.kindLabel}',
            ),
            icon: switch (target.family) {
              MapContextFamily.character => Icons.person_outline,
              MapContextFamily.marker => Icons.place_outlined,
              MapContextFamily.warp => Icons.door_front_door_outlined,
              MapContextFamily.decor => Icons.park_outlined,
              MapContextFamily.zone => Icons.grid_view_outlined,
              MapContextFamily.trigger => Icons.auto_stories_outlined,
              MapContextFamily.cell => Icons.crop_square,
            },
            selected: target.sameAs(request.selected),
            key: ValueKey('map-context-pick-${target.key}'),
            onPressed: () => widget.onTarget(target),
          ),
      ];
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.action,
    required this.onPressed,
    this.selected = false,
    this.icon,
  });
  final MapContextAction action;
  final VoidCallback onPressed;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = action.enabled
        ? _actionColor(colors, action.command)
        : colors.onSurfaceVariant;
    final row = TextButton(
      onPressed: action.enabled ? onPressed : null,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: selected ? colors.primaryContainer : null,
        foregroundColor: action.command == MapContextCommand.delete
            ? colors.error
            : selected
            ? colors.onPrimaryContainer
            : colors.onSurface,
        disabledForegroundColor: colors.onSurfaceVariant,
      ),
      child: Row(
        children: [
          Icon(icon ?? _actionIcon(action.command), size: 17, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return action.enabled
        ? row
        : Tooltip(message: action.unavailable!, child: row);
  }
}

IconData _actionIcon(MapContextCommand command) => switch (command) {
  MapContextCommand.properties => Icons.tune,
  MapContextCommand.openResource => Icons.open_in_new,
  MapContextCommand.editResource => Icons.edit_outlined,
  MapContextCommand.openInteraction => Icons.forum_outlined,
  MapContextCommand.openDestination => Icons.map_outlined,
  MapContextCommand.openNarrativeDocument => Icons.auto_stories_outlined,
  MapContextCommand.move => Icons.open_with,
  MapContextCommand.bringForward => Icons.vertical_align_top,
  MapContextCommand.sendBackward => Icons.vertical_align_bottom,
  MapContextCommand.copyCoordinates => Icons.content_copy,
  MapContextCommand.eraseTile => Icons.backspace_outlined,
  MapContextCommand.delete => Icons.delete_outline,
};

Color _actionColor(ColorScheme colors, MapContextCommand command) =>
    switch (command) {
      MapContextCommand.delete || MapContextCommand.eraseTile => colors.error,
      MapContextCommand.move ||
      MapContextCommand.bringForward ||
      MapContextCommand.sendBackward => colors.secondary,
      MapContextCommand.properties ||
      MapContextCommand.editResource ||
      MapContextCommand.openInteraction => colors.tertiary,
      _ => colors.primary,
    };

class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout(this.anchor);
  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        constraints.biggest,
      ).deflate(const EdgeInsets.all(8));

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    anchor.dx.clamp(
      8.0,
      (size.width - childSize.width - 8).clamp(8.0, double.infinity),
    ),
    anchor.dy.clamp(
      8.0,
      (size.height - childSize.height - 8).clamp(8.0, double.infinity),
    ),
  );

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) => oldDelegate.anchor != anchor;
}
