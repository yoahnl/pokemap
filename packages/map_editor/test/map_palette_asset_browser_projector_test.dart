import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_palette_asset_browser.dart';
import 'package:map_editor/src/application/services/map_palette_asset_browser_projector.dart';
import 'package:map_editor/src/application/use_cases/project_tileset_use_cases.dart';
import 'package:map_editor/src/features/editor/state/models/editor_palette_session.dart';

void main() {
  late MapPaletteAssetBrowserProjector projector;

  setUp(() {
    projector = MapPaletteAssetBrowserProjector(
      ResolveAssignableTilesetsForMapUseCase(),
    );
  });

  group('MapPaletteAssetBrowserProjector', () {
    test('shows global and ancestor-group sources but hides foreign scopes',
        () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
      );

      expect(
        result.items.map((item) => item.tileset.id),
        <String>[
          'world',
          'unclassified',
          'regional_details',
          'town_details',
        ],
      );
      expect(result.items.every((item) => !item.isAssigned), isTrue);
      expect(result.items.every((item) => item.isCompatible), isTrue);
      expect(
        result.items.map((item) => item.tileset.id),
        isNot(contains('foreign_characters')),
      );
    });

    test('reveals incompatible sources disabled with an explicit reason', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        showIncompatible: true,
      );

      final foreign = result.items.singleWhere(
        (item) => item.tileset.id == 'foreign_characters',
      );
      expect(foreign.isCompatible, isFalse);
      expect(foreign.disabledReason, contains('autre groupe'));
    });

    test('builds declared breadcrumbs and filters a folder subtree', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        folderId: 'outdoor',
        showIncompatible: true,
      );

      expect(
        result.folders.map((folder) => folder.path),
        <String>['Extérieur', 'Extérieur / Nature', 'Personnages'],
      );
      expect(
        result.items.map((item) => item.tileset.id),
        <String>['world', 'regional_details', 'town_details'],
      );
      expect(
        result.items
            .singleWhere((item) => item.tileset.id == 'regional_details')
            .folderPath,
        'Extérieur / Nature',
      );
    });

    test('offers a deterministic unclassified bucket', () {
      final projectWithOrphan = project.copyWith(
        tilesets: <ProjectTilesetEntry>[
          ...project.tilesets,
          const ProjectTilesetEntry(
            id: 'orphan',
            name: 'Dossier supprimé',
            relativePath: 'tilesets/orphan.png',
            folderId: 'missing_folder',
          ),
        ],
      );
      final result = projector.project(
        project: projectWithOrphan,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        folderId: kEditorPaletteUnclassifiedFolderId,
      );

      expect(result.hasUnclassifiedSources, isTrue);
      expect(
        result.items.map((item) => item.tileset.id),
        containsAll(<String>['unclassified', 'orphan']),
      );
      expect(result.items.every((item) => item.folderPath == 'Non classé'),
          isTrue);
    });

    test('searches declared labels and never infers from filenames', () {
      final elementMatch = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        query: 'lampadaire',
      );
      final folderMatch = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        query: 'nature',
      );
      final filenameOnly = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        query: 'secret_filename',
        showIncompatible: true,
      );

      expect(
        elementMatch.items.map((item) => item.tileset.id),
        <String>['regional_details'],
      );
      expect(
        folderMatch.items.map((item) => item.tileset.id),
        <String>['world', 'regional_details', 'town_details'],
      );
      expect(filenameOnly.items, isEmpty);
    });

    test('filters explicit element categories without filename heuristics', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        elementCategoryId: 'nature',
      );

      expect(
        result.items.map((item) => item.tileset.id),
        <String>['world'],
      );
    });

    test('returns typed empty states instead of throwing on missing context',
        () {
      final noProject = projector.project(
        project: null,
        map: null,
        activeLayerId: null,
      );
      final noMap = projector.project(
        project: project,
        map: null,
        activeLayerId: null,
      );
      final missingLayer = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'removed',
        showIncompatible: true,
      );

      expect(noProject.status, MapPaletteAssetBrowserStatus.noProject);
      expect(noProject.items, isEmpty);
      expect(noMap.status, MapPaletteAssetBrowserStatus.noMap);
      expect(noMap.items, isEmpty);
      expect(
        missingLayer.status,
        MapPaletteAssetBrowserStatus.activeLayerMissing,
      );
      expect(
        missingLayer.items.every(
          (item) =>
              item.assignmentState ==
              MapPaletteAssetAssignmentState.layerMissing,
        ),
        isTrue,
      );
    });

    test('does not treat palette dependencies as source assignment', () {
      final missingSourceMap = mapWithLayer().copyWith(
        layers: const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Sol',
            palette: <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(
                tilesetId: 'deleted_source',
                localTileId: 0,
              ),
            ],
            cells: <int>[0],
          ),
        ],
      );

      final result = projector.project(
        project: project,
        map: missingSourceMap,
        activeLayerId: 'ground',
      );

      expect(
        result.status,
        MapPaletteAssetBrowserStatus.ready,
      );
      expect(result.assignedTilesetId, isNull);
      expect(result.diagnostic, isNull);
      expect(result.items, isNotEmpty);
      expect(result.items.every((item) => item.canAssign), isTrue);

      final occupied = projector.project(
        project: project,
        map: missingSourceMap.copyWith(
          layers: const <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Sol',
              palette: <TileLayerPaletteEntry>[
                TileLayerPaletteEntry(
                  tilesetId: 'deleted_source',
                  localTileId: 0,
                ),
              ],
              cells: <int>[1],
            ),
          ],
        ),
        activeLayerId: 'ground',
        showIncompatible: true,
      );
      expect(occupied.diagnostic, isNull);
      expect(
        occupied.items
            .where((item) => item.isScopeAssignable)
            .every((item) => item.canAssign),
        isTrue,
      );
    });

    test('surfaces an invalid map scope as a diagnostic projection', () {
      final invalidProject = project.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'town',
            name: 'Ville',
            relativePath: 'maps/town.json',
            groupId: 'missing-group',
          ),
        ],
      );

      final result = projector.project(
        project: invalidProject,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        showIncompatible: true,
      );

      expect(result.status, MapPaletteAssetBrowserStatus.invalidMapScope);
      expect(result.diagnostic, contains('invalide'));
      expect(result.items, isNotEmpty);
    });

    test('projects recent order and favorites from session-only ids', () {
      final recent = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        collection: EditorPaletteAssetCollection.recent,
        recentTilesetIds: const <String>[
          'regional_details',
          'missing',
          'world',
        ],
      );
      final favorites = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'ground',
        collection: EditorPaletteAssetCollection.favorites,
        favoriteTilesetIds: const <String>[
          'town_details',
          'missing',
          'world',
        ],
      );

      expect(
        recent.items.map((item) => item.tileset.id),
        <String>['regional_details', 'world'],
      );
      expect(
        favorites.items.map((item) => item.tileset.id),
        <String>['world', 'town_details'],
      );
      expect(favorites.items.every((item) => item.isFavorite), isTrue);
    });

    test('keeps every compatible source available on a non-empty layer', () {
      final hidden = projector.project(
        project: project,
        map: mapWithLayer(occupied: true),
        activeLayerId: 'ground',
      );
      final revealed = projector.project(
        project: project,
        map: mapWithLayer(occupied: true),
        activeLayerId: 'ground',
        showIncompatible: true,
      );

      expect(
        hidden.items.map((item) => item.tileset.id),
        <String>[
          'world',
          'unclassified',
          'regional_details',
          'town_details',
        ],
      );
      final other = revealed.items.singleWhere(
        (item) => item.tileset.id == 'regional_details',
      );
      expect(other.isCompatible, isTrue);
      expect(other.disabledReason, isNull);
      expect(
        revealed.items
            .singleWhere((item) => item.tileset.id == 'world')
            .canAssign,
        isTrue,
      );
    });

    test('explains that a non-tile layer cannot receive a tileset', () {
      final result = projector.project(
        project: project,
        map: mapWithLayer(),
        activeLayerId: 'collision',
        showIncompatible: true,
      );

      expect(result.items, isNotEmpty);
      expect(result.items.every((item) => !item.isCompatible), isTrue);
      expect(result.items.first.disabledReason, contains('calque de tuiles'));
      expect(result.activeLayerName, 'Collision');
    });
  });
}

const project = ProjectManifest(
  name: 'Browser',
  groups: <ProjectMapGroup>[
    ProjectMapGroup(
      id: 'region',
      name: 'Région',
      type: MapGroupType.special,
    ),
    ProjectMapGroup(
      id: 'town_group',
      name: 'Villes',
      type: MapGroupType.city,
      parentGroupId: 'region',
    ),
    ProjectMapGroup(
      id: 'foreign',
      name: 'Étranger',
      type: MapGroupType.special,
    ),
  ],
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
      groupId: 'town_group',
    ),
  ],
  tilesetFolders: <ProjectTilesetFolder>[
    ProjectTilesetFolder(id: 'outdoor', name: 'Extérieur'),
    ProjectTilesetFolder(
      id: 'nature_folder',
      name: 'Nature',
      parentFolderId: 'outdoor',
    ),
    ProjectTilesetFolder(id: 'characters', name: 'Personnages'),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'nature', name: 'Nature'),
    ProjectElementCategory(
      id: 'trees',
      name: 'Arbres',
      parentCategoryId: 'nature',
    ),
    ProjectElementCategory(id: 'decor', name: 'Décor'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
      folderId: 'outdoor',
      sortOrder: 0,
    ),
    ProjectTilesetEntry(
      id: 'unclassified',
      name: 'Divers',
      relativePath: 'tilesets/misc.png',
      sortOrder: 1,
    ),
    ProjectTilesetEntry(
      id: 'regional_details',
      name: 'Détails régionaux',
      relativePath: 'tilesets/secret_filename.png',
      scope: TilesetScope.group,
      groupId: 'region',
      folderId: 'nature_folder',
      sortOrder: 0,
    ),
    ProjectTilesetEntry(
      id: 'town_details',
      name: 'Détails urbains',
      relativePath: 'tilesets/town.png',
      scope: TilesetScope.group,
      groupId: 'town_group',
      folderId: 'nature_folder',
      sortOrder: 1,
    ),
    ProjectTilesetEntry(
      id: 'foreign_characters',
      name: 'Personnages étrangers',
      relativePath: 'tilesets/characters.png',
      scope: TilesetScope.group,
      groupId: 'foreign',
      folderId: 'characters',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Grand arbre',
      tilesetId: 'world',
      categoryId: 'trees',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
        ),
      ],
      tags: <String>['forêt'],
    ),
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lampadaire',
      tilesetId: 'regional_details',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
        ),
      ],
    ),
  ],
);

MapData mapWithLayer({bool occupied = false}) => MapData(
      id: 'town',
      name: 'Ville',
      size: const GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Sol',
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'world', localTileId: 0),
          ],
          cells: <int>[occupied ? 1 : 0],
        ),
        const CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false],
        ),
      ],
    );
