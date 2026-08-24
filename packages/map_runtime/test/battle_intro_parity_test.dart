import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_intro_animation_planner.dart';
import 'package:map_runtime/src/presentation/flame/battle_intro_trainer_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';

// BETA-BAT-027 — recette du 2026-08-24 (vidéo 18-09-39) : « les deux pokémons
// sont déjà présents, PUIS il y a l'animation » et « lorsque l'on est face à
// un dresseur, lui aussi lance une pokéball face à nous ».
//
// L'oracle est Transition::Base#transition et ses trois temps (100 RBYWild.rb
// / 100 RBYTrainer.rb) : l'adversaire entre, l'annonce tombe, l'adversaire
// envoie (dresseur : il sort du champ en lançant), le joueur envoie.

BattleSession _session({required bool isTrainerBattle}) {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'grenousse',
        level: 5,
        maxHp: 17,
        currentHp: 17,
        stats: BattleStatsSnapshot(
          attack: 10,
          defense: 10,
          specialAttack: 10,
          specialDefense: 10,
          speed: 90,
        ),
        moves: <BattleMoveData>[
          BattleMoveData(id: 'a', name: 'A', power: 20),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'pikachu',
        level: 4,
        maxHp: 19,
        currentHp: 19,
        stats: BattleStatsSnapshot(
          attack: 10,
          defense: 10,
          specialAttack: 10,
          specialDefense: 10,
          speed: 10,
        ),
        moves: <BattleMoveData>[
          BattleMoveData(id: 'b', name: 'B', power: 20),
        ],
      ),
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'pierre' : null,
    ),
  );
}

Future<ui.Image> _fakeTrainerImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 64, 64),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  return recorder.endRecording().toImage(64, 64);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('le plan d’intro suit l’ordre de la référence', () {
    List<String> messagesOf(BattleAnimationPlan plan) => <String>[
          for (final step in plan.steps)
            if (step is ShowMessageStep) step.message,
        ];

    test(
        'combat sauvage : l’adversaire entre, PUIS l’annonce, PUIS la Ball du '
        'joueur, PUIS « Vas-y »', () {
      final plan = buildBattleIntroAnimationPlan(
        session: _session(isTrainerBattle: false),
        slideDistancePx: 1080,
        playerBallSheetName: 'ball_1',
      );
      final steps = plan.steps;

      final slideIndex = steps.indexWhere(
        (step) =>
            step is CombatantMotionStep &&
            step.side == BattleSideId.enemy &&
            step.motionKind == BattleCombatantMotionKind.introSlide,
      );
      final appearingIndex = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('apparaît'),
      );
      final ballIndex = steps.indexWhere(
        (step) =>
            step is PlayBallSequenceStep && step.side == BattleSideId.player,
      );
      final sendIndex = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('Vas-y'),
      );

      expect(slideIndex, greaterThanOrEqualTo(0));
      expect(
        appearingIndex,
        greaterThan(slideIndex),
        reason: 'la référence annonce APRÈS le glissement',
      );
      expect(
        ballIndex,
        greaterThan(appearingIndex),
        reason: 'l’envoi du joueur vient APRÈS l’annonce — les messages '
            'n’étaient plus tous groupés à la fin',
      );
      expect(sendIndex, greaterThan(ballIndex));
    });

    test(
        'combat de dresseur : il entre, défie, SORT en lançant sa Ball, son '
        'Pokémon apparaît, puis le joueur envoie', () {
      final plan = buildBattleIntroAnimationPlan(
        session: _session(isTrainerBattle: true),
        slideDistancePx: 1080,
        playerBallSheetName: 'ball_1',
        enemyBallSheetName: 'ball_1',
        hasEnemyTrainerSprite: true,
      );
      final steps = plan.steps;

      final enterIndex = steps.indexWhere(
        (step) =>
            step is EnemyTrainerIntroStep &&
            step.motion == BattleIntroTrainerMotionKind.enter,
      );
      final challengeIndex = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('défie'),
      );
      final exitIndex = steps.indexWhere(
        (step) =>
            step is EnemyTrainerIntroStep &&
            step.motion == BattleIntroTrainerMotionKind.exit,
      );
      final enemyBallIndex = steps.indexWhere(
        (step) =>
            step is PlayBallSequenceStep && step.side == BattleSideId.enemy,
      );
      final enemySendIndex = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('envoie'),
      );
      final playerBallIndex = steps.indexWhere(
        (step) =>
            step is PlayBallSequenceStep && step.side == BattleSideId.player,
      );

      expect(enterIndex, greaterThanOrEqualTo(0),
          reason: 'c’est le DRESSEUR qui entre, pas son Pokémon');
      expect(challengeIndex, greaterThan(enterIndex));
      expect(exitIndex, greaterThan(challengeIndex),
          reason: 'parité create_enemy_send_animation : il sort du champ');
      expect(enemyBallIndex, greaterThan(exitIndex),
          reason: 'sa Ball part quand il quitte l’écran');
      expect(enemySendIndex, greaterThan(enemyBallIndex));
      expect(playerBallIndex, greaterThan(enemySendIndex),
          reason: 'le joueur envoie en dernier');
      expect(
        steps.whereType<CombatantMotionStep>().where(
              (step) =>
                  step.side == BattleSideId.enemy &&
                  step.motionKind == BattleCombatantMotionKind.introSlide,
            ),
        isEmpty,
        reason: 'le Pokémon adverse ne glisse pas : il sort de sa Ball',
      );
      // Sans résolveur injecté, les noms restent les identifiants — c'est le
      // défaut documenté du planner ; l'hôte en fournit un.
      expect(
        messagesOf(plan),
        containsAllInOrder(<String>[
          'Le Dresseur pierre te défie !',
          'Le Dresseur pierre envoie pikachu !',
          'Vas-y, grenousse !',
        ]),
      );
    });

    test('sans planche de Ball, le glissement historique des deux camps tient',
        () {
      final plan = buildBattleIntroAnimationPlan(
        session: _session(isTrainerBattle: false),
        slideDistancePx: 1080,
      );

      expect(
        plan.steps.whereType<CombatantMotionStep>().map((step) => step.side),
        containsAll(<BattleSideId>[BattleSideId.enemy, BattleSideId.player]),
      );
      expect(plan.steps.whereType<PlayBallSequenceStep>(), isEmpty);
    });

    test('dresseur sans image : la Ball adverse joue quand même', () {
      final plan = buildBattleIntroAnimationPlan(
        session: _session(isTrainerBattle: true),
        slideDistancePx: 1080,
        playerBallSheetName: 'ball_1',
        enemyBallSheetName: 'ball_1',
      );

      expect(plan.steps.whereType<EnemyTrainerIntroStep>(), isEmpty);
      expect(
        plan.steps.whereType<PlayBallSequenceStep>().map((step) => step.side),
        containsAll(<BattleSideId>[BattleSideId.enemy, BattleSideId.player]),
        reason: 'le repli garde les deux envois, sans le sprite',
      );
    });
  });

  group('les poses d’entrée survivent au montage', () {
    Future<BattleOverlayComponent> mount({
      required bool isTrainerBattle,
      ui.Image? trainerImage,
    }) async {
      final overlay = BattleOverlayComponent(
        session: _session(isTrainerBattle: isTrainerBattle),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        introEnabled: true,
      );
      if (trainerImage != null) {
        overlay.prepareIntroTrainerVisual(trainerImage);
      }
      await overlay.onLoad();
      await overlay.waitForPendingVisualSync();
      return overlay;
    }

    test(
        'recette 2026-08-24 : au lever du rideau, AUCUN combattant n’est à sa '
        'place', () async {
      final overlay = await mount(isTrainerBattle: false);

      expect(
        overlay.debugPlayerSpriteScaleX,
        0.0,
        reason: 'le joueur sort de sa Ball : il attend caché (parité '
            'actor_sprites, qui pose zoom = 0)',
      );
      expect(
        overlay.debugEnemySpriteOffset!.dx,
        lessThan(-100),
        reason: 'le sauvage attend hors champ avant de glisser',
      );
    });

    test('le dresseur adverse attend hors champ et son Pokémon reste caché',
        () async {
      final overlay = await mount(
        isTrainerBattle: true,
        trainerImage: await _fakeTrainerImage(),
      );

      expect(
        overlay.debugEnemySpriteScaleX,
        0.0,
        reason: 'parité enemy_sprites : le Pokémon adverse attend dans sa '
            'Ball, c’est le dresseur qu’on voit',
      );
      final trainer = overlay.debugIntroTrainerSprite;
      expect(trainer, isNotNull, reason: 'le sprite du dresseur est monté');
      expect(trainer!.debugOffsetX, lessThan(-100));
    });

    test(
        'recette 2026-08-24 : pendant l’intro, la boîte ne pose PAS la '
        'question du menu', () async {
      // La vidéo montrait « Que doit faire Grenousse ? » AVANT les messages
      // d'ouverture : le menu semblait ouvert alors que la scène entrait.
      final snapshots = <BattleCommandOverlaySnapshot?>[];
      final overlay = BattleOverlayComponent(
        session: _session(isTrainerBattle: false),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        introEnabled: true,
        onCommandOverlaySnapshotChanged: snapshots.add,
      );
      await overlay.onLoad();
      await overlay.waitForPendingVisualSync();
      overlay.setUseFlutterCommandOverlay(true);

      overlay.startIntro();
      // Le premier temps du plan est l'attente du fondu : le runner joue,
      // sans message à dire.
      overlay.updateTree(0.05);
      await Future<void>.delayed(Duration.zero);

      final published = snapshots.whereType<BattleCommandOverlaySnapshot>();
      expect(published, isNotEmpty, reason: 'un snapshot a été publié');
      expect(
        published.map((snapshot) => snapshot.prompt).where(
              (prompt) => prompt.contains('Que doit faire'),
            ),
        isEmpty,
        reason: 'une animation qui joue sans message ne pose aucune question',
      );
    });

    test(
        'BETA-BAT-028 : les barres d’info n’entrent qu’APRÈS l’annonce',
        () async {
      // Parité `show_team_info` : la référence les fait glisser dans le même
      // temps que le message d'apparition, pas au lever du rideau.
      final snapshots = <BattleCommandOverlaySnapshot?>[];
      final overlay = BattleOverlayComponent(
        session: _session(isTrainerBattle: false),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        introEnabled: true,
        onCommandOverlaySnapshotChanged: snapshots.add,
      );
      await overlay.onLoad();
      await overlay.waitForPendingVisualSync();
      overlay.setUseFlutterCommandOverlay(true);
      overlay.startIntro();

      var sawHidden = false;
      var sawRevealed = false;
      for (var i = 0; i < 120 && overlay.isTurnPresentationActive; i++) {
        overlay.updateTree(0.05);
        await Future<void>.delayed(Duration.zero);
        final last = snapshots.whereType<BattleCommandOverlaySnapshot>().isEmpty
            ? null
            : snapshots.whereType<BattleCommandOverlaySnapshot>().last;
        if (last == null) continue;
        if (!last.enemyHud.isRevealed) {
          sawHidden = true;
        } else if (sawHidden) {
          sawRevealed = true;
          break;
        }
      }

      expect(
        sawHidden,
        isTrue,
        reason: 'au lever du rideau, les barres ne sont pas encore là',
      );
      expect(
        sawRevealed,
        isTrue,
        reason: 'le step ShowTeamInfo les fait entrer pendant l’intro',
      );
    });

    test(
        'BETA-BAT-028 : le sauvage entre en silhouette noire et se révèle à '
        'la fin de son glissement', () async {
      final overlay = await mount(isTrainerBattle: false);
      final enemy = overlay.debugEnemyCombatant!;

      expect(
        enemy.debugIntroSilhouetteActive,
        isTrue,
        reason: 'parité create_enemy_sprites : il entre en noir',
      );
      expect(enemy.currentVisualToneColor, const Color(0xFF000000));

      await enemy.playIntroSlide(durationSeconds: 0.8, distancePx: 1080);
      for (var i = 0; i < 10; i++) {
        enemy.update(0.05);
      }
      expect(
        enemy.debugIntroSilhouetteActive,
        isTrue,
        reason: 'elle TIENT pendant le glissement, elle ne s’estompe pas',
      );
      expect(enemy.currentVisualToneColor, const Color(0xFF000000));

      for (var i = 0; i < 12; i++) {
        enemy.update(0.05);
      }
      expect(
        enemy.debugIntroSilhouetteActive,
        isFalse,
        reason: 'parité enemy_discover_animations : révélation d’un coup à '
            'la fin du mouvement',
      );
      expect(enemy.currentVisualToneColor, isNull);
    });

    test('le dresseur entre, puis sort du champ et se retire', () async {
      final overlay = await mount(
        isTrainerBattle: true,
        trainerImage: await _fakeTrainerImage(),
      );
      final trainer = overlay.debugIntroTrainerSprite!;

      trainer.play(
        motion: BattleIntroTrainerMotion.enter,
        durationSeconds: 0.8,
      );
      for (var i = 0; i < 20; i++) {
        trainer.update(0.05);
      }
      expect(
        trainer.debugOffsetX,
        closeTo(0, 1e-6),
        reason: 'l’entrée le pose à la place de son Pokémon',
      );

      trainer.play(
        motion: BattleIntroTrainerMotion.exit,
        durationSeconds: 0.8,
      );
      for (var i = 0; i < 20; i++) {
        trainer.update(0.05);
      }
      expect(
        trainer.debugOffsetX,
        greaterThan(100),
        reason: 'il quitte l’écran par son bord en lançant sa Ball',
      );
      expect(trainer.isMotionComplete, isTrue);
    });
  });
}
