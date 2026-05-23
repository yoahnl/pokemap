# PSDK Fight Convergence Dashboard

Generated: 2026-05-23T11:55:29.728677Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 463 / 728 | 63.6% | 265 |
| Methods | 272 / 330 | 82.4% | 58 |
| Effects | 404 / 482 | 83.8% | 78 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 214 | 5 | 35 | 40 |
| field | 15 | 0 | 0 | 0 |
| item | 81 | 0 | 6 | 6 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 83 | 8 | 24 | 32 |
| status | 7 | 0 | 0 | 0 |

## Method Backlog

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Action queue / copy-call residuals | 1 | `s_electrify` |
| Damage formula / variable power | 15 | `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_core_enforcer`, `s_dragon_darts`, `s_flying_press`, `s_frustration`, `s_hidden_power`, `s_order_up`, `s_payday`, `s_pre_attack_base`, `s_return`, `s_shell_trap`, `s_split_up`, `s_upper_hand` |
| Effect hook / manifest final sweep | 42 | `s_chilly_reception`, `s_conversion`, `s_conversion2`, `s_court_change`, `s_destiny_bond`, `s_doodle`, `s_dragon_cheer`, `s_embargo`, `s_entrainment`, `s_flower_shield`, `s_gear_up`, `s_geomancy`, `s_gravity`, `s_grudge`, `s_happy_hour`, `s_healing_wish`, `s_helping_hand`, `s_ion_deluge`, `s_lunar_dance`, `s_magic_coat`, `s_magic_powder`, `s_magic_room`, `s_magnetic_flux`, `s_nightmare`, `s_no_retreat`, `s_perish_song`, `s_powder`, `s_revival_blessing`, `s_role_play`, `s_rototiller`, `s_shed_tail`, `s_simple_beam`, `s_skill_swap`, `s_snatch`, `s_spite`, `s_stuff_cheeks`, `s_swallow`, `s_teatime`, `s_teleport`, `s_wish`, `s_wonder_room`, `s_worry_seed` |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| switch | 1 | 17 | 18 |
| post_damage | 4 | 11 | 15 |
| unclassified | 0 | 5 | 5 |
| end_turn | 0 | 4 | 4 |
| weather_change | 1 | 3 | 4 |
| ability_change | 1 | 2 | 3 |
| move_prevention | 0 | 3 | 3 |
| action_order | 0 | 2 | 2 |
| damage_prevention | 0 | 2 | 2 |
| accuracy | 0 | 1 | 1 |
| damage_change | 0 | 1 | 1 |
| item_change | 0 | 1 | 1 |
| stat_change | 0 | 1 | 1 |
| status_prevention | 0 | 1 | 1 |
| terrain_change | 0 | 1 | 1 |

## Item Effect Backlog

| Batch | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| berries | 0 | 1 | 1 |
| focus/eject/choice/orb | 0 | 4 | 4 |
| held-item lifecycle and consumption | 0 | 1 | 1 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (40 remaining effects).
