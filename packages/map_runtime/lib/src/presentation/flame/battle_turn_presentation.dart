import 'package:map_battle/map_battle.dart';

class BattleTurnPresentationStep {
  const BattleTurnPresentationStep({
    required this.message,
    this.flashTargetSide,
    this.hpFrom,
    this.hpTo,
  });

  final String message;
  final BattleSideId? flashTargetSide;
  final int? hpFrom;
  final int? hpTo;

  bool get animatesDamage =>
      flashTargetSide != null && hpFrom != null && hpTo != null;
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
    if (event is! BattleTurnExecutionEvent) {
      continue;
    }

    final execution = event.execution;
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
        hpFrom: hpFrom,
        hpTo: hpTo,
      ),
    );
  }

  return List<BattleTurnPresentationStep>.unmodifiable(steps);
}

String _presentationCombatantLabel(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}
