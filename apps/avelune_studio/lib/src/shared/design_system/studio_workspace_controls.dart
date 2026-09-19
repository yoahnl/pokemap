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

Future<String?> confirmStudioClose(BuildContext context) => showDialog<String>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Conserver vos modifications ?'),
    content: const Text('Des cartes ont des modifications non enregistrées.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, 'cancel'),
        child: const Text('Annuler'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, 'discard'),
        child: const Text('Abandonner'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, 'save'),
        child: const Text('Enregistrer'),
      ),
    ],
  ),
);
