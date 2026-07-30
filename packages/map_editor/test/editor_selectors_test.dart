import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/application/world_map_inspector_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

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

    test('asset browser snapshot exposes only active layer session inputs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const key = EditorPaletteContextKey(
        mapId: 'town',
        layerId: 'ground',
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: const ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        activeMap: const MapData(
          id: 'town',
          name: 'Town',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: <int>[0],
            ),
          ],
        ),
        activeLayerId: 'ground',
        paletteSession: EditorPaletteSession(
          activeKey: key,
          contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
            key: const EditorLayerPaletteContext(
              selectedTilesetId: 'details',
              browserQuery: 'arbres',
              browserCollection: EditorPaletteAssetCollection.favorites,
            ),
          },
          recentTilesetIds: <String>['world'],
          favoriteTilesetIds: <String>['details'],
        ),
      );

      final snapshot =
          container.read(editorMapPaletteAssetBrowserSnapshotProvider);

      expect(snapshot.activeMap?.id, 'town');
      expect(snapshot.activeLayerId, 'ground');
      expect(snapshot.assignedTilesetId, 'world');
      expect(snapshot.context.selectedTilesetId, 'details');
      expect(snapshot.context.browserQuery, 'arbres');
      expect(snapshot.recentTilesetIds, <String>['world']);
      expect(snapshot.favoriteTilesetIds, <String>['details']);
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

    test('editorWorldMapToolbarSnapshotProvider projects only toolbar inputs',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const map = MapData(
        id: 'town',
        name: 'Starter Town',
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[],
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
        ),
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.selection,
        canUndoMap: true,
        canRedoMap: true,
      );

      final snapshot = container.read(editorWorldMapToolbarSnapshotProvider);

      expect(snapshot.project?.name, 'demo');
      expect(snapshot.settings, const ProjectSettings());
      expect(snapshot.activeMap, map);
      expect(snapshot.activeLayer?.id, 'ground');
      expect(snapshot.activeTool, EditorToolType.selection);
      expect(snapshot.canSaveMap, isTrue);
      expect(snapshot.canUndoMap, isTrue);
      expect(snapshot.canRedoMap, isTrue);
    });

    test('world map toolbar snapshot ignores session and palette-only changes',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const key = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const map = MapData(
        id: 'town',
        name: 'Starter Town',
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[],
          ),
        ],
      );
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'ground',
          activeTool: EditorToolType.selection,
        );
      final emissions = <EditorWorldMapToolbarSnapshot>[];
      final subscription = container.listen<EditorWorldMapToolbarSnapshot>(
        editorWorldMapToolbarSnapshotProvider,
        (_, next) => emissions.add(next),
        fireImmediately: true,
      );

      container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .setInspectorVisible(false);
      notifier.state = notifier.state.copyWith(
        activeBrush: const EditorBrush.tile(
          tileId: 7,
          tilesetId: 'world',
        ),
        paletteSession: EditorPaletteSession(
          activeKey: key,
          contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
            key: const EditorLayerPaletteContext(
              browserQuery: 'arbres',
              browserCollection: EditorPaletteAssetCollection.favorites,
            ),
          },
        ),
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
      );
      await container.pump();

      expect(emissions, hasLength(1));

      notifier.state = notifier.state.copyWith(
        activeTool: EditorToolType.eraser,
      );
      await container.pump();

      expect(emissions, hasLength(2));
      expect(emissions.last.activeTool, EditorToolType.eraser);
      subscription.close();
    });

    test('world map brush kind stays narrow and covers every brush variant',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final emissions = <EditorWorldMapBrushKind>[];
      final subscription = container.listen<EditorWorldMapBrushKind>(
        editorWorldMapBrushKindProvider,
        (_, next) => emissions.add(next),
        fireImmediately: true,
      );

      for (final testCase
          in <({EditorBrush brush, EditorWorldMapBrushKind kind})>[
        (
          brush: const EditorBrush.tile(tileId: 1, tilesetId: 'world'),
          kind: EditorWorldMapBrushKind.tile,
        ),
        (
          brush: const EditorBrush.paletteEntry(
            entryId: 'tree',
            tilesetId: 'world',
          ),
          kind: EditorWorldMapBrushKind.paletteEntry,
        ),
        (
          brush: const EditorBrush.projectElement(elementId: 'tree'),
          kind: EditorWorldMapBrushKind.projectElement,
        ),
        (
          brush: const EditorBrush.none(),
          kind: EditorWorldMapBrushKind.none,
        ),
      ]) {
        notifier.state = notifier.state.copyWith(
          activeBrush: testCase.brush,
        );
        await container.pump();
        expect(
          container.read(editorWorldMapBrushKindProvider),
          testCase.kind,
        );
      }

      expect(
        emissions,
        <EditorWorldMapBrushKind>[
          EditorWorldMapBrushKind.none,
          EditorWorldMapBrushKind.tile,
          EditorWorldMapBrushKind.paletteEntry,
          EditorWorldMapBrushKind.projectElement,
          EditorWorldMapBrushKind.none,
        ],
      );
      subscription.close();
    });

    test('world map toolbar disables map commands outside map and in strokes',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const map = MapData(
        id: 'town',
        name: 'Starter Town',
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[],
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.state = const EditorState(
        workspaceMode: EditorWorkspaceMode.tileset,
        activeMap: map,
        canUndoMap: true,
        canRedoMap: true,
      );
      var snapshot = container.read(editorWorldMapToolbarSnapshotProvider);
      expect(snapshot.canSaveMap, isFalse);
      expect(snapshot.canUndoMap, isFalse);
      expect(snapshot.canRedoMap, isFalse);

      notifier.state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        mapStrokeStart: MapHistorySnapshot(map: map),
        canUndoMap: true,
        canRedoMap: true,
      );
      snapshot = container.read(editorWorldMapToolbarSnapshotProvider);
      expect(snapshot.canSaveMap, isFalse);
      expect(snapshot.canUndoMap, isFalse);
      expect(snapshot.canRedoMap, isFalse);

      notifier.state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        isSaving: true,
      );
      snapshot = container.read(editorWorldMapToolbarSnapshotProvider);
      expect(snapshot.canSaveMap, isFalse);
    });

    test(
        'world map document viewport interaction and inspector snapshots emit only for declared inputs',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const map = MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'tree-1',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 2, y: 3),
          ),
        ],
      );
      const project = ProjectManifest(
        name: 'Demo',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      const paletteKey = EditorPaletteContextKey(
        mapId: 'town',
        layerId: 'ground',
      );
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          projectRootPath: '/tmp/demo',
          project: project,
          activeMap: map,
          activeMapPath: 'maps/town.json',
          activeLayerId: 'ground',
          activeTool: EditorToolType.selection,
        );
      container.read(worldMapWorkspaceSessionProvider);

      final documents = <EditorMapDocumentSnapshot>[];
      final viewports = <EditorMapViewportSnapshot>[];
      final interactions = <EditorMapInteractionSnapshot>[];
      final inspectorInputs = <EditorWorldMapInspectorInputSnapshot>[];
      final inspectorOutputs = <WorldMapInspectorSnapshot>[];
      final subscriptions = [
        container.listen(
          editorMapDocumentSnapshotProvider,
          (_, next) => documents.add(next),
          fireImmediately: true,
        ),
        container.listen(
          editorMapViewportSnapshotProvider,
          (_, next) => viewports.add(next),
          fireImmediately: true,
        ),
        container.listen(
          editorMapInteractionSnapshotProvider,
          (_, next) => interactions.add(next),
          fireImmediately: true,
        ),
        container.listen(
          editorWorldMapInspectorInputSnapshotProvider,
          (_, next) => inspectorInputs.add(next),
          fireImmediately: true,
        ),
        container.listen(
          worldMapInspectorSnapshotProvider,
          (_, next) => inspectorOutputs.add(next),
          fireImmediately: true,
        ),
      ];
      addTearDown(() {
        for (final subscription in subscriptions) {
          subscription.close();
        }
      });

      notifier.state = notifier.state.copyWith(
        paletteCategoryFilter: PaletteCategory.floors,
        paletteSession: EditorPaletteSession(
          activeKey: paletteKey,
          contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
            paletteKey: const EditorLayerPaletteContext(
              browserQuery: 'arbres',
              browserFolderId: 'nature',
              projectElementCategoryId: 'vegetation',
              browserCollection: EditorPaletteAssetCollection.favorites,
            ),
          },
          recentTilesetIds: <String>['world'],
          favoriteTilesetIds: <String>['world'],
        ),
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
      );
      await container.pump();

      expect(documents, hasLength(1));
      expect(viewports, hasLength(1));
      expect(interactions, hasLength(1));
      expect(inspectorInputs, hasLength(1));
      expect(inspectorOutputs, hasLength(1));

      notifier.state = notifier.state.copyWith(
        zoom: 1.5,
        panOffset: const Offset(12, 24),
      );
      await container.pump();

      expect(documents, hasLength(1));
      expect(viewports, hasLength(2));
      expect(interactions, hasLength(1));
      expect(inspectorInputs, hasLength(1));

      notifier.state = notifier.state.copyWith(
        selectedPlacedElementInstanceId: 'tree-1',
      );
      await container.pump();

      expect(documents, hasLength(1));
      expect(viewports, hasLength(2));
      expect(interactions, hasLength(2));
      expect(inspectorInputs, hasLength(2));
      expect(inspectorOutputs.last.kind, WorldMapInspectorKind.objectSelection);

      notifier.state = notifier.state.copyWith(
        activeMap: map.copyWith(name: 'Town updated'),
      );
      await container.pump();

      expect(documents, hasLength(2));
      expect(viewports, hasLength(2));

      notifier.state = notifier.state.copyWith(
        selectedPlacedElementInstanceId: null,
      );
      await container.pump();
      final interactionCountBeforeCell = interactions.length;
      final inspectorInputCountBeforeCell = inspectorInputs.length;
      final inspectorOutputCountBeforeCell = inspectorOutputs.length;

      container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .selectCell(mapId: 'town', cell: const GridPos(x: 4, y: 5));
      await container.pump();

      expect(interactions, hasLength(interactionCountBeforeCell));
      expect(inspectorInputs, hasLength(inspectorInputCountBeforeCell));
      expect(inspectorOutputs, hasLength(inspectorOutputCountBeforeCell + 1));
      expect(inspectorOutputs.last.kind, WorldMapInspectorKind.cellSelection);
      expect(inspectorOutputs.last.cell, const GridPos(x: 4, y: 5));
    });
  });
}
