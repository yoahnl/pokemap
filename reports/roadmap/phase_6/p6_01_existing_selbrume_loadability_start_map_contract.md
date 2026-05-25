# P6-01 — Existing Selbrume Loadability / Start Map Contract V0

## 1. Résumé exécutif

P6-01 a prouvé que le projet Selbrume intégré au repo est chargeable par le chemin runtime ciblé :

```text
/Users/karim/Project/pokemonProject/selbrume/project.json
-> loadRuntimeMapBundle(..., mapId: Selbrume)
-> loadRuntimeMapBundle(..., mapId: route 1)
-> resolveInitialPlayerSpawn(Selbrume)
-> createNewGameStateFromMap(Selbrume)
```

Contrat de départ retenu :

```text
startMapId = Selbrume
spawnId = spawn
position = x=17, y=24
facing = south
```

La dépendance dangereuse à la première map du manifest est neutralisée par le test : la première map reste `route 1`, mais P6-01 charge explicitement `Selbrume` pour le New Game.

Le dossier `selbrume/` était déjà massivement présent dans l'état Git au Gate 0. P6-01 n'a pas appliqué de patch aux données Selbrume, et le contrôle final ne montre aucun diff sous `selbrume/`.

Prochain lot exact :

```text
P6-02 — Selbrume Initial Party / Bag Setup V0
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
reports/roadmap/phase_5/p5_checkpoint_01_bis_existing_selbrume_project_alignment.md
```

Sources techniques :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_gameplay/lib/src/player_spawn_resolver.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/map_runtime.dart
packages/map_gameplay/lib/map_gameplay.dart
packages/map_runtime/pubspec.yaml
```

Tests Phase 5 lus :

```text
examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
packages/map_gameplay/test/new_game_state_builder_test.dart
```

Skills lus :

```text
dart-add-unit-test
executing-plans
```

Note : la première tentative de lecture du skill `executing-plans` a utilisé un chemin local erroné et a échoué avec `No such file or directory`. La lecture correcte a ensuite été faite depuis le cache plugin Superpowers.

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
pwd:
/Users/karim/Project/pokemonProject

git branch --show-current:
main

git diff --stat:
Sortie : <vide>

git diff --name-only:
Sortie : <vide>

git log --oneline -n 10:
e2541284 Ajoute le rapport P6-00 et met à jour road_map_phase_6.md
a54b6001 Ajoute le rapport P5-Checkpoint-01-bis et met à jour les roadmaps
beb36d20 Ajoute road_map_phase_6.md et le rapport P5-Checkpoint-01, met à jour road_map_global.md et road_map_phase_5.md
a04b8997 Ajoute P5-10 : Scope Audio Out of Scope Checkpoint Redirect (rapport)
a547ccc2 Ajoute P5-08 et P5-09 : Beta Runtime Smoke et Beta Playability Validator (code, tests et rapports)
2ac26e93 Ajoute P5-07 : Gameplay Save/Load Beta Roundtrip (test et rapport)
f7a0cfd6 Ajoute P5-06 : Capture Destination (Party/Box) Minimal Flow (code, tests et rapport)
ede6aa87 Ajoute P5-05 : Battle Rewards (Money/XP) Minimal Apply (code, test et rapport)
5ac1311c Ajoute P5-04 : Party/Bag Heal Minimal Operations (code, test et rapport)
857a3f3a Met à jour les fichiers pour la résolution du rendu des path patterns (éditeur et runtime)
```

`git status --short --untracked-files=all` initial :

```text
Le statut initial contient 10388 lignes `A  selbrume/...` préexistantes.
Les premières lignes observées sont :

A  selbrume/assets/pokemon/cries/abomasnow.ogg
A  selbrume/assets/pokemon/cries/abra.ogg
A  selbrume/assets/pokemon/cries/absol.ogg
A  selbrume/assets/pokemon/cries/accelgor.ogg
A  selbrume/assets/pokemon/cries/aerodactyl.ogg
A  selbrume/assets/pokemon/cries/aggron.ogg
A  selbrume/assets/pokemon/cries/aipom.ogg
A  selbrume/assets/pokemon/cries/alakazam.ogg
A  selbrume/assets/pokemon/cries/alcremie.ogg
A  selbrume/assets/pokemon/cries/alomomola.ogg
A  selbrume/assets/pokemon/cries/altaria.ogg
A  selbrume/assets/pokemon/cries/amaura.ogg
A  selbrume/assets/pokemon/cries/ambipom.ogg
A  selbrume/assets/pokemon/cries/amoonguss.ogg
A  selbrume/assets/pokemon/cries/ampharos.ogg
```

Commandes repo-local Selbrume :

```bash
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
find "/Users/karim/Project/pokemonProject/selbrume" -maxdepth 2 -type f | sort | sed -n '1,200p'
find "/Users/karim/Project/pokemonProject/selbrume" -maxdepth 2 -type d | sort | sed -n '1,200p'
```

Sorties :

```text
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists

/Users/karim/Project/pokemonProject/selbrume/dialogues/g.yarn
/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
/Users/karim/Project/pokemonProject/selbrume/maps/house 1.json
/Users/karim/Project/pokemonProject/selbrume/maps/house 2.json
/Users/karim/Project/pokemonProject/selbrume/maps/house 3.json
/Users/karim/Project/pokemonProject/selbrume/maps/house 4.json
/Users/karim/Project/pokemonProject/selbrume/maps/house 5.json
/Users/karim/Project/pokemonProject/selbrume/maps/lab.json
/Users/karim/Project/pokemonProject/selbrume/maps/pokémon center.json
/Users/karim/Project/pokemonProject/selbrume/maps/pub.json
/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
/Users/karim/Project/pokemonProject/selbrume/project.json
/Users/karim/Project/pokemonProject/selbrume/project.shadow59.before.json

/Users/karim/Project/pokemonProject/selbrume
/Users/karim/Project/pokemonProject/selbrume/assets
/Users/karim/Project/pokemonProject/selbrume/assets/pokemon
/Users/karim/Project/pokemonProject/selbrume/assets/tilesets
/Users/karim/Project/pokemonProject/selbrume/data
/Users/karim/Project/pokemonProject/selbrume/data/pokemon
/Users/karim/Project/pokemonProject/selbrume/dialogues
/Users/karim/Project/pokemonProject/selbrume/maps
```

## 4. Changement de chemin Selbrume actif

Ancien chemin historique :

```text
/Users/karim/Desktop/selbrume
```

Chemin actif Phase 6 à partir de P6-01 :

```text
/Users/karim/Project/pokemonProject/selbrume
```

Décision :

- les rapports P5/P6-00 conservent l'ancien chemin comme historique ;
- les preuves actives P6-01 et suivantes doivent utiliser le projet repo-local ;
- le test créé en P6-01 cherche `selbrume/project.json` depuis `Directory.current` en remontant jusqu'à la racine repo ;
- le test ne contient pas le chemin Desktop.

Preuve que le test ne référence pas l'ancien chemin :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
Sortie : <vide>
```

## 5. État Git du dossier selbrume/

Commande :

```bash
git status --short --untracked-files=all -- selbrume | sed -n '1,120p'
printf 'SELBRUME_STATUS_COUNT='
git status --short --untracked-files=all -- selbrume | wc -l
```

Sortie utile :

```text
A  selbrume/assets/pokemon/cries/abomasnow.ogg
A  selbrume/assets/pokemon/cries/abra.ogg
A  selbrume/assets/pokemon/cries/absol.ogg
A  selbrume/assets/pokemon/cries/accelgor.ogg
A  selbrume/assets/pokemon/cries/aerodactyl.ogg
A  selbrume/assets/pokemon/cries/aggron.ogg
A  selbrume/assets/pokemon/cries/aipom.ogg
A  selbrume/assets/pokemon/cries/alakazam.ogg
A  selbrume/assets/pokemon/cries/alcremie.ogg
A  selbrume/assets/pokemon/cries/alomomola.ogg
A  selbrume/assets/pokemon/cries/altaria.ogg
A  selbrume/assets/pokemon/cries/amaura.ogg
A  selbrume/assets/pokemon/cries/ambipom.ogg
A  selbrume/assets/pokemon/cries/amoonguss.ogg
A  selbrume/assets/pokemon/cries/ampharos.ogg
SELBRUME_STATUS_COUNT=   10388
```

Décision :

```text
selbrume/ était déjà ajouté à l'état Git au Gate 0.
P6-01 ne modifie donc aucun fichier sous selbrume/.
Le contrat start map / spawn est prouvé par test, pas par mutation data.
```

Vérification des fichiers data autorisés mais non modifiés en worktree :

```bash
git diff -- selbrume/project.json selbrume/maps/Selbrume.json
```

Sortie :

```text
Sortie : <vide>
```

## 6. Preuve de loadability

Test créé :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Ce test prouve :

- `selbrume/project.json` existe dans le repo ;
- `loadRuntimeMapBundle` charge `Selbrume` depuis le projet repo-local ;
- `loadRuntimeMapBundle` charge `route 1` depuis le même projet ;
- le `projectRootDirectory` du bundle est `/Users/karim/Project/pokemonProject/selbrume` ;
- le manifest contient `route 1` et `Selbrume` ;
- la première map du manifest est encore `route 1` ;
- le test sélectionne explicitement `Selbrume`.

Sortie du test ciblé :

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

## 7. Contrat start map / spawn

Parsing read-only du projet repo-local :

```text
project_path = /Users/karim/Project/pokemonProject/selbrume/project.json
maps_order = ['route 1', 'Selbrume', 'house 1', 'house 2', 'house 3', 'house 4', 'house 5', 'pokémon center', 'pub', 'lab']
Selbrume_entry = {'id': 'Selbrume', 'name': 'Selbrume', 'relativePath': 'maps/Selbrume.json', 'groupId': 'group_1777757343053', 'role': 'exterior', 'sortOrder': 0}
route_1_entry = {'id': 'route 1', 'name': 'route 1', 'relativePath': 'maps/route 1.json', 'groupId': 'group_1778244410364', 'role': 'exterior', 'sortOrder': 0}
Selbrume_metadata = {'displayName': '', 'mapType': 'route', 'musicId': None, 'weather': 'none', 'isIndoor': False, 'allowEscapeRope': True, 'defaultSpawnId': None, 'tags': []}
spawn_entity = {'id': 'spawn', 'name': 'spawn', 'kind': 'spawn', 'pos': {'x': 17, 'y': 24}, 'size': {'width': 2, 'height': 2}, 'npc': None, 'sign': None, 'item': None, 'spawn': {'spawnKey': '', 'role': 'player_start', 'facing': 'south', 'categoryTag': ''}, 'editorVisual': None, 'blocksMovement': True, 'properties': {}}
route_1_entities_count = 0
route_1_zones_count = 5
```

Contrat fixé par P6-01 :

```text
startMapId = Selbrume
spawnId = spawn
position = GridPos(x: 17, y: 24)
facing = EntityFacing.south
```

Preuve testée :

```text
resolveInitialPlayerSpawn(Selbrume).pos == GridPos(x: 17, y: 24)
resolveInitialPlayerSpawn(Selbrume).facing == Direction.south
createNewGameStateFromMap(Selbrume).currentMapId == Selbrume
createNewGameStateFromMap(Selbrume).playerPosition == GridPos(x: 17, y: 24)
createNewGameStateFromMap(Selbrume).playerFacing == EntityFacing.south
party initiale vide
bag initial vide
money initial = 0
```

## 8. Décision defaultSpawnId

`MapMetadata.defaultSpawnId` existe dans les modèles et Selbrume le porte déjà dans son JSON :

```text
defaultSpawnId: None
```

P6-01 ne modifie pas `selbrume/maps/Selbrume.json`, pour deux raisons :

1. `selbrume/` était déjà massivement ajouté à l'état Git avant ce lot.
2. Le resolver existant sait résoudre le premier spawn `player_start` quand `defaultSpawnId` est absent.

Décision :

```text
Le contrat P6-01 est explicite dans le test et la roadmap :
startMapId=Selbrume, spawnId=spawn.
Un futur lot pourra décider de persister defaultSpawnId=spawn si la base
Selbrume doit être modifiée une fois l'état Git stabilisé.
```

## 9. Tests exécutés

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Résultat :

```text
00:00 +1: All tests passed!
```

La sortie complète utile est incluse en section 6. Le test a été relancé après
la détection du diff final sur `selbrume/maps/Selbrume.json`; il passe toujours
sur l'état actuel du worktree.

## 10. Analyse exécutée

Commande ciblée :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
Analyzing p6_existing_selbrume_loadability_start_map_contract_test.dart...

No issues found! (ran in 2.2s)
```

Commande package lancée en plus :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos
```

Résultat :

```text
exit code 0
352 infos historiques détectées dans le package, principalement prefer_const_constructors, prefer_const_declarations, avoid_relative_lib_imports et no_leading_underscores_for_local_identifiers.
```

Ces infos ne proviennent pas du test P6-01. La commande ciblée sur le fichier créé est clean.

## 11. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_6.md
MVP Selbrume/road_map_global.md
```

Fichiers Selbrume modifiés :

```text
aucun
```

Code production modifié :

```text
aucun
```

Tests hors scope modifiés :

```text
aucun
```

## 12. Roadmap Phase 6 mise à jour

Sections modifiées de `MVP Selbrume/road_map_phase_6.md` :

```text
SELBRUME_EXISTING_PROJECT_PATH :

/Users/karim/Project/pokemonProject/selbrume

Ancien chemin historique :

/Users/karim/Desktop/selbrume

Lot courant : ✅ P6-01 — Existing Selbrume Loadability / Start Map Contract V0

Prochain lot exact : P6-02 — Selbrume Initial Party / Bag Setup V0

Suivi des lots :
- ✅ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
- ✅ P6-01 — Existing Selbrume Loadability / Start Map Contract V0
- ➡️ P6-02 — Selbrume Initial Party / Bag Setup V0
```

Section ajoutée :

```text
## Changement de chemin actif P6-01

Après P6-00, le projet Selbrume a été intégré directement dans le repo Git.

Chemin actif Phase 6 :

/Users/karim/Project/pokemonProject/selbrume

L'ancien chemin Desktop reste une information historique du checkpoint bis et
de l'audit P6-00. Les preuves actives P6-01 et suivantes doivent utiliser le
dossier repo-local `selbrume/`.
```

Section résultat ajoutée :

```text
## Résultat P6-01

selbrume/project.json existe
loadRuntimeMapBundle charge explicitement la map Selbrume
loadRuntimeMapBundle charge explicitement la map route 1
la première map du manifest reste route 1
le contrat de départ ne dépend donc pas de la première map déclarée
start map retenue : Selbrume
spawn retenu : spawn
position attendue : x=17, y=24
facing attendu : south
createNewGameStateFromMap construit un GameState initial depuis Selbrume/spawn
```

## 13. Prochain lot exact

P6-01 est concluant.

Prochain lot exact :

```text
P6-02 — Selbrume Initial Party / Bag Setup V0
```

Objectif attendu :

```text
fournir une party initiale et un bag minimal utilisables dans le golden slice,
sans créer de starter UI, de bag UI ou de contenu final.
```

## 14. Ce qui n'a pas été fait

```text
pas de modification de selbrume/project.json
pas de modification de selbrume/maps/Selbrume.json
pas de modification de route 1
pas de PNJ créé
pas de dialogue créé
pas de trainer créé
pas d'encounter ajouté
pas de starter final
pas de bag final
pas de capture setup
pas de Boot Flow
pas d'audio
pas de runtime smoke complet
pas de validator pass complet
pas de P6-02
```

## 15. Evidence Pack

### 15.1 Contenu complet du test créé

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn',
    () async {
      final repoRoot = _findRepoRoot();
      final projectFilePath = p.join(repoRoot.path, 'selbrume', 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final selbrumeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'Selbrume',
      );
      final routeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'route 1',
      );

      expect(selbrumeBundle.projectRootDirectory,
          p.normalize(p.join(repoRoot.path, 'selbrume')));
      expect(selbrumeBundle.manifest.name, 'Selbrume');
      expect(
        selbrumeBundle.manifest.maps.map((map) => map.id),
        containsAll(<String>['route 1', 'Selbrume']),
      );
      expect(selbrumeBundle.manifest.maps.first.id, 'route 1');

      expect(selbrumeBundle.map.id, 'Selbrume');
      expect(routeBundle.map.id, 'route 1');
      expect(routeBundle.map.entities, isEmpty);

      final startMap = selbrumeBundle.map;
      expect(startMap.mapMetadata.defaultSpawnId, isNull);

      final spawn = startMap.entities.singleWhere(
        (entity) => entity.id == 'spawn',
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final resolvedSpawn = resolveInitialPlayerSpawn(
        startMap,
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );
      expect(resolvedSpawn.pos, const GridPos(x: 17, y: 24));
      expect(resolvedSpawn.facing, Direction.south);

      final state = createNewGameStateFromMap(
        startMap: startMap,
        saveId: 'p6_01_selbrume_new_game',
        playerName: 'P6 Tester',
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );

      expect(state.saveId, 'p6_01_selbrume_new_game');
      expect(state.currentMapId, 'Selbrume');
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.party.members, isEmpty);
      expect(state.bag.entries, isEmpty);
      expect(state.trainerProfile.money, 0);
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
```

### 15.2 Format

Commande :

```bash
dart format --set-exit-if-changed packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

Sortie :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

### 15.3 Sections modifiées éventuelles de `road_map_global.md`

Modification ciblée du chemin actif Phase 6 :

```diff
-projet existant situé à `/Users/karim/Desktop/selbrume` comme base.
+base active, situé à `/Users/karim/Project/pokemonProject/selbrume`.
```

Les entrées historiques P5-CHECKPOINT-01-bis qui mentionnent l'ancien chemin Desktop sont conservées comme historique.

### 15.4 Diff des fichiers Selbrume modifiés

Commande :

```bash
git diff -- selbrume/project.json selbrume/maps/Selbrume.json
```

Sortie :

```text
Sortie : <vide>
```

### 15.5 Contrôles finaux

`git diff --check` final :

```text
Sortie : <vide>
```

`git diff --stat` final :

```text
 MVP Selbrume/road_map_global.md  |  6 ++--
 MVP Selbrume/road_map_phase_6.md | 72 +++++++++++++++++++++++++++++++++++-----
 2 files changed, 67 insertions(+), 11 deletions(-)
```

`git diff --name-only` final :

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_6.md
```

`git status --short --untracked-files=all` final :

```text
 M "MVP Selbrume/road_map_global.md"
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
?? reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
```

### 15.6 Confirmations

```text
chemin actif Selbrume repo-local utilisé: oui
ancien chemin Desktop non utilisé dans le test: oui
loadability réelle prouvée par loadRuntimeMapBundle: oui
New Game minimal construit depuis Selbrume/spawn: oui
route 1 première map neutralisée par sélection explicite: oui
aucun champ startMapId inventé: oui
aucun fichier selbrume/ modifié: oui
aucun code production modifié: oui
aucun test hors scope modifié: oui
P6-02 non lancé: oui
aucun contenu final Selbrume créé: oui
```

## 16. Auto-review critique

- Ai-je remplacé le chemin actif Desktop par le chemin repo-local ? Oui.
- Ai-je évité de réécrire l'historique inutilement ? Oui, les anciennes mentions historiques restent historiques.
- Ai-je prouvé la loadability réelle ou seulement le parsing JSON ? Loadability réelle prouvée via `loadRuntimeMapBundle` sur `Selbrume` et `route 1`.
- Ai-je évité de dépendre de la première map `route 1` ? Oui, le test vérifie que `route 1` reste première et charge explicitement `Selbrume`.
- Ai-je fixé un contrat start map / spawn clair ? Oui : `Selbrume / spawn`.
- Ai-je évité d'inventer un champ `startMapId` non supporté ? Oui.
- Ai-je évité de modifier `selbrume/` alors que le dossier était déjà massif au Gate 0 ? Oui.
- Ai-je modifié du code production ? Non.
- Ai-je modifié des tests hors scope ? Non.
- Ai-je lancé P6-02 ? Non.
- Ai-je créé du contenu final Selbrume ? Non.
- Ai-je gardé le lot borné ? Oui.
- Ai-je identifié un prochain lot exact unique ? Oui : `P6-02 — Selbrume Initial Party / Bag Setup V0`.
