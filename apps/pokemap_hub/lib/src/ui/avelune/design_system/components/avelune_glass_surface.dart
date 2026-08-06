import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../foundation/avelune_glass_tokens.dart';
import '../theme/avelune_theme_extensions.dart';

/// The one place in the app that touches `liquid_glass_easy`.
///
/// Every glass surface in the chrome goes through here. The package is young —
/// 3.5.0 was published days before this landed, by an unverified uploader — so
/// the whole dependency is deliberately reachable from a single file. If it
/// breaks or has to be swapped for a plain `BackdropFilter`, this is the only
/// widget that changes.
///
/// Refraction needs Impeller. Under Skia — which is what the headless visual
/// gates use — the package logs a notice and falls back to a frosted blur and
/// tint. That means the goldens record the fallback, never the real lensing;
/// the premium look can only be judged on a device.
class AveluneGlassSurface extends StatelessWidget {
  const AveluneGlassSurface({
    super.key,
    required this.child,
    this.cornerRadius = AveluneGlass.panelRadius,
    this.padding = EdgeInsets.zero,
    this.readable = false,
    this.elevated = true,
    this.semanticLabel,
  });

  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry padding;

  /// Uses the denser fill, for surfaces carrying body copy over a busy scene.
  final bool readable;

  /// Whether the surface casts a shadow onto what it floats over.
  final bool elevated;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final glass = LiquidGlassLens(
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
        ),
        appearance: LiquidGlassAppearance(
          color: readable ? AveluneGlass.readableTint : AveluneGlass.tint,
          blur: LiquidGlassBlur(
            sigmaX: AveluneGlass.blur,
            sigmaY: AveluneGlass.blur,
          ),
          saturation: AveluneGlass.saturation,
        ),
        refraction: const LiquidGlassRefraction(
          distortion: AveluneGlass.distortion,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    // The lens is the sizing child, so the stack takes its measurements from
    // the content. Positioning both children would leave the stack unbounded
    // and it would fail to lay out at all.
    final bordered = Stack(
      children: <Widget>[
        glass,
        // The rim is drawn on top rather than as part of the lens: the lens
        // clips its child to the shape, so a border inside it would be cut in
        // half along the edge.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AveluneGlass.radiusOf(cornerRadius),
                border: Border.all(color: AveluneGlass.border),
              ),
            ),
          ),
        ),
      ],
    );

    final surface = elevated
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AveluneGlass.radiusOf(cornerRadius),
              boxShadow: AveluneGlass.elevation(colors.canvas),
            ),
            child: bordered,
          )
        : bordered;

    if (semanticLabel == null) return surface;
    return Semantics(container: true, label: semanticLabel, child: surface);
  }
}
