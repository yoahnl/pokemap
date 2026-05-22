# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 631 |
| Studio attacks `partiel` | 97 |
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
| s_conversion | 1 |
| s_conversion2 | 1 |
| s_core_enforcer | 1 |
| s_destiny_bond | 1 |
| s_embargo | 1 |
| s_entrainment | 1 |
| s_flower_shield | 1 |
| s_frustration | 1 |
| s_gear_up | 1 |
| s_genesis_supernova | 1 |
| s_gravity | 1 |
| s_grudge | 1 |
| s_guardian_of_alola | 1 |
| s_happy_hour | 1 |
| s_healing_wish | 1 |
| s_helping_hand | 1 |
| s_hidden_power | 1 |
| s_hyperspace_hole | 1 |
| s_ion_deluge | 1 |
| s_light_that_burns_the_sky | 1 |
| s_lunar_dance | 1 |
| s_magic_coat | 1 |
| s_magic_room | 1 |
| s_magnetic_flux | 1 |
| s_malicious_moonsault | 1 |
| s_multi_hit | 1 |
| s_nightmare | 1 |
| s_payday | 1 |
| s_perish_song | 1 |
| s_powder | 1 |
| s_return | 1 |
| s_role_play | 1 |
| s_rototiller | 1 |
| s_self_stat_z_move | 2 |
| s_shell_trap | 1 |
| s_simple_beam | 1 |
| s_skill_swap | 1 |
| s_snatch | 1 |
| s_spite | 1 |
| s_splintered_stormshards | 1 |
| s_split_up | 1 |
| s_swallow | 1 |
| s_teleport | 1 |
| s_wish | 1 |
| s_wonder_room | 1 |
| s_worry_seed | 1 |
| s_z_move | 10 |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 274 |
| `partial` | 56 |
| `missing` | 0 |
| Total manifest methods | 330 |

### Partial Methods by Dependency

| Dependency | Partial methods |
| --- | ---: |
| effects | 56 |
| ability | 19 |
| handlerDamage | 14 |
| item | 14 |
| field | 8 |
| endTurn | 1 |
| handlerStat | 1 |
| handlerSwitch | 1 |
| targetingMulti | 1 |

### Partial Method Batches

Each partial method is assigned to its first actionable Phase 2 batch.

| Batch | Partial methods | Methods |
| --- | ---: | --- |
| Damage formula / variable power | 14 | `s_aura_wheel`, `s_beak_blast`, `s_beat_up`, `s_core_enforcer`, `s_dragon_darts`, `s_frustration`, `s_hidden_power`, `s_order_up`, `s_payday`, `s_pre_attack_base`, `s_return`, `s_shell_trap`, `s_split_up`, `s_upper_hand` |
| Effect hook / manifest final sweep | 42 | `s_chilly_reception`, `s_conversion`, `s_conversion2`, `s_court_change`, `s_destiny_bond`, `s_doodle`, `s_dragon_cheer`, `s_embargo`, `s_entrainment`, `s_flower_shield`, `s_gear_up`, `s_geomancy`, `s_gravity`, `s_grudge`, `s_happy_hour`, `s_healing_wish`, `s_helping_hand`, `s_ion_deluge`, `s_lunar_dance`, `s_magic_coat`, `s_magic_powder`, `s_magic_room`, `s_magnetic_flux`, `s_nightmare`, `s_no_retreat`, `s_perish_song`, `s_powder`, `s_revival_blessing`, `s_role_play`, `s_rototiller`, `s_shed_tail`, `s_simple_beam`, `s_skill_swap`, `s_snatch`, `s_spite`, `s_stuff_cheeks`, `s_swallow`, `s_teatime`, `s_teleport`, `s_wish`, `s_wonder_room`, `s_worry_seed` |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 404 |
| `partial` | 13 |
| `missing` | 65 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 214 | 5 | 35 |
| field | 15 | 0 | 0 |
| item | 81 | 0 | 6 |
| mechanics | 4 | 0 | 0 |
| move | 83 | 8 | 24 |
| status | 7 | 0 | 0 |

### Missing Effects by Family

| Family | Missing effects |
| --- | ---: |
| ability | 35 |
| item | 6 |
| move | 24 |

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
