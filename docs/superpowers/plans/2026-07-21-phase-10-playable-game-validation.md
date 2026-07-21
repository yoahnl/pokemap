# Phase 10 — Playable Game Validation Implementation Plan

> **Execution mode:** inline, because sub-agent delegation is disabled for this session.
> Apply `executing-plans`, `test-driven-development`, and
> `verification-before-completion` throughout. Commit every FG lot separately.

**Goal:** Close FG-180 through FG-185 with a fail-closed gameplay-readiness
report, a versioned three-map Golden Slice, a production-backed end-to-end
smoke, a regression matrix, an executable roadmap dashboard, and a fresh MVP
release decision.

**Architecture:** Keep project inspection and release evidence in pure Dart.
`map_core` owns readiness/report contracts. `map_gameplay` owns the missing
pure shop transaction. The runtime-host fixture and test compose existing
production APIs; they do not implement parallel gameplay rules. Documentation
and dashboard tooling consume evidence but never mutate product code.

**Tech Stack:** Dart 3, Flutter test, `package:test`, existing PokeMap package
APIs, JSON fixtures, Markdown Evidence Packs.

---

## Task 1 — FG-180 Project Gameplay Readiness Report V0

**Files:**

- Create: `packages/map_core/lib/src/read_models/project_gameplay_readiness.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create: `packages/map_core/test/project_gameplay_readiness_test.dart`
- Create: `reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md`

**Steps:**

1. Write failing tests for a complete fixture, a broken fixture, missing
   evidence, severity ordering, creator summary, and agent detail rendering.
2. Run only `project_gameplay_readiness_test.dart` and record the expected RED.
3. Implement the eleven canonical FG-180 checks as typed evidence with
   `passed`, `failed`, and `unverified` states. Normalize each state into
   `info`, `error`, and `warning` diagnostics respectively.
4. Make passed evidence fail closed when its summary or source is blank.
5. Expose `isPlayable`, severity counts, creator-facing Markdown, and detailed
   agent Markdown without filesystem access.
6. Export the API from `map_core.dart`, format, run the targeted test, then run
   the full `map_core` test and analysis gates.
7. Write the FG-180 Evidence Pack and commit only this lot.

## Task 2 — FG-181 Golden Slice Fangame Fixture V0

**Files:**

- Create: `examples/playable_runtime_host/golden_fangame_slice/project.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/maps/golden_town.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/maps/golden_route.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/maps/golden_summit.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/walkthrough.json`
- Copy minimal Pokémon JSON data from the existing versioned battle fixture.
- Create: `examples/playable_runtime_host/test/golden_fangame_slice_fixture_test.dart`
- Create: `reports/gameplay/fg_181_golden_slice_fangame_fixture_v0.md`

**Steps:**

1. Write a failing fixture contract test expecting three loadable maps,
   authored New Game and starter data, encounter/trainer content, and the full
   ordered walkthrough contract.
2. Add the smallest JSON fixture able to express the journey. Use no raster
   assets and reuse only the existing minimal species/move catalog JSON.
3. Validate `ProjectManifest`, every `MapData`, map references, spawn points,
   encounter tables, trainer references, and walkthrough IDs.
4. Run the targeted host fixture test, then host analysis.
5. Document the expected walkthrough and preserved non-goals; commit the lot.

## Task 3 — FG-182 Golden Slice End-to-End Smoke V0

**Files:**

- Modify: `packages/map_gameplay/lib/src/game_state_mutations.dart`
- Modify: `packages/map_gameplay/lib/map_gameplay.dart`
- Modify: `packages/map_gameplay/test/party_bag_heal_operations_test.dart`
- Create: `examples/playable_runtime_host/test/golden_fangame_slice_e2e_test.dart`
- Create: `reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md`

**Steps:**

1. RED: specify a typed `ShopPurchaseResult` and `purchaseItem` mutation that
   rejects invalid quantity/price, insufficient money, and overflow, and that
   atomically deducts money plus grants the item on success.
2. GREEN: implement the minimal pure shop transaction in `map_gameplay` and
   export it. Do not add UI, catalogs, or hardcoded prices.
3. RED: write one automated Golden Slice journey smoke that must prove all
   eleven FG-182 checkpoints in order.
4. GREEN: load the real fixture and compose production APIs for New Game and
   starter selection, deterministic encounter and combat, capture destination,
   trainer victory, reward/level-up, shop purchase, heal recovery, story flag,
   Surf unlock, save/JSON reload, and story end.
5. Assert every intermediate and reloaded state, not only a final boolean.
6. Run targeted gameplay and host tests, then both full suites and analyses.
7. Write the walkthrough evidence and commit the lot.

## Task 4 — FG-183 Regression Matrix V0

**Files:**

- Create: `reports/gameplay/fg_183_regression_matrix_v0.md`

**Steps:**

1. Inventory every test package and the Phase 10 targeted files.
2. Map FG-180 through FG-185 to exact fast commands and full package gates.
3. Include runtime/host Phase A smokes, Selbrume journey coverage, analyzer
   commands, and macOS build commands.
4. Verify every documented path and command exists; run the fast Phase 10
   matrix fresh.
5. Record exact results and commit the documentation-only lot.

## Task 5 — FG-184 Roadmap Status Dashboard Generator V0

**Files:**

- Create: `packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create: `packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart`
- Create: `packages/map_core/test/gameplay_roadmap_dashboard_test.dart`
- Create: `reports/gameplay/fg_184_roadmap_status_dashboard_generator_v0.md`

**Steps:**

1. RED: test roadmap-lot parsing, report-evidence discovery, explicit proposed
   status extraction, TODO/PARTIAL/DONE output, deterministic sorting, and
   malformed-report handling.
2. Implement a pure read model that combines the canonical roadmap with report
   text supplied by the caller.
3. Add a read-only CLI which reads `pokemap_roadmap_mecaniques_fangame.md` and
   `reports/gameplay`, prints a Markdown table to stdout, and performs no writes.
4. Test the parser, run the CLI against the repository, and verify that
   `git status --short` is unchanged by execution.
5. Run full `map_core` tests/analyze, write the Evidence Pack, and commit.

## Task 6 — FG-185 MVP Release Gate V0

**Files:**

- Modify: `packages/map_core/test/mvp_release_gate_test.dart`
- Modify: `reports/gameplay/fg_185_mvp_release_gate_v0.md`
- Create: `reports/gameplay/fg_180_185_phase_10_playable_game_validation_completion.md`

**Steps:**

1. Add a release-gate characterization test using the fresh Phase 10 evidence
   sources. Preserve fail-closed behavior for absent user scope approval.
2. Run every pure-Dart package suite and analysis, then runtime, editor, and
   runtime-host suites and analyses package by package.
3. Run the Golden Slice smoke, Selbrume player journey, runtime battle smokes,
   editor seed check, and macOS debug builds for editor and host.
4. Evaluate all five FG-185 criteria from the fresh evidence. Do not promote
   user scope approval from implementation authorization; leave it
   `unverified` unless the user explicitly approves the documented MVP cutoff.
5. Update the FG-185 report and create the Phase 10 completion Evidence Pack
   with initial/final Git state, complete file inventory, commands, exact
   results, named review passes, limitations, and self-critique.
6. Commit the technical release-gate lot. Do not push unless explicitly asked.

## Final Verification Gate

Run from each package, never from a nonexistent monorepo orchestrator:

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart
cd examples/playable_runtime_host && flutter test test/selbrume_player_journey_e2e_test.dart
cd packages/map_editor && flutter build macos --debug
cd examples/playable_runtime_host && flutter build macos --debug
```

Final hygiene:

```bash
git diff --check
git status --short --untracked-files=all
```
