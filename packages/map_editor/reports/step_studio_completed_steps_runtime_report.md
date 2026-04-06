# Rapport : persistance runtime des steps Step Studio (`whenCutsceneEnds`)

**Date** : 2026-04-06  
**Portée** : `map_core`, `map_runtime`, libellés UI `map_editor`  
**Contrainte** : aucune opération Git d’écriture effectuée dans le cadre de ce travail.

---

## 1. Diagnostic initial

### 1.1 Symptômes observés (produit)

- Une step Step Studio peut déclarer une completion **`whenCutsceneEnds`** avec un **`cutsceneId`** (identifiant du scénario **local** / cutscene).
- Après exécution de cette cutscene jusqu’à la fin du graphe (nœud `end`), l’intention produit est : la step est **terminée** et **ne doit plus se rejouer** ; la **sauvegarde** doit refléter cet état.
- Comportement constaté avant correctif : la sauvegarde ne contenait **aucune** trace explicite de « step complétée » ; au rechargement ou au redéclenchement (`mapEnter`, trigger, interaction), la cutscene pouvait **repartir**.

### 1.2 Points d’intégration identifiés dans le codebase (audit)

| Sujet | Emplacement principal |
|--------|------------------------|
| Document Step Studio (JSON) | Métadonnée `authoring.stepStudioDocument` sur le scénario **`globalStory`**, parsé côté éditeur dans `parseStepStudioDocumentFromGlobalScenario` (`map_editor`, `step_studio_authoring.dart`). |
| Conditions d’activation des steps | Authoring + UI Step Studio ; **pas** d’évaluateur runtime dédié « step active » dans cette mission — le runtime existant pilote surtout les **scénarios** (`ScenarioRuntimeExecutor`). |
| Exécution des cutscenes (Scenario Graph) | `ScenarioRuntimeExecutor` (`map_runtime`) : sources `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived`. |
| Fin de cutscene interceptable | Lorsque le graphe atteint un nœud **`end`**, le statut retourné est **`ScenarioRuntimeExecutionStatus.reachedEnd`** avec un **`scenarioId`** non nul. |
| Sauvegarde | `SaveData` / `GameState` dans `map_core` ; conversion `gameStateFromSaveData` / `saveDataFromGameState` dans `game_state_persistence.dart` ; persistance fichier via `FileGameSaveRepository` + use cases (`map_runtime`). |
| `storyFlags`, `scriptVariables`, `consumedEventIds` | `GameState` : flags dans `StoryFlags` + liste `progression.storyFlags` (fusion à l’export save) ; variables dans `ScriptVariables` ; événements carte dans `consumedEventIds`. |
| Notion voisine « outcome scénario » | Flags `scenario.outcome.<id>` via `StoryFlagsManager` + `emitOutcome` dans le graphe — **distinct** des steps Step Studio. |

### 1.3 Cause exacte du bug

Le runtime **ne lisait pas** le document Step Studio pour :

1. **Écrire** un identifiant de step complétée dans l’état persistant lorsqu’un scénario local se termine (`reachedEnd`).
2. **Filtrer** les scénarios locaux déjà « consommés » par une step complétée lors d’un nouveau `dispatch` (sinon le premier scénario matchant repart).

Les champs `storyFlags` / `consumedEventIds` ne couvrent pas ce contrat sans duplication fragile : la progression Step Studio est un **contrat authoring** explicite (`step.id` + `completion.mode` + `cutsceneId`).

---

## 2. Architecture retenue

### 2.1 Principe

- **Source de vérité authoring** : JSON `authoring.stepStudioDocument` (même clé que l’éditeur), embarqué dans les métadonnées du scénario **`globalStory`**.
- **Persistance joueur** : nouvelle liste **`PlayerProgression.completedStepIds`** dans `map_core`, sérialisée dans `SaveData.progression` (JSON stable, débogable).
- **Runtime** (`map_runtime`) :
  - Construction d’un **index** `cutsceneScenarioId → stepId` pour les steps dont `completion.mode == whenCutsceneEnds` (parse JSON léger, **sans** dépendre de `map_editor`).
  - À chaque résultat **`reachedEnd`** : si le `scenarioId` est dans l’index, ajouter `stepId` à `completedStepIds` (idempotent).
  - À chaque **`dispatch`** (pas `dispatchContinuation`) : callback **`shouldSkipScenario`** sur le contexte d’exécution — si la step liée à cette cutscene est déjà complétée, **ignorer** ce scénario et tenter le suivant.

### 2.2 Pourquoi ne pas importer `map_editor` dans `map_runtime`

Éviter une dépendance lourde et les cycles ; le format JSON du document est **stable** et sérialisé par l’éditeur ; le runtime ne duplique que la **lecture minimale** des champs nécessaires (`steps[].id`, `completion.mode`, `completion.cutsceneId`).

### 2.3 Flux runtime — avant / après

**Avant**

1. Événement monde → `dispatch` → premier scénario local matchant → exécution jusqu’à dialogue / fin.
2. Nœud `end` → `reachedEnd` → **aucune** mise à jour de progression Step Studio.
3. Sauvegarde → pas de `completedStepIds`.

**Après**

1. Même chaîne, mais `dispatch` reçoit `shouldSkipScenario` : les cutscenes dont la step est dans `completedStepIds` sont **sautées**.
2. `reachedEnd` avec `scenarioId` = cutscene → recherche dans l’index → **`completedStepIds` mis à jour** dans `GameState`.
3. `saveDataFromGameState` inclut `progression.completedStepIds` → fichier JSON de sauvegarde.

---

## 3. Structures de données

### 3.1 `PlayerProgression` (`map_core`)

Nouveau champ :

- **`completedStepIds`** : `List<String>`, défaut `[]` — identifiants des steps Step Studio terminées côté runtime.

Sérialisation JSON : clé **`completedStepIds`** sous `progression`.

### 3.2 `StepCompletionCutsceneIndex` (`map_runtime`)

Type interne (fichier `step_studio_completion_runtime.dart`) :

- **`cutsceneScenarioIdToStepId`** : map `String → String` — pour chaque règle `whenCutsceneEnds`, la clé est l’id du **scénario local** (`cutsceneId` authoring), la valeur est le **`step.id`**.

Fonctions :

- **`buildStepCompletionCutsceneIndex(scenarios)`** — parcourt les scénarios `globalStory` avec métadonnée `authoring.stepStudioDocument`.
- **`appendCompletedStepIdIfAbsent`** — ajout idempotent à la liste.

### 3.3 `ScenarioRuntimeExecutionContext`

Nouveau champ optionnel :

- **`shouldSkipScenario`** : `bool Function(String scenarioId)?` — utilisé uniquement dans **`dispatch`**, pas dans **`dispatchContinuation`** (reprise de flow déjà engagé).

---

## 4. Fichiers modifiés ou ajoutés

| Fichier | Rôle |
|---------|------|
| `packages/map_core/lib/src/models/save_data.dart` | Champ `completedStepIds` sur `PlayerProgression`. |
| `packages/map_core/lib/src/models/save_data.*` (générés) | Régénération `build_runner`. |
| `packages/map_core/test/save_data_test.dart` | Tests sérialisation / défauts. |
| `packages/map_core/test/game_state_persistence_test.dart` | Round-trip `completedStepIds`. |
| `packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart` | **Nouveau** — index + helpers. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | `ScenarioRuntimeShouldSkipScenario`, champ contexte. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | Contournement des scénarios si `shouldSkipScenario` est vrai. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Contexte unifié, finalisation `reachedEnd`, cache d’index. |
| `packages/map_runtime/lib/map_runtime.dart` | Export `ScenarioRuntimeShouldSkipScenario`. |
| `packages/map_runtime/test/step_studio_completion_runtime_test.dart` | **Nouveau** — tests index / append. |
| `packages/map_runtime/test/scenario_runtime_executor_test.dart` | Test `shouldSkipScenario`. |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | Libellé **Cutscene Studio**. |
| `packages/map_editor/lib/src/ui/shared/top_toolbar.dart` | Tooltip Cutscene Studio. |

---

## 5. Extraits de code représentatifs

### 5.1 Modèle de sauvegarde (`map_core`)

```dart
// PlayerProgression : completedStepIds sérialisé sous progression.completedStepIds
@Default([]) List<String> completedStepIds,
```

### 5.2 Filtre + finalisation (`PlayableMapGame`)

- **`_buildScenarioRuntimeExecutionContext`** : passe `shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep`.
- **`_finalizeScenarioRuntimeResult`** : si `reachedEnd`, ajoute le `stepId` issu de l’index.

### 5.3 Exécuteur scénario

Après résolution d’une source valide, si `shouldSkipScenario(scenario.id)` retourne `true`, le candidat est ignoré et la boucle continue.

---

## 6. Cas couverts

- Step avec **`whenCutsceneEnds`** et **`cutsceneId`** = id du scénario local : à la fin du flow (`reachedEnd`), la step est enregistrée dans **`completedStepIds`**.
- Re-déclenchement (`mapEnter`, trigger, interaction) : le scénario local lié est **ignoré** si la step est déjà complétée.
- **Sauvegarde / chargement** : `completedStepIds` fait partie de `SaveData.progression` ; les saves sans clé obtiennent `[]` via les défauts JSON.
- **Idempotence** : `appendCompletedStepIdIfAbsent` évite les doublons.

---

## 7. Limites restantes

- **Autres modes de completion** Step Studio (`whenOutcomeEmitted`, `whenInteractionDone`, `whenFlagTrue`, `manual`) : **non** branchés automatiquement sur `completedStepIds` dans cette mission (seul `whenCutsceneEnds` + fin de graphe `reachedEnd` est traité).
- **Activation** des steps (ex. `atGameStart`, `afterPreviousStep`) : pas d’évaluateur runtime unifié des steps dans ce changement — le non-rejeu repose sur **skip** + **completedStepIds**.
- **Conflit** : deux steps déclarant la même `cutsceneId` en `whenCutsceneEnds` : la dernière occurrence lue **écrase** l’entrée dans la map (documenté dans le code ; cas authoring à éviter).
- **Cutscenes non pilotées par le Scenario Graph** (autre pipeline) : non concernées par `ScenarioRuntimeExecutor.reachedEnd`.

---

## 8. Tests ajoutés ou mis à jour

| Test | Package | Description |
|------|---------|-------------|
| `PlayerProgression` / `SaveData` defaults | `map_core` | Présence et round-trip de `completedStepIds`. |
| `game_state_persistence_test` | `map_core` | `completedStepIds` dans `gameStateFromSaveData` / `saveDataFromGameState`. |
| `buildStepCompletionCutsceneIndex` | `map_runtime` | Indexation `whenCutsceneEnds` depuis métadonnées global. |
| `appendCompletedStepIdIfAbsent` | `map_runtime` | Idempotence. |
| `shouldSkipScenario bypasses...` | `map_runtime` | Deux scénarios locaux : le premier skip, le second s’exécute. |

---

## 9. Résultats des tests (commandes exécutées)

```text
cd packages/map_core && dart test
# Résultat : All tests passed!

cd packages/map_runtime && flutter test
# Résultat : All tests passed!
```

*(Les sorties exactes peuvent varier selon la version du SDK ; l’état au moment du développement : succès complet.)*

---

## 10. Renommage UI demandé

- **`Cutscene Workspace`** → **`Cutscene Studio`** dans `editor_shell_page.dart`.
- Tooltip : **`Switch to Cutscene Studio`** dans `top_toolbar.dart`.

*(Une mention historique subsiste dans un rapport de lot sous `reports/lots/...` — non modifié ici car hors périmètre UI applicative.)*

---

## 11. Synthèse

Le correctif **matérialise** la promesse authoring « la step se complète quand la cutscene se termine » en :

1. **Persistant** les ids de steps dans **`progression.completedStepIds`** ;
2. **Empêchant** le redispatch des scénarios locaux correspondants une fois la step complétée ;
3. **Restant** aligné sur l’architecture existante (Scenario Graph, `SaveData`, pas de dépendance `map_editor` au runtime).
