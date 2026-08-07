import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_shape_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_extensions.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_glass_surface.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_pressable.dart';

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
        child: AveluneGlassSurface(
          cornerRadius: AveluneShapes.minimumTouchTarget / 2,
          elevated: false,
          interactive: true,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: enabled ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
