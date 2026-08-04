import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('setActiveLayer restores an independent palette context A to B to A',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
        selectedTilesetEditorId: 'details',
        selectedTilesetElementGroupId: 'nature',
        paletteCategoryFilter: PaletteCategory.trees,
        activeBrush: EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
      );

    notifier.setPaletteBrowserQuery('arbres');
    notifier.setPaletteBrowserFolder('outdoor');
    notifier.setPaletteBrowserElementCategory('nature');
    notifier.setPaletteBrowserCollection(
      EditorPaletteAssetCollection.favorites,
    );
    notifier.setPaletteBrowserShowIncompatible(true);
    notifier.togglePaletteTilesetFavorite('world');
    notifier.setActiveLayer('details');

    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    expect(notifier.state.activeBrush, const EditorBrush.none());
    expect(notifier.state.selectedTilesetElementGroupId, isNull);
    expect(notifier.state.paletteCategoryFilter, isNull);
    expect(
      notifier.state.tilesElementsPanelMode,
      TilesElementsPanelMode.palette,
    );
    expect(_activeContext(notifier).browserQuery, isEmpty);
    expect(_activeContext(notifier).browserFolderId, isNull);
    expect(
      _activeContext(notifier).browserCollection,
      EditorPaletteAssetCollection.all,
    );
    expect(_activeContext(notifier).showIncompatible, isFalse);

    notifier.selectTilesetEditorContext('details');
    notifier.selectTilesetElementGroupFilter('decor');
    notifier.setPaletteCategoryFilter(PaletteCategory.decorations);
    notifier.selectPaletteTile(3);
    notifier.setTilesElementsPanelMode(TilesElementsPanelMode.palette);
    notifier.setPaletteBrowserQuery('lampes');
    notifier.setPaletteBrowserCollection(EditorPaletteAssetCollection.recent);

    notifier.setActiveLayer('ground');

    expect(notifier.getSelectedTilesetEntry()?.id, 'world');
    expect(
      notifier.state.activeBrush,
      const EditorBrush.tile(tileId: 7, tilesetId: 'world'),
    );
    expect(notifier.state.selectedTilesetElementGroupId, 'nature');
    expect(notifier.state.paletteCategoryFilter, PaletteCategory.trees);
    expect(
      notifier.state.tilesElementsPanelMode,
      TilesElementsPanelMode.placedInstances,
    );
    expect(_activeContext(notifier).browserQuery, 'arbres');
    expect(_activeContext(notifier).browserFolderId, 'outdoor');
    expect(_activeContext(notifier).projectElementCategoryId, 'nature');
    expect(
      _activeContext(notifier).browserCollection,
      EditorPaletteAssetCollection.favorites,
    );
    expect(_activeContext(notifier).showIncompatible, isTrue);
    expect(notifier.state.paletteSession.favoriteTilesetIds, <String>['world']);

    notifier.setActiveLayer('details');

    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    expect(
      notifier.state.activeBrush,
      const EditorBrush.tile(tileId: 3, tilesetId: 'details'),
    );
    expect(notifier.state.selectedTilesetElementGroupId, 'decor');
    expect(
      notifier.state.paletteCategoryFilter,
      PaletteCategory.decorations,
    );
    expect(_activeContext(notifier).browserQuery, 'lampes');
    expect(
      _activeContext(notifier).browserCollection,
      EditorPaletteAssetCollection.recent,
    );
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('browsing another tileset arms a brush without assigning the layer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
      );

    notifier.selectTilesetEditorContext('details');
    expect(notifier.getSelectedTilesetEntry()?.id, 'details');

    notifier.selectPaletteTile(3);

    expect(
      notifier.state.activeBrush,
      const EditorBrush.tile(tileId: 3, tilesetId: 'details'),
    );
    expect(notifier.state.errorMessage, isNull);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('painting interns a second tileset directly in the layer palette', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
        activeBrush: EditorBrush.tile(tileId: 3, tilesetId: 'details'),
      );

    notifier.paintSelectedBrushAt(
      const GridPos(x: 0, y: 0),
      tilesetColumnsById: const <String, int>{},
    );
    notifier.endMapStroke();

    final layer = notifier.state.activeMap!.layers.first as TileLayer;
    expect(
        resolveTileLayerCell(layer, 0),
        const TileLayerPaletteEntry(
          tilesetId: 'details',
          localTileId: 2,
        ));
    expect(
        layer.palette.map((entry) => entry.tilesetId),
        containsAll(<String>[
          'world',
          'details',
        ]));
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(notifier.state.isDirty, isTrue);
    expect(notifier.state.errorMessage, isNull);
  });

  test('invalid browser filters are rejected without map mutations', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'ground',
      );

    notifier.setPaletteBrowserFolder('missing-folder');

    expect(notifier.state.errorMessage, contains('n’existe plus'));
    expect(notifier.state.activeMap, _map);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });
}

EditorLayerPaletteContext _activeContext(EditorNotifier notifier) {
  final map = notifier.state.activeMap!;
  final key = EditorPaletteContextKey(
    mapId: map.id,
    layerId: notifier.state.activeLayerId!,
  );
  return notifier.state.paletteSession.contexts[key]!;
}

const _project = ProjectManifest(
  name: 'Palette context',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Town',
      relativePath: 'maps/town.json',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Extérieur'),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
      elementGroups: <TilesetElementGroup>[
        TilesetElementGroup(id: 'nature', name: 'Nature'),
      ],
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Details',
      relativePath: 'tilesets/details.png',
      elementGroups: <TilesetElementGroup>[
        TilesetElementGroup(id: 'decor', name: 'Décor'),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'world', localTileId: 0),
      ],
      cells: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    TileLayer(
      id: 'details',
      name: 'Details',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'details', localTileId: 0),
      ],
      cells: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
  ],
);
