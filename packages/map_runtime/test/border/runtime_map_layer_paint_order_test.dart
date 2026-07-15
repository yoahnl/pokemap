import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_layer_paint_order.dart';

void main() {
  group('buildRuntimeMapLayerPaintOrder', () {
    test('uses direct authored order for every background slot', () {
      final order = buildRuntimeMapLayerPaintOrder(
        const MapData(
          id: 'modern',
          name: 'Modern',
          size: GridSize(width: 1, height: 1),
          properties: <String, dynamic>{
            'tileLayerOrder': 'bottom_to_top',
          },
          layers: <MapLayer>[
            TerrainLayer(id: 'terrain', name: 'Terrain'),
            CollisionLayer(id: 'collision', name: 'Collision'),
            PathLayer(id: 'path', name: 'Path'),
            BorderLayer(id: 'border-low', name: 'Border low'),
            SurfaceLayer(id: 'surface', name: 'Surface'),
            TileLayer(id: 'tile', name: 'Tile'),
            ObjectLayer(id: 'objects', name: 'Objects'),
            EnvironmentLayer(id: 'environment', name: 'Environment'),
            BorderLayer(id: 'border-high', name: 'Border high'),
          ],
        ),
      );

      expect(order.usesAuthoredVisualLayerOrder, isTrue);
      expect(
        order.authoredLayers
            .map((entry) => '${entry.kind.name}:${entry.layer.id}'),
        const <String>[
          'terrain:terrain',
          'path:path',
          'border:border-low',
          'surface:surface',
          'tileBackground:tile',
          'objectNoop:objects',
          'environmentNoop:environment',
          'border:border-high',
        ],
      );
      expect(
        order.visibleTileLayersInPaintOrder.map((layer) => layer.id),
        const <String>['tile'],
      );
    });

    test('uses reverse authored order for legacy direction and skips hidden',
        () {
      final order = buildRuntimeMapLayerPaintOrder(
        const MapData(
          id: 'legacy',
          name: 'Legacy',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            BorderLayer(id: 'border-high', name: 'Border high'),
            EnvironmentLayer(id: 'environment', name: 'Environment'),
            ObjectLayer(id: 'objects', name: 'Objects'),
            TileLayer(id: 'tile', name: 'Tile'),
            SurfaceLayer(id: 'surface', name: 'Surface'),
            BorderLayer(
              id: 'hidden-border',
              name: 'Hidden Border',
              isVisible: false,
            ),
            PathLayer(id: 'path', name: 'Path'),
            TerrainLayer(id: 'terrain', name: 'Terrain'),
            BorderLayer(id: 'border-low', name: 'Border low'),
          ],
        ),
      );

      expect(
        order.authoredLayers.map((entry) => entry.layer.id),
        const <String>[
          'border-low',
          'terrain',
          'path',
          'surface',
          'tile',
          'objects',
          'environment',
          'border-high',
        ],
      );
    });

    test('a hidden sole Border still opts in while a Border-free map does not',
        () {
      final hiddenBorder = buildRuntimeMapLayerPaintOrder(
        const MapData(
          id: 'hidden',
          name: 'Hidden',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(id: 'tile', name: 'Tile'),
            BorderLayer(
              id: 'border',
              name: 'Border',
              isVisible: false,
            ),
          ],
        ),
      );
      final noBorder = buildRuntimeMapLayerPaintOrder(
        const MapData(
          id: 'old',
          name: 'Old',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(id: 'tile', name: 'Tile'),
          ],
        ),
      );

      expect(hiddenBorder.usesAuthoredVisualLayerOrder, isTrue);
      expect(hiddenBorder.authoredLayers.map((entry) => entry.layer.id),
          const <String>['tile']);
      expect(noBorder.usesAuthoredVisualLayerOrder, isFalse);
    });

    test('keeps an opted-in path directly after its ground tile', () {
      final order = buildRuntimeMapLayerPaintOrder(
        const MapData(
          id: 'deferred-path',
          name: 'Deferred path',
          size: GridSize(width: 1, height: 1),
          properties: <String, dynamic>{
            'tileLayerOrder': 'bottom_to_top',
          },
          layers: <MapLayer>[
            PathLayer(
              id: 'path',
              name: 'Path',
              properties: <String, String>{
                'paintAfterTileLayerId': 'ground',
              },
            ),
            BorderLayer(id: 'border-low', name: 'Border low'),
            TileLayer(id: 'ground', name: 'Ground'),
            SurfaceLayer(id: 'surface', name: 'Surface'),
            BorderLayer(id: 'border-high', name: 'Border high'),
          ],
        ),
      );

      expect(
        order.authoredLayers.map((entry) => entry.layer.id),
        const <String>[
          'border-low',
          'ground',
          'path',
          'surface',
          'border-high',
        ],
      );
    });

    test('documents every deferred runtime sentinel outside authored order',
        () {
      final order = buildRuntimeMapLayerPaintOrder(
        const MapData(
          id: 'sentinels',
          name: 'Sentinels',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            BorderLayer(id: 'border', name: 'Border'),
          ],
        ),
      );

      expect(
        order.deferredSentinels,
        const <RuntimeMapDeferredPaintSentinel>[
          RuntimeMapDeferredPaintSentinel.shadows,
          RuntimeMapDeferredPaintSentinel.backgroundPlacedElements,
          RuntimeMapDeferredPaintSentinel.backgroundEntities,
          RuntimeMapDeferredPaintSentinel.foregroundTilesAndPlacedElements,
          RuntimeMapDeferredPaintSentinel.foregroundEntities,
          RuntimeMapDeferredPaintSentinel.collisionOverlay,
        ],
      );
    });
  });
}
