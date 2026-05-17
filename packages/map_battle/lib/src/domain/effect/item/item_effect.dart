import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';

abstract class BattleItemEffect extends BattleEffect {
  const BattleItemEffect({
    required this.itemId,
    required super.scope,
  }) : super(id: 'item:$itemId');

  final String itemId;

  PsdkBattleSlotRef? get owner {
    final scope = this.scope;
    return scope is BattlerBattleEffectScope ? scope.slot : null;
  }

  bool isOwnedBy(PsdkBattleSlotRef slot) => owner == slot;

  bool? groundedOverride(PsdkBattleCombatant battler) => null;

  int? minimumHitCount(BattleMoveDefinition move) => null;

  int? weatherDuration(String dbSymbol) => null;

  int? terrainDuration(String dbSymbol) => null;

  double drainHealMultiplier(BattleItemDrainModifierContext context) {
    return 1;
  }

  int? bindDuration(BattleItemBindDurationContext context) => null;

  int? bindResidualDamageDivisor(BattleItemBindResidualContext context) {
    return null;
  }

  double damageBasePowerMultiplier(BattleItemDamageModifierContext context) {
    return 1;
  }

  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    return 1;
  }

  double statMultiplier(PsdkBattleCombatant battler, String stat) {
    return 1;
  }
}

final class BattleItemDamageModifierContext {
  const BattleItemDamageModifierContext({
    required this.user,
    required this.target,
    required this.move,
    required this.moveType,
    required this.typeEffectivenessMultiplier,
  });

  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final BattleMoveDefinition move;
  final String moveType;
  final double typeEffectivenessMultiplier;
}

final class BattleItemDrainModifierContext {
  const BattleItemDrainModifierContext({
    required this.user,
    required this.target,
    required this.move,
    required this.baseHealAmount,
  });

  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final BattleMoveDefinition? move;
  final int baseHealAmount;
}

final class BattleItemBindDurationContext {
  const BattleItemBindDurationContext({
    required this.user,
    required this.target,
    required this.rolledTurns,
  });

  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final int rolledTurns;
}

final class BattleItemBindResidualContext {
  const BattleItemBindResidualContext({
    required this.origin,
    required this.target,
    required this.defaultDivisor,
  });

  final PsdkBattleCombatant origin;
  final PsdkBattleCombatant target;
  final int defaultDivisor;
}

extension BattleItemEffectList on PsdkBattleCombatant {
  Iterable<BattleItemEffect> get itemEffects sync* {
    for (final effect in effects.effects) {
      if (effect is BattleItemEffect) {
        yield effect;
      }
    }
  }

  bool get itemEffectsSuppressed {
    return effects.contains('embargo') || effects.contains('magic_room');
  }

  Iterable<BattleItemEffect> get activeItemEffects sync* {
    if (itemEffectsSuppressed) {
      return;
    }
    yield* itemEffects;
  }
}
