# P6-02 — Selbrume Initial Party / Bag Setup V0

## 1. Résumé exécutif

P6-02 a construit et prouvé un état initial Selbrume minimalement jouable à
partir du projet repo-local :

```text
/Users/karim/Project/pokemonProject/selbrume
```

Chaîne prouvée :

```text
selbrume/project.json
-> loadRuntimeMapBundle(mapId: Selbrume)
-> createNewGameStateFromMap(Selbrume/spawn)
-> GameStateMutations.givePokemon(pidgeotto)
-> GameStateMutations.giveItem(poke-ball, potion)
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
```

Résultat :

```text
start map = Selbrume
spawn = spawn
position = x:17, y:24
facing = south
party initiale = pidgeotto niveau 8, moves gust/tackle
bag initial = poke-ball x5, potion x2
money = 0
roundtrip SaveData = prouvé
```

Aucun contenu final Selbrume n'a été créé. Aucun code production n'a été
modifié. Aucun fichier `selbrume/` n'a été modifié.

Prochain lot exact :

```text
P6-03 — Selbrume First Narrative Interaction V0
```

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
```

Sources techniques :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/player_spawn_resolver.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_core/lib/src/models/project_manifest.dart
```

Tests lus :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_gameplay/test/new_game_initial_party_test.dart
packages/map_gameplay/test/party_bag_heal_operations_test.dart
packages/map_gameplay/test/battle_reward_operations_test.dart
packages/map_gameplay/test/capture_destination_operations_test.dart
packages/map_core/test/game_state_persistence_test.dart
packages/map_core/test/save_data_test.dart
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
```

Skills lus :

```text
dart-add-unit-test
verification-before-completion
```

Lot mécanique lié :

```text
FG roadmap : Party + Bag runtime restent PARTIAL au sens produit complet.
P6-02 apporte une preuve Selbrume seedée, pas un modèle produit final de New Game config.
```

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
pwd:
/Users/karim/Project/pokemonProject

git branch --show-current:
main

git status --short --untracked-files=all:
Sortie : <vide>

git diff --stat:
Sortie : <vide>

git diff --name-only:
Sortie : <vide>

git log --oneline -n 10:
bbf94b052 Ajoute P6-01 : Existing Selbrume Loadability Start Map Contract (test et rapport)
715335335 update Selbrume.json
7bdf1dae7 Ajoute les sprites Pokémon pour Selbrume
e25412844 Ajoute le rapport P6-00 et met à jour road_map_phase_6.md
a54b6001d Ajoute le rapport P5-Checkpoint-01-bis et met à jour les roadmaps
beb36d201 Ajoute road_map_phase_6.md et le rapport P5-Checkpoint-01, met à jour road_map_global.md et road_map_phase_5.md
a04b89977 Ajoute P5-10 : Scope Audio Out of Scope Checkpoint Redirect (rapport)
a547ccc22 Ajoute P5-08 et P5-09 : Beta Runtime Smoke et Beta Playability Validator (code, tests et rapports)
2ac26e931 Ajoute P5-07 : Gameplay Save/Load Beta Roundtrip (test et rapport)
f7a0cfd6a Ajoute P5-06 : Capture Destination (Party/Box) Minimal Flow (code, tests et rapport)
```

Commandes Selbrume repo-local :

```bash
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume | sed -n '1,120p'
printf 'SELBRUME_STATUS_COUNT='
git status --short --untracked-files=all -- selbrume | wc -l
```

Sorties :

```text
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists

git status --short --untracked-files=all -- selbrume | sed -n '1,120p':
Sortie : <vide>

SELBRUME_STATUS_COUNT=       0
```

Décision :

```text
selbrume/ était propre au Gate 0.
P6-02 n'a pourtant pas modifié selbrume/, car aucun support officiel initialParty/initialBag persistant n'a été trouvé.
```

## 4. Support initial party / bag existant

Audit `ProjectManifest` et `project.json` :

```text
ProjectManifest ne contient pas de champ initialParty.
ProjectManifest ne contient pas de champ initialBag.
ProjectSettings ne contient pas de champ initialParty.
ProjectSettings ne contient pas de champ initialBag.
globalProperties est vide dans selbrume/project.json.
BetaPlayabilityValidationContext accepte des initialPartySpeciesIds / initialPartyMoveIds, mais c'est un contexte de validation pur, pas une config persistée New Game.
```

Commande de preuve :

```bash
python3 - <<'PY'
import json
from pathlib import Path
root = Path('selbrume')
project = json.loads((root/'project.json').read_text())
print('pokemon_config =', project.get('pokemon'))
print('project_top_level_has_initialParty =', 'initialParty' in project)
print('project_top_level_has_initialBag =', 'initialBag' in project)
print('globalProperties_keys =', sorted((project.get('globalProperties') or {}).keys()))
print('settings_keys =', sorted((project.get('settings') or {}).keys()))
print('settings_has_initialParty =', 'initialParty' in (project.get('settings') or {}))
print('settings_has_initialBag =', 'initialBag' in (project.get('settings') or {}))
PY
```

Sortie :

```text
pokemon_config = {'enabled': True, 'dataRoot': 'data/pokemon', 'speciesDir': 'data/pokemon/species', 'learnsetsDir': 'data/pokemon/learnsets', 'evolutionsDir': 'data/pokemon/evolutions', 'mediaDir': 'data/pokemon/media', 'catalogFiles': {'moves': 'data/pokemon/catalogs/moves.json', 'abilities': 'data/pokemon/catalogs/abilities.json', 'items': 'data/pokemon/catalogs/items.json', 'types': 'data/pokemon/catalogs/types.json', 'growth_rates': 'data/pokemon/catalogs/growth_rates.json', 'natures': 'data/pokemon/catalogs/natures.json', 'egg_groups': 'data/pokemon/catalogs/egg_groups.json', 'habitats': 'data/pokemon/catalogs/habitats.json', 'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json', 'generations': 'data/pokemon/catalogs/generations.json', 'version_groups': 'data/pokemon/catalogs/version_groups.json'}}
project_top_level_has_initialParty = False
project_top_level_has_initialBag = False
globalProperties_keys = []
settings_keys = ['defaultMapHeight', 'defaultMapWidth', 'defaultPlayerCharacterId', 'displayScale', 'tileHeight', 'tileWidth']
settings_has_initialParty = False
settings_has_initialBag = False
```

Décision P6-02 :

```text
P6-02 n'invente aucun champ JSON.
P6-02 n'utilise pas globalProperties comme stockage magique.
P6-02 prouve le setup initial par seed explicite de test.
```

## 5. Choix du Pokémon initial

Pokémon retenu :

```text
speciesId = pidgeotto
level = 8
abilityId = keen_eye
natureId = hardy
currentHp = 24
moves = gust, tackle
```

Ce choix est technique pour le golden slice. Il n'est pas vendu comme starter
narratif final.

Preuves de données Selbrume :

```bash
python3 - <<'PY'
import json
from pathlib import Path
root = Path('selbrume')
for path in sorted((root/'data/pokemon/species').glob('*.json')):
    data = json.loads(path.read_text())
    if data.get('id') == 'pidgeotto':
        print('species_path =', path)
        print('species_id =', data.get('id'))
        print('species_name =', data.get('names', {}).get('en') or data.get('name'))
        print('abilities =', data.get('abilities'))
        print('refs =', data.get('refs'))
        print('learnsetRef =', data.get('learnsetRef'))
        print('typing =', data.get('typing'))
        print('baseStats =', data.get('baseStats'))
        break
else:
    print('species pidgeotto not found')
learnset_path = root/'data/pokemon/learnsets/pidgeotto.json'
print('learnset_path_exists =', learnset_path.exists())
if learnset_path.exists():
    learnset = json.loads(learnset_path.read_text())
    print('learnset_id =', learnset.get('id'))
    print('startingMoves =', learnset.get('startingMoves'))
    print('levelUp_first_10 =', learnset.get('levelUp', [])[:10])
PY
```

Sortie utile :

```text
species_path = selbrume/data/pokemon/species/0017-pidgeotto.json
species_id = pidgeotto
species_name = Pidgeotto
abilities = {'primary': 'keen_eye', 'secondary': 'tangled_feet', 'hidden': 'big_pecks'}
refs = {'learnset': 'pidgeotto', 'evolution': 'pidgeotto', 'media': 'pidgeotto'}
learnsetRef = None
typing = {'types': ['normal', 'flying']}
baseStats = {'hp': 63, 'atk': 60, 'def': 55, 'spa': 50, 'spd': 50, 'spe': 71, 'bst': 349}
learnset_path_exists = True
learnset_id = None
startingMoves = ['gust', 'quick_attack', 'sand_attack', 'tackle']
levelUp_first_10 = [{'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'black-2-white-2'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'black-white'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'blue-japan'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'brilliant-diamond-shining-pearl'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'colosseum'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'crystal'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'diamond-pearl'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'emerald'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'firered-leafgreen'}, {'moveId': 'gust', 'level': 1, 'source': 'level_up', 'versionGroup': 'gold-silver'}]
```

Preuve moves :

```bash
python3 - <<'PY'
import json
from pathlib import Path
root = Path('selbrume')
moves = json.loads((root/'data/pokemon/catalogs/moves.json').read_text())
entries = moves.get('entries', [])
lookup = {entry.get('id'): entry for entry in entries if isinstance(entry, dict)}
print('moves_catalog_path = selbrume/data/pokemon/catalogs/moves.json')
print('moves_catalog =', moves.get('catalog'))
print('moves_count =', len(entries))
for mid in ['gust','tackle','quick-attack','sand-attack']:
    entry = lookup.get(mid)
    print(f'move {mid} exists =', entry is not None)
    if entry:
        print(f'move {mid} summary =', {k: entry.get(k) for k in ['id','name','type','category','power','accuracy','pp','battleSupport']})
PY
```

Sortie :

```text
moves_catalog_path = selbrume/data/pokemon/catalogs/moves.json
moves_catalog = moves
moves_count = 954
move gust exists = True
move gust summary = {'id': 'gust', 'name': 'Gust', 'type': 'flying', 'category': 'special', 'power': None, 'accuracy': {'value': 100, 'kind': 'percent'}, 'pp': 35, 'battleSupport': None}
move tackle exists = True
move tackle summary = {'id': 'tackle', 'name': 'Tackle', 'type': 'normal', 'category': 'physical', 'power': None, 'accuracy': {'value': 100, 'kind': 'percent'}, 'pp': 35, 'battleSupport': None}
move quick-attack exists = False
move sand-attack exists = False
```

Décision :

```text
Seuls gust et tackle sont retenus en P6-02, car ils existent dans le learnset pidgeotto et dans le catalogue moves Selbrume.
```

## 6. Choix du bag initial

Bag retenu :

```text
poke-ball x5
potion x2
```

Objectif :

```text
poke-ball prépare P6-04 rencontre/capture route 1
potion fournit une ressource de soin minimale sans tester l'effet de soin dans P6-02
```

Preuve items :

```bash
python3 - <<'PY'
import json
from pathlib import Path
root = Path('selbrume')
items = json.loads((root/'data/pokemon/catalogs/items.json').read_text())
entries = items.get('entries', [])
lookup = {entry.get('id'): entry for entry in entries if isinstance(entry, dict)}
print('items_catalog_path = selbrume/data/pokemon/catalogs/items.json')
print('items_catalog =', items.get('catalog'))
print('items_count =', len(entries))
for iid in ['poke-ball','potion','super-potion','antidote']:
    entry = lookup.get(iid)
    print(f'item {iid} exists =', entry is not None)
    if entry:
        print(f'item {iid} summary =', {k: entry.get(k) for k in ['id','name','category','kind','effect','pocket','battleSupport']})
print('first_12_item_ids =', [entry.get('id') for entry in entries[:12] if isinstance(entry, dict)])
PY
```

Sortie :

```text
items_catalog_path = selbrume/data/pokemon/catalogs/items.json
items_catalog = items
items_count = 2176
item poke-ball exists = True
item poke-ball summary = {'id': 'poke-ball', 'name': 'Poké Ball', 'category': None, 'kind': None, 'effect': None, 'pocket': None, 'battleSupport': None}
item potion exists = True
item potion summary = {'id': 'potion', 'name': 'Potion', 'category': None, 'kind': None, 'effect': None, 'pocket': None, 'battleSupport': None}
item super-potion exists = True
item super-potion summary = {'id': 'super-potion', 'name': 'Super Potion', 'category': None, 'kind': None, 'effect': None, 'pocket': None, 'battleSupport': None}
item antidote exists = True
item antidote summary = {'id': 'antidote', 'name': 'Antidote', 'category': None, 'kind': None, 'effect': None, 'pocket': None, 'battleSupport': None}
first_12_item_ids = ['ability-capsule', 'ability-patch', 'ability-shield', 'ability-urge', 'abomasite', 'abra-candy', 'absolite', 'absorb-bulb', 'academy-ball', 'academy-bottle', 'academy-cup', 'academy-tablecloth']
```

Décision :

```text
P6-02 ne crée pas ItemRegistry.
P6-02 ne teste pas l'effet de soin.
P6-02 prouve seulement la présence en bag et la persistence.
```

## 7. Preuve GameState initial

Test créé :

```text
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
```

Le test vérifie :

```text
selbrume/project.json existe dans le repo
loadRuntimeMapBundle charge Selbrume
le spawn "spawn" existe, role playerStart, facing south
les données pidgeotto / gust / tackle / poke-ball / potion existent
createNewGameStateFromMap produit Selbrume x=17 y=24 south
givePokemon ajoute pidgeotto niveau 8
giveItem ajoute poke-ball x5 et potion x2
money reste 0
```

## 8. Preuve roundtrip SaveData

Le test vérifie :

```text
saveDataFromGameState(state)
-> gameStateFromSaveData(saveData)
-> normalizeLoadedGameState(reloaded)
```

Champs conservés :

```text
saveId
currentMapId
playerPosition
playerFacing
trainerProfile.money
party species/level/currentHp/moves
bag itemId/categoryId/quantity
progression caughtSpeciesIds
progression seenSpeciesIds
```

## 9. Tests exécutés

Test ciblé P6-02 :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
00:00 +0: P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=638171
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=2
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1266443
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=1 placedElements=1180 warps=3 triggers=0
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

Régression P6-01 :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
00:00 +0: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=638171
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=2
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1266443
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=1 placedElements=1180 warps=3 triggers=0
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
[runtime_loader] project manifest read ok bytes=638171
[runtime_loader] project manifest validated maps=10 tilesets=30 scenarios=2
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

## 10. Analyse exécutée

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_initial_party_bag_setup_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_initial_party_bag_setup_test.dart...

No issues found! (ran in 2.3s)
```

## 11. Modifications effectuées

Fichier créé :

```text
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_6.md
```

Fichiers non modifiés :

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_5.md
packages/map_core/lib/**
packages/map_gameplay/lib/**
packages/map_runtime/lib/**
selbrume/**
```

## 12. Roadmap Phase 6 mise à jour

Sections modifiées de `MVP Selbrume/road_map_phase_6.md` :

```text
Lot courant : ✅ P6-02 — Selbrume Initial Party / Bag Setup V0

Prochain lot exact : P6-03 — Selbrume First Narrative Interaction V0

Suivi des lots :

- ✅ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
- ✅ P6-01 — Existing Selbrume Loadability / Start Map Contract V0
- ✅ P6-02 — Selbrume Initial Party / Bag Setup V0
- ➡️ P6-03 — Selbrume First Narrative Interaction V0

P6-02 : ✅ terminé

P6-03 : ➡️ prochain lot exact

Prochain lot exact :

P6-03 — Selbrume First Narrative Interaction V0
```

Section ajoutée :

```text
## Résultat P6-02

Preuve ciblée réalisée sur le projet repo-local :

selbrume/project.json est chargé via loadRuntimeMapBundle
start map retenue : Selbrume
spawn retenu : spawn
position conservée : x=17, y=24
facing conservé : south
party initiale seedée par test : pidgeotto niveau 8
moves retenus : gust, tackle
bag initial seedé par test : poke-ball x5, potion x2
money initial conservé : 0
roundtrip SaveData conserve map, position, facing, party, bag, money, caught/seen

Décision initial party / bag :

aucun champ officiel initialParty ou initialBag n'existe dans ProjectManifest
aucun contrat New Game config persistant n'est créé en P6-02
aucun fichier selbrume/ n'est modifié
le setup initial est prouvé par seed explicite de test
```

## 13. Prochain lot exact

```text
P6-03 — Selbrume First Narrative Interaction V0
```

Justification :

```text
P6-01 a verrouillé Selbrume/spawn.
P6-02 a prouvé party/bag initial et roundtrip SaveData.
Le prochain gap du golden slice est la première interaction narrative courte.
```

## 14. Ce qui n'a pas été fait

Non-objectifs respectés :

```text
aucune starter UI
aucune bag UI
aucun professeur / PNJ / dialogue final
aucun trainer
aucun encounter supplémentaire
aucun shop
aucun Pokémon Center
aucune capture flow complet
aucun Boot Flow
aucun audio
aucune UI premium
aucun validator pass complet
aucun runtime smoke complet
aucun P6-03 lancé
```

Limite assumée :

```text
Le setup initial est un seed explicite de test/runtime golden slice.
Le modèle produit persistant "New Game config" reste à décider plus tard si nécessaire.
```

## 15. Evidence Pack

### Gate 0 exact

Voir section 3.

### Preuve que le test n'utilise pas l'ancien chemin Desktop

Commande :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
```

Sortie :

```text
Sortie : <vide>
```

### Contenu complet du test créé

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _spawnId = 'spawn';
const _saveId = 'p6_02_selbrume_initial_party_bag';
const _initialSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData',
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

      final spawn = bundle.map.entities.singleWhere(
        (entity) => entity.id == _spawnId,
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final speciesJson = await _readSpeciesJsonById(
        projectRoot: projectRoot,
        speciesDir: bundle.manifest.pokemon.speciesDir,
        speciesId: _initialSpeciesId,
      );
      expect(speciesJson['id'], _initialSpeciesId);
      expect(
        (speciesJson['abilities'] as Map<String, dynamic>)['primary'],
        _initialAbilityId,
      );

      final learnsetJson = await _readProjectJson(
        projectRoot,
        p.join(
          bundle.manifest.pokemon.learnsetsDir,
          '$_initialSpeciesId.json',
        ),
      );
      expect(
        (learnsetJson['startingMoves'] as List<dynamic>).cast<String>(),
        containsAll(_initialMoves),
      );

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: bundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      expect(moveIds, containsAll(_initialMoves));

      final itemIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: bundle.manifest.pokemon.catalogFiles['items']!,
        expectedCatalog: 'items',
      );
      expect(itemIds, containsAll(<String>[_captureItemId, _medicineItemId]));

      const mutations = GameStateMutations();
      var state = createNewGameStateFromMap(
        startMap: bundle.map,
        saveId: _saveId,
        playerName: 'P6 Tester',
        tileWidthPx: bundle.manifest.settings.tileWidth,
        tileHeightPx: bundle.manifest.settings.tileHeight,
      );

      state = mutations.givePokemon(
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
      state = mutations.giveItem(state, _captureItemId, 5);
      state = mutations.giveItem(state, _medicineItemId, 2);

      expect(state.saveId, _saveId);
      expect(state.currentMapId, _startMapId);
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.trainerProfile.money, 0);
      expect(state.party.members, hasLength(1));
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(state.party.members.single.level, 8);
      expect(state.party.members.single.currentHp, 24);
      expect(state.party.members.single.abilityId, _initialAbilityId);
      expect(state.party.members.single.knownMoveIds, _initialMoves);
      expect(state.bag.entries, hasLength(2));
      expect(
        state.bag.entries,
        contains(
          const BagEntry(
            itemId: _captureItemId,
            categoryId: 'items',
            quantity: 5,
          ),
        ),
      );
      expect(
        state.bag.entries,
        contains(
          const BagEntry(
            itemId: _medicineItemId,
            categoryId: 'medicine',
            quantity: 2,
          ),
        ),
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _startMapId);
      expect(reloaded.playerPosition, const GridPos(x: 17, y: 24));
      expect(reloaded.playerFacing, EntityFacing.south);
      expect(reloaded.trainerProfile.money, 0);
      expect(reloaded.party.members, hasLength(1));
      expect(reloaded.party.members.single.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.single.level, 8);
      expect(reloaded.party.members.single.currentHp, 24);
      expect(reloaded.party.members.single.knownMoveIds, _initialMoves);
      expect(
        reloaded.bag.entries,
        equals(<BagEntry>[
          const BagEntry(
            itemId: _captureItemId,
            categoryId: 'items',
            quantity: 5,
          ),
          const BagEntry(
            itemId: _medicineItemId,
            categoryId: 'medicine',
            quantity: 2,
          ),
        ]),
      );
      expect(
          reloaded.progression.caughtSpeciesIds, contains(_initialSpeciesId));
      expect(reloaded.progression.seenSpeciesIds, contains(_initialSpeciesId));
    },
  );
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
  return (decoded as Map<String, dynamic>);
}
```

### Format

Commande finale :

```bash
dart format --set-exit-if-changed packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
```

Sortie :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

Note :

```text
Une première exécution du format a retourné exit code 1 car elle a formaté le nouveau fichier.
La commande finale ci-dessus prouve que le fichier est ensuite stable.
```

### Diff selbrume

Commande :

```bash
git diff -- selbrume
```

Sortie :

```text
Sortie : <vide>
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
 MVP Selbrume/road_map_phase_6.md | 52 +++++++++++++++++++++++++++++++++-------
 1 file changed, 44 insertions(+), 8 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
MVP Selbrume/road_map_phase_6.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
?? reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
```

Contrôles explicites :

```text
Aucun code production modifié.
Aucun test hors scope modifié.
Aucun fichier selbrume/ modifié.
Aucun contenu final Selbrume créé.
Aucune UI créée.
Aucun P6-03 lancé.
MVP Selbrume/road_map_global.md non modifié.
MVP Selbrume/road_map_phase_5.md non modifié.
```

## 16. Auto-review critique

- Ai-je utilisé le chemin repo-local selbrume ? Oui.
- Ai-je évité l'ancien chemin Desktop ? Oui, le test actif ne le contient pas.
- Ai-je vérifié que les species/moves/items choisis existent ? Oui.
- Ai-je évité de vendre ce Pokémon comme starter final ? Oui.
- Ai-je évité d'inventer initialParty / initialBag dans project.json ? Oui.
- Ai-je évité d'utiliser globalProperties comme champ poubelle ? Oui.
- Ai-je modifié selbrume/ ? Non.
- Ai-je modifié du code production ? Non.
- Ai-je créé seulement un test ciblé ? Oui.
- Ai-je prouvé le roundtrip SaveData ? Oui, par test ciblé.
- Ai-je lancé P6-03 ? Non.
- Ai-je créé du contenu final ? Non.
- Ai-je fixé un prochain lot exact unique ? Oui : P6-03.
