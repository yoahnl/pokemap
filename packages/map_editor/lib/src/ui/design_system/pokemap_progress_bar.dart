import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_tone.dart';

class PokeMapProgressBar extends StatelessWidget {
  const PokeMapProgressBar({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.height = 6,
    this.tone = PokeMapTone.brand,
  });

  final double value;
  final String semanticLabel;
  final double height;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    final normalizedValue = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(normalizedValue * 100).toStringAsFixed(1)}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: normalizedValue,
          heightFactor: 1,
          child: ColoredBox(color: toneColors.icon),
        ),
      ),
    );
  }
}
