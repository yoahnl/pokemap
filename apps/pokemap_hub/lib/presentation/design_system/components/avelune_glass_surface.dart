import 'package:flutter/widgets.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_glass_tokens.dart';

/// The one place in the app that touches `liquid_glass_easy`.
///
/// Every glass surface goes through here. The package is young — 3.5.0 was
/// published days before this landed, by an unverified uploader — so the whole
/// dependency stays reachable from a single file. If it breaks or has to become
/// a plain `BackdropFilter`, one widget changes.
///
/// Refraction needs Impeller. Under Skia — which is what the headless visual
/// gates use — the package logs a notice and falls back to a frosted blur and
/// tint. The goldens therefore record the fallback, never the real lensing.
class AveluneGlassSurface extends StatelessWidget {
  const AveluneGlassSurface({
    super.key,
    required this.child,
    this.cornerRadius = AveluneGlass.panelRadius,
    this.padding = EdgeInsets.zero,
    this.readable = false,
    this.elevated = true,
    this.interactive = false,
    this.semanticLabel,
  });

  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry padding;

  /// Uses the denser fill, for surfaces carrying body copy over a busy scene.
  final bool readable;

  /// Whether the surface casts a shadow onto what it floats over.
  final bool elevated;

  /// Lets the glass deform under a finger. This is what replaces a Material
  /// ripple: the surface itself answers the touch, instead of an ink splash
  /// spreading across a rectangle.
  final bool interactive;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final surface = LiquidGlassLens(
      style: LiquidGlassStyle(
        // The shape carries the rim. Drawing a border over the lens instead
        // gives a flat outline; the package's optical border samples what is
        // behind the glass and lights the edge from it, which is most of what
        // separates real glass from a tinted rectangle.
        shape: LiquidGlassShape.squircle(
          cornerRadius: cornerRadius,
          borderWidth: AveluneGlass.borderWidth,
          lightIntensity: AveluneGlass.lightIntensity,
          lightColor: AveluneGlass.lightColor,
          borderType: const OpticalBorder(
            borderSaturation: AveluneGlass.borderSaturation,
            ambientIntensity: AveluneGlass.ambientIntensity,
          ),
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
          distortionWidth: AveluneGlass.distortionWidth,
          chromaticAberration: AveluneGlass.chromaticAberration,
        ),
      ),
      touch: interactive
          ? const LiquidGlassTouch(flex: LiquidGlassFlex.subtle())
          : null,
      child: Padding(padding: padding, child: child),
    );

    final result = elevated
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AveluneGlass.radiusOf(cornerRadius),
              boxShadow: AveluneGlass.elevation,
            ),
            child: surface,
          )
        : surface;

    if (semanticLabel == null) return result;
    return Semantics(container: true, label: semanticLabel, child: result);
  }
}
