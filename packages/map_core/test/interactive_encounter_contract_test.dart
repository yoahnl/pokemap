import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _entity() => {
  ...const MapEntity(
    id: 'tree',
    kind: MapEntityKind.custom,
    pos: GridPos(x: 2, y: 1),
  ).toJson(),
  'interactiveEncounter': {
    'trigger': 'headbutt',
    'encounterTableId': 'tree-table',
    'reusePolicy': 'oncePerMapInstance',
    'conditions': <Object>[],
    'presentation': const EncounterZonePayload(
      encounterTableId: 'tree-table',
      encounterKind: EncounterKind.headbutt,
    ).toJson(),
  },
};

void main() {
  test('interactive encounter payload survives the native entity wire', () {
    final json = _entity();
    expect(
      MapEntity.fromJson(json).toJson()['interactiveEncounter'],
      json['interactiveEncounter'],
    );
  });
  test(
    'interactive encounter rejects malformed payload and incompatible entities',
    () {
      for (final json in [
        {
          ..._entity(),
          'interactiveEncounter': {
            ..._entity()['interactiveEncounter'] as Map,
            'unknown': true,
          },
        },
        {..._entity(), 'kind': 'npc'},
        {..._entity(), 'blocksMovement': false},
        {
          ..._entity(),
          'size': {'width': 2, 'height': 1},
        },
        {
          ..._entity(),
          'fieldObstacle': const MapEntityFieldObstacleData().toJson(),
        },
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
    'strict presentation rejects unknown nested keys and mismatched table kind',
    () {
      final entity = _entity();
      final payload = Map<String, dynamic>.from(
        entity['interactiveEncounter'] as Map,
      );
      final presentation = Map<String, dynamic>.from(
        payload['presentation'] as Map,
      );
      for (final raw in [
        {...presentation, 'unknown': true},
        {...presentation, 'encounterKind': 'special'},
        {...presentation, 'encounterTableId': 'other'},
      ]) {
        expect(
          () => MapEntity.fromJson({
            ...entity,
            'interactiveEncounter': {...payload, 'presentation': raw},
          }),
          throwsFormatException,
        );
      }
      final rock = {
        ...entity,
        'fieldObstacle': const MapEntityFieldObstacleData(
          kind: FieldObstacleKind.rockSmashRock,
        ).toJson(),
        'interactiveEncounter': MapEntityInteractiveEncounterData(
          trigger: InteractiveEncounterTrigger.afterRockSmash,
          encounterTableId: 'rocks',
        ).toJson(),
      };
      expect(
        MapEntity.fromJson(rock).interactiveEncounter?.trigger,
        InteractiveEncounterTrigger.afterRockSmash,
      );
    },
  );
  test(
    'consumed identities are immutable, sorted, unique and instance scoped',
    () {
      final ids = <String>{'b', 'a'};
      final original = MapInstanceRuntimeState(
        instanceId: 'i',
        consumedInteractiveEncounterEntityIds: ids,
      );
      ids.clear();
      expect(original.toJson()['consumedInteractiveEncounterEntityIds'], [
        'a',
        'b',
      ]);
      expect(
        () => original.consumedInteractiveEncounterEntityIds.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => MapInstanceRuntimeState.fromJson({
          ...original.toJson(),
          'consumedInteractiveEncounterEntityIds': ['a', 'a'],
        }),
        throwsFormatException,
      );
      expect(MapInstanceRuntimeState.fromJson(original.toJson()), original);
      expect(
        MapInstanceRuntimeState.fromJson(original.toJson()).hashCode,
        original.hashCode,
      );
    },
  );
  test('instance state6 persists consumed encounters and rejects older states', () {
    final json = {
      'schemaVersion': 6,
      'instancesByMapId': {
        'route': {
          ...MapInstanceRuntimeState(instanceId: 'r1').toJson(),
          'consumedInteractiveEncounterEntityIds': ['tree'],
        },
      },
    };
    expect(MapInstanceWorldState.fromJson(json).toJson(), json);
    expect(
      () => MapInstanceWorldState.fromJson({
        'schemaVersion': 4,
        'instancesByMapId': {},
      }),
      throwsFormatException,
    );
    expect(
      () => MapInstanceWorldState.fromJson({
        'schemaVersion': 5,
        'instancesByMapId': {},
      }),
      throwsFormatException,
    );
  });
}
