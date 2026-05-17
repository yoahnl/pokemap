# PSDK Fight Parity Audit

Source: `moves=../../pokémon_sdk_test_project/Data/Studio/moves; effects=../../pokemonsdk-development/scripts/5 Battle`

Important: `partiel` is executable coverage, not strict PSDK parity.

## Attack Coverage

| Metric | Count |
| --- | ---: |
| Studio attacks total | 728 |
| Studio attacks `fait` | 267 |
| Studio attacks `partiel` | 461 |
| Studio attacks `pas_fait` | 0 |
| Unknown methods | 0 |
| Unique battle engine methods | 258 |

## Method Coverage

| Status | Count |
| --- | ---: |
| `ported` | 65 |
| `partial` | 265 |
| `missing` | 0 |
| Total manifest methods | 330 |

## Effect Coverage

| Status | Count |
| --- | ---: |
| `ported` | 0 |
| `partial` | 25 |
| `missing` | 457 |
| Total effect classes | 482 |

### Effects by Family

| Family | Ported | Partial | Missing |
| --- | ---: | ---: | ---: |
| ability | 0 | 3 | 251 |
| field | 0 | 0 | 15 |
| item | 0 | 0 | 87 |
| mechanics | 0 | 0 | 4 |
| move | 0 | 22 | 93 |
| status | 0 | 0 | 7 |

## Runtime Bridge

| Metric | Value |
| --- | --- |
| Status | `not_measured` |
| Reason | Runtime bridge diagnostics live in packages/map_runtime and are opened by Lot 04. |
