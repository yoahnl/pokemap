# Dynamic Shop State Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettre d’authorer sans code des états complets de boutique, de les résoudre selon le `GameState`, puis de vendre le bon catalogue au bon prix dans Selbrume.

**Architecture:** `map_core` porte les contrats sérialisés et les diagnostics purs. `map_gameplay` évalue les conditions, résout un profil et sécurise la transaction. `map_runtime` et le host ouvrent le profil résolu. `map_editor` expose le workspace quatre zones validé, sans couleur locale ni identifiant libre.

**Tech Stack:** Dart 3, Freezed/json_serializable, Flutter desktop, Riverpod, PokeMap design system, `package:test`, `flutter_test`.

**Design specification:** `docs/superpowers/specs/2026-07-23-dynamic-shop-state-builder-design.md`

**Execution constraint:** Le propriétaire du projet a explicitement indiqué qu’un worktree dédié n’est pas nécessaire. Travailler dans l’arbre courant, préserver les preuves de walkthrough non suivies et vérifier le diff avant chaque commit.

**Progression:** `FG-074` terminé le 2026-07-23 ; `FG-075` est le prochain lot.

---

## File map

### Contracts and validation

- Create `packages/map_core/lib/src/models/shop_state_definition.dart`
  Owns `ShopStateDefinition` and normalization.
- Generate `packages/map_core/lib/src/models/shop_state_definition.freezed.dart`
- Generate `packages/map_core/lib/src/models/shop_state_definition.g.dart`
- Modify `packages/map_core/lib/src/models/shop_definition.dart`
  Adds conditional states while retaining legacy default entries.
- Modify `packages/map_core/lib/src/models/script_conditions.dart`
  Adds typed game-state condition sources required by shop progression.
- Modify generated `script_conditions.*` and `shop_definition.*`
- Modify `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- Modify `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- Modify `packages/map_core/lib/src/operations/narrative_project_validator.dart`
- Modify `packages/map_core/lib/src/operations/narrative_validator.dart`
- Modify `packages/map_core/lib/src/read_models/narrative_dependency_index.dart`
- Modify `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- Modify `packages/map_core/lib/src/read_models/storyline_progression_projection.dart`
- Modify `packages/map_core/lib/src/validation/validators.dart`
  Keeps every exhaustive `ScriptConditionType` consumer compiling and records
  the new references without exposing raw IDs.
- Create `packages/map_core/lib/src/validation/shop_state_validator.dart`
  Owns project-aware shop diagnostics.
- Modify `packages/map_core/lib/map_core.dart`
  Exports the new public contracts.

### Pure gameplay

- Create `packages/map_gameplay/lib/src/shop_state_resolver.dart`
  Owns deterministic state selection and explanation.
- Modify `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
  Evaluates the newly exposed game-state sources.
- Modify `packages/map_gameplay/lib/src/game_state_mutations.dart`
  Revalidates the selected profile and persists state-scoped stock.
- Create `packages/map_gameplay/lib/src/shop_state_resolution_validator.dart`
  Owns diagnostics that require evaluating states against simulated
  `GameState` values.
- Modify `packages/map_gameplay/lib/map_gameplay.dart`
  Exports the resolver and runtime-aware diagnostics.

### Runtime and host

- Modify `packages/map_runtime/lib/src/application/player_service_runtime_controller.dart`
  Resolves `openShop` requests against the live `GameState`.
- Modify `examples/playable_runtime_host/lib/src/in_game_shop_page.dart`
  Presents the resolved catalogue and closed state.
- Modify `examples/playable_runtime_host/lib/main.dart`
  Uses the resolved title and profile.
- Modify `examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart`
  Exercises the same guarded purchase path as production.

### No-code editor

- Modify `packages/map_editor/lib/src/features/gameplay/application/shop_editor_controller.dart`
  Adds state lifecycle and profile catalogue operations.
- Create `packages/map_editor/lib/src/features/gameplay/application/shop_state_simulation_controller.dart`
- Refactor `packages/map_editor/lib/src/features/gameplay/presentation/shop_editor_panel.dart`
- Create `packages/map_editor/lib/src/features/gameplay/presentation/shop_project_list.dart`
- Create `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_list.dart`
- Create `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_catalog_editor.dart`
- Create `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_inspector.dart`
- Create `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_preview_strip.dart`
- Modify `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- Modify `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart`
- Modify `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart`
- Modify `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart`
- Modify `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- Modify `packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart`
- Modify `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- Modify `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
  Handles the expanded shared condition enum explicitly; the Shop Builder
  remains the first no-code surface for the new state sources.

### Selbrume and evidence

- Modify `selbrume/project.json`
- Modify `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`
- Modify `examples/playable_runtime_host/tool/src/selbrume_mvp_journey_verifier.dart`
- Create `reports/gameplay/fg_079_selbrume_dynamic_shop_golden_slice.md`
- Modify `pokemap_roadmap_mecaniques_fangame.md`

---

## Lot FG-074 — Shop State Model & Compatibility V0

### Task 1: Add the serialized shop-state contract

**Files:**

- Create: `packages/map_core/lib/src/models/shop_state_definition.dart`
- Modify: `packages/map_core/lib/src/models/shop_definition.dart`
- Modify: `packages/map_core/lib/src/models/script_conditions.dart`
- Modify: `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- Modify: `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- Modify: `packages/map_core/lib/src/operations/narrative_project_validator.dart`
- Modify: `packages/map_core/lib/src/operations/narrative_validator.dart`
- Modify: `packages/map_core/lib/src/read_models/narrative_dependency_index.dart`
- Modify: `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- Modify: `packages/map_core/lib/src/read_models/storyline_progression_projection.dart`
- Modify: `packages/map_core/lib/src/validation/validators.dart`
- Modify: `packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- Modify: `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Generate: `packages/map_core/lib/src/models/shop_state_definition.freezed.dart`
- Generate: `packages/map_core/lib/src/models/shop_state_definition.g.dart`
- Generate: `packages/map_core/lib/src/models/shop_definition.freezed.dart`
- Generate: `packages/map_core/lib/src/models/shop_definition.g.dart`
- Generate: `packages/map_core/lib/src/models/script_conditions.freezed.dart`
- Generate: `packages/map_core/lib/src/models/script_conditions.g.dart`
- Create: `packages/map_core/test/shop_state_definition_test.dart`
- Test: `packages/map_core/test/shop_definition_test.dart`
- Test: `packages/map_core/test/project_json_migrations_test.dart`
- Create: `packages/map_core/test/script_conditions_test.dart`
- Modify: `packages/map_core/test/narrative_dependency_index_test.dart`
- Modify: `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- Modify: `packages/map_core/test/narrative_project_validator_test.dart`
- Modify: `packages/map_editor/test/npc_runtime_rules_authoring_catalog_test.dart`
- Modify: `packages/map_editor/test/event_properties_panel_scene_target_test.dart`
- Modify: `packages/map_editor/test/storylines_workspace_shell_test.dart`

- [x] **Step 1: Write the failing state round-trip test**

Create `packages/map_core/test/shop_state_definition_test.dart` with a test that
locks normalization and JSON:

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes and round-trips one complete conditional state', () {
    final state = ShopStateDefinition(
      id: ' after-lysa ',
      label: ' Après la victoire contre Lysa ',
      priority: 10,
      activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
      storefrontLabel: ' Comptoir victorieux ',
      welcomeMessage: ' Félicitations ! ',
      entries: const [
        ShopEntryDefinition(itemId: 'potion', price: 250, stock: 20),
      ],
    ).normalized(knownItemIds: const {'potion'});

    final restored = ShopStateDefinition.fromJson(state.toJson());

    expect(restored.id, 'after-lysa');
    expect(restored.label, 'Après la victoire contre Lysa');
    expect(restored.storefrontLabel, 'Comptoir victorieux');
    expect(restored.welcomeMessage, 'Félicitations !');
    expect(restored.entries.single.price, 250);
  });
}
```

- [x] **Step 2: Extend the existing shop test with legacy and uniqueness cases**

Add tests proving:

```dart
test('legacy shops without states keep their default catalogue', () {
  final shop = ShopDefinition.fromJson({
    'id': 'mart',
    'label': 'Boutique',
    'entries': [
      {'itemId': 'potion', 'price': 300}
    ],
  });

  expect(shop.states, isEmpty);
  expect(shop.entries.single.itemId, 'potion');
});

test('rejects duplicate conditional state ids', () {
  expect(
    () => ShopDefinition(
      id: 'mart',
      label: 'Boutique',
      states: [
        _state('after-story'),
        _state('after-story'),
      ],
    ).normalized(),
    throwsStateError,
  );
});
```

Define `_state` in the test with a valid flag condition and an empty catalogue.

- [x] **Step 3: Lock the expanded shared condition contract**

Create `script_conditions_test.dart` to round-trip each new condition. For
`factEquals`, cover `bool`, `int` and `string` values that have ambiguous text
forms such as `"true"` and `"42"`; assert `valueType` preserves the kind.

Extend the dependency/reference/project-validator tests so Fact, Step, badge
and item IDs are reported at their exact condition path. Extend the three
editor characterization tests to prove their current visible condition
catalogues do not gain a raw-ID escape hatch as a side effect of the enum
extension.

- [x] **Step 4: Run the focused tests and observe the missing API**

Run:

```bash
cd packages/map_core
dart test test/shop_state_definition_test.dart \
  test/shop_definition_test.dart \
  test/script_conditions_test.dart \
  test/narrative_dependency_index_test.dart \
  test/narrative_reference_picker_read_models_test.dart \
  test/narrative_project_validator_test.dart
```

Expected: compilation fails because `ShopStateDefinition`,
`ShopDefinition.states` and the new typed condition vocabulary do not exist.

- [x] **Step 5: Implement `ShopStateDefinition`**

Create the Freezed model with these exact public fields:

```dart
@freezed
class ShopStateDefinition with _$ShopStateDefinition {
  const ShopStateDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ShopStateDefinition({
    required String id,
    required String label,
    @Default(0) int priority,
    required ScriptCondition activation,
    @Default(true) bool isOpen,
    String? storefrontLabel,
    @Default('') String welcomeMessage,
    @Default('') String closedMessage,
    @Default([]) List<ShopEntryDefinition> entries,
  }) = _ShopStateDefinition;

  factory ShopStateDefinition.fromJson(Map<String, dynamic> json) =>
      _$ShopStateDefinitionFromJson(json).normalized();
}
```

`normalized()` must trim strings, reject empty `id`/`label`, normalize every
entry, and reject duplicate item IDs in that state.

- [x] **Step 6: Add `states` to `ShopDefinition` without moving `entries`**

Add:

```dart
@Default([]) List<ShopStateDefinition> states,
```

Normalize every state, reject duplicate state IDs, and leave legacy `entries`
untouched as the implicit default profile.

- [x] **Step 7: Add the progression condition wire vocabulary**

Extend `ScriptConditionType` and `ScriptConditionParams` with:

```dart
factEquals
stepCompleted
badgeOwned
itemQuantityAtLeast
moneyAtLeast
```

Use parameter keys:

```dart
factId
valueType
stepId
badgeId
itemId
value
quantity
amount
```

`factEquals` must encode `NarrativeValue.kind.wireName` into `valueType` and
the canonical scalar into `value`; decoding is driven by `valueType`, never by
guessing from the text. Add factory helpers that validate non-empty IDs and
encode numeric thresholds as decimal strings.

- [x] **Step 8: Update every exhaustive shared-condition consumer**

Update all files listed above that switch on `ScriptConditionType`:

- dependency and validation readers collect Fact, Step, badge and item
  references with typed paths;
- Event Builder mappings either present a guided reference or mark the new
  type as unavailable in that surface, never as an implicit legacy flag;
- existing storyline, event-properties and NPC authoring screens keep their
  previous visible catalogue unless they gain a complete guided picker;
- no switch uses a broad `default` branch to hide a newly unsupported case.

- [x] **Step 9: Regenerate only map_core files**

Run:

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart format lib/src/models/shop_state_definition.dart \
  lib/src/models/shop_definition.dart \
  lib/src/models/script_conditions.dart \
  lib/src/authoring/event_builder_authoring_operations.dart \
  lib/src/authoring/event_builder_contract.dart \
  lib/src/operations/narrative_project_validator.dart \
  lib/src/operations/narrative_validator.dart \
  lib/src/read_models/narrative_dependency_index.dart \
  lib/src/read_models/narrative_reference_picker_read_models.dart \
  lib/src/read_models/storyline_progression_projection.dart \
  lib/src/validation/validators.dart \
  test/shop_state_definition_test.dart \
  test/shop_definition_test.dart \
  test/script_conditions_test.dart \
  test/narrative_dependency_index_test.dart \
  test/narrative_reference_picker_read_models_test.dart \
  test/narrative_project_validator_test.dart

cd ../map_editor
dart format \
  lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart \
  lib/src/ui/canvas/storylines_workspace.dart \
  lib/src/ui/panels/event_properties_panel.dart \
  test/npc_runtime_rules_authoring_catalog_test.dart \
  test/event_properties_panel_scene_target_test.dart \
  test/storylines_workspace_shell_test.dart
```

Expected: generation and formatting complete without conflict.

- [x] **Step 10: Prove legacy migration and the new contract**

Run:

```bash
cd packages/map_core
dart test test/shop_state_definition_test.dart \
  test/shop_definition_test.dart \
  test/project_json_migrations_test.dart \
  test/script_conditions_test.dart \
  test/event_builder_contract_test.dart \
  test/narrative_dependency_index_test.dart \
  test/narrative_reference_picker_read_models_test.dart \
  test/storyline_progression_projection_test.dart \
  test/narrative_project_validator_test.dart
dart analyze

cd ../map_editor
flutter test test/npc_runtime_rules_authoring_catalog_test.dart \
  test/event_properties_panel_scene_target_test.dart \
  test/storylines_workspace_shell_test.dart
flutter analyze
```

Expected: focused tests pass and both analyzers report no issues.

- [x] **Step 11: Commit FG-074**

```bash
git add -f docs/superpowers/specs/2026-07-23-dynamic-shop-state-builder-design.md \
  docs/superpowers/plans/2026-07-23-dynamic-shop-state-builder.md
git add packages/map_core/lib/map_core.dart \
  packages/map_core/lib/src/models/shop_definition.dart \
  packages/map_core/lib/src/models/shop_definition.freezed.dart \
  packages/map_core/lib/src/models/shop_definition.g.dart \
  packages/map_core/lib/src/models/shop_state_definition.dart \
  packages/map_core/lib/src/models/shop_state_definition.freezed.dart \
  packages/map_core/lib/src/models/shop_state_definition.g.dart \
  packages/map_core/lib/src/models/script_conditions.dart \
  packages/map_core/lib/src/models/script_conditions.freezed.dart \
  packages/map_core/lib/src/models/script_conditions.g.dart \
  packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart \
  packages/map_core/lib/src/authoring/event_builder_contract.dart \
  packages/map_core/lib/src/operations/narrative_project_validator.dart \
  packages/map_core/lib/src/operations/narrative_validator.dart \
  packages/map_core/lib/src/read_models/narrative_dependency_index.dart \
  packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart \
  packages/map_core/lib/src/read_models/storyline_progression_projection.dart \
  packages/map_core/lib/src/validation/validators.dart \
  packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart \
  packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart \
  packages/map_editor/lib/src/ui/panels/event_properties_panel.dart \
  packages/map_core/test/shop_state_definition_test.dart \
  packages/map_core/test/shop_definition_test.dart \
  packages/map_core/test/project_json_migrations_test.dart \
  packages/map_core/test/script_conditions_test.dart \
  packages/map_core/test/narrative_dependency_index_test.dart \
  packages/map_core/test/narrative_reference_picker_read_models_test.dart \
  packages/map_core/test/narrative_project_validator_test.dart \
  packages/map_editor/test/npc_runtime_rules_authoring_catalog_test.dart \
  packages/map_editor/test/event_properties_panel_scene_target_test.dart \
  packages/map_editor/test/storylines_workspace_shell_test.dart
git commit -m "feat(core): model conditional shop states"
```

---

## Lot FG-075 — Shop State Resolver & Stock V0

### Task 2: Resolve a profile and guard every purchase

**Files:**

- Create: `packages/map_gameplay/lib/src/shop_state_resolver.dart`
- Modify: `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- Modify: `packages/map_gameplay/lib/src/game_state_mutations.dart`
- Modify: `packages/map_gameplay/lib/map_gameplay.dart`
- Create: `packages/map_gameplay/test/shop_state_resolver_test.dart`
- Create: `packages/map_gameplay/test/script_condition_evaluator_test.dart`
- Test: `packages/map_gameplay/test/shop_operations_test.dart`

- [ ] **Step 1: Write resolver tests for fallback, priority, closure and ties**

Create `shop_state_resolver_test.dart` with these expectations:

```dart
const resolver = ShopStateResolver();

test('uses the legacy default catalogue when no state matches', () {
  final result = resolver.resolve(shop: shop(), gameState: state());
  expect(result.isDefault, isTrue);
  expect(result.stateId, ShopStateResolver.defaultStateId);
  expect(result.entries.single.price, 300);
});

test('selects the highest-priority matching state', () {
  final result = resolver.resolve(
    shop: shopWithAfterLysaAndEnding(),
    gameState: state(flags: {'lysa_defeated', 'story_finished'}),
  );
  expect(result.stateId, 'story-finished');
  expect(result.priority, 30);
});

test('keeps declaration order for an equal-priority runtime tie', () {
  final result = resolver.resolve(
    shop: tiedShop(),
    gameState: state(flags: {'shared_flag'}),
  );
  expect(result.stateId, 'first-declared');
  expect(result.matchedStateIds, ['first-declared', 'second-declared']);
});

test('returns the authored closed message', () {
  final result = resolver.resolve(
    shop: closedShop(),
    gameState: state(flags: {'lighthouse_danger'}),
  );
  expect(result.isOpen, isFalse);
  expect(result.message, 'Le comptoir est fermé pendant l’alerte.');
});
```

- [ ] **Step 2: Write evaluator tests for the new game-state sources**

Cover:

```dart
ScriptConditionFactory.stepCompleted('step_lysa')
ScriptConditionFactory.badgeOwned('badge_brisants')
ScriptConditionFactory.itemQuantityAtLeast('potion', 2)
ScriptConditionFactory.moneyAtLeast(500)
ScriptConditionFactory.factEquals(
  'fact_lysa_defeated',
  const NarrativeValue.boolean(true),
)
```

Each test must include both true and false states. The Fact cases must build a
`NarrativeFactRuntimeResolver` from a typed Fact catalogue and pass it through
`ScriptEvaluationContext`; cover both the Fact default value and an explicit
runtime override.

- [ ] **Step 3: Write guarded purchase tests**

Add tests asserting:

- an item outside the resolved state returns `unknownItem`;
- a closed state returns `shopClosed`;
- a state changed since rendering returns `shopStateChanged`;
- a conditional state uses `shopId::stateId::itemId`;
- default-state purchase still uses `shopId::itemId`;
- returning to a prior state preserves its consumed stock.

- [ ] **Step 4: Run the tests and observe the missing resolver**

Run:

```bash
cd packages/map_gameplay
dart test test/shop_state_resolver_test.dart \
  test/script_condition_evaluator_test.dart \
  test/shop_operations_test.dart
```

Expected: compilation fails on `ShopStateResolver` and the new purchase
failures.

- [ ] **Step 5: Implement `ResolvedShopState` and `ShopStateResolver`**

Use one pure resolver:

```dart
final class ShopStateResolver {
  const ShopStateResolver({
    this.conditions = const ScriptConditionEvaluator(),
  });

  static const String defaultStateId = 'default';
  final ScriptConditionEvaluator conditions;

  ResolvedShopState resolve({
    required ShopDefinition shop,
    required GameState gameState,
    ScriptEvaluationContext? conditionContext,
  }) {
    // Evaluate in declaration order, sort matches by descending priority,
    // preserve declaration order for equal priority, then project one snapshot.
  }
}
```

`ResolvedShopState` must expose the fields fixed in the design specification
and an immutable `matchedStateIds`.

- [ ] **Step 6: Extend `ScriptConditionEvaluator`**

Evaluate:

- Fact through `conditionContext.narrativeFactResolver.resolve(...)`, including
  the authored initial value when no runtime override exists ;
- Step through `gameState.progression.completedStepIds` ;
- badge through `gameState.trainerProfile.badgeIds` ;
- item quantity through `gameState.bag.entries` ;
- money through `gameState.trainerProfile.money`.

Decode the Fact scalar according to `valueType` (`bool`, `int`, `string`) and
compare exact `NarrativeValue` kinds. Missing Fact context, malformed
parameters, type mismatches and unknown references must evaluate to `false`,
matching the evaluator’s fail-closed behavior.

- [ ] **Step 7: Add `purchaseFromResolvedShop` and preserve the old API**

Add:

```dart
ShopPurchaseResult purchaseFromResolvedShop(
  GameState state, {
  required ShopDefinition shop,
  required String expectedStateId,
  required String itemId,
  required String categoryId,
  required int quantity,
  ScriptEvaluationContext? conditionContext,
})
```

Resolve again inside the mutation. Reject a closed shop or a changed
`expectedStateId`. Use the resolved entry price and stock. Keep
`purchaseFromShop` as the legacy-default compatibility entry point. Every
caller that can author typed Facts must pass the same condition context used to
render the resolved profile.

- [ ] **Step 8: Export, format and run focused checks**

Run:

```bash
cd packages/map_gameplay
dart format lib/src/shop_state_resolver.dart \
  lib/src/script_condition_evaluator.dart \
  lib/src/game_state_mutations.dart \
  test/shop_state_resolver_test.dart \
  test/script_condition_evaluator_test.dart \
  test/shop_operations_test.dart
dart test test/shop_state_resolver_test.dart \
  test/script_condition_evaluator_test.dart \
  test/shop_operations_test.dart
dart analyze
```

Expected: all focused tests pass and analyzer reports no issues.

- [ ] **Step 9: Commit FG-075**

```bash
git add packages/map_gameplay/lib/map_gameplay.dart \
  packages/map_gameplay/lib/src/shop_state_resolver.dart \
  packages/map_gameplay/lib/src/script_condition_evaluator.dart \
  packages/map_gameplay/lib/src/game_state_mutations.dart \
  packages/map_gameplay/test/shop_state_resolver_test.dart \
  packages/map_gameplay/test/script_condition_evaluator_test.dart \
  packages/map_gameplay/test/shop_operations_test.dart
git commit -m "feat(gameplay): resolve dynamic shop states"
```

---

## Lot FG-076 — Dynamic Shop Runtime V0

### Task 3: Carry the resolved profile through the physical service flow

**Files:**

- Modify: `packages/map_runtime/lib/src/application/player_service_runtime_controller.dart`
- Test: `packages/map_runtime/test/player_service_runtime_controller_test.dart`
- Modify: `examples/playable_runtime_host/lib/src/in_game_shop_page.dart`
- Modify: `examples/playable_runtime_host/lib/main.dart`
- Modify: `examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart`
- Test: `examples/playable_runtime_host/test/in_game_shop_page_test.dart`
- Create: `examples/playable_runtime_host/test/selbrume_player_services_test.dart`

- [ ] **Step 1: Write the runtime request test**

Extend the controller test so `openShop(shopId)` with
`story_finished == true` emits a `PlayerServiceShopRequest` whose
`resolvedState.stateId` is `story-finished` and whose visible label is the
profile label. Add one typed-Fact case whose initial Fact value only resolves
when the controller receives the project-backed condition context.

- [ ] **Step 2: Write widget tests for dynamic and closed states**

Add tests proving:

```dart
expect(find.text('Potion'), findsOneWidget);
expect(find.textContaining('250'), findsOneWidget);
expect(find.text('Super Potion'), findsOneWidget);
```

after the After-Lysa state resolves, and:

```dart
expect(find.text('Le comptoir est fermé pendant l’alerte.'), findsOneWidget);
expect(find.byKey(const Key('shop-buy-potion')), findsNothing);
```

for the closed state.

- [ ] **Step 3: Write a stale-screen transaction test**

Render the After-Lysa profile, mutate the test `GameState` so the final profile
becomes active, then attempt the previous purchase. Expect the page to refresh
and display the current catalogue without committing the stale transaction.

- [ ] **Step 4: Run the focused Flutter tests and observe the failure**

Run:

```bash
cd packages/map_runtime
flutter test test/player_service_runtime_controller_test.dart

cd ../../examples/playable_runtime_host
flutter test test/in_game_shop_page_test.dart \
  test/selbrume_player_services_test.dart
```

Expected: tests fail because the request and page only know static
`ShopDefinition.entries`.

- [ ] **Step 5: Resolve the shop in `PlayerServiceRuntimeController`**

Add `ResolvedShopState resolvedState` to `PlayerServiceShopRequest`. Resolve it
from the exact `GameState` used to open the service. Add an optional
`ScriptEvaluationContext conditionContext` to
`PlayerServiceRuntimeController`, defaulting to the current legacy-safe empty
context, and carry it in the request. In the production host, build it once
from `NarrativeFactRuntimeResolver.fromFacts(project.facts)`. Keep `shopId` and
`ShopDefinition` unchanged so Scene commands and dependency repair remain
compatible.

- [ ] **Step 6: Render only the resolved snapshot**

In `InGameShopPage`, require the request’s condition context and:

- resolve the selected shop from `_gameState` with that context on every build
  boundary;
- show `storefrontLabel` and `message`;
- show no buy control when `isOpen == false`;
- call `purchaseFromResolvedShop` with `expectedStateId` and the same context;
- re-resolve after every successful state commit;
- convert `shopStateChanged` into a refresh message, not a generic failure.

- [ ] **Step 7: Align production and test overlay hosts**

Use `request.resolvedState.storefrontLabel` for the physical overlay title.
Update `selbrume_player_service_test_host.dart` to call the guarded mutation
with `request.resolvedState.stateId` and `request.conditionContext`.

- [ ] **Step 8: Run runtime, host and smoke checks**

Run:

```bash
cd packages/map_runtime
flutter test test/player_service_runtime_controller_test.dart
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
flutter analyze

cd ../../examples/playable_runtime_host
flutter test test/in_game_shop_page_test.dart \
  test/selbrume_player_services_test.dart
flutter analyze
```

Expected: focused tests and smoke pass; both analyzers report no issues.

- [ ] **Step 9: Commit FG-076**

```bash
git add packages/map_runtime/lib/src/application/player_service_runtime_controller.dart \
  packages/map_runtime/test/player_service_runtime_controller_test.dart \
  examples/playable_runtime_host/lib/src/in_game_shop_page.dart \
  examples/playable_runtime_host/lib/main.dart \
  examples/playable_runtime_host/test/in_game_shop_page_test.dart \
  examples/playable_runtime_host/test/selbrume_player_services_test.dart \
  examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart
git commit -m "feat(runtime): open resolved shop profiles"
```

---

## Lot FG-077 — Dynamic Shop No-Code Builder V0

### Task 4: Build and route the four-zone Shop Builder

**Files:**

- Modify: `packages/map_editor/lib/src/features/gameplay/application/shop_editor_controller.dart`
- Modify: `packages/map_editor/lib/src/features/gameplay/presentation/shop_editor_panel.dart`
- Create: `packages/map_editor/lib/src/features/gameplay/presentation/shop_project_list.dart`
- Create: `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_list.dart`
- Create: `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_catalog_editor.dart`
- Create: `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_inspector.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- Test: `packages/map_editor/test/shop_editor_controller_test.dart`
- Test: `packages/map_editor/test/shop_editor_panel_test.dart`
- Create: `packages/map_editor/test/narrative_studio_shop_route_test.dart`

- [ ] **Step 1: Write controller lifecycle tests**

Add tests for:

- `createStateFromDefault` copies default entries;
- `duplicateState` generates a stable unique ID;
- `createEmptyState` owns an empty catalogue;
- rename trims the label without changing the ID;
- delete cannot target the implicit default;
- adding/editing/removing an entry affects only the selected state;
- every mutation updates `controller.manifest`.

- [ ] **Step 2: Write route and navigation tests**

Create `narrative_studio_shop_route_test.dart` asserting:

```dart
expect(
  NarrativeStudioRouteLocation.shops().destination,
  NarrativeStudioDestination.shops,
);
expect(
  narrativeStudioPresentationFor(
    NarrativeStudioRouteLocation.shops(),
  ).breadcrumb,
  contains('Boutique Builder'),
);
```

Also tap the `Boutiques` rail item and assert the Shop Builder workspace key.

- [ ] **Step 3: Write the four-zone widget test**

Pump a 1920×1080 surface and assert:

```dart
find.byKey(const Key('shop-project-list'))
find.byKey(const Key('shop-state-list'))
find.byKey(const Key('shop-state-catalog-editor'))
find.byKey(const Key('shop-state-inspector'))
```

Select `Après la victoire contre Lysa`, change its price, and assert one
`onManifestChanged` notification with the conditional state updated.

- [ ] **Step 4: Write responsive layout tests**

At widths 1440, 1200 and 980, assert:

- no `FlutterError` overflow;
- inspector inline only at the wide breakpoint;
- inspector side-sheet launcher at the medium breakpoint;
- compact list launcher at the narrow breakpoint.

- [ ] **Step 5: Run the editor tests and observe the missing route**

Run:

```bash
cd packages/map_editor
flutter test test/shop_editor_controller_test.dart \
  test/shop_editor_panel_test.dart \
  test/narrative_studio_shop_route_test.dart
```

Expected: compilation fails on the new state operations and Shop destination.

- [ ] **Step 6: Implement state operations in the controller**

Add typed methods:

```dart
ShopStateDefinition createStateFromDefault(...)
ShopStateDefinition createEmptyState(...)
ShopStateDefinition duplicateState(...)
void renameState(...)
void updateStateSettings(...)
void replaceStateActivation(...)
void addStateEntry(...)
void updateStateEntry(...)
void removeStateEntry(...)
void deleteState(...)
```

All IDs are derived via the existing slug logic. All writes end in normalized
`ProjectManifest` values.

- [ ] **Step 7: Add the typed Narrative Studio route**

Add:

```dart
EditorWorkspaceMode.shops
NarrativeStudioDestination.shops
NarrativeStudioChildRoute.shopBuilder
NarrativeStudioAssetKind.shop
NarrativeStudioRouteLocation.shops(...)
```

Wire the rail label `Boutiques`, the breadcrumb
`Narrative Studio / Boutique Builder`, and the workspace body.

- [ ] **Step 8: Split the panel into the approved four zones**

Keep `ShopEditorPanel` as coordinator only. Move list and inspector widgets to
the files in the file map. Use only:

- `PokeMapPanel`;
- `PokeMapCard`;
- `PokeMapButton`;
- `PokeMapTextField`;
- `PokeMapDropdownField`;
- `PokeMapBadge`;
- semantic theme tokens.

Do not introduce `Color(...)`, `Colors.*`, or a feature-local palette.

- [ ] **Step 9: Connect the real item catalogue**

Project `PokemonItemCatalogEntryView` values from
`LoadPokemonItemsCatalogUseCase` into `ShopEditorItemOption`. Show a
`PokeMapEmptyState` with a recovery action when the catalogue cannot load.

- [ ] **Step 10: Run focused editor tests and analysis**

Run:

```bash
cd packages/map_editor
dart format lib/src/features/gameplay \
  lib/src/features/editor/state/models/editor_workspace_mode.dart \
  lib/src/ui/canvas/narrative_studio \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/shop_editor_controller_test.dart \
  test/shop_editor_panel_test.dart \
  test/narrative_studio_shop_route_test.dart
flutter test test/shop_editor_controller_test.dart \
  test/shop_editor_panel_test.dart \
  test/narrative_studio_shop_route_test.dart
flutter analyze
```

Expected: all focused tests pass and analyzer reports no issues.

- [ ] **Step 11: Commit FG-077**

```bash
git add packages/map_editor/lib/src/features/gameplay \
  packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_studio \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart \
  packages/map_editor/test/shop_editor_controller_test.dart \
  packages/map_editor/test/shop_editor_panel_test.dart \
  packages/map_editor/test/narrative_studio_shop_route_test.dart
git commit -m "feat(editor): add the dynamic Shop Builder"
```

---

## Lot FG-078 — Shop State Validator & Simulator V0

### Task 5: Explain profile selection and block invalid authoring

**Files:**

- Create: `packages/map_core/lib/src/validation/shop_state_validator.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create: `packages/map_core/test/shop_state_validator_test.dart`
- Create: `packages/map_gameplay/lib/src/shop_state_resolution_validator.dart`
- Modify: `packages/map_gameplay/lib/map_gameplay.dart`
- Create: `packages/map_gameplay/test/shop_state_resolution_validator_test.dart`
- Create: `packages/map_editor/lib/src/features/gameplay/application/shop_state_simulation_controller.dart`
- Create: `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_preview_strip.dart`
- Modify: `packages/map_editor/lib/src/features/gameplay/presentation/shop_state_inspector.dart`
- Modify: `packages/map_editor/lib/src/features/gameplay/presentation/shop_editor_panel.dart`
- Create: `packages/map_editor/test/shop_state_simulation_controller_test.dart`
- Create: `packages/map_editor/test/shop_state_preview_strip_test.dart`

- [ ] **Step 1: Write validator tests**

Cover exact diagnostic codes:

```text
SHOP_STATE_DUPLICATE_ID
SHOP_STATE_UNKNOWN_ITEM
SHOP_STATE_INVALID_PRICE
SHOP_STATE_INVALID_STOCK
SHOP_STATE_UNKNOWN_CONDITION_REFERENCE
SHOP_STATE_EQUAL_PRIORITY_IDENTICAL_CONDITION
SHOP_STATE_EQUAL_PRIORITY_ACTIVE_MATCH
SHOP_STATE_CLOSED_WITHOUT_MESSAGE
SHOP_STATE_OPEN_EMPTY_CATALOGUE
```

Each diagnostic must include `shopId`, optional `stateId`, field path and
severity. The Core test owns structural/reference diagnostics, including
identical expressions. The Gameplay test owns
`SHOP_STATE_EQUAL_PRIORITY_ACTIVE_MATCH`, which requires evaluating a supplied
context.

- [ ] **Step 2: Write simulation agreement tests**

Build one project and three synthetic `GameState` values. Assert that the
simulation controller and `ShopStateResolver` return the same `stateId`,
priority and matched-state list for all three. Assert
`ShopStateResolutionValidator` reports only the context in which two
equal-priority states match.

- [ ] **Step 3: Write the preview-strip widget test**

Assert visible labels:

```text
Contexte simulé
État retenu
Après la victoire contre Lysa
2 conditions remplies
```

When two states tie in the simulated context, assert a warning badge and both
state labels.

- [ ] **Step 4: Run tests and observe missing diagnostics**

Run:

```bash
cd packages/map_core
dart test test/shop_state_validator_test.dart

cd ../map_gameplay
dart test test/shop_state_resolution_validator_test.dart

cd ../map_editor
flutter test test/shop_state_simulation_controller_test.dart \
  test/shop_state_preview_strip_test.dart
```

Expected: compilation fails because the structural validator, runtime-aware
validator and simulator do not exist.

- [ ] **Step 5: Implement project-aware validation**

`ShopStateValidator` receives:

```dart
ProjectManifest project
Set<String> knownItemIds
```

Validate references against project Facts, storyline Steps, badges and known
item IDs supplied by the caller after loading the path declared by
`project.pokemon.catalogFiles['items']`.
Treat byte-for-byte equivalent normalized expressions with the same priority
as a structural blocking diagnostic. This class stays in `map_core`, performs
no filesystem I/O and must not import `map_gameplay`.

- [ ] **Step 6: Implement runtime-aware conflict validation**

`ShopStateResolutionValidator` receives a shop, simulated `GameState` values
and their project-backed `ScriptEvaluationContext`. It delegates matching to
`ShopStateResolver` and emits `SHOP_STATE_EQUAL_PRIORITY_ACTIVE_MATCH` when two
matched states share the winning priority. It never duplicates condition
evaluation inside `map_core`.

- [ ] **Step 7: Implement non-mutating simulation**

`ShopStateSimulationController` owns a draft `GameState`, delegates all
resolution to `ShopStateResolver`, and creates the same
`ScriptEvaluationContext` from `project.facts` as production. It exposes a read
model containing:

```dart
resolvedState
matchedStates
conditionRows
hasPriorityConflict
```

Never write the draft into `EditorNotifier`, project storage or a save file.

- [ ] **Step 8: Build the preview strip and inspector diagnostics**

Use design-system badges and surfaces. A diagnostic action selects the
referenced state and focuses the precise inspector section.

- [ ] **Step 9: Run validation and editor checks**

Run:

```bash
cd packages/map_core
dart format lib/src/validation/shop_state_validator.dart \
  test/shop_state_validator_test.dart
dart test test/shop_state_validator_test.dart
dart analyze

cd ../map_gameplay
dart format lib/src/shop_state_resolution_validator.dart \
  test/shop_state_resolution_validator_test.dart
dart test test/shop_state_resolution_validator_test.dart
dart analyze

cd ../map_editor
dart format lib/src/features/gameplay/application/shop_state_simulation_controller.dart \
  lib/src/features/gameplay/presentation/shop_state_preview_strip.dart \
  lib/src/features/gameplay/presentation/shop_state_inspector.dart \
  lib/src/features/gameplay/presentation/shop_editor_panel.dart \
  test/shop_state_simulation_controller_test.dart \
  test/shop_state_preview_strip_test.dart
flutter test test/shop_state_simulation_controller_test.dart \
  test/shop_state_preview_strip_test.dart \
  test/shop_editor_panel_test.dart
flutter analyze
```

Expected: focused tests pass and all three analyzers report no issues.

- [ ] **Step 10: Commit FG-078**

```bash
git add packages/map_core/lib/map_core.dart \
  packages/map_core/lib/src/validation/shop_state_validator.dart \
  packages/map_core/test/shop_state_validator_test.dart \
  packages/map_gameplay/lib/map_gameplay.dart \
  packages/map_gameplay/lib/src/shop_state_resolution_validator.dart \
  packages/map_gameplay/test/shop_state_resolution_validator_test.dart \
  packages/map_editor/lib/src/features/gameplay/application/shop_state_simulation_controller.dart \
  packages/map_editor/lib/src/features/gameplay/presentation/shop_state_preview_strip.dart \
  packages/map_editor/lib/src/features/gameplay/presentation/shop_state_inspector.dart \
  packages/map_editor/lib/src/features/gameplay/presentation/shop_editor_panel.dart \
  packages/map_editor/test/shop_state_simulation_controller_test.dart \
  packages/map_editor/test/shop_state_preview_strip_test.dart
git commit -m "feat(editor): simulate and validate shop states"
```

---

## Lot FG-079 — Selbrume Dynamic Shop Golden Slice V0

### Task 6: Author Selbrume states and close the end-to-end slice

**Files:**

- Modify: `selbrume/project.json`
- Modify: `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`
- Modify: `examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart`
- Modify: `examples/playable_runtime_host/tool/src/selbrume_mvp_journey_verifier.dart`
- Create: `reports/gameplay/fg_079_selbrume_dynamic_shop_golden_slice.md`
- Modify: `pokemap_roadmap_mecaniques_fangame.md`

- [ ] **Step 1: Extend the Selbrume journey test before changing data**

Assert these four states of `shop_port_supplies`:

```text
default          -> Potion 300, Poké Ball 200
after-lysa       -> Potion 250, Poké Ball 200, Antidote 100
lighthouse-alert -> closed with an authored message
story-finished   -> Potion 200, Super Potion 700, Poké Ball 150
```

For each open state, purchase one product and assert exact money, bag quantity
and state-scoped stock key.

- [ ] **Step 2: Add a save/load assertion**

Save after purchasing from `after-lysa`, reload, reopen the shop and assert the
remaining stock and resolved state are unchanged.

- [ ] **Step 3: Run the E2E test and observe the static-catalogue failure**

Run:

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_player_journey_e2e_test.dart
```

Expected: the new assertions fail because Selbrume contains no conditional
states yet.

- [ ] **Step 4: Author the four Selbrume states**

Modify only `shop_port_supplies`. Preserve:

```text
service_port_shop
scene_port_shop
openShop(shop_port_supplies)
```

Use existing canonical Facts, completed Step IDs and ending flags already
produced by the Selbrume campaign. Do not invent parallel progression markers.

- [ ] **Step 5: Update the MVP verifier**

Make `mvp16Shop` require evidence for:

- a purchase before the Lysa transition ;
- a changed price or catalogue after Lysa ;
- the closed lighthouse state ;
- a final-state purchase ;
- stock persistence through save/load.

- [ ] **Step 6: Run focused and sequential Selbrume checks**

Run:

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_player_journey_e2e_test.dart
dart run tool/src/selbrume_mvp_journey_verifier.dart \
  --project-root ../../selbrume \
  --output build/mvp-release/selbrume-journey-receipt.json
```

Expected: E2E and sequential journey verifier pass.

- [ ] **Step 7: Run package-wide regression checks**

Run:

```bash
cd packages/map_core
dart test
dart analyze

cd ../map_gameplay
dart test
dart analyze

cd ../map_runtime
flutter test
flutter analyze

cd ../map_editor
flutter test
flutter analyze

cd ../../examples/playable_runtime_host
flutter test
flutter analyze
```

Expected: every suite passes and every analyzer reports no issues.

- [ ] **Step 8: Perform visual QA against the approved mockup**

Capture the implemented Shop Builder at 1920×1080 and compare:

- four-zone hierarchy ;
- selected state emphasis ;
- catalogue readability ;
- inspector condition rows ;
- preview strip ;
- no overflow at 1440, 1200 and 980 px.

Store deliberate evidence under
`reports/gameplay/evidence/fg_079_dynamic_shop_builder/`. Fix visible
mismatches before writing the closure report. Do not move, rename or delete the
pre-existing Selbrume walkthrough captures.

- [ ] **Step 9: Write the lot report and update the roadmap**

Create `reports/gameplay/fg_079_selbrume_dynamic_shop_golden_slice.md` with:

- initial and final Git status ;
- all modified files ;
- exact commands and results ;
- evidence paths ;
- compatibility proof ;
- known limits ;
- self-critique.

Add `FG-074` through `FG-079` to Phase 4. Mark only lots backed by the fresh
evidence from this execution.

- [ ] **Step 10: Commit the FG-079 release candidate**

```bash
git add selbrume/project.json \
  examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart \
  examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart \
  examples/playable_runtime_host/tool/src/selbrume_mvp_journey_verifier.dart \
  reports/gameplay/evidence/fg_079_dynamic_shop_builder \
  reports/gameplay/fg_079_selbrume_dynamic_shop_golden_slice.md \
  pokemap_roadmap_mecaniques_fangame.md
git commit -m "feat(selbrume): prove dynamic shop progression"
```

- [ ] **Step 11: Establish a clean release candidate**

Run `git status --short --untracked-files=all`. The release verifier refuses a
dirty repository. Do not delete or stash the owner’s existing walkthrough
evidence to make this pass: either it has already been committed deliberately,
or record the global release gate as `BLOCKED` until its ownership is resolved.

- [ ] **Step 12: Package and run the supported release gate**

Only from a clean worktree, run:

```bash
cd examples/playable_runtime_host
dart run tool/package_selbrume_macos.dart \
  --project ../../selbrume \
  --release
dart run tool/verify_mvp_release.dart \
  --project ../../selbrume/project.json \
  --package build/mvp-release/selbrume-macos.zip \
  --full \
  --output build/mvp-release/evidence.json
```

Expected: the package is bound to the current candidate commit and release
evidence contains a passing dynamic-shop criterion. A packaging, cleanliness
or human-walkthrough prerequisite may block the global MVP release without
reopening FG-074 through FG-079 when their own fresh done criteria remain
green.

---

## Final acceptance checklist

- [ ] Static `ShopDefinition.entries` projects remain compatible.
- [ ] Legacy stock keys remain readable.
- [ ] Conditional state stock persists independently.
- [ ] Resolver and simulator select the same state.
- [ ] Runtime revalidates the state before purchase.
- [ ] Closed shops cannot commit purchases.
- [ ] `openShop(shopId)` remains the Scene contract.
- [ ] Four-zone Shop Builder is routed in Narrative Studio.
- [ ] No raw technical ID is required in normal authoring.
- [ ] No feature screen contains hard-coded product colors.
- [ ] Validator links diagnostics back to the state inspector.
- [ ] Selbrume proves default, progressed, closed and final states.
- [ ] Package tests and analyzers pass with fresh output.
- [ ] Canonical roadmap reflects only proven statuses.
- [ ] Pre-existing walkthrough evidence remains untouched.
