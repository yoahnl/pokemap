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
            delta = MapMutationDelta.placedElement(
              instance: instance,
              instanceIndex: map.placedElements.indexWhere(
                (candidate) => candidate.id == instance.id,
              ),
            );
        }

        final receipt = MapDeltaValidator.validate(
          DeltaValidationContext(before: before, after: map, delta: delta),
        );

        expect(receipt.inspectedCellCount, lessThanOrEqualTo(9));
        MapValidator.validate(map);
      }
    });

    test(
      'defers undeclared resources outside the delta to full validation',
      () {
        final before = _map(1024);
        final ground = before.layers.whereType<TileLayer>().single;
        final collision = before.layers.whereType<CollisionLayer>().single;
        final layers = List<MapLayer>.of(before.layers);
        layers[before.layers.indexOf(ground)] = ground.copyWith(
          cells: <int>[...ground.cells]..[0] = 1,
        );
        layers[before.layers.indexOf(collision)] = collision.copyWith(
          collisions: collision.collisions.sublist(1),
        );
        final after = before.copyWith(
          layers: layers,
          entities: const <MapEntity>[
            MapEntity(
              id: '',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 0, y: 0),
            ),
          ],
        );

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

        expect(receipt.inspectedLayerCount, 1);
        expect(
          () => MapValidator.validate(after),
          throwsA(isA<ValidationException>()),
        );
      },
    );

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

      final duplicatePaletteLayers = List<MapLayer>.of(before.layers);
      duplicatePaletteLayers[before.layers.indexOf(tile)] = tile.copyWith(
        palette: <TileLayerPaletteEntry>[...tile.palette, tile.palette.single],
        cells: <int>[...tile.cells]..[3] = 2,
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: duplicatePaletteLayers),
            delta: const MapMutationDelta.tileCells(
              layerId: 'ground',
              cellIndices: <int>{3},
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      final invalidPaletteLayers = List<MapLayer>.of(before.layers);
      invalidPaletteLayers[before.layers.indexOf(tile)] = tile.copyWith(
        palette: <TileLayerPaletteEntry>[
          ...tile.palette,
          const TileLayerPaletteEntry(tilesetId: '', localTileId: 1),
        ],
        cells: <int>[...tile.cells]..[3] = 2,
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: invalidPaletteLayers),
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

      final duplicateMaterialLayers = List<MapLayer>.of(before.layers);
      duplicateMaterialLayers[before.layers.indexOf(smart)] = smart.copyWith(
        materialPalette: <String>[...smart.materialPalette, 'grass'],
        field: field.copyWith(
          semanticCells: <int>[...field.semanticCells]..[2] = 2,
        ),
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: duplicateMaterialLayers),
            delta: const MapMutationDelta.smartTileCells(
              layerId: 'smart',
              cellIndices: <int>{2},
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      final invalidMaterialLayers = List<MapLayer>.of(before.layers);
      invalidMaterialLayers[before.layers.indexOf(smart)] = smart.copyWith(
        materialPalette: <String>[...smart.materialPalette, ''],
        field: field.copyWith(
          semanticCells: <int>[...field.semanticCells]..[2] = 2,
        ),
      );
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: before,
            after: before.copyWith(layers: invalidMaterialLayers),
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
            delta: MapMutationDelta.placedElement(
              instance: placed.placedElements.single,
              instanceIndex: 0,
            ),
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
        expect(receipt.inspectedLayerCount, 1);
      }
    });

    test('reports only the layer and resources declared by each delta', () {
      final before = _map(8);
      final tile = before.layers.whereType<TileLayer>().single;
      final tileAfter = paintTileOnLayer(
        before,
        layerId: tile.id,
        pos: const GridPos(x: 0, y: 0),
        tile: tile.palette.single,
      );
      final tileReceipt = MapDeltaValidator.validate(
        DeltaValidationContext(
          before: before,
          after: tileAfter,
          delta: const MapMutationDelta.tileCells(
            layerId: 'ground',
            cellIndices: <int>{0},
          ),
        ),
      );

      expect(tileReceipt.inspectedLayerCount, 1);
      expect(tileReceipt.inspectedResourceCount, 1);

      final smart = before.layers.whereType<SmartTileLayer>().single;
      final smartAfter = replaceSmartTileLayer(
        before,
        layer: applySmartTileMaterialGesture(
          smart,
          mapSize: before.size,
          cells: const <GridPos>[GridPos(x: 0, y: 0)],
          materialId: 'grass',
        ),
      );
      final smartReceipt = MapDeltaValidator.validate(
        DeltaValidationContext(
          before: before,
          after: smartAfter,
          delta: const MapMutationDelta.smartTileCells(
            layerId: 'smart',
            cellIndices: <int>{0},
          ),
        ),
      );

      expect(smartReceipt.inspectedLayerCount, 1);
      expect(smartReceipt.inspectedResourceCount, 1);

      final placements = <MapPlacedElement>[
        for (var index = 0; index < 32; index++)
          MapPlacedElement(
            id: 'existing-$index',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: index % 8, y: index ~/ 8),
          ),
      ];
      final placementBefore = before.copyWith(placedElements: placements);
      const placed = MapPlacedElement(
        id: 'placed',
        layerId: 'ground',
        elementId: 'tree',
        pos: GridPos(x: 7, y: 7),
      );
      final placementAfter = upsertMapPlacedElement(
        placementBefore,
        instance: placed,
      );
      final placementReceipt = MapDeltaValidator.validate(
        DeltaValidationContext(
          before: placementBefore,
          after: placementAfter,
          delta: const MapMutationDelta.placedElement(
            instance: placed,
            instanceIndex: 32,
          ),
        ),
      );

      expect(placementReceipt.inspectedLayerCount, 1);
      expect(placementReceipt.inspectedResourceCount, 1);
      expect(placementReceipt.inspectedPlacedElementCount, 1);
      expect(
        () => MapDeltaValidator.validate(
          DeltaValidationContext(
            before: placementBefore,
            after: placementAfter,
            delta: const MapMutationDelta.placedElement(
              instance: placed,
              instanceIndex: 0,
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
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
