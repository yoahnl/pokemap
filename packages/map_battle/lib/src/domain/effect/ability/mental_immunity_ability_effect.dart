import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class MentalImmunityAbilityEffect extends BattleAbilityEffect {
  const MentalImmunityAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MentalImmunityAbilityEffect(abilityId: abilityId, scope: scope);
  }
}

bool battleMentalAbilityBlocksEffect({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String effectId,
}) {
  if (!_mentalAbilityBlockedEffectIds.contains(effectId)) {
    return false;
  }
  if (user != target && _userBypassesMentalAbility(state: state, user: user)) {
    return false;
  }

  final targetAbilityIds = _targetAbilityIdsForEffect(effectId);
  if (_mentalAbilityActive(state.battlerAt(target), targetAbilityIds)) {
    return true;
  }

  if (!_mentalEffectIds.contains(effectId)) {
    return false;
  }

  return state.aliveSlots().any((slot) {
    if (slot.bank != target.bank) {
      return false;
    }
    return _mentalAbilityActive(
      state.battlerAt(slot),
      const <String>{'aroma_veil'},
    );
  });
}

bool battleAromaVeilBlocksEffect({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
}) {
  if (user != target && _userBypassesMentalAbility(state: state, user: user)) {
    return false;
  }

  if (_mentalAbilityActive(
    state.battlerAt(target),
    const <String>{'aroma_veil'},
  )) {
    return true;
  }

  return state.aliveSlots().any((slot) {
    if (slot.bank != target.bank) {
      return false;
    }
    return _mentalAbilityActive(
      state.battlerAt(slot),
      const <String>{'aroma_veil'},
    );
  });
}

const _mentalEffectIds = <String>{
  'attract',
  'disable',
  'encore',
  'heal_block',
  'taunt',
  'torment',
};

const _mentalAbilityBlockedEffectIds = <String>{
  ..._mentalEffectIds,
  PsdkBattleEffectIds.confusion,
  'flinch',
};

Set<String> _targetAbilityIdsForEffect(String effectId) {
  return switch (effectId) {
    PsdkBattleEffectIds.confusion => const <String>{'own_tempo'},
    'flinch' => const <String>{'inner_focus'},
    _ => const <String>{'aroma_veil', 'oblivious'},
  };
}

const _mentalAbilityBypassIds = <String>{
  'mold_breaker',
  'teravolt',
  'turboblaze',
};

bool _mentalAbilityActive(
  PsdkBattleCombatant battler,
  Set<String> abilityIds,
) {
  return abilityIds.contains(_normalizedId(battler.abilityId)) &&
      !battler.effects.contains('ability_suppressed');
}

bool _userBypassesMentalAbility({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
}) {
  final battler = state.battlerAt(user);
  if (battler.effects.contains('ability_suppressed')) {
    return false;
  }
  return _mentalAbilityBypassIds.contains(_normalizedId(battler.abilityId));
}

String? _normalizedId(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
