# FG-164 — Runtime Map / Fast Travel UI V0

Date: 2026-07-21

Verdict proposé: `DONE` for FG-164 UI

Dependency kept explicit: FG-125 Fly / Fast Travel V0 remains `TODO`.

## Résumé exécutif

The pause menu now includes a functional read-only Map section. It lists project
maps deterministically, marks the current map, reveals visited destinations and
hides locked destination names. The projection is built from the authored
manifest plus persisted `NarrativeEventProgress.visitedNarrativeMapIds`.

No fast-travel button is exposed because the canonical mechanics roadmap keeps
the actual Fly/warp mechanic in FG-125, which is still TODO, and the current
`FieldAbility` contract has no Fly member. The UI states this limitation
explicitly. This satisfies FG-164's exact condition “used by Fly if available”:
Fly is not yet available, so this lot does not synthesize or misrepresent it.

## Remise en cause du micro-plan initial

The initial Phase 9 micro-plan proposed adding a public fast-travel seam to
`PlayableMapGame`. Repository evidence invalidated that scope:

- canonical FG-125 owns unlocked destinations, ability/badge validation and
  warp-to-spawn behavior;
- FG-125 is marked TODO;
- `FieldAbility` contains Surf, Cut, Strength, Flash, Rock Smash, Waterfall and
  Dive, but not Fly;
- FG-164 only requires known destinations and integration with Fly *if
  available*.

The micro-plan was corrected before implementation. The alternative is smaller,
architecturally honest and keeps FG-125 independently implementable.

## Audit initial et scope

- Project manifest already supplies map ID, name and deterministic sort order.
- Narrative Event progress already persists visited map IDs and marks map entry.
- The pause menu had no Map entry.
- Initial Git state was clean after `c130251f`.

Included: current/known/locked projection, manifest hygiene, privacy, menu
rendering and explicit unavailable-Fly state.

Excluded: FieldAbility schema changes, badge/move validation, interior rules,
warp/spawn execution and fast-travel buttons. Those are FG-125.

## Fichiers

| File | Zones | Impact |
|---|---|---|
| `examples/playable_runtime_host/lib/src/runtime_map_destinations.dart` | New status, projection and normalization | Builds immutable player-visible destinations from existing data. |
| `examples/playable_runtime_host/test/runtime_map_destinations_test.dart` | New pure projection tests | Covers ordering, status, privacy, duplicate/blank IDs. |
| `examples/playable_runtime_host/lib/src/in_game_menu.dart` | Map section/tile and map list | Exposes destinations without visual-polish or Fly dependencies. |
| `examples/playable_runtime_host/lib/main.dart` | Menu composition | Passes the already loaded manifest map entries. |
| `examples/playable_runtime_host/test/in_game_menu_test.dart` | Map widget test | Proves current/known display, locked-name privacy and absence of false travel action. |
| `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md` | Corrected FG-164 task | Records the FG-125 boundary and completed steps. |
| `reports/gameplay/fg_164_runtime_map_fast_travel_ui_v0.md` | This Evidence Pack | Records the scope correction and evidence. |

## Zones précises

`resolveRuntimeMapDestinations`:

- trims and deduplicates manifest map IDs;
- ignores blank IDs;
- treats current map as known;
- merges persisted visited map IDs;
- sorts by `sortOrder`, then authored name, then ID;
- emits `current`, `known` or `locked`;
- replaces every locked display name with `???`.

The Map section uses only icons, labels, cards and list tiles. It has no
rendered-world-map asset dependency. Because no Fly callback exists, it renders
no travel button and clearly references the planned FG-125 mechanic.

## TDD et validations

RED:

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test \
  test/runtime_map_destinations_test.dart \
  test/in_game_menu_test.dart
```

Observed compilation failures: the projection file/types did not exist and
`InGameMenuPage` had no `projectMaps` input.

GREEN:

```bash
/opt/homebrew/bin/flutter test \
  test/runtime_map_destinations_test.dart \
  test/in_game_menu_test.dart
```

Exact result: `+11: All tests passed!`

Covered behaviors include deterministic ordering, current/known/locked status,
locked-name privacy, defensive duplicate/blank manifest handling, menu labels,
explicit unavailable state and absence of a false `FilledButton` action.

Analysis first run:

```text
2 info findings: prefer_const_literals_to_create_immutables
```

Both test literals were corrected. Final analysis:

```bash
/opt/homebrew/bin/flutter analyze
```

Exact result: `No issues found! (ran in 4.1s)`.

Build:

```bash
/opt/homebrew/bin/flutter build macos --debug
```

Exact result:
`✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app`

## Passes séparées

| Pass | Verdict |
|---|---|
| Audit / Architecture | PASS — FG-125 ownership was found and the over-scoped plan was corrected. |
| Implementation | PASS — immutable projection uses manifest + persisted visits only. |
| Tests | PASS — RED observed and 11 focused tests pass. |
| Build / Validation | PASS — final host analyzer and macOS build pass. |
| Critique finale | PASS — no control claims a Fly/warp behavior the engine cannot perform. |

## Auto-critique, limites et risques

- Visited status is based on Narrative Event map-entry progress. Projects that
  never dispatch narrative map-enter occurrences may only show the current map;
  this is safe and fail-closed.
- Locked maps retain a row and national ordering equivalent, but hide authored
  names. This lets players see discovery capacity without spoilers.
- FG-164 can be proposed DONE independently. The product must not be described
  as supporting Fly or fast travel until FG-125 is implemented and proven.

## Contenu complet des fichiers créés

### `runtime_map_destinations.dart`

```dart
import 'package:map_core/map_core.dart';

enum RuntimeMapDestinationStatus {
  current,
  known,
  locked,
}

/// Read-only player projection of an authored project map.
final class RuntimeMapDestination {
  const RuntimeMapDestination({
    required this.mapId,
    required this.authoredName,
    required this.displayName,
    required this.status,
  });

  final String mapId;
  final String authoredName;
  final String displayName;
  final RuntimeMapDestinationStatus status;
}

/// Builds the Phase 9 map list from existing manifest and narrative progress.
///
/// Fast travel itself belongs to FG-125 and is not synthesized here. The
/// current map is always known; other names are revealed only after a recorded
/// visit. Duplicate or blank manifest IDs are ignored defensively.
List<RuntimeMapDestination> resolveRuntimeMapDestinations({
  required List<ProjectMapEntry> maps,
  required GameState gameState,
}) {
  final currentMapId = gameState.currentMapId.trim();
  final knownMapIds = <String>{
    currentMapId,
    ...gameState.narrativeEventProgress.visitedNarrativeMapIds.map(
      (id) => id.trim(),
    ),
  }..remove('');
  final normalizedMaps = <String, ProjectMapEntry>{};
  for (final map in maps) {
    final mapId = map.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    normalizedMaps.putIfAbsent(mapId, () => map);
  }
  final sortedMaps = normalizedMaps.entries.toList(growable: false)
    ..sort((left, right) {
      final sortOrder = left.value.sortOrder.compareTo(right.value.sortOrder);
      if (sortOrder != 0) {
        return sortOrder;
      }
      final name = left.value.name.compareTo(right.value.name);
      return name != 0 ? name : left.key.compareTo(right.key);
    });

  return List<RuntimeMapDestination>.unmodifiable(
    sortedMaps.map((entry) {
      final mapId = entry.key;
      final authoredName =
          entry.value.name.trim().isEmpty ? mapId : entry.value.name.trim();
      final status = mapId == currentMapId
          ? RuntimeMapDestinationStatus.current
          : knownMapIds.contains(mapId)
              ? RuntimeMapDestinationStatus.known
              : RuntimeMapDestinationStatus.locked;
      return RuntimeMapDestination(
        mapId: mapId,
        authoredName: authoredName,
        displayName:
            status == RuntimeMapDestinationStatus.locked ? '???' : authoredName,
        status: status,
      );
    }),
  );
}
```

### `runtime_map_destinations_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/runtime_map_destinations.dart';

void main() {
  test('projects deterministic current, known and locked destinations', () {
    final destinations = resolveRuntimeMapDestinations(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'cave',
          name: 'Grotte',
          relativePath: 'maps/cave.json',
          sortOrder: 30,
        ),
        ProjectMapEntry(
          id: 'port',
          name: 'Port',
          relativePath: 'maps/port.json',
          sortOrder: 20,
        ),
        ProjectMapEntry(
          id: 'town',
          name: 'Bourg',
          relativePath: 'maps/town.json',
          sortOrder: 10,
        ),
      ],
      gameState: GameState(
        saveId: 'save',
        currentMapId: 'town',
        narrativeEventProgress: NarrativeEventProgress(
          visitedNarrativeMapIds: const ['port'],
        ),
      ),
    );

    expect(destinations.map((entry) => entry.mapId), ['town', 'port', 'cave']);
    expect(destinations[0].status, RuntimeMapDestinationStatus.current);
    expect(destinations[1].status, RuntimeMapDestinationStatus.known);
    expect(destinations[2].status, RuntimeMapDestinationStatus.locked);
    expect(destinations[2].displayName, '???');
  });

  test('normalizes duplicate and stale manifest entries defensively', () {
    final destinations = resolveRuntimeMapDestinations(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
        ProjectMapEntry(
          id: ' port ',
          name: 'Duplicate',
          relativePath: 'maps/duplicate.json',
        ),
        ProjectMapEntry(
          id: ' ',
          name: 'Invalid',
          relativePath: 'maps/invalid.json',
        ),
      ],
      gameState: const GameState(saveId: 'save', currentMapId: 'port'),
    );

    expect(destinations, hasLength(1));
    expect(destinations.single.displayName, 'Port');
    expect(destinations.single.status, RuntimeMapDestinationStatus.current);
  });
}
```

## État Git final attendu

The dedicated FG-164 commit contains only the files inventoried above. Exact
hash and final worktree status are recorded after the Phase 9 gate.

## Prochaine étape

Run the complete `map_runtime` and `playable_runtime_host` suites, both analyses,
the Phase A smokes and the macOS build. Then propose DONE for FG-160–FG-165
while leaving FG-125 explicitly TODO.
