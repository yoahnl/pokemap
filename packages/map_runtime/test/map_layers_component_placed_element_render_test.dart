import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent placed element rendering', () {
    test('renders a static MapPlacedElement from its project element frame',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: const MapData(
            id: 'placed-element-map',
            name: 'Placed Element Map',
            size: GridSize(width: 1, height: 1),
            layers: [
              MapLayer.tile(
                id: 'decor',
                name: 'Decor',
                tilesetId: 'base',
                tiles: [0],
              ),
            ],
            placedElements: [
              MapPlacedElement(
                id: 'tree-1',
                layerId: 'decor',
                elementId: 'tree',
                pos: GridPos(x: 0, y: 0),
              ),
            ],
          ),
          elements: const [
            ProjectElementEntry(
              id: 'tree',
              name: 'Tree',
              tilesetId: 'entity',
              categoryId: 'nature',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(const [Color(0xFF000000)]),
          'entity': await runtimeTilesetImage(const [Color(0xFF29B34A)]),
        },
      );

      final image = await _renderComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(41, 179, 74, 255));
    });
  });
}

Future<ui.Image> _renderComponent(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(
        surfaceTestTileSize,
        surfaceTestTileSize,
      );
}
