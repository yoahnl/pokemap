import 'package:flutter/material.dart';

class StudioChoice extends StatelessWidget {
  const StudioChoice({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.subtitle,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? leading;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    selected: selected,
    leading: leading,
    onTap: onTap,
    title: Text(label),
    subtitle: subtitle == null ? null : Text(subtitle!),
    selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
