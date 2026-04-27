# Battle Data Coverage — BDC-01 — probabilistic stat riders

## Executive summary

BDC-01 is implemented as a small, honest battle-data coverage slice.

This lot is **not** the BAG runtime `lot-9a / lot-9b / lot-9c` thread. It only extends the distinct `runtime battle data / runtime -> battle bridge` surface so that simple probabilistic stat-stage riders such as `Bubble` and `Bubble Beam` are now really consumable by `map_battle`.

The lot adds:

- a minimal battle-side contract for chance-bearing stat-stage riders;
- deterministic RNG resolution in `map_battle`;
- strict runtime bridge support for the specific supported shape;
- converter support so the covered Showdown shape is no longer downgraded dishonestly;
- regression tests proving success, failure, miss, and guard-rail cases.

The lot does **not** continue BAG runtime work, does **not** widen the battle UI, and does **not** open unrelated mechanics such as drain, recoil, multi-hit, items, abilities, terrains, or accuracy/evasion stage support.

## Scope separation

Confirmed before coding:

- BAG reports concern battle menu runtime/UI work:
  - `reports/lot-9a-battle-bag-menu-ui-shell-report.md`
  - `reports/lot-9b-battle-bag-capture-wiring-report.md`
- the existing battle-data handoff report concerns runtime battle setup work:
  - `reports/phase-r1-lot-9-runtime-battle-setup-report.md`

This BDC-01 lot continues only the second track.

## Initial git state

Initial worktree before BDC-01:

- `git status --short --untracked-files=all`: clean
- `git diff --stat`: clean
- `git ls-files --others --exclude-standard`: clean

## Root diagnosis

Before BDC-01:

- canonical project data already preserved `PokemonMoveEffect.modifyStats(chance: 10, ...)` for moves like `Bubble`;
- `map_editor` marked that shape as `unsupported_mechanic:probabilistic_modify_stats`;
- `RuntimeBattleMoveBridge` rejected it honestly because `map_battle` had no contract or RNG resolution for probabilistic stat-stage riders;
- runtime setup therefore filtered `Bubble` out of the real battle choice surface.

The real missing piece was not catalog data. It was the absence of a minimal battle-engine contract that could consume the rider honestly.

## Design choice

The chosen contract is intentionally small:

- add `BattleStatStageEffect`
- fields:
  - `List<BattleStatStageChange> changes`
  - `int? chancePercent`

This keeps deterministic stat-stage changes intact while making chance-bearing riders explicit. The chance is resolved in `BattleSession` with `BattleRng`, before calling the existing stage application logic.

This avoids:

- pretending a probabilistic rider is deterministic;
- smuggling chance into implicit conventions;
- widening the engine toward generic Showdown callback behavior.

## Code changes

### `map_battle`

Modified files:

- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_move_effects_test.dart`

Implemented:

- introduced `BattleStatStageEffect`;
- added `selfStatStageRider` and `targetStatStageRider` to the battle move contract;
- carried those riders through setup/session materialization;
- applied riders only after real move resolution;
- resolved rider chance with `BattleRng.nextChance(...)`;
- kept deterministic stage changes unchanged.

Preserved invariants:

- miss: no rider application;
- damaging move immunity: no rider application;
- deterministic stage changes still apply on hit as before;
- speed stage changes still affect move order only on following turns.

### `map_runtime`

Modified files:

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`

Implemented:

- the bridge now accepts `modifyStats(chance: X, ...)` only when:
  - `X` is in `1..100`;
  - the target scope is still honest in singles;
  - the affected stats are within the local battle contract;
  - no other real unsupported reason remains.
- the bridge still rejects:
  - invalid chance values;
  - unsupported stats such as accuracy/evasion;
  - unsupported target shapes;
  - probabilistic riders combined with other real unsupported mechanics.

Also kept the existing narrow partial-acceptance behavior for tolerated metadata-only reasons such as `unsupported_mechanic:zMove`.

Validation-only fixes:

- three runtime test files still contained invalid `const` constructions for non-const loaders/builders and had to be corrected to keep the requested runtime test surface executable:
  - `runtime_battle_combatant_seed_builder_test.dart`
  - `runtime_move_catalog_loader_test.dart`
  - `runtime_pokemon_learnset_loader_test.dart`

These were test-only corrections, not product-surface behavior changes.

### `map_editor`

Modified files:

- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/test/showdown_move_catalog_converter_test.dart`

Implemented:

- the converter no longer blindly adds `unsupported_mechanic:probabilistic_modify_stats` for the specific supported structured shape;
- `Bubble` and `Bubble Beam` keep their structured `modifyStats(chance: 10, speed -1)` effect and can now become `structuredSupported` when no other unsupported reason remains;
- unsupported probabilistic riders outside the contract still stay downgraded honestly.

### Seed bootstrap

No seed content changes were required.

Observed state:

- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart` does not currently contain `bubble` or `bubble_beam`.

So the bootstrap seed test surface stayed as a guard rail, but the seed itself was not widened.

## Tests added or updated

### `map_battle`

`packages/map_battle/test/battle_move_effects_test.dart`

Added:

- `a damaging move applies a probabilistic target stat rider when the chance roll succeeds`
- `a damaging move skips the probabilistic target stat rider when the chance roll fails`
- `a miss does not consume or apply a probabilistic target stat rider`

These prove:

- hit + success path;
- hit + failed chance path;
- miss path with no extra rider roll consumption.

### `map_runtime`

`packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

Updated:

- replaced the old Bubble rejection expectation with a positive projection test;
- added a negative guard where `probabilistic_modify_stats` plus another real unsupported reason still rejects honestly.

`packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

Updated:

- Squirtle starter coverage now exposes `bubble` as a real battle move choice;
- still keeps at least one non-bridgeable move filtered elsewhere to prove the lot did not open everything.

### `map_editor`

`packages/map_editor/test/showdown_move_catalog_converter_test.dart`

Updated:

- Bubble and Bubble Beam now stay structured and supported in the covered case;
- an unsupported probabilistic stat rider case still stays partial.

`packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`

- no semantic widening was needed beyond confirming the existing curated seed policy remains honest.

## Validation executed

### `packages/map_battle`

Executed:

- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_move_effects_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze lib/src/battle_move.dart lib/src/battle_setup.dart lib/src/battle_session.dart test/battle_move_effects_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`

Result:

- all green

### `packages/map_runtime`

Executed:

- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_move_bridge_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_combatant_seed_builder_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_setup_mapper_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_combatant_seed_builder_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test`

Result:

- all green

### `packages/map_editor`

Executed:

- `cd packages/map_editor && /opt/homebrew/bin/flutter test test/showdown_move_catalog_converter_test.dart`
- `cd packages/map_editor && /opt/homebrew/bin/flutter test test/pokemon_moves_bootstrap_seed_test.dart`
- `cd packages/map_editor && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/services/showdown_move_catalog_converter.dart test/showdown_move_catalog_converter_test.dart test/pokemon_moves_bootstrap_seed_test.dart`
- `cd packages/map_editor && /opt/homebrew/bin/flutter test`
- `cd packages/map_editor && /opt/homebrew/bin/flutter test --reporter expanded test/pokedex_workspace_ui_test.dart`

Result:

- targeted BDC-01 tests: green
- targeted analyze: green
- full package suite: not fully green in aggregate
- isolated rerun of `test/pokedex_workspace_ui_test.dart`: green

Honest conclusion for `map_editor`:

- the BDC-01 touched slice is green;
- the aggregate `packages/map_editor && flutter test` run still reported a broader suite failure ending in the Pokédex workspace surface;
- rerunning that suspect file alone passed, so no direct regression from the BDC-01 touched files was proven, but the package-wide aggregate run cannot be claimed fully green.

## Final git state

Modified files at the end of BDC-01:

- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/test/battle_move_effects_test.dart`
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/test/showdown_move_catalog_converter_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`
- `reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md`

## Limits intentionally preserved

Still out of scope after BDC-01:

- BAG runtime work;
- heal / drain / recoil;
- multi-hit;
- selfSwitch / forceSwitch;
- abilities / held items;
- terrains;
- Toxic Spikes / Sticky Web;
- accuracy/evasion stage support;
- generic Showdown callbacks;
- fallback moves such as Struggle;
- doubles or richer target routing.

## Conclusion

BDC-01 succeeds on its intended slice:

- `Bubble` / `Bubble Beam` style probabilistic speed-drop riders are now really supported end-to-end through catalog conversion, runtime bridge, and battle execution.

It remains a deliberately small slice:

- only the covered probabilistic stat-stage rider shape is opened;
- unsupported mechanics remain rejected honestly.
