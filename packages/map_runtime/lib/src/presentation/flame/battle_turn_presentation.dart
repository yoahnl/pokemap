import 'package:map_battle/map_battle.dart';

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
