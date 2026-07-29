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

    notifier.setActiveLayer('details');

    expect(notifier.getSelectedTilesetEntry()?.id, 'details');
    expect(notifier.state.activeBrush, const EditorBrush.none());
    expect(notifier.state.selectedTilesetElementGroupId, isNull);
    expect(notifier.state.paletteCategoryFilter, isNull);
    expect(
      notifier.state.tilesElementsPanelMode,
      TilesElementsPanelMode.palette,
    );

    notifier.selectTilesetEditorContext('details');
    notifier.selectTilesetElementGroupFilter('decor');
    notifier.setPaletteCategoryFilter(PaletteCategory.decorations);
    notifier.selectPaletteTile(3);
    notifier.setTilesElementsPanelMode(TilesElementsPanelMode.palette);

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
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('browsing another tileset never arms an incompatible paint brush', () {
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

    expect(notifier.state.activeBrush, const EditorBrush.none());
    expect(notifier.state.errorMessage, contains('Assignez'));
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('painting never assigns a mismatched brush tileset implicitly', () {
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

    expect(notifier.state.activeMap, _map);
    expect(
      (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
      'world',
    );
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.errorMessage, contains('Assignez-lui'));
  });
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
      tilesetId: 'world',
      tiles: [],
    ),
    TileLayer(
      id: 'details',
      name: 'Details',
      tilesetId: 'details',
      tiles: [],
    ),
  ],
);
