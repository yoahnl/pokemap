# P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0

## 1. Résumé exécutif

P6-04 est concluant.

Le projet Selbrume repo-local est utilisé comme source active :

```text
/Users/karim/Project/pokemonProject/selbrume
```

Le lot prouve une boucle courte :

```text
Selbrume/spawn
-> party/bag seedé P6-02
-> flag/step P6-03 conservés
-> passage logique vers route 1
-> encounter walk via grass_path_route_1
-> WildBattleStartRequest runtime-application
-> consommation poke-ball
-> capture minimale pidgeotto vers party
-> SaveData roundtrip
```

Niveau de preuve encounter obtenu : **gameplay encounter + runtime-application handoff**, pas Battle UI et pas runtime smoke complet.

Aucun code production n'a été modifié par P6-04.
Le test P6-04 et la roadmap ne modifient pas les données Selbrume.
Attention : le worktree final contient des changements `selbrume/` observés hors livrables P6-04 (`selbrume/project.json`, `selbrume/maps/route 1.json` et `selbrume/assets/tilesets/grant.png`). Ils ne sont pas utilisés par le test P6-04 et ne sont pas écrasés dans ce lot.
Aucun trainer, reward, Battle UI, PC UI, formule de capture officielle ou P6-05 n'a été créé.

Prochain lot exact :

```text
P6-05 — Selbrume First Trainer Battle Golden Slice V0
```

## 2. Sources lues

Sources gouvernance :

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
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
```

Sources techniques :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
packages/map_runtime/lib/src/application/encounter_to_battle_request.dart
packages/map_runtime/lib/src/application/battle_start_request.dart
packages/map_gameplay/lib/src/gameplay_encounter.dart
packages/map_gameplay/lib/src/gameplay_world_state.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/player_spawn_resolver.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_gameplay/test/capture_destination_operations_test.dart
packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
```

Skills consultés :

```text
superpowers:using-superpowers
dart-add-unit-test
superpowers:verification-before-completion
superpowers:systematic-debugging
```

## 3. Gate 0

Commandes Gate 0 exécutées depuis la racine :

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
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` initial :

```text
Sortie : <vide>
```

`git diff --stat` initial :

```text
Sortie : <vide>
```

`git diff --name-only` initial :

```text
Sortie : <vide>
```

`git log --oneline -n 10` initial :

```text
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
25d623ca Ajoute selbrume/assets/pokemon/sprites/ à .gitignore
951b5e6b Ajoute P6-02 : Selbrume Initial Party/Bag Setup (test et rapport)
1886d1bf Ajoute P6-01 : Existing Selbrume Loadability Start Map Contract (test et rapport)
845dd603 update Selbrume.json
fbc32f8b Ajoute les sprites Pokémon pour Selbrume
e2541284 Ajoute le rapport P6-00 et met à jour road_map_phase_6.md
a54b6001 Ajoute le rapport P5-Checkpoint-01-bis et met à jour les roadmaps
beb36d20 Ajoute road_map_phase_6.md et le rapport P5-Checkpoint-01, met à jour road_map_global.md et road_map_phase_5.md
a04b8997 Ajoute P5-10 : Scope Audio Out of Scope Checkpoint Redirect (rapport)
```

Vérification Selbrume repo-local :

```bash
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume | sed -n '1,160p'
printf 'SELBRUME_STATUS_COUNT='
git status --short --untracked-files=all -- selbrume | wc -l
```

Sorties :

```text
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists
Sortie status selbrume : <vide>
SELBRUME_STATUS_COUNT=       0
```

## 4. Audit Route 1 encounter existant

Audit `selbrume/project.json` et `selbrume/maps/route 1.json` :

```text
encounterTables count 1
table grass_path_route_1 grass path route 1 entries 1
entry {'speciesId': 'pidgeotto', 'minLevel': 1, 'maxLevel': 5, 'weight': 1}
route id route 1
connections [{'direction': 'west', 'targetMapId': 'Selbrume', 'offset': 0}]
gameplayZones count 5
zone zone   kind encounter area x=1 y=27 width=2 height=8 table grass_path_route_1 walk
zone zone_1 kind encounter area x=3 y=27 width=3 height=6 table grass_path_route_1 walk
zone zone_2 kind encounter area x=4 y=28 width=3 height=8 table grass_path_route_1 walk
zone zone_3 kind encounter area x=7 y=31 width=5 height=3 table grass_path_route_1 walk
zone zone_4 kind encounter area x=10 y=32 width=3 height=2 table grass_path_route_1 walk
triggers count 0
entities count 0
```

Conclusion :

```text
La table grass_path_route_1 existe déjà.
La route 1 contient cinq zones encounter walk exploitables.
La table ne contient qu'une espèce : pidgeotto.
P6-04 n'a pas besoin de créer une nouvelle table ou de modifier route 1.
```

## 5. Niveau de preuve encounter obtenu

Le test P6-04 prouve :

```text
loadRuntimeMapBundle(projectFilePath: repo-local selbrume/project.json, mapId: Selbrume)
loadRuntimeMapBundle(projectFilePath: repo-local selbrume/project.json, mapId: route 1)
route 1 -> Selbrume existe dans les connections
GameplayWorldState.initial sur route 1 à x=1 y=27
checkEncounterAtPlayerPosition(... EncounterKind.walk, chancePerStep: 1)
encounter déclenché : pidgeotto niveau 3
buildBattleStartRequestFromEncounter(...)
WildBattleStartRequest kind=wild source=encounterZone
```

Niveau retenu :

```text
gameplay encounter proof : oui
runtime-application handoff proof : oui
Battle UI proof : non
runtime smoke complet : non
```

La transition joueur complète Selbrume -> route 1 n'est pas prouvée en mouvement runtime.
Le test utilise `GameStateMutations.warpPlayer(...)` pour isoler Route 1 sans créer de nouveau système de transition.

## 6. Capture minimale retenue

Capture retenue :

```text
speciesId : pidgeotto
level : 3
abilityId : keen_eye
moves : gust, tackle
capture item : poke-ball
```

La capture utilise :

```text
markSpeciesSeenInGameState(...)
GameStateMutations.consumeItem(... poke-ball, 1)
GameStateMutations.applyCapturedPokemon(...)
```

Résultat :

```text
destination : party
party avant capture : 1 pidgeotto niveau 8
party après capture : 2 pidgeotto
pokemonStorage : vide
poke-ball : 5 -> 4
potion : 2 -> 2
caughtSpeciesIds contient pidgeotto
seenSpeciesIds contient pidgeotto
```

Limite honnête :

```text
Le pidgeotto capturé duplique l'espèce du Pokémon initial P6-02.
Ce n'est pas un problème de mécanique V0, car l'API autorise deux instances en party.
Le signal de capture est donc prouvé par party size 1 -> 2, destination party et bag 5 -> 4.
Le signal caught/seen est cohérent, mais l'espèce était déjà présente dans la party initiale.
```

## 7. Preuve GameState / progression

Assertions principales :

```text
currentMapId initial = Selbrume
playerPosition initial = GridPos(x:17, y:24)
playerFacing initial = south
party initiale = pidgeotto level 8
bag initial = poke-ball x5, potion x2
story flag P6-03 conservé = p6.selbrume.first_interaction.seen
completed step P6-03 conservé = p6.selbrume.first_interaction
currentMapId après warp logique = route 1
playerPosition Route 1 = GridPos(x:1, y:27)
playerFacing Route 1 = east
encounter route 1 = pidgeotto level 3
party après capture = 2 membres
storage après capture = vide
bag après capture = poke-ball x4, potion x2
```

## 8. Preuve SaveData / persistance

Roundtrip exécuté :

```text
saveDataFromGameState(state)
gameStateFromSaveData(saveData)
normalizeLoadedGameState(...)
```

Assertions post-roundtrip :

```text
saveId = p6_04_selbrume_route_1_encounter_capture
currentMapId = route 1
playerPosition = GridPos(x:1, y:27)
playerFacing = east
party size = 2
party[0].speciesId = pidgeotto
party[1].speciesId = pidgeotto
party[1].level = 3
party[1].knownMoveIds = gust, tackle
pokemonStorage.storedPokemon = vide
poke-ball = 4
potion = 2
caughtSpeciesIds contient pidgeotto
seenSpeciesIds contient pidgeotto
story flag P6-03 conservé
completed step P6-03 conservé
```

## 9. Tests exécutés

Test ciblé P6-04 :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sortie exacte finale :

```text
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

Régressions lancées :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
```

Sortie P6-01 :

```text
00:00 +0: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=638171
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=2
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1267082
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=2 placedElements=1180 warps=3 triggers=0
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=route 1
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=638171
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=2
[runtime_loader] bundle map resolved mapId=route 1 relativePath=maps/route 1.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file read ok bytes=222423
[runtime_loader] map validated id=route 1 size=45x45 layers=6 entities=0 placedElements=68 warps=0 triggers=0
[runtime_loader] bundle load ok mapId=route 1 projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=6
00:00 +1: All tests passed!
```

Sortie P6-02 :

```text
00:00 +0: P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=638171
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=2
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1267082
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=2 placedElements=1180 warps=3 triggers=0
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
00:00 +1: All tests passed!
```

Sortie P6-03 après restauration intermédiaire :

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
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
00:00 +1: All tests passed!
```

Note d'incident pendant vérification :

```text
Une première exécution de la régression P6-03 a échoué avec "Bad state: No element"
sur le scénario p6_03_first_interaction.
Le diff montrait une suppression temporaire de ce scénario dans selbrume/project.json.
Le bloc P6-03 a été restauré une première fois pour revenir au contenu attendu, puis la régression P6-03 est repassée.
Ensuite, de nouveaux changements hors livrables P6-04 sont apparus sous selbrume/ : un tileset/trainer grant dans project.json, un NPC grant dans route 1, l'absence du scénario p6_03_first_interaction dans le manifest courant, et selbrume/assets/tilesets/grant.png non tracké.
Ces changements ne sont pas écrasés par P6-04.
Le test ciblé P6-04 reste passant sur cet état courant.
```

## 10. Analyse exécutée

Format exécuté :

```bash
dart format --set-exit-if-changed packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sortie finale :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sortie exacte :

```text
No issues found! (ran in 2.4s)
```

## 11. Modifications effectuées

Fichier créé :

```text
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_6.md
```

Aucun fichier `selbrume/` n'est modifié par les livrables P6-04.
Le worktree final contient toutefois des changements `selbrume/` hors livrables P6-04, conservés sans écrasement.
Aucun fichier de code production n'est modifié.
Aucun test existant n'est modifié.

## 12. Roadmap Phase 6 mise à jour

Sections modifiées principales :

```text
Lot courant : ✅ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
Prochain lot exact : P6-05 — Selbrume First Trainer Battle Golden Slice V0

P6-04 : ✅ terminé
P6-05 : ➡️ prochain lot exact

Résultat P6-04 :
encounter table retenue : grass_path_route_1
species encounter/capture : pidgeotto
niveau de preuve encounter : gameplay + runtime-application
capture destination : party
bag après capture : poke-ball x4, potion x2
roundtrip SaveData prouvé
```

## 13. Prochain lot exact

Prochain lot exact :

```text
P6-05 — Selbrume First Trainer Battle Golden Slice V0
```

Justification :

```text
P6-04 ferme la boucle encounter/capture Route 1 minimale.
Le golden slice peut maintenant passer au premier combat trainer court.
P6-05 ne doit pas être lancé dans ce lot.
```

## 14. Ce qui n’a pas été fait

Non-objectifs respectés :

```text
aucun trainer créé
aucune Lysa créée
aucun combat trainer créé
aucun reward créé
aucune XP persistée complète ajoutée
aucun move learning ajouté
aucune évolution ajoutée
aucune PC UI créée
aucune bag UI créée
aucune battle UI créée
aucune capture formula officielle créée
aucune nouvelle encounter table créée
aucune donnée Pokémon modifiée
aucun asset modifié
aucun Boot Flow créé
aucun audio créé
aucun validator pass complet lancé
aucun runtime smoke complet lancé
aucun P6-05 lancé
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
sed -n '1,260p' AGENTS.md
sed -n '1,260p' agent_rules.md
sed -n '1,220p' skills/README.md
sed -n '1,260p' pokemap_roadmap_mecaniques_fangame.md
sed -n '1,140p' "MVP Selbrume/road_map_global.md"
sed -n '1,140p' "MVP Selbrume/road_map_phase_6.md"
sed -n '1,260p' reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
sed -n '1,260p' reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
sed -n '1,260p' reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
sed -n '1,260p' reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
rg -n "Encounter|encounterTable|encounterTables|WildBattle|WildBattleStart|capture|applyCapturedPokemon|CaptureDestination|poke-ball|consumeItem|caughtSpeciesIds|seenSpeciesIds" packages/map_core packages/map_gameplay packages/map_runtime examples/playable_runtime_host --glob '!build/**' --glob '!**/.dart_tool/**'
rg --files packages/map_core/lib packages/map_runtime/lib packages/map_runtime/test packages/map_gameplay/test | rg "encounter|capture|battle|wild|p6|p5|game_state|project_manifest|map_data|map_gameplay_zone"
python3 - <<'PY'
import json
from pathlib import Path
root=Path('selbrume')
project=json.loads((root/'project.json').read_text())
print('encounterTables count', len(project.get('encounterTables', [])))
for t in project.get('encounterTables', []):
    print('table', t.get('id'), t.get('name'), t.get('kind'), 'entries', len(t.get('entries', [])))
    for e in t.get('entries', []):
        print(' entry', e)
route=json.loads((root/'maps'/'route 1.json').read_text())
print('route id', route.get('id'))
print('connections', route.get('connections'))
print('gameplayZones count', len(route.get('gameplayZones', [])))
for z in route.get('gameplayZones', []):
    print('zone', z)
print('triggers count', len(route.get('triggers', [])))
print('entities count', len(route.get('entities', [])))
PY
python3 - <<'PY'
import json
from pathlib import Path
root=Path('selbrume')
for rel in ['data/pokemon/species/0017-pidgeotto.json','data/pokemon/learnsets/pidgeotto.json','data/pokemon/catalogs/moves.json','data/pokemon/catalogs/items.json']:
    p=root/rel
    print('---', rel, 'exists=', p.exists())
    data=json.loads(p.read_text())
    if rel.endswith('moves.json'):
        for id_ in ['gust','tackle']:
            hit=next(e for e in data['entries'] if e['id']==id_)
            print(id_, {'id': hit['id'], 'name': hit.get('name'), 'type': hit.get('type'), 'category': hit.get('category'), 'pp': hit.get('pp')})
    elif rel.endswith('items.json'):
        for id_ in ['poke-ball','potion']:
            hit=next(e for e in data['entries'] if e['id']==id_)
            print(id_, {'id': hit['id'], 'name': hit.get('name'), 'categoryId': hit.get('categoryId'), 'shortEffectText': hit.get('shortEffectText')})
    else:
        print(json.dumps(data, indent=2, ensure_ascii=False)[:2400])
PY
dart format --set-exit-if-changed packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
```

### Preuve que l'ancien chemin Desktop n'est pas utilisé

Le test P6-04 localise la racine repo en cherchant :

```text
selbrume/project.json
selbrume/maps/route 1.json
```

Le contenu complet du test ne contient pas :

```text
/Users/karim/Desktop/selbrume
```

### Preuve species / moves / item

Sortie utile :

```text
--- data/pokemon/species/0017-pidgeotto.json exists= True
"id": "pidgeotto"
"primary": "keen_eye"
--- data/pokemon/learnsets/pidgeotto.json exists= True
"speciesId": "pidgeotto"
"startingMoves": ["gust", "quick_attack", "sand_attack", "tackle"]
gust {'id': 'gust', 'name': 'Gust', 'type': 'flying', 'category': 'special', 'pp': 35}
tackle {'id': 'tackle', 'name': 'Tackle', 'type': 'normal', 'category': 'physical', 'pp': 35}
poke-ball {'id': 'poke-ball', 'name': 'Poké Ball', 'categoryId': 'standard-balls', 'shortEffectText': 'Tries to catch a wild Pokémon.'}
potion {'id': 'potion', 'name': 'Potion', 'categoryId': 'healing', 'shortEffectText': 'Restores 20 HP.'}
```

### Contenu complet du test créé

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _saveId = 'p6_04_selbrume_route_1_encounter_capture';
const _encounterTableId = 'grass_path_route_1';
const _capturedSpeciesId = 'pidgeotto';
const _initialSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';
const _p603FlagId = 'p6.selbrume.first_interaction.seen';
const _p603StepId = 'p6.selbrume.first_interaction';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-04 triggers repo-local Route 1 encounter and persists a minimal capture',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final selbrumeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _startMapId,
      );
      final routeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _routeMapId,
      );

      expect(
          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(selbrumeBundle.map.id, _startMapId);
      expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(routeBundle.map.id, _routeMapId);
      expect(
        selbrumeBundle.manifest.maps.map((entry) => entry.id),
        containsAll(<String>[_startMapId, _routeMapId]),
      );

      final connectsBackToSelbrume = routeBundle.map.connections.any(
        (connection) => connection.targetMapId == _startMapId,
      );
      expect(connectsBackToSelbrume, isTrue);

      final table = routeBundle.manifest.encounterTables.singleWhere(
        (candidate) => candidate.id == _encounterTableId,
      );
      expect(table.name, 'grass path route 1');
      expect(table.encounterKind, EncounterKind.walk);
      expect(table.entries, hasLength(1));
      final entry = table.entries.single;
      expect(entry.speciesId, _capturedSpeciesId);
      expect(entry.minLevel, 1);
      expect(entry.maxLevel, 5);
      expect(entry.weight, 1);

      final encounterZones = routeBundle.map.gameplayZones
          .where(
            (zone) =>
                zone.kind == GameplayZoneKind.encounter &&
                zone.encounter?.encounterTableId == _encounterTableId &&
                zone.encounter?.encounterKind == EncounterKind.walk,
          )
          .toList(growable: false);
      expect(encounterZones, hasLength(5));

      final firstEncounterZone = encounterZones.first;
      final encounterPos = firstEncounterZone.area.pos;
      expect(encounterPos, const GridPos(x: 1, y: 27));

      final speciesJson = await _readSpeciesJsonById(
        projectRoot: projectRoot,
        speciesDir: routeBundle.manifest.pokemon.speciesDir,
        speciesId: _capturedSpeciesId,
      );
      expect(speciesJson['id'], _capturedSpeciesId);
      expect(
        (speciesJson['abilities'] as Map<String, dynamic>)['primary'],
        _initialAbilityId,
      );

      final learnsetJson = await _readProjectJson(
        projectRoot,
        p.join(
          routeBundle.manifest.pokemon.learnsetsDir,
          '$_capturedSpeciesId.json',
        ),
      );
      expect(
        (learnsetJson['startingMoves'] as List<dynamic>).cast<String>(),
        containsAll(_initialMoves),
      );

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: routeBundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      expect(moveIds, containsAll(_initialMoves));

      final itemIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: routeBundle.manifest.pokemon.catalogFiles['items']!,
        expectedCatalog: 'items',
      );
      expect(itemIds, containsAll(<String>[_captureItemId, _medicineItemId]));

      const mutations = GameStateMutations();
      var state = createNewGameStateFromMap(
        startMap: selbrumeBundle.map,
        saveId: _saveId,
        playerName: 'P6 Tester',
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );
      state = _seedP6InitialState(state);
      state = mutations.setFlag(state, _p603FlagId);
      state = mutations.completeStep(state, _p603StepId);

      expect(state.currentMapId, _startMapId);
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.party.members, hasLength(1));
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(_bagQuantity(state, _captureItemId), 5);
      expect(_bagQuantity(state, _medicineItemId), 2);

      state = mutations.warpPlayer(
        state,
        _routeMapId,
        encounterPos.x,
        encounterPos.y,
        facing: EntityFacing.east,
      );

      expect(state.currentMapId, _routeMapId);
      expect(state.playerPosition, encounterPos);
      expect(state.playerFacing, EntityFacing.east);

      final world = GameplayWorldState.initial(
        map: routeBundle.map,
        playerPos: state.playerPosition,
        playerFacing: Direction.east,
        project: routeBundle.manifest,
        tileWidth: routeBundle.manifest.settings.tileWidth,
        tileHeight: routeBundle.manifest.settings.tileHeight,
      );
      final encounterCheck = checkEncounterAtPlayerPosition(
        world: world,
        project: routeBundle.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 2],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.mapId, _routeMapId);
      expect(encounter.zoneId, firstEncounterZone.id);
      expect(encounter.tableId, _encounterTableId);
      expect(encounter.encounterKind, EncounterKind.walk);
      expect(encounter.speciesId, _capturedSpeciesId);
      expect(encounter.minLevel, entry.minLevel);
      expect(encounter.maxLevel, entry.maxLevel);
      expect(encounter.level, 3);
      expect(encounter.playerPos, encounterPos);

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: world,
        createdAtEpochMs: 1,
      );
      expect(request.kind, RuntimeBattleKind.wild);
      expect(request.source, RuntimeBattleSourceKind.encounterZone);
      expect(request.mapId, _routeMapId);
      expect(request.zoneId, firstEncounterZone.id);
      expect(request.tableId, _encounterTableId);
      expect(request.speciesId, _capturedSpeciesId);
      expect(request.level, 3);
      expect(request.returnContext.mapId, _routeMapId);
      expect(request.returnContext.playerPos, encounterPos);

      state = markSpeciesSeenInGameState(state, encounter.speciesId);
      expect(state.progression.seenSpeciesIds, contains(_capturedSpeciesId));

      state = mutations.consumeItem(state, _captureItemId, 1);
      expect(_bagQuantity(state, _captureItemId), 4);
      expect(_bagQuantity(state, _medicineItemId), 2);

      final capturedPokemon = PlayerPokemon(
        speciesId: encounter.speciesId,
        natureId: 'hardy',
        abilityId: _initialAbilityId,
        level: encounter.level,
        currentHp: 18,
        knownMoveIds: _initialMoves,
      );
      final captureResult = mutations.applyCapturedPokemon(
        state,
        pokemon: capturedPokemon,
      );
      expect(captureResult.destination, CaptureDestinationKind.party);
      expect(captureResult.partyIndex, 1);
      expect(captureResult.storageIndex, isNull);
      state = captureResult.state;

      expect(state.currentMapId, _routeMapId);
      expect(state.playerPosition, encounterPos);
      expect(state.party.members, hasLength(2));
      expect(state.party.members.first.speciesId, _initialSpeciesId);
      expect(state.party.members.last.speciesId, _capturedSpeciesId);
      expect(state.party.members.last.level, encounter.level);
      expect(state.party.members.last.knownMoveIds, _initialMoves);
      expect(state.pokemonStorage.storedPokemon, isEmpty);
      expect(_bagQuantity(state, _captureItemId), 4);
      expect(_bagQuantity(state, _medicineItemId), 2);
      expect(state.progression.caughtSpeciesIds, contains(_capturedSpeciesId));
      expect(state.progression.seenSpeciesIds, contains(_capturedSpeciesId));
      expect(state.storyFlags.activeFlags, contains(_p603FlagId));
      expect(state.progression.completedStepIds, contains(_p603StepId));

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _routeMapId);
      expect(reloaded.playerPosition, encounterPos);
      expect(reloaded.playerFacing, EntityFacing.east);
      expect(reloaded.party.members, hasLength(2));
      expect(reloaded.party.members.first.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.last.speciesId, _capturedSpeciesId);
      expect(reloaded.party.members.last.level, 3);
      expect(reloaded.party.members.last.knownMoveIds, _initialMoves);
      expect(reloaded.pokemonStorage.storedPokemon, isEmpty);
      expect(_bagQuantity(reloaded, _captureItemId), 4);
      expect(_bagQuantity(reloaded, _medicineItemId), 2);
      expect(
        reloaded.progression.caughtSpeciesIds,
        contains(_capturedSpeciesId),
      );
      expect(
        reloaded.progression.seenSpeciesIds,
        contains(_capturedSpeciesId),
      );
      expect(reloaded.storyFlags.activeFlags, contains(_p603FlagId));
      expect(reloaded.progression.completedStepIds, contains(_p603StepId));
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

int _bagQuantity(GameState state, String itemId) {
  final entry = state.bag.normalized().entries.firstWhere(
        (candidate) => candidate.itemId == itemId,
        orElse: () =>
            BagEntry(itemId: itemId, categoryId: 'items', quantity: 0),
      );
  return entry.quantity;
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

Future<Map<String, dynamic>> _readSpeciesJsonById({
  required Directory projectRoot,
  required String speciesDir,
  required String speciesId,
}) async {
  final directory = Directory(p.join(projectRoot.path, speciesDir));
  await for (final entity in directory.list(recursive: false)) {
    if (entity is! File || p.extension(entity.path) != '.json') {
      continue;
    }
    final json = await _readJsonFile(entity);
    if (json['id'] == speciesId) {
      return json;
    }
  }
  throw StateError('Species id not found in Selbrume data: $speciesId');
}

Future<Set<String>> _readCatalogIds({
  required Directory projectRoot,
  required String relativePath,
  required String expectedCatalog,
}) async {
  final json = await _readProjectJson(projectRoot, relativePath);
  expect(json['catalog'], expectedCatalog);
  return (json['entries'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((entry) => entry['id'] as String)
      .toSet();
}

Future<Map<String, dynamic>> _readProjectJson(
  Directory projectRoot,
  String relativePath,
) {
  return _readJsonFile(File(p.join(projectRoot.path, relativePath)));
}

Future<Map<String, dynamic>> _readJsonFile(File file) async {
  final decoded = jsonDecode(await file.readAsString());
  return decoded as Map<String, dynamic>;
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  var _doubleIndex = 0;
  var _intIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    final value = nextDoubleValues[_doubleIndex % nextDoubleValues.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    final value = nextIntValues[_intIndex % nextIntValues.length];
    _intIndex++;
    return max == 0 ? 0 : value % max;
  }
}
```

### Sections modifiées de road_map_phase_6.md

```text
Lot courant : ✅ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
Prochain lot exact : P6-05 — Selbrume First Trainer Battle Golden Slice V0

Suivi des lots :
- ✅ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
- ➡️ P6-05 — Selbrume First Trainer Battle Golden Slice V0

P6-04 : ✅ terminé
P6-05 : ➡️ prochain lot exact

Résultat P6-04 :
selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées : Selbrume et route 1
connexion observée : route 1 -> Selbrume
encounter table retenue : grass_path_route_1
encounter kind : walk
zones route 1 exploitables : 5 zones encounter
species encounter/capture : pidgeotto
plage de niveau authorée : 1..5
niveau déclenché dans le test : 3
moves vérifiés : gust, tackle
item capture vérifié : poke-ball
bag initial P6-02 : poke-ball x5, potion x2
preuve encounter : gameplay encounter via checkEncounterAtPlayerPosition
preuve runtime-application : WildBattleStartRequest via buildBattleStartRequestFromEncounter
capture minimale : applyCapturedPokemon
destination capture : party
bag après capture : poke-ball x4, potion x2
roundtrip SaveData conserve route 1, party, capture, bag, seen/caught et flags P6-03
```

### Diff ciblé de selbrume/project.json ou route 1

Commande :

```bash
git diff --name-only -- selbrume/project.json "selbrume/maps/route 1.json"
```

Sortie :

```text
selbrume/project.json
```

Commande :

```bash
git diff --stat -- selbrume/project.json "selbrume/maps/route 1.json"
```

Sortie :

```text
selbrume/maps/route 1.json | 41 +++-
selbrume/project.json      | 549 +++++++++++++++++++++++++++------------------
2 files changed, 340 insertions(+), 250 deletions(-)
```

### Contrôles explicites

```text
Aucun code production PokeMap n'a été modifié.
Aucun test existant n'a été modifié.
Les livrables P6-04 ne modifient pas `selbrume/`.
Le worktree final contient des changements `selbrume/` hors livrables P6-04 : `selbrume/project.json`, `selbrume/maps/route 1.json` et `selbrume/assets/tilesets/grant.png`.
Le projet actif utilisé est /Users/karim/Project/pokemonProject/selbrume.
L'ancien chemin /Users/karim/Desktop/selbrume n'est pas utilisé par le test actif.
Aucun trainer n'a été créé par P6-04.
Aucun trainer n'est référencé par le test P6-04.
Le worktree courant contient toutefois un trainer/NPC `grant` hors livrables P6-04.
Aucune Lysa n'a été créée.
Aucun reward n'a été créé par P6-04.
Aucune formule de capture officielle n'a été ajoutée.
Aucune donnée Pokémon n'a été modifiée.
Aucun contenu final Selbrume n'a été créé.
Aucun P6-05 n'a été lancé.
```

### Contrôles finaux

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
MVP Selbrume/road_map_phase_6.md |  63 ++++-
selbrume/maps/route 1.json       |  41 ++-
selbrume/project.json            | 549 +++++++++++++++++++++------------------
3 files changed, 395 insertions(+), 258 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
MVP Selbrume/road_map_phase_6.md
selbrume/maps/route 1.json
selbrume/project.json
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M "MVP Selbrume/road_map_phase_6.md"
 M "selbrume/maps/route 1.json"
 M selbrume/project.json
?? packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
?? reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
?? selbrume/assets/tilesets/grant.png
```

## 16. Auto-review critique

Questions de contrôle :

```text
Ai-je utilisé le chemin repo-local selbrume ? Oui.
Ai-je évité l'ancien chemin Desktop ? Oui, le test ne le contient pas.
Ai-je réutilisé l'encounter table existante si possible ? Oui, grass_path_route_1.
Ai-je modifié selbrume/ ? Les livrables P6-04 non ; le worktree final contient des changements selbrume/ hors livrables P6-04 conservés sans écrasement.
Ai-je modifié du code production ? Non.
Ai-je créé seulement un test ciblé ? Oui.
Ai-je prouvé un runtime encounter, un gameplay encounter ou seulement un contrat ? Gameplay encounter + runtime-application handoff.
Ai-je prouvé la capture minimale ? Oui, applyCapturedPokemon destination party.
Ai-je prouvé la consommation ou présence de poke-ball correctement ? Oui, poke-ball x5 -> x4.
Ai-je prouvé la persistance de la capture ? Oui, SaveData roundtrip.
Ai-je créé un trainer ou un combat trainer ? Non.
Ai-je lancé P6-05 ? Non.
Ai-je créé du contenu final ? Non.
Ai-je fixé un prochain lot exact unique ? Oui, P6-05.
```
