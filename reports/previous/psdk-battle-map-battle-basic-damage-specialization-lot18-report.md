# PSDK Battle Lot 18 - Basic Damage Specializations

## Scope

Ported two small PSDK `Basic` descendants into `packages/map_battle`:

- `s_false_swipe` -> `BasicDamageSpecializationMoveBehavior.falseSwipe` (`partial`)
- `s_full_crit` -> `BasicDamageSpecializationMoveBehavior.fullCrit` (`ported`)

This lot was chosen because both moves are isolated damage-rule specializations and do not require a new long-lived battle effect model.

## Ruby Source Audited

- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 FalseSwipe.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 FullCrit.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/100 Basic.rb`

Observed PSDK rules:

- `FalseSwipe` uses normal `Basic` damage, then clamps lethal damage to `target.hp - 1` unless Substitute is active.
- `FullCrit` only overrides `critical_rate` to `100`.

## Files Changed

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/move/behaviors/basic_damage_specialization_move_behavior.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/tool/extract_psdk_move_registry.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_move_families/basic_damage_specialization_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_battle_cli_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_registry_manifest_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `/Users/karim/Project/pokemonProject/reports/psdk-move-porting-matrix.md`
- `/Users/karim/Project/pokemonProject/reports/psdk-effect-porting-matrix.md`

## Logic Implemented

Added `BasicDamageSpecializationMoveBehavior`:

- runs the shared PSDK move preparation pipeline,
- calculates normal damage through `BattleMoveDamageCalculator`,
- applies a local False Swipe anti-KO clamp before direct damage application,
- forces Full Crit by evaluating damage against an equivalent move definition with `criticalRate: 100`,
- keeps secondary effects routed through the normal PSDK secondary resolver.

The global damage formula and critical resolver were not changed.

## Tests Added

`basic_damage_specialization_test.dart` covers:

- `s_false_swipe` leaves the target at exactly 1 HP when calculated damage would KO.
- `s_false_swipe` emits no zero-damage event when the target is already at 1 HP.
- `s_false_swipe` keeps normal damage when damage is below the anti-KO threshold.
- `s_false_swipe` keeps the common immunity precheck.
- `s_full_crit` deals more than a matching non-critical `s_basic` move and does not consume the critical RNG stream.

`psdk_battle_cli_test.dart` covers:

- `--scenario basic_specialization`, asserting False Swipe damage `29`, opponent remaining HP `1`, and a follow-up `s_full_crit` damage event for `23`.

`psdk_registry_manifest_test.dart` covers:

- `s_false_swipe`: `partial`, because Substitute is not modelled.
- `s_full_crit`: `ported`.

## CLI Scenario

Added:

```bash
dart run bin/psdk_battle_cli.dart --scenario basic_specialization --format json
```

Observed smoke result:

- `outcome`: `ongoing`
- `playerHp`: `77`
- `opponentHp`: `1`
- `false_swipe` damage: `29`
- `false_swipe` remaining target HP: `1`
- `full_crit_slash` damage: `23`

## Verification Evidence

RED checks before implementation:

- `dart test test/psdk_move_families/basic_damage_specialization_test.dart` failed on unsupported `s_false_swipe` and `s_full_crit`.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 18"` failed because the manifest still marked the methods as `missing`.

GREEN targeted checks after implementation:

- `dart test test/psdk_move_families/basic_damage_specialization_test.dart` -> all tests passed.
- `dart test test/psdk_battle_cli_test.dart --name "basic specialization"` -> all tests passed.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 18"` -> all tests passed.
- `dart run bin/psdk_battle_cli.dart --scenario basic_specialization --format json` -> deterministic expected output.

Sub-agent audit:

- `McClintock`: confirmed `s_false_swipe` should remain `partial` until Substitute exists, and `s_full_crit` can be marked `ported` using existing critical-rate behavior.
- `Maxwell`: no blocking findings. One non-blocking note asked the CLI smoke to cover `s_full_crit`; the scenario and test were updated accordingly.

## Remaining Limitations

- False Swipe does not yet detect Substitute, because the current PSDK lane has no Substitute effect contract.
- Full Crit does not add new critical messaging; the current timeline still focuses on deterministic damage events.
