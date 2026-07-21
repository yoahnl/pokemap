# Phase 9 — Runtime Menus & Player UX Completion Evidence

Date: 2026-07-21

Scope: FG-160 through FG-165 as explicitly defined in
`pokemap_roadmap_mecaniques_fangame.md`.

Overall verdict proposed: `DONE` for FG-160, FG-161, FG-162, FG-163, FG-164
and FG-165.

The canonical roadmap itself was not edited because the user asked for
implementation, not a roadmap status mutation.

## Résumé exécutif

Phase 9 now exposes a complete V0 player menu over real runtime state:

- typed modal input ownership prevents keyboard, touch and direct gamepad input
  from reaching the overworld under the pause route;
- Party, Bag, Pokédex, Trainer, Save, Options, Map, Close and Quit are reachable
  with mouse and keyboard;
- dialogue speed changes actual Flame rendering and persists locally;
- Pokédex knowledge updates from live seen/caught progression and preserves
  unknown-species privacy;
- save requires confirmation and disk/runtime failures remain visible;
- Map shows current, known and locked destinations without a visual-polish
  dependency or a fake Fly implementation.

All touched-package suites, analyses, Phase A smokes and the macOS host build
pass freshly after all six commits.

## Interpretation de la demande

The Narrative Studio completion roadmap ended at Phase 8. The repository's
canonical remaining “Phase 9” is the mechanics roadmap section “Menus runtime
et UX joueur,” whose explicit lots are FG-160–FG-165. That interpretation was
recorded before implementation.

The work was executed without a dedicated worktree per the user's earlier
instruction. Every lot received a dedicated commit as requested.

## Audit initial

Initial Git state:

```text
branch: main
HEAD: a09d399b2 feat(narrative): close Selbrume release gate
worktree: clean
```

Initial findings:

- the host menu already had read-only Party, Bag, Pokédex and Trainer snapshots
  plus Save/Load callbacks;
- it lacked Options, Map, Quit, keyboard shortcuts and an external input lock;
- direct gamepad events bypassed Flutter focus and reached Flame;
- dialogue rendered full lines instantly;
- host preferences stored only project path and map ID;
- Pokédex disclosed all species details regardless of progression;
- save had no menu confirmation and no UI-level thrown-error guard;
- visited maps were already persisted by Narrative Event progress;
- actual Fly mechanics belong to FG-125, which remains TODO.

## Lots et commits

| Lot | Verdict | Commit | Proof summary |
|---|---|---|---|
| FG-165 Runtime Input Lock Conventions V0 | `DONE` | `ef4a449bc` | Typed authority, pause owner, held-direction cleanup, common input seam. |
| FG-162 Runtime Options V0 | `DONE` | `1056f2540` | Real Unicode dialogue reveal, persisted typed text/touch preferences. |
| FG-160 Pause Menu Complete V0 | `DONE` | `6a59f5b5a` | Complete menu, Tab/Enter, Escape, confirmed session Quit, lock lifecycle. |
| FG-161 Runtime Pokédex Read-only V0 | `DONE` | `1005d206c` | Live unknown/seen/caught projection and privacy. |
| FG-163 Runtime Save Menu V0 | `DONE` | `c130251f6` | Confirmation, cancel, busy guard, structured/thrown error feedback. |
| FG-164 Runtime Map / Fast Travel UI V0 | `DONE` (UI) | `c6b415127` | Current/known/locked destinations; honest FG-125 boundary. |

The dependency order was intentional: input authority and real options were
implemented before the pause shell consumed them.

## Inventaire complet des fichiers de Phase 9

Created:

- `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md`
- `examples/playable_runtime_host/lib/src/runtime_map_destinations.dart`
- `examples/playable_runtime_host/lib/src/runtime_player_options.dart`
- `examples/playable_runtime_host/test/runtime_map_destinations_test.dart`
- `examples/playable_runtime_host/test/runtime_player_options_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/dialogue_text_speed.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_input_authority.dart`
- `packages/map_runtime/test/dialogue_text_speed_test.dart`
- `packages/map_runtime/test/runtime_input_authority_test.dart`
- `reports/gameplay/fg_160_pause_menu_complete_v0.md`
- `reports/gameplay/fg_161_runtime_pokedex_read_only_v0.md`
- `reports/gameplay/fg_162_runtime_options_v0.md`
- `reports/gameplay/fg_163_runtime_save_menu_v0.md`
- `reports/gameplay/fg_164_runtime_map_fast_travel_ui_v0.md`
- `reports/gameplay/fg_165_runtime_input_lock_conventions_v0.md`
- `reports/gameplay/fg_160_165_phase_9_runtime_menus_ux_completion.md`

Modified:

- `examples/playable_runtime_host/lib/main.dart`
- `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`
- `examples/playable_runtime_host/test/in_game_menu_test.dart`
- `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/dialogue_runtime_outcome_test.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`

Each lot Evidence Pack includes precise modified zones and the complete content
of its created implementation/test files.

## Résultats TDD ciblés

| Lot | RED proof | Final targeted result |
|---|---|---|
| FG-165 | Authority types and lock methods undefined. | `+39: All tests passed!` |
| FG-162 | Speed/overlay/options contracts undefined. | Runtime `+7`; host `+3`, all passed. |
| FG-160 | New menu constructor/options/quit contract absent. | `+6: All tests passed!` |
| FG-161 | Knowledge resolver absent and unknown data disclosed. | `+9: All tests passed!` |
| FG-163 | Confirmation absent; thrown disk error escaped. | `+8: All tests passed!` |
| FG-164 | Destination projection and Map input absent. | `+11: All tests passed!` |

## Gate exhaustive finale

### Runtime suite

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test
```

Exact final result:

```text
01:59 +1917 ~1: All tests passed!
```

The single skip is pre-existing/intentional and was not converted to a pass.

### Host suite

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test
```

Exact final result:

```text
03:30 +89: All tests passed!
```

### Analyses

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter analyze
```

Exact result: `No issues found! (ran in 4.4s)`.

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter analyze
```

Exact result: `No issues found! (ran in 4.2s)`.

### Phase A smokes

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/phase_a_golden_battle_slice_smoke_test.dart
```

Exact result: `+3: All tests passed!`

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart
```

Exact result: `+1: All tests passed!`

### Build

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter build macos --debug
```

Exact result:

```text
✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

### Hygiene

- every touched Dart file was formatted package-locally;
- `git diff --check` passed before every commit;
- generated build output was not staged;
- no canonical roadmap status was changed.

## Passes manuelles séparées

The active environment instruction prohibited spawning sub-agents for this
request. The five required `codex_rule.md` roles were therefore executed as
separate named passes.

### Audit / Architecture — PASS

- `map_runtime` remains the runtime authority;
- host UI owns Flutter composition and local presentation preferences;
- gameplay state stays in existing `GameState`/save contracts;
- the FG-125 Fly boundary was discovered and preserved.

### Implementation — PASS

- one common input seam handles every runtime source;
- options are consumed by real behavior;
- Pokédex/Map are projections, not parallel stores;
- save delegates to the existing repository.

### Tests — PASS

- RED failures were observed for every lot;
- positive, negative, guard and non-regression cases were added;
- both final full suites pass.

### Build / Validation — PASS

- both analyzers pass;
- both Phase A smokes pass;
- macOS debug host builds.

### Critique finale — PASS with explicit limits

- no fake global-volume slider was added without an audio mixer;
- no fake Fly button or hidden warp seam was added while FG-125 is TODO;
- Quit closes the runtime session and returns to the loader; it does not
  terminate the desktop process;
- Party and Bag remain live read-only V0 views; item use/reorder are not claimed;
- map knowledge relies on Narrative Event visit progress and fails closed.

## État produit proposé

| Lot | Proposed canonical status | Remaining external dependency |
|---|---|---|
| FG-160 | `DONE` | None for V0. |
| FG-161 | `DONE` | None for V0. |
| FG-162 | `DONE` | Global volume waits for a real audio mixer. |
| FG-163 | `DONE` | Multi-slot/cloud save out of scope. |
| FG-164 | `DONE` for Map UI | FG-125 remains required for actual Fly/Fast Travel. |
| FG-165 | `DONE` | Add typed owners if future external overlays appear. |

For the six explicitly defined Phase 9 lots, implementation completion is
`6/6 (100%)`. This percentage does not include FG-125 or unrelated mechanics
roadmap phases.

## Risques restants et prochaine étape

The honest next mechanics lot for interactive travel is FG-125. It should add a
real Fly field ability/unlock contract, destination policy, interior rule and a
tested warp-to-authored-spawn seam. Only then should FG-164 render an enabled
travel action.

## État Git final attendu

After the closure evidence commit:

- branch remains `main`;
- the six lot commits plus one evidence-gate commit are present;
- worktree is clean;
- nothing is pushed because the user requested commits, not a push.
