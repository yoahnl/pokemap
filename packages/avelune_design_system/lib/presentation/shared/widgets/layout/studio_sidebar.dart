import 'package:flutter/material.dart';

class StudioSidebar extends StatelessWidget {
  const StudioSidebar({super.key, required this.child, this.width = 250});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    ),
  );
}
