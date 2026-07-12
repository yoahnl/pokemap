import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';

const _originKey = 'pokemapPlacementOrigin';

void main() {
  group('PlacedElementInstanceIndexer ownership', () {
    test('preserves authored placements when a TileLayer has no tileset', () {
      final authored = _placement(id: 'authored', x: 0);
      final staleDerived = _placement(
        id: 'stale',
        x: 1,
        properties: const {_originKey: 'tile_index'},
      );
      final map = _map(
        width: 2,
        tilesetId: null,
        tiles: const [],
        placedElements: [authored, staleDerived],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: _manifest(),
      );

      expect(synced.placedElements, [authored]);
    });

    test('preserves authored and environment placements for a zero tileset',
        () {
      final authored = _placement(
        id: 'authored',
        x: 0,
        properties: const {_originKey: 'authored', 'note': 'keep'},
      );
      final environment = _placement(
        id: 'environment',
        x: 1,
        properties: const {_originKey: 'environment', 'seed': '42'},
      );
      final legacyUnknown = _placement(
        id: 'legacy_unknown',
        x: 2,
        properties: const {_originKey: 'older_editor'},
      );
      final staleDerived = _placement(
        id: 'stale',
        x: 3,
        properties: const {_originKey: 'tile_index'},
      );
      final map = _map(
        width: 4,
        tiles: const [0, 0, 0, 0],
        placedElements: [
          authored,
          environment,
          legacyUnknown,
          staleDerived,
        ],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: _manifest(),
      );

      expect(
        synced.placedElements,
        [authored, environment, legacyUnknown],
      );
    });

    test(
        'environment ids override tile_index markers and protected positions are not overwritten',
        () {
      final authored = _placement(id: 'authored', x: 0);
      final environment = _placement(
        id: 'generated_tree',
        x: 1,
        properties: const {_originKey: 'tile_index', 'seed': '7'},
      );
      final map = _map(
        width: 2,
        tiles: const [1, 1],
        placedElements: [authored, environment],
        environmentGeneratedIds: const ['generated_tree'],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: _manifest(),
      );

      expect(synced.placedElements, [authored, environment]);
      expect(
        synced.placedElements.where((entry) => entry.pos.x == 0),
        hasLength(1),
      );
      expect(
        synced.placedElements.where((entry) => entry.pos.x == 1),
        hasLength(1),
      );
    });

    test('removes stale derived placements and marks generated placements', () {
      final staleDerived = _placement(
        id: 'stale',
        x: 1,
        properties: const {_originKey: 'tile_index', 'legacy': 'value'},
      );
      final map = _map(
        width: 2,
        tiles: const [1, 0],
        placedElements: [staleDerived],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: _manifest(),
      );

      expect(synced.placedElements, hasLength(1));
      final generated = synced.placedElements.single;
      expect(generated.id, isNot('stale'));
      expect(generated.pos, const GridPos(x: 0, y: 0));
      expect(generated.properties[_originKey], 'tile_index');
    });

    test('reuses only a derived placement and normalizes its origin marker',
        () {
      final existingDerived = _placement(
        id: 'derived',
        x: 0,
        properties: const {_originKey: 'tile_index', 'custom': 'keep'},
      );
      final map = _map(
        width: 1,
        tiles: const [1],
        placedElements: [existingDerived],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: _manifest(),
      );

      expect(synced.placedElements, hasLength(1));
      expect(synced.placedElements.single.id, 'derived');
      expect(
        synced.placedElements.single.properties,
        const {_originKey: 'tile_index', 'custom': 'keep'},
      );
    });
  });
}

MapData _map({
  required int width,
  required List<int> tiles,
  required List<MapPlacedElement> placedElements,
  String? tilesetId = 'nature',
  List<String> environmentGeneratedIds = const [],
}) {
  final layers = <MapLayer>[
    if (environmentGeneratedIds.isNotEmpty)
      MapLayer.environment(
        id: 'environment',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'decor',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Area',
              presetId: 'forest',
              seed: 1,
              mask: EnvironmentAreaMask(
                width: width,
                height: 1,
                cells: List<bool>.filled(width, true),
              ),
              generatedPlacementIds: environmentGeneratedIds,
            ),
          ],
        ),
      ),
    MapLayer.tile(
      id: 'decor',
      name: 'Decor',
      tilesetId: tilesetId,
      tiles: tiles,
    ),
  ];
  return MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: width, height: 1),
    layers: layers,
    placedElements: placedElements,
  );
}

MapPlacedElement _placement({
  required String id,
  required int x,
  Map<String, String> properties = const {},
}) {
  return MapPlacedElement(
    id: id,
    layerId: 'decor',
    elementId: 'tree',
    pos: GridPos(x: x, y: 0),
    properties: properties,
  );
}

ProjectManifest _manifest() {
  return const ProjectManifest(
    name: 'Project',
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
    ],
  );
}
