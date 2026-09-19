import 'package:flutter/material.dart';

class StudioButton extends StatelessWidget {
  const StudioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final content = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Flexible(child: Text(label)),
            ],
          );
    return secondary
        ? OutlinedButton(onPressed: onPressed, child: content)
        : FilledButton(onPressed: onPressed, child: content);
  }
}
