# P3-05 — Fact / World Rule Runtime Projection Validation

## 1. Résumé exécutif

P3-05 a produit une preuve exécutable ciblée que les vérités techniques
existantes peuvent être lues passivement par le runtime pour projeter le monde,
sans créer de `FactRegistry`, sans `WorldRuleRegistry` et sans nouvelle source
de vérité.

Livrables :

- fixture disque technique non-Selbrume :
  `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/` ;
- test ciblé :
  `packages/map_runtime/test/p3_fact_world_rule_projection_test.dart` ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md` ;
- rapport P3-05.

Preuves obtenues :

- vrai `project.json` chargé par `loadRuntimeMapBundle` ;
- `visibilityRule` lit `storyFlags` ;
- `visibilityRule` lit `completedStepIds` ;
- `visibilityRule` lit `completedCutsceneIds` ;
- `scenario.outcome.*` est lisible comme flag technique ;
- `battle:*` est lisible comme flag technique ;
- `chapterCompleted` est dérivé via metadata Global Story sans état stocké de
  chapitre ;
- Step Studio world presence lit les `completedStepIds` depuis une metadata
  `ScenarioAsset` ;
- `conditionalDialogues` choisit le dialogue via predicates existants ;
- les cas négatifs mauvais flag/step/cutscene/outcome/battle/chapter restent
  false ou fallback ;
- les évaluations ne mutent pas `GameState`.

Niveau de preuve :

```text
Level 4 partiel : vrai project.json + vraie map JSON chargés depuis disque.
Level 2/3 contrôlé : predicates/runtime projection sans PlayableMapGame complet.
```

Prochain lot exact :

```text
P3-06 — Save/Load Narrative State Roundtrip Validation
```

## 2. Scope du lot

Inclus :

- fixture disque technique ;
- test runtime/application ciblé ;
- `MapEntityRuntimePredicateEvaluator` ;
- `visibilityRule` ;
- `conditionalDialogues` ;
- `isNpcRuntimePresentOnMap` ;
- `buildStepStudioWorldPresenceRuleList` ;
- `buildGlobalStoryChapterStepIndex` ;
- roadmap Phase 3.

Exclus :

- `FactRegistry` ;
- `WorldRuleRegistry` ;
- modèle persistant ;
- modification `GameState` ;
- modification `ProjectManifest` ;
- modification `MapEntityRuntimePredicate` ;
- save/load roundtrip ;
- battle continuation ;
- reward, money, XP, level-up ;
- UI ;
- Selbrume ;
- P3-06.

## 3. Sources lues

Fichiers de gouvernance et rapports :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md`
- `reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md`
- `reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md`
- `reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md`

Code et tests inspectés :

- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `packages/map_runtime/lib/src/application/npc_runtime_presence.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/npc_runtime_presence_test.dart`
- `packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart`
- `packages/map_runtime/test/p3_outcome_battle_continuation_test.dart`
- `packages/map_runtime/test/p3_event_source_bridge_validation_test.dart`

## 4. Fixture créée ou modifiée

Fixture créée :

```text
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/
├── README.md
├── maps/
│   └── p3_fact_world_rule_field.json
└── project.json
```

La fixture contient :

- map `p3_fact_world_rule_map` ;
- entités NPC avec `visibilityRule` sur flag, step, cutscene, scenario outcome,
  battle outcome et chapter ;
- NPC de Step Studio world presence ;
- NPC de dialogues conditionnels ;
- scenario global `p3_fact_world_rule_global_story` avec metadata
  `authoring.stepStudioDocument` et `authoring.globalStoryStudioDocument`.

Elle ne contient pas de Selbrume, de save, de registry ou d'UI.

## 5. Projection par story flag

Entité :

```text
p3_flag_visible_npc
```

Predicate :

```text
kind = storyFlagSet
refId = p3.fact.flag.visible
```

Test :

- sans flag : invisible ;
- avec `p3.fact.flag.visible` : visible ;
- avec `p3.fact.flag.wrong` : invisible.

Source lue :

```text
GameState.storyFlags.activeFlags
```

## 6. Projection par completed step

Entité :

```text
p3_step_visible_npc
```

Predicate :

```text
kind = stepCompleted
refId = p3.step.visible
```

Test :

- sans completed step : invisible ;
- avec `p3.step.visible` : visible ;
- avec `p3.step.wrong` : invisible.

Source lue :

```text
GameState.progression.completedStepIds
```

## 7. Projection par completed cutscene

Entité :

```text
p3_cutscene_visible_npc
```

Predicate :

```text
kind = cutsceneCompleted
refId = p3.cutscene.visible
```

Test :

- sans completed cutscene : invisible ;
- avec `p3.cutscene.visible` : visible ;
- avec `p3.cutscene.wrong` : invisible.

Source lue :

```text
GameState.progression.completedCutsceneIds
```

## 8. Projection par scenario outcome

Entité :

```text
p3_outcome_visible_npc
```

Predicate :

```text
kind = storyFlagSet
refId = scenario.outcome.p3.outcome.visible
```

Test :

- sans flag outcome : invisible ;
- avec `scenario.outcome.p3.outcome.visible` : visible ;
- avec `scenario.outcome.p3.outcome.wrong` : invisible.

Interprétation :

`scenario.outcome.*` reste un flag technique lu comme tel. P3-05 ne le
transforme pas en Fact persistant.

## 9. Projection par battle outcome

Entité :

```text
p3_battle_visible_npc
```

Predicate :

```text
kind = storyFlagSet
refId = battle:p3_battle_projection:victory
```

Test :

- sans flag battle : invisible ;
- avec `battle:p3_battle_projection:victory` : visible ;
- avec `battle:p3_battle_projection:defeat` : invisible.

Interprétation :

`battle:*` reste un flag technique lu par `storyFlagSet`. P3-05 ne fusionne pas
battle outcome et scenario outcome.

## 10. Conditional dialogues

NPC :

```text
p3_conditional_dialogue_npc
```

Dialogues testés :

- fallback : `p3.default.dialogue` ;
- flag : `p3.flag.dialogue` ;
- step : `p3.step.dialogue` ;
- scenario outcome : `p3.outcome.dialogue` ;
- battle outcome : `p3.battle.dialogue`.

Le test vérifie aussi qu'un mauvais flag revient au fallback.

La résolution reste passive : elle choisit un `DialogueRef`, elle ne déclenche
pas de Scene et n'écrit pas dans `GameState`.

## 11. Step Studio / chapter world presence

Chapter :

- metadata lue : `authoring.globalStoryStudioDocument` ;
- chapter id : `p3.chapter.visible` ;
- steps requises : `p3.chapter.step.a`, `p3.chapter.step.b`.

Test :

- une seule step complétée : invisible ;
- mauvaise step : invisible ;
- les deux steps complétées : visible.

Step Studio world presence :

- metadata lue : `authoring.stepStudioDocument` ;
- step source : `p3.world_presence.step.visible` ;
- cible : `p3_world_presence_npc` ;
- rule : `visibleAfterStepCompletion`.

Test :

- sans step : absent ;
- mauvaise step : absent ;
- step source complétée : présent.

La combinaison passe par `isNpcRuntimePresentOnMap`, qui compose les predicates
NPC et les world changes Step Studio sans écrire d'état.

## 12. Niveau de preuve obtenu

```text
Level 4 partiel :
- vrai project.json ;
- vraie map JSON ;
- chargement via loadRuntimeMapBundle.

Level 2/3 contrôlé :
- MapEntityRuntimePredicateEvaluator ;
- GlobalStoryChapterStepIndex ;
- StepStudioWorldPresenceRule ;
- isNpcRuntimePresentOnMap ;
- conditional dialogues.
```

Non revendiqué :

```text
PlayableMapGame complet.
Host smoke.
Save/load roundtrip.
Authoring UI.
```

## 13. Ce qui est prouvé

P3-05 prouve que :

- les vérités techniques existantes sont lisibles au runtime ;
- les projections testées sont passives ;
- les mauvais identifiants ne déclenchent pas de projection ;
- `scenario.outcome.*` et `battle:*` sont lisibles comme flags techniques ;
- les chapters peuvent être dérivés des steps via metadata globale ;
- Step Studio world presence peut projeter la présence PNJ depuis metadata ;
- conditional dialogues peuvent varier selon les predicates existants ;
- aucune source de vérité nouvelle n'est créée.

## 14. Ce qui n’est pas prouvé

P3-05 ne prouve pas :

- `PlayableMapGame` complet ;
- host smoke ;
- save/load roundtrip ;
- authoring UI ;
- Fact Presentation Layer ;
- WorldRuleReadModel ;
- FactRegistry ;
- WorldRuleRegistry ;
- conflit multi-règles avancé ;
- projection des non-NPC par Step Studio world presence ;
- reward, money, XP, level-up.

## 15. Gaps reportés à P3-06 / P3-07 / Phase 4

P3-06 :

- roundtrip save/load des `storyFlags`, `completedStepIds`,
  `completedCutsceneIds`, `scenario.outcome.*` et `battle:*`.

P3-07 :

- preuve host / `PlayableMapGame` que ces projections affectent le monde
  visible dans le chemin runtime complet.

Phase 4 :

- intégration UI / pickers / authoring des Facts et World Rules ;
- diagnostics authoring avancés ;
- conflits world presence / visibility rule.

## 16. Tests exécutés

Commandes :

```bash
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && flutter test test/npc_runtime_presence_test.dart
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
```

Résultats :

```text
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
00:00 +2: All tests passed!

cd packages/map_runtime && dart format --set-exit-if-changed test/p3_fact_world_rule_projection_test.dart
Formatted 1 file (0 changed) in 0.01 seconds.

cd packages/map_runtime && flutter test test/npc_runtime_presence_test.dart
00:00 +5: All tests passed!

cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
00:00 +4: All tests passed!

cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
00:00 +2: All tests passed!
```

Cycle TDD :

- premier run rouge : compilation échouée à cause d'un mélange d'identités
  d'import relatif/package pour `StepStudioWorldPresenceRule` ;
- correction limitée aux imports du test ;
- second run rouge : `Project file not found`, attendu avant création fixture ;
- création fixture ;
- test vert.

## 17. Modifications effectuées

Fichiers créés :

```text
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_3.md
```

Code de production modifié :

```text
Aucun.
```

## 18. Evidence Pack

### 18.1 git status initial exact

```text

```

### 18.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_02_scenario_asset_runtime_execution_golden_path.md
reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md
reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/npc_runtime_presence.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/npc_runtime_presence_test.dart
packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart
packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
```

### 18.3 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,620p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,360p' reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md
sed -n '1,260p' reports/roadmap/phase_3/p3_04_bis_outcome_battle_evidence_status_reconciliation.md
rg -n "MapEntityRuntimePredicate|visibilityRule|conditionalDialogues|completedStepIds|completedCutsceneIds|storyFlags|scenario.outcome|battle:|StepStudioWorldPresence|world presence|chapter" packages/map_core packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,320p' packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart || true
sed -n '1,320p' packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart || true
sed -n '1,260p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,180p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,140p' packages/map_core/lib/src/models/map_entity_payloads.g.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/npc_runtime_presence.dart
sed -n '1,220p' packages/map_runtime/test/map_entity_runtime_predicate_evaluator_test.dart
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && dart format --set-exit-if-changed test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
cd packages/map_runtime && flutter test test/npc_runtime_presence_test.dart
cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 18.4 Sorties utiles

Audit runtime :

```text
MapEntityRuntimePredicateEvaluator:
- storyFlagSet lit GameState.storyFlags.activeFlags
- stepCompleted lit GameState.progression.completedStepIds
- cutsceneCompleted lit GameState.progression.completedCutsceneIds
- chapterCompleted lit GlobalStoryChapterStepIndex
- isNpcPresentOnMap évalue visibilityRule sans mutation
- resolveNpcDialogue retourne la première variante qui matche puis fallback

StepStudioWorldPresenceRuntime:
- lit metadata authoring.stepStudioDocument sur scenarios globalStory
- produit StepStudioWorldPresenceRule
- entityPassesStepStudioWorldPresence lit completedStepIds
- non-NPC retourne true

GlobalStoryChapterRuntime:
- lit metadata authoring.globalStoryStudioDocument
- chapterCompleted = toutes les stepIds du chapitre sont complétées
```

Run rouge utile :

```text
Project file not found
package:map_runtime/src/application/load_runtime_map_bundle.dart 34:5  loadProjectManifestFromFile
```

Test ciblé final :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
00:00 +0: P3 fact and world rule runtime projection loads the disk fixture and projects NPC visibility from truths
00:00 +1: P3 fact and world rule runtime projection resolves conditional dialogues from existing predicates passively
00:00 +2: All tests passed!
```

Régressions :

```text
packages/map_runtime/test/npc_runtime_presence_test.dart
00:00 +5: All tests passed!

packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
00:00 +4: All tests passed!

packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
00:00 +2: All tests passed!
```

### 18.5 Fichiers créés

```text
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json
packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md
```

### 18.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_3.md
```

### 18.7 Contenu complet des fichiers de fixture créés

`packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md`

```md
# P3 Fact World Rule Projection Fixture

Technical non-Selbrume fixture for P3-05.

It proves that existing runtime predicates can passively read technical truths:

- `storyFlags`
- `completedStepIds`
- `completedCutsceneIds`
- `scenario.outcome.*` as story flags
- `battle:*` as story flags
- chapter completion derived from Global Story metadata
- Step Studio world presence derived from ScenarioAsset metadata
- conditional dialogues resolved by existing predicates

It does not create a FactRegistry, WorldRuleRegistry, UI, save/load roundtrip,
reward model, money, XP, level-up, or Selbrume content.
```

`packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json`

```json
{
  "name": "P3 Fact World Rule Projection",
  "version": "v1",
  "maps": [
    {
      "id": "p3_fact_world_rule_map",
      "name": "P3 Fact World Rule Map",
      "relativePath": "maps/p3_fact_world_rule_field.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "dialogues": [
    {
      "id": "p3.default.dialogue",
      "name": "P3 Default Dialogue",
      "relativePath": "dialogues/p3_default.yarn"
    },
    {
      "id": "p3.flag.dialogue",
      "name": "P3 Flag Dialogue",
      "relativePath": "dialogues/p3_flag.yarn"
    },
    {
      "id": "p3.step.dialogue",
      "name": "P3 Step Dialogue",
      "relativePath": "dialogues/p3_step.yarn"
    },
    {
      "id": "p3.outcome.dialogue",
      "name": "P3 Outcome Dialogue",
      "relativePath": "dialogues/p3_outcome.yarn"
    },
    {
      "id": "p3.battle.dialogue",
      "name": "P3 Battle Dialogue",
      "relativePath": "dialogues/p3_battle.yarn"
    }
  ],
  "scenarios": [
    {
      "id": "p3_fact_world_rule_global_story",
      "name": "P3 Fact World Rule Global Story",
      "description": "Technical metadata fixture for P3-05 passive projection.",
      "scope": "globalStory",
      "entryNodeId": "p3_fact_world_rule_start",
      "nodes": [
        {
          "id": "p3_fact_world_rule_start",
          "type": "start"
        },
        {
          "id": "p3_fact_world_rule_end",
          "type": "end"
        }
      ],
      "edges": [
        {
          "id": "p3_fact_world_rule_edge_start_end",
          "fromNodeId": "p3_fact_world_rule_start",
          "toNodeId": "p3_fact_world_rule_end"
        }
      ],
      "metadata": {
        "authoring.stepStudioDocument": "{\"schemaVersion\":1,\"steps\":[{\"id\":\"p3.world_presence.step.visible\",\"worldChanges\":[{\"mapId\":\"p3_fact_world_rule_map\",\"entityId\":\"p3_world_presence_npc\",\"presenceRule\":\"visibleAfterStepCompletion\"}]}]}",
        "authoring.globalStoryStudioDocument": "{\"schemaVersion\":1,\"chapters\":[{\"id\":\"p3.chapter.visible\",\"stepIds\":[\"p3.chapter.step.a\",\"p3.chapter.step.b\"]}]}"
      }
    }
  ]
}
```

`packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json`

```json
{
  "id": "p3_fact_world_rule_map",
  "name": "P3 Fact World Rule Map",
  "size": {
    "width": 8,
    "height": 8
  },
  "version": "v1",
  "entities": [
    {
      "id": "p3_fact_world_rule_spawn",
      "name": "P3 Fact World Rule Spawn",
      "kind": "spawn",
      "pos": {
        "x": 0,
        "y": 0
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "south"
      }
    },
    {
      "id": "p3_flag_visible_npc",
      "name": "P3 Flag Visible NPC",
      "kind": "npc",
      "pos": {
        "x": 1,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Flag Visible NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "storyFlagSet",
            "refId": "p3.fact.flag.visible"
          }
        }
      }
    },
    {
      "id": "p3_step_visible_npc",
      "name": "P3 Step Visible NPC",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Step Visible NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "stepCompleted",
            "refId": "p3.step.visible"
          }
        }
      }
    },
    {
      "id": "p3_cutscene_visible_npc",
      "name": "P3 Cutscene Visible NPC",
      "kind": "npc",
      "pos": {
        "x": 3,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Cutscene Visible NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "cutsceneCompleted",
            "refId": "p3.cutscene.visible"
          }
        }
      }
    },
    {
      "id": "p3_outcome_visible_npc",
      "name": "P3 Outcome Visible NPC",
      "kind": "npc",
      "pos": {
        "x": 4,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Outcome Visible NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "storyFlagSet",
            "refId": "scenario.outcome.p3.outcome.visible"
          }
        }
      }
    },
    {
      "id": "p3_battle_visible_npc",
      "name": "P3 Battle Visible NPC",
      "kind": "npc",
      "pos": {
        "x": 5,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Battle Visible NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "storyFlagSet",
            "refId": "battle:p3_battle_projection:victory"
          }
        }
      }
    },
    {
      "id": "p3_chapter_visible_npc",
      "name": "P3 Chapter Visible NPC",
      "kind": "npc",
      "pos": {
        "x": 6,
        "y": 1
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Chapter Visible NPC",
        "visibilityRule": {
          "mode": "visibleWhen",
          "predicate": {
            "kind": "chapterCompleted",
            "refId": "p3.chapter.visible"
          }
        }
      }
    },
    {
      "id": "p3_world_presence_npc",
      "name": "P3 World Presence NPC",
      "kind": "npc",
      "pos": {
        "x": 1,
        "y": 3
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 World Presence NPC"
      }
    },
    {
      "id": "p3_conditional_dialogue_npc",
      "name": "P3 Conditional Dialogue NPC",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 3
      },
      "blocksMovement": false,
      "npc": {
        "displayName": "P3 Conditional Dialogue NPC",
        "dialogue": {
          "dialogueId": "p3.default.dialogue"
        },
        "conditionalDialogues": [
          {
            "when": {
              "kind": "storyFlagSet",
              "refId": "p3.fact.flag.visible"
            },
            "dialogue": {
              "dialogueId": "p3.flag.dialogue"
            }
          },
          {
            "when": {
              "kind": "stepCompleted",
              "refId": "p3.step.visible"
            },
            "dialogue": {
              "dialogueId": "p3.step.dialogue"
            }
          },
          {
            "when": {
              "kind": "storyFlagSet",
              "refId": "scenario.outcome.p3.outcome.visible"
            },
            "dialogue": {
              "dialogueId": "p3.outcome.dialogue"
            }
          },
          {
            "when": {
              "kind": "storyFlagSet",
              "refId": "battle:p3_battle_projection:victory"
            },
            "dialogue": {
              "dialogueId": "p3.battle.dialogue"
            }
          }
        ]
      }
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "p3_fact_world_rule_spawn"
  }
}
```

### 18.8 Contenu complet du test créé

`packages/map_runtime/test/p3_fact_world_rule_projection_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
import 'package:map_runtime/src/application/step_studio_world_presence_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 fact and world rule runtime projection', () {
    test('loads the disk fixture and projects NPC visibility from truths',
        () async {
      final bundle = await _loadBundle();
      final rules =
          buildStepStudioWorldPresenceRuleList(bundle.manifest.scenarios);

      expect(bundle.map.id, _mapId);
      expect(rules, hasLength(1));

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_flag_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(flags: {_flagVisible}),
        wrong: _state(flags: {'p3.fact.flag.wrong'}),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_step_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(completedSteps: [_stepVisible]),
        wrong: _state(completedSteps: ['p3.step.wrong']),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_cutscene_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(completedCutscenes: [_cutsceneVisible]),
        wrong: _state(completedCutscenes: ['p3.cutscene.wrong']),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_outcome_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(flags: {_scenarioOutcomeFlag}),
        wrong: _state(flags: {'scenario.outcome.p3.outcome.wrong'}),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_battle_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(flags: {_battleVictoryFlag}),
        wrong: _state(flags: {'battle:p3_battle_projection:defeat'}),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_chapter_visible_npc',
        inactive: _state(completedSteps: ['p3.chapter.step.a']),
        active: _state(completedSteps: [
          'p3.chapter.step.a',
          'p3.chapter.step.b',
        ]),
        wrong: _state(completedSteps: ['p3.chapter.step.wrong']),
      );

      _expectStepStudioPresence(
        bundle,
        rules: rules,
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(completedSteps: [_worldPresenceStep]),
        wrong: _state(completedSteps: ['p3.world_presence.wrong']),
      );
    });

    test('resolves conditional dialogues from existing predicates passively',
        () async {
      final bundle = await _loadBundle();
      final npc = _npc(bundle, 'p3_conditional_dialogue_npc').npc!;

      expect(_resolveDialogue(bundle, npc, const GameState(saveId: 'p3')),
          'p3.default.dialogue');
      expect(_resolveDialogue(bundle, npc, _state(flags: {_flagVisible})),
          'p3.flag.dialogue');
      expect(
          _resolveDialogue(bundle, npc, _state(completedSteps: [_stepVisible])),
          'p3.step.dialogue');
      expect(
          _resolveDialogue(bundle, npc, _state(flags: {_scenarioOutcomeFlag})),
          'p3.outcome.dialogue');
      expect(_resolveDialogue(bundle, npc, _state(flags: {_battleVictoryFlag})),
          'p3.battle.dialogue');
      expect(
          _resolveDialogue(bundle, npc, _state(flags: {'p3.fact.flag.wrong'})),
          'p3.default.dialogue');
    });
  });
}

const _mapId = 'p3_fact_world_rule_map';
const _flagVisible = 'p3.fact.flag.visible';
const _stepVisible = 'p3.step.visible';
const _cutsceneVisible = 'p3.cutscene.visible';
const _scenarioOutcomeFlag = 'scenario.outcome.p3.outcome.visible';
const _battleVictoryFlag = 'battle:p3_battle_projection:victory';
const _worldPresenceStep = 'p3.world_presence.step.visible';

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_fact_world_rule_projection',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

GameState _state({
  Set<String> flags = const {},
  List<String> completedSteps = const [],
  List<String> completedCutscenes = const [],
}) {
  return GameState(
    saveId: 'p3-fact-world-rule',
    storyFlags: StoryFlags(activeFlags: flags),
    progression: PlayerProgression(
      completedStepIds: completedSteps,
      completedCutsceneIds: completedCutscenes,
    ),
  );
}

void _expectVisibilityFlip(
  RuntimeMapBundle bundle, {
  required String entityId,
  required GameState inactive,
  required GameState active,
  required GameState wrong,
}) {
  final entity = _npc(bundle, entityId);
  final inactiveBefore = inactive.toJson();
  final activeBefore = active.toJson();
  final wrongBefore = wrong.toJson();

  expect(_isVisible(bundle, entity, inactive), isFalse);
  expect(_isVisible(bundle, entity, wrong), isFalse);
  expect(_isVisible(bundle, entity, active), isTrue);
  expect(inactive.toJson(), inactiveBefore);
  expect(active.toJson(), activeBefore);
  expect(wrong.toJson(), wrongBefore);
}

void _expectStepStudioPresence(
  RuntimeMapBundle bundle, {
  required List<StepStudioWorldPresenceRule> rules,
  required GameState inactive,
  required GameState active,
  required GameState wrong,
}) {
  final entity = _npc(bundle, 'p3_world_presence_npc');
  final inactiveBefore = inactive.toJson();
  final activeBefore = active.toJson();
  final wrongBefore = wrong.toJson();

  expect(
    isNpcRuntimePresentOnMap(
      gameState: inactive,
      manifest: bundle.manifest,
      stepStudioWorldRules: rules,
      mapId: _mapId,
      entity: entity,
    ),
    isFalse,
  );
  expect(
    isNpcRuntimePresentOnMap(
      gameState: wrong,
      manifest: bundle.manifest,
      stepStudioWorldRules: rules,
      mapId: _mapId,
      entity: entity,
    ),
    isFalse,
  );
  expect(
    isNpcRuntimePresentOnMap(
      gameState: active,
      manifest: bundle.manifest,
      stepStudioWorldRules: rules,
      mapId: _mapId,
      entity: entity,
    ),
    isTrue,
  );
  expect(inactive.toJson(), inactiveBefore);
  expect(active.toJson(), activeBefore);
  expect(wrong.toJson(), wrongBefore);
}

bool _isVisible(RuntimeMapBundle bundle, MapEntity entity, GameState state) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator.isNpcPresentOnMap(entity);
}

String? _resolveDialogue(
  RuntimeMapBundle bundle,
  MapEntityNpcData npc,
  GameState state,
) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator.resolveNpcDialogue(npc)?.dialogueId;
}

MapEntity _npc(RuntimeMapBundle bundle, String entityId) {
  return bundle.map.entities.singleWhere((entity) => entity.id == entityId);
}
```

### 18.9 Extraits des fichiers modifiés

`MVP Selbrume/road_map_phase_3.md` :

```text
Lot courant : P3-06 — Save/Load Narrative State Roundtrip Validation
Prochain lot exact : P3-06 — Save/Load Narrative State Roundtrip Validation

- ✅ P3-05 — Fact / World Rule Runtime Projection Validation
- 🔜 P3-06 — Save/Load Narrative State Roundtrip Validation

P3-05 : ✅ terminé
P3-06 : 🔜 prochain lot exact
```

### 18.10 Sortie complète du test ciblé

```text
cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
00:00 +0: P3 fact and world rule runtime projection loads the disk fixture and projects NPC visibility from truths
00:00 +1: P3 fact and world rule runtime projection resolves conditional dialogues from existing predicates passively
00:00 +2: All tests passed!
```

### 18.11 Sortie complète des régressions ciblées

```text
cd packages/map_runtime && flutter test test/npc_runtime_presence_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/npc_runtime_presence_test.dart
00:00 +0: isNpcRuntimePresentOnMap Emma présente avant complétion de la step (hiddenAfterStepCompletion)
00:00 +1: isNpcRuntimePresentOnMap Emma absente après complétion — cas produit (Bourivka / emma)
00:00 +2: isNpcRuntimePresentOnMap GameplayWorldState reconstruit : toujours absent avec même prédicat
00:00 +3: isNpcRuntimePresentOnMap après sérialisation GameState : completedStepIds conservés → absent
00:00 +4: isNpcRuntimePresentOnMap visibilité de base false : absent sans évaluer Step Studio
00:00 +5: All tests passed!

cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_outcome_battle_continuation_test.dart
00:00 +0: P3 outcome and battle outcome continuation emits a scenario outcome and reaches a sourceOutcome continuation
00:00 +1: P3 outcome and battle outcome continuation dispatches explicit outcomeReceived and ignores unknown outcomes
00:00 +2: P3 outcome and battle outcome continuation starts a trainer battle and exposes battle handoff data
00:00 +3: P3 outcome and battle outcome continuation keeps battle outcome flags separate and resumes victory or defeat
00:00 +4: All tests passed!

cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
00:00 +0: P3 event source bridge validation dispatches each runtime source to only its matching disk scenario
00:00 +1: P3 event source bridge validation does not dispatch runtime sources with mismatched identifiers
00:00 +2: All tests passed!
```

### 18.12 git diff --check exact

```text

```

### 18.13 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_3.md | 56 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 49 insertions(+), 7 deletions(-)
```

### 18.14 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_3.md
```

### 18.15 git status final exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/README.md
?? packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json
?? packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json
?? packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
?? reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md
```

### 18.16 Contrôles explicites

```text
road_map_global.md modifié : non
P3-06 exécuté : non
Selbrume final créé : non
FactRegistry créé : non
WorldRuleRegistry créé : non
save/load roundtrip ouvert : non
code de production modifié : non
```

## 19. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui : test/fixture map_runtime, rapport et roadmap Phase 3.
```

Le rapport P3-05 existe-t-il au bon chemin ?

```text
Oui.
```

road_map_phase_3.md a-t-elle été mise à jour ?

```text
Oui.
```

road_map_global.md est-elle restée intacte ?

```text
Contrôle final documenté dans l'Evidence Pack.
```

Aucun code de production n'a-t-il été modifié ?

```text
Contrôle final documenté dans l'Evidence Pack.
```

Aucun `FactRegistry` / `WorldRuleRegistry` n'a-t-il été créé ?

```text
Oui.
```

Les projections restent-elles passives ?

```text
Oui. Le test compare les JSON de `GameState` avant/après évaluation pour les
projections testées.
```

Le test ciblé passe-t-il ?

```text
Oui.
```

Les régressions ciblées passent-elles ?

```text
Oui.
```

P3-06 n'a-t-il pas été exécuté ?

```text
Oui.
```

Le prochain lot exact est-il clair ?

```text
Oui : P3-06 — Save/Load Narrative State Roundtrip Validation.
```

## 20. Regard critique sur le prompt

Le prompt est bien cadré : il force à distinguer vérité technique, Fact
présenté et World Rule passive. Le risque principal était de sur-modéliser un
Fact/WorldRule registry ou de vendre un test predicate comme preuve Flame
complète. La solution reste volontairement basse : disque réel, predicates
existants, aucune nouvelle source de vérité, et report clair du save/load et du
host smoke.
