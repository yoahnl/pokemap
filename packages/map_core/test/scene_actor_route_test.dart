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
