import '../../psdk/domain/psdk_battle_combatant.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/item/item_effect.dart';

/// Resolves PSDK grounded state from passive battler data.
///
/// Pokemon SDK checks forced-grounding causes before airborne causes. FIGHT-02
/// keeps this resolver pure and data-only: it reads ids already present on the
/// battler, but does not execute ability/item effects. Those hooks belong to
/// FIGHT-09 and FIGHT-10.
final class BattleGroundingResolver {
  const BattleGroundingResolver();

  bool isGrounded(PsdkBattleCombatant battler) {
    if (battler.effects.contains('gravity') ||
        battler.effects.contains('smack_down') ||
        battler.effects.contains('ingrain')) {
      return true;
    }

    if (battler.effects.contains('telekinesis') ||
        battler.effects.contains('magnet_rise')) {
      return false;
    }

    if (!battler.effects.contains('embargo')) {
      for (final effect in battler.itemEffects) {
        final grounded = effect.groundedOverride(battler);
        if (grounded != null) {
          return grounded;
        }
      }
      if (battler.heldItemId == 'iron_ball') {
        return true;
      }
      if (battler.heldItemId == 'air_balloon' && !battler.itemConsumed) {
        return false;
      }
    }

    for (final effect in battler.abilityEffects) {
      final grounded = effect.groundedOverride(battler);
      if (grounded != null) {
        return grounded;
      }
    }
    if (battler.abilityId == 'levitate' &&
        !battler.effects.contains('ability_suppressed')) {
      return false;
    }

    return !battler.hasType('flying');
  }
}
