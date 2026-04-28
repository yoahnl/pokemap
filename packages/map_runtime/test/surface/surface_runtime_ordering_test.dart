import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime ordering hardening', () {
    test('renders SurfaceLayer above terrain and path in background pass',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              const MapLayer.terrain(
                id: 'terrain',
                name: 'Terrain',
                terrains: [TerrainType.grass],
              ),
              const MapLayer.path(
                id: 'path',
                name: 'Path',
                cells: [true],
              ),
              surfaceTestLayer(),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('renders TileLayer above SurfaceLayer in background pass', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.tile(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: [1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'base': await runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('renders project element entities above SurfaceLayer', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          elements: [surfaceTestElement()],
          map: surfaceTestMap(
            layers: [surfaceTestLayer()],
            entities: const [
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'entity-prop',
                ),
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'entity': await runtimeTilesetImage([const Color(0xFF800080)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(128, 0, 128, 255));
    });

    test('renders collision overlay above SurfaceLayer when enabled', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.collision(
                id: 'collision',
                name: 'Collision',
                collisions: [true],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
        showCollisionOverlay: true,
      );

      final image = await renderSurfaceTestComponent(component);
      final pixel = await pixelAt(image, 16, 16);

      expect(pixel[0], greaterThan(0));
      expect(pixel[1], greaterThan(0));
      expect(pixel[2], lessThan(255));
      expect(pixel[3], 255);
    });

    test('keeps SurfaceLayer out of foreground pass', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(layers: [surfaceTestLayer()]),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
        renderPass: MapLayerRenderPass.foreground,
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
    });

    test('respects SurfaceLayer visibility and opacity', () async {
      final invisible = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [surfaceTestLayer(isVisible: false)],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );
      expect(
        await pixelAt(await renderSurfaceTestComponent(invisible), 16, 16),
        rgba(0, 0, 0, 0),
      );

      final transparent = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [surfaceTestLayer(opacity: 0)],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );
      expect(
        await pixelAt(await renderSurfaceTestComponent(transparent), 16, 16),
        rgba(0, 0, 0, 0),
      );

      final halfOpacity = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [surfaceTestLayer(opacity: 0.5)],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );
      final halfOpacityPixel = await pixelAt(
        await renderSurfaceTestComponent(halfOpacity),
        16,
        16,
      );
      expect(halfOpacityPixel[3], greaterThan(0));
      expect(halfOpacityPixel[3], lessThan(255));
    });
  });
}
