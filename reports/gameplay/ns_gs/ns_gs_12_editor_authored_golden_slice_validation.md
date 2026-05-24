# NS-GS-12 — Editor-authored Golden Slice Validation

---

## 1. Résumé exécutif

**Le Golden Slice intégré est prouvé au niveau Application (Level 2).**

L'audit + test d'intégration démontre que les briques NS-GS-05 à NS-GS-11 composent en une chaîne end-to-end fonctionnelle :

```text
New Game (empty party)
→ NPC Interaction (entityInteract → scenario match)
→ Scene Execution (givePokemon + setFlag + completeStep)
→ Save/Load round-trip
→ World Rule projection (rival NPC visible ↔ fact gate)
→ Dialogue + emitOutcome → outcome flag
→ sourceOutcome → rival battle scene
→ startTrainerBattle → graph suspendu (battle effect)
→ dispatchContinuation (victory branch / defeat branch)
→ setFlag + completeStep dans la branche correcte
→ Save/Load round-trip (tous flags, steps, party préservés)
→ World Rule recalculation (conditional dialogue post-battle)
```

Aucune brique manquante au niveau executor. Aucun code de prod modifié.

14 tests de caractérisation ajoutés prouvant la chaîne complète avec des ids génériques `test_*`. Tous passent. Analyze clean (0 diagnostic).

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (766 lignes).

Statut initial de NS-GS-12 : 🔜 (prochain lot après NS-GS-11).

Définition dans la roadmap :

```text
"voici comment valider un Golden Slice créé dans l'éditeur"
```

Scope contractuel :

```text
- Scope strictement mechanics-first
- Aucune fixture Selbrume finale créée
- Aucun project.json Selbrume complet généré
- Aucun contenu final Selbrume créé dans le repo
- Validation de la capacité de PokeMap à exécuter un Golden Slice authorable
- Lot audit-first
- Si validation Flame/editor complète pas possible, limite documentée précisément
- Tests uniquement avec ids test_*
```

---

## 3. Frontière Event / Scene / Battle / World Rule

### Event

```text
Event = déclenchement externe.
entityInteract(mapId, entityId), outcomeReceived(outcomeId).
Détermine quel scénario s'active.
```

### Scene

```text
Scene = déroulé narratif.
Traverse le graphe ScenarioAsset : actions (givePokemon, setFlag, completeStep),
effets (openDialogue, startTrainerBattle), branches (condition), emit/consume outcomes.
Responsable de la progression narrative.
```

### Battle

```text
Trainer Battle = mécanique gameplay appelée par une Scene.
Ne décide pas seul de la progression narrative.
Produit un outcome (victory / defeat / flee / captured) exploitable par la Scene.
```

### World Rule

```text
World Rule = projection passive de l'état du GameState sur le monde.
MapEntityRuntimePredicateEvaluator évalue visibilité, présence, dialogue conditionnel.
```

### Règle stricte appliquée

```text
Event déclenche.
Scene orchestre (givePokemon, emitOutcome, startTrainerBattle).
Battle résout un combat.
Outcome battle revient à la Scene.
World Rule projette ensuite l'état.
Save/Load préserve tout le state.
```

---

## 4. Niveau de preuve atteint

### Level 2 — Application layer ✅ (prouvé)

| Composant | Rôle | Prouvé |
|---|---|---|
| `ScenarioRuntimeExecutor.dispatch` | Match source event → exécute graphe | ✅ |
| `ScenarioRuntimeExecutor.dispatchContinuation` | Reprend après effet (dialogue / battle) | ✅ |
| `MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap` | Visibilité NPC conditionnel | ✅ |
| `MapEntityRuntimePredicateEvaluator.resolveNpcDialogue` | Dialogue conditionnel | ✅ |
| `createNewGameState` | Nouvelle partie vide | ✅ |
| `saveDataFromGameState` / `gameStateFromSaveData` | Save/load round-trip | ✅ |
| `normalizeLoadedGameState` | Normalisation post-load | ✅ |

### Level 3 — Flame runtime ❌ (non prouvé)

Raisons documentées :

```text
1. PlayableMapGame requiert un RuntimeMapBundle (project manifest, map data, tilesets).
2. Aucun harness headless PlayableMapGame n'existe.
3. Créer ce harness nécessiterait un projet fixture complet (project.json + maps/ + tilesets/).
4. Cela équivaudrait à créer du contenu Selbrume, interdit par le contrat.
5. Widget test Flame nécessite WidgetTester + GameWidget setup.
```

### Level 4 — Disk project ❌ (exclu par contrat)

```text
Aucun project.json, aucune fixture Selbrume, aucun contenu final.
Le lot valide la capacité de PokeMap à exécuter un Golden Slice authorable,
pas un contenu final.
```

---

## 5. Décision d'implémentation

| Choix | Détail |
|---|---|
| Type | Validation intégrée au niveau Application |
| Code de prod modifié | Aucun |
| Tests ajoutés | 14 tests dans `ns_gs_12_golden_slice_validation_test.dart` |
| build_runner | Non lancé |
| Nouveau modèle | Aucun |

---

## 6. Fichiers créés / modifiés

| Action | Fichier | Détail |
|---|---|---|
| CRÉÉ | `packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart` | 14 tests d'intégration Golden Slice |
| CRÉÉ | `reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md` | Ce rapport |

---

## 7. Architecture du test : 3 graphes de scénario composés

### 7.1 — mentorGivesPokemonScene (localEventFlow)

```text
[source_mentor]  entityInteract(test_start_map, test_mentor_npc)
      ↓ next
[give_pokemon]   actionKind: givePokemon
                 params: speciesId=test_starter_species, level=5
      ↓ next
[set_fact_1]     actionKind: setFlag → test_given_starter_fact
      ↓ next
[complete_step_1] actionKind: completeStep → test_step_starter_received
      ↓ next
[set_fact_2]     actionKind: setFlag → test_mission_started_fact
      ↓ next
[complete_step_2] actionKind: completeStep → test_step_mission_started
      ↓ next
[end_mentor]     type: end
```

### 7.2 — rivalDialogueScene (localEventFlow)

```text
[source_rival]   entityInteract(test_port_map, test_rival_npc)
      ↓ next
[open_dialogue]  actionKind: openDialogue → dialogueId: test_scene_rival_dialogue
      ↓ next
[emit_outcome]   actionKind: emitOutcome
                 binding.outcomeId: test_dialogue_outcome_confident
      ↓ next
[end_dialogue]   type: end
```

### 7.3 — rivalBattleScene (globalStory)

```text
[source_outcome]   reference / sourceOutcome
                   binding.outcomeId: test_dialogue_outcome_confident
      ↓ next
[condition_confident] condition: flagIsSet(scenario.outcome.test_dialogue_outcome_confident)
      ├─ trueBranch → [battle_node]
      └─ falseBranch → [end_skip]
            
[battle_node]    actionKind: startTrainerBattle
                 params.battleId: test_battle
                 binding.trainerId: test_trainer, binding.entityId: test_rival_npc
      ↓ next
[condition_victory] condition: flagIsSet(battle:test_battle:victory)
      ├─ trueBranch → [set_victory_fact] → [complete_battle_step_victory] → [end_victory]
      └─ falseBranch → [set_defeat_fact] → [complete_battle_step_defeat] → [end_defeat]
```

---

## 8. Tests ajoutés — 14 tests

Fichier : `packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart`

### 1. New game + empty party (1 test)

1. `createNewGameState starts with empty party on test_start_map`

### 2. Mentor scene → GivePokemon + completeStep (1 test)

2. `interacting with mentor NPC gives pokemon and sets facts/steps`

### 3. Save/load preserves pokemon + progression (1 test)

3. `save/load round-trip preserves party, facts, and steps`

### 4. World Rule unlocks rival NPC (3 tests)

4. `rival is hidden before mentor scene`
5. `rival is visible after starter + mission facts`
6. `rival visibility survives save/load`

### 5. Outcome → Branch (2 tests)

7. `rival dialogue emits outcome and sets outcome flag`
8. `outcome flag triggers battle scene via sourceOutcome`

### 6. Trainer Battle → Battle Effect (1 test)

9. `battle effect contains battleId trainerId npcEntityId`

### 7. Victory continuation (1 test)

10. `victory flag → victory path → fact + step completed`

### 8. Defeat continuation (1 test)

11. `defeat flag → defeat path → fact + step completed`

### 9. Save/load preserves final state (2 tests)

12. `full golden slice state survives save/load (victory path)`
13. `world rule still resolves correctly after full save/load`

### 10. No Selbrume ids guard (1 test)

14. `all fixture ids use test_* prefix`

---

## 9. Commandes exécutées

```bash
# Flutter test
cd packages/map_runtime && flutter test test/ns_gs_12_golden_slice_validation_test.dart

# Flutter analyze
cd packages/map_runtime && flutter analyze test/ns_gs_12_golden_slice_validation_test.dart
```

---

## 10. Résultats des tests

```text
00:00 +0: loading ns_gs_12_golden_slice_validation_test.dart
00:00 +0: 1. New game + empty party createNewGameState starts with empty party on test_start_map
00:00 +1: 2. Mentor scene → GivePokemon + completeStep interacting with mentor NPC gives pokemon and sets facts/steps
00:00 +2: 3. Save/load preserves pokemon + progression save/load round-trip preserves party, facts, and steps
00:00 +3: 4. World Rule unlocks rival NPC rival is hidden before mentor scene
00:00 +4: 4. World Rule unlocks rival NPC rival is visible after starter + mission facts
00:00 +5: 4. World Rule unlocks rival NPC rival visibility survives save/load
00:00 +6: 5. Outcome → Branch rival dialogue emits outcome and sets outcome flag
00:00 +7: 5. Outcome → Branch outcome flag triggers battle scene via sourceOutcome
00:00 +8: 6. Trainer Battle → Battle Effect battle effect contains battleId trainerId npcEntityId
00:00 +9: 7. Victory continuation victory flag → victory path → fact + step completed
00:00 +10: 8. Defeat continuation defeat flag → defeat path → fact + step completed
00:00 +11: 9. Save/load preserves final state full golden slice state survives save/load (victory path)
00:00 +12: 9. Save/load preserves final state world rule still resolves correctly after full save/load
00:00 +13: 10. No Selbrume ids guard all fixture ids use test_* prefix
00:00 +14: All tests passed!
```

---

## 11. Résultat analyzer

```bash
cd packages/map_runtime && flutter analyze test/ns_gs_12_golden_slice_validation_test.dart
```

```text
Analyzing ns_gs_12_golden_slice_validation_test.dart...
No issues found! (ran in 1.8s)
```

0 diagnostic. Clean.

---

## 12. Ce que la validation prouve

| Brique Golden Slice | Lot d'origine | Prouvé en intégration |
|---|---|---|
| Nouvelle partie (party vide, startMapId) | NS-GS-05 | ✅ |
| PNJ donne Pokémon (givePokemon) | NS-GS-06 | ✅ |
| Progression (setFlag + completeStep) | NS-GS-07 | ✅ |
| NPC interaction → scène (entityInteract → dispatch) | NS-GS-08 | ✅ |
| Dialogue outcome → branch (emitOutcome → sourceOutcome) | NS-GS-09 | ✅ |
| World Rule (visibilité, dialogue conditionnel) | NS-GS-10 | ✅ |
| Trainer Battle (startTrainerBattle → continuation) | NS-GS-11 | ✅ |
| Save/Load préserve party + flags + steps | NS-GS-05/07 | ✅ |
| Victory/Defeat branching | NS-GS-11 | ✅ |
| World Rule recalculation post-battle | NS-GS-10 | ✅ |

---

## 13. Garde-fou contre faux positif

### Question obligatoire

> Les 14 tests prouvent-ils réellement le flux Golden Slice intégré, ou seulement des briques isolées rassemblées artificiellement ?

### Réponse

**Cas 1 — Flux intégré prouvé au niveau Application.**

Les tests prouvent la composition réelle :

1. `dispatch()` avec `mentorGivesPokemonScene` exécute givePokemon + setFlag + completeStep atomiquement.
2. Le GameState résultant est vérifié (party.members, storyFlags, progression).
3. Save/Load round-trip préserve ce state.
4. `MapEntityRuntimePredicateEvaluator` projette correctement la visibilité du rival à partir du state muté.
5. `dispatch()` avec `rivalDialogueScene` ouvre un dialogue et suspend le graphe.
6. `dispatchContinuation()` reprend le graphe, exécute `emitOutcome`, pose le flag outcome.
7. `emitOutcome` dans le graphe dialogue déclenche en cascade `rivalBattleScene` via `sourceOutcome`.
8. Le graphe battle suspend à `battle_node` et produit un `ScenarioRuntimeEffectType.battle`.
9. `dispatchContinuation()` reprend après battle, condition victory/defeat, branche correcte.
10. Save/Load final préserve tous les flags et steps cumulés.
11. World Rule recalcule correctement le dialogue conditionnel post-battle.

### Gap honnête

Les tests ne prouvent pas :

```text
- PlayableMapGame._handleScenarioBattleEffect (niveau Flame widget test).
- PlayableMapGame._onBattleFinished pose le flag dans le contexte Flame.
- buildTrainerBattleRequestFromNpc dans le flux scénario complet
  (testé séparément dans trainer_battle_request_test.dart).
- applyRuntimeBattleOutcomeToGameState applique les HP/defeated flag
  (testé séparément dans runtime_battle_outcome_apply_test.dart).
- Le résultat de battle est simulé (flag posé manuellement, pas via engine battle réel).
- openDialogue est stubé (retourne true immédiatement, pas de Yarn + UI overlay).
- Pas de PC/Box overflow testé.
- Pas de bag/items testé dans le Golden Slice.
```

Ces briques sont testées individuellement dans leurs fichiers respectifs. Le test d'intégration NS-GS-12 prouve le câblage entre elles au niveau executor.

---

## 14. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun code de prod modifié | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Aucun project.json Selbrume généré | ✅ |
| Aucun contenu final Selbrume dans le repo | ✅ |
| Aucun id Selbrume hardcodé | ✅ |
| Lot audit-first | ✅ |
| Limite Flame/editor documentée précisément | ✅ |
| Tous les ids test_* | ✅ |
| build_runner non lancé | ✅ |
| Aucune modification Freezed/generated | ✅ |

---

## 15. Limites et non-objectifs

```text
1. Tests au niveau ScenarioRuntimeExecutor, pas au niveau Flame complet.
2. PlayableMapGame._handleScenarioBattleEffect non testé au niveau Flame widget test.
3. PlayableMapGame._onBattleFinished non testé au niveau Flame widget test.
4. buildTrainerBattleRequestFromNpc testé séparément, pas dans le flux scénario complet.
5. applyRuntimeBattleOutcomeToGameState testé séparément.
6. Battle outcome simulé (flag posé manuellement).
7. openDialogue stubé.
8. XP / money / level-up / rewards non implémentés (hors scope).
9. PC/Box overflow non testé.
10. Bag/items non testé.
11. Validator narratif complet non créé (hors scope — NS-GS-13).
```

---

## 16. Prochain lot recommandé

```text
NS-GS-13 — Narrative Validator Minimal V0
```

Raison : maintenant que le flux Golden Slice est prouvé au niveau Application,
le prochain objectif est un validator qui vérifie qu'un projet créé dans l'éditeur
est structurellement valide (scénarios connectés, ids résolvables, pas de nœuds orphelins).

---

## 17. Mise à jour road_map.md

NS-GS-12 marqué ✅ fait.

Prochain lot mis à jour : 🔜 NS-GS-13 — Narrative Validator Minimal V0.

Section « Mise à jour NS-GS-12 — 2026-05-24 » ajoutée.

---

## 18. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre)
```

### Commandes de test exécutées

```bash
cd packages/map_runtime && flutter test test/ns_gs_12_golden_slice_validation_test.dart
# 14/14 passed

cd packages/map_runtime && flutter analyze test/ns_gs_12_golden_slice_validation_test.dart
# No issues found! (ran in 1.8s)
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart
?? reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
```

Un fichier modifié (roadmap). Deux fichiers non-tracked (test + rapport).

### Confirmations

```text
Aucun code de prod modifié.
Aucune fixture Selbrume finale créée.
Aucun project.json Selbrume complet généré.
Aucun contenu final Selbrume créé dans le repo.
Aucun id Selbrume hardcodé (test_mentor_npc, test_rival_npc, test_starter_species, test_battle, etc.).
Lot audit-first respecté.
Limite Flame/editor documentée (Level 3 non prouvé, raison : pas de harness headless PlayableMapGame).
Flux Golden Slice intégré prouvé par 14 tests.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 19. Auto-review

| Question | Réponse |
|---|---|
| Golden Slice intégré prouvé ? | ✅ 14 tests composent NS-GS-05..11 |
| Level 2 Application atteint ? | ✅ |
| Level 3 Flame atteint ? | ❌ Limite documentée |
| Frontière Event / Scene / Battle / World Rule respectée ? | ✅ |
| Code de prod modifié ? | Non |
| Fixture Selbrume créée ? | Non |
| project.json Selbrume généré ? | Non |
| Contenu final Selbrume créé ? | Non |
| Id Selbrume hardcodé ? | Non |
| Tous ids test_* ? | ✅ |
| Save/Load round-trip prouvé ? | ✅ (2 tests dédiés + assertions dans d'autres) |
| World Rule recalculation post-battle prouvée ? | ✅ |
| Dialogue conditionnel post-battle prouvé ? | ✅ |
| Victory branching prouvé ? | ✅ |
| Defeat branching prouvé ? | ✅ |
| emitOutcome → sourceOutcome cross-scenario prouvé ? | ✅ |
| Tests passent ? | ✅ 14/14 |
| Analyze exécuté ? | ✅ 0 diagnostic |
| Garde-fou faux positif ? | ✅ Cas 1 documenté avec gap honnête |
| Rapport créé ? | ✅ |
| NS-GS-13 recommandé ? | ✅ |

---

*Fin du document NS-GS-12.*
