import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_shape_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_spacing_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_glass_surface.dart';

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
    // Glass rather than a filled panel: sheets sit over the room, so the
    // surface has something worth refracting behind it.
    return AveluneGlassSurface(
      cornerRadius: borderRadius.topLeft.x,
      padding: padding,
      readable: true,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}
