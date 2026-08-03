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

    test(
        'preserves a reused tile-index rotation and creates new instances unrotated',
        () {
      final existingDerived = _placement(
        id: 'derived',
        x: 0,
        quarterTurns: 3,
        properties: const {_originKey: 'tile_index', 'custom': 'keep'},
      );
      final map = _map(
        width: 2,
        tiles: const [1, 1],
        placedElements: [existingDerived],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: _manifest(),
      );

      expect(synced.placedElements, hasLength(2));
      final reused =
          synced.placedElements.singleWhere((entry) => entry.pos.x == 0);
      final generated =
          synced.placedElements.singleWhere((entry) => entry.pos.x == 1);
      expect(reused, existingDerived);
      expect(reused.quarterTurns, 3);
      expect(
        reused.properties,
        const {_originKey: 'tile_index', 'custom': 'keep'},
      );
      expect(generated.quarterTurns, 0);
    });

    test('repainting a moved placement origin allocates a stable unique id',
        () {
      final oldPositionId = buildMapPlacedElementId(
        layerId: 'decor',
        elementId: 'tree',
        pos: const GridPos(x: 0, y: 0),
      );
      final moved = _placement(
        id: oldPositionId,
        x: 1,
        properties: const {_originKey: 'tile_index', 'custom': 'keep'},
      );
      const indexer = PlacedElementInstanceIndexer();
      final movedMap = indexer.syncAllTileLayers(
        map: _map(
          width: 2,
          tiles: const [0, 1],
          placedElements: [moved],
        ),
        project: _manifest(),
      );
      final movedLayer = movedMap.layers.whereType<TileLayer>().single;
      final repaintedMap = movedMap.copyWith(
        layers: <MapLayer>[
          movedLayer.copyWith(tiles: const [1, 1]),
        ],
      );

      final firstSync = indexer.syncAllTileLayers(
        map: repaintedMap,
        project: _manifest(),
      );
      final secondSync = indexer.syncAllTileLayers(
        map: firstSync,
        project: _manifest(),
      );

      expect(firstSync.placedElements, hasLength(2));
      expect(
        firstSync.placedElements.map((entry) => entry.id).toSet(),
        hasLength(2),
      );
      expect(
        firstSync.placedElements.singleWhere((entry) => entry.pos.x == 1),
        moved,
      );
      expect(
        firstSync.placedElements.singleWhere((entry) => entry.pos.x == 0).id,
        '${oldPositionId}_2',
      );
      expect(secondSync.placedElements, firstSync.placedElements);
    });

    test('resize keeps in-bounds authored and environment ownership', () {
      final authored = _placement(
        id: 'authored',
        x: 0,
        properties: const {_originKey: 'authored'},
      );
      final environment = _placement(
        id: 'environment',
        x: 1,
        properties: const {_originKey: 'environment'},
      );
      final derived = _placement(
        id: 'derived',
        x: 2,
        properties: const {_originKey: 'tile_index'},
      );
      final map = _map(
        width: 3,
        tiles: const [0, 0, 1],
        placedElements: [authored, environment, derived],
        environmentGeneratedIds: const ['environment'],
      );

      final resized = resizeMapData(map, width: 2, height: 1);
      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: resized,
        project: _manifest(),
      );

      expect(synced.placedElements, [authored, environment]);
      expect(synced.size, const GridSize(width: 2, height: 1));
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
  int quarterTurns = 0,
  Map<String, String> properties = const {},
}) {
  return MapPlacedElement(
    id: id,
    layerId: 'decor',
    elementId: 'tree',
    pos: GridPos(x: x, y: 0),
    quarterTurns: quarterTurns,
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
