import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/application/services/terrain_preset_resolver.dart';
import 'package:map_editor/src/application/services/terrain_preset_selection_coordinator.dart';
import 'package:map_editor/src/features/editor/application/map_selection_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('MapSelectionController', () {
    const controller = MapSelectionController(
      terrainPresetSelectionCoordinator: TerrainPresetSelectionCoordinator(
        resolver: TerrainPresetResolver(),
      ),
    );

    test('selectTool derives path terrain mode from the active layer', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          PathLayer(id: 'path', name: 'Path'),
        ],
      );
      const current = EditorState(
        activeMap: map,
        activeLayerId: 'path',
        activeTool: EditorToolType.selection,
        terrainSelectionMode: TerrainSelectionMode.terrain,
      );

      final next = controller.selectTool(
        current: current,
        tool: EditorToolType.terrainPaint,
      );

      expect(next.activeTool, EditorToolType.terrainPaint);
      expect(next.terrainSelectionMode, TerrainSelectionMode.path);
    });

    test('selectTerrainPreset activates terrain paint and updates selection',
        () {
      const current = EditorState(
        activeTool: EditorToolType.selection,
        selectedTerrainType: TerrainType.grass,
      );
      const preset = ProjectTerrainPreset(
        id: 'rock_a',
        name: 'Rock A',
        terrainType: TerrainType.rock,
      );

      final next = controller.selectTerrainPreset(
        current: current,
        preset: preset,
      );

      expect(next.activeTool, EditorToolType.terrainPaint);
      expect(next.terrainSelectionMode, TerrainSelectionMode.terrain);
      expect(next.selectedTerrainType, TerrainType.rock);
      expect(next.selectedTerrainPresetId, 'rock_a');
      expect(next.statusMessage, 'Terrain preset: Rock A');
      expect(next.errorMessage, isNull);
    });

    test('selectPathPaintMode without preset keeps explicit path mode', () {
      const current = EditorState(
        activeTool: EditorToolType.selection,
        selectedTerrainType: TerrainType.grass,
        selectedTerrainPresetId: 'grass_a',
      );

      final next = controller.selectPathPaintMode(
        current: current,
        selectedPathPreset: null,
      );

      expect(next.activeTool, EditorToolType.terrainPaint);
      expect(next.terrainSelectionMode, TerrainSelectionMode.path);
      expect(next.selectedTerrainPresetId, 'grass_a');
      expect(next.statusMessage, 'Path paint mode');
    });

    test('coerceActiveToolIfIncompatibleWithLayer falls back to selection', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          TerrainLayer(id: 'ground', name: 'Ground'),
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

    test('surface paint is compatible only with SurfaceLayer', () {
      const map = MapData(
        id: 'map_1',
        name: 'Map 1',
        size: GridSize(width: 4, height: 4),
        layers: [
          SurfaceLayer(id: 'surface', name: 'Surfaces'),
          TerrainLayer(id: 'ground', name: 'Ground'),
        ],
      );

      const surfaceState = EditorState(
        activeMap: map,
        activeLayerId: 'surface',
        activeTool: EditorToolType.surfacePaint,
      );
      const groundState = EditorState(
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.surfacePaint,
      );

      expect(
        controller
            .coerceActiveToolIfIncompatibleWithLayer(surfaceState)
            .activeTool,
        EditorToolType.surfacePaint,
      );
      expect(
        controller
            .coerceActiveToolIfIncompatibleWithLayer(groundState)
            .activeTool,
        EditorToolType.selection,
      );
    });
  });
}
