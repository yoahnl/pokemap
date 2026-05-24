# PSDK Fight Convergence Dashboard

Generated: 2026-05-24T20:46:53.064131Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 728 / 728 | 100.0% | 0 |
| Methods | 330 / 330 | 100.0% | 0 |
| Effects | 442 / 482 | 91.7% | 40 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 231 | 5 | 18 | 23 |
| field | 15 | 0 | 0 | 0 |
| item | 87 | 0 | 0 | 0 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 98 | 14 | 3 | 17 |
| status | 7 | 0 | 0 | 0 |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| post_damage | 4 | 5 | 9 |
| switch | 1 | 8 | 9 |
| move_prevention | 0 | 3 | 3 |
| unclassified | 0 | 3 | 3 |
| ability_change | 1 | 1 | 2 |
| action_order | 0 | 2 | 2 |
| weather_change | 1 | 1 | 2 |
| accuracy | 0 | 1 | 1 |
| end_turn | 0 | 1 | 1 |
| item_change | 0 | 1 | 1 |
| stat_change | 0 | 1 | 1 |
| terrain_change | 0 | 1 | 1 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (23 remaining effects).
