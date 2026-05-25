# P6-04-bis — Selbrume Git Worktree Attribution / Diff Cleanup

## 1. Résumé exécutif

Décision retenue : **option B**.

Le problème signalé par P6-04 n'existe plus sous forme de diff courant : l'état
Git actuel est propre au Gate 0, et les fichiers `grant` sont désormais suivis
par Git.

Attribution établie :

```text
selbrume/assets/tilesets/grant.png
-> introduit par 02fbb1db add grant

selbrume/project.json
selbrume/maps/route 1.json
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
MVP Selbrume/road_map_phase_6.md
-> introduits ou modifiés ensemble par cbfec67e
```

Impact vérifié :

```text
P6-04 : passe encore
P6-02 : passe encore
P6-01 : échoue, car route 1 contient maintenant l'entité NPC grant
P6-03 : échoue, car p6_03_first_interaction n'est plus présent dans project.json
```

Conclusion :

```text
Ne pas passer directement à P6-05.
Prochain lot exact recommandé : P6-04-ter — Selbrume Grant Diff Attribution / P6-03 Regression Fix.
```

## 2. Pourquoi ce bis est nécessaire

Le rapport P6-04 avait un Gate 0 propre, mais un statut final contenant :

```text
 M "MVP Selbrume/road_map_phase_6.md"
 M "selbrume/maps/route 1.json"
 M selbrume/project.json
?? packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
?? reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
?? selbrume/assets/tilesets/grant.png
```

Ces changements n'étaient pas tous dans le scope P6-04. Le bis devait donc
déterminer s'ils étaient compatibles avec la suite ou s'ils cassaient une preuve
précédente.

## 3. Gate 0

Commandes exécutées depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties :

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
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
8f40c1f6 update gitignore
02fbb1db add grant
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
25d623ca Ajoute selbrume/assets/pokemon/sprites/ à .gitignore
951b5e6b Ajoute P6-02 : Selbrume Initial Party/Bag Setup (test et rapport)
1886d1bf Ajoute P6-01 : Existing Selbrume Loadability Start Map Contract (test et rapport)
```

État Selbrume ciblé :

```bash
git status --short --untracked-files=all -- selbrume
git diff --stat -- selbrume/project.json "selbrume/maps/route 1.json"
git diff --name-only -- selbrume/project.json "selbrume/maps/route 1.json"
test -f "selbrume/assets/tilesets/grant.png" && echo "grant.png exists" || echo "grant.png missing"
```

Sorties :

```text
git status --short --untracked-files=all -- selbrume
Sortie : <vide>

git diff --stat -- selbrume/project.json "selbrume/maps/route 1.json"
Sortie : <vide>

git diff --name-only -- selbrume/project.json "selbrume/maps/route 1.json"
Sortie : <vide>

test -f "selbrume/assets/tilesets/grant.png" && echo "grant.png exists" || echo "grant.png missing"
grant.png exists
```

Preuve que les chemins concernés sont suivis par Git :

```bash
git ls-files --stage -- "MVP Selbrume/road_map_phase_6.md" packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md selbrume/project.json "selbrume/maps/route 1.json" selbrume/assets/tilesets/grant.png
```

Sortie :

```text
100644 f50cf904e42cf88aeb9bba3fcbb4b7f7dde061fc 0	MVP Selbrume/road_map_phase_6.md
100644 50c86c2013fd257922f07287e09faf1f37691a92 0	packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
100644 f7348ad4afd74ff315d6f45940a869c864acdd8a 0	reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
100644 c25384ecd02fcdb07b41ac7542bee098cf00ad68 0	selbrume/assets/tilesets/grant.png
100644 f16eca6c46ab9234c5db01fc529352aa9d9bde52 0	selbrume/maps/route 1.json
100644 c354bbaff1e660d00723c4431a01c242611f6ebe 0	selbrume/project.json
```

Historique ciblé :

```bash
git log --oneline -- selbrume/project.json "selbrume/maps/route 1.json" selbrume/assets/tilesets/grant.png | sed -n '1,12p'
```

Sortie :

```text
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
02fbb1db add grant
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
fbc32f8b Ajoute les sprites Pokémon pour Selbrume
```

## 4. Diffs Selbrume observés

Diffs courants demandés :

```bash
git diff -- selbrume/project.json
git diff -- "selbrume/maps/route 1.json"
```

Sorties :

```text
git diff -- selbrume/project.json
Sortie : <vide>

git diff -- "selbrume/maps/route 1.json"
Sortie : <vide>
```

Conclusion :

```text
Les changements Selbrume mentionnés par P6-04 ne sont plus dans le diff courant.
Ils sont désormais dans l'historique Git.
```

## 5. Attribution de selbrume/project.json

Recherche courante :

```bash
rg -n "p6_03_first_interaction|p6_03_intro_sign" selbrume/project.json
```

Sortie :

```text
Sortie : <vide>
```

Recherche sur la map Selbrume :

```bash
rg -n "p6_03_first_interaction|p6_03_intro_sign" "selbrume/maps/Selbrume.json"
```

Sortie :

```text
67539:      "id": "p6_03_intro_sign",
```

Résumé JSON courant :

```bash
python3 - <<'PY'
import json
from pathlib import Path
project = json.loads(Path('selbrume/project.json').read_text())
route = json.loads(Path('selbrume/maps/route 1.json').read_text())
print('project.scenario_ids =', [s.get('id') for s in project.get('scenarios', [])])
print('project.has_p6_03_first_interaction =', any(s.get('id') == 'p6_03_first_interaction' for s in project.get('scenarios', [])))
print('project.trainer_ids =', [t.get('id') for t in project.get('trainers', [])])
print('project.tileset_grant =', [t for t in project.get('tilesets', []) if t.get('id') == 'grant'])
print('project.character_grant =', [c.get('id') for c in project.get('characters', []) if c.get('id') == 'grant'])
print('project.encounter_tables =', [(t.get('id'), t.get('encounterKind'), t.get('entries')) for t in project.get('encounterTables', [])])
print('route.entity_ids =', [(e.get('id'), e.get('kind'), (e.get('npc') or {}).get('trainerId')) for e in route.get('entities', [])])
print('route.connections =', route.get('connections'))
print('route.encounter_zones =', [(z.get('id'), z.get('kind'), (z.get('encounter') or {}).get('encounterTableId'), (z.get('encounter') or {}).get('encounterKind')) for z in route.get('gameplayZones', [])])
PY
```

Sortie :

```text
project.scenario_ids = ['global_story', 'test']
project.has_p6_03_first_interaction = False
project.trainer_ids = ['grant']
project.tileset_grant = [{'id': 'grant', 'name': 'grant', 'relativePath': 'assets/tilesets/grant.png', 'scope': 'global', 'groupId': None, 'folderId': 'sprites', 'sortOrder': 4, 'isWorldTileset': False, 'elementGroups': [], 'paletteEntries': []}]
project.character_grant = ['grant']
project.encounter_tables = [('grass_path_route_1', 'walk', [{'speciesId': 'pidgeotto', 'minLevel': 1, 'maxLevel': 5, 'weight': 1}])]
route.entity_ids = [('grant', 'npc', 'grant')]
route.connections = [{'direction': 'west', 'targetMapId': 'Selbrume', 'offset': 0}]
route.encounter_zones = [('zone', 'encounter', 'grass_path_route_1', 'walk'), ('zone_1', 'encounter', 'grass_path_route_1', 'walk'), ('zone_2', 'encounter', 'grass_path_route_1', 'walk'), ('zone_3', 'encounter', 'grass_path_route_1', 'walk'), ('zone_4', 'encounter', 'grass_path_route_1', 'walk')]
```

Diff historique ciblé du commit `cbfec67e` :

```bash
git show --unified=6 cbfec67e -- selbrume/project.json | rg -n -C 10 "grant|p6_03|scenarios|trainers|tilesets|grass_path_route_1|pidgeotto"
```

Sortie :

```text
10-+++ b/selbrume/project.json
11-@@ -515,12 +515,24 @@
12-       "groupId": null,
13-       "folderId": "path",
14-       "sortOrder": 1,
15-       "isWorldTileset": false,
16-       "elementGroups": [],
17-       "paletteEntries": []
18-+    },
19-+    {
20:+      "id": "grant",
21:+      "name": "grant",
22:+      "relativePath": "assets/tilesets/grant.png",
23-+      "scope": "global",
24-+      "groupId": null,
25-+      "folderId": "sprites",
26-+      "sortOrder": 4,
27-+      "isWorldTileset": false,
28-+      "elementGroups": [],
29-+      "paletteEntries": []
30-     }
31-   ],
32-   "elementCategories": [
--
35-       "name": "batiments",
36-@@ -12774,265 +12786,67 @@
37-         }
38-       ],
39-       "metadata": {
40-         "authoring.cutsceneSchema": "cutscene_studio_v2",
41-         "authoring.cutsceneFlow": "{\"v\":1,\"seq\":[{\"t\":\"b\",\"b\":{\"id\":\"block_dialogue_1\",\"kind\":\"dialogue\",\"actorId\":null,\"dialogueId\":null,\"messageText\":null,\"scriptId\":null,\"flagName\":null,\"outcomeId\":null,\"resultLabel\":null,\"resultScope\":null,\"destinationTargetKind\":null,\"destinationTargetId\":null,\"transitionMapId\":null,\"transitionWarpId\":null,\"facingDirection\":null,\"durationMs\":null,\"waitForCompletion\":null,\"choiceOptions\":[]}}]}"
42-       }
43--    },
44--    {
45:-      "id": "p6_03_first_interaction",
46--      "name": "P6-03 First Narrative Interaction",
47--      "description": "Interaction narrative technique courte pour le golden slice V0.",
48--      "scope": "localEventFlow",
49--      "entryNodeId": "start",
50--      "declaredOutcomes": [],
51--      "activationCondition": null,
52--      "nodes": [
53--        {
54--          "id": "start",
55--          "type": "start",
--
86--          "type": "reference",
87--          "title": "Source",
88--          "description": "",
89--          "position": {
90--            "x": 0.0,
91--            "y": 0.0
92--          },
93--          "binding": {
94--            "mapId": "Selbrume",
95--            "eventId": null,
96:-            "entityId": "p6_03_intro_sign",
97--            "warpId": null,
98--            "triggerId": null,
99--            "trainerId": null,
100--            "dialogueId": null,
101--            "scriptId": null,
102--            "outcomeId": null,
103--            "flagName": null,
104--            "variableName": null
105--          },
106--          "payload": {
--
270--        {
271--          "id": "edge_complete_intro_step_show_intro_message",
272--          "fromNodeId": "complete_intro_step",
273--          "toNodeId": "show_intro_message",
274--          "label": "",
275--          "kind": "next",
276--          "order": 0,
277--          "metadata": {}
278-+    }
279-+  ],
280:+  "trainers": [
281-+    {
282:+      "id": "grant",
283:+      "name": "grant",
284:+      "trainerClass": "grant",
285-+      "battleDifficulty": 10,
286-+      "battleBackgroundRelativePath": null,
287:+      "characterId": "grant",
288-+      "portraitElementId": null,
289-+      "battleThemeId": null,
290-+      "victoryThemeId": null,
291-+      "team": [
292-+        {
293-+          "speciesId": "bulbasaur",
294-+          "level": 1,
295-+          "moves": [
296-+            "growl",
297-+            "tackle"
--
334-+          "shiny": false
335-         }
336-       ],
337--      "metadata": {
338--        "phase": "P6-03",
339--        "contentStatus": "technical_golden_slice_v0"
340--      }
341-+      "tags": []
342-     }
343-   ],
344:-  "trainers": [],
345-   "characters": [
346-     {
347-       "id": "vova",
348-       "name": "vova",
349-       "tilesetId": "vova",
350-       "frameWidth": 2,
351-@@ -13983,12 +13797,251 @@
352-             }
353-           ]
354-         }
355-       ],
356-       "tags": [],
357-       "sortOrder": 0
358-+    },
359-+    {
360:+      "id": "grant",
361:+      "name": "grant",
362:+      "tilesetId": "grant",
363-+      "frameWidth": 2,
364-+      "frameHeight": 2,
365-+      "animations": [
366-+        {
367-+          "state": "idle",
368-+          "direction": "south",
369-+          "frames": [
370-+            {
371-+              "source": {
372-+                "x": 0,
```

Attribution :

```text
Le projet courant contient grant comme tileset, character et trainer.
Le même commit retire le scénario p6_03_first_interaction ajouté par P6-03.
Ce changement prépare vraisemblablement P6-05, mais il introduit une régression P6-03.
```

## 6. Attribution de selbrume/maps/route 1.json

Recherche courante :

```bash
rg -n "grant|trainer|encounter|grass_path_route_1|pidgeotto|connections|gameplayZones" "selbrume/maps/route 1.json"
```

Sortie :

```text
13355:      "id": "grant",
13356:      "name": "grant",
13367:        "displayName": "grant",
13371:        "trainerId": "grant",
13393:  "connections": [
13402:  "gameplayZones": [
13406:      "kind": "encounter",
13418:      "encounter": {
13419:        "encounterTableId": "grass_path_route_1",
13420:        "encounterKind": "walk",
13431:      "kind": "encounter",
13443:      "encounter": {
13444:        "encounterTableId": "grass_path_route_1",
13445:        "encounterKind": "walk",
13456:      "kind": "encounter",
13468:      "encounter": {
13469:        "encounterTableId": "grass_path_route_1",
13470:        "encounterKind": "walk",
13481:      "kind": "encounter",
13493:      "encounter": {
13494:        "encounterTableId": "grass_path_route_1",
13495:        "encounterKind": "walk",
13506:      "kind": "encounter",
13518:      "encounter": {
13519:        "encounterTableId": "grass_path_route_1",
13520:        "encounterKind": "walk",
```

Diff historique ciblé du commit `cbfec67e` :

```bash
git show --unified=6 cbfec67e -- "selbrume/maps/route 1.json" | rg -n -C 12 "grant|trainerId|gameplayZones|grass_path_route_1|connections|encounter"
```

Sortie :

```text
9---- a/selbrume/maps/route 1.json	
10-+++ b/selbrume/maps/route 1.json	
11-@@ -13347,13 +13347,52 @@
12-       "animation": null,
13-       "shadowOverride": null,
14-       "behaviors": [],
15-       "properties": {}
16-     }
17-   ],
18--  "entities": [],
19-+  "entities": [
20-+    {
21:+      "id": "grant",
22:+      "name": "grant",
23-+      "kind": "npc",
24-+      "pos": {
25-+        "x": 24,
26-+        "y": 20
27-+      },
28-+      "size": {
29-+        "width": 2,
30-+        "height": 2
31-+      },
32-+      "npc": {
33:+        "displayName": "grant",
34-+        "dialogue": null,
35-+        "facing": "north",
36-+        "visualElementId": "",
37:+        "trainerId": "grant",
38-+        "lineOfSightRange": 12,
39-+        "defeatDialogueRef": null,
40-+        "characterId": null,
41-+        "movement": {
42-+          "mode": "idle",
43-+          "waypoints": [],
44-+          "loop": true,
45-+          "pauseDurationMs": 0,
46-+          "stepDurationMs": 200
47-+        },
48-+        "visibilityRule": null,
49-+        "conditionalDialogues": []
50-+      },
51-+      "sign": null,
52-+      "item": null,
53-+      "spawn": null,
54-+      "editorVisual": null,
55-+      "blocksMovement": true,
56-+      "properties": {}
57-+    }
58-+  ],
59:   "connections": [
60-     {
61-       "direction": "west",
62-       "targetMapId": "Selbrume",
63-       "offset": 0
64-     }
```

Attribution :

```text
route 1 gagne un NPC grant avec trainerId=grant.
Les zones encounter grass_path_route_1 et la connexion west -> Selbrume restent présentes.
Le changement prépare P6-05, mais il casse l'assertion P6-01 qui attendait routeBundle.map.entities vide.
```

## 7. Attribution de selbrume/assets/tilesets/grant.png

Preuves fichier :

```bash
file selbrume/assets/tilesets/grant.png
ls -lh selbrume/assets/tilesets/grant.png
git show --stat --oneline 02fbb1db -- selbrume/assets/tilesets/grant.png
```

Sorties :

```text
selbrume/assets/tilesets/grant.png: PNG image data, 256 x 256, 8-bit colormap, non-interlaced
-rw-r--r--@ 1 karim  staff   3.0K Apr  3 18:52 selbrume/assets/tilesets/grant.png
02fbb1db add grant
 selbrume/assets/tilesets/grant.png | Bin 0 -> 3119 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
```

Attribution :

```text
grant.png est un asset PNG suivi par Git.
Il est référencé par project.json via tileset id grant.
Il est probablement lié au trainer/NPC grant, donc au futur P6-05.
```

## 8. Impact sur P6-04

P6-04 reste fonctionnel sur l'état courant.

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
00:00 +0: P6-04 triggers repo-local Route 1 encounter and persists a minimal capture
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644871
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=2
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
[runtime_loader] project manifest read ok bytes=644871
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=2
[runtime_loader] bundle map resolved mapId=route 1 relativePath=maps/route 1.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file read ok bytes=223274
[runtime_loader] map validated id=route 1 size=45x45 layers=6 entities=1 placedElements=68 warps=0 triggers=0
[runtime_loader] bundle tilesets collected ids=arbre_pixellab,route_1_1,haute_herbe,pavement_path,gros_sol_herbre,vova,grant
[runtime_loader] bundle tileset path id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_loader] bundle tileset path id=route_1_1 path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/route_1_1.png
[runtime_loader] bundle tileset path id=haute_herbe path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/haute_herbe.png
[runtime_loader] bundle tileset path id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_loader] bundle tileset path id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_loader] bundle tileset path id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_loader] bundle tileset path id=grant path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/grant.png
[runtime_loader] bundle load ok mapId=route 1 projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=7
00:00 +1: All tests passed!
```

Conclusion :

```text
Les changements grant ne cassent pas la preuve P6-04.
```

## 9. Impact sur P6-03

P6-03 est cassé sur l'état courant.

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie :

```text
00:00 +0: P6-03 triggers repo-local Selbrume first narrative interaction and persists its state
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644871
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=2
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
00:00 +0 -1: P6-03 triggers repo-local Selbrume first narrative interaction and persists its state [E]
  Bad state: No element
  dart:collection                                               ListBase.singleWhere
  test/p6_selbrume_first_narrative_interaction_test.dart 65:50  main.<fn>
  
00:00 +0 -1: Some tests failed.
```

Racine établie :

```text
La ligne 65 cherche p6_03_first_interaction dans bundle.manifest.scenarios.
Le project.json courant contient seulement ['global_story', 'test'].
Le scénario P6-03 est donc absent du manifest courant.
```

Extrait test :

```text
65	      final scenario = bundle.manifest.scenarios.singleWhere(
66	        (candidate) => candidate.id == _scenarioId,
```

## 10. Impact probable sur P6-05

Le contenu `grant` semble préparatoire pour P6-05 :

```text
project.json contient trainer grant
project.json contient character grant
project.json contient tileset grant
route 1 contient NPC grant avec trainerId=grant
grant.png existe
```

Mais il ne faut pas démarrer P6-05 tant que les preuves P6-01/P6-03 ne sont pas
réconciliées avec ce nouvel état.

## 11. Tests et régressions relancés

### P6-01

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
00:00 +0: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644871
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=2
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
[runtime_loader] project manifest read ok bytes=644871
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=2
[runtime_loader] bundle map resolved mapId=route 1 relativePath=maps/route 1.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file read ok bytes=223274
[runtime_loader] map validated id=route 1 size=45x45 layers=6 entities=1 placedElements=68 warps=0 triggers=0
[runtime_loader] bundle tilesets collected ids=arbre_pixellab,route_1_1,haute_herbe,pavement_path,gros_sol_herbre,vova,grant
[runtime_loader] bundle tileset path id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_loader] bundle tileset path id=route_1_1 path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/route_1_1.png
[runtime_loader] bundle tileset path id=haute_herbe path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/haute_herbe.png
[runtime_loader] bundle tileset path id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_loader] bundle tileset path id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_loader] bundle tileset path id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_loader] bundle tileset path id=grant path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/grant.png
[runtime_loader] bundle load ok mapId=route 1 projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=7
00:00 +0 -1: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn [E]
  Expected: empty
    Actual: [
              _$MapEntityImpl:MapEntity(id: grant, name: grant, kind: MapEntityKind.npc, pos: GridPos(x: 24, y: 20), size: GridSize(width: 2, height: 2), npc: MapEntityNpcData(displayName: grant, dialogue: null, facing: EntityFacing.north, visualElementId: , trainerId: grant, lineOfSightRange: 12, defeatDialogueRef: null, characterId: null, movement: MapEntityNpcMovementConfig(mode: MapEntityNpcMovementMode.idle, waypoints: [], loop: true, pauseDurationMs: 0, stepDurationMs: 200), visibilityRule: null, conditionalDialogues: []), sign: null, item: null, spawn: null, editorVisual: null, blocksMovement: true, properties: {})
            ]
  
  package:matcher                                                          expect
  package:flutter_test/src/widget_tester.dart 473:18                       expect
  test/p6_existing_selbrume_loadability_start_map_contract_test.dart 40:7  main.<fn>
  
00:00 +0 -1: Some tests failed.
```

### P6-02

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
```

Sortie :

```text
00:00 +0: P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=644871
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=2
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

### P6-03

Sortie déjà reproduite en section 9.

### Analyse ciblée P6-04

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_route_1_encounter_capture_golden_slice_test.dart...

No issues found! (ran in 2.3s)
```

## 12. Décision recommandée

Décision : **option B**.

```text
Les changements grant cassent au moins deux preuves précédentes :
- P6-01, car route 1 n'est plus vide ;
- P6-03, car p6_03_first_interaction a disparu de project.json.
```

Recommandation :

```text
Ne pas lancer P6-05.
Créer un micro-lot P6-04-ter pour réconcilier grant avec les contrats P6-01/P6-03.
```

## 13. Roadmap Phase 6

`MVP Selbrume/road_map_phase_6.md` a été modifiée, car la décision B impose de
changer le prochain lot exact.

Sections modifiées principales :

```text
Lot courant : ✅ P6-04-bis — Selbrume Git Worktree Attribution / Diff Cleanup

Prochain lot exact : P6-04-ter — Selbrume Grant Diff Attribution / P6-03 Regression Fix

- ✅ P6-04-bis — Selbrume Git Worktree Attribution / Diff Cleanup
- ➡️ P6-04-ter — Selbrume Grant Diff Attribution / P6-03 Regression Fix
- ⏳ P6-05 — Selbrume First Trainer Battle Golden Slice V0
```

Diff roadmap :

```text
diff --git a/MVP Selbrume/road_map_phase_6.md b/MVP Selbrume/road_map_phase_6.md
index f50cf904..5a65295e 100644
--- a/MVP Selbrume/road_map_phase_6.md	
+++ b/MVP Selbrume/road_map_phase_6.md	
@@ -18,9 +18,9 @@ Ancien chemin historique :
 /Users/karim/Desktop/selbrume
 ```
 
-Lot courant : ✅ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
+Lot courant : ✅ P6-04-bis — Selbrume Git Worktree Attribution / Diff Cleanup
 
-Prochain lot exact : P6-05 — Selbrume First Trainer Battle Golden Slice V0
+Prochain lot exact : P6-04-ter — Selbrume Grant Diff Attribution / P6-03 Regression Fix
```

## 14. Ce qui n’a pas été fait

```text
Aucun nettoyage Git.
Aucun git restore/reset/checkout/clean.
Aucun fichier selbrume/ modifié.
Aucun code modifié.
Aucun test modifié.
Aucun P6-05 lancé.
Aucun contenu trainer battle créé.
Aucun contenu final Selbrume créé.
```

## 15. Evidence Pack

Sources lues principales :

```text
AGENTS.md
agent_rules.md
skills/README.md
pokemap_roadmap_mecaniques_fangame.md
MVP Selbrume/road_map_phase_6.md
reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Commandes exécutées :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
git status --short --untracked-files=all -- selbrume
git diff --stat -- selbrume/project.json "selbrume/maps/route 1.json"
git diff --name-only -- selbrume/project.json "selbrume/maps/route 1.json"
test -f "selbrume/assets/tilesets/grant.png" && echo "grant.png exists" || echo "grant.png missing"
git diff -- selbrume/project.json
git diff -- "selbrume/maps/route 1.json"
rg -n "p6_03_first_interaction|p6_03_intro_sign" selbrume/project.json
rg -n "p6_03_first_interaction|p6_03_intro_sign" "selbrume/maps/Selbrume.json"
rg -n "grant|trainer|encounter|grass_path_route_1|pidgeotto|connections|gameplayZones" "selbrume/maps/route 1.json"
file selbrume/assets/tilesets/grant.png
ls -lh selbrume/assets/tilesets/grant.png
git show --stat --oneline --name-only cbfec67e -- selbrume/project.json "selbrume/maps/route 1.json" packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md "MVP Selbrume/road_map_phase_6.md"
git show --stat --oneline --name-only 02fbb1db -- selbrume/assets/tilesets/grant.png
git show --stat --oneline --name-only 91cb80f9 -- selbrume/project.json "selbrume/maps/Selbrume.json" packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md "MVP Selbrume/road_map_phase_6.md"
python3 - <<'PY' ...
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Preuve que les tests actifs ne référencent pas l'ancien chemin Desktop :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie :

```text
Sortie : <vide>
```

Fichiers créés :

```text
reports/roadmap/phase_6/p6_04_bis_selbrume_git_worktree_attribution.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_6.md
```

Fichiers Selbrume modifiés par ce bis :

```text
Sortie : <vide>
```

Contrôles explicites :

```text
Aucun fichier Selbrume n'a été modifié par ce bis.
Aucun code n'a été modifié par ce bis.
Aucun test n'a été modifié par ce bis.
P6-05 n'a pas été lancé.
```

Vérifications finales :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sorties :

```text
git diff --check
Sortie : <vide>

git diff --stat
 MVP Selbrume/road_map_phase_6.md | 73 ++++++++++++++++++++++++++++++++++++----
 1 file changed, 67 insertions(+), 6 deletions(-)

git diff --name-only
MVP Selbrume/road_map_phase_6.md

git status --short --untracked-files=all
 M "MVP Selbrume/road_map_phase_6.md"
?? reports/roadmap/phase_6/p6_04_bis_selbrume_git_worktree_attribution.md
```

## 16. Auto-review critique

- Ai-je modifié selbrume/ ? Non.
- Ai-je modifié du code ? Non.
- Ai-je modifié des tests ? Non.
- Ai-je lancé P6-05 ? Non.
- Ai-je attribué project.json précisément ? Oui : changement suivi par Git, commit `cbfec67e`, ajout grant et retrait du scénario P6-03.
- Ai-je attribué route 1 précisément ? Oui : changement suivi par Git, commit `cbfec67e`, ajout NPC grant.
- Ai-je attribué grant.png précisément ? Oui : fichier PNG suivi par Git, commit `02fbb1db`.
- Ai-je vérifié l'impact sur P6-03 ? Oui : test P6-03 relancé, échec reproduit, cause reliée à l'absence du scénario.
- Ai-je vérifié l'impact sur P6-04 ? Oui : test P6-04 relancé, passe.
- Ai-je recommandé clairement passer / ne pas passer à P6-05 ? Oui : ne pas passer directement à P6-05.
- Ai-je laissé la roadmap inchangée sauf nécessité ? Non, elle a été modifiée uniquement parce que la décision B impose un prochain lot correctif.
