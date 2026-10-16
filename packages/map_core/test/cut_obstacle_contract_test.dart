import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _entityJson() => {
  ...const MapEntity(
    id: 'tree',
    kind: MapEntityKind.custom,
    pos: GridPos(x: 2, y: 1),
  ).toJson(),
  'fieldObstacle': {'kind': 'cutTree', 'resetPolicy': 'mapInstance'},
};

void main() {
  test(
    'instance NPC positions remain typed and survive every obstacle and event setter',
    () {
      var state = MapInstanceWorldState(
        instancesByMapId: {'route': MapInstanceRuntimeState(instanceId: 'r1')},
      );
      final scope = state.instanceRef('route')!;
      state = state
          .setNpcPositions(scope, const {'walker': GridPos(x: 4, y: 2)})
          .activateStrength(scope)
          .moveFieldObstacle(scope, 'rock', const GridPos(x: 3, y: 1))
          .clearFieldObstacle(scope, 'tree')
          .setEventBoolean(scope, 'door', 'A', true);
      final restored = MapInstanceWorldState.fromJson(state.toJson());
      expect(restored, state);
      expect(restored.instancesByMapId['route']!.npcPositions, {
        'walker': const GridPos(x: 4, y: 2),
      });
      expect(
        () => restored.instancesByMapId['route']!.npcPositions.clear(),
        throwsUnsupportedError,
      );
    },
  );

  for (final entry in const {
    'cutTree': FieldAbility.cut,
    'strengthBoulder': FieldAbility.strength,
    'rockSmashRock': FieldAbility.rockSmash,
  }.entries) {
    test('native obstacle wire supports ${entry.key}', () {
      final obstacle = MapEntityFieldObstacleData.fromJson({
        'kind': entry.key,
        'resetPolicy': 'mapInstance',
      });
      expect(obstacle.ability, entry.value);
      expect(obstacle.toJson()['kind'], entry.key);
    });
  }
  test('old schema2 state is rejected explicitly', () {
    expect(
      () => MapInstanceWorldState.fromJson({
        'schemaVersion': 2,
        'instancesByMapId': {},
      }),
      throwsFormatException,
    );
  });

  for (final position in [
    null,
    true,
    [],
    {'x': 1},
    {'x': 1.0, 'y': 1},
    {'x': -1, 'y': 0},
    {'x': 1, 'y': 1, 'z': 0},
  ]) {
    test('typed position wire refuses malformed $position', () {
      expect(
        () => MapInstanceWorldState.fromJson({
          'schemaVersion': 4,
          'instancesByMapId': {
            'route': {
              'instanceId': 'r1',
              'clearedFieldObstacleIds': [],
              'eventBooleans': {},
              'npcPositions': {},
              'strengthActive': true,
              'illuminatedZoneIds': <String>[],
              'fieldObstaclePositions': {'rock': position},
            },
          },
        }),
        throwsFormatException,
      );
    });
  }
  test(
    'typed obstacle positions are immutable and reject negative coordinates',
    () {
      final positions = {'rock': const GridPos(x: 3, y: 1)};
      final instance = MapInstanceRuntimeState(
        instanceId: 'r1',
        fieldObstaclePositions: positions,
      );
      positions.clear();
      expect(instance.fieldObstaclePositions, {
        'rock': const GridPos(x: 3, y: 1),
      });
      expect(
        () => instance.fieldObstaclePositions.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => MapInstanceRuntimeState(
          instanceId: 'r1',
          fieldObstaclePositions: const {'rock': GridPos(x: -1, y: 1)},
        ),
        throwsArgumentError,
      );
    },
  );
  test('typed Cut obstacle survives the native entity wire format', () {
    final json = _entityJson();
    expect(
      MapEntity.fromJson(json).toJson()['fieldObstacle'],
      json['fieldObstacle'],
    );
  });
  test(
    'obstacle wire rejects unknown formats and unsupported entity shapes',
    () {
      for (final json in [
        {
          ..._entityJson(),
          'fieldObstacle': {
            'kind': 'unknownObstacle',
            'resetPolicy': 'mapInstance',
          },
        },
        {
          ..._entityJson(),
          'fieldObstacle': {'kind': 'cutTree', 'resetPolicy': 'permanent'},
        },
        {
          ..._entityJson(),
          'fieldObstacle': {
            'kind': 'cutTree',
            'resetPolicy': 'mapInstance',
            'unknown': true,
          },
        },
        {..._entityJson(), 'kind': 'npc'},
        {
          ..._entityJson(),
          'size': {'width': 2, 'height': 1},
        },
        {..._entityJson(), 'blocksMovement': false},
      ]) {
        expect(
          () => MapEntity.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    },
  );
  test(
    'instance state v4 persists cleared obstacles alongside event booleans',
    () {
      final json = <String, dynamic>{
        'schemaVersion': 4,
        'instancesByMapId': {
          'route': {
            'instanceId': 'route-1',
            'eventBooleans': {
              'door': {'A': true},
            },
            'clearedFieldObstacleIds': ['tree'],
            'fieldObstaclePositions': {
              'boulder': {'x': 3, 'y': 1},
            },
            'npcPositions': {},
            'strengthActive': true,
            'illuminatedZoneIds': <String>[],
          },
        },
      };
      expect(() => MapInstanceWorldState.fromJson(json), returnsNormally);
      expect(MapInstanceWorldState.fromJson(json).toJson(), json);
    },
  );
  test('instance state v1 is explicitly unsupported without migration', () {
    expect(
      () => MapInstanceWorldState.fromJson({
        'schemaVersion': 1,
        'instancesByMapId': {},
      }),
      throwsFormatException,
    );
  });
  test(
    'cleared obstacle identities are immutable and scoped beside door state',
    () {
      final ids = <String>{'first'};
      final original = MapInstanceWorldState(
        instancesByMapId: {
          'route': MapInstanceRuntimeState(
            instanceId: 'route-1',
            clearedFieldObstacleIds: ids,
          ),
          'other': MapInstanceRuntimeState(instanceId: 'other-1'),
        },
      );
      ids.clear();
      final scope = original.instanceRef('route')!;
      expect(original.isFieldObstacleCleared(scope, 'first'), isTrue);
      expect(
        () =>
            original.instancesByMapId['route']!.clearedFieldObstacleIds.clear(),
        throwsUnsupportedError,
      );
      final cleared = original.clearFieldObstacle(scope, 'tree');
      final door = cleared.setEventBoolean(scope, 'door', 'A', true);
      expect(door.isFieldObstacleCleared(scope, 'tree'), isTrue);
      expect(door.eventBoolean(scope, 'door', 'A'), isTrue);
      expect(
        door.isFieldObstacleCleared(door.instanceRef('other')!, 'tree'),
        isFalse,
      );
      expect(identical(door.clearFieldObstacle(scope, 'tree'), door), isTrue);
      final saved = GameState(saveId: 'cut', mapInstanceWorldState: door);
      expect(GameState.fromJson(saved.toJson()).mapInstanceWorldState, door);
    },
  );
  test('stale map instance identities cannot inspect or clear obstacles', () {
    final state = MapInstanceWorldState(
      instancesByMapId: {
        'route': MapInstanceRuntimeState(instanceId: 'route-2'),
      },
    );
    final stale = MapInstanceRef(mapId: 'route', instanceId: 'route-1');
    expect(() => state.clearFieldObstacle(stale, 'tree'), throwsStateError);
    expect(() => state.isFieldObstacleCleared(stale, 'tree'), throwsStateError);
  });
  for (final raw in [
    null,
    true,
    'tree',
    [null],
    [1],
    ['tree', 'tree'],
    [' padded'],
    [''],
  ]) {
    test('instance v4 rejects malformed cleared obstacle identities $raw', () {
      expect(
        () => MapInstanceWorldState.fromJson({
          'schemaVersion': 4,
          'instancesByMapId': {
            'route': {
              'instanceId': 'route-1',
              'eventBooleans': {},
              'clearedFieldObstacleIds': raw,
              'fieldObstaclePositions': {},
              'npcPositions': {},
              'strengthActive': false,
              'illuminatedZoneIds': <String>[],
            },
          },
        }),
        throwsFormatException,
      );
    });
  }
  test(
    'canonical map validation rejects malformed typed obstacles and spatial use',
    () {
      final valid = MapEntity.fromJson(_entityJson());
      MapData map(MapEntity entity) => MapData(
        id: 'route',
        name: 'Route',
        size: const GridSize(width: 5, height: 4),
        entities: [entity],
      );
      MapValidator.validate(map(valid));
      for (final malformed in [
        valid.copyWith(kind: MapEntityKind.npc),
        valid.copyWith(blocksMovement: false),
        valid.copyWith(size: const GridSize(width: 2, height: 1)),
      ]) {
        expect(
          () => MapValidator.validate(map(malformed)),
          throwsA(isA<ValidationException>()),
        );
      }
      expect(
        () => MapValidator.validate(
          map(valid).copyWith(version: ProjectVersion.v9),
        ),
        throwsFormatException,
      );
      expect(
        () => MapValidator.validate(
          map(valid).copyWith(
            version: ProjectVersion.v9,
            spatialScene: MapSpatialScene(width: 5, depth: 4),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'canonical entity update preserves, sets and explicitly clears Cut data',
    () {
      final entity = MapEntity.fromJson(_entityJson());
      final map = MapData(
        id: 'route',
        name: 'Route',
        size: const GridSize(width: 5, height: 4),
        entities: [entity],
      );
      final renamed = updateEntityOnMap(map, entityId: 'tree', name: 'Renamed');
      expect(renamed.entities.single.fieldObstacle, entity.fieldObstacle);
      final cleared = updateEntityOnMap(
        renamed,
        entityId: 'tree',
        fieldObstacle: null,
      );
      expect(cleared.entities.single.fieldObstacle, isNull);
      final set = updateEntityOnMap(
        cleared,
        entityId: 'tree',
        fieldObstacle: const MapEntityFieldObstacleData(),
      );
      expect(set.entities.single.fieldObstacle, entity.fieldObstacle);
      expect(set.entities.single.name, 'Renamed');
      expect(map.entities.single.fieldObstacle, entity.fieldObstacle);
    },
  );

  test('one-cell Cut collision clamps metadata after native JSON decoding', () {
    for (final properties in const [
      {'collision.width': '2', 'collision.height': '2'},
      {'collision.offsetX': '1', 'collision.offsetY': '1'},
    ]) {
      final entity = MapEntity.fromJson({
        ..._entityJson(),
        'properties': properties,
      });
      expect(resolveEntityCollisionCells(entity), [entity.pos]);
      MapValidator.validate(
        MapData(
          id: 'route',
          name: 'Route',
          size: const GridSize(width: 5, height: 4),
          entities: [entity],
        ),
      );
      final rect = resolveEntityCollisionRectPx(
        entity,
        tileWidthPx: 16,
        tileHeightPx: 16,
      );
      expect(
        [rect.leftPx, rect.topPx, rect.widthPx, rect.heightPx],
        [entity.pos.x * 16, entity.pos.y * 16, 16, 16],
      );
    }
  });

  test(
    'an absent field obstacle does not add a payload to ordinary entities',
    () {
      expect(
        const MapEntity(
          id: 'ordinary',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 0, y: 0),
        ).toJson().containsKey('fieldObstacle'),
        isFalse,
      );
    },
  );
}
