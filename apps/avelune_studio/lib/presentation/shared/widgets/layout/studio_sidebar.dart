import 'package:flutter/material.dart';

class StudioSidebar extends StatelessWidget {
  const StudioSidebar({super.key, required this.child, this.width = 220});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      width: width,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    ),
  );
}
