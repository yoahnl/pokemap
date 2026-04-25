# PSDK Battle Lot 21 - Recoil Move

## Scope

Ported the base PSDK recoil family into `packages/map_battle`:

- `s_recoil` -> `RecoilMoveBehavior.psdkRecoil` (`partial`)
- `s_struggle` intentionally remains `missing`

The lot only models the normal RecoilMove damage sequence. It does not add
Rock Head, Parental Bond, Reckless, item callbacks, dedicated recoil messages,
or Basculin evolution bookkeeping.

## Prompt Audit

The user asked to continue the next lots. I narrowed this pass to `s_recoil`
only. `s_struggle` shares the Ruby file but changes type behavior and is also
auto-selected by battle AI/scene code in PSDK, so folding it into this lot would
mix move behavior with no-PP fallback behavior.

## Ruby Source Audited

- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 RecoilMove.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/100 Basic.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/100 Move.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/101 Damage_Calc.rb`
- `/Users/karim/Project/pokemonProject/pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`

Observed PSDK rules:

- `RecoilMove < Basic`.
- `recoil?` returns true.
- `recoil_factor` comes from `RECOIL_FACTORS[db_symbol] || 4`.
- Default recoil base is the HP passed by `Basic#deal_damage`.
- `Damage_Calc#damages` clamps that HP to the target current HP before it is
  passed to `damage_change_with_process`.
- `shadow_rush` uses user max HP as recoil base.
- `shadow_end` uses user current HP as recoil base.
- Recoil damage is `floor(base / factor)`, clamped to at least `1`.
- Recoil happens after target damage and before secondary status/stat/effect
  riders.

## Existing Contracts Audited

- `prepareBattleMove` already owns target resolution, PP-independent
  declaration, accuracy, Protect and type immunity.
- `BattleMoveDamageCalculator` returns formula damage that may exceed target HP.
- `applyDirectDamage` clamps actual HP loss and emits `PsdkBattleDamageEvent`.
- `BattleMoveSecondaryEffectResolver` applies status/stat riders after damage.
- Current timeline has no dedicated recoil event, so recoil is represented as a
  damage event where `target == user`.

## Files Changed

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/move/behaviors/recoil_move_behavior.dart`
  - New behavior for `s_recoil`.
  - Computes normal target damage, then self recoil.
  - Preserves PSDK order: target damage -> recoil -> secondary effects.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/static_basic_move_registry.dart`
  - Imports and registers `RecoilMoveBehavior.psdkRecoil`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
  - Adds `--scenario recoil`.
- `/Users/karim/Project/pokemonProject/packages/map_battle/tool/extract_psdk_move_registry.dart`
  - Marks `s_recoil` as partial.
  - Leaves `s_struggle` missing.
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
  - Regenerated.
- `/Users/karim/Project/pokemonProject/reports/psdk-move-porting-matrix.md`
  - Regenerated.
- `/Users/karim/Project/pokemonProject/reports/psdk-effect-porting-matrix.md`
  - Regenerated.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_move_families/recoil_move_behavior_test.dart`
  - New behavior test file.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_registry_manifest_test.dart`
  - Adds Lot 21 registry assertions.
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/psdk_battle_cli_test.dart`
  - Adds CLI smoke assertions.

## Code Added

New behavior:

```dart
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const Map<String, int> _psdkRecoilFactors = <String, int>{
  'brave_bird': 3,
  'double_edge': 3,
  'chloroblast': 2,
  'flare_blitz': 3,
  'head_charge': 4,
  'head_smash': 2,
  'light_of_ruin': 2,
  'shadow_end': 2,
  'shadow_rush': 16,
  'struggle': 4,
  'submission': 4,
  'take_down': 4,
  'volt_tackle': 3,
  'wave_crash': 3,
  'wild_charge': 4,
  'wood_hammer': 3,
};

const Set<String> _recoilFromUserMaxHp = <String>{
  'struggle',
  'shadow_rush',
};

const Set<String> _recoilFromUserCurrentHp = <String>{
  'shadow_end',
};

/// Ports the base PSDK `RecoilMove` family.
///
/// The target hit still uses the normal damage formula and shared move
/// procedure. Recoil is represented as a second damage event targeting the
/// user. This is intentionally partial: abilities such as Rock Head and
/// Parental Bond, item callbacks, dedicated recoil messages and Basculin
/// evolution bookkeeping are not available in the current PSDK lane.
final class RecoilMoveBehavior implements BattleMoveBehavior {
  const RecoilMoveBehavior.psdkRecoil() : battleEngineMethod = 's_recoil';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];
    if (targetDamage.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: damageResult.rng,
        events: events,
      );
    }

    final recoilBase = _recoilBaseDamage(
      dbSymbol: context.move.dbSymbol,
      user: user,
      targetDamage: targetDamage.damage,
    );
    final recoilDamage = _recoilDamage(
      baseDamage: recoilBase,
      factor: _recoilFactor(context.move.dbSymbol),
    );
    final recoil = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      amount: recoilDamage,
    );
    state = recoil.state;
    if (recoil.event != null) {
      events.add(recoil.event!);
    }

    // PSDK Basic applies recoil immediately after target damage and before
    // status/stat/effect riders. Keeping secondary effects after the self-hit
    // preserves that order for animation consumers and tests.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return BattleMoveBehaviorResolution(
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  int _recoilFactor(String dbSymbol) {
    return _psdkRecoilFactors[dbSymbol] ?? 4;
  }

  int _recoilBaseDamage({
    required String dbSymbol,
    required PsdkBattleCombatant user,
    required int targetDamage,
  }) {
    if (_recoilFromUserMaxHp.contains(dbSymbol)) {
      return user.maxHp;
    }
    if (_recoilFromUserCurrentHp.contains(dbSymbol)) {
      return user.currentHp;
    }
    // PSDK `damages` clamps normal move damage to the target's current HP
    // before `recoil(hp, user)` receives it. `applyDirectDamage.damage` is the
    // same clamped amount in this Dart lane.
    return targetDamage;
  }

  int _recoilDamage({
    required int baseDamage,
    required int factor,
  }) {
    final damage = baseDamage ~/ factor;
    return damage < 1 ? 1 : damage;
  }
}
```

## Tests Added

`recoil_move_behavior_test.dart` covers:

- target damage then user recoil order,
- factor table with `take_down` and `double_edge`,
- normal recoil based on clamped target damage,
- minimum recoil of `1`,
- recoil KO of the user,
- no recoil on miss,
- no recoil on type immunity,
- no recoil when Protect blocks the target hit,
- secondary status after recoil.

`psdk_battle_cli_test.dart` covers:

- `--scenario recoil`, asserting player HP `98`, opponent HP `92`, target
  damage `8`, recoil damage `2`.

`psdk_registry_manifest_test.dart` covers:

- `s_recoil`: `partial`.
- `s_struggle`: `missing`.

## Verification Evidence

RED checks before implementation:

- `dart test test/psdk_move_families/recoil_move_behavior_test.dart` failed on
  unsupported `s_recoil`.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 21"` failed
  because `s_recoil` was still `missing`.
- `dart test test/psdk_battle_cli_test.dart --name "recoil scenario"` failed
  because the CLI scenario did not exist yet.

GREEN checks after implementation:

- `dart test test/psdk_move_families/recoil_move_behavior_test.dart` -> 8 tests
  passed.
- `dart test test/psdk_battle_cli_test.dart --name "recoil scenario"` -> 1 test
  passed.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 21"` -> 1 test
  passed.
- `dart run bin/psdk_battle_cli.dart --scenario recoil --format json` ->
  `playerHp=98`, `opponentHp=92`, `take_down` damage `8`, recoil `2`.
- `dart format --set-exit-if-changed ...` -> 8 files checked, 0 changed.
- `dart analyze` -> no issues found.
- `dart test` -> 376 tests passed.
- `dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_check` ->
  generated executable.
- `dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_check`
  -> generated executable.
- `dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_check`
  -> generated executable.
- `git diff --check` -> no whitespace errors.

## Matrix Impact

Before Lot 21:

- `ported`: 19
- `partial`: 18
- `missing`: 279

After Lot 21:

- `ported`: 19
- `partial`: 19
- `missing`: 278

Row updates:

- `s_recoil`: `TODO/missing` -> `RecoilMoveBehavior.psdkRecoil/partial`
- `s_struggle`: remains `TODO/missing`

## Sub-Agent Verdicts

- Audit / Architecture: `Schrodinger` recommended `s_recoil` only, status
  `partial`, with `s_struggle` left missing.
- Implementation: local main-agent pass added one behavior and no new public
  model fields.
- Tests: local main-agent pass wrote RED tests before implementation and kept
  positive, negative and ordering cases covered.
- Build / Validation: local main-agent pass ran targeted tests, full tests,
  analysis, compile checks and `git diff --check`.
- Critique finale: `Wegener` returned OK with no blocking findings. It noted a
  P3 gap for an explicit Protect test; that test was added before final
  validation.

## Remaining Limitations

- `s_recoil` is partial because Rock Head, Parental Bond, Reckless, item hooks,
  dedicated recoil messages and Basculin evolution bookkeeping are absent.
- Recoil currently appears as a regular damage event with `target == user`.
- `s_struggle` is intentionally still missing.
- Double-KO semantics still follow the current battle outcome priority
  (`opponent fainted` before `player fainted`) because draw support is not in
  the current engine contract.
