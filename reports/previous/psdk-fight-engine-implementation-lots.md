# PSDK Fight Engine Implementation Lots

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the remaining Showdown-shaped combat path with a pure Dart,
clean-architecture battle engine aligned with Pokemon SDK `scripts/5 Battle`.

**Architecture:** `packages/map_battle` owns the battle simulation and emits a
pure Dart timeline. `packages/map_runtime` consumes that timeline for visuals
and battle handoff, without owning battle rules. `packages/map_editor` and
`packages/map_core` own import/catalog data, but never execute battle logic.

**Tech Stack:** Dart, package:test, Flutter tests for runtime/editor bridges,
Freezed/JSON generation where map_core/editor/runtime models change, Pokemon
SDK Ruby scripts as the read-only source of truth.

---

Date: 2026-04-25

Source report:

- `reports/psdk-fight-engine-parity-master-report.md`

Reference PSDK folders:

- `pokemonsdk-development/scripts/5 Battle/03 PokemonBattler`
- `pokemonsdk-development/scripts/5 Battle/04 Logic`
- `pokemonsdk-development/scripts/5 Battle/05 Actions`
- `pokemonsdk-development/scripts/5 Battle/06 Effects`
- `pokemonsdk-development/scripts/5 Battle/10 Move`
- `pokemonsdk-development/scripts/5 Battle/30 AI`

Scope note:

- Animations are considered already handled by the user. These lots focus on
  combat semantics, event/timeline output, data bridges, and runtime handoff.
- Do not port PSDK `01 Scene`, `02 Visual`, or `20 MoveAnimation` into
  `map_battle`. `map_battle` stays pure Dart.
- Do not rewrite unrelated reports, fixtures, maps, editor UI, or generated
  files outside the package currently touched by a lot.

Execution rules:

- One lot should be implementable independently and leave the repo green.
- Prefer one commit per lot, or one commit per sub-lot when a lot touches
  multiple packages.
- Every lot starts with a failing or protective test.
- Every lot ends with at least:
  - `cd packages/map_battle && dart analyze`
  - `cd packages/map_battle && dart test`
- If `packages/map_core` changes, also run:
  - `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`
  - `cd packages/map_core && dart analyze`
  - `cd packages/map_core && dart test`
- If `packages/map_runtime` changes, also run:
  - `cd packages/map_runtime && flutter analyze`
  - `cd packages/map_runtime && flutter test`
- If `packages/map_editor` changes, also run:
  - `cd packages/map_editor && flutter analyze`
  - `cd packages/map_editor && flutter test`

Current baseline from audit:

- PSDK moves: 20 `ported`, 24 `partial`, 286 `missing`, 330 total.
- PSDK effects: 0 `ported`, 1 `partial`, 481 `missing`, 482 total.
- `packages/map_battle`: `dart analyze` green, `dart test` green with 410
  tests.

## Lot Map

| Lot | Name | Main package | Purpose |
| --- | --- | --- | --- |
| FIGHT-00 | Audit Gates And Matrices | `map_battle` | Make parity measurable and impossible to fake. |
| FIGHT-01 | Remove Active Showdown Combat Path | `map_core`, `map_editor`, `map_runtime` | Make PSDK the only active move/combat source. |
| FIGHT-02 | PSDK Battler Parity State | `map_battle` | Give combatants the state PSDK moves depend on. |
| FIGHT-03 | Effect Kernel | `map_battle` | Replace id-only effects with hookable PSDK effects. |
| FIGHT-04 | Handler Layer | `map_battle` | Centralize damage/status/stat/weather/item mutations. |
| FIGHT-05 | PSDK Action Queue | `map_battle` | Model Fight/Switch/Item/Flee/Mega/Shift ordering. |
| FIGHT-06 | Targeting And Topology | `map_battle` | Support PSDK target taxonomy and doubles-ready slots. |
| FIGHT-07 | Field Weather Terrain | `map_battle` | Port weather/terrain state, duration and hooks. |
| FIGHT-08 | Status Lifecycle | `map_battle` | Port burn/poison/toxic/paralysis/sleep/freeze effects. |
| FIGHT-09 | Ability Effects | `map_battle`, `map_runtime` | Port ability hooks needed by move parity. |
| FIGHT-10 | Item Effects | `map_battle`, `map_runtime` | Port held-item hooks needed by action/damage/status parity. |
| FIGHT-11 | Full PSDK Move Procedure | `map_battle` | Align Dart procedure with `10 Move/120 Procedure.rb`. |
| FIGHT-12 | Move Family Porting Waves | `map_battle` | Move the matrix from partial coverage to full coverage. |
| FIGHT-13 | PSDK AI | `map_battle` | Replace fixed opponent choice with PSDK-style AI policy. |
| FIGHT-14 | Runtime Bridge | `map_runtime` | Feed runtime from PSDK state/timeline only. |
| FIGHT-15 | Parity Harness And Legacy Removal | all combat packages | CLI scenarios, generated parity gates, legacy cleanup. |

## Shared Code Conventions

Use these conventions in every lot:

- New combat-domain code lives under `packages/map_battle/lib/src/domain`.
- PSDK DTOs already under `packages/map_battle/lib/src/psdk/domain` can remain
  public migration contracts, but non-DTO battle rules should move into
  `domain/*`.
- Timeline events must remain serializable and Flutter-free.
- Runtime adapters convert project/editor data into PSDK battle DTOs. They do
  not execute battle rules.
- Names should prefer PSDK vocabulary where the concept comes from Ruby PSDK:
  `battleEngineMethod`, `fieldTerrain`, `grounded`, `effects`, `handlers`,
  `moveHistory`, `damageHistory`, `statHistory`.

Recommended import shape for new `map_battle` files:

```dart
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';
```

Recommended event mutation shape:

```dart
final result = handler.apply(context);
context.applyStateAndRng(
  nextState: result.state,
  nextRng: result.rng,
);
timeline.addAll(result.events);
```

Recommended unit-test shape:

```dart
test('describes one PSDK rule in one sentence', () {
  final engine = BattleEngine(setup: setupForThisRule());

  final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

  expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
  expect(result.timeline.events.map((event) => event.kind), contains('damage'));
});
```

## FIGHT-00 - Audit Gates And Matrices

### Objective

Make the current parity state measurable. After this lot, every new move or
effect port must update the generated matrix, and the tests must fail if a
registered PSDK method silently disappears or gets mislabeled.

### Why

Right now the engine foundation is healthy, but the project can still
accidentally claim support for a move without implementing its dependencies.
Pokemon SDK move classes are small because effects, handlers and histories do
the hard work. This lot makes those dependencies explicit.

### Files

Modify:

- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/tool/extract_psdk_effect_matrix.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `reports/psdk-move-porting-matrix.md`
- `reports/psdk-effect-porting-matrix.md`

Create:

- `reports/psdk-fight-engine-parity-status.md`
- `packages/map_battle/test/psdk_effect_matrix_test.dart`

### Logic

Add dependency tags to every move registry row:

- `effects`
- `handler_damage`
- `handler_status`
- `handler_stat`
- `handler_item`
- `handler_switch`
- `handler_weather`
- `handler_terrain`
- `end_turn`
- `field`
- `weather`
- `terrain`
- `targeting_multi`
- `ability`
- `item`
- `history`
- `grounded`
- `faint_process`
- `runtime_bridge`

Add hook-family tags to every effect row:

- `move_prevention`
- `damage_prevention`
- `damage_change`
- `post_damage`
- `status_prevention`
- `stat_change`
- `weather_change`
- `terrain_change`
- `switch`
- `end_turn`
- `action_order`
- `item_change`
- `ability_change`

### Code To Put In Place

In `packages/map_battle/tool/extract_psdk_move_registry.dart`, add the
dependency enum and render it in both markdown and Dart manifest:

```dart
enum _PsdkMoveDependency {
  effects('effects'),
  handlerDamage('handler_damage'),
  handlerStatus('handler_status'),
  handlerStat('handler_stat'),
  handlerItem('handler_item'),
  handlerSwitch('handler_switch'),
  handlerWeather('handler_weather'),
  handlerTerrain('handler_terrain'),
  endTurn('end_turn'),
  field('field'),
  weather('weather'),
  terrain('terrain'),
  targetingMulti('targeting_multi'),
  ability('ability'),
  item('item'),
  history('history'),
  grounded('grounded'),
  faintProcess('faint_process'),
  runtimeBridge('runtime_bridge');

  const _PsdkMoveDependency(this.token);

  final String token;
}

const _manualDependencies = <String, Set<_PsdkMoveDependency>>{
  's_weather': {
    _PsdkMoveDependency.handlerWeather,
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
  },
  's_terrain': {
    _PsdkMoveDependency.handlerTerrain,
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.item,
  },
  's_weather_ball': {
    _PsdkMoveDependency.weather,
    _PsdkMoveDependency.ability,
  },
  's_rising_voltage': {
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
  },
  's_expanding_force': {
    _PsdkMoveDependency.terrain,
    _PsdkMoveDependency.grounded,
    _PsdkMoveDependency.targetingMulti,
  },
  's_multi_hit': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
  },
  's_recoil': {
    _PsdkMoveDependency.handlerDamage,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.item,
    _PsdkMoveDependency.history,
  },
  's_explosion': {
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.faintProcess,
  },
  's_false_swipe': {
    _PsdkMoveDependency.effects,
  },
  's_low_kick': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
    _PsdkMoveDependency.grounded,
  },
  's_heavy_slam': {
    _PsdkMoveDependency.effects,
    _PsdkMoveDependency.ability,
  },
};

Set<_PsdkMoveDependency> _dependenciesFor(String method) {
  return _manualDependencies[method] ?? const <_PsdkMoveDependency>{};
}
```

In the generated manifest model, expose dependencies with a public enum:

```dart
enum PsdkMoveDependency {
  effects,
  handlerDamage,
  handlerStatus,
  handlerStat,
  handlerItem,
  handlerSwitch,
  handlerWeather,
  handlerTerrain,
  endTurn,
  field,
  weather,
  terrain,
  targetingMulti,
  ability,
  item,
  history,
  grounded,
  faintProcess,
  runtimeBridge,
}

class PsdkMoveRegistryManifestEntry {
  const PsdkMoveRegistryManifestEntry({
    required this.battleEngineMethod,
    required this.rubyClass,
    required this.rubyPath,
    required this.dartBehavior,
    required this.status,
    this.dependencies = const <PsdkMoveDependency>[],
  });

  final String battleEngineMethod;
  final String rubyClass;
  final String rubyPath;
  final String dartBehavior;
  final PsdkPortStatus status;
  final List<PsdkMoveDependency> dependencies;
}
```

Add a test to `packages/map_battle/test/psdk_registry_manifest_test.dart`:

```dart
test('records dependencies that block partial move promotion', () {
  final byMethod = {
    for (final entry in psdkMoveRegistryManifest)
      entry.battleEngineMethod: entry,
  };

  expect(
    byMethod['s_weather']!.dependencies,
    containsAll(<PsdkMoveDependency>[
      PsdkMoveDependency.handlerWeather,
      PsdkMoveDependency.weather,
      PsdkMoveDependency.effects,
    ]),
  );
  expect(
    byMethod['s_expanding_force']!.dependencies,
    containsAll(<PsdkMoveDependency>[
      PsdkMoveDependency.terrain,
      PsdkMoveDependency.grounded,
      PsdkMoveDependency.targetingMulti,
    ]),
  );
  expect(byMethod['s_basic']!.status, PsdkPortStatus.partial);
});
```

Create `packages/map_battle/test/psdk_effect_matrix_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('effect matrix keeps Protect honest until the effect kernel exists', () {
    final matrix = File('../../reports/psdk-effect-porting-matrix.md');

    expect(matrix.existsSync(), isTrue);
    final content = matrix.readAsStringSync();

    expect(content, contains('`Protect`'));
    expect(content, contains('`partial`'));
    expect(content, contains('full effect object not ported yet'));
  });
}
```

Create `reports/psdk-fight-engine-parity-status.md` with the current counts:

```markdown
# PSDK Fight Engine Parity Status

Date: 2026-04-25

| Axis | Current |
| --- | ---: |
| PSDK move methods | 330 |
| Move methods ported | 20 |
| Move methods partial | 24 |
| Move methods missing | 286 |
| PSDK effect classes | 482 |
| Effect classes ported | 0 |
| Effect classes partial | 1 |
| Effect classes missing | 481 |
```

### How To Implement

- Add dependency fields first.
- Regenerate the manifest with:

```bash
cd packages/map_battle
dart run tool/extract_psdk_move_registry.dart \
  ../../pokemonsdk-development/scripts/5\ Battle \
  ../../reports/psdk-move-porting-matrix.md \
  --manifest lib/src/data/generated/psdk_move_registry_manifest.dart
dart run tool/extract_psdk_effect_matrix.dart \
  ../../pokemonsdk-development/scripts/5\ Battle \
  ../../reports/psdk-effect-porting-matrix.md
```

- Run the registry tests before widening scope.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_registry_manifest_test.dart
dart test test/psdk_effect_matrix_test.dart
dart analyze
dart test
```

### Exit Criteria

- Manifest exposes dependencies.
- Matrix reports dependencies in markdown.
- Tests prove at least `s_weather`, `s_expanding_force`, `s_multi_hit`, and
  `s_recoil` are classified with their blockers.
- The status report exists and can be updated after every future lot.

## FIGHT-01 - Remove Active Showdown Combat Path

### Objective

Make Pokemon SDK Studio and PSDK battle metadata the only active source for the
combat pipeline. Showdown may remain readable only as a legacy import adapter if
the project still needs old catalog migration, but runtime combat must no
longer branch on Showdown ids, callbacks or unsupported reasons.

### Why

The current battle work is undermined if `map_runtime` or `map_editor` still
uses Showdown metadata to decide whether a move is executable or which visual
id to use. This lot prevents future PSDK behavior from being mixed with a
different rule model.

### Files

Modify:

- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_core/lib/src/models/pokemon_move.freezed.dart`
- `packages/map_core/lib/src/models/pokemon_move.g.dart`
- `packages/map_core/test/pokemon_move_test.dart`
- `packages/map_editor/lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/battle_move_visual_resolver_test.dart`

Delete or quarantine under a clearly named legacy path:

- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`
- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`

### Logic

- `PokemonMoveSourceRefs` keeps only PSDK source refs for the active combat
  path.
- `source == 'pokemon_sdk_studio'` becomes the expected source for battle-ready
  moves.
- `runtime_battle_move_bridge.dart` maps project moves to `PsdkBattleMoveData`
  from `battleEngineMethod`, `battleEngineAimedTarget`, `studioFlags`,
  `battleStageMods`, and `moveStatuses`.
- `battle_move_visual_resolver.dart` resolves by PSDK animation id, PSDK db
  symbol, then local move id. It never falls back to `showdownMoveId`.
- Editor UI labels say PSDK Studio, not Showdown.

### Code To Put In Place

In `packages/map_core/lib/src/models/pokemon_move.dart`, replace the source
refs with a PSDK-only active shape:

```dart
@freezed
class PokemonMoveSourceRefs with _$PokemonMoveSourceRefs {
  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveSourceRefs({
    String? psdkStudioMoveId,
    String? psdkDbSymbol,
    String? psdkBattleEngineMethod,
    String? psdkScriptClass,
    String? psdkScriptPath,
    String? psdkAnimationId,
    @Default(<String>[]) List<String> psdkDependencies,
  }) = _PokemonMoveSourceRefs;

  factory PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveSourceRefsFromJson(_migrateLegacySourceRefs(json));

  const PokemonMoveSourceRefs._();

  PokemonMoveSourceRefs normalized() {
    String? normalizeOptional(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }

    final dependencies = <String>[];
    final seen = <String>{};
    for (final dependency in psdkDependencies) {
      final trimmed = dependency.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      dependencies.add(trimmed);
    }

    return copyWith(
      psdkStudioMoveId: normalizeOptional(psdkStudioMoveId),
      psdkDbSymbol: normalizeOptional(psdkDbSymbol),
      psdkBattleEngineMethod: normalizeOptional(psdkBattleEngineMethod),
      psdkScriptClass: normalizeOptional(psdkScriptClass),
      psdkScriptPath: normalizeOptional(psdkScriptPath),
      psdkAnimationId: normalizeOptional(psdkAnimationId),
      psdkDependencies: dependencies,
    );
  }
}

Map<String, dynamic> _migrateLegacySourceRefs(Map<String, dynamic> json) {
  final migrated = Map<String, dynamic>.from(json);
  migrated.remove('showdownMoveId');
  migrated.remove('showdownHooksPresent');
  return migrated;
}
```

In `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`,
use a single resolver helper:

```dart
String battleVisualMoveKey(PokemonMove move) {
  final animationId = move.sourceRefs.psdkAnimationId?.trim();
  if (animationId != null && animationId.isNotEmpty) {
    return animationId;
  }

  final sourceDbSymbol = move.sourceRefs.psdkDbSymbol?.trim();
  if (sourceDbSymbol != null && sourceDbSymbol.isNotEmpty) {
    return sourceDbSymbol;
  }

  final dbSymbol = move.dbSymbol.trim();
  if (dbSymbol.isNotEmpty) {
    return dbSymbol;
  }

  return move.id;
}
```

In `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`,
replace Showdown unsupported-reason logic with an explicit PSDK support check:

```dart
bool isMoveSupportedByPsdkBattle(PokemonMove move) {
  return move.battleEngineMethod.trim().isNotEmpty &&
      move.engineSupportLevel != PokemonMoveEngineSupportLevel.catalogOnly;
}

PsdkBattleMoveData toPsdkBattleMoveData(PokemonMove move) {
  if (!isMoveSupportedByPsdkBattle(move)) {
    throw StateError(
      'Move "${move.id}" is not wired to the PSDK battle engine.',
    );
  }

  return PsdkBattleMoveData(
    id: move.id,
    dbSymbol: move.dbSymbol.isEmpty ? move.id : move.dbSymbol,
    name: move.name,
    type: move.type,
    category: _toPsdkMoveCategory(move.category),
    power: move.power,
    accuracy: move.accuracy.percentOrBypass,
    pp: move.pp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: _toPsdkMoveTarget(move.battleEngineAimedTarget),
    protectable: move.studioFlags.blocable,
    statuses: move.moveStatuses.map(_toPsdkStatus).toList(growable: false),
    stageMods: move.battleStageMods.map(_toPsdkStageMod).toList(growable: false),
  );
}
```

Add a guard test to `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`:

```dart
test('runtime battle bridge does not use Showdown callback reasons', () {
  final move = _psdkMove(
    id: 'acrobatics',
    battleEngineMethod: 's_basic',
    unsupportedReasons: const <String>['showdown_callback:basePowerCallback'],
  );

  expect(() => toPsdkBattleMoveData(move), returnsNormally);
});
```

### How To Implement

- First change `map_core` model and regenerate Freezed/JSON.
- Then update editor converters and seeds to write PSDK refs.
- Then update runtime bridge and visual resolver.
- Keep legacy adapters only if tests prove old project JSON still loads. If
  they stay, move them behind names containing `LegacyShowdown` and make sure
  no runtime battle path imports them.

### Validation

```bash
rg -n "showdown|Showdown|showdownMoveId|showdownHooksPresent|fetchShowdown|Sync depuis Showdown" \
  packages/map_core packages/map_editor packages/map_runtime
```

Acceptable hits after this lot:

- Historical reports.
- Tests explicitly named `legacy`.
- Comments explaining tolerant migration of old JSON.

Run:

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart analyze
dart test

cd ../map_runtime
flutter analyze
flutter test

cd ../map_editor
flutter analyze
flutter test
```

### Exit Criteria

- Runtime combat no longer uses Showdown ids, callbacks or unsupported reasons.
- Editor primary sync path says PSDK Studio.
- Existing old project files still load through tolerant migration or an
  explicit legacy adapter.

## FIGHT-02 - PSDK Battler Parity State

### Objective

Expand `PsdkBattleCombatant` so it can represent the battle state expected by
Pokemon SDK `PokemonBattler`.

### Why

Many attacks are blocked because the target/user lacks the state that Ruby PSDK
consults: ability, item, grounded state inputs, histories, sleep turns,
consumed item, type3/temp types, transform and battle-turn flags.

### Files

Modify:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_setup.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/test/psdk_battler_state_test.dart`

Create:

- `packages/map_battle/lib/src/domain/battler/battle_combatant_history.dart`
- `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`
- `packages/map_battle/lib/src/domain/battler/battle_transform_state.dart`
- `packages/map_battle/test/psdk_battler_parity_test.dart`

### Logic

Add to setup and runtime combatant:

- `abilityId`
- `heldItemId`
- `consumedItemId`
- `itemConsumed`
- `sleepTurns`
- `battleTurnCount`
- `lastBattleTurn`
- `lastSentTurn`
- `lastHitByMoveId`
- `koCount`
- `switching`
- `hasJustShifted`
- `type3`
- `temporaryTypes`
- `damageHistory`
- `statHistory`
- richer successful move history with targets
- transform/illusion placeholders

Do not implement ability or item behavior yet. This lot stores state only.

### Code To Put In Place

Create `packages/map_battle/lib/src/domain/battler/battle_combatant_history.dart`:

```dart
import '../../psdk/domain/psdk_battle_slots.dart';

final class PsdkBattleDamageHistoryEntry {
  const PsdkBattleDamageHistoryEntry({
    required this.turn,
    required this.source,
    required this.moveId,
    required this.damage,
    required this.remainingHp,
  });

  final int turn;
  final PsdkBattleSlotRef source;
  final String moveId;
  final int damage;
  final int remainingHp;
}

final class PsdkBattleDamageHistory {
  const PsdkBattleDamageHistory({
    this.entries = const <PsdkBattleDamageHistoryEntry>[],
  });

  final List<PsdkBattleDamageHistoryEntry> entries;

  PsdkBattleDamageHistory record(PsdkBattleDamageHistoryEntry entry) {
    return PsdkBattleDamageHistory(
      entries: <PsdkBattleDamageHistoryEntry>[...entries, entry],
    );
  }
}

final class PsdkBattleStatHistoryEntry {
  const PsdkBattleStatHistoryEntry({
    required this.turn,
    required this.stat,
    required this.delta,
    required this.currentStage,
  });

  final int turn;
  final String stat;
  final int delta;
  final int currentStage;
}

final class PsdkBattleStatHistory {
  const PsdkBattleStatHistory({
    this.entries = const <PsdkBattleStatHistoryEntry>[],
  });

  final List<PsdkBattleStatHistoryEntry> entries;

  PsdkBattleStatHistory record(PsdkBattleStatHistoryEntry entry) {
    return PsdkBattleStatHistory(
      entries: <PsdkBattleStatHistoryEntry>[...entries, entry],
    );
  }
}
```

Create `packages/map_battle/lib/src/domain/battler/battle_transform_state.dart`:

```dart
final class PsdkBattleTransformState {
  const PsdkBattleTransformState({
    this.transformedFromSpeciesId,
    this.illusionSpeciesId,
    this.illusionDisplayName,
  });

  final String? transformedFromSpeciesId;
  final String? illusionSpeciesId;
  final String? illusionDisplayName;

  bool get isTransformed => transformedFromSpeciesId != null;
  bool get hasIllusion => illusionSpeciesId != null;
}
```

Extend `PsdkBattleCombatantSetup` and `PsdkBattleCombatant`:

```dart
class PsdkBattleCombatantSetup {
  PsdkBattleCombatantSetup({
    required this.id,
    required this.speciesId,
    required this.displayName,
    required this.level,
    required this.maxHp,
    required this.currentHp,
    required this.types,
    required this.stats,
    required List<PsdkBattleMoveData> moves,
    this.abilityId,
    this.heldItemId,
    this.consumedItemId,
    this.itemConsumed = false,
    this.sleepTurns = 0,
    this.battleTurnCount = 0,
    this.lastBattleTurn,
    this.lastSentTurn,
    this.lastHitByMoveId,
    this.koCount = 0,
    this.switching = false,
    this.hasJustShifted = false,
    this.type3,
    List<String> temporaryTypes = const <String>[],
    this.transformState = const PsdkBattleTransformState(),
    this.majorStatus,
    this.statStages,
    this.moveHistory,
    this.damageHistory = const PsdkBattleDamageHistory(),
    this.statHistory = const PsdkBattleStatHistory(),
    double baseWeightKg = 1,
    double? currentWeightKg,
    PsdkBattleEffectStack? effects,
  })  : temporaryTypes = List<String>.unmodifiable(temporaryTypes),
        baseWeightKg = _requirePositiveWeight(baseWeightKg, 'baseWeightKg'),
        currentWeightKg = _requirePositiveWeight(
          currentWeightKg ?? baseWeightKg,
          'currentWeightKg',
        ),
        effects = effects ?? const PsdkBattleEffectStack.empty(),
        _moves = List<PsdkBattleMoveData>.unmodifiable(moves);

  final String? abilityId;
  final String? heldItemId;
  final String? consumedItemId;
  final bool itemConsumed;
  final int sleepTurns;
  final int battleTurnCount;
  final int? lastBattleTurn;
  final int? lastSentTurn;
  final String? lastHitByMoveId;
  final int koCount;
  final bool switching;
  final bool hasJustShifted;
  final String? type3;
  final List<String> temporaryTypes;
  final PsdkBattleTransformState transformState;
  final PsdkBattleDamageHistory damageHistory;
  final PsdkBattleStatHistory statHistory;
}
```

Add copy helpers on `PsdkBattleCombatant`:

```dart
PsdkBattleCombatant recordDamage({
  required int turn,
  required PsdkBattleSlotRef source,
  required String moveId,
  required int damage,
  required int remainingHp,
}) {
  return copyWith(
    lastHitByMoveId: moveId,
    damageHistory: damageHistory.record(
      PsdkBattleDamageHistoryEntry(
        turn: turn,
        source: source,
        moveId: moveId,
        damage: damage,
        remainingHp: remainingHp,
      ),
    ),
  );
}

PsdkBattleCombatant recordStatChange({
  required int turn,
  required String stat,
  required int delta,
  required int currentStage,
}) {
  return copyWith(
    statHistory: statHistory.record(
      PsdkBattleStatHistoryEntry(
        turn: turn,
        stat: stat,
        delta: delta,
        currentStage: currentStage,
      ),
    ),
  );
}
```

Create `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`:

```dart
import '../../psdk/domain/psdk_battle_combatant.dart';

final class BattleGroundingResolver {
  const BattleGroundingResolver();

  bool isGrounded(PsdkBattleCombatant battler) {
    if (battler.effects.contains('gravity')) {
      return true;
    }
    if (battler.effects.contains('ingrain')) {
      return true;
    }
    if (battler.effects.contains('smack_down')) {
      return true;
    }
    if (battler.heldItemId == 'iron_ball') {
      return true;
    }
    if (battler.heldItemId == 'air_balloon' && !battler.itemConsumed) {
      return false;
    }
    if (battler.abilityId == 'levitate') {
      return false;
    }
    return battler.types.primary != 'flying' &&
        battler.types.secondary != 'flying' &&
        battler.type3 != 'flying' &&
        !battler.temporaryTypes.contains('flying');
  }
}
```

Add tests:

```dart
test('PSDK battler carries ability item and histories without mutation leaks', () {
  final battler = PsdkBattleCombatant.fromSetup(
    _psdkCombatant(
      abilityId: 'levitate',
      heldItemId: 'air_balloon',
    ),
  );

  final damaged = battler.recordDamage(
    turn: 1,
    source: psdkOpponentSlot,
    moveId: 'tackle',
    damage: 12,
    remainingHp: 28,
  );

  expect(damaged.abilityId, 'levitate');
  expect(damaged.heldItemId, 'air_balloon');
  expect(damaged.lastHitByMoveId, 'tackle');
  expect(damaged.damageHistory.entries.single.damage, 12);
  expect(() => damaged.temporaryTypes.clear(), throwsUnsupportedError);
});

test('grounding resolver follows PSDK priority for gravity and air balloon', () {
  const resolver = BattleGroundingResolver();
  final airborne = PsdkBattleCombatant.fromSetup(
    _psdkCombatant(
      abilityId: 'levitate',
      heldItemId: 'air_balloon',
      types: const PsdkBattleTypes(primary: 'electric'),
    ),
  );

  expect(resolver.isGrounded(airborne), isFalse);
  expect(
    resolver.isGrounded(
      airborne.copyWith(effects: airborne.effects.add('gravity')),
    ),
    isTrue,
  );
});
```

### How To Implement

- Add pure state classes first.
- Add fields to setup and combatant constructors.
- Update `fromSetup` and `copyWith`.
- Export the new classes from `packages/map_battle/lib/map_battle.dart`.
- Do not add ability/item behavior yet. That comes in FIGHT-09 and FIGHT-10.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_battler_state_test.dart
dart test test/psdk_battler_parity_test.dart
dart analyze
dart test
```

### Exit Criteria

- PSDK combatants can carry ability, item, histories, grounded inputs and
  transform placeholders.
- Existing tests remain green.
- No runtime/editor imports are introduced into `map_battle`.

## FIGHT-03 - Effect Kernel

### Objective

Replace the id-only `PsdkBattleEffectStack` with a real effect system capable
of PSDK-style hooks.

### Why

PSDK attacks rely on effects for prevention, damage modification, status gates,
weather/terrain behavior, item/ability callbacks and end-turn ticks. Without
this kernel, many move families remain permanently partial.

### Files

Create:

- `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_scope.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_registry.dart`
- `packages/map_battle/lib/src/domain/effect/move/protect_effect.dart`
- `packages/map_battle/test/psdk_effect_kernel_test.dart`

Modify:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`
- `packages/map_battle/lib/map_battle.dart`

### Logic

The kernel needs:

- effect identity;
- scope: battler, bank/side, field, weather, terrain;
- owner;
- optional remaining turn counter;
- hook methods with pass-through defaults;
- add/replace/delete/get/update behavior like PSDK `EffectsHandler`;
- serialization-friendly ids for timeline/debug.

### Code To Put In Place

Create `battle_effect_scope.dart`:

```dart
import '../../psdk/domain/psdk_battle_slots.dart';

sealed class BattleEffectScope {
  const BattleEffectScope();
}

final class BattlerEffectScope extends BattleEffectScope {
  const BattlerEffectScope(this.slot);

  final PsdkBattleSlotRef slot;
}

final class BankEffectScope extends BattleEffectScope {
  const BankEffectScope(this.bank);

  final int bank;
}

final class FieldEffectScope extends BattleEffectScope {
  const FieldEffectScope();
}

final class WeatherEffectScope extends BattleEffectScope {
  const WeatherEffectScope();
}

final class TerrainEffectScope extends BattleEffectScope {
  const TerrainEffectScope();
}
```

Create `battle_effect_hooks.dart`:

```dart
import '../../psdk/domain/psdk_battle_state.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_prevention.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';
import 'battle_effect_scope.dart';

final class BattleEffectHookContext {
  const BattleEffectHookContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.scope,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final BattleEffectScope scope;
}

final class BattleEffectMoveContext {
  const BattleEffectMoveContext({
    required this.base,
    required this.user,
    required this.target,
    required this.move,
  });

  final BattleEffectHookContext base;
  final BattlePositionRef user;
  final BattlePositionRef target;
  final BattleMoveDefinition move;
}

final class BattleEffectResult {
  const BattleEffectResult({
    required this.state,
    required this.rng,
    this.events = const <BattleTimelineEvent>[],
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<BattleTimelineEvent> events;
}

final class BattleEffectPreventionResult {
  const BattleEffectPreventionResult({
    required this.reason,
    this.events = const <BattleTimelineEvent>[],
  });

  final BattleMoveFailureReason reason;
  final List<BattleTimelineEvent> events;
}
```

Create `battle_effect.dart`:

```dart
import '../move/battle_move_prevention.dart';
import 'battle_effect_hooks.dart';
import 'battle_effect_scope.dart';

abstract class BattleEffect {
  const BattleEffect({
    required this.id,
    required this.scope,
    this.remainingTurns,
  });

  final String id;
  final BattleEffectScope scope;
  final int? remainingTurns;

  bool get isTurnScoped => remainingTurns == 0;

  BattleEffect? tickEndTurn() {
    final turns = remainingTurns;
    if (turns == null) {
      return this;
    }
    if (turns <= 1) {
      return null;
    }
    return copyWithRemainingTurns(turns - 1);
  }

  BattleEffect copyWithRemainingTurns(int remainingTurns);

  BattleMoveFailureReason? onMovePreventionUser(
    BattleEffectMoveContext context,
  ) {
    return null;
  }

  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    return null;
  }

  BattleEffectResult? onEndTurn(BattleEffectHookContext context) {
    return null;
  }
}
```

Create `battle_effect_stack.dart`:

```dart
import 'battle_effect.dart';

final class BattleEffectStack {
  BattleEffectStack({
    Iterable<BattleEffect> effects = const <BattleEffect>[],
  }) : _effects = List<BattleEffect>.unmodifiable(effects);

  const BattleEffectStack.empty() : _effects = const <BattleEffect>[];

  final List<BattleEffect> _effects;

  List<BattleEffect> get effects => List<BattleEffect>.unmodifiable(_effects);

  bool contains(String id) => _effects.any((effect) => effect.id == id);

  BattleEffect? firstById(String id) {
    for (final effect in _effects) {
      if (effect.id == id) {
        return effect;
      }
    }
    return null;
  }

  BattleEffectStack addOrReplace(BattleEffect effect) {
    final next = <BattleEffect>[
      for (final current in _effects)
        if (current.id != effect.id) current,
      effect,
    ];
    return BattleEffectStack(effects: next);
  }

  BattleEffectStack remove(String id) {
    return BattleEffectStack(
      effects: _effects.where((effect) => effect.id != id),
    );
  }

  BattleEffectStack clearTurnScopedEffects() {
    return BattleEffectStack(
      effects: _effects.where((effect) => !effect.isTurnScoped),
    );
  }
}
```

Create `protect_effect.dart`:

```dart
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class ProtectEffect extends BattleEffect {
  const ProtectEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'protect',
          scope: scope,
          remainingTurns: 0,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ProtectEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!context.move.flags.protectable) {
      return null;
    }
    if (context.user == context.target) {
      return null;
    }
    return BattleMoveFailureReason.protected;
  }
}
```

### How To Implement

- Introduce the new effect stack while keeping compatibility helpers:
  `contains(String id)` and `clearTurnScopedEffects()`.
- Port current Protect behavior from inline string check into `ProtectEffect`.
- Make current tests pass before adding more hooks.
- Do not port 481 effects in this lot. This lot only builds the kernel and
  proves it with Protect.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_protect_effect_test.dart
dart test test/psdk_effect_kernel_test.dart
dart analyze
dart test
```

### Exit Criteria

- Protect is a real effect object, not only an id.
- Existing Protect behavior is unchanged.
- Effect stack can store battler/field scoped effects.
- Effect matrix can promote `Protect` from `partial id bridge` to `partial
  effect object` or `ported` depending on exact hook coverage.

## FIGHT-04 - Handler Layer

### Objective

Introduce PSDK-style handlers for every state mutation category. Moves must
call handlers instead of mutating HP, statuses, stats, weather, terrain, items
or switches directly.

### Why

Pokemon SDK centralizes battle changes through handlers:

- `DamageHandler`
- `StatusChangeHandler`
- `StatChangeHandler`
- `ItemChangeHandler`
- `SwitchHandler`
- `WeatherChangeHandler`
- `FTerrainChangeHandler`
- `EndTurnHandler`

That is where effects, abilities and items intercept behavior. Direct mutation
inside a Dart move makes parity impossible.

### Files

Create:

- `packages/map_battle/lib/src/domain/handler/battle_handler_context.dart`
- `packages/map_battle/lib/src/domain/handler/battle_handler_result.dart`
- `packages/map_battle/lib/src/domain/handler/battle_damage_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_heal_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_stat_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_item_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_weather_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_terrain_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_ability_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_battle_end_handler.dart`
- `packages/map_battle/test/psdk_handlers_test.dart`

Modify:

- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_secondary_effect_resolver.dart`
- all files under `packages/map_battle/lib/src/domain/move/behaviors/`
- `packages/map_battle/lib/map_battle.dart`

### Logic

Handlers return:

- next state;
- next RNG;
- timeline events;
- whether the change was applied;
- exact failure/prevention reason when blocked.

Moves call:

- `BattleDamageHandler.applyDamage`
- `BattleHealHandler.heal`
- `BattleStatusChangeHandler.applyStatus`
- `BattleStatChangeHandler.applyStatChange`
- `BattleWeatherChangeHandler.changeWeather`
- `BattleTerrainChangeHandler.changeTerrain`

### Code To Put In Place

Create `battle_handler_context.dart`:

```dart
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../rng/battle_rng_streams.dart';

final class BattleHandlerContext {
  const BattleHandlerContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef user;
}
```

Create `battle_handler_result.dart`:

```dart
import '../../psdk/domain/psdk_battle_state.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';

final class BattleHandlerResult {
  const BattleHandlerResult({
    required this.state,
    required this.rng,
    this.events = const <BattleTimelineEvent>[],
    this.applied = true,
    this.reason,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<BattleTimelineEvent> events;
  final bool applied;
  final String? reason;
}
```

Create `battle_damage_handler.dart`:

```dart
import '../../psdk/domain/psdk_battle_slots.dart';
import '../timeline/battle_timeline_event.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleDamageHandler {
  const BattleDamageHandler();

  BattleHandlerResult applyDamage({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
    required int rawDamage,
  }) {
    final targetBattler = context.state.battlerAt(target);
    final damage = rawDamage.clamp(0, targetBattler.currentHp).toInt();
    if (damage <= 0) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'zero_damage',
      );
    }

    final nextTarget = targetBattler
        .copyWith(currentHp: targetBattler.currentHp - damage)
        .recordDamage(
          turn: context.turn,
          source: context.user,
          moveId: moveId,
          damage: damage,
          remainingHp: targetBattler.currentHp - damage,
        );

    return BattleHandlerResult(
      state: context.state.replaceBattler(target, nextTarget),
      rng: context.rng,
      events: <BattleTimelineEvent>[
        BattleDamageTimelineEvent(
          turn: context.turn,
          user: BattlePositionRef(
            bank: context.user.bank,
            position: context.user.position,
          ),
          target: BattlePositionRef(bank: target.bank, position: target.position),
          moveId: moveId,
          damage: damage,
          remainingHp: nextTarget.currentHp,
        ),
      ],
    );
  }
}
```

Create `battle_status_change_handler.dart`:

```dart
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../timeline/battle_timeline_event.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleStatusChangeHandler {
  const BattleStatusChangeHandler();

  BattleHandlerResult applyMajorStatus({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String moveId,
    required PsdkBattleMajorStatus status,
  }) {
    final targetBattler = context.state.battlerAt(target);
    if (targetBattler.majorStatus != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'already_statused',
      );
    }

    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (battler) => battler.copyWith(majorStatus: status),
      ),
      rng: context.rng,
      events: <BattleTimelineEvent>[
        BattleStatusChangeTimelineEvent(
          turn: context.turn,
          user: BattlePositionRef(
            bank: context.user.bank,
            position: context.user.position,
          ),
          target: BattlePositionRef(bank: target.bank, position: target.position),
          moveId: moveId,
          status: status,
        ),
      ],
    );
  }
}
```

Update `applyDirectDamage` in `battle_move_behavior_support.dart` to call the
damage handler instead of writing HP directly.

### How To Implement

- Add handler context/result.
- Migrate one behavior family at a time.
- Keep behavior tests unchanged where possible; they should prove no regression.
- Once all behaviors call handlers, forbid direct `copyWith(currentHp: ...)` in
  behavior files with an `rg` check.

### Validation

```bash
cd packages/map_battle
rg -n "copyWith\\(.*currentHp|majorStatus:|statStages:" lib/src/domain/move/behaviors
dart test test/psdk_handlers_test.dart
dart test test/psdk_move_families
dart analyze
dart test
```

### Exit Criteria

- Move behaviors do not directly mutate HP/status/stat state.
- Damage, status and stat histories are recorded by handlers.
- Existing move-family tests remain green.

## FIGHT-05 - PSDK Action Queue

### Objective

Replace the temporary singles-only action sorting inside
`BattleTurnRunner` with a PSDK-style action queue.

### Why

PSDK action order is not just priority and speed. It includes action type,
items, abilities, pre-attack actions, Pursuit, Trick Room, Quick Claw, Custap,
Quick Draw, Stall, Lagging Tail, Full Incense and speed-tie RNG.

### Files

Create:

- `packages/map_battle/lib/src/domain/action/battle_action.dart`
- `packages/map_battle/lib/src/domain/action/battle_action_queue.dart`
- `packages/map_battle/lib/src/domain/action/battle_action_ordering.dart`
- `packages/map_battle/lib/src/domain/action/battle_action_decision_mapper.dart`
- `packages/map_battle/test/psdk_action_queue_test.dart`

Modify:

- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/domain/decision/battle_decision.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`
- `packages/map_battle/lib/map_battle.dart`

### Logic

Actions to model:

- `fight`
- `switch`
- `item`
- `flee`
- `mega`
- `shift`
- `preAttack`
- `noAction`
- `highPriorityItem`

Ordering inputs:

- action priority bucket;
- move priority;
- Pursuit-on-switch;
- high priority item;
- Quick Claw;
- Custap Berry;
- Quick Draw;
- Stall;
- Full Incense;
- Lagging Tail;
- Mycelium Might;
- Trick Room;
- speed tie RNG.

### Code To Put In Place

Create `battle_action.dart`:

```dart
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';

enum BattleActionKind {
  fight,
  switchPokemon,
  item,
  flee,
  mega,
  shift,
  preAttack,
  noAction,
  highPriorityItem,
}

sealed class BattleAction {
  const BattleAction({
    required this.kind,
    required this.user,
  });

  final BattleActionKind kind;
  final PsdkBattleSlotRef user;
}

final class BattleFightAction extends BattleAction {
  const BattleFightAction({
    required PsdkBattleSlotRef user,
    required this.target,
    required this.moveSlot,
    required this.move,
    required this.speed,
  }) : super(kind: BattleActionKind.fight, user: user);

  final PsdkBattleSlotRef target;
  final int moveSlot;
  final PsdkBattleMoveData move;
  final int speed;
}

final class BattleSwitchAction extends BattleAction {
  const BattleSwitchAction({
    required PsdkBattleSlotRef user,
    required this.partyIndex,
  }) : super(kind: BattleActionKind.switchPokemon, user: user);

  final int partyIndex;
}

final class BattleNoAction extends BattleAction {
  const BattleNoAction({required PsdkBattleSlotRef user})
      : super(kind: BattleActionKind.noAction, user: user);
}
```

Create `battle_action_ordering.dart`:

```dart
import '../rng/battle_rng_streams.dart';
import 'battle_action.dart';

final class BattleActionOrdering {
  const BattleActionOrdering();

  List<BattleAction> order({
    required List<BattleAction> actions,
    required bool trickRoom,
    required BattleRngStreams rng,
  }) {
    final indexed = <({int index, BattleAction action})>[
      for (var i = 0; i < actions.length; i += 1) (index: i, action: actions[i]),
    ];

    indexed.sort((left, right) {
      final bucket = _bucket(right.action).compareTo(_bucket(left.action));
      if (bucket != 0) {
        return bucket;
      }

      final movePriority = _movePriority(right.action)
          .compareTo(_movePriority(left.action));
      if (movePriority != 0) {
        return movePriority;
      }

      final speed = trickRoom
          ? _speed(left.action).compareTo(_speed(right.action))
          : _speed(right.action).compareTo(_speed(left.action));
      if (speed != 0) {
        return speed;
      }

      return left.index.compareTo(right.index);
    });

    return indexed.map((entry) => entry.action).toList(growable: false);
  }

  int _bucket(BattleAction action) {
    return switch (action.kind) {
      BattleActionKind.highPriorityItem => 80,
      BattleActionKind.switchPokemon => 70,
      BattleActionKind.mega => 60,
      BattleActionKind.fight => 50,
      BattleActionKind.item => 40,
      BattleActionKind.flee => 30,
      BattleActionKind.shift => 20,
      BattleActionKind.preAttack => 10,
      BattleActionKind.noAction => 0,
    };
  }

  int _movePriority(BattleAction action) {
    return switch (action) {
      BattleFightAction(:final move) => move.priority,
      _ => 0,
    };
  }

  int _speed(BattleAction action) {
    return switch (action) {
      BattleFightAction(:final speed) => speed,
      _ => 0,
    };
  }
}
```

Extend decisions:

```dart
sealed class BattleDecision {
  const BattleDecision();

  const factory BattleDecision.fight({
    required int moveSlot,
    PsdkBattleSlotRef? target,
  }) = BattleFightDecision;

  const factory BattleDecision.switchPokemon({
    required int partyIndex,
  }) = BattleSwitchDecision;
}

final class BattleSwitchDecision extends BattleDecision {
  const BattleSwitchDecision({required this.partyIndex});

  final int partyIndex;
}
```

### How To Implement

- Add the action model and tests independent from `BattleTurnRunner`.
- Replace `_BattleResolvedAction` with `BattleAction`.
- Keep opponent AI as fixed first-move until FIGHT-13.
- Add items/abilities as no-op ordering hooks first, then wire real effects in
  FIGHT-09 and FIGHT-10.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_action_queue_test.dart
dart test test/psdk_protect_effect_test.dart
dart analyze
dart test
```

### Exit Criteria

- `BattleTurnRunner` delegates ordering to `BattleActionQueue` or
  `BattleActionOrdering`.
- Fight and switch actions can coexist.
- Existing fight-only behavior remains unchanged.

## FIGHT-06 - Targeting And Topology

### Objective

Support Pokemon SDK target taxonomy and prepare the engine for doubles/multi-bank
battles.

### Why

Moves such as `s_expanding_force`, spread attacks, ally-target moves,
side-target moves, field-target moves and random-target moves cannot be correct
with only `adjacentFoe` and `user`.

### Files

Modify:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_slots.dart`
- `packages/map_battle/lib/src/domain/battle/battle_topology.dart`
- `packages/map_battle/lib/src/domain/move/battle_target_resolver.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/test/psdk_targeting_test.dart`
- `packages/map_battle/test/psdk_battle_topology_test.dart`

Create:

- `packages/map_battle/test/psdk_multi_target_test.dart`

### Logic

Add targets:

- `adjacentAlly`
- `adjacentAllyOrSelf`
- `adjacentFoe`
- `allAdjacent`
- `allAdjacentFoes`
- `allBattlers`
- `allFoes`
- `allAllies`
- `anyFoe`
- `bank`
- `randomFoe`
- `self`
- `user`
- `userSide`
- `foeSide`
- `none`

Resolution rules:

- A target list can contain zero, one or many battlers.
- Side/field moves can have no battler target and still execute.
- Random targeting uses the targeting RNG stream.
- Fainted targets are filtered unless the PSDK move family explicitly allows
  them.

### Code To Put In Place

Update `PsdkBattleMoveTarget`:

```dart
enum PsdkBattleMoveTarget {
  adjacentAlly,
  adjacentAllyOrSelf,
  adjacentFoe,
  allAdjacent,
  allAdjacentFoes,
  allBattlers,
  allFoes,
  allAllies,
  anyFoe,
  bank,
  randomFoe,
  self,
  user,
  userSide,
  foeSide,
  none,
}
```

Add topology helpers:

```dart
extension PsdkBattleTopologySlots on PsdkBattleState {
  List<PsdkBattleSlotRef> aliveSlots() {
    return combatants.entries
        .where((entry) => !entry.value.isFainted)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  List<PsdkBattleSlotRef> foesOf(PsdkBattleSlotRef user) {
    return aliveSlots()
        .where((slot) => slot.bank != user.bank)
        .toList(growable: false);
  }

  List<PsdkBattleSlotRef> alliesOf(PsdkBattleSlotRef user) {
    return aliveSlots()
        .where((slot) => slot.bank == user.bank && slot != user)
        .toList(growable: false);
  }
}
```

Update target resolver:

```dart
List<BattlePositionRef> resolve(BattleMoveProcedureExecution execution) {
  final state = execution.context.state;
  final user = execution.context.user;
  final psdkUser = PsdkBattleSlotRef(bank: user.bank, position: user.position);

  final targets = switch (execution.move.target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => <PsdkBattleSlotRef>[
        psdkUser,
      ],
    PsdkBattleMoveTarget.adjacentFoe => <PsdkBattleSlotRef>[
        execution.requestedTarget == null
            ? psdkSinglesFoeOf(psdkUser)
            : PsdkBattleSlotRef(
                bank: execution.requestedTarget!.bank,
                position: execution.requestedTarget!.position,
              ),
      ],
    PsdkBattleMoveTarget.allFoes ||
    PsdkBattleMoveTarget.allAdjacentFoes =>
      state.foesOf(psdkUser),
    PsdkBattleMoveTarget.allAllies => state.alliesOf(psdkUser),
    PsdkBattleMoveTarget.allBattlers => state.aliveSlots(),
    PsdkBattleMoveTarget.none ||
    PsdkBattleMoveTarget.userSide ||
    PsdkBattleMoveTarget.foeSide ||
    PsdkBattleMoveTarget.bank => const <PsdkBattleSlotRef>[],
    _ => throw UnsupportedError(
        'Unsupported PSDK target ${execution.move.target.name}',
      ),
  };

  return targets
      .map((slot) => BattlePositionRef(bank: slot.bank, position: slot.position))
      .toList(growable: false);
}
```

### How To Implement

- Add enum values.
- Expand target resolver tests before changing runtime paths.
- Keep unsupported targets loud until implemented.
- Do not add doubles UI in this lot; only engine topology and tests.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_targeting_test.dart
dart test test/psdk_multi_target_test.dart
dart analyze
dart test
```

### Exit Criteria

- The target enum covers PSDK Studio aimed targets.
- Resolver handles self, foe, all foes, all battlers, side/field no-target.
- Multi-target moves can emit multi-target declaration and damage events.

## FIGHT-07 - Field Weather Terrain

### Objective

Port PSDK field, weather and terrain semantics into the engine.

### Why

Weather and terrain unlock many currently partial or missing moves:

- `s_weather`
- `s_terrain`
- `s_weather_ball`
- `s_terrain_pulse`
- `s_rising_voltage`
- `s_expanding_force`
- `s_grassy_glide`
- `s_solar_beam`
- `s_thunder`
- `s_shore_up`

### Files

Modify:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_field.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/lib/src/domain/handler/battle_weather_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_terrain_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/terrain_power_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart`
- `packages/map_battle/test/psdk_battle_field_test.dart`

Create:

- `packages/map_battle/lib/src/domain/effect/field/weather_effect.dart`
- `packages/map_battle/lib/src/domain/effect/field/terrain_effect.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/weather_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/terrain_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/weather_power_move_behavior.dart`
- `packages/map_battle/test/psdk_weather_terrain_test.dart`

### Logic

- Weather/terrain state must be clearable.
- Duration defaults to 5 turns.
- Weather rocks extend weather to 8 turns.
- Terrain Extender extends terrain to 8 turns.
- Hard weather prevents incompatible weather changes.
- Air Lock / Cloud Nine suppress weather effects without necessarily removing
  weather state.
- End-turn handler decrements duration and emits expiration events.

### Code To Put In Place

Update `PsdkBattleFieldState` with clearable copy:

```dart
const _unchanged = Object();

class PsdkBattleFieldState {
  const PsdkBattleFieldState({
    this.terrain,
    this.weather,
  });

  final PsdkBattleTerrainState? terrain;
  final PsdkBattleWeatherState? weather;

  PsdkBattleFieldState clearTerrain() => copyWith(terrain: null);

  PsdkBattleFieldState clearWeather() => copyWith(weather: null);

  PsdkBattleFieldState tickEndTurn() {
    return copyWith(
      terrain: terrain?.tick(),
      weather: weather?.tick(),
    );
  }

  PsdkBattleFieldState copyWith({
    Object? terrain = _unchanged,
    Object? weather = _unchanged,
  }) {
    return PsdkBattleFieldState(
      terrain: identical(terrain, _unchanged)
          ? this.terrain
          : terrain as PsdkBattleTerrainState?,
      weather: identical(weather, _unchanged)
          ? this.weather
          : weather as PsdkBattleWeatherState?,
    );
  }
}

extension on PsdkBattleTerrainState {
  PsdkBattleTerrainState? tick() {
    if (remainingTurns <= 1) {
      return null;
    }
    return PsdkBattleTerrainState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

extension on PsdkBattleWeatherState {
  PsdkBattleWeatherState? tick() {
    if (remainingTurns <= 1) {
      return null;
    }
    return PsdkBattleWeatherState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}
```

Create weather handler:

```dart
final class BattleWeatherChangeHandler {
  const BattleWeatherChangeHandler();

  BattleHandlerResult changeWeather({
    required BattleHandlerContext context,
    required PsdkBattleWeatherId weather,
    int duration = 5,
  }) {
    final current = context.state.field.weather;
    if (current?.id == weather) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'weather_already_active',
      );
    }

    final nextField = context.state.field.withWeather(
      weather,
      remainingTurns: duration,
    );

    return BattleHandlerResult(
      state: context.state.copyWith(field: nextField),
      rng: context.rng,
      events: <BattleTimelineEvent>[
        BattleWeatherChangedTimelineEvent(
          turn: context.turn,
          weather: weather.jsonName,
          remainingTurns: duration,
        ),
      ],
    );
  }
}
```

Add move behavior for `s_weather`:

```dart
final class WeatherMoveBehavior implements BattleMoveBehavior {
  const WeatherMoveBehavior(this.weather);

  final PsdkBattleWeatherId weather;

  @override
  String get battleEngineMethod => 's_weather';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      weather: weather,
    );

    return BattleMoveBehaviorResolution(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...result.events.map((event) => event.toPsdkEvent()).whereType<PsdkBattleEvent>(),
      ],
      successful: result.applied,
    );
  }
}
```

### How To Implement

- Make field state clearable and tickable first.
- Add handlers.
- Add end-turn weather/terrain tick.
- Wire simple weather/terrain moves.
- Then promote weather/terrain-dependent move families.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_battle_field_test.dart
dart test test/psdk_weather_terrain_test.dart
dart analyze
dart test
```

### Exit Criteria

- Weather and terrain can be applied, refreshed, blocked and expired.
- End-turn events include expiration.
- `s_weather` and `s_terrain` become executable with explicit dependencies.

## FIGHT-08 - Status Lifecycle

### Objective

Port major status effects and end-turn status behavior.

### Why

Status-dependent attacks are already partly present, but the status lifecycle is
not PSDK-complete. Burn, poison, toxic, paralysis, sleep and freeze must be real
effects with prevention and end-turn behavior.

### Files

Create:

- `packages/map_battle/lib/src/domain/effect/status/burn_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/poison_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/toxic_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/paralysis_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/sleep_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/freeze_effect.dart`
- `packages/map_battle/lib/src/domain/effect/status/status_effect_registry.dart`
- `packages/map_battle/test/psdk_status_lifecycle_test.dart`

Modify:

- `packages/map_battle/lib/src/domain/handler/battle_status_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_end_turn_handler.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/variable_power_test.dart`

### Logic

- Burn deals end-turn damage and affects physical attack calculation.
- Poison deals end-turn damage.
- Toxic increments its counter and deals increasing damage.
- Paralysis can prevent action and modifies speed.
- Sleep tracks turns and prevents action until wake.
- Freeze prevents action and can thaw.
- Status application checks immunity/prevention hooks.

### Code To Put In Place

Create a base class:

```dart
abstract class BattleMajorStatusEffect extends BattleEffect {
  const BattleMajorStatusEffect({
    required super.id,
    required super.scope,
    super.remainingTurns,
  });

  PsdkBattleMajorStatus get status;
}
```

Burn:

```dart
final class BurnEffect extends BattleMajorStatusEffect {
  const BurnEffect({
    required BattleEffectScope scope,
  }) : super(id: 'burn', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.burn;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BurnEffect(scope: scope);
  }

  @override
  BattleEffectResult? onEndTurn(BattleEffectHookContext context) {
    final scope = this.scope;
    if (scope is! BattlerEffectScope) {
      return null;
    }
    final battler = context.state.battlerAt(scope.slot);
    final damage = (battler.maxHp / 16).floor().clamp(1, battler.currentHp);
    final nextBattler = battler.copyWith(
      currentHp: battler.currentHp - damage,
    );
    return BattleEffectResult(
      state: context.state.replaceBattler(scope.slot, nextBattler),
      rng: context.rng,
      events: <BattleTimelineEvent>[
        BattleDamageTimelineEvent(
          turn: context.turn,
          user: BattlePositionRef(bank: scope.slot.bank, position: scope.slot.position),
          target: BattlePositionRef(bank: scope.slot.bank, position: scope.slot.position),
          moveId: 'status:burn',
          damage: damage,
          remainingHp: nextBattler.currentHp,
        ),
      ],
    );
  }
}
```

Sleep user-prevention hook:

```dart
final class SleepEffect extends BattleMajorStatusEffect {
  const SleepEffect({
    required BattleEffectScope scope,
    required this.turnsRemaining,
  }) : super(id: 'sleep', scope: scope, remainingTurns: turnsRemaining);

  final int turnsRemaining;

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.sleep;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SleepEffect(scope: scope, turnsRemaining: remainingTurns);
  }

  @override
  BattleMoveFailureReason? onMovePreventionUser(
    BattleEffectMoveContext context,
  ) {
    return BattleMoveFailureReason.unusableByUser;
  }
}
```

### How To Implement

- Add burn and poison first because they are deterministic end-turn damage.
- Add toxic counter.
- Add paralysis and sleep action-prevention through effect hooks.
- Add freeze last because thaw rules interact with move flags.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_status_lifecycle_test.dart
dart test test/psdk_move_families/variable_power_test.dart
dart analyze
dart test
```

### Exit Criteria

- End-turn handler ticks statuses.
- `s_facade`, `s_hex`, `s_venoshock`, `s_infernal_parade`,
  `s_bitter_malice` use real statuses, not only setup flags.
- Status events are visible in timeline.

## FIGHT-09 - Ability Effects

### Objective

Port the ability hooks that block promotion of existing partial moves.

### Why

Several current Dart move families are locally executable but still partial
because ability hooks are missing: Damp, No Guard, Skill Link, Rock Head,
Reckless, Levitate, Air Lock, Cloud Nine and status/immunity abilities.

### Files

Create:

- `packages/map_battle/lib/src/domain/effect/ability/ability_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/ability_effect_registry.dart`
- `packages/map_battle/lib/src/domain/effect/ability/damp_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/no_guard_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/skill_link_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/rock_head_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/reckless_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/levitate_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/air_lock_effect.dart`
- `packages/map_battle/lib/src/domain/effect/ability/cloud_nine_effect.dart`
- `packages/map_battle/test/psdk_ability_effects_test.dart`

Modify:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/recoil_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/self_destruct_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/mind_blown_move_behavior.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

### Logic

Priority abilities:

1. `damp`: blocks self-destruct style moves.
2. `no_guard`: bypasses accuracy checks.
3. `skill_link`: forces five hits for compatible multi-hit moves.
4. `rock_head`: prevents recoil.
5. `reckless`: boosts recoil moves.
6. `levitate`: affects grounded checks.
7. `air_lock` / `cloud_nine`: suppress weather effects.
8. status prevention abilities.
9. type/damage modifier abilities.

### Code To Put In Place

Create registry:

```dart
typedef AbilityEffectFactory = BattleEffect Function({
  required PsdkBattleSlotRef owner,
});

final class AbilityEffectRegistry {
  const AbilityEffectRegistry({
    Map<String, AbilityEffectFactory> factories = _defaultFactories,
  }) : _factories = factories;

  static final _defaultFactories = <String, AbilityEffectFactory>{
    'damp': ({required owner}) => DampEffect(
          scope: BattlerEffectScope(owner),
        ),
    'skill_link': ({required owner}) => SkillLinkEffect(
          scope: BattlerEffectScope(owner),
        ),
    'rock_head': ({required owner}) => RockHeadEffect(
          scope: BattlerEffectScope(owner),
        ),
    'levitate': ({required owner}) => LevitateEffect(
          scope: BattlerEffectScope(owner),
        ),
  };

  final Map<String, AbilityEffectFactory> _factories;

  BattleEffect? create(String? abilityId, PsdkBattleSlotRef owner) {
    if (abilityId == null || abilityId.trim().isEmpty) {
      return null;
    }
    return _factories[abilityId.trim()]?.call(owner: owner);
  }
}
```

`DampEffect`:

```dart
final class DampEffect extends BattleEffect {
  const DampEffect({
    required BattleEffectScope scope,
  }) : super(id: 'ability:damp', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DampEffect(scope: scope);
  }

  @override
  BattleMoveFailureReason? onMovePreventionUser(
    BattleEffectMoveContext context,
  ) {
    final method = context.move.battleEngineMethod;
    if (method == 's_explosion' ||
        method == 's_misty_explosion' ||
        method == 's_mind_blown' ||
        method == 's_chloroblast') {
      return BattleMoveFailureReason.unusableByUser;
    }
    return null;
  }
}
```

`SkillLinkEffect`:

```dart
final class SkillLinkEffect extends BattleEffect {
  const SkillLinkEffect({
    required BattleEffectScope scope,
  }) : super(id: 'ability:skill_link', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SkillLinkEffect(scope: scope);
  }

  int? forcedHitCount(String battleEngineMethod) {
    return switch (battleEngineMethod) {
      's_multi_hit' || 's_triple_kick' || 's_water_shuriken' => 5,
      _ => null,
    };
  }
}
```

Add a test:

```dart
test('Damp prevents Explosion before PP and damage are applied', () {
  final engine = BattleEngine(
    setup: _setup(
      playerAbilityId: 'damp',
      opponentMove: _move(
        id: 'explosion',
        battleEngineMethod: 's_explosion',
        power: 250,
      ),
    ),
  );

  final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

  expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
  expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
  expect(
    result.timeline.events
        .where((event) => event.toJson()['moveId'] == 'explosion')
        .map((event) => event.kind),
    contains('move_failed'),
  );
});
```

### How To Implement

- Start with ability id hydration in runtime seed builder.
- Instantiate ability effects in battle setup/state.
- Port ability hooks one by one with move-family tests.
- Promote matrix statuses only when the move family has tests for the ability
  interaction.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_ability_effects_test.dart
dart test test/psdk_move_families/fixed_damage_and_multi_hit_test.dart
dart test test/psdk_move_families/recoil_move_behavior_test.dart
dart analyze
dart test
```

### Exit Criteria

- `s_multi_hit`, `s_recoil`, `s_explosion`, `s_mind_blown` blockers are reduced.
- Ability ids from runtime setup reach `PsdkBattleCombatant`.
- Grounded checks use ability effects rather than hardcoded isolated fields
  where possible.

## FIGHT-10 - Item Effects

### Objective

Port held-item hooks that affect action order, grounded state, damage, status,
weather/terrain duration and multi-hit behavior.

### Why

PSDK item effects are part of combat rules. Without them, action order and many
move families remain non-parity.

### Files

Create:

- `packages/map_battle/lib/src/domain/effect/item/item_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- `packages/map_battle/lib/src/domain/effect/item/air_balloon_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/iron_ball_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/quick_claw_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/lagging_tail_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/full_incense_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/choice_item_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/weather_rock_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/terrain_extender_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/loaded_dice_effect.dart`
- `packages/map_battle/lib/src/domain/effect/item/berry_effect.dart`
- `packages/map_battle/test/psdk_item_effects_test.dart`

Modify:

- `packages/map_battle/lib/src/domain/action/battle_action_ordering.dart`
- `packages/map_battle/lib/src/domain/battler/battle_grounding_resolver.dart`
- `packages/map_battle/lib/src/domain/handler/battle_item_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_weather_change_handler.dart`
- `packages/map_battle/lib/src/domain/handler/battle_terrain_change_handler.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

### Logic

Priority item effects:

1. Air Balloon: airborne until consumed.
2. Iron Ball: grounded and speed-affecting.
3. Quick Claw: action order boost chance.
4. Lagging Tail: action order penalty.
5. Full Incense: action order penalty.
6. Choice items: lock selected move and modify stat.
7. Weather rocks: 8-turn weather.
8. Terrain Extender: 8-turn terrain.
9. Loaded Dice: multi-hit floor.
10. Berries: status/heal/stat reactions.

### Code To Put In Place

Item registry:

```dart
typedef ItemEffectFactory = BattleEffect Function({
  required PsdkBattleSlotRef owner,
});

final class ItemEffectRegistry {
  const ItemEffectRegistry({
    Map<String, ItemEffectFactory> factories = _defaultFactories,
  }) : _factories = factories;

  static final _defaultFactories = <String, ItemEffectFactory>{
    'air_balloon': ({required owner}) =>
        AirBalloonEffect(scope: BattlerEffectScope(owner)),
    'iron_ball': ({required owner}) =>
        IronBallEffect(scope: BattlerEffectScope(owner)),
    'quick_claw': ({required owner}) =>
        QuickClawEffect(scope: BattlerEffectScope(owner)),
    'loaded_dice': ({required owner}) =>
        LoadedDiceEffect(scope: BattlerEffectScope(owner)),
  };

  final Map<String, ItemEffectFactory> _factories;

  BattleEffect? create(String? itemId, PsdkBattleSlotRef owner) {
    if (itemId == null || itemId.trim().isEmpty) {
      return null;
    }
    return _factories[itemId.trim()]?.call(owner: owner);
  }
}
```

Loaded Dice:

```dart
final class LoadedDiceEffect extends BattleEffect {
  const LoadedDiceEffect({
    required BattleEffectScope scope,
  }) : super(id: 'item:loaded_dice', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LoadedDiceEffect(scope: scope);
  }

  int minimumHitCount(String battleEngineMethod) {
    return battleEngineMethod == 's_multi_hit' ? 4 : 1;
  }
}
```

Item consumption handler:

```dart
final class BattleItemChangeHandler {
  const BattleItemChangeHandler();

  BattleHandlerResult consumeHeldItem({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String itemId,
  }) {
    final battler = context.state.battlerAt(target);
    if (battler.heldItemId != itemId || battler.itemConsumed) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'item_not_available',
      );
    }

    final next = battler.copyWith(
      heldItemId: null,
      consumedItemId: itemId,
      itemConsumed: true,
    );

    return BattleHandlerResult(
      state: context.state.replaceBattler(target, next),
      rng: context.rng,
      events: <BattleTimelineEvent>[
        BattleItemTimelineEvent(
          turn: context.turn,
          holder: BattlePositionRef(bank: target.bank, position: target.position),
          itemId: itemId,
          action: 'consumed',
        ),
      ],
    );
  }
}
```

### How To Implement

- Add item id hydration first.
- Add item effects that are deterministic.
- Add chance-based action-order items after action queue tests exist.
- Add berries after status lifecycle is implemented.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_item_effects_test.dart
dart test test/psdk_action_queue_test.dart
dart test test/psdk_weather_terrain_test.dart
dart analyze
dart test
```

### Exit Criteria

- Grounded resolver honors Air Balloon and Iron Ball through item state.
- Weather/terrain duration items work.
- Loaded Dice affects multi-hit tests.
- Quick Claw/Lagging Tail/Full Incense affect action ordering.

## FIGHT-11 - Full PSDK Move Procedure

### Objective

Align `BattleMoveProcedure` with Pokemon SDK `10 Move/120 Procedure.rb`.

### Why

Current Dart move procedure has a useful foundation, but PSDK includes more
steps: user usability, target remap, pre-accuracy hooks, immunity/blocking,
post-accuracy hooks, animation, damage, effect body, status, stats, effects,
history and cleanup.

### Files

Modify:

- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`
- `packages/map_battle/lib/src/domain/move/battle_accuracy_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_target_resolver.dart`
- all behavior files under `packages/map_battle/lib/src/domain/move/behaviors/`
- `packages/map_battle/test/psdk_move_procedure_test.dart`
- `packages/map_battle/test/psdk_move_hooks_test.dart`

Create:

- `packages/map_battle/lib/src/domain/move/battle_move_remapper.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_immunity_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_history_recorder.dart`
- `packages/map_battle/test/psdk_move_procedure_parity_test.dart`

### Logic

Target PSDK order:

1. user alive;
2. possible target resolution;
3. `move_usable_by_user`;
4. usage event/message;
5. pre-accuracy effects;
6. no-target check;
7. accuracy check;
8. remap user/targets;
9. immunity/blocking check;
10. post-accuracy effects;
11. post-accuracy move hook;
12. animation cue;
13. damage;
14. effect body;
15. status;
16. stats;
17. effects;
18. move history;
19. successful move history;
20. cleanup/faint/end state.

### Code To Put In Place

Refactor `BattleMoveProcedure` around explicit stages:

```dart
enum BattleMoveProcedureStage {
  userAlive,
  resolveTargets,
  usableByUser,
  usage,
  preAccuracy,
  noTarget,
  accuracy,
  remap,
  immunity,
  postAccuracy,
  postAccuracyMove,
  animation,
  damage,
  effectBody,
  status,
  stats,
  effects,
  history,
  cleanup,
}

final class BattleMoveProcedureTraceEvent extends BattleTimelineEvent {
  const BattleMoveProcedureTraceEvent({
    required int turn,
    required this.moveId,
    required this.stage,
  }) : super(kind: 'move_procedure_stage', turn: turn);

  final String moveId;
  final BattleMoveProcedureStage stage;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...baseJson(),
      'moveId': moveId,
      'stage': stage.name,
    };
  }

  @override
  PsdkBattleEvent? toPsdkEvent() => null;
}
```

Add a remapper interface:

```dart
abstract interface class BattleMoveRemapper {
  BattleMoveRemapResult remap(BattleMoveRemapContext context);
}

final class BattleMoveRemapContext {
  const BattleMoveRemapContext({
    required this.state,
    required this.turn,
    required this.user,
    required this.targets,
    required this.move,
  });

  final PsdkBattleState state;
  final int turn;
  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
  final BattleMoveDefinition move;
}

final class BattleMoveRemapResult {
  const BattleMoveRemapResult({
    required this.user,
    required this.targets,
  });

  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
}
```

Keep default remapper neutral:

```dart
final class NoopBattleMoveRemapper implements BattleMoveRemapper {
  const NoopBattleMoveRemapper();

  @override
  BattleMoveRemapResult remap(BattleMoveRemapContext context) {
    return BattleMoveRemapResult(
      user: context.user,
      targets: context.targets,
    );
  }
}
```

### How To Implement

- First add procedure trace tests with a simple damaging move.
- Refactor procedure without changing behavior.
- Add remap/immunity stage as neutral.
- Then wire effects into prevention and post-accuracy hooks.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_move_procedure_test.dart
dart test test/psdk_move_procedure_parity_test.dart
dart test test/psdk_move_hooks_test.dart
dart analyze
dart test
```

### Exit Criteria

- Procedure stage order is covered by tests.
- Existing moves still work.
- Future effects can plug into pre/post accuracy, prevention and remap without
  editing every move family.

## FIGHT-12 - Move Family Porting Waves

### Objective

Move the PSDK move matrix from 20 `ported` / 24 `partial` toward full coverage.

### Why

After effects, handlers, action queue, targeting, field, status, abilities and
items exist, move families can finally be ported honestly. Before then, many
families can only be partial.

### Files

Modify repeatedly:

- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `reports/psdk-move-porting-matrix.md`
- existing files under `packages/map_battle/lib/src/domain/move/behaviors/`

Create per family:

- `packages/map_battle/lib/src/domain/move/behaviors/<family>_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/<family>_test.dart`

### Logic

Port in waves:

Wave A: promote existing partials after their blockers are implemented:

- `s_basic`
- `s_status`
- `s_protect`
- `s_multi_hit`
- `s_triple_kick`
- `s_population_bomb`
- `s_water_shuriken`
- `s_false_swipe`
- `s_splash`
- `s_final_gambit`
- `s_chloroblast`
- `s_mind_blown`
- `s_steel_beam`
- `s_explosion`
- `s_misty_explosion`
- `s_recoil`
- `s_gyro_ball`
- `s_hex`
- `s_low_kick`
- `s_heavy_slam`
- `s_body_press`
- `s_foul_play`
- `s_psyshock`
- `s_custom_stats_based`

Wave B: local formulas with limited dependencies:

- fixed damage variants;
- variable power variants;
- crit variants;
- direct HP moves;
- no-effect moves;
- custom stat source moves.

Wave C: field/weather/terrain moves:

- weather setters;
- terrain setters;
- weather power/type moves;
- terrain power/type moves;
- Solar Beam/Solar Blade style charge skips;
- Thunder/Hurricane accuracy weather variants.

Wave D: status/stat/effect moves:

- stat raises/drops;
- status-only moves;
- drain moves;
- healing moves;
- cure moves;
- trapping/bind moves;
- protection variants;
- substitute;
- screens;
- entry hazards.

Wave E: complex action/procedure moves:

- switch/force switch;
- pivot moves;
- copy/counter/mirror moves;
- two-turn moves;
- recharge;
- lock-in moves;
- future attacks;
- pledge/combo moves;
- multi-turn rampage.

### Code To Put In Place

Use this behavior template for every new family:

```dart
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

final class ExampleFamilyMoveBehavior implements BattleMoveBehavior {
  const ExampleFamilyMoveBehavior();

  @override
  String get battleEngineMethod => 's_example_family';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final result = applyFamilyRule(
      state: prepared.state,
      rng: prepared.rng,
      user: context.user,
      targets: prepared.psdkTargets,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...result.events,
      ],
      successful: result.successful,
    );
  }
}
```

Use this test template for each family:

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK s_example_family', () {
    test('matches the Pokemon SDK primary rule', () {
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'example_move',
            battleEngineMethod: 's_example_family',
            power: 80,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.timeline.events.map((event) => event.kind), contains('damage'));
    });
  });
}
```

Registry entry pattern:

```dart
's_example_family': _KnownDartBehavior(
  dartBehavior: 'ExampleFamilyMoveBehavior',
  status: _PsdkPortStatus.ported,
),
```

### How To Implement

- Port one move family per commit.
- For every family, read the Ruby source in `10 Move`.
- Write tests for:
  - normal success;
  - miss or immunity when relevant;
  - Protect interaction when relevant;
  - ability/item/status dependency when relevant;
  - history/timeline events.
- Update registry and regenerate matrix after the tests pass.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_move_families
dart run tool/extract_psdk_move_registry.dart \
  ../../pokemonsdk-development/scripts/5\ Battle \
  ../../reports/psdk-move-porting-matrix.md \
  --manifest lib/src/data/generated/psdk_move_registry_manifest.dart
dart test test/psdk_registry_manifest_test.dart
dart analyze
dart test
```

### Exit Criteria

- No move is promoted to `ported` without tests for every dependency listed in
  its manifest row.
- Partial status always names a missing dependency.
- Matrix count improves after every wave.

## FIGHT-13 - PSDK AI

### Objective

Replace the hardcoded opponent first-move decision with a PSDK-style AI policy.

### Why

The engine currently proves move execution, but a real battle needs opponent
decisions. PSDK has AI heuristics under `30 AI`. The Dart version should remain
pure and testable, with deterministic RNG.

### Files

Create:

- `packages/map_battle/lib/src/domain/ai/battle_ai.dart`
- `packages/map_battle/lib/src/domain/ai/battle_ai_context.dart`
- `packages/map_battle/lib/src/domain/ai/battle_move_heuristic.dart`
- `packages/map_battle/lib/src/domain/ai/basic_psdk_battle_ai.dart`
- `packages/map_battle/test/psdk_ai_test.dart`

Modify:

- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/application/battle_engine.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_engine.dart`
- `packages/map_battle/lib/map_battle.dart`

### Logic

AI v1:

- choose a legal move;
- prefer damaging moves that can KO;
- avoid status move if target already has a major status;
- avoid no-PP moves;
- use deterministic tie-breaking from the AI RNG stream.

AI later:

- switch decisions;
- item decisions;
- doubles coordination;
- trainer personality.

### Code To Put In Place

Create AI interface:

```dart
abstract interface class BattleAi {
  BattleDecision choose(BattleAiContext context);
}

final class BattleAiContext {
  const BattleAiContext({
    required this.state,
    required this.actor,
    required this.rng,
    required this.turn,
  });

  final PsdkBattleState state;
  final PsdkBattleSlotRef actor;
  final BattleRngStreams rng;
  final int turn;
}
```

Basic AI:

```dart
final class BasicPsdkBattleAi implements BattleAi {
  const BasicPsdkBattleAi();

  @override
  BattleDecision choose(BattleAiContext context) {
    final battler = context.state.battlerAt(context.actor);
    final choices = <int>[
      for (var i = 0; i < battler.moves.length; i += 1)
        if (battler.moves[i].hasUsablePp) i,
    ];
    if (choices.isEmpty) {
      return const BattleDecision.fight(moveSlot: 0);
    }

    choices.sort((left, right) {
      final leftMove = battler.moves[left];
      final rightMove = battler.moves[right];
      final byPower = rightMove.power.compareTo(leftMove.power);
      if (byPower != 0) {
        return byPower;
      }
      return left.compareTo(right);
    });

    return BattleDecision.fight(moveSlot: choices.first);
  }
}
```

### How To Implement

- Add AI interface.
- Inject AI into `BattleEngine`.
- Keep default AI equivalent enough to current behavior for smoke tests unless
  stronger move exists.
- Add deterministic tests.

### Validation

```bash
cd packages/map_battle
dart test test/psdk_ai_test.dart
dart test test/psdk_engine_smoke_test.dart
dart analyze
dart test
```

### Exit Criteria

- Opponent choice is no longer hardcoded in `BattleTurnRunner`.
- AI decisions are deterministic under the battle RNG seed.
- Existing CLI can select AI mode.

## FIGHT-14 - Runtime Bridge

### Objective

Make the runtime battle handoff consume PSDK data/state/timeline only.

### Why

`map_runtime` must render and orchestrate battles without owning combat rules.
The battle engine should emit timeline events; runtime should map them to
animations, HUD updates and battle outcome application.

### Files

Modify:

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_move_visual_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_animation_runner.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/battle_turn_animation_planner_test.dart`

Create:

- `packages/map_runtime/lib/src/application/runtime_psdk_battle_event_mapper.dart`
- `packages/map_runtime/test/runtime_psdk_battle_event_mapper_test.dart`

### Logic

Runtime responsibilities:

- Build `PsdkBattleSetup` from runtime Pokemon/save data.
- Include ability id, held item id, statuses, weight, types, move data.
- Submit player decisions.
- Consume `BattleTimelineEvent` or `PsdkBattleEvent`.
- Map animation cues by PSDK ids.
- Apply outcome to runtime state/save.

Runtime must not:

- inspect Showdown unsupported reasons;
- calculate damage;
- apply status rules directly;
- guess move behavior from animation names.

### Code To Put In Place

Event mapper:

```dart
sealed class RuntimeBattlePresentationEvent {
  const RuntimeBattlePresentationEvent();
}

final class RuntimeBattleMoveAnimationEvent
    extends RuntimeBattlePresentationEvent {
  const RuntimeBattleMoveAnimationEvent({
    required this.userBank,
    required this.userPosition,
    required this.targetBank,
    required this.targetPosition,
    required this.moveId,
    required this.animationId,
  });

  final int userBank;
  final int userPosition;
  final int targetBank;
  final int targetPosition;
  final String moveId;
  final String animationId;
}

List<RuntimeBattlePresentationEvent> mapPsdkTimelineToRuntime(
  BattleTimeline timeline,
) {
  return <RuntimeBattlePresentationEvent>[
    for (final event in timeline.events)
      if (event is BattleAnimationCueTimelineEvent)
        RuntimeBattleMoveAnimationEvent(
          userBank: event.user.bank,
          userPosition: event.user.position,
          targetBank: event.targets.first.bank,
          targetPosition: event.targets.first.position,
          moveId: event.moveId,
          animationId: event.animationId ?? event.moveId,
        ),
  ];
}
```

Combatant seed builder must hydrate PSDK fields:

```dart
PsdkBattleCombatantSetup buildPsdkCombatantSeed(RuntimePokemon pokemon) {
  return PsdkBattleCombatantSetup(
    id: pokemon.instanceId,
    speciesId: pokemon.speciesId,
    displayName: pokemon.displayName,
    level: pokemon.level,
    maxHp: pokemon.maxHp,
    currentHp: pokemon.currentHp,
    types: PsdkBattleTypes(
      primary: pokemon.primaryType,
      secondary: pokemon.secondaryType,
    ),
    stats: PsdkBattleStats(
      attack: pokemon.attack,
      defense: pokemon.defense,
      specialAttack: pokemon.specialAttack,
      specialDefense: pokemon.specialDefense,
      speed: pokemon.speed,
    ),
    moves: pokemon.moves.map(toPsdkBattleMoveData).toList(growable: false),
    abilityId: pokemon.abilityId,
    heldItemId: pokemon.heldItemId,
    majorStatus: _toPsdkStatusOrNull(pokemon.majorStatus),
    baseWeightKg: pokemon.weightKg,
  );
}
```

### How To Implement

- Start with tests for no Showdown references in runtime bridge.
- Hydrate new PSDK battler fields.
- Map timeline events to existing animation planner inputs.
- Keep UI unchanged unless a runtime model requires a new field.

### Validation

```bash
cd packages/map_runtime
flutter test test/runtime_battle_move_bridge_test.dart
flutter test test/runtime_battle_combatant_seed_builder_test.dart
flutter test test/runtime_battle_setup_mapper_test.dart
flutter test test/runtime_psdk_battle_event_mapper_test.dart
flutter analyze
flutter test
```

### Exit Criteria

- Runtime battle setup includes PSDK ability/item/status/weight/move fields.
- Runtime animation planning consumes timeline events.
- No active runtime combat branch depends on Showdown.

## FIGHT-15 - Parity Harness And Legacy Removal

### Objective

Create a durable CLI and test harness that proves the PSDK Fight Engine works,
then remove legacy combat paths when the runtime no longer needs them.

### Why

The user explicitly wants a battle CLI for testing behaviors. This becomes the
long-term parity smoke tool for agents and developers. It should be easy to run
specific scenarios and compare timelines.

### Files

Modify:

- `packages/map_battle/bin/psdk_battle_cli.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_queue.dart`

Create:

- `packages/map_battle/test/fixtures/psdk_scenarios/basic_damage.json`
- `packages/map_battle/test/fixtures/psdk_scenarios/weather_terrain.json`
- `packages/map_battle/test/fixtures/psdk_scenarios/status_lifecycle.json`
- `packages/map_battle/test/fixtures/psdk_scenarios/ability_item_hooks.json`
- `packages/map_battle/tool/run_psdk_parity_scenarios.dart`
- `reports/psdk-fight-engine-scenario-results.md`

Delete after migration is complete and runtime tests prove no imports remain:

- legacy root files in `packages/map_battle/lib/src/*.dart` that duplicate the
  clean PSDK engine;
- legacy tests that only assert old non-PSDK combat semantics;
- legacy adapters in runtime/editor that exist only for Showdown combat.

### Logic

CLI features:

- run a named fixture scenario;
- select player move slots;
- print JSON timeline;
- print final state;
- optionally run all scenarios and summarize pass/fail;
- no Flutter dependency.

Scenario JSON shape:

```json
{
  "name": "basic_damage",
  "turns": [
    {"player": {"kind": "fight", "moveSlot": 0}}
  ],
  "expect": {
    "outcome": "victory",
    "events": ["turn_started", "move_declared", "animation_cue", "damage"]
  }
}
```

### Code To Put In Place

CLI entry:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';

Future<void> main(List<String> args) async {
  final parsed = PsdkBattleCliArgs.parse(args);
  if (parsed == null) {
    stderr.writeln(
      'Usage: dart run bin/psdk_battle_cli.dart --scenario <path> [--json]',
    );
    exitCode = 64;
    return;
  }

  final scenario = PsdkBattleCliScenario.fromJson(
    jsonDecode(File(parsed.scenarioPath).readAsStringSync())
        as Map<String, dynamic>,
  );
  final result = PsdkBattleCliRunner().run(scenario);

  if (parsed.json) {
    stdout.writeln(jsonEncode(result.toJson()));
  } else {
    stdout.writeln(result.toPrettyText());
  }
}
```

Runner:

```dart
final class PsdkBattleCliRunner {
  const PsdkBattleCliRunner();

  PsdkBattleCliResult run(PsdkBattleCliScenario scenario) {
    final engine = BattleEngine(setup: scenario.setup);
    final timelines = <Map<String, Object?>>[];

    for (final turn in scenario.turns) {
      final result = engine.submit(turn.playerDecision);
      timelines.add(<String, Object?>{
        'turn': result.state.turnNumber,
        'events': result.timeline.events.map((event) => event.toJson()).toList(),
        'outcome': result.outcome?.kind.name,
      });
      if (result.state.isFinished) {
        break;
      }
    }

    return PsdkBattleCliResult(
      finalState: engine.snapshot(),
      turns: timelines,
    );
  }
}
```

Parity scenario tool:

```dart
Future<void> main(List<String> args) async {
  final root = Directory('test/fixtures/psdk_scenarios');
  final files = root
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));

  var failures = 0;
  for (final file in files) {
    final scenario = PsdkBattleCliScenario.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
    final result = const PsdkBattleCliRunner().run(scenario);
    final passed = result.matches(scenario.expectation);
    stdout.writeln('${passed ? 'PASS' : 'FAIL'} ${scenario.name}');
    if (!passed) {
      failures += 1;
    }
  }

  if (failures > 0) {
    exitCode = 1;
  }
}
```

Legacy import guard:

```bash
rg -n "src/battle_session.dart|src/battle_state.dart|src/battle_queue.dart" \
  packages/map_runtime packages/map_editor examples
```

### How To Implement

- Extend existing CLI before deleting anything.
- Add JSON fixtures for one scenario per major system.
- Make the tool run in CI-like local commands.
- Remove legacy root battle files only after `map_runtime` no longer imports
  them and the public barrel has PSDK replacements.

### Validation

```bash
cd packages/map_battle
dart run bin/psdk_battle_cli.dart \
  --scenario test/fixtures/psdk_scenarios/basic_damage.json \
  --json
dart run tool/run_psdk_parity_scenarios.dart
dart test test/psdk_battle_cli_test.dart
dart analyze
dart test

cd ../map_runtime
flutter test
```

### Exit Criteria

- CLI can run all scenario fixtures.
- Scenario results are written to
  `reports/psdk-fight-engine-scenario-results.md`.
- Legacy battle files are removed only when no active runtime/editor/example
  import remains.
- `rg -n "showdown|Showdown|showdownMoveId|showdownHooksPresent" packages`
  returns only legacy migration docs/tests or no active combat hits.

## Recommended Execution Order

1. FIGHT-00, because it gives the migration measurable gates.
2. FIGHT-02, because handlers/effects need richer battler state.
3. FIGHT-03, because all PSDK interception depends on effects.
4. FIGHT-04, because move families must mutate through handlers.
5. FIGHT-05 and FIGHT-06, because action order and targeting affect almost
   every non-trivial move.
6. FIGHT-07 and FIGHT-08, because they unlock a large block of partial moves.
7. FIGHT-09 and FIGHT-10, because ability/item hooks promote many partials.
8. FIGHT-11, because the full procedure should be in place before mass porting.
9. FIGHT-12, in small move-family waves.
10. FIGHT-13, when AI is needed beyond smoke battles.
11. FIGHT-14, once the battle engine emits stable timeline events.
12. FIGHT-01 can be started early, but finish it only when editor/runtime tests
    prove old project migration still works.
13. FIGHT-15 closes the migration.

## Global Definition Of Done

The PSDK Fight Engine migration is done when:

- `reports/psdk-move-porting-matrix.md` has 330 `ported` move methods or every
  remaining non-ported row is explicitly out of project scope.
- `reports/psdk-effect-porting-matrix.md` has all required PSDK battle effects
  ported for the supported generation/data scope.
- Runtime combat uses `BattleEngine` / PSDK lane only.
- No active runtime battle branch references Showdown.
- CLI scenario suite covers:
  - basic damage;
  - status lifecycle;
  - stat stages;
  - weather;
  - terrain;
  - protection;
  - multi-hit;
  - recoil;
  - self-KO;
  - ability prevention;
  - item ordering;
  - switch action;
  - multi-target action.
- `cd packages/map_battle && dart analyze && dart test` passes.
- `cd packages/map_runtime && flutter analyze && flutter test` passes.
- `cd packages/map_core && dart analyze && dart test` passes after model
  migration.
- `cd packages/map_editor && flutter analyze && flutter test` passes after
  import/source migration.

## Notes For Future Agents

- Do not promote a move from `partial` to `ported` because it "seems to work" in
  a single happy-path test. Check its PSDK Ruby class and dependency tags.
- Do not put runtime visuals inside `map_battle`.
- Do not add Flutter or Flame imports to pure Dart packages.
- Do not remove legacy files until `rg` proves no active package imports them.
- When a lot touches generated files, regenerate only in that package.
- When a lot is too large, split it by dependency boundary, not by arbitrary
  file count.
