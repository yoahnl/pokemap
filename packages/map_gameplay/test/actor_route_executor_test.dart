import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/actor_route_executor.dart';
import 'package:test/test.dart';

final class _Port implements ActorRouteExecutionPort {
  bool current = true;
  String appearance = 'base';
  @override
  Object captureAppearance(SceneActorTarget target) => appearance;
  @override
  void restoreAppearance(SceneActorTarget target, Object snapshot) {
    appearance = snapshot as String;
    calls.add('restoreAppearance:$appearance');
  }
  @override
  Future<void> setAppearance(SceneActorTarget target, String characterId) async {
    await _call('appearance', 'appearance:$characterId');
    appearance = characterId;
  }
  bool visible = true;
  @override
  bool get isVisible => visible;
  @override
  void restoreVisibility(SceneActorTarget target, {required bool visible}) {
    this.visible = visible;
    calls.add('restoreVisibility:$visible');
  }

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

  bool above = false;
  @override
  bool get renderAboveMap => above;
  @override
  Future<void> setRenderAboveMap(SceneActorTarget target,
      {required bool enabled}) async {
    await _call('above', 'above:$enabled');
    above = enabled;
  }

  @override
  Future<ActorRouteMoveOutcome> moveDiagonal(
      SceneActorTarget target, EntityFacing horizontal, EntityFacing vertical,
      {required int durationMs, required bool through}) async {
    targets.add(target);
    await _call('diagonal',
        'diagonal:${horizontal.name}:${vertical.name}:$durationMs:$through');
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
  Future<void> setVisibility(SceneActorTarget target,
      {required bool visible}) async {
    targets.add(target);
    await _call('visibility', 'visibility:$visible');
    this.visible = visible;
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

  for (final blocked in [false, true]) {
    test('temporary appearance restores after route blocked=$blocked', () async {
      final port = _Port();
      if (blocked) port.moveOutcomes.add(ActorRouteMoveOutcome.obstructed);
      final command = _route([
        SceneActorRouteStep.fromJson({'kind': 'appearance', 'characterId': 'coat'}),
        SceneActorRouteStep.move(direction: EntityFacing.north, durationMs: 50),
      ]);
      final result = await executor.execute(command, port: port);
      expect(result, blocked ? ActorRouteExecutionOutcome.blocked : ActorRouteExecutionOutcome.completed);
      expect(port.calls, contains('appearance:coat'));
      expect(port.appearance, 'base');
    });
  }

  test('scene appearance is retained between routes', () async {
    final port = _Port();
    final state = ActorRouteTransientState();
    final command = SceneActorRouteInteractiveCommand(
      target: SceneActorTarget.player(mapId: 'centre'),
      transientScope: ActorRouteTransientScope.scene,
      steps: [SceneActorRouteStep.fromJson({'kind': 'appearance', 'characterId': 'coat'})],
    );
    expect(await executor.execute(command, port: port, sceneState: state),
        ActorRouteExecutionOutcome.completed);
    expect(port.appearance, 'coat');
  });

  test('appearance cancellation restores without applying later commands', () async {
    final port = _Port()..gates['wait'] = Completer<void>();
    final running = executor.execute(_route([
      SceneActorRouteStep.fromJson({'kind': 'appearance', 'characterId': 'coat'}),
      SceneActorRouteStep.wait(durationMs: 50),
      SceneActorRouteStep.sound(mediaAssetId: 'late', gain: 1),
    ]), port: port);
    await port.waitUntilEntered('wait');
    expect(port.appearance, 'coat');
    port.current = false;
    port.gates['wait']!.complete();
    expect(await running, ActorRouteExecutionOutcome.interrupted);
    expect(port.appearance, 'base');
    expect(port.calls, isNot(contains('sound:late:1.0')));
  });

  for (final original in [true, false]) {
    test('route restores original visibility $original after completion',
        () async {
      final port = _Port()..visible = original;
      final result = await executor.execute(
        _route([SceneActorRouteStep.visibility(visible: !original)]),
        port: port,
      );
      expect(result, ActorRouteExecutionOutcome.completed);
      expect(port.visible, original);
    });
  }

  for (final scope in ActorRouteTransientScope.values) {
    test('$scope restores visibility on a blocked route', () async {
      final port = _Port()..moveOutcomes.add(ActorRouteMoveOutcome.obstructed);
      final command = SceneActorRouteInteractiveCommand(
        target: SceneActorTarget.player(mapId: 'room'),
        transientScope: scope,
        steps: [
          SceneActorRouteStep.visibility(visible: false),
          SceneActorRouteStep.move(
              direction: EntityFacing.east, durationMs: 250),
        ],
      );
      expect(
          await executor.execute(command,
              port: port, sceneState: ActorRouteTransientState()),
          ActorRouteExecutionOutcome.blocked);
      expect(port.visible, isTrue);
    });
  }

  test('scene visibility persists until its owning scene restores it',
      () async {
    final port = _Port();
    final result = await executor.execute(
        SceneActorRouteInteractiveCommand(
          target: SceneActorTarget.player(mapId: 'room'),
          transientScope: ActorRouteTransientScope.scene,
          steps: [SceneActorRouteStep.visibility(visible: false)],
        ),
        port: port,
        sceneState: ActorRouteTransientState());
    expect(result, ActorRouteExecutionOutcome.completed);
    expect(port.visible, isFalse);
  });

  for (final scope in ActorRouteTransientScope.values) {
    test('$scope restores visibility after cancellation during a wait',
        () async {
      final port = _Port()..gates['wait'] = Completer<void>();
      final running = executor.execute(
          SceneActorRouteInteractiveCommand(
            target: SceneActorTarget.player(mapId: 'room'),
            transientScope: scope,
            steps: [
              SceneActorRouteStep.visibility(visible: false),
              SceneActorRouteStep.wait(durationMs: 250),
              SceneActorRouteStep.sound(mediaAssetId: 'late', gain: 1),
            ],
          ),
          port: port,
          sceneState: ActorRouteTransientState());
      await port.waitUntilEntered('wait');
      expect(port.visible, isFalse);
      port.current = false;
      port.gates['wait']!.complete();
      expect(await running, ActorRouteExecutionOutcome.interrupted);
      expect(port.visible, isTrue);
      expect(port.calls, isNot(contains('sound:late:1.0')));
    });
  }

  test(
      'diagonal actor route is one simultaneous operation and restores priority',
      () async {
    final port = _Port();
    final command = SceneInteractiveCommand.fromJson({
      'kind': 'actorRoute',
      'target': {'kind': 'player', 'mapId': 'centre'},
      'steps': [
        {'kind': 'renderAboveMap', 'enabled': true},
        {
          'kind': 'moveDiagonal',
          'horizontal': 'west',
          'vertical': 'north',
          'durationMs': 250
        },
      ],
      'skippable': false,
    }) as SceneActorRouteInteractiveCommand;
    expect(await executor.execute(command, port: port),
        ActorRouteExecutionOutcome.completed);
    expect(port.calls,
        ['above:true', 'diagonal:west:north:250:false', 'above:false']);
    expect(port.above, isFalse);
  });

  test('scene scope carries flags only between its own explicit routes',
      () async {
    final state = ActorRouteTransientState();
    final port = _Port();
    SceneActorRouteInteractiveCommand scoped(
            String mapId, List<SceneActorRouteStep> steps) =>
        SceneActorRouteInteractiveCommand(
            target: SceneActorTarget.player(mapId: mapId),
            steps: steps,
            transientScope: ActorRouteTransientScope.scene);
    expect(
        await executor.execute(
            scoped('centre', [
              SceneActorRouteStep.through(enabled: true),
              SceneActorRouteStep.renderAboveMap(enabled: true),
            ]),
            port: port,
            sceneState: state),
        ActorRouteExecutionOutcome.completed);
    expect(state.through, isTrue);
    expect(state.renderAboveMap, isTrue);
    expect(port.above, isTrue);
    await executor.execute(
        _route([
          SceneActorRouteStep.move(direction: EntityFacing.east, durationMs: 20)
        ]),
        port: port,
        sceneState: state);
    expect(port.calls.last, 'move:east:20:false');
    expect(state.through, isTrue);
    await executor.execute(
        scoped('upstairs', [
          SceneActorRouteStep.moveDiagonal(
              horizontal: EntityFacing.west,
              vertical: EntityFacing.north,
              durationMs: 250),
          SceneActorRouteStep.through(enabled: false),
          SceneActorRouteStep.renderAboveMap(enabled: false),
        ]),
        port: port,
        sceneState: state);
    expect(port.calls, contains('diagonal:west:north:250:true'));
    expect(state.through, isFalse);
    expect(state.renderAboveMap, isFalse);
    expect(port.above, isFalse);
  });

  test(
      'scene scope cannot use an initial collision owner while through is inherited',
      () async {
    final port = _Port();
    final state = ActorRouteTransientState(through: true);
    final command = SceneActorRouteInteractiveCommand(
        target: SceneActorTarget.player(mapId: 'centre'),
        transientScope: ActorRouteTransientScope.scene,
        steps: [
          SceneActorRouteStep.move(
              direction: EntityFacing.south,
              durationMs: 250,
              initialCollisionOwnerEntityId: 'owner'),
        ]);
    expect(await executor.execute(command, port: port, sceneState: state),
        ActorRouteExecutionOutcome.blocked);
    expect(port.calls, isEmpty);
    expect(state.through, isTrue);
  });

  test('scene scope requires a live scene state before changing presentation',
      () async {
    final port = _Port();
    final command = SceneActorRouteInteractiveCommand(
        target: SceneActorTarget.player(mapId: 'centre'),
        transientScope: ActorRouteTransientScope.scene,
        steps: [SceneActorRouteStep.renderAboveMap(enabled: true)]);
    expect(await executor.execute(command, port: port),
        ActorRouteExecutionOutcome.blocked);
    expect(port.calls, isEmpty);
  });

  for (final scope in ActorRouteTransientScope.values) {
    for (final failure in ['blocked', 'throw', 'interrupted']) {
      test('transient scope=$scope restores previous flags after $failure',
          () async {
        final port = _Port()..above = true;
        final state =
            ActorRouteTransientState(through: true, renderAboveMap: true);
        if (failure == 'blocked')
          port.moveOutcomes.add(ActorRouteMoveOutcome.obstructed);
        if (failure == 'throw') port.failingOperation = 'diagonal';
        if (failure == 'interrupted') port.current = false;
        final command = SceneActorRouteInteractiveCommand(
            target: SceneActorTarget.player(mapId: 'centre'),
            transientScope: scope,
            steps: [
              SceneActorRouteStep.through(enabled: false),
              SceneActorRouteStep.renderAboveMap(enabled: false),
              SceneActorRouteStep.moveDiagonal(
                  horizontal: EntityFacing.east,
                  vertical: EntityFacing.north,
                  durationMs: 250),
            ]);
        final execution =
            executor.execute(command, port: port, sceneState: state);
        if (failure == 'throw') {
          await expectLater(execution, throwsStateError);
        } else {
          expect(
              await execution,
              failure == 'blocked'
                  ? ActorRouteExecutionOutcome.blocked
                  : ActorRouteExecutionOutcome.interrupted);
        }
        expect(port.above, isTrue);
        expect(state.through, isTrue);
        expect(state.renderAboveMap, isTrue);
      });
    }
  }

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
    final running = executor
        .execute(
            _route([
              _yieldingFace(durationMs: 25),
              SceneActorSoundStep(mediaAssetId: 'after-yield', gain: .8),
            ]),
            port: port)
        .then((result) {
      completed = true;
      return result;
    });
    await port
        .waitUntilEntered('nextUpdate')
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
    await port
        .waitUntilEntered('nextUpdate')
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
              ? [
                  'move:north:50:false',
                  'nextUpdate',
                  'wait:25',
                  'move:east:75:false'
                ]
              : ['move:north:50:false']);
    });
  }

  test(
    'a skipped obstruction waits for the next update before sound',
    () async {
      final port = _Port()
        ..moveOutcomes.add(ActorRouteMoveOutcome.obstructed)
        ..gates['nextUpdate'] = Completer<void>();
      var completed = false;
      final running = executor
          .execute(
        _route([
          SceneActorMoveStep(
            direction: EntityFacing.south,
            durationMs: 250,
          ),
          SceneActorSoundStep(mediaAssetId: 'after-skip', gain: .8),
        ], skippable: true),
        port: port,
      )
          .then((result) {
        completed = true;
        return result;
      });
      await Future<void>.delayed(Duration.zero);
      expect(port.calls, ['move:south:250:false', 'nextUpdate']);
      expect(completed, isFalse);
      port.gates['nextUpdate']!.complete();
      expect(await running, ActorRouteExecutionOutcome.completed);
      expect(port.calls.last, 'sound:after-skip:0.8');
    },
  );

  test('closure during the skipped pass prevents the following step', () async {
    final port = _Port()
      ..moveOutcomes.add(ActorRouteMoveOutcome.obstructed)
      ..gates['nextUpdate'] = Completer<void>();
    final running = executor.execute(
      _route([
        SceneActorMoveStep(direction: EntityFacing.south, durationMs: 250),
        SceneActorSoundStep(mediaAssetId: 'must-not-start', gain: .8),
      ], skippable: true),
      port: port,
    );
    await Future<void>.delayed(Duration.zero);
    expect(port.calls, ['move:south:250:false', 'nextUpdate']);
    port.current = false;
    port.gates['nextUpdate']!.complete();
    expect(await running, ActorRouteExecutionOutcome.interrupted);
    expect(port.calls, ['move:south:250:false', 'nextUpdate']);
  });

  test('the skipped pass propagates next-update failures', () async {
    final port = _Port()
      ..moveOutcomes.add(ActorRouteMoveOutcome.obstructed)
      ..failingOperation = 'nextUpdate';
    await expectLater(
      executor.execute(
        _route([
          SceneActorMoveStep(direction: EntityFacing.south, durationMs: 250),
        ], skippable: true),
        port: port,
      ),
      throwsStateError,
    );
  });

  test('a successful skippable move adds no extra update', () async {
    final port = _Port();
    expect(
      await executor.execute(
        _route([
          SceneActorMoveStep(direction: EntityFacing.south, durationMs: 250),
        ], skippable: true),
        port: port,
      ),
      ActorRouteExecutionOutcome.completed,
    );
    expect(port.calls, ['move:south:250:false']);
  });

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
  test('route visibility follows completed movement and explicit restoration',
      () async {
    final port = _Port()..gates['move'] = Completer<void>();
    final pending = executor.execute(
        _route([
          SceneActorRouteStep.move(
              direction: EntityFacing.north, durationMs: 250),
          SceneActorRouteStep.visibility(visible: false),
          SceneActorRouteStep.wait(durationMs: 100),
          SceneActorRouteStep.visibility(visible: true),
        ]),
        port: port);
    await port.waitUntilEntered('move');
    expect(port.calls, ['move:north:250:false']);
    port.gates['move']!.complete();
    expect(await pending, ActorRouteExecutionOutcome.completed);
    expect(port.calls, [
      'move:north:250:false',
      'visibility:false',
      'wait:100',
      'visibility:true'
    ]);
  });
  for (final cancelled in [false, true]) {
    test('uncommitted movement cannot hide the actor: cancellation=$cancelled',
        () async {
      final port = _Port()..gates['move'] = Completer<void>();
      if (!cancelled) port.moveOutcomes.add(ActorRouteMoveOutcome.obstructed);
      final pending = executor.execute(
          _route([
            SceneActorRouteStep.move(
                direction: EntityFacing.north, durationMs: 250),
            SceneActorRouteStep.visibility(visible: false),
          ]),
          port: port);
      await port.waitUntilEntered('move');
      if (cancelled) port.current = false;
      port.gates['move']!.complete();
      expect(
          await pending,
          cancelled
              ? ActorRouteExecutionOutcome.interrupted
              : ActorRouteExecutionOutcome.blocked);
      expect(port.calls, ['move:north:250:false']);
    });
  }
}

SceneActorFaceStep _yieldingFace({int durationMs = 0}) =>
    SceneActorRouteStep.fromJson({
      'kind': 'face',
      'direction': 'north',
      'durationMs': durationMs,
      'yieldAfter': true,
    }) as SceneActorFaceStep;
