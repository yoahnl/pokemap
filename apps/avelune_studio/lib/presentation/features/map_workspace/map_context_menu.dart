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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
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
            child: GestureDetector(
              key: const ValueKey('map-context-scrim'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              onSecondaryTap: widget.onDismiss,
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
            selected: target.id == request.selected?.id,
            key: ValueKey('map-context-pick-${target.id}'),
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
  });
  final MapContextAction action;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final row = InkWell(
      onTap: action.enabled ? onPressed : null,
      child: Container(
        color: selected ? colors.primaryContainer : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          action.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: action.enabled
                ? (selected ? colors.onPrimaryContainer : colors.onSurface)
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
    return action.enabled
        ? row
        : Tooltip(message: action.unavailable!, child: row);
  }
}

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
