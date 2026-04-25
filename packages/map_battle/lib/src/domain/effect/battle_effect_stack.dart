import 'battle_effect.dart';

/// Immutable object-backed effect collection for the PSDK lane.
///
/// The older public `PsdkBattleEffectStack` still exposes id helpers for
/// compatibility. This inner stack owns the real effect objects so FIGHT-03 can
/// route Protect through a hook instead of hardcoded string checks.
final class BattleEffectObjectStack {
  BattleEffectObjectStack({
    Iterable<BattleEffect> effects = const <BattleEffect>[],
  }) : _effects = List<BattleEffect>.unmodifiable(effects);

  const BattleEffectObjectStack.empty() : _effects = const <BattleEffect>[];

  final List<BattleEffect> _effects;

  List<BattleEffect> get effects => List<BattleEffect>.unmodifiable(_effects);

  bool contains(String effectId) => _effects.any(
        (effect) => effect.id == effectId,
      );

  BattleEffectObjectStack addOrReplace(BattleEffect effect) {
    final next = <BattleEffect>[
      for (final current in _effects)
        if (current.id != effect.id) current,
      effect,
    ];
    return BattleEffectObjectStack(effects: next);
  }

  BattleEffectObjectStack remove(String effectId) {
    return BattleEffectObjectStack(
      effects: _effects.where((effect) => effect.id != effectId),
    );
  }

  BattleEffectObjectStack clearTurnScopedEffects() {
    return BattleEffectObjectStack(
      effects: _effects.where((effect) => !effect.isTurnScoped),
    );
  }
}
