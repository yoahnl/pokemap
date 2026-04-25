# PSDK Battle Lot 17 - Advanced Multi-Hit

## Scope

Ported the next PSDK multi-hit slice into `packages/map_battle`:

- `s_triple_kick` -> `MultiHitMoveBehavior.tripleKick` (`partial`)
- `s_population_bomb` -> `MultiHitMoveBehavior.populationBomb` (`partial`)
- `s_water_shuriken` -> `MultiHitMoveBehavior.waterShuriken` (`partial`)

These are intentionally not marked `ported` yet. The executable Dart behavior is present, but PSDK branches that require richer combatant contracts remain outside this lot.

## Ruby Source Audited

- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/103 TwoHit MultiHit.rb`

Observed PSDK rules:

- `TripleKick`: up to 3 hits, per-hit power ramps as `P`, `2P`, `3P`, and later hits recheck accuracy.
- `PopulationBomb`: up to 10 hits with constant power, later hits recheck accuracy, plus an `always_hit?` override not yet modelled in Dart.
- `WaterShuriken`: uses the base 2-5 hit multi-hit distribution, with an Ash-Greninja/form-specific branch that is not available in the current combatant snapshot.

## Files Changed

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/tool/extract_psdk_move_registry.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_move_families/fixed_damage_and_multi_hit_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_battle_cli_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_registry_manifest_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `/Users/karim/Project/pokemonProject/reports/psdk-move-porting-matrix.md`
- `/Users/karim/Project/pokemonProject/reports/psdk-effect-porting-matrix.md`

## Logic Implemented

`MultiHitMoveBehavior` now supports:

- fixed 2/3 hits already present from the earlier slice,
- PSDK base random 2-5 hit distribution,
- `TripleKick` fixed 3-hit plan with power ramp per successful hit,
- `PopulationBomb` fixed 10-hit plan with constant power,
- `WaterShuriken` as the current base multi-hit distribution alias.

Accuracy rechecks are local to `TripleKick` and `PopulationBomb` after the first hit. A failed later hit emits a `PsdkBattleMissEvent` and stops the hit loop without undoing previous damage.

## Tests Added

`fixed_damage_and_multi_hit_test.dart` now covers:

- `s_triple_kick` damage ramp `[3, 5, 7]`.
- `s_triple_kick` stopping on a second-hit miss.
- `s_triple_kick` preserving damage before a third-hit miss.
- `s_population_bomb` producing 10 constant-power hits.
- `s_population_bomb` stopping on a later miss.
- `s_water_shuriken` using the current PSDK 2-5 distribution.

`psdk_battle_cli_test.dart` now covers:

- `--scenario advanced_multi_hit`, asserting `triple_kick` damage `[3, 5, 7]`.

`psdk_registry_manifest_test.dart` now asserts honest manifest statuses:

- `s_triple_kick`: `partial`
- `s_population_bomb`: `partial`
- `s_water_shuriken`: `partial`

## CLI Scenario

Added:

```bash
dart run bin/psdk_battle_cli.dart --scenario advanced_multi_hit --format json
```

Observed smoke result:

- `outcome`: `ongoing`
- `opponentHp`: `85`
- `triple_kick` damage events: `3`, `5`, `7`

## Verification Evidence

RED checks before implementation:

- `dart test test/psdk_move_families/fixed_damage_and_multi_hit_test.dart` failed on unsupported `s_triple_kick`, `s_population_bomb`, `s_water_shuriken`.
- `dart test test/psdk_battle_cli_test.dart` failed on unknown `advanced_multi_hit` scenario.
- `dart test test/psdk_registry_manifest_test.dart` failed because the manifest did not yet track the new behaviors.

GREEN targeted checks after implementation:

- `dart test test/psdk_move_families/fixed_damage_and_multi_hit_test.dart` -> all tests passed.
- `dart test test/psdk_battle_cli_test.dart --name "advanced multi-hit"` -> all tests passed.
- `dart test test/psdk_registry_manifest_test.dart --name "fixed-damage and multi-hit"` -> all tests passed.
- `dart run bin/psdk_battle_cli.dart --scenario advanced_multi_hit --format json` -> deterministic expected output.

Sub-agent review:

- `Lovelace`: audit confirmed the three behaviors should remain `partial`.
- `Linnaeus`: no blocking findings. Two P3 notes were addressed: clarified partial status wording and added a Population Bomb miss test.

## Remaining Limitations

- Skill Link is not represented in the current PSDK combatant snapshot.
- Population Bomb's PSDK `always_hit?` override is not represented yet.
- Ash-Greninja/form-specific Water Shuriken is not represented yet.
- Multi-target remap, parent handlers, richer messages and recoil/last-hit hooks are still broader PSDK battle work.

