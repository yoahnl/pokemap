import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../action/battle_action.dart';
import '../decision/battle_decision.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../move/battle_move_type_processor.dart';
import 'psdk_move_score.dart';

final class PsdkBattleAi {
  const PsdkBattleAi({
    this.level = 3,
    this.canSwitch = false,
    this.canUseItem = false,
    this.canFlee = false,
    this.itemOptions = const <PsdkBattleAiItemOption>[],
    BattleMoveTypeProcessor typeProcessor = const BattleMoveTypeProcessor(),
  }) : _typeProcessor = typeProcessor;

  final int level;
  final bool canSwitch;
  final bool canUseItem;
  final bool canFlee;
  final List<PsdkBattleAiItemOption> itemOptions;
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
    final itemDecision =
        canUseItem ? _chooseItemDecision(state: state, user: user) : null;
    if (itemDecision != null) {
      return itemDecision;
    }

    final activeChoice = chooseMoveOrNull(
      state: state,
      user: user,
      target: target,
    );
    final switchDecision = canSwitch
        ? _chooseSwitchDecision(
            state: state,
            user: user,
            target: target,
            activeChoice: activeChoice,
          )
        : null;
    if (switchDecision != null) {
      return switchDecision;
    }

    if (canFlee && _shouldFlee(activeChoice)) {
      return const BattleDecision.flee();
    }

    if (activeChoice == null) {
      return const BattleDecision.noAction();
    }
    return BattleDecision.fight(moveSlot: activeChoice.moveSlot);
  }

  BattleItemDecision? _chooseItemDecision({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
  }) {
    final battler = state.battlerAt(user);
    PsdkBattleAiItemOption? bestOption;
    var bestScore = 0.0;
    for (final option in itemOptions) {
      final score = _itemScore(option: option, battler: battler);
      if (score > bestScore) {
        bestOption = option;
        bestScore = score;
      }
    }
    if (bestOption == null || bestScore <= 0) {
      return null;
    }
    return BattleItemDecision(
      itemId: bestOption.itemId,
      target: bestOption.target ?? user,
      effect: bestOption.effect,
    );
  }

  BattleSwitchDecision? _chooseSwitchDecision({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required PsdkBattleAiMoveChoice? activeChoice,
  }) {
    final active = state.battlerAt(user);
    final activeScore = activeChoice?.score.value ?? 0.0;
    final party = state.partyForBank(user.bank);
    PsdkMoveScore? bestReserveScore;
    int? bestPartyIndex;

    for (var partyIndex = 0; partyIndex < party.length; partyIndex += 1) {
      final candidate = party[partyIndex];
      if (candidate.id == active.id || candidate.isFainted) {
        continue;
      }
      final candidateScore = _bestMoveScoreForBattler(
        state: state,
        user: user,
        target: target,
        battler: candidate,
      );
      if (candidateScore == null || candidateScore.value <= 0) {
        continue;
      }
      if (bestReserveScore == null ||
          candidateScore.value > bestReserveScore.value) {
        bestReserveScore = candidateScore;
        bestPartyIndex = partyIndex;
      }
    }

    if (bestReserveScore == null || bestPartyIndex == null) {
      return null;
    }
    final clearGain = bestReserveScore.value - activeScore;
    if (activeScore > 0 && clearGain < 25) {
      return null;
    }
    return BattleSwitchDecision(partyIndex: bestPartyIndex);
  }

  bool _shouldFlee(PsdkBattleAiMoveChoice? activeChoice) {
    return activeChoice == null || activeChoice.score.value <= 0;
  }

  PsdkMoveScore? _bestMoveScoreForBattler({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required PsdkBattleCombatant battler,
  }) {
    final targetBattler = state.battlerAt(target);
    PsdkMoveScore? best;
    for (var i = 0; i < battler.moves.length; i += 1) {
      final score = _scoreMove(
        state: state,
        user: user,
        target: target,
        userBattler: battler,
        targetBattler: targetBattler,
        moveSlot: i,
        move: battler.moves[i],
      );
      if (!score.isUsable) {
        continue;
      }
      if (best == null || score.value > best.value) {
        best = score;
      }
    }
    return best;
  }

  double _itemScore({
    required PsdkBattleAiItemOption option,
    required PsdkBattleCombatant battler,
  }) {
    final effect = option.effect;
    if (effect is PsdkBattleHpHealItemEffect) {
      final missingHp = battler.maxHp - battler.currentHp;
      if (missingHp <= 0) {
        return 0;
      }
      if (effect.restoreToFull) {
        return missingHp.toDouble();
      }
      final amount = effect.amount ?? 0;
      final hpRatio =
          battler.maxHp <= 0 ? 0.0 : battler.currentHp / battler.maxHp;
      if (hpRatio > 0.5 && missingHp < amount) {
        return 0;
      }
      return missingHp.clamp(0, amount).toDouble();
    }
    if (effect is PsdkBattleStatusCureItemEffect) {
      final status = battler.majorStatus;
      return status != null && effect.cures(status) ? 45.0 : 0.0;
    }
    return 0;
  }

  BattleDecision chooseFightDecision({
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
      switch (status.volatileStatus) {
        case PsdkBattleVolatileStatus.confusion:
          if (!target.effects.contains(PsdkBattleEffectIds.confusion)) {
            score += 30.0 * (status.chance / 100.0);
          }
        case PsdkBattleVolatileStatus.flinch:
          if (!target.effects.contains(PsdkBattleEffectIds.flinch)) {
            score += 18.0 * (status.chance / 100.0);
          }
        case null:
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

final class PsdkBattleAiItemOption {
  const PsdkBattleAiItemOption({
    required this.itemId,
    required PsdkBattleItemActionEffect effect,
    this.target,
  })  : _effect = effect,
        _hpHealAmount = null;

  const PsdkBattleAiItemOption.hpHeal({
    required String itemId,
    required int amount,
    PsdkBattleSlotRef? target,
  })  : itemId = itemId,
        target = target,
        _effect = null,
        _hpHealAmount = amount;

  final String itemId;
  final PsdkBattleSlotRef? target;
  final PsdkBattleItemActionEffect? _effect;
  final int? _hpHealAmount;

  PsdkBattleItemActionEffect get effect {
    final explicit = _effect;
    if (explicit != null) {
      return explicit;
    }
    return PsdkBattleHpHealItemEffect.flat(_hpHealAmount!);
  }
}
