# PSDK Fight Convergence Dashboard

Generated: 2026-05-24T16:30:12.254692Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 716 / 728 | 98.4% | 12 |
| Methods | 326 / 330 | 98.8% | 4 |
| Effects | 407 / 482 | 84.4% | 75 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 214 | 5 | 35 | 40 |
| field | 15 | 0 | 0 | 0 |
| item | 81 | 0 | 6 | 6 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 86 | 9 | 20 | 29 |
| status | 7 | 0 | 0 | 0 |

## Method Backlog

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Action queue / copy-call residuals | 1 | `s_shell_trap` |
| Effect hook / manifest final sweep | 3 | `s_magic_coat`, `s_revival_blessing`, `s_snatch` |

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
