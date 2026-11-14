import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

class StudioFilterChip extends StatelessWidget {
  const StudioFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      tooltip: tooltip,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      visualDensity: VisualDensity.compact,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      ),
    );
  }
}
