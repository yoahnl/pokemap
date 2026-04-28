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
import '../domain/move/battle_move_prevention.dart';
import '../domain/move/battle_move_registry.dart';
import '../domain/move/battle_move_secondary_effect_resolver.dart';
import '../domain/rng/battle_rng_streams.dart';
import '../domain/effect/battle_effect.dart';
import '../domain/effect/battle_effect_scope.dart';
import '../domain/effect/move/attract_effect.dart';
import '../domain/effect/move/bind_effect.dart';
import '../domain/effect/move/cant_switch_effect.dart';
import '../domain/effect/move/disable_effect.dart';
import '../domain/effect/move/encore_effect.dart';
import '../domain/effect/move/force_next_move_base_effect.dart';
import '../domain/effect/move/heal_block_effect.dart';
import '../domain/effect/move/imprison_effect.dart';
import '../domain/effect/move/protect_effect.dart';
import '../domain/effect/move/taunt_effect.dart';
import '../domain/effect/move/torment_effect.dart';
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
      battleEngineMethod: 's_cantflee',
      resolve: _resolveCantFlee,
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
    const ActionGatedMoveBehavior.snore(),
    const ActionGatedMoveBehavior.suckerPunch(),
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
    const MultiHitMoveBehavior.tripleKick(),
    const MultiHitMoveBehavior.populationBomb(),
    const MultiHitMoveBehavior.waterShuriken(),
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
  's_fake_out',
  's_feint',
  's_fell_stinger',
  's_flame_burst',
  's_flying_press',
  's_focus_punch',
  's_frustration',
  's_fusion_bolt',
  's_fusion_flare',
  's_genesis_supernova',
  's_guardian_of_alola',
  's_hidden_power',
  's_hyperspace_hole',
  's_jump_kick',
  's_last_resort',
  's_light_that_burns_the_sky',
  's_magnitude',
  's_malicious_moonsault',
  's_payday',
  's_photon_geyser',
  's_pollen_puff',
  's_pursuit',
  's_rage',
  's_return',
  's_round',
  's_shell_trap',
  's_split_up',
  's_splintered_stormshards',
  's_spectral_thief',
  's_stomp',
  's_u_turn',
  's_aura_wheel',
  's_baddy_bad',
  's_double_iron_bash',
  's_dragon_darts',
  's_eerie_spell',
  's_electro_shot',
  's_fickle_beam',
  's_freezy_frost',
  's_genies_storm',
  's_glaive_rush',
  's_glitzy_glow',
  's_grav_apple',
  's_ice_spinner',
  's_jaw_lock',
  's_last_respects',
  's_make_it_rain',
  's_order_up',
  's_poltergeist',
  's_pre_attack_base',
  's_raging_bull',
  's_sappy_seed',
  's_scale_shot',
  's_shell_side_arm',
  's_steel_roller',
  's_super_duper_effective',
  's_triple_arrows',
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
  's_electrify': 'change_type',
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
  's_parting_shot',
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

  final targetSlot = prepared.psdkTargets.single;
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

  return BattleMoveBehaviorResolution(
    state: _clearRapidSpinAffectedEffects(
      state: basic.state,
      user: context.user,
      includeAllBanks: false,
      clearOpposingScreens: false,
    ),
    rng: basic.rng,
    events: basic.events,
  );
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

  return BattleMoveBehaviorResolution(
    state: _clearRapidSpinAffectedEffects(
      state: secondary.state,
      user: context.user,
      includeAllBanks: true,
      clearOpposingScreens: true,
    ),
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
  for (final targetSlot in prepared.psdkTargets) {
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
    events: prepared.events,
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
  for (final targetSlot in prepared.psdkTargets) {
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
    events: prepared.events,
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
  }

  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    events: events,
  );
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
    effect: GenericBattleEffect(
      id: PsdkBattleEffectIds.twoTurnCharge,
      scope: BattlerBattleEffectScope(context.user),
    ),
  );
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

  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final protectedSlot = common.psdkTargets.single;
  final protectedBattler = common.state.battlerAt(protectedSlot);

  // PSDK stores Protect as a pokemon-tied effect. This first Dart slice keeps
  // only the effect id and the same one-turn lifetime; success-rate decay and
  // variants such as Endure/Spiky Shield intentionally remain outside Lot 14.
  final nextState = common.state.replaceBattler(
    protectedSlot,
    protectedBattler.copyWith(
      effects: protectedBattler.effects.addEffect(
        ProtectEffect(
          scope: BattlerBattleEffectScope(
            PsdkBattleSlotRef(
              bank: protectedSlot.bank,
              position: protectedSlot.position,
            ),
          ),
        ),
      ),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: common.rng,
    events: common.events,
  );
}
