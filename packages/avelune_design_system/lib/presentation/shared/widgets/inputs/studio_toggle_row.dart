import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

class StudioToggleRow extends StatelessWidget {
  const StudioToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.icon,
    this.accent,
  });
  final String label;
  final String? description;
  final IconData? icon;
  final StudioAccent? accent;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    secondary: icon == null
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              color: accent?.color(context).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 21, color: accent?.color(context)),
            ),
          ),
    activeThumbColor: accent?.color(context),
    title: Text(label),
    subtitle: description == null ? null : Text(description!),
    value: value,
    onChanged: onChanged,
  );
}
