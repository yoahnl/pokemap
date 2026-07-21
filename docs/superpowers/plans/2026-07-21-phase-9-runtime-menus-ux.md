# Phase 9 — Runtime Menus & Player UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close mechanical roadmap lots FG-160 through FG-165 with real,
persisted and tested player-facing runtime menus.

**Architecture:** `PlayableMapGame` remains the authority for runtime input,
dialogue presentation, save/load and map transitions. The standalone runtime
host owns Flutter menu composition and local player preferences, while pure
projections/codecs live in focused files that widget tests can exercise without
mounting Flame. The implementation order follows dependencies rather than lot
numbers: input authority, options, pause shell, Pokédex, save confirmation,
then fast travel.

**Tech Stack:** Dart 3.13, Flutter 3.46 beta, Flame 1.35, `map_core`,
`map_gameplay`, `map_runtime`, Flutter widget tests.

---

## Scope decisions

- The Narrative Studio roadmap ends at Phase 8. “Phase 9” therefore means the
  canonical mechanics roadmap Phase 9 (`FG-160` to `FG-165`).
- The runtime host is the existing player-facing Flutter shell; no parallel
  menu framework is introduced in `map_runtime`.
- Global volume is not exposed because the engine currently owns only
  per-command Cinematic volume. The Options screen must say this explicitly
  instead of presenting a non-functional slider.
- Fast travel reuses the runtime warp pipeline and a map's authored player
  spawn. It never mutates `GameState` directly and requires the Fly ability.
- Existing Party and Bag views remain read-only in this phase; they are linked
  to live `GameState` snapshots and therefore satisfy menu accessibility
  without inventing unplanned item-use or party-reorder mechanics.

## Task 1 — FG-165 Runtime Input Lock Conventions V0

**Files:**

- Create: `packages/map_runtime/lib/src/presentation/flame/runtime_input_authority.dart`
- Create: `packages/map_runtime/test/runtime_input_authority_test.dart`
- Modify: `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modify: `packages/map_runtime/lib/map_runtime.dart`
- Modify: `packages/map_runtime/test/playable_map_game_input_test.dart`
- Create: `reports/gameplay/fg_165_runtime_input_lock_conventions_v0.md`

- [x] **Step 1: write the pure authority RED tests**

```dart
expect(
  const RuntimeInputAuthoritySnapshot(
    context: RuntimeInputContext.overworld,
    externalLocks: {RuntimeExternalInputLock.pauseMenu},
  ).acceptsRuntimeInput,
  isFalse,
);
```

- [x] **Step 2: run RED**

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/runtime_input_authority_test.dart
```

Expected: compilation failure because the authority types do not exist.

- [x] **Step 3: implement the closed authority contract**

```dart
enum RuntimeInputContext {
  overworld,
  dialogue,
  battle,
  cinematic,
  transition,
  blocked,
}

enum RuntimeExternalInputLock { pauseMenu }

final class RuntimeInputAuthoritySnapshot {
  const RuntimeInputAuthoritySnapshot({
    required this.context,
    this.externalLocks = const <RuntimeExternalInputLock>{},
  });

  final RuntimeInputContext context;
  final Set<RuntimeExternalInputLock> externalLocks;
  bool get acceptsRuntimeInput => externalLocks.isEmpty;
  bool get acceptsOverworldInput =>
      acceptsRuntimeInput && context == RuntimeInputContext.overworld;
}
```

- [x] **Step 4: integrate external locks into the single runtime input seam**

`PlayableMapGame.setExternalInputLock` must clear held movement controls on
acquire; `handleRuntimeInputEvent` must consume every event while an external
lock is held; `inputAuthoritySnapshot` must derive dialogue/battle/cinematic/
transition/blocked from the existing runtime flow instead of storing a second
flow state.

- [x] **Step 5: run GREEN and non-regression**

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test \
  test/runtime_input_authority_test.dart \
  test/playable_map_game_input_test.dart
/opt/homebrew/bin/flutter analyze
```

- [x] **Step 6: write Evidence Pack, stage only FG-165 and commit**

```bash
git commit -m "feat(runtime): unify player input authority"
```

## Task 2 — FG-162 Runtime Options V0

**Files:**

- Create: `packages/map_runtime/lib/src/presentation/flame/dialogue_text_speed.dart`
- Modify: `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart`
- Modify: `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modify: `packages/map_runtime/lib/map_runtime.dart`
- Create: `packages/map_runtime/test/dialogue_text_speed_test.dart`
- Modify: `packages/map_runtime/test/dialogue_runtime_outcome_test.dart`
- Create: `examples/playable_runtime_host/lib/src/runtime_player_options.dart`
- Create: `examples/playable_runtime_host/test/runtime_player_options_test.dart`
- Modify: `examples/playable_runtime_host/lib/main.dart`
- Create: `reports/gameplay/fg_162_runtime_options_v0.md`

- [x] **Step 1: write RED tests for normalization, JSON round-trip and reveal**

```dart
expect(
  RuntimePlayerOptions.fromJson(
    const {'dialogueTextSpeed': 'fast', 'showTouchControls': false},
  ).toJson(),
  const {'dialogueTextSpeed': 'fast', 'showTouchControls': false},
);
```

The overlay test must prove that `advance()` first reveals a partial line and
only a second call advances the dialogue.

- [x] **Step 2: run RED**

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/dialogue_text_speed_test.dart
cd ../../examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/runtime_player_options_test.dart
```

- [x] **Step 3: implement actual dialogue speed**

```dart
enum RuntimeDialogueTextSpeed { slow, normal, fast, instant }
```

Use Unicode runes for reveal units, preserve `instant` as the engine default,
and allow `PlayableMapGame.setDialogueTextSpeed` to update the active overlay.

- [x] **Step 4: persist host options in the existing preferences JSON**

Store the typed object under `playerOptions`; invalid/legacy preferences fall
back to defaults. Apply options to each new `PlayableMapGame` and to the touch
controls visibility state.

- [x] **Step 5: run GREEN, package tests and analyses**

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/dialogue_text_speed_test.dart test/dialogue_runtime_outcome_test.dart
/opt/homebrew/bin/flutter analyze
cd ../../examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/runtime_player_options_test.dart
/opt/homebrew/bin/flutter analyze
```

- [x] **Step 6: Evidence Pack and commit**

```bash
git commit -m "feat(runtime): persist player options"
```

## Task 3 — FG-160 Pause Menu Complete V0

**Files:**

- Modify: `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- Modify: `examples/playable_runtime_host/lib/main.dart`
- Modify: `examples/playable_runtime_host/test/in_game_menu_test.dart`
- Create: `reports/gameplay/fg_160_pause_menu_complete_v0.md`

- [x] **Step 1: write RED widget tests**

Prove Options is a real section, Escape closes, Tab/Enter can activate a menu
tile, Quit asks confirmation, and opening the route acquires the
`RuntimeExternalInputLock.pauseMenu` lock until every exit path completes.

- [x] **Step 2: run RED**

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
```

- [x] **Step 3: implement the complete menu shell**

Add `options` to `InGameMenuSection`, pass a typed options snapshot and change
callback, add explicit Close and Quit actions, use `CallbackShortcuts` for
Escape, and retain live Party/Bag/Pokédex/Save snapshots.

- [x] **Step 4: connect host lifecycle and lock**

Acquire the pause-menu lock before `Navigator.push`, release it in `finally`,
and make Quit close the route then reset only the runtime session.

- [x] **Step 5: GREEN, analyze, build, Evidence Pack and commit**

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
/opt/homebrew/bin/flutter analyze
/opt/homebrew/bin/flutter build macos --debug
git commit -m "feat(runtime): complete the pause menu shell"
```

## Task 4 — FG-161 Runtime Pokédex Read-only V0

**Files:**

- Modify: `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`
- Modify: `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- Modify: `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`
- Modify: `examples/playable_runtime_host/test/in_game_menu_test.dart`
- Create: `reports/gameplay/fg_161_runtime_pokedex_read_only_v0.md`

- [ ] **Step 1: write RED tests for unknown/seen/caught**

```dart
expect(
  resolveRuntimePokedexKnowledge(
    speciesId: 'bulbasaur',
    progression: const PlayerProgression(
      caughtSpeciesIds: ['bulbasaur'],
    ),
  ),
  RuntimePokedexKnowledge.caught,
);
```

The widget test mutates the live snapshot from seen to caught, rebuilds, and
expects the status badge/detail to update without reloading species files.

- [ ] **Step 2: run RED, implement projection and privacy**

Unknown entries render `???`; seen entries expose minimal identity/types;
caught entries expose the full currently available local detail. Caught always
dominates seen.

- [ ] **Step 3: GREEN, analyze, Evidence Pack and commit**

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/runtime_pokedex_loader_test.dart test/in_game_menu_test.dart
/opt/homebrew/bin/flutter analyze
git commit -m "feat(runtime): expose live Pokedex progress"
```

## Task 5 — FG-163 Runtime Save Menu V0

**Files:**

- Modify: `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- Modify: `examples/playable_runtime_host/test/in_game_menu_test.dart`
- Create: `reports/gameplay/fg_163_runtime_save_menu_v0.md`

- [ ] **Step 1: write RED tests**

Prove Cancel invokes no callback, Confirm invokes exactly once, busy disables
actions, structured disk errors are visible, and thrown callback errors become
visible instead of escaping the widget tree.

- [ ] **Step 2: run RED and implement confirmation/error guard**

Use a Material confirmation dialog before save. Keep load unconfirmed. Wrap
callbacks in `try/catch`, preserve mounted checks and always clear busy state.

- [ ] **Step 3: GREEN, analyze, Evidence Pack and commit**

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
/opt/homebrew/bin/flutter analyze
git commit -m "feat(runtime): harden the pause save menu"
```

## Task 6 — FG-164 Runtime Map / Fast Travel UI V0

**Files:**

- Create: `packages/map_runtime/lib/src/application/runtime_fast_travel.dart`
- Modify: `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modify: `packages/map_runtime/lib/map_runtime.dart`
- Create: `packages/map_runtime/test/runtime_fast_travel_test.dart`
- Create: `examples/playable_runtime_host/lib/src/runtime_map_destinations.dart`
- Create: `examples/playable_runtime_host/test/runtime_map_destinations_test.dart`
- Modify: `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- Modify: `examples/playable_runtime_host/lib/main.dart`
- Modify: `examples/playable_runtime_host/test/in_game_menu_test.dart`
- Create: `reports/gameplay/fg_164_runtime_map_fast_travel_ui_v0.md`

- [ ] **Step 1: write RED domain and widget tests**

Prove deterministic known/current/locked destinations; reject no-Fly, unknown,
current and busy destinations; and prove a successful travel uses the authored
player spawn and the normal map activation/warp pipeline.

- [ ] **Step 2: implement structured result and public runtime seam**

```dart
enum RuntimeFastTravelFailure {
  runtimeUnavailable,
  flyLocked,
  unknownDestination,
  currentDestination,
  transitionBusy,
  invalidSpawn,
  transitionFailed,
}
```

`PlayableMapGame.fastTravelToMap` validates state, loads the target bundle,
resolves its authored player spawn, then delegates to `_handleWarp`. Change the
private warp method to return success without changing existing callers.

- [ ] **Step 3: implement Map section**

List every project map with known/current/locked state. Enable travel only for
known non-current destinations when Fly is unlocked. On success, close the menu
so the pause lock is released after the transition.

- [ ] **Step 4: GREEN, full touched-package gates and commit**

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/runtime_fast_travel_test.dart test/playable_map_game_input_test.dart
/opt/homebrew/bin/flutter analyze
cd ../../examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/runtime_map_destinations_test.dart test/in_game_menu_test.dart
/opt/homebrew/bin/flutter analyze
/opt/homebrew/bin/flutter build macos --debug
git commit -m "feat(runtime): add known-map fast travel"
```

## Final Phase 9 gate

- [ ] Run complete `map_runtime` and `playable_runtime_host` test suites.
- [ ] Run both analyses and the host macOS debug build.
- [ ] Run the Phase A runtime/host smoke tests.
- [ ] Perform the five manual named passes required by `codex_rule.md`:
  Audit/Architecture, Implementation, Tests, Build/Validation, Critique.
- [ ] Verify six isolated commits, `git diff --check`, and a clean final status.
- [ ] Propose `DONE` for FG-160 through FG-165; do not edit the canonical
  mechanics roadmap unless the user explicitly asks for that status update.
