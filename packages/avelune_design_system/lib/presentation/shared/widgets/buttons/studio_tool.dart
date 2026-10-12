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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: IconButton(
        key: ValueKey(label),
        onPressed: onPressed,
        isSelected: selected,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 18),
            if (selected)
              Positioned(
                left: 4,
                right: 4,
                bottom: -5,
                child: Container(height: 2, color: colors.onPrimaryContainer),
              ),
          ],
        ),
        tooltip: shortcut == null ? label : '$label · $shortcut',
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(7)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurfaceVariant.withValues(alpha: .35)
                : selected
                ? colors.onPrimaryContainer
                : colors.onSurface,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.surfaceContainerLow
                : selected
                ? colors.primaryContainer
                : colors.surfaceContainer,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? colors.onSurface
                  : selected
                  ? colors.primary
                  : colors.outlineVariant,
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? colors.primary.withValues(alpha: .25)
                : colors.primary.withValues(alpha: .10),
          ),
        ),
      ),
    );
  }
}
