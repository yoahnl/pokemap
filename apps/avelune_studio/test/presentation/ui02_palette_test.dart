import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_tile_choices.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'catalogue search selects the actual decor brush without editing the map',
    () async {
      final project = workspaceProject.copyWith(
        elements: [
          for (var i = 0; i < 500; i++)
            workspaceElement.copyWith(id: 'tree-$i', name: 'Arbre $i'),
        ],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r', mapId: 'a'),
      );
      final workspace =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      addTearDown(workspace.dispose);
      final view = MapWorkspaceEditingState();
      view.resourceFilters.query = 'Arbre 499';
      final visible = view.paletteResourcesFor(project, 'a', 'Décors');
      expect(visible.map((item) => item.id), ['tree-499']);
      final before = document.current;
      expect(
        await useMapResource(
          workspace: workspace,
          item: visible.single,
          view: () => view,
          isActive: () => true,
          chooseMap: (_) async => null,
          chooseTile: (_) async => null,
        ),
        isTrue,
      );
      expect(view.brush!.id, 'tree-499');
      expect(view.tool, StudioMapTool.place);
      expect(document.current, same(before));
      expect(document.dirty, isFalse);
    },
  );

  test('atlas priorities and coordinates select the real local tile without editing the map', () async {
    const source = ProjectRegularAtlasTilesetSource(
      assetId: 'atlas',
      pixelWidth: 128,
      pixelHeight: 128,
      tileWidth: 32,
      tileHeight: 32,
    );
    final project = workspaceProject.copyWith(
      tilesets: [
        const ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas test',
          relativePath: 'atlas.png',
          source: source,
        ),
        const ProjectTilesetEntry(
          id: 'other',
          name: 'Other',
          relativePath: 'other.png',
          source: source,
        ),
      ],
    );
    final known = [
      const TileLayerPaletteEntry(tilesetId: 'other', localTileId: 8),
      const TileLayerPaletteEntry(tilesetId: 'other', localTileId: 8),
    ];
    expect(mapPaletteAtlas(project.tilesets, knownTiles: known)!.id, 'other');
    expect(
      mapPaletteAtlas(
        project.tilesets,
        selected: const TileLayerPaletteEntry(
          tilesetId: 'atlas',
          localTileId: 0,
        ),
        knownTiles: known,
      )!.id,
      'atlas',
    );
    expect(
      mapPaletteAtlas(
        project.tilesets,
        atlasId: 'other',
        selected: const TileLayerPaletteEntry(
          tilesetId: 'atlas',
          localTileId: 0,
        ),
      )!.id,
      'other',
    );
    expect(mapPaletteAtlasTileIds(project.tilesets.last, known), [8]);
    final tile = mapPaletteAtlasSelection(
      'atlas',
      source,
      const TilesetSourceRect(x: 2, y: 1),
    );
    expect(
      tile,
      const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 6),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r', mapId: 'a'),
    );
    final workspace =
        MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
          ..project = project
          ..active = document;
    addTearDown(workspace.dispose);
    final view = MapWorkspaceEditingState();
    final item = view
        .paletteResourcesFor(project, 'a', 'Tuiles')
        .singleWhere((item) => item.id == 'atlas');
    final before = document.current;
    expect(
      await useMapResource(
        workspace: workspace,
        item: item,
        view: () => view,
        isActive: () => true,
        chooseMap: (_) async => null,
        chooseTile: (_) async => tile,
      ),
      isTrue,
    );
    expect(view.tile, tile);
    expect(view.tool, StudioMapTool.paint);
    expect(document.current, same(before));
  });
}
