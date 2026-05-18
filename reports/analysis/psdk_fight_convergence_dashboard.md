# PSDK Fight Convergence Dashboard

Generated: 2026-05-18T08:39:42.487789Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 343 / 728 | 47.1% | 385 |
| Methods | 149 / 330 | 45.2% | 181 |
| Effects | 206 / 482 | 42.7% | 276 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 55 | 2 | 197 | 199 |
| field | 15 | 0 | 0 | 0 |
| item | 45 | 10 | 32 | 42 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 80 | 8 | 27 | 35 |
| status | 7 | 0 | 0 | 0 |

## Method Backlog

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Action queue / copy-call residuals | 24 | `s_after_you`, `s_assist`, `s_bide`, `s_double_iron_bash`, `s_electrify`, `s_final_gambit`, `s_follow_me`, `s_ice_ball`, `s_instruct`, `s_me_first`, `s_metronome`, `s_mimic`, `s_mirror_move`, `s_outrage`, `s_quash`, `s_rollout`, `s_scale_shot`, `s_sketch`, `s_sleep_talk`, `s_thrash`, `s_torment`, `s_triple_kick`, `s_trump_card`, `s_uproar` |
| Target resolution / doubles topology | 11 | `s_expanding_force`, `s_heal_bell`, `s_helping_hand`, `s_jungle_healing`, `s_life_dew`, `s_psycho_shift`, `s_purify`, `s_smack_down`, `s_sparkly_swirl`, `s_synchronoise`, `s_take_heart` |
| Failure / prevention / immunity | 21 | `s_a_fang`, `s_baton_pass`, `s_captivate`, `s_chloroblast`, `s_dragon_tail`, `s_explosion`, `s_mind_blown`, `s_misty_explosion`, `s_parting_shot`, `s_roar`, `s_secret_power`, `s_smelling_salt`, `s_sparkling_aria`, `s_steel_beam`, `s_toxic_thread`, `s_trick`, `s_u_turn`, `s_venom_drench`, `s_wakeup_slap`, `s_wonder_room`, `s_yawn` |
| Multi-turn / delayed state | 5 | `s_aqua_ring`, `s_future_sight`, `s_ingrain`, `s_leech_seed`, `s_wish` |
| Damage formula / variable power | 49 | `s_add_type`, `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_bestow`, `s_body_press`, `s_camouflage`, `s_chilly_reception`, `s_core_enforcer`, `s_court_change`, `s_custom_stats_based`, `s_dragon_darts`, `s_entrainment`, `s_fairy_lock`, `s_fling`, `s_floral_healing`, `s_flying_press`, `s_foul_play`, `s_frustration`, `s_gravity`, `s_happy_hour`, `s_hidden_power`, `s_ion_deluge`, `s_knock_off`, `s_magic_room`, `s_nature_power`, `s_ohko`, `s_order_up`, `s_pain_split`, `s_payday`, `s_pluck`, `s_population_bomb`, `s_pre_attack_base`, `s_psyshock`, `s_reflect_type`, `s_return`, `s_role_play`, `s_roost`, `s_sacred_sword`, `s_shell_trap`, `s_simple_beam`, `s_skill_swap`, `s_split_up`, `s_teatime`, `s_thief`, `s_thing_sport`, `s_upper_hand`, `s_water_shuriken`, `s_worry_seed` |
| Effect hook / manifest final sweep | 71 | `s_attract`, `s_autotomize`, `s_baddy_bad`, `s_brick_break`, `s_change_type`, `s_conversion`, `s_conversion2`, `s_corrosive_gas`, `s_destiny_bond`, `s_disable`, `s_doodle`, `s_dragon_cheer`, `s_eerie_spell`, `s_embargo`, `s_encore`, `s_false_swipe`, `s_fell_stinger`, `s_fickle_beam`, `s_flame_burst`, `s_flower_shield`, `s_fusion_bolt`, `s_fusion_flare`, `s_gear_up`, `s_geomancy`, `s_glaive_rush`, `s_glitzy_glow`, `s_grav_apple`, `s_grudge`, `s_heal_block`, `s_healing_wish`, `s_ice_spinner`, `s_imprison`, `s_jaw_lock`, `s_jump_kick`, `s_last_respects`, `s_lock_on`, `s_lunar_dance`, `s_magic_coat`, `s_magic_powder`, `s_magnetic_flux`, `s_magnitude`, `s_make_it_rain`, `s_mind_reader`, `s_nightmare`, `s_no_retreat`, `s_octolock`, `s_perish_song`, `s_photon_geyser`, `s_plasma_fists`, `s_powder`, `s_pursuit`, `s_rage`, `s_raging_bull`, `s_revival_blessing`, `s_rototiller`, `s_sappy_seed`, `s_shed_tail`, `s_shell_side_arm`, `s_snatch`, `s_spectral_thief`, `s_spite`, `s_steel_roller`, `s_stockpile`, `s_stomp`, `s_struggle`, `s_stuff_cheeks`, `s_substitute`, `s_super_duper_effective`, `s_swallow`, `s_teleport`, `s_triple_arrows` |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| unclassified | 0 | 64 | 64 |
| post_damage | 0 | 48 | 48 |
| switch | 2 | 43 | 45 |
| status_prevention | 0 | 16 | 16 |
| end_turn | 1 | 11 | 12 |
| stat_change | 0 | 11 | 11 |
| move_prevention | 0 | 9 | 9 |
| action_order | 0 | 8 | 8 |
| weather_change | 1 | 5 | 6 |
| ability_change | 0 | 4 | 4 |
| damage_prevention | 0 | 4 | 4 |
| item_change | 0 | 4 | 4 |
| ability_immunity | 0 | 3 | 3 |
| terrain_change | 0 | 2 | 2 |
| accuracy | 0 | 1 | 1 |
| damage_change | 0 | 1 | 1 |
| drain | 0 | 1 | 1 |

## Item Effect Backlog

| Batch | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| damage/type/stat modifiers | 3 | 2 | 5 |
| berries | 1 | 5 | 6 |
| focus/eject/choice/orb | 1 | 4 | 5 |
| weather/terrain/field | 0 | 1 | 1 |
| held-item lifecycle and consumption | 5 | 20 | 25 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (199 remaining effects).
