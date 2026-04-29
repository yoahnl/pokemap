import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorState grouped views', () {
    test('exposes coherent grouped snapshots', () {
      const map = MapData(
        id: 'map_001',
        name: 'Starter Town',
        size: GridSize(width: 10, height: 8),
        layers: [],
      );
      const snapshot = MapHistorySnapshot(
        map: map,
        activeLayerId: 'ground',
      );
      const state = EditorState(
        projectRootPath: '/tmp/demo',
        project: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
          name: 'Demo',
          maps: [],
          tilesets: [],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        workspaceMode: EditorWorkspaceMode.dialogue,
        activeMap: map,
        activeMapPath: 'maps/map_001.json',
        activeTool: EditorToolType.terrainPaint,
        activeLayerId: 'ground',
        hoveredTile: GridPos(x: 2, y: 3),
        terrainSelectionMode: TerrainSelectionMode.path,
        selectedTerrainType: TerrainType.rock,
        selectedTerrainPresetId: 'terrain-water',
        selectedPathPresetId: 'path-road',
        selectedTerrainPresetByType: {
          TerrainType.rock: 'terrain-water',
        },
        selectedEntityId: 'npc_1',
        selectedMapEventId: 'event_1',
        selectedTrainerId: 'trainer_1',
        zoom: 2.0,
        panOffset: Offset(12, 18),
        mapUndoStack: [snapshot],
        savedMapSnapshot: map,
        canUndoMap: true,
        isDirty: true,
        statusMessage: 'Ready',
      );

      expect(state.projectSession.projectRootPath, '/tmp/demo');
      expect(state.projectSession.workspaceMode, EditorWorkspaceMode.dialogue);
      expect(state.projectSession.activeMapPath, 'maps/map_001.json');

      expect(state.selection.activeTool, EditorToolType.terrainPaint);
      expect(state.selection.terrainSelectionMode, TerrainSelectionMode.path);
      expect(state.selection.selectedTerrainType, TerrainType.rock);
      expect(state.selection.selectedPathPresetId, 'path-road');
      expect(state.selection.selectedTrainerId, 'trainer_1');

      expect(state.viewport.zoom, 2.0);
      expect(state.viewport.panOffset, const Offset(12, 18));

      expect(state.documentStatus.mapUndoStack, [snapshot]);
      expect(state.documentStatus.savedMapSnapshot, map);
      expect(state.documentStatus.canUndoMap, isTrue);
      expect(state.documentStatus.isDirty, isTrue);
      expect(state.documentStatus.statusMessage, 'Ready');
    });

    test('copy helpers round-trip a grouped update back into EditorState', () {
      const initial = EditorState(
        projectRootPath: '/tmp/old',
        workspaceMode: EditorWorkspaceMode.map,
        zoom: 1.0,
      );

      final updated = initial
          .copyWithProjectSession(
            const EditorProjectSessionState(
              projectRootPath: '/tmp/new',
              project: null,
              workspaceMode: EditorWorkspaceMode.pokedex,
              activeMap: null,
              activeMapPath: 'maps/new.json',
            ),
          )
          .copyWithSelection(
            const EditorSelectionState(
              activeTool: EditorToolType.entityPlacement,
              activeLayerId: 'entities',
              hoveredTile: null,
              activeBrush: EditorBrush.none(),
              terrainSelectionMode: TerrainSelectionMode.terrain,
              selectedTerrainType: TerrainType.grass,
              selectedEntityKind: MapEntityKind.custom,
              selectedTerrainPresetId: null,
              selectedPathPresetId: null,
              selectedSurfacePresetId: null,
              selectedTerrainPresetByType: {},
              collisionBrushSizeMode: CollisionBrushSizeMode.singleTile,
              selectedEntityId: 'entity_7',
              npcWaypointPlacementEntityId: null,
              selectedMapEventId: null,
              selectedWarpId: null,
              selectedTriggerId: null,
              selectedGameplayZoneId: null,
              gameplayZoneDraftArea: null,
              selectedTilesetEditorId: 'tileset_world',
              selectedTilesetElementGroupId: null,
              tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
              selectedPlacedElementInstanceId: 'placed_1',
              selectedProjectDialogueId: null,
              selectedTrainerId: null,
              selectedCharacterId: null,
              paletteCategoryFilter: null,
            ),
          )
          .copyWithViewport(
            const EditorViewportState(
              zoom: 3.0,
              panOffset: Offset(40, 24),
            ),
          )
          .copyWithDocumentStatus(
            const EditorDocumentStatusState(
              mapUndoStack: [],
              mapRedoStack: [],
              mapStrokeStart: null,
              savedMapSnapshot: null,
              canUndoMap: false,
              canRedoMap: false,
              isDirty: true,
              isSaving: false,
              statusMessage: 'Updated',
              errorMessage: null,
            ),
          );

      expect(updated.projectRootPath, '/tmp/new');
      expect(updated.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(updated.activeMapPath, 'maps/new.json');
      expect(updated.activeTool, EditorToolType.entityPlacement);
      expect(updated.selectedEntityKind, MapEntityKind.custom);
      expect(updated.selectedTilesetEditorId, 'tileset_world');
      expect(updated.tilesElementsPanelMode,
          TilesElementsPanelMode.placedInstances);
      expect(updated.zoom, 3.0);
      expect(updated.panOffset, const Offset(40, 24));
      expect(updated.isDirty, isTrue);
      expect(updated.statusMessage, 'Updated');
    });
  });
}
