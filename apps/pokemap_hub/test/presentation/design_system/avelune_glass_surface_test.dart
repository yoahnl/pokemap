import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:pokemap_hub/presentation/design_system/avelune_design_system.dart';

/// The glass has to be on the optical path, not the legacy one.
///
/// `liquid_glass_easy` carries two refraction calculations. The legacy dials
/// (`distortion`, `distortionWidth`) drive `1 + d * pow(t, d)` with
/// `d = distortion * 100`, which stays flat across the band and then explodes
/// over the last few percent at the rim. That near-discontinuous sampling
/// gradient is what read as pixelated stair-stepping on device, and raising the
/// strength made it worse because the exponent grows with it.
///
/// None of this is visible in a golden: under Skia the package falls back to a
/// frosted blur and records none of the refraction. So the configuration is
/// asserted directly instead.
void main() {
  testWidgets('the lens refracts by Snell law, not the legacy curve',
      (tester) async {
    final lens = await _pumpAndReadLens(tester);
    final refraction = lens.style.refraction;

    expect(
      refraction.refractionType,
      isA<OpticalRefraction>(),
      reason: 'A null refractionType silently selects the legacy calculation, '
          'whose gradient is near-discontinuous at the rim.',
    );
    final optical = refraction.refractionType! as OpticalRefraction;
    expect(optical.refraction, greaterThan(1));
    expect(
      optical.depth,
      greaterThan(0),
      reason: 'Depth is the strength dial; at zero the glass stops bending '
          'anything and only the tint is left.',
    );
  });

  testWidgets('magnification does not enlarge the sampled pixels',
      (tester) async {
    final lens = await _pumpAndReadLens(tester);

    expect(
      lens.style.refraction.magnification,
      1,
      reason: 'Magnification scales the sampling around the lens centre, so '
          'above 1 it enlarges the very pixels it samples.',
    );
  });

  testWidgets('the clip follows the shape the shader draws', (tester) async {
    final lens = await _pumpAndReadLens(tester);
    final shape = lens.style.shape!;

    expect(
      shape.clipQuality,
      LiquidGlassClipQuality.exact,
      reason: 'The default circular clip does not follow a squircle corner, so '
          'the clipped blur edge misses the refraction in the corners.',
    );
  });

  testWidgets('blur stays low enough to read as glass rather than frost',
      (tester) async {
    final lens = await _pumpAndReadLens(tester);
    final blur = lens.style.appearance.blur;

    expect(
      blur.sigmaX,
      lessThanOrEqualTo(4),
      reason: 'Blur is what makes a surface read as frosted. It also stops '
          'matching between Skia and Impeller above roughly 7, per the '
          "package's own warning.",
    );
    expect(blur.sigmaX, blur.sigmaY);
  });
}

Future<LiquidGlassLens> _pumpAndReadLens(WidgetTester tester) async {
  await tester.pumpWidget(
    _TestApp(
      child: AveluneGlassSurface(
        cornerRadius: AveluneGlass.capsuleRadius,
        child: const SizedBox(width: 200, height: 60),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 60));
  return tester.widget<LiquidGlassLens>(find.byType(LiquidGlassLens));
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AveluneThemeData.standard.applyTo(ThemeData.dark()),
        home: Center(child: child),
      );
}
