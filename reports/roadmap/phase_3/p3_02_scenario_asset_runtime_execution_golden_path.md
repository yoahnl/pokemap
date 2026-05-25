# P3-02 — ScenarioAsset Runtime Execution Golden Path

## 1. Résumé exécutif

P3-02 a produit une preuve exécutable, non-Selbrume, du golden path minimal :

```text
fixture disque technique
-> project.json
-> ProjectManifest.scenarios
-> loadRuntimeMapBundle(...)
-> RuntimeMapBundle.manifest.scenarios
-> ScenarioRuntimeExecutor
-> ScenarioRuntimeSourceEvent.mapEnter
-> GameState muté
```

Résultat :

- fixture créée : `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/` ;
- test créé : `packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart` ;
- `loadRuntimeMapBundle` charge un vrai `project.json` ;
- le `ScenarioAsset` vient bien du `ProjectManifest` chargé depuis disque ;
- le scénario exécute `setFlag`, `completeStep`, `emitOutcome` ;
- le test ciblé passe ;
- deux régressions ciblées executor/outcome passent ;
- pas de Selbrume, pas d'UI, pas de battle, pas de save/load roundtrip, pas de World Rule.

Prochain lot exact :

```text
P3-03 — Event Source to Scenario Runtime Bridge Validation
```

## 2. Scope du lot

Inclus :

- création d'une fixture technique minimale ;
- création d'un test ciblé `map_runtime` ;
- preuve disque `project.json` + `RuntimeMapBundle` ;
- preuve application runtime via `ScenarioRuntimeExecutor` ;
- vérification de mutations `GameState` ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md` ;
- rapport P3-02.

Exclus :

- host smoke complet ;
- instanciation `PlayableMapGame` ;
- dialogue Yarn réel ;
- battle handoff ;
- outcome/battle continuation ;
- save/load roundtrip ;
- World Rules ;
- UI / Scene Builder / Cinematic Builder ;
- Selbrume.

## 3. Sources lues

Sources obligatoires :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md`
- `reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md`

Sources code / tests :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scenario_runtime_executor_test.dart`
- `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart`
- `examples/playable_runtime_host/golden_battle_slice/project.json`
- `examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`

## 4. Fixture technique créée ou réutilisée

Fixture créée :

```text
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/
```

Fichiers :

- `README.md`
- `project.json`
- `maps/p3_scenario_field.json`

IDs non-Selbrume :

- map id : `p3_test_map`
- scenario id : `p3_test_scenario`
- source id : `p3_test_source`
- step id : `p3.step.completed`
- flag id : `p3.flag.executed`
- outcome id : `p3.outcome.done`

Le scénario :

```text
start
-> sourceMapEnter(p3_test_map)
-> setFlag(p3.flag.executed)
-> completeStep(p3.step.completed)
-> emitOutcome(p3.outcome.done)
-> end
```

Note : un node `start` a été ajouté parce que `ProjectValidator.validate` exige exactement un start node pour un `ScenarioAsset` chargé depuis `project.json`. Le dispatch runtime testé reste bien `sourceMapEnter`.

## 5. Golden path testé

Le test `p3_scenario_runtime_golden_path_test.dart` vérifie :

1. `loadRuntimeMapBundle` charge le vrai fichier `project.json` de fixture.
2. `bundle.map.id == p3_test_map`.
3. `bundle.manifest.scenarios` contient exactement un scénario.
4. Le scénario chargé a l'id `p3_test_scenario`.
5. Le dispatch utilise `ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_test_map')`.
6. `ScenarioRuntimeExecutor` atteint `ScenarioRuntimeExecutionStatus.reachedEnd`.
7. `GameState.storyFlags.activeFlags` contient `p3.flag.executed`.
8. `GameState.progression.completedStepIds` contient `p3.step.completed`.
9. `GameState.storyFlags.activeFlags` contient `scenario.outcome.p3.outcome.done`.

## 6. Niveau de preuve obtenu

Preuve obtenue :

- Level 4 partiel : vrai `project.json` et vraie map JSON chargés par `loadRuntimeMapBundle`.
- Level 4 partiel : `ScenarioAsset` embedded réellement désérialisé depuis `ProjectManifest.scenarios`.
- Level 2/3 contrôlé : `ScenarioRuntimeExecutor` exécute les données chargées, sans instancier `PlayableMapGame`.

Ce n'est pas vendu comme preuve Flame complète :

- `PlayableMapGame` n'est pas instancié ;
- le host n'est pas lancé ;
- aucun `GameWidget` ou input runtime n'est testé.

## 7. Ce qui est prouvé

- Le loader porte bien un `ScenarioAsset` depuis un projet disque minimal.
- Le scénario peut être lu dans `RuntimeMapBundle.manifest.scenarios`.
- Une source runtime minimale `sourceMapEnter` peut déclencher le scénario.
- Les actions `setFlag`, `completeStep` et `emitOutcome` mutent bien `GameState`.
- L'outcome est persisté selon la convention existante `scenario.outcome.<outcomeId>`.
- Le scénario utilise des IDs techniques génériques, pas Selbrume.

## 8. Ce qui n’est pas prouvé

- Dispatch complet via `PlayableMapGame`.
- Interaction player/input/Flame.
- Dialogue Yarn réel.
- `sourceTriggerEnter`, `sourceEntityInteract`, `sourceOutcome`.
- Battle handoff.
- Battle outcome continuation.
- Save/load roundtrip.
- World Rule projection.
- Host smoke test.

## 9. Gaps reportés à P3-03 / P3-04 / P3-05 / P3-06 / P3-07

- P3-03 : valider les hooks Event Source vers le scenario runtime (`mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived`) dans le chemin runtime adapté.
- P3-04 : valider continuation outcome et battle outcome.
- P3-05 : valider Fact / World Rule runtime projection.
- P3-06 : valider save/load narrative state roundtrip.
- P3-07 : valider un smoke test host narratif si les lots précédents rendent le périmètre stable.

## 10. Tests exécutés

Commandes :

```bash
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_scenario_runtime_golden_path_test.dart
```

Résultats :

- P3-02 ciblé : vert.
- `scenario_runtime_executor_test.dart` : vert.
- `outcome_scene_branch_readiness_test.dart` : vert.
- format check : `0 changed`.

## 11. Modifications effectuées

Fichiers créés :

- `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/README.md`
- `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json`
- `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json`
- `packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart`
- `reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md`

Fichier modifié :

- `MVP Selbrume/road_map_phase_3.md`

Code de production modifié :

- Aucun.

## 12. Evidence Pack

### 12.1 git status initial exact

```text

```

### 12.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/scenario_runtime_executor_test.dart
packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
examples/playable_runtime_host/golden_battle_slice/project.json
examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json
```

### 12.3 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,360p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,260p' reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
sed -n '1,420p' reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
find . -name project.json -o -name runtime_host_launch_save.json -o -name "*.yarn" -o -name "*scenario*.json" | sort
rg -n "ScenarioRuntimeExecutor|ScenarioRuntimeSourceEvent|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|outcomeReceived|emitOutcome|completeStep|setFlag|scenario.outcome|loadRuntimeMapBundle|RuntimeMapBundle|ProjectManifest.scenarios|PlayableMapGame" packages/map_core packages/map_runtime examples/playable_runtime_host --glob '!build/**' --glob '!**/.dart_tool/**'
mkdir -p packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_scenario_runtime_golden_path_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- "MVP Selbrume/road_map_global.md"
find reports/roadmap/phase_3 packages/map_runtime/test packages/map_runtime/test/fixtures -path '*p3_03*' -o -path '*p3-03*' | sort
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md || true
git diff --no-index --check /dev/null packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart || true
git diff --no-index --check /dev/null packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json || true
git diff --no-index --check /dev/null packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json || true
git diff --no-index --check /dev/null packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/README.md || true
```

### 12.4 Sorties utiles

Recherche fixtures avant création :

```text
./examples/playable_runtime_host/golden_battle_slice/project.json
./examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_0.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_1.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_10.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_11.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_12.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_13.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_2.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_3.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_4.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_5.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_6.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_7.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_8.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_9.json
```

Premier test rouge :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
00:00 +0: P3 ScenarioAsset runtime golden path loads a disk project and executes its embedded ScenarioAsset
00:00 +0 -1: P3 ScenarioAsset runtime golden path loads a disk project and executes its embedded ScenarioAsset [E]
  Failed to load project: Scenario p3_test_scenario must contain exactly one start node
  package:map_runtime/src/application/load_runtime_map_bundle.dart 45:5  loadProjectManifestFromFile

00:00 +0 -1: Some tests failed.
```

Correction appliquée : ajout du node `p3_start` dans la fixture.

Test ciblé vert :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
00:00 +0: P3 ScenarioAsset runtime golden path loads a disk project and executes its embedded ScenarioAsset
00:00 +1: All tests passed!
```

Régressions ciblées :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scenario_runtime_executor_test.dart
00:00 +0: ScenarioRuntimeExecutor map enter source triggers dialogue node
00:00 +1: ScenarioRuntimeExecutor trigger enter source matches map + trigger id
00:00 +2: ScenarioRuntimeExecutor entity interaction source can run script action
00:00 +3: ScenarioRuntimeExecutor condition node routes to trueBranch and evaluates flag mutation
00:00 +4: ScenarioRuntimeExecutor unsupported choice node blocks execution explicitly
00:00 +5: ScenarioRuntimeExecutor local outcome can route into global story sourceOutcome
00:00 +6: ScenarioRuntimeExecutor scenario activationCondition gates local source execution
00:00 +7: ScenarioRuntimeExecutor dispatchContinuation resumes after dialogue and executes moveCharacter
00:00 +8: ScenarioRuntimeExecutor moveCharacter blocks when target data is missing
00:00 +9: ScenarioRuntimeExecutor followCharacter delegates to context and continues to end
00:00 +10: ScenarioRuntimeExecutor followCharacter blocks when leaderId is missing
00:00 +11: ScenarioRuntimeExecutor transitionMap delegates to context and continues to end
00:00 +12: ScenarioRuntimeExecutor transitionMap blocks when mapId or warpId is missing
00:00 +13: ScenarioRuntimeExecutor shouldSkipScenario bypasses scenario and tries next candidate
00:00 +14: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
00:00 +0: Outcome → Scene branch readiness emitOutcome sets the outcome flag in GameState
00:00 +1: Outcome → Scene branch readiness condition node branches to true when outcome flag is set
00:00 +2: Outcome → Scene branch readiness condition node branches to false when outcome flag is absent
00:00 +3: Outcome → Scene branch readiness full chain: emitOutcome then branch reads outcome flag
00:00 +4: Outcome → Scene branch readiness different outcome leads to different branch
00:00 +5: Outcome → Scene branch readiness outcome flag survives save/load round-trip
00:00 +6: Outcome → Scene branch readiness emitOutcome with completeStep in same flow
00:00 +7: Outcome → Scene branch readiness emitOutcome blocks when outcomeId is missing
00:00 +8: Outcome → Scene branch readiness does not hardcode any Selbrume ids
00:00 +9: All tests passed!
```

Format check :

```text
Formatted 1 file (0 changed) in 0.00 seconds.
```

### 12.5 Contenu complet des fichiers de fixture créés

`packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json` :

```json
{
  "name": "P3 Scenario Runtime Golden Path",
  "version": "v1",
  "maps": [
    {
      "id": "p3_test_map",
      "name": "P3 Test Map",
      "relativePath": "maps/p3_scenario_field.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "scenarios": [
    {
      "id": "p3_test_scenario",
      "name": "P3 Test Scenario",
      "description": "Technical fixture proving ScenarioAsset execution from disk.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_start",
      "declaredOutcomes": [
        "p3.outcome.done"
      ],
      "nodes": [
        {
          "id": "p3_start",
          "type": "start"
        },
        {
          "id": "p3_test_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceMapEnter"
          },
          "binding": {
            "mapId": "p3_test_map"
          }
        },
        {
          "id": "p3_set_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.flag.executed"
          }
        },
        {
          "id": "p3_complete_step",
          "type": "action",
          "payload": {
            "actionKind": "completeStep",
            "params": {
              "stepId": "p3.step.completed"
            }
          }
        },
        {
          "id": "p3_emit_outcome",
          "type": "action",
          "payload": {
            "actionKind": "emitOutcome"
          },
          "binding": {
            "outcomeId": "p3.outcome.done"
          }
        },
        {
          "id": "p3_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_edge_start_source",
          "fromNodeId": "p3_start",
          "toNodeId": "p3_test_source"
        },
        {
          "id": "p3_edge_source_flag",
          "fromNodeId": "p3_test_source",
          "toNodeId": "p3_set_flag"
        },
        {
          "id": "p3_edge_flag_step",
          "fromNodeId": "p3_set_flag",
          "toNodeId": "p3_complete_step"
        },
        {
          "id": "p3_edge_step_outcome",
          "fromNodeId": "p3_complete_step",
          "toNodeId": "p3_emit_outcome"
        },
        {
          "id": "p3_edge_outcome_end",
          "fromNodeId": "p3_emit_outcome",
          "toNodeId": "p3_end"
        }
      ],
      "metadata": {
        "phase": "P3-02"
      }
    }
  ]
}
```

`packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json` :

```json
{
  "id": "p3_test_map",
  "name": "P3 Test Map",
  "size": {
    "width": 3,
    "height": 3
  },
  "version": "v1",
  "mapMetadata": {
    "defaultSpawnId": "p3_spawn_start"
  },
  "entities": [
    {
      "id": "p3_spawn_start",
      "name": "P3 Spawn Start",
      "kind": "spawn",
      "pos": {
        "x": 1,
        "y": 1
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "south"
      }
    }
  ]
}
```

`packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/README.md` :

```md
# P3 Scenario Runtime Golden Path Fixture

Technical non-Selbrume fixture for P3-02.

Purpose:

- load a real `project.json` through `loadRuntimeMapBundle`;
- expose one embedded `ScenarioAsset` from `ProjectManifest.scenarios`;
- execute the scenario with `ScenarioRuntimeExecutor`;
- verify `setFlag`, `completeStep`, and `emitOutcome` mutations.

This fixture intentionally avoids dialogue, battle, save/load roundtrip, world
rules, UI, and host smoke coverage. Those belong to later Phase 3 lots.
```

### 12.6 Contenu complet du test créé

`packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart` :

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 ScenarioAsset runtime golden path', () {
    test('loads a disk project and executes its embedded ScenarioAsset',
        () async {
      final projectFilePath = p.join(
        Directory.current.path,
        'test',
        'fixtures',
        'p3_scenario_runtime_golden_path',
        'project.json',
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'p3_test_map',
      );

      expect(bundle.map.id, 'p3_test_map');
      expect(bundle.manifest.scenarios, hasLength(1));

      final scenario = bundle.manifest.scenarios.single;
      expect(scenario.id, 'p3_test_scenario');
      expect(scenario.entryNodeId, 'p3_start');
      expect(scenario.declaredOutcomes, contains('p3.outcome.done'));

      var state = const GameState(saveId: 'p3-scenario-runtime-golden-path');
      final result = const ScenarioRuntimeExecutor().dispatch(
        scenarios: bundle.manifest.scenarios,
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_test_map'),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (_, {startNode, runtimeSourceId}) => false,
          runScript: (_, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(result.scenarioId, 'p3_test_scenario');
      expect(result.sourceNodeId, 'p3_test_source');
      expect(result.stopNodeId, 'p3_end');

      expect(state.storyFlags.activeFlags, contains('p3.flag.executed'));
      expect(
        state.progression.completedStepIds,
        contains('p3.step.completed'),
      );
      expect(
        state.storyFlags.activeFlags,
        contains(scenarioOutcomeFlagName('p3.outcome.done')),
      );
    });
  });
}
```

### 12.7 Extraits des fichiers modifiés

`MVP Selbrume/road_map_phase_3.md` :

```text
Lot courant : P3-03 — Event Source to Scenario Runtime Bridge Validation

Prochain lot exact : P3-03 — Event Source to Scenario Runtime Bridge Validation

- ✅ P3-02 — ScenarioAsset Runtime Execution Golden Path
- 🔜 P3-03 — Event Source to Scenario Runtime Bridge Validation
```

Section P3-02 ajoutée :

```text
Résultat P3-02 :

- rapport créé :
  `reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md` ;
- fixture technique non-Selbrume créée :
  `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/` ;
- test ciblé créé :
  `packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart` ;
- preuve obtenue :
  - vrai `project.json` chargé par `loadRuntimeMapBundle` ;
  - `ScenarioAsset` embedded disponible via `RuntimeMapBundle.manifest.scenarios` ;
  - `ScenarioRuntimeExecutor` déclenché par `ScenarioRuntimeSourceEvent.mapEnter` ;
  - `GameState.storyFlags` reçoit `p3.flag.executed` ;
  - `GameState.progression.completedStepIds` reçoit `p3.step.completed` ;
  - `emitOutcome` pose `scenario.outcome.p3.outcome.done` ;
- niveau de preuve : Level 4 partiel pour disque + Level 2/3 contrôlé pour executor ;
- non prouvé volontairement : hook complet `PlayableMapGame`, host smoke, dialogue
  Yarn réel, battle continuation, save/load roundtrip, World Rules ;
```

### 12.8 git diff --check exact

```text

```

### 12.9 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_3.md | 45 +++++++++++++++++++++++++++++++++-------
 1 file changed, 38 insertions(+), 7 deletions(-)
```

### 12.10 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_3.md
```

### 12.11 git status final exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/README.md
?? packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json
?? packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json
?? packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
?? reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
```

### 12.12 Contrôles explicites

```text
road_map_global.md non modifié :
git diff --name-only -- "MVP Selbrume/road_map_global.md"
Sortie exacte : sortie vide.

P3-03 non exécuté : aucun rapport, fixture ou test P3-03 créé.
find reports/roadmap/phase_3 packages/map_runtime/test packages/map_runtime/test/fixtures -path '*p3_03*' -o -path '*p3-03*' | sort
Sortie exacte : sortie vide.

Selbrume final non créé : IDs de fixture strictement p3_*.

No-index whitespace checks des fichiers créés :
- report P3-02 : sortie vide.
- test P3-02 : sortie vide.
- fixture project/map/README : sortie vide.
```

## 13. Auto-review critique

- Le lot a-t-il produit une preuve exécutable ? Oui.
- Le test charge-t-il un vrai `project.json` ? Oui.
- Le scénario vient-il de `RuntimeMapBundle.manifest.scenarios` ? Oui.
- Le test évite-t-il un manifest seulement in-memory ? Oui.
- `GameState` est-il muté et vérifié ? Oui.
- Le test ciblé passe-t-il ? Oui.
- Les régressions ciblées passent-elles ? Oui.
- Aucun modèle core n'a-t-il été modifié ? Oui.
- Aucune UI n'a-t-elle été créée ? Oui.
- Aucun battle/reward/world rule/save-load hors scope n'a-t-il été ouvert ? Oui.
- P3-03 n'a-t-il pas été exécuté ? Oui.
- Prochain lot exact clair ? Oui : P3-03.

## 14. Regard critique sur le prompt

Le prompt cadre bien la différence entre preuve disque et preuve Flame. Le point utile découvert par le test rouge est que les scénarios chargés par `ProjectValidator` doivent contenir un node `start`, même si le dispatch runtime P3-02 démarre depuis un source node. Cette contrainte mérite de rester visible pour les futures fixtures Phase 3.
