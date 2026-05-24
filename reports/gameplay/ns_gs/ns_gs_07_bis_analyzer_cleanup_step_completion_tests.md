# NS-GS-07-bis — Analyzer Cleanup for Step Completion Tests

---

## 1. Résumé exécutif

Remplacement des 2 imports relatifs (`../lib/...`) par des imports `package:` dans `scenario_complete_step_test.dart`. Les diagnostics `avoid_relative_lib_imports` sont supprimés. Aucune logique modifiée. 8 tests passent. 0 diagnostic analyzer pointe vers le fichier modifié.

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (684 lignes).

Statut initial de NS-GS-07 : ✅ fait.

NS-GS-07-bis est un micro-lot de nettoyage post NS-GS-07.

---

## 3. Audit initial

### Imports fautifs

```dart
// scenario_complete_step_test.dart (lignes 5-6 avant correction)
import '../lib/src/application/global_story_chapter_runtime.dart';
import '../lib/src/application/map_entity_runtime_predicate_evaluator.dart';
```

Ces imports relatifs vers `lib/` déclenchent `avoid_relative_lib_imports`.

### Convention repo

Le test voisin `map_entity_runtime_predicate_evaluator_test.dart` utilise le même pattern relatif (lignes 4-5). Ce pattern est pré-existant et hors scope de ce lot.

La correction propre : remplacer par des imports `package:` vers les fichiers src internes. Les classes ne sont pas exportées depuis le barrel `map_runtime.dart`, mais elles sont accessibles via `package:map_runtime/src/...` pour les tests du même package.

---

## 4. Correction appliquée

```diff
-import '../lib/src/application/global_story_chapter_runtime.dart';
-import '../lib/src/application/map_entity_runtime_predicate_evaluator.dart';
+import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
+import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
```

---

## 5. Fichiers modifiés / créés

| Action | Fichier | Détail |
|---|---|---|
| MODIFIÉ | `packages/map_runtime/test/scenario_complete_step_test.dart` | 2 imports remplacés |
| CRÉÉ | `reports/gameplay/ns_gs_07_bis_analyzer_cleanup_step_completion_tests.md` | Ce rapport |
| MODIFIÉ | `MVP Selbrume/road_map.md` | Section NS-GS-07-bis ajoutée |

---

## 6. Tests exécutés

```bash
cd packages/map_runtime && flutter test test/scenario_complete_step_test.dart
```

---

## 7. Résultats des tests

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

---

## 8. Résultat analyzer

```bash
cd packages/map_runtime && flutter analyze
```

Résultat :

```text
352 issues found. (ran in 1.7s)
```

Diagnostics pointant vers `scenario_complete_step_test.dart` : **0**.

Confirmation :

```bash
$ flutter analyze 2>&1 | grep "scenario_complete_step"
(aucune sortie — 0 résultat)
```

Tous les 352 issues sont pré-existants (info-level `prefer_const_constructors` dans d'autres fichiers).

---

## 9. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun code de prod modifié | ✅ |
| Aucune logique de test modifiée | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Aucun id Selbrume hardcodé | ✅ |
| completeStep inchangé | ✅ |
| kScenarioActionCompleteStep inchangé | ✅ |
| build_runner non lancé | ✅ |

---

## 10. Mise à jour road_map.md

Section « Mise à jour NS-GS-07-bis » ajoutée.

Prochain lot confirmé : 🔜 NS-GS-08 — NPC Interaction → Scene Authoring Readiness.

---

## 11. Limites et non-objectifs

```text
Le test pré-existant map_entity_runtime_predicate_evaluator_test.dart
utilise aussi des imports relatifs ../lib/... mais ce n'est pas dans le scope
de ce lot (fichier pré-existant, pas introduit par NS-GS-07).
```

---

## 12. Prochain lot recommandé

```text
NS-GS-08 — NPC Interaction → Scene Authoring Readiness
```

---

## 13. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre)
```

### Git diff --check final

```bash
$ git diff --check
EXIT:0
```

### Git diff --stat final

```bash
$ git diff --stat
 MVP Selbrume/road_map.md                                  | 15 +++++++++++++++
 .../map_runtime/test/scenario_complete_step_test.dart     |  4 ++--
 2 files changed, 17 insertions(+), 2 deletions(-)
```

### Git diff --name-only final

```bash
$ git diff --name-only
MVP Selbrume/road_map.md
packages/map_runtime/test/scenario_complete_step_test.dart
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M "MVP Selbrume/road_map.md"
 M packages/map_runtime/test/scenario_complete_step_test.dart
?? reports/gameplay/ns_gs_07_bis_analyzer_cleanup_step_completion_tests.md
```

### Confirmations

```text
Aucune logique modifiée.
Aucun code de prod modifié.
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
0 diagnostic analyzer pointe vers scenario_complete_step_test.dart.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 14. Auto-review

| Question | Réponse |
|---|---|
| Imports relatifs supprimés ? | ✅ |
| avoid_relative_lib_imports supprimé ? | ✅ (0 résultat grep) |
| Tests passent ? | ✅ 8/8 |
| Analyze exécuté ? | ✅ 352 issues pré-existants |
| 0 diagnostic sur le fichier modifié ? | ✅ |
| Code de prod inchangé ? | ✅ |
| Logique de test inchangée ? | ✅ |
| road_map.md mis à jour ? | ✅ |
| Rapport créé ? | ✅ |
| Aucune fixture Selbrume ? | ✅ |
| NS-GS-08 recommandé ? | ✅ |

---

*Fin du document NS-GS-07-bis.*
