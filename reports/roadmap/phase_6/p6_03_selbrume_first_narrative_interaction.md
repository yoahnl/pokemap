# P6-03 — Selbrume First Narrative Interaction V0

## 1. Résumé exécutif

P6-03 est terminé.

Le projet Selbrume repo-local contient maintenant une première interaction narrative technique courte :

```text
map : Selbrume
entity : p6_03_intro_sign
scenario : p6_03_first_interaction
source : sourceEntityInteract
effet observable : showMessage
effet persistable : story flag p6.selbrume.first_interaction.seen
effet persistable : completed step p6.selbrume.first_interaction
```

La preuve est runtime-application : le test charge `selbrume/project.json` via `loadRuntimeMapBundle`, construit le New Game minimal Selbrume/spawn, seede la party/bag de P6-02, déclenche `ScenarioRuntimeExecutor.dispatch(entityInteract)`, vérifie le message, puis vérifie un roundtrip `SaveData`.

Ce texte est une preuve technique golden slice V0. Ce n'est pas un dialogue final, pas une quête finale, pas une cinématique, pas Maël/Lysa final, pas un combat.

## 2. Sources lues

Sources de gouvernance :

```text
AGENTS.md
agent_rules.md
skills/README.md
pokemap_roadmap_mecaniques_fangame.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_6.md
reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
```

Sources techniques :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/enums.dart
```

Tests lus :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
packages/map_runtime/test/scenario_runtime_executor_test.dart
packages/map_runtime/test/scenario_complete_step_test.dart
```

Chemins demandés mais absents sous la forme exacte :

```text
packages/map_runtime/lib/src/scenario_runtime_executor.dart
packages/map_runtime/lib/src/scenario_runtime_state.dart
```

Équivalents trouvés :

```text
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
```

## 3. Gate 0

Commandes exécutées depuis `/Users/karim/Project/pokemonProject` :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume | sed -n '1,160p'
printf 'SELBRUME_STATUS_COUNT='
git status --short --untracked-files=all -- selbrume | wc -l
```

Sorties utiles :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git diff --name-only
Sortie : <vide>

git log --oneline -n 10
25d623ca Ajoute selbrume/assets/pokemon/sprites/ à .gitignore
951b5e6b Ajoute P6-02 : Selbrume Initial Party/Bag Setup (test et rapport)
1886d1bf Ajoute P6-01 : Existing Selbrume Loadability Start Map Contract (test et rapport)
845dd603 update Selbrume.json
fbc32f8b Ajoute les sprites Pokémon pour Selbrume
e2541284 Ajoute le rapport P6-00 et met à jour road_map_phase_6.md
a54b6001 Ajoute le rapport P5-Checkpoint-01-bis et met à jour les roadmaps
beb36d20 Ajoute road_map_phase_6.md et le rapport P5-Checkpoint-01, met à jour road_map_global.md et road_map_phase_5.md
a04b8997 Ajoute P5-10 : Scope Audio Out of Scope Checkpoint Redirect (rapport)
a547ccc2 Ajoute P5-08 et P5-09 : Beta Runtime Smoke et Beta Playability Validator (code, tests et rapports)

test existence repo-local selbrume
REPO_SELBRUME_PROJECT_PATH exists

test existence project.json
repo-local selbrume/project.json exists

git status --short --untracked-files=all -- selbrume
Sortie : <vide>

SELBRUME_STATUS_COUNT=       0
```

Conclusion Gate 0 :

```text
selbrume/ était propre au Gate 0.
Les modifications Selbrume strictement limitées à project.json et maps/Selbrume.json étaient donc autorisées par le contrat P6-03.
```

## 4. Audit narratif Selbrume existant

État observé avant modification :

```text
project.json top-level keys : characters, dialogueFolders, dialogues, elementCategories, elements, encounterTables, environmentPresets, globalProperties, groups, maps, name, pathCategories, pathPatternPresets, pathPresets, pokemon, scenarios, scripts, settings, shadowCatalog, surfaceCatalog, terrainCategories, terrainPresets, tilesetFolders, tilesets, trainers, version
dialogues : list[1]
scripts : list[0]
scenarios : list[2]
```

Dialogue existant :

```text
id : g
relativePath : dialogues/g.yarn
contenu :
title: g
---
(Begin editing your dialogue here.)
===
```

Scénarios existants :

```text
global_story : scope globalStory, nodes 2, edges 1, pas de binding source exploitable pour P6-03
test : scope localEventFlow, nodes 4, edges 3
```

Le scénario `test` contenait déjà une source `sourceEntityInteract` sur `Selbrume`, mais il n'était pas exploitable comme preuve P6-03 :

```text
source.entityId : null
showMessage.message : ""
nom/id : test
pas d'effet persistable
```

Map Selbrume avant modification :

```text
id : Selbrume
entities : list[1]
entity existante : spawn
triggers : list[0]
events : list[0]
```

Décision d'audit :

```text
Réutilisation stricte impossible sans créer un faux positif.
Création d'une interaction technique minimale explicite retenue.
```

## 5. Décision d’interaction retenue

Interaction retenue :

```text
entityId : p6_03_intro_sign
entity kind : sign
scenarioId : p6_03_first_interaction
source : sourceEntityInteract(mapId=Selbrume, entityId=p6_03_intro_sign)
```

Flow runtime :

```text
source
-> set_seen_flag
-> complete_intro_step
-> show_intro_message
-> end
```

Effets :

```text
setFlag : p6.selbrume.first_interaction.seen
completeStep : p6.selbrume.first_interaction
showMessage : Bienvenue à Selbrume. Ceci est la première interaction narrative du golden slice.
```

Pourquoi `setFlag` et `completeStep` avant `showMessage` :

```text
ScenarioRuntimeExecutor arrête le traversal sur showMessage, car c'est un effet terminal observable.
Le flag et la step doivent donc être avant showMessage pour être appliqués et persistés.
```

## 6. Modifications Selbrume

Fichiers Selbrume modifiés :

```text
selbrume/project.json
selbrume/maps/Selbrume.json
```

`selbrume/dialogues/g.yarn` n'a pas été modifié.

Diff ciblé `selbrume/project.json` :

```diff
diff --git a/selbrume/project.json b/selbrume/project.json
index 11c20cab..31827463 100644
--- a/selbrume/project.json
+++ b/selbrume/project.json
@@ -12777,6 +12777,256 @@
         "authoring.cutsceneSchema": "cutscene_studio_v2",
         "authoring.cutsceneFlow": "{\"v\":1,\"seq\":[{\"t\":\"b\",\"b\":{\"id\":\"block_dialogue_1\",\"kind\":\"dialogue\",\"actorId\":null,\"dialogueId\":null,\"messageText\":null,\"scriptId\":null,\"flagName\":null,\"outcomeId\":null,\"resultLabel\":null,\"resultScope\":null,\"destinationTargetKind\":null,\"destinationTargetId\":null,\"transitionMapId\":null,\"transitionWarpId\":null,\"facingDirection\":null,\"durationMs\":null,\"waitForCompletion\":null,\"choiceOptions\":[]}}]}"
       }
+    },
+    {
+      "id": "p6_03_first_interaction",
+      "name": "P6-03 First Narrative Interaction",
+      "description": "Interaction narrative technique courte pour le golden slice V0.",
+      "scope": "localEventFlow",
+      "entryNodeId": "start",
+      "declaredOutcomes": [],
+      "activationCondition": null,
+      "nodes": [
+        {
+          "id": "start",
+          "type": "start",
+          "title": "Start",
+          "description": "",
+          "position": {
+            "x": 0.0,
+            "y": 0.0
+          },
+          "binding": {
+            "mapId": null,
+            "eventId": null,
+            "entityId": null,
+            "warpId": null,
+            "triggerId": null,
+            "trainerId": null,
+            "dialogueId": null,
+            "scriptId": null,
+            "outcomeId": null,
+            "flagName": null,
+            "variableName": null
+          },
+          "payload": {
+            "actionKind": null,
+            "message": null,
+            "condition": null,
+            "choiceLabels": [],
+            "params": {}
+          },
+          "metadata": {}
+        },
+        {
+          "id": "source",
+          "type": "reference",
+          "title": "Source",
+          "description": "",
+          "position": {
+            "x": 0.0,
+            "y": 0.0
+          },
+          "binding": {
+            "mapId": "Selbrume",
+            "eventId": null,
+            "entityId": "p6_03_intro_sign",
+            "warpId": null,
+            "triggerId": null,
+            "trainerId": null,
+            "dialogueId": null,
+            "scriptId": null,
+            "outcomeId": null,
+            "flagName": null,
+            "variableName": null
+          },
+          "payload": {
+            "actionKind": "sourceEntityInteract",
+            "message": null,
+            "condition": null,
+            "choiceLabels": [],
+            "params": {}
+          },
+          "metadata": {}
+        },
+        {
+          "id": "set_seen_flag",
+          "type": "action",
+          "title": "Mark first interaction seen",
+          "description": "",
+          "position": {
+            "x": 180.0,
+            "y": 0.0
+          },
+          "binding": {
+            "mapId": null,
+            "eventId": null,
+            "entityId": null,
+            "warpId": null,
+            "triggerId": null,
+            "trainerId": null,
+            "dialogueId": null,
+            "scriptId": null,
+            "outcomeId": null,
+            "flagName": "p6.selbrume.first_interaction.seen",
+            "variableName": null
+          },
+          "payload": {
+            "actionKind": "setFlag",
+            "message": null,
+            "condition": null,
+            "choiceLabels": [],
+            "params": {}
+          },
+          "metadata": {}
+        },
+        {
+          "id": "complete_intro_step",
+          "type": "action",
+          "title": "Complete first interaction step",
+          "description": "",
+          "position": {
+            "x": 360.0,
+            "y": 0.0
+          },
+          "binding": {
+            "mapId": null,
+            "eventId": null,
+            "entityId": null,
+            "warpId": null,
+            "triggerId": null,
+            "trainerId": null,
+            "dialogueId": null,
+            "scriptId": null,
+            "outcomeId": null,
+            "flagName": null,
+            "variableName": null
+          },
+          "payload": {
+            "actionKind": "completeStep",
+            "message": null,
+            "condition": null,
+            "choiceLabels": [],
+            "params": {
+              "stepId": "p6.selbrume.first_interaction"
+            }
+          },
+          "metadata": {}
+        },
+        {
+          "id": "show_intro_message",
+          "type": "action",
+          "title": "Show first interaction message",
+          "description": "",
+          "position": {
+            "x": 540.0,
+            "y": 0.0
+          },
+          "binding": {
+            "mapId": null,
+            "eventId": null,
+            "entityId": null,
+            "warpId": null,
+            "triggerId": null,
+            "trainerId": null,
+            "dialogueId": null,
+            "scriptId": null,
+            "outcomeId": null,
+            "flagName": null,
+            "variableName": null
+          },
+          "payload": {
+            "actionKind": "showMessage",
+            "message": "Bienvenue à Selbrume. Ceci est la première interaction narrative du golden slice.",
+            "condition": null,
+            "choiceLabels": [],
+            "params": {}
+          },
+          "metadata": {}
+        },
+        {
+          "id": "end",
+          "type": "end",
+          "title": "End",
+          "description": "",
+          "position": {
+            "x": 720.0,
+            "y": 0.0
+          },
+          "binding": {
+            "mapId": null,
+            "eventId": null,
+            "entityId": null,
+            "warpId": null,
+            "triggerId": null,
+            "trainerId": null,
+            "dialogueId": null,
+            "scriptId": null,
+            "outcomeId": null,
+            "flagName": null,
+            "variableName": null
+          },
+          "payload": {
+            "actionKind": null,
+            "message": null,
+            "condition": null,
+            "choiceLabels": [],
+            "params": {}
+          },
+          "metadata": {}
+        }
+      ],
+      "edges": [
+        {
+          "id": "edge_start_source",
+          "fromNodeId": "start",
+          "toNodeId": "source",
+          "label": "",
+          "kind": "next",
+          "order": 0,
+          "metadata": {}
+        },
+        {
+          "id": "edge_source_set_seen_flag",
+          "fromNodeId": "source",
+          "toNodeId": "set_seen_flag",
+          "label": "",
+          "kind": "next",
+          "order": 0,
+          "metadata": {}
+        },
+        {
+          "id": "edge_set_seen_flag_complete_intro_step",
+          "fromNodeId": "set_seen_flag",
+          "toNodeId": "complete_intro_step",
+          "label": "",
+          "kind": "next",
+          "order": 0,
+          "metadata": {}
+        },
+        {
+          "id": "edge_complete_intro_step_show_intro_message",
+          "fromNodeId": "complete_intro_step",
+          "toNodeId": "show_intro_message",
+          "label": "",
+          "kind": "next",
+          "order": 0,
+          "metadata": {}
+        },
+        {
+          "id": "edge_show_intro_message_end",
+          "fromNodeId": "show_intro_message",
+          "toNodeId": "end",
+          "label": "",
+          "kind": "next",
+          "order": 0,
+          "metadata": {}
+        }
+      ],
+      "metadata": {
+        "phase": "P6-03",
+        "contentStatus": "technical_golden_slice_v0"
+      }
     }
   ],
   "trainers": [],
```

Diff ciblé `selbrume/maps/Selbrume.json` :

```diff
diff --git a/selbrume/maps/Selbrume.json b/selbrume/maps/Selbrume.json
index 4448cf03..40d49f7a 100644
--- a/selbrume/maps/Selbrume.json
+++ b/selbrume/maps/Selbrume.json
@@ -67534,6 +67534,33 @@
       "editorVisual": null,
       "blocksMovement": true,
       "properties": {}
+    },
+    {
+      "id": "p6_03_intro_sign",
+      "name": "P6-03 intro sign",
+      "kind": "sign",
+      "pos": {
+        "x": 22,
+        "y": 25
+      },
+      "size": {
+        "width": 2,
+        "height": 1
+      },
+      "npc": null,
+      "sign": {
+        "title": "P6-03 Intro",
+        "dialogue": null,
+        "plainText": "Bienvenue à Selbrume. Ceci est la première interaction narrative du golden slice."
+      },
+      "item": null,
+      "spawn": null,
+      "editorVisual": null,
+      "blocksMovement": true,
+      "properties": {
+        "phase": "P6-03",
+        "contentStatus": "technical_golden_slice_v0"
+      }
     }
   ],
   "connections": [
```

Validation JSON :

```text
python3 -m json.tool selbrume/project.json >/dev/null && python3 -m json.tool selbrume/maps/Selbrume.json >/dev/null && echo "Selbrume JSON OK"
Selbrume JSON OK
```

## 7. Preuve d’interaction

Preuve obtenue :

```text
loadRuntimeMapBundle charge Selbrume
bundle.manifest.scenarios contient p6_03_first_interaction
bundle.map.entities contient p6_03_intro_sign
ScenarioRuntimeExecutor.dispatch(entityInteract) matche la source
showMessage est émis avec le texte attendu
setFlag est appliqué avant showMessage
completeStep est appliqué avant showMessage
```

Le test ne prouve pas une UI dialogue interactive. Il prouve le bridge runtime-application `ScenarioRuntimeExecutor`, avec callback `showMessage`.

## 8. Preuve SaveData / persistance si applicable

Le scénario mute `GameState` via deux actions existantes :

```text
setFlag -> GameState.storyFlags.activeFlags
completeStep -> GameState.progression.completedStepIds
```

Le test convertit ensuite :

```text
GameState
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
```

Assertions de persistance :

```text
SaveData.progression.storyFlags contient p6.selbrume.first_interaction.seen
SaveData.progression.completedStepIds contient p6.selbrume.first_interaction
GameState rechargé conserve storyFlags.activeFlags
GameState rechargé conserve completedStepIds
GameState rechargé conserve party P6-02
GameState rechargé conserve bag P6-02
```

## 9. Tests exécutés

### Test ciblé P6-03

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
```

Première exécution utile, avant correction du graphe :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
00:00 +0: P6-03 triggers repo-local Selbrume first narrative interaction and persists its state
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=643956
[runtime_loader] project manifest load failed path=/Users/karim/Project/pokemonProject/selbrume/project.json error=Scenario p6_03_first_interaction must contain exactly one start node
00:00 +0 -1: P6-03 triggers repo-local Selbrume first narrative interaction and persists its state [E]
  Failed to load project: Scenario p6_03_first_interaction must contain exactly one start node
  package:map_runtime/src/application/load_runtime_map_bundle.dart 59:5  loadProjectManifestFromFile
  
00:00 +0 -1: Some tests failed.
```

Diagnostic :

```text
Le validator de manifest exige exactement un node start par scenario.
Correction appliquée : ajout du node start et edge start -> source dans p6_03_first_interaction.
```

Exécution finale :

```text
00:00 +0: P6-03 triggers repo-local Selbrume first narrative interaction and persists its state
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644962
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=3
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1267082
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=2 placedElements=1180 warps=3 triggers=0
[runtime_loader] bundle tilesets collected ids=arbre_pixellab,selbrume_all_sprite,grass_elements,objectif,fleurs_selbrume_de_toure_es,deep_water,pavement_path,gros_sol_herbre,beach_tile,vova
[runtime_loader] bundle tileset path id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_loader] bundle tileset path id=selbrume_all_sprite path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/selbrume_all_sprite.png
[runtime_loader] bundle tileset path id=grass_elements path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/grass_elements.png
[runtime_loader] bundle tileset path id=objectif path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/objectif.png
[runtime_loader] bundle tileset path id=fleurs_selbrume_de_toure_es path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/fleurs_selbrume_de_toure_es.png
[runtime_loader] bundle tileset path id=deep_water path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/deep_water.png
[runtime_loader] bundle tileset path id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_loader] bundle tileset path id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_loader] bundle tileset path id=beach_tile path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/beach_tile.png
[runtime_loader] bundle tileset path id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
00:00 +1: All tests passed!
```

### Régression P6-01

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
00:00 +0: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644962
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=3
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1267082
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=2 placedElements=1180 warps=3 triggers=0
[runtime_loader] bundle tilesets collected ids=arbre_pixellab,selbrume_all_sprite,grass_elements,objectif,fleurs_selbrume_de_toure_es,deep_water,pavement_path,gros_sol_herbre,beach_tile,vova
[runtime_loader] bundle tileset path id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_loader] bundle tileset path id=selbrume_all_sprite path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/selbrume_all_sprite.png
[runtime_loader] bundle tileset path id=grass_elements path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/grass_elements.png
[runtime_loader] bundle tileset path id=objectif path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/objectif.png
[runtime_loader] bundle tileset path id=fleurs_selbrume_de_toure_es path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/fleurs_selbrume_de_toure_es.png
[runtime_loader] bundle tileset path id=deep_water path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/deep_water.png
[runtime_loader] bundle tileset path id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_loader] bundle tileset path id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_loader] bundle tileset path id=beach_tile path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/beach_tile.png
[runtime_loader] bundle tileset path id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=route 1
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644962
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=3
[runtime_loader] bundle map resolved mapId=route 1 relativePath=maps/route 1.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file read ok bytes=222423
[runtime_loader] map validated id=route 1 size=45x45 layers=6 entities=0 placedElements=68 warps=0 triggers=0
[runtime_loader] bundle tilesets collected ids=arbre_pixellab,route_1_1,haute_herbe,pavement_path,gros_sol_herbre,vova
[runtime_loader] bundle tileset path id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_loader] bundle tileset path id=route_1_1 path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/route_1_1.png
[runtime_loader] bundle tileset path id=haute_herbe path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/haute_herbe.png
[runtime_loader] bundle tileset path id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_loader] bundle tileset path id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_loader] bundle tileset path id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_loader] bundle load ok mapId=route 1 projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=6
00:00 +1: All tests passed!
```

### Régression P6-02

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
```

Sortie :

```text
00:00 +0: P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644962
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=3
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1267082
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=2 placedElements=1180 warps=3 triggers=0
[runtime_loader] bundle tilesets collected ids=arbre_pixellab,selbrume_all_sprite,grass_elements,objectif,fleurs_selbrume_de_toure_es,deep_water,pavement_path,gros_sol_herbre,beach_tile,vova
[runtime_loader] bundle tileset path id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_loader] bundle tileset path id=selbrume_all_sprite path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/selbrume_all_sprite.png
[runtime_loader] bundle tileset path id=grass_elements path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/grass_elements.png
[runtime_loader] bundle tileset path id=objectif path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/objectif.png
[runtime_loader] bundle tileset path id=fleurs_selbrume_de_toure_es path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/fleurs_selbrume_de_toure_es.png
[runtime_loader] bundle tileset path id=deep_water path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/deep_water.png
[runtime_loader] bundle tileset path id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_loader] bundle tileset path id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_loader] bundle tileset path id=beach_tile path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/beach_tile.png
[runtime_loader] bundle tileset path id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
00:00 +1: All tests passed!
```

## 10. Analyse exécutée

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_first_narrative_interaction_test.dart...
No issues found! (ran in 2.0s)
```

## 11. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_6.md
selbrume/project.json
selbrume/maps/Selbrume.json
```

Fichiers explicitement non modifiés :

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_5.md
reports/roadmap/phase_5/*
reports/roadmap/phase_6/p6_00_*.md
reports/roadmap/phase_6/p6_01_*.md
reports/roadmap/phase_6/p6_02_*.md
packages/map_core/lib/**
packages/map_gameplay/lib/**
packages/map_battle/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
examples/playable_runtime_host/lib/**
```

## 12. Roadmap Phase 6 mise à jour

Sections modifiées :

```text
Lot courant : ✅ P6-03 — Selbrume First Narrative Interaction V0

Prochain lot exact : P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0

Suivi des lots :
- ✅ P6-03 — Selbrume First Narrative Interaction V0
- ➡️ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0

P6-03 : ✅ terminé
P6-04 : ➡️ prochain lot exact
```

Résultat ajouté :

```text
## Résultat P6-03

selbrume/project.json est chargé via loadRuntimeMapBundle
start map retenue : Selbrume
spawn retenu : spawn
party/bag minimal seedé comme P6-02
interaction retenue : p6_03_intro_sign
scénario retenu : p6_03_first_interaction
preuve : ScenarioRuntimeExecutor.dispatch(entityInteract)
effet runtime observable : showMessage court
effet persistable : story flag p6.selbrume.first_interaction.seen
effet persistable : completed step p6.selbrume.first_interaction
roundtrip SaveData conserve flag, completed step, party et bag
```

## 13. Prochain lot exact

Prochain lot exact :

```text
P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
```

Justification :

```text
P6-01 a fixé le départ Selbrume/spawn.
P6-02 a fixé la party/bag minimale.
P6-03 a fixé une première interaction narrative courte et persistable.
Le golden slice peut maintenant avancer vers route 1, encounter et capture.
```

## 14. Ce qui n’a pas été fait

Non-objectifs respectés :

```text
pas de Maël final
pas de Lysa
pas de rival
pas de professeur
pas de starter scene
pas de choix de starter
pas de cinématique
pas de combat
pas de trainer
pas de reward
pas de capture
pas de transition route 1 obligatoire
pas de quête
pas de système de quêtes
pas de Scene Builder
pas de UI
pas de Boot Flow
pas d'audio
pas de validator pass complet
pas de runtime smoke complet
pas de P6-04
```

Limite honnête :

```text
La preuve est runtime-application via ScenarioRuntimeExecutor.
Elle ne prouve pas encore une UI interactive complète dans PlayableMapGame.
Elle ne prouve pas encore un dialogue Yarn final.
```

## 15. Evidence Pack

### Commandes exécutées

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume | sed -n '1,160p'
printf 'SELBRUME_STATUS_COUNT='
git status --short --untracked-files=all -- selbrume | wc -l
find packages examples -path '*test*' -type f | sort | rg 'scenario|event|dialogue|runtime|outcome|interaction'
rg -n "sourceEntityInteract|entityInteract|showMessage|ScenarioRuntimeExecutor|outcomeReceived|emitOutcome|storyFlags|consumedEventIds" packages examples
python3 -m json.tool selbrume/project.json >/dev/null && python3 -m json.tool selbrume/maps/Selbrume.json >/dev/null && echo "Selbrume JSON OK"
dart format packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
```

### Preuve que le test n’utilise pas l’ancien chemin Desktop

Commande :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie :

```text
Sortie : <vide>
```

### Contenu complet du test créé

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _spawnId = 'spawn';
const _saveId = 'p6_03_selbrume_first_narrative_interaction';
const _scenarioId = 'p6_03_first_interaction';
const _interactionEntityId = 'p6_03_intro_sign';
const _interactionFlagId = 'p6.selbrume.first_interaction.seen';
const _interactionStepId = 'p6.selbrume.first_interaction';
const _interactionMessage =
    'Bienvenue à Selbrume. Ceci est la première interaction narrative du golden slice.';

const _initialSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-03 triggers repo-local Selbrume first narrative interaction and persists its state',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _startMapId,
      );

      expect(bundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(bundle.map.id, _startMapId);
      expect(bundle.manifest.maps.first.id, 'route 1');
      expect(
        bundle.manifest.maps.map((entry) => entry.id),
        containsAll(<String>['route 1', _startMapId]),
      );

      final spawn = bundle.map.entities.singleWhere(
        (entity) => entity.id == _spawnId,
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final sign = bundle.map.entities.singleWhere(
        (entity) => entity.id == _interactionEntityId,
      );
      expect(sign.kind, MapEntityKind.sign);
      expect(sign.sign?.plainText, _interactionMessage);
      expect(sign.properties['contentStatus'], 'technical_golden_slice_v0');

      final scenario = bundle.manifest.scenarios.singleWhere(
        (candidate) => candidate.id == _scenarioId,
      );
      expect(scenario.scope, ScenarioScope.localEventFlow);
      expect(scenario.entryNodeId, 'start');
      expect(
        scenario.nodes.where((node) => node.type == ScenarioNodeType.start),
        hasLength(1),
      );
      final sourceNode = scenario.nodes.singleWhere(
        (node) => node.id == 'source',
      );
      expect(sourceNode.type, ScenarioNodeType.reference);
      expect(sourceNode.payload.actionKind, kScenarioSourceEntityInteract);
      expect(sourceNode.binding.mapId, _startMapId);
      expect(sourceNode.binding.entityId, _interactionEntityId);
      expect(
        scenario.nodes.map((node) => node.payload.actionKind),
        containsAll(<String>[
          kScenarioActionSetFlag,
          kScenarioActionCompleteStep,
          kScenarioActionShowMessage,
        ]),
      );

      var state = createNewGameStateFromMap(
        startMap: bundle.map,
        saveId: _saveId,
        playerName: 'P6 Tester',
        tileWidthPx: bundle.manifest.settings.tileWidth,
        tileHeightPx: bundle.manifest.settings.tileHeight,
      );
      state = _seedP6InitialState(state);

      expect(state.currentMapId, _startMapId);
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_captureItemId));
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_medicineItemId));
      expect(state.storyFlags.activeFlags, isNot(contains(_interactionFlagId)));
      expect(
        state.progression.completedStepIds,
        isNot(contains(_interactionStepId)),
      );

      final messages = <String>[];
      const executor = ScenarioRuntimeExecutor();
      final result = executor.dispatch(
        scenarios: bundle.manifest.scenarios,
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: _startMapId,
          entityId: _interactionEntityId,
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => false,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: messages.add,
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.message);
      expect(result.effect.message, _interactionMessage);
      expect(result.scenarioId, _scenarioId);
      expect(result.sourceNodeId, 'source');
      expect(result.stopNodeId, 'show_intro_message');
      expect(messages, <String>[_interactionMessage]);

      expect(state.storyFlags.activeFlags, contains(_interactionFlagId));
      expect(
        state.progression.completedStepIds,
        contains(_interactionStepId),
      );
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_captureItemId));
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_medicineItemId));

      final saveData = saveDataFromGameState(state);
      expect(saveData.progression.storyFlags, contains(_interactionFlagId));
      expect(
        saveData.progression.completedStepIds,
        contains(_interactionStepId),
      );

      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _startMapId);
      expect(reloaded.playerPosition, const GridPos(x: 17, y: 24));
      expect(reloaded.playerFacing, EntityFacing.south);
      expect(reloaded.party.members.single.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.single.knownMoveIds, _initialMoves);
      expect(reloaded.bag.entries.map((entry) => entry.itemId),
          contains(_captureItemId));
      expect(reloaded.bag.entries.map((entry) => entry.itemId),
          contains(_medicineItemId));
      expect(reloaded.storyFlags.activeFlags, contains(_interactionFlagId));
      expect(
        reloaded.progression.completedStepIds,
        contains(_interactionStepId),
      );
    },
  );
}

GameState _seedP6InitialState(GameState state) {
  const mutations = GameStateMutations();
  var next = mutations.givePokemon(
    state,
    pokemon: const PlayerPokemon(
      speciesId: _initialSpeciesId,
      natureId: 'hardy',
      abilityId: _initialAbilityId,
      level: 8,
      currentHp: 24,
      knownMoveIds: _initialMoves,
    ),
  );
  next = mutations.giveItem(next, _captureItemId, 5);
  next = mutations.giveItem(next, _medicineItemId, 2);
  return next;
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final candidate = File(
      p.join(current.path, 'selbrume', 'project.json'),
    );
    if (candidate.existsSync()) {
      return current;
    }

    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError('Could not find repo-local selbrume/project.json');
    }
    current = parent;
  }
}
```

### Sortie format

Commande :

```bash
dart format packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie finale :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Contrôles explicites

```text
Aucun code production modifié : oui.
Aucun fichier packages/map_runtime/lib modifié : oui.
Aucun fichier packages/map_core/lib modifié : oui.
Aucun fichier packages/map_gameplay/lib modifié : oui.
Aucun test hors scope modifié : oui.
Aucun contenu final Selbrume créé : oui.
Aucune UI créée : oui.
Aucun combat créé : oui.
Aucun trainer créé : oui.
Aucune capture créée : oui.
Aucun P6-04 lancé : oui.
Ancien chemin Desktop absent du test actif : oui.
```

### Vérifications finales

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
MVP Selbrume/road_map_phase_6.md |  61 ++++++++--
selbrume/maps/Selbrume.json      |  29 ++++-
selbrume/project.json            | 252 ++++++++++++++++++++++++++++++++++++++-
3 files changed, 332 insertions(+), 10 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
MVP Selbrume/road_map_phase_6.md
selbrume/maps/Selbrume.json
selbrume/project.json
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M "MVP Selbrume/road_map_phase_6.md"
 M selbrume/maps/Selbrume.json
 M selbrume/project.json
?? packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
?? reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
```

## 16. Auto-review critique

- Ai-je utilisé le chemin repo-local selbrume ? Oui, le test localise `selbrume/project.json` dans le repo.
- Ai-je évité l'ancien chemin Desktop ? Oui, le test ne contient pas `/Users/karim/Desktop/selbrume`.
- Ai-je réutilisé l'existant si possible ? Oui, l'audit a vérifié `test`, mais il était incomplet.
- Ai-je créé seulement une interaction courte ? Oui, un panneau technique et un scénario court.
- Ai-je évité de créer un PNJ final ou un dialogue final ? Oui.
- Ai-je modifié selbrume/ ? Oui : `project.json` et `maps/Selbrume.json`, strictement pour brancher l'interaction.
- Ai-je modifié du code production ? Non.
- Ai-je créé seulement un test ciblé ? Oui.
- Ai-je prouvé une exécution runtime ou seulement un contrat ? Exécution runtime-application via `ScenarioRuntimeExecutor`.
- Ai-je prouvé la persistance si GameState est muté ? Oui, `SaveData` roundtrip vérifie flag et step.
- Ai-je lancé P6-04 ? Non.
- Ai-je créé du contenu final ? Non.
- Ai-je fixé un prochain lot exact unique ? Oui : P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0.
