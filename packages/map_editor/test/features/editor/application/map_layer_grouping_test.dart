import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_layer_grouping.dart';

void main() {
  const service = MapLayerGroupService();

  group('MapLayerGroupService', () {
    test(
      'exposes top-first groups with every valid Environment attachment',
      () {
        final map = _interleavedMap();

        final groups = service.groupsTopFirst(map);

        expect(
          groups.map((group) => group.primaryLayer.id),
          const <String>['top', 'middle', 'tile-a', 'orphan', 'bottom'],
        );
        final tileGroup =
            groups.singleWhere((group) => group.primaryLayer.id == 'tile-a');
        expect(tileGroup.isTileEnvironmentGroup, isTrue);
        expect(
          tileGroup.attachedEnvironmentLayersTopFirst.map((layer) => layer.id),
          const <String>['env-a-2', 'env-a-1'],
        );
        expect(
          tileGroup.membersTopFirst.map((layer) => layer.id),
          const <String>['env-a-2', 'tile-a', 'env-a-1'],
        );
        expect(
          tileGroup.membersTopFirst.map((layer) => map.layers.indexOf(layer)),
          orderedEquals(<int>[1, 3, 5]),
        );
      },
    );

    test('keeps every orphan or invalid Environment as a standalone group', () {
      final map = _mapWithInvalidEnvironments();

      final groups = service.groupsTopFirst(map);

      expect(
        groups.map((group) => group.primaryLayer.id),
        const <String>[
          'no-target',
          'missing-target',
          'non-tile-target',
          'objects',
          'tile-a',
        ],
      );
      for (final id in const <String>[
        'no-target',
        'missing-target',
        'non-tile-target',
      ]) {
        final group =
            groups.singleWhere((entry) => entry.primaryLayer.id == id);
        expect(group.membersTopFirst, hasLength(1), reason: id);
        expect(group.primaryLayer, isA<EnvironmentLayer>(), reason: id);
        expect(group.isTileEnvironmentGroup, isFalse, reason: id);
      }
      expect(
        groups
            .singleWhere((entry) => entry.primaryLayer.id == 'tile-a')
            .attachedEnvironmentLayersTopFirst,
        isEmpty,
      );
    });

    test('moves a whole Tile and Environment group one row up or down', () {
      final map = _orderedMap();

      final movedUp = service.moveAdjacent(
        map: map,
        layerId: 'tile-a',
        direction: MapLayerGroupMoveDirection.up,
      );
      final movedDown = service.moveAdjacent(
        map: map,
        layerId: 'tile-a',
        direction: MapLayerGroupMoveDirection.down,
      );
      final movedByAttachedId = service.moveAdjacent(
        map: map,
        layerId: 'env-a-1',
        direction: MapLayerGroupMoveDirection.down,
      );

      expect(
        _layerIds(movedUp),
        const <String>[
          'tile-a',
          'env-a-1',
          'env-a-2',
          'top',
          'middle',
          'bottom',
        ],
      );
      expect(
        _layerIds(movedDown),
        const <String>[
          'top',
          'middle',
          'tile-a',
          'env-a-1',
          'env-a-2',
          'bottom',
        ],
      );
      expect(movedByAttachedId, movedDown);
    });

    test('does not move the first group up or the last group down', () {
      final map = _orderedMap();

      final aboveTop = service.moveAdjacent(
        map: map,
        layerId: 'top',
        direction: MapLayerGroupMoveDirection.up,
      );
      final belowBottom = service.moveAdjacent(
        map: map,
        layerId: 'bottom',
        direction: MapLayerGroupMoveDirection.down,
      );

      expect(aboveTop, same(map));
      expect(belowBottom, same(map));
    });

    test(
      'an interleaved group becomes one block without changing member order',
      () {
        final map = _interleavedMap();

        final moved = service.moveAdjacent(
          map: map,
          layerId: 'tile-a',
          direction: MapLayerGroupMoveDirection.up,
        );

        expect(
          _layerIds(moved),
          const <String>[
            'top',
            'env-a-2',
            'tile-a',
            'env-a-1',
            'middle',
            'orphan',
            'bottom',
          ],
        );
        expect(moved.copyWith(layers: map.layers), map);
        expect(
          moved.layers.map((layer) => layer.id).toSet(),
          map.layers.map((layer) => layer.id).toSet(),
        );
        for (final original in map.layers) {
          expect(
            moved.layers.singleWhere((layer) => layer.id == original.id),
            same(original),
            reason: original.id,
          );
        }
      },
    );

    test('drag before an index or a group matches the adjacent move', () {
      final map = _orderedMap();
      final adjacent = service.moveAdjacent(
        map: map,
        layerId: 'tile-a',
        direction: MapLayerGroupMoveDirection.down,
      );

      final beforeIndex = service.moveBeforeGroupIndex(
        map: map,
        layerId: 'tile-a',
        beforeGroupIndex: 3,
      );
      final beforeGroup = service.moveBeforeGroup(
        map: map,
        layerId: 'tile-a',
        beforeLayerId: 'bottom',
      );

      expect(beforeIndex, adjacent);
      expect(beforeGroup, adjacent);
    });

    test('supports drag slots at the very top and bottom', () {
      final map = _orderedMap();

      final atTop = service.moveBeforeGroupIndex(
        map: map,
        layerId: 'middle',
        beforeGroupIndex: 0,
      );
      final groupCount = service.groupsTopFirst(map).length;
      final atBottom = service.moveBeforeGroupIndex(
        map: map,
        layerId: 'tile-a',
        beforeGroupIndex: groupCount,
      );

      expect(
        _layerIds(atTop),
        const <String>[
          'middle',
          'top',
          'tile-a',
          'env-a-1',
          'env-a-2',
          'bottom',
        ],
      );
      expect(
        _layerIds(atBottom),
        const <String>[
          'top',
          'middle',
          'bottom',
          'tile-a',
          'env-a-1',
          'env-a-2',
        ],
      );
    });

    test('same-group drag targets are exact no-ops', () {
      final map = _orderedMap();

      final beforeSelf = service.moveBeforeGroup(
        map: map,
        layerId: 'env-a-2',
        beforeLayerId: 'tile-a',
      );
      final alreadyBeforeNext = service.moveBeforeGroup(
        map: map,
        layerId: 'tile-a',
        beforeLayerId: 'middle',
      );

      expect(beforeSelf, same(map));
      expect(alreadyBeforeNext, same(map));
    });

    test(
      'duplicate Environment ids never duplicate serialized layer instances',
      () {
        final firstEnvironment = _environment('duplicate', 'tile-a');
        final secondEnvironment = _environment('duplicate', 'tile-b');
        final map = MapData(
          id: 'invalid-duplicate-environment-ids',
          name: 'Invalid duplicate Environment ids',
          size: const GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            _tile('tile-a'),
            firstEnvironment,
            _tile('tile-b'),
            secondEnvironment,
            const ObjectLayer(id: 'bottom', name: 'Bottom'),
          ],
        );

        final moved = service.moveAdjacent(
          map: map,
          layerId: 'tile-b',
          direction: MapLayerGroupMoveDirection.down,
        );

        expect(moved.layers, hasLength(map.layers.length));
        expect(
          moved.layers,
          orderedEquals(<MapLayer>[
            map.layers[0],
            firstEnvironment,
            map.layers[4],
            map.layers[2],
            secondEnvironment,
          ]),
        );
        for (final original in map.layers) {
          expect(
            moved.layers.where((layer) => identical(layer, original)),
            hasLength(1),
          );
        }
      },
    );

    test('rejects stale identifiers and invalid drag slots', () {
      final map = _orderedMap();

      expect(
        () => service.moveAdjacent(
          map: map,
          layerId: 'missing',
          direction: MapLayerGroupMoveDirection.up,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.moveBeforeGroup(
          map: map,
          layerId: 'tile-a',
          beforeLayerId: 'missing',
        ),
        throwsArgumentError,
      );
      expect(
        () => service.moveBeforeGroupIndex(
          map: map,
          layerId: 'tile-a',
          beforeGroupIndex: -1,
        ),
        throwsRangeError,
      );
      expect(
        () => service.moveBeforeGroupIndex(
          map: map,
          layerId: 'tile-a',
          beforeGroupIndex: service.groupsTopFirst(map).length + 1,
        ),
        throwsRangeError,
      );
    });
  });
}

MapData _orderedMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    properties: const <String, String>{'preserve': 'exactly'},
    layers: <MapLayer>[
      const ObjectLayer(id: 'top', name: 'Top'),
      _tile('tile-a'),
      _environment('env-a-1', 'tile-a'),
      _environment('env-a-2', 'tile-a'),
      const ObjectLayer(id: 'middle', name: 'Middle'),
      const ObjectLayer(id: 'bottom', name: 'Bottom'),
    ],
  );
}

MapData _interleavedMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    properties: const <String, String>{'preserve': 'exactly'},
    layers: <MapLayer>[
      const ObjectLayer(id: 'top', name: 'Top'),
      _environment('env-a-2', 'tile-a'),
      const ObjectLayer(id: 'middle', name: 'Middle'),
      _tile('tile-a'),
      _environment('orphan', 'missing'),
      _environment('env-a-1', 'tile-a'),
      const ObjectLayer(id: 'bottom', name: 'Bottom'),
    ],
  );
}

MapData _mapWithInvalidEnvironments() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      _environment('no-target', null),
      _environment('missing-target', 'missing'),
      _environment('non-tile-target', 'objects'),
      const ObjectLayer(id: 'objects', name: 'Objects'),
      _tile('tile-a'),
    ],
  );
}

TileLayer _tile(String id) {
  return TileLayer(id: id, name: id, cells: const <int>[0]);
}

EnvironmentLayer _environment(String id, String? targetLayerId) {
  return EnvironmentLayer(
    id: id,
    name: id,
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  );
}

List<String> _layerIds(MapData map) {
  return map.layers.map((layer) => layer.id).toList(growable: false);
}
