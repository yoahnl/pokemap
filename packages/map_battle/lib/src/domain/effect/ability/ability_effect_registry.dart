import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../data/generated/psdk_ability_effect_manifest.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'accuracy_modifier_ability_effect.dart';
import 'ability_immunity_effect.dart';
import 'air_lock_effect.dart';
import 'apply_status_to_move_target_ability_effect.dart';
import 'cloud_nine_effect.dart';
import 'contact_disable_ability_effect.dart';
import 'contact_punish_ability_effect.dart';
import 'contact_status_ability_effect.dart';
import 'damage_modifier_ability_effect.dart';
import 'damp_effect.dart';
import 'levitate_effect.dart';
import 'move_shape_power_ability_effect.dart';
import 'move_type_change_ability_effect.dart';
import 'no_guard_effect.dart';
import 'post_damage_stat_change_ability_effect.dart';
import 'priority_move_prevention_ability_effect.dart';
import 'reckless_effect.dart';
import 'residual_ability_effect.dart';
import 'rock_head_effect.dart';
import 'shadow_tag_effect.dart';
import 'skill_link_effect.dart';
import 'soundproof_effect.dart';
import 'stat_change_ability_effect.dart';
import 'stat_modifier_ability_effect.dart';
import 'stat_drop_prevention_ability_effect.dart';
import 'status_immunity_effect.dart';
import 'switch_trigger_ability_effect.dart';
import 'switch_out_cleanup_ability_effect.dart';
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
    'aftermath': ({required scope}) => AftermathEffect(scope: scope),
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
    'well_baked_body': ({required scope}) => TypeImmunityAbilityEffect(
          abilityId: 'well_baked_body',
          scope: scope,
          blockedType: 'fire',
          reward: TypeImmunityReward.defenseSharp,
          preventsBeforeDamage: false,
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
    'aroma_veil': ({required scope}) => GenericBattleEffect(
          id: 'ability:aroma_veil',
          scope: scope,
        ),
    'oblivious': ({required scope}) => GenericBattleEffect(
          id: 'ability:oblivious',
          scope: scope,
        ),
    'bulletproof': ({required scope}) => BulletproofEffect(scope: scope),
    'good_as_gold': ({required scope}) => GoodAsGoldEffect(scope: scope),
    'sturdy': ({required scope}) => SturdyEffect(scope: scope),
    'wonder_guard': ({required scope}) => WonderGuardEffect(scope: scope),
    'big_pecks': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'big_pecks',
          scope: scope,
          preventedStats: const <String>{'defense'},
        ),
    'hyper_cutter': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'hyper_cutter',
          scope: scope,
          preventedStats: const <String>{'attack'},
        ),
    'keen_eye': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'keen_eye',
          scope: scope,
          preventedStats: const <String>{'accuracy'},
        ),
    'mind_s_eye': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'mind_s_eye',
          scope: scope,
          preventedStats: const <String>{'accuracy'},
        ),
    'clear_body': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'clear_body',
          scope: scope,
        ),
    'full_metal_body': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'full_metal_body',
          scope: scope,
        ),
    'white_smoke': ({required scope}) => StatDropPreventionAbilityEffect(
          abilityId: 'white_smoke',
          scope: scope,
        ),
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
    'aerilate': ({required scope}) => MoveTypeChangeAbilityEffect(
          abilityId: 'aerilate',
          scope: scope,
          mode: AbilityMoveTypeChangeMode.normalToType,
          convertedType: 'flying',
          powerMultiplier: 1.3,
        ),
    'galvanize': ({required scope}) => MoveTypeChangeAbilityEffect(
          abilityId: 'galvanize',
          scope: scope,
          mode: AbilityMoveTypeChangeMode.normalToType,
          convertedType: 'electric',
          powerMultiplier: 1.3,
        ),
    'pixilate': ({required scope}) => MoveTypeChangeAbilityEffect(
          abilityId: 'pixilate',
          scope: scope,
          mode: AbilityMoveTypeChangeMode.normalToType,
          convertedType: 'fairy',
          powerMultiplier: 1.3,
        ),
    'refrigerate': ({required scope}) => MoveTypeChangeAbilityEffect(
          abilityId: 'refrigerate',
          scope: scope,
          mode: AbilityMoveTypeChangeMode.normalToType,
          convertedType: 'ice',
          powerMultiplier: 1.3,
        ),
    'normalize': ({required scope}) => MoveTypeChangeAbilityEffect(
          abilityId: 'normalize',
          scope: scope,
          mode: AbilityMoveTypeChangeMode.anyToNormal,
        ),
    'liquid_voice': ({required scope}) => MoveTypeChangeAbilityEffect(
          abilityId: 'liquid_voice',
          scope: scope,
          mode: AbilityMoveTypeChangeMode.soundToWater,
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
    'strong_jaw': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'strong_jaw',
          scope: scope,
          shape: AbilityMovePowerShape.bite,
          multiplier: 1.5,
        ),
    'mega_launcher': ({required scope}) => MoveShapePowerAbilityEffect(
          abilityId: 'mega_launcher',
          scope: scope,
          shape: AbilityMovePowerShape.pulse,
          multiplier: 1.5,
        ),
    'battery': ({required scope}) => AllyDamageModifierAbilityEffect(
          abilityId: 'battery',
          scope: scope,
          kind: AllyDamageModifierKind.batterySpecialAttack,
          multiplier: 1.3,
        ),
    'friend_guard': ({required scope}) => AllyDamageModifierAbilityEffect(
          abilityId: 'friend_guard',
          scope: scope,
          kind: AllyDamageModifierKind.friendGuard,
          multiplier: 0.75,
        ),
    'power_spot': ({required scope}) => AllyDamageModifierAbilityEffect(
          abilityId: 'power_spot',
          scope: scope,
          kind: AllyDamageModifierKind.powerSpot,
          multiplier: 1.2,
        ),
    'steely_spirit': ({required scope}) => AllyDamageModifierAbilityEffect(
          abilityId: 'steely_spirit',
          scope: scope,
          kind: AllyDamageModifierKind.steelySpirit,
          multiplier: 1.5,
        ),
    'stalwart': ({required scope}) => GenericBattleEffect(
          id: 'ability:stalwart',
          scope: scope,
        ),
    'propeller_tail': ({required scope}) => GenericBattleEffect(
          id: 'ability:propeller_tail',
          scope: scope,
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
    'neuroforce': ({required scope}) => AbilityFinalDamageModifierEffect(
          abilityId: 'neuroforce',
          scope: scope,
          condition: AbilityFinalDamageCondition.superEffectiveOutgoing,
          multiplier: 1.25,
        ),
    'dark_aura': ({required scope}) => AuraPowerAbilityEffect(
          abilityId: 'dark_aura',
          scope: scope,
        ),
    'fairy_aura': ({required scope}) => AuraPowerAbilityEffect(
          abilityId: 'fairy_aura',
          scope: scope,
        ),
    'aura_break': ({required scope}) => AuraPowerAbilityEffect(
          abilityId: 'aura_break',
          scope: scope,
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
    'queenly_majesty': ({required scope}) =>
        PriorityMovePreventionAbilityEffect(
          abilityId: 'queenly_majesty',
          scope: _bankScopeFor(scope),
        ),
    'dazzling': ({required scope}) => PriorityMovePreventionAbilityEffect(
          abilityId: 'dazzling',
          scope: _bankScopeFor(scope),
        ),
    'armor_tail': ({required scope}) => PriorityMovePreventionAbilityEffect(
          abilityId: 'armor_tail',
          scope: _bankScopeFor(scope),
          requiresProtectable: false,
          restrictToSingleTargetOrPerishSong: true,
        ),
    'pure_power': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'pure_power',
          scope: scope,
          statMultipliers: const <String, double>{'attack': 2},
        ),
    'huge_power': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'huge_power',
          scope: scope,
          statMultipliers: const <String, double>{'attack': 2},
        ),
    'guts': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'guts',
          scope: scope,
          statMultipliers: const <String, double>{'attack': 1.5},
          condition: hasMajorStatus,
        ),
    'flare_boost': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'flare_boost',
          scope: scope,
          statMultipliers: const <String, double>{'specialAttack': 1.5},
          condition: hasBurnStatus,
        ),
    'toxic_boost': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'toxic_boost',
          scope: scope,
          statMultipliers: const <String, double>{'attack': 1.5},
          condition: hasPoisonStatus,
        ),
    'defeatist': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'defeatist',
          scope: scope,
          condition: AbilityBasePowerCondition.lowHpUser,
          multiplier: 0.5,
        ),
    'fluffy': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'fluffy',
          scope: scope,
          condition: AbilityBasePowerCondition.fluffyIncoming,
          multiplier: 1,
        ),
    'heatproof': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'heatproof',
          scope: scope,
          condition: AbilityBasePowerCondition.fireIncoming,
          multiplier: 0.5,
        ),
    'thick_fat': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'thick_fat',
          scope: scope,
          condition: AbilityBasePowerCondition.fireOrIceIncoming,
          multiplier: 0.5,
        ),
    'sand_force': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'sand_force',
          scope: scope,
          condition: AbilityBasePowerCondition.sandForceOutgoing,
          multiplier: 1.3,
        ),
    'stakeout': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'stakeout',
          scope: scope,
          condition: AbilityBasePowerCondition.stakeoutOutgoing,
          multiplier: 2,
        ),
    'analytic': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'analytic',
          scope: scope,
          condition: AbilityBasePowerCondition.analyticOutgoing,
          multiplier: 1.3,
        ),
    'ice_scales': ({required scope}) => AbilityBasePowerModifierEffect(
          abilityId: 'ice_scales',
          scope: scope,
          condition: AbilityBasePowerCondition.specialIncoming,
          multiplier: 0.5,
        ),
    'fur_coat': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'fur_coat',
          scope: scope,
          statMultipliers: const <String, double>{'defense': 2},
        ),
    'hustle': ({required scope}) => HustleAbilityEffect(scope: scope),
    'marvel_scale': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'marvel_scale',
          scope: scope,
          statMultipliers: const <String, double>{'defense': 1.5},
          condition: hasMajorStatus,
        ),
    'grass_pelt': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'grass_pelt',
          scope: scope,
          statMultipliers: const <String, double>{'defense': 1.5},
          condition: hasGrassyTerrain,
        ),
    'contrary': ({required scope}) => StatChangeTransformAbilityEffect(
          abilityId: 'contrary',
          scope: scope,
          transform: AbilityStatChangeTransform.contrary,
        ),
    'simple': ({required scope}) => StatChangeTransformAbilityEffect(
          abilityId: 'simple',
          scope: scope,
          transform: AbilityStatChangeTransform.simple,
        ),
    'guard_dog': ({required scope}) => StatChangeTransformAbilityEffect(
          abilityId: 'guard_dog',
          scope: scope,
          transform: AbilityStatChangeTransform.guardDog,
        ),
    'defiant': ({required scope}) => StatDropPunishAbilityEffect(
          abilityId: 'defiant',
          scope: scope,
          boostedStat: 'attack',
        ),
    'competitive': ({required scope}) => StatDropPunishAbilityEffect(
          abilityId: 'competitive',
          scope: scope,
          boostedStat: 'specialAttack',
        ),
    'chlorophyll': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'chlorophyll',
          scope: scope,
          statMultipliers: const <String, double>{'speed': 2},
          condition: hasSunnyWeather,
        ),
    'swift_swim': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'swift_swim',
          scope: scope,
          statMultipliers: const <String, double>{'speed': 2},
          condition: hasRainWeather,
        ),
    'sand_rush': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'sand_rush',
          scope: scope,
          statMultipliers: const <String, double>{'speed': 2},
          condition: hasSandstormWeather,
        ),
    'slush_rush': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'slush_rush',
          scope: scope,
          statMultipliers: const <String, double>{'speed': 2},
          condition: hasSnowingWeather,
        ),
    'quick_feet': ({required scope}) => StatModifierAbilityEffect(
          abilityId: 'quick_feet',
          scope: scope,
          statMultipliers: const <String, double>{'speed': 1.5},
          condition: hasMajorStatus,
        ),
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
    'water_bubble': ({required scope}) => WaterBubbleEffect(scope: scope),
    'purifying_salt': ({required scope}) => PurifyingSaltEffect(scope: scope),
    'leaf_guard': ({required scope}) => StatusPreventionAbilityEffect(
          abilityId: 'leaf_guard',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.poison,
            PsdkBattleMajorStatus.toxic,
            PsdkBattleMajorStatus.sleep,
            PsdkBattleMajorStatus.freeze,
            PsdkBattleMajorStatus.paralysis,
            PsdkBattleMajorStatus.burn,
          },
          requiresSunnyWeather: true,
        ),
    'sweet_veil': ({required scope}) => StatusPreventionAbilityEffect(
          abilityId: 'sweet_veil',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.sleep,
          },
          preventionScope: StatusPreventionScope.bank,
        ),
    'pastel_veil': ({required scope}) => StatusPreventionAbilityEffect(
          abilityId: 'pastel_veil',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.poison,
            PsdkBattleMajorStatus.toxic,
          },
          preventionScope: StatusPreventionScope.bank,
          curesBankPoisonOnSwitch: true,
        ),
    'flower_veil': ({required scope}) => FlowerVeilEffect(scope: scope),
    'comatose': ({required scope}) => StatusImmunityEffect(
          abilityId: 'comatose',
          scope: scope,
          preventedStatuses: const <PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.poison,
            PsdkBattleMajorStatus.toxic,
            PsdkBattleMajorStatus.burn,
            PsdkBattleMajorStatus.paralysis,
            PsdkBattleMajorStatus.freeze,
            PsdkBattleMajorStatus.sleep,
          },
          curesExistingStatus: false,
        ),
    'compound_eyes': ({required scope}) => AccuracyModifierAbilityEffect(
          abilityId: 'compound_eyes',
          scope: scope,
          condition: AbilityAccuracyCondition.user,
          multiplier: 1.3,
        ),
    'victory_star': ({required scope}) => AccuracyModifierAbilityEffect(
          abilityId: 'victory_star',
          scope: scope,
          condition: AbilityAccuracyCondition.allyBank,
          multiplier: 1.1,
        ),
    'sand_veil': ({required scope}) => AccuracyModifierAbilityEffect(
          abilityId: 'sand_veil',
          scope: scope,
          condition: AbilityAccuracyCondition.targetSandstorm,
          multiplier: 0.8,
        ),
    'snow_cloak': ({required scope}) => AccuracyModifierAbilityEffect(
          abilityId: 'snow_cloak',
          scope: scope,
          condition: AbilityAccuracyCondition.targetSnowing,
          multiplier: 0.8,
        ),
    'wonder_skin': ({required scope}) => AccuracyModifierAbilityEffect(
          abilityId: 'wonder_skin',
          scope: scope,
          condition: AbilityAccuracyCondition.targetStatusMove,
          multiplier: 0.5,
        ),
    'flame_body': ({required scope}) => ContactStatusAbilityEffect(
          abilityId: 'flame_body',
          scope: scope,
          status: PsdkBattleMajorStatus.burn,
        ),
    'static': ({required scope}) => ContactStatusAbilityEffect(
          abilityId: 'static',
          scope: scope,
          status: PsdkBattleMajorStatus.paralysis,
        ),
    'poison_point': ({required scope}) => ContactStatusAbilityEffect(
          abilityId: 'poison_point',
          scope: scope,
          status: PsdkBattleMajorStatus.poison,
        ),
    'effect_spore': ({required scope}) =>
        ContactStatusAbilityEffect.effectSpore(scope: scope),
    'cursed_body': ({required scope}) => ContactDisableAbilityEffect(
          abilityId: 'cursed_body',
          scope: scope,
        ),
    'poison_touch': ({required scope}) => ApplyStatusToMoveTargetAbilityEffect(
          abilityId: 'poison_touch',
          scope: scope,
          status: PsdkBattleMajorStatus.poison,
          requiresContact: true,
        ),
    'toxic_chain': ({required scope}) => ApplyStatusToMoveTargetAbilityEffect(
          abilityId: 'toxic_chain',
          scope: scope,
          status: PsdkBattleMajorStatus.toxic,
        ),
    'stamina': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'stamina',
          scope: scope,
          condition: AbilityPostDamageStatCondition.anyIncoming,
          changes: const <String, int>{'defense': 1},
        ),
    'weak_armor': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'weak_armor',
          scope: scope,
          condition: AbilityPostDamageStatCondition.physicalIncoming,
          changes: const <String, int>{'defense': -1, 'speed': 1},
        ),
    'water_compaction': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'water_compaction',
          scope: scope,
          condition: AbilityPostDamageStatCondition.waterIncoming,
          changes: const <String, int>{'defense': 2},
        ),
    'steam_engine': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'steam_engine',
          scope: scope,
          condition: AbilityPostDamageStatCondition.fireOrWaterIncoming,
          changes: const <String, int>{'speed': 3},
        ),
    'thermal_exchange': ({required scope}) =>
        ThermalExchangeEffect(scope: scope),
    'justified': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'justified',
          scope: scope,
          condition: AbilityPostDamageStatCondition.darkIncoming,
          changes: const <String, int>{'attack': 1},
        ),
    'rattled': ({required scope}) => RattledEffect(scope: scope),
    'berserk': ({required scope}) => HalfHpThresholdStatChangeAbilityEffect(
          abilityId: 'berserk',
          scope: scope,
          changes: const <String, int>{'specialAttack': 1},
        ),
    'anger_shell': ({required scope}) => HalfHpThresholdStatChangeAbilityEffect(
          abilityId: 'anger_shell',
          scope: scope,
          changes: const <String, int>{
            'attack': 1,
            'specialAttack': 1,
            'speed': 1,
            'defense': -1,
            'specialDefense': -1,
          },
        ),
    'moxie': ({required scope}) => PostDamageKoStatBoostAbilityEffect(
          abilityId: 'moxie',
          scope: scope,
          boostedStat: 'attack',
          skipFellStinger: true,
        ),
    'chilling_neigh': ({required scope}) => PostDamageKoStatBoostAbilityEffect(
          abilityId: 'chilling_neigh',
          scope: scope,
          boostedStat: 'attack',
          skipFellStinger: true,
        ),
    'grim_neigh': ({required scope}) => PostDamageKoStatBoostAbilityEffect(
          abilityId: 'grim_neigh',
          scope: scope,
          boostedStat: 'specialAttack',
          skipFellStinger: true,
        ),
    'beast_boost': ({required scope}) => PostDamageKoStatBoostAbilityEffect(
          abilityId: 'beast_boost',
          scope: scope,
        ),
    'gooey': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'gooey',
          scope: scope,
          condition: AbilityPostDamageStatCondition.contactIncoming,
          changes: const <String, int>{'speed': -1},
          changeTarget: AbilityPostDamageStatChangeTarget.user,
        ),
    'tangling_hair': ({required scope}) => PostDamageStatChangeAbilityEffect(
          abilityId: 'tangling_hair',
          scope: scope,
          condition: AbilityPostDamageStatCondition.contactIncoming,
          changes: const <String, int>{'speed': -1},
          changeTarget: AbilityPostDamageStatChangeTarget.user,
        ),
    'speed_boost': ({required scope}) => SpeedBoostEffect(scope: scope),
    'rain_dish': ({required scope}) => RainDishEffect(scope: scope),
    'hydration': ({required scope}) => HydrationEffect(scope: scope),
    'ice_body': ({required scope}) => IceBodyEffect(scope: scope),
    'dry_skin': ({required scope}) => DrySkinEffect(scope: scope),
    'solar_power': ({required scope}) => SolarPowerEffect(scope: scope),
    'shed_skin': ({required scope}) => ShedSkinEffect(scope: scope),
    'bad_dreams': ({required scope}) => BadDreamsEffect(scope: scope),
    'natural_cure': ({required scope}) => NaturalCureEffect(scope: scope),
    'regenerator': ({required scope}) => RegeneratorEffect(scope: scope),
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
    'dauntless_shield': ({required scope}) => SwitchStatBoostAbilityEffect(
          abilityId: 'dauntless_shield',
          scope: scope,
          stat: 'defense',
          stages: 1,
        ),
    'intrepid_sword': ({required scope}) => SwitchStatBoostAbilityEffect(
          abilityId: 'intrepid_sword',
          scope: scope,
          stat: 'attack',
          stages: 1,
        ),
    'download': ({required scope}) => DownloadEffect(scope: scope),
    'forewarn': ({required scope}) => ForewarnEffect(scope: scope),
    'frisk': ({required scope}) => FriskEffect(scope: scope),
    'intimidate': ({required scope}) => IntimidateEffect(scope: scope),
    'imposter': ({required scope}) => ImposterEffect(scope: scope),
    'trace': ({required scope}) => TraceEffect(scope: scope),
    'telepathy': ({required scope}) => TelepathyEffect(scope: scope),
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

BattleEffectScope _bankScopeFor(BattleEffectScope scope) {
  return switch (scope) {
    BattlerBattleEffectScope(:final slot) => BankBattleEffectScope(slot.bank),
    _ => scope,
  };
}
