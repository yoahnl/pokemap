import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('editor selectors', () {
    test('editorShellSnapshotProvider derives map title and save affordance',
        () {
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
      expect(shell.workspaceSubtitle, contains('12 × 8 tuiles'));
      expect(shell.canUndoMap, isTrue);
      expect(shell.canSaveMap, isTrue);
    });

    test('editorToolbarSnapshotProvider resolves selected tileset from layer',
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
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
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
        eraserFootprint: EditorEraserFootprint.custom(
          size: GridSize(width: 3, height: 2),
        ),
      );

      final toolbar = container.read(editorToolbarSnapshotProvider);
      expect(toolbar.selectedTilesetEntry?.id, 'world');
      expect(toolbar.activeLayer, isA<TileLayer>());
      expect(
        toolbar.eraserFootprint,
        const EditorEraserFootprint.custom(
          size: GridSize(width: 3, height: 2),
        ),
      );
    });

    test('map selectors do not let the Tileset Studio choice outrank the layer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        selectedTilesetEditorId: 'details',
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.png',
            ),
            ProjectTilesetEntry(
              id: 'details',
              name: 'Details',
              relativePath: 'tilesets/details.png',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Town',
          size: GridSize(width: 4, height: 4),
          layers: <MapLayer>[
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

      final palette = container.read(editorTilesetPaletteSnapshotProvider);
      expect(palette.selectedTilesetEntry?.id, 'world');
    });

    test(
        'an unassigned map layer never falls back to the Tileset Studio source',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        selectedTilesetEditorId: 'studio_only',
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'studio_only',
              name: 'Studio only',
              relativePath: 'tilesets/studio.png',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Town',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tiles: <int>[0],
            ),
          ],
        ),
        activeLayerId: 'ground',
      );

      final palette = container.read(editorTilesetPaletteSnapshotProvider);
      expect(palette.selectedTilesetEntry, isNull);
      expect(
        container
            .read(editorNotifierProvider.notifier)
            .getSelectedTilesetEntry(),
        isNull,
      );
    });

    test('Path Studio snapshots hide map save and history actions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pathStudio,
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [],
        ),
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
        isProjectDirty: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      final toolbar = container.read(editorToolbarSnapshotProvider);

      expect(shell.canSaveMap, isFalse);
      expect(shell.canUndoMap, isFalse);
      expect(shell.canRedoMap, isFalse);
      expect(toolbar.canSaveMap, isFalse);
      expect(toolbar.canUndoMap, isFalse);
      expect(toolbar.canRedoMap, isFalse);
      expect(toolbar.isProjectDirty, isTrue);
    });

    test('active map strokes hide save and history actions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const map = MapData(
        id: 'town',
        name: 'Starter Town',
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[],
      );
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        mapStrokeStart: MapHistorySnapshot(map: map),
        canUndoMap: true,
        canRedoMap: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      final toolbar = container.read(editorToolbarSnapshotProvider);

      expect(shell.canSaveMap, isFalse);
      expect(shell.canUndoMap, isFalse);
      expect(shell.canRedoMap, isFalse);
      expect(toolbar.canSaveMap, isFalse);
      expect(toolbar.canUndoMap, isFalse);
      expect(toolbar.canRedoMap, isFalse);
    });

    test('editorProjectExplorerSnapshotProvider exposes active map selection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.items,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
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
      expect(snapshot.pokemonCatalogSection, PokemonCatalogSection.items);
      expect(snapshot.activeMapId, 'town');
      expect(snapshot.project?.name, 'demo');
    });

    test('editorShellSnapshotProvider exposes trainer studio labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.trainer,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Trainer Studio');
      expect(
        shell.workspaceSubtitle,
        contains('prêtes au combat'),
      );
    });

    test('editorShellSnapshotProvider exposes Pokémon catalogs labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Catalogues Pokémon');
      expect(shell.workspaceSubtitle, contains('Pokédex, Moves et Items'));
    });

    test('editorShellSnapshotProvider exposes clean Environment Studio labels',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.environmentStudio,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Environment Studio');
      expect(
        shell.workspaceSubtitle,
        'Presets d’environnements réutilisables',
      );
      expect(shell.workspaceSubtitle, isNot(contains('shell read-only')));
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
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
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

    test('editorTilesetPaletteSnapshotProvider exposes palette panel state',
        () {
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
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
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
