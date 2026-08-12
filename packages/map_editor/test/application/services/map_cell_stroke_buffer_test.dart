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

  test('Smart Tile samples stay sparse until one validated commit', () {
    final source = _smartTileMap(1024);
    final buffer = MapCellStrokeBuffer.smartTile(
      sourceMap: source,
      layerId: 'smart',
    );
    var validations = 0;

    for (var x = 0; x < 1000; x++) {
      buffer.setSmartTileMaterials(
        cells: <GridPos>[GridPos(x: x, y: 7)],
        materialId: 'grass',
      );
    }

    expect(buffer.touchedCellCount, 1000);
    expect(buffer.fullLayerCopyCount, 0);
    expect(buffer.mapMaterializationCount, 0);
    expect(buffer.validationCount, 0);
    expect(buffer.smartTileMaterialAt(999, 7), 'grass');

    final committed = buffer.commit(
      validate: (map) {
        validations += 1;
        MapValidator.validate(map);
      },
    );

    expect(buffer.fullLayerCopyCount, 1);
    expect(buffer.mapMaterializationCount, 1);
    expect(buffer.validationCount, 1);
    expect(validations, 1);
    expect(
      smartTileSemanticCells(
        committed.layers.single as SmartTileLayer,
      ).where((value) => value == 1),
      hasLength(1000),
    );
  });

  test('Smart Tile mixed commit matches sequential canonical gestures', () {
    final source = _smartTileMap(8, mixed: true);
    final buffer = MapCellStrokeBuffer.smartTile(
      sourceMap: source,
      layerId: 'smart',
    );
    buffer.setSmartTileMaterialAt(
      origin: const GridPos(x: 1, y: 3),
      materialId: 'grass',
    );
    buffer.setSmartTileMaterialAt(
      origin: const GridPos(x: 4, y: 3),
      materialId: 'grass',
    );
    buffer.breakInterpolation();
    buffer.setSmartTileMaterialAt(
      origin: const GridPos(x: 2, y: 3),
      materialId: null,
    );

    var expectedLayer = source.layers.single as SmartTileLayer;
    for (var x = 1; x <= 4; x++) {
      expectedLayer = applySmartTileMaterialGesture(
        expectedLayer,
        mapSize: source.size,
        cells: <GridPos>[GridPos(x: x, y: 3)],
        materialId: 'grass',
      );
    }
    expectedLayer = applySmartTileMaterialGesture(
      expectedLayer,
      mapSize: source.size,
      cells: const <GridPos>[GridPos(x: 2, y: 3)],
      materialId: null,
    );
    final expected = replaceSmartTileLayer(source, layer: expectedLayer);

    expect(buffer.commit(validate: MapValidator.validate), expected);
  });

  test('Smart Tile rebase preserves local cells over a canonical adoption', () {
    final source = _smartTileMap(8);
    final buffer = MapCellStrokeBuffer.smartTile(
      sourceMap: source,
      layerId: 'smart',
    );
    buffer.setSmartTileMaterials(
      cells: const <GridPos>[GridPos(x: 4, y: 2)],
      materialId: 'grass',
    );
    final sourceLayer = source.layers.single as SmartTileLayer;
    final adoptedLayer = applySmartTileMaterialGesture(
      sourceLayer,
      mapSize: source.size,
      cells: const <GridPos>[GridPos(x: 0, y: 0)],
      materialId: 'grass',
    );
    final adopted = replaceSmartTileLayer(source, layer: adoptedLayer);

    buffer.rebaseSmartTileSource(adopted);

    expect(buffer.sourceMap, same(adopted));
    expect(buffer.smartTileMaterialAt(0, 0), 'grass');
    expect(buffer.smartTileMaterialAt(4, 2), 'grass');
    expect(buffer.touchedCellCount, 1);
    final committed = buffer.commit(validate: MapValidator.validate);
    final cells = smartTileSemanticCells(
      committed.layers.single as SmartTileLayer,
    );
    expect(cells[0], 1);
    expect(cells[2 * 8 + 4], 1);
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

MapData _smartTileMap(int extent, {bool mixed = false}) => MapData(
  id: 'smart-$extent',
  name: 'Smart $extent',
  size: GridSize(width: extent, height: extent),
  layers: <MapLayer>[
    MapLayer.smartTile(
      id: 'smart',
      name: 'Smart',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: const <String>['', 'grass'],
      field: mixed
          ? SmartTileField.mixed(
              semanticCells: List<int>.filled(extent * extent, 0),
              horizontalEdges: List<int>.filled(extent * (extent + 1), 0),
              verticalEdges: List<int>.filled((extent + 1) * extent, 0),
              corners: List<int>.filled((extent + 1) * (extent + 1), 0),
            )
          : SmartTileField.cell(
              semanticCells: List<int>.filled(extent * extent, 0),
            ),
    ),
  ],
);
