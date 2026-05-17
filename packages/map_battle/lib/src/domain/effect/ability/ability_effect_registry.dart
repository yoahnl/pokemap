import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../data/generated/psdk_ability_effect_manifest.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'ability_immunity_effect.dart';
import 'air_lock_effect.dart';
import 'cloud_nine_effect.dart';
import 'contact_punish_ability_effect.dart';
import 'damage_modifier_ability_effect.dart';
import 'damp_effect.dart';
import 'levitate_effect.dart';
import 'move_shape_power_ability_effect.dart';
import 'no_guard_effect.dart';
import 'reckless_effect.dart';
import 'residual_ability_effect.dart';
import 'rock_head_effect.dart';
import 'shadow_tag_effect.dart';
import 'skill_link_effect.dart';
import 'soundproof_effect.dart';
import 'status_immunity_effect.dart';
import 'switch_trigger_ability_effect.dart';
import 'type_boosting_ability_effect.dart';
import 'type_immunity_ability_effect.dart';

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
    'rough_skin': ({required scope}) => ContactPunishAbilityEffect(
          abilityId: 'rough_skin',
          scope: scope,
        ),
    'iron_barbs': ({required scope}) => ContactPunishAbilityEffect(
          abilityId: 'iron_barbs',
          scope: scope,
        ),
    'water_absorb': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'water_absorb',
          scope: scope,
          blockedType: 'water',
          reward: TypeImmunityReward.healQuarter,
        ),
    'volt_absorb': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'volt_absorb',
          scope: scope,
          blockedType: 'electric',
          reward: TypeImmunityReward.healQuarter,
        ),
    'earth_eater': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'earth_eater',
          scope: scope,
          blockedType: 'ground',
          reward: TypeImmunityReward.healQuarter,
        ),
    'flash_fire': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'flash_fire',
          scope: scope,
          blockedType: 'fire',
          reward: TypeImmunityReward.flashFire,
        ),
    'motor_drive': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'motor_drive',
          scope: scope,
          blockedType: 'electric',
          reward: TypeImmunityReward.speed,
        ),
    'lightning_rod': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'lightning_rod',
          scope: scope,
          blockedType: 'electric',
          reward: TypeImmunityReward.specialAttack,
        ),
    'storm_drain': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'storm_drain',
          scope: scope,
          blockedType: 'water',
          reward: TypeImmunityReward.specialAttack,
        ),
    'sap_sipper': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'sap_sipper',
          scope: scope,
          blockedType: 'grass',
          reward: TypeImmunityReward.attack,
          excludedMoveIds: const <String>{'aromatherapy'},
        ),
    'overcoat': ({required scope}) => PowderMoveImmunityAbilityEffect(
          abilityId: 'overcoat',
          scope: scope,
        ),
    'sturdy': ({required scope}) => SturdyEffect(scope: scope),
    'wonder_guard': ({required scope}) => WonderGuardEffect(scope: scope),
    'blaze': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'blaze',
          scope: scope,
          boostedType: 'fire',
          requiresLowHp: true,
        ),
    'overgrow': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'overgrow',
          scope: scope,
          boostedType: 'grass',
          requiresLowHp: true,
        ),
    'torrent': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'torrent',
          scope: scope,
          boostedType: 'water',
          requiresLowHp: true,
        ),
    'swarm': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'swarm',
          scope: scope,
          boostedType: 'bug',
          requiresLowHp: true,
        ),
    'dragon_s_maw': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'dragon_s_maw',
          scope: scope,
          boostedType: 'dragon',
        ),
    'steelworker': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'steelworker',
          scope: scope,
          boostedType: 'steel',
        ),
    'transistor': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'transistor',
          scope: scope,
          boostedType: 'electric',
        ),
    'rocky_payload': ({required scope}) => TypeBoostingAbilityEffect(
          abilityId: 'rocky_payload',
          scope: scope,
          boostedType: 'rock',
        ),
    'technician': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'technician',
          scope: scope,
          shape: AbilityMovePowerShape.technician,
          multiplier: 1.5,
        ),
    'iron_fist': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'iron_fist',
          scope: scope,
          shape: AbilityMovePowerShape.punch,
          multiplier: 1.2,
        ),
    'tough_claws': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'tough_claws',
          scope: scope,
          shape: AbilityMovePowerShape.contact,
          multiplier: 1.3,
        ),
    'sharpness': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'sharpness',
          scope: scope,
          shape: AbilityMovePowerShape.slicing,
          multiplier: 1.5,
        ),
    'punk_rock': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'punk_rock',
          scope: scope,
          shape: AbilityMovePowerShape.sound,
          multiplier: 1.3,
        ),
    'solid_rock': ({required scope}) => AbilityFinalDamageModifierEffect(
          abilityId: 'solid_rock',
          scope: scope,
          condition: AbilityFinalDamageCondition.superEffectiveIncoming,
          multiplier: 0.75,
        ),
    'filter': ({required scope}) => AbilityFinalDamageModifierEffect(
          abilityId: 'filter',
          scope: scope,
          condition: AbilityFinalDamageCondition.superEffectiveIncoming,
          multiplier: 0.75,
        ),
    'prism_armor': ({required scope}) => AbilityFinalDamageModifierEffect(
          abilityId: 'prism_armor',
          scope: scope,
          condition: AbilityFinalDamageCondition.superEffectiveIncoming,
          multiplier: 0.75,
        ),
    'tinted_lens': ({required scope}) => AbilityFinalDamageModifierEffect(
          abilityId: 'tinted_lens',
          scope: scope,
          condition: AbilityFinalDamageCondition.notVeryEffectiveOutgoing,
          multiplier: 2,
        ),
    'multiscale': ({required scope}) => FullHpIncomingPowerReductionEffect(
          abilityId: 'multiscale',
          scope: scope,
          multiplier: 0.5,
        ),
    'shadow_shield': ({required scope}) => FullHpIncomingPowerReductionEffect(
          abilityId: 'shadow_shield',
          scope: scope,
          multiplier: 0.5,
        ),
    'levitate': ({required scope}) => LevitateEffect(scope: scope),
    'no_guard': ({required scope}) => NoGuardEffect(scope: scope),
    'reckless': ({required scope}) => RecklessEffect(scope: scope),
    'rock_head': ({required scope}) => RockHeadEffect(scope: scope),
    'shadow_tag': ({required scope}) => ShadowTagEffect(scope: scope),
    'arena_trap': ({required scope}) => ShadowTagEffect.arenaTrap(
          scope: scope,
        ),
    'magnet_pull': ({required scope}) => ShadowTagEffect.magnetPull(
          scope: scope,
        ),
    'skill_link': ({required scope}) => SkillLinkEffect(scope: scope),
    'soundproof': ({required scope}) => SoundproofEffect(scope: scope),
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
    'speed_boost': ({required scope}) => SpeedBoostEffect(scope: scope),
    'rain_dish': ({required scope}) => RainDishEffect(scope: scope),
    'dry_skin': ({required scope}) => DrySkinEffect(scope: scope),
    'drizzle': ({required scope}) => SwitchWeatherAbilityEffect(
          abilityId: 'drizzle',
          scope: scope,
          weather: PsdkBattleWeatherId.rain,
          weatherMoveDbSymbol: 'rain_dance',
        ),
    'drought': ({required scope}) => SwitchWeatherAbilityEffect(
          abilityId: 'drought',
          scope: scope,
          weather: PsdkBattleWeatherId.sunny,
          weatherMoveDbSymbol: 'sunny_day',
        ),
    'sand_stream': ({required scope}) => SwitchWeatherAbilityEffect(
          abilityId: 'sand_stream',
          scope: scope,
          weather: PsdkBattleWeatherId.sandstorm,
          weatherMoveDbSymbol: 'sandstorm',
        ),
    'snow_warning': ({required scope}) => SwitchWeatherAbilityEffect(
          abilityId: 'snow_warning',
          scope: scope,
          weather: PsdkBattleWeatherId.hail,
          weatherMoveDbSymbol: 'hail',
        ),
    'electric_surge': ({required scope}) => SwitchTerrainAbilityEffect(
          abilityId: 'electric_surge',
          scope: scope,
          terrain: PsdkBattleTerrainId.electricTerrain,
          terrainMoveDbSymbol: 'electric_terrain',
        ),
    'grassy_surge': ({required scope}) => SwitchTerrainAbilityEffect(
          abilityId: 'grassy_surge',
          scope: scope,
          terrain: PsdkBattleTerrainId.grassyTerrain,
          terrainMoveDbSymbol: 'grassy_terrain',
        ),
    'misty_surge': ({required scope}) => SwitchTerrainAbilityEffect(
          abilityId: 'misty_surge',
          scope: scope,
          terrain: PsdkBattleTerrainId.mistyTerrain,
          terrainMoveDbSymbol: 'misty_terrain',
        ),
    'psychic_surge': ({required scope}) => SwitchTerrainAbilityEffect(
          abilityId: 'psychic_surge',
          scope: scope,
          terrain: PsdkBattleTerrainId.psychicTerrain,
          terrainMoveDbSymbol: 'psychic_terrain',
        ),
    'intimidate': ({required scope}) => IntimidateEffect(scope: scope),
    'imposter': ({required scope}) => ImposterEffect(scope: scope),
  };

  final Map<String, AbilityEffectFactory> _factories;

  Set<String> get registeredAbilityIds {
    return <String>{
      for (final entry in psdkAbilityEffectManifest) entry.abilityId,
    };
  }

  AbilityEffectRegistryCoverage manifestCoverage() {
    final manifestIds = registeredAbilityIds;
    final factoryIds = _factories.keys.toSet();
    return AbilityEffectRegistryCoverage(
      manifestAbilityIds: manifestIds,
      concreteFactoryAbilityIds: factoryIds,
      factoryIdsOutsideManifest: factoryIds.difference(manifestIds),
      declaredEffectsWithoutFactory: <String>{
        for (final entry in psdkAbilityEffectManifest)
          if (entry.dartEffect != null && !factoryIds.contains(entry.abilityId))
            entry.abilityId,
      },
      missingAbilityIds: <String>{
        for (final entry in psdkAbilityEffectManifest)
          if (entry.status == PsdkAbilityPortStatus.missing) entry.abilityId,
      },
    );
  }

  BattleEffect? create(String? abilityId, {PsdkBattleSlotRef? owner}) {
    final normalized = _normalizeAbilityId(abilityId);
    if (normalized == null) {
      return null;
    }
    final factory = _factories[normalized];
    if (factory == null) {
      return GenericBattleEffect(
        id: 'ability:$normalized',
        scope: owner == null
            ? const LocalBattleEffectScope()
            : BattlerBattleEffectScope(owner),
      );
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

final class AbilityEffectRegistryCoverage {
  AbilityEffectRegistryCoverage({
    required Set<String> manifestAbilityIds,
    required Set<String> concreteFactoryAbilityIds,
    required Set<String> factoryIdsOutsideManifest,
    required Set<String> declaredEffectsWithoutFactory,
    required Set<String> missingAbilityIds,
  })  : manifestAbilityIds = Set<String>.unmodifiable(manifestAbilityIds),
        concreteFactoryAbilityIds =
            Set<String>.unmodifiable(concreteFactoryAbilityIds),
        factoryIdsOutsideManifest =
            Set<String>.unmodifiable(factoryIdsOutsideManifest),
        declaredEffectsWithoutFactory =
            Set<String>.unmodifiable(declaredEffectsWithoutFactory),
        missingAbilityIds = Set<String>.unmodifiable(missingAbilityIds);

  final Set<String> manifestAbilityIds;
  final Set<String> concreteFactoryAbilityIds;
  final Set<String> factoryIdsOutsideManifest;
  final Set<String> declaredEffectsWithoutFactory;
  final Set<String> missingAbilityIds;

  int get totalManifestAbilities => manifestAbilityIds.length;
}

String? _normalizeAbilityId(String? abilityId) {
  if (abilityId == null) {
    return null;
  }
  final normalized = abilityId.trim().toLowerCase();
  return normalized.isEmpty || normalized == 'unknown' ? null : normalized;
}
