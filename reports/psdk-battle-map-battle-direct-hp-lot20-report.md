# PSDK Battle Lot 20 - Direct HP Moves

## Scope

Ported the next isolated direct-HP PSDK moves into `packages/map_battle`:

- `s_endeavor` -> `DirectHpMoveBehavior.endeavor` (`ported`)
- `s_final_gambit` -> `DirectHpMoveBehavior.finalGambit` (`partial`)

This lot adds a small behavior-level user-prevention seam because PSDK
`Endeavor#move_usable_by_user` fails before PP spending, declaration and
animation when the user HP is greater than or equal to every target HP.

## Prompt Audit

The user allowed multiple lots in one pass. I kept the second lot to direct HP
moves only. I did not include recoil, Absorb, Dream Eater, Struggle or healing
because those need richer event contracts, ability/effect hooks or
faint-process behavior that would broaden the change beyond this verified
slice.

## Ruby Source Audited

- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 Endeavor.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 FinalGambit.rb`
- PSDK procedure ordering around `move_usable_by_user`.

Observed PSDK rules:

- `Endeavor` fails in `move_usable_by_user` if user HP is not lower than target
  HP.
- `Endeavor#deal_damage` returns true without normal formula damage.
- `Endeavor#deal_effect` applies `target.hp - user.hp` when target HP is higher.
- `FinalGambit#deal_effect` captures `user.hp`, damages the user by that amount,
  then damages each actual target by the captured amount.

## Existing Contracts Audited

- `BattleTurnRunner` already has a pre-PP `BattleMoveProcedureHooks.preventUser`
  seam for external effects.
- Before this lot, move-specific user prevention was only possible inside
  behavior resolution, which happens after PP spending.
- `BattleMoveRegistry` can resolve a behavior before PP without mutating state.
- `applyDirectDamage` already emits direct `PsdkBattleDamageEvent` without using
  the normal formula.

## Files Changed

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/move/behaviors/direct_hp_move_behavior.dart`
  - Added `DirectHpMoveBehavior`.
  - Implements direct HP damage for Endeavor and Final Gambit.
  - Implements behavior-level pre-PP user prevention for Endeavor.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
  - Added `BattleMoveUserPreventionBehavior`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
  - Added registry-level `preventUser`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/application/battle_turn_runner.dart`
  - Calls behavior-level prevention after external hooks and before PP spending.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`
  - Exports the new prevention behavior interface.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/static_basic_move_registry.dart`
  - Registered `s_endeavor` and `s_final_gambit`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
  - Added `direct_hp` scenario with Endeavor plus Splash.
- `/Users/karim/Project/pokemonProject/packages/map_battle/tool/extract_psdk_move_registry.dart`
  - Added known behavior metadata.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_move_families/no_effect_and_direct_hp_test.dart`
  - Added Lot 20 behavior tests.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_battle_cli_test.dart`
  - Added CLI smoke assertions.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_registry_manifest_test.dart`
  - Added manifest assertions.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
  - Regenerated.
- `/Users/karim/Project/pokemonProject/reports/psdk-move-porting-matrix.md`
  - Regenerated.
- `/Users/karim/Project/pokemonProject/reports/psdk-effect-porting-matrix.md`
  - Regenerated.

## Code Added

Core new file:

```dart
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _DirectHpMoveKind {
  endeavor,
  finalGambit,
}

/// Ports PSDK moves that assign HP loss directly instead of using the normal
/// damage formula.
///
/// This behavior deliberately reuses the shared procedure before HP changes so
/// accuracy, Protect and type-immunity stay aligned with other PSDK move
/// families. It does not attempt to model text messages or later faint-process
/// callbacks, which is why Final Gambit remains partial in the matrix.
final class DirectHpMoveBehavior implements BattleMoveUserPreventionBehavior {
  const DirectHpMoveBehavior.endeavor()
      : battleEngineMethod = 's_endeavor',
        _kind = _DirectHpMoveKind.endeavor;

  const DirectHpMoveBehavior.finalGambit()
      : battleEngineMethod = 's_final_gambit',
        _kind = _DirectHpMoveKind.finalGambit;

  @override
  final String battleEngineMethod;
  final _DirectHpMoveKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    if (_kind != _DirectHpMoveKind.endeavor) {
      return null;
    }

    final userHp = context.state.battlerAt(context.user).currentHp;
    final targetHp = context.state.battlerAt(context.target).currentHp;
    if (userHp < targetHp) {
      return null;
    }

    // Ruby PSDK implements this in `move_usable_by_user`, before PP spending
    // and before the usage animation. Exposing it through the behavior-level
    // prevention seam keeps that timing exact for the clean engine runner.
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _DirectHpMoveKind.endeavor => _resolveEndeavor(
          context: context,
          prepared: prepared,
        ),
      _DirectHpMoveKind.finalGambit => _resolveFinalGambit(
          context: context,
          prepared: prepared,
        ),
    };
  }

  BattleMoveBehaviorResolution _resolveEndeavor({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final target = prepared.psdkTargets.single;
    final userHp = prepared.state.battlerAt(context.user).currentHp;
    final targetHp = prepared.state.battlerAt(target).currentHp;
    final amount = targetHp - userHp;
    if (amount <= 0) {
      return prepared.toResolution();
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: target,
      moveId: context.move.id,
      amount: amount,
    );

    return BattleMoveBehaviorResolution(
      state: applied.state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveFinalGambit({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final hpDealt = prepared.state.battlerAt(context.user).currentHp;
    var nextState = prepared.state;
    final events = <PsdkBattleEvent>[...prepared.events];

    // PSDK first removes the user's current HP, then applies that captured
    // amount to every actual target. Keeping the original amount protects the
    // move from accidentally dealing zero after the self-KO mutation.
    final selfDamage = applyDirectDamage(
      state: nextState,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      amount: hpDealt,
    );
    nextState = selfDamage.state;
    if (selfDamage.event != null) {
      events.add(selfDamage.event!);
    }

    for (final target in prepared.psdkTargets) {
      final targetDamage = applyDirectDamage(
        state: nextState,
        user: context.user,
        target: target,
        moveId: context.move.id,
        amount: hpDealt,
      );
      nextState = targetDamage.state;
      if (targetDamage.event != null) {
        events.add(targetDamage.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: prepared.rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: prevention.reason.jsonName,
        ),
      ],
      successful: false,
    );
  }
}
```

## Tests Added

`no_effect_and_direct_hp_test.dart` covers Lot 20:

- `s_endeavor` lowers target HP to user current HP.
- `s_endeavor` failure happens before PP and declaration when user HP is too
  high.
- `s_final_gambit` damages the user first, then damages the target by the
  captured HP amount.
- `s_final_gambit` respects the shared immunity precheck before self-damage.

`psdk_battle_cli_test.dart` covers:

- `--scenario direct_hp`, asserting player HP `40`, opponent HP `40`, Endeavor
  damage `60`, and Splash no damage.

`psdk_registry_manifest_test.dart` covers:

- `s_endeavor`: `ported`.
- `s_final_gambit`: `partial`, because richer faint-process callbacks and
  double-KO semantics are not fully represented yet.

## CLI Scenario

Added:

```bash
dart run bin/psdk_battle_cli.dart --scenario direct_hp --format json
```

Observed smoke result:

- `outcome`: `ongoing`
- `turns`: `1`
- `playerHp`: `40`
- `opponentHp`: `40`
- `endeavor` damage: `60`
- `splash`: declaration and animation, no damage

## Verification Evidence

RED checks before implementation:

- `dart test test/psdk_move_families/no_effect_and_direct_hp_test.dart` failed
  on unsupported `s_endeavor` and `s_final_gambit`.
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
  deterministic expected output.
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

Lot 20 row updates:

- `s_endeavor`: `TODO/missing` -> `DirectHpMoveBehavior.endeavor/ported`
- `s_final_gambit`: `TODO/missing` -> `DirectHpMoveBehavior.finalGambit/partial`

Combined Lot 19/20 counts:

- `ported`: 19
- `partial`: 18
- `missing`: 279

## Sub-Agent Verdicts

- Audit / Architecture: `Copernicus` recommended Endeavor and Final Gambit as
  the next low-risk direct-HP family, with Final Gambit kept partial.
- Implementation: local main-agent pass added a behavior-level prevention seam
  instead of accepting the previous after-PP timing mismatch for Endeavor.
- Tests: local main-agent pass wrote RED tests first and kept both positive and
  negative behavior covered.
- Build / Validation: local main-agent pass ran targeted tests, full tests,
  analyze, compile checks and `git diff --check`.
- Critique finale: `Ptolemy` was launched as an independent read-only review
  but did not return a verdict before timeout and was shut down. Local final
  critique reran targeted behavior tests, `dart analyze`, and `git diff --check`;
  no blocking finding was observed.

## Remaining Limitations

- Final Gambit's direct HP transfer is implemented, but PSDK's richer
  faint-process callbacks and double-KO ordering still need a fuller battle
  procedure model.
- Direct HP tests currently exercise the singles PSDK lane. Multi-target
  behavior remains future topology work.
- No localized text/message event was added.
