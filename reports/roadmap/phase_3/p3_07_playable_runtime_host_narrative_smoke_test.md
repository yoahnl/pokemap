# P3-07 — Playable Runtime Host Narrative Smoke Test

## 1. Résumé exécutif

P3-07 a produit une preuve exécutable ciblée que les briques Phase 3 peuvent
être reliées au host jouable et à `PlayableMapGame`, sans créer Selbrume, sans
UI premium et sans ouvrir les gaps gameplay.

Livrables :

- fixture host technique non-Selbrume :
  `examples/playable_runtime_host/p3_narrative_smoke_slice/` ;
- test ciblé :
  `examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart` ;
- correction de test host existant :
  `examples/playable_runtime_host/test/runtime_launch_save_test.dart` ;
- roadmap Phase 3 mise à jour ;
- rapport P3-07.

Preuve obtenue :

- vrai `project.json` host chargé ;
- vraie `runtime_host_launch_save.json` chargée ;
- `RuntimeMapBundle` contient map + `ScenarioAsset` narratif ;
- `PlayableMapGame` instancié avec bundle + save host ;
- `PlayableMapGame.onLoad()` exécuté après `onGameResize` ;
- hook runtime `mapEnter` déclenche le scenario disque ;
- `gameStateSnapshot` expose le flag et la step produits ;
- la projection NPC fonctionne via les predicates runtime existants.

Prochain lot exact :

```text
P3-CHECKPOINT-01 — Runtime & Disk Readiness Review
```

## 2. Scope du lot

Inclus :

- mini-audit faisabilité host / `PlayableMapGame` ;
- fixture host technique ;
- `runtime_host_launch_save.json` ;
- test ciblé dans `examples/playable_runtime_host` ;
- instanciation de `PlayableMapGame` ;
- `onLoad()` après sizing Flame explicite ;
- assertion sur `gameStateSnapshot` ;
- projection NPC via API runtime existante ;
- mise à jour roadmap.

Exclus :

- Selbrume ;
- UI premium ;
- Scene Builder ;
- Cinematic Builder ;
- vrai dialogue Yarn riche ;
- combat complet ;
- rewards, money, XP, level-up ;
- Phase 4 authoring ;
- Phase 5 gameplay gaps ;
- P3-CHECKPOINT-01.

## 3. Sources lues

Gouvernance et rapports :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md`
- `reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md`
- `reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md`
- `reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md`
- `reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md`
- `reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md`

Host/runtime :

- `examples/playable_runtime_host/lib/main.dart`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart`
- `packages/map_runtime/test/p3_fact_world_rule_projection_test.dart`

Fixtures relues :

- `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/`
- `packages/map_runtime/test/fixtures/p3_event_source_bridge/`
- `packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/`
- `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/`
- `examples/playable_runtime_host/golden_battle_slice/`

## 4. Faisabilité PlayableMapGame / host

Constats :

- le host sait charger une launch save adjacente via
  `loadRuntimeHostLaunchSaveData` ;
- `loadRuntimeMapBundle` est disponible depuis le host ;
- `PlayableMapGame` accepte `RuntimeMapBundle`, `projectFilePath` et `SaveData` ;
- `PlayableMapGame.gameStateSnapshot` expose un état observable sans champ privé ;
- `PlayableMapGame.onLoad()` déclenche déjà `ScenarioRuntimeSourceEvent.mapEnter`
  depuis le hook interne ;
- appeler `onLoad()` directement sans taille Flame échoue sur `hasLayout` ;
- le pattern existant dans les tests runtime est d'appeler
  `game.onGameResize(Vector2(...))` avant `onLoad()`.

Choix :

```text
Option B partielle : instancier PlayableMapGame, lui fournir un layout explicite,
appeler onLoad(), puis vérifier le state public et une projection runtime.
```

Ce choix évite `GameWidget`, input joueur, UI fragile et tout refactor.

## 5. Fixture créée ou réutilisée

Fixture créée :

```text
examples/playable_runtime_host/p3_narrative_smoke_slice/
├── README.md
├── maps/
│   └── p3_narrative_smoke_field.json
├── project.json
└── runtime_host_launch_save.json
```

IDs :

```text
map id : p3_narrative_smoke_map
scenario id : p3_narrative_smoke_scenario
launch flag : p3.smoke.launch.flag
scenario flag : p3.smoke.flag.visible
scenario step : p3.smoke.step.completed
npc id : p3_smoke_npc
```

La fixture est technique et non-Selbrume.

## 6. Smoke path testé

Chemin testé :

```text
examples/playable_runtime_host/p3_narrative_smoke_slice/project.json
-> loadRuntimeHostLaunchSaveData
-> SaveData
-> loadRuntimeMapBundle
-> RuntimeMapBundle.manifest.scenarios
-> PlayableMapGame(bundle, projectFilePath, saveData)
-> onGameResize
-> onLoad
-> internal mapEnter dispatch
-> p3_narrative_smoke_scenario
-> setFlag p3.smoke.flag.visible
-> completeStep p3.smoke.step.completed
-> gameStateSnapshot
-> isNpcRuntimePresentOnMap
```

Assertions principales :

- launch save présente et normalisée ;
- bundle map id correct ;
- scenario id présent ;
- NPC invisible avant `mapEnter` ;
- `PlayableMapGame` construit avec la save host ;
- `gameStateSnapshot` contient le flag de launch avant `onLoad` ;
- après `onLoad`, `gameStateSnapshot` contient flag scenario + step ;
- NPC visible après dispatch mapEnter.

## 7. Niveau de preuve obtenu

```text
Level 4 partiel :
- vrai dossier projet host ;
- vrai project.json ;
- vraie map JSON ;
- vraie runtime_host_launch_save.json.

Level 3 partiel :
- PlayableMapGame instancié ;
- onGameResize exécuté ;
- onLoad exécuté ;
- hook mapEnter interne exercé.

Level 2/3 contrôlé :
- assertions sur SaveData ;
- assertions sur RuntimeMapBundle ;
- assertions sur gameStateSnapshot ;
- projection via isNpcRuntimePresentOnMap.
```

Non revendiqué :

```text
UI complète.
Input joueur complet.
Combat complet.
Host app entier.
GameWidget interactif.
```

## 8. Ce qui est prouvé

P3-07 prouve que :

- le host peut charger une fixture narrative disque ;
- le host peut charger une save de lancement ;
- `RuntimeMapBundle` transporte bien les scenarios dans le contexte host ;
- `PlayableMapGame` accepte le bundle + save ;
- `PlayableMapGame.onLoad()` déclenche un scenario `sourceMapEnter` ;
- le scenario mutile l'état runtime visible via `gameStateSnapshot` ;
- une projection passive devient vraie après cette mutation ;
- le smoke reste non-Selbrume et sans UI.

## 9. Ce qui n’est pas prouvé

P3-07 ne prouve pas :

- input joueur complet ;
- interaction entity/trigger dans `PlayableMapGame` ;
- host app complet avec `GameWidget` et sélection projet ;
- vrai combat complet ;
- `_onBattleFinished` complet dans host ;
- save slot UX ;
- dialogue Yarn réel ;
- Scene Builder ;
- Cinematic Builder ;
- Selbrume final ;
- rewards, money, XP, level-up.

## 10. Gaps restants pour P3-CHECKPOINT

À trancher au checkpoint :

- Phase 3 a-t-elle assez de preuves Level 4 partielles pour passer Phase 4 ?
- Le smoke P3-07 suffit-il comme preuve host minimale malgré l'absence de
  GameWidget/input complet ?
- Les hooks entity/trigger/outcome restent-ils acceptés comme prouvés par
  executor + code path, ou faut-il un futur smoke Flame dédié ?
- Le test `runtime_launch_save_test.dart` avait un import legacy cassé ; P3-07
  l'a corrigé, mais le checkpoint doit noter cette dette de propreté historique.

## 11. Tests exécutés

Test ciblé :

```text
cd examples/playable_runtime_host && flutter test test/p3_narrative_smoke_slice_test.dart
```

Régressions :

```text
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
cd examples/playable_runtime_host && flutter test test/runtime_launch_save_test.dart
cd packages/map_runtime && flutter test test/p3_save_load_narrative_state_roundtrip_test.dart
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
```

Format :

```text
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/p3_narrative_smoke_slice_test.dart
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/runtime_launch_save_test.dart test/p3_narrative_smoke_slice_test.dart
```

Note debugging :

- première tentative `await game.onLoad()` sans `onGameResize` : échec Flame
  `hasLayout`;
- root cause : `PlayableMapGame._configureCameraViewport` a besoin d'une taille ;
- fix test : `game.onGameResize(Vector2(320, 240))` avant `onLoad()`.

## 12. Modifications effectuées

Fichiers créés :

```text
examples/playable_runtime_host/p3_narrative_smoke_slice/README.md
examples/playable_runtime_host/p3_narrative_smoke_slice/project.json
examples/playable_runtime_host/p3_narrative_smoke_slice/runtime_host_launch_save.json
examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json
examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
reports/roadmap/phase_3/p3_07_playable_runtime_host_narrative_smoke_test.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_3.md
examples/playable_runtime_host/test/runtime_launch_save_test.dart
```

Code de production modifié :

```text
Aucun.
```

## 13. Evidence Pack

### 13.1 git status initial exact

```text

```

### 13.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md
reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md
reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md
examples/playable_runtime_host/lib/main.dart
examples/playable_runtime_host/lib/src/runtime_launch_save.dart
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
examples/playable_runtime_host/test/runtime_launch_save_test.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
```

### 13.3 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,820p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,360p' reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md
sed -n '1,360p' examples/playable_runtime_host/lib/main.dart
sed -n '1,220p' examples/playable_runtime_host/lib/src/runtime_launch_save.dart
sed -n '1,220p' examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
sed -n '1,220p' examples/playable_runtime_host/test/runtime_launch_save_test.dart
sed -n '1,360p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
rg -n "PlayableMapGame|loadRuntimeMapBundle|runtime_host_launch_save|loadRuntimeHostLaunchSaveData|GameWidget|saveData|projectFilePath|manifest.scenarios|_dispatchScenarioRuntimeSource|mapEnter|triggerEnter|entityInteract|outcomeReceived" examples/playable_runtime_host packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/p3_narrative_smoke_slice_test.dart
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/p3_narrative_smoke_slice_test.dart && flutter test test/p3_narrative_smoke_slice_test.dart
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/runtime_launch_save_test.dart test/p3_narrative_smoke_slice_test.dart && flutter test test/runtime_launch_save_test.dart && flutter test test/phase_a_golden_slice_launch_test.dart
cd packages/map_runtime && flutter test test/p3_save_load_narrative_state_roundtrip_test.dart && flutter test test/p3_fact_world_rule_projection_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 13.4 Sorties utiles

`PlayableMapGame` :

```text
constructor: RuntimeMapBundle + projectFilePath + SaveData?
public: gameStateSnapshot
onLoad: dispatch ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId)
```

`runtime_launch_save.dart` :

```text
loadRuntimeHostLaunchSaveData(projectFilePath)
loads runtime_host_launch_save.json adjacent to project.json
returns SaveData.normalized()
```

### 13.5 Contenu complet des fixtures créées ou modifiées

`examples/playable_runtime_host/p3_narrative_smoke_slice/README.md`

```md
# P3 Narrative Smoke Slice

Technical non-Selbrume fixture for P3-07.

It proves that the playable runtime host can load:

- a real `project.json`;
- a real map JSON;
- a real `runtime_host_launch_save.json`;
- a `ScenarioAsset` embedded in the manifest;
- a minimal `PlayableMapGame` path that dispatches map enter on load.

It does not create Selbrume, UI, rewards, money, XP, level-up, Scene Builder, or
Cinematic Builder content.
```

`examples/playable_runtime_host/p3_narrative_smoke_slice/project.json`

```json
{
  "name": "P3 Narrative Smoke Slice",
  "version": "v1",
  "maps": [
    {
      "id": "p3_narrative_smoke_map",
      "name": "P3 Narrative Smoke Map",
      "relativePath": "maps/p3_narrative_smoke_field.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "scenarios": [
    {
      "id": "p3_narrative_smoke_scenario",
      "name": "P3 Narrative Smoke Scenario",
      "description": "Technical fixture proving PlayableMapGame can dispatch a mapEnter scenario from host-loaded disk data.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_smoke_start",
      "nodes": [
        {
          "id": "p3_smoke_start",
          "type": "start"
        },
        {
          "id": "p3_smoke_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceMapEnter"
          },
          "binding": {
            "mapId": "p3_narrative_smoke_map"
          }
        },
        {
          "id": "p3_smoke_set_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.smoke.flag.visible"
          }
        },
        {
          "id": "p3_smoke_complete_step",
          "type": "action",
          "payload": {
            "actionKind": "completeStep",
            "params": {
              "stepId": "p3.smoke.step.completed"
            }
          }
        },
        {
          "id": "p3_smoke_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_smoke_edge_start_source",
          "fromNodeId": "p3_smoke_start",
          "toNodeId": "p3_smoke_source"
        },
        {
          "id": "p3_smoke_edge_source_flag",
          "fromNodeId": "p3_smoke_source",
          "toNodeId": "p3_smoke_set_flag"
        },
        {
          "id": "p3_smoke_edge_flag_step",
          "fromNodeId": "p3_smoke_set_flag",
          "toNodeId": "p3_smoke_complete_step"
        },
        {
          "id": "p3_smoke_edge_step_end",
          "fromNodeId": "p3_smoke_complete_step",
          "toNodeId": "p3_smoke_end"
        }
      ],
      "metadata": {
        "phase": "P3-07"
      }
    }
  ]
}
```

`examples/playable_runtime_host/p3_narrative_smoke_slice/runtime_host_launch_save.json`

```json
{
  "saveId": "p3_narrative_smoke_save",
  "currentMapId": "p3_narrative_smoke_map",
  "playerPosition": {
    "x": 1,
    "y": 1
  },
  "playerFacing": "east",
  "progression": {
    "storyFlags": [
      "p3.smoke.launch.flag"
    ],
    "completedStepIds": [],
    "completedCutsceneIds": []
  },
  "trainerProfile": {
    "name": "P3 Smoke Tester"
  }
}
```

`examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json`

```json
{
  "id": "p3_narrative_smoke_map",
  "name": "P3 Narrative Smoke Map",
  "size": {
    "width": 4,
    "height": 4
  },
  "version": "v1",
  "mapMetadata": {
    "defaultSpawnId": "p3_smoke_spawn"
  },
  "entities": [
    {
      "id": "p3_smoke_spawn",
      "name": "P3 Smoke Spawn",
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
      "id": "p3_smoke_npc",
      "name": "P3 Smoke NPC",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Smoke NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "storyFlagSet",
            "refId": "p3.smoke.flag.visible"
          }
        }
      }
    }
  ]
}
```

### 13.6 Contenu complet du test créé

```dart
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('P3 narrative smoke slice loads host data and PlayableMapGame dispatches mapEnter',
      () async {
    final projectFilePath = p.join(
      Directory.current.path,
      'p3_narrative_smoke_slice',
      'project.json',
    );

    final launchSave = await loadRuntimeHostLaunchSaveData(
      projectFilePath: projectFilePath,
    );

    expect(launchSave, isNotNull);
    expect(launchSave!.currentMapId, _mapId);
    expect(launchSave.progression.storyFlags, contains(_launchFlag));

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: launchSave.currentMapId,
    );

    expect(bundle.map.id, _mapId);
    expect(bundle.manifest.scenarios.map((scenario) => scenario.id),
        contains(_scenarioId));

    final launchState = gameStateFromSaveData(launchSave);
    expect(launchState.storyFlags.activeFlags, contains(_launchFlag));
    expect(_isSmokeNpcVisible(bundle, launchState), isFalse);

    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: projectFilePath,
      saveData: launchSave,
    );

    expect(game.saveLoadInfo.mapId, _mapId);
    expect(game.gameStateSnapshot.storyFlags.activeFlags, contains(_launchFlag));
    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      isNot(contains(_scenarioFlag)),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    game.update(0);

    final loadedState = game.gameStateSnapshot;
    expect(loadedState.currentMapId, _mapId);
    expect(loadedState.storyFlags.activeFlags, contains(_launchFlag));
    expect(loadedState.storyFlags.activeFlags, contains(_scenarioFlag));
    expect(loadedState.progression.completedStepIds, contains(_scenarioStep));
    expect(_isSmokeNpcVisible(bundle, loadedState), isTrue);
  });
}

const _mapId = 'p3_narrative_smoke_map';
const _scenarioId = 'p3_narrative_smoke_scenario';
const _launchFlag = 'p3.smoke.launch.flag';
const _scenarioFlag = 'p3.smoke.flag.visible';
const _scenarioStep = 'p3.smoke.step.completed';

bool _isSmokeNpcVisible(RuntimeMapBundle bundle, GameState state) {
  final entity = bundle.map.entities.singleWhere(
    (candidate) => candidate.id == 'p3_smoke_npc',
  );
  return isNpcRuntimePresentOnMap(
    gameState: state,
    manifest: bundle.manifest,
    stepStudioWorldRules: const [],
    mapId: _mapId,
    entity: entity,
  );
}
```

### 13.7 Diff du test existant modifié

```diff
-import 'package:PokeMap_Loader/src/runtime_launch_save.dart';
+import 'package:pokemap_loader/src/runtime_launch_save.dart';
```

### 13.8 Sortie complète du test ciblé

```text
Formatted 1 file (0 changed) in 0.00 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
00:00 +0: P3 narrative smoke slice loads host data and PlayableMapGame dispatches mapEnter
[runtime] Map loaded: p3_narrative_smoke_map, spawn at (1, 1)
[step_studio_trace] npc_mount_skipped map=p3_narrative_smoke_map entity=p3_smoke_npc reason=presence_predicate_false
[step_studio_trace] npc_presence_applied map=p3_narrative_smoke_map entity=p3_smoke_npc present=false
[runtime] local scenario "p3_narrative_smoke_scenario" marked completed (predicate cutsceneCompleted).
[step_studio_trace] completion_applied scenario=p3_narrative_smoke_scenario origin=dispatch:mapEnter completedSteps=[p3.smoke.step.completed] completedCutscenes=[p3_narrative_smoke_scenario]
[scenario_runtime] source=mapEnter map=p3_narrative_smoke_map trigger=- entity=- status=reachedEnd scenario=p3_narrative_smoke_scenario sourceNode=p3_smoke_source stopNode=p3_smoke_end message=Flow terminé sur End.
00:00 +1: All tests passed!
```

### 13.9 Sortie complète des régressions ciblées

```text
Formatted 2 files (0 changed) in 0.00 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_launch_save_test.dart
00:00 +0: loadRuntimeHostLaunchSaveData returns null when no versioned launch save is present
00:00 +1: loadRuntimeHostLaunchSaveData loads a versioned launch save adjacent to project.json
00:00 +2: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
00:00 +0: the versioned Phase A golden slice exposes a real launch save
00:00 +1: All tests passed!
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart
00:00 +0: P3 save/load narrative state roundtrip persists narrative truths and projections after reload
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_ObKVJj/pokemonProject/game_save.json completedStepIds=[p3.step.visible, p3.chapter.step.a, p3.chapter.step.b, p3.world_presence.step.visible]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_ObKVJj/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_ObKVJj/pokemonProject/game_save.json completedStepIds=[p3.step.visible, p3.chapter.step.a, p3.chapter.step.b, p3.world_presence.step.visible]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_ObKVJj/pokemonProject/game_save.json
00:00 +1: P3 save/load narrative state roundtrip keeps projections false or fallback after a negative reload
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_T5JO3s/pokemonProject/game_save.json completedStepIds=[p3.step.wrong, p3.chapter.step.a, p3.world_presence.wrong]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_T5JO3s/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_T5JO3s/pokemonProject/game_save.json completedStepIds=[p3.step.wrong, p3.chapter.step.a, p3.world_presence.wrong]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-Gm6Wdz/p3_save_load_narrative_T5JO3s/pokemonProject/game_save.json
00:00 +2: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
00:00 +0: P3 fact and world rule runtime projection loads the disk fixture and projects NPC visibility from truths
00:00 +1: P3 fact and world rule runtime projection resolves conditional dialogues from existing predicates passively
00:00 +2: All tests passed!
```

### 13.10 Échec initial documenté

```text
Failed assertion: 'hasLayout': "size" is not ready yet.
Root cause: onLoad direct sans onGameResize avant _configureCameraViewport.
Fix test: game.onGameResize(Vector2(320, 240)) avant await game.onLoad().
```

### 13.11 git diff --check exact

```text

```

### 13.12 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_3.md                   | 60 +++++++++++++++++++---
 .../test/runtime_launch_save_test.dart             |  2 +-
 2 files changed, 54 insertions(+), 8 deletions(-)
```

### 13.13 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_3.md
examples/playable_runtime_host/test/runtime_launch_save_test.dart
```

### 13.14 git status final exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
 M examples/playable_runtime_host/test/runtime_launch_save_test.dart
?? examples/playable_runtime_host/p3_narrative_smoke_slice/README.md
?? examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json
?? examples/playable_runtime_host/p3_narrative_smoke_slice/project.json
?? examples/playable_runtime_host/p3_narrative_smoke_slice/runtime_host_launch_save.json
?? examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
?? reports/roadmap/phase_3/p3_07_playable_runtime_host_narrative_smoke_test.md
```

### 13.15 Contrôles no-index / hors scope

```text
road_map_global diff : sortie vide.
production scope diff packages/map_core packages/map_runtime/lib packages/map_editor packages/map_gameplay packages/map_battle : sortie vide.
git diff --no-index --check sur rapport/test/fixture P3-07 : sorties vides.
find reports/roadmap/phase_3 -maxdepth 1 \( -name '*checkpoint*' -o -name '*CHECKPOINT*' \) -type f | sort : sortie vide.
```

### 13.16 Contrôles explicites

```text
road_map_global.md n'a pas été modifié.
P3-CHECKPOINT-01 n'a pas été exécuté.
Selbrume final n'a pas été créé.
Aucun reward/money/XP n'a été ajouté.
Aucune UI premium n'a été créée.
Aucun FactRegistry / WorldRuleRegistry n'a été créé.
```

## 14. Auto-review critique

- Le lot a-t-il produit une preuve exécutable ? Oui.
- Le vrai `project.json` host est-il chargé ? Oui.
- La launch save host est-elle chargée ? Oui.
- Le bundle contient-il map + scenario ? Oui.
- `PlayableMapGame` est-il instancié ? Oui.
- `PlayableMapGame.onLoad()` est-il exercé ? Oui, après sizing explicite.
- Une projection narrative est-elle vérifiée ? Oui.
- Le niveau de preuve est-il honnête ? Oui : Level 4/3 partiel, pas host UI
  complet.
- Le rapport P3-07 existe-t-il ? Oui.
- La roadmap Phase 3 est-elle mise à jour ? Oui.
- `road_map_global.md` est-elle intacte ? Oui.
- P3-CHECKPOINT-01 n'a-t-il pas été exécuté ? Oui.
- Selbrume final n'a-t-il pas été créé ? Oui.
- Rewards/money/XP sont-ils restés hors scope ? Oui.

## 15. Regard critique sur le prompt

Le prompt force le bon équilibre : il demande une preuve proche du host sans
survendre une preuve UI complète. Le point délicat était `PlayableMapGame.onLoad`
hors `GameWidget` : il est testable si le test fournit explicitement une taille
Flame avec `onGameResize`. Le résultat est plus fort qu'un simple loader test,
mais reste honnêtement inférieur à un smoke end-to-end joueur complet.
