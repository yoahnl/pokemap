import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/application/services/terrain_preset_selection_coordinator.dart';
import 'package:map_editor/src/features/editor/application/project_session_controller.dart';
import 'package:map_editor/src/features/editor/application/project_session_models.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('ProjectSessionController', () {
    const controller = ProjectSessionController();

    test('openProjectSession resets document and transient selections', () {
      const state = EditorState(
        projectRootPath: '/tmp/old',
        workspaceMode: EditorWorkspaceMode.dialogue,
        activeMapPath: 'maps/old.json',
        activeLayerId: 'ground',
        activeTool: EditorToolType.entityPlacement,
        selectedEntityId: 'npc_1',
        selectedMapEventId: 'event_1',
        selectedProjectDialogueId: 'dlg_1',
        mapUndoStack: [],
        mapRedoStack: [],
        canUndoMap: true,
        isDirty: true,
        errorMessage: 'Old error',
      );

      const updated = ProjectManifest(
        name: 'Demo',
        maps: [],
        tilesets: [],
      );

      final next = controller.openProjectSession(
        current: state,
        session: const ProjectSessionLoadResult(
          projectRootPath: '/tmp/new',
          project: updated,
          presetSelection: TerrainPresetSelection(
            selectionMode: TerrainSelectionMode.terrain,
            selectedTerrainType: TerrainType.grass,
            selectedTerrainPresetId: 'grass-a',
            selectedPathPresetId: 'path-a',
            selectedTerrainPresetByType: {},
          ),
        ),
        statusMessage: 'Loaded',
      );

      expect(next.projectRootPath, '/tmp/new');
      expect(next.project, updated);
      expect(next.workspaceMode, EditorWorkspaceMode.map);
      expect(next.activeMap, isNull);
      expect(next.activeMapPath, isNull);
      expect(next.activeLayerId, isNull);
      expect(next.selectedEntityId, isNull);
      expect(next.selectedMapEventId, isNull);
      expect(next.selectedProjectDialogueId, isNull);
      expect(next.selectedTerrainPresetId, 'grass-a');
      expect(next.selectedPathPresetId, 'path-a');
      expect(next.isDirty, isFalse);
      expect(next.errorMessage, isNull);
      expect(next.statusMessage, 'Loaded');
    });

    test('openMapDocument swaps the active document and resets history', () {
      const current = EditorState(
        projectRootPath: '/tmp/demo',
        activeTool: EditorToolType.tilePaint,
        selectedEntityId: 'npc_1',
        selectedMapEventId: 'event_1',
        mapUndoStack: [],
        mapRedoStack: [],
        isDirty: true,
      );
      const map = MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 8, height: 8),
        layers: [
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'tileset_world',
            tiles: [],
          ),
        ],
      );

      final next = controller.openMapDocument(
        current: current,
        document: const MapDocumentLoadResult(
          map: map,
          activeMapPath: '/tmp/demo/maps/town.json',
          presetSelection: TerrainPresetSelection(
            selectionMode: TerrainSelectionMode.path,
            selectedTerrainType: TerrainType.rock,
            selectedTerrainPresetId: 'rock-a',
            selectedPathPresetId: 'path-road',
            selectedTerrainPresetByType: {},
          ),
          selectedTilesetEditorId: 'tileset_world',
        ),
        statusMessage: 'Map loaded',
      );

      expect(next.activeMap, map);
      expect(next.activeMapPath, '/tmp/demo/maps/town.json');
      expect(next.workspaceMode, EditorWorkspaceMode.map);
      expect(next.activeLayerId, 'ground');
      expect(next.selectedEntityId, isNull);
      expect(next.selectedMapEventId, isNull);
      expect(next.selectedTilesetEditorId, 'tileset_world');
      expect(next.selectedPathPresetId, 'path-road');
      expect(next.savedMapSnapshot, map);
      expect(next.isDirty, isFalse);
      expect(next.statusMessage, 'Map loaded');
    });

    test('afterMapRenamed resets history when the active document changed id',
        () {
      const map = MapData(
        id: 'old_map',
        name: 'Old Map',
        size: GridSize(width: 4, height: 4),
        layers: [],
      );
      const state = EditorState(
        project: ProjectManifest(
          name: 'Demo',
          maps: [],
          tilesets: [],
        ),
        activeMap: map,
        activeMapPath: '/tmp/demo/maps/old_map.json',
        savedMapSnapshot: map,
        mapUndoStack: [
          MapHistorySnapshot(map: map),
        ],
        canUndoMap: true,
        isDirty: true,
      );

      final next = controller.afterMapRenamed(
        current: state,
        updatedProject: const ProjectManifest(
          name: 'Demo',
          maps: [],
          tilesets: [],
        ),
        oldId: 'old_map',
        newId: 'new_map',
        newPath: '/tmp/demo/maps/new_map.json',
        statusMessage: 'Renamed',
      );

      expect(next.activeMap?.id, 'new_map');
      expect(next.activeMapPath, '/tmp/demo/maps/new_map.json');
      expect(next.mapUndoStack, isEmpty);
      expect(next.canUndoMap, isFalse);
      expect(next.isDirty, isFalse);
      expect(next.statusMessage, 'Renamed');
    });

    test('afterMapDeleted clears the active document when it was selected', () {
      const map = MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 4, height: 4),
        layers: [],
      );
      const state = EditorState(
        project: ProjectManifest(
          name: 'Demo',
          maps: [],
          tilesets: [],
        ),
        activeMap: map,
        activeMapPath: '/tmp/demo/maps/town.json',
        activeLayerId: 'ground',
        selectedEntityId: 'npc_1',
        selectedWarpId: 'warp_1',
        selectedTriggerId: 'trigger_1',
        selectedMapEventId: 'event_1',
        selectedTilesetEditorId: 'tileset_world',
        mapUndoStack: [MapHistorySnapshot(map: map)],
        savedMapSnapshot: map,
        canUndoMap: true,
        isDirty: true,
      );

      final next = controller.afterMapDeleted(
        current: state,
        updatedProject: const ProjectManifest(
          name: 'Demo',
          maps: [],
          tilesets: [],
        ),
        deletedMapId: 'town',
        statusMessage: 'Deleted',
      );

      expect(next.activeMap, isNull);
      expect(next.activeMapPath, isNull);
      expect(next.activeLayerId, isNull);
      expect(next.selectedEntityId, isNull);
      expect(next.selectedWarpId, isNull);
      expect(next.selectedTriggerId, isNull);
      expect(next.selectedMapEventId, isNull);
      expect(next.selectedTilesetEditorId, isNull);
      expect(next.mapUndoStack, isEmpty);
      expect(next.savedMapSnapshot, isNull);
      expect(next.canUndoMap, isFalse);
      expect(next.isDirty, isFalse);
      expect(next.statusMessage, 'Deleted');
    });
  });
}
