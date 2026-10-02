import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void verifyUwu6InstalledConnections(RuntimeMapBundle bundle) {
  final layer = bundle.map.layers.whereType<SmartTileLayer>().single;
  final visuals = resolveSmartTileLayerVisuals(
    map: bundle.map,
    layer: layer,
    catalog: bundle.manifest.smartTileCatalog,
    pass: SmartTileVisualPass.background,
  );
  expect(visuals, hasLength(3));
  final frames = {
    for (final visual in visuals) (visual.sourceRect.x, visual.sourceRect.y),
  };
  expect(frames.length, greaterThan(1));
  final edited = visuals.singleWhere((v) => v.cellX == 5 && v.cellY == 8);
  expect((edited.sourceRect.x, edited.sourceRect.y), (16, 0));
  expect(visuals.map((v) => (v.cellX, v.cellY)).toSet(), {
    (5, 8),
    (5, 9),
    (6, 9),
  });
  print('UWU6_INSTALLED_CONNECTION_RECTS=$frames cells=5,8;5,9;6,9');
}

Future<void> verifyUwu6InstalledConnectionPixels(ui.Image frame) async {
  final pixels = (await frame.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  var green = 0, yellow = 0, blue = 0;
  for (var i = 0; i < pixels.lengthInBytes; i += 4) {
    if (pixels.getUint8(i + 3) != 255) continue;
    final color = (
      pixels.getUint8(i),
      pixels.getUint8(i + 1),
      pixels.getUint8(i + 2),
    );
    if (color == (25, 211, 181)) green++;
    if (color == (245, 210, 80)) yellow++;
    if (color == (55, 100, 240)) blue++;
  }
  expect(green, greaterThan(100));
  expect(yellow, greaterThan(100));
  expect(blue, greaterThan(100));
  print(
    'UWU6_INSTALLED_CONNECTION_PIXELS green=$green yellow=$yellow blue=$blue',
  );
}
