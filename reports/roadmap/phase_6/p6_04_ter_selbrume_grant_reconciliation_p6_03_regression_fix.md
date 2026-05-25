# P6-04-ter — Selbrume Grant Reconciliation / P6-03 Regression Fix

## 1. Résumé exécutif

P6-04-ter est concluant.

Grant est conservé comme contenu utilisateur volontaire fourni par Karim :

```text
project.json contient toujours trainer grant
project.json contient toujours character grant
project.json contient toujours tileset grant
route 1 contient toujours l'entité NPC grant avec trainerId=grant
selbrume/assets/tilesets/grant.png existe toujours
```

Corrections réalisées :

```text
p6_03_first_interaction restauré dans selbrume/project.json
P6-01 adapté à route 1 contenant désormais Grant
P6-01 / P6-02 / P6-03 / P6-04 relancés
```

P6-05 n'a pas été lancé.

Prochain lot exact :

```text
P6-05 — Selbrume First Trainer Battle Golden Slice V0
```

## 2. Pourquoi ce ter est nécessaire

P6-04-bis a établi que Grant était présent et suivi par Git, mais que deux
preuves précédentes étaient cassées :

```text
P6-01 échouait car route 1 n'était plus vide.
P6-03 échouait car p6_03_first_interaction était absent de project.json.
```

Karim a confirmé que Grant est volontaire :

```text
Grant ne doit pas être supprimé.
Grant doit être traité comme contenu utilisateur légitime.
```

Le bon correctif était donc de réconcilier les tests et la donnée narrative, pas
de retirer Grant.

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
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
8f40c1f6 update gitignore
02fbb1db add grant
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
25d623ca Ajoute selbrume/assets/pokemon/sprites/ à .gitignore
951b5e6b Ajoute P6-02 : Selbrume Initial Party/Bag Setup (test et rapport)
```

Vérification Selbrume :

```bash
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume
```

Sorties :

```text
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists

git status --short --untracked-files=all -- selbrume
Sortie : <vide>
```

Vérification Grant et P6-03 avant correction :

```bash
rg -n "grant|trainerId|p6_03_first_interaction|p6_03_intro_sign|p6\\.selbrume\\.first_interaction" selbrume/project.json "selbrume/maps/Selbrume.json" "selbrume/maps/route 1.json"
test -f "selbrume/assets/tilesets/grant.png" && echo "grant.png exists" || echo "grant.png missing"
```

Sorties :

```text
selbrume/maps/route 1.json:13355:      "id": "grant",
selbrume/maps/route 1.json:13356:      "name": "grant",
selbrume/maps/route 1.json:13367:        "displayName": "grant",
selbrume/maps/route 1.json:13371:        "trainerId": "grant",
selbrume/project.json:523:      "id": "grant",
selbrume/project.json:524:      "name": "grant",
selbrume/project.json:525:      "relativePath": "assets/tilesets/grant.png",
selbrume/project.json:12555:            "trainerId": null,
selbrume/project.json:12586:            "trainerId": null,
selbrume/project.json:12649:            "trainerId": null,
selbrume/project.json:12680:            "trainerId": null,
selbrume/project.json:12711:            "trainerId": null,
selbrume/project.json:12742:            "trainerId": null,
selbrume/project.json:12796:      "id": "grant",
selbrume/project.json:12797:      "name": "grant",
selbrume/project.json:12798:      "trainerClass": "grant",
selbrume/project.json:12801:      "characterId": "grant",
selbrume/project.json:13805:      "id": "grant",
selbrume/project.json:13806:      "name": "grant",
selbrume/project.json:13807:      "tilesetId": "grant",
selbrume/maps/Selbrume.json:67539:      "id": "p6_03_intro_sign",
grant.png exists
```

Conclusion Gate 0 :

```text
Grant existe.
p6_03_intro_sign existe.
p6_03_first_interaction est absent de project.json au Gate 0.
```

## 4. Décision sur Grant

Décision :

```text
Grant est un contenu utilisateur volontaire, ajouté par Karim.
P6-04-ter ne le supprime pas.
Grant est probablement préparatoire au premier trainer battle P6-05.
```

Contrôle après correction :

```text
trainer grant : conservé
character grant : conservé
tileset grant : conservé
NPC route 1 grant : conservé
grant.png : conservé
```

## 5. Correction P6-03

RED avant correction :

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

Correction :

```text
p6_03_first_interaction réintroduit dans selbrume/project.json.
Le bloc vient du scénario technique P6-03 historique.
Selbrume.json n'a pas été modifié car p6_03_intro_sign existait encore.
```

Preuve après correction :

```bash
python3 - <<'PY'
import json
from pathlib import Path
project=json.loads(Path('selbrume/project.json').read_text())
scenario=[s for s in project.get('scenarios',[]) if s.get('id')=='p6_03_first_interaction']
print('scenario_count=', len(scenario))
if scenario:
    print('scenario_scope=', scenario[0].get('scope'))
    print('start_nodes=', [n.get('id') for n in scenario[0].get('nodes',[]) if n.get('type')=='start'])
    print('action_kinds=', [n.get('payload',{}).get('actionKind') for n in scenario[0].get('nodes',[])])
print('trainer_ids=', [t.get('id') for t in project.get('trainers', [])])
PY
```

Sortie :

```text
scenario_count= 1
scenario_scope= localEventFlow
start_nodes= ['start']
action_kinds= [None, 'sourceEntityInteract', 'setFlag', 'completeStep', 'showMessage', None]
trainer_ids= ['grant']
```

Extrait complet du scénario restauré :

```json
{
  "id": "p6_03_first_interaction",
  "name": "P6-03 First Narrative Interaction",
  "description": "Interaction narrative technique courte pour le golden slice V0.",
  "scope": "localEventFlow",
  "entryNodeId": "start",
  "declaredOutcomes": [],
  "activationCondition": null,
  "nodes": [
    {"id": "start", "type": "start"},
    {"id": "source", "type": "reference", "actionKind": "sourceEntityInteract", "mapId": "Selbrume", "entityId": "p6_03_intro_sign"},
    {"id": "set_seen_flag", "type": "action", "actionKind": "setFlag", "flagName": "p6.selbrume.first_interaction.seen"},
    {"id": "complete_intro_step", "type": "action", "actionKind": "completeStep", "stepId": "p6.selbrume.first_interaction"},
    {"id": "show_intro_message", "type": "action", "actionKind": "showMessage", "message": "Bienvenue à Selbrume. Ceci est la première interaction narrative du golden slice."},
    {"id": "end", "type": "end"}
  ],
  "edges": [
    "start -> source",
    "source -> set_seen_flag",
    "set_seen_flag -> complete_intro_step",
    "complete_intro_step -> show_intro_message",
    "show_intro_message -> end"
  ],
  "metadata": {
    "phase": "P6-03",
    "contentStatus": "technical_golden_slice_v0"
  }
}
```

## 6. Correction P6-01

RED avant correction :

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

Correction :

```text
L'assertion routeBundle.map.entities isEmpty est remplacée.
Le test vérifie maintenant que route 1 charge, que Grant existe comme NPC,
que trainerId=grant et que le manifest contient trainer grant.
Le contrat Selbrume/spawn reste inchangé.
```

Diff ciblé du test P6-01 :

```text
diff --git a/packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart b/packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
index 5936c7d3..86e2cdc6 100644
--- a/packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
+++ b/packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
@@ -37,7 +37,15 @@ void main() {
 
       expect(selbrumeBundle.map.id, 'Selbrume');
       expect(routeBundle.map.id, 'route 1');
-      expect(routeBundle.map.entities, isEmpty);
+      final grant = routeBundle.map.entities.singleWhere(
+        (entity) => entity.id == 'grant',
+      );
+      expect(grant.kind, MapEntityKind.npc);
+      expect(grant.npc?.trainerId, 'grant');
+      expect(
+        selbrumeBundle.manifest.trainers.map((trainer) => trainer.id),
+        contains('grant'),
+      );
 
       final startMap = selbrumeBundle.map;
       expect(startMap.mapMetadata.defaultSpawnId, isNull);
```

## 7. Tests relancés

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
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
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
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
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

### P6-03

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie :

```text
00:00 +0: P6-03 triggers repo-local Selbrume first narrative interaction and persists its state
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
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
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
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

### P6-04

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sortie :

```text
00:00 +0: P6-04 triggers repo-local Route 1 encounter and persists a minimal capture
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
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
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
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

## 8. Analyse exécutée

Format :

```bash
cd packages/map_runtime && dart format --set-exit-if-changed test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

Analyse ciblée :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_existing_selbrume_loadability_start_map_contract_test.dart test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie :

```text
Analyzing 2 items...

No issues found! (ran in 2.2s)
```

## 9. Modifications effectuées

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_6.md
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
selbrume/project.json
```

Fichier créé :

```text
reports/roadmap/phase_6/p6_04_ter_selbrume_grant_reconciliation_p6_03_regression_fix.md
```

Diff stat courant avant rapport final :

```text
 MVP Selbrume/road_map_phase_6.md                   |  51 ++++-
 ...lbrume_loadability_start_map_contract_test.dart |  10 +-
 selbrume/project.json                              | 252 ++++++++++++++++++++-
 3 files changed, 302 insertions(+), 11 deletions(-)
```

## 10. Roadmap Phase 6 mise à jour

La roadmap Phase 6 indique maintenant :

```text
Lot courant : ✅ P6-04-ter — Selbrume Grant Reconciliation / P6-03 Regression Fix
Prochain lot exact : P6-05 — Selbrume First Trainer Battle Golden Slice V0
P6-04-ter : ✅ terminé
P6-05 : ➡️ prochain lot exact
```

## 11. Prochain lot exact

```text
P6-05 — Selbrume First Trainer Battle Golden Slice V0
```

Justification :

```text
Grant est conservé.
P6-01 repasse avec Grant présent.
P6-03 est restauré.
P6-02 et P6-04 repassent.
Le terrain est propre pour traiter explicitement le trainer battle en P6-05.
```

## 12. Ce qui n’a pas été fait

```text
Grant n'a pas été supprimé.
Aucun combat Grant n'a été prouvé.
Aucun trainer battle final n'a été créé.
Aucune Battle UI n'a été créée.
Aucun reward n'a été créé.
Aucune XP n'a été ajoutée.
Aucune nouvelle encounter table n'a été créée.
Aucun code production n'a été modifié.
P6-05 n'a pas été lancé.
```

## 13. Evidence Pack

Sources lues principales :

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_phase_6.md
reports/roadmap/phase_6/p6_04_bis_selbrume_git_worktree_attribution.md
reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
selbrume/project.json
selbrume/maps/Selbrume.json
selbrume/maps/route 1.json
selbrume/assets/tilesets/grant.png
```

Commandes exécutées :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume
rg -n "grant|trainerId|p6_03_first_interaction|p6_03_intro_sign|p6\\.selbrume\\.first_interaction" selbrume/project.json "selbrume/maps/Selbrume.json" "selbrume/maps/route 1.json"
test -f "selbrume/assets/tilesets/grant.png" && echo "grant.png exists" || echo "grant.png missing"
python3 - <<'PY' ...
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_existing_selbrume_loadability_start_map_contract_test.dart test/p6_selbrume_first_narrative_interaction_test.dart
```

Contrôles explicites :

```text
Grant n'a pas été supprimé.
p6_03_first_interaction existe après correction.
p6_03_intro_sign existe.
Aucun code production n'a été modifié.
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
 MVP Selbrume/road_map_phase_6.md                   |  51 ++++-
 ...lbrume_loadability_start_map_contract_test.dart |  10 +-
 selbrume/project.json                              | 252 ++++++++++++++++++++-
 3 files changed, 302 insertions(+), 11 deletions(-)

git diff --name-only
MVP Selbrume/road_map_phase_6.md
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
selbrume/project.json

git status --short --untracked-files=all
 M "MVP Selbrume/road_map_phase_6.md"
 M packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
 M selbrume/project.json
?? reports/roadmap/phase_6/p6_04_ter_selbrume_grant_reconciliation_p6_03_regression_fix.md
```

## 14. Auto-review critique

- Ai-je conservé Grant ? Oui.
- Ai-je évité de supprimer du contenu utilisateur ? Oui.
- Ai-je restauré p6_03_first_interaction ? Oui.
- Ai-je vérifié p6_03_intro_sign ? Oui.
- Ai-je adapté P6-01 sans affaiblir le contrat start map/spawn ? Oui.
- Ai-je relancé P6-01/P6-02/P6-03/P6-04 ? Oui.
- Ai-je modifié du code production ? Non.
- Ai-je lancé P6-05 ? Non.
- Ai-je créé du contenu final ? Non.
- Ai-je fixé un prochain lot exact unique ? Oui : P6-05 — Selbrume First Trainer Battle Golden Slice V0.
