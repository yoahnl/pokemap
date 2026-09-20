import 'package:flutter/material.dart';
import 'studio_graph_card.dart';

class StudioTimelineClip extends StatelessWidget {
  const StudioTimelineClip({
    super.key,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onResizeStart,
    this.onResizeUpdate,
    this.onResizeEnd,
    this.handleKey,
  });
  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onSelect, onDragStart, onDragEnd;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback? onResizeStart, onResizeEnd;
  final ValueChanged<double>? onResizeUpdate;
  final Key? handleKey;

  @override
  Widget build(BuildContext context) => StudioGraphCard(
    selected: selected,
    accent: accent,
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect,
            onHorizontalDragStart: (_) => onDragStart(),
            onHorizontalDragUpdate: (event) => onDragUpdate(event.delta.dx),
            onHorizontalDragEnd: (_) => onDragEnd(),
            child: Tooltip(
              message: label,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: accent.withValues(alpha: .35),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onResizeStart != null)
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              key: handleKey,
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => onResizeStart!(),
              onHorizontalDragUpdate: (event) =>
                  onResizeUpdate!(event.delta.dx),
              onHorizontalDragEnd: (_) => onResizeEnd!(),
              child: Container(width: 10, color: accent.withValues(alpha: .8)),
            ),
          ),
      ],
    ),
  );
}
