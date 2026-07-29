import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_palette_session_service.dart';
import 'package:map_editor/src/features/editor/state/models/editor_palette_session.dart';

void main() {
  const service = EditorPaletteSessionService(
    maxRecentTilesets: 3,
    maxFavoriteTilesets: 3,
  );

  group('EditorPaletteSessionService', () {
    test('restores every palette field across A to B to A navigation', () {
      const keyA = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const keyB = EditorPaletteContextKey(mapId: 'town', layerId: 'details');
      const contextA = EditorLayerPaletteContext(
        selectedTilesetId: 'world',
        selectedElementGroupId: 'nature',
        paletteCategoryFilter: PaletteCategory.trees,
        activeBrush:
            EditorPaletteBrushMemory.tile(tileId: 7, tilesetId: 'world'),
        browserQuery: 'arbres',
        browserFolderId: 'outdoor',
        browserCollection: EditorPaletteAssetCollection.favorites,
        showIncompatible: true,
      );
      const contextB = EditorLayerPaletteContext(
        selectedTilesetId: 'details',
        browserQuery: 'lampes',
      );

      var session = service.remember(
        const EditorPaletteSession(),
        key: keyA,
        context: contextA,
      );
      session = service
          .activate(
            session,
            key: keyB,
            project: project,
            assignedTilesetId: 'details',
          )
          .session;
      session = service.remember(
        session,
        key: keyB,
        context: contextB,
      );

      final restored = service.activate(
        session,
        key: keyA,
        project: project,
        assignedTilesetId: 'world',
      );

      expect(restored.context, contextA);
      expect(restored.session.activeKey, keyA);
    });

    test('does not collide when two maps reuse the same layer id', () {
      const town = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const route = EditorPaletteContextKey(mapId: 'route', layerId: 'ground');
      var session = service.remember(
        const EditorPaletteSession(),
        key: town,
        context: const EditorLayerPaletteContext(
          selectedTilesetId: 'world',
          browserQuery: 'town',
        ),
      );
      session = service.remember(
        session,
        key: route,
        context: const EditorLayerPaletteContext(
          selectedTilesetId: 'details',
          browserQuery: 'route',
        ),
      );

      expect(session.contexts[town]?.browserQuery, 'town');
      expect(session.contexts[route]?.browserQuery, 'route');
    });

    test('sanitizes stale source, group, brush, folder and preferences', () {
      const key = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      const missingLayerKey =
          EditorPaletteContextKey(mapId: 'town', layerId: 'removed');
      const missingMapKey =
          EditorPaletteContextKey(mapId: 'removed', layerId: 'ground');
      final stale = EditorPaletteSession(
        activeKey: key,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          key: const EditorLayerPaletteContext(
            selectedTilesetId: 'missing',
            selectedElementGroupId: 'missing-group',
            activeBrush: EditorPaletteBrushMemory.paletteEntry(
              entryId: 'missing-entry',
              tilesetId: 'missing',
            ),
            browserFolderId: 'missing-folder',
            projectElementCategoryId: 'missing-category',
          ),
          missingLayerKey:
              const EditorLayerPaletteContext(selectedTilesetId: 'world'),
          missingMapKey:
              const EditorLayerPaletteContext(selectedTilesetId: 'world'),
        },
        recentTilesetIds: <String>['missing', 'world'],
        favoriteTilesetIds: <String>['details', 'missing'],
      );

      final result = service.activate(
        stale,
        key: key,
        project: project,
        assignedTilesetId: 'world',
        activeMap: townMap,
      );

      expect(result.context.selectedTilesetId, 'world');
      expect(result.context.selectedElementGroupId, isNull);
      expect(
        result.context.activeBrush,
        const EditorPaletteBrushMemory.none(),
      );
      expect(result.context.browserFolderId, isNull);
      expect(result.context.projectElementCategoryId, isNull);
      expect(result.session.contexts.keys, <EditorPaletteContextKey>{key});
      expect(result.session.recentTilesetIds, <String>['world']);
      expect(result.session.favoriteTilesetIds, <String>['details']);
    });

    test('recents are LRU and favorites are bounded session preferences', () {
      var session = const EditorPaletteSession();
      for (final id in <String>['world', 'details', 'indoor', 'world']) {
        session = service.recordRecent(
          session,
          tilesetId: id,
          validTilesetIds: const <String>{
            'world',
            'details',
            'indoor',
            'other',
          },
        );
      }
      expect(
        session.recentTilesetIds,
        <String>['world', 'indoor', 'details'],
      );

      for (final id in <String>['world', 'details', 'indoor', 'other']) {
        session = service.toggleFavorite(
          session,
          tilesetId: id,
          validTilesetIds: const <String>{
            'world',
            'details',
            'indoor',
            'other',
          },
        );
      }
      expect(
        session.favoriteTilesetIds,
        <String>['details', 'indoor', 'other'],
      );
    });

    test('reset drops contexts, recents and favorites', () {
      const key = EditorPaletteContextKey(mapId: 'town', layerId: 'ground');
      final populated = EditorPaletteSession(
        activeKey: key,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          key: const EditorLayerPaletteContext(selectedTilesetId: 'world'),
        },
        recentTilesetIds: <String>['world'],
        favoriteTilesetIds: <String>['world'],
      );

      expect(service.reset(populated), const EditorPaletteSession());
    });
  });
}

const project = ProjectManifest(
  name: 'Palette session',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Town',
      relativePath: 'maps/town.json',
    ),
    ProjectMapEntry(
      id: 'route',
      name: 'Route',
      relativePath: 'maps/route.json',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Outdoor'),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
      folderId: 'outdoor',
      elementGroups: <TilesetElementGroup>[
        TilesetElementGroup(id: 'nature', name: 'Nature'),
      ],
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Details',
      relativePath: 'tilesets/details.png',
    ),
    ProjectTilesetEntry(
      id: 'indoor',
      name: 'Indoor',
      relativePath: 'tilesets/indoor.png',
    ),
    ProjectTilesetEntry(
      id: 'other',
      name: 'Other',
      relativePath: 'tilesets/other.png',
    ),
  ],
);

const townMap = MapData(
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
);
