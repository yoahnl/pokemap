import '../domain/move/behaviors/advanced_stat_move_behavior.dart';
import '../domain/move/behaviors/action_gated_move_behavior.dart';
import '../domain/move/behaviors/battle_move_behavior_support.dart';
import '../domain/move/behaviors/basic_damage_specialization_move_behavior.dart';
import '../domain/move/behaviors/consecutive_power_move_behavior.dart';
import '../domain/move/behaviors/counter_damage_move_behavior.dart';
import '../domain/move/behaviors/custom_stat_source_move_behavior.dart';
import '../domain/move/behaviors/direct_hp_move_behavior.dart';
import '../domain/move/behaviors/drain_move_behavior.dart';
import '../domain/move/behaviors/field_location_move_behavior.dart';
import '../domain/move/behaviors/fixed_damage_move_behavior.dart';
import '../domain/move/behaviors/forced_action_move_behavior.dart';
import '../domain/move/behaviors/grounding_move_behavior.dart';
import '../domain/move/behaviors/heal_move_behavior.dart';
import '../domain/move/behaviors/hit_then_cure_status_move_behavior.dart';
import '../domain/move/behaviors/history_power_move_behavior.dart';
import '../domain/move/behaviors/item_dependent_move_behavior.dart';
import '../domain/move/behaviors/mind_blown_move_behavior.dart';
import '../domain/move/behaviors/multi_hit_move_behavior.dart';
import '../domain/move/behaviors/no_effect_move_behavior.dart';
import '../domain/move/behaviors/ohko_move_behavior.dart';
import '../domain/move/behaviors/persistent_effect_move_behavior.dart';
import '../domain/move/behaviors/power_trick_move_behavior.dart';
import '../domain/move/behaviors/psycho_shift_move_behavior.dart';
import '../domain/move/behaviors/purify_move_behavior.dart';
import '../domain/move/behaviors/recovery_stat_move_behavior.dart';
import '../domain/move/behaviors/recoil_move_behavior.dart';
import '../domain/move/behaviors/self_destruct_move_behavior.dart';
import '../domain/move/behaviors/special_secondary_move_behavior.dart';
import '../domain/move/behaviors/special_power_move_behavior.dart';
import '../domain/move/behaviors/speed_swap_move_behavior.dart';
import '../domain/move/behaviors/stat_split_move_behavior.dart';
import '../domain/move/behaviors/status_cure_move_behavior.dart';
import '../domain/move/behaviors/status_stat_move_behavior.dart';
import '../domain/move/behaviors/switch_effect_move_behavior.dart';
import '../domain/move/behaviors/terrain_power_move_behavior.dart';
import '../domain/move/behaviors/terrain_move_behavior.dart';
import '../domain/move/behaviors/transform_move_behavior.dart';
import '../domain/move/behaviors/type_based_move_behavior.dart';
import '../domain/move/behaviors/variable_power_move_behavior.dart';
import '../domain/move/behaviors/weather_move_behavior.dart';
import '../domain/move/behaviors/weather_power_move_behavior.dart';
import '../domain/move/behaviors/weight_power_move_behavior.dart';
import '../domain/move/battle_move_behavior.dart';
import '../domain/move/battle_move_data.dart';
import '../domain/move/battle_move_damage_calculator.dart';
import '../domain/move/battle_move_immunity_resolver.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/move/battle_move_registry.dart';
import '../domain/move/battle_move_secondary_effect_resolver.dart';
import '../domain/move/battle_move_type_processor.dart';
import '../domain/rng/battle_rng_streams.dart';
import '../domain/handler/battle_handler_context.dart';
import '../domain/handler/battle_stat_change_handler.dart';
import '../domain/handler/battle_switch_handler.dart';
import '../domain/handler/battle_terrain_change_handler.dart';
import '../domain/effect/battle_effect.dart';
import '../domain/effect/battle_effect_scope.dart';
import '../domain/effect/move/attract_effect.dart';
import '../domain/effect/move/bind_effect.dart';
import '../domain/effect/move/cant_switch_effect.dart';
import '../domain/effect/move/disable_effect.dart';
import '../domain/effect/move/encore_effect.dart';
import '../domain/effect/move/endure_effect.dart';
import '../domain/effect/move/force_next_move_base_effect.dart';
import '../domain/effect/move/heal_block_effect.dart';
import '../domain/effect/move/imprison_effect.dart';
import '../domain/effect/move/leech_seed_effect.dart';
import '../domain/effect/move/protect_effect.dart';
import '../domain/effect/move/taunt_effect.dart';
import '../domain/effect/move/torment_effect.dart';
import '../domain/effect/move/two_turn_charge_effect.dart';
import '../domain/effect/side/hazard_effects.dart';
import '../psdk/domain/psdk_battle_field.dart';
import '../psdk/domain/psdk_battle_combatant.dart';
import '../psdk/domain/psdk_battle_move.dart';
import '../psdk/domain/psdk_battle_slots.dart';
import '../psdk/domain/psdk_battle_state.dart';
import '../psdk/domain/psdk_battle_timeline.dart';

BattleMoveRegistry createStaticBasicMoveRegistry() {
  return BattleMoveRegistry(<BattleMoveBehavior>[
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_basic',
      resolve: _resolveBasic,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_z_move',
      resolve: _resolveBasic,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_2turns',
      resolve: _resolveTwoTurns,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_sky_drop',
      resolve: _resolveTwoTurns,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_substitute',
      resolve: _resolveSubstitute,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_add_type',
      resolve: _resolveAddType,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_change_type',
      resolve: _resolveChangeType,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_foresight',
      resolve: _resolveForesight,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_stockpile',
      resolve: _resolveStockpile,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_lock_on',
      resolve: _resolveLockOn,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_mind_reader',
      resolve: _resolveLockOn,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_memento',
      resolve: _resolveMemento,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_make_it_rain',
      resolve: _resolveBasicThenSelfStages,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_last_resort',
      resolve: _resolveLastResort,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_photon_geyser',
      resolve: _resolvePhotonGeyser,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_pollen_puff',
      resolve: _resolvePollenPuff,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_pursuit',
      resolve: _resolvePursuit,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_thing_sport',
      resolve: _resolveThingSport,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_trick',
      resolve: _resolveTrick,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_plasma_fists',
      resolve: _resolvePlasmaFists,
    ),
    for (final method in _partialAbilityChangingMethods.keys)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveAbilityChanging,
      ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_reflect_type',
      resolve: _resolveReflectType,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_attract',
      resolve: _resolveAttract,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_bind',
      resolve: _resolveBind,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_brick_break',
      resolve: _resolveBrickBreak,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_raging_bull',
      resolve: _resolveBrickBreak,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_baddy_bad',
      resolve: _resolveScreenSettingHit,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_feint',
      resolve: _resolveFeint,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_fell_stinger',
      resolve: _resolveFellStinger,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_flame_burst',
      resolve: _resolveFlameBurst,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_fusion_bolt',
      resolve: _resolveFusionMove,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_fusion_flare',
      resolve: _resolveFusionMove,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_freezy_frost',
      resolve: _resolveFreezyFrost,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_eerie_spell',
      resolve: _resolveEerieSpell,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_electro_shot',
      resolve: _resolveElectroShot,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_fickle_beam',
      resolve: _resolveFickleBeam,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_glitzy_glow',
      resolve: _resolveScreenSettingHit,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_grav_apple',
      resolve: _resolveGravApple,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_glaive_rush',
      resolve: _resolveGlaiveRush,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_last_respects',
      resolve: _resolveLastRespects,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_shell_side_arm',
      resolve: _resolveShellSideArm,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_magnitude',
      resolve: _resolveMagnitude,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_present',
      resolve: _resolvePresent,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_triple_arrows',
      resolve: _resolveTripleArrows,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_poltergeist',
      resolve: _resolvePoltergeist,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_stomp',
      resolve: _resolveStomp,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_super_duper_effective',
      resolve: _resolveSuperDuperEffective,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_jump_kick',
      resolve: _resolveJumpKick,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_ice_spinner',
      resolve: _resolveTerrainClearingHit,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_sappy_seed',
      resolve: _resolveSappySeed,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_steel_roller',
      resolve: _resolveTerrainClearingHit,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_u_turn',
      resolve: _resolveUTurn,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_volt_switch',
      resolve: _resolveUTurn,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_flip_turn',
      resolve: _resolveUTurn,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_cantflee',
      resolve: _resolveCantFlee,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_jaw_lock',
      resolve: _resolveJawLock,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_disable',
      resolve: _resolveDisable,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_encore',
      resolve: _resolveEncore,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_heal_block',
      resolve: _resolveHealBlock,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_stone_axe',
      resolve: _resolveHazardSettingBasic,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_ceaseless_edge',
      resolve: _resolveHazardSettingBasic,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_rapid_spin',
      resolve: _resolveRapidSpin,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_rage',
      resolve: _resolveRage,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_defog',
      resolve: _resolveDefog,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_dragon_tail',
      resolve: _resolveForceSwitch,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_imprison',
      resolve: _resolveImprison,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_roar',
      resolve: _resolveForceSwitch,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_parting_shot',
      resolve: _resolvePartingShot,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_spectral_thief',
      resolve: _resolveSpectralThief,
    ),
    const ActionGatedMoveBehavior.snore(),
    const ActionGatedMoveBehavior.suckerPunch(),
    const ActionGatedMoveBehavior.fakeOut(),
    const FieldLocationMoveBehavior.camouflage(),
    const FieldLocationMoveBehavior.naturePower(),
    for (final method in _partialTargetMarkerMethods.keys)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveTargetMarker,
      ),
    for (final method in _partialUserBankMarkerMethods.keys)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveUserBankMarker,
      ),
    for (final method in _partialFoeBankMarkerMethods.keys)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveFoeBankMarker,
      ),
    for (final method in _partialFieldMarkerMethods.keys)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveFieldMarker,
      ),
    for (final method in _partialSecondaryOnlyMethods)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveSecondaryOnly,
      ),
    for (final method in _partialBasicDescendantMethods)
      CallbackBattleMoveBehavior(
        battleEngineMethod: method,
        resolve: _resolveBasic,
      ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_reload',
      resolve: _resolveReload,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_reflect',
      resolve: _resolveReflect,
    ),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_follow_me',
      resolve: _resolveFollowMe,
    ),
    const StatusStatMoveBehavior.status(),
    const StatusStatMoveBehavior.stat(),
    const StatusStatMoveBehavior.selfStat(),
    const StatusStatMoveBehavior.selfStatus(),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_protect',
      resolve: _resolveProtect,
    ),
    const FixedDamageMoveBehavior.psdkFixedDamage(),
    const FixedDamageMoveBehavior.userLevel(),
    const FixedDamageMoveBehavior.psywave(),
    const FixedDamageMoveBehavior.halfCurrentTargetHp(),
    const MultiHitMoveBehavior.fixed(
      battleEngineMethod: 's_2hits',
      hitCount: 2,
    ),
    const MultiHitMoveBehavior.fixed(
      battleEngineMethod: 's_3hits',
      hitCount: 3,
    ),
    const MultiHitMoveBehavior.psdkRandom(),
    const MultiHitMoveBehavior.doubleIronBash(),
    const MultiHitMoveBehavior.tripleKick(),
    const MultiHitMoveBehavior.populationBomb(),
    const MultiHitMoveBehavior.waterShuriken(),
    const MultiHitMoveBehavior.scaleShot(),
    const BasicDamageSpecializationMoveBehavior.fangs(),
    const BasicDamageSpecializationMoveBehavior.falseSwipe(),
    const BasicDamageSpecializationMoveBehavior.fullCrit(),
    const NoEffectMoveBehavior.doNothing(),
    const NoEffectMoveBehavior.splash(),
    const OhkoMoveBehavior(),
    const DirectHpMoveBehavior.endeavor(),
    const DirectHpMoveBehavior.finalGambit(),
    const DirectHpMoveBehavior.painSplit(),
    const DrainMoveBehavior.absorb(),
    const DrainMoveBehavior.dreamEater(),
    const HealMoveBehavior(),
    const HealMoveBehavior.weather(),
    const HealMoveBehavior.floralHealing(),
    const HealMoveBehavior.roost(),
    const HealMoveBehavior.shoreUp(),
    const HealMoveBehavior.lifeDew(),
    const HealMoveBehavior.jungleHealing(),
    const HitThenCureStatusMoveBehavior.smellingSalt(),
    const HitThenCureStatusMoveBehavior.wakeUpSlap(),
    const HitThenCureStatusMoveBehavior.sparklingAria(),
    const HistoryPowerMoveBehavior.assurance(),
    const HistoryPowerMoveBehavior.avalanche(),
    const HistoryPowerMoveBehavior.fishiousRend(),
    const HistoryPowerMoveBehavior.lashOut(),
    const HistoryPowerMoveBehavior.payback(),
    const HistoryPowerMoveBehavior.rageFist(),
    const HistoryPowerMoveBehavior.retaliate(),
    const HistoryPowerMoveBehavior.revenge(),
    const HistoryPowerMoveBehavior.stompingTantrum(),
    const PsychoShiftMoveBehavior(),
    const PurifyMoveBehavior(),
    const StatusCureMoveBehavior.healBell(),
    const StatusCureMoveBehavior.takeHeart(),
    const StatusCureMoveBehavior.sparklySwirl(),
    const RecoveryStatMoveBehavior.rest(),
    const RecoveryStatMoveBehavior.bellyDrum(),
    const RecoveryStatMoveBehavior.filletAway(),
    const RecoveryStatMoveBehavior.strengthSap(),
    const PersistentEffectMoveBehavior.aquaRing(),
    const PersistentEffectMoveBehavior.ingrain(),
    const PersistentEffectMoveBehavior.leechSeed(),
    const AdvancedStatMoveBehavior.acupressure(),
    const AdvancedStatMoveBehavior.clangorousSoul(),
    const AdvancedStatMoveBehavior.curse(),
    const AdvancedStatMoveBehavior.growth(),
    const AdvancedStatMoveBehavior.guardSwap(),
    const AdvancedStatMoveBehavior.haze(),
    const AdvancedStatMoveBehavior.heartSwap(),
    const AdvancedStatMoveBehavior.powerSwap(),
    const AdvancedStatMoveBehavior.psychUp(),
    const AdvancedStatMoveBehavior.topsyTurvy(),
    const StatSplitMoveBehavior.power(),
    const StatSplitMoveBehavior.guard(),
    const PowerTrickMoveBehavior(),
    const SpeedSwapMoveBehavior(),
    const SwitchEffectMoveBehavior.batonPass(),
    const SpecialPowerMoveBehavior.acrobatics(),
    const SpecialPowerMoveBehavior.storedPower(),
    const MindBlownMoveBehavior.mindBlown(),
    const MindBlownMoveBehavior.steelBeam(),
    const MindBlownMoveBehavior.chloroblast(),
    const SelfDestructMoveBehavior.explosion(),
    const SelfDestructMoveBehavior.mistyExplosion(),
    const WeatherMoveBehavior(),
    const TerrainMoveBehavior(),
    const TerrainPowerMoveBehavior.terrainBoosting(),
    const TerrainPowerMoveBehavior.expandingForce(),
    const TerrainPowerMoveBehavior.grassyGlide(),
    const TerrainPowerMoveBehavior.risingVoltage(),
    const TerrainPowerMoveBehavior.terrainPulse(),
    const WeatherPowerMoveBehavior.weatherBall(),
    const WeatherPowerMoveBehavior.thunder(),
    const WeatherPowerMoveBehavior.hurricane(),
    const WeatherPowerMoveBehavior.geniesStorm(),
    const WeatherPowerMoveBehavior.solarBeam(),
    const ConsecutivePowerMoveBehavior.echoedVoice(),
    const ConsecutivePowerMoveBehavior.furyCutter(),
    const ConsecutivePowerMoveBehavior.rollout(),
    const ConsecutivePowerMoveBehavior.iceBall(),
    const ConsecutivePowerMoveBehavior.trumpCard(),
    const CounterDamageMoveBehavior.counter(),
    const CounterDamageMoveBehavior.mirrorCoat(),
    const CounterDamageMoveBehavior.metalBurst(),
    const CounterDamageMoveBehavior.bide(),
    const ItemDependentMoveBehavior.belch(),
    const ItemDependentMoveBehavior.bestow(),
    const ItemDependentMoveBehavior.fling(),
    const ItemDependentMoveBehavior.knockOff(),
    const ItemDependentMoveBehavior.naturalGift(),
    const ItemDependentMoveBehavior.pluck(),
    const ItemDependentMoveBehavior.recycle(),
    const ItemDependentMoveBehavior.technoBlast(),
    const ItemDependentMoveBehavior.thief(),
    const ForcedActionMoveBehavior.gigatonHammer(),
    const ForcedActionMoveBehavior.thrash(),
    const ForcedActionMoveBehavior.outrage(),
    const ForcedActionMoveBehavior.uproar(),
    const GroundingMoveBehavior.smackDown(),
    const FieldLocationMoveBehavior.pledge(),
    const FieldLocationMoveBehavior.secretPower(),
    const FieldLocationMoveBehavior.synchronoise(),
    const SpecialSecondaryMoveBehavior.alluringVoice(),
    const SpecialSecondaryMoveBehavior.burnUp(),
    const SpecialSecondaryMoveBehavior.burningJealousy(),
    const SpecialSecondaryMoveBehavior.incinerate(),
    const SpecialSecondaryMoveBehavior.psychicNoise(),
    const SpecialSecondaryMoveBehavior.relicSong(),
    const SpecialSecondaryMoveBehavior.saltCure(),
    const SpecialSecondaryMoveBehavior.syrupBomb(),
    const SpecialSecondaryMoveBehavior.tarShot(),
    const SpecialSecondaryMoveBehavior.throatChop(),
    const SpecialSecondaryMoveBehavior.triAttack(),
    const TransformMoveBehavior(),
    const RecoilMoveBehavior.psdkRecoil(),
    const RecoilMoveBehavior.struggle(),
    const VariablePowerMoveBehavior.brine(),
    const VariablePowerMoveBehavior.eruption(),
    const VariablePowerMoveBehavior.flail(),
    const VariablePowerMoveBehavior.wringOut(),
    const VariablePowerMoveBehavior.hardPress(),
    const VariablePowerMoveBehavior.electroBall(),
    const VariablePowerMoveBehavior.gyroBall(),
    const VariablePowerMoveBehavior.facade(),
    const VariablePowerMoveBehavior.infernalParade(),
    const VariablePowerMoveBehavior.bitterMalice(),
    const VariablePowerMoveBehavior.hex(),
    const VariablePowerMoveBehavior.venoshock(),
    const WeightPowerMoveBehavior.lowKick(),
    const WeightPowerMoveBehavior.heavySlam(),
    const CustomStatSourceMoveBehavior.bodyPress(),
    const CustomStatSourceMoveBehavior.foulPlay(),
    const CustomStatSourceMoveBehavior.psyshock(),
    const CustomStatSourceMoveBehavior.customStatsBased(),
    const CustomStatSourceMoveBehavior.sacredSword(),
    const TypeBasedMoveBehavior.ivyCudgel(),
    const TypeBasedMoveBehavior.judgment(),
    const TypeBasedMoveBehavior.multiAttack(),
    const TypeBasedMoveBehavior.revelationDance(),
  ]);
}

const _partialBasicDescendantMethods = <String>[
  's_beak_blast',
  's_beat_up',
  's_core_enforcer',
  's_flying_press',
  's_focus_punch',
  's_frustration',
  's_genesis_supernova',
  's_guardian_of_alola',
  's_hidden_power',
  's_hyperspace_hole',
  's_light_that_burns_the_sky',
  's_malicious_moonsault',
  's_payday',
  's_return',
  's_round',
  's_shell_trap',
  's_split_up',
  's_splintered_stormshards',
  's_aura_wheel',
  's_dragon_darts',
  's_order_up',
  's_pre_attack_base',
  's_upper_hand',
];

const _partialTargetMarkerMethods = <String, String>{
  's_after_you': 'after_you',
  's_ally_switch': 'ally_switch',
  's_assist': 'assist',
  's_autotomize': 'autotomize',
  's_charge': 'charge',
  's_conversion': 'conversion',
  's_conversion2': 'conversion2',
  's_corrosive_gas': 'corrosive_gas',
  's_doodle': 'doodle',
  's_destiny_bond': 'destiny_bond',
  's_electrify': 'electrify',
  's_embargo': 'embargo',
  's_focus_energy': 'focus_energy',
  's_gastro_acid': 'ability_suppressed',
  's_future_sight': 'future_sight',
  's_grudge': 'grudge',
  's_healing_wish': 'healing_wish',
  's_instruct': 'instruct',
  's_laser_focus': 'laser_focus',
  's_lunar_dance': 'lunar_dance',
  's_magic_coat': 'magic_coat',
  's_magic_powder': 'magic_powder',
  's_magnet_rise': 'magnet_rise',
  's_me_first': 'me_first',
  's_metronome': 'metronome',
  's_mimic': 'mimic',
  's_minimize': 'minimize',
  's_miracle_eye': 'miracle_eye',
  's_mirror_move': 'mirror_move',
  's_nightmare': 'nightmare',
  's_octolock': 'octolock',
  's_perish_song': 'perish_song',
  's_powder': 'powder',
  's_quash': 'quash',
  's_revival_blessing': 'revival_blessing',
  's_sketch': 'sketch',
  's_sleep_talk': 'sleep_talk',
  's_snatch': 'snatch',
  's_spite': 'spite',
  's_swallow': 'swallow',
  's_taunt': 'taunt',
  's_telekinesis': 'telekinesis',
  's_teleport': 'teleport',
  's_torment': 'torment',
  's_yawn': 'drowsiness',
};

const _gastroAcidProtectedAbilityIds = <String>{
  'as_one',
  'battle_bond',
  'comatose',
  'commander',
  'disguise',
  'gulp_missile',
  'hadron_engine',
  'hunger_switch',
  'ice_face',
  'imposter',
  'multitype',
  'orichalcum_pulse',
  'power_construct',
  'protosynthesis',
  'quark_drive',
  'rks_system',
  'schooling',
  'shields_down',
  'stance_change',
  'wonder_guard',
  'zen_mode',
  'zero_to_hero',
};

const _partialAbilityChangingMethods = <String, String>{
  's_entrainment': 'entrainment',
  's_role_play': 'role_play',
  's_simple_beam': 'simple',
  's_skill_swap': 'skill_swap',
  's_worry_seed': 'insomnia',
};

const _partialUserBankMarkerMethods = <String, String>{
  's_crafty_shield': 'crafty_shield',
  's_flower_shield': 'flower_shield',
  's_gear_up': 'gear_up',
  's_dragon_cheer': 'dragon_cheer',
  's_geomancy': 'geomancy',
  's_helping_hand': 'helping_hand',
  's_lucky_chant': 'lucky_chant',
  's_magnetic_flux': 'magnetic_flux',
  's_mist': 'mist',
  's_no_retreat': 'no_retreat',
  's_rototiller': 'rototiller',
  's_safe_guard': 'safeguard',
  's_shed_tail': 'shed_tail',
  's_stuff_cheeks': 'stuff_cheeks',
  's_tailwind': 'tailwind',
  's_tidy_up': 'tidy_up',
  's_wish': 'wish',
};

const _partialFoeBankMarkerMethods = <String, String>{
  's_spike': 'spikes',
  's_stealth_rock': 'stealth_rock',
  's_sticky_web': 'sticky_web',
  's_toxic_spike': 'toxic_spikes',
};

const _partialFieldMarkerMethods = <String, String>{
  's_chilly_reception': 'chilly_reception',
  's_court_change': 'court_change',
  's_fairy_lock': 'fairy_lock',
  's_gravity': 'gravity',
  's_happy_hour': 'happy_hour',
  's_ion_deluge': 'ion_deluge',
  's_magic_room': 'magic_room',
  's_teatime': 'teatime',
  's_trick_room': 'trick_room',
  's_wonder_room': 'wonder_room',
};

const _partialSecondaryOnlyMethods = <String>[
  's_captivate',
  's_self_stat_z_move',
  's_toxic_thread',
  's_venom_drench',
];

const _unencorableMoveIds = <String>{
  'encore',
  'mimic',
  'mirror_move',
  'sketch',
  'struggle',
  'transform',
};

BattleMoveBehaviorResolution _resolveBasic(BattleMoveBehaviorContext context) {
  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final targetSlot = common.psdkTargets.single;
  final user = common.state.battlerAt(context.user);
  final target = common.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: common.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: common.state,
      rng: damageResult.rng,
      events: common.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: common.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );

  final applied = applyDirectDamage(
    state: common.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...common.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

int _screenAdjustedDamage({
  required PsdkBattleState state,
  required PsdkBattleCombatant user,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
  required int damage,
  required bool isCritical,
}) {
  if (damage <= 1 ||
      isCritical ||
      _normalizedId(user.abilityId) == 'infiltrator') {
    return damage;
  }
  final screenId = switch (move.category) {
    PsdkBattleMoveCategory.physical => 'reflect',
    PsdkBattleMoveCategory.special => 'light_screen',
    PsdkBattleMoveCategory.status => null,
  };
  if (screenId == null) {
    return damage;
  }
  final hasScreen = _bankHasEffect(state, target.bank, screenId) ||
      _bankHasEffect(state, target.bank, 'aurora_veil');
  if (!hasScreen) {
    return damage;
  }
  final reduced = damage ~/ 2;
  return reduced < 1 ? 1 : reduced;
}

BattleMoveBehaviorResolution _resolveAbilityChanging(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = context.target;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final nextState = switch (context.move.battleEngineMethod) {
    's_role_play' => prepared.state.updateBattler(
        context.user,
        (battler) => battler
            .copyWith(abilityId: target.abilityId)
            .withAbilityEffect(context.user),
      ),
    's_entrainment' => prepared.state.updateBattler(
        targetSlot,
        (battler) => battler
            .copyWith(abilityId: user.abilityId)
            .withAbilityEffect(targetSlot),
      ),
    's_skill_swap' => prepared.state
        .updateBattler(
          context.user,
          (battler) => battler
              .copyWith(abilityId: target.abilityId)
              .withAbilityEffect(context.user),
        )
        .updateBattler(
          targetSlot,
          (battler) => battler
              .copyWith(abilityId: user.abilityId)
              .withAbilityEffect(targetSlot),
        ),
    final method => prepared.state.updateBattler(
        targetSlot,
        (battler) => battler
            .copyWith(abilityId: _partialAbilityChangingMethods[method])
            .withAbilityEffect(targetSlot),
      ),
  };

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: prepared.rng,
    events: prepared.events,
  );
}

BattleMoveBehaviorResolution _resolveRapidSpin(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .any((event) => event.moveId == context.move.id);
  if (!hit) {
    return basic;
  }

  final cleaned = _clearRapidSpinAffectedEffects(
    state: basic.state,
    user: context.user,
    includeAllBanks: false,
    clearOpposingScreens: false,
  );
  final boosted = const BattleStatChangeHandler().applyStatChange(
    context: BattleHandlerContext(
      state: cleaned,
      rng: basic.rng,
      turn: context.turn,
      user: context.user,
    ),
    target: context.user,
    stat: 'speed',
    stages: 1,
  );
  return BattleMoveBehaviorResolution(
    state: boosted.state,
    rng: boosted.rng,
    events: <PsdkBattleEvent>[
      ...basic.events,
      ...boosted.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveLastResort(
  BattleMoveBehaviorContext context,
) {
  final user = context.state.battlerAt(context.user);
  final currentMoveId = _normalizedId(context.move.id);
  final otherMoveIds = user.moves
      .map((move) => _normalizedId(move.id))
      .where((moveId) => moveId.isNotEmpty && moveId != currentMoveId)
      .toSet();
  final usedMoveIds = user.moveHistory.usedMoveIds
      .map(_normalizedId)
      .where((moveId) => moveId.isNotEmpty)
      .toSet();
  final requirementsMet =
      otherMoveIds.isNotEmpty && usedMoveIds.containsAll(otherMoveIds);
  if (!requirementsMet) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      successful: false,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: 'last_resort_requirements_unmet',
        ),
      ],
    );
  }

  return _resolveBasic(context);
}

BattleMoveBehaviorResolution _resolvePhotonGeyser(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final usePhysical =
      user.effectiveStat('attack') > user.effectiveStat('specialAttack');
  final chosenMove = BattleMoveDefinition.fromPsdk(
    context.move.psdkMove.copyWith(
      category: usePhysical
          ? PsdkBattleMoveCategory.physical
          : PsdkBattleMoveCategory.special,
    ),
  );
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: chosenMove,
      rng: prepared.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: chosenMove,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );

  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: chosenMove,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolvePollenPuff(
  BattleMoveBehaviorContext context,
) {
  if (context.target.bank != context.user.bank ||
      context.target == context.user) {
    return _resolveBasic(context);
  }

  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = context.target;
  final target = prepared.state.battlerAt(targetSlot);
  final healed = applyDirectHeal(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: prepared.rng,
    turn: context.turn,
    amount: target.maxHp ~/ 2,
  );

  return BattleMoveBehaviorResolution(
    state: healed.state,
    rng: healed.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (healed.event != null) healed.event!,
    ],
  );
}

BattleMoveBehaviorResolution _resolveRage(BattleMoveBehaviorContext context) {
  final basic = _resolveBasic(context);
  final hit = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .any((event) => event.moveId == context.move.id);
  if (!hit || basic.state.battlerAt(context.user).effects.contains('rage')) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          GenericBattleEffect(
            id: 'rage',
            scope: BattlerBattleEffectScope(context.user),
          ),
        ),
      ),
    ),
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveGlaiveRush(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .any((event) => event.moveId == context.move.id);
  if (!hit ||
      basic.state.battlerAt(context.user).effects.contains('glaive_rush')) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          GenericBattleEffect(
            id: 'glaive_rush',
            scope: BattlerBattleEffectScope(context.user),
            remainingTurns: 2,
          ),
        ),
      ),
    ),
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolvePursuit(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final target = prepared.state.battlerAt(targetSlot);
  final boosted = target.switching && target.lastSentTurn != context.turn;
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: prepared.state.battlerAt(context.user),
      target: target,
      move: context.move,
      rng: prepared.rng,
      overrides: boosted
          ? BattleMoveDamageOverrides(power: context.move.power * 2)
          : null,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }

  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damageResult.damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveFlameBurst(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final primaryDamageEvents =
      basic.events.whereType<PsdkBattleDamageEvent>().where(
            (event) => event.moveId == context.move.id,
          );
  if (primaryDamageEvents.isEmpty) {
    return basic;
  }

  var state = basic.state;
  var rng = basic.rng;
  final events = <PsdkBattleEvent>[...basic.events];
  for (final primary in primaryDamageEvents) {
    for (final splashTarget in state.adjacentAlliesOf(primary.target)) {
      final battler = state.battlerAt(splashTarget);
      if (_normalizedId(battler.abilityId) == 'magic_guard' &&
          !battler.effects.contains('ability_suppressed')) {
        continue;
      }
      final splashDamage = (battler.maxHp ~/ 16).clamp(
        1,
        battler.currentHp,
      );
      final applied = applyDirectDamage(
        state: state,
        user: context.user,
        target: splashTarget,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: splashDamage,
      );
      state = applied.state;
      rng = applied.rng;
      if (applied.event != null) {
        events.add(applied.event!);
      }
    }
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    events: events,
  );
}

BattleMoveBehaviorResolution _resolveFusionMove(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final boosted = _sameTurnFusionCounterpartSucceeded(
    state: prepared.state,
    user: context.user,
    turn: context.turn,
    method: context.move.battleEngineMethod,
  );
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: prepared.state.battlerAt(context.user),
      target: prepared.state.battlerAt(targetSlot),
      move: context.move,
      rng: prepared.rng,
      overrides: boosted
          ? BattleMoveDamageOverrides(power: context.move.power * 2)
          : null,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }

  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damageResult.damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

bool _sameTurnFusionCounterpartSucceeded({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required int turn,
  required String method,
}) {
  final counterpart = switch (method) {
    's_fusion_bolt' => 'fusion_flare',
    's_fusion_flare' => 'fusion_bolt',
    _ => '',
  };
  if (counterpart.isEmpty) {
    return false;
  }

  return state.foesOf(user).any((slot) {
    final successes = state.battlerAt(slot).moveHistory.successes;
    if (successes.isEmpty) {
      return false;
    }
    final lastSuccess = successes.last;
    return lastSuccess.turn == turn &&
        _normalizedId(lastSuccess.moveId) == counterpart;
  });
}

BattleMoveBehaviorResolution _resolveBrickBreak(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == context.move.id)
      .toList(growable: false);
  if (hit.isEmpty) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: _clearScreenEffects(
      state: basic.state,
      targetBank: hit.first.target.bank,
    ),
    rng: basic.rng,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveSpectralThief(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().where(
        (event) => event.moveId == context.move.id,
      );
  if (hit.isEmpty) {
    return basic;
  }

  final targetSlot = hit.first.target;
  final target = basic.state.battlerAt(targetSlot);
  final stolenStages = Map<String, int>.fromEntries(
    target.statStages.values.entries.where((entry) => entry.value > 0),
  );
  if (stolenStages.isEmpty) {
    return basic;
  }

  var userStages = Map<String, int>.from(
    basic.state.battlerAt(context.user).statStages.values,
  );
  final targetStages = Map<String, int>.from(target.statStages.values);
  for (final entry in stolenStages.entries) {
    userStages[entry.key] = entry.value;
    targetStages.remove(entry.key);
  }

  var nextState = basic.state.updateBattler(
    context.user,
    (battler) => battler.copyWith(
      statStages: PsdkBattleStatStages(values: userStages),
    ),
  );
  nextState = nextState.updateBattler(
    targetSlot,
    (battler) => battler.copyWith(
      statStages: PsdkBattleStatStages(values: targetStages),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveBasicThenSelfStages(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(
    BattleMoveBehaviorContext(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      user: context.user,
      target: context.target,
      move: BattleMoveDefinition.fromPsdk(
        context.move.psdkMove.copyWith(
          stageMods: const <PsdkBattleMoveStageMod>[],
        ),
      ),
      isLastActionOfTurn: context.isLastActionOfTurn,
      moveProcedureHooks: context.moveProcedureHooks,
    ),
  );
  final hit = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .any((event) => event.moveId == context.move.id);
  if (!hit) {
    return basic;
  }

  var state = basic.state;
  var rng = basic.rng;
  final events = <PsdkBattleEvent>[...basic.events];
  for (final mod in context.move.stageMods) {
    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.user,
      stat: mod.stat,
      stages: mod.stages,
    );
    state = changed.state;
    rng = changed.rng;
    events.addAll(changed.events);
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    successful: basic.successful,
    events: events,
  );
}

BattleMoveBehaviorResolution _resolveScreenSettingHit(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) => event.moveId == context.move.id,
      );
  if (!hit) {
    return basic;
  }

  final effectId = switch (context.move.battleEngineMethod) {
    's_baddy_bad' => 'reflect',
    _ => 'light_screen',
  };
  if (_bankHasEffect(basic.state, context.user.bank, effectId)) {
    return basic;
  }

  final user = basic.state.battlerAt(context.user);
  final duration =
      _normalizedId(user.heldItemId) == 'light_clay' && !user.itemConsumed
          ? 8
          : 5;
  return _addEffectToUser(
    context: context,
    state: basic.state,
    rng: basic.rng,
    events: basic.events,
    effect: GenericBattleEffect(
      id: effectId,
      scope: BattlerBattleEffectScope(context.user),
      remainingTurns: duration,
    ),
  );
}

BattleMoveBehaviorResolution _resolveFeint(BattleMoveBehaviorContext context) {
  final prepared = prepareBattleMove(
    context,
    targetPrecheck: (execution, targets) {
      return const BattleMoveImmunityResolver().precheck(
        execution,
        targets,
        ignoreProtect: true,
      );
    },
  );
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: prepared.rng,
      overrides: _targetProtectedThisTurn(target, context.turn)
          ? const BattleMoveDamageOverrides(power: 50)
          : null,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );
  final lifted = secondary.state.updateBattler(
    targetSlot,
    (battler) => battler.copyWith(
      effects: battler.effects.remove('protect').remove('crafty_shield'),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: lifted,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveFellStinger(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final knockedOutTarget = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) =>
            event.moveId == context.move.id &&
            basic.state.battlerAt(event.target).isFainted,
      );
  if (!knockedOutTarget) {
    return basic;
  }

  final boosted = const BattleStatChangeHandler().applyStatChange(
    context: BattleHandlerContext(
      state: basic.state,
      rng: basic.rng,
      turn: context.turn,
      user: context.user,
    ),
    target: context.user,
    stat: 'attack',
    stages: 3,
  );

  return BattleMoveBehaviorResolution(
    state: boosted.state,
    rng: boosted.rng,
    successful: basic.successful,
    events: <PsdkBattleEvent>[
      ...basic.events,
      ...boosted.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveFreezyFrost(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) => event.moveId == context.move.id,
      );
  if (!hit) {
    return basic;
  }

  var state = basic.state;
  for (final slot in state.aliveSlots()) {
    final battler = state.battlerAt(slot);
    if (battler.statStages.values.isEmpty) {
      continue;
    }
    state = state.updateBattler(
      slot,
      (current) => current.copyWith(
        statStages: PsdkBattleStatStages.neutral(),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolvePoltergeist(
  BattleMoveBehaviorContext context,
) {
  final target = context.state.battlerAt(context.target);
  if (target.heldItemId == null) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: 'no_held_item',
        ),
      ],
      successful: false,
    );
  }

  return _resolveBasic(context);
}

BattleMoveBehaviorResolution _resolveSappySeed(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) => event.moveId == context.move.id,
      );
  if (!hit) {
    return basic;
  }

  final targetSlot = context.target;
  final target = basic.state.battlerAt(targetSlot);
  if (target.isFainted ||
      target.hasType('grass') ||
      target.effects.contains('leech_seed') ||
      target.effects.contains('substitute')) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          LeechSeedEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            source: context.user,
          ),
        ),
      ),
    ),
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveStomp(BattleMoveBehaviorContext context) {
  final isMinimized = context.state.battlerAt(context.target).effects.contains(
        'minimize',
      );
  final prepared = prepareBattleMove(
    context,
    forceAccuracyBypass: isMinimized,
  );
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: prepared.rng,
      overrides: isMinimized
          ? BattleMoveDamageOverrides(power: context.move.power * 2)
          : null,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveGravApple(
  BattleMoveBehaviorContext context,
) {
  final gravityActive = _isGravityActive(context.state);
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: prepared.rng,
      overrides: gravityActive
          ? BattleMoveDamageOverrides(power: (context.move.power * 3) ~/ 2)
          : null,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

bool _isGravityActive(PsdkBattleState state) {
  return state.combatants.values.any(
    (battler) => battler.effects.contains('gravity'),
  );
}

BattleMoveBehaviorResolution _resolveMagnitude(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final magnitudeRoll = prepared.rng.generic.nextPercent();
  final resolvedPower = _magnitudePowerForDice(magnitudeRoll.value - 1);
  final rngAfterMagnitude = prepared.rng.copyWith(generic: magnitudeRoll.next);
  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: rngAfterMagnitude,
      overrides: BattleMoveDamageOverrides(power: resolvedPower),
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolvePresent(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final powerRoll = prepared.rng.generic.nextPercent();
  final resolvedPower = _presentPowerForRoll(powerRoll.value);
  final rngAfterPower = prepared.rng.copyWith(generic: powerRoll.next);
  final targetSlot = prepared.psdkTargets.single;
  final target = prepared.state.battlerAt(targetSlot);
  if (resolvedPower == 0) {
    final healAmount = target.maxHp ~/ 4;
    if (healAmount <= 0 ||
        target.currentHp >= target.maxHp ||
        target.effects.contains('heal_block')) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: rngAfterPower,
        events: prepared.events,
      );
    }
    final healed = applyDirectHeal(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: rngAfterPower,
      turn: context.turn,
      amount: healAmount,
    );
    return BattleMoveBehaviorResolution(
      state: healed.state,
      rng: healed.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (healed.event != null) healed.event!,
      ],
    );
  }

  final user = prepared.state.battlerAt(context.user);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: rngAfterPower,
      overrides: BattleMoveDamageOverrides(power: resolvedPower),
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveTripleArrows(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) => event.moveId == context.move.id,
      );
  if (!hit) {
    return basic;
  }

  final user = basic.state.battlerAt(context.user);
  if (_tripleArrowsUnstackableEffects.any(user.effects.contains)) {
    return basic;
  }
  return _addEffectToUser(
    context: context,
    state: basic.state,
    rng: basic.rng,
    events: basic.events,
    effect: GenericBattleEffect(
      id: 'triple_arrows',
      scope: BattlerBattleEffectScope(context.user),
      remainingTurns: 4,
    ),
  );
}

BattleMoveBehaviorResolution _resolveFickleBeam(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final empoweredRoll = prepared.rng.generic.nextPercent();
  final empowered = empoweredRoll.value <= 30;
  final rngAfterEmpowerment =
      prepared.rng.copyWith(generic: empoweredRoll.next);
  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: rngAfterEmpowerment,
      overrides: empowered
          ? BattleMoveDamageOverrides(power: context.move.power * 2)
          : null,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveShellSideArm(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final physicalMove = BattleMoveDefinition.fromPsdk(
    context.move.psdkMove.copyWith(category: PsdkBattleMoveCategory.physical),
  );
  final specialMove = BattleMoveDefinition.fromPsdk(
    context.move.psdkMove.copyWith(category: PsdkBattleMoveCategory.special),
  );
  const calculator = BattleMoveDamageCalculator();
  final physicalResult = calculator.calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: physicalMove,
      rng: prepared.rng,
    ),
  );
  final specialResult = calculator.calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: specialMove,
      rng: prepared.rng,
    ),
  );
  final physicalDamage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: physicalMove,
    damage: physicalResult.damage,
    isCritical: physicalResult.isCritical,
  );
  final specialDamage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: specialMove,
    damage: specialResult.damage,
    isCritical: specialResult.isCritical,
  );
  final usePhysical = physicalDamage > specialDamage;
  final chosenMove = usePhysical ? physicalMove : specialMove;
  final chosenResult = usePhysical ? physicalResult : specialResult;
  final damage = usePhysical ? physicalDamage : specialDamage;
  if (damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: chosenResult.rng,
      events: prepared.events,
    );
  }

  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: chosenResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: chosenMove,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveElectroShot(
  BattleMoveBehaviorContext context,
) {
  final user = context.state.battlerAt(context.user);
  if (user.effects.contains(PsdkBattleEffectIds.twoTurnCharge)) {
    final releasedState = context.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.remove(PsdkBattleEffectIds.twoTurnCharge),
      ),
    );
    return _resolveBasic(
      BattleMoveBehaviorContext(
        state: releasedState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
    );
  }

  final prepared = prepareBattleMove(context, forceAccuracyBypass: true);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final boosted = const BattleStatChangeHandler().applyStatChange(
    context: BattleHandlerContext(
      state: prepared.state,
      rng: prepared.rng,
      turn: context.turn,
      user: context.user,
    ),
    target: context.user,
    stat: 'specialAttack',
    stages: 1,
  );
  final events = <PsdkBattleEvent>[
    ...prepared.events,
    ...boosted.events,
  ];
  if (!_isRainActive(boosted.state)) {
    return _addEffectToUser(
      context: context,
      state: boosted.state,
      rng: boosted.rng,
      events: events,
      effect: GenericBattleEffect(
        id: PsdkBattleEffectIds.twoTurnCharge,
        scope: BattlerBattleEffectScope(context.user),
      ),
    );
  }

  final targetSlot = prepared.psdkTargets.single;
  final boostedUser = boosted.state.battlerAt(context.user);
  final target = boosted.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: boostedUser,
      target: target,
      move: context.move,
      rng: boosted.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: boosted.state,
      rng: damageResult.rng,
      events: events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: boosted.state,
    user: boostedUser,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: boosted.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveEerieSpell(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hit = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .any((event) => event.moveId == context.move.id);
  if (!hit) {
    return basic;
  }

  final targetSlot = context.target;
  final target = basic.state.battlerAt(targetSlot);
  final lastMoveId = target.moveHistory.lastMoveId;
  if (lastMoveId == null) {
    return basic;
  }
  final moveIndex = target.moves.indexWhere((move) => move.id == lastMoveId);
  if (moveIndex < 0) {
    return basic;
  }
  final move = target.moves[moveIndex];
  if (move.currentPp <= 0) {
    return basic;
  }
  final ppLoss = move.currentPp < 3 ? move.currentPp : 3;

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      targetSlot,
      (battler) => battler.replaceMoveAt(
        moveIndex,
        move.spendPp(ppLoss),
      ),
    ),
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveLastRespects(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final multiplier = (user.koCount + 1).clamp(1, 101).toInt();
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: prepared.rng,
      overrides: BattleMoveDamageOverrides(
        power: context.move.power * multiplier,
      ),
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveSuperDuperEffective(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: prepared.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final baseDamage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final superEffective = const BattleMoveTypeProcessor()
          .resolveEffectiveness(
            moveType: context.move.type,
            targetTypes: target.types,
            forceGrounded: target.effects.contains('smack_down'),
          )
          .multiplier >
      1.0;
  final damage = superEffective ? (baseDamage * 5461) ~/ 4096 : baseDamage;
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

int _magnitudePowerForDice(int dice) {
  if (dice < 5) {
    return 10;
  }
  if (dice < 15) {
    return 30;
  }
  if (dice < 35) {
    return 50;
  }
  if (dice < 65) {
    return 70;
  }
  if (dice < 85) {
    return 90;
  }
  if (dice < 95) {
    return 110;
  }
  return 150;
}

int _presentPowerForRoll(int roll) {
  if (roll <= 40) {
    return 40;
  }
  if (roll <= 70) {
    return 80;
  }
  if (roll <= 80) {
    return 120;
  }
  return 0;
}

const _tripleArrowsUnstackableEffects = <String>{
  'dragon_cheer',
  'focus_energy',
  'triple_arrows',
};

BattleMoveBehaviorResolution _resolveUTurn(BattleMoveBehaviorContext context) {
  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) =>
            event.moveId == context.move.id && event.target != context.user,
      );
  if (!hit) {
    return basic;
  }

  final switching = const BattleSwitchHandler().markSwitching(
    context: BattleHandlerContext(
      state: basic.state,
      rng: basic.rng,
      turn: context.turn,
      user: context.user,
    ),
    target: context.user,
    switching: true,
  );
  return BattleMoveBehaviorResolution(
    state: switching.state,
    rng: switching.rng,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveJumpKick(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    if (_shouldJumpKickCrash(prepared.failureReason)) {
      return _crashUserForJumpKick(
        context: context,
        state: prepared.state,
        rng: prepared.rng,
        events: prepared.events,
        successful: false,
      );
    }
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: prepared.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return _crashUserForJumpKick(
      context: context,
      state: prepared.state,
      rng: damageResult.rng,
      events: prepared.events,
    );
  }
  final damage = _screenAdjustedDamage(
    state: prepared.state,
    user: user,
    target: targetSlot,
    move: context.move,
    damage: damageResult.damage,
    isCritical: damageResult.isCritical,
  );
  final applied = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveTerrainClearingHit(
  BattleMoveBehaviorContext context,
) {
  if (context.move.battleEngineMethod == 's_steel_roller' &&
      context.state.field.terrain == null) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: 'no_terrain',
        ),
      ],
      successful: false,
    );
  }

  final basic = _resolveBasic(context);
  final hit = basic.events.whereType<PsdkBattleDamageEvent>().any(
        (event) => event.moveId == context.move.id,
      );
  if (!hit || basic.state.field.terrain == null) {
    return basic;
  }

  final cleared = const BattleTerrainChangeHandler().clearTerrain(
    context: BattleHandlerContext(
      state: basic.state,
      rng: basic.rng,
      turn: context.turn,
      user: context.user,
    ),
    reason: context.move.id,
  );
  return BattleMoveBehaviorResolution(
    state: cleared.state,
    rng: cleared.rng,
    events: <PsdkBattleEvent>[
      ...basic.events,
      ...cleared.events,
    ],
    successful: basic.successful,
  );
}

bool _shouldJumpKickCrash(BattleMoveFailureReason? reason) {
  return switch (reason) {
    BattleMoveFailureReason.accuracy ||
    BattleMoveFailureReason.immunity ||
    BattleMoveFailureReason.protected =>
      true,
    _ => false,
  };
}

BattleMoveBehaviorResolution _crashUserForJumpKick({
  required BattleMoveBehaviorContext context,
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required List<PsdkBattleEvent> events,
  bool successful = true,
}) {
  final user = state.battlerAt(context.user);
  final crash = applyDirectDamage(
    state: state,
    user: context.user,
    target: context.user,
    moveId: context.move.id,
    rng: rng,
    turn: context.turn,
    amount: user.maxHp ~/ 2,
  );

  return BattleMoveBehaviorResolution(
    state: crash.state,
    rng: crash.rng,
    events: <PsdkBattleEvent>[
      ...events,
      if (crash.event != null) crash.event!,
    ],
    successful: successful,
  );
}

bool _targetProtectedThisTurn(PsdkBattleCombatant target, int turn) {
  return target.moveHistory.successes.any((entry) {
    if (entry.turn != turn) {
      return false;
    }
    final moveId = _normalizedId(entry.moveId);
    return moveId == 'protect' ||
        moveId == 's_protect' ||
        moveId == 'crafty_shield' ||
        moveId == 's_crafty_shield';
  });
}

BattleMoveBehaviorResolution _resolveHazardSettingBasic(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  final hits = basic.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == context.move.id)
      .toList(growable: false);
  if (hits.isEmpty) {
    return basic;
  }

  final targetBank = hits.first.target.bank;
  final hazard = switch (context.move.battleEngineMethod) {
    's_stone_axe' => StealthRockEffect(bank: targetBank),
    's_ceaseless_edge' => SpikesEffect(bank: targetBank),
    final method => throw StateError('Unsupported hazard setter $method.'),
  };
  if (_isHazardAtMax(
    state: basic.state,
    owner: context.user,
    hazard: hazard,
  )) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: _addOrEmpowerHazard(
      state: basic.state,
      owner: context.user,
      hazard: hazard,
    ),
    rng: basic.rng,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveDefog(
  BattleMoveBehaviorContext context,
) {
  final secondary = _resolveSecondaryOnly(context);
  final failed = secondary.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == context.move.id);
  if (failed) {
    return secondary;
  }

  final cleaned = _clearRapidSpinAffectedEffects(
    state: secondary.state,
    user: context.user,
    includeAllBanks: true,
    clearOpposingScreens: true,
  );
  final state = cleaned.field.weather?.id == PsdkBattleWeatherId.fog
      ? cleaned.copyWith(field: cleaned.field.clearWeather())
      : cleaned;

  return BattleMoveBehaviorResolution(
    state: state,
    rng: secondary.rng,
    events: secondary.events,
  );
}

BattleMoveBehaviorResolution _resolveLockOn(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: 'lock_on',
      scope: BattlerBattleEffectScope(context.user),
      remainingTurns: 2,
    ),
  );
}

BattleMoveBehaviorResolution _resolveMemento(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  var rng = prepared.rng;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    rng = secondary.rng;
    events.addAll(secondary.events);
  }

  final user = state.battlerAt(context.user);
  final selfDamage = applyDirectDamage(
    state: state,
    user: context.user,
    target: context.user,
    moveId: context.move.id,
    rng: rng,
    turn: context.turn,
    amount: user.currentHp,
  );

  return BattleMoveBehaviorResolution(
    state: selfDamage.state,
    rng: selfDamage.rng,
    events: <PsdkBattleEvent>[
      ...events,
      if (selfDamage.event != null) selfDamage.event!,
    ],
  );
}

BattleMoveBehaviorResolution _resolveReflectType(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final target = prepared.state.battlerAt(prepared.psdkTargets.single);
  return BattleMoveBehaviorResolution(
    state: prepared.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        types: target.types,
        type3: target.type3,
        temporaryTypes: target.temporaryTypes,
      ),
    ),
    rng: prepared.rng,
    events: prepared.events,
  );
}

BattleMoveBehaviorResolution _resolveAttract(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    if (_aromaVeilBlocksMentalEffect(
      state: state,
      target: targetSlot,
      effectId: 'attract',
    )) {
      events.add(
        _mentalEffectBlockedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
        ),
      );
      continue;
    }

    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          AttractEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            attractedTo: context.user,
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: events,
  );
}

BattleMoveBehaviorResolution _resolveBind(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  if (!basic.successful) {
    return basic;
  }

  final targetSlot = context.target;
  final target = basic.state.battlerAt(targetSlot);
  if (target.isFainted ||
      target.hasType('ghost') ||
      target.effects.contains(PsdkBattleEffectIds.bind)) {
    return basic;
  }

  final user = basic.state.battlerAt(context.user);
  final roll = basic.rng.generic.nextIntInclusive(min: 4, max: 5);
  final remainingTurns = user.heldItemId == 'grip_claw' ? 7 : roll.value;
  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          BindEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            origin: context.user,
            remainingTurns: remainingTurns,
          ),
        ),
      ),
    ),
    rng: basic.rng.copyWith(generic: roll.next),
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveCantFlee(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  if (!basic.successful) {
    return basic;
  }

  final targetSlot = context.target;
  final target = basic.state.battlerAt(targetSlot);
  if (target.isFainted ||
      target.effects.contains(PsdkBattleEffectIds.cantSwitch) ||
      (context.move.category == PsdkBattleMoveCategory.status &&
          target.hasType('ghost'))) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          CantSwitchEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            origin: context.user,
          ),
        ),
      ),
    ),
    rng: basic.rng,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveJawLock(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  if (!basic.successful) {
    return basic;
  }

  final user = basic.state.battlerAt(context.user);
  final target = basic.state.battlerAt(context.target);
  if (user.effects.contains(PsdkBattleEffectIds.cantSwitch) ||
      target.effects.contains(PsdkBattleEffectIds.cantSwitch) ||
      target.isFainted) {
    return basic;
  }

  final state = basic.state
      .updateBattler(
        context.user,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(
            CantSwitchEffect(
              scope: BattlerBattleEffectScope(context.user),
              origin: context.user,
            ),
          ),
        ),
      )
      .updateBattler(
        context.target,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(
            CantSwitchEffect(
              scope: BattlerBattleEffectScope(context.target),
              origin: context.user,
            ),
          ),
        ),
      );

  return BattleMoveBehaviorResolution(
    state: state,
    rng: basic.rng,
    successful: basic.successful,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveForceSwitch(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  if (!basic.successful) {
    return basic;
  }

  final targetSlot = context.target;
  final target = basic.state.battlerAt(targetSlot);
  if (target.isFainted || target.abilityId == 'guard_dog') {
    return basic;
  }
  if (context.move.battleEngineMethod == 's_dragon_tail' &&
      target.effects.contains('substitute')) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(switching: true),
    ),
    rng: basic.rng,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveDisable(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  var installed = false;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    final target = state.battlerAt(targetSlot);
    final disabledMoveId = target.moveHistory.lastSuccessfulMoveId;
    if (_aromaVeilBlocksMentalEffect(
      state: state,
      target: targetSlot,
      effectId: 'disable',
    )) {
      events.add(
        _mentalEffectBlockedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
        ),
      );
      continue;
    }

    if (disabledMoveId == null || disabledMoveId == 'struggle') {
      events.add(
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      );
      continue;
    }

    installed = true;
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          DisableEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            disabledMoveId: disabledMoveId,
            remainingTurns: _markerTurnCount('s_disable') ?? 4,
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: events,
    successful: installed,
  );
}

BattleMoveBehaviorResolution _resolveEncore(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  var installed = false;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    final target = state.battlerAt(targetSlot);
    final encoredMoveId = target.moveHistory.lastSuccessfulMoveId;
    if (_aromaVeilBlocksMentalEffect(
      state: state,
      target: targetSlot,
      effectId: 'encore',
    )) {
      events.add(
        _mentalEffectBlockedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
        ),
      );
      continue;
    }

    if (encoredMoveId == null || _unencorableMoveIds.contains(encoredMoveId)) {
      events.add(
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      );
      continue;
    }

    installed = true;
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          EncoreEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            encoredMoveId: encoredMoveId,
            remainingTurns: _markerTurnCount('s_encore') ?? 3,
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: events,
    successful: installed,
  );
}

BattleMoveBehaviorResolution _resolveHealBlock(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    if (_aromaVeilBlocksMentalEffect(
      state: state,
      target: targetSlot,
      effectId: 'heal_block',
    )) {
      events.add(
        _mentalEffectBlockedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
        ),
      );
      continue;
    }

    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          HealBlockEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            remainingTurns: _markerTurnCount('s_heal_block') ?? 5,
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: events,
  );
}

BattleMoveBehaviorResolution _resolveImprison(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final userMoveIds = prepared.state
      .battlerAt(context.user)
      .moves
      .map((move) => move.id)
      .toSet();
  var state = prepared.state;
  for (final targetSlot in prepared.psdkTargets) {
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          ImprisonEffect(
            scope: BattlerBattleEffectScope(targetSlot),
            imprisonedMoveIds: userMoveIds,
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: prepared.events,
  );
}

BattleMoveBehaviorResolution _resolveTargetMarker(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final effectId =
      _partialTargetMarkerMethods[context.move.battleEngineMethod]!;
  var state = prepared.state;
  var rng = prepared.rng;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    final targetBefore = state.battlerAt(targetSlot);
    if (_aromaVeilBlocksMentalEffect(
      state: state,
      target: targetSlot,
      effectId: effectId,
    )) {
      events.add(
        _mentalEffectBlockedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
        ),
      );
      continue;
    }

    if (_gastroAcidBlockedTarget(
      method: context.move.battleEngineMethod,
      target: targetBefore,
    )) {
      events.add(
        _targetMarkerImmunityEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
        ),
      );
      continue;
    }

    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          _targetMarkerEffect(
            method: context.move.battleEngineMethod,
            effectId: effectId,
            target: targetSlot,
          ),
        ),
      ),
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    rng = secondary.rng;
    events.addAll(secondary.events);
    if (context.move.battleEngineMethod == 's_autotomize') {
      state = _applyAutotomizeWeightLoss(
        state: state,
        target: targetSlot,
        before: targetBefore,
      );
    }
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    events: events,
  );
}

PsdkBattleState _applyAutotomizeWeightLoss({
  required PsdkBattleState state,
  required PsdkBattleSlotRef target,
  required PsdkBattleCombatant before,
}) {
  final after = state.battlerAt(target);
  if (!_statStagesChanged(before.statStages, after.statStages)) {
    return state;
  }
  return state.updateBattler(
    target,
    (battler) => battler.copyWith(
      currentWeightKg: (battler.currentWeightKg - 100)
          .clamp(
            0.1,
            double.infinity,
          )
          .toDouble(),
    ),
  );
}

bool _statStagesChanged(
  PsdkBattleStatStages before,
  PsdkBattleStatStages after,
) {
  const stats = <String>{
    'attack',
    'defense',
    'specialAttack',
    'specialDefense',
    'speed',
    'evasion',
    'accuracy',
  };
  return stats.any((stat) => before.valueOf(stat) != after.valueOf(stat));
}

BattleMoveBehaviorResolution _resolveUserBankMarker(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(
    BattleMoveBehaviorContext(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      user: context.user,
      target: context.target,
      move: BattleMoveDefinition.fromPsdk(
        context.move.psdkMove.copyWith(target: PsdkBattleMoveTarget.userSide),
      ),
      isLastActionOfTurn: context.isLastActionOfTurn,
      moveProcedureHooks: context.moveProcedureHooks,
    ),
  );
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final effectId =
      _partialUserBankMarkerMethods[context.move.battleEngineMethod]!;
  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: effectId,
      scope: BankBattleEffectScope(context.user.bank),
      remainingTurns: _markerTurnCount(context.move.battleEngineMethod),
    ),
  );
}

BattleMoveBehaviorResolution _resolveFoeBankMarker(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetBank = prepared.psdkTargets.isEmpty
      ? psdkSinglesFoeOf(context.user).bank
      : prepared.psdkTargets.first.bank;
  final effectId =
      _partialFoeBankMarkerMethods[context.move.battleEngineMethod]!;
  if (_hazardEffectFor(effectId, targetBank) case final hazard?) {
    if (_isHazardAtMax(
      state: prepared.state,
      owner: context.user,
      hazard: hazard,
    )) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: 'hazard_already_active',
          ),
        ],
        successful: false,
      );
    }
    return BattleMoveBehaviorResolution(
      state: _addOrEmpowerHazard(
        state: prepared.state,
        owner: context.user,
        hazard: hazard,
      ),
      rng: prepared.rng,
      events: prepared.events,
    );
  }
  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: effectId,
      scope: BankBattleEffectScope(targetBank),
      remainingTurns: _markerTurnCount(context.move.battleEngineMethod),
    ),
  );
}

BattleEffect? _hazardEffectFor(String effectId, int bank) {
  return switch (effectId) {
    'spikes' => SpikesEffect(bank: bank),
    'stealth_rock' => StealthRockEffect(bank: bank),
    'sticky_web' => StickyWebEffect(bank: bank),
    'toxic_spikes' => ToxicSpikesEffect(bank: bank),
    _ => null,
  };
}

bool _isHazardAtMax({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required BattleEffect hazard,
}) {
  final current = _firstEffectWithId(
    state.battlerAt(owner).effects.effects,
    hazard.id,
  );
  return switch (current) {
    SpikesEffect(:final layers) => layers >= 3,
    ToxicSpikesEffect(:final layers) => layers >= 2,
    StealthRockEffect() || StickyWebEffect() => true,
    _ => false,
  };
}

PsdkBattleState _addOrEmpowerHazard({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required BattleEffect hazard,
}) {
  final battler = state.battlerAt(owner);
  final current = _firstEffectWithId(battler.effects.effects, hazard.id);
  final nextHazard = switch ((current, hazard)) {
    (SpikesEffect current, SpikesEffect _) => current.empower(),
    (ToxicSpikesEffect current, ToxicSpikesEffect _) => current.empower(),
    (BattleEffect current, _) => current,
    _ => hazard,
  };
  return state.updateBattler(
    owner,
    (currentBattler) => currentBattler.copyWith(
      effects: currentBattler.effects.addEffect(nextHazard),
    ),
  );
}

BattleEffect? _firstEffectWithId(Iterable<BattleEffect> effects, String id) {
  for (final effect in effects) {
    if (effect.id == id) {
      return effect;
    }
  }
  return null;
}

BattleMoveBehaviorResolution _resolveFieldMarker(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final effectId = _partialFieldMarkerMethods[context.move.battleEngineMethod]!;
  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: effectId,
      scope: const FieldBattleEffectScope(),
      remainingTurns: _markerTurnCount(context.move.battleEngineMethod),
    ),
  );
}

int? _markerTurnCount(String battleEngineMethod) {
  return switch (battleEngineMethod) {
    's_electrify' ||
    's_after_you' ||
    's_ally_switch' ||
    's_crafty_shield' ||
    's_grudge' ||
    's_ion_deluge' ||
    's_magic_coat' ||
    's_powder' ||
    's_snatch' =>
      0,
    's_charge' || 's_laser_focus' => 2,
    's_disable' => 4,
    's_encore' => 3,
    's_embargo' ||
    's_gravity' ||
    's_heal_block' ||
    's_magic_room' ||
    's_magnet_rise' =>
      5,
    's_future_sight' => 3,
    's_lucky_chant' ||
    's_mist' ||
    's_safe_guard' ||
    's_tailwind' ||
    's_thing_sport' ||
    's_trick_room' ||
    's_wonder_room' =>
      5,
    's_perish_song' => 4,
    's_telekinesis' => 3,
    's_wish' || 's_yawn' => 2,
    _ => null,
  };
}

BattleEffect _targetMarkerEffect({
  required String method,
  required String effectId,
  required PsdkBattleSlotRef target,
}) {
  final scope = BattlerBattleEffectScope(target);
  final remainingTurns = _markerTurnCount(method);
  return switch (effectId) {
    'taunt' => TauntEffect(scope: scope, remainingTurns: remainingTurns ?? 3),
    'torment' =>
      TormentEffect(scope: scope, remainingTurns: remainingTurns ?? 3),
    _ => GenericBattleEffect(
        id: effectId,
        scope: scope,
        remainingTurns: remainingTurns,
      ),
  };
}

const _aromaVeilBlockedMentalEffectIds = <String>{
  'attract',
  'disable',
  'encore',
  'heal_block',
  'taunt',
  'torment',
};

bool _aromaVeilBlocksMentalEffect({
  required PsdkBattleState state,
  required PsdkBattleSlotRef target,
  required String effectId,
}) {
  if (!_aromaVeilBlockedMentalEffectIds.contains(effectId)) {
    return false;
  }

  final battler = state.battlerAt(target);
  return _normalizedId(battler.abilityId) == 'aroma_veil' &&
      !battler.effects.contains('ability_suppressed');
}

bool _gastroAcidBlockedTarget({
  required String method,
  required PsdkBattleCombatant target,
}) {
  if (method != 's_gastro_acid') {
    return false;
  }
  final abilityId = _normalizedId(target.abilityId);
  return target.effects.contains('ability_suppressed') ||
      abilityId == 'good_as_gold' ||
      _gastroAcidProtectedAbilityIds.contains(abilityId);
}

PsdkBattleMoveFailedEvent _targetMarkerImmunityEvent({
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
}) {
  return PsdkBattleMoveFailedEvent(
    user: user,
    target: target,
    moveId: moveId,
    reason: BattleMoveFailureReason.immunity.jsonName,
  );
}

PsdkBattleMoveFailedEvent _mentalEffectBlockedEvent({
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
}) {
  return PsdkBattleMoveFailedEvent(
    user: user,
    target: target,
    moveId: moveId,
    reason: BattleMoveFailureReason.unusableByUser.jsonName,
  );
}

BattleMoveBehaviorResolution _resolveTwoTurns(
  BattleMoveBehaviorContext context,
) {
  final user = context.state.battlerAt(context.user);
  if (user.effects.contains(PsdkBattleEffectIds.twoTurnCharge)) {
    final releasedState = context.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.remove(PsdkBattleEffectIds.twoTurnCharge),
      ),
    );
    return _resolveBasic(
      BattleMoveBehaviorContext(
        state: releasedState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
    );
  }

  final prepared = prepareBattleMove(context, forceAccuracyBypass: true);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: TwoTurnChargeEffect(
      scope: BattlerBattleEffectScope(context.user),
      chargedMoveId: context.move.id,
      chargedTarget: context.target,
    ),
  );
}

bool _isRainActive(PsdkBattleState state) {
  if (state.weatherEffectsSuppressed) {
    return false;
  }
  return switch (state.field.weather?.id) {
    PsdkBattleWeatherId.rain || PsdkBattleWeatherId.hardrain => true,
    _ => false,
  };
}

BattleMoveBehaviorResolution _resolveTrick(BattleMoveBehaviorContext context) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final targetSlot = prepared.psdkTargets.single;
  final user = prepared.state.battlerAt(context.user);
  final target = prepared.state.battlerAt(targetSlot);
  if (user.heldItemId == null && target.heldItemId == null) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      ],
      successful: false,
    );
  }

  final userItem = user.heldItemId;
  final targetItem = target.heldItemId;
  final userSwappedState = prepared.state.updateBattler(
    context.user,
    (battler) => battler
        .copyWith(
          heldItemId: targetItem,
          consumedItemId: null,
          itemConsumed: false,
        )
        .withItemEffect(context.user),
  );
  final swappedState = userSwappedState.updateBattler(
    targetSlot,
    (battler) => battler
        .copyWith(
          heldItemId: userItem,
          consumedItemId: null,
          itemConsumed: false,
        )
        .withItemEffect(targetSlot),
  );

  return BattleMoveBehaviorResolution(
    state: swappedState,
    rng: prepared.rng,
    events: prepared.events,
  );
}

BattleMoveBehaviorResolution _resolvePlasmaFists(
  BattleMoveBehaviorContext context,
) {
  final basic = _resolveBasic(context);
  if (!basic.successful) {
    return basic;
  }

  return _addEffectToUser(
    context: context,
    state: basic.state,
    rng: basic.rng,
    events: basic.events,
    effect: const GenericBattleEffect(
      id: 'ion_deluge',
      scope: FieldBattleEffectScope(),
    ),
  );
}

BattleMoveBehaviorResolution _resolvePartingShot(
  BattleMoveBehaviorContext context,
) {
  final secondary = _resolveSecondaryOnly(context);
  final applied = secondary.events.any(
    (event) =>
        event is PsdkBattleStatStageEvent || event is PsdkBattleStatusEvent,
  );
  if (!applied) {
    return secondary;
  }

  final switching = const BattleSwitchHandler().markSwitching(
    context: BattleHandlerContext(
      state: secondary.state,
      rng: secondary.rng,
      turn: context.turn,
      user: context.user,
    ),
    target: context.user,
    switching: true,
  );
  return BattleMoveBehaviorResolution(
    state: switching.state,
    rng: switching.rng,
    events: secondary.events,
  );
}

BattleMoveBehaviorResolution _resolveSecondaryOnly(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  var rng = prepared.rng;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    rng = secondary.rng;
    events.addAll(secondary.events);
    if (context.move.battleEngineMethod == 's_toxic_thread' &&
        secondary.events.isEmpty) {
      events.add(
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: targetSlot,
          moveId: context.move.id,
          reason: 'toxic_thread_blocked',
        ),
      );
    }
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    events: events,
  );
}

BattleMoveBehaviorResolution _resolveSubstitute(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final user = prepared.state.battlerAt(context.user);
  final hpCost = (user.maxHp ~/ 4).clamp(1, user.currentHp).toInt();
  if (user.currentHp <= hpCost || user.effects.contains('substitute')) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.user,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      ],
      successful: false,
    );
  }

  final damage = applyDirectDamage(
    state: prepared.state,
    user: context.user,
    target: context.user,
    moveId: context.move.id,
    rng: prepared.rng,
    turn: context.turn,
    amount: hpCost,
  );
  return _addEffectToUser(
    context: context,
    state: damage.state,
    rng: damage.rng,
    events: <PsdkBattleEvent>[
      ...prepared.events,
      if (damage.event != null) damage.event!,
    ],
    effect: GenericBattleEffect(
      id: 'substitute',
      scope: BattlerBattleEffectScope(context.user),
    ),
  );
}

BattleMoveBehaviorResolution _resolveAddType(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final addedType = _addedTypeFor(context.move.dbSymbol);
  var state = prepared.state;
  for (final targetSlot in prepared.psdkTargets) {
    final target = state.battlerAt(targetSlot);
    if (target.hasType(addedType)) {
      continue;
    }
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(type3: addedType),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: prepared.events,
  );
}

BattleMoveBehaviorResolution _resolveChangeType(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  for (final targetSlot in prepared.psdkTargets) {
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        types: PsdkBattleTypes(primary: context.move.type),
        type3: null,
        temporaryTypes: const <String>[],
        effects: battler.effects.addEffect(
          GenericBattleEffect(
            id: 'change_type',
            scope: BattlerBattleEffectScope(targetSlot),
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: prepared.events,
  );
}

String _addedTypeFor(String dbSymbol) {
  return switch (dbSymbol.trim().toLowerCase()) {
    'trick_or_treat' => 'ghost',
    'forest_s_curse' => 'grass',
    _ => 'normal',
  };
}

BattleMoveBehaviorResolution _resolveStockpile(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  var rng = prepared.rng;
  final events = <PsdkBattleEvent>[...prepared.events];
  for (final targetSlot in prepared.psdkTargets) {
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          GenericBattleEffect(
            id: 'stockpile',
            scope: BattlerBattleEffectScope(targetSlot),
          ),
        ),
      ),
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: context.user,
      target: targetSlot,
      move: BattleMoveDefinition.fromPsdk(
        context.move.psdkMove.copyWith(
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'defense',
              stages: 1,
              chance: 100,
            ),
            PsdkBattleMoveStageMod(
              stat: 'specialDefense',
              stages: 1,
              chance: 100,
            ),
          ],
        ),
      ),
      turn: context.turn,
    );
    state = secondary.state;
    rng = secondary.rng;
    events.addAll(secondary.events);
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    events: events,
  );
}

BattleMoveBehaviorResolution _resolveForesight(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  var state = prepared.state;
  for (final targetSlot in prepared.psdkTargets) {
    state = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          GenericBattleEffect(
            id: PsdkBattleEffectIds.foresight,
            scope: BattlerBattleEffectScope(targetSlot),
          ),
        ),
      ),
    );
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: prepared.rng,
    events: prepared.events,
  );
}

BattleMoveBehaviorResolution _resolveThingSport(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final effectId = context.move.dbSymbol.trim().toLowerCase() == 'water_sport'
      ? PsdkBattleEffectIds.waterSport
      : PsdkBattleEffectIds.mudSport;
  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: effectId,
      scope: const FieldBattleEffectScope(),
      remainingTurns: 5,
    ),
  );
}

BattleMoveBehaviorResolution _resolveReload(BattleMoveBehaviorContext context) {
  final basic = _resolveBasic(context);
  if (!basic.successful) {
    return basic;
  }

  return BattleMoveBehaviorResolution(
    state: basic.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          ForceNextMoveBaseEffect(
            scope: BattlerBattleEffectScope(context.user),
          ),
        ),
      ),
    ),
    rng: basic.rng,
    events: basic.events,
  );
}

BattleMoveBehaviorResolution _resolveReflect(
    BattleMoveBehaviorContext context) {
  final prepared = prepareBattleMove(
    BattleMoveBehaviorContext(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      user: context.user,
      target: context.target,
      move: BattleMoveDefinition.fromPsdk(
        context.move.psdkMove.copyWith(target: PsdkBattleMoveTarget.userSide),
      ),
      isLastActionOfTurn: context.isLastActionOfTurn,
      moveProcedureHooks: context.moveProcedureHooks,
    ),
  );
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  final effectId = switch (context.move.id) {
    'light_screen' => 'light_screen',
    'aurora_veil' => 'aurora_veil',
    _ => 'reflect',
  };
  if (_bankHasEffect(prepared.state, context.user.bank, effectId)) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.user,
          moveId: context.move.id,
          reason: 'screen_already_active',
        ),
      ],
      successful: false,
    );
  }
  if (effectId == 'aurora_veil' && !_globalSnowing(prepared.state)) {
    return BattleMoveBehaviorResolution(
      state: prepared.state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.user,
          moveId: context.move.id,
          reason: 'weather_required',
        ),
      ],
      successful: false,
    );
  }
  final user = prepared.state.battlerAt(context.user);
  final duration =
      _normalizedId(user.heldItemId) == 'light_clay' && !user.itemConsumed
          ? 8
          : 5;
  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: effectId,
      scope: BattlerBattleEffectScope(context.user),
      remainingTurns: duration,
    ),
  );
}

bool _globalSnowing(PsdkBattleState state) {
  if (state.weatherEffectsSuppressed) {
    return false;
  }
  return state.field.isWeatherActive(PsdkBattleWeatherId.snow) ||
      state.field.isWeatherActive(PsdkBattleWeatherId.hail);
}

BattleMoveBehaviorResolution _resolveFollowMe(
  BattleMoveBehaviorContext context,
) {
  final prepared = prepareBattleMove(context);
  if (!prepared.shouldExecuteBehavior) {
    return prepared.toResolution();
  }

  return _addEffectToUser(
    context: context,
    state: prepared.state,
    rng: prepared.rng,
    events: prepared.events,
    effect: GenericBattleEffect(
      id: PsdkBattleEffectIds.centerOfAttention,
      scope: BattlerBattleEffectScope(context.user),
      remainingTurns: 0,
    ),
  );
}

BattleMoveBehaviorResolution _addEffectToUser({
  required BattleMoveBehaviorContext context,
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required List<PsdkBattleEvent> events,
  required BattleEffect effect,
}) {
  return BattleMoveBehaviorResolution(
    state: state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(effect),
      ),
    ),
    rng: rng,
    events: events,
  );
}

const _rapidSpinAffectedEffectIds = <String>{
  PsdkBattleEffectIds.bind,
  PsdkBattleEffectIds.leechSeed,
  'spikes',
  'stealth_rock',
  'sticky_web',
  'toxic_spikes',
};

const _defogOpposingScreenEffectIds = <String>{
  'aurora_veil',
  'light_screen',
  'mist',
  'reflect',
  'safeguard',
};

PsdkBattleState _clearRapidSpinAffectedEffects({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required bool includeAllBanks,
  required bool clearOpposingScreens,
}) {
  var next = state;
  for (final entry in state.combatants.entries) {
    final filtered = entry.value.effects.effects.where(
      (effect) => _keepsEffectAfterHazardCleanup(
        effect,
        user: user,
        owner: entry.key,
        includeAllBanks: includeAllBanks,
        clearOpposingScreens: clearOpposingScreens,
      ),
    );
    next = next.updateBattler(
      entry.key,
      (battler) => battler.copyWith(
        effects: PsdkBattleEffectStack(effects: filtered),
      ),
    );
  }
  return next;
}

PsdkBattleState _clearScreenEffects({
  required PsdkBattleState state,
  required int targetBank,
}) {
  var next = state;
  for (final entry in state.combatants.entries) {
    final filtered = entry.value.effects.effects.where((effect) {
      if (!_defogOpposingScreenEffectIds.contains(effect.id)) {
        return true;
      }
      final scope = effect.scope;
      if (scope is BankBattleEffectScope) {
        return scope.bank != targetBank;
      }
      if (scope is BattlerBattleEffectScope) {
        return scope.slot.bank != targetBank;
      }
      return true;
    });
    next = next.updateBattler(
      entry.key,
      (battler) => battler.copyWith(
        effects: PsdkBattleEffectStack(effects: filtered),
      ),
    );
  }
  return next;
}

bool _bankHasEffect(PsdkBattleState state, int bank, String effectId) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any((effect) {
      if (effect.id != effectId) {
        return false;
      }
      final scope = effect.scope;
      if (scope is BankBattleEffectScope) {
        return scope.bank == bank;
      }
      if (scope is BattlerBattleEffectScope) {
        return scope.slot.bank == bank;
      }
      return false;
    }),
  );
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}

bool _keepsEffectAfterHazardCleanup(
  BattleEffect effect, {
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef owner,
  required bool includeAllBanks,
  required bool clearOpposingScreens,
}) {
  if (_rapidSpinAffectedEffectIds.contains(effect.id)) {
    final scope = effect.scope;
    if (scope is BankBattleEffectScope) {
      return !includeAllBanks && scope.bank != user.bank;
    }
    if (owner == user) {
      return false;
    }
  }

  if (clearOpposingScreens &&
      _defogOpposingScreenEffectIds.contains(effect.id)) {
    final scope = effect.scope;
    if (scope is BankBattleEffectScope) {
      return scope.bank == user.bank;
    }
    if (scope is BattlerBattleEffectScope) {
      return scope.slot.bank == user.bank;
    }
  }

  return true;
}

BattleMoveBehaviorResolution _resolveProtect(
    BattleMoveBehaviorContext context) {
  if (context.isLastActionOfTurn) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      ],
      successful: false,
    );
  }
  final failureCheck = _protectFailureCheck(context);
  if (failureCheck != null) {
    return failureCheck;
  }

  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final protectedSlot = common.psdkTargets.single;
  final protectedBattler = common.state.battlerAt(protectedSlot);

  final effect = context.move.id == PsdkBattleEffectIds.endure
      ? EndureEffect(
          scope: BattlerBattleEffectScope(
            PsdkBattleSlotRef(
              bank: protectedSlot.bank,
              position: protectedSlot.position,
            ),
          ),
        )
      : ProtectEffect(
          scope: BattlerBattleEffectScope(
            PsdkBattleSlotRef(
              bank: protectedSlot.bank,
              position: protectedSlot.position,
            ),
          ),
        );
  final nextState = common.state.replaceBattler(
    protectedSlot,
    protectedBattler.copyWith(
      effects: protectedBattler.effects.addEffect(effect),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: common.rng,
    events: common.events,
  );
}

BattleMoveBehaviorResolution? _protectFailureCheck(
  BattleMoveBehaviorContext context,
) {
  if (_protectSkipsFailureCheck(context.move.dbSymbol)) {
    return null;
  }

  final priorSuccesses = _priorSuccessfulProtectChain(
    context.state.battlerAt(context.user),
  );
  if (priorSuccesses <= 0) {
    return null;
  }

  final denominator = _protectSuccessDenominator(priorSuccesses);
  final roll = context.rng.generic.nextChance(
    numerator: 1,
    denominator: denominator,
  );
  if (roll.didOccur) {
    return null;
  }

  return BattleMoveBehaviorResolution(
    state: context.state,
    rng: context.rng.copyWith(generic: roll.next),
    events: <PsdkBattleEvent>[
      PsdkBattleMoveFailedEvent(
        user: context.user,
        target: context.target,
        moveId: context.move.id,
        reason: BattleMoveFailureReason.unusableByUser.jsonName,
      ),
    ],
    successful: false,
  );
}

int _priorSuccessfulProtectChain(PsdkBattleCombatant user) {
  final lastSentTurn = user.lastSentTurn ?? -1;
  final successfulProtectTurns = <int>{
    for (final entry in user.moveHistory.successes)
      if (entry.turn > lastSentTurn && _isProtectFamilyMoveId(entry.moveId))
        entry.turn,
  };

  var count = 0;
  for (final attempt in user.moveHistory.attempts.reversed) {
    if (attempt.turn <= lastSentTurn ||
        !_isProtectFamilyMoveId(attempt.moveId)) {
      break;
    }
    if (!successfulProtectTurns.contains(attempt.turn)) {
      break;
    }
    count++;
  }
  return count.clamp(0, 6).toInt();
}

int _protectSuccessDenominator(int priorSuccesses) {
  var denominator = 1;
  for (var index = 0; index < priorSuccesses.clamp(0, 6); index++) {
    denominator *= 3;
  }
  return denominator;
}

bool _protectSkipsFailureCheck(String dbSymbol) {
  return dbSymbol == 'quick_guard' || dbSymbol == 'wide_guard';
}

bool _isProtectFamilyMoveId(String moveId) {
  return _protectFamilyMoveIds.contains(_normalizedId(moveId));
}

const _protectFamilyMoveIds = <String>{
  'baneful_bunker',
  'detect',
  'endure',
  'king_s_shield',
  'mat_block',
  'protect',
  'quick_guard',
  'spiky_shield',
  'wide_guard',
};
