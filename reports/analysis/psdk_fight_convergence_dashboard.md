# PSDK Fight Convergence Dashboard

Generated: 2026-05-25T00:04:58.156893Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 728 / 728 | 100.0% | 0 |
| Methods | 330 / 330 | 100.0% | 0 |
| Effects | 453 / 482 | 94.0% | 29 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 239 | 5 | 10 | 15 |
| field | 15 | 0 | 0 | 0 |
| item | 87 | 0 | 0 | 0 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 101 | 14 | 0 | 14 |
| status | 7 | 0 | 0 | 0 |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| post_damage | 3 | 4 | 7 |
| switch | 1 | 4 | 5 |
| unclassified | 0 | 3 | 3 |
| action_order | 2 | 0 | 2 |
| move_prevention | 1 | 1 | 2 |
| ability_change | 0 | 1 | 1 |
| end_turn | 0 | 1 | 1 |
| item_change | 0 | 1 | 1 |
| stat_change | 1 | 0 | 1 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (15 remaining effects).
