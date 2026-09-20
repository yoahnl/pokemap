import 'package:flutter/material.dart';

class StudioMapOverlayFrame extends StatelessWidget {
  const StudioMapOverlayFrame({
    super.key,
    required this.child,
    this.selected = false,
  });
  final Widget child;
  final bool selected;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: selected
          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
          : null,
    ),
    child: child,
  );
}
