# P3-04 — Outcome / Battle Outcome Runtime Continuation Validation

## 1. Résumé exécutif

P3-04 a produit une preuve exécutable ciblée pour la continuation `Scenario
outcome` et pour la continuation minimale post-battle accessible sans lancer un
vrai combat complet.

Livrables créés :

- fixture technique non-Selbrume :
  `packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/` ;
- test ciblé :
  `packages/map_runtime/test/p3_outcome_battle_continuation_test.dart` ;
- rapport :
  `reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md`.

Preuves obtenues :

- un vrai `project.json` est chargé via `loadRuntimeMapBundle` ;
- les `ScenarioAsset` viennent de `RuntimeMapBundle.manifest.scenarios` ;
- `emitOutcome` pose bien `scenario.outcome.p3.outcome.continuation` ;
- `emitOutcome` déclenche déjà une continuation automatique
  `outcomeReceived` dans `ScenarioRuntimeExecutor` ;
- `outcomeReceived` explicite déclenche le scénario `sourceOutcome` attendu ;
- un `startTrainerBattle` chargé depuis disque produit un
  `ScenarioRuntimeEffectType.battle` avec `battleId`, `trainerId` et
  `npcEntityId` ;
- `battle:p3_battle_test:victory` et `battle:p3_battle_test:defeat` restent
  distincts de `scenario.outcome.*` ;
- une reprise post-battle minimale est prouvée via `dispatchContinuation` après
  pose explicite du flag battle outcome.

Limites volontaires :

- pas de preuve complète `PlayableMapGame._onBattleFinished` ;
- pas de vrai battle engine ;
- pas de rewards, money, XP ou level-up ;
- pas de save/load roundtrip ;
- pas de World Rules ;
- pas de host smoke test.

Prochain lot exact :

```text
P3-05 — Fact / World Rule Runtime Projection Validation
```

## 2. Scope du lot

Inclus :

- création d'une fixture disque technique non-Selbrume ;
- test ciblé `ScenarioRuntimeExecutor` + `loadRuntimeMapBundle` ;
- validation `emitOutcome -> scenario.outcome.*` ;
- validation `sourceOutcome / outcomeReceived` explicite ;
- validation de la continuation automatique `emitOutcome -> outcomeReceived`
  déjà supportée par l'executor ;
- validation `startTrainerBattle -> ScenarioRuntimeEffect.battle` ;
- validation des noms de flags battle outcome `battle:<battleId>:victory` et
  `battle:<battleId>:defeat` ;
- validation d'une reprise minimale via `dispatchContinuation` ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md`.

Exclus :

- vrai combat complet ;
- moteur battle ;
- rewards, money, XP, level-up ;
- capture, flee ou static wild authoring ;
- save/load roundtrip ;
- World Rules ;
- UI ;
- Selbrume ;
- smoke test host complet ;
- modification `map_core`, `map_editor`, `map_gameplay`, `map_battle`.

## 3. Sources lues

Fichiers de gouvernance et rapports :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md`
- `reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md`
- `reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md`
- `reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md`

Code runtime et modèles inspectés :

- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Tests et fixtures relus :

- `packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart`
- `packages/map_runtime/test/p3_event_source_bridge_validation_test.dart`
- `packages/map_runtime/test/scenario_battle_from_scene_test.dart`
- `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart`
- `packages/map_runtime/test/scenario_runtime_executor_test.dart`
- `packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/`
- `packages/map_runtime/test/fixtures/p3_event_source_bridge/`

## 4. Fixture créée ou modifiée

Fixture créée :

```text
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/
├── README.md
├── maps/
│   └── p3_outcome_battle_field.json
└── project.json
```

La fixture est strictement technique et non-Selbrume. Elle contient :

- une map `p3_outcome_battle_map` ;
- un NPC `p3_battle_npc` ;
- un trainer minimal `p3_trainer_test` ;
- un scenario emitter `p3_scenario_outcome_emitter` ;
- un scenario receiver `p3_scenario_outcome_receiver` ;
- un scenario battle starter `p3_battle_starter_scenario`.

IDs clés :

```text
outcome id : p3.outcome.continuation
battle id : p3_battle_test
trainer id : p3_trainer_test
scenario outcome flag : scenario.outcome.p3.outcome.continuation
battle victory flag : battle:p3_battle_test:victory
battle defeat flag : battle:p3_battle_test:defeat
```

## 5. Scenario outcome continuation

Le scenario `p3_scenario_outcome_emitter` est déclenché par :

```dart
ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_outcome_battle_map')
```

Il exécute :

```text
sourceMapEnter
-> setFlag p3.outcome.emitted
-> emitOutcome p3.outcome.continuation
-> end
```

Le test vérifie que :

- `scenarioOutcomeFlagName('p3.outcome.continuation')` est présent dans
  `GameState.storyFlags.activeFlags` ;
- `p3.outcome.emitted` est posé ;
- `ScenarioRuntimeExecutionResult.emittedOutcomeId` vaut
  `p3.outcome.continuation`.

L'audit du code a confirmé que `ScenarioRuntimeExecutor` ne se limite pas à
poser le flag : il déclenche déjà un dispatch global
`ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId: outcomeId)` après
`emitOutcome`. Cette continuation automatique est donc prouvée par le test :
le résultat final revient du scenario receiver.

## 6. Battle outcome continuation

Le scenario `p3_battle_starter_scenario` est déclenché par :

```dart
ScenarioRuntimeSourceEvent.entityInteract(
  mapId: 'p3_outcome_battle_map',
  entityId: 'p3_battle_npc',
)
```

Il exécute :

```text
sourceEntityInteract
-> startTrainerBattle battleId=p3_battle_test trainerId=p3_trainer_test
-> condition battle:p3_battle_test:victory
-> setFlag p3.battle.victory.continued
-> condition battle:p3_battle_test:defeat
-> setFlag p3.battle.defeat.continued
-> end
```

Le premier dispatch s'arrête volontairement au battle handoff et vérifie :

- `ScenarioRuntimeExecutionStatus.executedEffect` ;
- `ScenarioRuntimeEffectType.battle` ;
- `effect.battleId == p3_battle_test` ;
- `effect.trainerId == p3_trainer_test` ;
- `effect.npcEntityId == p3_battle_npc`.

La continuation post-battle est testée avec l'API existante :

```dart
ScenarioRuntimeExecutor().dispatchContinuation(...)
```

Le test pose explicitement soit `battle:p3_battle_test:victory`, soit
`battle:p3_battle_test:defeat`, puis reprend après `p3_battle_node`. Cela prouve
que le graphe existant sait continuer sur la branche victory ou defeat quand le
flag battle outcome est présent.

Limite importante : la pose automatique de ces flags par
`PlayableMapGame._onBattleFinished` existe dans du code privé, mais P3-04 ne la
teste pas directement pour éviter un refactor public opportuniste. La preuve
complète Flame/host reste reportée.

## 7. Séparation scenario outcome / battle outcome

Le test vérifie explicitement :

```text
scenario.outcome.p3.outcome.continuation
battle:p3_battle_test:victory
battle:p3_battle_test:defeat
```

Les flags battle ne commencent pas par `scenario.outcome.` et le flag scenario
outcome n'est égal à aucun flag battle.

La séparation de contrat reste donc :

```text
Scenario outcome : scenario.outcome.<outcomeId>
Battle outcome : battle:<battleId>:<suffix>
```

P3-04 ne transforme pas battle outcome en scenario outcome et ne crée pas de
flag commun.

## 8. Cas positifs

Cas positifs couverts :

- chargement d'un vrai `project.json` via `loadRuntimeMapBundle` ;
- présence des scenarios P3-04 dans `RuntimeMapBundle.manifest.scenarios` ;
- `mapEnter` déclenche le scenario emitter ;
- `emitOutcome` pose le flag `scenario.outcome.p3.outcome.continuation` ;
- `emitOutcome` rejoint automatiquement le receiver `sourceOutcome` ;
- `outcomeReceived` explicite déclenche le scenario receiver ;
- `entityInteract` déclenche le scenario battle starter ;
- `startTrainerBattle` retourne un effet battle avec les IDs attendus ;
- `dispatchContinuation` continue la branche victory ;
- `dispatchContinuation` continue la branche defeat.

## 9. Cas négatifs

Cas négatifs couverts :

- `outcomeReceived` avec `p3.outcome.unknown` retourne
  `ScenarioRuntimeExecutionStatus.noMatchingSource` et ne pose aucun flag ;
- la continuation victory ne pose pas `p3.battle.defeat.continued` ;
- la continuation defeat ne pose pas `p3.battle.victory.continued` ;
- les flags `battle:*` ne ressemblent pas à `scenario.outcome.*` ;
- le flag `scenario.outcome.*` n'est pas confondu avec victory ou defeat.

Cas non couvert volontairement :

- mauvais `battleId` dans une reprise automatique PlayableMapGame, car
  `_onBattleFinished` est privé et ce lot ne crée pas d'API publique de test.

## 10. Niveau de preuve obtenu

Niveau obtenu :

```text
Level 4 partiel :
- vrai project.json de fixture disque ;
- scenarios embedded chargés via loadRuntimeMapBundle ;
- RuntimeMapBundle.manifest.scenarios utilisé par le test.

Level 2/3 contrôlé :
- ScenarioRuntimeExecutor dispatch ;
- ScenarioRuntimeEffect.battle ;
- StoryFlagsManager ;
- dispatchContinuation.
```

Non revendiqué :

```text
Level 3 Flame complet :
- pas d'instanciation PlayableMapGame ;
- pas de test _onBattleFinished ;
- pas de host smoke.
```

## 11. Ce qui est prouvé

P3-04 prouve :

- `emitOutcome` écrit le flag `scenario.outcome.<outcomeId>` ;
- `emitOutcome` déclenche déjà une continuation automatique
  `outcomeReceived` quand un scenario `sourceOutcome` existe ;
- `outcomeReceived` explicite reste utilisable directement ;
- `startTrainerBattle` produit un effet battle minimal ;
- `battleId`, `trainerId` et `npcEntityId` sont transportés par l'effet battle ;
- les helpers battle outcome produisent `battle:<battleId>:victory` et
  `battle:<battleId>:defeat` ;
- les flags battle outcome restent séparés des flags scenario outcome ;
- une branche post-battle peut être reprise via `dispatchContinuation` si le
  flag battle outcome est présent.

## 12. Ce qui n’est pas prouvé

P3-04 ne prouve pas :

- l'exécution d'un vrai combat complet ;
- la pose automatique des flags battle outcome par un vrai résultat battle ;
- `PlayableMapGame._onBattleFinished` en test Flame ;
- le host jouable complet ;
- save/load roundtrip ;
- rewards, money, XP, level-up ;
- capture ou flee ;
- World Rules ;
- UI.

## 13. Gaps reportés à P3-05 / P3-06 / P3-07

P3-05 :

- validation runtime des projections Fact / World Rule ;
- lecture passive de vérités runtime sans écrire de Fact.

P3-06 :

- roundtrip save/load des flags `scenario.outcome.*` et `battle:*` ;
- conservation des états narratifs nécessaires.

P3-07 :

- preuve `PlayableMapGame` / host smoke ;
- vérification éventuelle du chemin privé `_onBattleFinished` dans un test
  Flame/host ciblé ;
- preuve end-to-end runtime plus proche du joueur.

Hors Phase 3 :

- rewards, money, XP, level-up ;
- static wild authoring ;
- capture/flee comme contrat narratif complet ;
- UI authoring.

## 14. Tests exécutés

Tests ciblés et regressions lancés :

```bash
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
```

Résultats utiles :

```text
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
00:00 +4: All tests passed!

cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
00:00 +2: All tests passed!

cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
00:00 +14: All tests passed!

cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
00:00 +9: All tests passed!

cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
00:00 +15: All tests passed!
```

Le premier cycle TDD a aussi vérifié deux états rouges :

- compilation rouge sur constante de prefix non exportée, corrigée côté test ;
- test rouge `Project file not found` avant création de la fixture, prouvant que
  le test chargeait bien un vrai fichier disque.

## 15. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/README.md
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/maps/p3_outcome_battle_field.json
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/project.json
packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_3.md
```

Fichiers de code de production modifiés :

```text
Aucun.
```

Packages hors `map_runtime/test` modifiés :

```text
Aucun.
```

## 16. Evidence Pack

### 16.1 git status initial exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? packages/map_runtime/test/fixtures/p3_event_source_bridge/README.md
?? packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
?? packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
?? packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
?? reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
```

Ces fichiers non trackés P3-03 étaient préexistants au démarrage de P3-04 et
n'ont pas été restaurés ni déplacés.

### 16.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
packages/map_runtime/test/scenario_battle_from_scene_test.dart
packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
packages/map_runtime/test/scenario_runtime_executor_test.dart
packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/
packages/map_runtime/test/fixtures/p3_event_source_bridge/
```

### 16.3 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,520p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,320p' reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
sed -n '1,360p' reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
sed -n '1,320p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '1,520p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,180p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
rg -n "emitOutcome|sourceOutcome|outcomeReceived|scenario.outcome|startTrainerBattle|ScenarioRuntimeEffectType.battle|battle:|trainer_defeated|dispatchContinuation|resume|battleOutcome|victory|defeat" packages/map_core packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 16.4 Sorties utiles des commandes

Sorties utiles de l'audit :

```text
scenario_runtime_executor.dart:
- kScenarioSourceOutcome = 'sourceOutcome'
- kScenarioActionEmitOutcome = 'emitOutcome'
- kScenarioActionStartTrainerBattle = 'startTrainerBattle'
- kScenarioOutcomeFlagPrefix = 'scenario.outcome.'
- dispatchContinuation(...) existe
- emitOutcome pose scenarioOutcomeFlagName(outcomeId)
- emitOutcome déclenche ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId: outcomeId)
- startTrainerBattle retourne ScenarioRuntimeEffectType.battle

scenario_battle_outcome_flags.dart:
- kBattleOutcomeFlagPrefix = 'battle:'
- kBattleOutcomeSuffixVictory = 'victory'
- kBattleOutcomeSuffixDefeat = 'defeat'
- scenarioBattleOutcomeFlagName(...) retourne battle:<battleId>:<suffix>

runtime_battle_outcome_apply.dart:
- applique trainer_defeated:<trainerId> pour une victoire trainer
- ne pose pas battle:<battleId>:victory/defeat

playable_map_game.dart:
- _onBattleFinished pose scenarioBattleOutcomeFlagName(...)
- _resumeScenarioAfterRuntimeSource appelle dispatchContinuation(...)
- ces méthodes restent privées et ne sont pas testées directement en P3-04
```

Sortie du premier test rouge utile :

```text
Failed to load ".../test/fixtures/p3_outcome_battle_continuation/project.json":
PathNotFoundException: Cannot open file
```

Sortie du test ciblé final :

```text
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
00:00 +4: All tests passed!
```

Sorties des regressions ciblées :

```text
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
00:00 +2: All tests passed!

cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
00:00 +14: All tests passed!

cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
00:00 +9: All tests passed!

cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
00:00 +15: All tests passed!
```

### 16.5 Fichiers créés

```text
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/README.md
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/maps/p3_outcome_battle_field.json
packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/project.json
packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
```

### 16.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_3.md
```

### 16.7 Contenu complet des fichiers de fixture créés

`packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/README.md`

```md
# P3 Outcome Battle Continuation Fixture

Technical non-Selbrume fixture for P3-04.

It proves:

- `emitOutcome` writes `scenario.outcome.<outcomeId>`.
- `sourceOutcome` / explicit `outcomeReceived` can continue a global scenario.
- `startTrainerBattle` returns a `ScenarioRuntimeEffectType.battle` handoff.
- `battle:<battleId>:victory` and `battle:<battleId>:defeat` stay separate from
  `scenario.outcome.*`.
- Post-battle continuation can be simulated through the existing
  `dispatchContinuation` API after setting the battle outcome flag.

It does not prove a full battle engine run, rewards, money, XP, save/load
roundtrip, World Rules, UI, PlayableMapGame hooks, or a host smoke test.
```

`packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/maps/p3_outcome_battle_field.json`

```json
{
  "id": "p3_outcome_battle_map",
  "name": "P3 Outcome Battle Map",
  "size": {
    "width": 4,
    "height": 4
  },
  "version": "v1",
  "entities": [
    {
      "id": "p3_outcome_battle_spawn",
      "name": "P3 Outcome Battle Spawn",
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
      "id": "p3_battle_npc",
      "name": "P3 Battle NPC",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 1
      },
      "npc": {
        "displayName": "P3 Battle NPC",
        "trainerId": "p3_trainer_test",
        "facing": "west"
      }
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "p3_outcome_battle_spawn"
  }
}
```

`packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/project.json`

```json
{
  "name": "P3 Outcome Battle Continuation",
  "version": "v1",
  "maps": [
    {
      "id": "p3_outcome_battle_map",
      "name": "P3 Outcome Battle Map",
      "relativePath": "maps/p3_outcome_battle_field.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "trainers": [
    {
      "id": "p3_trainer_test",
      "name": "P3 Test Trainer",
      "trainerClass": "Test Trainer",
      "battleDifficulty": 1,
      "team": [
        {
          "speciesId": "p3_test_mon",
          "level": 5,
          "moves": [
            "tackle"
          ]
        }
      ]
    }
  ],
  "scenarios": [
    {
      "id": "p3_scenario_outcome_emitter",
      "name": "P3 Scenario Outcome Emitter",
      "description": "Technical fixture proving emitOutcome from disk.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_outcome_emitter_start",
      "declaredOutcomes": [
        "p3.outcome.continuation"
      ],
      "nodes": [
        {
          "id": "p3_outcome_emitter_start",
          "type": "start"
        },
        {
          "id": "p3_outcome_emitter_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceMapEnter"
          },
          "binding": {
            "mapId": "p3_outcome_battle_map"
          }
        },
        {
          "id": "p3_outcome_emitter_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.outcome.emitted"
          }
        },
        {
          "id": "p3_outcome_emit",
          "type": "action",
          "payload": {
            "actionKind": "emitOutcome"
          },
          "binding": {
            "outcomeId": "p3.outcome.continuation"
          }
        },
        {
          "id": "p3_outcome_emitter_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_outcome_emitter_edge_start_source",
          "fromNodeId": "p3_outcome_emitter_start",
          "toNodeId": "p3_outcome_emitter_source"
        },
        {
          "id": "p3_outcome_emitter_edge_source_flag",
          "fromNodeId": "p3_outcome_emitter_source",
          "toNodeId": "p3_outcome_emitter_flag"
        },
        {
          "id": "p3_outcome_emitter_edge_flag_emit",
          "fromNodeId": "p3_outcome_emitter_flag",
          "toNodeId": "p3_outcome_emit"
        },
        {
          "id": "p3_outcome_emitter_edge_emit_end",
          "fromNodeId": "p3_outcome_emit",
          "toNodeId": "p3_outcome_emitter_end"
        }
      ],
      "metadata": {
        "phase": "P3-04"
      }
    },
    {
      "id": "p3_scenario_outcome_receiver",
      "name": "P3 Scenario Outcome Receiver",
      "description": "Technical fixture proving sourceOutcome / outcomeReceived continuation.",
      "scope": "globalStory",
      "entryNodeId": "p3_outcome_receiver_start",
      "nodes": [
        {
          "id": "p3_outcome_receiver_start",
          "type": "start"
        },
        {
          "id": "p3_outcome_receiver_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceOutcome"
          },
          "binding": {
            "outcomeId": "p3.outcome.continuation"
          }
        },
        {
          "id": "p3_outcome_receiver_flag",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.outcome.received"
          }
        },
        {
          "id": "p3_outcome_receiver_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_outcome_receiver_edge_start_source",
          "fromNodeId": "p3_outcome_receiver_start",
          "toNodeId": "p3_outcome_receiver_source"
        },
        {
          "id": "p3_outcome_receiver_edge_source_flag",
          "fromNodeId": "p3_outcome_receiver_source",
          "toNodeId": "p3_outcome_receiver_flag"
        },
        {
          "id": "p3_outcome_receiver_edge_flag_end",
          "fromNodeId": "p3_outcome_receiver_flag",
          "toNodeId": "p3_outcome_receiver_end"
        }
      ],
      "metadata": {
        "phase": "P3-04"
      }
    },
    {
      "id": "p3_battle_starter_scenario",
      "name": "P3 Battle Starter Scenario",
      "description": "Technical fixture proving startTrainerBattle and post-battle continuation flags.",
      "scope": "localEventFlow",
      "entryNodeId": "p3_battle_start",
      "nodes": [
        {
          "id": "p3_battle_start",
          "type": "start"
        },
        {
          "id": "p3_battle_source",
          "type": "reference",
          "payload": {
            "actionKind": "sourceEntityInteract"
          },
          "binding": {
            "mapId": "p3_outcome_battle_map",
            "entityId": "p3_battle_npc"
          }
        },
        {
          "id": "p3_battle_node",
          "type": "action",
          "payload": {
            "actionKind": "startTrainerBattle",
            "params": {
              "battleId": "p3_battle_test"
            }
          },
          "binding": {
            "trainerId": "p3_trainer_test",
            "entityId": "p3_battle_npc"
          }
        },
        {
          "id": "p3_check_battle_victory",
          "type": "condition",
          "payload": {
            "condition": {
              "type": "flagIsSet",
              "params": {
                "flagName": "battle:p3_battle_test:victory"
              }
            }
          }
        },
        {
          "id": "p3_battle_victory_continuation",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.battle.victory.continued"
          }
        },
        {
          "id": "p3_check_battle_defeat",
          "type": "condition",
          "payload": {
            "condition": {
              "type": "flagIsSet",
              "params": {
                "flagName": "battle:p3_battle_test:defeat"
              }
            }
          }
        },
        {
          "id": "p3_battle_defeat_continuation",
          "type": "action",
          "payload": {
            "actionKind": "setFlag"
          },
          "binding": {
            "flagName": "p3.battle.defeat.continued"
          }
        },
        {
          "id": "p3_battle_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_battle_edge_start_source",
          "fromNodeId": "p3_battle_start",
          "toNodeId": "p3_battle_source"
        },
        {
          "id": "p3_battle_edge_source_battle",
          "fromNodeId": "p3_battle_source",
          "toNodeId": "p3_battle_node"
        },
        {
          "id": "p3_battle_edge_battle_check_victory",
          "fromNodeId": "p3_battle_node",
          "toNodeId": "p3_check_battle_victory"
        },
        {
          "id": "p3_battle_edge_victory_true",
          "fromNodeId": "p3_check_battle_victory",
          "toNodeId": "p3_battle_victory_continuation",
          "kind": "trueBranch"
        },
        {
          "id": "p3_battle_edge_victory_false",
          "fromNodeId": "p3_check_battle_victory",
          "toNodeId": "p3_check_battle_defeat",
          "kind": "falseBranch"
        },
        {
          "id": "p3_battle_edge_defeat_true",
          "fromNodeId": "p3_check_battle_defeat",
          "toNodeId": "p3_battle_defeat_continuation",
          "kind": "trueBranch"
        },
        {
          "id": "p3_battle_edge_defeat_false",
          "fromNodeId": "p3_check_battle_defeat",
          "toNodeId": "p3_battle_end",
          "kind": "falseBranch"
        },
        {
          "id": "p3_battle_edge_victory_end",
          "fromNodeId": "p3_battle_victory_continuation",
          "toNodeId": "p3_battle_end"
        },
        {
          "id": "p3_battle_edge_defeat_end",
          "fromNodeId": "p3_battle_defeat_continuation",
          "toNodeId": "p3_battle_end"
        }
      ],
      "metadata": {
        "phase": "P3-04"
      }
    }
  ]
}
```

### 16.8 Contenu complet du test créé

`packages/map_runtime/test/p3_outcome_battle_continuation_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 outcome and battle outcome continuation', () {
    test('emits a scenario outcome and reaches a sourceOutcome continuation',
        () async {
      final bundle = await _loadBundle();

      expect(
        bundle.manifest.scenarios.map((scenario) => scenario.id),
        containsAll(<String>[
          _outcomeEmitterScenarioId,
          _outcomeReceiverScenarioId,
        ]),
      );

      final dispatch = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.mapEnter(mapId: _mapId),
      );

      expect(dispatch.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(dispatch.result.emittedOutcomeId, _outcomeId);
      expect(dispatch.result.scenarioId, _outcomeReceiverScenarioId);
      expect(dispatch.result.sourceNodeId, 'p3_outcome_receiver_source');
      expect(
        dispatch.state.storyFlags.activeFlags,
        contains(scenarioOutcomeFlagName(_outcomeId)),
      );
      expect(
        dispatch.state.storyFlags.activeFlags,
        contains('p3.outcome.emitted'),
      );
      expect(
        dispatch.state.storyFlags.activeFlags,
        contains('p3.outcome.received'),
      );
    });

    test('dispatches explicit outcomeReceived and ignores unknown outcomes',
        () async {
      final bundle = await _loadBundle();

      final explicit = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId: _outcomeId),
      );

      expect(explicit.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(explicit.result.scenarioId, _outcomeReceiverScenarioId);
      expect(
        explicit.state.storyFlags.activeFlags,
        contains('p3.outcome.received'),
      );
      expect(
        explicit.state.storyFlags.activeFlags,
        isNot(contains(scenarioOutcomeFlagName(_outcomeId))),
      );

      final unknown = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'p3.outcome.unknown',
        ),
      );

      expect(unknown.result.status,
          ScenarioRuntimeExecutionStatus.noMatchingSource);
      expect(unknown.state.storyFlags.activeFlags, isEmpty);
    });

    test('starts a trainer battle and exposes battle handoff data', () async {
      final bundle = await _loadBundle();

      final dispatch = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.entityInteract(
          mapId: _mapId,
          entityId: _npcEntityId,
        ),
      );

      expect(dispatch.result.status,
          ScenarioRuntimeExecutionStatus.executedEffect);
      expect(dispatch.result.scenarioId, _battleScenarioId);
      expect(dispatch.result.sourceNodeId, 'p3_battle_source');
      expect(dispatch.result.stopNodeId, 'p3_battle_node');
      expect(dispatch.result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(dispatch.result.effect.battleId, _battleId);
      expect(dispatch.result.effect.trainerId, _trainerId);
      expect(dispatch.result.effect.npcEntityId, _npcEntityId);
    });

    test('keeps battle outcome flags separate and resumes victory or defeat',
        () async {
      final bundle = await _loadBundle();
      final victoryFlag = scenarioBattleOutcomeFlagName(
        _battleId,
        kBattleOutcomeSuffixVictory,
      );
      final defeatFlag = scenarioBattleOutcomeFlagName(
        _battleId,
        kBattleOutcomeSuffixDefeat,
      );

      expect(victoryFlag, 'battle:p3_battle_test:victory');
      expect(defeatFlag, 'battle:p3_battle_test:defeat');
      expect(victoryFlag, isNot(startsWith('scenario.outcome.')));
      expect(defeatFlag, isNot(startsWith('scenario.outcome.')));
      expect(
        scenarioOutcomeFlagName(_outcomeId),
        isNot(anyOf(victoryFlag, defeatFlag)),
      );

      final victory =
          _continueAfterBattle(bundle, activeBattleFlag: victoryFlag);
      expect(victory.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
        victory.state.storyFlags.activeFlags,
        contains('p3.battle.victory.continued'),
      );
      expect(
        victory.state.storyFlags.activeFlags,
        isNot(contains('p3.battle.defeat.continued')),
      );

      final defeat = _continueAfterBattle(bundle, activeBattleFlag: defeatFlag);
      expect(defeat.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
        defeat.state.storyFlags.activeFlags,
        contains('p3.battle.defeat.continued'),
      );
      expect(
        defeat.state.storyFlags.activeFlags,
        isNot(contains('p3.battle.victory.continued')),
      );
    });
  });
}

const _mapId = 'p3_outcome_battle_map';
const _npcEntityId = 'p3_battle_npc';
const _trainerId = 'p3_trainer_test';
const _battleId = 'p3_battle_test';
const _outcomeId = 'p3.outcome.continuation';
const _outcomeEmitterScenarioId = 'p3_scenario_outcome_emitter';
const _outcomeReceiverScenarioId = 'p3_scenario_outcome_receiver';
const _battleScenarioId = 'p3_battle_starter_scenario';

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_outcome_battle_continuation',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

_DispatchProbe _dispatch(
  RuntimeMapBundle bundle,
  ScenarioRuntimeSourceEvent sourceEvent,
) {
  var state = const GameState(saveId: 'p3-outcome-battle-continuation');
  final result = const ScenarioRuntimeExecutor().dispatch(
    scenarios: bundle.manifest.scenarios,
    sourceEvent: sourceEvent,
    context: _context(
      state: state,
      onUpdate: (next) => state = next,
    ),
  );

  return _DispatchProbe(result: result, state: state);
}

_DispatchProbe _continueAfterBattle(
  RuntimeMapBundle bundle, {
  required String activeBattleFlag,
}) {
  var state = const StoryFlagsManager().set(
    const GameState(saveId: 'p3-outcome-battle-continuation'),
    activeBattleFlag,
  );
  final result = const ScenarioRuntimeExecutor().dispatchContinuation(
    scenarios: bundle.manifest.scenarios,
    scenarioId: _battleScenarioId,
    sourceNodeId: 'p3_battle_source',
    resumeAfterNodeId: 'p3_battle_node',
    context: _context(
      state: state,
      onUpdate: (next) => state = next,
    ),
  );

  return _DispatchProbe(result: result, state: state);
}

ScenarioRuntimeExecutionContext _context({
  required GameState state,
  required void Function(GameState) onUpdate,
}) {
  return ScenarioRuntimeExecutionContext(
    gameState: state,
    onGameStateUpdated: onUpdate,
    openDialogue: (_, {startNode, runtimeSourceId}) => false,
    runScript: (_, {startNode, runtimeSourceId}) => false,
    showMessage: (_) {},
  );
}

class _DispatchProbe {
  const _DispatchProbe({
    required this.result,
    required this.state,
  });

  final ScenarioRuntimeExecutionResult result;
  final GameState state;
}
```

### 16.9 Extraits des fichiers modifiés

`MVP Selbrume/road_map_phase_3.md`

Sections modifiées :

```text
Lot courant : P3-05 — Fact / World Rule Runtime Projection Validation
Prochain lot exact : P3-05 — Fact / World Rule Runtime Projection Validation

- ✅ P3-04 — Outcome / Battle Outcome Runtime Continuation Validation
- 🔜 P3-05 — Fact / World Rule Runtime Projection Validation

P3-04 : ✅ terminé
P3-05 : 🔜 prochain lot exact
```

La section P3-04 a été renseignée avec le résumé, les fichiers créés, les tests
exécutés, les limites de preuve et le prochain lot exact.

### 16.10 Sortie complète du test ciblé final

```text
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
00:00 +0: P3 outcome and battle outcome continuation emits a scenario outcome and reaches a sourceOutcome continuation
00:00 +1: P3 outcome and battle outcome continuation dispatches explicit outcomeReceived and ignores unknown outcomes
00:00 +2: P3 outcome and battle outcome continuation starts a trainer battle and exposes battle handoff data
00:00 +3: P3 outcome and battle outcome continuation keeps battle outcome flags separate and resumes victory or defeat
00:00 +4: All tests passed!
```

### 16.11 Sortie complète des regressions ciblées

```text
cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
00:00 +2: All tests passed!

cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
00:00 +14: All tests passed!

cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart
00:00 +9: All tests passed!

cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
00:00 +15: All tests passed!
```

### 16.12 git diff --check exact

```text

```

### 16.13 git diff --stat exact

```text

```

### 16.14 git diff --name-only exact

```text

```

### 16.15 git status final exact

```text
?? reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
```

Note : au contrôle final, les fichiers de fixture/test P3-04 et la roadmap Phase
3 sont présents dans l'état courant du repo mais ne sont plus listés par
`git status`; le seul fichier encore non suivi est le rapport P3-04.

### 16.16 Contrôles explicites

```text
road_map_global.md modifié : non
P3-05 exécuté : non
Selbrume final créé : non
reward/money/XP ajouté : non
code de production modifié : non
```

## 17. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui. Les changements sont limités à une fixture/test map_runtime ciblés, au
rapport P3-04 et à la roadmap Phase 3.
```

Le rapport P3-04 existe-t-il au bon chemin ?

```text
Oui.
```

road_map_phase_3.md a-t-elle été mise à jour ?

```text
Oui.
```

road_map_global.md est-elle restée intacte ?

```text
Oui, contrôle final documenté dans l'Evidence Pack.
```

Aucun code de production n'a-t-il été modifié ?

```text
Oui. Le code modifié est uniquement du test et de la fixture.
```

Le test ciblé passe-t-il ?

```text
Oui.
```

Les regressions ciblées pertinentes passent-elles ?

```text
Oui.
```

La séparation scenario outcome / battle outcome est-elle claire ?

```text
Oui. `scenario.outcome.*` et `battle:*` sont testés comme conventions
distinctes.
```

La relation automatique `emitOutcome -> outcomeReceived` est-elle clarifiée ?

```text
Oui. Elle existe dans `ScenarioRuntimeExecutor` et est prouvée par le test.
```

La preuve battle reste-t-elle bornée ?

```text
Oui. P3-04 prouve le handoff, les flags et la reprise via
`dispatchContinuation`, sans lancer de combat complet ni modifier
`PlayableMapGame`.
```

P3-05 n'a-t-il pas été exécuté ?

```text
Oui.
```

Selbrume final n'a-t-il pas été créé ?

```text
Oui.
```

Aucun reward/money/XP n'a-t-il été ajouté ?

```text
Oui.
```

Le prochain lot exact est-il clair ?

```text
Oui : P3-05 — Fact / World Rule Runtime Projection Validation.
```

## 18. Regard critique sur le prompt

Le prompt est très cadrant et sain : il force la séparation entre outcome
scenario, battle outcome, vrai battle engine et reprise runtime. Le point le
plus délicat est la demande de "battle outcome continuation" alors que la pose
réelle des flags battle outcome est encapsulée dans une méthode privée de
`PlayableMapGame`. La solution retenue évite le refactor opportuniste : elle
prouve le handoff, la convention de flags et la reprise `dispatchContinuation`
au niveau public existant, puis reporte la preuve Flame complète à P3-07.
