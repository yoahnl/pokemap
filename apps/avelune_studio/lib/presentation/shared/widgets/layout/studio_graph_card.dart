import 'package:flutter/material.dart';

class StudioGraphCard extends StatelessWidget {
  const StudioGraphCard({
    super.key,
    required this.child,
    this.selected = false,
  });
  final Widget child;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
