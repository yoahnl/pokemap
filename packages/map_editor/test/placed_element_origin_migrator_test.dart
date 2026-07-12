import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/application/services/placed_element_origin_migrator.dart';

void main() {
  group('PlacedElementOriginMigrator', () {
    test('previews exact classifications without mutating the map', () {
      final map = _legacyMap();

      final preview = const PlacedElementOriginMigrator().preview(
        map: map,
        project: _manifest,
      );

      expect(map.placedElements.map((entry) => entry.properties), [
        const {'note': 'exact tile pattern'},
        const {'pokemapPlacementOrigin': 'older_editor'},
        const {'pokemapPlacementOrigin': 'tile_index', 'seed': '9'},
      ]);
      expect(preview.mapId, 'migration_fixture');
      expect(preview.entries, hasLength(3));
      expect(preview.classificationFor('legacy_tile')!.proposedOrigin,
          pokemapPlacementOriginTileIndex);
      expect(preview.classificationFor('legacy_authored')!.proposedOrigin,
          pokemapPlacementOriginAuthored);
      expect(preview.classificationFor('legacy_environment')!.proposedOrigin,
          pokemapPlacementOriginEnvironment);
      expect(preview.countFor(pokemapPlacementOriginTileIndex), 1);
      expect(preview.countFor(pokemapPlacementOriginAuthored), 1);
      expect(preview.countFor(pokemapPlacementOriginEnvironment), 1);
    });

    test('applies the reviewed preview and preserves custom properties', () {
      final map = _legacyMap();
      const migrator = PlacedElementOriginMigrator();
      final preview = migrator.preview(map: map, project: _manifest);

      final migrated = migrator.apply(map: map, preview: preview);

      expect(
        migrated.placedElements
            .singleWhere((entry) => entry.id == 'legacy_tile')
            .properties,
        const {
          'note': 'exact tile pattern',
          'pokemapPlacementOrigin': 'tile_index',
        },
      );
      expect(
        migrated.placedElements
            .singleWhere((entry) => entry.id == 'legacy_authored')
            .properties,
        const {'pokemapPlacementOrigin': 'authored'},
      );
      expect(
        migrated.placedElements
            .singleWhere((entry) => entry.id == 'legacy_environment')
            .properties,
        const {'pokemapPlacementOrigin': 'environment', 'seed': '9'},
      );
      expect(map.placedElements, isNot(same(migrated.placedElements)));
    });

    test('refuses to apply a stale preview to a changed map', () {
      final map = _legacyMap();
      const migrator = PlacedElementOriginMigrator();
      final preview = migrator.preview(map: map, project: _manifest);
      final changed = map.copyWith(
        placedElements: [
          ...map.placedElements.take(2),
        ],
      );

      expect(
        () => migrator.apply(map: changed, preview: preview),
        throwsStateError,
      );
    });

    test('returns the same map when the reviewed classification is current',
        () {
      const migrator = PlacedElementOriginMigrator();
      final firstPreview = migrator.preview(
        map: _legacyMap(),
        project: _manifest,
      );
      final migrated = migrator.apply(
        map: firstPreview.sourceMap,
        preview: firstPreview,
      );
      final currentPreview = migrator.preview(
        map: migrated,
        project: _manifest,
      );

      expect(currentPreview.changedCount, 0);
      expect(
        migrator.apply(map: migrated, preview: currentPreview),
        same(migrated),
      );
    });
  });
}

MapData _legacyMap() => MapData(
      id: 'migration_fixture',
      name: 'Migration fixture',
      size: const GridSize(width: 3, height: 1),
      layers: <MapLayer>[
        EnvironmentLayer(
          id: 'environment',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'decor',
            areas: [
              EnvironmentArea(
                id: 'forest',
                name: 'Forest',
                presetId: 'forest',
                seed: 7,
                mask: EnvironmentAreaMask(
                  width: 3,
                  height: 1,
                  cells: [false, false, true],
                ),
                generatedPlacementIds: ['legacy_environment'],
              ),
            ],
          ),
        ),
        const TileLayer(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'nature',
          tiles: [1, 0, 1],
        ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'legacy_tile',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
          properties: {'note': 'exact tile pattern'},
        ),
        MapPlacedElement(
          id: 'legacy_authored',
          layerId: 'decor',
          elementId: 'house',
          pos: GridPos(x: 1, y: 0),
          properties: {'pokemapPlacementOrigin': 'older_editor'},
        ),
        MapPlacedElement(
          id: 'legacy_environment',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 2, y: 0),
          properties: {
            'pokemapPlacementOrigin': 'tile_index',
            'seed': '9',
          },
        ),
      ],
    );

const _manifest = ProjectManifest(
  name: 'Migration project',
  maps: [],
  tilesets: [
    ProjectTilesetEntry(
      id: 'nature',
      name: 'Nature',
      relativePath: 'tilesets/nature.png',
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
  elements: [
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'nature',
      categoryId: 'nature',
      frames: [
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    ),
    ProjectElementEntry(
      id: 'house',
      name: 'House',
      tilesetId: 'nature',
      categoryId: 'building',
      frames: [
        TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
      ],
    ),
  ],
);
