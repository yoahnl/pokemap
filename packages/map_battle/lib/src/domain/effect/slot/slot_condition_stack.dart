import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class SlotConditionStack {
  SlotConditionStack({
    required this.slot,
    Iterable<BattleEffect> effects = const <BattleEffect>[],
  }) : _effects = List<BattleEffect>.unmodifiable(
          effects.map((effect) => _validatedEffect(slot, effect)),
        );

  factory SlotConditionStack.empty({required PsdkBattleSlotRef slot}) {
    return SlotConditionStack(slot: slot);
  }

  final PsdkBattleSlotRef slot;
  final List<BattleEffect> _effects;

  List<BattleEffect> get effects => List<BattleEffect>.unmodifiable(_effects);

  bool contains(String effectId) => effect(effectId) != null;

  BattleEffect? effect(String effectId) {
    for (final effect in _effects) {
      if (effect.id == effectId) {
        return effect;
      }
    }
    return null;
  }

  SlotConditionStack addOrReplace(BattleEffect effect) {
    final validated = _validatedEffect(slot, effect);
    return SlotConditionStack(
      slot: slot,
      effects: <BattleEffect>[
        for (final current in _effects)
          if (current.id != validated.id) current,
        validated,
      ],
    );
  }

  SlotConditionStack remove(String effectId) {
    return SlotConditionStack(
      slot: slot,
      effects: _effects.where((effect) => effect.id != effectId),
    );
  }

  SlotConditionTickResult tickDurations() {
    final next = <BattleEffect>[];
    final expired = <BattleEffect>[];
    for (final effect in _effects) {
      final remainingTurns = effect.remainingTurns;
      if (remainingTurns == null) {
        next.add(effect);
      } else if (remainingTurns <= 1) {
        expired.add(effect);
      } else {
        next.add(effect.copyWithRemainingTurns(remainingTurns - 1));
      }
    }
    return SlotConditionTickResult(
      stack: SlotConditionStack(slot: slot, effects: next),
      expired: expired,
    );
  }
}

final class SlotConditionTickResult {
  SlotConditionTickResult({
    required this.stack,
    Iterable<BattleEffect> expired = const <BattleEffect>[],
  }) : expired = List<BattleEffect>.unmodifiable(expired);

  final SlotConditionStack stack;
  final List<BattleEffect> expired;
}

BattleEffect _validatedEffect(PsdkBattleSlotRef slot, BattleEffect effect) {
  final scope = effect.scope;
  if (scope is! SlotBattleEffectScope || scope.slot != slot) {
    throw ArgumentError(
      'Slot condition ${effect.id} must use SlotBattleEffectScope('
      'bank: ${slot.bank}, position: ${slot.position}).',
    );
  }
  return effect;
}
