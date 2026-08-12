import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapDeltaValidator', () {
    test('matches full validation for randomized local mutations', () {
      final random = Random(5005);
      var map = _map(32);
      MapValidator.validate(map);

      for (var iteration = 0; iteration < 200; iteration++) {
        final x = random.nextInt(map.size.width);
        final y = random.nextInt(map.size.height);
        final cellIndex = y * map.size.width + x;
        final before = map;
        final mutationKind = random.nextInt(4);
        late final MapMutationDelta delta;

        switch (mutationKind) {
          case 0:
            map = paintTileOnLayer(
              map,
              layerId: 'ground',
              pos: GridPos(x: x, y: y),
              tile: TileLayerPaletteEntry(
                tilesetId: 'world',
                localTileId: random.nextInt(16),
              ),
            );
            delta = MapMutationDelta.tileCells(
              layerId: 'ground',
              cellIndices: <int>{cellIndex},
            );
          case 1:
            map = random.nextBool()
                ? paintCollisionOnLayer(
                    map,
                    layerId: 'collision',
                    pos: GridPos(x: x, y: y),
                  )
                : eraseCollisionOnLayer(
                    map,
                    layerId: 'collision',
                    pos: GridPos(x: x, y: y),
                  );
            delta = MapMutationDelta.collisionCells(
              layerId: 'collision',
              cellIndices: <int>{cellIndex},
            );
          case 2:
            final smartLayer = map.layers.whereType<SmartTileLayer>().single;
            final updatedLayer = applySmartTileMaterialGesture(
              smartLayer,
              mapSize: map.size,
              cells: <GridPos>[GridPos(x: x, y: y)],
              materialId: random.nextBool() ? 'grass' : null,
            );
            map = replaceSmartTileLayer(map, layer: updatedLayer);
            delta = MapMutationDelta.smartTileCells(
              layerId: 'smart',
              cellIndices: <int>{cellIndex},
            );
          case 3:
            final instance = MapPlacedElement(
              id: 'placed-${iteration % 8}',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: x, y: y),
              quarterTurns: random.nextInt(4),
            );
            map = upsertMapPlacedElement(map, instance: instance);
            delta = MapMutationDelta.placedElement(instanceId: instance.id);
        }

        final receipt = MapDeltaValidator.validate(
          DeltaValidationContext(before: before, after: map, delta: delta),
        );

        expect(receipt.inspectedCellCount, lessThanOrEqualTo(9));
        MapValidator.validate(map);
      }
    });

    test('rejects an undeclared layer mutation without scanning its cells', () {
      final before = _map(1024);
      final ground = before.layers.whereType<TileLayer>().single;
      final collision = before.layers.whereType<CollisionLayer>().single;
      final layers = List<MapLayer>.of(before.layers);
      layers[before.layers.indexOf(ground)] = ground.copyWith(
        cells: <int>[...ground.cells]..[0] = 1,
      );
      layers[before.layers.indexOf(collision)] = collision.copyWith(
        collisions: <bool>[...collision.collisions]..[1] = true,
      );
      final after = before.copyWith(layers: layers);

      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: after,
            delta: const MapMutationDelta.tileCells(
              layerId: 'ground',
              cellIndices: <int>{0},
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'validates only declared cells while full boundary catches corruption',
      () {
        final before = _map(128);
        final layer = before.layers.whereType<TileLayer>().single;
        final cells = List<int>.of(layer.cells);
        cells[0] = 1;
        cells[cells.length - 1] = 999;
        final layers = List<MapLayer>.of(before.layers);
        layers[before.layers.indexOf(layer)] = layer.copyWith(cells: cells);
        final after = before.copyWith(layers: layers);

        final receipt = MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: after,
            delta: const MapMutationDelta.tileCells(
              layerId: 'ground',
              cellIndices: <int>{0},
            ),
          ),
        );

        expect(receipt.inspectedCellCount, 1);
        expect(
          () => MapValidator.validate(after),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('rejects invalid values in each touched resource', () {
      final before = _map(4);
      final tile = before.layers.whereType<TileLayer>().single;
      final tileLayers = List<MapLayer>.of(before.layers);
      tileLayers[before.layers.indexOf(tile)] = tile.copyWith(
        cells: <int>[...tile.cells]..[3] = 999,
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: tileLayers),
            delta: const MapMutationDelta.tileCells(
              layerId: 'ground',
              cellIndices: <int>{3},
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      final smart = before.layers.whereType<SmartTileLayer>().single;
      final field = smart.field as SmartTileMixedField;
      final smartLayers = List<MapLayer>.of(before.layers);
      smartLayers[before.layers.indexOf(smart)] = smart.copyWith(
        field: field.copyWith(
          semanticCells: <int>[...field.semanticCells]..[2] = 999,
        ),
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: smartLayers),
            delta: const MapMutationDelta.smartTileCells(
              layerId: 'smart',
              cellIndices: <int>{2},
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      final invalidTopologyLayers = List<MapLayer>.of(before.layers);
      invalidTopologyLayers[before.layers.indexOf(smart)] = smart.copyWith(
        field: field.copyWith(horizontalEdges: const <int>[]),
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: invalidTopologyLayers),
            delta: const MapMutationDelta.smartTileCells(
              layerId: 'smart',
              cellIndices: <int>{2},
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      final placed = before.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'bad',
            layerId: 'ground',
            elementId: '',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: placed,
            delta: const MapMutationDelta.placedElement(instanceId: 'bad'),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('work count depends on the delta rather than map surface', () {
      for (final extent in <int>[128, 256, 512, 1024]) {
        final before = _map(extent);
        final after = paintCollisionOnLayer(
          before,
          layerId: 'collision',
          pos: GridPos(x: extent - 1, y: extent - 1),
        );
        final receipt = MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: after,
            delta: MapMutationDelta.collisionCells(
              layerId: 'collision',
              cellIndices: <int>{extent * extent - 1},
            ),
          ),
        );

        expect(receipt.inspectedCellCount, 1);
        expect(receipt.inspectedLayerCount, before.layers.length);
      }
    });
  });
}

MapData _map(int extent) {
  final cellCount = extent * extent;
  final horizontalCount = extent * (extent + 1);
  final verticalCount = (extent + 1) * extent;
  final cornerCount = (extent + 1) * (extent + 1);
  return MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: extent, height: extent),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        palette: const <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: 'world', localTileId: 0),
        ],
        cells: List<int>.filled(cellCount, 0),
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: List<bool>.filled(cellCount, false),
      ),
      MapLayer.smartTile(
        id: 'smart',
        name: 'Smart',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: const <String>['', 'grass'],
        field: SmartTileField.mixed(
          semanticCells: List<int>.filled(cellCount, 0),
          horizontalEdges: List<int>.filled(horizontalCount, 0),
          verticalEdges: List<int>.filled(verticalCount, 0),
          corners: List<int>.filled(cornerCount, 0),
        ),
      ),
    ],
  );
}
