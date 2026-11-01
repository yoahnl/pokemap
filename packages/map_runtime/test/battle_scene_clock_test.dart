import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

import 'support/load_flame_component.dart';

final class _ClockProbe extends Component {
  int updates = 0;
  double seconds = 0;
  void Function()? onFirstUpdate;
  void Function(int updateIndex)? onUpdate;

  @override
  void update(double dt) {
    updates += 1;
    seconds += dt;
    onUpdate?.call(updates);
    if (updates == 1) onFirstUpdate?.call();
  }
}

Future<(BattleOverlayComponent, _ClockProbe)> _scene({
  void Function(String name)? sound,
  void Function() Function(StartTrackedEffectStep, void Function())? startTrackedEffect,
}) async {
  const stats = BattleStatsSnapshot(
    attack: 20, defense: 20, specialAttack: 20,
    specialDefense: 20, speed: 20,
  );
  const pokemon = BattleCombatantData(
    speciesId: 'totodile', level: 7, maxHp: 25, currentHp: 25,
    stats: stats, moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
  );
  final overlay = BattleOverlayComponent(
    session: createBattleSession(BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: pokemon, enemyPokemon: pokemon,
      isTrainerBattle: false, trainerId: null,
    )),
    viewportSize: Vector2(390, 844),
    onPlayerChoice: (_) {},
    playSfx: (name, {volume = 100, pitch = 100}) => sound?.call(name),
    onStartTrackedEffect: startTrackedEffect,
  );
  final probe = _ClockProbe();
  overlay.add(probe);
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  addTearDown(overlay.onRemove);
  return (overlay, probe);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tracked effect completion cannot advance the next step during the same child tick', () async {
    late void Function() complete;
    late _ClockProbe probe;
    double? completedAt;
    double? playedAt;
    final scene = await _scene(
      startTrackedEffect: (_, done) { complete = done; return () {}; },
      sound: (_) => playedAt = probe.seconds,
    );
    final overlay = scene.$1;
    probe = scene.$2;
    probe.onUpdate = (index) {
      if (index == 2) {
        completedAt = probe.seconds;
        complete();
      }
    };
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      StartTrackedEffectStep(effectId: 'synthetic'),
      WaitTrackedEffectsStep(),
      WaitStep(durationSeconds: .05),
      PlaySeStep(seName: 'done'),
    ]));
    overlay.updateTree(.15);
    expect(completedAt, isNotNull);
    expect(playedAt, isNotNull);
    expect(playedAt! - completedAt!, greaterThanOrEqualTo(.05 - .000001));
    expect(playedAt! - completedAt!, lessThanOrEqualTo(.05 + 1 / 60 + .000001));
  });

  test('a delayed frame bounds child work and retains the whole elapsed time', () async {
    final (overlay, probe) = await _scene();
    overlay.updateTree(5);
    expect(probe.updates, inInclusiveRange(1, 32));
    for (var frame = 0; frame < 12; frame++) {
      overlay.updateTree(0);
    }
    expect(probe.seconds, closeTo(5, .000001));
  });

  test('instantaneous dispatch is bounded across all overlay substeps', () async {
    final sounds = <String>[];
    final (overlay, probe) = await _scene(sound: sounds.add);
    overlay.presentPostBattlePlan(BattleAnimationPlan(steps: [
      const WaitStep(durationSeconds: .01),
      for (var index = 0; index < 1024; index++) PlaySeStep(seName: 'cue_$index'),
      const WaitStep(durationSeconds: .1),
    ]));
    var previousCount = 0;
    overlay.updateTree(.3);
    var count = sounds.length;
    expect(count - previousCount, inInclusiveRange(1, 256));
    expect(overlay.isTurnPresentationActive, isTrue);
    for (var frame = 0; frame < 30 && overlay.isTurnPresentationActive; frame++) {
      previousCount = count;
      final before = probe.seconds;
      overlay.updateTree(0);
      count = sounds.length;
      expect(count - previousCount, lessThanOrEqualTo(256));
      if (count - previousCount == 256) expect(probe.seconds, before);
    }
    expect(sounds, [for (var index = 0; index < 1024; index++) 'cue_$index']);
    expect(overlay.isTurnPresentationActive, isFalse);
    expect(probe.seconds, closeTo(.3, .000001));
  });

  test('replacement from a child shares the frame dispatch budget', () async {
    final sounds = <String>[];
    final (overlay, probe) = await _scene(sound: sounds.add);
    overlay.presentPostBattlePlan(BattleAnimationPlan(steps: [
      const WaitStep(durationSeconds: .01),
      for (var index = 0; index < 200; index++) PlaySeStep(seName: 'old_$index'),
      const WaitStep(durationSeconds: .1),
    ]));
    probe.onUpdate = (index) {
      if (index != 2) return;
      overlay.presentPostBattlePlan(BattleAnimationPlan(steps: [
        for (var index = 0; index < 1024; index++) PlaySeStep(seName: 'new_$index'),
        const WaitStep(durationSeconds: .1),
      ]));
    };
    overlay.updateTree(.3);
    expect(sounds.length, inInclusiveRange(201, 256));
    for (var frame = 0; frame < 8; frame++) overlay.updateTree(0);
    expect(sounds, [
      for (var index = 0; index < 200; index++) 'old_$index',
      for (var index = 0; index < 1024; index++) 'new_$index',
    ]);
    expect(overlay.isTurnPresentationActive, isTrue);
    overlay.updateTree(.1);
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test('catch-up preserves presentation events and completes the plan once', () async {
    final (overlay, probe) = await _scene();
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      WaitStep(durationSeconds: .6),
      HudLevelUpStep(),
      WaitStep(durationSeconds: .6),
      HudLevelUpStep(),
      WaitStep(durationSeconds: .6),
    ]));
    overlay.updateTree(2);
    expect(overlay.isTurnPresentationActive, isTrue);
    expect(probe.updates, lessThanOrEqualTo(32));
    for (var frame = 0; frame < 6; frame++) {
      overlay.updateTree(0);
    }
    expect(overlay.isTurnPresentationActive, isFalse);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 9);
    expect(probe.seconds, closeTo(2, .000001));
    overlay.updateTree(0);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 9);
  });

  test('non-finite and negative deltas are rejected without poisoning the clock', () async {
    final (overlay, probe) = await _scene();
    for (final dt in [double.infinity, double.negativeInfinity, double.nan, -1.0]) {
      overlay.updateTree(dt);
    }
    expect(probe.updates, 0);
    overlay.updateTree(.1);
    expect(probe.seconds, closeTo(.1, .000001));
  });

  test('replacing a plan clears backlog from the previous presentation', () async {
    final (overlay, _) = await _scene();
    overlay.updateTree(5);
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      WaitStep(durationSeconds: .6), HudLevelUpStep(),
    ]));
    overlay.updateTree(0);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 7);
    overlay.updateTree(.3);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 7);
    overlay.updateTree(.31);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 8);
  });

  test('a replacement inside a child tick invalidates the old frame backlog', () async {
    final (overlay, probe) = await _scene();
    probe.onFirstUpdate = () => overlay.presentPostBattlePlan(
      const BattleAnimationPlan(steps: [
        WaitStep(durationSeconds: .6), HudLevelUpStep(),
      ]),
    );
    overlay.updateTree(5);
    expect(probe.updates, 1);
    overlay.updateTree(0);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 7);
    overlay.updateTree(.31);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 7);
    overlay.updateTree(.31);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.level, 8);
  });

  test('cancelling state presentation discards its backlog', () async {
    final (overlay, probe) = await _scene();
    overlay.updateTree(5);
    final secondsBeforeCancel = probe.seconds;
    overlay.updateState(overlay.debugSession);
    await overlay.waitForPendingVisualSync();
    overlay.updateTree(0);
    expect(probe.seconds, secondsBeforeCancel);
    overlay.updateTree(.1);
    expect(probe.seconds, closeTo(secondsBeforeCancel + .1, .000001));
  });

  test('removal inside a child tick stops the frame and later debt draining', () async {
    final (overlay, probe) = await _scene();
    probe.onFirstUpdate = overlay.onRemove;
    overlay.updateTree(5);
    expect(probe.updates, 1);
    overlay.updateTree(0);
    overlay.updateTree(1);
    expect(probe.updates, 1);
  });
}
