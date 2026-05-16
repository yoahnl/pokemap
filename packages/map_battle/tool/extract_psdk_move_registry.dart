import 'dart:io';

final _registerPattern = RegExp(
  r'(?:Move\.)?register\(:((?:s_)[a-zA-Z0-9_]+),\s*([A-Za-z0-9_:]+)\)',
);

const _knownDartBehaviors = <String, _KnownDartBehavior>{
  // These statuses stay "partial" until their Ruby behavior families are fully
  // parity-tested. The engine can execute them today, but Lot 15 must not claim
  // complete PSDK parity just because a method is wired.
  's_2turns': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_2turns',
    status: _PsdkPortStatus.partial,
  ),
  's_add_type': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_add_type',
    status: _PsdkPortStatus.partial,
  ),
  's_after_you': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_after_you)',
    status: _PsdkPortStatus.partial,
  ),
  's_ally_switch': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_ally_switch)',
    status: _PsdkPortStatus.partial,
  ),
  's_autotomize': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_autotomize)',
    status: _PsdkPortStatus.partial,
  ),
  's_assist': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_assist)',
    status: _PsdkPortStatus.partial,
  ),
  's_beat_up': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_beat_up)',
    status: _PsdkPortStatus.partial,
  ),
  's_bestow': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.bestow',
    status: _PsdkPortStatus.partial,
  ),
  's_bide': _KnownDartBehavior(
    dartBehavior: 'CounterDamageMoveBehavior.bide',
    status: _PsdkPortStatus.partial,
  ),
  's_camouflage': _KnownDartBehavior(
    dartBehavior: 'FieldLocationMoveBehavior.camouflage',
    status: _PsdkPortStatus.partial,
  ),
  's_conversion': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_conversion)',
    status: _PsdkPortStatus.partial,
  ),
  's_conversion2': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_conversion2)',
    status: _PsdkPortStatus.partial,
  ),
  's_counter': _KnownDartBehavior(
    dartBehavior: 'CounterDamageMoveBehavior.counter',
    status: _PsdkPortStatus.partial,
  ),
  's_echo': _KnownDartBehavior(
    dartBehavior: 'ConsecutivePowerMoveBehavior.echoedVoice',
    status: _PsdkPortStatus.partial,
  ),
  's_fling': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.fling',
    status: _PsdkPortStatus.partial,
  ),
  's_flower_shield': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_flower_shield)',
    status: _PsdkPortStatus.partial,
  ),
  's_frustration': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_frustration)',
    status: _PsdkPortStatus.partial,
  ),
  's_gear_up': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_gear_up)',
    status: _PsdkPortStatus.partial,
  ),
  's_healing_wish': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_healing_wish)',
    status: _PsdkPortStatus.partial,
  ),
  's_helping_hand': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_helping_hand)',
    status: _PsdkPortStatus.partial,
  ),
  's_instruct': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_instruct)',
    status: _PsdkPortStatus.partial,
  ),
  's_lunar_dance': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_lunar_dance)',
    status: _PsdkPortStatus.partial,
  ),
  's_magnetic_flux': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_magnetic_flux)',
    status: _PsdkPortStatus.partial,
  ),
  's_magnitude': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_magnitude',
    status: _PsdkPortStatus.partial,
  ),
  's_me_first': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_me_first)',
    status: _PsdkPortStatus.partial,
  ),
  's_metal_burst': _KnownDartBehavior(
    dartBehavior: 'CounterDamageMoveBehavior.metalBurst',
    status: _PsdkPortStatus.partial,
  ),
  's_metronome': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_metronome)',
    status: _PsdkPortStatus.partial,
  ),
  's_mimic': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_mimic)',
    status: _PsdkPortStatus.partial,
  ),
  's_mirror_coat': _KnownDartBehavior(
    dartBehavior: 'CounterDamageMoveBehavior.mirrorCoat',
    status: _PsdkPortStatus.partial,
  ),
  's_mirror_move': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_mirror_move)',
    status: _PsdkPortStatus.partial,
  ),
  's_natural_gift': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.naturalGift',
    status: _PsdkPortStatus.partial,
  ),
  's_nature_power': _KnownDartBehavior(
    dartBehavior: 'FieldLocationMoveBehavior.naturePower',
    status: _PsdkPortStatus.partial,
  ),
  's_present': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_present',
    status: _PsdkPortStatus.partial,
  ),
  's_recycle': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.recycle',
    status: _PsdkPortStatus.partial,
  ),
  's_return': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_return)',
    status: _PsdkPortStatus.partial,
  ),
  's_rototiller': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_rototiller)',
    status: _PsdkPortStatus.partial,
  ),
  's_sketch': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_sketch)',
    status: _PsdkPortStatus.partial,
  ),
  's_sleep_talk': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_sleep_talk)',
    status: _PsdkPortStatus.partial,
  ),
  's_spite': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_spite)',
    status: _PsdkPortStatus.partial,
  ),
  's_split_up': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_split_up)',
    status: _PsdkPortStatus.partial,
  ),
  's_swallow': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_swallow)',
    status: _PsdkPortStatus.partial,
  ),
  's_teleport': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_teleport)',
    status: _PsdkPortStatus.partial,
  ),
  's_venom_drench': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.secondaryOnly(s_venom_drench)',
    status: _PsdkPortStatus.partial,
  ),
  's_alluring_voice': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.alluringVoice',
    status: _PsdkPortStatus.partial,
  ),
  's_aura_wheel': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_aura_wheel)',
    status: _PsdkPortStatus.partial,
  ),
  's_baddy_bad': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_baddy_bad',
    status: _PsdkPortStatus.partial,
  ),
  's_burning_jealousy': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.burningJealousy',
    status: _PsdkPortStatus.partial,
  ),
  's_chilly_reception': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialFieldMarker(s_chilly_reception)',
    status: _PsdkPortStatus.partial,
  ),
  's_corrosive_gas': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialTargetMarker(s_corrosive_gas)',
    status: _PsdkPortStatus.partial,
  ),
  's_court_change': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_court_change)',
    status: _PsdkPortStatus.partial,
  ),
  's_doodle': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_doodle)',
    status: _PsdkPortStatus.partial,
  ),
  's_double_iron_bash': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.doubleIronBash',
    status: _PsdkPortStatus.partial,
  ),
  's_dragon_cheer': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_dragon_cheer)',
    status: _PsdkPortStatus.partial,
  ),
  's_dragon_darts': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_dragon_darts)',
    status: _PsdkPortStatus.partial,
  ),
  's_eerie_spell': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_eerie_spell',
    status: _PsdkPortStatus.partial,
  ),
  's_electro_shot': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_electro_shot',
    status: _PsdkPortStatus.partial,
  ),
  's_expanding_force': _KnownDartBehavior(
    dartBehavior: 'TerrainPowerMoveBehavior.expandingForce',
    status: _PsdkPortStatus.partial,
  ),
  's_fairy_lock': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_fairy_lock)',
    status: _PsdkPortStatus.partial,
  ),
  's_fickle_beam': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_fickle_beam',
    status: _PsdkPortStatus.partial,
  ),
  's_fishious_rend': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.fishiousRend',
    status: _PsdkPortStatus.partial,
  ),
  's_freezy_frost': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_freezy_frost',
    status: _PsdkPortStatus.partial,
  ),
  's_genies_storm': _KnownDartBehavior(
    dartBehavior: 'WeatherPowerMoveBehavior.geniesStorm',
    status: _PsdkPortStatus.partial,
  ),
  's_geomancy': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_geomancy)',
    status: _PsdkPortStatus.partial,
  ),
  's_gigaton_hammer': _KnownDartBehavior(
    dartBehavior: 'ForcedActionMoveBehavior.gigatonHammer',
    status: _PsdkPortStatus.partial,
  ),
  's_glaive_rush': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_glaive_rush',
    status: _PsdkPortStatus.partial,
  ),
  's_glitzy_glow': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_glitzy_glow',
    status: _PsdkPortStatus.partial,
  ),
  's_grassy_glide': _KnownDartBehavior(
    dartBehavior: 'TerrainPowerMoveBehavior.grassyGlide',
    status: _PsdkPortStatus.partial,
  ),
  's_grav_apple': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_grav_apple',
    status: _PsdkPortStatus.partial,
  ),
  's_ice_spinner': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_ice_spinner',
    status: _PsdkPortStatus.partial,
  ),
  's_ivy_cudgel': _KnownDartBehavior(
    dartBehavior: 'TypeBasedMoveBehavior.ivyCudgel',
    status: _PsdkPortStatus.partial,
  ),
  's_jaw_lock': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_jaw_lock',
    status: _PsdkPortStatus.partial,
  ),
  's_lash_out': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.lashOut',
    status: _PsdkPortStatus.partial,
  ),
  's_last_respects': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_last_respects',
    status: _PsdkPortStatus.partial,
  ),
  's_magic_powder': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_magic_powder)',
    status: _PsdkPortStatus.partial,
  ),
  's_make_it_rain': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_make_it_rain',
    status: _PsdkPortStatus.partial,
  ),
  's_no_retreat': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_no_retreat)',
    status: _PsdkPortStatus.partial,
  ),
  's_octolock': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_octolock)',
    status: _PsdkPortStatus.partial,
  ),
  's_order_up': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_order_up)',
    status: _PsdkPortStatus.partial,
  ),
  's_poltergeist': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_poltergeist',
    status: _PsdkPortStatus.partial,
  ),
  's_pre_attack_base': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_pre_attack_base)',
    status: _PsdkPortStatus.partial,
  ),
  's_rage_fist': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.rageFist',
    status: _PsdkPortStatus.partial,
  ),
  's_raging_bull': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_raging_bull',
    status: _PsdkPortStatus.partial,
  ),
  's_revival_blessing': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialTargetMarker(s_revival_blessing)',
    status: _PsdkPortStatus.partial,
  ),
  's_rising_voltage': _KnownDartBehavior(
    dartBehavior: 'TerrainPowerMoveBehavior.risingVoltage',
    status: _PsdkPortStatus.partial,
  ),
  's_salt_cure': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.saltCure',
    status: _PsdkPortStatus.partial,
  ),
  's_sappy_seed': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_sappy_seed',
    status: _PsdkPortStatus.partial,
  ),
  's_scale_shot': _KnownDartBehavior(
    dartBehavior: 'MultiHitMoveBehavior.scaleShot',
    status: _PsdkPortStatus.partial,
  ),
  's_shed_tail': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_shed_tail)',
    status: _PsdkPortStatus.partial,
  ),
  's_shell_side_arm': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_shell_side_arm',
    status: _PsdkPortStatus.partial,
  ),
  's_steel_roller': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_steel_roller',
    status: _PsdkPortStatus.partial,
  ),
  's_stuff_cheeks': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_stuff_cheeks)',
    status: _PsdkPortStatus.partial,
  ),
  's_super_duper_effective': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_super_duper_effective',
    status: _PsdkPortStatus.partial,
  ),
  's_syrup_bomb': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.syrupBomb',
    status: _PsdkPortStatus.partial,
  ),
  's_tar_shot': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.tarShot',
    status: _PsdkPortStatus.partial,
  ),
  's_teatime': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_teatime)',
    status: _PsdkPortStatus.partial,
  ),
  's_terrain_pulse': _KnownDartBehavior(
    dartBehavior: 'TerrainPowerMoveBehavior.terrainPulse',
    status: _PsdkPortStatus.partial,
  ),
  's_tidy_up': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_tidy_up)',
    status: _PsdkPortStatus.partial,
  ),
  's_triple_arrows': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_triple_arrows',
    status: _PsdkPortStatus.partial,
  ),
  's_upper_hand': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_upper_hand)',
    status: _PsdkPortStatus.partial,
  ),
  's_basic': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_basic',
    status: _PsdkPortStatus.ported,
  ),
  's_status': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.status',
    status: _PsdkPortStatus.ported,
  ),
  's_stat': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.stat',
    status: _PsdkPortStatus.ported,
  ),
  's_self_stat': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.selfStat',
    status: _PsdkPortStatus.ported,
  ),
  's_self_status': _KnownDartBehavior(
    dartBehavior: 'StatusStatMoveBehavior.selfStatus',
    status: _PsdkPortStatus.ported,
  ),
  's_protect': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_protect',
    status: _PsdkPortStatus.partial,
  ),
  // These PSDK classes are Basic descendants whose regular hit/damage path is
  // executable locally. Their method-specific effects remain future work, so
  // they stay partial and carry explicit dependency tags below.
  's_avalanche': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.avalanche',
    status: _PsdkPortStatus.partial,
  ),
  's_assurance': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.assurance',
    status: _PsdkPortStatus.partial,
  ),
  's_attract': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.attract',
    status: _PsdkPortStatus.partial,
  ),
  's_beak_blast': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_beak_blast)',
    status: _PsdkPortStatus.partial,
  ),
  's_belch': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.belch',
    status: _PsdkPortStatus.partial,
  ),
  's_bind': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_bind',
    status: _PsdkPortStatus.partial,
  ),
  's_brick_break': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_brick_break',
    status: _PsdkPortStatus.partial,
  ),
  's_burn_up': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.burnUp',
    status: _PsdkPortStatus.partial,
  ),
  's_cantflee': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_cantflee',
    status: _PsdkPortStatus.partial,
  ),
  's_captivate': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.secondaryOnly(s_captivate)',
    status: _PsdkPortStatus.partial,
  ),
  's_ceaseless_edge': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_ceaseless_edge',
    status: _PsdkPortStatus.partial,
  ),
  's_charge': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_charge)',
    status: _PsdkPortStatus.partial,
  ),
  's_change_type': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_change_type',
    status: _PsdkPortStatus.partial,
  ),
  's_crafty_shield': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_crafty_shield)',
    status: _PsdkPortStatus.partial,
  ),
  's_defog': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_defog',
    status: _PsdkPortStatus.partial,
  ),
  's_core_enforcer': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_core_enforcer)',
    status: _PsdkPortStatus.partial,
  ),
  's_follow_me': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_follow_me',
    status: _PsdkPortStatus.partial,
  ),
  's_focus_energy': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_focus_energy)',
    status: _PsdkPortStatus.partial,
  ),
  's_focus_punch': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_focus_punch)',
    status: _PsdkPortStatus.partial,
  ),
  's_foresight': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_foresight',
    status: _PsdkPortStatus.partial,
  ),
  's_flying_press': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_flying_press)',
    status: _PsdkPortStatus.partial,
  ),
  's_future_sight': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_future_sight)',
    status: _PsdkPortStatus.partial,
  ),
  's_gastro_acid': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_gastro_acid)',
    status: _PsdkPortStatus.partial,
  ),
  's_gravity': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_gravity)',
    status: _PsdkPortStatus.partial,
  ),
  's_destiny_bond': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_destiny_bond)',
    status: _PsdkPortStatus.partial,
  ),
  's_disable': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.disable',
    status: _PsdkPortStatus.partial,
  ),
  's_electrify': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_electrify)',
    status: _PsdkPortStatus.partial,
  ),
  's_embargo': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_embargo)',
    status: _PsdkPortStatus.partial,
  ),
  's_encore': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.encore',
    status: _PsdkPortStatus.partial,
  ),
  's_entrainment': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialAbilityChanging(s_entrainment)',
    status: _PsdkPortStatus.partial,
  ),
  's_grudge': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_grudge)',
    status: _PsdkPortStatus.partial,
  ),
  's_happy_hour': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_happy_hour)',
    status: _PsdkPortStatus.partial,
  ),
  's_heal_block': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.healBlock',
    status: _PsdkPortStatus.partial,
  ),
  's_imprison': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.imprison',
    status: _PsdkPortStatus.partial,
  ),
  's_ion_deluge': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_ion_deluge)',
    status: _PsdkPortStatus.partial,
  ),
  's_lucky_chant': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialUserBankMarker(s_lucky_chant)',
    status: _PsdkPortStatus.partial,
  ),
  's_laser_focus': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_laser_focus)',
    status: _PsdkPortStatus.partial,
  ),
  's_lock_on': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_lock_on',
    status: _PsdkPortStatus.partial,
  ),
  's_magic_coat': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_magic_coat)',
    status: _PsdkPortStatus.partial,
  ),
  's_magic_room': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_magic_room)',
    status: _PsdkPortStatus.partial,
  ),
  's_magnet_rise': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_magnet_rise)',
    status: _PsdkPortStatus.partial,
  ),
  's_memento': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_memento',
    status: _PsdkPortStatus.partial,
  ),
  's_minimize': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_minimize)',
    status: _PsdkPortStatus.partial,
  ),
  's_mind_reader': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_mind_reader',
    status: _PsdkPortStatus.partial,
  ),
  's_miracle_eye': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_miracle_eye)',
    status: _PsdkPortStatus.partial,
  ),
  's_mist': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_mist)',
    status: _PsdkPortStatus.partial,
  ),
  's_multi_attack': _KnownDartBehavior(
    dartBehavior: 'TypeBasedMoveBehavior.multiAttack',
    status: _PsdkPortStatus.partial,
  ),
  's_nightmare': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_nightmare)',
    status: _PsdkPortStatus.partial,
  ),
  's_perish_song': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_perish_song)',
    status: _PsdkPortStatus.partial,
  ),
  's_parting_shot': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.secondaryOnly(s_parting_shot)',
    status: _PsdkPortStatus.partial,
  ),
  's_powder': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_powder)',
    status: _PsdkPortStatus.partial,
  ),
  's_plasma_fists': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_plasma_fists',
    status: _PsdkPortStatus.partial,
  ),
  's_quash': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_quash)',
    status: _PsdkPortStatus.partial,
  ),
  's_dragon_tail': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.forceSwitch(s_dragon_tail)',
    status: _PsdkPortStatus.partial,
  ),
  's_fake_out': _KnownDartBehavior(
    dartBehavior: 'ActionGatedMoveBehavior.fakeOut',
    status: _PsdkPortStatus.partial,
  ),
  's_feint': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_feint',
    status: _PsdkPortStatus.partial,
  ),
  's_fell_stinger': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_fell_stinger',
    status: _PsdkPortStatus.partial,
  ),
  's_flame_burst': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_flame_burst',
    status: _PsdkPortStatus.partial,
  ),
  's_fury_cutter': _KnownDartBehavior(
    dartBehavior: 'ConsecutivePowerMoveBehavior.furyCutter',
    status: _PsdkPortStatus.partial,
  ),
  's_fusion_bolt': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_fusion_bolt',
    status: _PsdkPortStatus.partial,
  ),
  's_fusion_flare': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_fusion_flare',
    status: _PsdkPortStatus.partial,
  ),
  's_hidden_power': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_hidden_power)',
    status: _PsdkPortStatus.partial,
  ),
  's_hurricane': _KnownDartBehavior(
    dartBehavior: 'WeatherPowerMoveBehavior.hurricane',
    status: _PsdkPortStatus.partial,
  ),
  's_ice_ball': _KnownDartBehavior(
    dartBehavior: 'ConsecutivePowerMoveBehavior.iceBall',
    status: _PsdkPortStatus.partial,
  ),
  's_incinerate': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.incinerate',
    status: _PsdkPortStatus.partial,
  ),
  's_judgment': _KnownDartBehavior(
    dartBehavior: 'TypeBasedMoveBehavior.judgment',
    status: _PsdkPortStatus.partial,
  ),
  's_jump_kick': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_jump_kick',
    status: _PsdkPortStatus.partial,
  ),
  's_knock_off': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.knockOff',
    status: _PsdkPortStatus.partial,
  ),
  's_last_resort': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_last_resort',
    status: _PsdkPortStatus.partial,
  ),
  's_outrage': _KnownDartBehavior(
    dartBehavior: 'ForcedActionMoveBehavior.outrage',
    status: _PsdkPortStatus.partial,
  ),
  's_payback': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.payback',
    status: _PsdkPortStatus.partial,
  ),
  's_payday': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_payday)',
    status: _PsdkPortStatus.partial,
  ),
  's_photon_geyser': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_photon_geyser',
    status: _PsdkPortStatus.partial,
  ),
  's_pledge': _KnownDartBehavior(
    dartBehavior: 'FieldLocationMoveBehavior.pledge',
    status: _PsdkPortStatus.partial,
  ),
  's_pluck': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.pluck',
    status: _PsdkPortStatus.partial,
  ),
  's_pollen_puff': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_pollen_puff',
    status: _PsdkPortStatus.partial,
  ),
  's_psychic_noise': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.psychicNoise',
    status: _PsdkPortStatus.partial,
  ),
  's_pursuit': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_pursuit',
    status: _PsdkPortStatus.partial,
  ),
  's_rage': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_rage',
    status: _PsdkPortStatus.partial,
  ),
  's_rapid_spin': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_rapid_spin',
    status: _PsdkPortStatus.partial,
  ),
  's_retaliate': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.retaliate',
    status: _PsdkPortStatus.partial,
  ),
  's_revenge': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.revenge',
    status: _PsdkPortStatus.partial,
  ),
  's_revelation_dance': _KnownDartBehavior(
    dartBehavior: 'TypeBasedMoveBehavior.revelationDance',
    status: _PsdkPortStatus.partial,
  ),
  's_relic_song': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.relicSong',
    status: _PsdkPortStatus.partial,
  ),
  's_reflect': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_reflect',
    status: _PsdkPortStatus.partial,
  ),
  's_reflect_type': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_reflect_type',
    status: _PsdkPortStatus.partial,
  ),
  's_reload': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_reload',
    status: _PsdkPortStatus.partial,
  ),
  's_roar': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.forceSwitch(s_roar)',
    status: _PsdkPortStatus.partial,
  ),
  's_rollout': _KnownDartBehavior(
    dartBehavior: 'ConsecutivePowerMoveBehavior.rollout',
    status: _PsdkPortStatus.partial,
  ),
  's_role_play': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialAbilityChanging(s_role_play)',
    status: _PsdkPortStatus.partial,
  ),
  's_round': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_round)',
    status: _PsdkPortStatus.partial,
  ),
  's_safe_guard': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_safe_guard)',
    status: _PsdkPortStatus.partial,
  ),
  's_secret_power': _KnownDartBehavior(
    dartBehavior: 'FieldLocationMoveBehavior.secretPower',
    status: _PsdkPortStatus.partial,
  ),
  's_shell_trap': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialBasic(s_shell_trap)',
    status: _PsdkPortStatus.partial,
  ),
  's_simple_beam': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialAbilityChanging(s_simple_beam)',
    status: _PsdkPortStatus.partial,
  ),
  's_snatch': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_snatch)',
    status: _PsdkPortStatus.partial,
  ),
  's_skill_swap': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialAbilityChanging(s_skill_swap)',
    status: _PsdkPortStatus.partial,
  ),
  's_snore': _KnownDartBehavior(
    dartBehavior: 'ActionGatedMoveBehavior.snore',
    status: _PsdkPortStatus.partial,
  ),
  's_solar_beam': _KnownDartBehavior(
    dartBehavior: 'WeatherPowerMoveBehavior.solarBeam',
    status: _PsdkPortStatus.partial,
  ),
  's_spectral_thief': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_spectral_thief',
    status: _PsdkPortStatus.partial,
  ),
  's_sky_drop': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_sky_drop',
    status: _PsdkPortStatus.partial,
  ),
  's_spike': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFoeBankMarker(s_spike)',
    status: _PsdkPortStatus.partial,
  ),
  's_stealth_rock': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialFoeBankMarker(s_stealth_rock)',
    status: _PsdkPortStatus.partial,
  ),
  's_stone_axe': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_stone_axe',
    status: _PsdkPortStatus.partial,
  ),
  's_sticky_web': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFoeBankMarker(s_sticky_web)',
    status: _PsdkPortStatus.partial,
  ),
  's_struggle': _KnownDartBehavior(
    dartBehavior: 'RecoilMoveBehavior.struggle',
    status: _PsdkPortStatus.partial,
  ),
  's_stockpile': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_stockpile',
    status: _PsdkPortStatus.partial,
  ),
  's_stomp': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_stomp',
    status: _PsdkPortStatus.partial,
  ),
  's_stomping_tantrum': _KnownDartBehavior(
    dartBehavior: 'HistoryPowerMoveBehavior.stompingTantrum',
    status: _PsdkPortStatus.partial,
  ),
  's_substitute': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_substitute',
    status: _PsdkPortStatus.partial,
  ),
  's_sucker_punch': _KnownDartBehavior(
    dartBehavior: 'ActionGatedMoveBehavior.suckerPunch',
    status: _PsdkPortStatus.partial,
  ),
  's_synchronoise': _KnownDartBehavior(
    dartBehavior: 'FieldLocationMoveBehavior.synchronoise',
    status: _PsdkPortStatus.partial,
  ),
  's_techno_blast': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.technoBlast',
    status: _PsdkPortStatus.partial,
  ),
  's_tailwind': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_tailwind)',
    status: _PsdkPortStatus.partial,
  ),
  's_taunt': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_taunt)',
    status: _PsdkPortStatus.partial,
  ),
  's_telekinesis': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_telekinesis)',
    status: _PsdkPortStatus.partial,
  ),
  's_thief': _KnownDartBehavior(
    dartBehavior: 'ItemDependentMoveBehavior.thief',
    status: _PsdkPortStatus.partial,
  ),
  's_thrash': _KnownDartBehavior(
    dartBehavior: 'ForcedActionMoveBehavior.thrash',
    status: _PsdkPortStatus.partial,
  ),
  's_throat_chop': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.throatChop',
    status: _PsdkPortStatus.partial,
  ),
  's_smack_down': _KnownDartBehavior(
    dartBehavior: 'GroundingMoveBehavior.smackDown',
    status: _PsdkPortStatus.partial,
  ),
  's_thunder': _KnownDartBehavior(
    dartBehavior: 'WeatherPowerMoveBehavior.thunder',
    status: _PsdkPortStatus.partial,
  ),
  's_thing_sport': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_thing_sport',
    status: _PsdkPortStatus.partial,
  ),
  's_torment': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_torment)',
    status: _PsdkPortStatus.partial,
  ),
  's_toxic_spike': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFoeBankMarker(s_toxic_spike)',
    status: _PsdkPortStatus.partial,
  ),
  's_toxic_thread': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.secondaryOnly(s_toxic_thread)',
    status: _PsdkPortStatus.partial,
  ),
  's_trick': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_trick',
    status: _PsdkPortStatus.partial,
  ),
  's_trick_room': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_trick_room)',
    status: _PsdkPortStatus.partial,
  ),
  's_tri_attack': _KnownDartBehavior(
    dartBehavior: 'SpecialSecondaryMoveBehavior.triAttack',
    status: _PsdkPortStatus.partial,
  ),
  's_trump_card': _KnownDartBehavior(
    dartBehavior: 'ConsecutivePowerMoveBehavior.trumpCard',
    status: _PsdkPortStatus.partial,
  ),
  's_u_turn': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.s_u_turn',
    status: _PsdkPortStatus.partial,
  ),
  's_uproar': _KnownDartBehavior(
    dartBehavior: 'ForcedActionMoveBehavior.uproar',
    status: _PsdkPortStatus.partial,
  ),
  's_wish': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_wish)',
    status: _PsdkPortStatus.partial,
  ),
  's_wonder_room': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_wonder_room)',
    status: _PsdkPortStatus.partial,
  ),
  's_worry_seed': _KnownDartBehavior(
    dartBehavior:
        'StaticBasicMoveRegistry.partialAbilityChanging(s_worry_seed)',
    status: _PsdkPortStatus.partial,
  ),
  's_yawn': _KnownDartBehavior(
    dartBehavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_yawn)',
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
  's_a_fang': _KnownDartBehavior(
    dartBehavior: 'BasicDamageSpecializationMoveBehavior.fangs',
    status: _PsdkPortStatus.partial,
  ),
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
  // OHKO's direct HP removal is executable after the shared procedure hits,
  // but level-based hit chance and Sheer Cold's Ice immunity still belong to
  // future accuracy/effect hooks.
  's_ohko': _KnownDartBehavior(
    dartBehavior: 'OhkoMoveBehavior',
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
  // Pain Split shares current HP locally and bypasses accuracy like PSDK. It
  // stays partial until Substitute/authentic effect handling is available.
  's_pain_split': _KnownDartBehavior(
    dartBehavior: 'DirectHpMoveBehavior.painSplit',
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
  's_ingrain': _KnownDartBehavior(
    dartBehavior: 'PersistentEffectMoveBehavior.ingrain',
    status: _PsdkPortStatus.partial,
  ),
  's_leech_seed': _KnownDartBehavior(
    dartBehavior: 'PersistentEffectMoveBehavior.leechSeed',
    status: _PsdkPortStatus.partial,
  ),
  's_baton_pass': _KnownDartBehavior(
    dartBehavior: 'SwitchEffectMoveBehavior.batonPass',
    status: _PsdkPortStatus.partial,
  ),
  // Transform copies target battle-visible form, stats, ability, stages and
  // moves. It stays partial until switch-out cleanup, Imposter and Illusion
  // initialization hooks are fully ported.
  's_transform': _KnownDartBehavior(
    dartBehavior: 'TransformMoveBehavior',
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
  // Psycho Shift transfers the user's major status through the local status
  // handler. It remains partial until status target-immunity events,
  // Substitute/effect interception and multi-target process hooks match PSDK.
  's_psycho_shift': _KnownDartBehavior(
    dartBehavior: 'PsychoShiftMoveBehavior',
    status: _PsdkPortStatus.partial,
  ),
  // Purify executes its local cure + half-max user heal. It stays partial
  // until status cure process hooks, Substitute interception and multi-target
  // status checks match Ruby PSDK.
  's_purify': _KnownDartBehavior(
    dartBehavior: 'PurifyMoveBehavior',
    status: _PsdkPortStatus.partial,
  ),
  's_heal_bell': _KnownDartBehavior(
    dartBehavior: 'StatusCureMoveBehavior.healBell',
    status: _PsdkPortStatus.partial,
  ),
  's_take_heart': _KnownDartBehavior(
    dartBehavior: 'StatusCureMoveBehavior.takeHeart',
    status: _PsdkPortStatus.partial,
  ),
  's_sparkly_swirl': _KnownDartBehavior(
    dartBehavior: 'StatusCureMoveBehavior.sparklySwirl',
    status: _PsdkPortStatus.partial,
  ),
  // Recovery/stat moves execute their local HP/status/stat formulas. They stay
  // partial until terrain grounding, full berry/drain-family item coverage,
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
  's_power_split': _KnownDartBehavior(
    dartBehavior: 'StatSplitMoveBehavior.power',
    status: _PsdkPortStatus.ported,
  ),
  's_guard_split': _KnownDartBehavior(
    dartBehavior: 'StatSplitMoveBehavior.guard',
    status: _PsdkPortStatus.ported,
  ),
  's_power_trick': _KnownDartBehavior(
    dartBehavior: 'PowerTrickMoveBehavior',
    status: _PsdkPortStatus.ported,
  ),
  's_speed_swap': _KnownDartBehavior(
    dartBehavior: 'SpeedSwapMoveBehavior',
    status: _PsdkPortStatus.ported,
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
  's_sacred_sword': _KnownDartBehavior(
    dartBehavior: 'CustomStatSourceMoveBehavior.sacredSword',
    status: _PsdkPortStatus.partial,
  ),
};

const _manualDependencies = <String, Set<_PsdkMoveDependency>>{
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
  's_transform': {
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_2turns': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.actionOrder,
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.targetingMulti,
  },
  's_add_type': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_bind': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.handlerSwitch,
  },
  's_brick_break': {
    _PsdkMoveDependency.effects,
  },
  's_cantflee': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerSwitch,
  },
  's_follow_me': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.actionOrder,
    _PsdkMoveDependency.targetingMulti,
  },
  's_foresight': {
    _PsdkMoveDependency.effects,
  },
  's_future_sight': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.endTurn,
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerSwitch,
  },
  's_dragon_tail': {
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_hurricane': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.accuracy,
    _PsdkMoveDependency.handlerStatus,
  },
  's_ice_ball': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.accuracy,
  },
  's_outrage': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.history,
  },
  's_pledge': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.field,
    _PsdkMoveDependency.targetingMulti,
    _PsdkMoveDependency.actionOrder,
  },
  's_pluck': {
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
  },
  's_psychic_noise': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_retaliate': {
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.faintProcess,
  },
  's_revenge': {
    _PsdkMoveDependency.history,
  },
  's_revelation_dance': {
    _PsdkMoveDependency.effects,
  },
  's_reflect': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.weather,
  },
  's_reflect_type': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_reload': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.actionOrder,
  },
  's_roar': {
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_rollout': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.accuracy,
  },
  's_role_play': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_round': {
    _PsdkMoveDependency.actionOrder,
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.targetingMulti,
  },
  's_safe_guard': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerStatus,
  },
  's_secret_power': {
    _PsdkMoveDependency.field,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.handlerStat,
  },
  's_simple_beam': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_skill_swap': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_smack_down': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.grounded,
    _PsdkMoveDependency.targetingMulti,
  },
  's_snore': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.ability,
  },
  's_spike': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.grounded,
  },
  's_stealth_rock': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerSwitch,
  },
  's_sticky_web': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.grounded,
  },
  's_stomping_tantrum': {
    _PsdkMoveDependency.history,
  },
  's_sucker_punch': {
    _PsdkMoveDependency.actionOrder,
  },
  's_synchronoise': {
    _PsdkMoveDependency.targetingMulti,
  },
  's_tailwind': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.actionOrder,
  },
  's_taunt': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.actionOrder,
  },
  's_techno_blast': {
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
  },
  's_thief': {
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_thrash': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.history,
  },
  's_throat_chop': {
    _PsdkMoveDependency.effects,
  },
  's_thunder': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.accuracy,
  },
  's_thing_sport': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.field,
  },
  's_torment': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.history,
  },
  's_toxic_spike': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.grounded,
  },
  's_trick': {
    _PsdkMoveDependency.handlerItem,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
  },
  's_trick_room': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.actionOrder,
    _PsdkMoveDependency.field,
  },
  's_tri_attack': {
    _PsdkMoveDependency.handlerStatus,
  },
  's_trump_card': {
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.accuracy,
    _PsdkMoveDependency.effects,
  },
  's_u_turn': {
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.ability,
  },
  's_uproar': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.history,
    _PsdkMoveDependency.targetingMulti,
  },
  's_wish': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.endTurn,
    _PsdkMoveDependency.handlerSwitch,
  },
  's_wonder_room': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerStat,
    _PsdkMoveDependency.field,
  },
  's_worry_seed': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.effects,
  },
  's_yawn': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.terrain,
  },
  's_solar_beam': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.effects,
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
  's_a_fang': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
  's_ohko': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
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
  's_pain_split': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
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
  's_ingrain': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.endTurn,
    _PsdkMoveDependency.item,
  },
  's_leech_seed': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.endTurn,
    _PsdkMoveDependency.ability,
  },
  's_baton_pass': {
    _PsdkMoveDependency.handlerSwitch,
    _PsdkMoveDependency.effects,
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
  's_psycho_shift': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.targetingMulti,
  },
  's_purify': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.targetingMulti,
  },
  's_heal_bell': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.targetingMulti,
  },
  's_take_heart': {
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.targetingMulti,
  },
  's_sparkly_swirl': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.handlerStatus,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.targetingMulti,
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
  's_sacred_sword': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.effects,
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
  accuracy('accuracy', 'accuracy'),
  history('history', 'history'),
  grounded('grounded', 'grounded'),
  faintProcess('faint_process', 'faintProcess'),
  runtimeBridge('runtime_bridge', 'runtimeBridge'),
  actionOrder('action_order', 'actionOrder');

  const _PsdkMoveDependency(this.token, this.dartName);

  final String token;
  final String dartName;
}
