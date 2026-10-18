import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _stateJson() => {
  'schemaVersion': 6,
  'instancesByMapId': {
    'room': <String, dynamic>{
      'instanceId': 'room-1',
      'eventBooleans': {},
      'clearedFieldObstacleIds': [],
      'consumedInteractiveEncounterEntityIds': [],
      'illuminatedZoneIds': [],
      'fieldObstaclePositions': {},
      'strengthActive': false,
      'npcPoses': {
        'guide': {
          'position': {'x': 4, 'y': 2},
          'facing': 'west',
        },
      },
    },
  },
};

void main() {
  test('state6 preserves one canonical NPC position and facing', () {
    final json = _stateJson();
    final state = MapInstanceWorldState.fromJson(json);
    expect(state.toJson(), json);
    expect(state.toJson().toString(), isNot(contains('npcPositions')));
  });
  test('state5 is rejected even when empty', () {
    expect(
      () => MapInstanceWorldState.fromJson({
        'schemaVersion': 5,
        'instancesByMapId': {},
      }),
      throwsFormatException,
    );
  });
  test(
    'NPC poses are immutable and facing-only updates survive all setters',
    () {
      final source = <String, MapInstanceNpcPose>{
        'guide': MapInstanceNpcPose(
          position: const GridPos(x: 4, y: 2),
          facing: EntityFacing.west,
        ),
      };
      var state = MapInstanceWorldState(
        instancesByMapId: {
          'room': MapInstanceRuntimeState(instanceId: 'r1', npcPoses: source),
          'other': MapInstanceRuntimeState(instanceId: 'r2'),
        },
      );
      source.clear();
      final scope = state.instanceRef('room')!;
      final initial = state;
      expect(state.instancesByMapId['room']!.npcPoses, hasLength(1));
      expect(
        () => state.instancesByMapId['room']!.npcPoses.clear(),
        throwsUnsupportedError,
      );
      final changed = {
        'guide': MapInstanceNpcPose(
          position: const GridPos(x: 4, y: 2),
          facing: EntityFacing.north,
        ),
      };
      state = state.setNpcPoses(scope, changed);
      changed.clear();
      expect(
        state.instancesByMapId['room']!.npcPoses['guide']!.facing,
        EntityFacing.north,
      );
      expect(
        initial.instancesByMapId['room']!.npcPoses['guide']!.facing,
        EntityFacing.west,
      );
      expect(
        state.setNpcPoses(scope, state.instancesByMapId['room']!.npcPoses),
        same(state),
      );
      state = state
          .setEventBoolean(scope, 'event', 'A', true)
          .clearFieldObstacle(scope, 'tree')
          .consumeInteractiveEncounter(scope, 'encounter')
          .illuminateZone(scope, 'zone')
          .activateStrength(scope)
          .moveFieldObstacle(scope, 'rock', const GridPos(x: 2, y: 3));
      final restored = MapInstanceWorldState.fromJson(state.toJson());
      expect(restored, state);
      expect(restored.hashCode, state.hashCode);
      expect(
        restored.instancesByMapId['room']!.npcPoses['guide']!.facing,
        EntityFacing.north,
      );
      expect(restored.instancesByMapId['other']!.npcPoses, isEmpty);
      expect(
        () => state.setNpcPoses(
          MapInstanceRef(mapId: 'room', instanceId: 'stale'),
          {},
        ),
        throwsStateError,
      );
      expect(
        () => state.setNpcPoses(scope, {
          ' bad ': MapInstanceNpcPose(
            position: const GridPos(x: 0, y: 0),
            facing: EntityFacing.south,
          ),
        }),
        throwsArgumentError,
      );
    },
  );

  for (final pose in <Map<String, dynamic>>[
    {},
    {
      'position': {'x': 0, 'y': 0},
    },
    {
      'position': {'x': 0.5, 'y': 0},
      'facing': 'north',
    },
    {
      'position': {'x': -1, 'y': 0},
      'facing': 'north',
    },
    {
      'position': {'x': 0, 'y': 0},
      'facing': null,
    },
    {
      'position': {'x': 0, 'y': 0},
      'facing': 'up',
    },
    {
      'position': {'x': 0, 'y': 0},
      'facing': 'north',
      'unknown': true,
    },
    {'x': 0, 'y': 0, 'facing': 'north'},
  ]) {
    test('malformed NPC pose is refused $pose', () {
      expect(() => MapInstanceNpcPose.fromJson(pose), throwsFormatException);
    });
  }
  test('state6 refuses old position zone and null pose maps', () {
    final json = _stateJson();
    final room = (json['instancesByMapId'] as Map)['room'] as Map;
    room['npcPositions'] = room.remove('npcPoses');
    expect(() => MapInstanceWorldState.fromJson(json), throwsFormatException);
    room.remove('npcPositions');
    room['npcPoses'] = null;
    expect(() => MapInstanceWorldState.fromJson(json), throwsFormatException);
    expect(
      () => MapInstanceNpcPose(
        position: const GridPos(x: -1, y: 0),
        facing: EntityFacing.south,
      ),
      throwsArgumentError,
    );
  });
}
