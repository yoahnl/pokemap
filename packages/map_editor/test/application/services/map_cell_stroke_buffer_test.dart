import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/map_cell_stroke_buffer.dart';

void main() {
  const tileA = TileLayerPaletteEntry(tilesetId: 'world', localTileId: 4);
  const tileB = TileLayerPaletteEntry(tilesetId: 'world', localTileId: 8);

  test('tile samples stay sparse until one validated commit', () {
    final source = _tileMap(1024);
    final buffer = MapCellStrokeBuffer.tile(
      sourceMap: source,
      layerId: 'ground',
    );
    var validations = 0;

    for (var x = 0; x < 1000; x++) {
      buffer.paintTiles(
        origin: GridPos(x: x, y: 5),
        patternSize: const GridSize(width: 1, height: 1),
        tiles: const <TileLayerPaletteEntry?>[tileA],
      );
    }

    expect(buffer.touchedCellCount, 1000);
    expect(buffer.fullLayerCopyCount, 0);
    expect(buffer.mapMaterializationCount, 0);
    expect(buffer.validationCount, 0);
    expect(buffer.tileAt(5 * 1024 + 999), tileA);

    final committed = buffer.commit(
      validate: (map) {
        validations += 1;
        MapValidator.validate(map);
      },
    );

    expect(committed, isNot(same(source)));
    expect(buffer.fullLayerCopyCount, 1);
    expect(buffer.mapMaterializationCount, 1);
    expect(buffer.validationCount, 1);
    expect(validations, 1);
  });

  test('collision samples stay sparse and cancellation needs no copy', () {
    final source = _collisionMap(1024);
    final buffer = MapCellStrokeBuffer.collision(
      sourceMap: source,
      layerId: 'collision',
    );

    for (var x = 0; x < 1000; x++) {
      buffer.setCollisions(
        origin: GridPos(x: x, y: 9),
        patternSize: const GridSize(width: 1, height: 1),
        value: true,
      );
    }

    expect(buffer.touchedCellCount, 1000);
    expect(buffer.collisionAt(9 * 1024 + 999), isTrue);
    expect(buffer.fullLayerCopyCount, 0);
    expect(buffer.mapMaterializationCount, 0);
    expect(buffer.validationCount, 0);
    expect(source.layers.single, isA<CollisionLayer>());
    expect(
      (source.layers.single as CollisionLayer).collisions,
      everyElement(isFalse),
    );
  });

  test('tile commit matches sequential canonical operations bit for bit', () {
    final source = _tileMap(8);
    final buffer = MapCellStrokeBuffer.tile(
      sourceMap: source,
      layerId: 'ground',
    );
    buffer.paintTiles(
      origin: const GridPos(x: 1, y: 3),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[tileA],
    );
    buffer.paintTiles(
      origin: const GridPos(x: 4, y: 3),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[tileB],
    );
    buffer.paintTiles(
      origin: const GridPos(x: 4, y: 3),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[null],
    );

    var expected = source;
    for (var x = 1; x <= 4; x++) {
      expected = paintTilePatternOnLayer(
        expected,
        layerId: 'ground',
        pos: GridPos(x: x, y: 3),
        patternSize: const GridSize(width: 1, height: 1),
        tiles: const <TileLayerPaletteEntry?>[tileA],
      );
    }
    for (var x = 1; x <= 4; x++) {
      expected = paintTilePatternOnLayer(
        expected,
        layerId: 'ground',
        pos: GridPos(x: x, y: 3),
        patternSize: const GridSize(width: 1, height: 1),
        tiles: const <TileLayerPaletteEntry?>[tileB],
      );
    }
    expected = paintTilePatternOnLayer(
      expected,
      layerId: 'ground',
      pos: const GridPos(x: 4, y: 3),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[null],
    );

    expect(buffer.commit(validate: MapValidator.validate), expected);
  });

  test('transient tile paint preserves the canonical palette side effect', () {
    final source = _tileMap(4);
    final buffer = MapCellStrokeBuffer.tile(
      sourceMap: source,
      layerId: 'ground',
    );
    buffer.paintTiles(
      origin: const GridPos(x: 2, y: 2),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[tileA],
    );
    buffer.paintTiles(
      origin: const GridPos(x: 2, y: 2),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[null],
    );

    final painted = paintTilePatternOnLayer(
      source,
      layerId: 'ground',
      pos: const GridPos(x: 2, y: 2),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[tileA],
    );
    final expected = paintTilePatternOnLayer(
      painted,
      layerId: 'ground',
      pos: const GridPos(x: 2, y: 2),
      patternSize: const GridSize(width: 1, height: 1),
      tiles: const <TileLayerPaletteEntry?>[null],
    );

    expect(buffer.hasChanges, isTrue);
    expect(buffer.commit(validate: MapValidator.validate), expected);
  });

  test('canvas exit breaks interpolation before re-entry', () {
    final source = _collisionMap(8);
    final buffer = MapCellStrokeBuffer.collision(
      sourceMap: source,
      layerId: 'collision',
    );
    buffer.setCollisions(
      origin: const GridPos(x: 1, y: 1),
      patternSize: const GridSize(width: 1, height: 1),
      value: true,
    );
    buffer.breakInterpolation();
    buffer.setCollisions(
      origin: const GridPos(x: 6, y: 1),
      patternSize: const GridSize(width: 1, height: 1),
      value: true,
    );

    expect(buffer.collisionAt(1 * 8 + 1), isTrue);
    expect(buffer.collisionAt(1 * 8 + 6), isTrue);
    for (var x = 2; x < 6; x++) {
      expect(buffer.collisionAt(1 * 8 + x), isFalse);
    }
  });

  test(
    'collision commit matches sequential canonical operations bit for bit',
    () {
      final source = _collisionMap(8);
      final buffer = MapCellStrokeBuffer.collision(
        sourceMap: source,
        layerId: 'collision',
      );
      buffer.setCollisions(
        origin: const GridPos(x: 1, y: 5),
        patternSize: const GridSize(width: 1, height: 1),
        value: true,
      );
      buffer.setCollisions(
        origin: const GridPos(x: 6, y: 5),
        patternSize: const GridSize(width: 1, height: 1),
        value: true,
      );

      var expected = source;
      for (var x = 1; x <= 6; x++) {
        expected = paintCollisionPatternOnLayer(
          expected,
          layerId: 'collision',
          pos: GridPos(x: x, y: 5),
          patternSize: const GridSize(width: 1, height: 1),
        );
      }

      expect(buffer.commit(validate: MapValidator.validate), expected);
    },
  );

  test('1 10 100 1000 samples stay sparse across target extents', () {
    const matrix = <int, int>{128: 1, 256: 10, 512: 100, 1024: 1000};

    for (final entry in matrix.entries) {
      final source = _collisionMap(entry.key);
      final buffer = MapCellStrokeBuffer.collision(
        sourceMap: source,
        layerId: 'collision',
      );
      for (var x = 0; x < entry.value; x++) {
        buffer.setCollisions(
          origin: GridPos(x: x, y: 0),
          patternSize: const GridSize(width: 1, height: 1),
          value: true,
        );
      }
      expect(buffer.touchedCellCount, entry.value);
      expect(buffer.fullLayerCopyCount, 0);
      expect(buffer.mapMaterializationCount, 0);
      final committed = buffer.commit(validate: MapValidator.validate);
      expect(buffer.fullLayerCopyCount, 1);
      expect(buffer.mapMaterializationCount, 1);
      expect(
        (committed.layers.single as CollisionLayer).collisions.where((v) => v),
        hasLength(entry.value),
      );
    }
  });
}

MapData _tileMap(int extent) => MapData(
  id: 'tile-$extent',
  name: 'Tile $extent',
  size: GridSize(width: extent, height: extent),
  layers: <MapLayer>[
    MapLayer.tile(
      id: 'ground',
      name: 'Ground',
      cells: List<int>.filled(extent * extent, 0, growable: false),
    ),
  ],
);

MapData _collisionMap(int extent) => MapData(
  id: 'collision-$extent',
  name: 'Collision $extent',
  size: GridSize(width: extent, height: extent),
  layers: <MapLayer>[
    MapLayer.collision(
      id: 'collision',
      name: 'Collision',
      collisions: List<bool>.filled(extent * extent, false, growable: false),
    ),
  ],
);
