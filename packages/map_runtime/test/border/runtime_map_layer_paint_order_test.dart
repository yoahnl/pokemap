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

      expect(order.strategy, MapVisualCompositionStrategy.authoredStack);
      expect(
        order.semantics,
        MapVisualCompositionSemantics.legacyRuntimeV1,
      );
      expect(
        order.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'terrainLayer:terrain',
          'pathLayer:path',
          'borderLayer:border-low',
          'surfaceLayer:surface',
          'tileBackgroundLayer:tile',
          'objectNoop:objects',
          'environmentNoop:environment',
          'borderLayer:border-high',
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
        order.authoredLayerSteps.map((step) => step.layer!.id),
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

      expect(
        hiddenBorder.strategy,
        MapVisualCompositionStrategy.authoredStack,
      );
      expect(
        hiddenBorder.authoredLayerSteps.map((step) => step.layer!.id),
        const <String>['tile'],
      );
      expect(noBorder.strategy, MapVisualCompositionStrategy.legacyPhased);
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
        order.authoredLayerSteps.map((step) => step.layer!.id),
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
        order.steps.skip(1).map((step) => step.kind),
        const <MapVisualCompositionStepKind>[
          MapVisualCompositionStepKind.shadows,
          MapVisualCompositionStepKind.backgroundEntities,
          MapVisualCompositionStepKind.collisionOverlay,
          MapVisualCompositionStepKind.foregroundTilesAndPlacedElements,
          MapVisualCompositionStepKind.foregroundEntities,
        ],
      );
    });

    test('canonical order is independent from Border presence', () {
      MapVisualCompositionPlan plan({required bool includeHiddenBorder}) {
        return buildRuntimeMapLayerPaintOrder(
          MapData(
            id: includeHiddenBorder ? 'with-border' : 'without-border',
            name: 'Canonical',
            size: const GridSize(width: 1, height: 1),
            version: ProjectVersion.v3,
            visualStack: MapVisualStackConfig.canonicalV1,
            properties: const <String, dynamic>{
              'tileLayerOrder': 'bottom_to_top',
            },
            layers: <MapLayer>[
              const SurfaceLayer(id: 'surface-top', name: 'Surface top'),
              const TileLayer(id: 'tile-bottom', name: 'Tile bottom'),
              if (includeHiddenBorder)
                const BorderLayer(
                  id: 'hidden-border',
                  name: 'Hidden Border',
                  isVisible: false,
                ),
            ],
          ),
        );
      }

      final withoutBorder = plan(includeHiddenBorder: false);
      final withBorder = plan(includeHiddenBorder: true);

      expect(
        withoutBorder.steps.map((step) => step.stableKey),
        withBorder.steps.map((step) => step.stableKey),
      );
      expect(
        withoutBorder.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'tileBackgroundLayer:tile-bottom',
          'surfaceLayer:surface-top',
        ],
      );
      expect(
        withoutBorder.semantics,
        MapVisualCompositionSemantics.canonicalV1,
      );
    });

    test('rejects an unsupported future visual-stack version', () {
      expect(
        () => buildRuntimeMapLayerPaintOrder(
          MapData(
            id: 'future',
            name: 'Future',
            size: const GridSize(width: 1, height: 1),
            version: ProjectVersion.v3,
            visualStack: MapVisualStackConfig(semanticsVersion: 99),
          ),
        ),
        throwsA(
          isA<MapLoadException>().having(
            (error) => error.message,
            'message',
            contains('legacy rendering was not used'),
          ),
        ),
      );
    });
  });
}
