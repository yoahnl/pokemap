import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('placedElements identity', () {
    test('buildMapPlacedElementId is stable across element changes', () {
      final pos = const GridPos(x: 4, y: 7);
      final first = buildMapPlacedElementId(
        layerId: 'layer_tree',
        elementId: 'tree_oak',
        pos: pos,
      );
      final second = buildMapPlacedElementId(
        layerId: 'layer_tree',
        elementId: 'tree_pine',
        pos: pos,
      );
      expect(first, second);
    });
  });

  group('placedElements operations', () {
    test('removeMapLayer removes placed elements tied to layer', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        layers: const [
          MapLayer.tile(
              id: 'a',
              name: 'A',
              cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
          MapLayer.tile(
              id: 'b',
              name: 'B',
              cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'a::0::0',
            layerId: 'a',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'b::1::1',
            layerId: 'b',
            elementId: 'house',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      final updated = removeMapLayer(map, layerId: 'a');
      expect(updated.layers.map((e) => e.id), ['b']);
      expect(updated.placedElements.map((e) => e.id), ['b::1::1']);
    });

    test('resizeMapData removes placed elements with origin outside bounds',
        () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        layers: const [
          MapLayer.tile(
              id: 'a',
              name: 'A',
              cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'a::0::0',
            layerId: 'a',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'a::3::3',
            layerId: 'a',
            elementId: 'house',
            pos: GridPos(x: 3, y: 3),
          ),
        ],
      );

      final updated = resizeMapData(map, width: 2, height: 2);
      expect(updated.placedElements.map((e) => e.id), ['a::0::0']);
    });
  });

  group('placedElements validation', () {
    test('MapValidator accepts elements from another palette source', () {
      final project = _projectWithElement(
        elementId: 'house',
        elementTilesetId: 'ts_house',
        source: const TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        layers: const [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            palette: [
              TileLayerPaletteEntry(
                tilesetId: 'ts_tree',
                localTileId: 0,
              ),
            ],
            cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'house',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        returnsNormally,
      );
    });

    test('MapValidator rejects footprint exceeding map bounds', () {
      final project = _projectWithElement(
        elementId: 'house',
        elementTilesetId: 'ts_house',
        source: const TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 2, height: 2),
        layers: const [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            cells: [0, 0, 0, 0],
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'house',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectManifest _projectWithElement({
  required String elementId,
  required String elementTilesetId,
  required TilesetSourceRect source,
}) {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: [
      ProjectTilesetEntry(
        id: elementTilesetId,
        name: elementTilesetId,
        relativePath: '$elementTilesetId.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: '$elementTilesetId.png',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
      const ProjectTilesetEntry(
        id: 'ts_tree',
        name: 'ts_tree',
        relativePath: 'ts_tree.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'ts_tree.png',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'decor', name: 'decor'),
    ],
    elements: [
      ProjectElementEntry(
        id: elementId,
        name: elementId,
        tilesetId: elementTilesetId,
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(source: source),
        ],
      ),
    ],
  );
}
