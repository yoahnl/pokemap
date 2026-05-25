# P6-06 — Selbrume Save/Load Golden Slice V0

## 1. Résumé exécutif

P6-06 est concluant.

Le lot prouve que l'état complet du golden slice Selbrume construit jusqu'à
P6-05 survit à une vraie sauvegarde disque et à un vrai rechargement disque.

Chaîne prouvée :

```text
repo-local selbrume/project.json
-> loadRuntimeMapBundle Selbrume
-> loadRuntimeMapBundle route 1
-> New Game Selbrume/spawn
-> party/bag P6-02
-> flag/step P6-03
-> capture P6-04
-> trainer battle Grant P6-05 avec outcome contrôlé
-> SaveGameUseCase + FileGameSaveRepository
-> vrai fichier temporaire game_save.json hors repo
-> LoadGameUseCase
-> normalizeLoadedGameState(...)
-> assertions golden slice complètes
```

Niveau de preuve obtenu :

```text
repository/use-case disque réel
pas seulement roundtrip SaveData en mémoire
pas UI save/load
pas menu de sauvegarde
pas Boot Flow
```

Chemin de sauvegarde observé pendant le test :

```text
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p6_06_selbrume_save_load_Up31dL/pokemonProject/game_save.json
```

Ce chemin est sous `Directory.systemTemp`, hors repo et hors `selbrume/`.

Prochain lot exact :

```text
P6-07 — Selbrume Beta Validator Pass V0
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
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
reports/roadmap/phase_6/p6_04_selbrume_route_1_encounter_capture_golden_slice.md
reports/roadmap/phase_6/p6_04_bis_selbrume_git_worktree_attribution.md
reports/roadmap/phase_6/p6_04_ter_selbrume_grant_reconciliation_p6_03_regression_fix.md
reports/roadmap/phase_6/p6_05_selbrume_first_trainer_battle_golden_slice.md
reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md
```

Tests lus :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
```

Sources techniques lues :

```text
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
packages/map_runtime/lib/src/application/save_game_use_case.dart
packages/map_runtime/lib/src/application/load_game_use_case.dart
packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
packages/map_runtime/lib/domain/repositories/game_save_repository.dart
```

Skills lus :

```text
superpowers:test-driven-development
superpowers:verification-before-completion
```

Roadmap mécanique fangame :

```text
Le bloc Save/GameState reste PARTIAL au sens produit complet, car P6-06 ne crée
pas UI save/load, menu, slots, Boot Flow ou session runtime complète.
P6-06 apporte une preuve disque réelle ciblée du golden slice Selbrume.
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

Sortie :

```text
/Users/karim/Project/pokemonProject
main
 M "MVP Selbrume/road_map_phase_6.md"
?? reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md
 MVP Selbrume/road_map_phase_6.md | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)
MVP Selbrume/road_map_phase_6.md
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle Golden Slice (test et rapport)
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
8f40c1f6 update gitignore
02fbb1db add grant
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists
```

`git status --short --untracked-files=all -- selbrume` :

```text
Sortie : <vide>
```

État préexistant documenté :

```text
MVP Selbrume/road_map_phase_6.md était déjà modifié au Gate 0 par P6-05-bis.
reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md était
déjà non tracké au Gate 0.
P6-06 n'a pas modifié ce rapport P6-05-bis.
```

## 4. Mécanisme save/load existant

Mécanisme choisi :

```text
SaveGameUseCase
LoadGameUseCase
FileGameSaveRepository
```

Justification :

```text
Ces classes existent déjà dans map_runtime.
FileGameSaveRepository est le repository fichier utilisé par les tests P5.
Le test P6-06 crée une sous-classe de test pour rediriger getSaveFilePath()
vers Directory.systemTemp, comme les tests P5 existants.
```

Niveau de preuve :

```text
real disk save/load through application/repository layer
```

Ce qui n'est pas utilisé :

```text
pas de fallback codec manuel
pas de fichier écrit dans le repo
pas de fichier écrit dans selbrume/
```

## 5. État golden slice reconstruit

État reconstruit dans le test :

```text
saveId = p6_06_selbrume_save_load_golden_slice
currentMapId = route 1
playerPosition = x=24, y=22
playerFacing = north
party[0] = pidgeotto, level 9, currentHp 18, moves gust/tackle
party[1] = pidgeotto capturé, level 3, currentHp 16 après trainer write-back, moves gust/tackle
pokemonStorage = vide
bag = poke-ball x4, potion x2
money = 120
story flag = p6.selbrume.first_interaction.seen
completed step = p6.selbrume.first_interaction
trainer defeated flag = trainer_defeated:grant
caughtSpeciesIds contient pidgeotto
seenSpeciesIds contient pidgeotto
metadata = lot p6_06, persistence file_game_save_repository
```

Note sur le second Pidgeotto :

```text
Le Pidgeotto capturé a currentHp 16 après le write-back trainer P6-05, car le
mapper battle reconstruit la réserve selon le setup battle. P6-06 vérifie donc
l'état complet réel après P6-05, pas seulement l'état P6-04 pré-battle.
```

## 6. Preuve sauvegarde disque

Le test utilise :

```text
Directory.systemTemp.createTemp('p6_06_selbrume_save_load_')
_TempFileGameSaveRepository extends FileGameSaveRepository
SaveGameUseCase(repository).execute(state)
```

Assertions de sauvegarde :

```text
saveGame.execute(state) == true
repository.exists() == true
game_save.json existe
saveFilePath hors repo
saveFilePath hors selbrume/
JSON disque contient saveId p6_06_selbrume_save_load_golden_slice
JSON disque contient currentMapId route 1
JSON disque contient pokemonStorage
JSON disque contient story flag P6-03
```

## 7. Preuve chargement disque

Le test utilise :

```text
LoadGameUseCase(repository).execute()
normalizeLoadedGameState(loaded)
```

Assertions de chargement :

```text
loaded != null
reloaded.saveId = p6_06_selbrume_save_load_golden_slice
reloaded.currentMapId = route 1
reloaded.playerPosition = x=24, y=22
reloaded.playerFacing = north
reloaded.party, bag, money, flags, progression et metadata conservés
```

## 8. Assertions après reload

Assertions principales :

```text
saveId conservé
route 1 conservée
position x=24 y=22 conservée
facing north conservé
party size 2 conservée
party[0] pidgeotto level 9 HP 18 moves gust/tackle conservé
party[1] pidgeotto level 3 HP 16 moves gust/tackle conservé
storage vide conservé
poke-ball x4 conservé
potion x2 conservé
money 120 conservé
p6.selbrume.first_interaction.seen conservé
p6.selbrume.first_interaction conservé
trainer_defeated:grant conservé
caught/seen pidgeotto conservés
metadata P6-06 conservée
```

## 9. Tests exécutés

### 9.1 RED / corrections de test

Premier lancement du test P6-06 :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_save_load_golden_slice_test.dart
```

Sortie :

```text
test/p6_selbrume_save_load_golden_slice_test.dart:208:24: Error: The method 'mapSync' isn't defined for the type 'RuntimeBattleSetupMapper'.
```

Correction :

```text
Remplacement de mapSync par l'API existante await mapper.map(...).
```

Deuxième lancement :

```text
Expected: <18>
  Actual: <16>
```

Correction :

```text
L'assertion du HP du Pokémon capturé a été alignée avec l'état réel post
write-back trainer P6-05 : currentHp = 16.
```

### 9.2 Test ciblé P6-06

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_save_load_golden_slice_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
00:00 +0: P6-06 persists the full Selbrume golden slice through real disk save/load
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
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p6_06_selbrume_save_load_Up31dL/pokemonProject/game_save.json completedStepIds=[p6.selbrume.first_interaction]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p6_06_selbrume_save_load_Up31dL/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p6_06_selbrume_save_load_Up31dL/pokemonProject/game_save.json completedStepIds=[p6.selbrume.first_interaction]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p6_06_selbrume_save_load_Up31dL/pokemonProject/game_save.json
00:01 +1: All tests passed!
```

### 9.3 Régressions P6-01 à P6-05

Commande :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart && flutter test test/p6_selbrume_first_narrative_interaction_test.dart && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart && flutter test test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
```

Sorties finales :

```text
P6-01:
00:00 +1: All tests passed!

P6-02:
00:00 +1: All tests passed!

P6-03:
00:00 +1: All tests passed!

P6-04:
00:00 +1: All tests passed!

P6-05:
00:01 +1: All tests passed!
```

## 10. Analyse exécutée

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_save_load_golden_slice_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_save_load_golden_slice_test.dart...

No issues found! (ran in 2.1s)
```

## 11. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_6.md
```

Fichiers préexistants non attribués à P6-06 :

```text
reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md
```

Fichiers `selbrume/` modifiés :

```text
Sortie : <vide>
```

## 12. Roadmap Phase 6 mise à jour

Sections mises à jour :

```text
Lot courant : ✅ P6-06 — Selbrume Save/Load Golden Slice V0
Prochain lot exact : P6-07 — Selbrume Beta Validator Pass V0

- ✅ P6-06 — Selbrume Save/Load Golden Slice V0
- ➡️ P6-07 — Selbrume Beta Validator Pass V0

P6-06 : ✅ terminé
P6-07 : ➡️ prochain lot exact

Résultat P6-06 ajouté.

### ✅ P6-06 — Selbrume Save/Load Golden Slice V0
Statut : terminé.

### ➡️ P6-07 — Selbrume Beta Validator Pass V0
Statut : prochain lot exact.
```

## 13. Prochain lot exact

```text
P6-07 — Selbrume Beta Validator Pass V0
```

Justification :

```text
P6-06 a prouvé la persistance disque réelle du golden slice.
Le prochain risque logique est le validator bêta Selbrume, sans démarrer le
runtime smoke complet P6-08.
```

## 14. Ce qui n’a pas été fait

```text
Aucun fichier selbrume/ modifié.
Aucun code production modifié.
Aucun test existant modifié.
Aucune UI save/load créée.
Aucun menu sauvegarde créé.
Aucun Boot Flow créé.
Aucun autosave system créé.
Aucun cloud save créé.
Aucun slot UI créé.
Aucun validator pass complet lancé.
Aucun runtime smoke complet lancé.
P6-07 n'a pas été lancé.
P6-08 n'a pas été lancé.
```

## 15. Evidence Pack

### 15.1 Gate 0

Voir section 3 pour les sorties Gate 0 exactes.

### 15.2 Preuve que le test n'utilise pas l'ancien chemin Desktop

Commande :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart || true
```

Sortie :

```text
Sortie : <vide>
```

### 15.3 Contenu complet du test créé

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _saveId = 'p6_06_selbrume_save_load_golden_slice';
const _trainerId = 'grant';
const _trainerDefeatedFlag = 'trainer_defeated:grant';
const _grantNpcId = 'grant';
const _initialSpeciesId = 'pidgeotto';
const _capturedSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';
const _p603FlagId = 'p6.selbrume.first_interaction.seen';
const _p603StepId = 'p6.selbrume.first_interaction';
const _rewardMoney = 120;
const _grantPlayerBattlePos = GridPos(x: 24, y: 22);
const _capturedHpAfterTrainerWriteBack = 16;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-06 persists the full Selbrume golden slice through real disk save/load',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');
      final testDirectory =
          await Directory.systemTemp.createTemp('p6_06_selbrume_save_load_');
      final repository = _TempFileGameSaveRepository(testDirectory);
      final saveGame = SaveGameUseCase(repository);
      final loadGame = LoadGameUseCase(repository);

      try {
        expect(await File(projectFilePath).exists(), isTrue);
        expect(p.isWithin(repoRoot.path, testDirectory.path), isFalse);

        final selbrumeBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: _startMapId,
        );
        final routeBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: _routeMapId,
        );

        expect(
          selbrumeBundle.projectRootDirectory,
          p.normalize(projectRoot.path),
        );
        expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
        expect(selbrumeBundle.map.id, _startMapId);
        expect(routeBundle.map.id, _routeMapId);

        var state = createNewGameStateFromMap(
          startMap: selbrumeBundle.map,
          saveId: _saveId,
          playerName: 'P6 Tester',
          tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
          tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
        ).copyWith(
          metadata: const <String, String>{
            'lot': 'p6_06',
            'persistence': 'file_game_save_repository',
          },
        );

        state = _seedP6InitialState(state);
        state = _applyP603NarrativeState(state);
        state = _applyP604CaptureState(state);
        state = await _applyP605TrainerVictoryState(
          state: state,
          routeBundle: routeBundle,
        );

        _expectGoldenSliceState(state);
        expect(await saveGame.execute(state), isTrue);
        expect(await repository.exists(), isTrue);

        final saveFilePath = await repository.exposedSaveFilePath();
        final saveFile = File(saveFilePath);
        expect(await saveFile.exists(), isTrue);
        expect(p.isWithin(repoRoot.path, saveFile.path), isFalse);
        expect(p.isWithin(projectRoot.path, saveFile.path), isFalse);

        final savedJson =
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
        expect(savedJson['saveId'], _saveId);
        expect(savedJson['currentMapId'], _routeMapId);
        expect(savedJson['pokemonStorage'], isA<Map<String, dynamic>>());
        expect(
          (savedJson['progression'] as Map<String, dynamic>)['storyFlags'],
          contains(_p603FlagId),
        );

        final loaded = await loadGame.execute();
        expect(loaded, isNotNull);

        final reloaded = normalizeLoadedGameState(loaded!);
        _expectGoldenSliceState(reloaded);
      } finally {
        if (await testDirectory.exists()) {
          await testDirectory.delete(recursive: true);
        }
      }
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

GameState _applyP603NarrativeState(GameState state) {
  const mutations = GameStateMutations();
  var next = mutations.setFlag(state, _p603FlagId);
  next = mutations.completeStep(next, _p603StepId);
  return next;
}

GameState _applyP604CaptureState(GameState state) {
  const mutations = GameStateMutations();
  var next = markSpeciesSeenInGameState(state, _capturedSpeciesId);
  next = mutations.consumeItem(next, _captureItemId, 1);
  final captureResult = mutations.applyCapturedPokemon(
    next,
    pokemon: const PlayerPokemon(
      speciesId: _capturedSpeciesId,
      natureId: 'hardy',
      abilityId: _initialAbilityId,
      level: 3,
      currentHp: 18,
      knownMoveIds: _initialMoves,
    ),
  );
  expect(captureResult.destination, CaptureDestinationKind.party);
  expect(captureResult.partyIndex, 1);
  return captureResult.state;
}

Future<GameState> _applyP605TrainerVictoryState({
  required GameState state,
  required RuntimeMapBundle routeBundle,
}) async {
  const mutations = GameStateMutations();
  var next = mutations.warpPlayer(
    state,
    _routeMapId,
    _grantPlayerBattlePos.x,
    _grantPlayerBattlePos.y,
    facing: EntityFacing.north,
  );

  final grantNpc = routeBundle.map.entities.singleWhere(
    (entity) => entity.id == _grantNpcId,
  );
  expect(grantNpc.kind, MapEntityKind.npc);
  expect(grantNpc.npc?.trainerId, _trainerId);

  final world = GameplayWorldState.initial(
    map: routeBundle.map,
    playerPos: next.playerPosition,
    playerFacing: Direction.north,
    project: routeBundle.manifest,
    tileWidth: routeBundle.manifest.settings.tileWidth,
    tileHeight: routeBundle.manifest.settings.tileHeight,
  );
  final request = buildTrainerBattleRequestFromNpc(
    entity: grantNpc,
    manifest: routeBundle.manifest,
    world: world,
    createdAtEpochMs: 1,
  );

  expect(request, isNotNull);
  expect(request!.kind, RuntimeBattleKind.trainer);
  expect(request.trainerId, _trainerId);
  expect(request.mapId, _routeMapId);
  expect(request.playerPos, _grantPlayerBattlePos);

  final mapper = RuntimeBattleSetupMapper();
  final lineup = mapper.selectPlayerBattleLineup(next.party);
  final setup = await mapper.map(
    bundle: routeBundle,
    gameState: next,
    request: request,
    playerPartyIndex: lineup.activeIndex,
  );

  expect(setup.isTrainerBattle, isTrue);
  expect(setup.trainerId, _trainerId);
  expect(setup.allowCapture, isFalse);
  expect(setup.playerPokemon.speciesId, _initialSpeciesId);
  expect(setup.enemyPokemon.speciesId, 'bulbasaur');

  final session = createBattleSession(setup);
  expect(session.state.isFinished, isFalse);

  final outcome = _controlledTrainerVictoryOutcome(
    session.state,
    playerCurrentHp: 18,
  );
  expect(outcome.isVictory, isTrue);

  next = applyRuntimeBattleOutcomeToGameState(
    gameState: next,
    context: RuntimeActiveBattleContext(
      request: request,
      playerPartyIndex: lineup.activeIndex,
      playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
    ),
    outcome: outcome,
  );
  expect(next.storyFlags.activeFlags, contains(_trainerDefeatedFlag));

  next = mutations.applyBattleRewards(
    next,
    moneyReward: _rewardMoney,
    levelUpsByPartyIndex: const <int, int>{0: 1},
  );
  return next;
}

BattleOutcome _controlledTrainerVictoryOutcome(
  BattleState battleState, {
  required int playerCurrentHp,
}) {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _withCurrentHp(battleState.player, playerCurrentHp),
      playerReserve: battleState.playerReserve,
      enemy: _withCurrentHp(battleState.enemy, 0),
      enemyReserve: battleState.enemyReserve
          .map((combatant) => _withCurrentHp(combatant, 0))
          .toList(growable: false),
      field: battleState.field,
      currentTurn: null,
      outcome: null,
    ),
  );
}

BattleCombatant _withCurrentHp(BattleCombatant combatant, int currentHp) {
  final clamped = currentHp.clamp(0, combatant.maxHp).toInt();
  if (clamped == combatant.currentHp) {
    return combatant;
  }
  if (clamped < combatant.currentHp) {
    return combatant.withDamage(combatant.currentHp - clamped);
  }
  return combatant.withHeal(clamped - combatant.currentHp);
}

void _expectGoldenSliceState(GameState state) {
  expect(state.saveId, _saveId);
  expect(state.currentMapId, _routeMapId);
  expect(state.playerPosition, _grantPlayerBattlePos);
  expect(state.playerFacing, EntityFacing.north);
  expect(state.party.members, hasLength(2));

  final initialPokemon = state.party.members.first;
  expect(initialPokemon.speciesId, _initialSpeciesId);
  expect(initialPokemon.level, 9);
  expect(initialPokemon.currentHp, 18);
  expect(initialPokemon.knownMoveIds, _initialMoves);

  final capturedPokemon = state.party.members.last;
  expect(capturedPokemon.speciesId, _capturedSpeciesId);
  expect(capturedPokemon.level, 3);
  expect(capturedPokemon.currentHp, _capturedHpAfterTrainerWriteBack);
  expect(capturedPokemon.knownMoveIds, _initialMoves);

  expect(state.pokemonStorage.storedPokemon, isEmpty);
  expect(_bagQuantity(state, _captureItemId), 4);
  expect(_bagQuantity(state, _medicineItemId), 2);
  expect(state.trainerProfile.money, _rewardMoney);
  expect(state.storyFlags.activeFlags, contains(_p603FlagId));
  expect(state.progression.completedStepIds, contains(_p603StepId));
  expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
  expect(state.progression.caughtSpeciesIds, contains(_capturedSpeciesId));
  expect(state.progression.seenSpeciesIds, contains(_capturedSpeciesId));
  expect(
    state.metadata,
    equals(<String, String>{
      'lot': 'p6_06',
      'persistence': 'file_game_save_repository',
    }),
  );
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

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory(p.join(_testDirectory.path, 'pokemonProject'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return p.join(saveDir.path, 'game_save.json');
  }
}
```

### 15.4 Sections modifiées de `road_map_phase_6.md`

```text
Lot courant : ✅ P6-06 — Selbrume Save/Load Golden Slice V0
Prochain lot exact : P6-07 — Selbrume Beta Validator Pass V0

- ✅ P6-06 — Selbrume Save/Load Golden Slice V0
- ➡️ P6-07 — Selbrume Beta Validator Pass V0

P6-06 : ✅ terminé
P6-07 : ➡️ prochain lot exact

## Résultat P6-06

Preuve ciblée réalisée sur le projet repo-local :

selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées : Selbrume et route 1
état golden slice reconstruit depuis les preuves P6-02 à P6-05
party : pidgeotto niveau 9, pidgeotto capturé niveau 3
bag : poke-ball x4, potion x2
progression narrative : p6.selbrume.first_interaction.seen
completed step : p6.selbrume.first_interaction
trainer defeated flag : trainer_defeated:grant
money : 120
position finale : route 1, x=24, y=22, facing north
repository : SaveGameUseCase + LoadGameUseCase + FileGameSaveRepository
fichier disque temporaire hors repo : Directory.systemTemp sous p6_06_selbrume_save_load_*/pokemonProject/game_save.json
rechargement disque réel prouvé
normalizeLoadedGameState appliqué après LoadGameUseCase
assertions golden slice complètes après reload

Niveau de preuve save/load :

repository/use-case disque réel
pas seulement un roundtrip SaveData en mémoire
pas de UI save/load
pas de Boot Flow

Décision roadmap :

P6-06 est concluant.
Aucun code production et aucun fichier selbrume/ n'est modifié en P6-06.
Prochain lot exact : P6-07 — Selbrume Beta Validator Pass V0.

### ✅ P6-06 — Selbrume Save/Load Golden Slice V0
Statut : terminé.

### ➡️ P6-07 — Selbrume Beta Validator Pass V0
Statut : prochain lot exact.
```

### 15.5 Contrôles finaux

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git status --short --untracked-files=all -- selbrume packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart "MVP Selbrume/road_map_phase_6.md" reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md
```

Sortie :

```text
git diff --check:
Sortie : <vide>

git diff --stat:
 MVP Selbrume/road_map_phase_6.md | 67 ++++++++++++++++++++++++++++++++++------
 1 file changed, 58 insertions(+), 9 deletions(-)

git diff --name-only:
MVP Selbrume/road_map_phase_6.md

git status --short --untracked-files=all:
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
?? reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md

git status --short --untracked-files=all -- selbrume packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart "MVP Selbrume/road_map_phase_6.md" reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md reports/roadmap/phase_6/p6_05_bis_phase_6_roadmap_consistency_fix.md:
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
?? reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md
```

### 15.6 Confirmations de périmètre

```text
Aucun code production modifié.
Aucun fichier selbrume/ modifié.
Aucun test existant modifié.
P6-07 n'a pas été lancé.
```

## 16. Auto-review critique

Ai-je utilisé le chemin repo-local selbrume ?

```text
Oui. Le test utilise /Users/karim/Project/pokemonProject/selbrume via recherche
de selbrume/project.json depuis la racine repo.
```

Ai-je évité l'ancien chemin Desktop ?

```text
Oui. Le test ne contient pas /Users/karim/Desktop/selbrume.
```

Ai-je utilisé un vrai mécanisme disque ?

```text
Oui. SaveGameUseCase, LoadGameUseCase et FileGameSaveRepository sont utilisés.
```

Ai-je écrit la sauvegarde hors repo ?

```text
Oui. Le fichier est écrit sous Directory.systemTemp et le test vérifie qu'il
n'est pas dans le repo ni dans selbrume/.
```

Ai-je évité de modifier selbrume/ ?

```text
Oui.
```

Ai-je prouvé le rechargement réel ?

```text
Oui. LoadGameUseCase relit le fichier disque, puis normalizeLoadedGameState est
appliqué avant les assertions.
```

Ai-je vérifié tout l'état golden slice ?

```text
Oui : map, position, facing, party, storage, bag, money, flags, completed step,
trainer defeated, caught/seen et metadata.
```

Ai-je modifié du code production ?

```text
Non.
```

Ai-je lancé P6-07 ?

```text
Non.
```

Ai-je créé une UI save/load ?

```text
Non.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : P6-07 — Selbrume Beta Validator Pass V0.
```
