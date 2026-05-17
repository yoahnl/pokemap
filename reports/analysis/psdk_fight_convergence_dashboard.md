# PSDK Fight Convergence Dashboard

Generated: 2026-05-17T23:27:38.567359Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 343 / 728 | 47.1% | 385 |
| Methods | 149 / 330 | 45.2% | 181 |
| Effects | 183 / 482 | 38.0% | 299 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 55 | 2 | 197 | 199 |
| field | 15 | 0 | 0 | 0 |
| item | 34 | 10 | 43 | 53 |
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
| berries | 1 | 11 | 12 |
| focus/eject/choice/orb | 1 | 8 | 9 |
| weather/terrain/field | 0 | 2 | 2 |
| held-item lifecycle and consumption | 5 | 20 | 25 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (199 remaining effects).
