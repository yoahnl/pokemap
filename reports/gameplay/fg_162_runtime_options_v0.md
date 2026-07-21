# FG-162 — Runtime Options V0

Date: 2026-07-21

Verdict proposé: `DONE`

## Résumé exécutif

The runtime now consumes a real player-selected dialogue cadence and the host
persists typed player preferences separately from gameplay saves. Slow, normal
and fast reveal Unicode runes over time; instant preserves the historical
engine default. Pressing validate while a line is incomplete reveals it fully
without advancing the session. A second press advances normally.

Touch-control visibility is stored in the same local options object. Global
volume remains deliberately absent because the current engine has no global
audio authority; exposing a slider would lie to the player.

## Audit et scope

- The Flame dialogue overlay previously rendered the complete line immediately.
- The host preference file stored only project path and map ID.
- Cinematic commands expose command-level volume, not a global runtime mixer.
- Player presentation preferences belong to the host preference file, while
  party/story/position remain in the versioned gameplay save.
- Initial Git state was clean after FG-165 at `ef4a449b`.

Included: cadence contract, Unicode reveal, validate-to-complete, active-overlay
updates, typed JSON codec, local persistence and touch preference application.

Excluded: Options screen composition (FG-160), audio mixer work, key rebinding
and gameplay-state mutation.

## Inventaire des changements

| File | Change and impact |
|---|---|
| `packages/map_runtime/lib/src/presentation/flame/dialogue_text_speed.dart` | New cadence and safe storage parser. |
| `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart` | Rune reveal state, timed update, completion-first advance and live speed update. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Stores host preference, applies it to current/future overlays. |
| `packages/map_runtime/lib/map_runtime.dart` | Public speed export. |
| `packages/map_runtime/test/dialogue_text_speed_test.dart` | Cadence, fallback and ordering coverage. |
| `packages/map_runtime/test/dialogue_runtime_outcome_test.dart` | Unicode partial reveal and two-step validation non-regression. |
| `examples/playable_runtime_host/lib/src/runtime_player_options.dart` | Typed immutable host preferences and JSON codec. |
| `examples/playable_runtime_host/lib/main.dart` | Restore/persist/apply options; persists touch toggle. |
| `examples/playable_runtime_host/test/runtime_player_options_test.dart` | Round-trip, malformed input and copy coverage. |
| `docs/superpowers/plans/2026-07-21-phase-9-runtime-menus-ux.md` | Marks FG-162 executable steps complete. |
| `reports/gameplay/fg_162_runtime_options_v0.md` | This Evidence Pack. |

## Zones précises modifiées

`DialogueOverlayComponent` now owns `_visibleRuneCount` and an elapsed-time
accumulator. `update(dt)` converts elapsed time into reveal units. `advance()`
first calls `_revealCurrentLineFully()` when required; it calls the existing
`DialogueSession.advance()` only once the current line is complete.

`PlayableMapGame.setDialogueTextSpeed` updates both the stored setting and the
active overlay, and `_openDialogue` passes it to every new overlay.

The host restores `playerOptions` even when no previous project can be reopened,
persists it next to legacy session keys, applies dialogue speed to each new game
and keeps the touch toggle synchronized with `showTouchControls`.

## TDD et résultats exacts

RED runtime:

```bash
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/dialogue_text_speed_test.dart test/dialogue_runtime_outcome_test.dart
```

Observed: compilation failed because the speed type, overlay parameter and
reveal getters did not exist.

RED host:

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/runtime_player_options_test.dart
```

Observed: compilation failed because `runtime_player_options.dart` and
`RuntimePlayerOptions` did not exist.

GREEN runtime:

```bash
/opt/homebrew/bin/flutter test test/dialogue_text_speed_test.dart test/dialogue_runtime_outcome_test.dart
```

Exact result: `+7: All tests passed!`

GREEN host:

```bash
/opt/homebrew/bin/flutter test test/runtime_player_options_test.dart
```

Exact result: `+3: All tests passed!`

Analyses:

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze
cd examples/playable_runtime_host && /opt/homebrew/bin/flutter analyze
```

Exact results: `No issues found! (ran in 3.8s)` and
`No issues found! (ran in 3.6s)`.

Build:

```bash
cd examples/playable_runtime_host
/opt/homebrew/bin/flutter build macos --debug
```

Exact result:
`✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app`

The exhaustive package suites are deliberately deferred to the Phase 9 final
gate. FG-165 had already freshly proved all 1,913 runtime tests immediately
before this lot; the changed behavior is covered by the focused tests above.

## Passes séparées

| Pass | Verdict |
|---|---|
| Audit / Architecture | PASS — preferences stay outside gameplay saves and cadence is consumed by Flame. |
| Implementation | PASS — no host-only fake option; Unicode reveal uses runes. |
| Tests | PASS — RED observed; 7 runtime and 3 host tests pass. |
| Build / Validation | PASS — both analyzers and macOS build pass. |
| Critique finale | PASS — volume is intentionally not exposed without a real mixer. |

## Risques, limites et auto-critique

- Reveal cadence uses fixed intervals and has no punctuation pause. This is a
  clear V0 behavior, not a localization-aware typography engine.
- `RuntimePlayerOptions` storage is best-effort like the existing host session
  preferences. Disk errors cannot block the game.
- The Options UI will be added in FG-160; until then, the existing touch button
  is the only interactive writer and dialogue speed uses the restored/default
  value.
- No global volume control is claimed.

## Contenu complet des fichiers créés

### `dialogue_text_speed.dart`

```dart
/// Player-selectable reveal cadence for runtime dialogue lines.
///
/// `instant` preserves the historical runtime behaviour and remains useful for
/// tests and accessibility. Timed modes are consumed by the Flame overlay;
/// they are not cosmetic host-only preferences.
enum RuntimeDialogueTextSpeed {
  slow,
  normal,
  fast,
  instant;

  Duration? get revealInterval => switch (this) {
        RuntimeDialogueTextSpeed.slow => const Duration(milliseconds: 45),
        RuntimeDialogueTextSpeed.normal => const Duration(milliseconds: 30),
        RuntimeDialogueTextSpeed.fast => const Duration(milliseconds: 15),
        RuntimeDialogueTextSpeed.instant => null,
      };

  static RuntimeDialogueTextSpeed fromStorage(
    Object? value, {
    RuntimeDialogueTextSpeed fallback = RuntimeDialogueTextSpeed.instant,
  }) {
    if (value is! String) {
      return fallback;
    }
    for (final speed in RuntimeDialogueTextSpeed.values) {
      if (speed.name == value.trim()) {
        return speed;
      }
    }
    return fallback;
  }
}
```

### `runtime_player_options.dart`

```dart
import 'package:map_runtime/map_runtime.dart';

/// Local player presentation preferences owned by the standalone runtime host.
///
/// These values are deliberately separate from gameplay saves: moving a save
/// between devices must not overwrite accessibility or device-control choices.
final class RuntimePlayerOptions {
  const RuntimePlayerOptions({
    this.dialogueTextSpeed = RuntimeDialogueTextSpeed.normal,
    this.showTouchControls = true,
  });

  final RuntimeDialogueTextSpeed dialogueTextSpeed;
  final bool showTouchControls;

  factory RuntimePlayerOptions.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const RuntimePlayerOptions();
    }
    final rawTouchControls = json['showTouchControls'];
    return RuntimePlayerOptions(
      dialogueTextSpeed: RuntimeDialogueTextSpeed.fromStorage(
        json['dialogueTextSpeed'],
        fallback: RuntimeDialogueTextSpeed.normal,
      ),
      showTouchControls: rawTouchControls is bool ? rawTouchControls : true,
    );
  }

  RuntimePlayerOptions copyWith({
    RuntimeDialogueTextSpeed? dialogueTextSpeed,
    bool? showTouchControls,
  }) {
    return RuntimePlayerOptions(
      dialogueTextSpeed: dialogueTextSpeed ?? this.dialogueTextSpeed,
      showTouchControls: showTouchControls ?? this.showTouchControls,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dialogueTextSpeed': dialogueTextSpeed.name,
        'showTouchControls': showTouchControls,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimePlayerOptions &&
          dialogueTextSpeed == other.dialogueTextSpeed &&
          showTouchControls == other.showTouchControls;

  @override
  int get hashCode => Object.hash(dialogueTextSpeed, showTouchControls);
}
```

### `dialogue_text_speed_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeDialogueTextSpeed', () {
    test('keeps an explicit instant mode for backwards-compatible rendering',
        () {
      expect(RuntimeDialogueTextSpeed.instant.revealInterval, isNull);
      expect(RuntimeDialogueTextSpeed.fromStorage('instant'),
          RuntimeDialogueTextSpeed.instant);
    });

    test('normalizes invalid persisted values to the requested fallback', () {
      expect(
        RuntimeDialogueTextSpeed.fromStorage(
          'warp-speed',
          fallback: RuntimeDialogueTextSpeed.normal,
        ),
        RuntimeDialogueTextSpeed.normal,
      );
    });

    test('orders real reveal intervals from slowest to fastest', () {
      expect(
        RuntimeDialogueTextSpeed.slow.revealInterval!,
        greaterThan(RuntimeDialogueTextSpeed.normal.revealInterval!),
      );
      expect(
        RuntimeDialogueTextSpeed.normal.revealInterval!,
        greaterThan(RuntimeDialogueTextSpeed.fast.revealInterval!),
      );
    });
  });
}
```

### `runtime_player_options_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_player_options.dart';

void main() {
  group('RuntimePlayerOptions', () {
    test('round-trips supported persisted player preferences', () {
      final options = RuntimePlayerOptions.fromJson(
        const <String, dynamic>{
          'dialogueTextSpeed': 'fast',
          'showTouchControls': false,
        },
      );

      expect(options.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
      expect(options.showTouchControls, isFalse);
      expect(
        options.toJson(),
        const <String, dynamic>{
          'dialogueTextSpeed': 'fast',
          'showTouchControls': false,
        },
      );
    });

    test('falls back safely for legacy or malformed preferences', () {
      expect(
        RuntimePlayerOptions.fromJson(null),
        const RuntimePlayerOptions(),
      );
      expect(
        RuntimePlayerOptions.fromJson(
          const <String, dynamic>{
            'dialogueTextSpeed': 'impossible',
            'showTouchControls': 'yes',
          },
        ),
        const RuntimePlayerOptions(),
      );
    });

    test('copyWith changes one option without corrupting the other', () {
      const initial = RuntimePlayerOptions(
        dialogueTextSpeed: RuntimeDialogueTextSpeed.slow,
        showTouchControls: false,
      );

      expect(
        initial.copyWith(dialogueTextSpeed: RuntimeDialogueTextSpeed.fast),
        const RuntimePlayerOptions(
          dialogueTextSpeed: RuntimeDialogueTextSpeed.fast,
          showTouchControls: false,
        ),
      );
    });
  });
}
```

## État Git final attendu

The dedicated commit must contain only the files inventoried above. Final
worktree cleanliness and commit hash are recorded in the Phase 9 handoff.

## Prochaine étape

FG-160 exposes these real options in the complete pause menu and connects the
FG-165 lock to the route lifecycle.
