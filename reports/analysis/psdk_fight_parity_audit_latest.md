# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 658 |
| Studio attacks `partiel` | 70 |
| Studio attacks `pas_fait` | 0 |
| Unknown methods | 0 |
| Unique battle engine methods | 258 |

### Partial Attacks by Method

| Battle method | Partial attacks |
| --- | ---: |
| s_absorb | 1 |
| s_basic | 37 |
| s_beak_blast | 1 |
| s_beat_up | 1 |
| s_core_enforcer | 1 |
| s_frustration | 1 |
| s_genesis_supernova | 1 |
| s_guardian_of_alola | 1 |
| s_hidden_power | 1 |
| s_hyperspace_hole | 1 |
| s_light_that_burns_the_sky | 1 |
| s_magic_coat | 1 |
| s_malicious_moonsault | 1 |
| s_multi_hit | 1 |
| s_payday | 1 |
| s_return | 1 |
| s_self_stat_z_move | 2 |
| s_shell_trap | 1 |
| s_snatch | 1 |
| s_splintered_stormshards | 1 |
| s_split_up | 1 |
| s_swallow | 1 |
| s_teleport | 1 |
| s_z_move | 10 |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 304 |
| `partial` | 26 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |
| effects | 26 |
| ability | 14 |
| handlerDamage | 14 |
| item | 14 |
| field | 3 |

### Partial Method Batches

Each partial method is assigned to its first actionable Phase 2 batch.

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Damage formula / variable power | 14 | `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_core_enforcer`, `s_dragon_darts`, `s_frustration`, `s_hidden_power`, `s_order_up`, `s_payday`, `s_pre_attack_base`, `s_return`, `s_shell_trap`, `s_split_up`, `s_upper_hand` |
| Effect hook / manifest final sweep | 12 | `s_chilly_reception`, `s_court_change`, `s_doodle`, `s_geomancy`, `s_magic_coat`, `s_revival_blessing`, `s_shed_tail`, `s_snatch`, `s_stuff_cheeks`, `s_swallow`, `s_teatime`, `s_teleport` |

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
