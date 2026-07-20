import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart';

void main() {
  group('buildEditorMapLayerPaintOrder', () {
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

    test('keeps deferred legacy sentinels explicit and collision read-only',
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
        plan.deferredSentinels,
        const <EditorMapDeferredPaintSentinel>[
          EditorMapDeferredPaintSentinel.projectedShadows,
          EditorMapDeferredPaintSentinel.staticShadows,
          EditorMapDeferredPaintSentinel.backgroundPlacedElements,
          EditorMapDeferredPaintSentinel.collisionOverlay,
          EditorMapDeferredPaintSentinel.gridOverlay,
          EditorMapDeferredPaintSentinel.backgroundEntities,
          EditorMapDeferredPaintSentinel.foregroundTilesAndPlacedElements,
          EditorMapDeferredPaintSentinel.foregroundEntities,
          EditorMapDeferredPaintSentinel.editorOverlays,
        ],
      );
      expect(plan.collisionOverlayLayers.single.id, 'collision');
    });
  });
}
