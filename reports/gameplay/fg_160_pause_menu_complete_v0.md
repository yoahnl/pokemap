# FG-160 — Pause Menu Complete V0

Date: 2026-07-21

Verdict proposé: `DONE`

## Résumé exécutif

The runtime host pause menu now exposes the existing Pokédex, Party, Bag,
Trainer and Save flows plus a real Options section, explicit Close and a
confirmed Quit-session action. Keyboard navigation supports Tab/Enter and
Escape; mouse/touch interaction remains available.

The complete Flutter route lifecycle is wrapped by the typed FG-165 pause-menu
lock. The guard releases its owner in `finally`, including normal close, Escape,
Quit and navigation errors. Acquiring the lock therefore prevents direct
gamepad forwarding from moving the overworld beneath the route.

## Audit initial et scope

- The existing menu already exposed live GameState snapshots for Party, Bag,
  Trainer and Save/Load, but had no Options or Quit flow.
- The host pushed a Flutter route without notifying Flame. Keyboard focus could
  hide keyboard input, but direct gamepad events still reached the game.
- FG-162 supplied real persisted player options before this UI exposed them.
- FG-165 supplied the typed external input owner and runtime enforcement.
- Initial Git state was clean after `1056f254`.

Included: complete menu entries, keyboard flow, real options, close, confirmed
session quit, host option application and typed lock lifecycle.

Excluded: Pokédex knowledge privacy (FG-161), save confirmation/error hardening
(FG-163), fast travel (FG-164), item use and party reordering.

## Fichiers modifiés

| File | Zones | Impact |
|---|---|---|
| `examples/playable_runtime_host/lib/src/in_game_menu.dart` | `InGameMenuSection`, constructor contract, shortcut/focus shell, Options section, Quit dialog, typed route guard | Completes player-facing pause navigation and makes route locking independently testable. |
| `examples/playable_runtime_host/lib/main.dart` | `_openInGameMenu`, `_updatePlayerOptions` | Wraps Navigator in the typed lock, applies/persists options and resets only the runtime session on Quit. |
| `examples/playable_runtime_host/test/in_game_menu_test.dart` | Guard unit tests and widget tests | Proves lock release, keyboard navigation, options, Escape and confirmed Quit. |
| `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md` | FG-160 checklist | Records executable completion. |
| `reports/gameplay/fg_160_pause_menu_complete_v0.md` | This Evidence Pack | Records proof and preserved limits. |

## Zones précises

The route lifecycle is centralized as:

```dart
Future<void> runWithRuntimePauseMenuInputLock({
  required RuntimeExternalInputLockSetter setExternalInputLock,
  required Future<void> Function() openMenu,
}) async {
  setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: true);
  try {
    await openMenu();
  } finally {
    setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: false);
  }
}
```

`_openInGameMenu` passes the real `PlayableMapGame.setExternalInputLock` method
to this guard. Quit pops the route then calls `_reset`, which closes only the
active runtime session and does not delete saves or host preferences.

`CallbackShortcuts` maps Escape to the same close callback. The Pokédex tile
owns initial focus so Tab/Enter traverses the side menu predictably.

The Options section edits the FG-162 object. Speed changes immediately call the
active game, and every change is persisted best-effort. Audio visibly states
that global volume is unavailable instead of presenting a non-functional
control.

## TDD et validations

RED:

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
```

Observed compilation failure: `InGameMenuPage` had no `playerOptions`,
`supportsTouchControls`, `onOptionsChanged` or `onQuitRequested` contract.

GREEN:

```bash
/opt/homebrew/bin/flutter test test/in_game_menu_test.dart
```

Exact result: `+6: All tests passed!`

Covered behaviors:

- the typed lock is acquired then released after completion;
- the typed lock is released after a thrown navigation error;
- existing Pokédex/Party/Bag/Trainer navigation remains intact;
- existing Save/Load callbacks remain connected;
- Tab + Enter opens Party and Escape closes;
- dialogue speed and touch visibility update real typed options;
- Quit cancellation invokes no callback and confirmation invokes exactly once.

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

Full host and runtime suites are reserved for the Phase 9 final gate after all
six lots have landed.

## Passes séparées

| Pass | Verdict |
|---|---|
| Audit / Architecture | PASS — the host composes UI while PlayableMapGame remains input authority. |
| Implementation | PASS — every route exit shares one typed `finally` guard. |
| Tests | PASS — RED observed and six focused tests pass. |
| Build / Validation | PASS — host analyze and macOS build pass. |
| Critique finale | PASS — Quit closes the session only; it does not impersonate an application-process exit. |

## Auto-critique, limites et risques

- “Quitter la partie” returns to the project loader. It intentionally does not
  terminate the desktop process, which is safer and matches the host boundary.
- Party and Bag remain read-only. Their complete menu accessibility does not
  claim unplanned item use or reorder mechanics.
- The menu is a standalone runtime-host surface, not an editor design-system
  screen; editor UI token rules do not apply here.
- Save confirmation remains assigned to FG-163, so this lot preserves the
  current one-click callback until that dedicated lot lands.

## État Git final attendu

The dedicated commit must contain only the files above. Commit hash and final
worktree status are included in the Phase 9 completion handoff.

## Prochaine étape

FG-161 projects live seen/caught progression into the existing Pokédex section
without reloading species assets.
