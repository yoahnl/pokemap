import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _routeWire({bool entity = false}) => {
  'kind': 'actorRoute',
  'target': <String, dynamic>{
    'kind': entity ? 'entity' : 'player',
    'mapId': 'centre',
    if (entity) 'entityId': 'door',
  },
  'steps': <Map<String, dynamic>>[
    {'kind': 'face', 'direction': 'north', 'durationMs': 50},
    {'kind': 'through', 'enabled': true},
    {'kind': 'move', 'direction': 'north', 'durationMs': 150},
    {'kind': 'wait', 'durationMs': 100},
    {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': .8},
    {'kind': 'through', 'enabled': false},
  ],
  'skippable': false,
};

void main() {
  test('actor move initial collision owner is canonical optional JSON', () {
    for (final direction in EntityFacing.values) {
      final wire = <String, dynamic>{
        'kind': 'move',
        'direction': direction.name,
        'durationMs': 200,
        'initialCollisionOwnerEntityId': 'door',
      };
      final step = SceneActorRouteStep.fromJson(wire);
      expect(step, isA<SceneActorMoveStep>());
      expect(step.toJson(), wire);
      expect(SceneActorRouteStep.fromJson(step.toJson()), step);
      expect(
        SceneActorRouteStep.fromJson(step.toJson()).hashCode,
        step.hashCode,
      );
      final ordinary = SceneActorRouteStep.fromJson(
        {...wire}..remove('initialCollisionOwnerEntityId'),
      );
      expect(ordinary, isNot(step));
      expect(
        ordinary.toJson().containsKey('initialCollisionOwnerEntityId'),
        isFalse,
      );
      final otherOwner = SceneActorRouteStep.fromJson({
        ...wire,
        'initialCollisionOwnerEntityId': 'another-door',
      });
      expect(otherOwner, isNot(step));
    }
  });

  test(
    'actor move initial collision owner rejects explicit null and noncanonical ids',
    () {
      for (final owner in <Object?>[null, '', ' ', ' door', 'door ', 8, true]) {
        expect(
          () => SceneActorRouteStep.fromJson({
            'kind': 'move',
            'direction': 'south',
            'durationMs': 200,
            'initialCollisionOwnerEntityId': owner,
          }),
          throwsFormatException,
          reason: 'owner=$owner',
        );
      }
    },
  );

  test('initial collision owner remains unknown on every other actor step', () {
    for (final step in <Map<String, dynamic>>[
      {'kind': 'face', 'direction': 'south', 'durationMs': 50},
      {'kind': 'wait', 'durationMs': 100},
      {'kind': 'through', 'enabled': false},
      {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': 1.0},
    ]) {
      expect(
        () => SceneActorRouteStep.fromJson({
          ...step,
          'initialCollisionOwnerEntityId': 'door',
        }),
        throwsFormatException,
      );
    }
  });

  test('player route preserves one initial collision owner movement', () {
    final wire = _routeWire()
      ..['steps'] = [
        {'kind': 'face', 'direction': 'south', 'durationMs': 50},
        {
          'kind': 'move',
          'direction': 'south',
          'durationMs': 200,
          'initialCollisionOwnerEntityId': 'door',
        },
        {'kind': 'move', 'direction': 'south', 'durationMs': 200},
      ];
    final command = SceneInteractiveCommand.fromJson(wire);
    expect(command.toJson(), wire);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
  });

  test('initial collision owner is forbidden for an entity route target', () {
    final step = SceneActorRouteStep.move(
      direction: EntityFacing.south,
      durationMs: 200,
      initialCollisionOwnerEntityId: 'door',
    );
    final target = SceneActorTarget.entity(mapId: 'centre', entityId: 'actor');
    for (final skippable in [false, true]) {
      expect(
        () => SceneInteractiveCommand.actorRoute(
          target: target,
          steps: [step],
          skippable: skippable,
        ),
        throwsArgumentError,
      );
      expect(
        () => SceneInteractiveCommand.fromJson({
          ..._routeWire(entity: true),
          'steps': [step.toJson()],
          'skippable': skippable,
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'initial collision owner refuses effective through at its own movement',
    () {
      final owner = SceneActorMoveStep(
        direction: EntityFacing.south,
        durationMs: 200,
        initialCollisionOwnerEntityId: 'door',
      );
      for (final steps in <List<SceneActorRouteStep>>[
        [const SceneActorThroughStep(enabled: true), owner],
        [
          const SceneActorThroughStep(enabled: true),
          SceneActorFaceStep(direction: EntityFacing.south),
          SceneActorWaitStep(durationMs: 100),
          SceneActorSoundStep(mediaAssetId: 'door-sound', gain: 1),
          owner,
        ],
        [owner, const SceneActorThroughStep(enabled: true), owner],
      ]) {
        expect(
          () => SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.player(mapId: 'centre'),
            steps: steps,
            skippable: true,
          ),
          throwsArgumentError,
        );
        expect(
          () => SceneInteractiveCommand.fromJson({
            ..._routeWire(),
            'steps': steps.map((step) => step.toJson()).toList(),
          }),
          throwsFormatException,
        );
      }
    },
  );

  test('through disabled before owner movement restores route eligibility', () {
    final steps = <SceneActorRouteStep>[
      const SceneActorThroughStep(enabled: true),
      SceneActorMoveStep(direction: EntityFacing.south, durationMs: 100),
      const SceneActorThroughStep(enabled: false),
      SceneActorMoveStep(
        direction: EntityFacing.south,
        durationMs: 200,
        initialCollisionOwnerEntityId: 'door',
      ),
      const SceneActorThroughStep(enabled: true),
      SceneActorMoveStep(direction: EntityFacing.south, durationMs: 100),
    ];
    final route = SceneInteractiveCommand.actorRoute(
      target: SceneActorTarget.player(mapId: 'centre'),
      steps: steps,
    );
    expect(SceneInteractiveCommand.fromJson(route.toJson()), route);
  });

  test(
    'initial collision owner constructors keep canonical identities immutable',
    () {
      for (final id in ['', ' ', ' door', 'door ']) {
        expect(
          () => SceneActorMoveStep(
            direction: EntityFacing.south,
            durationMs: 200,
            initialCollisionOwnerEntityId: id,
          ),
          throwsArgumentError,
        );
      }
      final step = SceneActorMoveStep(
        direction: EntityFacing.south,
        durationMs: 200,
        initialCollisionOwnerEntityId: 'door',
      );
      final wire = step.toJson()..['initialCollisionOwnerEntityId'] = 'other';
      expect(wire['initialCollisionOwnerEntityId'], 'other');
      expect(step.initialCollisionOwnerEntityId, 'door');
    },
  );

  test('actor route constructors preserve immutable value contracts', () {
    final target = SceneActorTarget.entity(mapId: 'centre', entityId: 'door');
    final steps = <SceneActorRouteStep>[
      SceneActorRouteStep.face(direction: EntityFacing.north, durationMs: 50),
      SceneActorRouteStep.wait(durationMs: 100),
    ];
    final route =
        SceneInteractiveCommand.actorRoute(target: target, steps: steps)
            as SceneActorRouteInteractiveCommand;
    steps.clear();
    expect(route.steps, hasLength(2));
    expect(() => route.steps.clear(), throwsUnsupportedError);
    expect(SceneActorTarget.fromJson(target.toJson()), target);
    expect(
      SceneActorTarget.fromJson(target.toJson()).hashCode,
      target.hashCode,
    );
    expect(SceneInteractiveCommand.fromJson(route.toJson()), route);
    expect(
      SceneInteractiveCommand.fromJson(route.toJson()).hashCode,
      route.hashCode,
    );
    final wire = route.toJson();
    ((wire['steps'] as List).first as Map)['durationMs'] = 0;
    (wire['target'] as Map)['entityId'] = 'another-door';
    expect((route.steps.first as SceneActorFaceStep).durationMs, 50);
    expect(route.target.entityId, 'door');
  });

  test(
    'actor route constructors reject invalid finite durations gains and ids',
    () {
      for (final duration in [-1, 0x80000000]) {
        expect(
          () => SceneActorFaceStep(
            direction: EntityFacing.north,
            durationMs: duration,
          ),
          throwsArgumentError,
        );
        expect(
          () => SceneActorWaitStep(durationMs: duration),
          throwsArgumentError,
        );
      }
      expect(
        () => SceneActorMoveStep(direction: EntityFacing.north, durationMs: 0),
        throwsArgumentError,
      );
      for (final gain in [double.nan, double.infinity, -.01, 1.01]) {
        expect(
          () => SceneActorSoundStep(mediaAssetId: 'door-sound', gain: gain),
          throwsArgumentError,
        );
      }
      expect(() => SceneActorTarget.player(mapId: ' '), throwsArgumentError);
      expect(
        () => SceneActorTarget.entity(mapId: 'centre', entityId: ''),
        throwsArgumentError,
      );
      for (final direction in EntityFacing.values) {
        expect(SceneActorFaceStep(direction: direction).durationMs, 0);
        expect(
          SceneActorMoveStep(
            direction: direction,
            durationMs: 0x7fffffff,
          ).durationMs,
          0x7fffffff,
        );
      }
    },
  );

  test('actor route command recognizes its typed finite blocking program', () {
    for (final entity in [false, true]) {
      final wire = _routeWire(entity: entity);
      final command = SceneInteractiveCommand.fromJson(wire);
      expect(
        command.runtimeType.toString(),
        'SceneActorRouteInteractiveCommand',
      );
      expect(command.kind.name, 'actorRoute');
      expect(command.outputPortIds, ['completed', 'blocked']);
      expect(command.toJson(), wire);
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    }
  });

  test('actor visibility round-trips a map-bound player or entity target', () {
    for (final entity in [false, true]) {
      for (final visible in [false, true]) {
        final wire = <String, dynamic>{
          'kind': 'actorVisibility',
          'target': {
            'kind': entity ? 'entity' : 'player',
            'mapId': 'centre',
            if (entity) 'entityId': 'door',
          },
          'visible': visible,
        };
        final command = SceneInteractiveCommand.fromJson(wire);
        expect(
          command.runtimeType.toString(),
          'SceneActorVisibilityInteractiveCommand',
        );
        expect(command.toJson(), wire);
        expect(command.outputPortIds, ['completed', 'blocked']);
        expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      }
    }
  });

  test('actor route defaults only face duration and skippable', () {
    final wire = _routeWire();
    wire.remove('skippable');
    ((wire['steps'] as List).first as Map).remove('durationMs');
    final json = SceneInteractiveCommand.fromJson(wire).toJson();
    expect(json['skippable'], isFalse);
    expect((json['steps'] as List).first['durationMs'], 0);
  });

  test('actor route rejects unknown fields at every contract boundary', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (wire) => wire['repeat'] = false,
      (wire) => wire['unknown'] = true,
      (wire) => (wire['target'] as Map)['entityId'] = 'forbidden-player-id',
      (wire) => (wire['target'] as Map)['unknown'] = true,
      (wire) => ((wire['steps'] as List).first as Map)['unknown'] = true,
      (wire) => ((wire['steps'] as List)[1] as Map)['durationMs'] = 0,
      (wire) => ((wire['steps'] as List)[4] as Map)['volume'] = .8,
    ]) {
      final wire = _routeWire();
      mutate(wire);
      expect(
        () => SceneInteractiveCommand.fromJson(wire),
        throwsFormatException,
      );
    }
  });

  test('actor route refuses malformed targets and state flags', () {
    for (final target in <Object?>[
      null,
      'player',
      <String, dynamic>{},
      {'kind': 'unknown', 'mapId': 'centre'},
      {'kind': 'player'},
      {'kind': 'player', 'mapId': ' '},
      {'kind': 'entity', 'mapId': 'centre'},
      {'kind': 'entity', 'mapId': 'centre', 'entityId': null},
      {'kind': 'entity', 'mapId': 'centre', 'entityId': ''},
      {'kind': 'player', 'mapId': 7},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          ..._routeWire(),
          'target': target,
        }),
        throwsFormatException,
      );
    }
    for (final flag in <Object?>[null, 0, 'true']) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          ..._routeWire(),
          'skippable': flag,
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'actor route durations are literal int32 with strictly positive movement',
    () {
      for (final kind in ['face', 'move', 'wait']) {
        for (final duration in <Object?>[
          -1,
          0x80000000,
          1.0,
          '50',
          null,
          true,
        ]) {
          final wire = _routeWire();
          wire['steps'] = [
            {
              'kind': kind,
              if (kind != 'wait') 'direction': 'north',
              'durationMs': duration,
            },
          ];
          expect(
            () => SceneInteractiveCommand.fromJson(wire),
            throwsFormatException,
            reason: '$kind duration=$duration',
          );
        }
      }
      final zeroMove = _routeWire()
        ..['steps'] = [
          {'kind': 'move', 'direction': 'north', 'durationMs': 0},
        ];
      expect(
        () => SceneInteractiveCommand.fromJson(zeroMove),
        throwsFormatException,
      );
      for (final kind in ['face', 'wait']) {
        final wire = _routeWire()
          ..['steps'] = [
            {
              'kind': kind,
              if (kind == 'face') 'direction': 'south',
              'durationMs': 0,
            },
          ];
        expect(SceneInteractiveCommand.fromJson(wire).toJson(), wire);
      }
    },
  );

  test('actor route refuses invalid directions and non-finite sound gains', () {
    for (final direction in <Object?>['up', '', 8, null]) {
      final wire = _routeWire()
        ..['steps'] = [
          {'kind': 'face', 'direction': direction},
        ];
      expect(
        () => SceneInteractiveCommand.fromJson(wire),
        throwsFormatException,
      );
    }
    for (final gain in <Object?>[
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -.001,
      1.001,
      '.8',
      true,
      null,
    ]) {
      final wire = _routeWire()
        ..['steps'] = [
          {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': gain},
        ];
      expect(
        () => SceneInteractiveCommand.fromJson(wire),
        throwsFormatException,
      );
    }
    for (final step in <Object?>[
      null,
      'north',
      {'kind': 'unknown'},
      {'kind': 'through', 'enabled': 1},
      {'kind': 'sound', 'mediaAssetId': ' ', 'gain': .8},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          ..._routeWire(),
          'steps': [step],
        }),
        throwsFormatException,
      );
    }
  });

  test('actor visibility rejects extra fields and non-boolean visibility', () {
    final wire = <String, dynamic>{
      'kind': 'actorVisibility',
      'target': {'kind': 'player', 'mapId': 'centre'},
      'visible': false,
    };
    for (final mutate in <Map<String, dynamic>>[
      {'blocksMovement': false},
      {'present': false},
      {'visible': 0},
      {'visible': null},
      {'steps': []},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({...wire, ...mutate}),
        throwsFormatException,
      );
    }
  });
}
