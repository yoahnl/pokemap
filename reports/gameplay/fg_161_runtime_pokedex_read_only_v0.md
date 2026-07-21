# FG-161 — Runtime Pokédex Read-only V0

Date: 2026-07-21

Verdict proposé: `DONE`

## Résumé exécutif

The pause-menu Pokédex now projects the live `PlayerProgression` status for
every local species. Unknown species hide identity and descriptive content;
seen species expose name and types; caught species expose the complete detail
currently available in project data. Capture always dominates seen, including
legacy saves that contain a species only in `caughtSpeciesIds`.

The species files are loaded once for the menu route. Knowledge is resolved
from the current `GameState` on every widget rebuild, so reopening or rebuilding
after encounter/capture immediately reflects persisted progression without
reloading the species directory.

## Audit initial et scope

- `RuntimePokedexEntry` already provided stable, sorted species metadata.
- The menu displayed every identity and flavor text regardless of player
  progression.
- `PlayerProgression` already persisted `seenSpeciesIds` and
  `caughtSpeciesIds`; runtime battle/capture paths already write those fields.
- Initial Git state was clean after `6a59f5b5`.

Included: knowledge projection, caught precedence, unknown privacy, seen/caught
badges, live detail updates and focused coverage.

Excluded: Pokédex search/filtering, artwork, habitat data, editor schema changes
and any new persistence field.

## Fichiers modifiés

| File | Zones | Impact |
|---|---|---|
| `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart` | `RuntimePokedexKnowledge`, `resolveRuntimePokedexKnowledge` | Adds a pure projection over existing progression. |
| `examples/playable_runtime_host/lib/src/in_game_menu.dart` | Pokédex list/detail builders and labels | Applies privacy/status from the live snapshot. |
| `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart` | Knowledge projection test | Covers unknown, seen and caught dominance. |
| `examples/playable_runtime_host/test/in_game_menu_test.dart` | Live privacy widget test and caught fixture | Proves unknown → seen → caught without species reload. |
| `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md` | FG-161 checklist | Records executable completion. |
| `reports/gameplay/fg_161_runtime_pokedex_read_only_v0.md` | This Evidence Pack | Records evidence and limits. |

## Zones précises

The pure resolver trims identifiers, then checks `caughtSpeciesIds` before
`seenSpeciesIds`. An empty or absent identifier is unknown.

The list receives `gameState.progression` from the menu build rather than
storing a copy. It renders:

| Knowledge | List/detail visibility |
|---|---|
| Unknown | `???`, national number and “Inconnu”; no ID, type or flavor text. |
| Seen | Name, national number, types and “Vu”; no project/internal detail or flavor text. |
| Caught | Name, types, ID, project availability and flavor text. |

Status chips have stable semantic keys containing species ID and knowledge,
which supports deterministic widget regression tests.

## TDD et validations

RED:

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test \
  test/runtime_pokedex_loader_test.dart \
  test/in_game_menu_test.dart
```

Observed:

- compilation failed because `RuntimePokedexKnowledge` and
  `resolveRuntimePokedexKnowledge` did not exist;
- the privacy test found no `???` because unknown species were still fully
  disclosed.

GREEN:

```bash
/opt/homebrew/bin/flutter test \
  test/runtime_pokedex_loader_test.dart \
  test/in_game_menu_test.dart
```

Exact result: `+9: All tests passed!`

The live widget test starts unknown, rebuilds the same menu with a seen
progression, then caught progression. It proves flavor text appears only at the
captured state and that species files are not reloaded.

Analysis:

```bash
/opt/homebrew/bin/flutter analyze
```

Exact result: `No issues found! (ran in 3.7s)`.

Build:

```bash
/opt/homebrew/bin/flutter build macos --debug
```

Exact result:
`✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app`

Full host and runtime suites remain assigned to the final Phase 9 gate.

## Passes séparées

| Pass | Verdict |
|---|---|
| Audit / Architecture | PASS — existing save progression is reused; no parallel Pokédex store. |
| Implementation | PASS — knowledge is a pure projection and species metadata remains immutable. |
| Tests | PASS — RED observed and nine focused tests pass. |
| Build / Validation | PASS — host analyzer and macOS build pass. |
| Critique finale | PASS — internal IDs and flavor are not leaked for unknown/seen states. |

## Auto-critique, limites et risques

- National number remains visible for unknown entries, providing stable list
  ordering while preserving identity privacy.
- “Seen” displays types because the lot's explicit V0 plan defines minimal
  identity/types at this state.
- The menu is paused by FG-165, so progression normally changes between menu
  openings; live rebuild support also handles programmatic state replacement.
- This lot does not claim artwork or a full canonical Pokémon Pokédex schema.

## État Git final attendu

The dedicated commit contains only the inventoried files. Commit hash and final
worktree status are recorded in the Phase 9 handoff.

## Prochaine étape

FG-163 adds save confirmation and converts thrown disk failures into visible,
non-crashing player feedback.
