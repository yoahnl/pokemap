import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_selection_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('MapSelectionController', () {
    const controller = MapSelectionController();

    test('selectTool activates Smart Tile painting without legacy state', () {
      const current = EditorState(
        activeTool: EditorToolType.selection,
      );

      final next = controller.selectTool(
        current: current,
        tool: EditorToolType.terrainPaint,
      );

      expect(next.activeTool, EditorToolType.terrainPaint);
    });

    test('coerceActiveToolIfIncompatibleWithLayer falls back to selection', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          SmartTileLayer(
            id: 'ground',
            name: 'Ground',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(semanticCells: <int>[]),
          ),
        ],
      );
      const current = EditorState(
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
      );

      final next = controller.coerceActiveToolIfIncompatibleWithLayer(current);

      expect(next.activeTool, EditorToolType.selection);
    });

    test('Smart Tile paint is compatible only with SmartTileLayer', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        version: ProjectVersion.v6,
        size: GridSize(width: 4, height: 4),
        layers: [
          SmartTileLayer(
            id: 'surface',
            name: 'Surfaces',
            presetId: 'forest',
            usage: SmartTileUsage.forestSurface,
            field: SmartTileField.cell(semanticCells: <int>[]),
          ),
          TileLayer(id: 'tiles', name: 'Tiles'),
        ],
      );

      const surfaceState = EditorState(
        activeMap: map,
        activeLayerId: 'surface',
        activeTool: EditorToolType.terrainPaint,
      );
      const groundState = EditorState(
        activeMap: map,
        activeLayerId: 'tiles',
        activeTool: EditorToolType.terrainPaint,
      );

      expect(
        controller
            .coerceActiveToolIfIncompatibleWithLayer(surfaceState)
            .activeTool,
        EditorToolType.terrainPaint,
      );
      expect(
        controller
            .coerceActiveToolIfIncompatibleWithLayer(groundState)
            .activeTool,
        EditorToolType.selection,
      );
    });

    test('Border paint and erase stay outside the generic eraser flow', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        version: ProjectVersion.v6,
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          MapLayer.border(id: 'border', name: 'Bordures'),
          MapLayer.collision(id: 'collision', name: 'Collision'),
        ],
      );

      for (final tool in <EditorToolType>[
        EditorToolType.borderPaint,
        EditorToolType.borderErase,
      ]) {
        final borderState = EditorState(
          activeMap: map,
          activeLayerId: 'border',
          activeTool: tool,
        );
        final collisionState = EditorState(
          activeMap: map,
          activeLayerId: 'collision',
          activeTool: tool,
        );
        expect(
          controller
              .coerceActiveToolIfIncompatibleWithLayer(borderState)
              .activeTool,
          tool,
        );
        expect(
          controller
              .coerceActiveToolIfIncompatibleWithLayer(collisionState)
              .activeTool,
          EditorToolType.selection,
        );
      }

      const genericEraser = EditorState(
        activeMap: map,
        activeLayerId: 'border',
        activeTool: EditorToolType.eraser,
      );
      expect(
        controller
            .coerceActiveToolIfIncompatibleWithLayer(genericEraser)
            .activeTool,
        EditorToolType.selection,
      );
    });
  });
}
