# FG-163 — Runtime Save Menu V0

Date: 2026-07-21

Verdict proposé: `DONE`

## Résumé exécutif

The pause-menu save flow now requires explicit confirmation before invoking the
real runtime save callback. Cancelling performs no write. Save and load share a
single guarded action runner that disables both buttons during I/O, preserves
structured host errors, catches thrown disk/runtime exceptions, and always
clears the busy state while mounted.

Load remains one click because it is a read operation. No alternate save format
or repository was introduced; the menu still delegates to the existing
`PlayableMapGame.saveGame` / `loadGame` pipeline through host callbacks.

## Audit initial et scope

- The host callback already caught production `saveGame`/`loadGame` exceptions
  and returned `InGameMenuActionResult`.
- The menu itself invoked save immediately and awaited callbacks without a
  `try/catch`, so an injected or future host callback could escape the widget
  tree.
- `_saveBusy` existed but duplicated save and load state handling.
- Initial Git state was clean after `1005d206`.

Included: confirmation, cancel guard, exactly-once callback path, shared busy
guard, structured error rendering and thrown-exception rendering.

Excluded: save-slot selection, autosave, cloud sync, save schema changes and
load confirmation.

## Fichiers modifiés

| File | Zones | Impact |
|---|---|---|
| `examples/playable_runtime_host/lib/src/in_game_menu.dart` | `_runSave`, `_runLoad`, `_runSaveLoadAction`, confirmation dialog | Hardens the existing save/load callbacks without duplicating persistence. |
| `examples/playable_runtime_host/test/in_game_menu_test.dart` | Existing save test plus cancellation/busy/error widget test | Covers positive, negative and failure paths. |
| `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md` | FG-163 checklist | Records executable completion. |
| `reports/gameplay/fg_163_runtime_save_menu_v0.md` | This Evidence Pack | Records proof, scope and limits. |

## Zones précises

`_runSave` opens a Material `AlertDialog`. Only a `true` result proceeds to the
shared runner. Both buttons use stable keys for deterministic keyboard/widget
coverage.

`_runSaveLoadAction`:

1. ignores re-entry while `_saveBusy` is true;
2. clears previous status/error and disables Save + Load;
3. awaits the injected production callback;
4. renders returned status/error values unchanged;
5. converts a thrown error to `Erreur sauvegarde: …` or
   `Erreur chargement: …`;
6. clears busy in `finally` only while the widget remains mounted.

This preserves the host's existing disk error detail and adds a second UI-level
guard against callback changes.

## TDD et validations

RED:

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
```

Observed:

- no `save-confirm-button` or confirmation dialog existed;
- cancellation could not be expressed;
- a `StateError('disk full')` escaped the widget tree.

GREEN:

```bash
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
```

Exact result: `+8: All tests passed!`

The added/updated tests prove:

- Cancel invokes save zero times;
- Confirm invokes save once;
- successful save/load statuses remain visible;
- both buttons have `onPressed == null` while a load future is pending;
- a thrown `disk full` error is caught and rendered;
- a structured disk error is rendered unchanged;
- all previously completed menu, options, quit and Pokédex flows remain green.

Analysis:

```bash
/opt/homebrew/bin/flutter analyze
```

Exact result: `No issues found! (ran in 3.6s)`.

Build:

```bash
/opt/homebrew/bin/flutter build macos --debug
```

Exact result:
`✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app`

Full host/runtime suites remain assigned to the final Phase 9 gate.

## Passes séparées

| Pass | Verdict |
|---|---|
| Audit / Architecture | PASS — the existing persistence pipeline remains the sole authority. |
| Implementation | PASS — confirmation precedes busy/write; shared runner closes every state path. |
| Tests | PASS — RED observed and eight focused tests pass. |
| Build / Validation | PASS — host analyzer and macOS build pass. |
| Critique finale | PASS — no success is synthesized; structured/throwing failures remain failures. |

## Auto-critique, limites et risques

- The confirmation copy says the existing save will be replaced; this host
  currently has one canonical save slot, so the wording is accurate.
- Callback cancellation after I/O starts is not supported. Buttons stay
  disabled until the future resolves.
- Save errors are surfaced as text. Retry is intentionally the same explicit
  Save action rather than an additional hidden loop.
- This lot does not change atomicity guarantees inside the repository; it
  hardens the player-facing orchestration around the existing implementation.

## État Git final attendu

The dedicated commit contains only the files above. Commit hash and final
worktree status are recorded in the Phase 9 handoff.

## Prochaine étape

FG-164 is the final functional lot: project map destinations and Fly-gated fast
travel through the normal runtime transition pipeline.
