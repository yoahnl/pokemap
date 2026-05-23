# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 668 |
| Studio attacks `partiel` | 60 |
| Studio attacks `pas_fait` | 0 |
| Unknown methods | 0 |
| Unique battle engine methods | 258 |

### Partial Attacks by Method

| Battle method | Partial attacks |
| --- | ---: |
| s_basic | 37 |
| s_beak_blast | 1 |
| s_genesis_supernova | 1 |
| s_guardian_of_alola | 1 |
| s_hyperspace_hole | 1 |
| s_light_that_burns_the_sky | 1 |
| s_magic_coat | 1 |
| s_malicious_moonsault | 1 |
| s_multi_hit | 1 |
| s_self_stat_z_move | 2 |
| s_shell_trap | 1 |
| s_snatch | 1 |
| s_splintered_stormshards | 1 |
| s_z_move | 10 |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 321 |
| `partial` | 9 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |
| effects | 9 |
| ability | 6 |
| handlerDamage | 6 |
| item | 6 |

### Partial Method Batches

Each partial method is assigned to its first actionable Phase 2 batch.

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Damage formula / variable power | 6 | `s_beak_blast`, `s_dragon_darts`, `s_order_up`, `s_pre_attack_base`, `s_shell_trap`, `s_upper_hand` |
| Effect hook / manifest final sweep | 3 | `s_magic_coat`, `s_revival_blessing`, `s_snatch` |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 406 |
| `partial` | 13 |
| `missing` | 63 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 214 | 5 | 35 |
| field | 15 | 0 | 0 |
| item | 81 | 0 | 6 |
| mechanics | 4 | 0 | 0 |
| move | 85 | 8 | 22 |
| status | 7 | 0 | 0 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |
| ability | 35 |
| item | 6 |
| move | 22 |

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
