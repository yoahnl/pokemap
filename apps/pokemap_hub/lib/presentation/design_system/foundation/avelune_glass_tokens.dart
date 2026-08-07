import 'package:flutter/widgets.dart';

/// Glass vocabulary for the Avelune chrome.
///
/// The room itself — console, credenza, cartridges — stays skeuomorphic. Only
/// the chrome floating over it is glass, which is the case the effect is built
/// for: a lens has to have something worth refracting behind it.
///
/// Values follow the Grimaldi design system's conventions: a named token per
/// decision, with the reason recorded next to it rather than in a commit.
abstract final class AveluneGlass {
  /// Corner radius of a floating capsule, such as the navigation pill. Applied
  /// as a continuous rounded rectangle, so it reads as a squircle rather than a
  /// stadium with two hard arcs.
  static const double capsuleRadius = 28;

  /// Corner radius of a sheet or panel.
  static const double panelRadius = 26;

  /// Corner radius of a small inline surface, such as a settings row.
  static const double tileRadius = 18;

  /// Fill of the glass. Low-alpha white over the dark room reads as a lit edge
  /// rather than a grey overlay.
  static const Color tint = Color(0x1FFFFFFF);

  /// Slightly denser fill for surfaces that carry body copy, so text keeps its
  /// contrast against a busy background.
  static const Color readableTint = Color(0x33FFFFFF);

  /// Fully transparent, for borders that are only present when selected.
  static const Color clear = Color(0x00FFFFFF);

  /// The bright rim along the top edge of a real glass slab.
  static const Color border = Color(0x3DFFFFFF);

  /// Rim thickness handed to the lens shape, which lights the edge from what it
  /// samples behind the glass rather than stroking a flat outline.
  static const double borderWidth = 1.2;

  /// Colour and strength of that rim light.
  static const Color lightColor = Color(0xC2FFFFFF);
  static const double lightIntensity = 1.15;

  /// How much colour the optical border pulls from the backdrop, and how much
  /// ambient light it adds. Kept near the package defaults: the room is warm and
  /// detailed, and a hotter rim starts to look like neon.
  static const double borderSaturation = 1.45;
  static const double ambientIntensity = 1.1;

  /// Width of the band at the edge where the lens bends hardest, and the colour
  /// split across it. Both are what make an edge read as thick glass.
  static const double distortionWidth = 26;
  static const double chromaticAberration = 0.004;

  /// How much the lens bends what sits behind it. Kept low: the room is
  /// detailed, and heavy distortion turns the credenza into soup.
  static const double distortion = 0.07;

  /// Blur behind the glass. The package warns that values above roughly 7 stop
  /// matching between Skia and Impeller, so this stays under that.
  static const double blur = 6;

  /// Saturation lift, so the warm room colour carries through the glass instead
  /// of washing out to grey.
  static const double saturation = 1.12;

  /// Border radius for a glass surface of [cornerRadius].
  ///
  /// The lens takes a raw corner radius, but the rim and the shadow are ordinary
  /// Flutter decorations, and the component layer is barred from constructing
  /// radii itself — so the conversion belongs here with the other tokens.
  static BorderRadius radiusOf(double cornerRadius) =>
      BorderRadius.circular(cornerRadius);

  /// Drop shadow under a floating surface. Follows the Grimaldi navigation bar:
  /// a wide, soft shadow pulled slightly inward so it reads as height above the
  /// scene rather than as a hard outline.
  static const List<BoxShadow> elevation = <BoxShadow>[
        BoxShadow(
          color: Color(0x75000000),
          blurRadius: 30,
          offset: Offset(0, 10),
          spreadRadius: -2,
        ),
      ];
}
