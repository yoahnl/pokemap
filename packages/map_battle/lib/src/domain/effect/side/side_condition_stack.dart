import '../battle_effect.dart';
import '../battle_effect_scope.dart';

final class SideConditionStack {
  SideConditionStack({
    required this.bank,
    Iterable<BattleEffect> effects = const <BattleEffect>[],
  }) : _effects = List<BattleEffect>.unmodifiable(
          effects.map((effect) => _validatedEffect(bank, effect)),
        );

  factory SideConditionStack.empty({required int bank}) {
    return SideConditionStack(bank: bank);
  }

  final int bank;
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

  SideConditionStack addOrReplace(BattleEffect effect) {
    final validated = _validatedEffect(bank, effect);
    return SideConditionStack(
      bank: bank,
      effects: <BattleEffect>[
        for (final current in _effects)
          if (current.id != validated.id) current,
        validated,
      ],
    );
  }

  SideConditionStack remove(String effectId) {
    return SideConditionStack(
      bank: bank,
      effects: _effects.where((effect) => effect.id != effectId),
    );
  }

  SideConditionTickResult tickDurations() {
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
    return SideConditionTickResult(
      stack: SideConditionStack(bank: bank, effects: next),
      expired: expired,
    );
  }
}

final class SideConditionTickResult {
  SideConditionTickResult({
    required this.stack,
    Iterable<BattleEffect> expired = const <BattleEffect>[],
  }) : expired = List<BattleEffect>.unmodifiable(expired);

  final SideConditionStack stack;
  final List<BattleEffect> expired;
}

BattleEffect _validatedEffect(int bank, BattleEffect effect) {
  final scope = effect.scope;
  if (scope is! BankBattleEffectScope || scope.bank != bank) {
    throw ArgumentError(
      'Side condition ${effect.id} must use BankBattleEffectScope($bank).',
    );
  }
  return effect;
}
