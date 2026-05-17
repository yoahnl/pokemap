# PSDK Fight Convergence Dashboard

Generated: 2026-05-17T22:47:37.524568Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 343 / 728 | 47.1% | 385 |
| Methods | 149 / 330 | 45.2% | 181 |
| Effects | 171 / 482 | 35.5% | 311 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 50 | 2 | 202 | 204 |
| field | 15 | 0 | 0 | 0 |
| item | 27 | 10 | 50 | 60 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 69 | 7 | 39 | 46 |
| status | 6 | 0 | 1 | 1 |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| unclassified | 0 | 64 | 64 |
| post_damage | 0 | 48 | 48 |
| switch | 2 | 43 | 45 |
| status_prevention | 0 | 16 | 16 |
| end_turn | 1 | 13 | 14 |
| stat_change | 0 | 11 | 11 |
| move_prevention | 0 | 9 | 9 |
| action_order | 0 | 8 | 8 |
| weather_change | 1 | 5 | 6 |
| ability_change | 0 | 4 | 4 |
| damage_prevention | 0 | 4 | 4 |
| item_change | 0 | 4 | 4 |
| ability_immunity | 0 | 3 | 3 |
| move_type_change | 0 | 3 | 3 |
| terrain_change | 0 | 2 | 2 |
| accuracy | 0 | 1 | 1 |
| damage_change | 0 | 1 | 1 |
| drain | 0 | 1 | 1 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (204 remaining effects).
