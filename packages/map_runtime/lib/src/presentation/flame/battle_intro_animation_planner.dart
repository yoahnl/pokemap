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
}) {
  final openingLines = resolveSpeciesDisplayName == null
      ? buildBattleOpeningNarrationLinesForOverlay(session)
      : buildBattleOpeningNarrationLinesForOverlay(
          session,
          resolveSpeciesDisplayName: resolveSpeciesDisplayName,
        );
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
