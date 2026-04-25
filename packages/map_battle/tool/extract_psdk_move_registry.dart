import 'dart:io';

final _registerPattern = RegExp(
  r'(?:Move\.)?register\(:((?:s_)[a-zA-Z0-9_]+),\s*([A-Za-z0-9_:]+)\)',
);

const _knownDartBehaviors = <String, _KnownDartBehavior>{
  // These statuses stay "partial" until their Ruby behavior families are fully
  // parity-tested. The engine can execute them today, but Lot 15 must not claim
  // complete PSDK parity just because a method is wired.
  's_basic': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_basic',
    status: _PsdkPortStatus.partial,
  ),
  's_status': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.status',
    status: _PsdkPortStatus.partial,
  ),
  's_stat': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.stat',
    status: _PsdkPortStatus.partial,
  ),
  's_self_stat': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.selfStat',
    status: _PsdkPortStatus.partial,
  ),
  's_self_status': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.selfStatus',
    status: _PsdkPortStatus.partial,
  ),
  's_protect': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_protect',
    status: _PsdkPortStatus.partial,
  ),
  's_fixed_damage': _KnownDartBehavior(
    dartBehavior: 'FixedDamageMoveBehavior.psdkFixedDamage',
    status: _PsdkPortStatus.ported,
  ),
  's_hp_eq_level': _KnownDartBehavior(
    dartBehavior: 'FixedDamageMoveBehavior.userLevel',
    status: _PsdkPortStatus.ported,
  ),
  's_psywave': _KnownDartBehavior(
    dartBehavior: 'FixedDamageMoveBehavior.psywave',
    status: _PsdkPortStatus.ported,
  ),
  's_super_fang': _KnownDartBehavior(
    dartBehavior: 'FixedDamageMoveBehavior.halfCurrentTargetHp',
    status: _PsdkPortStatus.ported,
  ),
  's_2hits': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.fixed(2)',
    status: _PsdkPortStatus.ported,
  ),
  's_3hits': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.fixed(3)',
    status: _PsdkPortStatus.ported,
  ),
  // Base PSDK MultiHit is executable, including the 2-5 hit distribution, but
  // remains partial until ability data can model Skill Link's forced five hits.
  's_multi_hit': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.psdkRandom',
    status: _PsdkPortStatus.partial,
  ),
  // These descendants execute their local hit-count/power/accuracy rules, but
  // stay partial until Skill Link, Population Bomb's always-hit override and
  // form-specific Water Shuriken data are available in the combatant snapshot.
  's_triple_kick': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.tripleKick',
    status: _PsdkPortStatus.partial,
  ),
  's_population_bomb': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.populationBomb',
    status: _PsdkPortStatus.partial,
  ),
  's_water_shuriken': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.waterShuriken',
    status: _PsdkPortStatus.partial,
  ),
  // False Swipe is executable but remains partial until Substitute is available
  // in combatant effects. Full Crit only overrides Ruby critical_rate to 100.
  's_false_swipe': _KnownDartBehavior(
    dartBehavior: 'BasicDamageSpecializationMoveBehavior.falseSwipe',
    status: _PsdkPortStatus.partial,
  ),
  's_full_crit': _KnownDartBehavior(
    dartBehavior: 'BasicDamageSpecializationMoveBehavior.fullCrit',
    status: _PsdkPortStatus.ported,
  ),
  's_do_nothing': _KnownDartBehavior(
    dartBehavior: 'NoEffectMoveBehavior.doNothing',
    status: _PsdkPortStatus.ported,
  ),
  // Splash mutates no combat state, but PSDK also displays a localized
  // "nothing happened" message that this pure battle event lane cannot emit
  // yet.
  's_splash': _KnownDartBehavior(
    dartBehavior: 'NoEffectMoveBehavior.splash',
    status: _PsdkPortStatus.partial,
  ),
  's_endeavor': _KnownDartBehavior(
    dartBehavior: 'DirectHpMoveBehavior.endeavor',
    status: _PsdkPortStatus.ported,
  ),
  // The HP transfer is executable, but PSDK's full faint-process callbacks and
  // double-KO semantics still need the richer battle procedure stack.
  's_final_gambit': _KnownDartBehavior(
    dartBehavior: 'DirectHpMoveBehavior.finalGambit',
    status: _PsdkPortStatus.partial,
  ),
  // Drain/heal families are executable for their local HP transfer rules, but
  // stay partial until PSDK's Heal Block, drain-prevention and item/ability
  // hooks are represented as full effects.
  's_absorb': _KnownDartBehavior(
    dartBehavior: 'DrainMoveBehavior.absorb',
    status: _PsdkPortStatus.partial,
  ),
  's_dream_eater': _KnownDartBehavior(
    dartBehavior: 'DrainMoveBehavior.dreamEater',
    status: _PsdkPortStatus.partial,
  ),
  's_heal': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior',
    status: _PsdkPortStatus.partial,
  ),
  's_heal_weather': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior.weather',
    status: _PsdkPortStatus.partial,
  ),
  's_floral_healing': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior.floralHealing',
    status: _PsdkPortStatus.partial,
  ),
  's_roost': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior.roost',
    status: _PsdkPortStatus.partial,
  ),
  's_shore_up': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior.shoreUp',
    status: _PsdkPortStatus.partial,
  ),
  's_life_dew': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior.lifeDew',
    status: _PsdkPortStatus.partial,
  ),
  's_jungle_healing': _KnownDartBehavior(
    dartBehavior: 'HealMoveBehavior.jungleHealing',
    status: _PsdkPortStatus.partial,
  ),
  's_aqua_ring': _KnownDartBehavior(
    dartBehavior: 'PersistentEffectMoveBehavior.aquaRing',
    status: _PsdkPortStatus.partial,
  ),
  // Hit-then-cure moves execute their local power/cure rules. They stay
  // partial until status cure process hooks and Substitute-style effect
  // interception can mirror Ruby PSDK completely.
  's_smelling_salt': _KnownDartBehavior(
    dartBehavior: 'HitThenCureStatusMoveBehavior.smellingSalt',
    status: _PsdkPortStatus.partial,
  ),
  's_wakeup_slap': _KnownDartBehavior(
    dartBehavior: 'HitThenCureStatusMoveBehavior.wakeUpSlap',
    status: _PsdkPortStatus.partial,
  ),
  's_sparkling_aria': _KnownDartBehavior(
    dartBehavior: 'HitThenCureStatusMoveBehavior.sparklingAria',
    status: _PsdkPortStatus.partial,
  ),
  // Recovery/stat moves execute their local HP/status/stat formulas. They stay
  // partial until terrain grounding, Chesto Berry/Big Root/Liquid Ooze,
  // Contrary and Heal Block style hooks are represented in the battle lane.
  's_rest': _KnownDartBehavior(
    dartBehavior: 'RecoveryStatMoveBehavior.rest',
    status: _PsdkPortStatus.partial,
  ),
  's_bellydrum': _KnownDartBehavior(
    dartBehavior: 'RecoveryStatMoveBehavior.bellyDrum',
    status: _PsdkPortStatus.partial,
  ),
  's_strength_sap': _KnownDartBehavior(
    dartBehavior: 'RecoveryStatMoveBehavior.strengthSap',
    status: _PsdkPortStatus.partial,
  ),
  's_fillet_away': _KnownDartBehavior(
    dartBehavior: 'RecoveryStatMoveBehavior.filletAway',
    status: _PsdkPortStatus.partial,
  ),
  's_acupressure': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.acupressure',
    status: _PsdkPortStatus.partial,
  ),
  's_clangorous_soul': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.clangorousSoul',
    status: _PsdkPortStatus.partial,
  ),
  's_curse': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.curse',
    status: _PsdkPortStatus.partial,
  ),
  's_growth': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.growth',
    status: _PsdkPortStatus.partial,
  ),
  's_guard_swap': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.guardSwap',
    status: _PsdkPortStatus.partial,
  ),
  's_haze': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.haze',
    status: _PsdkPortStatus.partial,
  ),
  's_heart_swap': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.heartSwap',
    status: _PsdkPortStatus.partial,
  ),
  's_power_swap': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.powerSwap',
    status: _PsdkPortStatus.partial,
  ),
  's_psych_up': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.psychUp',
    status: _PsdkPortStatus.partial,
  ),
  's_topsy_turvy': _KnownDartBehavior(
    dartBehavior: 'AdvancedStatMoveBehavior.topsyTurvy',
    status: _PsdkPortStatus.partial,
  ),
  // Acrobatics' no-item branch is executable. Keep it partial until consumed
  // item and Gem item-effect parity is covered in the item hook matrix.
  's_acrobatics': _KnownDartBehavior(
    dartBehavior: 'SpecialPowerMoveBehavior.acrobatics',
    status: _PsdkPortStatus.partial,
  ),
  's_stored_power': _KnownDartBehavior(
    dartBehavior: 'SpecialPowerMoveBehavior.storedPower',
    status: _PsdkPortStatus.ported,
  ),
  // PSDK registers all three methods on `Move::MindBlown`. The Dart behavior
  // ports the half-max-HP crash on hit, miss, type immunity and Protect-style
  // target blocking, but remains partial until Damp/Wonder Guard ability gates
  // exist in the PSDK combatant snapshot.
  's_chloroblast': _KnownDartBehavior(
    dartBehavior: 'MindBlownMoveBehavior.chloroblast',
    status: _PsdkPortStatus.partial,
  ),
  's_mind_blown': _KnownDartBehavior(
    dartBehavior: 'MindBlownMoveBehavior.mindBlown',
    status: _PsdkPortStatus.partial,
  ),
  's_steel_beam': _KnownDartBehavior(
    dartBehavior: 'MindBlownMoveBehavior.steelBeam',
    status: _PsdkPortStatus.partial,
  ),
  // PSDK registers SelfDestruct/Explosion with unprefixed `register(...)`.
  // The self-KO behavior is executable, but Damp remains future ability work.
  's_explosion': _KnownDartBehavior(
    dartBehavior: 'SelfDestructMoveBehavior.explosion',
    status: _PsdkPortStatus.partial,
  ),
  // Misty Explosion's terrain power boost is executable once Lot 24 exposes
  // field terrain. It remains partial until Damp and grounded/airborne state
  // are available.
  's_misty_explosion': _KnownDartBehavior(
    dartBehavior: 'SelfDestructMoveBehavior.mistyExplosion',
    status: _PsdkPortStatus.partial,
  ),
  // PSDK currently maps only Psyblade to Electric Terrain for this family. The
  // formula is executable exactly; field setters and duration hooks stay out.
  's_terrain_boosting': _KnownDartBehavior(
    dartBehavior: 'TerrainPowerMoveBehavior.terrainBoosting',
    status: _PsdkPortStatus.ported,
  ),
  // Field setters now execute through PSDK-style handlers, including item
  // duration extension and hard-weather blocking. They stay partial until the
  // full field effect hook surface is ported.
  's_weather': _KnownDartBehavior(
    dartBehavior: 'WeatherMoveBehavior',
    status: _PsdkPortStatus.partial,
  ),
  's_terrain': _KnownDartBehavior(
    dartBehavior: 'TerrainMoveBehavior',
    status: _PsdkPortStatus.partial,
  ),
  // Weather Ball has executable weather power/type behavior. Keep it partial
  // until every weather effect and suppression hook has parity coverage.
  's_weather_ball': _KnownDartBehavior(
    dartBehavior: 'WeatherPowerMoveBehavior.weatherBall',
    status: _PsdkPortStatus.partial,
  ),
  // The base recoil damage is executable. Keep the status partial until Rock
  // Head, Parental Bond/Reckless style ability hooks, item callbacks and
  // Basculin evolution bookkeeping exist in the PSDK lane.
  's_recoil': _KnownDartBehavior(
    dartBehavior: 'RecoilMoveBehavior.psdkRecoil',
    status: _PsdkPortStatus.partial,
  ),
  's_brine': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.brine',
    status: _PsdkPortStatus.ported,
  ),
  's_eruption': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.eruption',
    status: _PsdkPortStatus.ported,
  ),
  's_flail': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.flail',
    status: _PsdkPortStatus.ported,
  ),
  's_wring_out': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.wringOut',
    status: _PsdkPortStatus.ported,
  ),
  's_hard_press': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.hardPress',
    status: _PsdkPortStatus.ported,
  ),
  's_electro_ball': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.electroBall',
    status: _PsdkPortStatus.ported,
  ),
  // The Dart behavior applies the clamp that the PSDK Ruby class computes but
  // does not return explicitly. Keep the matrix partial until exact parity vs.
  // intentional adaptation is documented at the canonical combat level.
  's_gyro_ball': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.gyroBall',
    status: _PsdkPortStatus.partial,
  ),
  's_facade': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.facade',
    status: _PsdkPortStatus.ported,
  ),
  's_infernal_parade': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.infernalParade',
    status: _PsdkPortStatus.ported,
  ),
  's_bitter_malice': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.bitterMalice',
    status: _PsdkPortStatus.ported,
  ),
  's_venoshock': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.venoshock',
    status: _PsdkPortStatus.ported,
  ),
  // PSDK Hex also doubles damage for Comatose, which belongs to the future
  // ability/effect stack rather than this status-only Lot 16 slice.
  's_hex': _KnownDartBehavior(
    dartBehavior: 'VariablePowerMoveBehavior.hex',
    status: _PsdkPortStatus.partial,
  ),
  // Weight formulas are executable, but PSDK's Minimize bonus/bypass and
  // modified-weight ability fallback are still future effect/ability work.
  's_low_kick': _KnownDartBehavior(
    dartBehavior: 'WeightPowerMoveBehavior.lowKick',
    status: _PsdkPortStatus.partial,
  ),
  's_heavy_slam': _KnownDartBehavior(
    dartBehavior: 'WeightPowerMoveBehavior.heavySlam',
    status: _PsdkPortStatus.partial,
  ),
  // These moves reuse the PSDK stat-source formulas but still rely on future
  // ability/item/effect hooks for complete damage parity.
  's_body_press': _KnownDartBehavior(
    dartBehavior: 'CustomStatSourceMoveBehavior.bodyPress',
    status: _PsdkPortStatus.partial,
  ),
  's_foul_play': _KnownDartBehavior(
    dartBehavior: 'CustomStatSourceMoveBehavior.foulPlay',
    status: _PsdkPortStatus.partial,
  ),
  's_psyshock': _KnownDartBehavior(
    dartBehavior: 'CustomStatSourceMoveBehavior.psyshock',
    status: _PsdkPortStatus.partial,
  ),
  's_custom_stats_based': _KnownDartBehavior(
    dartBehavior: 'CustomStatSourceMoveBehavior.customStatsBased',
    status: _PsdkPortStatus.partial,
  ),
};

const _manualDependencies = <String, Set<_PsdkMoveDependency>>{
  's_status': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_stat': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_self_stat': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_self_status': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  // Weather and terrain families need handlers/effects before their move class
  // can be considered truly ported. PSDK delegates most of that behavior to
  // WeatherChangeHandler, FTerrainChangeHandler, item duration hooks and field
  // effects, so the matrix must not present these as isolated move work.
  's_weather': {
    _PsdkMoveDependency.handlerWeather,
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
  },
  's_terrain': {
    _PsdkMoveDependency.handlerTerrain,
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
  },
  's_weather_ball': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.ability,
  },
  's_terrain_pulse': {
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
  },
  's_rising_voltage': {
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
  },
  's_expanding_force': {
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
    _PsdkMoveDependency.targetingMulti,
  },
  's_grassy_glide': {
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
    _PsdkMoveDependency.actionOrder,
  },
  's_solar_beam': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.effects,
  },
  's_thunder': {
    _PsdkMoveDependency.weather,
  },
  's_shore_up': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
  },
  // Multi-hit parity depends on ability/item hooks that can alter hit counts.
  's_multi_hit': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  's_triple_kick': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.history,
  },
  's_population_bomb': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  's_water_shuriken': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  // Existing local implementations remain partial until common handlers and
  // effect hooks can intercept the same situations as Ruby PSDK.
  's_recoil': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.history,
  },
  's_explosion': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.faintProcess,
  },
  's_misty_explosion': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.faintProcess,
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
  },
  's_mind_blown': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.faintProcess,
  },
  's_chloroblast': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.faintProcess,
  },
  's_steel_beam': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.faintProcess,
  },
  's_false_swipe': {
    _PsdkMoveDependency.effects,
  },
  's_final_gambit': {
    _PsdkMoveDependency.faintProcess,
    _PsdkMoveDependency.history,
  },
  's_absorb': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
  },
  's_dream_eater': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
  },
  's_heal': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_heal_weather': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_floral_healing': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_roost': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
  },
  's_life_dew': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.targetingMulti,
  },
  's_jungle_healing': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.targetingMulti,
  },
  's_aqua_ring': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.endTurn,
    _PsdkMoveDependency.item,
  },
  's_smelling_salt': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
  },
  's_wakeup_slap': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_sparkling_aria': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
  },
  's_rest': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.item,
  },
  's_bellydrum': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_strength_sap': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.effects,
  },
  's_fillet_away': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_acupressure': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_clangorous_soul': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_curse': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.endTurn,
  },
  's_growth': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_guard_swap': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_haze': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.targetingMulti,
  },
  's_heart_swap': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_power_swap': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_psych_up': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_topsy_turvy': {
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_acrobatics': {
    _PsdkMoveDependency.item,
  },
  's_hex': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.handlerStatus,
  },
  's_low_kick': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.grounded,
  },
  's_heavy_slam': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_body_press': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  's_foul_play': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  's_psyshock': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  's_custom_stats_based': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
};

Future<void> main(List<String> args) async {
  final parsed = _MoveExtractorArgs.parse(args);
  if (parsed == null) {
    stderr.writeln(
      'Usage: dart run tool/extract_psdk_move_registry.dart '
      '<psdk-5-battle-dir> <output-md> [--manifest <output-dart>]',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(parsed.psdkBattleRootPath);
  if (!root.existsSync()) {
    stderr.writeln('PSDK battle folder not found: ${root.path}');
    exitCode = 66;
    return;
  }

  final rows = await _extractRows(root);
  await _writeTextFile(
      parsed.outputMarkdownPath, _renderMoveMatrix(root, rows));
  final manifestPath = parsed.outputManifestPath;
  if (manifestPath != null) {
    await _writeTextFile(manifestPath, _renderDartManifest(rows));
  }
}

Future<List<_MoveRegistryRow>> _extractRows(Directory root) async {
  final scanRoot = _childDir(root, '10 Move') ?? root;
  final rows = <_MoveRegistryRow>[];
  for (final file in _rubyFiles(scanRoot)) {
    final content = await file.readAsString();
    for (final match in _registerPattern.allMatches(content)) {
      final method = match.group(1)!;
      final known = _knownDartBehaviors[method];
      rows.add(
        _MoveRegistryRow(
          method: method,
          rubyClass: match.group(2)!,
          rubyPath: _relativePath(root, file),
          dartBehavior: known?.dartBehavior ?? 'TODO',
          status: known?.status ?? _PsdkPortStatus.missing,
          dependencies: _dependenciesFor(method),
        ),
      );
    }
  }
  rows.sort((left, right) => left.method.compareTo(right.method));
  return _dedupeByMethod(rows);
}

String _renderMoveMatrix(Directory root, List<_MoveRegistryRow> rows) {
  final counts = {
    for (final status in _PsdkPortStatus.values)
      status: rows.where((row) => row.status == status).length,
  };
  final buffer = StringBuffer()
    ..writeln('# PSDK Move Porting Matrix')
    ..writeln()
    ..writeln('Source: `${_markdownEscape(root.path)}`')
    ..writeln()
    ..writeln('Total registered methods: ${rows.length}')
    ..writeln()
    ..writeln('| Status | Count |')
    ..writeln('| --- | ---: |');
  for (final status in _PsdkPortStatus.values) {
    buffer.writeln('| `${status.name}` | ${counts[status]} |');
  }
  buffer
    ..writeln()
    ..writeln(
      '| Method | Ruby class | Ruby path | Dart behavior | Status | Dependencies |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln(
      '| `${_markdownEscape(row.method)}` '
      '| `${_markdownEscape(row.rubyClass)}` '
      '| `${_markdownEscape(row.rubyPath)}` '
      '| `${_markdownEscape(row.dartBehavior)}` '
      '| `${row.status.name}` '
      '| ${_renderDependencies(row.dependencies)} |',
    );
  }
  return buffer.toString();
}

String _renderDartManifest(List<_MoveRegistryRow> rows) {
  final buffer = StringBuffer()
    ..writeln('/// Generated PSDK move registry manifest.')
    ..writeln('///')
    ..writeln('/// Do not edit entries by hand. Regenerate with:')
    ..writeln('///')
    ..writeln('/// ```bash')
    ..writeln('/// dart run tool/extract_psdk_move_registry.dart \\')
    ..writeln('///   ../../pokemonsdk-development/scripts/5\\ Battle \\')
    ..writeln('///   ../../reports/psdk-move-porting-matrix.md \\')
    ..writeln(
        '///   --manifest lib/src/data/generated/psdk_move_registry_manifest.dart')
    ..writeln('/// ```')
    ..writeln(
      'const psdkMoveRegistryManifest = <PsdkMoveRegistryManifestEntry>[',
    );
  for (final row in rows) {
    buffer
      ..writeln('  PsdkMoveRegistryManifestEntry(')
      ..writeln("    battleEngineMethod: '${_dartEscape(row.method)}',")
      ..writeln("    rubyClass: '${_dartEscape(row.rubyClass)}',")
      ..writeln("    rubyPath: '${_dartEscape(row.rubyPath)}',")
      ..writeln("    dartBehavior: '${_dartEscape(row.dartBehavior)}',")
      ..writeln('    status: PsdkPortStatus.${row.status.name},')
      ..writeln(
        '    dependencies: ${_renderDartDependencies(row.dependencies)},',
      )
      ..writeln('  ),');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('final class PsdkMoveRegistryManifestEntry {')
    ..writeln('  const PsdkMoveRegistryManifestEntry({')
    ..writeln('    required this.battleEngineMethod,')
    ..writeln('    required this.rubyClass,')
    ..writeln('    required this.rubyPath,')
    ..writeln('    required this.dartBehavior,')
    ..writeln('    required this.status,')
    ..writeln('    this.dependencies = const <PsdkMoveDependency>[],')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final String battleEngineMethod;')
    ..writeln('  final String rubyClass;')
    ..writeln('  final String rubyPath;')
    ..writeln('  final String dartBehavior;')
    ..writeln('  final PsdkPortStatus status;')
    ..writeln('  final List<PsdkMoveDependency> dependencies;')
    ..writeln('}')
    ..writeln()
    ..writeln('enum PsdkPortStatus {')
    ..writeln('  ported,')
    ..writeln('  partial,')
    ..writeln('  missing,')
    ..writeln('}')
    ..writeln()
    ..writeln('enum PsdkMoveDependency {');
  for (final dependency in _PsdkMoveDependency.values) {
    buffer.writeln('  ${dependency.dartName},');
  }
  buffer..writeln('}');
  return buffer.toString();
}

String _renderDependencies(Set<_PsdkMoveDependency> dependencies) {
  if (dependencies.isEmpty) {
    return '`-`';
  }
  return dependencies.map((dependency) => '`${dependency.token}`').join(', ');
}

String _renderDartDependencies(Set<_PsdkMoveDependency> dependencies) {
  if (dependencies.isEmpty) {
    return 'const <PsdkMoveDependency>[]';
  }
  final values = dependencies
      .map((dependency) => 'PsdkMoveDependency.${dependency.dartName}')
      .join(', ');
  return 'const <PsdkMoveDependency>[$values]';
}

Set<_PsdkMoveDependency> _dependenciesFor(String method) {
  final dependencies = _manualDependencies[method];
  if (dependencies == null) {
    return const <_PsdkMoveDependency>{};
  }
  return Set<_PsdkMoveDependency>.unmodifiable(dependencies);
}

List<_MoveRegistryRow> _dedupeByMethod(List<_MoveRegistryRow> rows) {
  final seen = <String>{};
  final unique = <_MoveRegistryRow>[];
  for (final row in rows) {
    if (seen.add(row.method)) {
      unique.add(row);
    }
  }
  return unique;
}

List<File> _rubyFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.rb'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
}

Directory? _childDir(Directory root, String childName) {
  final child = Directory('${root.path}/$childName');
  return child.existsSync() ? child : null;
}

String _relativePath(Directory root, File file) {
  final rootPath = _withTrailingSeparator(root.absolute.path);
  final filePath = file.absolute.path;
  if (filePath.startsWith(rootPath)) {
    return filePath.substring(rootPath.length);
  }
  return filePath;
}

String _withTrailingSeparator(String path) {
  return path.endsWith(Platform.pathSeparator)
      ? path
      : '$path${Platform.pathSeparator}';
}

Future<void> _writeTextFile(String path, String content) async {
  final file = File(path);
  file.parent.createSync(recursive: true);
  await file.writeAsString(content);
}

String _markdownEscape(String value) => value.replaceAll('|', r'\|');

String _dartEscape(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}

final class _MoveExtractorArgs {
  const _MoveExtractorArgs({
    required this.psdkBattleRootPath,
    required this.outputMarkdownPath,
    this.outputManifestPath,
  });

  final String psdkBattleRootPath;
  final String outputMarkdownPath;
  final String? outputManifestPath;

  static _MoveExtractorArgs? parse(List<String> args) {
    if (args.length == 2) {
      return _MoveExtractorArgs(
        psdkBattleRootPath: args[0],
        outputMarkdownPath: args[1],
      );
    }
    if (args.length == 4 && args[2] == '--manifest') {
      return _MoveExtractorArgs(
        psdkBattleRootPath: args[0],
        outputMarkdownPath: args[1],
        outputManifestPath: args[3],
      );
    }
    return null;
  }
}

final class _MoveRegistryRow {
  const _MoveRegistryRow({
    required this.method,
    required this.rubyClass,
    required this.rubyPath,
    required this.dartBehavior,
    required this.status,
    required this.dependencies,
  });

  final String method;
  final String rubyClass;
  final String rubyPath;
  final String dartBehavior;
  final _PsdkPortStatus status;
  final Set<_PsdkMoveDependency> dependencies;
}

final class _KnownDartBehavior {
  const _KnownDartBehavior({
    required this.dartBehavior,
    required this.status,
  });

  final String dartBehavior;
  final _PsdkPortStatus status;
}

enum _PsdkPortStatus {
  ported,
  partial,
  missing,
}

enum _PsdkMoveDependency {
  effects('effects', 'effects'),
  handlerDamage('handler_damage', 'handlerDamage'),
  handlerStatus('handler_status', 'handlerStatus'),
  handlerStat('handler_stat', 'handlerStat'),
  handlerItem('handler_item', 'handlerItem'),
  handlerSwitch('handler_switch', 'handlerSwitch'),
  handlerWeather('handler_weather', 'handlerWeather'),
  handlerTerrain('handler_terrain', 'handlerTerrain'),
  endTurn('end_turn', 'endTurn'),
  field('field', 'field'),
  weather('weather', 'weather'),
  terrain('terrain', 'terrain'),
  targetingMulti('targeting_multi', 'targetingMulti'),
  ability('ability', 'ability'),
  item('item', 'item'),
  history('history', 'history'),
  grounded('grounded', 'grounded'),
  faintProcess('faint_process', 'faintProcess'),
  runtimeBridge('runtime_bridge', 'runtimeBridge'),
  actionOrder('action_order', 'actionOrder');

  const _PsdkMoveDependency(this.token, this.dartName);

  final String token;
  final String dartName;
}
