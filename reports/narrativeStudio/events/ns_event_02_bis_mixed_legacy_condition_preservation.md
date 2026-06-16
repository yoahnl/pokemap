# NS-EVENT-02-bis — Mixed Legacy Condition Preservation Hardening

## Résumé exécutif

Verdict : `NS-EVENT-02-bis : DONE`.

Ce bis corrige un risque de perte silencieuse dans le contrat core Event Builder : une condition legacy mixte, contenant à la fois une partie traduisible par l'Event Builder MVP et une partie non supportée, est maintenant préservée intégralement.

Comportement livré :

- une condition entièrement supportée reste éditable ;
- une condition entièrement legacy reste préservée comme avant ;
- une condition mixte expose toujours les bindings supportés à titre informatif ;
- une condition mixte conserve l'expression `ScriptCondition` originale complète dans `legacyConditionToPreserve` ;
- `applyEventBuilderContractToMapEvent` conserve cette condition originale tant qu'il n'existe pas d'opération explicite de remplacement complet ;
- `addEventBuilderCondition` et `removeEventBuilderCondition` refusent l'édition quand une condition legacy est préservée, via `UnsupportedError`.

NS-EVENT-03 n'a pas été démarré. Aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `selbrume`, fixture, runtime bridge, build runner ou fichier generated n'a été modifié.

## Scope confirmé

Lot exécuté uniquement :

```text
NS-EVENT-02-bis — Mixed Legacy Condition Preservation Hardening
```

Fichiers modifiés :

```text
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
reports/narrativeStudio/events/ns_event_02_bis_mixed_legacy_condition_preservation.md
```

Fichiers explicitement non modifiés :

```text
packages/map_editor/**
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
assets/**
selbrume/**
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/authoring/event_builder_contract.dart
```

## Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 20
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
```

Au Gate 0, `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` ne sortaient rien. Le worktree était propre avant le lot.

## Règles lues

Fichiers lus :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
/Users/karim/.codex/attachments/ce0ee306-4da4-4c54-bd0b-235d60a2ade0/pasted-text.txt
```

Point notable : `codex_rule.md` demande des passes type sub-agents. Comme aucun outil sub-agent réel n'était nécessaire pour ce bis chirurgical, j'ai appliqué des passes séparées :

- Sub-agent Audit / Architecture : audit du contrat Event Builder et du comportement legacy.
- Sub-agent Implémentation : patch minimal dans les opérations authoring core.
- Sub-agent Tests : RED ciblé, tests ajoutés, GREEN ciblé.
- Sub-agent Build / Validation : suite complète `map_core` et `dart analyze`.
- Sub-agent Critique finale : anti-scope et risques restants.

## Problème initial

La logique existante préservait la condition legacy seulement si aucune condition Event Builder supportée n'était lue :

```dart
legacyConditionToPreserve: conditions.isEmpty ? page.condition : null,
```

Cas dangereux :

```dart
ScriptConditionFactory.allOf([
  ScriptConditionFactory.flagIsSet('fact_started'),
  ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
]);
```

Avant ce bis, la lecture pouvait exposer :

```text
conditions:
- factIsTrue('fact_started')

diagnostics:
- unsupportedLegacyCondition

legacyConditionToPreserve:
- null
```

Puis `applyEventBuilderContractToMapEvent` recompilait seulement `flagIsSet('fact_started')`, ce qui supprimait silencieusement `variableEqualsString('legacy_variable', 'yes')`.

## Décision d'implémentation

Décision retenue :

```text
Si un diagnostic unsupportedLegacyCondition est produit pendant la lecture de page.condition,
alors page.condition est préservée intégralement dans legacyConditionToPreserve,
même si certains bindings supportés ont aussi été exposés.
```

Raison :

- l'Event Builder MVP peut afficher les parties connues pour information ;
- il n'a pas encore d'API explicite "replace all conditions" ;
- autoriser add/remove dans cet état serait ambigu ;
- la seule option sûre en NS-EVENT-02-bis est de préserver l'original complet et de bloquer les éditions partielles.

Impact pour NS-EVENT-03 :

- l'UI/read model pourra afficher les bindings supportés ;
- si `legacyConditionToPreserve != null`, les contrôles d'édition doivent être verrouillés ou proposer plus tard une action explicite de remplacement complet ;
- il ne faut pas faire croire que la condition mixte est entièrement authorable.

## Code modifié

### `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`

Zones modifiées :

- `readEventBuilderContractFromMapEvent`
- `applyEventBuilderContractToMapEvent`
- `addEventBuilderCondition`
- `removeEventBuilderCondition`
- ajout du helper privé `_throwIfPreservedLegacyCondition`

Diff pertinent :

```diff
+  final conditionDiagnosticsStart = diagnostics.length;
   final conditions = _readConditionBindings(
     page.condition,
     diagnostics,
     path: 'page.condition',
   );
+  final hasUnsupportedLegacyCondition = diagnostics
+      .skip(conditionDiagnosticsStart)
+      .any((diagnostic) =>
+          diagnostic.kind ==
+          EventBuilderContractDiagnosticKind.unsupportedLegacyCondition);
...
+    // Keep the original condition when any unsupported legacy fragment exists.
+    // NS-EVENT-02-bis has no replace-all operation, so partial recompilation
+    // would silently drop data from mixed supported/unsupported conditions.
     legacyConditionToPreserve: page.condition != null &&
+            (conditions.isEmpty || hasUnsupportedLegacyCondition)
         ? page.condition
         : null,
```

```diff
+  final ScriptCondition? nextCondition;
+  if (contract.legacyConditionToPreserve != null) {
+    // Preserve the whole legacy expression until a future explicit replace-all
+    // API can make condition edits intentional.
+    nextCondition = contract.legacyConditionToPreserve;
+  } else {
+    final compiled = compileEventBuilderConditionsToScriptCondition(
+      contract.conditions,
+    );
+    if (compiled.hasErrors) {
+      throw UnsupportedError(
+        'Event Builder contract contains conditions that cannot be compiled '
+        'to ScriptCondition in NS-EVENT-02.',
+      );
+    }
+    nextCondition = compiled.condition;
+  }
```

```diff
 EventBuilderContractView addEventBuilderCondition(
   EventBuilderContractView contract,
   EventBuilderConditionBinding condition,
 ) {
+  _throwIfPreservedLegacyCondition(contract, 'add a condition');
   return contract.copyWith(
     conditions: [...contract.conditions, condition],
     clearLegacyConditionToPreserve: true,
```

```diff
 EventBuilderContractView removeEventBuilderCondition(
   EventBuilderContractView contract,
   int index,
 ) {
+  _throwIfPreservedLegacyCondition(contract, 'remove a condition');
   if (index < 0 || index >= contract.conditions.length) {
     throw RangeError.index(index, contract.conditions, 'index');
   }
```

```diff
+void _throwIfPreservedLegacyCondition(
+  EventBuilderContractView contract,
+  String operation,
+) {
+  if (contract.legacyConditionToPreserve == null) {
+    return;
+  }
+  throw UnsupportedError(
+    'Cannot $operation while a legacy condition is preserved. '
+    'NS-EVENT-02-bis has no explicit replace-all condition operation, so the '
+    'original condition is kept to avoid silent data loss.',
+  );
+}
```

### `packages/map_core/test/event_builder_authoring_operations_test.dart`

Tests ajoutés :

```text
preserves mixed supported and legacy condition when applying
add condition refuses preserved legacy condition
remove condition refuses preserved legacy condition
keeps fully supported conditions editable
```

Diff pertinent :

```diff
+    test('preserves mixed supported and legacy condition when applying', () {
+      final original = ScriptConditionFactory.allOf([
+        ScriptConditionFactory.flagIsSet('fact_started'),
+        ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
+      ]);
+      final event = _event(
+        page: MapEventPage(
+          pageNumber: 0,
+          condition: original,
+        ),
+      );
+
+      final contract = readEventBuilderContractFromMapEvent(event);
+
+      expect(contract.conditions, [
+        EventBuilderConditionBinding.factIsTrue('fact_started'),
+      ]);
+      expect(contract.legacyConditionToPreserve, original);
+      expect(
+        contract.diagnostics.map((diagnostic) => diagnostic.kind),
+        contains(EventBuilderContractDiagnosticKind.unsupportedLegacyCondition),
+      );
+
+      final updated = applyEventBuilderContractToMapEvent(
+        event,
+        contract.copyWith(
+          sceneAction: EventBuilderSceneActionBinding(sceneId: 'scene_rival'),
+        ),
+      );
+
+      expect(updated.pages.single.condition, original);
+      expect(
+        updated.pages.single.sceneTarget,
+        const MapEventSceneTarget(sceneId: 'scene_rival'),
+      );
+    });
```

```diff
+    test('add condition refuses preserved legacy condition', () {
+      final original = ScriptConditionFactory.allOf([
+        ScriptConditionFactory.flagIsSet('fact_started'),
+        ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
+      ]);
+      final event = _event(
+        page: MapEventPage(
+          pageNumber: 0,
+          condition: original,
+        ),
+      );
+      final contract = readEventBuilderContractFromMapEvent(event);
+
+      expect(
+        () => addEventBuilderCondition(
+          contract,
+          EventBuilderConditionBinding.factIsFalse('fact_blocked'),
+        ),
+        throwsUnsupportedError,
+      );
+    });
```

```diff
+    test('remove condition refuses preserved legacy condition', () {
+      final original = ScriptConditionFactory.allOf([
+        ScriptConditionFactory.flagIsSet('fact_started'),
+        ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
+      ]);
+      final event = _event(
+        page: MapEventPage(
+          pageNumber: 0,
+          condition: original,
+        ),
+      );
+      final contract = readEventBuilderContractFromMapEvent(event);
+
+      expect(
+        () => removeEventBuilderCondition(contract, 0),
+        throwsUnsupportedError,
+      );
+    });
```

```diff
+    test('keeps fully supported conditions editable', () {
+      final original = ScriptConditionFactory.allOf([
+        ScriptConditionFactory.flagIsSet('fact_started'),
+        ScriptConditionFactory.not(
+          ScriptConditionFactory.eventIsConsumed('evt_rival'),
+        ),
+      ]);
+      final event = _event(
+        page: MapEventPage(
+          pageNumber: 0,
+          condition: original,
+        ),
+      );
+      final contract = readEventBuilderContractFromMapEvent(event);
+
+      final withCondition = addEventBuilderCondition(
+        contract,
+        EventBuilderConditionBinding.factIsFalse('fact_blocked'),
+      );
+      final removedFirst = removeEventBuilderCondition(withCondition, 0);
+      final updated = applyEventBuilderContractToMapEvent(
+        event,
+        removedFirst.copyWith(
+          sceneAction: EventBuilderSceneActionBinding(sceneId: 'scene_rival'),
+        ),
+      );
+
+      expect(contract.legacyConditionToPreserve, isNull);
+      expect(updated.pages.single.condition, isNot(original));
+      expect(updated.pages.single.condition?.type, ScriptConditionType.allOf);
+      expect(updated.pages.single.condition?.children, [
+        ScriptConditionFactory.not(
+          ScriptConditionFactory.eventIsConsumed('evt_rival'),
+        ),
+        ScriptConditionFactory.flagIsUnset('fact_blocked'),
+      ]);
+    });
```

## TDD RED

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_authoring_operations_test.dart
```

Sortie utile :

```text
+6 -1: Event Builder authoring operations preserves mixed supported and legacy condition when applying [E]
Expected: ScriptCondition(type: allOf, ... flagIsSet + variableEquals ...)
Actual: <null>

+6 -2: Event Builder authoring operations add condition refuses preserved legacy condition [E]
Expected: throws UnsupportedError
Actual: returned EventBuilderContractView

+6 -3: Event Builder authoring operations remove condition refuses preserved legacy condition [E]
Expected: throws UnsupportedError
Actual: returned EventBuilderContractView

Some tests failed.
```

Le RED prouve que les nouveaux tests capturaient bien le bug : la condition mixte n'était pas préservée et add/remove ne refusaient pas l'édition.

## TDD GREEN ciblé

Commande :

```bash
cd packages/map_core
dart format lib/src/authoring/event_builder_authoring_operations.dart test/event_builder_authoring_operations_test.dart
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart
```

Sortie :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
00:00 +18: test/event_builder_authoring_operations_test.dart: Event Builder authoring operations keeps malformed legacy conditions as diagnostic instead of crashing
00:00 +18: All tests passed!
```

## Validation complète map_core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact
```

Sortie utile :

```text
00:08 +2548: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel actor display reports missing stage point and does not invent coordinates
00:08 +2549: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel actor display reports missing stage point and does not invent coordinates
00:08 +2549: All tests passed!
EXIT_CODE=0
```

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Build :

```text
Pas de build Flutter lancé : le lot touche uniquement `packages/map_core`, package Dart pur.
La validation build pertinente pour ce périmètre est `dart test` complet + `dart analyze`.
Le prompt interdit aussi build_runner et generated files.
```

## Evidence Pack

### Gate final

Commande :

```bash
git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check
```

Sortie :

```text
 M packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
 M packages/map_core/test/event_builder_authoring_operations_test.dart
?? reports/narrativeStudio/events/ns_event_02_bis_mixed_legacy_condition_preservation.md
 .../event_builder_authoring_operations.dart        |  54 ++++++++--
 .../event_builder_authoring_operations_test.dart   | 116 +++++++++++++++++++++
 2 files changed, 160 insertions(+), 10 deletions(-)
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
```

`git diff --check` n'a produit aucune sortie.

Commande anti-scope :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_02_bis_mixed_legacy_condition_preservation.md
```

Le contenu complet du fichier créé est le présent rapport.

### Fichiers modifiés

```text
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
reports/narrativeStudio/events/ns_event_02_bis_mixed_legacy_condition_preservation.md
```

### Fichiers supprimés

```text
<aucun>
```

### Anti-scope

Non modifiés par ce lot :

```text
packages/map_editor
packages/map_runtime
packages/map_gameplay
packages/map_battle
examples
assets
selbrume
pubspec.yaml
```

### Commandes de preuve

Commandes lancées :

```bash
cd packages/map_core && dart test --reporter=compact test/event_builder_authoring_operations_test.dart
cd packages/map_core && dart format lib/src/authoring/event_builder_authoring_operations.dart test/event_builder_authoring_operations_test.dart
cd packages/map_core && dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart
cd packages/map_core && dart test --reporter=compact
cd packages/map_core && dart analyze
```

Résultats :

```text
RED ciblé : 3 échecs attendus sur le bug et les garde-fous.
GREEN ciblé : +18 All tests passed.
Suite complète map_core : +2549 All tests passed, EXIT_CODE=0.
Analyse map_core : No issues found.
```

## Impact fonctionnel

Ce bis protège le chemin NS-EVENT-02 sans ajouter de nouvelle feature.

Cas maintenant sûr :

```dart
ScriptConditionFactory.allOf([
  ScriptConditionFactory.flagIsSet('fact_started'),
  ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
]);
```

Lecture :

```text
conditions:
- factIsTrue('fact_started')

diagnostics:
- unsupportedLegacyCondition

legacyConditionToPreserve:
- condition originale complète
```

Application sans remplacement explicite :

```text
updated.pages.single.condition == original
```

Tentative d'édition partielle :

```text
addEventBuilderCondition(...) -> UnsupportedError
removeEventBuilderCondition(...) -> UnsupportedError
```

## Limites conservées

- Pas d'API `replaceAllEventBuilderConditions` créée.
- Pas de Story Step condition runtime.
- Pas de read model UI.
- Pas d'Event Builder UI.
- Pas de runtime bridge.
- Pas de migration JSON.
- Pas de modification Selbrume.
- Pas de support supplémentaire de `ScriptConditionType`.

## Prochaines étapes proposées

Pour NS-EVENT-03 ou un lot UI futur :

```text
Si legacyConditionToPreserve != null :
- afficher la condition comme verrouillée / partiellement lisible ;
- ne pas proposer add/remove classique ;
- proposer plus tard une action explicite "Remplacer toute la condition" si le produit le veut ;
- garder le diagnostic no-code indiquant qu'une partie legacy est préservée.
```

## Verdict des passes

| Passe | Verdict |
|---|---|
| Audit / Architecture | Le bug est réel : l'ancienne règle `conditions.isEmpty` ne couvre pas le mixed legacy. |
| Implémentation | Patch minimal dans `map_core` authoring operations, pas de nouveau modèle. |
| Tests | RED observé, puis GREEN ciblé avec 4 tests ajoutés. |
| Build / Validation | `dart test` complet map_core et `dart analyze` passent. |
| Critique finale | Scope respecté ; la seule limite restante est volontaire : pas de replace-all. |

## Auto-critique finale

Ce qui est bien couvert :

- condition mixte supportée + legacy ;
- préservation de la condition originale complète à l'application ;
- refus d'add/remove quand legacy est préservé ;
- non-régression sur conditions entièrement supportées ;
- non-régression sur condition legacy malformed existante via la suite ciblée.

Ce qui n'est pas couvert volontairement :

- UI verrouillée côté Event Builder ;
- remplacement explicite complet d'une condition legacy ;
- nouvelles familles de conditions ;
- runtime Event -> Scene.

Risque restant :

- `EventBuilderContractView.copyWith(clearLegacyConditionToPreserve: true)` existe déjà et peut être appelé manuellement par un futur code. Le garde-fou ajouté protège les opérations publiques `addEventBuilderCondition` et `removeEventBuilderCondition`, conformément au bis. Un futur lot de replace-all devra encadrer explicitement ce chemin.

Critique du prompt :

- Le prompt est cohérent avec l'état du repo et le bug réel.
- Le choix `throwsUnsupportedError` est adapté à une API core MVP sans transaction UI.
- Le prompt a raison de ne pas demander une compensation UI maintenant : ce serait NS-EVENT-03 ou un lot dédié.
- La seule ambiguïté est le mot "expose les bindings supportés pour information" : le core expose bien les bindings, mais le futur UI devra éviter de les présenter comme pleinement éditables.
