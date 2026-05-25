import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class StatDropPreventionAbilityEffect extends BattleAbilityEffect {
  StatDropPreventionAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    Set<String>? preventedStats,
  })  : _preventedStats = preventedStats == null
            ? null
            : Set<String>.unmodifiable(preventedStats),
        super(abilityId: abilityId, scope: scope);

  final Set<String>? _preventedStats;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatDropPreventionAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      preventedStats: _preventedStats,
    );
  }

  @override
  String? onStatDecreasePrevention(
    BattleEffectStatChangePreventionContext context,
  ) {
    if (!isOwnedBy(context.target) || context.user == context.target) {
      return null;
    }
    final preventedStats = _preventedStats;
    if (preventedStats != null && !preventedStats.contains(context.stat)) {
      return null;
    }
    return 'ability:$abilityId';
  }
}
