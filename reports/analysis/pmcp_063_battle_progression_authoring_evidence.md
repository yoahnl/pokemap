# PMCP-063 — Battle and progression authoring evidence

Date: 2026-07-31

## Scope and roadmap alignment

PMCP-063 exposes deterministic battle simulation and detached post-battle progression without moving rules out of `map_battle`, `map_gameplay`, or `map_runtime`. It covers wild/trainer/static setup, scripted commands, seeded traces, terminal outcomes, write-back projections, deterministic receipts, XP/levels, move learning, evolution, rewards, capture destination, and runtime-consumer capability truth.

Relevant mechanics roadmap lots are FG-040 through FG-053 and the held-item boundary FG-072. Existing statuses remain authoritative: FG-040 through FG-049 and FG-051 are DONE; FG-050, FG-052, FG-053, and FG-072 remain TODO. This authoring lot consumes those mechanics and does not change the roadmap.

## Initial audit

- Base commit: `e217ca09 feat(authoring): add sandbox player state authoring`.
- `map_authoring` may depend only on `map_core`; battle execution therefore remains in `map_battle`, progression in `map_gameplay`, and runtime truth in `map_runtime`.
- The runtime already owned HP/PP/status and held-item write-back, capture placement, reward resolution, and post-battle decisions.
- The battle package exposes two engine generations. The bounded authoring simulator uses the immutable legacy `BattleSession`; runtime capability truth explicitly identifies PSDK-only held-item projection.
- Unrelated changes in `examples/playable_runtime_host/pubspec.lock`, `packages/map_gameplay/lib/src/gameplay_world_state.dart`, and `.superpowers/brainstorm/` were not modified or staged by this lot.

## Implementation verdict

PASS, with explicit limitations.

- Same setup, seed, and scripted decisions produce byte-stable JSON traces and the same deterministic receipt.
- Wild, trainer, and static setup builders delegate validation to `map_battle`.
- Illegal decisions, unused scripted decisions, invalid seeds, and non-terminal step limits fail explicitly.
- Trace entries preserve request kind, selected choice, before/after state, move execution facts, and timeline size.
- Outcome projections expose HP, PP, major status, lineup identity, participants, and capture attempt identity.
- Progression previews operate on a JSON-detached `GameState`, reuse `BattleProgressionService`, preserve typed move/evolution decisions, and identify party/box/full capture destinations through `PlayerStorageOperations`.
- Runtime truth names the concrete consumer for HP, PP, status, held item, XP, level, moves, evolution, capture, money, items, Facts, and badges.
- Unregistered effects are `unsupported`; registered effect families are only `partial`. Manual targeting, arbitrary RNG probes, pause/resume, and production outcome application are not advertised by the authoring action catalog.

## Files changed

Created:

- `packages/map_battle/lib/src/battle_authoring_simulator.dart`
- `packages/map_battle/test/battle_authoring_simulator_test.dart`
- `packages/map_gameplay/lib/src/battle_progression_authoring_service.dart`
- `packages/map_gameplay/test/battle_progression_authoring_service_test.dart`
- `packages/map_authoring/lib/src/domains/gameplay/battle_actions.dart`
- `packages/map_authoring/lib/src/domains/gameplay/progression_actions.dart`
- `packages/map_authoring/test/domains/gameplay/battle_simulation_contract_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_authoring_capability_truth.dart`
- `packages/map_runtime/test/battle_authoring_simulation_runtime_consumption_test.dart`
- `reports/analysis/pmcp_063_battle_progression_authoring_evidence.md`
- `reports/analysis/pmcp_063_battle_progression_authoring_evidence_appendix.md`

Modified:

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- `packages/map_authoring/test/registry/action_registry_test.dart`
- `packages/map_runtime/lib/map_runtime.dart`

The appendix contains the complete contents of every created Dart file. Existing files only receive public exports, the `battleProgression` resource kind, and its sorted registry expectation.

## Test-driven passes

Initial RED:

- Four targeted package tests failed to compile because simulator, progression preview, action catalog, and runtime proof types did not exist.
- The first authoring GREEN attempt exposed an invalid guarantee enum and was corrected to `dryRun` plus a deterministic extension.
- Runtime analysis reported seven `prefer_const_constructors` infos in the new smoke test; they were corrected.
- The setup-builder test initially enabled capture without a required catch rate; the fixture was corrected to validate an honest non-capturable wild setup.

Final GREEN:

```text
packages/map_authoring
dart test test/domains/gameplay/battle_simulation_contract_test.dart test/registry/action_registry_test.dart test/package_boundary_test.dart
Result: +12, all tests passed.
dart test
Result: +279, all tests passed.
dart analyze
Result: No issues found.

packages/map_battle
dart test test/battle_authoring_simulator_test.dart
Result: +5, all tests passed.
dart test
Result: +1769, all tests passed.
dart analyze
Result: No issues found.

packages/map_gameplay
dart test test/battle_progression_authoring_service_test.dart
Result: +5, all tests passed.
dart test
Result: +446, all tests passed.
dart analyze
Result: No issues found.

packages/map_runtime
flutter test test/battle_authoring_simulation_runtime_consumption_test.dart
Result: +2, all tests passed.
flutter test test/battle_authoring_simulation_runtime_consumption_test.dart test/runtime_battle_outcome_apply_test.dart test/runtime_held_item_bridge_v0_test.dart test/playable_map_game_post_battle_progression_integration_test.dart test/runtime_battle_reward_resolver_test.dart test/runtime_post_battle_decision_coordinator_test.dart
Result: +61, all tests passed.
flutter test
Result: +2279, ~1 skipped, all executed tests passed.
flutter analyze
Result: No issues found.

packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
Result: +3, all tests passed.

examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
Result: +1, all tests passed.
```

## Decisions and non-goals

- The simulator is a deterministic, terminal, in-memory playtest façade; it is not a stateful pause/resume server.
- Simulation receipts use stable FNV-1a identity over canonical JSON. They detect replay identity but are not cryptographic security signatures.
- The simulator wraps legacy `BattleSession`; PSDK held-item write-back remains truthful through the runtime consumer but is not projected by the legacy simulation result.
- No production save or project mutation action is registered.
- No generic item/effect engine, manual doubles targeting, or arbitrary RNG injection was invented.
- No MCP transport or editor UI is implemented in this lot.

## Precise changed zones

- `map_battle`: setup factory, serializable choices, seeded terminal runner, trace snapshots, write-back projection, capture identity, and receipt.
- `map_gameplay`: detached progression/reward preview, typed decision trace, outcome policy, and party/box capture destination preview.
- `map_authoring`: exact battle/progression catalog descriptors with playtest-only authorization and no mutation dispatch.
- `map_runtime`: consumer-backed support matrix plus a smoke test feeding a simulated outcome into the real write-back function.

## Final critique and risks

- Legacy and PSDK engines coexist. A later lot should add a PSDK-native authoring simulator before claiming complete parity for held items and all registered effects.
- Receipt stability is version-local; changing trace serialization or engine behavior intentionally changes the receipt.
- Runtime capability truth is explicit code and must be updated when consumer support changes.
- The combined runtime suite contains one pre-existing skipped test; this lot does not reinterpret that skip as passing coverage.
- Full support is not claimed for unregistered move, item, or ability effects.

## Git evidence

The lot started at `e217ca09` and is committed independently as `feat(authoring): add battle progression authoring`. Unrelated external workspace changes remain outside the lot.
