# PSDK Battle Lot 19 - No-Effect Moves

## Scope

Ported the smallest PSDK no-effect move family into `packages/map_battle`:

- `s_do_nothing` -> `NoEffectMoveBehavior.doNothing` (`ported`)
- `s_splash` -> `NoEffectMoveBehavior.splash` (`partial`)

This lot deliberately excludes animation/runtime work because the user already
handled animations. It also excludes broader message plumbing: PSDK Splash
displays a localized "nothing happened" text, but the pure Dart battle event
lane has no localized text event contract yet.

## Prompt Audit

The prompt asked to continue multiple lots. The safe interpretation was to take
two low-risk, isolated move families instead of jumping into Absorb, Dream
Eater, recoil or Struggle. Those families require healing events, ability/effect
contracts, or faint-process details that are not fully present in the current
clean battle lane.

## Ruby Source Audited

- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 Splash.rb`

Observed PSDK rules:

- `Splash#deal_effect` only displays `parse_text(18, 106)`.
- `DoNothing#deal_effect` aliases `void_true`.
- Both methods still go through the normal move procedure before their local
  effect body.

## Existing Contracts Audited

- `BattleMoveProcedure` owns target resolution, declaration, accuracy,
  Protect/type precheck and animation cue emission.
- `prepareBattleMove` is the shared helper used by already ported move
  families.
- `BattleTurnRunner` spends PP before behavior resolution, which is correct for
  no-effect moves because they are still successfully used after the shared
  procedure.
- `PsdkBattleTimeline` has no localized text/message event yet.

## Files Changed

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/move/behaviors/no_effect_move_behavior.dart`
  - Added `NoEffectMoveBehavior`.
  - Keeps the shared procedure and returns success without state mutation.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/static_basic_move_registry.dart`
  - Registered `s_do_nothing` and `s_splash`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/tool/extract_psdk_move_registry.dart`
  - Added known behavior metadata for both methods.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
  - Regenerated from PSDK scripts.
- `/Users/karim/Project/pokemonProject/reports/psdk-move-porting-matrix.md`
  - Regenerated counts and rows.
- `/Users/karim/Project/pokemonProject/reports/psdk-effect-porting-matrix.md`
  - Regenerated with the same extraction command used by previous lots.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_move_families/no_effect_and_direct_hp_test.dart`
  - Added no-effect tests and direct-HP tests for Lot 20.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_registry_manifest_test.dart`
  - Added Lot 19/20 manifest assertions.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_battle_cli_test.dart`
  - Added shared `direct_hp` CLI smoke test that also proves Splash emits no
    damage.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
  - Added shared `direct_hp` scenario used by Lot 20 and Splash smoke coverage.

## Code Added

Core new file:

```dart
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _NoEffectMoveKind {
  splash,
  doNothing,
}

/// Ports PSDK moves whose Ruby `deal_effect` intentionally does not mutate
/// battle state.
///
/// The shared move procedure still emits declaration and animation events, and
/// still owns target resolution, accuracy, Protect and immunity. Splash remains
/// marked partial in the matrix because PSDK also displays a localized
/// "nothing happened" message, while this pure battle lane has no text event
/// contract yet.
final class NoEffectMoveBehavior implements BattleMoveBehavior {
  const NoEffectMoveBehavior.splash()
      : battleEngineMethod = 's_splash',
        _kind = _NoEffectMoveKind.splash;

  const NoEffectMoveBehavior.doNothing()
      : battleEngineMethod = 's_do_nothing',
        _kind = _NoEffectMoveKind.doNothing;

  @override
  final String battleEngineMethod;
  final _NoEffectMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    // Both PSDK classes are deliberately state-neutral. The switch keeps the
    // family explicit so future message/event support can specialize Splash
    // without changing the registry contract.
    return switch (_kind) {
      _NoEffectMoveKind.splash ||
      _NoEffectMoveKind.doNothing =>
        prepared.toResolution(successful: true),
    };
  }
}
```

## Tests Added

`no_effect_and_direct_hp_test.dart` covers Lot 19:

- `s_splash` emits `move_pp_spent`, `move_declared`, `animation_cue`.
- `s_splash` does not emit damage and does not mutate either HP value.
- `s_do_nothing` respects the shared miss pipeline.
- `s_do_nothing` misses without animation or damage.

`psdk_battle_cli_test.dart` covers:

- `--scenario direct_hp`, where the slower opponent uses `splash`.
- The scenario proves Splash emits the shared procedure events and no damage.

`psdk_registry_manifest_test.dart` covers:

- `s_do_nothing`: `ported`.
- `s_splash`: `partial`, due missing localized text event.

## Verification Evidence

RED checks before implementation:

- `dart test test/psdk_move_families/no_effect_and_direct_hp_test.dart` failed
  on unsupported `s_splash` and `s_do_nothing`.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 19/20"` failed
  because the manifest still marked the methods as `missing`.
- `dart test test/psdk_battle_cli_test.dart --name "direct HP"` failed because
  the CLI scenario did not exist yet.

GREEN checks after implementation:

- `dart test test/psdk_move_families/no_effect_and_direct_hp_test.dart` -> 6
  tests passed.
- `dart test test/psdk_battle_cli_test.dart --name "direct HP"` -> 2 tests
  passed.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 19/20"` -> 1
  test passed.
- `dart run bin/psdk_battle_cli.dart --scenario direct_hp --format json` ->
  `playerHp=40`, `opponentHp=40`, Endeavor damage `60`, Splash no damage.
- `dart format --set-exit-if-changed ...` -> 13 files checked, 0 changed.
- `dart analyze` -> no issues found.
- `dart test` -> 366 tests passed.
- `dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_check` ->
  generated executable.
- `dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_check`
  -> generated executable.
- `dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_check`
  -> generated executable.
- `git diff --check` -> no whitespace errors.

## Matrix Impact

Before this turn:

- `ported`: 17
- `partial`: 16
- `missing`: 283

After Lot 19 and Lot 20:

- `ported`: 19
- `partial`: 18
- `missing`: 279

Lot 19 row updates:

- `s_do_nothing`: `TODO/missing` -> `NoEffectMoveBehavior.doNothing/ported`
- `s_splash`: `TODO/missing` -> `NoEffectMoveBehavior.splash/partial`

## Sub-Agent Verdicts

- Audit / Architecture: `Copernicus` recommended Lot 19 as the safest next
  slice and identified `s_splash` as partial if the localized message remains
  observable outside the current battle event contract.
- Implementation: local main-agent pass kept the behavior in a single small
  class and reused the shared PSDK procedure.
- Tests: local main-agent pass wrote RED tests first, then verified them green.
- Build / Validation: local main-agent pass ran targeted tests, full tests,
  analyze, compile checks and `git diff --check`.
- Critique finale: `Ptolemy` was launched as an independent read-only review
  but did not return a verdict before timeout and was shut down. Local final
  critique reran targeted behavior tests, `dart analyze`, and `git diff --check`;
  no blocking finding was observed.

## Remaining Limitations

- Splash's localized text message is not emitted as a timeline event.
- No new runtime animation work was done by design.
- Multi-target no-effect variants still depend on the broader target topology
  work; this package currently focuses on the singles PSDK lane.
