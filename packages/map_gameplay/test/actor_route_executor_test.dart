import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/actor_route_executor.dart';
import 'package:test/test.dart';

final class _Port implements ActorRouteExecutionPort {
  bool current = true;
  final calls = <String>[];
  final targets = <SceneActorTarget>[];
  final gates = <String, Completer<void>>{};
  final entered = <String, Completer<void>>{};
  final moveOutcomes = <ActorRouteMoveOutcome>[];
  final initialCollisionOwners = <String?>[];
  String? failingOperation;

  @override
  bool get isCurrent => current;

  Future<void> _call(String operation, String description) async {
    calls.add(description);
    final entry = entered.putIfAbsent(operation, () => Completer<void>());
    if (!entry.isCompleted) entry.complete();
    await gates[operation]?.future;
    if (failingOperation == operation) {
      throw StateError('Missing target or failed $operation.');
    }
  }

  Future<void> waitUntilEntered(String operation) =>
      entered.putIfAbsent(operation, () => Completer<void>()).future;

  @override
  Future<void> face(SceneActorTarget target, EntityFacing direction) {
    targets.add(target);
    return _call('face', 'face:${direction.name}');
  }

  @override
  Future<ActorRouteMoveOutcome> move(
      SceneActorTarget target, EntityFacing direction,
      {required int durationMs,
      required bool through,
      String? initialCollisionOwnerEntityId}) async {
    targets.add(target);
    initialCollisionOwners.add(initialCollisionOwnerEntityId);
    await _call('move', 'move:${direction.name}:$durationMs:$through');
    return moveOutcomes.isEmpty
        ? ActorRouteMoveOutcome.moved
        : moveOutcomes.removeAt(0);
  }

  @override
  Future<void> nextUpdate() => _call('nextUpdate', 'nextUpdate');

  @override
  Future<void> wait(int durationMs) => _call('wait', 'wait:$durationMs');

  @override
  Future<void> sound(String mediaAssetId, {required double gain}) =>
      _call('sound', 'sound:$mediaAssetId:$gain');

  @override
  Future<void> setVisibility(SceneActorTarget target, {required bool visible}) {
    targets.add(target);
    return _call('visibility', 'visibility:$visible');
  }
}

SceneActorRouteInteractiveCommand _route(List<SceneActorRouteStep> steps,
        {bool skippable = false, SceneActorTarget? target}) =>
    SceneActorRouteInteractiveCommand(
      target: target ?? SceneActorTarget.player(mapId: 'centre'),
      steps: steps,
      skippable: skippable,
    );

void main() {
  const executor = ActorRouteExecutor();

  test('actor route forwards the initial owner only for its declared move',
      () async {
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'actorRoute',
      'target': {'kind': 'player', 'mapId': 'centre'},
      'steps': [
        {
          'kind': 'move',
          'direction': 'south',
          'durationMs': 250,
          'initialCollisionOwnerEntityId': 'door',
        },
        {'kind': 'move', 'direction': 'south', 'durationMs': 250},
      ],
      'skippable': false,
    }) as SceneActorRouteInteractiveCommand;
    final port = _Port();
    expect(await executor.execute(command, port: port),
        ActorRouteExecutionOutcome.completed);
    expect(port.initialCollisionOwners, ['door', null]);
    expect(port.calls, ['move:south:250:false', 'move:south:250:false']);
    await executor.execute(
        _route([
          SceneActorMoveStep(direction: EntityFacing.north, durationMs: 250),
        ]),
        port: port);
    expect(port.initialCollisionOwners, ['door', null, null]);
  });

  test('actor route executes typed operations in order with local through',
      () async {
    final port = _Port();
    final target = SceneActorTarget.entity(mapId: 'centre', entityId: 'door');
    final result = await executor.execute(
        _route([
          SceneActorFaceStep(direction: EntityFacing.west, durationMs: 50),
          const SceneActorThroughStep(enabled: true),
          SceneActorMoveStep(direction: EntityFacing.north, durationMs: 150),
          SceneActorWaitStep(durationMs: 100),
          SceneActorSoundStep(mediaAssetId: 'door-sound', gain: .8),
          const SceneActorThroughStep(enabled: false),
          SceneActorMoveStep(direction: EntityFacing.south, durationMs: 200),
        ], target: target),
        port: port);
    expect(result, ActorRouteExecutionOutcome.completed);
    expect(port.calls, [
      'face:west',
      'wait:50',
      'move:north:150:true',
      'wait:100',
      'sound:door-sound:0.8',
      'move:south:200:false'
    ]);
    expect(port.targets, [target, target, target]);
  });

  test('actor route remains blocking until face hold and final move complete',
      () async {
    final port = _Port()
      ..gates['face'] = Completer<void>()
      ..gates['wait'] = Completer<void>()
      ..gates['move'] = Completer<void>();
    var completed = false;
    final running = executor
        .execute(
            _route([
              SceneActorFaceStep(direction: EntityFacing.north, durationMs: 50),
              SceneActorMoveStep(
                  direction: EntityFacing.north, durationMs: 150),
            ]),
            port: port)
        .then((result) {
      completed = true;
      return result;
    });
    expect(port.calls, ['face:north']);
    await port.waitUntilEntered('face');
    expect(completed, isFalse);
    expect(port.calls, ['face:north']);
    port.gates['face']!.complete();
    await port.waitUntilEntered('wait');
    expect(completed, isFalse);
    expect(port.calls, ['face:north', 'wait:50']);
    port.gates['wait']!.complete();
    await port.waitUntilEntered('move');
    expect(completed, isFalse);
    port.gates['move']!.complete();
    expect(await running, ActorRouteExecutionOutcome.completed);
    expect(completed, isTrue);
  });

  test('actor route face with zero duration has no implicit frame wait',
      () async {
    final port = _Port();
    expect(
        await executor.execute(
            _route([
              SceneActorFaceStep(direction: EntityFacing.east),
            ]),
            port: port),
        ActorRouteExecutionOutcome.completed);
    expect(port.calls, ['face:east']);
  });

  test('actor route explicit yield runs before face hold and next step',
      () async {
    final port = _Port();
    final result = await executor.execute(
        _route([
          _yieldingFace(durationMs: 25),
          SceneActorSoundStep(mediaAssetId: 'after-yield', gain: .8),
        ]),
        port: port);
    expect(result, ActorRouteExecutionOutcome.completed);
    expect(port.calls,
        ['face:north', 'nextUpdate', 'wait:25', 'sound:after-yield:0.8']);
  });

  test('actor route explicit zero-duration yield adds no invented hold',
      () async {
    final port = _Port();
    expect(
        await executor.execute(
            _route([
              _yieldingFace(),
              SceneActorSoundStep(mediaAssetId: 'after-yield', gain: .8),
            ]),
            port: port),
        ActorRouteExecutionOutcome.completed);
    expect(port.calls, ['face:north', 'nextUpdate', 'sound:after-yield:0.8']);
  });

  test('actor route starts face duration only after its explicit yield',
      () async {
    final port = _Port()
      ..gates['nextUpdate'] = Completer<void>()
      ..gates['wait'] = Completer<void>();
    var completed = false;
    final running = executor.execute(
        _route([
          _yieldingFace(durationMs: 25),
          SceneActorSoundStep(mediaAssetId: 'after-yield', gain: .8),
        ]),
        port: port).then((result) {
      completed = true;
      return result;
    });
    await port.waitUntilEntered('nextUpdate')
        .timeout(const Duration(seconds: 1));
    expect(port.calls, ['face:north', 'nextUpdate']);
    expect(completed, isFalse);
    port.gates['nextUpdate']!.complete();
    await port.waitUntilEntered('wait').timeout(const Duration(seconds: 1));
    expect(port.calls, ['face:north', 'nextUpdate', 'wait:25']);
    expect(completed, isFalse);
    port.gates['wait']!.complete();
    expect(await running, ActorRouteExecutionOutcome.completed);
    expect(port.calls.last, 'sound:after-yield:0.8');
  });

  test('actor route closure during explicit yield prevents duration and sound',
      () async {
    final port = _Port()..gates['nextUpdate'] = Completer<void>();
    final running = executor.execute(
        _route([
          _yieldingFace(durationMs: 25),
          SceneActorSoundStep(mediaAssetId: 'must-not-start', gain: .8),
        ], skippable: true),
        port: port);
    await port.waitUntilEntered('nextUpdate')
        .timeout(const Duration(seconds: 1));
    port.current = false;
    port.gates['nextUpdate']!.complete();
    expect(await running, ActorRouteExecutionOutcome.interrupted);
    expect(port.calls, ['face:north', 'nextUpdate']);
  });

  test('actor route explicit yield failure is not skipped', () async {
    final port = _Port()..failingOperation = 'nextUpdate';
    await expectLater(
        executor.execute(
            _route([
              _yieldingFace(),
              SceneActorSoundStep(mediaAssetId: 'must-not-start', gain: .8),
            ], skippable: true),
            port: port),
        throwsStateError);
    expect(port.calls, ['face:north', 'nextUpdate']);
  });

  for (final skippable in [false, true]) {
    test('actor route obstruction skips only when skippable=$skippable',
        () async {
      final port = _Port()
        ..moveOutcomes.addAll([
          ActorRouteMoveOutcome.obstructed,
          ActorRouteMoveOutcome.moved,
        ]);
      final result = await executor.execute(
          _route([
            SceneActorMoveStep(direction: EntityFacing.north, durationMs: 50),
            SceneActorWaitStep(durationMs: 25),
            SceneActorMoveStep(direction: EntityFacing.east, durationMs: 75),
          ], skippable: skippable),
          port: port);
      expect(
          result,
          skippable
              ? ActorRouteExecutionOutcome.completed
              : ActorRouteExecutionOutcome.blocked);
      expect(
          port.calls,
          skippable
              ? ['move:north:50:false', 'wait:25', 'move:east:75:false']
              : ['move:north:50:false']);
    });
  }

  test('actor route through never survives into another invocation', () async {
    final port = _Port();
    await executor.execute(
        _route([
          const SceneActorThroughStep(enabled: true),
          SceneActorMoveStep(direction: EntityFacing.north, durationMs: 50),
        ]),
        port: port);
    await executor.execute(
        _route([
          SceneActorMoveStep(direction: EntityFacing.south, durationMs: 50),
        ]),
        port: port);
    expect(port.calls, ['move:north:50:true', 'move:south:50:false']);
  });

  test('actor route refuses a closed session before the first effect',
      () async {
    final port = _Port()..current = false;
    expect(
        await executor.execute(
            _route([
              SceneActorFaceStep(direction: EntityFacing.north, durationMs: 50),
              SceneActorSoundStep(mediaAssetId: 'door-sound', gain: .8),
            ]),
            port: port),
        ActorRouteExecutionOutcome.interrupted);
    expect(port.calls, isEmpty);
  });

  for (final operation in ['face', 'move', 'wait', 'sound']) {
    test('actor route stops after a pending $operation loses its session',
        () async {
      final port = _Port()..gates[operation] = Completer<void>();
      final first = switch (operation) {
        'face' =>
          SceneActorFaceStep(direction: EntityFacing.north, durationMs: 50),
        'move' =>
          SceneActorMoveStep(direction: EntityFacing.north, durationMs: 150),
        'wait' => SceneActorWaitStep(durationMs: 100),
        _ => SceneActorSoundStep(mediaAssetId: 'door-sound', gain: .8),
      };
      final running = executor.execute(
          _route([
            first,
            SceneActorSoundStep(mediaAssetId: 'must-not-start', gain: .5),
          ], skippable: true),
          port: port);
      expect(port.calls, isNotEmpty);
      await port.waitUntilEntered(operation);
      port.current = false;
      port.gates[operation]!.complete();
      expect(await running, ActorRouteExecutionOutcome.interrupted);
      expect(port.calls, hasLength(1));
    });
  }

  for (final operation in ['face', 'move', 'wait', 'sound']) {
    test('actor route propagates $operation failures even when skippable',
        () async {
      final port = _Port()..failingOperation = operation;
      final step = switch (operation) {
        'face' => SceneActorFaceStep(direction: EntityFacing.north),
        'move' =>
          SceneActorMoveStep(direction: EntityFacing.north, durationMs: 50),
        'wait' => SceneActorWaitStep(durationMs: 50),
        _ => SceneActorSoundStep(mediaAssetId: 'missing-sound', gain: .8),
      };
      await expectLater(
          executor.execute(
              _route([
                step,
                SceneActorWaitStep(durationMs: 0),
              ], skippable: true),
              port: port),
          throwsStateError);
      expect(port.calls, hasLength(1));
    });
  }

  test('actor visibility uses its own visual port for the exact target',
      () async {
    final port = _Port();
    final target = SceneActorTarget.entity(mapId: 'centre', entityId: 'door');
    expect(
        await executor.executeVisibility(
            SceneActorVisibilityInteractiveCommand(
              target: target,
              visible: false,
            ),
            port: port),
        ActorRouteExecutionOutcome.completed);
    expect(port.calls, ['visibility:false']);
    expect(port.targets, [target]);
  });

  test('actor visibility stops before or after closure without further effects',
      () async {
    final command = SceneActorVisibilityInteractiveCommand(
      target: SceneActorTarget.player(mapId: 'centre'),
      visible: false,
    );
    final closed = _Port()..current = false;
    expect(await executor.executeVisibility(command, port: closed),
        ActorRouteExecutionOutcome.interrupted);
    expect(closed.calls, isEmpty);
    final pending = _Port()..gates['visibility'] = Completer<void>();
    final running = executor.executeVisibility(command, port: pending);
    expect(pending.calls, ['visibility:false']);
    await pending.waitUntilEntered('visibility');
    pending.current = false;
    pending.gates['visibility']!.complete();
    expect(await running, ActorRouteExecutionOutcome.interrupted);
    expect(pending.calls, ['visibility:false']);
  });

  test('actor visibility propagates a missing target failure', () async {
    final port = _Port()..failingOperation = 'visibility';
    await expectLater(
        executor.executeVisibility(
            SceneActorVisibilityInteractiveCommand(
              target:
                  SceneActorTarget.entity(mapId: 'centre', entityId: 'missing'),
              visible: false,
            ),
            port: port),
        throwsStateError);
  });
}

SceneActorFaceStep _yieldingFace({int durationMs = 0}) =>
    SceneActorRouteStep.fromJson({
      'kind': 'face',
      'direction': 'north',
      'durationMs': durationMs,
      'yieldAfter': true,
    }) as SceneActorFaceStep;
