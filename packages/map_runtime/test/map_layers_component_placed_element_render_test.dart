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
                cells: [0],
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

    test('does not render a placed element whose instance opacity is zero',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: const MapData(
            id: 'hidden-placed-element-map',
            name: 'Hidden Placed Element Map',
            size: GridSize(width: 1, height: 1),
            layers: [
              MapLayer.tile(
                id: 'decor',
                name: 'Decor',
                palette: <TileLayerPaletteEntry>[
                  TileLayerPaletteEntry(tilesetId: 'base', localTileId: 0),
                ],
                cells: [1],
              ),
            ],
            placedElements: [
              MapPlacedElement(
                id: 'reserved-state',
                layerId: 'decor',
                elementId: 'tree',
                pos: GridPos(x: 0, y: 0),
                opacity: 0,
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
          'base': await runtimeTilesetImage(const [Color(0xFF3156A4)]),
          'entity': await runtimeTilesetImage(const [Color(0xFF29B34A)]),
        },
      );

      final image = await _renderComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(49, 86, 164, 255));
    });

    test('renders an authored one-shot in the foreground pass', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: const MapData(
            id: 'animated-authored-element-map',
            name: 'Animated Authored Element Map',
            size: GridSize(width: 1, height: 1),
            layers: [
              MapLayer.tile(
                id: 'decor',
                name: 'Decor',
                cells: [0],
              ),
            ],
            placedElements: [
              MapPlacedElement(
                id: 'door-1',
                layerId: 'decor',
                elementId: 'door',
                pos: GridPos(x: 0, y: 0),
                animation: MapPlacedElementAnimation(
                  enabled: false,
                  autoplay: false,
                  speed: 2,
                ),
                properties: {
                  pokemapPlacementOriginProperty:
                      pokemapPlacementOriginAuthored,
                },
              ),
            ],
          ),
          elements: const [
            ProjectElementEntry(
              id: 'door',
              name: 'Door',
              tilesetId: 'entity',
              categoryId: 'architecture',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 100,
                ),
              ],
            ),
          ],
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(const [Color(0xFF000000)]),
          'entity': await runtimeTilesetImage(
            const [Color(0xFFC52D3C), Color(0xFF29B34A)],
          ),
        },
      );
      final foreground = MapLayersComponent(
        bundle: component.bundle,
        tileImagesByTilesetId: component.tileImagesByTilesetId,
        renderPass: MapLayerRenderPass.foreground,
      );

      component.update(0.12);
      foreground.update(0.12);
      final idleImage = await _renderComponent(component);
      expect(await pixelAt(idleImage, 16, 16), rgba(197, 45, 60, 255));

      expect(
        component.playPlacedElementAnimationOnce(instanceId: 'door-1'),
        isTrue,
      );
      expect(
        foreground.playPlacedElementAnimationOnce(instanceId: 'door-1'),
        isTrue,
      );
      component.update(0.06);
      foreground.update(0.06);

      final backgroundImage = await _renderComponent(component);
      final foregroundImage = await _renderComponent(foreground);

      expect(await pixelAt(backgroundImage, 16, 16), rgba(0, 0, 0, 0));
      expect(await pixelAt(foregroundImage, 16, 16), rgba(41, 179, 74, 255));
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
