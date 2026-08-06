import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// The console has to rest on the credenza, not hover over it.
///
/// Both layers are painted with transparent padding around their art, so the
/// seam between them cannot be derived from the layout rectangles alone:
/// `console/body.webp` keeps 36 px of empty canvas below the feet on a 360 px
/// height, which put the credenza a tenth of the console height too low.
void main() {
  const presets = <Size>[
    Size(393, 852),
    Size(427, 952),
    Size(320, 568),
  ];

  testWidgets('the published fractions still match the artwork',
      (tester) async {
    final consoleBottom = await _lastOpaqueRowFraction(
      tester,
      AveluneMaterialCatalog.consoleBody.path,
    );
    final credenzaTop = await _firstOpaqueRowFraction(
      tester,
      AveluneMaterialCatalog.furnitureFinish('walnut').path,
    );

    expect(
      consoleBottom,
      closeTo(kAveluneConsoleFootlineFraction, 0.005),
      reason: 'Re-exporting the console art without its padding would silently '
          'move the seam.',
    );
    expect(
      credenzaTop,
      closeTo(kAveluneCredenzaVisibleTopFraction, 0.005),
      reason: 'Same for the credenza silhouette.',
    );
  });

  for (final preset in presets) {
    test('console feet meet the credenza surface at '
        '${preset.width.toInt()}x${preset.height.toInt()}', () {
      final geometry = AveluneHomeGeometry.resolve(
        viewportSize: preset,
        safeArea: const EdgeInsets.only(top: 24, bottom: 16),
      );
      final layout = AveluneRoomSceneLayout.resolve(geometry);

      final consoleFootline = geometry.consoleRect.top +
          (geometry.consoleRect.height * kAveluneConsoleFootlineFraction);
      final credenzaSurface = layout.furnitureRect.top +
          (layout.furnitureRect.height * kAveluneCredenzaVisibleTopFraction);

      expect(
        credenzaSurface,
        closeTo(consoleFootline, 0.5),
        reason: 'A gap here is the console floating; an overlap is the console '
            'sinking into the furniture.',
      );
    });
  }
}

Future<double> _firstOpaqueRowFraction(WidgetTester tester, String asset) =>
    _rowFraction(tester, asset, first: true);

Future<double> _lastOpaqueRowFraction(WidgetTester tester, String asset) =>
    _rowFraction(tester, asset, first: false);

Future<double> _rowFraction(
  WidgetTester tester,
  String asset, {
  required bool first,
}) async {
  late double fraction;
  await tester.runAsync(() async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final pixels = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final bytes = pixels!.buffer.asUint8List();
      final rows = <int>[];
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (bytes[((y * image.width) + x) * 4 + 3] > 32) {
            rows.add(y);
            break;
          }
        }
      }
      // `first` yields the top of the art; otherwise the row just past the
      // bottom of it, which is the edge a surface has to line up with.
      fraction = first
          ? rows.first / image.height
          : (rows.last + 1) / image.height;
    } finally {
      image.dispose();
      codec.dispose();
    }
  });
  return fraction;
}
