import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'air_lock_effect.dart';
import 'cloud_nine_effect.dart';
import 'damp_effect.dart';
import 'levitate_effect.dart';
import 'no_guard_effect.dart';
import 'reckless_effect.dart';
import 'rock_head_effect.dart';
import 'skill_link_effect.dart';
import 'status_immunity_effect.dart';

typedef AbilityEffectFactory = BattleEffect Function({
  required BattleEffectScope scope,
});

final class AbilityEffectRegistry {
  AbilityEffectRegistry({
    Map<String, AbilityEffectFactory>? factories,
  }) : _factories = factories ?? _defaultFactories;

  static final Map<String, AbilityEffectFactory> _defaultFactories =
      <String, AbilityEffectFactory>{
    'air_lock': ({required scope}) => AirLockEffect(scope: scope),
    'cloud_nine': ({required scope}) => CloudNineEffect(scope: scope),
    'damp': ({required scope}) => DampEffect(scope: scope),
    'levitate': ({required scope}) => LevitateEffect(scope: scope),
    'no_guard': ({required scope}) => NoGuardEffect(scope: scope),
    'reckless': ({required scope}) => RecklessEffect(scope: scope),
    'rock_head': ({required scope}) => RockHeadEffect(scope: scope),
    'skill_link': ({required scope}) => SkillLinkEffect(scope: scope),
    'immunity': ({required scope}) => StatusImmunityEffect(
          abilityId: 'immunity',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.poison,
            PsdkBattleMajorStatus.toxic,
          },
        ),
    'insomnia': ({required scope}) => StatusImmunityEffect(
          abilityId: 'insomnia',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.sleep,
          },
        ),
    'vital_spirit': ({required scope}) => StatusImmunityEffect(
          abilityId: 'vital_spirit',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.sleep,
          },
        ),
    'limber': ({required scope}) => StatusImmunityEffect(
          abilityId: 'limber',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.paralysis,
          },
        ),
    'magma_armor': ({required scope}) => StatusImmunityEffect(
          abilityId: 'magma_armor',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.freeze,
          },
        ),
    'water_veil': ({required scope}) => StatusImmunityEffect(
          abilityId: 'water_veil',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.burn,
          },
        ),
  };

  final Map<String, AbilityEffectFactory> _factories;

  BattleEffect? create(String? abilityId, {PsdkBattleSlotRef? owner}) {
    final normalized = _normalizeAbilityId(abilityId);
    if (normalized == null) {
      return null;
    }
    final factory = _factories[normalized];
    if (factory == null) {
      return null;
    }
    return factory(
      scope: owner == null
          ? const LocalBattleEffectScope()
          : BattlerBattleEffectScope(owner),
    );
  }

  PsdkBattleEffectStack hydrateEffects({
    required PsdkBattleEffectStack effects,
    required String? abilityId,
    PsdkBattleSlotRef? owner,
  }) {
    final base = effects.withoutAbilityEffects();
    final effect = create(abilityId, owner: owner);
    return effect == null ? base : base.addEffect(effect);
  }
}

String? _normalizeAbilityId(String? abilityId) {
  if (abilityId == null) {
    return null;
  }
  final normalized = abilityId.trim().toLowerCase();
  return normalized.isEmpty || normalized == 'unknown' ? null : normalized;
}
