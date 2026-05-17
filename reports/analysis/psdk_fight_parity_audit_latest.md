# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 299 |
| Studio attacks `partiel` | 429 |
| Studio attacks `pas_fait` | 0 |
| Unknown methods | 0 |
| Unique battle engine methods | 258 |

### Partial Attacks by Method

| Battle method | Partial attacks |
| --- | ---: |
| s_2turns | 7 |
| s_a_fang | 3 |
| s_absorb | 2 |
| s_acupressure | 1 |
| s_add_type | 2 |
| s_after_you | 1 |
| s_aqua_ring | 1 |
| s_assist | 1 |
| s_attract | 1 |
| s_autotomize | 1 |
| s_basic | 148 |
| s_baton_pass | 1 |
| s_beak_blast | 1 |
| s_beat_up | 1 |
| s_bellydrum | 1 |
| s_bestow | 1 |
| s_bide | 1 |
| s_brick_break | 2 |
| s_camouflage | 1 |
| s_captivate | 1 |
| s_change_type | 1 |
| s_charge | 1 |
| s_conversion | 1 |
| s_conversion2 | 1 |
| s_core_enforcer | 1 |
| s_curse | 1 |
| s_destiny_bond | 1 |
| s_disable | 1 |
| s_dragon_tail | 2 |
| s_dream_eater | 1 |
| s_echo | 1 |
| s_electrify | 1 |
| s_embargo | 1 |
| s_encore | 1 |
| s_entrainment | 1 |
| s_explosion | 2 |
| s_fake_out | 1 |
| s_false_swipe | 2 |
| s_feint | 1 |
| s_fell_stinger | 1 |
| s_final_gambit | 1 |
| s_flame_burst | 1 |
| s_fling | 1 |
| s_floral_healing | 1 |
| s_flower_shield | 1 |
| s_flying_press | 1 |
| s_focus_energy | 1 |
| s_focus_punch | 1 |
| s_follow_me | 3 |
| s_foresight | 2 |
| s_foul_play | 1 |
| s_frustration | 1 |
| s_fusion_bolt | 1 |
| s_fusion_flare | 1 |
| s_future_sight | 2 |
| s_gastro_acid | 1 |
| s_gear_up | 1 |
| s_genesis_supernova | 1 |
| s_gravity | 1 |
| s_growth | 1 |
| s_grudge | 1 |
| s_guard_swap | 1 |
| s_guardian_of_alola | 1 |
| s_happy_hour | 1 |
| s_haze | 2 |
| s_heal | 1 |
| s_heal_bell | 3 |
| s_heal_block | 1 |
| s_healing_wish | 1 |
| s_heart_swap | 1 |
| s_helping_hand | 1 |
| s_hidden_power | 1 |
| s_hyperspace_hole | 1 |
| s_ice_ball | 1 |
| s_imprison | 1 |
| s_incinerate | 1 |
| s_ingrain | 1 |
| s_instruct | 1 |
| s_ion_deluge | 1 |
| s_jump_kick | 2 |
| s_knock_off | 1 |
| s_laser_focus | 1 |
| s_last_resort | 1 |
| s_leech_seed | 1 |
| s_light_that_burns_the_sky | 1 |
| s_lock_on | 1 |
| s_lunar_dance | 1 |
| s_magic_coat | 1 |
| s_magic_room | 1 |
| s_magnet_rise | 1 |
| s_magnetic_flux | 1 |
| s_magnitude | 1 |
| s_malicious_moonsault | 1 |
| s_me_first | 1 |
| s_metronome | 1 |
| s_mimic | 1 |
| s_mind_reader | 1 |
| s_minimize | 1 |
| s_miracle_eye | 1 |
| s_mirror_move | 2 |
| s_multi_hit | 1 |
| s_nature_power | 1 |
| s_nightmare | 1 |
| s_ohko | 4 |
| s_outrage | 2 |
| s_pain_split | 1 |
| s_parting_shot | 1 |
| s_payday | 1 |
| s_perish_song | 1 |
| s_photon_geyser | 1 |
| s_plasma_fists | 1 |
| s_pledge | 3 |
| s_pluck | 2 |
| s_pollen_puff | 1 |
| s_powder | 1 |
| s_power_swap | 1 |
| s_protect | 3 |
| s_psych_up | 1 |
| s_psycho_shift | 1 |
| s_psyshock | 2 |
| s_purify | 1 |
| s_pursuit | 1 |
| s_quash | 1 |
| s_rage | 1 |
| s_recoil | 4 |
| s_reflect_type | 1 |
| s_relic_song | 1 |
| s_return | 1 |
| s_roar | 2 |
| s_role_play | 1 |
| s_rollout | 1 |
| s_roost | 1 |
| s_rototiller | 1 |
| s_round | 1 |
| s_sacred_sword | 3 |
| s_secret_power | 1 |
| s_self_stat | 27 |
| s_self_stat_z_move | 2 |
| s_shell_trap | 1 |
| s_simple_beam | 1 |
| s_sketch | 1 |
| s_skill_swap | 1 |
| s_sky_drop | 1 |
| s_sleep_talk | 1 |
| s_smack_down | 2 |
| s_smelling_salt | 1 |
| s_snatch | 1 |
| s_snore | 1 |
| s_sparkling_aria | 1 |
| s_spectral_thief | 1 |
| s_spite | 1 |
| s_splash | 3 |
| s_splintered_stormshards | 1 |
| s_split_up | 1 |
| s_stat | 8 |
| s_status | 4 |
| s_stockpile | 1 |
| s_stomp | 4 |
| s_strength_sap | 1 |
| s_struggle | 1 |
| s_substitute | 1 |
| s_sucker_punch | 1 |
| s_swallow | 1 |
| s_synchronoise | 1 |
| s_telekinesis | 1 |
| s_teleport | 1 |
| s_thief | 2 |
| s_thing_sport | 2 |
| s_thrash | 1 |
| s_throat_chop | 1 |
| s_topsy_turvy | 1 |
| s_torment | 1 |
| s_toxic_thread | 1 |
| s_transform | 1 |
| s_tri_attack | 1 |
| s_trick | 2 |
| s_triple_kick | 1 |
| s_trump_card | 1 |
| s_u_turn | 2 |
| s_uproar | 1 |
| s_venom_drench | 1 |
| s_wakeup_slap | 1 |
| s_wish | 1 |
| s_wonder_room | 1 |
| s_worry_seed | 1 |
| s_yawn | 1 |
| s_z_move | 10 |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 101 |
| `partial` | 229 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |
| no_dependency_declared | 142 |
| effects | 64 |
| ability | 48 |
| handlerDamage | 26 |
| handlerStatus | 18 |
| handlerStat | 15 |
| item | 15 |
| targetingMulti | 15 |
| history | 10 |
| handlerSwitch | 8 |
| endTurn | 6 |
| faintProcess | 6 |
| actionOrder | 4 |
| field | 4 |
| terrain | 4 |
| accuracy | 3 |
| grounded | 3 |
| handlerItem | 1 |
| weather | 1 |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 0 |
| `partial` | 25 |
| `missing` | 457 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 0 | 3 | 251 |
| field | 0 | 0 | 15 |
| item | 0 | 0 | 87 |
| mechanics | 0 | 0 | 4 |
| move | 0 | 22 | 93 |
| status | 0 | 0 | 7 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |
| ability | 251 |
| field | 15 |
| item | 87 |
| mechanics | 4 |
| move | 93 |
| status | 7 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `not_measured` |
| Reason | Runtime bridge diagnostics live in packages/map_runtime and are opened by Lot 04. |
