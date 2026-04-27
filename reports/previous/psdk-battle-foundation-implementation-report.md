# PSDK Battle Foundation Implementation Report

Date: 2026-04-24

## Scope

Implemented the first safe migration slice for the Pokemon SDK battle rewrite:
a parallel, pure-Dart PSDK battle lane inside `packages/map_battle`, plus a CLI
smoke harness. This deliberately does not remove the legacy Showdown-inspired
engine yet. The first slice proves that PSDK-shaped move data can drive a
deterministic battle path while legacy `BattleSession` continues to compile and
pass its existing tests.

## Prompt Audit

The requested migration is a full battle-engine replacement across `map_core`,
`map_editor`, `map_runtime`, and `map_battle`. Doing all lots as one big-bang
change would make it difficult to verify behavior, would likely break editor
and runtime adapters at the same time, and would violate the repository rule to
keep package responsibilities isolated.

Decision: implement a reviewable first slice that can be tested independently:
PSDK battle domain contracts, a small move behavior registry, deterministic RNG
streams, a singles engine, timeline events, and a CLI fixture.

## Files Created

- `packages/map_battle/bin/psdk_battle_cli.dart`
- `packages/map_battle/lib/src/psdk/psdk_battle.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_engine.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_outcome.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_rng.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_setup.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_slots.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_timeline.dart`
- `packages/map_battle/test/psdk_engine_smoke_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`

## Files Modified

- `packages/map_battle/lib/map_battle.dart`

## Implemented Logic

- `PsdkBattleMoveData` exposes PSDK-facing fields such as `dbSymbol`,
  `battleEngineMethod`, target, power, accuracy, PP, priority, category, and
  status riders.
- Public DTO invariants are runtime validations (`ArgumentError`/`RangeError`),
  not debug-only asserts.
- `accuracy == 0` is accepted as the PSDK bypass-accuracy sentinel.
- PSDK move behavior registry supports `s_basic` and `s_status`.
- Unknown `battleEngineMethod` throws `UnsupportedPsdkBattleMoveBehavior`
  instead of silently falling back.
- `s_basic` uses a small Pokemon-style damage formula with deterministic damage
  rolls and does not invent chip damage for zero-power moves.
- `s_status` supports chance-gated major status application and does not
  overwrite an existing major status.
- Move targets currently supported: `adjacentFoe` and `user`.
- State, setup, combatants, timelines, status lists, and registry maps snapshot
  incoming collections so callers cannot mutate engine behavior externally.
- Initial outcomes are exposed when a setup starts with an already-fainted
  combatant.
- Timeline emits turn start, move declaration, animation cue, damage, status,
  miss, and battle end events.
- CLI exposes a deterministic embedded fixture:
  `dart run bin/psdk_battle_cli.dart --format json`.

## Sub-Agent Verdicts

- Audit/Architecture: recommended a parallel `src/psdk/**` lane in
  `map_battle`, no runtime/editor coupling, and targeted coexistence tests.
- Tests/Build: identified `map_battle` as the correct first pure-Dart boundary
  and recommended targeted tests plus full package tests.
- Implementation: created the initial PSDK lane and CLI.
- Critique pass 1: found blocking issues around ignored `user` targets,
  mutable state exposure, `accuracy == 0`, zero-power damage, and file
  structure. Fixed.
- Critique pass 2: found remaining aliasing risks in statuses, setup moves, and
  registry maps. Fixed.
- Critique pass 3: non-blocking, recommended runtime validations, exact CLI
  determinism, status non-overwrite, and initial-outcome handling. Fixed.
- Final critique: non-blocking. Remaining future decision: explicit double-KO
  outcome when both combatants enter already fainted.

## Verification

All commands were run from `packages/map_battle` unless noted.

```bash
dart test test/psdk_engine_smoke_test.dart
```

Result: exit 0, `+15: All tests passed!`

```bash
dart test test/psdk_battle_cli_test.dart
```

Result: exit 0, `+2: All tests passed!`

```bash
dart analyze
```

Result: exit 0, `No issues found!`

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/map_battle_psdk_battle_cli
```

Result: exit 0, `Generated: /tmp/map_battle_psdk_battle_cli`

```bash
dart run bin/psdk_battle_cli.dart --format json
```

Result: exit 0.

```json
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

```bash
dart run bin/psdk_battle_cli.dart --unknown
```

Result: exit 64, `Unknown argument "--unknown".`

```bash
dart test
```

Result: exit 0, `+223: All tests passed!`

```bash
git diff --check
```

Result: exit 0, no output.

## Limits

- This is a PSDK foundation slice, not the full engine replacement.
- No `map_core` model migration has been performed yet.
- No `map_editor` PSDK Studio importer has been performed yet.
- No `map_runtime` battle handoff has been switched to the new PSDK engine yet.
- Only singles `user` and `adjacentFoe` targets are supported.
- Only `s_basic` and `s_status` behavior methods are implemented.
- PP consumption, switching, items, field conditions, full stat stages, type
  chart, abilities, held items, multi-target battles, and animation integration
  are future lots.

## Next Lot Recommendation

Do not delete Showdown fields in `map_core` as a blind next step. The audit
shows many downstream references in editor/runtime tests and converters. The
next safe lot should first add PSDK Studio-compatible move fields and adapters
with tolerant JSON migration, then migrate editor/runtime references in a
separate reviewable pass.

