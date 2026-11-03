import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_program_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

import 'support/load_flame_component.dart';

final class _ClockProbe extends Component {
  _ClockProbe(this.onTick);
  final void Function() onTick;

  @override
  void update(double dt) => onTick();
}

Map<String, dynamic> _instruction(
  String op, [
  Map<String, dynamic> args = const {},
]) => {
  'op': op,
  'args': args,
  'source': {'index': 0, 'line': 1, 'name': op, 'operands': <String>[]},
};

Map<String, dynamic> _program(List<Map<String, dynamic>> instructions) => {
  'kind': 'gen5SourceProgram',
  'timebaseHz': 60,
  'source': {'path': 'tackle.s'},
  'variants': ['Tackle'],
  'labels': [
    {'name': 'Tackle', 'instructionIndex': 0, 'line': 1},
  ],
  'variant': 'Tackle',
  'entryIndex': 0,
  'conversion': 'supported',
  'instructions': instructions,
};

Future<BattleOverlayComponent> _scene({
  bool intro = false,
  Component? probe,
  void Function() Function(
    StartTrackedEffectStep,
    void Function(),
    void Function(),
  )?
  onStartRecoverableTrackedEffect,
}) async {
  const pokemon = BattleCombatantData(
    speciesId: 'totodile',
    level: 7,
    maxHp: 25,
    currentHp: 25,
    stats: BattleStatsSnapshot(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: 20,
    ),
    moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
  );
  final overlay = BattleOverlayComponent(
    session: createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: pokemon,
        enemyPokemon: pokemon,
        isTrainerBattle: false,
        trainerId: null,
      ),
    ),
    viewportSize: Vector2(390, 844),
    onPlayerChoice: (_) {},
    introEnabled: intro,
    onStartRecoverableTrackedEffect: onStartRecoverableTrackedEffect,
  );
  if (probe != null) overlay.add(probe);
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: []));
  addTearDown(overlay.onRemove);
  return overlay;
}

BattleGen5SourceProgramPlayback _playback(List<int> trace) {
  late final BattleGen5SourceProgramPlayback playback;
  playback = BattleGen5SourceProgramPlayback(
    program: _program([
      _instruction('playSound'),
      _instruction('waitFrames', {'frames': 2}),
      _instruction('playSound'),
      _instruction('end'),
    ]),
    variant: 'Tackle',
    admit: (_) => null,
    dispatch: (_) {
      trace.add(playback.tickCount);
      return BattleGen5SourceDispatchResult.completed;
    },
    isBusy: (_) => false,
    isParticleLoading: () => false,
  );
  return playback;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'source calls use the scene clock for fractional and large updates',
    () async {
      for (final deltas in [
        List<double>.filled(120, 1 / 120),
        List<double>.filled(60, 1 / 60),
        List<double>.filled(30, 1 / 30),
      ]) {
        final overlay = await _scene();
        final trace = <int>[];
        final released = <BattleGen5SourcePlaybackStatus>[];
        final playback = _playback(trace);
        final finished = overlay.presentGen5SourceProgram(
          playback,
          detach: released.add,
        );
        expect(overlay.isTurnPresentationActive, isTrue);
        overlay.updateTree(0);
        expect(trace, isEmpty);
        for (final delta in deltas) {
          overlay.updateTree(delta);
        }
        expect(trace, [1, 5]);
        expect(await finished, BattleGen5SourcePlaybackStatus.finished);
        expect(released, [BattleGen5SourcePlaybackStatus.finished]);
        expect(overlay.isTurnPresentationActive, isFalse);
      }
    },
  );

  test('replacing a presentation cancels the source program once', () async {
    final overlay = await _scene();
    final trace = <int>[];
    final released = <BattleGen5SourcePlaybackStatus>[];
    final playback = _playback(trace);
    final finished = overlay.presentGen5SourceProgram(
      playback,
      detach: released.add,
    );
    overlay.updateTree(1 / 60);
    expect(trace, [1]);
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(steps: [WaitStep(durationSeconds: .1)]),
    );
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(released, [BattleGen5SourcePlaybackStatus.cancelled]);
    overlay.updateTree(1);
    expect(trace, [1]);
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test(
    'a source program does not consume scene debt from before it starts',
    () async {
      final overlay = await _scene();
      overlay.updateTree(2);
      final trace = <int>[];
      final playback = _playback(trace);
      overlay.presentGen5SourceProgram(playback, detach: (_) {});
      overlay.updateTree(1 / 60);
      expect(trace, [1]);
      expect(playback.tickCount, 1);
    },
  );

  test(
    'release failure settles the source presentation with an error',
    () async {
      final overlay = await _scene();
      final playback = _playback(<int>[]);
      var releases = 0;
      final finished = overlay.presentGen5SourceProgram(
        playback,
        detach: (_) {},
        release: (_) {
          releases++;
          throw StateError('release failed');
        },
      );
      final result = expectLater(finished, throwsStateError);
      for (var index = 0; index < 12; index++) {
        overlay.updateTree(1 / 60);
      }
      await result;
      expect(releases, 1);
      expect(overlay.isTurnPresentationActive, isFalse);
    },
  );

  test('completion waits for asynchronous release', () async {
    final overlay = await _scene();
    final playback = _playback(<int>[]);
    final release = Completer<void>();
    final finished = overlay.presentGen5SourceProgram(
      playback,
      detach: (_) {},
      release: (_) => release.future,
    );
    for (var index = 0; index < 12; index++) {
      overlay.updateTree(1 / 60);
    }
    expect(playback.status, BattleGen5SourcePlaybackStatus.finished);
    expect(overlay.isTurnPresentationActive, isTrue);
    release.complete();
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test('a pending battle intro prevents source playback', () async {
    final overlay = await _scene(intro: true);
    final playback = _playback(<int>[]);
    expect(
      () => overlay.presentGen5SourceProgram(playback, detach: (_) {}),
      throwsStateError,
    );
    expect(playback.status, BattleGen5SourcePlaybackStatus.ready);
  });

  test('source playback waits for the prior sprite synchronization', () async {
    final overlay = await _scene();
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(steps: [WaitStep(durationSeconds: .02)]),
    );
    overlay.updateTree(.1);
    final playback = _playback(<int>[]);
    expect(
      () => overlay.presentGen5SourceProgram(playback, detach: (_) {}),
      throwsStateError,
    );
    await overlay.waitForPendingVisualSync();
    final finished = overlay.presentGen5SourceProgram(playback, detach: (_) {});
    overlay.updateTree(.5);
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
  });

  test(
    'end detaches owned visuals before the remaining scene advances',
    () async {
      final events = <String>[];
      final overlay = await _scene(
        probe: _ClockProbe(() => events.add('child')),
      );
      final playback = BattleGen5SourceProgramPlayback(
        program: _program([_instruction('end')]),
        variant: 'Tackle',
        admit: (_) => null,
        dispatch: (_) => BattleGen5SourceDispatchResult.completed,
        isBusy: (_) => false,
        isParticleLoading: () => false,
      );
      final finished = overlay.presentGen5SourceProgram(
        playback,
        detach: (_) => events.add('detach'),
      );
      overlay.updateTree(1 / 120);
      expect(events, ['detach', 'child']);
      expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    },
  );

  test('source tasks advance once per tick after dispatch', () async {
    final overlay = await _scene();
    final events = <String>[];
    final playback = BattleGen5SourceProgramPlayback(
      program: _program([
        _instruction('startEmitter'),
        _instruction('waitFrames', {'frames': 2}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      admit: (_) => null,
      dispatch: (_) {
        events.add('dispatch');
        return BattleGen5SourceDispatchResult.completed;
      },
      isBusy: (_) => false,
      isParticleLoading: () => false,
    );
    final finished = overlay.presentGen5SourceProgram(
      playback,
      advance: () => events.add('advance'),
      detach: (_) => events.add('detach'),
    );
    overlay.updateTree(1 / 120);
    expect(events, ['dispatch', 'advance']);
    overlay.updateTree(1 / 120);
    expect(events, ['dispatch', 'advance']);
    overlay.updateTree(4 / 60);
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(events, [
      'dispatch',
      'advance',
      'advance',
      'advance',
      'advance',
      'detach',
    ]);
  });

  test('task failure cancels the source program and detaches once', () async {
    final overlay = await _scene();
    final playback = _playback(<int>[]);
    final detached = <BattleGen5SourcePlaybackStatus>[];
    final finished = overlay.presentGen5SourceProgram(
      playback,
      advance: () => throw StateError('source task failed'),
      detach: detached.add,
    );
    final result = expectLater(finished, throwsStateError);
    overlay.updateTree(1 / 60);
    await result;
    expect(playback.status, BattleGen5SourcePlaybackStatus.cancelled);
    expect(detached, [BattleGen5SourcePlaybackStatus.cancelled]);
  });

  test(
    'experimental source drives camera, actor and emitter together',
    () async {
      final overlay = await _scene();
      final instructions = [
        _instruction('moveCameraPreset', {
          'moveType': 1,
          'camera': 11,
          'frames': 4,
          'wait': 0,
          'brake': 0,
        }),
        _instruction('waitTasks', {'what': 'CAMERA'}),
        _instruction('moveCombatant', {
          'targets': 'EFFVM_ATTACKER',
          'type': 2,
          'x': 4096,
          'y': 0,
          'frames': 4,
          'wait': 0,
          'times': 1,
        }),
        _instruction('setAnimationState', {
          'targets': 'EFFVM_DEFENDER',
          'mode': 1,
        }),
        _instruction('startEmitter', {
          'particle': 199,
          'emitter': 0,
          'from': 'EFFVM_EMIT_DEFENDER',
          'to': 8,
          'offsetY': 8192,
          'unk18': 0,
          'unused': 0,
          'radiusScale': 4096,
          'lifeScale': 4096,
          'scaleScale': 4096,
          'cameraScale': 4096,
        }),
        _instruction('scaleCombatant', {
          'targets': 'EFFVM_DEFENDER',
          'type': 2,
          'x': 1229,
          'y': -1229,
          'frames': 2,
          'wait': 1,
          'times': 1,
        }),
        _instruction('waitTasks', {'what': 'ALL'}),
        _instruction('setAnimationState', {
          'targets': 'EFFVM_DEFENDER',
          'mode': 0,
        }),
        _instruction('moveCameraPreset', {
          'moveType': 1,
          'camera': 8,
          'frames': 4,
          'wait': 0,
          'brake': 0,
        }),
        _instruction('waitTasks', {'what': 'ALL'}),
        _instruction('end'),
      ];
      final initialPose = overlay.battleCameraPose!;
      final initialActor =
          overlay.debugPlayerCombatant!.currentCameraNeutralRenderedSpriteRect;
      final initialTarget =
          overlay.debugEnemyCombatant!.currentCameraNeutralRenderedSpriteRect;
      var started = false;
      var detached = 0;
      var particleTicks = 0;
      var sawPaused = false;
      var sawMoved = false;
      var sawCamera = false;
      var sawScale = false;
      final finished = overlay.presentExperimentalGen5Attack(
        program: _program(instructions),
        variant: 'Tackle',
        hasEmitter: (particle, emitter) => particle == 199 && emitter == 0,
        startEmitter: (particle, emitter, offsetY) {
          expect((particle, emitter, offsetY), (199, 0, 8192));
          started = true;
          particleTicks = 4;
        },
        particlesBusy: () => particleTicks > 0,
        detachParticles: () => detached++,
        allowSilentAudio: false,
      );
      for (
        var tick = 0;
        tick < 100 && overlay.isTurnPresentationActive;
        tick++
      ) {
        overlay.updateTree(1 / 60);
        if (particleTicks > 0) particleTicks--;
        sawPaused |=
            overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused;
        sawMoved |=
            overlay
                .debugPlayerCombatant!
                .currentCameraNeutralRenderedSpriteRect !=
            initialActor;
        sawCamera |=
            overlay.battleCameraPose!.eye.distanceTo(initialPose.eye) > .01;
        sawScale |=
            overlay
                .debugEnemyCombatant!
                .currentCameraNeutralRenderedSpriteRect
                .size !=
            initialTarget.size;
      }
      expect(await finished, BattleGen5SourcePlaybackStatus.finished);
      expect(started && sawPaused && sawMoved && sawCamera && sawScale, isTrue);
      expect(detached, 1);
      expect(
        overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused,
        isFalse,
      );
      expect(
        overlay.battleCameraPose!.eye.distanceTo(initialPose.eye),
        lessThan(.001),
      );
      final finalActor =
          overlay.debugPlayerCombatant!.currentCameraNeutralRenderedSpriteRect;
      expect(
        (finalActor.center - initialActor.center).distance,
        lessThan(.001),
      );
      expect(finalActor.size, initialActor.size);
    },
  );

  test(
    'experimental source refuses silent audio unless explicitly selected',
    () async {
      final overlay = await _scene();
      expect(
        () => overlay.presentExperimentalGen5Attack(
          program: _program([_instruction('playSound'), _instruction('end')]),
          variant: 'Tackle',
          hasEmitter: (_, _) => false,
          startEmitter: (_, _, _) {},
          particlesBusy: () => false,
          detachParticles: () {},
          allowSilentAudio: false,
        ),
        throwsFormatException,
      );
      expect(overlay.isTurnPresentationActive, isFalse);
    },
  );

  test(
    'a tracked source attack completes before the real turn displays damage',
    () async {
      late BattleOverlayComponent overlay;
      var started = false;
      var completed = false;
      var detached = 0;
      overlay = await _scene(
        onStartRecoverableTrackedEffect: (step, done, fail) {
          expect(step.effectId, 'source-tackle');
          started = true;
          final result = overlay.presentExperimentalGen5Attack(
            program: _program([
              _instruction('waitFrames', {'frames': 20}),
              _instruction('end'),
            ]),
            variant: 'Tackle',
            hasEmitter: (_, _) => false,
            startEmitter: (_, _, _) {},
            particlesBusy: () => false,
            detachParticles: () => detached++,
            allowSilentAudio: false,
            duringTrackedEffect: true,
          );
          unawaited(
            result.then((status) {
              if (status == BattleGen5SourcePlaybackStatus.finished) {
                completed = true;
                done();
              } else {
                fail();
              }
            }, onError: (Object _) => fail()),
          );
          return overlay.cancelExperimentalGen5Attack;
        },
      );
      final initial = overlay.debugSession;
      final turn = initial.applyChoice(const PlayerBattleChoiceFight(0));
      final event = turn.state.currentTurn!.timeline
          .whereType<BattleTurnExecutionEvent>()
          .firstWhere(
            (event) => event.execution.attackerSide == BattleSideId.player,
          );
      expect(
        turn.state.enemy.currentHp,
        lessThan(initial.state.enemy.currentHp),
      );
      overlay.updateState(
        turn,
        experimentalSourceEffects: {event: 'source-tackle'},
      );
      await overlay.waitForPendingVisualSync();
      for (var tick = 0; tick < 240 && !started; tick++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(started, isTrue);
      expect(completed, isFalse);
      expect(
        overlay.currentCommandOverlaySnapshot!.enemyHud.effectiveDisplayedHp,
        initial.state.enemy.currentHp,
      );
      for (
        var tick = 0;
        tick < 600 && overlay.isTurnPresentationActive;
        tick++
      ) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(completed, isTrue);
      expect(detached, 1);
      expect(overlay.isTurnPresentationActive, isFalse);
      expect(
        overlay.currentCommandOverlaySnapshot!.enemyHud.effectiveDisplayedHp,
        turn.state.enemy.currentHp,
      );
    },
  );

  test(
    'replacing a turn cancels its tracked source effect and resumes the actor',
    () async {
      late BattleOverlayComponent overlay;
      var started = false;
      var detached = 0;
      BattleGen5SourcePlaybackStatus? result;
      overlay = await _scene(
        onStartRecoverableTrackedEffect: (step, done, fail) {
          started = true;
          final future = overlay.presentExperimentalGen5Attack(
            program: _program([
              _instruction('setAnimationState', {
                'targets': 'EFFVM_DEFENDER',
                'mode': 1,
              }),
              _instruction('waitFrames', {'frames': 120}),
              _instruction('end'),
            ]),
            variant: 'Tackle',
            hasEmitter: (_, _) => false,
            startEmitter: (_, _, _) {},
            particlesBusy: () => false,
            detachParticles: () => detached++,
            allowSilentAudio: false,
            duringTrackedEffect: true,
          );
          unawaited(
            future.then((status) {
              result = status;
              if (status == BattleGen5SourcePlaybackStatus.finished) {
                done();
              } else {
                fail();
              }
            }, onError: (Object _) => fail()),
          );
          return overlay.cancelExperimentalGen5Attack;
        },
      );
      final turn = overlay.debugSession.applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final event = turn.state.currentTurn!.timeline
          .whereType<BattleTurnExecutionEvent>()
          .firstWhere(
            (event) => event.execution.attackerSide == BattleSideId.player,
          );
      overlay.updateState(
        turn,
        experimentalSourceEffects: {event: 'source-tackle'},
      );
      await overlay.waitForPendingVisualSync();
      for (var tick = 0; tick < 240 && !started; tick++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(started, isTrue);
      overlay.updateTree(1 / 60);
      expect(
        overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused,
        isTrue,
      );
      overlay.presentPostBattlePlan(
        const BattleAnimationPlan(steps: [WaitStep(durationSeconds: .1)]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(result, BattleGen5SourcePlaybackStatus.cancelled);
      expect(detached, 1);
      expect(
        overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused,
        isFalse,
      );
      for (var tick = 0; tick < 40; tick++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(overlay.isTurnPresentationActive, isFalse);
      expect(detached, 1);
    },
  );

  test('BW2 Surf camera shake moves and restores the combat camera', () async {
    final overlay = await _scene();
    final initial = overlay.battleCameraPose!;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('shakeCamera', {
          'direction': 0,
          'amplitude': 410,
          'unused': 4096,
          'frames': 1,
          'wait': 1,
          'count': 14,
        }),
        _instruction('waitTasks', {'what': 'CAMERA'}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: false,
    );

    var highest = 0.0;
    var lowest = 0.0;
    var ticks = 0;
    while (overlay.isTurnPresentationActive && ticks < 200) {
      overlay.updateTree(1 / 60);
      final current = overlay.battleCameraPose!;
      final offset = current.eye.y - initial.eye.y;
      if (offset > highest) highest = offset;
      if (offset < lowest) lowest = offset;
      expect(current.aim.y - initial.aim.y, closeTo(offset, 1 / 4096));
      ticks++;
      await Future<void>.delayed(Duration.zero);
    }

    expect(overlay.isTurnPresentationActive, isFalse);
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(highest, closeTo(410 / 4096, 1 / 4096));
    expect(lowest, closeTo(-410 / 4096, 1 / 4096));
    expect(ticks, greaterThanOrEqualTo(111));
    expect(
      overlay.battleCameraPose!.eye.distanceTo(initial.eye),
      lessThan(.001),
    );
  });

  test(
    'unsupported camera shakes are rejected before the scene moves',
    () async {
      final overlay = await _scene();
      final initial = overlay.battleCameraPose!;
      final validArgs = {
        'direction': 0,
        'amplitude': 410,
        'unused': 4096,
        'frames': 1,
        'wait': 1,
        'count': 14,
      };
      for (final invalid in [
        {'direction': 1},
        {'frames': 0},
        {'frames': 2},
        {'amplitude': 28673},
        {'wait': -1},
        {'count': 0},
      ]) {
        expect(
          () => overlay.presentExperimentalGen5Attack(
            program: _program([
              _instruction('shakeCamera', {...validArgs, ...invalid}),
              _instruction('end'),
            ]),
            variant: 'Tackle',
            hasEmitter: (_, _) => false,
            startEmitter: (_, _, _) {},
            particlesBusy: () => false,
            detachParticles: () {},
            allowSilentAudio: false,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(overlay.isTurnPresentationActive, isFalse);
        expect(overlay.battleCameraPose!.eye.distanceTo(initial.eye), 0);
      }
    },
  );

  test(
    'Surf is rejected before playback while its source operations are missing',
    () async {
      final overlay = await _scene();
      final source = jsonDecode(
        File('../../tools/avelune_attack_comparator/assets/bw2/surf.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final instructions = source['instructions'] as List;
      expect(
        instructions.where((value) => value['op'] == 'startEmitter').length,
        5,
      );
      var starts = 0;
      final originalPose = overlay.battleCameraPose!;
      expect(
        () => overlay.presentExperimentalGen5Attack(
          program: source,
          variant: 'Surf',
          hasEmitter: (_, _) => true,
          startEmitter: (_, _, _) => starts++,
          particlesBusy: () => false,
          detachParticles: () {},
          allowSilentAudio: true,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'reason',
            contains('panSound'),
          ),
        ),
      );
      expect(starts, 0);
      expect(overlay.isTurnPresentationActive, isFalse);
      expect(overlay.battleCameraPose!.eye.distanceTo(originalPose.eye), 0);
    },
  );

  test('Surf dispatches the real source sequence and restores scene state', () async {
    final overlay = await _scene();
    final source = jsonDecode(
      File('../../tools/avelune_attack_comparator/assets/bw2/surf.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final calls = <Map<String, dynamic>>[];
    var detached = 0;
    final initial = overlay.battleCameraPose!;
    final finished = overlay.presentExperimentalGen5Attack(
      program: source,
      variant: 'Surf',
      hasEmitter: (particle, emitter) => particle == 222 && [3, 1, 4, 5, 2].contains(emitter),
      startEmitter: (_, _, _) => fail('Source arguments were not preserved'),
      startSourceEmitter: (args) => calls.add(args),
      particlesBusy: () => false,
      detachParticles: () => detached++,
      allowSilentAudio: true,
      allowUnmappedAudioControls: true,
    );
    var sawHiddenShadows = false;
    var sawPalette = false;
    for (var tick = 0; tick < 500 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      sawHiddenShadows |= overlay.debugPlayerCombatant!.stageShadowTint.a == 0 &&
          overlay.debugEnemyCombatant!.stageShadowTint.a == 0;
      sawPalette |= overlay.debugEnemyCombatant!.hasBattleScriptPalette;
      await Future<void>.delayed(Duration.zero);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls.map((args) => args['emitter']), [3, 1, 4, 5, 2]);
    expect(calls[1]['scaleScale'], 2867);
    expect(calls[3]['from'], 'EFFVM_EMIT_ATTACKER');
    expect(calls[3]['to'], 'EFFVM_EMIT_DEFENDER');
    expect(sawHiddenShadows && sawPalette, isTrue);
    expect(detached, 1);
    expect(overlay.debugPlayerCombatant!.stageShadowTint.a, greaterThan(0));
    expect(overlay.debugEnemyCombatant!.stageShadowTint.a, greaterThan(0));
    expect(overlay.debugEnemyCombatant!.hasBattleScriptPalette, isFalse);
    expect(overlay.debugPlayerCombatant!.debugBattleSpriteAnimationPaused, isFalse);
    expect(overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused, isFalse);
    expect(overlay.battleCameraPose!.eye.distanceTo(initial.eye), lessThan(.001));
  });

  test('cancelling Surf restores shadows and palette', () async {
    final overlay = await _scene();
    final source = jsonDecode(
      File('../../tools/avelune_attack_comparator/assets/bw2/surf.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final finished = overlay.presentExperimentalGen5Attack(
      program: source,
      variant: 'Surf',
      hasEmitter: (_, _) => true,
      startEmitter: (_, _, _) {},
      startSourceEmitter: (_) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      allowUnmappedAudioControls: true,
    );
    for (var tick = 0; tick < 300 && !overlay.debugEnemyCombatant!.hasBattleScriptPalette; tick++) {
      overlay.updateTree(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(overlay.debugEnemyCombatant!.hasBattleScriptPalette, isTrue);
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(overlay.debugEnemyCombatant!.hasBattleScriptPalette, isFalse);
    expect(overlay.debugEnemyCombatant!.stageShadowTint.a, greaterThan(0));
    expect(overlay.debugPlayerCombatant!.stageShadowTint.a, greaterThan(0));
    expect(overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused, isFalse);
  });
}
