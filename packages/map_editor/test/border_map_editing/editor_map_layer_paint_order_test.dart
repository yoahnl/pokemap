import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart';

void main() {
  group('buildEditorMapLayerPaintOrder', () {
    test(
        'canonical v6 paints the authored top-first stack bottom-to-top '
        'without Border selecting semantics', () {
      final withoutBorder = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'canonical',
          name: 'Canonical',
          size: GridSize(width: 1, height: 1),
          version: ProjectVersion.v6,
          visualStack: MapVisualStackConfig.canonicalV1,
          properties: <String, dynamic>{
            'tileLayerOrder': 'bottom_to_top',
          },
          layers: <MapLayer>[
            SmartTileLayer(
              id: 'top-surface',
              name: 'Top surface',
              presetId: 'forest',
              usage: SmartTileUsage.forestSurface,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
            TileLayer(id: 'middle-tiles', name: 'Middle tiles'),
            SmartTileLayer(
              id: 'bottom-terrain',
              name: 'Bottom terrain',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
          ],
        ),
      );
      final withHiddenBorder = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'canonical-border',
          name: 'Canonical with hidden Border',
          size: GridSize(width: 1, height: 1),
          version: ProjectVersion.v6,
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: <MapLayer>[
            SmartTileLayer(
              id: 'top-surface',
              name: 'Top surface',
              presetId: 'forest',
              usage: SmartTileUsage.forestSurface,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
            BorderLayer(
              id: 'hidden-border',
              name: 'Hidden Border',
              isVisible: false,
            ),
            TileLayer(id: 'middle-tiles', name: 'Middle tiles'),
            SmartTileLayer(
              id: 'bottom-terrain',
              name: 'Bottom terrain',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
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
          version: ProjectVersion.v6,
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

    test('can inspect an explicitly visible data layer in the editor', () {
      final plan = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'data-layer-inspection',
          name: 'Data layer inspection',
          size: GridSize(width: 1, height: 1),
          version: ProjectVersion.v6,
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: <MapLayer>[
            TileLayer(
              id: 'technical',
              name: 'Technical',
              purpose: MapLayerPurpose.data,
            ),
          ],
        ),
      );

      expect(plan.authoredLayers.single.layer.id, 'technical');
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
            SmartTileLayer(
              id: 'terrain',
              name: 'Terrain',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
            CollisionLayer(id: 'collision-low', name: 'Collision low'),
            SmartTileLayer(
              id: 'path',
              name: 'Path',
              presetId: 'path',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
            BorderLayer(id: 'coast-low', name: 'Coast low'),
            SmartTileLayer(
              id: 'surface',
              name: 'Surface',
              presetId: 'forest',
              usage: SmartTileUsage.forestSurface,
              field: SmartTileField.cell(semanticCells: <int>[0]),
            ),
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
          'smartTile:terrain',
          'smartTile:path',
          'border:coast-low',
          'smartTile:surface',
          'tileBackground:tiles',
          'objectLayer:objects',
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
          version: ProjectVersion.v6,
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

    test('uses shared core steps for deferred passes and collision read-only',
        () {
      final plan = buildEditorMapLayerPaintOrder(
        const MapData(
          id: 'sentinels',
          name: 'Sentinels',
          version: ProjectVersion.v6,
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
