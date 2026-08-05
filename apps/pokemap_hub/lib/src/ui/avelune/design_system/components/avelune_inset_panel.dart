import 'package:flutter/material.dart';

import '../foundation/avelune_shape_tokens.dart';
import '../foundation/avelune_spacing_tokens.dart';
import '../theme/avelune_theme_extensions.dart';

class AveluneInsetPanel extends StatelessWidget {
  const AveluneInsetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AveluneSpacing.md),
    this.borderRadius = AveluneShapes.lg,
    this.semanticLabel,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceInset,
          borderRadius: borderRadius,
          border: Border.all(color: colors.outline),
          boxShadow: context.aveluneDepth.inset,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          clipBehavior: clipBehavior,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
