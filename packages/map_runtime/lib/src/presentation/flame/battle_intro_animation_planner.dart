import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_overlay_component.dart';

/// La séquence d'entrée en combat — BETA-BAT-016, portée en parité stricte
/// par BETA-BAT-027 (recette du 2026-08-24, vidéo 18-09-39).
///
/// L'oracle est `Transition::Base#transition` et ses trois temps, plus la
/// version RBY de chacun (`100 RBYWild.rb` / `100 RBYTrainer.rb`) :
///
/// 1. `create_sprite_move_animation` (0,8 s) — l'adversaire entre par son
///    bord. Dans un combat SAUVAGE c'est le Pokémon ; dans un combat de
///    DRESSEUR c'est le dresseur, son Pokémon restant caché (`enemy_sprites`
///    pose `zoom = 0` dessus).
/// 2. `show_appearing_message` — « Un X sauvage apparaît ! » ou
///    « [Dresseur] te défie ! ». Le message vient AVANT les envois : c'est
///    l'ordre de la référence, et l'écart le plus visible de notre ancienne
///    version qui les groupait tous à la fin.
/// 3. `start_enemy_send_animation` — dresseur uniquement : il quitte l'écran
///    par la droite (0,8 s) en lançant sa Ball, PUIS son Pokémon apparaît, et
///    le message « [Dresseur] envoie Y ! » l'accompagne.
/// 4. `start_actor_send_animation` — la Ball du joueur est lancée en arc, son
///    Pokémon grandit, et « Vas-y, Z ! » l'accompagne.
///
/// Chaque brique a son repli : sans planche de Ball chargeable on retombe sur
/// le glissement historique, et sans image de dresseur le Pokémon adverse
/// glisse comme un sauvage. L'intro ne casse jamais.
BattleAnimationPlan buildBattleIntroAnimationPlan({
  required BattleSession session,
  required double slideDistancePx,
  BattleSpeciesDisplayNameResolver? resolveSpeciesDisplayName,
  double revealSeconds = 0.25,
  double slideSeconds = 0.8,
  String? playerBallSheetName,
  String? enemyBallSheetName,
  bool hasEnemyTrainerSprite = false,
}) {
  final openingLines = resolveSpeciesDisplayName == null
      ? buildBattleOpeningNarrationLinesForOverlay(session)
      : buildBattleOpeningNarrationLinesForOverlay(
          session,
          resolveSpeciesDisplayName: resolveSpeciesDisplayName,
        );
  // Les lignes de la référence, dans l'ordre : l'annonce, l'envoi adverse
  // (dresseur seulement), l'envoi du joueur. Lire par position serait
  // fragile ; on prend la première et la dernière, et l'intermédiaire quand
  // elle existe.
  final appearingMessage = openingLines.isEmpty ? null : openingLines.first;
  final playerSendMessage =
      openingLines.length < 2 ? null : openingLines.last;
  final enemySendMessage =
      openingLines.length < 3 ? null : openingLines[openingLines.length - 2];

  final steps = <BattleAnimationStep>[
    WaitStep(durationSeconds: revealSeconds),
  ];

  // 1. L'entrée de l'adversaire.
  final enemyEntersAsTrainer = enemyBallSheetName != null;
  if (enemyEntersAsTrainer && hasEnemyTrainerSprite) {
    steps.add(
      EnemyTrainerIntroStep(
        motion: BattleIntroTrainerMotionKind.enter,
        durationSeconds: slideSeconds,
      ),
    );
  } else if (!enemyEntersAsTrainer) {
    steps.add(
      CombatantMotionStep(
        side: BattleSideId.enemy,
        motionKind: BattleCombatantMotionKind.introSlide,
        durationSeconds: slideSeconds,
        distancePx: slideDistancePx,
      ),
    );
    // Parité `cries_animations` : le sauvage crie quand sa silhouette se
    // révèle, à la fin de son glissement.
    steps.add(
      PlayCryStep(speciesId: session.state.enemy.speciesId),
    );
  }
  // Repli d'un combat de dresseur SANS image : rien n'entre, le Pokémon
  // apparaîtra à son envoi — la durée du glissement est laissée au message.

  // 2. L'annonce, puis l'entrée des barres d'info — parité
  // `show_appearing_message` suivi de `show_team_info` dans le même temps de
  // la référence (BETA-BAT-028 : elles n'étaient pas censées être à l'écran
  // au lever du rideau).
  if (appearingMessage != null) {
    steps.add(ShowMessageStep(message: appearingMessage));
  }
  steps.add(const ShowTeamInfoStep());

  // 3. L'envoi de l'adversaire — dresseur uniquement. Son MESSAGE existe dès
  // que la session est un combat de dresseur (trois lignes d'ouverture) ; les
  // mouvements, eux, dépendent des assets disponibles. Les conditionner
  // ensemble faisait disparaître « X envoie Y ! » quand la planche de Ball
  // manquait.
  if (enemySendMessage != null) {
    if (enemyEntersAsTrainer) {
      if (hasEnemyTrainerSprite) {
        steps.add(
          EnemyTrainerIntroStep(
            motion: BattleIntroTrainerMotionKind.exit,
            durationSeconds: slideSeconds,
          ),
        );
      }
      steps.add(
        PlayBallSequenceStep(
          side: BattleSideId.enemy,
          kind: BattleBallSequenceKind.sendOutHeld,
          sheetName: enemyBallSheetName,
        ),
      );
      steps.add(
        const CombatantMotionStep(
          side: BattleSideId.enemy,
          motionKind: BattleCombatantMotionKind.materializeIn,
          durationSeconds: 0.1,
        ),
      );
      // Parité `regular_go_in_animation` : tout Pokémon qui sort de sa Ball
      // crie.
      steps.add(PlayCryStep(speciesId: session.state.enemy.speciesId));
    }
    steps.add(ShowMessageStep(message: enemySendMessage));
  }

  // 4. L'envoi du joueur.
  if (playerBallSheetName != null) {
    steps.add(
      PlayBallSequenceStep(
        side: BattleSideId.player,
        kind: BattleBallSequenceKind.sendOutThrown,
        sheetName: playerBallSheetName,
      ),
    );
    steps.add(
      const CombatantMotionStep(
        side: BattleSideId.player,
        motionKind: BattleCombatantMotionKind.materializeIn,
        durationSeconds: 0.1,
      ),
    );
    steps.add(PlayCryStep(speciesId: session.state.player.speciesId));
  } else {
    steps.add(
      CombatantMotionStep(
        side: BattleSideId.player,
        motionKind: BattleCombatantMotionKind.introSlide,
        durationSeconds: slideSeconds,
        distancePx: slideDistancePx,
      ),
    );
  }
  if (playerSendMessage != null) {
    steps.add(ShowMessageStep(message: playerSendMessage));
  }

  return BattleAnimationPlan(
    steps: List<BattleAnimationStep>.unmodifiable(steps),
  );
}
