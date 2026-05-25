# P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit

## 1. Résumé exécutif

Verdict :

```text
Phase 3 correctement cadrée.
P3-01 doit rester le prochain lot exact.
```

Le socle Phase 2 peut alimenter le runtime au niveau domaine et application,
mais la preuve est inégale selon les niveaux :

- Level 1 : contrats, modèles et décisions Phase 2 solides.
- Level 2 : nombreuses preuves unitaires/application autour de
  `ScenarioRuntimeExecutor`, outcomes, battle handoff, predicates, save/load.
- Level 3 : hooks `PlayableMapGame` présents pour scenarios, sources,
  continuation, battle, world rules et save/load, mais la couverture narrative
  Flame complète reste partielle.
- Level 4 : chargement disque réel existe pour `project.json`, maps, tilesets,
  manifest et save de lancement, mais un flux narratif complet depuis projet
  disque chargé reste non prouvé.

Conclusion honnête : la roadmap Phase 3 actuelle est bonne. Elle commence par
P3-01 parce que le point le plus critique est de vérifier précisément ce que le
projet disque expose au runtime, notamment `ProjectManifest.scenarios`,
dialogues, trainers, maps et saves de lancement.

Prochain lot exact :

```text
P3-01 — Project Disk Narrative Asset Loading Audit
```

## 2. Scope du lot

Inclus :

- audit runtime / application / disk ;
- audit de la roadmap Phase 3 existante ;
- distinction Level 1 / 2 / 3 / 4 ;
- inventaire des preuves déjà présentes ;
- identification des gaps runtime/disk ;
- création du rapport P3-00 ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md`.

Exclus :

- implémentation runtime ;
- P3-01 ;
- smoke test runtime ;
- projet Selbrume ;
- UI ;
- nouveaux contrats domaine ;
- registry ;
- JSON / migration ;
- modification de code.

## 3. Sources lues

Roadmaps et rapports :

- `AGENTS.md`
- `skills/README.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md`
- `reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md`
- `reports/roadmap/phase_2/p2_10_reference_picker_read_models.md`

Code et tests inspectés en lecture seule :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scenario_runtime_executor_test.dart`
- `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart`
- `packages/map_runtime/test/scenario_battle_from_scene_test.dart`
- `packages/map_runtime/test/npc_runtime_presence_test.dart`
- `packages/map_runtime/test/npc_interaction_scene_readiness_test.dart`
- `packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `examples/playable_runtime_host/lib/main.dart`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

Zones parcourues par recherche :

- `packages/map_core`
- `packages/map_gameplay`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`

## 4. État de la roadmap Phase 3

La roadmap Phase 3 existante est cohérente avec le checkpoint Phase 2.

État observé avant P3-00 :

- Phase 3 marquée `À démarrer`.
- Lot courant : P3-00.
- Prochain lot exact : P3-00.
- Lots proposés : P3-00 à P3-CHECKPOINT-01.

Décision P3-00 :

- La roadmap ne nécessite pas de réordonnancement.
- P3-01 doit rester `Project Disk Narrative Asset Loading Audit`.
- P3-00 met seulement la roadmap vivante à jour : P3-00 terminé, P3-01
  prochain lot exact.

Justification : l'audit montre beaucoup de preuves Level 2 et des hooks Level 3,
mais le lien "vrai projet disque chargé -> assets narratifs disponibles ->
runtime narratif prouvé" reste le premier trou à fermer.

## 5. Inventaire runtime/application existant

Runtime application :

- `ScenarioRuntimeExecutor` existe et exécute des `ScenarioAsset` à partir de
  `ScenarioRuntimeSourceEvent`.
- Sources runtime supportées : `mapEnter`, `triggerEnter`, `entityInteract`,
  `outcomeReceived`.
- Effets supportés : dialogue, script, message, battle, plus mutations de
  `GameState` via flags, steps, outcomes, item/Pokemon selon actions déjà
  branchées.
- `PlayableMapGame` possède un point d'entrée `_dispatchScenarioRuntimeSource`
  qui délègue à `ScenarioRuntimeExecutor`.
- `PlayableMapGame` déclenche `mapEnter`, `triggerEnter`, `entityInteract` et
  `outcomeReceived` dans son code.
- `PlayableMapGame` sait reprendre une continuation via
  `_resumeScenarioAfterRuntimeSource`.
- `PlayableMapGame` gère un effet battle scénario via
  `_handleScenarioBattleEffect`, puis pose un flag `battle:<id>:<suffix>` à la
  fin du combat.
- `MapEntityRuntimePredicateEvaluator` existe et lit flags, steps, chapters et
  cutscenes.
- `step_studio_world_presence_runtime.dart` existe et dérive des règles de
  présence depuis les metadata Step Studio.
- `FileGameSaveRepository`, `SaveGameUseCase` et `LoadGameUseCase` existent.

Preuve actuelle :

- Les composants runtime existent.
- Plusieurs tests `map_runtime` prouvent des chemins application.
- Une partie du wiring `PlayableMapGame` est présente dans le code.
- Le smoke narratif complet dans un vrai host depuis projet disque reste non
  prouvé.

## 6. Inventaire disk/project loading existant

Chargement projet :

- `loadProjectManifestFromFile` charge un `project.json`, applique
  `migrateProjectManifestJson`, construit `ProjectManifest` et lance
  `ProjectValidator.validate`.
- `loadRuntimeMapBundle` charge le manifest, résout une `ProjectMapEntry`,
  charge la map correspondante, valide la map et résout les chemins absolus de
  tilesets.
- `RuntimeMapBundle` expose `manifest`, `map`, `projectRootDirectory` et
  `tilesetAbsolutePathsById`.
- Le host `examples/playable_runtime_host` permet de choisir un dossier projet
  contenant `project.json`.
- Le host lit le manifest pour lister les maps et construit un
  `PlayableMapGame` à partir d'un `RuntimeMapBundle`.
- `runtime_host_launch_save.json` peut initialiser une `SaveData` de lancement.

Limites :

- Le loader ne charge pas explicitement des fichiers narratifs externes dans le
  rapport P3-00 ; il expose ce que le `ProjectManifest` contient.
- Les `ScenarioAsset` sont disponibles si et seulement si ils sont présents dans
  `ProjectManifest.scenarios`.
- Le fait qu'un projet disque réel contienne un scénario narratif complet,
  dialogue, battle reference, outcome et world rule prêts pour runtime n'est pas
  encore prouvé par P3-00.

## 7. Matrice de preuve Level 1 / 2 / 3 / 4

| Sujet | Preuve actuelle | Niveau prouvé | Fichiers / tests observés | Gap restant | Phase concernée |
|---|---|---:|---|---|---|
| Project disk loading | `project.json` chargé en `ProjectManifest`, map chargée, tilesets résolus. | Level 3 partiel / Level 4 partiel | `load_runtime_map_bundle.dart`, host `main.dart`, tests golden battle slice | Prouver assets narratifs complets depuis disque. | P3-01 |
| ScenarioAsset availability from disk | `ProjectManifest.scenarios` existe et circule dans `RuntimeMapBundle.manifest`. | Level 1 / 3 code path | `project_manifest.dart`, `runtime_map_bundle.dart`, `PlayableMapGame` | Prouver un projet disque réel avec scenarios runtime exploitables. | P3-01 |
| ScenarioRuntimeExecutor execution | Executor et tests couvrent sources/actions. | Level 2 | `scenario_runtime_executor.dart`, `scenario_runtime_executor_test.dart` | Golden path dans `PlayableMapGame` à isoler. | P3-02 |
| Event source -> scenario bridge | `PlayableMapGame` appelle `_dispatchScenarioRuntimeSource` pour map/trigger/entity/outcome. | Level 3 code path, tests surtout Level 2 | `playable_map_game.dart`, `npc_interaction_scene_readiness_test.dart` | Test Flame ciblé par source. | P3-03 |
| sourceMapEnter | Executor + hooks map enter dans `PlayableMapGame`. | Level 2, Level 3 code path | `scenario_runtime_executor_test.dart`, `playable_map_game.dart` | Preuve runtime hostile/disque. | P3-03 |
| sourceTriggerEnter | Executor calcule triggers, `PlayableMapGame` compare l'entrée dans trigger. | Level 2, Level 3 code path | `triggerIdsAtPosition`, `_dispatchScenarioTriggerEnterFromMovement` | Preuve Flame end-to-end. | P3-03 |
| sourceEntityInteract | Executor et `PlayableMapGame` dispatchent l'interaction entité. | Level 2, Level 3 code path | `npc_interaction_scene_readiness_test.dart`, `playable_map_game.dart` | Preuve host/projet disque. | P3-03 |
| sourceOutcome / outcomeReceived | `emitOutcome` redispatche `outcomeReceived`; PlayableMapGame expose un chemin outcome. | Level 2, Level 3 code path | `outcome_scene_branch_readiness_test.dart`, `playable_map_game.dart` | Preuve dialogue/Yarn -> outcome -> scene dans host. | P3-04 |
| emitOutcome | Pose `scenario.outcome.<id>` et tente dispatch global. | Level 2 | `scenario_runtime_executor.dart`, `outcome_scene_branch_readiness_test.dart` | Preuve runtime Flame complète. | P3-04 |
| Battle handoff | `startTrainerBattle` produit `ScenarioRuntimeEffectType.battle`; PlayableMapGame enqueue battle. | Level 2, Level 3 code path | `scenario_battle_from_scene_test.dart`, `playable_map_game.dart` | Smoke runtime narratif complet après battle. | P3-04 |
| Battle outcome continuation | PlayableMapGame pose `battle:<id>:suffix` et reprend le scenario. | Level 3 code path, Level 2 tests autour helpers | `scenario_battle_outcome_flags.dart`, `playable_map_game.dart` | Prouver hors code path par test runtime/host. | P3-04 |
| storyFlags | `GameState.storyFlags`, `StoryFlagsManager`, save/load. | Level 2 | `game_state.dart`, `file_game_save_repository_test.dart` | Vérifier roundtrip narratif complet. | P3-06 |
| completedStepIds | Source de completion Step Studio, persiste via `GameState`. | Level 2 | `step_studio_save_reload_visibility_integration_test.dart` | Preuve depuis vrai flux runtime. | P3-06 |
| consumedEventIds | Présent dans `GameState` et save/load. | Level 2 | `game_state.dart`, `file_game_save_repository_test.dart` | Usage narratif P3 précis non prouvé. | P3-06 |
| MapEntityRuntimePredicate | Evaluateur runtime lit flags/steps/chapters/cutscenes. | Level 2 | `map_entity_runtime_predicate_evaluator.dart`, `npc_runtime_presence_test.dart` | Full PlayableMapGame test explicitement non prouvé dans rapport runtime existant. | P3-05 |
| visibilityRule | Evaluée par `MapEntityRuntimePredicateEvaluator`. | Level 2 | `npc_runtime_presence_test.dart` | Preuve visuelle Flame/host. | P3-05 |
| conditionalDialogues | Résolution première condition vraie puis fallback. | Level 2 | `map_entity_runtime_predicate_evaluator.dart` | Preuve interaction UI/dialogue runtime. | P3-05 |
| World Rule projection | Step Studio world presence + predicates passifs existent. | Level 2, Level 3 code path | `step_studio_world_presence_runtime.dart`, `npc_runtime_presence_test.dart` | Conflits et vraie projection host à prouver. | P3-05 |
| Save/load narrative state | Repo fichier, use cases, `PlayableMapGame.saveGame/loadGame`. | Level 2, Level 3 code path | `file_game_save_repository_test.dart`, `playable_map_game.dart` | Roundtrip scenario/outcome/battle/world rule en host. | P3-06 |
| playable_runtime_host readiness | Host charge `project.json`, save de lancement, maps, construit `PlayableMapGame`. | Level 4 partiel pour launch save/projet, pas narratif complet | host `main.dart`, `phase_a_golden_slice_launch_test.dart` | Smoke narratif P3-07. | P3-07 |

## 8. Analyse par sujet Phase 3

### Project Disk Loading

Le chargement disque existe déjà pour `project.json`, manifest, map et tilesets.
`loadRuntimeMapBundle` est le point d'entrée runtime le plus évident. Le host
desktop s'appuie dessus pour construire `PlayableMapGame`.

Niveau prouvé : Level 3 partiel / Level 4 partiel.

Non prouvé : un projet disque narratif complet où scenarios, dialogues,
trainers, outcomes et predicates sont chargés puis exécutés dans un flux
runtime.

### ScenarioAsset Availability From Disk

`ProjectManifest` porte `scenarios`, et `RuntimeMapBundle` expose le manifest au
runtime. `PlayableMapGame` lit `_bundle.manifest.scenarios` lors du dispatch.

Niveau prouvé : Level 1 pour le modèle, Level 3 code path pour l'accès runtime.

Non prouvé : fixture disque narrative minimale vérifiant explicitement que des
`ScenarioAsset` chargés depuis `project.json` déclenchent un effet runtime.

### ScenarioRuntimeExecutor Execution

L'executor est le plus solide côté application. Il sait matcher les sources,
traverser le graphe, exécuter des actions, poser des flags/outcomes, déclencher
des effets dialogue/script/message/battle et bloquer les nodes non supportés.

Niveau prouvé : Level 2.

Non prouvé : golden path `PlayableMapGame` minimal isolé avec assets disque.

### Event Source To Scenario Runtime Bridge

Le bridge existe dans `PlayableMapGame` :

- map enter après chargement / transitions ;
- trigger enter depuis le mouvement ;
- entity interact depuis interaction PNJ ;
- outcome received via dispatch outcome.

Niveau prouvé : Level 3 code path, Level 2 par tests d'executor.

Non prouvé : test Flame ciblé et reproductible pour chaque source depuis un
projet disque.

### Outcome / Battle Outcome Continuation

`emitOutcome` pose `scenario.outcome.<id>` puis tente un dispatch global
`outcomeReceived`. Le battle scénario pose `battle:<battleId>:victory/defeat`
ou suffixe technique puis reprend le scenario après le node battle.

Niveau prouvé : Level 2 pour outcome, Level 3 code path pour battle continuation.

Non prouvé : continuité complète hors tests application, notamment dialogue
Yarn réel -> outcome -> scene et combat réel -> flag -> continuation -> effet
suivant dans host.

### Fact / World Rule Runtime Projection

Les facts restent des vérités techniques (`storyFlags`, `completedStepIds`,
`completedCutsceneIds`, battle flags, trainer defeated). World Rule reste
projection passive via predicates et Step Studio world presence.

Niveau prouvé : Level 2.

Non prouvé : preuve visuelle/Flame complète et stratégie de conflits entre
rules.

### Save/Load Narrative State

`FileGameSaveRepository` persiste `GameState` normalisé. Les tests E2E repository
préservent notamment flags et `consumedEventIds`. `PlayableMapGame.saveGame` et
`loadGame` existent et resynchronisent le runtime.

Niveau prouvé : Level 2, Level 3 code path.

Non prouvé : roundtrip narratif complet après scenario/outcome/battle/world rule
dans un projet disque.

### Playable Runtime Host Readiness

Le host est suffisamment prêt pour servir de cible future : sélection de projet,
chargement map, launch save, construction de `PlayableMapGame`, boutons
save/load. Il n'est pas encore une preuve de flux narratif Phase 3.

Niveau prouvé : Level 4 partiel pour la présence d'un vrai projet disque de
golden battle slice ; non prouvé pour un smoke narratif complet.

## 9. Gaps et risques

Gaps principaux :

- Non prouvé : scenario narratif complet depuis projet disque chargé.
- Non prouvé : map/trigger/entity/outcome sources validées en test Flame ou host.
- Non prouvé : dialogue Yarn réel qui émet un outcome puis branche une Scene.
- Non prouvé : combat réel lancé depuis Scene puis continuation vérifiée dans le
  host.
- Non prouvé : save/load roundtrip d'un flux narratif complet.
- Non prouvé : projection World Rule visible en runtime host avec conflit
  maîtrisé.

Risques :

- Vendre du Level 2 comme Level 3/4.
- Confondre `RuntimeMapBundle.manifest.scenarios` disponible avec preuve disque
  narrative complète.
- Transformer P3 en Phase 4 UI ou Phase 6 Selbrume.
- Ajouter des fixtures trop ambitieuses au lieu de preuves ciblées.
- Ouvrir rewards/money/XP/static wild authoring avant Phase 5.

## 10. Ajustements recommandés de la roadmap Phase 3

Aucun ajustement structurel nécessaire.

Roadmap confirmée :

1. P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit
2. P3-01 — Project Disk Narrative Asset Loading Audit
3. P3-02 — ScenarioAsset Runtime Execution Golden Path
4. P3-03 — Event Source to Scenario Runtime Bridge Validation
5. P3-04 — Outcome / Battle Outcome Runtime Continuation Validation
6. P3-05 — Fact / World Rule Runtime Projection Validation
7. P3-06 — Save/Load Narrative State Roundtrip Validation
8. P3-07 — Playable Runtime Host Narrative Smoke Test
9. P3-CHECKPOINT-01 — Runtime & Disk Readiness Review

P3-01 reste prioritaire parce qu'il doit établir précisément ce que le disque
fournit au runtime avant d'écrire ou d'auditer des golden paths plus larges.

## 11. Prochain lot exact

```text
P3-01 — Project Disk Narrative Asset Loading Audit
```

Objectif recommandé de P3-01 :

```text
Auditer comment un projet disque charge maps, scenarios, dialogues, trainers et
assets narratifs, puis décider quelle fixture minimale peut prouver la présence
des assets narratifs sans démarrer un smoke test runtime complet.
```

## 12. Modifications effectuées

Fichiers créés :

- `reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_3.md`

Fichiers explicitement non modifiés :

- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `packages/map_core/**`
- `packages/map_gameplay/**`
- `packages/map_runtime/**`
- `packages/map_editor/**`
- `packages/map_battle/**`
- `examples/playable_runtime_host/**`

## 13. Evidence Pack

### 13.1 git status initial

```text
```

### 13.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/load_game_use_case.dart
packages/map_runtime/lib/src/application/save_game_use_case.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/scenario_runtime_executor_test.dart
packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
packages/map_runtime/test/scenario_battle_from_scene_test.dart
packages/map_runtime/test/npc_runtime_presence_test.dart
packages/map_runtime/test/npc_interaction_scene_readiness_test.dart
packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart
packages/map_runtime/test/file_game_save_repository_test.dart
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
examples/playable_runtime_host/lib/main.dart
examples/playable_runtime_host/lib/src/runtime_launch_save.dart
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
```

### 13.3 Commandes exécutées

```text
git status --short --untracked-files=all
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,220p' AGENTS.md
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,260p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,320p' reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
sed -n '1,260p' reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
sed -n '1,300p' reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
find packages/map_runtime -type f | sort
find examples/playable_runtime_host -type f | sort
rg -n "ScenarioAsset|ProjectManifest|GameState|SaveData|ScenarioRuntimeExecutor|ScenarioRuntimeSourceEvent|ScenarioRuntimeEffect|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|emitOutcome|startTrainerBattle|battle:|trainer_defeated|storyFlags|completedStepIds|consumedEventIds|MapEntityRuntimePredicate|visibilityRule|conditionalDialogues|PlayableMapGame|save|load" packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
rg -n "project.*load|load.*project|ProjectLoader|ProjectRepository|ProjectStorage|project.json|manifest|assets|scenario|dialogue|trainer|SaveData|saveData|loadGame|saveGame" packages examples
rg -n "ScenarioRuntimeExecutor|ScenarioRuntimeEffect|ScenarioRuntimeSourceEvent|outcomeReceived|scenarioBattleOutcomeFlagName|RuntimeBattle|PlayableMapGame" packages/map_runtime packages/map_core examples/playable_runtime_host
rg -n "narrative_validator|narrative_reference_picker|buildNarrativeScenarioPickerOptions|buildNarrativeOutcomePickerOptions|buildNarrativeBattleReferencePickerOptions" packages/map_core packages/map_editor
sed -n '1,260p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_map_bundle.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/load_game_use_case.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/save_game_use_case.dart
sed -n '1,340p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '300,760p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '980,1070p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
rg -n "ScenarioRuntime|scenario|dispatch|dispatchContinuation|outcomeReceived|startTrainerBattle|battleId|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|triggerIdsAtPosition|completedStep|saveGame|loadGame" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,120p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
sed -n '2090,2165p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '2156,2335p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '2408,2545p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '4588,4645p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '5740,5845p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '220,525p' examples/playable_runtime_host/lib/main.dart
sed -n '525,640p' examples/playable_runtime_host/lib/main.dart
sed -n '1,120p' examples/playable_runtime_host/lib/src/runtime_launch_save.dart
rg -n "class .*GameSave|GameSaveRepository|FileGameSave|SharedPreferences|SaveData|toJson|fromJson|runtime_host_launch_save|savePath|saveFile" packages/map_runtime examples/playable_runtime_host packages/map_core
sed -n '5845,5945p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
rg -n "class FileGameSaveRepository|FileGameSaveRepository" packages/map_runtime/lib packages/map_runtime/test examples/playable_runtime_host
sed -n '1,160p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '1,120p' packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
sed -n '1,140p' examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
sed -n '1,220p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
sed -n '1,140p' packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
sed -n '1,220p' packages/map_runtime/test/scenario_battle_from_scene_test.dart
sed -n '1,140p' packages/map_runtime/test/npc_runtime_presence_test.dart
sed -n '1,160p' packages/map_runtime/test/npc_interaction_scene_readiness_test.dart
sed -n '1,260p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,220p' "MVP Selbrume/road_map_global.md"
sed -n '1,220p' reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
find reports/roadmap -maxdepth 2 -type d | sort
sed -n '1,360p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
rg -n "declaredOutcomeNeverEmitted|emitOutcomeNotDeclared|visibilityRuleConditionalMissingPredicate|worldRulePredicateEmptyRefId|scenarioChoiceNodeRuntimeUnsupported" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/test/narrative_validator_test.dart
rg -n "class ProjectManifest|scenarios|trainers|class SaveData|class GameState|storyFlags|completedStepIds|consumedEventIds" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart
mkdir -p reports/roadmap/phase_3
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle examples/playable_runtime_host
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md"
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md || true
git diff -- "MVP Selbrume/road_map_phase_3.md"
```

### 13.4 Sorties utiles des commandes

```text
git status initial : sortie vide.

load_runtime_map_bundle.dart :
- loadProjectManifestFromFile charge project.json, migre, construit ProjectManifest et valide ProjectValidator.
- loadRuntimeMapBundle charge manifest + map + tilesets et retourne RuntimeMapBundle.

scenario_runtime_models.dart :
- ScenarioRuntimeSourceType = mapEnter, triggerEnter, entityInteract, outcomeReceived.
- ScenarioRuntimeEffectType inclut dialogue, script, message, battle, none.

scenario_runtime_executor.dart :
- dispatch sur ScenarioAsset.
- emitOutcome pose scenario.outcome.<outcomeId> et redispatche outcomeReceived.
- startTrainerBattle retourne ScenarioRuntimeEffectType.battle.

playable_map_game.dart :
- _dispatchScenarioRuntimeSource utilise _bundle.manifest.scenarios.
- hooks mapEnter / triggerEnter / entityInteract / outcomeReceived présents.
- _handleScenarioBattleEffect enregistre une continuation scenario.
- _onBattleFinished pose battle:<battleId>:<suffix> puis reprend la continuation.
- saveGame/loadGame existent et resynchronisent le runtime.

map_entity_runtime_predicate_evaluator.dart :
- lit storyFlags, completedStepIds, completedCutsceneIds et chapter index.
- visibilityRule et conditionalDialogues sont passifs.

examples/playable_runtime_host/lib/main.dart :
- le host choisit un project.json, lit les maps du manifest, charge RuntimeMapBundle,
  charge runtime_host_launch_save.json si présent, puis construit PlayableMapGame.

Tests observés :
- scenario_runtime_executor_test.dart couvre mapEnter/triggerEnter/entityInteract.
- outcome_scene_branch_readiness_test.dart couvre emitOutcome/outcomeReceived au niveau application.
- scenario_battle_from_scene_test.dart couvre startTrainerBattle au niveau application.
- npc_runtime_presence_test.dart couvre presence predicates / Step Studio presence.
- file_game_save_repository_test.dart couvre save/load de GameState.
- phase_a_golden_battle_slice_smoke_test.dart couvre un golden battle slice disque/application,
  mais pas un flux narratif Phase 3 complet.
```

### 13.5 Fichiers créés

```text
reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
```

### 13.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_3.md
```

### 13.7 git diff --check

```text
```

### 13.8 git diff --stat

```text
 MVP Selbrume/road_map_phase_3.md | 51 +++++++++++++++++++++++++++++++++-------
 1 file changed, 43 insertions(+), 8 deletions(-)
```

### 13.9 git diff --name-only

```text
MVP Selbrume/road_map_phase_3.md
```

### 13.10 git status final

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
```

### 13.11 Contrôles explicites

```text
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle examples/playable_runtime_host
Sortie exacte : vide.

git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md"
Sortie exacte : vide.

git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md || true
Sortie exacte : vide.

Aucun code modifié : confirmé par contrôle hors scope vide.
road_map_global.md non modifié : confirmé par contrôle dédié vide.
road_map_phase_2.md non modifié : confirmé par contrôle dédié vide.
P3-01 non exécuté : confirmé, aucun fichier P3-01 créé ou modifié.
Selbrume final non créé : confirmé, aucune création de contenu Selbrume.
Tests/analyze : non exécutés, car P3-00 est un audit documentaire et aucun code n'a changé.
```

## 14. Auto-review critique

- Le lot a modifié uniquement ce qui était autorisé : oui.
- Le rapport P3-00 existe au bon chemin : oui.
- `road_map_phase_3.md` est mise à jour : oui.
- `road_map_global.md` n'a pas été modifié : oui.
- Aucun code n'a été modifié : oui.
- Aucun runtime n'a été implémenté : oui.
- Aucun smoke test n'a été créé : oui.
- Aucun projet Selbrume final n'a été créé : oui.
- P3-01 n'a pas été exécuté : oui.
- Les niveaux Level 1 / 2 / 3 / 4 sont distingués : oui.
- Les gaps runtime/disk sont explicites : oui.
- Le prochain lot exact est clair : oui, P3-01.

## 15. Regard critique sur le prompt

Le prompt est strict et utile : il force à ne pas confondre existence de code,
preuve application et preuve runtime/disk. Sa contrainte la plus importante est
la phrase "Non prouvé" : elle évite de maquiller des hooks `PlayableMapGame` en
preuve Level 4. Le seul point de vigilance est la commande `rg` très large, qui
produit une sortie énorme ; pour garder l'Evidence Pack vérifiable, le rapport
documente la commande exacte et synthétise les signaux utiles au lieu de recopier
des milliers de lignes peu exploitables.
