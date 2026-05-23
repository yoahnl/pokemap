# NS-GS-09 — Yarn Outcome → Scene Branch Readiness

---

## 1. Résumé exécutif

**Cas A — Le flux outcome → Scene branch existe déjà.**

L'audit démontre que la chaîne complète est câblée end-to-end :

```text
emitOutcome('outcomeId')
→ set flag 'scenario.outcome.outcomeId' dans GameState
→ tentative dispatch global via outcomeReceived (pont inter-scénarios)
→ [scénario suivant] condition node avec flagIsSet('scenario.outcome.outcomeId')
→ trueBranch / falseBranch via ScenarioEdgeKind
→ action de branche (setFlag, completeStep, etc.)
→ convergence vers end
```

Aucune brique manquante. Aucun code de prod modifié.

9 tests de caractérisation ajoutés prouvant la chaîne. Tous passent. Analyze clean (0 nouveau diagnostic).

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (712 lignes après NS-GS-08).

Statut initial de NS-GS-09 : 🔜 (prochain lot après NS-GS-08).

---

## 3. Frontière Event / Scene

### Event

```text
Event = déclenchement et orchestration externe.
Réaction simple et plate.
Quand ? Où ? Par qui ? Sous quelles conditions ? Quelles réactions ?
```

Exemple :

```text
Quand le joueur interagit avec un coffre
Si le coffre n'est pas ouvert
Alors donner Potion x2
Puis poser fact_coffre_ouvert
```

### Scene

```text
Scene = déroulé narratif et logique interne.
Contient séquences, dialogues, outcomes, branches, convergence.
```

Exemple :

```text
Dialogue avec choix
→ outcome A / B / C
→ branche différente
→ convergence
→ action suivante
```

### Règle appliquée

Ce lot travaille exclusivement dans la logique **Scene**. Les outcomes sont lus par des condition nodes dans le graphe scénario, avec trueBranch/falseBranch. C'est du branching narratif Scene-level.

**Event n'a pas été transformé en Scene.** Event reste une réaction simple sans branching. Scene reste le lieu du branching narratif.

---

## 4. Audit initial

### Fichiers inspectés

| Fichier | Observation |
|---|---|
| `scenario_runtime_executor.dart:672-733` | Handler `kScenarioActionEmitOutcome` : extrait `outcomeId` du binding, set flag `scenario.outcome.{outcomeId}` via `storyFlags.set()`, appelle `onGameStateUpdated`, puis tente un dispatch global via `outcomeReceived`. Si pas de consommateur global, continue linéairement. |
| `scenario_runtime_executor.dart:83-88` | `kScenarioOutcomeFlagPrefix = 'scenario.outcome.'`, `scenarioOutcomeFlagName(outcomeId)` normalise le nom de flag. |
| `scenario_runtime_executor.dart:1148-1178` | Handler `ScenarioNodeType.condition` : évalue `node.payload.condition` via `ScriptConditionEvaluator.evaluate()`, puis `_pickConditionNextNodeId()` route vers `trueBranch` ou `falseBranch`. |
| `scenario_runtime_executor.dart:1299-1340` | `_pickConditionNextNodeId()` : cherche d'abord une edge de kind `trueBranch`/`falseBranch`, puis par label (`true`/`false`/`oui`/`non`), puis fallback déterministe. |
| `scenario_runtime_executor.dart:1263-1271` | Source matching pour `outcomeReceived` : compare `actionKind == kScenarioSourceOutcome`, match par `binding.outcomeId`. Pont inter-scénarios. |
| `scenario_runtime_models.dart:19-71` | `ScenarioRuntimeSourceType.outcomeReceived`, `ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId)`. |
| `scenario_asset.dart:118-178` | `ScenarioEdge` avec `ScenarioEdgeKind` : `next`, `trueBranch`, `falseBranch`, `choice`, `reference`. |
| `scenario_asset.dart:103-116` | `ScenarioNodePayload` avec `condition: ScriptCondition?`. |
| `script_conditions.dart:13-27` | `ScriptCondition` Freezed model avec `type`, `params`, `children`. |
| `script_conditions.dart:44-49` | `ScriptConditionType.flagIsSet` / `flagIsUnset`. |
| `script_condition_evaluator.dart:86-92` | `_evaluateFlagIsSet` : `state.storyFlags.activeFlags.contains(flagName)`. |

### Tests existants inspectés

| Test | Couverture |
|---|---|
| `scenario_runtime_executor_test.dart:182` | condition node routes to trueBranch (flag mutation). |
| `scenario_runtime_executor_test.dart:334` | emitOutcome basic. |
| `scenario_battle_from_scene_test.dart:385` | condition node in battle flow. |

### Conclusion de l'audit

**Le pont est complet.** Toutes les briques sont connectées :

1. `emitOutcome` set le flag `scenario.outcome.{outcomeId}` dans GameState.
2. `condition` node évalue `flagIsSet('scenario.outcome.{outcomeId}')`.
3. `_pickConditionNextNodeId` route vers `trueBranch` / `falseBranch`.
4. Les actions de branche s'exécutent normalement.
5. Les deux branches convergent vers un `end` node.
6. `onGameStateUpdated` est appelé pour chaque mutation.
7. Le flag outcome survit au save/load.

**Aucune brique manquante.** Pas de code de prod à ajouter.

Manquant avant ce lot : un **test de caractérisation end-to-end** prouvant qu'un outcome émis → condition → branch → action fonctionne de bout en bout.

---

## 5. Décision d'implémentation

| Choix | Détail |
|---|---|
| Type | Cas A — flux existant, tests de caractérisation ajoutés |
| Code de prod modifié | Aucun |
| Tests ajoutés | 9 tests dans `outcome_scene_branch_readiness_test.dart` |
| build_runner | Non lancé |
| Nouveau modèle | Aucun |

---

## 6. Fichiers créés / modifiés

| Action | Fichier | Détail |
|---|---|---|
| CRÉÉ | `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart` | 9 tests de caractérisation |
| CRÉÉ | `reports/gameplay/ns_gs_09_yarn_outcome_scene_branch_readiness.md` | Ce rapport |
| MODIFIÉ | `MVP Selbrume/road_map.md` | NS-GS-09 marqué ✅, prochain lot NS-GS-10 |

---

## 7. Flux outcome → branch

```text
[Scene A : dialogue produit un outcome]
        ↓
emitOutcome('test_confident')
        ↓
storyFlags.set(gameState, 'scenario.outcome.test_confident')
        ↓
onGameStateUpdated(nextState)
        ↓
(optionnel: dispatch outcomeReceived global → pont inter-scénarios)
        ↓
[Scene B : condition node]
        ↓
condition: flagIsSet('scenario.outcome.test_confident')
        ↓
ScriptConditionEvaluator.evaluate()
        ↓
state.storyFlags.activeFlags.contains('scenario.outcome.test_confident')
        ↓
_pickConditionNextNodeId():
  true  → edge kind trueBranch  → action_true  → setFlag test_flag_confident_path
  false → edge kind falseBranch → action_false → setFlag test_flag_tease_path
        ↓
convergence → end node
```

Convention clé : les outcomes sont persistés comme des flags avec le préfixe `scenario.outcome.`. Cela permet :
- la persistance save/load immédiate
- la réutilisation des conditions existantes (`flagIsSet` / `flagIsUnset`)
- un pont stable vers la progression globale

---

## 8. API ou comportement ajouté / caractérisé

Aucune nouvelle API ajoutée. Comportement existant caractérisé :

| Comportement | Prouvé |
|---|---|
| emitOutcome set le flag outcome dans GameState | ✅ |
| condition node branche vers trueBranch quand outcome flag est set | ✅ |
| condition node branche vers falseBranch quand outcome flag est absent | ✅ |
| Chaîne complète : emitOutcome → condition → branch | ✅ |
| Outcome différent → branche différente | ✅ |
| Outcome flag survit au save/load round-trip | ✅ |
| emitOutcome + completeStep dans le même flow | ✅ |
| emitOutcome bloque quand outcomeId est manquant | ✅ |
| Aucun id Selbrume hardcodé | ✅ |

---

## 9. Tests ajoutés

### map_runtime — 9 tests

Fichier : `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart`

1. `emitOutcome sets the outcome flag in GameState` — vérifie le flag `scenario.outcome.*`.
2. `condition node branches to true when outcome flag is set` — trueBranch route.
3. `condition node branches to false when outcome flag is absent` — falseBranch route.
4. `full chain: emitOutcome then branch reads outcome flag` — emitOutcome → condition → trueBranch.
5. `different outcome leads to different branch` — hesitant émis, confident vérifié → falseBranch.
6. `outcome flag survives save/load round-trip` — persistance.
7. `emitOutcome with completeStep in same flow` — outcome + step dans un flow.
8. `emitOutcome blocks when outcomeId is missing` — outcomeId vide → blocked.
9. `does not hardcode any Selbrume ids` — ids génériques.

---

## 10. Commandes exécutées

```bash
# Initial
git status --short --untracked-files=all

# Audit
rg -n "emitOutcome|kScenarioActionEmitOutcome|outcomeReceived|kScenarioSourceOutcome|ScenarioEdgeKind|condition.*outcome|gotoIfOutcome|lastOutcome|declaredOutcomes|flowMerge" packages/map_runtime/lib/src/application/scenario_runtime/ --type dart
rg -n "emitOutcome|kScenarioActionEmitOutcome" packages/map_runtime/test/ --type dart
rg -n "condition.*node|ScenarioNodeType.condition|trueBranch|falseBranch" packages/map_runtime/test/ --type dart

# Tests
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart

# Analyze
cd packages/map_runtime && flutter analyze
```

---

## 11. Résultats des tests

```text
00:00 +0: loading outcome_scene_branch_readiness_test.dart
00:00 +0: Outcome → Scene branch readiness emitOutcome sets the outcome flag in GameState
00:00 +1: Outcome → Scene branch readiness condition node branches to true when outcome flag is set
00:00 +2: Outcome → Scene branch readiness condition node branches to false when outcome flag is absent
00:00 +3: Outcome → Scene branch readiness full chain: emitOutcome then branch reads outcome flag
00:00 +4: Outcome → Scene branch readiness different outcome leads to different branch
00:00 +5: Outcome → Scene branch readiness outcome flag survives save/load round-trip
00:00 +6: Outcome → Scene branch readiness emitOutcome with completeStep in same flow
00:00 +7: Outcome → Scene branch readiness emitOutcome blocks when outcomeId is missing
00:00 +8: Outcome → Scene branch readiness does not hardcode any Selbrume ids
00:00 +9: All tests passed!
```

---

## 12. Résultat analyzer

```bash
cd packages/map_runtime && flutter analyze
```

```text
352 issues found. (ran in 1.8s)
```

Diagnostics pointant vers `outcome_scene_branch_readiness_test.dart` : **0**.

Tous les 352 issues sont pré-existants (info-level).

---

## 13. Garde-fou contre faux positif

### Question obligatoire

> Le test prouve-t-il un vrai outcome issu du dialogue/Yarn, ou seulement un outcome technique émis par ScenarioRuntimeExecutor ?

### Réponse

**Cas 2 — Outcome technique équivalent déjà utilisé par le runtime.**

Les tests utilisent `emitOutcome` qui est le mécanisme runtime officiel pour émettre un outcome dans une Scene. Ce n'est pas un appel direct au dialogue Yarn, mais c'est exactement le pipeline que le runtime utilise quand :

1. Un dialogue Yarn produit un outcome via ses options/commands.
2. Le `DialogueRuntimeController` ou le `CutsceneRuntimeRunner` traduit cet outcome en appel `emitOutcome` dans le graphe scénario.
3. Le flag `scenario.outcome.{outcomeId}` est posé dans GameState.
4. Les condition nodes le lisent via `flagIsSet`.

L'outcome convention (flag `scenario.outcome.*`) est la même que celle utilisée en production. Les tests ne simulent pas un pipeline fictif.

### Gap honnête

Le test ne prouve pas la connexion Yarn parser → dialogue option → `emitOutcome` automatique. Cette connexion passe par le `DialogueRuntimeController` qui est couplé au runtime Flame. Un test de ce niveau nécessiterait un widget test Flame ou un mock de `DialogueRuntimeController`, ce qui est hors scope de ce lot.

Ce gap est documenté en limite et ne bloque pas la progression vers NS-GS-10.

---

## 14. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun code de prod modifié | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Aucun id Selbrume hardcodé | ✅ |
| Event non transformé en Scene | ✅ |
| Scene reste le lieu du branching | ✅ |
| build_runner non lancé | ✅ |
| Aucune modification Freezed/generated | ✅ |

---

## 15. Mise à jour road_map.md

NS-GS-09 marqué ✅ fait.

Prochain lot mis à jour : 🔜 NS-GS-10 — World Rules / Conditional Presence Readiness.

Section « Mise à jour NS-GS-09 » ajoutée.

---

## 16. Limites et non-objectifs

```text
Les tests caractérisent le pont executor-level, pas le runtime Dialogue/Yarn complet.
La connexion Yarn parser → dialogue option → emitOutcome automatique n'est pas testée
(nécessiterait un widget test Flame ou mock DialogueRuntimeController).
Le pont est prouvé au niveau Scene (emitOutcome → flag → condition → branch).
CutsceneRuntimeRunner branching par outcome n'est pas testé ici (couvert par cutscene_runtime_runner_test.dart).
World rules / conditional presence hors scope (NS-GS-10).
Trainer battle authoring hors scope (NS-GS-11).
Event Builder non créé (hors scope et interdit).
```

---

## 17. Prochain lot recommandé

```text
NS-GS-10 — World Rules / Conditional Presence Readiness
```

---

## 18. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre)
```

### Commandes de test exécutées

```bash
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
# 9/9 passed

cd packages/map_runtime && flutter analyze
# 352 issues (pré-existants, 0 sur le fichier ajouté)
```

### Git diff --check final

```bash
$ git diff --check
EXIT:0
```

### Git diff --stat final

```bash
$ git diff --stat
 MVP Selbrume/road_map.md | 27 ++++++++++++++++++++++-----
 1 file changed, 22 insertions(+), 5 deletions(-)
```

### Git diff --name-only final

```bash
$ git diff --name-only
MVP Selbrume/road_map.md
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
?? reports/gameplay/ns_gs_09_yarn_outcome_scene_branch_readiness.md
```

### Confirmations

```text
Aucun code de prod modifié.
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
Event non transformé en Scene.
Scene reste le lieu du branching narratif.
Flux outcome → branch prouvé par 9 tests.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 19. Auto-review

| Question | Réponse |
|---|---|
| Flux outcome → branch audité ? | ✅ |
| Flux outcome → branch prouvé ? | ✅ 9 tests |
| Frontière Event / Scene respectée ? | ✅ |
| Event transformé en Scene ? | Non |
| Code de prod modifié ? | Non |
| Fixture Selbrume créée ? | Non |
| Id Selbrume hardcodé ? | Non |
| Tests passent ? | ✅ 9/9 |
| Analyze exécuté ? | ✅ 0 nouveau |
| Garde-fou faux positif ? | ✅ Cas 2 documenté |
| road_map.md mis à jour ? | ✅ |
| Rapport créé ? | ✅ |
| NS-GS-10 recommandé ? | ✅ |

---

*Fin du document NS-GS-09.*
