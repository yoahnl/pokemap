import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_overlay_component.dart';

/// La séquence d'entrée en combat — BETA-BAT-016.
///
/// Projection du `transition` de la référence, après le fondu du noir :
/// glissement des combattants vers leurs positions (0,8 s en parallèle,
/// parité `create_sprite_move_animation`), puis les messages d'ouverture,
/// un par un. Les textes viennent de la même source que la narration
/// d'ouverture, donc un combat de dresseur porte sa séquence d'envoi
/// (« X envoie Y ! ») et un combat sauvage n'en a pas — la parité
/// `wait(0)` de la référence tombe naturellement du nombre de lignes.
///
/// Le plan commence par une attente couvrant le fondu du noir joué par la
/// pré-transition : le glissement ne démarre qu'écran révélé, comme la
/// référence enchaîne `create_fade_out_animation` PUIS le mouvement.
BattleAnimationPlan buildBattleIntroAnimationPlan({
  required BattleSession session,
  required double slideDistancePx,
  BattleSpeciesDisplayNameResolver? resolveSpeciesDisplayName,
  double revealSeconds = 0.25,
  double slideSeconds = 0.8,
  String? playerBallSheetName,
}) {
  final openingLines = resolveSpeciesDisplayName == null
      ? buildBattleOpeningNarrationLinesForOverlay(session)
      : buildBattleOpeningNarrationLinesForOverlay(
          session,
          resolveSpeciesDisplayName: resolveSpeciesDisplayName,
        );
  // BETA-BAT-022 : quand la planche de Ball est chargeable, le joueur SORT
  // de sa Poké Ball — l'adversaire glisse d'abord (0,8 s), puis la Ball vole
  // et s'ouvre (0,6 s), puis le Pokémon grandit (0,1 s) — la parité
  // séquentielle de la référence (`create_sprite_move_animation` PUIS
  // `create_player_send_animation`). Sans planche : le glissement
  // historique des deux camps, en parallèle.
  if (playerBallSheetName != null) {
    return BattleAnimationPlan(
      steps: <BattleAnimationStep>[
        WaitStep(durationSeconds: revealSeconds),
        CombatantMotionStep(
          side: BattleSideId.enemy,
          motionKind: BattleCombatantMotionKind.introSlide,
          durationSeconds: slideSeconds,
          distancePx: slideDistancePx,
        ),
        PlayBallSequenceStep(
          side: BattleSideId.player,
          kind: BattleBallSequenceKind.sendOutThrown,
          sheetName: playerBallSheetName,
        ),
        const CombatantMotionStep(
          side: BattleSideId.player,
          motionKind: BattleCombatantMotionKind.materializeIn,
          durationSeconds: 0.1,
        ),
        for (final line in openingLines) ShowMessageStep(message: line),
      ],
    );
  }
  return BattleAnimationPlan(
    steps: <BattleAnimationStep>[
      WaitStep(durationSeconds: revealSeconds),
      AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: <BattleAnimationStep>[
          CombatantMotionStep(
            side: BattleSideId.enemy,
            motionKind: BattleCombatantMotionKind.introSlide,
            durationSeconds: slideSeconds,
            distancePx: slideDistancePx,
          ),
          CombatantMotionStep(
            side: BattleSideId.player,
            motionKind: BattleCombatantMotionKind.introSlide,
            durationSeconds: slideSeconds,
            distancePx: slideDistancePx,
          ),
        ],
      ),
      for (final line in openingLines) ShowMessageStep(message: line),
    ],
  );
}
