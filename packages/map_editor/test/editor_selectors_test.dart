import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('editor selectors', () {
    test('editorShellSnapshotProvider derives map title and save affordance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 12, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        canUndoMap: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Starter Town');
      expect(shell.workspaceSubtitle, contains('12 x 8 tiles'));
      expect(shell.canUndoMap, isTrue);
      expect(shell.canSaveMap, isTrue);
    });

    test('editorToolbarSnapshotProvider resolves selected tileset from layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
      );

      final toolbar = container.read(editorToolbarSnapshotProvider);
      expect(toolbar.selectedTilesetEntry?.id, 'world');
      expect(toolbar.activeLayer, isA<TileLayer>());
    });

    test('editorProjectExplorerSnapshotProvider exposes active map selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [],
        ),
      );

      final snapshot = container.read(editorProjectExplorerSnapshotProvider);
      expect(snapshot.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(snapshot.activeMapId, 'town');
      expect(snapshot.project?.name, 'demo');
    });

    test('editorTerrainLibrarySnapshotProvider exposes preset selection inputs',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        selectedTerrainType: TerrainType.grass,
        selectedTerrainPresetId: 'terrain.grass',
        selectedPathPresetId: 'path.route',
      );

      final snapshot = container.read(editorTerrainLibrarySnapshotProvider);
      expect(snapshot.project?.name, 'demo');
      expect(snapshot.tilesets.map((entry) => entry.id), ['world']);
      expect(snapshot.selectedTerrainPresetId, 'terrain.grass');
      expect(snapshot.selectedPathPresetId, 'path.route');
    });

    test('editorTilesetPaletteSnapshotProvider exposes palette panel state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/project',
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
        activeBrush: EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        paletteCategoryFilter: PaletteCategory.floors,
        selectedTilesetElementGroupId: 'group_a',
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
        selectedPlacedElementInstanceId: 'instance_1',
      );

      final snapshot = container.read(editorTilesetPaletteSnapshotProvider);
      expect(snapshot.selectedTilesetEntry?.id, 'world');
      expect(snapshot.projectRootPath, '/tmp/project');
      expect(snapshot.activeLayerId, 'ground');
      expect(snapshot.paletteCategoryFilter, PaletteCategory.floors);
      expect(
        snapshot.tilesElementsPanelMode,
        TilesElementsPanelMode.placedInstances,
      );
      expect(snapshot.selectedPlacedElementInstanceId, 'instance_1');
    });
  });
}
