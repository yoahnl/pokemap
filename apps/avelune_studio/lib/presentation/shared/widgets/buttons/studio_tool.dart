import 'package:flutter/material.dart';

class StudioTool extends StatelessWidget {
  const StudioTool({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.shortcut,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final String? shortcut;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    key: ValueKey(label),
    onPressed: onPressed,
    isSelected: selected,
    icon: Icon(icon),
    selectedIcon: Icon(icon),
    tooltip: shortcut == null ? label : '$label · $shortcut',
  );
}
