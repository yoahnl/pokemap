# PSDK Fight Parity Audit

Source: `moves=/Users/karim/Project/pokemonProject/pokémon_sdk_test_project/Data/Studio/moves; effects=/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 728 |
| Studio attacks `partiel` | 0 |
| Studio attacks `pas_fait` | 0 |
| Unknown methods | 0 |
| Unique battle engine methods | 258 |

### Partial Attacks by Method

| Battle method | Partial attacks |
| --- | ---: |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 330 |
| `partial` | 0 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 414 |
| `partial` | 13 |
| `missing` | 55 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 214 | 5 | 35 |
| field | 15 | 0 | 0 |
| item | 87 | 0 | 0 |
| mechanics | 4 | 0 | 0 |
| move | 87 | 8 | 20 |
| status | 7 | 0 | 0 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |
| ability | 35 |
| move | 20 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `explained` |
| Reason | Imported from reports/previous/phase-a-battle-coverage.md. Covers authored bootstrap, golden-slice, player, trainer, and wild runtime move rows; every rejected row has a bridge diagnostic reason. |
| Total moves | 28 |
| Bridgeable moves | 20 |
| Rejected moves | 8 |
| Explained rejected moves | 8 |
| Unexplained rejected moves | 0 |
