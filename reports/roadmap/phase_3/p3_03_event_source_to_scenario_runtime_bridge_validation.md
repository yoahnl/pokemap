# P3-03 — Event Source to Scenario Runtime Bridge Validation

## 1. Résumé exécutif

P3-03 ajoute une preuve exécutable ciblée du pont :

```text
fixture disque technique non-Selbrume
-> project.json
-> loadRuntimeMapBundle
-> RuntimeMapBundle.manifest.scenarios
-> ScenarioRuntimeExecutor.dispatch
-> ScenarioRuntimeSourceEvent.*
-> GameState.storyFlags
```

Le lot couvre les quatre sources demandées :

- `mapEnter` ;
- `triggerEnter` ;
- `entityInteract` ;
- `outcomeReceived`.

Résultat :

- fixture créée : `packages/map_runtime/test/fixtures/p3_event_source_bridge/` ;
- test créé : `packages/map_runtime/test/p3_event_source_bridge_validation_test.dart` ;
- chaque source positive matche son scénario et pose son flag distinct ;
- quatre cas négatifs vérifient qu'un mauvais `mapId`, `triggerId`, `entityId`
  ou `outcomeId` ne déclenche aucun scénario ;
- P3-02 et les régressions executor/outcome ciblées restent vertes ;
- aucun code runtime de production n'a été modifié ;
- pas de Selbrume, pas d'UI, pas de battle continuation, pas de save/load
  roundtrip, pas de World Rule.

Prochain lot exact :

```text
P3-04 — Outcome / Battle Outcome Runtime Continuation Validation
```

## 2. Scope du lot

Inclus :

- création d'une fixture disque technique non-Selbrume ;
- validation `loadRuntimeMapBundle` sur un vrai `project.json` ;
- validation de quatre `ScenarioRuntimeSourceEvent` envoyés explicitement au
  `ScenarioRuntimeExecutor` ;
- mutations `GameState.storyFlags` vérifiées ;
- cas négatifs contre les faux déclenchements ;
- tests ciblés et régressions ciblées ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md` ;
- rapport P3-03.

Exclus :

- preuve complète `PlayableMapGame` / Flame ;
- smoke test host ;
- chaine automatique `emitOutcome -> outcomeReceived` ;
- battle outcome continuation ;
- save/load roundtrip ;
- World Rules ;
- UI/editor ;
- Selbrume final ;
- P3-04.

## 3. Sources lues

Sources de gouvernance et rapports :

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
```

Sources runtime / core inspectees :

```text
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
packages/map_runtime/test/scenario_runtime_executor_test.dart
packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
packages/map_runtime/test/npc_interaction_scene_readiness_test.dart
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/README.md
```

## 4. Fixture créée ou modifiée

P3-03 crée une nouvelle fixture dédiée au lieu d'étendre la fixture P3-02.
Raison : `p3_scenario_runtime_golden_path_test.dart` vérifie que la fixture
P3-02 ne contient qu'un seul scénario. Une fixture P3-03 séparée garde la preuve
P3-02 stable.

Fichiers créés :

```text
packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md
packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
```

La fixture contient :

- map id : `p3_event_source_map` ;
- entity id : `p3_test_npc` ;
- trigger id logique : `p3_test_trigger` ;
- outcome id source : `p3.source.previous_outcome` ;
- quatre `ScenarioAsset` embedded dans `project.json`.

Le trigger reste un identifiant de source runtime. Le modèle map actuel ne force
pas une entité trigger physique pour que `ScenarioRuntimeExecutor` matche
`sourceTriggerEnter`.

## 5. Sources runtime testées

| Source runtime | Node source | Scenario attendu | Flag attendu |
|---|---|---|---|
| `ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_event_source_map')` | `sourceMapEnter` | `p3_source_map_enter_scenario` | `p3.source.map_enter.executed` |
| `ScenarioRuntimeSourceEvent.triggerEnter(mapId: 'p3_event_source_map', triggerId: 'p3_test_trigger')` | `sourceTriggerEnter` | `p3_source_trigger_enter_scenario` | `p3.source.trigger_enter.executed` |
| `ScenarioRuntimeSourceEvent.entityInteract(mapId: 'p3_event_source_map', entityId: 'p3_test_npc')` | `sourceEntityInteract` | `p3_source_entity_interact_scenario` | `p3.source.entity_interact.executed` |
| `ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId: 'p3.source.previous_outcome')` | `sourceOutcome` | `p3_source_outcome_received_scenario` | `p3.source.outcome_received.executed` |

## 6. Cas positifs

Le test `dispatches each runtime source to only its matching disk scenario`
vérifie :

- chargement de la fixture via `loadRuntimeMapBundle` ;
- présence des quatre scénarios dans `bundle.manifest.scenarios` ;
- `dispatch` atteint `ScenarioRuntimeExecutionStatus.reachedEnd` ;
- `scenarioId` et `sourceNodeId` correspondent à la source envoyée ;
- le flag attendu est posé dans `GameState.storyFlags.activeFlags` ;
- les trois autres flags restent absents pour chaque dispatch.

## 7. Cas négatifs

Le test `does not dispatch runtime sources with mismatched identifiers` vérifie :

- `mapEnter` avec `mapId: 'p3_wrong_map'` ;
- `triggerEnter` avec `triggerId: 'p3_wrong_trigger'` ;
- `entityInteract` avec `entityId: 'p3_wrong_npc'` ;
- `outcomeReceived` avec `outcomeId: 'p3.source.wrong_outcome'`.

Chaque cas retourne :

```text
ScenarioRuntimeExecutionStatus.noMatchingSource
scenarioId == null
GameState.storyFlags.activeFlags == empty
```

## 8. Niveau de preuve obtenu

Niveau obtenu :

- Level 4 partiel pour le disque : un vrai `project.json` de fixture est chargé
  via `loadRuntimeMapBundle` et expose ses `ScenarioAsset` dans
  `RuntimeMapBundle.manifest.scenarios` ;
- Level 2/3 contrôlé pour le dispatch application runtime :
  `ScenarioRuntimeExecutor.dispatch` est exécuté sur les données chargées et
  mute un `GameState` vérifié.

Non revendiqué :

- pas une preuve Flame complète ;
- pas une preuve host ;
- pas une preuve d'auto-dispatch après `emitOutcome`.

## 9. Ce qui est prouvé

P3-03 prouve que :

- les sources runtime supportées par `ScenarioRuntimeExecutor` peuvent être
  représentées dans des `ScenarioAsset` embedded dans un vrai `project.json` ;
- `loadRuntimeMapBundle` expose ces scénarios au runtime ;
- `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived` matchent les
  bons nodes sources ;
- chaque source déclenche uniquement son scénario attendu dans cette fixture ;
- des identifiants faux ne déclenchent aucun scénario ;
- les mutations observables restent des `storyFlags`, sans nouveau stockage.

## 10. Ce qui n’est pas prouvé

P3-03 ne prouve pas :

- que `PlayableMapGame` déclenche automatiquement ces quatre sources depuis la
  boucle Flame ;
- que le host jouable exécute un flux narratif complet ;
- que `emitOutcome` enchaine automatiquement vers `outcomeReceived` ;
- que les battle outcomes continuent vers des scénarios ;
- que save/load conserve ce flux ;
- que les World Rules se projettent depuis ces mutations ;
- que des fixtures Selbrume réelles existent.

## 11. Gaps reportés à P3-04 / P3-05 / P3-06 / P3-07

P3-04 :

- valider la continuation `emitOutcome -> outcomeReceived` si le runtime la
  supporte ou documenter le gap ;
- valider la continuation battle outcome séparément des scenario outcomes.

P3-05 :

- valider la projection Fact / World Rule depuis les vérités techniques
  existantes.

P3-06 :

- valider le roundtrip save/load des flags/outcomes/steps nécessaires.

P3-07 :

- valider, si les lots précédents le permettent, un smoke test narratif minimal
  dans le playable runtime host.

## 12. Tests exécutés

Commandes ciblées :

```text
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
```

Résultat : les tests ciblés et les régressions ciblées passent.

## 13. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md
packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_3.md
```

Aucun fichier de production runtime/core/editor/battle/gameplay n'a été modifié.

## 14. Evidence Pack

### 14.1 git status initial exact

```text
(no output)
```

### 14.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
packages/map_runtime/test/scenario_runtime_executor_test.dart
packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
packages/map_runtime/test/npc_interaction_scene_readiness_test.dart
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/README.md
```

### 14.3 Commandes exécutées

```bash
sed -n '1,220p' /Users/karim/.codex/skills/.system/../superpowers/using-superpowers/SKILL.md
sed -n '1,260p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
sed -n '1,260p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,220p' skills/README.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
find skills -maxdepth 2 -type f -path '*/SKILL.md' | sort
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,420p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,320p' reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
sed -n '1,260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '1,420p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,260p' packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
rg -n "sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|outcomeReceived|ScenarioRuntimeSourceEvent|triggerId|entityId|mapId|outcomeId" packages/map_core packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,260p' packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json
sed -n '1,220p' packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json
find packages/map_runtime/test -maxdepth 4 -type f | sort | sed -n '1,220p'
mkdir -p packages/map_runtime/test/fixtures/p3_event_source_bridge/maps
sed -n '1,260p' packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json
sed -n '1,220p' packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json
sed -n '1,260p' packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
sed -n '1,260p' packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
sed -n '1,360p' packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
sed -n '1,220p' packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
sed -n '1,160p' packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- "MVP Selbrume/road_map_global.md"
find reports/roadmap/phase_3 -maxdepth 1 -type f -name '*p3_04*' -o -name '*P3-04*' | sort
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md || true
git diff --no-index --check /dev/null packages/map_runtime/test/p3_event_source_bridge_validation_test.dart || true
git diff --no-index --check /dev/null packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json || true
git diff --no-index --check /dev/null packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json || true
git diff --no-index --check /dev/null packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md || true
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md || true
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_editor packages/map_battle examples/playable_runtime_host packages/map_runtime/lib packages/map_runtime/pubspec.yaml
```

### 14.4 Sorties utiles

Test ciblé P3-03 :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
00:00 +0: P3 event source bridge validation dispatches each runtime source to only its matching disk scenario
00:00 +1: P3 event source bridge validation does not dispatch runtime sources with mismatched identifiers
00:00 +2: All tests passed!
```

Régression P3-02 :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
00:00 +0: P3 ScenarioAsset runtime golden path loads a disk project and executes its embedded ScenarioAsset
00:00 +1: All tests passed!
```

Régression executor :

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
```

Régression outcome :

```text
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

### 14.5 Fichiers créés

```text
packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md
packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
```

### 14.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_3.md
```

### 14.7 Contenu complet de la fixture

`packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md`

```md
# P3 Event Source Bridge Fixture

Technical non-Selbrume fixture for P3-03.

It proves that a real `project.json` loaded through `loadRuntimeMapBundle`
can expose `ScenarioAsset` entries for the four runtime source events:

- `mapEnter`
- `triggerEnter`
- `entityInteract`
- `outcomeReceived`

The fixture is intentionally small and does not prove PlayableMapGame hooks,
host smoke flow, battle continuation, save/load roundtrip, World Rules, or UI.
```

`packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json`

```json
{
  "id": "p3_event_source_map",
  "name": "P3 Event Source Map",
  "size": {
    "width": 4,
    "height": 4
  },
  "version": "v1",
  "mapMetadata": {
    "defaultSpawnId": "p3_event_source_spawn"
  },
  "entities": [
    {
      "id": "p3_event_source_spawn",
      "name": "P3 Event Source Spawn",
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
    },
    {
      "id": "p3_test_npc",
      "name": "P3 Test NPC",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 1
      },
      "npc": {
        "displayName": "P3 Test NPC",
        "facing": "west"
      }
    }
  ]
}
```

`packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json`

```json
{
  "name": "P3 Event Source Bridge",
  "version": "v1",
  "maps": [
    {
      "id": "p3_event_source_map",
      "name": "P3 Event Source Map",
      "relativePath": "maps/p3_event_source_field.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "scenarios": [
    {
      "id": "p3_source_map_enter_scenario",
      "name": "P3 Source Map Enter Scenario",
      "description": "Technical fixture proving mapEnter event source dispatch.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_map_enter_start",
      "nodes": [
        {
          "id": "p3_map_enter_start",
          "type": "start"
        },
        {
          "id": "p3_map_enter_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceMapEnter"
          },
          "binding": {
            "mapId": "p3_event_source_map"
          }
        },
        {
          "id": "p3_map_enter_set_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.source.map_enter.executed"
          }
        },
        {
          "id": "p3_map_enter_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_map_enter_edge_start_source",
          "fromNodeId": "p3_map_enter_start",
          "toNodeId": "p3_map_enter_source"
        },
        {
          "id": "p3_map_enter_edge_source_flag",
          "fromNodeId": "p3_map_enter_source",
          "toNodeId": "p3_map_enter_set_flag"
        },
        {
          "id": "p3_map_enter_edge_flag_end",
          "fromNodeId": "p3_map_enter_set_flag",
          "toNodeId": "p3_map_enter_end"
        }
      ],
      "metadata": {
        "phase": "P3-03"
      }
    },
    {
      "id": "p3_source_trigger_enter_scenario",
      "name": "P3 Source Trigger Enter Scenario",
      "description": "Technical fixture proving triggerEnter event source dispatch.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_trigger_enter_start",
      "nodes": [
        {
          "id": "p3_trigger_enter_start",
          "type": "start"
        },
        {
          "id": "p3_trigger_enter_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceTriggerEnter"
          },
          "binding": {
            "mapId": "p3_event_source_map",
            "triggerId": "p3_test_trigger"
          }
        },
        {
          "id": "p3_trigger_enter_set_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.source.trigger_enter.executed"
          }
        },
        {
          "id": "p3_trigger_enter_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_trigger_enter_edge_start_source",
          "fromNodeId": "p3_trigger_enter_start",
          "toNodeId": "p3_trigger_enter_source"
        },
        {
          "id": "p3_trigger_enter_edge_source_flag",
          "fromNodeId": "p3_trigger_enter_source",
          "toNodeId": "p3_trigger_enter_set_flag"
        },
        {
          "id": "p3_trigger_enter_edge_flag_end",
          "fromNodeId": "p3_trigger_enter_set_flag",
          "toNodeId": "p3_trigger_enter_end"
        }
      ],
      "metadata": {
        "phase": "P3-03"
      }
    },
    {
      "id": "p3_source_entity_interact_scenario",
      "name": "P3 Source Entity Interact Scenario",
      "description": "Technical fixture proving entityInteract event source dispatch.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_entity_interact_start",
      "nodes": [
        {
          "id": "p3_entity_interact_start",
          "type": "start"
        },
        {
          "id": "p3_entity_interact_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceEntityInteract"
          },
          "binding": {
            "mapId": "p3_event_source_map",
            "entityId": "p3_test_npc"
          }
        },
        {
          "id": "p3_entity_interact_set_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.source.entity_interact.executed"
          }
        },
        {
          "id": "p3_entity_interact_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_entity_interact_edge_start_source",
          "fromNodeId": "p3_entity_interact_start",
          "toNodeId": "p3_entity_interact_source"
        },
        {
          "id": "p3_entity_interact_edge_source_flag",
          "fromNodeId": "p3_entity_interact_source",
          "toNodeId": "p3_entity_interact_set_flag"
        },
        {
          "id": "p3_entity_interact_edge_flag_end",
          "fromNodeId": "p3_entity_interact_set_flag",
          "toNodeId": "p3_entity_interact_end"
        }
      ],
      "metadata": {
        "phase": "P3-03"
      }
    },
    {
      "id": "p3_source_outcome_received_scenario",
      "name": "P3 Source Outcome Received Scenario",
      "description": "Technical fixture proving explicit outcomeReceived event source dispatch.",
      "scope": "globalStory",
      "entryNodeId": "p3_outcome_received_start",
      "nodes": [
        {
          "id": "p3_outcome_received_start",
          "type": "start"
        },
        {
          "id": "p3_outcome_received_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceOutcome"
          },
          "binding": {
            "outcomeId": "p3.source.previous_outcome"
          }
        },
        {
          "id": "p3_outcome_received_set_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.source.outcome_received.executed"
          }
        },
        {
          "id": "p3_outcome_received_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_outcome_received_edge_start_source",
          "fromNodeId": "p3_outcome_received_start",
          "toNodeId": "p3_outcome_received_source"
        },
        {
          "id": "p3_outcome_received_edge_source_flag",
          "fromNodeId": "p3_outcome_received_source",
          "toNodeId": "p3_outcome_received_set_flag"
        },
        {
          "id": "p3_outcome_received_edge_flag_end",
          "fromNodeId": "p3_outcome_received_set_flag",
          "toNodeId": "p3_outcome_received_end"
        }
      ],
      "metadata": {
        "phase": "P3-03"
      }
    }
  ]
}
```

### 14.8 Contenu complet du test créé

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 event source bridge validation', () {
    test('dispatches each runtime source to only its matching disk scenario',
        () async {
      final bundle = await _loadBundle();

      expect(bundle.map.id, _mapId);
      expect(
        bundle.manifest.scenarios.map((scenario) => scenario.id),
        containsAll(_allScenarioIds),
      );

      for (final bridgeCase in _positiveCases) {
        final result = _dispatch(bundle, bridgeCase.sourceEvent);

        expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
        expect(result.scenarioId, bridgeCase.scenarioId);
        expect(result.sourceNodeId, bridgeCase.sourceNodeId);
        expect(result.state.storyFlags.activeFlags, contains(bridgeCase.flag));

        for (final otherFlag
            in _allFlags.where((flag) => flag != bridgeCase.flag)) {
          expect(
              result.state.storyFlags.activeFlags, isNot(contains(otherFlag)));
        }
      }
    });

    test('does not dispatch runtime sources with mismatched identifiers',
        () async {
      final bundle = await _loadBundle();

      final negativeSources = <ScenarioRuntimeSourceEvent>[
        ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_wrong_map'),
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _mapId,
          triggerId: 'p3_wrong_trigger',
        ),
        ScenarioRuntimeSourceEvent.entityInteract(
          mapId: _mapId,
          entityId: 'p3_wrong_npc',
        ),
        ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'p3.source.wrong_outcome',
        ),
      ];

      for (final sourceEvent in negativeSources) {
        final result = _dispatch(bundle, sourceEvent);

        expect(result.status, ScenarioRuntimeExecutionStatus.noMatchingSource);
        expect(result.scenarioId, isNull);
        expect(result.state.storyFlags.activeFlags, isEmpty);
      }
    });
  });
}

const _mapId = 'p3_event_source_map';

const _allFlags = <String>[
  'p3.source.map_enter.executed',
  'p3.source.trigger_enter.executed',
  'p3.source.entity_interact.executed',
  'p3.source.outcome_received.executed',
];

const _allScenarioIds = <String>[
  'p3_source_map_enter_scenario',
  'p3_source_trigger_enter_scenario',
  'p3_source_entity_interact_scenario',
  'p3_source_outcome_received_scenario',
];

final _positiveCases = <_BridgeCase>[
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: _mapId),
    scenarioId: 'p3_source_map_enter_scenario',
    sourceNodeId: 'p3_map_enter_source',
    flag: 'p3.source.map_enter.executed',
  ),
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.triggerEnter(
      mapId: _mapId,
      triggerId: 'p3_test_trigger',
    ),
    scenarioId: 'p3_source_trigger_enter_scenario',
    sourceNodeId: 'p3_trigger_enter_source',
    flag: 'p3.source.trigger_enter.executed',
  ),
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _mapId,
      entityId: 'p3_test_npc',
    ),
    scenarioId: 'p3_source_entity_interact_scenario',
    sourceNodeId: 'p3_entity_interact_source',
    flag: 'p3.source.entity_interact.executed',
  ),
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
      outcomeId: 'p3.source.previous_outcome',
    ),
    scenarioId: 'p3_source_outcome_received_scenario',
    sourceNodeId: 'p3_outcome_received_source',
    flag: 'p3.source.outcome_received.executed',
  ),
];

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_event_source_bridge',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

_DispatchResult _dispatch(
  RuntimeMapBundle bundle,
  ScenarioRuntimeSourceEvent sourceEvent,
) {
  var state = const GameState(saveId: 'p3-event-source-bridge');
  final result = const ScenarioRuntimeExecutor().dispatch(
    scenarios: bundle.manifest.scenarios,
    sourceEvent: sourceEvent,
    context: ScenarioRuntimeExecutionContext(
      gameState: state,
      onGameStateUpdated: (next) => state = next,
      openDialogue: (_, {startNode, runtimeSourceId}) => false,
      runScript: (_, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    ),
  );

  return _DispatchResult(result: result, state: state);
}

class _BridgeCase {
  const _BridgeCase({
    required this.sourceEvent,
    required this.scenarioId,
    required this.sourceNodeId,
    required this.flag,
  });

  final ScenarioRuntimeSourceEvent sourceEvent;
  final String scenarioId;
  final String sourceNodeId;
  final String flag;
}

class _DispatchResult {
  const _DispatchResult({
    required this.result,
    required this.state,
  });

  final ScenarioRuntimeExecutionResult result;
  final GameState state;

  ScenarioRuntimeExecutionStatus get status => result.status;
  String? get scenarioId => result.scenarioId;
  String? get sourceNodeId => result.sourceNodeId;
}
```

### 14.9 git diff --check exact

```text
(no output)
```

### 14.10 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_3.md | 54 ++++++++++++++++++++++++++++++++++------
 1 file changed, 47 insertions(+), 7 deletions(-)
```

### 14.11 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_3.md
```

### 14.12 git status final exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md
?? packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
?? packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
?? packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
?? reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
```

### 14.13 Contrôles explicites

```text
road_map_global.md non modifié : oui, `git diff --name-only -- "MVP Selbrume/road_map_global.md"` n'a rien retourné.
P3-04 non exécuté : oui, seul le prochain lot a été fixé dans la roadmap.
Selbrume final créé : non.
Code de production modifié : non.
Contrôle packages production : `git diff --name-only -- packages/map_core packages/map_gameplay packages/map_editor packages/map_battle examples/playable_runtime_host packages/map_runtime/lib packages/map_runtime/pubspec.yaml` n'a rien retourné.
UI créée : non.
Battle / save-load / World Rules ouverts : non.
```

Checks `--no-index --check` sur les fichiers créés :

```text
report P3-03 : (no output)
test P3-03 : (no output)
fixture project.json : (no output)
fixture map JSON : (no output)
fixture README : (no output)
```

## 15. Auto-review critique

- Le lot a-t-il modifié uniquement ce qui était autorisé ? Oui :
  roadmap Phase 3, rapport, test runtime ciblé et fixture technique.
- Le rapport P3-03 existe-t-il au bon chemin ? Oui.
- `road_map_phase_3.md` est-elle mise à jour ? Oui, P3-04 est le prochain lot.
- `road_map_global.md` est-elle restée intacte ? Oui, contrôle final inclus.
- Une preuve exécutable existe-t-elle ? Oui, test P3-03 ciblé.
- Un vrai `project.json` est-il chargé ? Oui, par `loadRuntimeMapBundle`.
- Les `ScenarioAsset` viennent-ils de `bundle.manifest.scenarios` ? Oui.
- `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived` sont-ils testés
  positivement ? Oui.
- Au moins deux cas négatifs empêchent-ils un faux déclenchement ? Oui, quatre
  cas négatifs.
- `GameState` est-il muté et vérifié par source ? Oui, via flags distincts.
- Aucun Selbrume final n'a-t-il été créé ? Oui.
- P3-04 n'a-t-il pas été exécuté ? Oui.
- Le prochain lot exact est-il clair ? Oui :
  `P3-04 — Outcome / Battle Outcome Runtime Continuation Validation`.

## 16. Regard critique sur le prompt

Le prompt cadre bien le risque principal : ne pas confondre une preuve executor
avec une preuve Flame complète. La contrainte "ne pas tester la chaîne complète
`emitOutcome -> outcomeReceived`" est utile, car elle protège P3-04. Le seul
point délicat est la mention d'un trigger minimal dans la map si le modèle
l'exige : l'audit montre que le dispatch actuel matche le `triggerId` dans la
source node, sans imposer de trigger physique dans `MapData`. Le rapport le
documente plutôt que d'inventer un modèle de trigger.
