# PSDK Fight Convergence Dashboard

Generated: 2026-05-25T01:14:49.271431Z

## Final Gate Axes

| Axis | Complete | Percent | Remaining |
| --- | ---: | ---: | ---: |
| Attacks | 728 / 728 | 100.0% | 0 |
| Methods | 330 / 330 | 100.0% | 0 |
| Effects | 454 / 482 | 94.2% | 28 |

## Effects By Family

| Family | Ported | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: | ---: |
| ability | 240 | 12 | 2 | 14 |
| field | 15 | 0 | 0 | 0 |
| item | 87 | 0 | 0 | 0 |
| mechanics | 4 | 0 | 0 | 0 |
| move | 101 | 14 | 0 | 14 |
| status | 7 | 0 | 0 | 0 |

## Ability Effect Backlog

Effects with multiple PSDK hooks can appear in multiple hook families.

| Hook family | Partial | Missing | Remaining |
| --- | ---: | ---: | ---: |
| post_damage | 6 | 1 | 7 |
| switch | 4 | 1 | 5 |
| action_order | 2 | 0 | 2 |
| move_prevention | 2 | 0 | 2 |
| unclassified | 1 | 1 | 2 |
| ability_change | 0 | 1 | 1 |
| end_turn | 1 | 0 | 1 |
| item_change | 1 | 0 | 1 |
| stat_change | 1 | 0 | 1 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |

## Next Recommendation

Next recommended lot: close effect family `ability` (14 remaining effects).
