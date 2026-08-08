import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// The console has to rest on the cabin's technical ledge, not hover over it.
void main() {
  const presets = <Size>[
    Size(393, 852),
    Size(427, 952),
    Size(320, 568),
  ];

  testWidgets('the published console footline still matches the artwork',
      (tester) async {
    final consoleBottom = await _lastOpaqueRowFraction(
      tester,
      AveluneMaterialCatalog.consoleBody.path,
    );

    expect(
      consoleBottom,
      closeTo(kAveluneConsoleFootlineFraction, 0.005),
      reason: 'Re-exporting the console art without its padding would silently '
          'move the seam.',
    );
  });

  for (final preset in presets) {
    test(
        'console feet land inside the technical ledge at '
        '${preset.width.toInt()}x${preset.height.toInt()}', () {
      final geometry = AveluneHomeGeometry.resolve(
        viewportSize: preset,
        safeArea: const EdgeInsets.only(top: 24, bottom: 16),
      );
      final layout = AveluneRoomSceneLayout.resolve(geometry);

      final consoleFootline = geometry.consoleRect.top +
          (geometry.consoleRect.height * kAveluneConsoleFootlineFraction);
      expect(
        layout.consoleSupportY,
        closeTo(consoleFootline, 0.01),
      );
      expect(layout.consoleLedgeRect.top, lessThan(consoleFootline));
      expect(layout.consoleLedgeRect.bottom, greaterThan(consoleFootline));
      expect(
        layout.consoleLedgeRect.bottom,
        closeTo(layout.librarySheetRect.top, 0.01),
      );
    });

    test(
        'the ivory library carries uniformly aligned cartridges at '
        '${preset.width.toInt()}x${preset.height.toInt()}', () {
      final geometry = AveluneHomeGeometry.resolve(
        viewportSize: preset,
        safeArea: const EdgeInsets.only(top: 24, bottom: 16),
      );
      final layout = AveluneRoomSceneLayout.resolve(geometry);

      expect(
        geometry.shelfFirstCartridgeRect.bottom,
        closeTo(geometry.anchors.shelfBaseline.dy, 1),
      );
      expect(
        layout.librarySheetRect.width,
        greaterThanOrEqualTo(geometry.contentRect.width),
      );
      expect(
        layout.shelfRect.contains(geometry.shelfFirstCartridgeRect.center),
        isTrue,
      );
      expect(
        layout.windowRect.bottom,
        lessThan(layout.librarySheetRect.top),
      );
    });
  }
}

Future<double> _lastOpaqueRowFraction(WidgetTester tester, String asset) =>
    _rowFraction(tester, asset);

Future<double> _rowFraction(
  WidgetTester tester,
  String asset,
) async {
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
      fraction = (rows.last + 1) / image.height;
    } finally {
      image.dispose();
      codec.dispose();
    }
  });
  return fraction;
}
