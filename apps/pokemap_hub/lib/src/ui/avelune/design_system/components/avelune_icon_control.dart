import 'package:flutter/material.dart';

import '../foundation/avelune_shape_tokens.dart';
import '../theme/avelune_theme_extensions.dart';
import 'avelune_pressable.dart';

class AveluneIconControl extends StatelessWidget {
  const AveluneIconControl({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.selected = false,
    this.autofocus = false,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool selected;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return SizedBox.square(
      dimension: AveluneShapes.minimumTouchTarget,
      child: AvelunePressable(
        semanticLabel: semanticLabel,
        onPressed: onPressed,
        enabled: enabled,
        selected: selected,
        autofocus: autofocus,
        borderRadius: AveluneShapes.pill,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? colors.glass : colors.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: colors.outline),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: selected ? colors.accentBright : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
