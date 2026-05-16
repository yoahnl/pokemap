# PSDK Fight 100 Percent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` for independent lots or `superpowers:executing-plans` for sequential execution. Steps use checkbox syntax for tracking.

**Goal:** reach a real, measurable, and test-proven Pokemon SDK battle parity for the Dart battle engine, runtime bridge, attacks, effects, abilities, items, targeting, actions, AI, and final golden validation.

**Architecture:** keep `packages/map_battle` as the pure Dart battle domain, keep `packages/map_runtime` as the runtime integration seam, and keep Pokemon SDK extraction/reporting tools in `packages/map_battle/tool`. Every lot must move one measurable slice from `partial` or `missing` to `ported`, with tests and coverage metrics proving the change.

**Tech Stack:** Dart, Flutter tests for runtime integration, pure Dart tests for `map_battle`, Pokemon SDK Ruby scripts as reference material, local Studio move JSON under `pokémon_sdk_test_project/Data/Studio/moves`.

---

## Current Baseline

Baseline from `reports/analysis/psdk_fight_parity_audit_2026-05-16.md`:

| Axis | Current value |
| --- | ---: |
| Studio attacks strictly done | 33 / 728 |
| Studio attacks partial | 695 / 728 |
| PSDK battle engine methods ported | 25 / 330 |
| PSDK battle engine methods partial | 305 / 330 |
| PSDK effects ported | 0 / 482 |
| PSDK effects partial | 25 / 482 |
| PSDK effects missing | 457 / 482 |

Important rule: `pas_fait = 0` only means all local Studio moves have a registry entry or fallback. It does not mean the battle behavior is equivalent to Pokemon SDK.

## Global Execution Rules

- Work in a dedicated branch or worktree before implementation.
- Do not touch unrelated `map_editor` or shadow files.
- Each lot must include a failing or characterization test before code when feasible.
- Each lot must update the parity registry only after behavior is tested.
- Each lot must run at least targeted tests, then `cd packages/map_battle && dart test --reporter compact` for battle-domain lots.
- Runtime-facing lots must also run targeted `packages/map_runtime` or `examples/playable_runtime_host` tests.
- Every lot that changes coverage must regenerate attack/effect metrics into `/tmp` and update the tracked parity report if the lot explicitly owns reporting.
- Do not mark a method `ported` when only the damage happy path works. PSDK edge cases, hooks, relevant items/abilities, targeting, and failure conditions must be covered.

## Common Files

These files will be reused across many lots:

- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_execution.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/*`
- `packages/map_battle/lib/src/domain/effect/*`
- `packages/map_battle/lib/src/domain/handler/*`
- `packages/map_battle/test/psdk_move_families/*`
- `packages/map_battle/test/psdk_*`
- `packages/map_battle/tool/*`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

## Verification Commands

Use these commands repeatedly:

```bash
cd packages/map_battle && dart test --reporter compact
cd packages/map_battle && dart analyze
cd packages/map_runtime && flutter test test/runtime_battle_move_bridge_test.dart test/runtime_battle_setup_mapper_test.dart --reporter compact
cd examples/playable_runtime_host && flutter test test/runtime_demo_party_seed_test.dart --reporter compact
cd packages/map_battle && dart run tool/generate_psdk_attack_coverage_report.dart ../../pokémon_sdk_test_project/Data/Studio/moves /tmp/psdk-attack-coverage-current.md
cd packages/map_battle && dart run tool/extract_psdk_effect_matrix.dart ../../pokemonsdk-development/scripts/'5 Battle' /tmp/psdk-effect-matrix-current.md
```

---

## Phase 1 - Measurement, Gates, and Runtime Truth

### Lot 01 - Unified Parity Audit CLI

**Status 2026-05-16:** done. Implemented by `packages/map_battle/tool/psdk_fight_parity_audit.dart` with JSON/Markdown output and targeted tests.

**Goal:** create one CLI that reports attack, method, effect, and runtime bridge parity in one JSON + markdown output.

**Files:**
- Create: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Create: `packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart`
- Modify: `packages/map_battle/pubspec.yaml` only if a test helper package is already used locally and must be exposed
- Modify: `reports/analysis/psdk_fight_parity_audit_2026-05-16.md` only after the CLI proves the same baseline

**Logic to implement:**
- Load Studio moves from `pokémon_sdk_test_project/Data/Studio/moves`.
- Load `psdkMoveRegistryManifest`.
- Parse PSDK effects through the existing extractor logic.
- Count:
  - total attacks
  - attacks `fait`, `partiel`, `pas_fait`
  - unique battle methods
  - method statuses
  - effect classes by status and family
  - unknown methods
- Emit JSON for automation and markdown for humans.

**Code shape:**
- Reuse `loadPsdkStudioMoveCoverageEntries`.
- Extract pure functions from existing tools instead of duplicating parsing.
- Add a `PsdkFightParityAudit` immutable model with `toJson()` and `toMarkdown()`.

**Tests:**
- Fixture with 3 fake moves: 1 ported, 1 partial, 1 unknown.
- Assert JSON counts.
- Assert markdown has the warning that `partiel` is not strict parity.

**Definition of done:**
- `dart run tool/psdk_fight_parity_audit.dart --json /tmp/psdk.json --markdown /tmp/psdk.md` works.
- Baseline still reports 33 / 728 strict attacks.

### Lot 02 - Parity Gates and No-Regression Thresholds

**Status 2026-05-16:** done. Implemented by `packages/map_battle/test/psdk_parity_gate_test.dart` and `--gate` on the unified audit CLI.

**Goal:** prevent accidental regressions in PSDK parity.

**Files:**
- Create: `packages/map_battle/test/psdk_parity_gate_test.dart`
- Modify: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Create: `reports/analysis/psdk_fight_parity_gate_policy.md`

**Logic to implement:**
- Add a test that fails if:
  - `unknown_methods > 0`
  - strict attack count decreases below baseline
  - strict method count decreases below baseline
  - effect partial/ported count decreases below baseline
- Store baseline constants in the test with comments pointing to the audit report.

**Tests:**
- The gate itself is a test.
- Add a unit test around threshold comparison so failure messages are readable.

**Definition of done:**
- `cd packages/map_battle && dart test test/psdk_parity_gate_test.dart --reporter compact` passes.
- Future regressions produce actionable failure messages.

### Lot 03 - Golden Fixture Format Against Pokemon SDK

**Goal:** define the canonical format for PSDK-vs-Dart golden scenarios.

**Files:**
- Create: `packages/map_battle/test/fixtures/psdk_golden/README.md`
- Create: `packages/map_battle/test/fixtures/psdk_golden/schema.md`
- Create: `packages/map_battle/test/fixtures/psdk_golden/basic_damage_neutral.json`
- Create: `packages/map_battle/test/psdk_golden_fixture_test.dart`
- Create: `packages/map_battle/lib/src/data/psdk_golden_fixture.dart`

**Logic to implement:**
- Fixture fields:
  - `scenarioId`
  - `sourcePsdkVersion`
  - `initialBattle`
  - `actions`
  - `expectedFinalState`
  - `expectedTimeline`
  - `notes`
- Keep the first fixture tiny: one neutral damage move with deterministic RNG.
- Add parser validation that rejects missing required fields.

**Tests:**
- Parse fixture.
- Run it through current Dart battle engine.
- Assert final HP and event kinds.

**Definition of done:**
- One golden fixture passes and establishes the pattern for future lots.

### Lot 04 - Runtime Bridge Parity Diagnostics

**Goal:** make runtime bridge limitations measurable instead of hidden in thrown exceptions.

**Files:**
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- Create: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge_diagnostics.dart`
- Modify: `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- Modify: `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

**Logic to implement:**
- Add a non-throwing `inspectMove()` API returning:
  - `bridgeable`
  - `reason`
  - `engineSupportLevel`
  - `battleEngineMethod` when available
  - `psdkRegistryStatus` when available
- Keep `toBattleMoveData()` strict and throwing.

**Tests:**
- Assert `inspectMove()` reports `transform` as bridgeable.
- Assert `baton_pass` is not bridgeable yet with a precise reason.
- Assert a simple damage move is bridgeable.

**Definition of done:**
- Runtime UI and seed builder can ask why a move was filtered.

### Lot 05 - Runtime Bridge Uses PSDK Registry Status

**Goal:** align runtime bridge decisions with `psdkMoveRegistryManifest`.

**Files:**
- Modify: `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- Modify: `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- Modify: `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- Modify: `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- Modify: `packages/map_battle/lib/map_battle.dart` if registry exports are missing

**Logic to implement:**
- Resolve canonical move id -> Studio move metadata -> `battleEngineMethod`.
- Look up manifest status.
- Permit bridge only if the current runtime contract can carry the behavior.
- Report difference between:
  - `psdkRegistered`
  - `psdkPartial`
  - `runtimeBridgeable`

**Tests:**
- `Mew` picker keeps moves that are runtime bridgeable and explains filtered PSDK partial moves.
- `Squirtle` four-move regression stays green.

**Definition of done:**
- Runtime bridge no longer has an isolated notion of support disconnected from PSDK status.

### Lot 06 - Runtime Move Menu Shows Filtered/Partial State

**Goal:** make playable testing clearer without pretending partial moves are complete.

**Files:**
- Modify: `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- Modify: relevant runtime menu/view model files that show move choices
- Modify: `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- Add tests in `packages/map_runtime/test` if the menu model lives there

**Logic to implement:**
- For party builder and battle setup, store diagnostics for filtered moves.
- Show usable moves in battle.
- Keep non-usable moves out of command selection, but expose their reason in debug/test surfaces.

**Tests:**
- A Pokemon with 4 authored moves but 2 runtime bridgeable moves exposes a diagnostic list of 2 filtered moves.
- A Pokemon with 0 bridgeable moves fails with a precise message.

**Definition of done:**
- Testers know whether a move is absent because of data, bridge, or engine parity.

### Lot 07 - Direct PSDK Move Execution Contract

**Goal:** let runtime eventually execute by `battleEngineMethod`, not only by legacy `BattleMoveData`.

**Files:**
- Create: `packages/map_battle/lib/src/domain/move/psdk_battle_move_request.dart`
- Create: `packages/map_battle/lib/src/domain/move/psdk_battle_move_executor.dart`
- Modify: `packages/map_battle/lib/map_battle.dart`
- Create: `packages/map_battle/test/psdk_battle_move_executor_test.dart`

**Logic to implement:**
- Define request:
  - user ref
  - target ref
  - move id
  - battle engine method
  - Studio move metadata
- Executor resolves the behavior from `BattleMoveRegistry`.
- Keep legacy `BattleMoveData` path working.

**Tests:**
- Execute a `s_fixed_damage` move by method.
- Execute a `s_basic` partial move by method and verify standard damage.
- Unknown method fails explicitly.

**Definition of done:**
- Future lots can bypass runtime bridge limitations by using PSDK method execution directly.

---

## Phase 2 - Promote High-Volume Move Methods

### Lot 08 - Strict `s_basic` Damage Parity

**Goal:** promote `s_basic` from broad partial fallback to strict damage parity for plain damage moves only.

**Files:**
- Modify: `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`
- Create: `packages/map_battle/test/psdk_move_families/basic_damage_strict_test.dart`

**Logic to implement:**
- Split `s_basic` into:
  - strict plain damage subset
  - partial basic subset with special flags/effects
- Strict subset must cover:
  - power
  - type
  - category
  - accuracy
  - PP
  - priority
  - crit ratio
  - flags that affect current engine
- Keep special cases partial.

**Tests:**
- Test representative physical, special, priority, high crit, always-hit, and non-100 accuracy attacks.
- Assert methods are not promoted when Studio metadata has unsupported riders.

**Definition of done:**
- `s_basic` strict count increases, but partial `s_basic` remains for unsafe moves.

### Lot 09 - Strict `s_self_stat`

**Goal:** port self-target stat stage moves exactly for supported stats and failure conditions.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/status_stat_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- Modify: `packages/map_battle/test/psdk_move_families/generic_status_stat_test.dart`

**Logic to implement:**
- Handle self stat boosts.
- Clamp stages to -6 / +6.
- Fail when no stage can change if PSDK does so for that move.
- Respect move prevention hooks.
- Include accuracy/evasion only after those stats are supported.

**Tests:**
- `swords_dance`, `agility`, `iron_defense`, `calm_mind` style cases.
- Already-maxed stat failure behavior.

**Definition of done:**
- Safe `s_self_stat` moves can become `ported`.

### Lot 10 - Strict `s_stat`

**Goal:** port target stat lowering/raising moves with PSDK accuracy and immunity behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/status_stat_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/generic_status_stat_test.dart`

**Logic to implement:**
- Target stat stage changes.
- Accuracy/evasion support if required.
- Ability/item blocking remains partial until ability/item lots; do not promote moves depending on missing blockers.
- Handle target substitute if PSDK blocks the move.

**Tests:**
- Growl-like target attack drop.
- Tail Whip-like defense drop.
- Failure when target stat cannot change.

**Definition of done:**
- Strict subset of `s_stat` is promoted.

### Lot 11 - Strict `s_status`

**Goal:** port major status application moves.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/status_stat_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/generic_status_stat_test.dart`
- Modify: `packages/map_battle/test/psdk_status_effects_test.dart`

**Logic to implement:**
- Support burn, paralysis, poison, toxic, sleep, freeze where PSDK move expects it.
- Respect type immunities where already available.
- Respect existing status effect stack.
- Keep ability/item cures partial until those lots.

**Tests:**
- Thunder Wave / Will-O-Wisp / Toxic / Sleep Powder style scenarios.
- Failure on already-statused target.
- Immunity cases where type chart is enough.

**Definition of done:**
- Strict status moves that do not require missing ability/item hooks become `ported`.

### Lot 12 - Strict `s_self_status` and Local Volatiles

**Goal:** port self-applied status/volatile methods that have local engine support.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/status_stat_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/*`
- Modify: `packages/map_battle/test/psdk_move_families/status_utility_move_behavior_test.dart`

**Logic to implement:**
- Self sleep/rest-like state when not covered by direct heal lots.
- Self volatile markers with exact duration.
- Fail when the status cannot be applied.

**Tests:**
- Self status success.
- Blocked when existing state prevents it.

**Definition of done:**
- Local self-status methods move out of generic partials.

### Lot 13 - Strict Random Multi-Hit

**Goal:** port `s_multi_hit` PSDK random 2-5 hit behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/fixed_damage_and_multi_hit_test.dart`
- Modify: `packages/map_battle/test/psdk_ability_effects_test.dart`

**Logic to implement:**
- PSDK hit count distribution.
- Per-hit accuracy/damage semantics where PSDK requires.
- Skill Link interaction stays tested.
- Loaded Dice interaction if already present; otherwise keep item-dependent moves partial.

**Tests:**
- Seeded RNG produces expected hit counts.
- Skill Link forces max.
- KO mid-sequence stops correctly.

**Definition of done:**
- `s_multi_hit` strict subset is promoted.

### Lot 14 - Strict Two-Turn Moves

**Goal:** port `s_2turns` and common charge-then-strike semantics.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/forced_action_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/action_gated_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/forced_action_moves_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/action_gated_moves_test.dart`

**Logic to implement:**
- Charge turn effect.
- Forced next action.
- Interruptions from flinch/paralysis/sleep.
- Power Herb branch later under item lots; keep those branches partial until then.

**Tests:**
- Solar Beam style two-turn.
- Charge turn then hit.
- Prevention on second turn clears or preserves state according to PSDK.

**Definition of done:**
- Safe two-turn moves become `ported`.

### Lot 15 - Strict Recharge Moves

**Goal:** port `s_reload` and recharge-turn behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/forced_action_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/forced_action_moves_test.dart`

**Logic to implement:**
- User spends next turn recharging after successful hit.
- No recharge when move fails before execution if PSDK says so.
- Recharge action emits timeline.

**Tests:**
- Hyper Beam style success -> recharge.
- Miss/fail branch.
- Switch/faint clears recharge.

**Definition of done:**
- `s_reload` safe moves move to `ported`.

### Lot 16 - Strict Recoil

**Goal:** port `s_recoil` and recoil variants.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/recoil_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/rock_head_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/reckless_effect.dart`
- Modify: `packages/map_battle/test/psdk_move_families/recoil_move_behavior_test.dart`

**Logic to implement:**
- Recoil by fraction of damage dealt.
- Fixed self-crash cases stay separate.
- Rock Head prevents regular recoil.
- Reckless boosts target damage where applicable.

**Tests:**
- Take Down style recoil.
- Rock Head prevention.
- Reckless boost.
- KO from recoil.

**Definition of done:**
- Core recoil moves can be strict.

### Lot 17 - Strict Drain and Absorb

**Goal:** port `s_absorb` and drain modifiers.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/drain_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_heal_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/drain_heal_and_power_test.dart`

**Logic to implement:**
- Heal user from damage dealt.
- Liquid Ooze branch if ability is available; otherwise keep those branches partial.
- Big Root branch if item is available; otherwise keep item-dependent branch partial.
- Heal Block prevents drain if PSDK says so.

**Tests:**
- Absorb heals half damage.
- Heal cannot exceed max HP.
- Heal Block branch.

**Definition of done:**
- `s_absorb` strict subset is promoted.

### Lot 18 - Strict Heal Moves

**Goal:** port `s_heal`, `s_heal_weather`, Rest, and HP recovery variants.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/heal_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/recovery_stat_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/drain_heal_and_power_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/rest_belly_strength_test.dart`

**Logic to implement:**
- Fail at full HP when PSDK does.
- Weather-dependent heal amounts.
- Rest: sleep + full heal + terrain prevention branch.
- Heal Block prevention.

**Tests:**
- Recover success/fail.
- Synthesis weather amounts.
- Rest status replacement and HP restore.

**Definition of done:**
- Common heal families are strict.

### Lot 19 - Strict Protect Family

**Goal:** port Protect and variants beyond the minimal object effect.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/protect_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/persistent_effect_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_protect_effect_test.dart`

**Logic to implement:**
- Success-rate decay.
- Reset on non-protect action.
- Bypass rules such as Feint and future Unseen Fist ability lot.
- Variants: Detect, Endure, King's Shield, Spiky Shield, Baneful Bunker, etc. as separate strict or partial subgroups.

**Tests:**
- First protect guaranteed, consecutive protect seeded decay.
- Break Protect bypass.
- Variant-specific side effect remains partial until implemented.

**Definition of done:**
- Base `s_protect` moves are strict; variants only promoted when their side effects are tested.

### Lot 20 - Strict Trapping and Binding

**Goal:** port `s_bind`, `s_cantflee`, and trapping effects.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/move/bind_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/cant_switch_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/trapping_moves_test.dart`

**Logic to implement:**
- Residual damage duration.
- Switch prevention.
- Grip Claw / Binding Band branches later under items.
- Rapid Spin cleanup if already available, otherwise cross-link with hazard cleanup lot.

**Tests:**
- Bind applies residual.
- Target cannot switch.
- Effect clears on source faint.

**Definition of done:**
- Core trapping methods become strict.

### Lot 21 - Screens and Side Protection

**Goal:** port Reflect, Light Screen, Aurora Veil, Safeguard, Mist, Lucky Chant-like side conditions.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/side/*`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/persistent_effect_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/screen_moves_test.dart`

**Logic to implement:**
- Side duration.
- Damage mitigation.
- Crit/status/stat prevention where supported.
- Multiple application refresh rules.

**Tests:**
- Reflect halves physical damage according to local battle size.
- Light Screen halves special damage.
- Safeguard blocks status.

**Definition of done:**
- Screen methods move from marker partial to strict.

### Lot 22 - Hazards Strict Parity

**Goal:** port Spikes, Toxic Spikes, Stealth Rock, Sticky Web and cleanup.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/side/hazard_effects.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/persistent_effect_move_behavior.dart`
- Modify: `packages/map_battle/test/battle_spikes_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/hazard_cleanup_moves_test.dart`

**Logic to implement:**
- Layer rules.
- Switch-in application.
- Grounded checks.
- Poison/Toxic Spikes absorption.
- Rapid Spin / Defog / Tidy Up cleanup.

**Tests:**
- Layer caps.
- Stealth Rock type effectiveness.
- Cleanup removes correct side conditions.

**Definition of done:**
- Hazard methods become strict.

### Lot 23 - Weather Moves Strict Parity

**Goal:** port `s_weather`, `s_weather_ball`, Thunder/Hurricane weather branches and related weather moves.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/field/weather_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/weather_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/weather_power_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/weather_conditional_moves_test.dart`

**Logic to implement:**
- Weather duration.
- Weather replacement.
- Weather-based accuracy/power/type changes.
- Air Lock / Cloud Nine interaction if already available.

**Tests:**
- Rain/Sun/Sand/Hail/Snow if present in source data.
- Weather Ball type/power.
- Thunder accuracy branch.

**Definition of done:**
- Weather methods strict for branches implemented by engine.

### Lot 24 - Terrain Moves Strict Parity

**Goal:** port `s_terrain`, `s_terrain_boosting`, `s_terrain_pulse`, and terrain effects.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/field/terrain_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/terrain_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/terrain_power_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/terrain_power_move_behavior_test.dart`

**Logic to implement:**
- Terrain duration.
- Grounded checks.
- Terrain power/type modifiers.
- Electric Terrain sleep prevention.
- Grassy Terrain end-turn heal if in scope.

**Tests:**
- Terrain Pulse type/power.
- Expanding Force / Rising Voltage / Grassy Glide branches.
- Grounded vs airborne target.

**Definition of done:**
- Terrain methods strict where all branches are covered.

### Lot 25 - Variable Power Batch A

**Goal:** port high-value variable power moves not yet strict.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/variable_power_test.dart`

**Logic to implement:**
- Low Kick / Grass Knot weight formulas.
- Gyro Ball speed ratio.
- Heavy Slam / Heat Crash weight ratio.
- Body Press defense-as-attack.

**Tests:**
- Table-driven formula tests with expected base power.
- Boundary values.

**Definition of done:**
- Batch A methods become `ported`.

### Lot 26 - Variable Power Batch B

**Goal:** port contextual variable power moves requiring history/state.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/history_power_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/consecutive_power_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/history_power_moves_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/consecutive_power_moves_test.dart`

**Logic to implement:**
- Fury Cutter / Echoed Voice / Rollout / Ice Ball.
- Last Respects / Rage Fist / Stomping Tantrum style history dependencies.
- Reset rules.

**Tests:**
- Consecutive turn increases.
- Reset after different move or miss if PSDK does.
- Party faint count power.

**Definition of done:**
- History/consecutive power methods strict.

### Lot 27 - Counter and Retaliation Moves

**Goal:** port Counter, Mirror Coat, Metal Burst, Bide and revenge-style methods.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/counter_damage_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/battler/battle_combatant_history.dart`
- Modify: `packages/map_battle/test/psdk_move_families/counter_damage_moves_test.dart`

**Logic to implement:**
- Read last damage source/category.
- Fail when no valid damage exists.
- Return correct damage multiplier.
- Target the correct source where topology supports it.

**Tests:**
- Counter after physical damage.
- Mirror Coat after special damage.
- Failure after status/no damage.

**Definition of done:**
- Counter family strict in singles.

### Lot 28 - Type Changing and Type-Based Moves

**Goal:** port type-changing moves and type-dependent damage.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/type_based_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/field_location_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/type_based_power_moves_test.dart`
- Modify: `packages/map_battle/test/psdk_move_families/field_location_moves_test.dart`

**Logic to implement:**
- Camouflage.
- Nature Power.
- Secret Power.
- Hidden Power if data supports deterministic type/power.
- Burn Up / add/remove type branches.

**Tests:**
- Terrain/location determines type/effect.
- Type changes affect STAB and immunity.

**Definition of done:**
- Type-dependent methods strict where location/terrain data exists.

### Lot 29 - Item and Ability Changing Moves

**Goal:** port Trick, Switcheroo, Knock Off, Corrosive Gas, Gastro Acid, Skill Swap, Role Play, Entrainment, Simple Beam, Worry Seed.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/item_dependent_move_behavior.dart`
- Create: `packages/map_battle/lib/src/domain/move/behaviors/ability_change_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_item_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_ability_change_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/item_dependent_moves_test.dart`

**Logic to implement:**
- Item swap/remove.
- Ability suppress/change/copy.
- Failure rules for blocked items/abilities.
- Keep legendary/form restrictions partial until species/form support exists.

**Tests:**
- Trick swaps held items.
- Knock Off removes item and modifies damage if PSDK branch is in scope.
- Gastro Acid suppresses ability.

**Definition of done:**
- Core item/ability changing moves strict for local supported data.

### Lot 30 - Copy, Call, and Random Move Selection

**Goal:** port Metronome, Mimic, Sketch, Sleep Talk, Assist, Mirror Move, Copycat, Me First, Instruct.

**Files:**
- Create: `packages/map_battle/lib/src/domain/move/behaviors/copy_call_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_history_recorder.dart`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_registry.dart`
- Create: `packages/map_battle/test/psdk_move_families/copy_call_move_behavior_test.dart`

**Logic to implement:**
- Select eligible moves according to PSDK filters.
- Execute selected move through registry.
- Prevent recursion where PSDK excludes it.
- Use deterministic RNG streams.

**Tests:**
- Metronome picks a seeded eligible move.
- Sleep Talk only works while asleep.
- Sketch permanently copies when persistence layer exists; otherwise keep persistence branch partial.

**Definition of done:**
- Copy/call methods strict for in-battle behavior.

### Lot 31 - Force Switch and Baton Pass

**Goal:** port Roar, Whirlwind, Dragon Tail, Circle Throw, U-turn, Volt Switch, Flip Turn, Parting Shot, Baton Pass.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/switch_effect_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/baton_pass_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/test/psdk_move_families/switch_effect_moves_test.dart`

**Logic to implement:**
- Force target switch.
- Self switch after hit.
- Transfer Baton Pass effects/stages.
- Fail if no reserve exists.
- Respect trapping exceptions.

**Tests:**
- Dragon Tail damages then forces replacement.
- U-turn damages then requests self switch.
- Baton Pass transfers stat stages and transferable effects.

**Definition of done:**
- Switch move families strict in singles.

### Lot 32 - Substitute and Focus Punch

**Goal:** port Substitute and move interactions that depend on it.

**Files:**
- Create: `packages/map_battle/lib/src/domain/effect/move/substitute_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/persistent_effect_move_behavior.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/action_gated_move_behavior.dart`
- Create: `packages/map_battle/test/psdk_move_families/substitute_focus_punch_test.dart`

**Logic to implement:**
- Substitute HP cost and failure rules.
- Damage redirection to substitute.
- Status/stat blocking rules.
- Focus Punch fails when user is hit before action.

**Tests:**
- Substitute consumes HP and blocks status.
- Damage breaks substitute.
- Focus Punch success/fail branches.

**Definition of done:**
- Substitute-dependent methods can be promoted.

### Lot 33 - Delayed Attacks

**Goal:** port Future Sight, Doom Desire, Wish, Healing Wish, Lunar Dance delayed effects.

**Files:**
- Create: `packages/map_battle/lib/src/domain/effect/field/delayed_move_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Create: `packages/map_battle/test/psdk_move_families/delayed_attacks_test.dart`

**Logic to implement:**
- Store delayed action with origin, target slot, move data, turn counter.
- Resolve at correct end-turn phase.
- Handle target slot changes.
- Healing Wish/Lunar Dance apply on switch-in if PSDK says so.

**Tests:**
- Future Sight hits after delay.
- Slot target changes are handled.
- Wish heals after delay.

**Definition of done:**
- Delayed move families strict.

### Lot 34 - Combo and Pledge Families

**Goal:** port Pledge, Round, Echoed Voice and combo move behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/consecutive_power_move_behavior.dart`
- Create: `packages/map_battle/lib/src/domain/move/behaviors/combo_move_behavior.dart`
- Create: `packages/map_battle/test/psdk_move_families/combo_move_behavior_test.dart`

**Logic to implement:**
- Detect ally combo in the same turn where topology supports it.
- Apply combo power/effect.
- Keep doubles-only branches partial until targeting lots are complete.

**Tests:**
- Round doubles/changes order when ally used it.
- Pledge combo creates expected field effect in doubles fixture.

**Definition of done:**
- Singles-safe combo branches strict; doubles branches cross-linked to targeting lots.

### Lot 35 - Gimmick and Special Case Method Audit

**Goal:** decide exact scope for Z-Moves, Mega-related move behavior, Max-like moves, studio-only moves, and project-specific special methods.

**Files:**
- Create: `reports/analysis/psdk_fight_gimmick_scope.md`
- Modify: `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart` after decisions
- Modify: `packages/map_battle/test/psdk_registry_manifest_test.dart`

**Logic to implement:**
- Classify each gimmick method:
  - in 100% combat scope
  - data-only/catalog scope
  - intentionally unsupported for this project
- Do not falsely mark unsupported gimmicks as `ported`.

**Tests:**
- Registry test asserts every gimmick method has a scope decision.

**Definition of done:**
- No ambiguous special/gimmick methods remain in the manifest.

---

## Phase 3 - Generic PSDK Effect System

### Lot 36 - Generic Effect Dispatcher Core

**Goal:** build the Dart equivalent of the PSDK effect hook dispatcher.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- Create: `packages/map_battle/test/psdk_effect_dispatcher_test.dart`

**Logic to implement:**
- Define typed hooks for:
  - move prevention
  - target prevention
  - damage prevention
  - post damage
  - end turn
  - switch prevention
  - lifecycle
- Dispatcher runs effects in deterministic PSDK-like order.

**Tests:**
- Multiple effects run in order.
- Removing an effect during dispatch is safe.
- Hook results compose deterministically.

**Definition of done:**
- Future effect lots plug into the dispatcher instead of custom code paths.

### Lot 37 - Effect Lifecycle and Messages

**Goal:** port lifecycle semantics: add, delete, reset, duration, messages.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- Modify: `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`
- Create: `packages/map_battle/test/psdk_effect_lifecycle_test.dart`

**Logic to implement:**
- Effect counters.
- Duration decrement timing.
- Delete messages.
- Reset at switch/faint/battle end.

**Tests:**
- Timed effect expires at correct phase.
- Baton Pass transferable effect does not expire incorrectly.
- Timeline contains lifecycle events.

**Definition of done:**
- Effect partial notes about lifecycle can start being closed.

### Lot 38 - Move Prevention Hooks

**Goal:** make PSDK `on_move_prevention_user`, `on_move_disabled_check`, and related hooks generic.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/taunt_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/disable_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/encore_effect.dart`
- Modify: `packages/map_battle/test/psdk_move_families/move_prevention_test.dart`

**Logic to implement:**
- User prevention reasons.
- Disabled move checks for UI and engine.
- Force-next-move integration.

**Tests:**
- Taunt blocks status moves.
- Disable blocks last used move.
- Encore forces same move.

**Definition of done:**
- Move prevention effects no longer need bespoke execution checks.

### Lot 39 - Damage Prevention Hooks

**Goal:** port `on_damage_prevention` behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_damage_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- Create: `packages/map_battle/test/psdk_damage_prevention_effect_test.dart`

**Logic to implement:**
- Effects can prevent or alter incoming damage before HP changes.
- Protect and Substitute use the generic hook.
- Sturdy-like ability later plugs in here.

**Tests:**
- Protect prevents target damage.
- Substitute absorbs damage.
- Damage prevention emits timeline event.

**Definition of done:**
- Damage prevention hook family starts moving out of missing status.

### Lot 40 - Post Damage Hooks

**Goal:** port `on_post_damage` and `on_post_damage_death`.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_damage_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- Create: `packages/map_battle/test/psdk_post_damage_effect_test.dart`

**Logic to implement:**
- Trigger effects after damage.
- Separate death and non-death hooks.
- Support contact/attacker/defender metadata.

**Tests:**
- Rough Skin-like fixture can damage attacker.
- Life Orb-like fixture can damage user.
- Death hook order is deterministic.

**Definition of done:**
- Largest missing hook family has a real dispatcher seam.

### Lot 41 - End Turn Hooks

**Goal:** port generic PSDK end-turn effect execution.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/aqua_ring_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/leech_seed_effect.dart`
- Modify: `packages/map_battle/test/psdk_end_turn_effect_test.dart`

**Logic to implement:**
- End-turn effect order.
- Residual damage/healing.
- Faint handling during end turn.
- Duration decrement relation to effect action.

**Tests:**
- Aqua Ring heals.
- Leech Seed drains.
- Salt Cure damages.
- Multiple end-turn effects order.

**Definition of done:**
- End-turn effects share a generic path.

### Lot 42 - Switch Hooks

**Goal:** port switch prevention, switch event, and transfer hooks.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/baton_pass_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/move/cant_switch_effect.dart`
- Modify: `packages/map_battle/test/psdk_switch_effect_test.dart`

**Logic to implement:**
- Regular switch prevention.
- Force switch exceptions.
- Switch-out cleanup.
- Switch-in hazards/effects.
- Baton Pass transfer list.

**Tests:**
- Trapped battler cannot switch.
- Force switch can bypass specific trapping when PSDK says so.
- Transferable effects move to replacement.

**Definition of done:**
- Switch hook family is generic.

### Lot 43 - Stat and Status Change Hooks

**Goal:** port hooks around stat/status modification.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- Create: `packages/map_battle/test/psdk_stat_status_hook_test.dart`

**Logic to implement:**
- Pre/post stat change hooks.
- Status prevention hooks.
- Status cure hooks.
- Mist/Safeguard and ability effects use generic hooks.

**Tests:**
- Safeguard blocks status.
- Mist blocks stat decrease.
- Clear Body-like fixture blocks stat drop once ability lot lands.

**Definition of done:**
- Status/stat prevention can be shared by move, ability, and item effects.

### Lot 44 - Field, Weather, and Terrain Hooks

**Goal:** port weather/terrain change hooks.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_weather_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_terrain_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/field/weather_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/field/terrain_effect.dart`
- Create: `packages/map_battle/test/psdk_field_hook_test.dart`

**Logic to implement:**
- Allow effects to block or modify weather/terrain changes.
- Air Lock/Cloud Nine style suppression.
- Terrain Extender/rocks later modify duration through item hooks.

**Tests:**
- Air Lock prevents new weather if PSDK branch requires.
- Terrain duration modified by extender after item lot.

**Definition of done:**
- Field effect changes are hook-driven.

---

## Phase 4 - Status, Abilities, and Items

### Lot 45 - Full Major Status Effects

**Goal:** finish Burn, Poison, Toxic, Paralysis, Sleep, Freeze as PSDK status effects.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/status/*`
- Modify: `packages/map_battle/lib/src/domain/effect/status/status_effect_registry.dart`
- Modify: `packages/map_battle/test/psdk_status_effects_test.dart`

**Logic to implement:**
- End-turn damage.
- Action prevention.
- Speed/attack modifiers.
- Sleep counter.
- Freeze thaw checks.
- Toxic counter.

**Tests:**
- Each status has application, turn progression, and cure behavior.

**Definition of done:**
- Status effects can be marked complete where Pokemon SDK branches are covered.

### Lot 46 - Status Immunity and Cure Parity

**Goal:** connect status effects to immunities, terrains, abilities, and cure moves.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- Modify: `packages/map_battle/lib/src/domain/move/behaviors/status_cure_move_behavior.dart`
- Modify: `packages/map_battle/test/psdk_move_families/status_cure_move_behavior_test.dart`

**Logic to implement:**
- Type immunities.
- Terrain immunities.
- Heal Bell / Aromatherapy / Sparkly Swirl.
- Psycho Shift / Purify.

**Tests:**
- Electric Terrain blocks sleep on grounded targets.
- Heal Bell cures party where party state supports it.
- Psycho Shift transfers status.

**Definition of done:**
- Status moves depending on cure/immunity can be promoted.

### Lot 47 - Ability Registry Completeness Foundation

**Goal:** hydrate all known PSDK ability ids into a registry with explicit statuses.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/ability_effect_registry.dart`
- Create: `packages/map_battle/lib/src/data/generated/psdk_ability_effect_manifest.dart`
- Create: `packages/map_battle/test/psdk_ability_registry_manifest_test.dart`

**Logic to implement:**
- Extract/list all ability effects from PSDK.
- Mark each as `ported`, `partial`, `missing`, or `out_of_scope`.
- Unknown ability ids must not silently disappear.

**Tests:**
- Registry has no duplicate ability ids.
- Known local abilities hydrate.
- Unknown ability is represented safely.

**Definition of done:**
- Ability parity becomes measurable.

### Lot 48 - Ability Damage Modifiers

**Goal:** port common ability hooks that modify damage.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/*`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- Modify: `packages/map_battle/test/psdk_ability_effects_test.dart`

**Logic to implement:**
- Same-type boosts.
- Contact punishers.
- Critical modifiers.
- Recoil modifiers.
- Type power modifiers.

**Tests:**
- Table-driven ability damage cases.
- Ensure modifiers compose in deterministic order.

**Definition of done:**
- High-impact damage abilities move to partial/ported based on edge coverage.

### Lot 49 - Ability Immunities and Prevention

**Goal:** port ability-based immunities and action/status prevention.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/status_immunity_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/levitate_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/ability/*`
- Modify: `packages/map_battle/test/psdk_ability_effects_test.dart`

**Logic to implement:**
- Type immunities.
- Status immunities.
- Move prevention abilities.
- Mold Breaker-style bypass later if required.

**Tests:**
- Levitate Ground immunity.
- Water Absorb/Flash Fire style immunity if present.
- Status immunity ability blocks matching status.

**Definition of done:**
- Immunity/prevention ability family has real parity coverage.

### Lot 50 - Ability Weather, Terrain, and Switch Effects

**Goal:** port weather/terrain/switch-trigger abilities.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/*`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Modify: `packages/map_battle/test/psdk_ability_effects_test.dart`

**Logic to implement:**
- Weather on switch-in.
- Terrain on switch-in.
- Intimidate-style stat changes.
- Trapping abilities already partial become stricter.

**Tests:**
- Drizzle-like switch-in weather.
- Intimidate lowers foes.
- Shadow Tag / Arena Trap / Magnet Pull full exceptions.

**Definition of done:**
- Switch-trigger abilities are hook-driven.

### Lot 51 - Ability Post-Damage and End-Turn Effects

**Goal:** port ability effects that trigger after damage or at end turn.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/ability/*`
- Modify: `packages/map_battle/test/psdk_ability_effects_test.dart`

**Logic to implement:**
- Rough Skin / Iron Barbs style post-contact.
- Speed Boost / Moody style end-turn.
- Poison Heal / Rain Dish / Dry Skin style residual.

**Tests:**
- Contact damage to attacker.
- End-turn stat boost.
- Weather-dependent healing/damage.

**Definition of done:**
- Ability effect matrix missing count drops materially.

### Lot 52 - Item Registry Completeness Foundation

**Goal:** hydrate all known held item effects into a measurable registry.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- Create: `packages/map_battle/lib/src/data/generated/psdk_item_effect_manifest.dart`
- Create: `packages/map_battle/test/psdk_item_registry_manifest_test.dart`

**Logic to implement:**
- Extract/list item effects from PSDK.
- Track status per item effect.
- Unknown items must be explicit.

**Tests:**
- Registry has expected known local items.
- No duplicate ids.

**Definition of done:**
- Item parity becomes measurable.

### Lot 53 - Berries: Healing and Cure

**Goal:** port berry healing, status cure, pinch, and confusion branches.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/*`
- Create: `packages/map_battle/test/psdk_item_berries_test.dart`

**Logic to implement:**
- HP threshold triggers.
- Status cure triggers.
- Nature-based confusion if local nature data exists; otherwise mark that branch partial.

**Tests:**
- Berry heals at threshold.
- Berry cures status.
- Berry is consumed once.

**Definition of done:**
- Berry item family is usable and measured.

### Lot 54 - Held Item Damage, Stat, and Speed Modifiers

**Goal:** port common held item modifiers.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/*`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- Create: `packages/map_battle/test/psdk_item_damage_modifiers_test.dart`

**Logic to implement:**
- Type boosting items.
- Life Orb.
- Eviolite-like stat modifiers if stat calc supports it.
- Choice Scarf speed modifier.

**Tests:**
- Damage boost applies.
- Item consumes or persists correctly.
- Speed modifier affects action order.

**Definition of done:**
- Common item modifiers are hook-based.

### Lot 55 - Choice Items and Move Locks

**Goal:** port Choice Band/Specs/Scarf move-lock behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/*`
- Modify: `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- Create: `packages/map_battle/test/psdk_item_choice_lock_test.dart`

**Logic to implement:**
- First selected move becomes locked.
- Other moves blocked.
- Lock clears on switch/item removal.
- Disabled/Encore interactions stay tested.

**Tests:**
- Choice item locks after first move.
- Switch clears lock.
- Trick changing item affects lock.

**Definition of done:**
- Choice item family strict.

### Lot 56 - Weather/Terrain Duration Items and Misc Held Items

**Goal:** port rocks, Terrain Extender, Big Root, Binding Band, Grip Claw and similar branch-enabling items.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/effect/item/weather_rock_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/terrain_extender_effect.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/item/*`
- Create: `packages/map_battle/test/psdk_item_duration_and_move_modifier_test.dart`

**Logic to implement:**
- Weather duration extension.
- Terrain duration extension.
- Drain amount modifier.
- Bind duration/damage modifier.

**Tests:**
- Damp Rock extends rain.
- Terrain Extender extends terrain.
- Big Root modifies drain.
- Grip Claw modifies bind duration.

**Definition of done:**
- Item-dependent move branches from earlier lots can be promoted.

---

## Phase 5 - Targeting, Actions, AI, and Final 100%

### Lot 57 - Full Target Resolver for Singles and Doubles

**Goal:** implement PSDK target semantics across banks, slots, adjacent targets, allies, and foes.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/battle_target_resolver.dart`
- Modify: `packages/map_battle/lib/src/domain/battle/battle_topology.dart`
- Create: `packages/map_battle/test/psdk_target_resolver_doubles_test.dart`

**Logic to implement:**
- `normal`, `any`, `adjacentFoe`, `allAdjacentFoes`, `allAdjacent`, `ally`, `allySide`, `foeSide`, random target.
- Dead/empty slot filtering.
- Deterministic random target selection.

**Tests:**
- Singles behavior unchanged.
- Doubles target lists match PSDK expectations.
- Random target seeded.

**Definition of done:**
- Methods blocked by `targetingMulti` can start being promoted.

### Lot 58 - Side and Slot Conditions

**Goal:** model PSDK side/slot/position-tied effects fully.

**Files:**
- Create: `packages/map_battle/lib/src/domain/effect/side/side_condition_stack.dart`
- Create: `packages/map_battle/lib/src/domain/effect/slot/slot_condition_stack.dart`
- Modify: `packages/map_battle/lib/src/domain/battle/battle_slot.dart`
- Create: `packages/map_battle/test/psdk_side_slot_condition_test.dart`

**Logic to implement:**
- Side conditions with owner side.
- Slot conditions with bank/position.
- Duration and cleanup.
- Switch-in interactions.

**Tests:**
- Side condition persists across active battler switch.
- Slot condition follows slot, not Pokemon.
- Cleanup timing.

**Definition of done:**
- Side/slot marker methods can become real behavior.

### Lot 59 - Redirection and Doubles Protection

**Goal:** port Follow Me, Rage Powder, Ally Switch, Wide Guard, Quick Guard, Crafty Shield, Mat Block.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/move/battle_target_resolver.dart`
- Modify: `packages/map_battle/lib/src/domain/effect/side/*`
- Create: `packages/map_battle/test/psdk_redirection_guard_test.dart`

**Logic to implement:**
- Redirection priority.
- Powder immunity rules if available.
- Guard side protection.
- Ally Switch slot swap.

**Tests:**
- Follow Me redirects eligible single-target move.
- Wide Guard blocks spread move.
- Ally Switch swaps positions.

**Definition of done:**
- Core doubles utility moves are strict.

### Lot 60 - Voluntary Switch Action Parity

**Goal:** finish PSDK switch action behavior.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/action/battle_action.dart`
- Modify: `packages/map_battle/lib/src/domain/action/battle_action_decision_mapper.dart`
- Modify: `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- Create: `packages/map_battle/test/psdk_switch_action_test.dart`

**Logic to implement:**
- Switch priority/order.
- Legal replacement validation.
- Pursuit-like interactions if in scope.
- Switch event hooks.

**Tests:**
- Switch before regular move when PSDK order requires.
- Illegal switch rejected.
- Switch triggers hazards and abilities.

**Definition of done:**
- Switch action is PSDK-compatible enough for trainer battles.

### Lot 61 - Battle Item and High Priority Item Actions

**Goal:** port PSDK item actions used during battle.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/action/battle_action.dart`
- Create: `packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart`
- Create: `packages/map_battle/test/psdk_battle_item_action_test.dart`

**Logic to implement:**
- Potion/status item application.
- Ball/capture if battle scope includes wild battles.
- HighPriorityItem order.
- Item consumption.

**Tests:**
- Potion heals target.
- Status item cures.
- Illegal item target fails.

**Definition of done:**
- Runtime bag battle behavior can delegate to `map_battle`.

### Lot 62 - Mega and Form/Gimmick Actions

**Goal:** decide and implement PSDK Mega/action gimmick parity if it belongs to project scope.

**Files:**
- Create: `reports/analysis/psdk_fight_form_gimmick_scope.md`
- Modify: `packages/map_battle/lib/src/domain/action/battle_action.dart`
- Create: `packages/map_battle/test/psdk_gimmick_action_test.dart`

**Logic to implement:**
- Mega action eligibility.
- Form/stat/ability update.
- Once-per-battle rule.
- If out of scope, document it and mark methods/actions intentionally unsupported.

**Tests:**
- Eligible battler mega evolves.
- Ineligible battler fails.
- Once-per-battle rule.

**Definition of done:**
- Scope is explicit and no silent gap remains.

### Lot 63 - Flee, Safari, Shift, and NoAction

**Goal:** port non-attack action families.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/action/battle_action.dart`
- Modify: `packages/map_battle/lib/src/domain/battle/battle_outcome.dart`
- Create: `packages/map_battle/test/psdk_misc_action_test.dart`

**Logic to implement:**
- Flee success/failure.
- Safari commands if in scope.
- Shift action in multi battles.
- NoAction for forced/pass turns.

**Tests:**
- Flee ends eligible wild battle.
- Flee fails in trainer battle.
- NoAction consumes action without move effects.

**Definition of done:**
- PSDK action grammar has no unclassified local gaps.

### Lot 64 - Pokemon SDK AI: Move Scoring

**Goal:** port PSDK move-choice heuristics.

**Files:**
- Create: `packages/map_battle/lib/src/domain/ai/psdk_battle_ai.dart`
- Create: `packages/map_battle/lib/src/domain/ai/psdk_move_score.dart`
- Create: `packages/map_battle/test/psdk_ai_move_scoring_test.dart`

**Logic to implement:**
- Score damage.
- Score status/stat utility.
- Avoid ineffective moves.
- Prefer KO moves.
- Respect PP and disabled moves.

**Tests:**
- AI picks KO move.
- AI avoids immune target.
- AI uses utility move when damage is poor.

**Definition of done:**
- Opponent policy can use PSDK-like move scoring.

### Lot 65 - Pokemon SDK AI: Switch, Item, Flee, and Final Acceptance Gate

**Goal:** finish AI parity and define the final 100% acceptance gate.

**Files:**
- Modify: `packages/map_battle/lib/src/domain/ai/psdk_battle_ai.dart`
- Create: `packages/map_battle/test/psdk_ai_action_selection_test.dart`
- Create: `packages/map_battle/test/psdk_final_parity_gate_test.dart`
- Modify: `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- Create: `reports/analysis/psdk_fight_100_percent_acceptance.md`

**Logic to implement:**
- AI can choose switch/item/flee where PSDK would.
- Final gate requires:
  - 728 / 728 Studio attacks either `ported` or explicitly `out_of_scope` with approved scope decision
  - 330 / 330 battle methods either `ported` or approved `out_of_scope`
  - 482 / 482 effect classes either `ported` or approved `out_of_scope`
  - 0 unknown methods
  - runtime bridge exposes all playable moves or explains every unsupported one
  - golden fixtures cover representative PSDK families

**Tests:**
- AI switches away from a bad matchup when PSDK heuristic says so.
- AI uses item when configured and useful.
- Final parity gate fails if any method/effect lacks status.

**Definition of done:**
- The project has a mechanical, testable definition of "100% PSDK battle parity" and the suite enforces it.

---

## Recommended Batch Strategy

Do not execute these 65 lots one by one with a full report after every lot. Recommended grouping:

| Batch | Lots | Purpose |
| --- | --- | --- |
| Batch 1 | 01-07 | Measurement and runtime truth |
| Batch 2 | 08-18 | High-volume attack methods |
| Batch 3 | 19-35 | Advanced move families |
| Batch 4 | 36-44 | Generic effect system |
| Batch 5 | 45-56 | Status, abilities, items |
| Batch 6 | 57-63 | Targeting and actions |
| Batch 7 | 64-65 | AI and final acceptance |

## Definition of 100 Percent

The final target is not "the game starts" or "every attack has a fallback". The final target is:

- every Studio move has a known method;
- every method has an honest status;
- every supported method has tests proving PSDK-equivalent behavior;
- every out-of-scope method is explicitly approved and documented;
- every PSDK effect class is either ported or explicitly out of scope;
- runtime can expose all playable moves without silent filtering;
- golden fixtures prove cross-engine parity for critical behavior families;
- `map_battle` test and analyze commands pass.

## Self-Review

Spec coverage:

- Attack parity is covered by lots 08-35.
- Effect parity is covered by lots 36-44.
- Status, ability, and item parity are covered by lots 45-56.
- Runtime bridge parity is covered by lots 04-07.
- Targeting/actions are covered by lots 57-63.
- AI and final gate are covered by lots 64-65.
- Measurement and regression safety are covered by lots 01-03 and 65.

Known limitation:

- This plan intentionally does not include battle animations, because the current request is about battle parity and the previous audit excluded animations.
- Some gimmick systems may be marked `out_of_scope` only if the project owner agrees. Without that decision, a literal 100% Pokemon SDK parity includes them.

Recommended first execution:

Start with Lots 01-07. They make every later lot easier to measure and prevent wasting work on hidden partial support.
