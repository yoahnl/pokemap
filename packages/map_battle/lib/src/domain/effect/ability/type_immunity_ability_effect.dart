import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum TypeImmunityReward {
  none,
  healQuarter,
  attack,
  specialAttack,
  speed,
  defenseSharp,
  flashFire,
}

final class TypeImmunityAbilityEffect extends BattleAbilityEffect {
  const TypeImmunityAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.blockedType,
    this.reward = TypeImmunityReward.none,
    this.excludedMoveIds = const <String>{},
    this.preventsBeforeDamage = true,
  }) : super(abilityId: abilityId, scope: scope);

  final String blockedType;
  final TypeImmunityReward reward;
  final Set<String> excludedMoveIds;
  final bool preventsBeforeDamage;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TypeImmunityAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      blockedType: blockedType,
      reward: reward,
      excludedMoveIds: excludedMoveIds,
      preventsBeforeDamage: preventsBeforeDamage,
    );
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!preventsBeforeDamage ||
        !_isOwner(context.target) ||
        context.user == context.target ||
        !_blocks(context.move)) {
      return null;
    }
    return BattleMoveFailureReason.immunity;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (context.user == context.target || !_blocks(context.move)) {
      return null;
    }

    final rewarded = _applyReward(context);
    return BattleEffectDamagePreventionResult(
      state: rewarded.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.immunity,
      events: rewarded.events,
    );
  }

  @override
  bool preventsStatus(BattleAbilityStatusContext context) {
    return reward == TypeImmunityReward.flashFire &&
        context.status == PsdkBattleMajorStatus.burn;
  }

  bool _blocks(BattleMoveDefinition move) {
    return move.type.toLowerCase() == blockedType &&
        !excludedMoveIds.contains(move.dbSymbol);
  }

  bool _isOwner(BattlePositionRef target) {
    final scope = this.scope;
    if (scope is! BattlerBattleEffectScope) {
      return true;
    }
    return scope.slot.bank == target.bank &&
        scope.slot.position == target.position;
  }

  _RewardResult _applyReward(BattleEffectDamagePreventionContext context) {
    return switch (reward) {
      TypeImmunityReward.healQuarter => _healQuarter(context),
      TypeImmunityReward.attack => _raiseStat(context, 'attack'),
      TypeImmunityReward.specialAttack => _raiseStat(context, 'special_attack'),
      TypeImmunityReward.speed => _raiseStat(context, 'speed'),
      TypeImmunityReward.defenseSharp =>
        _raiseStat(context, 'defense', stages: 2),
      TypeImmunityReward.flashFire || TypeImmunityReward.none => _RewardResult(
          state: context.state,
          events: const <PsdkBattleEvent>[],
        ),
    };
  }

  _RewardResult _healQuarter(BattleEffectDamagePreventionContext context) {
    final battler = context.state.battlerAt(context.target);
    if (battler.effects.contains('heal_block')) {
      return _RewardResult(
        state: context.state,
        events: const <PsdkBattleEvent>[],
      );
    }

    final amount =
        (battler.maxHp ~/ 4).clamp(0, battler.maxHp - battler.currentHp);
    if (amount <= 0) {
      return _RewardResult(
        state: context.state,
        events: const <PsdkBattleEvent>[],
      );
    }

    final healedHp = battler.currentHp + amount;
    return _RewardResult(
      state: context.state.replaceBattler(
        context.target,
        battler.copyWith(currentHp: healedHp),
      ),
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: context.target,
          target: context.target,
          moveId: 'effect:$abilityId',
          amount: amount,
          remainingHp: healedHp,
        ),
      ],
    );
  }

  _RewardResult _raiseStat(
    BattleEffectDamagePreventionContext context,
    String stat, {
    int stages = 1,
  }) {
    final battler = context.state.battlerAt(context.target);
    final nextStages = battler.statStages.apply(stat: stat, stages: stages);
    final previousStage = battler.statStages.valueOf(stat);
    final currentStage = nextStages.valueOf(stat);
    if (currentStage == previousStage) {
      return _RewardResult(
        state: context.state,
        events: const <PsdkBattleEvent>[],
      );
    }

    final nextBattler =
        battler.copyWith(statStages: nextStages).recordStatChange(
              turn: context.turn,
              stat: stat,
              delta: stages,
              currentStage: currentStage,
            );
    return _RewardResult(
      state: context.state.replaceBattler(context.target, nextBattler),
      events: <PsdkBattleEvent>[
        PsdkBattleStatStageEvent(
          target: context.target,
          stat: stat,
          amount: stages,
          currentStage: currentStage,
        ),
      ],
    );
  }
}

final class _RewardResult {
  const _RewardResult({
    required this.state,
    required this.events,
  });

  final PsdkBattleState state;
  final List<PsdkBattleEvent> events;
}
