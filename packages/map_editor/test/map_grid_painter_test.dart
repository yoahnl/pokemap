import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  group('MapGridPainter foreground split helpers', () {
    test(
        'marks only non-collision cells of multi-tile placed elements as foreground',
        () {
      const map = MapData(
        id: 'lab',
        name: 'lab',
        size: GridSize(width: 3, height: 2),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tiles: <int>[
              1,
              1,
              0,
              1,
              1,
              0,
            ],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'table_1',
            layerId: 'ground',
            elementId: 'table',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'table',
            name: 'Table',
            tilesetId: 'interior',
            categoryId: 'decor',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              cells: <GridPos>[
                GridPos(x: 0, y: 0),
                GridPos(x: 1, y: 0),
              ],
            ),
          ),
        ],
      );

      final result = buildEditorForegroundTileCellIndicesByLayerId(
        map: map,
        project: project,
      );

      expect(result['ground'], equals(<int>{3, 4}));
    });

    test('routes split cells to the correct render pass deterministically', () {
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: false,
          isForegroundCell: false,
          foregroundPass: false,
        ),
        isTrue,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: false,
          isForegroundCell: true,
          foregroundPass: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: false,
          isForegroundCell: true,
          foregroundPass: true,
        ),
        isTrue,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: true,
          isForegroundCell: false,
          foregroundPass: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: true,
          isForegroundCell: false,
          foregroundPass: true,
        ),
        isTrue,
      );
    });

    test('routes project-element entities to the requested render pass', () {
      const normalEntity = MapEntity(
        id: 'pokeball',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
        editorVisual: MapEntityEditorVisual(elementId: 'pokeball'),
      );
      const foregroundEntity = MapEntity(
        id: 'pokeball_top',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
        editorVisual: MapEntityEditorVisual(
          elementId: 'pokeball',
          renderInForeground: true,
        ),
      );

      expect(
        shouldPaintEditorEntityInForegroundPass(
          normalEntity,
          foregroundPass: false,
        ),
        isTrue,
      );
      expect(
        shouldPaintEditorEntityInForegroundPass(
          normalEntity,
          foregroundPass: true,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorEntityInForegroundPass(
          foregroundEntity,
          foregroundPass: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorEntityInForegroundPass(
          foregroundEntity,
          foregroundPass: true,
        ),
        isTrue,
      );
    });
  });
}
