import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildMapVisualCompositionPlan', () {
    test('characterizes the no-Border legacy runtime phases exactly', () {
      final result = buildMapVisualCompositionPlan(
        const MapData(
          id: 'legacy',
          name: 'Legacy',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(id: 'top-tile', name: 'Top tile'),
            SurfaceLayer(id: 'surface', name: 'Surface'),
            PathLayer(id: 'path', name: 'Path'),
            TerrainLayer(id: 'terrain', name: 'Terrain'),
            TileLayer(id: 'bottom-tile', name: 'Bottom tile'),
            CollisionLayer(id: 'collision', name: 'Collision'),
          ],
        ),
      );
      final plan = result.plan!;

      expect(plan.strategy, MapVisualCompositionStrategy.legacyPhased);
      expect(
        plan.steps.map((step) => step.stableKey),
        const <String>[
          'terrainLayer:terrain',
          'pathLayer:path',
          'surfaceLayer:surface',
          'shadows',
          'tileBackgroundLayer:bottom-tile',
          'placedElements:bottom-tile',
          'tileBackgroundLayer:top-tile',
          'placedElements:top-tile',
          'backgroundEntities',
          'collisionOverlay',
          'foregroundTilesAndPlacedElements',
          'foregroundEntities',
        ],
      );
    });

    test('preserves legacy deferred Path interleaving around ground', () {
      final plan = buildMapVisualCompositionPlan(
        const MapData(
          id: 'deferred',
          name: 'Deferred',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(id: 'upper', name: 'Upper'),
            PathLayer(
              id: 'path',
              name: 'Path',
              properties: <String, String>{
                'paintAfterTileLayerId': 'ground',
              },
            ),
            TileLayer(id: 'ground', name: 'Ground'),
          ],
        ),
      ).plan!;

      expect(
        plan.steps.map((step) => step.stableKey),
        const <String>[
          'tileBackgroundLayer:ground',
          'pathLayer:path',
          'shadows',
          'placedElements:ground',
          'tileBackgroundLayer:upper',
          'placedElements:upper',
          'backgroundEntities',
          'collisionOverlay',
          'foregroundTilesAndPlacedElements',
          'foregroundEntities',
        ],
      );
    });

    test('legacy Border presence selects authored strategy even when hidden',
        () {
      final plan = buildMapVisualCompositionPlan(
        const MapData(
          id: 'border-legacy',
          name: 'Border legacy',
          size: GridSize(width: 1, height: 1),
          version: ProjectVersion.v2,
          layers: <MapLayer>[
            SurfaceLayer(id: 'surface', name: 'Surface'),
            BorderLayer(
              id: 'hidden-border',
              name: 'Hidden Border',
              isVisible: false,
            ),
            TileLayer(id: 'tile', name: 'Tile'),
          ],
        ),
      ).plan!;

      expect(plan.strategy, MapVisualCompositionStrategy.authoredStack);
      expect(
        plan.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'tileBackgroundLayer:tile',
          'surfaceLayer:surface',
        ],
      );
    });

    test(
        'canonical v1 uses authored top-first order regardless of Border '
        'or legacy tile-order hint', () {
      MapVisualCompositionPlan build({required bool includeBorder}) =>
          buildMapVisualCompositionPlan(
            MapData(
              id: includeBorder ? 'canonical-border' : 'canonical',
              name: 'Canonical',
              size: const GridSize(width: 1, height: 1),
              version: ProjectVersion.v3,
              visualStack: MapVisualStackConfig.canonicalV1,
              properties: const <String, dynamic>{
                'tileLayerOrder': 'bottom_to_top',
              },
              layers: <MapLayer>[
                const SurfaceLayer(id: 'top-surface', name: 'Top surface'),
                if (includeBorder)
                  const BorderLayer(
                    id: 'hidden-border',
                    name: 'Hidden Border',
                    isVisible: false,
                  ),
                const TileLayer(id: 'middle-tile', name: 'Middle tile'),
                const TerrainLayer(
                  id: 'bottom-terrain',
                  name: 'Bottom terrain',
                ),
              ],
            ),
          ).plan!;

      expect(
        build(includeBorder: false)
            .authoredLayerSteps
            .map((step) => step.stableKey),
        const <String>[
          'terrainLayer:bottom-terrain',
          'tileBackgroundLayer:middle-tile',
          'surfaceLayer:top-surface',
        ],
      );
      expect(
        build(includeBorder: true)
            .authoredLayerSteps
            .map((step) => step.stableKey),
        const <String>[
          'terrainLayer:bottom-terrain',
          'tileBackgroundLayer:middle-tile',
          'surfaceLayer:top-surface',
        ],
      );
    });

    test('canonical v1 ignores the legacy deferred-Path hint', () {
      final plan = buildMapVisualCompositionPlan(
        const MapData(
          id: 'canonical-path-hint',
          name: 'Canonical path hint',
          size: GridSize(width: 1, height: 1),
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: <MapLayer>[
            TileLayer(id: 'ground', name: 'Ground'),
            PathLayer(
              id: 'path-below',
              name: 'Path below',
              properties: <String, String>{
                'paintAfterTileLayerId': 'ground',
              },
            ),
          ],
        ),
      ).plan!;

      expect(
        plan.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'pathLayer:path-below',
          'tileBackgroundLayer:ground',
        ],
      );
    });

    test('a native v4 Smart Tile layer selects authored paint order', () {
      final plan = buildMapVisualCompositionPlan(
        const MapData(
          id: 'smart-v4',
          name: 'Smart v4',
          version: ProjectVersion.v4,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(id: 'top-tile', name: 'Top tile'),
            SmartTileLayer(
              id: 'smart-path',
              name: 'Smart path',
              presetId: 'path',
              usage: SmartTileUsage.path,
            ),
            TileLayer(id: 'bottom-tile', name: 'Bottom tile'),
          ],
        ),
      ).plan!;

      expect(plan.strategy, MapVisualCompositionStrategy.authoredStack);
      expect(
        plan.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'tileBackgroundLayer:bottom-tile',
          'smartTileLayer:smart-path',
          'tileBackgroundLayer:top-tile',
        ],
      );
    });

    test('legacy phased mode exposes Object and Environment as no-op steps',
        () {
      final plan = buildMapVisualCompositionPlan(
        const MapData(
          id: 'legacy-noops',
          name: 'Legacy no-ops',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            ObjectLayer(id: 'object-top', name: 'Object top'),
            TileLayer(id: 'tile', name: 'Tile'),
            EnvironmentLayer(
              id: 'environment-bottom',
              name: 'Environment bottom',
            ),
          ],
        ),
      ).plan!;

      expect(
        plan.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'environmentNoop:environment-bottom',
          'objectNoop:object-top',
          'tileBackgroundLayer:tile',
        ],
      );
    });

    test('makes no-op layers, system sentinels and collision explicit', () {
      final plan = buildMapVisualCompositionPlan(
        const MapData(
          id: 'all-kinds',
          name: 'All kinds',
          size: GridSize(width: 1, height: 1),
          version: ProjectVersion.v3,
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: <MapLayer>[
            CollisionLayer(id: 'collision-top', name: 'Collision top'),
            EnvironmentLayer(id: 'environment', name: 'Environment'),
            ObjectLayer(id: 'object', name: 'Object'),
            BorderLayer(id: 'border', name: 'Border'),
            SurfaceLayer(id: 'surface', name: 'Surface'),
            PathLayer(id: 'path', name: 'Path'),
            TileLayer(id: 'tile', name: 'Tile'),
            TerrainLayer(id: 'terrain', name: 'Terrain'),
            CollisionLayer(id: 'collision-bottom', name: 'Collision bottom'),
          ],
        ),
      ).plan!;

      expect(
        plan.authoredLayerSteps.map((step) => step.kind),
        const <MapVisualCompositionStepKind>[
          MapVisualCompositionStepKind.terrainLayer,
          MapVisualCompositionStepKind.tileBackgroundLayer,
          MapVisualCompositionStepKind.pathLayer,
          MapVisualCompositionStepKind.surfaceLayer,
          MapVisualCompositionStepKind.borderLayer,
          MapVisualCompositionStepKind.objectNoop,
          MapVisualCompositionStepKind.environmentNoop,
        ],
      );
      expect(
        plan.visibleCollisionLayersInPaintOrder.map((layer) => layer.id),
        const <String>['collision-bottom', 'collision-top'],
      );
      expect(
        plan.steps.map((step) => step.kind),
        containsAll(<MapVisualCompositionStepKind>[
          MapVisualCompositionStepKind.shadows,
          MapVisualCompositionStepKind.placedElements,
          MapVisualCompositionStepKind.backgroundEntities,
          MapVisualCompositionStepKind.foregroundTilesAndPlacedElements,
          MapVisualCompositionStepKind.foregroundEntities,
          MapVisualCompositionStepKind.collisionOverlay,
        ]),
      );
      expect(
        () => plan.steps.add(
          const MapVisualCompositionStep(
            MapVisualCompositionStepKind.shadows,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
