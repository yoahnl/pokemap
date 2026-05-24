# NS-GS-07 — Step Completion / Progression Hooks V0

---

## 1. Résumé exécutif

Ce lot ajoute la mécanique générique permettant de marquer une étape narrative comme complétée depuis le runtime narratif.

Deux couches livrées :

1. **Mutation pure** `GameStateMutations.completeStep` dans `map_gameplay` — ajoute un `stepId` à `PlayerProgression.completedStepIds`. Idempotente.
2. **Action narrative** `kScenarioActionCompleteStep` dans `map_runtime` — le ScenarioRuntimeExecutor lit `stepId` depuis `payload.params` et applique la mutation.

Le système de predicates existant (`MapEntityRuntimePredicateEvaluator`) lit déjà `completedStepIds` pour `stepCompleted` / `stepNotCompleted`. La chaîne complète est testée : completeStep → predicate `stepCompleted` vrai, predicate `stepNotCompleted` faux.

22 tests passent (14 gameplay + 8 runtime). Analyze clean (0 nouveau warning). Aucun id Selbrume hardcodé.

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (670 lignes).

Statut initial de NS-GS-07 : 🔜 (prochain lot recommandé par NS-GS-06-bis).

---

## 3. Audit initial

### Modèle existant

| Élément | Fichier | Observation |
|---|---|---|
| `PlayerProgression.completedStepIds` | `save_data.dart:202` | `@Default([]) List<String>` — Freezed, avec `copyWith`. Prêt à l'emploi. |
| `GameState.progression` | `game_state.dart:92` | `PlayerProgression` avec `copyWith`. |
| `PlayerProgression.normalized()` | `save_data.dart:223` | Appelle `_normalizeUniqueStringsPreserveOrder(completedStepIds)` — déduplique déjà. |
| `saveDataFromGameState` | `game_state_persistence.dart` | Sérialise `progression` avec `completedStepIds`. |
| `gameStateFromSaveData` | `game_state_persistence.dart` | Désérialise `PlayerProgression.fromJson`. |
| `MapEntityRuntimePredicateKind.stepCompleted` | `map_entity_payloads.dart:59-60` | Enum déjà défini. |
| `MapEntityRuntimePredicateKind.stepNotCompleted` | `map_entity_payloads.dart:61-62` | Enum déjà défini. |
| `MapEntityRuntimePredicateEvaluator` | `map_entity_runtime_predicate_evaluator.dart:45-48` | Lit `_completedSteps.contains(ref)`. Prêt. |
| `createNewGameState` | `new_game_state_builder.dart:49` | Initialise `progression: const PlayerProgression()` → `completedStepIds: []`. |
| `GameStateMutations` patterns | `game_state_mutations.dart` | `setFlag`, `clearFlag`, `markEventConsumed`, `givePokemon`. Pattern identique. |
| `ScenarioRuntimeExecutor` patterns | `scenario_runtime_executor.dart` | `setFlag`, `clearFlag`, `givePokemon`. Pattern identique. |

### Conclusion audit

Tout le support modèle, persistence, et predicates existe déjà. Il manque uniquement :

1. La mutation pure `completeStep` dans `GameStateMutations`.
2. L'action runtime `kScenarioActionCompleteStep` dans `ScenarioRuntimeExecutor`.
3. Les tests de bout en bout.

Pas de modification Freezed, pas de build_runner, pas de nouveau modèle.

---

## 4. Décision d'implémentation

| Choix | Détail |
|---|---|
| Mutation | `GameStateMutations.completeStep(state, stepId)` |
| Package | `map_gameplay` (même fichier que `setFlag`, `givePokemon`) |
| Action runtime | `kScenarioActionCompleteStep = 'completeStep'` |
| Params | `payload.params['stepId']` (obligatoire) |
| Idempotence | Oui — vérification `contains` avant ajout |
| No-op sur blank | Oui — comme `setFlag` |
| Predicates | Déjà supportés : `stepCompleted` / `stepNotCompleted` lisent `completedStepIds` |
| Save/load | Déjà supporté : `PlayerProgression` sérialisé avec `completedStepIds` |
| build_runner | Non lancé |
| Nouveau modèle | Aucun |

---

## 5. Fichiers créés / modifiés

| Action | Fichier | Détail |
|---|---|---|
| MODIFIÉ | `packages/map_gameplay/lib/src/game_state_mutations.dart` | +27 lignes : méthode `completeStep` |
| MODIFIÉ | `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | +46 lignes : constante + handler `kScenarioActionCompleteStep` |
| MODIFIÉ | `packages/map_runtime/lib/map_runtime.dart` | +1 ligne : export `kScenarioActionCompleteStep` |
| CRÉÉ | `packages/map_gameplay/test/complete_step_test.dart` | 14 tests mutation pure |
| CRÉÉ | `packages/map_runtime/test/scenario_complete_step_test.dart` | 8 tests action runtime + predicates |
| CRÉÉ | `reports/gameplay/ns_gs_07_step_completion_progression_hooks.md` | Ce rapport |
| MODIFIÉ | `MVP Selbrume/road_map.md` | NS-GS-07 marqué ✅, section mise à jour |

---

## 6. API ajoutée

### Mutation pure (map_gameplay)

```dart
/// Marque une étape narrative comme complétée.
/// Idempotente. No-op si stepId vide/blanc.
GameState completeStep(GameState state, String stepId);
```

### Action narrative (map_runtime)

```dart
const String kScenarioActionCompleteStep = 'completeStep';
```

Paramètre : `payload.params['stepId']` (obligatoire).

---

## 7. Action narrative ajoutée

Action native `kScenarioActionCompleteStep` dans le `ScenarioRuntimeExecutor`.

L'action :
- Lit `stepId` depuis `payload.params['stepId']`
- Bloque si `stepId` est absent ou vide
- Applique `GameStateMutations.completeStep`
- Met à jour `context.gameState` et `onGameStateUpdated`
- Avance vers le nœud suivant ou termine le flow
- Est idempotente (calling twice is safe)

Alignée avec les patterns existants (`setFlag`, `clearFlag`, `givePokemon`).

---

## 8. Conditions / predicates vérifiés

Le système de predicates existant lit déjà `completedStepIds` :

```dart
// map_entity_runtime_predicate_evaluator.dart:45-48
MapEntityRuntimePredicateKind.stepCompleted =>
  _completedSteps.contains(ref),
MapEntityRuntimePredicateKind.stepNotCompleted =>
  !_completedSteps.contains(ref),
```

Tests ajoutés dans `scenario_complete_step_test.dart` :

- `completeStep feeds stepCompleted predicate` — vérifie que `evaluatePredicate(stepCompleted, 'test_step')` retourne `true` après `completeStep`.
- `uncompleted step feeds stepNotCompleted predicate` — vérifie que `evaluatePredicate(stepNotCompleted, 'test_step')` retourne `true` et `stepCompleted` retourne `false` quand la step n'est pas complétée.

La chaîne complète est prouvée : `completeStep` → `PlayerProgression.completedStepIds` → `MapEntityRuntimePredicateEvaluator.evaluatePredicate`.

---

## 9. Comportement couvert

| Comportement | Implémenté | Testé |
|---|---|---|
| Ajout step à completedStepIds vide | ✅ | ✅ |
| Trimming whitespace | ✅ | ✅ |
| No-op si stepId vide | ✅ | ✅ |
| No-op si stepId blank | ✅ | ✅ |
| Idempotence (pas de doublon) | ✅ | ✅ |
| Préservation steps existantes | ✅ | ✅ |
| Préservation party | ✅ | ✅ |
| Préservation bag | ✅ | ✅ |
| Préservation storyFlags | ✅ | ✅ |
| Préservation currentMapId et playerPosition | ✅ | ✅ |
| Préservation consumedEventIds | ✅ | ✅ |
| Aucun id Selbrume hardcodé | ✅ | ✅ |
| Save/load round-trip | ✅ | ✅ |
| Full flow createNewGameState → completeStep → save/load | ✅ | ✅ |
| Action runtime complète une step | ✅ | ✅ |
| Action runtime avance le graphe | ✅ | ✅ |
| Action runtime appelle onGameStateUpdated | ✅ | ✅ |
| Action runtime bloque sans stepId | ✅ | ✅ |
| Action runtime bloque si stepId blank | ✅ | ✅ |
| Action runtime idempotente | ✅ | ✅ |
| completeStep alimente stepCompleted predicate | ✅ | ✅ |
| Step non complétée alimente stepNotCompleted predicate | ✅ | ✅ |

---

## 10. Tests ajoutés

### map_gameplay (14 tests)

Fichier : `packages/map_gameplay/test/complete_step_test.dart`

### map_runtime (8 tests)

Fichier : `packages/map_runtime/test/scenario_complete_step_test.dart`

---

## 11. Commandes exécutées

```bash
# Tests gameplay
cd packages/map_gameplay && dart test test/complete_step_test.dart

# Analyze gameplay
cd packages/map_gameplay && dart analyze

# Tests runtime
cd packages/map_runtime && flutter test test/scenario_complete_step_test.dart

# Analyze runtime
cd packages/map_runtime && flutter analyze
```

---

## 12. Résultats des tests

### map_gameplay — 14/14

```text
00:00 +0: loading test/complete_step_test.dart
00:00 +0: GameStateMutations.completeStep adds a step id to empty completedStepIds
00:00 +1: GameStateMutations.completeStep trims whitespace
00:00 +2: GameStateMutations.completeStep is no-op for empty stepId
00:00 +3: GameStateMutations.completeStep is no-op for blank stepId
00:00 +4: GameStateMutations.completeStep is idempotent
00:00 +5: GameStateMutations.completeStep preserves existing completed steps
00:00 +6: GameStateMutations.completeStep preserves party
00:00 +7: GameStateMutations.completeStep preserves bag
00:00 +8: GameStateMutations.completeStep preserves storyFlags
00:00 +9: GameStateMutations.completeStep preserves currentMapId and playerPosition
00:00 +10: GameStateMutations.completeStep preserves consumedEventIds
00:00 +11: GameStateMutations.completeStep does not hardcode any Selbrume ids
00:00 +12: GameStateMutations.completeStep round-trips through save/load
00:00 +13: GameStateMutations.completeStep full flow: createNewGameState → completeStep → save/load
00:00 +14: All tests passed!
```

### map_gameplay — analyze

```text
Analyzing map_gameplay...
warning - pubspec.yaml:20:5 - invalid_dependency (pré-existant)
   info - test/los_detection_test.dart:8:24 - no_leading_underscores_for_local_identifiers (pré-existant)
2 issues found. (0 nouveau)
```

### map_runtime — 8/8

```text
00:00 +0: loading scenario_complete_step_test.dart
00:00 +0: ScenarioRuntimeExecutor - completeStep action completeStep action completes a step
00:00 +1: ScenarioRuntimeExecutor - completeStep action completeStep action advances the graph
00:00 +2: ScenarioRuntimeExecutor - completeStep action completeStep action calls onGameStateUpdated
00:00 +3: ScenarioRuntimeExecutor - completeStep action completeStep action blocks when stepId missing
00:00 +4: ScenarioRuntimeExecutor - completeStep action completeStep action blocks when stepId is blank
00:00 +5: ScenarioRuntimeExecutor - completeStep action completeStep action is idempotent when run twice
00:00 +6: ScenarioRuntimeExecutor - completeStep action completeStep feeds stepCompleted predicate
00:00 +7: ScenarioRuntimeExecutor - completeStep action uncompleted step feeds stepNotCompleted predicate
00:00 +8: All tests passed!
```

### map_runtime — analyze

```text
352 issues found. (0 nouveau — tous pré-existants info-level: prefer_const_constructors, avoid_relative_lib_imports, etc.)
```

2 nouvelles `avoid_relative_lib_imports` info-level dans le nouveau test — même pattern que le test pré-existant `map_entity_runtime_predicate_evaluator_test.dart`.

---

## 13. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun id Selbrume hardcodé | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Mécanique générique | ✅ |
| createNewGameState reste party vide, progression vide | ✅ |
| completeStep ne décide pas quelle step compléter | ✅ |
| whenCutsceneEnds existant non supprimé | ✅ |
| build_runner non lancé | ✅ |
| Aucune modification Freezed/generated | ✅ |

---

## 14. Mise à jour road_map.md

NS-GS-07 marqué ✅ fait.

Prochain lot mis à jour : 🔜 NS-GS-08 — NPC Interaction → Scene Authoring Readiness.

Section « Mise à jour NS-GS-07 » ajoutée.

---

## 15. Limites et non-objectifs

```text
Pas de limite party 6 modélisée — hors scope.
Pas de validation existence stepId dans un registre — hors scope.
Pas de UI step studio modifiée — hors scope.
Pas de migration / upgrade de step schema — pas nécessaire (pas de modification modèle).
whenCutsceneEnds conservé — pas supprimé.
Pas de validator narratif — reporté à NS-GS-13.
Pas de side quests — reporté à NS-GS-16.
```

---

## 16. Prochain lot recommandé

```text
NS-GS-08 — NPC Interaction → Scene Authoring Readiness
```

---

## 17. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre)
```

### Commandes de test exécutées

```bash
cd packages/map_gameplay && dart test test/complete_step_test.dart
# 14/14 passed

cd packages/map_gameplay && dart analyze
# 2 issues (pré-existants)

cd packages/map_runtime && flutter test test/scenario_complete_step_test.dart
# 8/8 passed

cd packages/map_runtime && flutter analyze
# 352 issues (pré-existants info-level, 0 nouveau warning)
```

### Git diff --check final

```bash
$ git diff --check
EXIT:0
```

### Git diff --stat final

```bash
$ git diff --stat
 MVP Selbrume/road_map.md                           | 26 +++++++++---
 .../map_gameplay/lib/src/game_state_mutations.dart | 27 +++++++++++++
 packages/map_runtime/lib/map_runtime.dart          |  1 +
 .../scenario_runtime_executor.dart                 | 46 ++++++++++++++++++++++
 4 files changed, 94 insertions(+), 6 deletions(-)
```

### Git diff --name-only final

```bash
$ git diff --name-only
MVP Selbrume/road_map.md
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M "MVP Selbrume/road_map.md"
 M packages/map_gameplay/lib/src/game_state_mutations.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
?? packages/map_gameplay/test/complete_step_test.dart
?? packages/map_runtime/test/scenario_complete_step_test.dart
?? reports/gameplay/ns_gs_07_step_completion_progression_hooks.md
```

### Confirmations

```text
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
createNewGameState inchangé.
completeStep est générique et idempotent.
whenCutsceneEnds existant non supprimé.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 18. Auto-review

| Question | Réponse |
|---|---|
| Mutation completeStep existe ? | ✅ `GameStateMutations.completeStep` |
| Générique ? | ✅ Aucun id Selbrume |
| Idempotente ? | ✅ Testé |
| Ajoute à completedStepIds ? | ✅ Testé |
| Préserve le reste ? | ✅ party, bag, flags, map, position, events |
| Save/load round-trip ? | ✅ Testé |
| Action narrative runtime ? | ✅ `kScenarioActionCompleteStep` |
| Action testée ? | ✅ 8 tests scénario |
| Predicates vérifiés ? | ✅ `stepCompleted` et `stepNotCompleted` testés |
| Tests gameplay passent ? | ✅ 14/14 |
| Tests runtime passent ? | ✅ 8/8 |
| Analyze clean ? | ✅ 0 nouveau warning |
| road_map.md mis à jour ? | ✅ |
| Rapport créé ? | ✅ |
| createNewGameState inchangé ? | ✅ |
| Aucune fixture Selbrume ? | ✅ |
| NS-GS-08 recommandé ? | ✅ |

---

*Fin du document NS-GS-07.*
