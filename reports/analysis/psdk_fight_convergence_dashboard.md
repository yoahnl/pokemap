# PSDK Fight Convergence Dashboard

Generated: 2026-05-23T13:04:13.539412Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 658 / 728 | 90.4% | 70 |
| Methods | 306 / 330 | 92.7% | 24 |
| Effects | 406 / 482 | 84.2% | 76 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 214 | 5 | 35 | 40 |
| field | 15 | 0 | 0 | 0 |
| item | 81 | 0 | 6 | 6 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 85 | 8 | 22 | 30 |
| status | 7 | 0 | 0 | 0 |

## Method Backlog

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Damage formula / variable power | 14 | `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_core_enforcer`, `s_dragon_darts`, `s_frustration`, `s_hidden_power`, `s_order_up`, `s_payday`, `s_pre_attack_base`, `s_return`, `s_shell_trap`, `s_split_up`, `s_upper_hand` |
| Effect hook / manifest final sweep | 10 | `s_chilly_reception`, `s_court_change`, `s_doodle`, `s_geomancy`, `s_magic_coat`, `s_revival_blessing`, `s_shed_tail`, `s_snatch`, `s_swallow`, `s_teleport` |

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
