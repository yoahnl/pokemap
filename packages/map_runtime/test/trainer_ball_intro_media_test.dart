import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_intro_animation_planner.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

import 'support/load_flame_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trainer portrait and send-out do not depend on a Ball sheet', () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(trainer: true),
      slideDistancePx: 720,
      hasEnemyTrainerSprite: true,
    );
    final steps = plan.steps;
    final enter = steps.indexWhere(
      (step) =>
          step is EnemyTrainerIntroStep &&
          step.motion == BattleIntroTrainerMotionKind.enter,
    );
    final challenge = steps.indexWhere(
      (step) => step is ShowMessageStep && step.message.contains('défie'),
    );
    final exit = steps.indexWhere(
      (step) =>
          step is EnemyTrainerIntroStep &&
          step.motion == BattleIntroTrainerMotionKind.exit,
    );
    final appearance = steps.indexWhere(
      (step) =>
          step is CombatantMotionStep &&
          step.side == BattleSideId.enemy &&
          step.motionKind == BattleCombatantMotionKind.materializeIn,
    );
    expect(enter, greaterThanOrEqualTo(0));
    expect(challenge, greaterThan(enter));
    expect(exit, greaterThan(challenge));
    expect(appearance, greaterThan(exit));
    expect(steps.whereType<PlayBallSequenceStep>(), isEmpty);
    expect(
      steps.whereType<PlayCryStep>().where((step) => step.speciesId == 'enemy'),
      hasLength(1),
    );
  });

  test(
    'trainer without either image still sends its Pokemon after challenge',
    () {
      final steps = buildBattleIntroAnimationPlan(
        session: _session(trainer: true),
        slideDistancePx: 720,
      ).steps;
      final challenge = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('défie'),
      );
      final appearance = steps.indexWhere(
        (step) =>
            step is CombatantMotionStep &&
            step.side == BattleSideId.enemy &&
            step.motionKind == BattleCombatantMotionKind.materializeIn,
      );
      expect(steps.whereType<EnemyTrainerIntroStep>(), isEmpty);
      expect(appearance, greaterThan(challenge));
      expect(
        steps.whereType<CombatantMotionStep>().where(
          (step) =>
              step.side == BattleSideId.enemy &&
              step.motionKind == BattleCombatantMotionKind.introSlide,
        ),
        isEmpty,
      );
    },
  );

  test('wild entry ignores a supplied enemy Ball and trainer image flag', () {
    final steps = buildBattleIntroAnimationPlan(
      session: _session(trainer: false),
      slideDistancePx: 720,
      enemyBallItemId: 'project-orb',
      hasEnemyTrainerSprite: true,
    ).steps;
    expect(steps.whereType<EnemyTrainerIntroStep>(), isEmpty);
    expect(
      steps.whereType<PlayBallSequenceStep>().where(
        (step) => step.side == BattleSideId.enemy,
      ),
      isEmpty,
    );
    expect(
      steps.whereType<CombatantMotionStep>().where(
        (step) =>
            step.side == BattleSideId.enemy &&
            step.motionKind == BattleCombatantMotionKind.introSlide,
      ),
      hasLength(1),
    );
  });

  for (final media in ['absent', 'missing', 'corrupt']) {
    test(
      'mounted trainer keeps its portrait when Ball media is $media',
      () async {
        final directory = await Directory.systemTemp.createTemp('l16-intro-');
        addTearDown(() => directory.delete(recursive: true));
        final corrupt = File('${directory.path}/corrupt.png');
        await corrupt.writeAsBytes([1, 2, 3]);
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder)
            .drawColor(const ui.Color(0xff55aa88), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final trainerImage = await picture.toImage(48, 64);
        picture.dispose();
        final overlay =
            BattleOverlayComponent(
              session: _session(trainer: true),
              viewportSize: Vector2(640, 480),
              introEnabled: true,
              onPlayerChoice: (_) {},
        resolveCombatantBallItemId: (_, _) => 'project-orb',
              resolveBallSpritePath: (_) async => switch (media) {
                'absent' => null,
                'missing' => '${directory.path}/missing.png',
                _ => corrupt.path,
              },
            )..prepareIntroTrainerVisual(
              trainerImage,
              onRelease: trainerImage.dispose,
            );
        addTearDown(overlay.onRemove);
        await loadFlameComponent(overlay);
        await overlay.waitForPendingVisualSync();
        expect(overlay.debugIntroTrainerSprite, isNotNull);
        expect(overlay.debugEnemySpriteOpacity, 0);
        overlay.startIntro();
        for (
          var tick = 0;
          tick < 300 && overlay.isTurnPresentationActive;
          tick++
        ) {
          overlay.updateTree(0.1);
          await Future<void>.delayed(Duration.zero);
        }
        expect(overlay.isTurnPresentationActive, isFalse);
        expect(overlay.debugEnemySpriteOpacity, 1);
      },
    );
  }
}

BattleSession _session({required bool trainer}) => createBattleSession(
  BattleSetup.pokeMapBetaV1ForTest(
    playerPokemon: _combatant('player'),
    enemyPokemon: _combatant('enemy'),
    isTrainerBattle: trainer,
    trainerId: trainer ? 'project-trainer' : null,
  ),
);

BattleCombatantData _combatant(String id) => BattleCombatantData(
  speciesId: id,
  level: 5,
  maxHp: 20,
  currentHp: 20,
  stats: const BattleStatsSnapshot(
    attack: 10,
    defense: 10,
    specialAttack: 10,
    specialDefense: 10,
    speed: 10,
  ),
  moves: const [BattleMoveData(id: 'move', name: 'Move', power: 20)],
);
