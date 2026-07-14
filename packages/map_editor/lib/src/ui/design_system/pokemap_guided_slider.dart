import 'package:flutter/cupertino.dart';

import '../../theme/theme.dart';

/// Integer-only guided control for authoring values presented as percentages.
///
/// Product screens keep their domain conversion outside this primitive. The
/// slider only exposes a named, accessible value between [min] and [max].
class PokeMapGuidedSlider extends StatelessWidget {
  const PokeMapGuidedSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.min = 0,
    this.max = 100,
  }) : assert(min < max);

  final String label;
  final String? description;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final clampedValue = value.clamp(min, max);
    return Semantics(
      slider: true,
      label: label,
      value: '$clampedValue %',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description case final description?) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$clampedValue %',
                style: TextStyle(
                  color: colors.brandPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CupertinoSlider(
            value: clampedValue.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: colors.brandPrimary,
            thumbColor: colors.surfaceBase,
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      ),
    );
  }
}
