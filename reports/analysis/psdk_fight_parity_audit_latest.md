# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 378 |
| Studio attacks `partiel` | 350 |
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
| s_fell_stinger | 1 |
| s_final_gambit | 1 |
| s_fling | 1 |
| s_floral_healing | 1 |
| s_flower_shield | 1 |
| s_flying_press | 1 |
| s_follow_me | 3 |
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
| s_plasma_fists | 1 |
| s_pluck | 2 |
| s_powder | 1 |
| s_protect | 3 |
| s_psycho_shift | 1 |
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
| s_struggle | 1 |
| s_swallow | 1 |
| s_teleport | 1 |
| s_thief | 2 |
| s_thing_sport | 2 |
| s_thrash | 1 |
| s_torment | 1 |
| s_toxic_thread | 1 |
| s_trick | 2 |
| s_trump_card | 1 |
| s_u_turn | 2 |
| s_uproar | 1 |
| s_venom_drench | 1 |
| s_wakeup_slap | 1 |
| s_wish | 1 |
| s_wonder_room | 1 |
| s_worry_seed | 1 |
| s_z_move | 10 |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 194 |
| `partial` | 136 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |
| effects | 126 |
| ability | 46 |
| handlerDamage | 31 |
| item | 27 |
| handlerStatus | 18 |
| targetingMulti | 14 |
| field | 12 |
| history | 11 |
| handlerSwitch | 7 |
| handlerStat | 6 |
| accuracy | 5 |
| endTurn | 5 |
| grounded | 3 |
| terrain | 3 |
| faintProcess | 2 |
| handlerItem | 1 |

### Partial Method Batches

Each partial method is assigned to its first actionable Phase 2 batch.

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Damage formula / variable power | 36 | `s_aqua_ring`, `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_bide`, `s_core_enforcer`, `s_double_iron_bash`, `s_dragon_darts`, `s_floral_healing`, `s_flying_press`, `s_frustration`, `s_future_sight`, `s_hidden_power`, `s_ice_ball`, `s_ingrain`, `s_jungle_healing`, `s_leech_seed`, `s_life_dew`, `s_ohko`, `s_order_up`, `s_pain_split`, `s_payday`, `s_pre_attack_base`, `s_purify`, `s_return`, `s_rollout`, `s_roost`, `s_scale_shot`, `s_shell_trap`, `s_smelling_salt`, `s_sparkling_aria`, `s_sparkly_swirl`, `s_split_up`, `s_trump_card`, `s_upper_hand`, `s_wakeup_slap` |
| Effect hook / manifest final sweep | 100 | `s_a_fang`, `s_add_type`, `s_attract`, `s_autotomize`, `s_baton_pass`, `s_bestow`, `s_camouflage`, `s_captivate`, `s_change_type`, `s_chilly_reception`, `s_conversion`, `s_conversion2`, `s_corrosive_gas`, `s_court_change`, `s_destiny_bond`, `s_disable`, `s_doodle`, `s_dragon_cheer`, `s_dragon_tail`, `s_electrify`, `s_embargo`, `s_encore`, `s_entrainment`, `s_expanding_force`, `s_fell_stinger`, `s_final_gambit`, `s_fling`, `s_flower_shield`, `s_follow_me`, `s_fusion_bolt`, `s_fusion_flare`, `s_gear_up`, `s_geomancy`, `s_gravity`, `s_grudge`, `s_happy_hour`, `s_heal_bell`, `s_heal_block`, `s_healing_wish`, `s_helping_hand`, `s_imprison`, `s_ion_deluge`, `s_knock_off`, `s_lock_on`, `s_lunar_dance`, `s_magic_coat`, `s_magic_powder`, `s_magic_room`, `s_magnetic_flux`, `s_magnitude`, `s_make_it_rain`, `s_mind_reader`, `s_misty_explosion`, `s_nature_power`, `s_nightmare`, `s_no_retreat`, `s_outrage`, `s_parting_shot`, `s_perish_song`, `s_plasma_fists`, `s_pluck`, `s_powder`, `s_psycho_shift`, `s_pursuit`, `s_rage`, `s_raging_bull`, `s_reflect_type`, `s_revival_blessing`, `s_roar`, `s_role_play`, `s_rototiller`, `s_secret_power`, `s_shed_tail`, `s_shell_side_arm`, `s_simple_beam`, `s_skill_swap`, `s_smack_down`, `s_snatch`, `s_spectral_thief`, `s_spite`, `s_stockpile`, `s_struggle`, `s_stuff_cheeks`, `s_swallow`, `s_take_heart`, `s_teatime`, `s_teleport`, `s_thief`, `s_thing_sport`, `s_thrash`, `s_torment`, `s_toxic_thread`, `s_trick`, `s_u_turn`, `s_uproar`, `s_venom_drench`, `s_water_shuriken`, `s_wish`, `s_wonder_room`, `s_worry_seed` |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 368 |
| `partial` | 31 |
| `missing` | 83 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 195 | 17 | 42 |
| field | 15 | 0 | 0 |
| item | 64 | 6 | 17 |
| mechanics | 4 | 0 | 0 |
| move | 83 | 8 | 24 |
| status | 7 | 0 | 0 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |
| ability | 42 |
| item | 17 |
| move | 24 |

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
