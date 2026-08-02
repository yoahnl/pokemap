import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart';

void main() {
  group('buildEditorMapLayerPaintOrder', () {
    test(
        'canonical v1 paints the authored top-first stack bottom-to-top '
        'without Border selecting semantics', () {
      final withoutBorder = buildEditorMapLayerPaintOrder(
        const MapData(
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
            TileLayer(id: 'middle-tiles', name: 'Middle tiles'),
            TerrainLayer(id: 'bottom-terrain', name: 'Bottom terrain'),
          ],
        ),
      );
      final withHiddenBorder = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'canonical-border',
          name: 'Canonical with hidden Border',
          size: GridSize(width: 1, height: 1),
          version: ProjectVersion.v3,
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: <MapLayer>[
            SurfaceLayer(id: 'top-surface', name: 'Top surface'),
            BorderLayer(
              id: 'hidden-border',
              name: 'Hidden Border',
              isVisible: false,
            ),
            TileLayer(id: 'middle-tiles', name: 'Middle tiles'),
            TerrainLayer(id: 'bottom-terrain', name: 'Bottom terrain'),
          ],
        ),
      );

      expect(
        withoutBorder.authoredLayers.map((entry) => entry.layer.id),
        const <String>['bottom-terrain', 'middle-tiles', 'top-surface'],
      );
      expect(
        withHiddenBorder.authoredLayers.map((entry) => entry.layer.id),
        const <String>['bottom-terrain', 'middle-tiles', 'top-surface'],
      );
    });

    test('future visual semantics are read-only and never use legacy order',
        () {
      final result = buildEditorMapLayerPaintOrderResult(
        MapData(
          id: 'future',
          name: 'Future',
          size: const GridSize(width: 1, height: 1),
          version: ProjectVersion.v3,
          visualStack: MapVisualStackConfig(semanticsVersion: 99),
          layers: const <MapLayer>[
            TileLayer(id: 'tiles', name: 'Tiles'),
          ],
        ),
      );

      expect(result.requiresReadOnly, isTrue);
      expect(result.order, isNull);
      expect(result.diagnostics, isNotEmpty);
    });

    test('uses authored bottom-to-top order for every visual layer kind', () {
      final plan = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'modern',
          name: 'Modern',
          size: GridSize(width: 1, height: 1),
          properties: <String, dynamic>{
            'tileLayerOrder': 'bottom_to_top',
          },
          layers: <MapLayer>[
            TerrainLayer(id: 'terrain', name: 'Terrain'),
            CollisionLayer(id: 'collision-low', name: 'Collision low'),
            PathLayer(id: 'path', name: 'Path'),
            BorderLayer(id: 'coast-low', name: 'Coast low'),
            SurfaceLayer(id: 'surface', name: 'Surface'),
            TileLayer(id: 'tiles', name: 'Tiles'),
            ObjectLayer(id: 'objects', name: 'Objects'),
            EnvironmentLayer(id: 'environment', name: 'Environment'),
            BorderLayer(id: 'coast-high', name: 'Coast high'),
            CollisionLayer(id: 'collision-high', name: 'Collision high'),
          ],
        ),
      );

      expect(
        plan.authoredLayers
            .map((entry) => '${entry.kind.name}:${entry.layer.id}'),
        const <String>[
          'terrain:terrain',
          'path:path',
          'border:coast-low',
          'surface:surface',
          'tileBackground:tiles',
          'objectNoop:objects',
          'environmentNoop:environment',
          'border:coast-high',
        ],
      );
      expect(
        plan.collisionOverlayLayers.map((layer) => layer.id),
        const <String>['collision-high', 'collision-low'],
        reason: 'collision remains the historical reverse-order sentinel',
      );
    });

    test('exposes Smart Tile layers in authored bottom-to-top paint order', () {
      final plan = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'smart-tiles',
          name: 'Smart Tiles',
          version: ProjectVersion.v5,
          visualStack: MapVisualStackConfig.canonicalV1,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            SmartTileLayer(
              id: 'smart-top',
              name: 'Smart top',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
            SmartTileLayer(
              id: 'smart-bottom',
              name: 'Smart bottom',
              presetId: 'path',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
          ],
        ),
      );

      expect(
        plan.authoredLayers
            .map((entry) => '${entry.kind.name}:${entry.layer.id}'),
        const <String>[
          'smartTile:smart-bottom',
          'smartTile:smart-top',
        ],
      );
    });

    test('preserves reverse visual order for legacy maps and skips hidden', () {
      final plan = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'legacy',
          name: 'Legacy',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TerrainLayer(id: 'terrain', name: 'Terrain'),
            BorderLayer(id: 'hidden', name: 'Hidden', isVisible: false),
            TileLayer(id: 'tiles', name: 'Tiles'),
            BorderLayer(id: 'border', name: 'Border'),
          ],
        ),
      );

      expect(
        plan.authoredLayers.map((entry) => entry.layer.id),
        const <String>['border', 'tiles', 'terrain'],
      );
    });

    test('uses shared core steps for deferred passes and collision read-only',
        () {
      final plan = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'sentinels',
          name: 'Sentinels',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            CollisionLayer(id: 'collision', name: 'Collision'),
          ],
        ),
      );

      expect(plan.authoredLayers, isEmpty);
      expect(
        plan.compositionPlan.steps.map((step) => step.kind),
        const <MapVisualCompositionStepKind>[
          MapVisualCompositionStepKind.shadows,
          MapVisualCompositionStepKind.backgroundEntities,
          MapVisualCompositionStepKind.collisionOverlay,
          MapVisualCompositionStepKind.foregroundTilesAndPlacedElements,
          MapVisualCompositionStepKind.foregroundEntities,
        ],
      );
      expect(plan.collisionOverlayLayers.single.id, 'collision');
    });
  });
}
