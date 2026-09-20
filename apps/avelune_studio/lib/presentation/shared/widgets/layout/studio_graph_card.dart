import 'package:flutter/material.dart';

class StudioGraphCard extends StatelessWidget {
  const StudioGraphCard({
    super.key,
    required this.child,
    this.selected = false,
    this.accent,
  });
  final Widget child;
  final bool selected;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: accent == null
          ? colors.surfaceContainer
          : Color.alphaBlend(
              accent!.withValues(alpha: .14),
              colors.surfaceContainerLowest,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? colors.primary
              : accent?.withValues(alpha: .8) ?? colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
