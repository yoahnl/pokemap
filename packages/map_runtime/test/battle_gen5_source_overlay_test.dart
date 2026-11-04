import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_program_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_background.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';

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
  Vector2? viewport,
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
    viewportSize: viewport ?? Vector2(390, 844),
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

  test('absolute source camera movement runs and restores the scene', () async {
    final overlay = await _scene();
    final initial = overlay.battleCameraPose!;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('moveCameraAbsolute', {
          'moveType': 1, 'x': 0xca6, 'y': 0x5f33, 'z': 0x1dcc3,
          'targetX': -0xe8d, 'targetY': 0xad9a, 'targetZ': 0x27f6,
          'frames': 32, 'wait': 0, 'brake': 26,
        }),
        _instruction('waitTasks', {'what': 'CAMERA'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true, adaptSourceCamera: true,
    );
    var moved = false;
    for (var tick = 0; tick < 150 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final current = overlay.battleCameraPose!;
      moved |= current.eye.distanceTo(initial.eye) > .0001 ||
          current.aim.distanceTo(initial.aim) > .0001;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(moved, isTrue);
    expect(overlay.battleCameraPose!.eye.distanceTo(initial.eye), lessThan(.001));
  });

  test('field-origin moving emitter is admitted only for the experimental field', () async {
    final overlay = await _scene();
    final args = <String, dynamic>{
      'particle': 418, 'emitter': 3, 'motion': 1,
      'fromX': 0, 'fromY': 0x2000, 'fromZ': 0,
      'to': 'EFFVM_EMIT_DEFENDER', 'offsetY': 0x2000,
      'height': 0, 'turns': 0, 'motionFramesFx32': 20 * 4096,
      'motionFrames': 20, 'lifeScale': 4096, 'cameraScale': 4096,
    };
    final program = _program([_instruction('startMovingFieldEmitter', args),
      _instruction('end')]);
    final calls = <Map<String, dynamic>>[];
    expect(() => overlay.presentExperimentalGen5Attack(
      program: program, variant: 'Tackle', hasEmitter: (_, _) => true,
      startEmitter: (_, _, _) {}, startSourceEmitter: calls.add,
      particlesBusy: () => false, detachParticles: () {}, allowSilentAudio: true,
    ), throwsFormatException);
    final finished = overlay.presentExperimentalGen5Attack(
      program: program, variant: 'Tackle', hasEmitter: (_, _) => true,
      startEmitter: (_, _, _) {}, startSourceEmitter: calls.add,
      particlesBusy: () => false, detachParticles: () {}, allowSilentAudio: true,
      allowFieldEmitters: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls, [args]);
  });

  test('actor camera mode is admitted only for approximate flat actors', () async {
    final overlay = await _scene();
    final program = _program([
      _instruction('setActorCameraMode', {'mode': 0, 'scope': 0}),
      _instruction('end'),
    ]);
    expect(() => overlay.presentExperimentalGen5Attack(
      program: program, variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    ), throwsFormatException);
    final finished = overlay.presentExperimentalGen5Attack(
      program: program, variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
      allowApproximateFlatActors: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
  });

  test('particle deletion stops only the requested source group', () async {
    final overlay = await _scene();
    final active = <int>{511, 513};
    final deleted = <int>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('deleteParticle', {'particle': 511}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      deleteSourceParticle: (int id) {
        deleted.add(id);
        active.remove(id);
      },
      particlesBusy: () => false, detachParticles: () {}, allowSilentAudio: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(deleted, [511]);
    expect(active, {513});
    expect(() => overlay.presentExperimentalGen5Attack(
      program: _program([_instruction('deleteParticle', {'particle': 511}),
        _instruction('end')]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    ), throwsFormatException);
  });

  test('source animation and palette commands affect both combatants', () async {
    final overlay = await _scene();
    final player = overlay.debugPlayerCombatant!;
    final enemy = overlay.debugEnemyCombatant!;
    final other = Object();
    player.pauseBattleSpriteAnimation(owner: other);
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setAnimationState', {'targets': 'EFFVM_ALL', 'mode': 1}),
        _instruction('fadePalette', {
          'targets': 'EFFVM_ALL', 'startEvy': 0, 'endEvy': 12,
          'wait': 0, 'color': 32767,
        }),
        _instruction('waitFrames', {'frames': 60}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    );
    for (var tick = 0; tick < 8; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(player.debugBattleSpriteAnimationPaused, isTrue);
    expect(enemy.debugBattleSpriteAnimationPaused, isTrue);
    expect(player.hasBattleScriptPalette, isTrue);
    expect(enemy.hasBattleScriptPalette, isTrue);
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(player.debugBattleSpriteAnimationPaused, isTrue);
    expect(enemy.debugBattleSpriteAnimationPaused, isFalse);
    expect(player.hasBattleScriptPalette, isFalse);
    expect(enemy.hasBattleScriptPalette, isFalse);
    player.resumeBattleSpriteAnimation(owner: other);
  });

  test('source cries require explicit silent audio admission', () async {
    final overlay = await _scene();
    final program = _program([
      _instruction('playCry', {
        'targets': 'EFFVM_ATTACKER', 'speed': 34304, 'volume': 127,
        'chorusVolume': 60, 'chorusSpeed': -64, 'reverse': 1, 'delay': 0,
      }),
      _instruction('waitTasks', {'what': 'CRY'}),
      _instruction('end'),
    ]);
    Future<BattleGen5SourcePlaybackStatus> play(bool silent) =>
        overlay.presentExperimentalGen5Attack(
          program: program, variant: 'Tackle', hasEmitter: (_, _) => false,
          startEmitter: (_, _, _) {}, particlesBusy: () => false,
          detachParticles: () {}, allowSilentAudio: silent,
        );
    expect(() => play(false), throwsFormatException);
    final finished = play(true);
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
  });

  test('source alpha fades the attacker and waits before restoring it', () async {
    final overlay = await _scene();
    final actor = overlay.debugPlayerCombatant!;
    final initialAlpha = actor.stageTint.a;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('fadeCombatantAlpha', {
          'targets': 'EFFVM_ATTACKER', 'type': 1, 'alpha': 2,
          'frames': 8, 'wait': 1, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('fadeCombatantAlpha', {
          'targets': 'EFFVM_ATTACKER', 'type': 1, 'alpha': 31,
          'frames': 8, 'wait': 0, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true, allowSourceVisibility: true,
    );
    var minimum = initialAlpha;
    for (var tick = 0; tick < 80 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      if (actor.stageTint.a < minimum) minimum = actor.stageTint.a;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(minimum, closeTo(2 / 31, .01));
    expect(actor.stageTint.a, initialAlpha);
  });

  test('source alpha is restored after cancellation', () async {
    final overlay = await _scene();
    final actor = overlay.debugPlayerCombatant!;
    final initialAlpha = actor.stageTint.a;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('fadeCombatantAlpha', {
          'targets': 'EFFVM_ATTACKER', 'type': 0, 'alpha': 2,
          'frames': 1, 'wait': 0, 'times': 0,
        }),
        _instruction('waitFrames', {'frames': 60}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true, allowSourceVisibility: true,
    );
    for (var tick = 0; tick < 4; tick++) overlay.updateTree(1 / 60);
    expect(actor.stageTint.a, closeTo(2 / 31, .01));
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(actor.stageTint.a, initialAlpha);
  });

  test('source visibility hides then restores the attacker', () async {
    final overlay = await _scene();
    final actor = overlay.debugPlayerCombatant!;
    final initialAlpha = actor.stageTint.a;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setCombatantVisibility', {'targets': 'EFFVM_ATTACKER', 'mode': 3}),
        _instruction('waitFrames', {'frames': 4}),
        _instruction('setCombatantVisibility', {'targets': 'EFFVM_ATTACKER', 'mode': 4}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true, allowSourceVisibility: true,
    );
    var hidden = false;
    for (var tick = 0; tick < 20 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      hidden |= actor.stageTint.a == 0;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(hidden, isTrue);
    expect(actor.stageTint.a, initialAlpha);
  });

  test('source visibility cleanup preserves other hiding owners', () async {
    final overlay = await _scene();
    final actor = overlay.debugPlayerCombatant!;
    final other = Object();
    actor.setBattleScriptHidden(true, owner: other);
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setCombatantVisibility', {'targets': 'EFFVM_ATTACKER', 'mode': 3}),
        _instruction('waitFrames', {'frames': 60}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true, allowSourceVisibility: true,
    );
    overlay.updateTree(1 / 60);
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(actor.stageTint.a, 0);
    actor.setBattleScriptHidden(false, owner: other);
    expect(actor.stageTint.a, greaterThan(0));
  });

  test('relative source camera movement runs and restores the scene', () async {
    final overlay = await _scene();
    final initial = overlay.battleCameraPose!;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('moveCameraRelative', {
          'moveType': 2, 'x': 4096, 'y': 0, 'z': 0,
          'targetX': 0, 'targetY': 4096, 'targetZ': 0,
          'frames': 4, 'wait': 0, 'brake': 0,
        }),
        _instruction('waitTasks', {'what': 'CAMERA'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: false, adaptSourceCamera: true,
    );
    var moved = false;
    for (var tick = 0; tick < 30 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final current = overlay.battleCameraPose!;
      moved |= current.eye.distanceTo(initial.eye) > .0001 ||
          current.aim.distanceTo(initial.aim) > .0001;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(moved, isTrue);
    expect(overlay.battleCameraPose!.eye.distanceTo(initial.eye), lessThan(.001));
  });

  test('source scene admits sinusoidal moving emitters', () async {
    for (final type in [5, 6]) {
      final overlay = await _scene();
      final arguments = <String, dynamic>{
        'particle': 308, 'emitter': 0, 'motion': type,
        'from': 'EFFVM_EMIT_ATTACKER', 'to': 'EFFVM_EMIT_DEFENDER',
        'offsetY': 8192, 'height': 1638, 'turns': 16384,
        'motionFramesFx32': 100 * 4096, 'motionFrames': 100,
        'lifeScale': 4096, 'cameraScale': 4096,
      };
      final calls = <Map<String, dynamic>>[];
      final finished = overlay.presentExperimentalGen5Attack(
        program: _program([
          _instruction('startMovingEmitter', arguments),
          _instruction('end'),
        ]),
        variant: 'Tackle', hasEmitter: (_, _) => true,
        startEmitter: (_, _, _) => fail('source arguments must be preserved'),
        startSourceEmitter: calls.add, particlesBusy: () => false,
        detachParticles: () {}, allowSilentAudio: true,
      );
      for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
        overlay.updateTree(1 / 60);
      }
      expect(await finished, BattleGen5SourcePlaybackStatus.finished);
      expect(calls, [arguments]);
    }
  });

  test('source scene runs field emitters with their original coordinates', () async {
    final overlay = await _scene();
    final args = <String, dynamic>{
      'particle': 529, 'emitter': 0,
      'fromX': 0, 'fromY': 0, 'fromZ': 0x3000,
      'toX': 0, 'toY': 0, 'toZ': 0,
      'offsetY': 0x2000, 'unk18': 0, 'unused': 0,
      'radiusScale': 4096, 'lifeScale': 4096,
      'scaleScale': 4096, 'cameraScale': 4096,
    };
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('startFieldEmitter', args),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (particle, emitter) => particle == 529 && emitter == 0,
      startEmitter: (_, _, _) => fail('source arguments must be preserved'),
      startSourceEmitter: calls.add, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true, allowFieldEmitters: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls, [args]);
    expect(overlay.experimentalGen5FieldProjection().capture(), isNotNull);
  });

  test('field projection preserves the BW2 positions of both combatants', () async {
    for (final viewport in [Vector2(390, 844), Vector2(844, 390)]) {
      final overlay = await _scene(viewport: viewport);
      final field = overlay.experimentalGen5FieldProjection();
      final player = field.capture()!.single;
      final enemy = overlay.experimentalGen5Projection(
        attacker: false, anchorAtFoot: true,
      ).capture()!.single;
      final delta = field.worldTransform!.apply((
        x: 0x4cd - 0x800, y: 0, z: -0xa000 - 0x7000,
      ));
      expect(player.x + delta.x, closeTo(enemy.x, .001));
      expect(player.z + delta.z, closeTo(enemy.z, .001));
    }
  });

  test('field emitter anchor stays fixed while the attacker moves', () async {
    final overlay = await _scene();
    final field = overlay.experimentalGen5FieldProjection();
    final initialAnchor = field.capture()!.single;
    final initialActor = overlay.debugPlayerCombatant!.currentVisualOffset;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('moveCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 2, 'x': 4096, 'y': 0,
          'frames': 3, 'wait': 0, 'times': 1,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    );
    var moved = false;
    for (var tick = 0; tick < 20 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      moved |= overlay.debugPlayerCombatant!.currentVisualOffset != initialActor;
      final currentAnchor = field.capture()!.single;
      expect(currentAnchor.x, closeTo(initialAnchor.x, .001));
      expect(currentAnchor.y, closeTo(initialAnchor.y, .001));
      expect(currentAnchor.z, closeTo(initialAnchor.z, .001));
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(moved, isTrue);
  });

  test('relative source movement holds the actor and returns it to rest', () async {
    final overlay = await _scene();
    final actor = overlay.debugPlayerCombatant!;
    final initial = actor.currentVisualOffset;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('moveCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 1, 'x': 8192, 'y': 0,
          'frames': 2, 'wait': 0, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('waitFrames', {'frames': 4}),
        _instruction('moveCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 5, 'x': 0, 'y': 0,
          'frames': 2, 'wait': 0, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    );
    var heldTicks = 0;
    for (var tick = 0; tick < 40 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      if ((actor.currentVisualOffset.dx - initial.dx - 10).abs() < .001) {
        heldTicks++;
      }
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(heldTicks, greaterThanOrEqualTo(3));
    expect(actor.currentVisualOffset, initial);
  });

  test('cancelling a held relative source position restores the actor', () async {
    final overlay = await _scene();
    final actor = overlay.debugPlayerCombatant!;
    final initial = actor.currentVisualOffset;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('moveCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 1, 'x': 8192, 'y': 0,
          'frames': 2, 'wait': 0, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('waitFrames', {'frames': 60}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    );
    for (var tick = 0; tick < 8; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(actor.currentVisualOffset.dx - initial.dx, closeTo(10, .001));
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(actor.currentVisualOffset, initial);
  });

  test('source position shake moves a combatant in both directions', () async {
    final overlay = await _scene();
    final initial = overlay.debugPlayerCombatant!.currentVisualOffset;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('moveCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 3, 'x': 4096, 'y': 0,
          'frames': 1, 'wait': 0, 'times': 1,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: false,
    );
    var highest = 0.0;
    var lowest = 0.0;
    for (var tick = 0; tick < 20 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final x = overlay.debugPlayerCombatant!.currentVisualOffset.dx - initial.dx;
      if (x > highest) highest = x;
      if (x < lowest) lowest = x;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(highest, greaterThan(0));
    expect(lowest, lessThan(0));
    expect(overlay.debugPlayerCombatant!.currentVisualOffset, initial);
  });

  test('stage and field wait follows the active scene fade', () async {
    final overlay = await _scene();
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setYield', {'value': false}),
        _instruction('fadeStagePalette', {
          'fade': 4, 'evy': 0, 'targetEvy': 4, 'wait': 1, 'color': 0,
        }),
        _instruction('waitTasks', {'what': 'STAGE_FIELD_FADE'}),
        _instruction('startEmitter', {
          'particle': 1, 'emitter': 0,
          'from': 'EFFVM_EMIT_DEFENDER', 'to': 8, 'offsetY': 0,
          'unk18': 0, 'unused': 0, 'radiusScale': 4096,
          'lifeScale': 4096, 'scaleScale': 4096, 'cameraScale': 4096,
        }),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => true,
      startEmitter: (_, _, _) => fail('source arguments must be preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
    );
    for (var tick = 0; tick < 3; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(calls, isEmpty);
    for (var tick = 0; tick < 30 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls, hasLength(1));
  });

  testWidgets('scene palette fade leaves attack particles unchanged', (tester) async {
    final overlay = await _scene();
    final particle = RectangleComponent(
      position: Vector2(10, 10),
      size: Vector2.all(20),
      priority: 10,
      paint: ui.Paint()..color = const ui.Color(0xffff00ff),
    );
    overlay.add(particle);
    overlay.findGame()!.processLifecycleEvents();
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setYield', {'value': false}),
        _instruction('fadeStagePalette', {
          'fade': 4, 'evy': 16, 'targetEvy': 16, 'wait': 0, 'color': 0,
        }),
        _instruction('waitFrames', {'frames': 100}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
    );
    overlay.updateTree(1 / 60);
    overlay.findGame()!.processLifecycleEvents();
    final recorder = ui.PictureRecorder();
    overlay.renderTree(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(390, 844);
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final pixel = (15 * 390 + 15) * 4;
    expect([bytes!.getUint8(pixel), bytes.getUint8(pixel + 1),
      bytes.getUint8(pixel + 2), bytes.getUint8(pixel + 3)], [255, 0, 255, 255]);
    image.dispose();
    picture.dispose();
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
  });

  testWidgets('stage and background palette fades keep separate targets', (tester) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xff0000ff), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(512, 512);
    addTearDown(image.dispose);
    addTearDown(picture.dispose);
    final overlay = await _scene();
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setYield', {'value': false}),
        _instruction('loadBackground', {'background': 18}),
        _instruction('setSceneVisibility', {'target': 2, 'hide': 0}),
        _instruction('fadeStagePalette', {
          'fade': 2, 'evy': 16, 'targetEvy': 16, 'wait': 0, 'color': 0,
        }),
        _instruction('fadeStagePalette', {
          'fade': 3, 'evy': 16, 'targetEvy': 16, 'wait': 0, 'color': 31,
        }),
        _instruction('waitFrames', {'frames': 100}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
      sourceBackgrounds: {18: image},
    );
    overlay.updateTree(1 / 60);
    overlay.findGame()!.processLifecycleEvents();
    final stage = overlay.children.whereType<BattleStage3DComponent>().single;
    final background = overlay.children.whereType<BattleGen5SourceBackground>().single;
    expect(stage.sourcePaletteFilter, isNotNull);
    final output = ui.PictureRecorder();
    background.render(ui.Canvas(output));
    final frame = output.endRecording();
    final rendered = frame.toImageSync(390, 844);
    final bytes = await tester.runAsync(
      () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final pixel = (100 * 390 + 100) * 4;
    expect([bytes!.getUint8(pixel), bytes.getUint8(pixel + 1),
      bytes.getUint8(pixel + 2), bytes.getUint8(pixel + 3)], [255, 0, 0, 255]);
    rendered.dispose();
    frame.dispose();
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    expect(stage.sourcePaletteFilter, isNull);
  });

  testWidgets('waiting for the stage does not wait for a separate background fade', (tester) async {
    final sourceRecorder = ui.PictureRecorder();
    ui.Canvas(sourceRecorder).drawColor(const ui.Color(0xff0000ff), ui.BlendMode.src);
    final sourcePicture = sourceRecorder.endRecording();
    final image = sourcePicture.toImageSync(512, 512);
    addTearDown(image.dispose);
    addTearDown(sourcePicture.dispose);
    final overlay = await _scene();
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setYield', {'value': false}),
        _instruction('loadBackground', {'background': 18}),
        _instruction('setSceneVisibility', {'target': 2, 'hide': 0}),
        _instruction('fadeStagePalette', {
          'fade': 2, 'evy': 0, 'targetEvy': 3, 'wait': 1, 'color': 0,
        }),
        _instruction('fadeStagePalette', {
          'fade': 3, 'evy': 0, 'targetEvy': 16, 'wait': 1, 'color': 31,
        }),
        _instruction('waitTasks', {'what': 'STAGE_FIELD_FADE'}),
        _instruction('startEmitter', {
          'particle': 1, 'emitter': 0,
          'from': 'EFFVM_EMIT_DEFENDER', 'to': 8, 'offsetY': 0,
          'unk18': 0, 'unused': 0, 'radiusScale': 4096,
          'lifeScale': 4096, 'scaleScale': 4096, 'cameraScale': 4096,
        }),
        _instruction('waitFrames', {'frames': 100}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => true,
      startEmitter: (_, _, _) => fail('source arguments must be preserved'),
      startSourceEmitter: calls.add, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: true,
      sourceBackgrounds: {18: image},
    );
    for (var tick = 0; tick < 25 && calls.isEmpty; tick++) {
      overlay.updateTree(1 / 60);
      overlay.findGame()!.processLifecycleEvents();
    }
    expect(calls, hasLength(1));
    final background = overlay.children.whereType<BattleGen5SourceBackground>().single;
    final output = ui.PictureRecorder();
    background.render(ui.Canvas(output));
    final frame = output.endRecording();
    final rendered = frame.toImageSync(390, 844);
    final bytes = await tester.runAsync(
      () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final red = bytes!.getUint8((100 * 390 + 100) * 4);
    expect(red, greaterThan(0));
    expect(red, lessThan(255));
    rendered.dispose();
    frame.dispose();
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
  });

  test('orthographic source emitter can target the opposite combatant', () async {
    final overlay = await _scene();
    final arguments = <String, dynamic>{
      'particle': 236, 'emitter': 0,
      'from': 'EFFVM_EMIT_DEFENDER', 'to': 'EFFVM_EMIT_ATTACKER',
      'offsetX': 0, 'offsetY': 2867, 'offsetZ': 0,
      'radiusScale': 2048, 'lifeScale': 4096, 'scaleScale': 2048,
      'cameraScale': 4096,
    };
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('startOrthoEmitter', arguments),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (particle, emitter) => particle == 236 && emitter == 0,
      startEmitter: (_, _, _) => fail('source arguments must be preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      allowOrthographicEmitters: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls, [arguments]);
  });

  test('moving source emitter preserves particle lifetime scaling', () async {
    final overlay = await _scene();
    final arguments = <String, dynamic>{
      'particle': 605, 'emitter': 0, 'motion': 2,
      'from': 'EFFVM_EMIT_ATTACKER', 'to': 'EFFVM_EMIT_DEFENDER',
      'offsetY': 8192, 'height': 16384, 'turns': 0,
      'motionFramesFx32': 54 * 4096, 'motionFrames': 54,
      'lifeScale': 3686, 'cameraScale': 4096,
    };
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('startMovingEmitter', arguments),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (particle, emitter) => particle == 605 && emitter == 0,
      startEmitter: (_, _, _) => fail('source arguments must be preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls, [arguments]);
  });

  test('source emitter preserves non-neutral scaling and reverse target', () async {
    final overlay = await _scene();
    final arguments = <String, dynamic>{
      'particle': 470, 'emitter': 0,
      'from': 'EFFVM_EMIT_DEFENDER', 'to': 'EFFVM_EMIT_ATTACKER',
      'offsetY': 8192, 'unk18': 12288, 'unused': 1,
      'radiusScale': 2048, 'lifeScale': 2048, 'scaleScale': 6144,
      'cameraScale': 4096,
    };
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('startEmitter', arguments),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (particle, emitter) => particle == 470 && emitter == 0,
      startEmitter: (_, _, _) => fail('source arguments must be preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
    );
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls, [arguments]);
  });

  test('source background moves and restores the scene after playback', () async {
    final overlay = await _scene();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xff2244aa), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(512, 512);
    addTearDown(image.dispose);
    addTearDown(picture.dispose);
    final program = _program([
      _instruction('setYield', {'value': false}),
      _instruction('loadBackground', {'background': 18}),
      _instruction('setSceneVisibility', {'target': 2, 'hide': 0}),
      _instruction('setSceneVisibility', {'target': 0, 'hide': 1}),
      _instruction('setSceneVisibility', {'target': 1, 'hide': 1}),
      _instruction('moveBackground', {
        'mode': 4, 'x': -20, 'y': 0, 'frames': 2, 'wait': 0, 'count': 0,
      }),
      _instruction('setYield', {'value': true}),
      _instruction('waitTasks', {'what': 'BG'}),
      _instruction('end'),
    ]);
    Future<BattleGen5SourcePlaybackStatus> play(Map<int, ui.Image> backgrounds) =>
        overlay.presentExperimentalGen5Attack(
          program: program,
          variant: 'Tackle',
          hasEmitter: (_, _) => false,
          startEmitter: (_, _, _) {},
          particlesBusy: () => false,
          detachParticles: () {},
          allowSilentAudio: true,
          sourceBackgrounds: backgrounds,
        );
    expect(() => play({}), throwsFormatException);
    final finished = play({18: image});
    overlay.updateTree(1 / 60);
    overlay.findGame()!.processLifecycleEvents();
    final stage = overlay.children.whereType<BattleStage3DComponent>().single;
    final background = overlay.children.whereType<BattleGen5SourceBackground>().single;
    expect(background.viewport(), const ui.Rect.fromLTWH(0, 0, 390, 844));
    expect(stage.sourceHidePlatforms, isTrue);
    expect(stage.sourceHideFloor, isTrue);
    expect(background.visible, isTrue);
    expect(background.isMoving, isTrue);
    for (var tick = 0; tick < 12 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    overlay.findGame()!.processLifecycleEvents();
    expect(stage.sourceHidePlatforms, isFalse);
    expect(stage.sourceHideFloor, isFalse);
    expect(overlay.children.whereType<BattleGen5SourceBackground>(), isEmpty);
  });

  test('cancelling a source background restores both scene layers', () async {
    final overlay = await _scene();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xff2244aa), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(512, 512);
    addTearDown(image.dispose);
    addTearDown(picture.dispose);
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setYield', {'value': false}),
        _instruction('loadBackground', {'background': 18}),
        _instruction('setSceneVisibility', {'target': 2, 'hide': 0}),
        _instruction('setSceneVisibility', {'target': 0, 'hide': 1}),
        _instruction('setSceneVisibility', {'target': 1, 'hide': 1}),
        _instruction('waitFrames', {'frames': 100}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      sourceBackgrounds: {18: image},
    );
    overlay.updateTree(1 / 60);
    overlay.findGame()!.processLifecycleEvents();
    final stage = overlay.children.whereType<BattleStage3DComponent>().single;
    expect(stage.sourceHidePlatforms, isTrue);
    expect(stage.sourceHideFloor, isTrue);
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    overlay.findGame()!.processLifecycleEvents();
    expect(stage.sourceHidePlatforms, isFalse);
    expect(stage.sourceHideFloor, isFalse);
    expect(overlay.children.whereType<BattleGen5SourceBackground>(), isEmpty);
  });

  test('source field and full-scene fade work without a background image', () async {
    final overlay = await _scene();
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('setYield', {'value': false}),
        _instruction('fadeStagePalette', {
          'fade': 4, 'evy': 0, 'targetEvy': 0, 'wait': 0, 'color': 0,
        }),
        _instruction('setSceneVisibility', {'target': 0, 'hide': 1}),
        _instruction('setSceneVisibility', {'target': 1, 'hide': 1}),
        _instruction('waitFrames', {'frames': 100}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
    );
    overlay.updateTree(1 / 60);
    overlay.findGame()!.processLifecycleEvents();
    final stage = overlay.children.whereType<BattleStage3DComponent>().single;
    expect(stage.sourceHidePlatforms, isTrue);
    expect(stage.sourceHideFloor, isTrue);
    expect(overlay.children.whereType<BattleGen5SourceBackground>().single.hideField,
        isTrue);
    overlay.cancelExperimentalGen5Attack();
    expect(await finished, BattleGen5SourcePlaybackStatus.cancelled);
    overlay.findGame()!.processLifecycleEvents();
    expect(stage.sourceHidePlatforms, isFalse);
    expect(stage.sourceHideFloor, isFalse);
    expect(overlay.children.whereType<BattleGen5SourceBackground>(), isEmpty);
  });

  test('orthographic emitters require an explicit scene handler', () async {
    final overlay = await _scene();
    final args = <String, dynamic>{
      'particle': 270, 'emitter': 0, 'from': 'EFFVM_EMIT_DEFENDER',
      'to': 8, 'offsetX': 0, 'offsetY': 8192, 'offsetZ': 0,
      'radiusScale': 2048, 'lifeScale': 4096, 'scaleScale': 2048,
      'cameraScale': 4096,
    };
    Future<BattleGen5SourcePlaybackStatus> play({required bool allow}) =>
        overlay.presentExperimentalGen5Attack(
          program: _program([
            _instruction('startOrthoEmitter', args),
            _instruction('end'),
          ]),
          variant: 'Tackle',
          hasEmitter: (particle, emitter) => particle == 270 && emitter == 0,
          startEmitter: (_, _, _) => fail('source arguments must be preserved'),
          startSourceEmitter: (value) => expect(value, args),
          particlesBusy: () => false,
          detachParticles: () {},
          allowSilentAudio: true,
          allowOrthographicEmitters: allow,
        );
    expect(() => play(allow: false), throwsFormatException);
    final finished = play(allow: true);
    for (var tick = 0; tick < 10 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
  });

  test('BW2 scale step persists across waits and returns to its original size', () async {
    final overlay = await _scene();
    final initial = overlay.debugPlayerCombatant!
        .currentCameraNeutralRenderedSpriteRect;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('scaleCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 1, 'x': 2048, 'y': 2048,
          'frames': 4, 'wait': 0, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('waitFrames', {'frames': 5}),
        _instruction('scaleCombatant', {
          'targets': 'EFFVM_ATTACKER', 'type': 1, 'x': 4096, 'y': 4096,
          'frames': 4, 'wait': 0, 'times': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
    );
    var heldTicks = 0;
    for (var tick = 0; tick < 50 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final width = overlay.debugPlayerCombatant!
          .currentCameraNeutralRenderedSpriteRect.width;
      if ((width - initial.width / 2).abs() < 0.01) heldTicks++;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(heldTicks, greaterThanOrEqualTo(5));
    expect(overlay.debugPlayerCombatant!
        .currentCameraNeutralRenderedSpriteRect, initial);
  });

  test('BW2 scale shake rejects unsafe rounded scales before playback', () async {
    final overlay = await _scene();
    Object? failure;
    try {
      final pending = overlay.presentExperimentalGen5Attack(
        program: _program([
          _instruction('scaleCombatant', {
            'targets': 'EFFVM_DEFENDER', 'type': 3, 'x': 4095, 'y': 0,
            'frames': 2, 'wait': 0, 'times': 1,
          }),
          _instruction('end'),
        ]),
        variant: 'Tackle',
        hasEmitter: (_, _) => false,
        startEmitter: (_, _, _) {},
        particlesBusy: () => false,
        detachParticles: () {},
        allowSilentAudio: true,
      );
      overlay.cancelExperimentalGen5Attack();
      await pending;
    } on Object catch (error) {
      failure = error;
    }
    expect(failure, isA<FormatException>());
  });

  test('BW2 scale shake animates the target and restores its size', () async {
    final overlay = await _scene();
    final initial = overlay.debugEnemyCombatant!
        .currentCameraNeutralRenderedSpriteRect;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('scaleCombatant', {
          'targets': 'EFFVM_DEFENDER', 'type': 3, 'x': -1024, 'y': 1024,
          'frames': 2, 'wait': 1, 'times': 1,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
    );
    var sawSmaller = false;
    var sawLarger = false;
    for (var tick = 0; tick < 50 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final width = overlay.debugEnemyCombatant!
          .currentCameraNeutralRenderedSpriteRect.width;
      sawSmaller |= width < initial.width;
      sawLarger |= width > initial.width;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(sawSmaller, isTrue);
    expect(sawLarger, isTrue);
    expect(overlay.debugEnemyCombatant!
        .currentCameraNeutralRenderedSpriteRect, initial);
  });

  test('BW2 circular actor motion projects depth and restores the actor', () async {
    final overlay = await _scene();
    final initial = overlay.debugPlayerCombatant!
        .currentCameraNeutralRenderedSpriteRect;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('circleCombatant', {
          'targets': 'EFFVM_ATTACKER',
          'mode': 3,
          'start': 3,
          'radius1': 4096,
          'radius2': 4096,
          'framesFx32': 40960,
          'frames': 10,
          'waitFx32': 4096,
          'wait': 1,
          'countFx32': 4096,
          'count': 1,
          'turnWait': 0,
        }),
        _instruction('waitTasks', {'what': 'MCSS'}),
        _instruction('end'),
      ]),
      variant: 'Tackle',
      hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {},
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      adaptSourceCamera: true,
    );
    var sawHorizontal = false;
    var sawVertical = false;
    for (var tick = 0; tick < 100 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final current = overlay.debugPlayerCombatant!
          .currentCameraNeutralRenderedSpriteRect;
      sawHorizontal |= (current.center.dx - initial.center.dx).abs() > .1;
      sawVertical |= (current.center.dy - initial.center.dy).abs() > .1;
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(sawHorizontal, isTrue);
    expect(sawVertical, isTrue);
    expect(overlay.debugPlayerCombatant!
        .currentCameraNeutralRenderedSpriteRect, initial);
  });

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

  test('BW2 horizontal camera shake moves and restores the combat camera', () async {
    final overlay = await _scene();
    final initial = overlay.battleCameraPose!;
    final finished = overlay.presentExperimentalGen5Attack(
      program: _program([
        _instruction('shakeCamera', {
          'direction': 1, 'amplitude': 819, 'unused': 0,
          'frames': 2, 'wait': 0, 'count': 1,
        }),
        _instruction('waitTasks', {'what': 'CAMERA'}),
        _instruction('end'),
      ]),
      variant: 'Tackle', hasEmitter: (_, _) => false,
      startEmitter: (_, _, _) {}, particlesBusy: () => false,
      detachParticles: () {}, allowSilentAudio: false,
    );
    var highest = 0.0;
    var lowest = 0.0;
    for (var tick = 0; tick < 40 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final current = overlay.battleCameraPose!;
      final offset = current.eye.x - initial.eye.x;
      if (offset > highest) highest = offset;
      if (offset < lowest) lowest = offset;
      expect(current.aim.x - initial.aim.x, closeTo(offset, 1 / 4096));
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(highest, closeTo(820 / 4096, 1 / 4096));
    expect(lowest, closeTo(-820 / 4096, 1 / 4096));
    expect(overlay.battleCameraPose!.eye.distanceTo(initial.eye), lessThan(.001));
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
        {'direction': 2},
        {'frames': 0},
        {'frames': 601},
        {'frames': 600},
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

  test('Water Gun dispatches each source projectile and impact independently', () async {
    final overlay = await _scene();
    final source = jsonDecode(
      File('../../tools/avelune_attack_comparator/assets/bw2/water_gun.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final calls = <Map<String, dynamic>>[];
    var detached = 0;
    final initial = overlay.battleCameraPose!;
    final finished = overlay.presentExperimentalGen5Attack(
      program: source,
      variant: 'WaterGun',
      hasEmitter: (particle, emitter) => particle == 220 && [0, 1].contains(emitter),
      startEmitter: (_, _, _) => fail('Source arguments were not preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () => detached++,
      allowSilentAudio: true,
      allowUnmappedAudioControls: true,
      allowApproximateFlatActors: true,
    );
    for (var tick = 0; tick < 500 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls.where((args) => args['motion'] == 1), hasLength(15));
    expect(calls.where((args) => !args.containsKey('motion')), hasLength(2));
    expect(calls.where((args) => args['motion'] == 1).every((args) =>
        args['emitter'] == 1 && args['from'] == 'EFFVM_EMIT_ATTACKER' &&
        args['to'] == 'EFFVM_EMIT_DEFENDER' && args['motionFramesFx32'] == 0x1e000), isTrue);
    expect(detached, 1);
    expect(overlay.debugEnemyCombatant!.debugBattleSpriteAnimationPaused, isFalse);
    expect(overlay.battleCameraPose!.eye.distanceTo(initial.eye), lessThan(.001));
  });

  test('Acid dispatches four arcs and its three impacts', () async {
    final overlay = await _scene();
    final source = jsonDecode(
      File('../../tools/avelune_attack_comparator/assets/bw2/acid.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: source,
      variant: 'Acid',
      hasEmitter: (particle, emitter) => particle == 216 && emitter <= 3,
      startEmitter: (_, _, _) => fail('Source arguments were not preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      allowUnmappedAudioControls: true,
      allowApproximateFlatActors: true,
    );
    for (var tick = 0; tick < 500 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(calls.where((args) => args['motion'] == 2), hasLength(4));
    expect(calls.where((args) => !args.containsKey('motion')), hasLength(3));
  });

  test('Flamethrower fades the stage and releases it at the end', () async {
    final overlay = await _scene();
    final source = jsonDecode(
      File('../../tools/avelune_attack_comparator/assets/bw2/flamethrower.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final calls = <Map<String, dynamic>>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: source,
      variant: 'Flamethrower',
      hasEmitter: (particle, emitter) => particle == 218 && emitter <= 3,
      startEmitter: (_, _, _) => fail('Source arguments were not preserved'),
      startSourceEmitter: calls.add,
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      allowUnmappedAudioControls: true,
      allowApproximateFlatActors: true,
    );
    var sawStageFade = false;
    for (var tick = 0; tick < 500 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      overlay.findGame()!.processLifecycleEvents();
      sawStageFade |= overlay.children.whereType<BattleStage3DComponent>()
          .single.sourcePaletteFilter != null;
      await Future<void>.delayed(Duration.zero);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    overlay.findGame()!.processLifecycleEvents();
    expect(sawStageFade, isTrue);
    expect(calls.where((args) => args['motionFramesFx32'] == 0), hasLength(2));
    expect(calls.where((args) => !args.containsKey('motion')), hasLength(2));
    expect(overlay.children.whereType<BattleStage3DComponent>()
        .single.sourcePaletteFilter, isNull);
  });

  test('Charm rotates the attacker and restores its battle pose', () async {
    final overlay = await _scene();
    final bundle = jsonDecode(File(
      '../../tools/avelune_attack_comparator/assets/bw2/batch/charm.json',
    ).readAsStringSync()) as Map<String, dynamic>;
    final program = bundle['program'] as Map<String, dynamic>;
    final emitted = <int>[];
    final finished = overlay.presentExperimentalGen5Attack(
      program: program,
      variant: program['variant'] as String,
      hasEmitter: (particle, emitter) => particle == 374 && emitter == 0,
      startEmitter: (_, _, _) => fail('Source arguments were not preserved'),
      startSourceEmitter: (args) => emitted.add(args['emitter'] as int),
      particlesBusy: () => false,
      detachParticles: () {},
      allowSilentAudio: true,
      allowUnmappedAudioControls: true,
      allowApproximateFlatActors: true,
      adaptSourceCamera: true,
    );
    var minAngle = 0.0;
    var maxAngle = 0.0;
    for (var tick = 0; tick < 500 && overlay.isTurnPresentationActive; tick++) {
      overlay.updateTree(1 / 60);
      final angle = overlay.debugPlayerCombatant!.currentVisualRotation;
      if (angle < minAngle) minAngle = angle;
      if (angle > maxAngle) maxAngle = angle;
      await Future<void>.delayed(Duration.zero);
    }
    expect(await finished, BattleGen5SourcePlaybackStatus.finished);
    expect(minAngle, lessThan(0));
    expect(maxAngle, greaterThan(0));
    expect(overlay.debugPlayerCombatant!.currentVisualRotation, 0);
    expect(emitted, [0]);
  });

  test('workshop batch programs complete in the source scene', () async {
    final overlay = await _scene();
    final root = Directory('../../tools/avelune_attack_comparator');
    final candidateDir = Platform.environment['GEN5_WORKSHOP_CANDIDATES'];
    final index = candidateDir == null
        ? jsonDecode(
            File('${root.path}/assets/bw2/batch/index.json').readAsStringSync(),
          ) as List
        : Directory(candidateDir).listSync().whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .map((file) => {
                  'id': file.uri.pathSegments.last.replaceFirst('.json', ''),
                  'file': file.path,
                })
            .toList();
    expect(index, isNotEmpty);
    final failures = <String>[];
    for (final row in index.cast<Map<String, dynamic>>()) {
      final backgrounds = <int, ui.Image>{};
      final animationFrames = <ui.Image>[];
      final backgroundAnimations =
          <int, ({int background, List<ui.Image> frames, List<int> durations})>{};
      try {
        final bundle = jsonDecode(
          File(row['file'] as String? ?? '${root.path}/${row['bundleAsset']}')
              .readAsStringSync(),
        ) as Map<String, dynamic>;
        for (final entry in (bundle['backgrounds'] as Map? ?? const {}).entries) {
          final codec = await ui.instantiateImageCodec(base64Decode(entry.value as String));
          try {
            backgrounds[int.parse(entry.key as String)] = (await codec.getNextFrame()).image;
          } finally {
            codec.dispose();
          }
        }
        for (final entry in (bundle['backgroundAnimations'] as Map? ?? const {}).entries) {
          final animation = entry.value as Map;
          final frames = <ui.Image>[];
          for (final encoded in animation['frames'] as List) {
            final codec = await ui.instantiateImageCodec(base64Decode(encoded as String));
            try {
              final image = (await codec.getNextFrame()).image;
              frames.add(image);
              animationFrames.add(image);
            } finally {
              codec.dispose();
            }
          }
          backgroundAnimations[int.parse(entry.key as String)] = (
            background: animation['background'] as int,
            frames: frames,
            durations: (animation['durations'] as List).cast<int>(),
          );
        }
        final program = bundle['program'] as Map<String, dynamic>;
        final particle = bundle['particle'] as int?;
        final groups = bundle['particleGroups'] as Map? ??
            (particle == null ? const {} : {'$particle': bundle});
        Map? groupFor(int id) => groups['$id'] as Map?;
        final active = <({int particle, BattleSplStaticPlayback playback})>[];
        final finished = overlay.presentExperimentalGen5Attack(
          program: program,
          variant: program['variant'] as String,
          hasEmitter: (id, emitter) =>
              (groupFor(id)?['sourceEmitterIndices'] as List?)?.contains(emitter) ?? false,
          startEmitter: (_, _, _) => fail('Source arguments were not preserved'),
          startSourceEmitter: (args) {
            final group = groupFor(args['particle'] as int)!;
            final indices = (group['sourceEmitterIndices'] as List).cast<int>();
            final localIndex = indices.indexOf(args['emitter'] as int);
            final json = jsonDecode(jsonEncode(group['definition'])) as Map<String, dynamic>;
            final emitter = (json['emitters'] as List)[localIndex] as Map;
            final orthographic = args.containsKey('offsetX');
            applyGen5SourceEmitterParameters(emitter, args, orthographic: orthographic);
            final definition = BattleSplParticleDefinition.fromExperimentalJson(json);
            final ids = definition.textureIds.toList();
            final result = BattleSplStaticAdmission.prepare(
              definition: definition,
              textureIndices: {for (var i = 0; i < ids.length; i++) ids[i]: i},
              emitters: [BattleSplStaticEmitter(
                emitterIndex: localIndex, startTick: 0,
                position: (x: 0, y: args['offsetY'] as int, z: 0),
              )],
              seed: 0, poolCapacity: 256, maxTicks: 300,
            );
            if (result.failure != null) throw StateError('${result.failure}');
            active.add((particle: args['particle'] as int, playback: result.playback!));
          },
          deleteSourceParticle: (particle) {
            for (final entry in active.toList()) {
              if (entry.particle == particle) {
                entry.playback.cancel();
                active.remove(entry);
              }
            }
          },
          particlesBusy: () => active.isNotEmpty,
          detachParticles: () {
            for (final entry in active) {
              entry.playback.cancel();
            }
            active.clear();
          },
          allowSilentAudio: true,
          sourceBackgrounds: backgrounds,
          sourceBackgroundAnimations: backgroundAnimations,
          allowUnmappedAudioControls: true,
          allowOrthographicEmitters: true,
          allowFieldEmitters: true,
          allowSourceVisibility: true,
          allowApproximateFlatActors: true,
          adaptSourceCamera: true,
        );
        for (var tick = 0; tick < 3600 && overlay.isTurnPresentationActive; tick++) {
          overlay.updateTree(1 / 60);
          for (final entry in active.toList()) {
            final failure = entry.playback.advance();
            if (failure != null) throw StateError('$failure');
            if (entry.playback.isComplete) active.remove(entry);
          }
          await Future<void>.delayed(Duration.zero);
        }
        if (overlay.isTurnPresentationActive) {
          overlay.cancelExperimentalGen5Attack();
          failures.add('${row['id']}: timeout');
        } else if (await finished != BattleGen5SourcePlaybackStatus.finished) {
          failures.add('${row['id']}: failed');
        }
      } on Object catch (error) {
        failures.add('${row['id']}: $error');
        overlay.cancelExperimentalGen5Attack();
      } finally {
        for (final image in backgrounds.values) {
          image.dispose();
        }
        for (final image in animationFrames) {
          image.dispose();
        }
      }
    }
    expect(failures, isEmpty);
  });

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
