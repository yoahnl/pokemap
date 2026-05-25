# P6-05 — Selbrume First Trainer Battle Golden Slice V0

## 1. Résumé exécutif

P6-05 est concluant.

Le lot prouve un premier trainer battle Selbrume court en utilisant Grant, contenu utilisateur volontaire conserve dans le projet repo-local :

```text
/Users/karim/Project/pokemonProject/selbrume
```

Chaîne prouvée :

```text
Selbrume/spawn
-> party/bag P6-02
-> flag/step P6-03 conservés
-> capture P6-04 conservée
-> route 1
-> NPC Grant
-> TrainerBattleStartRequest
-> RuntimeBattleSetupMapper
-> createBattleSession(setup)
-> outcome victory contrôlé appliqué via applyRuntimeBattleOutcomeToGameState
-> trainer_defeated:grant
-> reward minimal test-level money +120 / party[0] level +1
-> SaveData roundtrip
```

Niveau de preuve battle obtenu :

```text
runtime-application trainer battle setup + controlled victory outcome write-back
pas de victoire battle engine complète
pas de Battle UI
pas de reward UI
```

P6-05 ne modifie aucun code production, ne modifie aucun fichier `selbrume/`, ne crée pas Lysa, ne crée pas de contenu final et ne lance pas P6-06.

Prochain lot exact :

```text
P6-06 — Selbrume Save/Load Golden Slice V0
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
```

Tests lus :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
```

Sources techniques :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/battle_start_request.dart
packages/map_runtime/lib/src/application/trainer_battle_request.dart
packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/encounter_to_battle_request.dart
packages/map_runtime/lib/src/application/story_flags_manager.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_battle/lib/src/battle_setup.dart
packages/map_battle/lib/src/battle_state.dart
packages/map_battle/lib/src/battle_resolution.dart
```

Skills consultés :

```text
superpowers:test-driven-development
superpowers:systematic-debugging
superpowers:verification-before-completion
dart-add-unit-test
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
rg -n "grant|trainerId|characterId|tilesetId|battleDifficulty|team|bulbasaur|tackle|growl|p6_03_first_interaction|p6_03_intro_sign" selbrume/project.json "selbrume/maps/route 1.json" "selbrume/maps/Selbrume.json"
test -f "selbrume/assets/tilesets/grant.png" && echo "grant.png exists" || echo "grant.png missing"
```

Sorties utiles :

```text
/Users/karim/Project/pokemonProject
main

git status --short --untracked-files=all:
Sortie : <vide>

git diff --stat:
Sortie : <vide>

git diff --name-only:
Sortie : <vide>

git log --oneline -n 10:
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
8f40c1f6 update gitignore
02fbb1db add grant
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
25d623ca Ajoute selbrume/assets/pokemon/sprites/ à .gitignore

REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists

git status --short --untracked-files=all -- selbrume:
Sortie : <vide>

grant.png exists
```

Extraits Grant / P6-03 observés au Gate 0 :

```text
selbrume/maps/route 1.json:13355:      "id": "grant",
selbrume/maps/route 1.json:13371:        "trainerId": "grant",
selbrume/project.json:523:      "id": "grant",
selbrume/project.json:525:      "relativePath": "assets/tilesets/grant.png",
selbrume/project.json:12794:      "id": "p6_03_first_interaction",
selbrume/project.json:12845:            "entityId": "p6_03_intro_sign",
selbrume/project.json:13046:      "id": "grant",
selbrume/project.json:13049:      "battleDifficulty": 10,
selbrume/project.json:13051:      "characterId": "grant",
selbrume/project.json:13055:      "team": [
selbrume/project.json:13057:          "speciesId": "bulbasaur",
selbrume/project.json:13060:            "growl",
selbrume/project.json:13061:            "tackle"
selbrume/project.json:14055:      "id": "grant",
selbrume/project.json:14057:      "tilesetId": "grant",
selbrume/maps/Selbrume.json:67539:      "id": "p6_03_intro_sign",
```

## 4. Audit Grant existant

Commande :

```bash
python3 - <<'PY'
import json
from pathlib import Path
project=json.loads(Path('selbrume/project.json').read_text())
trainer=next(t for t in project['trainers'] if t.get('id')=='grant')
print('trainer_id =', trainer.get('id'))
print('trainer_name =', trainer.get('name'))
print('trainer_class =', trainer.get('trainerClass'))
print('battleDifficulty =', trainer.get('battleDifficulty'))
print('characterId =', trainer.get('characterId'))
for i, member in enumerate(trainer.get('team', [])):
    print(f'team[{i}] species={member.get("speciesId")} level={member.get("level")} moves={member.get("moves")}')
route=json.loads(Path('selbrume/maps/route 1.json').read_text())
for entity in route.get('entities', []):
    if entity.get('id')=='grant':
        npc=entity.get('npc') or {}
        print('route_grant_entity =', entity.get('id'), entity.get('kind'), entity.get('pos'), 'trainerId='+str(npc.get('trainerId')), 'displayName='+str(npc.get('displayName')))
characters=[c for c in project.get('characters',[]) if c.get('id')=='grant']
tilesets=[t for t in project.get('tilesets',[]) if t.get('id')=='grant']
print('character_grant_count =', len(characters))
if characters:
    print('character_grant_tilesetId =', characters[0].get('tilesetId'))
print('tileset_grant_count =', len(tilesets))
if tilesets:
    print('tileset_grant_relativePath =', tilesets[0].get('relativePath'))
PY
file selbrume/assets/tilesets/grant.png
ls -lh selbrume/assets/tilesets/grant.png
```

Sortie :

```text
trainer_id = grant
trainer_name = grant
trainer_class = grant
battleDifficulty = 10
characterId = grant
team[0] species=bulbasaur level=1 moves=['growl', 'tackle']
team[1] species=metapod level=25 moves=['harden']
team[2] species=ivysaur level=25 moves=['sweet_scent', 'growl', 'growth', 'leech_seed']
route_grant_entity = grant npc {'x': 24, 'y': 20} trainerId=grant displayName=grant
character_grant_count = 1
character_grant_tilesetId = grant
tileset_grant_count = 1
tileset_grant_relativePath = assets/tilesets/grant.png
selbrume/assets/tilesets/grant.png: PNG image data, 256 x 256, 8-bit colormap, non-interlaced
-rw-r--r--@ 1 karim  staff   3.0K Apr  3 18:52 selbrume/assets/tilesets/grant.png
```

Conclusion :

```text
Grant est exploitable comme premier trainer battle golden slice.
Grant est conservé sans modification.
```

## 5. Vérification données Pokémon / moves

Commande :

```bash
python3 - <<'PY'
import json
from pathlib import Path
project=json.loads(Path('selbrume/project.json').read_text())
trainer=next(t for t in project['trainers'] if t.get('id')=='grant')
moves=json.loads(Path('selbrume/data/pokemon/catalogs/moves.json').read_text())
move_ids={e.get('id') for e in moves.get('entries',[])}
for member in trainer.get('team',[]):
    sid=member.get('speciesId')
    species_paths=[]
    for path in Path('selbrume/data/pokemon/species').glob('*.json'):
        data=json.loads(path.read_text())
        if data.get('id') == sid:
            species_paths.append(str(path))
    print(f'species {sid} exists = {bool(species_paths)} paths = {species_paths}')
    for move in member.get('moves',[]):
        print(f'move {move} exists = {move in move_ids}')
PY
```

Sortie :

```text
species bulbasaur exists = True paths = ['selbrume/data/pokemon/species/0001-bulbasaur.json']
move growl exists = True
move tackle exists = True
species metapod exists = True paths = ['selbrume/data/pokemon/species/0011-metapod.json']
move harden exists = True
species ivysaur exists = True paths = ['selbrume/data/pokemon/species/0002-ivysaur.json']
move sweet_scent exists = True
move growl exists = True
move growth exists = True
move leech_seed exists = True
```

## 6. Niveau de preuve trainer battle obtenu

Le test P6-05 prouve :

```text
loadRuntimeMapBundle Selbrume OK
loadRuntimeMapBundle route 1 OK
NPC Grant présent sur route 1
trainer Grant présent dans ProjectManifest
buildTrainerBattleRequestFromNpc retourne TrainerBattleStartRequest
RuntimeBattleSetupMapper construit BattleSetup trainer
createBattleSession(setup) démarre une session battle non terminée
setup player active = pidgeotto P6-02
setup player reserve = pidgeotto capturé P6-04
setup enemy active = bulbasaur
setup enemy reserve = metapod, ivysaur
```

Limite explicite :

```text
Le test ne joue pas une victoire complète via le moteur battle.
La victoire est un outcome contrôlé, construit à partir de la session battle initialisée.
Le niveau de preuve est runtime-application + write-back, pas Battle UI et pas runtime smoke complet.
```

## 7. Outcome / trainer defeated / reward

Outcome contrôlé :

```text
BattleOutcomeType.victory
player currentHp final : 18
enemy active HP final : 0
enemy reserve HP final : 0
```

Write-back :

```text
applyRuntimeBattleOutcomeToGameState
RuntimeActiveBattleContext.request = TrainerBattleStartRequest grant
playerPartyIndex = 0
playerPartySlotIndicesByLineupIndex = [0, 1]
trainer_defeated:grant posé
party[0].currentHp = 18
party[1] conservé
```

Reward minimal :

```text
GameStateMutations.applyBattleRewards
moneyReward = 120
levelUpsByPartyIndex = {0: 1}
money : 0 -> 120
party[0] level : 8 -> 9
```

Note :

```text
Le reward n'est pas authoré dans Grant, car ProjectTrainerEntry ne porte pas de champ reward.
P6-05 prouve donc un reward minimal test-level avec l'API existante, pas un reward produit final authoré.
```

## 8. Preuve GameState / progression

État vérifié dans le test :

```text
currentMapId = route 1
playerPosition = x=24, y=22
playerFacing = north
party size = 2
party[0] = pidgeotto P6-02, level 9 après reward, HP 18
party[1] = pidgeotto capturé P6-04, level 3
bag poke-ball = 4
bag potion = 2
story flag P6-03 conservé : p6.selbrume.first_interaction.seen
completed step P6-03 conservée : p6.selbrume.first_interaction
trainer defeated flag : trainer_defeated:grant
caught/seen pidgeotto conservés
money = 120
```

## 9. Preuve SaveData / persistance

Roundtrip exécuté :

```text
saveDataFromGameState(state)
gameStateFromSaveData(saveData)
normalizeLoadedGameState(...)
```

Assertions post-roundtrip :

```text
saveId = p6_05_selbrume_first_trainer_battle
currentMapId = route 1
position = x=24, y=22
facing = north
party size = 2
party[0].speciesId = pidgeotto
party[0].level = 9
party[0].currentHp = 18
party[1].speciesId = pidgeotto
party[1].level = 3
money = 120
poke-ball = 4
potion = 2
trainer_defeated:grant conservé
p6.selbrume.first_interaction.seen conservé
p6.selbrume.first_interaction conservé
caughtSpeciesIds contient pidgeotto
seenSpeciesIds contient pidgeotto
```

## 10. Tests exécutés

Test ciblé :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
00:00 +0: P6-05 builds Grant trainer battle setup and persists a controlled victory outcome
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=Selbrume
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
[runtime_loader] bundle map resolved mapId=Selbrume relativePath=maps/Selbrume.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/Selbrume.json
[runtime_loader] map file read ok bytes=1267082
[runtime_loader] map validated id=Selbrume size=55x55 layers=16 entities=2 placedElements=1180 warps=3 triggers=0
[runtime_loader] bundle load ok mapId=Selbrume projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=10
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/selbrume/project.json mapId=route 1
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/selbrume/project.json
[runtime_loader] project manifest read ok bytes=651662
[runtime_loader] project manifest validated maps=10 tilesets=31 scenarios=3
[runtime_loader] bundle map resolved mapId=route 1 relativePath=maps/route 1.json mapPath=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/selbrume/maps/route 1.json
[runtime_loader] map file read ok bytes=223274
[runtime_loader] map validated id=route 1 size=45x45 layers=6 entities=1 placedElements=68 warps=0 triggers=0
[runtime_loader] bundle load ok mapId=route 1 projectRoot=/Users/karim/Project/pokemonProject/selbrume tilesets=7
00:01 +1: All tests passed!
```

Régressions :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

Sorties finales des régressions :

```text
P6-01:
00:00 +1: All tests passed!

P6-02:
00:00 +1: All tests passed!

P6-03:
00:00 +1: All tests passed!

P6-04:
00:00 +1: All tests passed!
```

## 11. Analyse exécutée

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_first_trainer_battle_golden_slice_test.dart...

No issues found! (ran in 2.1s)
```

## 12. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
reports/roadmap/phase_6/p6_05_selbrume_first_trainer_battle_golden_slice.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_6.md
```

Fichiers Selbrume modifiés :

```text
Sortie : <vide>
```

Diff ciblé Selbrume :

```bash
git diff -- selbrume/project.json
git diff -- "selbrume/maps/route 1.json"
git status --short --untracked-files=all -- selbrume
```

Sorties :

```text
git diff -- selbrume/project.json:
Sortie : <vide>

git diff -- "selbrume/maps/route 1.json":
Sortie : <vide>

git status --short --untracked-files=all -- selbrume:
Sortie : <vide>
```

## 13. Roadmap Phase 6 mise à jour

Sections modifiées :

```text
Lot courant : ✅ P6-05 — Selbrume First Trainer Battle Golden Slice V0
Prochain lot exact : P6-06 — Selbrume Save/Load Golden Slice V0

Suivi des lots :
- ✅ P6-05 — Selbrume First Trainer Battle Golden Slice V0
- ➡️ P6-06 — Selbrume Save/Load Golden Slice V0

P6-05 : ✅ terminé
P6-06 : ➡️ prochain lot exact

Résultat P6-05 ajouté avec :
- trainer retenu : grant
- niveau de preuve battle : runtime-application setup + controlled victory outcome
- trainer defeated flag : trainer_defeated:grant
- reward minimal : money +120, level-up direct party[0] +1
- roundtrip SaveData prouvé
```

## 14. Prochain lot exact

```text
P6-06 — Selbrume Save/Load Golden Slice V0
```

Justification :

```text
P6-05 a prouvé le premier trainer battle Grant au niveau runtime-application et SaveData roundtrip local.
Le golden slice dispose maintenant des briques route 1, capture, trainer defeated, reward minimal et persistence locale.
Le prochain risque Phase 6 logique est de consolider le save/load golden slice complet.
```

## 15. Ce qui n’a pas été fait

```text
Aucun code production modifié.
Aucun fichier selbrume/ modifié.
Aucun trainer supprimé.
Grant n'a pas été supprimé.
Lysa n'a pas été créée.
Aucun rival final créé.
Aucune cinématique créée.
Aucune Battle UI créée.
Aucune reward UI créée.
Aucun système XP persistée complète créé.
Aucun move learning créé.
Aucune évolution créée.
Aucun Boot Flow créé.
Aucun audio créé.
Aucun validator pass complet lancé.
Aucun runtime smoke complet lancé.
P6-06 n'a pas été lancé.
```

## 16. Evidence Pack

### 16.1 pwd / branche / statut initial

```text
pwd:
/Users/karim/Project/pokemonProject

branche courante:
main

git status initial:
Sortie : <vide>

git diff --stat initial:
Sortie : <vide>

git diff --name-only initial:
Sortie : <vide>

git log --oneline -n 10:
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
8f40c1f6 update gitignore
02fbb1db add grant
91cb80f9 Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
25d623ca Ajoute selbrume/assets/pokemon/sprites/ à .gitignore
```

### 16.2 Existence projet repo-local

```text
REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists
```

### 16.3 État Git selbrume/

```text
git status --short --untracked-files=all -- selbrume:
Sortie : <vide>
```

### 16.4 Preuve absence ancien chemin Desktop dans le test

Commande :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart || true
```

Sortie :

```text
Sortie : <vide>
```

### 16.5 Contenu du test créé

Le test créé est :

```text
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
```

Son contenu vérifie :

```text
repo-local selbrume/project.json
loadRuntimeMapBundle Selbrume
loadRuntimeMapBundle route 1
trainer Grant
NPC Grant route 1
grant.png
species/moves Grant
party/bag P6-02
flag/step P6-03
capture P6-04 conservée
TrainerBattleStartRequest
RuntimeBattleSetupMapper
createBattleSession
outcome victory contrôlé
applyRuntimeBattleOutcomeToGameState
trainer_defeated:grant
applyBattleRewards money +120 / level +1
SaveData roundtrip
```

Contenu complet du test créé :

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
const _saveId = 'p6_05_selbrume_first_trainer_battle';
const _trainerId = 'grant';
const _trainerDefeatedFlag = 'trainer_defeated:grant';
const _grantNpcId = 'grant';
const _grantCharacterId = 'grant';
const _grantTilesetId = 'grant';
const _grantAssetRelativePath = 'assets/tilesets/grant.png';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-05 builds Grant trainer battle setup and persists a controlled victory outcome',
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

      final grantTrainer = routeBundle.manifest.trainers.singleWhere(
        (trainer) => trainer.id == _trainerId,
      );
      expect(grantTrainer.name, 'grant');
      expect(grantTrainer.trainerClass, 'grant');
      expect(grantTrainer.battleDifficulty, 10);
      expect(grantTrainer.characterId, _grantCharacterId);
      expect(grantTrainer.team.map((member) => member.speciesId), <String>[
        'bulbasaur',
        'metapod',
        'ivysaur',
      ]);
      expect(grantTrainer.team.map((member) => member.level), <int>[
        1,
        25,
        25,
      ]);

      final grantCharacter = routeBundle.manifest.characters.singleWhere(
        (character) => character.id == _grantCharacterId,
      );
      expect(grantCharacter.tilesetId, _grantTilesetId);

      final grantTileset = routeBundle.manifest.tilesets.singleWhere(
        (tileset) => tileset.id == _grantTilesetId,
      );
      expect(grantTileset.relativePath, _grantAssetRelativePath);
      expect(
        await File(p.join(projectRoot.path, _grantAssetRelativePath)).exists(),
        isTrue,
      );

      final grantNpc = routeBundle.map.entities.singleWhere(
        (entity) => entity.id == _grantNpcId,
      );
      expect(grantNpc.kind, MapEntityKind.npc);
      expect(grantNpc.pos, const GridPos(x: 24, y: 20));
      expect(grantNpc.npc?.trainerId, _trainerId);
      expect(grantNpc.npc?.displayName, 'grant');

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: routeBundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      for (final member in grantTrainer.team) {
        final speciesJson = await _readSpeciesJsonById(
          projectRoot: projectRoot,
          speciesDir: routeBundle.manifest.pokemon.speciesDir,
          speciesId: member.speciesId,
        );
        expect(speciesJson['id'], member.speciesId);
        expect(member.moves, isNotEmpty);
        expect(moveIds, containsAll(member.moves));
      }

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
      state = _applyP604CaptureState(state);
      state = mutations.warpPlayer(
        state,
        _routeMapId,
        _grantPlayerBattlePos.x,
        _grantPlayerBattlePos.y,
        facing: EntityFacing.north,
      );

      expect(state.currentMapId, _routeMapId);
      expect(state.playerPosition, _grantPlayerBattlePos);
      expect(state.playerFacing, EntityFacing.north);
      expect(state.party.members, hasLength(2));
      expect(state.party.members.first.speciesId, _initialSpeciesId);
      expect(state.party.members.last.speciesId, _capturedSpeciesId);
      expect(_bagQuantity(state, _captureItemId), 4);
      expect(_bagQuantity(state, _medicineItemId), 2);
      expect(state.storyFlags.activeFlags, contains(_p603FlagId));
      expect(state.progression.completedStepIds, contains(_p603StepId));

      final world = GameplayWorldState.initial(
        map: routeBundle.map,
        playerPos: state.playerPosition,
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
      expect(request.source, RuntimeBattleSourceKind.trainerInteraction);
      expect(request.requestId, 'trainer:route 1:grant:grant:1');
      expect(request.trainerId, _trainerId);
      expect(request.npcEntityId, _grantNpcId);
      expect(request.mapId, _routeMapId);
      expect(request.playerPos, _grantPlayerBattlePos);
      expect(request.returnContext.mapId, _routeMapId);
      expect(request.returnContext.playerPos, _grantPlayerBattlePos);
      expect(request.returnContext.playerFacing, Direction.north);

      final mapper = RuntimeBattleSetupMapper();
      final lineup = mapper.selectPlayerBattleLineup(state.party);
      expect(lineup.activeIndex, 0);
      expect(lineup.reserveIndices, <int>[1]);
      expect(lineup.lineupPartyIndices, <int>[0, 1]);

      final setup = await mapper.map(
        bundle: routeBundle,
        gameState: state,
        request: request,
        playerPartyIndex: lineup.activeIndex,
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.trainerId, _trainerId);
      expect(setup.allowCapture, isFalse);
      expect(setup.playerPokemon.speciesId, _initialSpeciesId);
      expect(setup.playerReservePokemon.map((pokemon) => pokemon.speciesId),
          <String>[_capturedSpeciesId]);
      expect(setup.enemyPokemon.speciesId, 'bulbasaur');
      expect(setup.enemyPokemon.level, 1);
      expect(setup.enemyPokemon.moves.map((move) => move.id), <String>[
        'growl',
        'tackle',
      ]);
      expect(setup.enemyReservePokemon.map((pokemon) => pokemon.speciesId),
          <String>['metapod', 'ivysaur']);

      final session = createBattleSession(setup);
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, _initialSpeciesId);
      expect(session.state.playerReserve.map((pokemon) => pokemon.speciesId),
          <String>[_capturedSpeciesId]);
      expect(session.state.enemy.speciesId, 'bulbasaur');
      expect(session.state.enemyReserve.map((pokemon) => pokemon.speciesId),
          <String>['metapod', 'ivysaur']);

      final outcome = _controlledTrainerVictoryOutcome(
        session.state,
        playerCurrentHp: 18,
      );
      expect(outcome.isVictory, isTrue);

      state = applyRuntimeBattleOutcomeToGameState(
        gameState: state,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: lineup.activeIndex,
          playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
        ),
        outcome: outcome,
      );

      expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
      expect(state.party.members.first.currentHp, 18);
      expect(state.party.members.first.level, 8);
      expect(state.party.members.last.speciesId, _capturedSpeciesId);
      expect(state.trainerProfile.money, 0);
      expect(_bagQuantity(state, _captureItemId), 4);

      state = mutations.applyBattleRewards(
        state,
        moneyReward: _rewardMoney,
        levelUpsByPartyIndex: const <int, int>{0: 1},
      );

      expect(state.trainerProfile.money, _rewardMoney);
      expect(state.party.members.first.level, 9);
      expect(state.party.members.first.currentHp, 18);
      expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
      expect(state.storyFlags.activeFlags, contains(_p603FlagId));
      expect(state.progression.completedStepIds, contains(_p603StepId));

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _routeMapId);
      expect(reloaded.playerPosition, _grantPlayerBattlePos);
      expect(reloaded.playerFacing, EntityFacing.north);
      expect(reloaded.party.members, hasLength(2));
      expect(reloaded.party.members.first.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.first.level, 9);
      expect(reloaded.party.members.first.currentHp, 18);
      expect(reloaded.party.members.last.speciesId, _capturedSpeciesId);
      expect(reloaded.party.members.last.level, 3);
      expect(reloaded.trainerProfile.money, _rewardMoney);
      expect(_bagQuantity(reloaded, _captureItemId), 4);
      expect(_bagQuantity(reloaded, _medicineItemId), 2);
      expect(reloaded.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
      expect(reloaded.storyFlags.activeFlags, contains(_p603FlagId));
      expect(reloaded.progression.completedStepIds, contains(_p603StepId));
      expect(
        reloaded.progression.caughtSpeciesIds,
        contains(_capturedSpeciesId),
      );
      expect(
        reloaded.progression.seenSpeciesIds,
        contains(_capturedSpeciesId),
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
  return captureResult.state;
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
```

### 16.6 Git diff / status avant rapport

```text
git diff --stat:
MVP Selbrume/road_map_phase_6.md | 55 +++++++++++++++++++++++++++++++++++-----
1 file changed, 49 insertions(+), 6 deletions(-)

git diff --name-only:
MVP Selbrume/road_map_phase_6.md

git status --short --untracked-files=all:
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
```

### 16.7 Tests / analyse

```text
flutter test test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
Résultat : 00:01 +1: All tests passed!

flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
Résultat : 00:00 +1: All tests passed!

flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
Résultat : 00:00 +1: All tests passed!

flutter test test/p6_selbrume_first_narrative_interaction_test.dart
Résultat : 00:00 +1: All tests passed!

flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
Résultat : 00:00 +1: All tests passed!

flutter analyze --no-fatal-infos test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
Résultat : No issues found! (ran in 2.1s)
```

### 16.8 Contrôles explicites

```text
Aucun code production modifié : confirmé par git diff --name-only final.
Aucun fichier packages/*/lib modifié : confirmé par git diff --name-only final.
Aucun fichier selbrume/ modifié : git status --short --untracked-files=all -- selbrume vide.
Grant conservé : trainer, NPC, character, tileset et grant.png vérifiés.
Aucun contenu final Selbrume créé.
Aucun Battle UI / reward UI créé.
P6-06 non lancé.
```

### 16.9 Vérifications finales

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git status --short --untracked-files=all -- selbrume
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart || true
```

Sorties :

```text
git diff --check:
Sortie : <vide>

git diff --stat:
 MVP Selbrume/road_map_phase_6.md | 55 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 49 insertions(+), 6 deletions(-)

git diff --name-only:
MVP Selbrume/road_map_phase_6.md

git status --short --untracked-files=all:
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
?? reports/roadmap/phase_6/p6_05_selbrume_first_trainer_battle_golden_slice.md

git status --short --untracked-files=all -- selbrume:
Sortie : <vide>

rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart || true:
Sortie : <vide>
```

## 17. Auto-review critique

Ai-je utilisé le chemin repo-local selbrume ?

```text
Oui. Le test résout selbrume/project.json depuis la racine repo.
```

Ai-je évité l'ancien chemin Desktop ?

```text
Oui. `rg -n "/Users/karim/Desktop/selbrume" ...` ne retourne rien.
```

Ai-je conservé Grant ?

```text
Oui. Aucun fichier selbrume/ n'a été modifié et Grant est vérifié.
```

Ai-je vérifié species/moves Grant ?

```text
Oui. bulbasaur, metapod, ivysaur et tous leurs moves déclarés existent.
```

Ai-je prouvé un battle engine réel ou seulement runtime outcome ?

```text
J'ai prouvé le setup battle réel et createBattleSession.
Je n'ai pas prouvé une victoire battle engine complète.
L'outcome victory est contrôlé et appliqué via le runtime write-back existant.
```

Ai-je appliqué trainer defeated / outcome ?

```text
Oui. applyRuntimeBattleOutcomeToGameState pose trainer_defeated:grant.
```

Ai-je appliqué un reward minimal sans inventer un système ?

```text
Oui. GameStateMutations.applyBattleRewards applique money +120 et level +1.
Le rapport précise que ce reward est test-level et non authoré dans Grant.
```

Ai-je prouvé SaveData roundtrip ?

```text
Oui. Le test vérifie saveDataFromGameState -> gameStateFromSaveData -> normalizeLoadedGameState.
```

Ai-je créé Lysa ou un contenu final ?

```text
Non.
```

Ai-je modifié du code production ?

```text
Non.
```

Ai-je lancé P6-06 ?

```text
Non.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : P6-06 — Selbrume Save/Load Golden Slice V0.
```
