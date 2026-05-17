import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../decision/battle_decision.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../move/battle_move_type_processor.dart';
import 'psdk_move_score.dart';

final class PsdkBattleAi {
  const PsdkBattleAi({
    this.level = 3,
    BattleMoveTypeProcessor typeProcessor = const BattleMoveTypeProcessor(),
  }) : _typeProcessor = typeProcessor;

  final int level;
  final BattleMoveTypeProcessor _typeProcessor;

  List<PsdkMoveScore> scoreMoves({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
  }) {
    final userBattler = state.battlerAt(user);
    final targetBattler = state.battlerAt(target);
    return <PsdkMoveScore>[
      for (var i = 0; i < userBattler.moves.length; i += 1)
        _scoreMove(
          state: state,
          user: user,
          target: target,
          userBattler: userBattler,
          targetBattler: targetBattler,
          moveSlot: i,
          move: userBattler.moves[i],
        ),
    ];
  }

  PsdkBattleAiMoveChoice chooseMove({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
  }) {
    final choice = chooseMoveOrNull(
      state: state,
      user: user,
      target: target,
    );
    if (choice == null) {
      throw StateError('PsdkBattleAi found no usable move.');
    }
    return choice;
  }

  PsdkBattleAiMoveChoice? chooseMoveOrNull({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
  }) {
    PsdkMoveScore? best;
    for (final score in scoreMoves(state: state, user: user, target: target)) {
      if (!score.isUsable) {
        continue;
      }
      if (best == null || score.value > best.value) {
        best = score;
      }
    }
    if (best == null) {
      return null;
    }
    return PsdkBattleAiMoveChoice(
      moveSlot: best.moveSlot,
      move: best.move,
      score: best,
    );
  }

  BattleDecision chooseDecision({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
  }) {
    final choice = chooseMoveOrNull(state: state, user: user, target: target);
    if (choice == null) {
      return const BattleDecision.noAction();
    }
    return BattleDecision.fight(moveSlot: choice.moveSlot);
  }

  PsdkMoveScore _scoreMove({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required PsdkBattleCombatant userBattler,
    required PsdkBattleCombatant targetBattler,
    required int moveSlot,
    required PsdkBattleMoveData move,
  }) {
    final preventionReason = _preventionReason(
      state: state,
      user: user,
      target: target,
      userBattler: userBattler,
      move: move,
    );
    if (preventionReason != null) {
      return PsdkMoveScore(
        moveSlot: moveSlot,
        move: move,
        value: double.negativeInfinity,
        isUsable: false,
        estimatedDamage: 0,
        effectiveness: 1,
        utilityScore: 0,
        preventedReason: preventionReason,
      );
    }

    final rawEffectiveness = _effectiveness(move, targetBattler);
    final effectiveness =
        move.category == PsdkBattleMoveCategory.status && rawEffectiveness > 0
            ? 1.0
            : rawEffectiveness;
    final estimatedDamage = _estimatedDamage(
      move: move,
      user: userBattler,
      target: targetBattler,
      effectiveness: effectiveness,
    );
    final utilityScore = _utilityScore(
      move: move,
      target: targetBattler,
      effectiveness: effectiveness,
    );
    final koBonus = estimatedDamage >= targetBattler.currentHp &&
            targetBattler.currentHp > 0
        ? 10000.0 + targetBattler.currentHp
        : 0.0;
    final value = estimatedDamage + utilityScore + koBonus;
    return PsdkMoveScore(
      moveSlot: moveSlot,
      move: move,
      value: effectiveness == 0 ? 0 : value,
      isUsable: true,
      estimatedDamage: effectiveness == 0 ? 0 : estimatedDamage,
      effectiveness: effectiveness,
      utilityScore: effectiveness == 0 ? 0 : utilityScore,
    );
  }

  String? _preventionReason({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required PsdkBattleCombatant userBattler,
    required PsdkBattleMoveData move,
  }) {
    if (!move.hasUsablePp) {
      return 'no_pp';
    }
    final prevention = userBattler.effects.moveSelectionPrevention(
      state: state,
      user: user,
      target: target,
      move: BattleMoveDefinition.fromPsdk(move),
    );
    return prevention?.reason.jsonName;
  }

  double _effectiveness(
    PsdkBattleMoveData move,
    PsdkBattleCombatant target,
  ) {
    if (level < 2) {
      return 1;
    }
    return _typeProcessor.resolveEffectiveness(
      moveType: move.type,
      targetTypes: target.types,
      extraTargetTypes: <String>[
        if (target.type3 != null) target.type3!,
        ...target.temporaryTypes,
      ],
    ).multiplier;
  }

  int _estimatedDamage({
    required PsdkBattleMoveData move,
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
    required double effectiveness,
  }) {
    if (level < 1 ||
        effectiveness == 0 ||
        move.category == PsdkBattleMoveCategory.status ||
        move.power <= 0) {
      return 0;
    }

    final offense = move.category == PsdkBattleMoveCategory.special
        ? user.effectiveStat('specialAttack')
        : user.effectiveStat('attack');
    final defense = move.category == PsdkBattleMoveCategory.special
        ? target.effectiveStat('specialDefense')
        : target.effectiveStat('defense');
    final levelFactor = ((2 * user.level) ~/ 5) + 2;
    final baseDamage =
        (((levelFactor * move.power * offense) ~/ _positive(defense)) ~/ 50) +
            2;
    final stab = _typeProcessor.resolveStabMultiplier(
      moveType: move.type,
      userTypes: user.types,
      extraUserTypes: <String>[
        if (user.type3 != null) user.type3!,
        ...user.temporaryTypes,
      ],
    );
    final accuracy = move.accuracy == 0 ? 1.0 : move.accuracy / 100.0;
    return (baseDamage * stab * effectiveness * accuracy).floor();
  }

  double _utilityScore({
    required PsdkBattleMoveData move,
    required PsdkBattleCombatant target,
    required double effectiveness,
  }) {
    if (level < 3 ||
        effectiveness == 0 ||
        move.category != PsdkBattleMoveCategory.status) {
      return 0;
    }

    var score = 0.0;
    for (final status in move.statuses) {
      if (status.majorStatus != null) {
        if (target.majorStatus == null) {
          score += 45.0 * (status.chance / 100.0);
        }
        continue;
      }
      if (status.volatileStatus == PsdkBattleVolatileStatus.confusion &&
          !target.effects.contains(PsdkBattleEffectIds.confusion)) {
        score += 30.0 * (status.chance / 100.0);
      }
    }
    for (final stageMod in move.stageMods) {
      final useful =
          _stageModIsUseful(move: move, target: target, stageMod: stageMod);
      if (useful) {
        score += 18.0 * stageMod.stages.abs();
      }
    }
    return score;
  }

  bool _stageModIsUseful({
    required PsdkBattleMoveData move,
    required PsdkBattleCombatant target,
    required PsdkBattleMoveStageMod stageMod,
  }) {
    if (_targetsUser(move.target)) {
      return stageMod.stages > 0;
    }
    if (stageMod.stages >= 0) {
      return false;
    }
    return target.statStages.valueOf(stageMod.stat) > -6;
  }
}

bool _targetsUser(PsdkBattleMoveTarget target) {
  return switch (target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => true,
    _ => false,
  };
}

int _positive(int value) => value <= 0 ? 1 : value;
