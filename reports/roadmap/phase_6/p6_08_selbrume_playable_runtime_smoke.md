# P6-08 — Selbrume Playable Runtime Smoke V0

## 1. Résumé exécutif

P6-08 est concluant au niveau **Level B** : le projet Selbrume repo-local est
chargé depuis le disque réel, `PlayableMapGame` est instancié avec un état New
Game Selbrume/spawn seedé, `onLoad` termine sans crash, les tilesets Selbrume
sont chargés, et les assertions runtime confirment la map active, le joueur et
l'état gameplay minimal.

Ce lot ne prouve pas une session joueur interactive complète, ne prouve pas le
Boot Flow, ne lance pas le checkpoint P6 et n'injecte pas encore l'état complet
P6-06 sauvegardé sur `route 1`.

## 2. Sources lues

Fichiers d'instructions et roadmaps :

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_6.md
```

Rapports Phase 6 lus :

```text
reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
reports/roadmap/phase_6/p6_04_bis_selbrume_git_worktree_attribution.md
reports/roadmap/phase_6/p6_04_ter_selbrume_grant_reconciliation_p6_03_regression_fix.md
reports/roadmap/phase_6/p6_05_selbrume_first_trainer_battle_golden_slice.md
reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md
reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md
reports/roadmap/phase_6/p6_07_selbrume_beta_validator_pass.md
```

Tests et sources runtime lus :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/save_game_use_case.dart
packages/map_runtime/lib/src/application/load_game_use_case.dart
packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
packages/map_runtime/lib/map_runtime.dart
```

Flame docs MCP consulté :

```text
search_documentation("FlameGame onLoad GameWidget test widget lifecycle onLoad") -> No results found
search_documentation("GameWidget onLoad FlameGame testing") -> No results found
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
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
git status --short --untracked-files=all -- selbrume
```

Sorties :

```text
/Users/karim/Project/pokemonProject
main
git status initial : Sortie : <vide>
git diff --stat initial : Sortie : <vide>
git diff --name-only initial : Sortie : <vide>
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle Golden Slice (test et rapport)
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists
git status selbrume initial : Sortie : <vide>
```

État Gate 0 :

```text
worktree propre
selbrume/ propre
selbrume/project.json présent dans le repo
aucun blocker Gate 0
```

## 4. Niveau de smoke runtime visé

Niveau visé et obtenu : **Level B**.

```text
Level A — PlayableMapGame onLoad avec projet Selbrume repo-local + état golden slice sauvegardé/rechargé
Level B — PlayableMapGame onLoad avec projet Selbrume repo-local + New Game Selbrume/spawn
Level C — RuntimeMapBundle + application runtime only, pas PlayableMapGame
```

Raison du choix :

```text
PlayableMapGame accepte un RuntimeMapBundle, un projectFilePath et un SaveData.
Le test peut donc prouver onLoad réel avec la map Selbrume/spawn.
L'injection honnête de l'état P6-06 complet sur route 1 demanderait un bundle route 1 compatible
et ne prouverait pas encore un Boot Flow de reprise de sauvegarde complet.
P6-08 reste donc borné à un smoke runtime New Game Selbrume/spawn.
```

## 5. API runtime utilisée

API utilisée :

```text
loadRuntimeMapBundle(projectFilePath, mapId: Selbrume)
loadRuntimeMapBundle(projectFilePath, mapId: route 1)
createNewGameStateFromMap(startMap: Selbrume)
GameStateMutations.givePokemon
GameStateMutations.giveItem
GameStateMutations.setFlag
GameStateMutations.completeStep
saveDataFromGameState
PlayableMapGame(bundle, projectFilePath, saveData)
PlayableMapGame.onGameResize
PlayableMapGame.onLoad
PlayableMapGame.update(0)
PlayableMapGame.debugFlowPhaseName
PlayableMapGame.debugIsMapLoaded
PlayableMapGame.debugPlayerGridPosition
PlayableMapGame.gameStateSnapshot
```

## 6. État initial ou sauvegardé utilisé

État utilisé :

```text
New Game Selbrume/spawn
saveId : p6_08_selbrume_playable_runtime_smoke
party : pidgeotto niveau 8, ability keen_eye, moves gust/tackle, currentHp 24
bag : poke-ball x5, potion x2
story flag : p6.selbrume.first_interaction.seen
completed step : p6.selbrume.first_interaction
money : 0
```

État P6-06 sauvegardé complet :

```text
Commande non lancée : l'injection de l'état disque complet P6-06 dans un Boot Flow runtime n'est pas le niveau prouvé par ce lot.
```

## 7. Preuve PlayableMapGame / host runtime

Preuve obtenue :

```text
loadRuntimeMapBundle charge Selbrume depuis /Users/karim/Project/pokemonProject/selbrume/project.json
loadRuntimeMapBundle charge route 1 depuis le même project.json
PlayableMapGame est instancié avec le bundle Selbrume et SaveData seedé
onGameResize(Vector2(320, 240)) est appelé avant onLoad
await game.onLoad() termine sans exception
game.update(0) termine sans exception
debugFlowPhaseName = overworld
debugIsMapLoaded(Selbrume) = true
debugPlayerGridPosition = GridPos(x: 17, y: 24)
```

## 8. Assertions runtime obtenues

Assertions principales :

```text
repo-local selbrume/project.json existe
projectRootDirectory = /Users/karim/Project/pokemonProject/selbrume
Selbrume bundle map.id = Selbrume
route 1 bundle map.id = route 1
tilesetAbsolutePathsById non vide
tous les chemins de tilesets Selbrume existent sur disque
saveLoadInfo.mapId = Selbrume
saveLoadInfo.playerX = 17
saveLoadInfo.playerY = 24
saveLoadInfo.facing = south
currentMapId = Selbrume
playerPosition = GridPos(x: 17, y: 24)
playerFacing = south
party size = 1
party[0].speciesId = pidgeotto
party[0].level = 8
party[0].knownMoveIds = gust,tackle
bag poke-ball = 5
bag potion = 2
story flag p6.selbrume.first_interaction.seen présent
completed step p6.selbrume.first_interaction présent
money = 0
```

## 9. Limites honnêtes du smoke

Limites :

```text
pas de session joueur interactive complète
pas de simulation clavier/manette
pas de Boot Flow
pas d'écran titre
pas de slots UI
pas de capture UI
pas de Battle UI
pas de checkpoint P6 lancé
pas d'injection runtime de l'état P6-06 complet sauvegardé sur route 1
```

## 10. Tests exécutés

Test ciblé :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_playable_runtime_smoke_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart
00:00 +0: P6-08 boots repo-local Selbrume in PlayableMapGame without crashing
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
[runtime_game] onLoad start map=Selbrume projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json tilesets=10
[runtime_game] world build start map=Selbrume
[runtime] Map loaded: Selbrume, spawn at (17, 24)
[runtime_game] tileset image load start map=Selbrume
[runtime_game] tileset cache resolve requested=10
[runtime_game] tileset cache miss id=arbre_pixellab path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/arbre_pixellab.png
[runtime_game] tileset cache miss id=selbrume_all_sprite path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/selbrume_all_sprite.png
[runtime_game] tileset cache miss id=grass_elements path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/grass_elements.png
[runtime_game] tileset cache miss id=objectif path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/objectif.png
[runtime_game] tileset cache miss id=fleurs_selbrume_de_toure_es path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/fleurs_selbrume_de_toure_es.png
[runtime_game] tileset cache miss id=deep_water path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/deep_water.png
[runtime_game] tileset cache miss id=pavement_path path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/pavement_path.png
[runtime_game] tileset cache miss id=gros_sol_herbre path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/gros_sol_herbre.png
[runtime_game] tileset cache miss id=beach_tile path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/beach_tile.png
[runtime_game] tileset cache miss id=vova path=/Users/karim/Project/pokemonProject/selbrume/assets/tilesets/vova.png
[runtime_game] tileset image loader start missing=10
[runtime_game] tileset image loaded id=arbre_pixellab
[runtime_game] tileset image loaded id=selbrume_all_sprite
[runtime_game] tileset image loaded id=grass_elements
[runtime_game] tileset image loaded id=objectif
[runtime_game] tileset image loaded id=fleurs_selbrume_de_toure_es
[runtime_game] tileset image loaded id=deep_water
[runtime_game] tileset image loaded id=pavement_path
[runtime_game] tileset image loaded id=gros_sol_herbre
[runtime_game] tileset image loaded id=beach_tile
[runtime_game] tileset image loaded id=vova
[runtime_game] tileset cache resolve ok result=10
[runtime_game] tileset image load ok count=10 map=Selbrume
[runtime_game] mount root map start map=Selbrume
[runtime_game] mount root map ok map=Selbrume
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=route 1
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=house 1
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=house 2
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_game] onLoad completed activeMapId=Selbrume
[runtime_game] tileset cache resolve requested=10
[runtime_game] tileset cache hit id=arbre_pixellab
[runtime_game] tileset cache hit id=selbrume_all_sprite
[runtime_game] tileset cache hit id=grass_elements
[runtime_game] tileset cache hit id=objectif
[runtime_game] tileset cache hit id=fleurs_selbrume_de_toure_es
[runtime_game] tileset cache hit id=deep_water
[runtime_game] tileset cache hit id=pavement_path
[runtime_game] tileset cache hit id=gros_sol_herbre
[runtime_game] tileset cache hit id=beach_tile
[runtime_game] tileset cache hit id=vova
[runtime_game] tileset cache resolve ok result=10
00:00 +1: All tests passed!
```

Régressions P6-01 à P6-07 :

```text
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
00:01 +1: All tests passed!

cd packages/map_runtime && flutter test test/p6_selbrume_save_load_golden_slice_test.dart
00:01 +1: All tests passed!

cd packages/map_runtime && flutter test test/p6_selbrume_beta_validator_pass_test.dart
00:00 +1: All tests passed!
```

## 11. Analyse exécutée

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_playable_runtime_smoke_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_playable_runtime_smoke_test.dart...
No issues found! (ran in 2.7s)
```

## 12. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart
reports/roadmap/phase_6/p6_08_selbrume_playable_runtime_smoke.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_6.md
```

Fichiers non modifiés :

```text
selbrume/**
packages/**/lib/**
examples/**/lib/**
```

## 13. Roadmap Phase 6 mise à jour

Sections modifiées :

```text
Lot courant : ✅ P6-08 — Selbrume Playable Runtime Smoke V0
Prochain lot exact : P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

- ✅ P6-08 — Selbrume Playable Runtime Smoke V0
- ➡️ P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

P6-08 : ✅ terminé
P6-CHECKPOINT-01 : ➡️ prochain lot exact

## Résultat P6-08
...
### ✅ P6-08 — Selbrume Playable Runtime Smoke V0
Statut : terminé.
Preuve : packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart

### ➡️ P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review
Statut : prochain lot exact.
```

## 14. Prochain lot exact

```text
P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review
```

Ce checkpoint n'a pas été lancé en P6-08.

## 15. Ce qui n’a pas été fait

```text
aucune modification selbrume/
aucune modification du code production
aucune modification examples/**/lib/**
pas de Boot Flow
pas d'écran titre
pas de slots UI
pas d'UI premium
pas de vraie session joueur complète
pas d'injection runtime de l'état disque P6-06 complet
pas de checkpoint P6 lancé
```

## 16. Evidence Pack

### Chemins et Git initiaux

```text
pwd -> /Users/karim/Project/pokemonProject
branche courante -> main
git status initial -> Sortie : <vide>
git diff --stat initial -> Sortie : <vide>
git diff --name-only initial -> Sortie : <vide>
git log --oneline -n 10 -> listé en section 3
```

### Projet Selbrume

```text
test existence repo-local selbrume/ -> REPO_SELBRUME_PROJECT_PATH exists
test existence selbrume/project.json -> repo-local selbrume/project.json exists
état Git de selbrume/ initial -> Sortie : <vide>
aucun fichier selbrume/ modifié
```

### Ancien chemin Desktop

Commande :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart || true
```

Sortie :

```text
Sortie : <vide>
```

### Niveau de smoke obtenu

```text
Level B — PlayableMapGame onLoad avec projet Selbrume repo-local + New Game Selbrume/spawn
```

### API runtime utilisée

```text
loadRuntimeMapBundle
createNewGameStateFromMap
saveDataFromGameState
PlayableMapGame
onGameResize
onLoad
update
debugFlowPhaseName
debugIsMapLoaded
debugPlayerGridPosition
gameStateSnapshot
```

### Contenu complet du test créé

```dart
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _saveId = 'p6_08_selbrume_playable_runtime_smoke';
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
    'P6-08 boots repo-local Selbrume in PlayableMapGame without crashing',
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
      expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(selbrumeBundle.map.id, _startMapId);
      expect(routeBundle.map.id, _routeMapId);
      expect(selbrumeBundle.tilesetAbsolutePathsById, isNotEmpty);
      expect(
        selbrumeBundle.tilesetAbsolutePathsById.values.every(
          (path) => File(path).existsSync(),
        ),
        isTrue,
      );

      final state = _buildSeededNewGameState(selbrumeBundle);
      final game = PlayableMapGame(
        bundle: selbrumeBundle,
        projectFilePath: projectFilePath,
        saveData: saveDataFromGameState(state),
      );

      expect(game.saveLoadInfo.mapId, _startMapId);
      expect(game.saveLoadInfo.playerX, 17);
      expect(game.saveLoadInfo.playerY, 24);
      expect(game.saveLoadInfo.facing, EntityFacing.south.name);
      expect(game.gameStateSnapshot.party.members.single.speciesId,
          _initialSpeciesId);
      expect(
          game.gameStateSnapshot.storyFlags.activeFlags, contains(_p603FlagId));

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      game.update(0);

      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsMapLoaded(_startMapId), isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 17, y: 24));

      final runtimeState = game.gameStateSnapshot;
      expect(runtimeState.saveId, _saveId);
      expect(runtimeState.currentMapId, _startMapId);
      expect(runtimeState.playerPosition, const GridPos(x: 17, y: 24));
      expect(runtimeState.playerFacing, EntityFacing.south);
      expect(runtimeState.party.members, hasLength(1));
      expect(runtimeState.party.members.single.speciesId, _initialSpeciesId);
      expect(runtimeState.party.members.single.level, 8);
      expect(runtimeState.party.members.single.currentHp, 24);
      expect(runtimeState.party.members.single.knownMoveIds, _initialMoves);
      expect(_bagQuantity(runtimeState, _captureItemId), 5);
      expect(_bagQuantity(runtimeState, _medicineItemId), 2);
      expect(runtimeState.storyFlags.activeFlags, contains(_p603FlagId));
      expect(
        runtimeState.progression.completedStepIds,
        contains(_p603StepId),
      );
      expect(runtimeState.trainerProfile.money, 0);
    },
  );
}

GameState _buildSeededNewGameState(RuntimeMapBundle bundle) {
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
  state = mutations.setFlag(state, _p603FlagId);
  state = mutations.completeStep(state, _p603StepId);
  return state;
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
```

### Sorties de vérification

Test ciblé : section 10.

Régressions :

```text
P6-01 : 00:00 +1: All tests passed!
P6-02 : 00:00 +1: All tests passed!
P6-03 : 00:00 +1: All tests passed!
P6-04 : 00:00 +1: All tests passed!
P6-05 : 00:01 +1: All tests passed!
P6-06 : 00:01 +1: All tests passed!
P6-07 : 00:00 +1: All tests passed!
```

Analyse ciblée : section 11.

### Git final

```text
git diff --check final -> Sortie : <vide>
git diff --stat final ->
 MVP Selbrume/road_map_phase_6.md | 62 ++++++++++++++++++++++++++++++++++------
 1 file changed, 53 insertions(+), 9 deletions(-)
git diff --name-only final ->
MVP Selbrume/road_map_phase_6.md
git status final ->
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart
?? reports/roadmap/phase_6/p6_08_selbrume_playable_runtime_smoke.md
```

### Confirmations

```text
aucun code production modifié
aucun fichier selbrume/ modifié
aucun checkpoint P6 lancé
aucun commit
aucun staging
```

## 17. Auto-review critique

Ai-je utilisé le chemin repo-local selbrume ?

```text
Oui. Le test localise repoRoot en remontant jusqu'à selbrume/project.json et utilise /Users/karim/Project/pokemonProject/selbrume.
```

Ai-je évité l'ancien chemin Desktop ?

```text
Oui. rg ne trouve aucune occurrence de /Users/karim/Desktop/selbrume dans le test P6-08.
```

Ai-je atteint PlayableMapGame / host runtime ?

```text
Oui. PlayableMapGame est instancié et onLoad termine sans crash.
```

Ai-je clairement classé le niveau de smoke ?

```text
Oui. Niveau obtenu : Level B.
```

Ai-je évité de vendre une session interactive complète ?

```text
Oui. Le rapport limite la preuve à un smoke onLoad/update ciblé.
```

Ai-je évité de modifier selbrume/ ?

```text
Oui. Aucun fichier selbrume/ n'est modifié.
```

Ai-je modifié du code production ?

```text
Non. Seul un test P6-08 a été créé côté package.
```

Ai-je lancé le checkpoint P6 ?

```text
Non.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review.
```
