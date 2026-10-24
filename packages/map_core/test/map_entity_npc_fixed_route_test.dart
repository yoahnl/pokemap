import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('native random movement round trips without a forced direction', () {
    final steps = [
      {'kind': 'randomMove'},
    ];
    final movement = MapEntityNpcMovementConfig.fromJson({
      ..._route(),
      'routeSteps': steps,
    });
    expect(movement.toJson()['routeSteps'], steps);
    final reopened = MapData.fromJson(
      addEntityToMap(_map(), entity: _entity(movement)).toJson(),
    );
    expect(reopened.entities.single.npc!.movement, movement);
    for (final extra in [
      {'direction': 'north'},
      {'through': true},
      {'script': 'move_random'},
    ]) {
      expect(
        () => MapEntityNpcMovementConfig.fromJson({
          ..._route(),
          'routeSteps': [
            {'kind': 'randomMove', ...extra},
          ],
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'fixed cardinal route preserves every authored step and source cadence',
    () {
      final movement = MapEntityNpcMovementConfig.fromJson(_route());
      expect(movement.mode.name, 'fixedRoute');
      expect(movement.toJson()['routeSteps'], _route()['routeSteps']);
      expect(movement.toJson(), isNot(contains('routeDirections')));
      expect(movement.pauseDurationMs, 2550);
      expect(movement.stepDurationMs, 250);
      expect(movement.loop, isTrue);
      final entity = _entity(movement);
      final next = addEntityToMap(_map(), entity: entity);
      final reopened = MapData.fromJson(next.toJson());
      expect(reopened.entities.single.npc!.movement, movement);
      MapValidator.validate(reopened);
    },
  );

  test(
    'fixed route timings accept zero wait and the bounded positive step',
    () {
      for (final pause in [0, 3600000]) {
        for (final step in [1, 60000]) {
          final movement = MapEntityNpcMovementConfig.fromJson({
            ..._route(),
            'pauseDurationMs': pause,
            'stepDurationMs': step,
          });
          expect(
            () => addEntityToMap(_map(), entity: _entity(movement)),
            returnsNormally,
          );
        }
      }
    },
  );

  test('fixed route rejects malformed or unqualified autonomous steps', () {
    for (final steps in [
      [
        {'kind': 'move', 'direction': 'diagonal'},
      ],
      [
        {'kind': 'move'},
      ],
      [
        {'kind': 'randomFacing', 'direction': 'west'},
      ],
      [
        {'kind': 'face', 'direction': 'west', 'through': true},
      ],
      [
        {'kind': 'wait', 'durationMs': 50},
      ],
      [
        {'kind': 'sound', 'assetId': 'sound'},
      ],
      'west',
      [null],
      [3],
    ]) {
      expect(
        () => MapEntityNpcMovementConfig.fromJson({
          ..._route(),
          'routeSteps': steps,
        }),
        throwsA(isA<Object>()),
      );
    }
  });

  test(
    'fixed route preserves moves, facing and native random facing separately',
    () {
      final steps = [
        {'kind': 'move', 'direction': 'east'},
        {'kind': 'face', 'direction': 'west'},
        {'kind': 'randomFacing'},
      ];
      final movement = MapEntityNpcMovementConfig.fromJson({
        ..._route(),
        'routeSteps': steps,
      });
      expect(movement.toJson()['routeSteps'], steps);
      final reopened = MapData.fromJson(
        addEntityToMap(_map(), entity: _entity(movement)).toJson(),
      );
      expect(reopened.entities.single.npc!.movement, movement);
    },
  );

  for (final changes in <Map<String, Object?>>[
    {'routeSteps': <Object>[]},
    {
      'routeSteps': List.filled(257, {'kind': 'move', 'direction': 'east'}),
    },
    {
      'waypoints': [
        {'x': 2, 'y': 3},
      ],
    },
    {'pauseDurationMs': -1},
    {'pauseDurationMs': 3600001},
    {'stepDurationMs': 0},
    {'stepDurationMs': 60001},
    {'mode': 'idle'},
    {'mode': 'patrol'},
    {'mode': 'scriptedOnly'},
  ]) {
    test(
      'canonical entity mutation refuses incoherent fixed route $changes',
      () {
        expect(() {
          final movement = MapEntityNpcMovementConfig.fromJson({
            ..._route(),
            ...changes,
          });
          addEntityToMap(_map(), entity: _entity(movement));
        }, throwsA(isA<ValidationException>()));
      },
    );
  }

  test('fixed route preserves an optional map-instance suspension binding', () {
    final flag = {'key': 'npc.autonomousRouteStopped', 'value': true};
    final movement = MapEntityNpcMovementConfig.fromJson({
      ..._route(),
      'suspendWhenInstanceBoolean': flag,
    });
    expect(movement.toJson()['suspendWhenInstanceBoolean'], flag);
    final reopened = MapData.fromJson(
      addEntityToMap(_map(), entity: _entity(movement)).toJson(),
    );
    expect(reopened.entities.single.npc!.movement, movement);
  });

  test(
    'instance suspension binding rejects malformed or ambiguous references',
    () {
      for (final flag in [
        {'key': '', 'value': true},
        {'key': ' routeStopped', 'value': true},
        {'key': 'routeStopped', 'value': 'true'},
        {'key': 'routeStopped'},
        {'key': 'routeStopped', 'value': true, 'mapId': 'foreign'},
        {'key': 'x' * 129, 'value': true},
      ]) {
        expect(
          () => MapEntityNpcMovementConfig.fromJson({
            ..._route(),
            'suspendWhenInstanceBoolean': flag,
          }),
          throwsA(isA<Object>()),
        );
      }
    },
  );

  test('instance suspension is refused outside the fixed route mode', () {
    final movement = MapEntityNpcMovementConfig.fromJson({
      ..._route(),
      'mode': 'idle',
      'routeSteps': <Object>[],
      'suspendWhenInstanceBoolean': {'key': 'routeStopped', 'value': true},
    });
    expect(
      () => addEntityToMap(_map(), entity: _entity(movement)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('fixed route supports a spatial map without changing its placement', () {
    final movement = MapEntityNpcMovementConfig.fromJson(_route());
    final spatial = _map().copyWith(version: ProjectVersion.v9);
    final next = addEntityToMap(spatial, entity: _entity(movement));
    expect(next.entities.single.npc!.movement, movement);
    expect(spatial.entities, isEmpty);
  });

  test('existing patrol waypoints keep their own order and timing', () {
    const movement = MapEntityNpcMovementConfig(
      mode: MapEntityNpcMovementMode.patrol,
      waypoints: [GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)],
      pauseDurationMs: 450,
      stepDurationMs: 260,
      loop: false,
    );
    final reopened = MapEntityNpcMovementConfig.fromJson(movement.toJson());
    expect(reopened, movement);
    expect(
      () => addEntityToMap(_map(), entity: _entity(reopened)),
      returnsNormally,
    );
  });
}

Map<String, dynamic> _route() => {
  'mode': 'fixedRoute',
  'routeSteps': [
    for (final direction in const [
      'east',
      'west',
      'west',
      'east',
      'west',
      'east',
      'west',
      'east',
      'east',
      'west',
      'east',
      'west',
      'east',
      'west',
    ])
      {'kind': 'move', 'direction': direction},
  ],
  'loop': true,
  'pauseDurationMs': 2550,
  'stepDurationMs': 250,
};

MapEntity _entity(MapEntityNpcMovementConfig movement) => MapEntity(
  id: 'npc',
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 4, y: 5),
  npc: MapEntityNpcData(movement: movement),
);

MapData _map() => const MapData(
  id: 'centre',
  name: 'Centre',
  size: GridSize(width: 20, height: 15),
);
