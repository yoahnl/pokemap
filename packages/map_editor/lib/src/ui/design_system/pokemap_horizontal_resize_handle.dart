import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// A token-driven vertical handle used to resize adjacent horizontal panes.
class PokeMapHorizontalResizeHandle extends StatelessWidget {
  const PokeMapHorizontalResizeHandle({
    super.key,
    required this.onDrag,
    required this.tooltip,
    this.width = 12,
  });

  final ValueChanged<double> onDrag;
  final String tooltip;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
          child: Semantics(
            label: tooltip,
            child: SizedBox(
              width: width,
              child: Center(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
