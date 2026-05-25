# P6-07 — Selbrume Beta Validator Pass V0

## 1. Résumé exécutif

P6-07 est concluant.

Le projet Selbrume repo-local passe le validator bêta V0 avec un contexte explicite de golden slice :

```text
/Users/karim/Project/pokemonProject/selbrume
```

Niveau de preuve obtenu :

```text
validator pass strict
errors : 0
warnings : 0
infos : 0
diagnostics bloquants : aucun
```

Chaîne prouvée :

```text
repo-local selbrume/project.json
-> loadRuntimeMapBundle Selbrume
-> loadRuntimeMapBundle route 1
-> parsing des 10 maps déclarées
-> collecte des espèces Pokémon projet
-> collecte du catalogue moves
-> collecte du catalogue items
-> BetaPlayabilityValidationContext explicite
-> validateBetaPlayability(...)
-> aucun diagnostic
```

Aucun code production n'a été modifié. Aucun fichier `selbrume/` n'a été modifié. P6-08 n'a pas été lancé.

Prochain lot exact :

```text
P6-08 — Selbrume Playable Runtime Smoke V0
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
reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md
```

Tests lus :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
packages/map_core/test/beta_playability_validator_test.dart
```

Sources validator et projet :

```text
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
```

Skills consultés :

```text
superpowers:test-driven-development
superpowers:verification-before-completion
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

git status --short --untracked-files=all:
Sortie : <vide>

git diff --stat:
Sortie : <vide>

git diff --name-only:
Sortie : <vide>

git log --oneline -n 10:
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle Golden Slice (test et rapport)
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
cbfec67e Ajoute P6-03 : Selbrume First Narrative Interaction (test, rapport et mises à jour)
4da7eafe update sprites
54161228 update gitignore
8f40c1f6 update gitignore

REPO_SELBRUME_PROJECT_PATH exists
repo-local selbrume/project.json exists

git status --short --untracked-files=all -- selbrume:
Sortie : <vide>
```

Conclusion Gate 0 :

```text
selbrume/ est propre.
Le dossier repo-local et selbrume/project.json existent.
P6-07 ne modifie pas selbrume/.
```

## 4. API validator utilisée

API utilisée :

```text
validateBetaPlayability(ProjectManifest manifest, {BetaPlayabilityValidationContext context})
```

Types utilisés :

```text
BetaPlayabilityValidationContext
BetaPlayabilityValidationResult
BetaPlayabilityDiagnostic
BetaPlayabilityDiagnosticKind
BetaPlayabilityDiagnosticSeverity
```

Champs de contexte utilisés :

```text
mapsById
startMapId
knownSpeciesIds
knownMoveIds
initialPartySpeciesIds
initialPartyMoveIds
requiresInitialParty
requiresTrainerBattle
requiresCapture
hasCaptureItemSource
requiresSaveLoad
hasSaveLoadSupport
```

Le validator existant est utilisé sans modification.

## 5. Contexte validator construit

Contexte construit par le test :

```text
projectFilePath = /Users/karim/Project/pokemonProject/selbrume/project.json
loadRuntimeMapBundle(mapId: Selbrume)
loadRuntimeMapBundle(mapId: route 1)
mapsById = 10 maps déclarées dans project.json
startMapId = Selbrume
knownSpeciesIds = IDs collectés depuis selbrume/data/pokemon/species
knownMoveIds = IDs collectés depuis selbrume/data/pokemon/catalogs/moves.json
initialPartySpeciesIds = [pidgeotto]
initialPartyMoveIds = [gust, tackle]
requiresInitialParty = true
requiresTrainerBattle = true
requiresCapture = true
hasCaptureItemSource = true car poke-ball existe
requiresSaveLoad = true
hasSaveLoadSupport = true car P6-06 a prouvé SaveGameUseCase + LoadGameUseCase + FileGameSaveRepository
```

Résumé structuré des données collectées :

```text
manifest_map_count = 10
manifest_map_ids = ['route 1', 'Selbrume', 'house 1', 'house 2', 'house 3', 'house 4', 'house 5', 'pokémon center', 'pub', 'lab']
species_count = 986
required_species_present = {'pidgeotto': True, 'bulbasaur': True, 'metapod': True, 'ivysaur': True}
move_count = 954
required_moves_present = {'gust': True, 'tackle': True, 'growl': True, 'harden': True, 'sweet_scent': True, 'growth': True, 'leech_seed': True}
item_count = 2176
required_items_present = {'poke-ball': True, 'potion': True}
start_spawn = [('spawn', 'spawn', {'x': 17, 'y': 24}, 'player_start', 'south')]
route_grant = [('grant', 'npc', {'x': 24, 'y': 20}, 'grant')]
encounter_table = {'id': 'grass_path_route_1', 'name': 'grass path route 1', 'encounterKind': 'walk', 'entries': [{'speciesId': 'pidgeotto', 'minLevel': 1, 'maxLevel': 5, 'weight': 1}], 'tags': []}
route_encounter_zones = [('zone', 'encounter', 'grass_path_route_1', 'walk'), ('zone_1', 'encounter', 'grass_path_route_1', 'walk'), ('zone_2', 'encounter', 'grass_path_route_1', 'walk'), ('zone_3', 'encounter', 'grass_path_route_1', 'walk'), ('zone_4', 'encounter', 'grass_path_route_1', 'walk')]
grant_team = [('bulbasaur', 1, ['growl', 'tackle']), ('metapod', 25, ['harden']), ('ivysaur', 25, ['sweet_scent', 'growl', 'growth', 'leech_seed'])]
```

Limite honnête :

```text
Le validator V0 ne représente pas directement la bag complète, les story flags P6-03, l'encounter table ou le save disque.
P6-07 les transforme en prérequis explicites du contexte validator quand l'API les supporte.
Les preuves détaillées de bag, capture, trainer battle et save disque restent celles de P6-02 à P6-06.
```

## 6. Diagnostics obtenus

Résultat du validator :

```text
result.hasErrors = false
result.isPlayable = true
result.diagnostics = []
```

Diagnostics par sévérité :

```text
error : []
warning : []
info : []
```

Diagnostics critiques absents :

```text
missingMap
missingStartMap
missingPlayerSpawn
invalidDefaultSpawn
missingTrainerReference
trainerHasEmptyTeam
trainerPokemonMissingSpecies
trainerPokemonMissingMoves
missingPokemonSpecies
missingPokemonMove
missingStarterOrInitialPartySource
missingCapturePrerequisite
missingSaveLoadPrerequisite
```

## 7. Diagnostics bloquants / non bloquants

Diagnostics bloquants :

```text
aucun
```

Warnings :

```text
aucun
```

Infos :

```text
aucun
```

Décision :

```text
Le validator bêta V0 ne signale aucun blocker pour le golden slice Selbrume.
```

## 8. Décision de pass / fail

Décision :

```text
validator pass strict
```

Justification :

```text
Le test ciblé appelle validateBetaPlayability sur le ProjectManifest Selbrume chargé depuis le projet repo-local.
Le contexte fournit startMapId=Selbrume, les 10 maps, les espèces/moves/items utiles, la party initiale, la capture source, le trainer Grant et le support save/load prouvé en P6-06.
Le résultat ne contient aucun diagnostic.
```

Prochain lot exact :

```text
P6-08 — Selbrume Playable Runtime Smoke V0
```

## 9. Tests exécutés

Test ciblé P6-07 :

```bash
cd packages/map_runtime && flutter test test/p6_selbrume_beta_validator_pass_test.dart
```

Résultat :

```text
00:00 +0: P6-07 validates repo-local Selbrume golden slice with no beta blocker
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

Régressions lancées :

```bash
cd packages/map_runtime && flutter test test/p6_existing_selbrume_loadability_start_map_contract_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_initial_party_bag_setup_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_narrative_interaction_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_first_trainer_battle_golden_slice_test.dart
cd packages/map_runtime && flutter test test/p6_selbrume_save_load_golden_slice_test.dart
```

Résultats des régressions :

```text
P6-01 : 00:00 +1: All tests passed!
P6-02 : 00:00 +1: All tests passed!
P6-03 : 00:00 +1: All tests passed!
P6-04 : 00:00 +1: All tests passed!
P6-05 : 00:02 +1: All tests passed!
P6-06 : 00:01 +1: All tests passed!
```

## 10. Analyse exécutée

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p6_selbrume_beta_validator_pass_test.dart
```

Sortie :

```text
Analyzing p6_selbrume_beta_validator_pass_test.dart...
No issues found! (ran in 2.0s)
```

## 11. Modifications effectuées

Fichier créé :

```text
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart
reports/roadmap/phase_6/p6_07_selbrume_beta_validator_pass.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_6.md
```

Fichiers non modifiés :

```text
selbrume/**
packages/map_core/lib/**
packages/map_gameplay/lib/**
packages/map_runtime/lib/**
packages/map_battle/lib/**
packages/map_editor/lib/**
examples/**
```

## 12. Roadmap Phase 6 mise à jour

Sections modifiées de `MVP Selbrume/road_map_phase_6.md` :

```text
Lot courant : ✅ P6-07 — Selbrume Beta Validator Pass V0

Prochain lot exact : P6-08 — Selbrume Playable Runtime Smoke V0

- ✅ P6-07 — Selbrume Beta Validator Pass V0
- ➡️ P6-08 — Selbrume Playable Runtime Smoke V0

P6-07 : ✅ terminé

P6-08 : ➡️ prochain lot exact

Prochain lot exact :

P6-08 — Selbrume Playable Runtime Smoke V0
```

Section résultat ajoutée :

```text
## Résultat P6-07

validator pass strict : aucun diagnostic bloquant et aucune warning/info
pas de modification du validator
pas de modification selbrume/
pas de runtime smoke complet
Prochain lot exact : P6-08 — Selbrume Playable Runtime Smoke V0.
```

Section Roadmap mise à jour :

```text
### ✅ P6-07 — Selbrume Beta Validator Pass V0

Statut : terminé.

Preuve :

packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart

### ➡️ P6-08 — Selbrume Playable Runtime Smoke V0

Statut : prochain lot exact.
```

## 13. Prochain lot exact

```text
P6-08 — Selbrume Playable Runtime Smoke V0
```

P6-08 n'a pas été lancé.

## 14. Ce qui n’a pas été fait

Non-objectifs respectés :

```text
pas de modification validator
pas d'auto-fix
pas de modification selbrume/
pas de nouveau trainer
pas de nouveau dialogue
pas de nouvelle map
pas de UI validator
pas de PlayableMapGame smoke complet
pas de runtime smoke P6-08
pas de save/load supplémentaire
pas de Boot Flow
pas d'audio
pas de P6-08
```

## 15. Evidence Pack

### 15.1 Preuve que le test n'utilise pas l'ancien chemin Desktop

Commande :

```bash
rg -n "/Users/karim/Desktop/selbrume" packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart
```

Sortie :

```text
Sortie : <vide>
```

### 15.2 Contenu complet du test créé

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _spawnId = 'spawn';
const _initialSpeciesId = 'pidgeotto';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';
const _encounterTableId = 'grass_path_route_1';
const _trainerId = 'grant';
const _grantNpcId = 'grant';
const _grantSpeciesIds = <String>['bulbasaur', 'metapod', 'ivysaur'];
const _grantMoveIds = <String>[
  'growl',
  'tackle',
  'harden',
  'sweet_scent',
  'growth',
  'leech_seed',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-07 validates repo-local Selbrume golden slice with no beta blocker',
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
      expect(
        selbrumeBundle.manifest.maps.map((entry) => entry.id),
        containsAll(<String>[_startMapId, _routeMapId]),
      );

      final mapsById = await _readAllManifestMaps(
        projectRoot: projectRoot,
        manifest: selbrumeBundle.manifest,
      );
      expect(
        mapsById.keys,
        containsAll(selbrumeBundle.manifest.maps.map((entry) => entry.id)),
      );

      final startMap = mapsById[_startMapId]!;
      final spawn = startMap.entities.singleWhere(
        (entity) => entity.id == _spawnId,
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final routeMap = mapsById[_routeMapId]!;
      final grantNpc = routeMap.entities.singleWhere(
        (entity) => entity.id == _grantNpcId,
      );
      expect(grantNpc.kind, MapEntityKind.npc);
      expect(grantNpc.npc?.trainerId, _trainerId);

      final encounterTable = selbrumeBundle.manifest.encounterTables
          .singleWhere((table) => table.id == _encounterTableId);
      expect(encounterTable.encounterKind, EncounterKind.walk);
      expect(encounterTable.entries.single.speciesId, _initialSpeciesId);
      expect(encounterTable.entries.single.minLevel, 1);
      expect(encounterTable.entries.single.maxLevel, 5);
      expect(
        routeMap.gameplayZones.where(
          (zone) =>
              zone.kind == GameplayZoneKind.encounter &&
              zone.encounter?.encounterTableId == _encounterTableId &&
              zone.encounter?.encounterKind == EncounterKind.walk,
        ),
        hasLength(5),
      );

      final speciesIds = await _readAllSpeciesIds(
        projectRoot: projectRoot,
        speciesDir: selbrumeBundle.manifest.pokemon.speciesDir,
      );
      expect(
        speciesIds,
        containsAll(<String>[_initialSpeciesId, ..._grantSpeciesIds]),
      );

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: selbrumeBundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      expect(
        moveIds,
        containsAll(<String>{..._initialMoves, ..._grantMoveIds}),
      );

      final itemIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: selbrumeBundle.manifest.pokemon.catalogFiles['items']!,
        expectedCatalog: 'items',
      );
      expect(itemIds, containsAll(<String>[_captureItemId, _medicineItemId]));

      final grantTrainer = selbrumeBundle.manifest.trainers.singleWhere(
        (trainer) => trainer.id == _trainerId,
      );
      expect(grantTrainer.team.map((member) => member.speciesId),
          _grantSpeciesIds);
      expect(
        grantTrainer.team.expand((member) => member.moves),
        containsAll(_grantMoveIds),
      );

      final result = validateBetaPlayability(
        selbrumeBundle.manifest,
        context: BetaPlayabilityValidationContext(
          mapsById: mapsById,
          startMapId: _startMapId,
          knownSpeciesIds: speciesIds,
          knownMoveIds: moveIds,
          initialPartySpeciesIds: const <String>{_initialSpeciesId},
          initialPartyMoveIds: _initialMoves.toSet(),
          requiresInitialParty: true,
          requiresTrainerBattle: true,
          requiresCapture: true,
          hasCaptureItemSource: itemIds.contains(_captureItemId),
          requiresSaveLoad: true,
          hasSaveLoadSupport: true,
        ),
      );

      expect(result.hasErrors, isFalse);
      expect(result.isPlayable, isTrue);
      expect(result.diagnostics, isEmpty);
      expect(
        _diagnosticsBySeverity(result),
        equals(<BetaPlayabilityDiagnosticSeverity,
            List<BetaPlayabilityDiagnosticKind>>{
          BetaPlayabilityDiagnosticSeverity.error:
              <BetaPlayabilityDiagnosticKind>[],
          BetaPlayabilityDiagnosticSeverity.warning:
              <BetaPlayabilityDiagnosticKind>[],
          BetaPlayabilityDiagnosticSeverity.info:
              <BetaPlayabilityDiagnosticKind>[],
        }),
      );

      final diagnosticKinds =
          result.diagnostics.map((diagnostic) => diagnostic.kind).toSet();
      expect(
        diagnosticKinds,
        isNot(
          containsAll(<BetaPlayabilityDiagnosticKind>{
            BetaPlayabilityDiagnosticKind.missingMap,
            BetaPlayabilityDiagnosticKind.missingStartMap,
            BetaPlayabilityDiagnosticKind.missingPlayerSpawn,
            BetaPlayabilityDiagnosticKind.invalidDefaultSpawn,
            BetaPlayabilityDiagnosticKind.missingTrainerReference,
            BetaPlayabilityDiagnosticKind.trainerHasEmptyTeam,
            BetaPlayabilityDiagnosticKind.trainerPokemonMissingSpecies,
            BetaPlayabilityDiagnosticKind.trainerPokemonMissingMoves,
            BetaPlayabilityDiagnosticKind.missingPokemonSpecies,
            BetaPlayabilityDiagnosticKind.missingPokemonMove,
            BetaPlayabilityDiagnosticKind.missingStarterOrInitialPartySource,
            BetaPlayabilityDiagnosticKind.missingCapturePrerequisite,
            BetaPlayabilityDiagnosticKind.missingSaveLoadPrerequisite,
          }),
        ),
      );
    },
  );
}

Future<Map<String, MapData>> _readAllManifestMaps({
  required Directory projectRoot,
  required ProjectManifest manifest,
}) async {
  final mapsById = <String, MapData>{};
  for (final entry in manifest.maps) {
    final json = await _readProjectJson(projectRoot, entry.relativePath);
    final map = MapData.fromJson(json);
    mapsById[map.id] = map;
  }
  return mapsById;
}

Future<Set<String>> _readAllSpeciesIds({
  required Directory projectRoot,
  required String speciesDir,
}) async {
  final directory = Directory(p.join(projectRoot.path, speciesDir));
  final ids = <String>{};
  await for (final entity in directory.list(recursive: false)) {
    if (entity is! File || p.extension(entity.path) != '.json') {
      continue;
    }
    final json = await _readJsonFile(entity);
    final id = json['id'];
    if (id is String && id.trim().isNotEmpty) {
      ids.add(id);
    }
  }
  return ids;
}

Future<Set<String>> _readCatalogIds({
  required Directory projectRoot,
  required String relativePath,
  required String expectedCatalog,
}) async {
  final json = await _readProjectJson(projectRoot, relativePath);
  expect(json['catalog'], expectedCatalog);
  return (json['entries'] as List<dynamic>)
      .map((entry) => entry as Map<String, dynamic>)
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

Map<BetaPlayabilityDiagnosticSeverity, List<BetaPlayabilityDiagnosticKind>>
    _diagnosticsBySeverity(BetaPlayabilityValidationResult result) {
  return <BetaPlayabilityDiagnosticSeverity,
      List<BetaPlayabilityDiagnosticKind>>{
    for (final severity in BetaPlayabilityDiagnosticSeverity.values)
      severity: result.diagnostics
          .where((diagnostic) => diagnostic.severity == severity)
          .map((diagnostic) => diagnostic.kind)
          .toList(growable: false),
  };
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

### 15.3 Git final

Commandes :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sorties après création du test, de la roadmap et du rapport :

```text
git diff --check:
Sortie : <vide>

git diff --stat:
 MVP Selbrume/road_map_phase_6.md | 73 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 64 insertions(+), 9 deletions(-)

git diff --name-only:
MVP Selbrume/road_map_phase_6.md

git status --short --untracked-files=all:
 M "MVP Selbrume/road_map_phase_6.md"
?? packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart
?? reports/roadmap/phase_6/p6_07_selbrume_beta_validator_pass.md

git status --short --untracked-files=all -- selbrume:
Sortie : <vide>
```

Confirmations :

```text
aucun code production n'a été modifié
aucun fichier selbrume/ n'a été modifié
aucun P6-08 n'a été lancé
```

## 16. Auto-review critique

Ai-je utilisé le chemin repo-local selbrume ?

```text
Oui. Le test découvre selbrume/project.json depuis la racine repo-local.
```

Ai-je évité l'ancien chemin Desktop ?

```text
Oui. La recherche dans le test P6-07 retourne Sortie : <vide>.
```

Ai-je utilisé le validator existant ?

```text
Oui. P6-07 appelle validateBetaPlayability sans modifier le validator.
```

Ai-je construit un contexte explicite et honnête ?

```text
Oui. Le contexte fournit startMapId, mapsById, knownSpeciesIds, knownMoveIds, initialPartySpeciesIds, initialPartyMoveIds, capture source et save/load support.
```

Ai-je listé les diagnostics ?

```text
Oui. errors=[], warnings=[], infos=[].
```

Ai-je distingué erreurs bloquantes, warnings et infos ?

```text
Oui. Les trois catégories sont vides.
```

Ai-je évité de modifier le validator ?

```text
Oui.
```

Ai-je évité de modifier selbrume/ ?

```text
Oui.
```

Ai-je lancé P6-08 ?

```text
Non.
```

Ai-je forcé un pass malgré des diagnostics bloquants ?

```text
Non. Le validator retourne zéro diagnostic.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : P6-08 — Selbrume Playable Runtime Smoke V0.
```
