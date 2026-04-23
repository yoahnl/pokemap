import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';

class BattleTurnPresentationStep {
  const BattleTurnPresentationStep({
    required this.message,
    this.flashTargetSide,
    this.hpChangeTargetSide,
    this.hpFrom,
    this.hpTo,
  });

  final String message;
  final BattleSideId? flashTargetSide;
  final BattleSideId? hpChangeTargetSide;
  final int? hpFrom;
  final int? hpTo;

  bool get animatesHpChange =>
      hpChangeTargetSide != null && hpFrom != null && hpTo != null;

  bool get animatesDamage => flashTargetSide != null && animatesHpChange;
}

List<BattleTurnPresentationStep> buildLegacyPresentationStepsFromAnimationPlan(
  BattleAnimationPlan plan,
) {
  final steps = <BattleTurnPresentationStep>[];

  for (final step in plan.steps) {
    switch (step) {
      case ShowMessageStep(:final message):
        steps.add(BattleTurnPresentationStep(message: message));
      case CombatantFlashStep(:final side):
        if (steps.isEmpty) {
          continue;
        }
        final previous = steps.removeLast();
        steps.add(
          BattleTurnPresentationStep(
            message: previous.message,
            flashTargetSide: previous.flashTargetSide ?? side,
            hpChangeTargetSide: previous.hpChangeTargetSide,
            hpFrom: previous.hpFrom,
            hpTo: previous.hpTo,
          ),
        );
      case HudHpTweenStep(:final side, :final fromHp, :final toHp):
        final previous = steps.isEmpty
            ? const BattleTurnPresentationStep(message: '')
            : steps.removeLast();
        steps.add(
          BattleTurnPresentationStep(
            message: previous.message,
            flashTargetSide: previous.flashTargetSide ?? side,
            hpChangeTargetSide: side,
            hpFrom: fromHp,
            hpTo: toHp,
          ),
        );
      default:
        continue;
    }
  }

  return List<BattleTurnPresentationStep>.unmodifiable(
    steps.where((step) => step.message.isNotEmpty || step.animatesHpChange),
  );
}

List<BattleTurnPresentationStep> buildBattleTurnPresentationSteps({
  required BattleCombatant playerBefore,
  required BattleCombatant enemyBefore,
  required BattleTurnResult turnResult,
}) {
  final trackedHp = <BattleSideId, int>{
    BattleSideId.player: playerBefore.currentHp,
    BattleSideId.enemy: enemyBefore.currentHp,
  };
  final steps = <BattleTurnPresentationStep>[];

  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnBagHpHealItemEvent(:final event):
        final userLabel = _presentationCombatantLabel(event.side);
        steps.add(
          BattleTurnPresentationStep(
            message:
                '$userLabel utilise ${event.itemKind.label} sur ${event.targetSpeciesId} !',
          ),
        );

        final visibleTargetSide = event.side == BattleSideId.player &&
                playerBefore.lineupIndex == event.targetLineupIndex
            ? BattleSideId.player
            : event.side == BattleSideId.enemy &&
                    enemyBefore.lineupIndex == event.targetLineupIndex
                ? BattleSideId.enemy
                : null;
        if (visibleTargetSide == null || event.healedAmount <= 0) {
          steps.add(
            BattleTurnPresentationStep(
              message:
                  '${event.targetSpeciesId} récupère ${event.healedAmount} PV.',
            ),
          );
          continue;
        }

        trackedHp[visibleTargetSide] = event.hpAfter;
        steps.add(
          BattleTurnPresentationStep(
            message:
                '${event.targetSpeciesId} récupère ${event.healedAmount} PV.',
            hpChangeTargetSide: visibleTargetSide,
            hpFrom: event.hpBefore,
            hpTo: event.hpAfter,
          ),
        );
      case BattleTurnExecutionEvent(:final execution):
        final message =
            '${_presentationCombatantLabel(execution.attackerSide)} utilise ${execution.move.name} !';
        final targetSide = execution.targetSide;
        final dealsVisibleDamage = execution.didHit &&
            execution.damage > 0 &&
            execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
            targetSide != null;

        if (!dealsVisibleDamage) {
          steps.add(BattleTurnPresentationStep(message: message));
          continue;
        }

        final hpFrom = trackedHp[targetSide] ?? 0;
        final hpTo = (hpFrom - execution.damage).clamp(0, hpFrom);
        trackedHp[targetSide] = hpTo;
        steps.add(
          BattleTurnPresentationStep(
            message: message,
            flashTargetSide: targetSide,
            hpChangeTargetSide: targetSide,
            hpFrom: hpFrom,
            hpTo: hpTo,
          ),
        );
      default:
        continue;
    }
  }

  return List<BattleTurnPresentationStep>.unmodifiable(steps);
}

String _presentationCombatantLabel(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}
