# PSDK Fight Gimmick Scope

Date: 2026-05-17

## Decision Summary

Lot 35 does not promote any move to strict parity. It removes ambiguity around
Z-Moves, Studio-only special methods, and form/action gimmicks so future lots
cannot accidentally mark them as `ported` without explicit behavior coverage.

| Area | Scope decision | Reason |
| --- | --- | --- |
| Generic offensive Z-Moves | Combat scope, partial today | Local Studio data contains playable Z-Move attacks using `s_z_move`; the current engine can execute their offensive hit, but lacks item, source-move, once-per-battle, runtime bridge, and full Z-Move eligibility gates. |
| Studio-only Z-Move methods | Combat scope, partial today | These methods are present in local Studio move data even when they are not registered by Pokemon SDK Ruby move files. They need explicit Dart behavior or documented fallback behavior before strict parity. |
| `s_self_stat_z_move` | Combat scope, partial today | Status Z-Move families need exact stat boosts and eligibility gates; the broad secondary-only fallback is not enough for strict parity. |
| `s_hyperspace_hole` | Combat scope, partial today | This is a playable Studio special-case method, so it stays in combat parity rather than catalog-only scope. |
| Mega Evolution | Action-system scope | Pokemon SDK models Mega Evolution as `Battle::Actions::Mega`, not as a move registry method. Lot 62 owns it. |
| Primal Reversion | Action/item/ability scope | Pokemon SDK models it through item/form effects and primal weather abilities. Ability and item lots own it. |
| Tera Shift | Ability/form scope | Pokemon SDK exposes this as an ability effect, not a move method. Ability/form lots own it. |
| Max/Dynamax move family | Data-only catalog for now | No Max/Dynamax move battleEngineMethod is present in the imported Pokemon SDK battle scripts or local Studio move dataset. |

## Move Method Decisions

| Battle method | Family | Scope | Current local behavior | Required for strict parity |
| --- | --- | --- | --- | --- |
| `s_z_move` | Z-Move | Combat scope | `StaticBasicMoveRegistry.s_z_move` executes the offensive hit as basic damage. | Z-Crystal/item validation, source-move relationship, once-per-battle usage, runtime bridge support, PP/selection gates, and Z-specific messages. |
| `s_self_stat_z_move` | Z-Move | Combat scope | `StaticBasicMoveRegistry.secondaryOnly(s_self_stat_z_move)` keeps it executable but not strict. | Exact Z-status stat boost table, normal status move payload execution, eligibility gates, and move-specific messages. |
| `s_genesis_supernova` | Z-Move | Combat scope | Partial Studio-only fallback. | Offensive hit plus Psychic Terrain side effect and Z-Move eligibility gates. |
| `s_guardian_of_alola` | Z-Move | Combat scope | Partial Studio-only fallback. | Fractional target-current-HP damage behavior, immunity/protection interactions, and Z-Move eligibility gates. |
| `s_light_that_burns_the_sky` | Z-Move | Combat scope | Partial Studio-only fallback. | Photon Geyser-like offensive stat choice, target ability suppression details, and Z-Move eligibility gates. |
| `s_malicious_moonsault` | Z-Move | Combat scope | Partial Studio-only fallback. | Move-specific offensive behavior and Z-Move eligibility gates. |
| `s_splintered_stormshards` | Z-Move | Combat scope | Partial Studio-only fallback. | Offensive hit plus terrain clearing and Z-Move eligibility gates. |
| `s_hyperspace_hole` | Studio-only special case | Combat scope | Partial Studio-only fallback. | Protect bypass behavior, exact target checks, and effect/ability interactions. |

## Non-Move Gimmick Decisions

| Action/system id | Family | Scope | Owner lot |
| --- | --- | --- | --- |
| `mega_evolution` | Mega Evolution | Action-system scope | Lot 62 |
| `primal_reversion` | Primal Reversion | Action/item/ability scope | Item, ability, and Lot 62 form/action work |
| `tera_shift` | Tera/form ability | Ability/form scope | Ability/form lots |
| `max_move_family` | Max/Dynamax | Data-only catalog | No combat lot until Pokemon SDK/local Studio data introduces a battle method |

## Guard Rails Added

- `psdkSpecialMoveScopeDecisions` records every local special/gimmick move
  method that must not stay ambiguous.
- `psdkSpecialActionScopeDecisions` records non-move gimmick systems so they do
  not get confused with move-registry parity.
- `psdk_registry_manifest_test.dart` now fails if the known Lot 35 move methods
  lose their scope decision.

## Current Percentage Impact

This lot is intentionally non-promotional:

| Metric | Before Lot 35 | After Lot 35 |
| --- | ---: | ---: |
| Strict Studio attacks | 262 / 728 | 262 / 728 |
| Executable Studio attacks | 728 / 728 | 728 / 728 |
| Strict PSDK methods | 63 / 330 | 63 / 330 |
| Partial PSDK effects | 25 / 482 | 25 / 482 |

