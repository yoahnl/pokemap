import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_layer_paint_order.dart';

void main() {
  group('runtime visual composition adapter', () {
    test('delegates absent-config maps to legacy core semantics', () {
      const map = MapData(
        id: 'legacy',
        name: 'Legacy',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(id: 'tile', name: 'Tile'),
          PathLayer(id: 'path', name: 'Path'),
          TerrainLayer(id: 'terrain', name: 'Terrain'),
          CollisionLayer(id: 'collision', name: 'Collision'),
        ],
      );

      final runtimePlan = buildRuntimeMapLayerPaintOrder(map);

      _expectMatchesCorePlan(runtimePlan, map);
      expect(
        runtimePlan.semantics,
        MapVisualCompositionSemantics.legacyRuntimeV1,
      );
      expect(
        runtimePlan.strategy,
        MapVisualCompositionStrategy.legacyPhased,
      );
    });

    test('delegates configured maps to canonical core semantics', () {
      const map = MapData(
        id: 'canonical',
        name: 'Canonical',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v3,
        visualStack: MapVisualStackConfig.canonicalV1,
        properties: <String, dynamic>{
          'tileLayerOrder': 'bottom_to_top',
        },
        layers: <MapLayer>[
          SurfaceLayer(id: 'top-surface', name: 'Top surface'),
          BorderLayer(
            id: 'hidden-border',
            name: 'Hidden Border',
            isVisible: false,
          ),
          TileLayer(id: 'bottom-tile', name: 'Bottom tile'),
        ],
      );

      final runtimePlan = buildRuntimeMapLayerPaintOrder(map);

      _expectMatchesCorePlan(runtimePlan, map);
      expect(
        runtimePlan.semantics,
        MapVisualCompositionSemantics.canonicalV1,
      );
      expect(
        runtimePlan.strategy,
        MapVisualCompositionStrategy.authoredStack,
      );
      expect(
        runtimePlan.authoredLayerSteps.map((step) => step.stableKey),
        const <String>[
          'tileBackgroundLayer:bottom-tile',
          'surfaceLayer:top-surface',
        ],
      );
    });

    test('turns unsupported future semantics into an explicit load failure',
        () {
      final map = MapData(
        id: 'future',
        name: 'Future',
        size: const GridSize(width: 1, height: 1),
        version: ProjectVersion.v3,
        visualStack: MapVisualStackConfig(semanticsVersion: 99),
        layers: const <MapLayer>[
          TileLayer(id: 'tile', name: 'Tile'),
        ],
      );
      final coreResult = buildMapVisualCompositionPlan(map);

      expect(coreResult.requiresReadOnly, isTrue);
      expect(coreResult.plan, isNull);
      expect(
        () => buildRuntimeMapLayerPaintOrder(map),
        throwsA(
          isA<MapLoadException>()
              .having(
                (error) => error.message,
                'message',
                contains(coreResult.diagnostics.single.message),
              )
              .having(
                (error) => error.message,
                'message',
                contains('Map future cannot be composed'),
              ),
        ),
      );
    });
  });
}

void _expectMatchesCorePlan(
  MapVisualCompositionPlan runtimePlan,
  MapData map,
) {
  final corePlan = buildMapVisualCompositionPlan(map).plan!;

  expect(runtimePlan.semantics, corePlan.semantics);
  expect(runtimePlan.strategy, corePlan.strategy);
  expect(
    runtimePlan.steps.map((step) => step.stableKey),
    corePlan.steps.map((step) => step.stableKey),
  );
  expect(
    runtimePlan.visibleTileLayersInPaintOrder.map((layer) => layer.id),
    corePlan.visibleTileLayersInPaintOrder.map((layer) => layer.id),
  );
  expect(
    runtimePlan.visibleCollisionLayersInPaintOrder.map((layer) => layer.id),
    corePlan.visibleCollisionLayersInPaintOrder.map((layer) => layer.id),
  );
}
