# FG-165 — Runtime Input Lock Conventions V0

Date: 2026-07-21

Verdict proposé: `DONE`

Roadmap source: Phase 9 of `pokemap_roadmap_mecaniques_fangame.md`

## Résumé exécutif

The runtime now exposes one typed explanation of who owns player input and one
typed seam for external Flutter surfaces to acquire it. A pause menu lock is
enforced inside `PlayableMapGame.handleRuntimeInputEvent`, so keyboard, touch
and directly forwarded gamepad commands share the same guard. Acquiring the
lock clears held directions, preventing movement from resuming unexpectedly
when the menu closes.

The implementation deliberately derives dialogue, battle, cinematic,
transition and blocked contexts from the existing runtime flow. It does not
introduce a competing state machine.

## Scope confirmé

- Included: typed runtime input contexts, typed pause-menu owner, immutable
  authority snapshot, acquire/release seam, held-direction cleanup, public
  export and focused/non-regression coverage.
- Excluded: pause-menu composition (FG-160), option persistence (FG-162), save
  confirmation (FG-163) and fast travel (FG-164).
- Roadmap status was not edited because the request did not explicitly ask to
  mutate the canonical roadmap.

## Audit initial

- `PlayableMapGame.handleRuntimeInputEvent` was already the common runtime seam
  for keyboard and host-forwarded controls.
- `_RuntimeFlowPhase` already represented overworld, dialogue, battle and
  transitions; cinematic and blocking work had dedicated runtime guards.
- The host's gamepad subscription forwarded events directly to the Flame game,
  so Flutter focus alone could not protect the overworld while a menu route was
  open.
- Existing tests in `playable_map_game_input_test.dart` covered routing for
  overworld, dialogue, battle, cinematic and transition states, but no external
  menu owner.
- Initial Git state: clean on `main`, HEAD `a09d399b2`.

Main risks identified:

1. storing a second internal flow state and letting it drift;
2. blocking only keyboard focus while gamepad events still reach Flame;
3. leaving a held direction active after closing a menu;
4. changing existing dialogue/battle routing.

## Fichiers

| File | Zones | Raison et impact |
|---|---|---|
| `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md` | Phase 9 micro-plan; FG-165 checklist | Defines dependency order and executable done criteria. |
| `packages/map_runtime/lib/src/presentation/flame/runtime_input_authority.dart` | New enums and snapshot | Provides the typed, immutable public contract. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | External lock set, `inputAuthoritySnapshot`, `setExternalInputLock`, input seam | Derives ownership from real runtime state and consumes every source while locked. |
| `packages/map_runtime/lib/map_runtime.dart` | Public exports | Makes the contract available to the Flutter host without private imports. |
| `packages/map_runtime/test/runtime_input_authority_test.dart` | New pure contract tests | Covers allowed, externally locked and dialogue contexts. |
| `packages/map_runtime/test/playable_map_game_input_test.dart` | Pause-lock integration test | Proves movement is consumed and resumes only after owner release. |
| `reports/gameplay/fg_165_runtime_input_lock_conventions_v0.md` | This Evidence Pack | Records audit, changes, commands, results and limits. |

## Zones modifiées

### `playable_map_game.dart`

```diff
+final Set<RuntimeExternalInputLock> _externalInputLocks =
+    <RuntimeExternalInputLock>{};
+
+RuntimeInputAuthoritySnapshot get inputAuthoritySnapshot { ... }
+
+void setExternalInputLock(
+  RuntimeExternalInputLock owner, {
+  required bool locked,
+}) { ... }
```

The snapshot switch maps the existing `_flowPhase` and existing cinematic,
activation, narrative-dispatch and scripted-movement guards to the public
context. `debugIsGameplayInputLocked` now delegates to that snapshot.

At the beginning of the existing common input seam:

```diff
+if (_externalInputLocks.isNotEmpty) {
+  if (_isMovementControl(control)) {
+    _releaseMovementControl(control);
+  }
+  return true;
+}
```

This placement is before the `isLoaded` guard on purpose: a host-forwarded
gamepad command is consumed as soon as a Flutter owner has acquired the lock.

### `map_runtime.dart`

The public barrel exports only `RuntimeInputContext`,
`RuntimeExternalInputLock` and `RuntimeInputAuthoritySnapshot`.

### `playable_map_game_input_test.dart`

The added integration case loads a real `PlayableMapGame`, waits for map
activation dispatch, acquires `pauseMenu`, sends a movement press, advances the
game and verifies that the grid position does not change. It then releases the
same owner and verifies the authority becomes available again.

## TDD et validations

### RED

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test \
  test/runtime_input_authority_test.dart \
  test/playable_map_game_input_test.dart
```

Expected failure observed: compilation failed because
`RuntimeInputAuthoritySnapshot`, `RuntimeInputContext`,
`RuntimeExternalInputLock`, `inputAuthoritySnapshot` and
`setExternalInputLock` did not exist.

### GREEN ciblé

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test \
  test/runtime_input_authority_test.dart \
  test/playable_map_game_input_test.dart
```

Exact result: `+39: All tests passed!`

### Suite complète

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test
```

Exact result: `+1913 ~1: All tests passed!`

### Analyse

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter analyze
```

Exact result: `No issues found! (ran in 7.7s)`

### Build réel

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter build macos --debug
```

Exact result:
`✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app`

### Hygiène

```bash
dart format <five touched Dart files>
git diff --check
```

Exact results: `Formatted 5 files (1 changed)`; `git diff --check` emitted no
error.

## Passes séparées obligatoires

The environment instruction prohibited spawning sub-agents for this request,
so the required roles were executed as named independent passes.

| Pass | Verdict |
|---|---|
| Audit / Architecture | PASS — one authority derived from existing state; no second flow machine. |
| Implementation | PASS — external ownership is typed and held movement is cleared. |
| Tests | PASS — RED observed; 39 targeted and 1,913 full tests pass, with one pre-existing skip. |
| Build / Validation | PASS — analyzer and macOS host build pass. |
| Critique finale | PASS — diff remains restricted to input authority; menu behavior itself remains correctly assigned to FG-160. |

## Limites conservées et risques restants

- This lot supplies the lock contract; the host will acquire it when FG-160
  wires the pause route.
- Only `pauseMenu` is a public external owner. New overlays must add a typed
  owner rather than reuse an unrelated boolean.
- Internal context is a snapshot, not a notification stream. The current host
  only needs synchronous ownership checks.
- The full test suite contains one intentional pre-existing skip (`~1`).

## Auto-critique

The lock is intentionally coarse: while the pause owner is present, even
dialogue validation is consumed. That is the safe rule for a modal route and
avoids double activation. If nested runtime overlays become a requirement,
priority between typed owners should be designed explicitly instead of making
this contract silently more permissive.

## Contenu complet des fichiers de code créés

### `runtime_input_authority.dart`

```dart
/// Player-facing contexts understood by the single runtime input seam.
///
/// The context describes where an accepted command is routed. It does not
/// duplicate the runtime flow state: [PlayableMapGame] derives it from the
/// already authoritative dialogue, battle, transition and cinematic state.
enum RuntimeInputContext {
  overworld,
  dialogue,
  battle,
  cinematic,
  transition,
  blocked,
}

/// Locks owned outside Flame but still enforced by the runtime input seam.
///
/// A closed Flutter pause route is the only external owner in Phase 9. Keeping
/// the owner typed prevents an arbitrary boolean from being released by the
/// wrong overlay when more player surfaces are added later.
enum RuntimeExternalInputLock {
  pauseMenu,
}

/// Immutable explanation of which player surface currently owns input.
final class RuntimeInputAuthoritySnapshot {
  const RuntimeInputAuthoritySnapshot({
    required this.context,
    this.externalLocks = const <RuntimeExternalInputLock>{},
  });

  final RuntimeInputContext context;
  final Set<RuntimeExternalInputLock> externalLocks;

  /// External Flutter surfaces consume input before Flame can route it.
  bool get acceptsRuntimeInput => externalLocks.isEmpty;

  /// Overworld movement is legal only when no overlay owns the command.
  bool get acceptsOverworldInput =>
      acceptsRuntimeInput && context == RuntimeInputContext.overworld;

  bool get isGameplayLocked => !acceptsOverworldInput;
}
```

### `runtime_input_authority_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeInputAuthoritySnapshot', () {
    test('overworld accepts runtime and overworld input without external lock',
        () {
      const snapshot = RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld,
      );

      expect(snapshot.acceptsRuntimeInput, isTrue);
      expect(snapshot.acceptsOverworldInput, isTrue);
      expect(snapshot.isGameplayLocked, isFalse);
    });

    test('pause menu lock blocks every runtime input source', () {
      const snapshot = RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld,
        externalLocks: <RuntimeExternalInputLock>{
          RuntimeExternalInputLock.pauseMenu,
        },
      );

      expect(snapshot.acceptsRuntimeInput, isFalse);
      expect(snapshot.acceptsOverworldInput, isFalse);
      expect(snapshot.isGameplayLocked, isTrue);
    });

    test('dialogue accepts routed input but never overworld movement', () {
      const snapshot = RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.dialogue,
      );

      expect(snapshot.acceptsRuntimeInput, isTrue);
      expect(snapshot.acceptsOverworldInput, isFalse);
      expect(snapshot.isGameplayLocked, isTrue);
    });
  });
}
```

## État Git final attendu

After the dedicated lot commit, the worktree must be clean and the commit must
contain only the files inventoried above. The exact commit hash is recorded in
the phase handoff after commit creation.

## Prochaine étape proposée

FG-162 Runtime Options V0: add real dialogue reveal speed and persist typed
player preferences before exposing the Options surface from FG-160.
