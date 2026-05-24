# NS-GS-10 — World Rules / Conditional Presence Readiness

---

## 1. Résumé exécutif

**Cas A — Le flux GameState → World Rule → présence / dialogue existe déjà et est complet.**

L'audit démontre que la chaîne complète est câblée end-to-end :

```text
GameState (storyFlags, completedStepIds, completedCutsceneIds)
→ MapEntityRuntimePredicateEvaluator lit GameState
→ MapEntityNpcVisibilityRule (visibleWhen / hiddenWhen) décide la présence
→ MapEntityConditionalDialogue sélectionne le dialogue alternatif
→ resolveNpcDialogue retourne la première variante qui matche ou le défaut
→ isNpcPresentOnMap filtre les PNJ visibles
→ save/load préserve l'état identiquement
→ recalculation après mutation (setFlag / completeStep) change le résultat
```

Aucune brique manquante. Aucun code de prod modifié.

31 tests de caractérisation ajoutés prouvant la chaîne complète. Tous passent. Analyze clean (0 nouveau diagnostic).

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (728 lignes après NS-GS-09).

Statut initial de NS-GS-10 : 🔜 (prochain lot après NS-GS-09).

---

## 3. Frontière Event / Scene / World Rule

### Event

```text
Event = déclenchement et orchestration externe.
Réaction simple : quand ? où ? par qui ? sous quelles conditions ? quelles réactions ?
Un Event peut déclencher une Scene, une action simple ou un changement de monde.
```

### Scene

```text
Scene = déroulé narratif et logique interne.
Que se passe-t-il dans quel ordre ? Quel dialogue ? Quel outcome ? Quelle branche ?
Quelle action gameplay suit ? Où les branches convergent ?
```

### World Rule

```text
World Rule = projection passive de l'état du GameState sur le monde.
Ce qui est visible. Ce qui est caché. Ce qui est interactable.
Quel dialogue est utilisé. Comment le monde reflète les facts / steps / cutscenes / chapters.
```

### Règle stricte appliquée

```text
Event déclenche.
Scene déroule.
World Rule projette un état.
```

Ce lot travaille exclusivement sur **World Rule / conditional presence / conditional dialogue**.

**Event n'a pas été transformé en World Rule.** World Rule n'a pas été transformée en Scene. Les trois concepts restent séparés.

---

## 4. Audit initial

### Fichiers inspectés

| Fichier | Observation |
|---|---|
| `map_entity_payloads.dart:54-70` | `MapEntityRuntimePredicateKind` : 8 variants — storyFlagSet, storyFlagUnset, stepCompleted, stepNotCompleted, chapterCompleted, chapterNotCompleted, cutsceneCompleted, cutsceneNotCompleted. Complet. |
| `map_entity_payloads.dart:73-97` | `MapEntityRuntimePredicate` (kind + refId), `MapEntityNpcVisibilityRule` (mode + predicate), `MapEntityNpcVisibilityMode` (always, visibleWhen, hiddenWhen). Complet. |
| `map_entity_payloads.dart:102-132` | `MapEntityConditionalDialogue` (when: predicate, dialogue: DialogueRef), `MapEntityNpcData` (visibilityRule, conditionalDialogues, dialogue). Complet. |
| `map_entity_runtime_predicate_evaluator.dart:19-100` | `MapEntityRuntimePredicateEvaluator` : evaluatePredicate (switch sur 8 kinds), isNpcPresentOnMap (visibility rule), resolveNpcDialogue (première variante matchée, sinon défaut). Complet. |
| `global_story_chapter_runtime.dart` | `GlobalStoryChapterStepIndex` : isChapterCompleted (toutes steps du chapitre complétées), isChapterNotCompleted. Complet. |
| `npc_runtime_presence.dart` | `isNpcRuntimePresentOnMap` : combine évaluation de base (MapEntityRuntimePredicateEvaluator) + StepStudio world rules. Complet. |
| `step_studio_world_presence_runtime.dart` | `buildStepStudioWorldPresenceRuleList`, StepStudioWorldPresenceRule. Complet. |
| `game_state_mutations.dart` | `setFlag`, `completeStep`, `givePokemon`. Complet. |
| `game_state_persistence.dart` | `saveDataFromGameState`, `gameStateFromSaveData`, `normalizeLoadedGameState`. Complet. |

### Tests existants inspectés

| Test | Couverture |
|---|---|
| `map_entity_runtime_predicate_evaluator_test.dart` (6 tests) | storyFlagSet visibility, stepCompleted visibility, chapterCompleted, conditional dialogue resolution (match + fallback), cutsceneCompleted. |
| `npc_runtime_presence_test.dart` (5 tests) | Step completion → presence, GameplayWorldState filter, serialization round-trip, visibilityRule base. |
| `step_studio_save_reload_visibility_integration_test.dart` (1 test) | cutscene → step → save/reload → NPC absent. |
| `scenario_complete_step_test.dart` (2 tests) | stepCompleted/stepNotCompleted predicates après completeStep. |

### Conclusion de l'audit

**Le flux est complet.** Toutes les briques sont connectées :

1. `MapEntityRuntimePredicateEvaluator` évalue les 8 predicate kinds.
2. `isNpcPresentOnMap` applique la visibility rule (visibleWhen/hiddenWhen/always).
3. `resolveNpcDialogue` sélectionne le dialogue conditionnel (première variante matchée ou défaut).
4. `saveDataFromGameState` / `gameStateFromSaveData` préservent storyFlags, completedStepIds, completedCutsceneIds.
5. `GameStateMutations.setFlag` et `.completeStep` mutent l'état.
6. Recréer un `MapEntityRuntimePredicateEvaluator` avec le nouvel état donne le nouveau résultat.

**Gaps identifiés dans les tests existants :**

Manquant avant ce lot :
- `storyFlagUnset` predicate (aucun test)
- `cutsceneNotCompleted` predicate (aucun test)
- `chapterNotCompleted` predicate (aucun test)
- `stepNotCompleted` dans un scénario de visibility rule (pas en isolation)
- Conditional dialogue by step completion (non testé)
- Conditional dialogue by fact (non testé en isolation)
- First-match priority order (testé mais pas explicitement)
- Recalculation after mutation (setFlag → visibility change, completeStep → dialogue change)
- Save/load round-trip pour conditional dialogue

Tous ces gaps sont couverts par les 31 nouveaux tests.

---

## 5. Décision d'implémentation

| Choix | Détail |
|---|---|
| Type | Cas A — flux existant complet, tests de caractérisation ajoutés |
| Code de prod modifié | Aucun |
| Tests ajoutés | 31 tests dans `world_rules_conditional_presence_readiness_test.dart` |
| build_runner | Non lancé |
| Nouveau modèle | Aucun |

---

## 6. Fichiers créés / modifiés

| Action | Fichier | Détail |
|---|---|---|
| CRÉÉ | `packages/map_runtime/test/world_rules_conditional_presence_readiness_test.dart` | 31 tests de caractérisation |
| CRÉÉ | `reports/gameplay/ns_gs_10_world_rules_conditional_presence_readiness.md` | Ce rapport |
| MODIFIÉ | `MVP Selbrume/road_map.md` | NS-GS-10 marqué ✅, prochain lot NS-GS-11 |

---

## 7. Flux GameState → World Rule → monde

```text
[Mutation narrative]
setFlag('test_fact_enabled')  /  completeStep('test_step_done')
        ↓
GameState.storyFlags.activeFlags / progression.completedStepIds
        ↓
MapEntityRuntimePredicateEvaluator(gameState, chapterIndex)
        ↓
evaluatePredicate(MapEntityRuntimePredicate):
  storyFlagSet    → _flags.contains(refId)
  storyFlagUnset  → !_flags.contains(refId)
  stepCompleted   → _completedSteps.contains(refId)
  stepNotCompleted → !_completedSteps.contains(refId)
  chapterCompleted → chapterIndex.isChapterCompleted(refId, _completedSteps)
  chapterNotCompleted → chapterIndex.isChapterNotCompleted(refId, _completedSteps)
  cutsceneCompleted → _completedCutscenes.contains(refId)
  cutsceneNotCompleted → !_completedCutscenes.contains(refId)
        ↓
isNpcPresentOnMap(entity):
  no rule / always → true
  visibleWhen → predicate satisfied → true
  hiddenWhen  → predicate satisfied → false (hidden)
        ↓
resolveNpcDialogue(npc):
  first conditionalDialogue whose predicate matches → dialogue
  no match → npc.dialogue (default)
        ↓
[save/load round-trip]
saveDataFromGameState → gameStateFromSaveData → normalizeLoadedGameState
→ même résultat avec le même evaluator
```

---

## 8. API ou comportement ajouté / caractérisé

Aucune nouvelle API ajoutée. Comportement existant caractérisé :

| Catégorie | Comportement | Prouvé |
|---|---|---|
| **Facts** | storyFlagSet true quand flag présent | ✅ |
| | storyFlagSet false quand flag absent | ✅ |
| | storyFlagUnset true quand flag absent | ✅ |
| | storyFlagUnset false quand flag présent | ✅ |
| **Steps** | stepCompleted true après completion | ✅ |
| | stepNotCompleted true avant completion | ✅ |
| | stepNotCompleted false après completion | ✅ |
| **Cutscenes** | cutsceneCompleted true quand terminée | ✅ |
| | cutsceneCompleted false quand non terminée | ✅ |
| | cutsceneNotCompleted true quand non terminée | ✅ |
| | cutsceneNotCompleted false quand terminée | ✅ |
| **Chapters** | chapterCompleted true quand toutes steps complétées | ✅ |
| | chapterCompleted false quand partiel | ✅ |
| | chapterNotCompleted true quand incomplet | ✅ |
| | chapterNotCompleted false quand complet | ✅ |
| **Dialogue** | dialogue par défaut si aucune condition ne matche | ✅ |
| | dialogue conditionnel par fact | ✅ |
| | dialogue conditionnel par step | ✅ |
| | première variante matchante gagne (priorité) | ✅ |
| **Visibility** | visibleWhen + flag set → présent | ✅ |
| | visibleWhen + flag absent → absent | ✅ |
| | hiddenWhen + step done → caché | ✅ |
| | hiddenWhen + step pending → visible | ✅ |
| | always → toujours présent | ✅ |
| | pas de rule → présent par défaut | ✅ |
| **Save/load** | visibility rule après save/load | ✅ |
| | conditional dialogue après save/load | ✅ |
| **Recalculation** | setFlag → visibility change | ✅ |
| | completeStep → dialogue change | ✅ |
| | completeStep → visibility change (hiddenWhen) | ✅ |
| **Garde-fou** | aucun id Selbrume hardcodé | ✅ |

---

## 9. Tests ajoutés

### map_runtime — 31 tests

Fichier : `packages/map_runtime/test/world_rules_conditional_presence_readiness_test.dart`

**Facts / story flags (4 tests)**

1. `storyFlagSet true when fact is present`
2. `storyFlagSet false when fact is absent`
3. `storyFlagUnset true when fact is absent`
4. `storyFlagUnset false when fact is present`

**Steps (3 tests)**

5. `stepCompleted true after completion`
6. `stepNotCompleted true before completion`
7. `stepNotCompleted false after completion`

**Cutscenes (4 tests)**

8. `cutsceneCompleted true when cutscene completed`
9. `cutsceneCompleted false when not completed`
10. `cutsceneNotCompleted true when not completed`
11. `cutsceneNotCompleted false when completed`

**Chapters (4 tests)**

12. `chapterCompleted true when all steps completed`
13. `chapterCompleted false when partial steps completed`
14. `chapterNotCompleted true when chapter incomplete`
15. `chapterNotCompleted false when chapter complete`

**Conditional dialogue (4 tests)**

16. `default dialogue when no condition matches`
17. `conditional dialogue selected by fact`
18. `conditional dialogue selected by step completion`
19. `first matching conditional dialogue wins (priority order)`

**Visibility rules (6 tests)**

20. `visibleWhen: NPC present when flag set`
21. `visibleWhen: NPC absent when flag not set`
22. `hiddenWhen: NPC hidden when step completed`
23. `hiddenWhen: NPC visible when step not yet completed`
24. `always mode: NPC always present regardless of state`
25. `no visibility rule: NPC present by default`

**Save / reload (2 tests)**

26. `visibility rule result preserved after save/load`
27. `conditional dialogue result preserved after save/load`

**Recalculation after mutation (3 tests)**

28. `visibility changes when flag is set`
29. `dialogue changes when step is completed`
30. `visibility changes when step is completed (hiddenWhen)`

**Garde-fou (1 test)**

31. `does not hardcode any Selbrume ids`

---

## 10. Commandes exécutées

```bash
# Initial
git status --short --untracked-files=all

# Audit
rg "MapEntityNpcVisibilityRule|MapEntityConditionalDialogue|MapEntityRuntimePredicateKind|visibilityRule|conditionalDialogues" packages/map_core packages/map_gameplay packages/map_runtime --type dart
rg "storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted|chapterCompleted|chapterNotCompleted|cutsceneCompleted|cutsceneNotCompleted" packages/map_core packages/map_gameplay packages/map_runtime --type dart

# Tests
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart

# Analyze
cd packages/map_runtime && flutter analyze
```

---

## 11. Résultats des tests

```text
00:00 +0: loading world_rules_conditional_presence_readiness_test.dart
00:00 +0: Facts / story flags storyFlagSet true when fact is present
00:00 +1: Facts / story flags storyFlagSet false when fact is absent
00:00 +2: Facts / story flags storyFlagUnset true when fact is absent
00:00 +3: Facts / story flags storyFlagUnset false when fact is present
00:00 +4: Steps stepCompleted true after completion
00:00 +5: Steps stepNotCompleted true before completion
00:00 +6: Steps stepNotCompleted false after completion
00:00 +7: Cutscenes cutsceneCompleted true when cutscene completed
00:00 +8: Cutscenes cutsceneCompleted false when not completed
00:00 +9: Cutscenes cutsceneNotCompleted true when not completed
00:00 +10: Cutscenes cutsceneNotCompleted false when completed
00:00 +11: Chapters chapterCompleted true when all steps completed
00:00 +12: Chapters chapterCompleted false when partial steps completed
00:00 +13: Chapters chapterNotCompleted true when chapter incomplete
00:00 +14: Chapters chapterNotCompleted false when chapter complete
00:00 +15: Conditional dialogue default dialogue when no condition matches
00:00 +16: Conditional dialogue conditional dialogue selected by fact
00:00 +17: Conditional dialogue conditional dialogue selected by step completion
00:00 +18: Conditional dialogue first matching conditional dialogue wins (priority order)
00:00 +19: Visibility rules visibleWhen: NPC present when flag set
00:00 +20: Visibility rules visibleWhen: NPC absent when flag not set
00:00 +21: Visibility rules hiddenWhen: NPC hidden when step completed
00:00 +22: Visibility rules hiddenWhen: NPC visible when step not yet completed
00:00 +23: Visibility rules always mode: NPC always present regardless of state
00:00 +24: Visibility rules no visibility rule: NPC present by default
00:00 +25: Save / reload consistency visibility rule result preserved after save/load
00:00 +26: Save / reload consistency conditional dialogue result preserved after save/load
00:00 +27: Recalculation after mutation visibility changes when flag is set
00:00 +28: Recalculation after mutation dialogue changes when step is completed
00:00 +29: Recalculation after mutation visibility changes when step is completed (hiddenWhen)
00:00 +30: does not hardcode any Selbrume ids
00:00 +31: All tests passed!
```

---

## 12. Résultat analyzer

```bash
cd packages/map_runtime && flutter analyze
```

```text
352 issues found. (ran in 1.7s)
```

Diagnostics pointant vers `world_rules_conditional_presence_readiness_test.dart` : **0**.

Tous les 352 issues sont pré-existants (info-level).

---

## 13. Garde-fou contre faux positif

### Question obligatoire

> Le test prouve-t-il réellement que le monde visible/interactable/dialoguable change selon le GameState, ou seulement qu'un predicate isolé retourne true/false ?

### Réponse

**Cas 2 — Test predicate + resolver utilisé en production.**

Les tests prouvent trois niveaux :

1. **Predicate** : `evaluatePredicate()` retourne true/false selon les 8 kinds. C'est le niveau atomique.

2. **Projection monde** : `isNpcPresentOnMap()` et `resolveNpcDialogue()` utilisent le predicate pour décider la présence et le dialogue. Ces fonctions sont utilisées en production par `PlayableMapGame._refreshWorldNpcPresence()` et le dialogue runtime.

3. **Recalculation** : les tests prouvent que la mutation d'état (setFlag, completeStep) suivie d'une recréation de l'evaluator change le résultat. C'est le cycle mutation → recalculation que le runtime Flame effectue à chaque GameState update.

### Gap honnête

Les tests ne prouvent pas la reconnexion Flame complète :
- `PlayableMapGame._refreshWorldNpcPresence()` n'est pas testée au niveau Flame widget test.
- Le refresh automatique après `onGameStateUpdated` dans le runtime Flame n'est pas prouvé ici.
- Ce gap sera couvert par NS-GS-12 (Editor-authored Golden Slice Validation).

Ce gap ne bloque pas la progression vers NS-GS-11.

---

## 14. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun code de prod modifié | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Aucun id Selbrume hardcodé | ✅ |
| Event non transformé en World Rule | ✅ |
| World Rule non transformée en Scene | ✅ |
| build_runner non lancé | ✅ |
| Aucune modification Freezed/generated | ✅ |

---

## 15. Mise à jour road_map.md

NS-GS-10 marqué ✅ fait.

Prochain lot mis à jour : 🔜 NS-GS-11 — Trainer Battle Authoring Readiness.

Section « Mise à jour NS-GS-10 » ajoutée.

---

## 16. Limites et non-objectifs

```text
Les tests caractérisent le pont evaluator-level, pas le runtime Flame complet.
PlayableMapGame._refreshWorldNpcPresence() n'est pas testée au niveau Flame.
Le refresh automatique après onGameStateUpdated n'est pas prouvé ici.
Ce gap sera couvert par NS-GS-12.
World Rule Editor complet non créé (hors scope).
Event Builder non créé (hors scope).
Validator narratif complet non créé (hors scope).
Système de rewards non créé (hors scope).
```

---

## 17. Prochain lot recommandé

```text
NS-GS-11 — Trainer Battle Authoring Readiness
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
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart
# 31/31 passed

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
?? packages/map_runtime/test/world_rules_conditional_presence_readiness_test.dart
?? reports/gameplay/ns_gs_10_world_rules_conditional_presence_readiness.md
```

### Confirmations

```text
Aucun code de prod modifié.
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
Event non transformé en World Rule.
World Rule non transformée en Scene.
Flux GameState → World Rule → présence / dialogue prouvé par 31 tests.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 19. Auto-review

| Question | Réponse |
|---|---|
| Flux GameState → World Rule → monde audité ? | ✅ |
| Flux GameState → World Rule → monde prouvé ? | ✅ 31 tests |
| Frontière Event / Scene / World Rule respectée ? | ✅ |
| Event transformé en World Rule ? | Non |
| World Rule transformée en Scene ? | Non |
| Code de prod modifié ? | Non |
| Fixture Selbrume créée ? | Non |
| Id Selbrume hardcodé ? | Non |
| Facts pilotent présence ? | ✅ |
| Steps pilotent présence ? | ✅ |
| Cutscenes pilotent présence ? | ✅ |
| Chapters pilotent présence ? | ✅ |
| Conditional dialogue prouvé ? | ✅ |
| Save/load préserve l'état ? | ✅ |
| Recalculation après mutation ? | ✅ |
| Tests passent ? | ✅ 31/31 |
| Analyze exécuté ? | ✅ 0 nouveau |
| Garde-fou faux positif ? | ✅ Cas 2 documenté |
| road_map.md mis à jour ? | ✅ |
| Rapport créé ? | ✅ |
| NS-GS-11 recommandé ? | ✅ |

---

*Fin du document NS-GS-10.*
