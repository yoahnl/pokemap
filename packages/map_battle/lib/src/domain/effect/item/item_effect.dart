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
