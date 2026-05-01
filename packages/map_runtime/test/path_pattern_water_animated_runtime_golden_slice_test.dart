import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('golden slice eau 2x2 animée depuis JSON dans MapLayersComponent',
      () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(_fixtureRaw()) as Map<String, dynamic>,
    );
    const map = MapData(
      id: 'runtime_water_golden',
      name: 'Runtime Water Golden',
      size: GridSize(width: 4, height: 2),
      layers: <MapLayer>[
        PathLayer(
          id: 'path_main',
          name: 'Path',
          presetId: 'water-base',
          cells: <bool>[
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
          ],
        ),
      ],
    );

    final bundle = RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: '/tmp/runtime-water-golden',
      tilesetAbsolutePathsById: const <String, String>{},
    );

    final component = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: {
        'tileset-main': await _runtimeTilesetImage(
          row0: const [
            Color(0xFFFF0000),
            Color(0xFF00FF00),
            Color(0xFF0000FF),
            Color(0xFFFFFF00),
          ],
          row1: const [
            Color(0xFFFF00FF),
            Color(0xFF00FFFF),
            Color(0xFFFFA500),
            Color(0xFF444444),
          ],
        ),
        'tileset-water-fx': await _runtimeTilesetImage(
          row0: const [
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFF111111),
          ],
          row1: const [
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFFFFFFFF),
          ],
        ),
      },
    );

    final frame0 = await _renderComponent(component, 128, 64);
    await _expectPixel(frame0, 16, 16, rgba(255, 0, 0, 255));
    await _expectPixel(frame0, 48, 16, rgba(0, 255, 0, 255));
    await _expectPixel(frame0, 16, 48, rgba(0, 0, 255, 255));
    await _expectPixel(frame0, 48, 48, rgba(255, 255, 0, 255));
    await _expectPixel(frame0, 80, 16, rgba(255, 0, 0, 255));
    await _expectPixel(frame0, 112, 48, rgba(255, 255, 0, 255));

    component.update(0.22);
    final frame1 = await _renderComponent(component, 128, 64);
    await _expectPixel(frame1, 16, 16, rgba(255, 0, 255, 255));
    await _expectPixel(frame1, 48, 16, rgba(0, 255, 255, 255));
    await _expectPixel(frame1, 16, 48, rgba(255, 165, 0, 255));
    await _expectPixel(frame1, 48, 48, rgba(255, 255, 255, 255));
    await _expectPixel(frame1, 80, 16, rgba(255, 0, 255, 255));
    await _expectPixel(frame1, 112, 48, rgba(255, 255, 255, 255));

    frame0.dispose();
    frame1.dispose();
  });
}

Future<void> _expectPixel(ui.Image image, int x, int y, List<int> expected) async {
  expect(await pixelAt(image, x, y), expected);
}

Future<ui.Image> _renderComponent(
  MapLayersComponent component,
  int width,
  int height,
) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

Future<RuntimeTilesetImage> _runtimeTilesetImage({
  required List<Color> row0,
  required List<Color> row1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  for (var x = 0; x < row0.length; x += 1) {
    canvas.drawRect(
      Rect.fromLTWH((x * 16).toDouble(), 0, 16, 16),
      Paint()..color = row0[x],
    );
    canvas.drawRect(
      Rect.fromLTWH((x * 16).toDouble(), 16, 16, 16),
      Paint()..color = row1[x],
    );
  }

  final image = await recorder.endRecording().toImage(64, 32);
  return RuntimeTilesetImage(
    images: [image],
    chunks: const [
      RuntimeTilesetChunk(
        top: 0,
        height: 32,
        width: 64,
      ),
    ],
    width: 64,
    height: 32,
  );
}

String _fixtureRaw() {
  return File(
    '../map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
  ).readAsStringSync();
}
