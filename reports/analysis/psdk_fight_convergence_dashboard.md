# PSDK Fight Convergence Dashboard

Generated: 2026-05-24T21:13:11.170602Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 728 / 728 | 100.0% | 0 |
| Methods | 330 / 330 | 100.0% | 0 |
| Effects | 443 / 482 | 91.9% | 39 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 232 | 5 | 17 | 22 |
| field | 15 | 0 | 0 | 0 |
| item | 87 | 0 | 0 | 0 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 98 | 14 | 3 | 17 |
| status | 7 | 0 | 0 | 0 |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| switch | 1 | 8 | 9 |
| post_damage | 3 | 5 | 8 |
| move_prevention | 0 | 3 | 3 |
| unclassified | 0 | 3 | 3 |
| ability_change | 1 | 1 | 2 |
| action_order | 0 | 2 | 2 |
| weather_change | 1 | 1 | 2 |
| accuracy | 0 | 1 | 1 |
| end_turn | 0 | 1 | 1 |
| item_change | 0 | 1 | 1 |
| stat_change | 1 | 0 | 1 |
| terrain_change | 0 | 1 | 1 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (22 remaining effects).
