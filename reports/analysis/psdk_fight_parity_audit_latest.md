# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 354 |
| Studio attacks `partiel` | 374 |
| Studio attacks `pas_fait` | 0 |
| Unknown methods | 0 |
| Unique battle engine methods | 258 |

### Partial Attacks by Method

| Battle method | Partial attacks |
| --- | ---: |
| s_2turns | 7 |
| s_a_fang | 3 |
| s_absorb | 2 |
| s_add_type | 2 |
| s_aqua_ring | 1 |
| s_attract | 1 |
| s_autotomize | 1 |
| s_basic | 148 |
| s_baton_pass | 1 |
| s_beak_blast | 1 |
| s_beat_up | 1 |
| s_bestow | 1 |
| s_bide | 1 |
| s_brick_break | 2 |
| s_camouflage | 1 |
| s_captivate | 1 |
| s_change_type | 1 |
| s_conversion | 1 |
| s_conversion2 | 1 |
| s_core_enforcer | 1 |
| s_destiny_bond | 1 |
| s_disable | 1 |
| s_dragon_tail | 2 |
| s_electrify | 1 |
| s_embargo | 1 |
| s_encore | 1 |
| s_entrainment | 1 |
| s_explosion | 2 |
| s_false_swipe | 2 |
| s_fell_stinger | 1 |
| s_final_gambit | 1 |
| s_flame_burst | 1 |
| s_fling | 1 |
| s_floral_healing | 1 |
| s_flower_shield | 1 |
| s_flying_press | 1 |
| s_follow_me | 3 |
| s_foul_play | 1 |
| s_frustration | 1 |
| s_fusion_bolt | 1 |
| s_fusion_flare | 1 |
| s_future_sight | 2 |
| s_gear_up | 1 |
| s_genesis_supernova | 1 |
| s_gravity | 1 |
| s_grudge | 1 |
| s_guardian_of_alola | 1 |
| s_happy_hour | 1 |
| s_heal | 1 |
| s_heal_bell | 3 |
| s_heal_block | 1 |
| s_healing_wish | 1 |
| s_helping_hand | 1 |
| s_hidden_power | 1 |
| s_hyperspace_hole | 1 |
| s_ice_ball | 1 |
| s_imprison | 1 |
| s_ingrain | 1 |
| s_ion_deluge | 1 |
| s_jump_kick | 2 |
| s_knock_off | 1 |
| s_leech_seed | 1 |
| s_light_that_burns_the_sky | 1 |
| s_lock_on | 1 |
| s_lunar_dance | 1 |
| s_magic_coat | 1 |
| s_magic_room | 1 |
| s_magnetic_flux | 1 |
| s_magnitude | 1 |
| s_malicious_moonsault | 1 |
| s_mind_reader | 1 |
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
| s_pluck | 2 |
| s_powder | 1 |
| s_protect | 3 |
| s_psycho_shift | 1 |
| s_psyshock | 2 |
| s_purify | 1 |
| s_pursuit | 1 |
| s_rage | 1 |
| s_recoil | 4 |
| s_reflect_type | 1 |
| s_return | 1 |
| s_roar | 2 |
| s_role_play | 1 |
| s_rollout | 1 |
| s_roost | 1 |
| s_rototiller | 1 |
| s_sacred_sword | 3 |
| s_secret_power | 1 |
| s_self_stat | 27 |
| s_self_stat_z_move | 2 |
| s_shell_trap | 1 |
| s_simple_beam | 1 |
| s_skill_swap | 1 |
| s_smack_down | 2 |
| s_smelling_salt | 1 |
| s_snatch | 1 |
| s_sparkling_aria | 1 |
| s_spectral_thief | 1 |
| s_spite | 1 |
| s_splintered_stormshards | 1 |
| s_split_up | 1 |
| s_stat | 8 |
| s_status | 4 |
| s_stockpile | 1 |
| s_stomp | 4 |
| s_struggle | 1 |
| s_substitute | 1 |
| s_swallow | 1 |
| s_synchronoise | 1 |
| s_teleport | 1 |
| s_thief | 2 |
| s_thing_sport | 2 |
| s_thrash | 1 |
| s_torment | 1 |
| s_toxic_thread | 1 |
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
| `ported` | 159 |
| `partial` | 171 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |
| effects | 150 |
| ability | 57 |
| handlerDamage | 36 |
| item | 33 |
| handlerStatus | 19 |
| targetingMulti | 15 |
| field | 13 |
| history | 12 |
| handlerSwitch | 7 |
| faintProcess | 6 |
| handlerStat | 6 |
| accuracy | 5 |
| endTurn | 5 |
| terrain | 4 |
| grounded | 3 |
| handlerItem | 1 |

### Partial Method Batches

Each partial method is assigned to its first actionable Phase 2 batch.

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Target resolution / doubles topology | 15 | `s_double_iron_bash`, `s_expanding_force`, `s_follow_me`, `s_heal_bell`, `s_helping_hand`, `s_jungle_healing`, `s_life_dew`, `s_psycho_shift`, `s_purify`, `s_scale_shot`, `s_smack_down`, `s_sparkly_swirl`, `s_synchronoise`, `s_take_heart`, `s_uproar` |
| Failure / prevention / immunity | 24 | `s_a_fang`, `s_baton_pass`, `s_captivate`, `s_chloroblast`, `s_dragon_tail`, `s_explosion`, `s_final_gambit`, `s_mind_blown`, `s_misty_explosion`, `s_outrage`, `s_parting_shot`, `s_roar`, `s_secret_power`, `s_smelling_salt`, `s_sparkling_aria`, `s_steel_beam`, `s_thrash`, `s_toxic_thread`, `s_trick`, `s_u_turn`, `s_venom_drench`, `s_wakeup_slap`, `s_wonder_room`, `s_yawn` |
| Multi-turn / delayed state | 5 | `s_aqua_ring`, `s_future_sight`, `s_ingrain`, `s_leech_seed`, `s_wish` |
| Damage formula / variable power | 54 | `s_add_type`, `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_bestow`, `s_bide`, `s_body_press`, `s_camouflage`, `s_chilly_reception`, `s_core_enforcer`, `s_court_change`, `s_custom_stats_based`, `s_dragon_darts`, `s_entrainment`, `s_fairy_lock`, `s_fling`, `s_floral_healing`, `s_flying_press`, `s_foul_play`, `s_frustration`, `s_gravity`, `s_happy_hour`, `s_hidden_power`, `s_ice_ball`, `s_ion_deluge`, `s_knock_off`, `s_magic_room`, `s_nature_power`, `s_ohko`, `s_order_up`, `s_pain_split`, `s_payday`, `s_pluck`, `s_population_bomb`, `s_pre_attack_base`, `s_psyshock`, `s_reflect_type`, `s_return`, `s_role_play`, `s_rollout`, `s_roost`, `s_sacred_sword`, `s_shell_trap`, `s_simple_beam`, `s_skill_swap`, `s_split_up`, `s_teatime`, `s_thief`, `s_thing_sport`, `s_triple_kick`, `s_trump_card`, `s_upper_hand`, `s_water_shuriken`, `s_worry_seed` |
| Effect hook / manifest final sweep | 73 | `s_attract`, `s_autotomize`, `s_baddy_bad`, `s_brick_break`, `s_change_type`, `s_conversion`, `s_conversion2`, `s_corrosive_gas`, `s_destiny_bond`, `s_disable`, `s_doodle`, `s_dragon_cheer`, `s_eerie_spell`, `s_electrify`, `s_embargo`, `s_encore`, `s_false_swipe`, `s_fell_stinger`, `s_fickle_beam`, `s_flame_burst`, `s_flower_shield`, `s_fusion_bolt`, `s_fusion_flare`, `s_gear_up`, `s_geomancy`, `s_glaive_rush`, `s_glitzy_glow`, `s_grav_apple`, `s_grudge`, `s_heal_block`, `s_healing_wish`, `s_ice_spinner`, `s_imprison`, `s_jaw_lock`, `s_jump_kick`, `s_last_respects`, `s_lock_on`, `s_lunar_dance`, `s_magic_coat`, `s_magic_powder`, `s_magnetic_flux`, `s_magnitude`, `s_make_it_rain`, `s_mind_reader`, `s_nightmare`, `s_no_retreat`, `s_octolock`, `s_perish_song`, `s_photon_geyser`, `s_plasma_fists`, `s_powder`, `s_pursuit`, `s_rage`, `s_raging_bull`, `s_revival_blessing`, `s_rototiller`, `s_sappy_seed`, `s_shed_tail`, `s_shell_side_arm`, `s_snatch`, `s_spectral_thief`, `s_spite`, `s_steel_roller`, `s_stockpile`, `s_stomp`, `s_struggle`, `s_stuff_cheeks`, `s_substitute`, `s_super_duper_effective`, `s_swallow`, `s_teleport`, `s_torment`, `s_triple_arrows` |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 206 |
| `partial` | 20 |
| `missing` | 256 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 55 | 2 | 197 |
| field | 15 | 0 | 0 |
| item | 45 | 10 | 32 |
| mechanics | 4 | 0 | 0 |
| move | 80 | 8 | 27 |
| status | 7 | 0 | 0 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |
| ability | 197 |
| item | 32 |
| move | 27 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |
| Total moves | 28 |
| Bridgeable moves | 20 |
| Rejected moves | 8 |
| Explained rejected moves | 8 |
| Unexplained rejected moves | 0 |
