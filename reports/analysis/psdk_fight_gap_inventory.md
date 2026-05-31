# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle`

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
| `ported` | 482 |
| `partial` | 0 |
| `missing` | 0 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 254 | 0 | 0 |
| field | 15 | 0 | 0 |
| item | 87 | 0 | 0 |
| mechanics | 4 | 0 | 0 |
| move | 115 | 0 | 0 |
| status | 7 | 0 | 0 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `complete` |
| Reason | Current runtime battle handoff is PSDK-first. The Phase A sampled runtime rows are bridgeable either through the legacy runtime bridge or through a PSDK ported battleEngineMethod. |
| Total moves | 28 |
| Bridgeable moves | 28 |
| Rejected moves | 0 |
| Explained rejected moves | 0 |
| Unexplained rejected moves | 0 |
