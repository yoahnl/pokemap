# Phase 3 Roadmap — Runtime / Application / Flame / Disk Validation

## 1. Statut de la phase

Phase 3 — Runtime / Application / Flame / Disk Validation

Statut : 🔜 En cours

Lot courant : P3-07 — Playable Runtime Host Narrative Smoke Test

Prochain lot exact : P3-07 — Playable Runtime Host Narrative Smoke Test

Suivi des lots :

- ✅ P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit
- ✅ P3-01 — Project Disk Narrative Asset Loading Audit
- ✅ P3-02 — ScenarioAsset Runtime Execution Golden Path
- ✅ P3-03 — Event Source to Scenario Runtime Bridge Validation
- ✅ P3-04 — Outcome / Battle Outcome Runtime Continuation Validation
- ✅ P3-05 — Fact / World Rule Runtime Projection Validation
- ✅ P3-06 — Save/Load Narrative State Roundtrip Validation
- 🔜 P3-07 — Playable Runtime Host Narrative Smoke Test
- P3-CHECKPOINT-01 — Runtime & Disk Readiness Review

P3-00 : ✅ terminé

P3-01 : ✅ terminé

P3-02 : ✅ terminé

P3-03 : ✅ terminé

P3-04 : ✅ terminé

P3-05 : ✅ terminé

P3-06 : ✅ terminé

P3-07 : 🔜 prochain lot exact

## 2. Objectif de la Phase 3

Valider que les contrats, diagnostics et read models Phase 2 peuvent être reliés
à un vrai projet disque et à l'exécution runtime, sans créer encore Selbrume
final, sans UI premium et sans ouvrir les grands gaps gameplay hors lot.

Phase 3 doit répondre à la question :

```text
Le socle domaine Phase 2 peut-il réellement alimenter le runtime et le disque ?
```

## 3. Pourquoi cette phase existe

La Phase 2 a stabilisé les décisions domaine, ajouté des diagnostics et créé les
premiers read models. Elle n'a pas prouvé :

- le chargement depuis un vrai projet disque ;
- l'exécution complète dans le runtime Flutter / Flame ;
- la continuité Event → Scene → Outcome / Battle → Fact / Step → World Rule ;
- le roundtrip save/load réel sur un flux narratif.

Phase 3 est donc une phase de preuve runtime/disk, pas une phase d'UI ou de
contenu final.

## 4. Préconditions

- Phase 2 clôturée avec réserves mineures.
- `reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 3.
- Les diagnostics P2-09 passent.
- Les read models P2-10 passent.
- Selbrume reste une référence conceptuelle.

## 5. Périmètre Phase 3

Inclus :

- audit runtime/disk ;
- validation du chargement narratif depuis projet disque ;
- validation du chemin `ScenarioAsset` vers runtime ;
- validation des sources Event vers scenario runtime ;
- validation de la continuation outcome / battle outcome ;
- validation de la projection Fact / World Rule au runtime ;
- validation save/load narrative state ;
- smoke test ciblé dans playable runtime host si justifié ;
- rapport checkpoint Phase 3.

Exclus :

- Selbrume final ;
- UI premium ;
- widgets authoring ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- Reward Model ;
- money / XP / level-up ;
- static wild authoring ;
- Door/Warp complet hors lot explicite ;
- Phase 4 authoring workflows ;
- Phase 5 gameplay gaps.

## 6. Règles de maintenance

À chaque lot Phase 3, l'agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire `MVP Selbrume/road_map_phase_3.md`.
3. Respecter le prochain lot exact.
4. Ne pas démarrer un autre lot.
5. Distinguer preuve runtime, preuve disk, preuve editor et preuve gameplay.
6. Ne pas créer Selbrume final.
7. Ne pas créer UI premium.
8. Ne pas ouvrir les gaps gameplay Phase 5 hors demande explicite.
9. Fournir un Evidence Pack complet.
10. Mettre à jour cette roadmap vivante.
11. Ne modifier `road_map_global.md` qu'au checkpoint ou sur demande explicite.

## 7. Lots Phase 3 proposés

### ✅ P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit

Objectif :
Valider le découpage Phase 3, inventorier les preuves runtime/disk existantes et
définir les lots de validation sans implémenter le runtime.

Résultat attendu :
Roadmap Phase 3 confirmée, risques runtime/disk listés, prochain lot P3-01
clarifié.

Non-objectifs :
Pas de code runtime, pas de projet Selbrume final, pas d'UI.

Résultat P3-00 :

- rapport créé :
  `reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md` ;
- roadmap Phase 3 confirmée sans réordonnancement ;
- P3-01 confirmé comme prochain lot exact ;
- niveaux de preuve clarifiés :
  - Level 1 solide sur contrats/modèles Phase 2 ;
  - Level 2 solide sur executor, outcomes, battle handoff, predicates et save/load ;
  - Level 3 présent sous forme de hooks `PlayableMapGame`, mais preuve narrative
    Flame complète encore partielle ;
  - Level 4 partiel sur chargement projet/host, mais flux narratif disque complet
    non prouvé ;
- aucun code modifié ;
- aucun test ajouté ou relancé ;
- aucun runtime, UI, smoke test ou projet Selbrume créé.

Commandes principales exécutées :

- `git status --short --untracked-files=all`
- `sed -n '1,260p' "MVP Selbrume/road_map_global.md"`
- `sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '1,260p' "MVP Selbrume/road_map_phase_3.md"`
- `sed -n '1,320p' reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md`
- `rg -n "ScenarioAsset|ProjectManifest|GameState|SaveData|ScenarioRuntimeExecutor|ScenarioRuntimeSourceEvent|ScenarioRuntimeEffect|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|emitOutcome|startTrainerBattle|battle:|trainer_defeated|storyFlags|completedStepIds|consumedEventIds|MapEntityRuntimePredicate|visibilityRule|conditionalDialogues|PlayableMapGame|save|load" packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host`
- `find packages/map_runtime -type f | sort`
- `find examples/playable_runtime_host -type f | sort`

Décision :
P3-01 reste nécessaire avant tout golden path runtime plus ambitieux, car le lien
`projet disque -> assets narratifs disponibles -> runtime narratif prouvé` reste
le premier gap à fermer.

### ✅ P3-01 — Project Disk Narrative Asset Loading Audit

Objectif :
Auditer comment un projet disque charge maps, scenarios, dialogues, trainers et
assets narratifs.

Résultat attendu :
Frontière claire entre `ProjectManifest`, fichiers disque et runtime loader.

Résultat P3-01 :

- rapport créé :
  `reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md` ;
- chemin disque clarifié :
  `project.json -> ProjectManifest -> RuntimeMapBundle -> PlayableMapGame` ;
- `ProjectManifest.scenarios` et `ProjectManifest.trainers` sont embedded dans
  `project.json` ;
- `ProjectManifest.dialogues` porte des métadonnées et chemins relatifs vers
  des fichiers Yarn externes, mais aucun fichier `.yarn` versionné n'a été trouvé ;
- les maps sont chargées depuis fichiers externes via `ProjectMapEntry.relativePath` ;
- `RuntimeMapBundle` expose le manifest, la map active, la racine projet et les
  chemins tilesets résolus ;
- `PlayableMapGame` lit les scénarios, dialogues et trainers depuis
  `_bundle.manifest` ;
- le host jouable charge une `runtime_host_launch_save.json` adjacente au
  `project.json` si elle existe ;
- la fixture disque `golden_battle_slice` prouve map + trainer + battle + save,
  mais ne prouve pas encore un flux narratif disque complet avec scenarios +
  dialogues ;
- aucun code modifié ;
- aucun test lancé, car le lot est documentaire et les tests existants ont été
  lus seulement comme preuves.

Décision :
P3-02 reste le prochain lot exact. Il devra prouver un golden path
`ScenarioAsset` et assumer explicitement qu'une fixture technique narrative
minimale est encore absente du repo actuel.

### ✅ P3-02 — ScenarioAsset Runtime Execution Golden Path

Objectif :
Prouver un chemin minimal d'exécution `ScenarioAsset` dans le runtime, sans
élargir le modèle.

Résultat attendu :
Preuve ciblée que le graphe existant s'exécute comme attendu ou liste de gaps.

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
- tests lancés :
  - `cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart`
  - `cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart`
  - `cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart`
  - `cd packages/map_runtime && dart format --set-exit-if-changed test/p3_scenario_runtime_golden_path_test.dart`

Décision :
P3-03 devient le prochain lot exact, car P3-02 a prouvé le scénario chargé
depuis disque et exécuté par le chemin application runtime sans ouvrir les
sources Event runtime complètes.

### ✅ P3-03 — Event Source to Scenario Runtime Bridge Validation

Objectif :
Valider le pont entre sources Event runtime et source nodes `ScenarioAsset`.

Résultat attendu :
Preuve `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived` selon
le périmètre réellement supporté.

Résultat P3-03 :

- rapport créé :
  `reports/roadmap/phase_3/p3_03_event_source_to_scenario_runtime_bridge_validation.md` ;
- fixture technique non-Selbrume créée :
  `packages/map_runtime/test/fixtures/p3_event_source_bridge/` ;
- test ciblé créé :
  `packages/map_runtime/test/p3_event_source_bridge_validation_test.dart` ;
- preuve obtenue :
  - vrai `project.json` chargé par `loadRuntimeMapBundle` ;
  - quatre `ScenarioAsset` embedded disponibles via
    `RuntimeMapBundle.manifest.scenarios` ;
  - `ScenarioRuntimeSourceEvent.mapEnter` matche seulement
    `sourceMapEnter` et pose `p3.source.map_enter.executed` ;
  - `ScenarioRuntimeSourceEvent.triggerEnter` matche seulement
    `sourceTriggerEnter` et pose `p3.source.trigger_enter.executed` ;
  - `ScenarioRuntimeSourceEvent.entityInteract` matche seulement
    `sourceEntityInteract` et pose `p3.source.entity_interact.executed` ;
  - `ScenarioRuntimeSourceEvent.outcomeReceived` matche explicitement
    `sourceOutcome` et pose `p3.source.outcome_received.executed` ;
  - les identifiants erronés map, trigger, entity et outcome ne déclenchent
    aucun scénario ;
- niveau de preuve : Level 4 partiel pour disque + Level 2/3 contrôlé pour
  executor ;
- non prouvé volontairement : hook complet `PlayableMapGame`, host smoke,
  chaîne automatique `emitOutcome -> outcomeReceived`, battle continuation,
  save/load roundtrip, World Rules ;
- tests lancés :
  - `cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart`
  - `cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart`
  - `cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart`
  - `cd packages/map_runtime && dart format --set-exit-if-changed test/p3_event_source_bridge_validation_test.dart`

Décision :
P3-04 devient le prochain lot exact, car P3-03 a prouvé le dispatch explicite
des sources Event runtime sans ouvrir la continuation outcome / battle outcome.

### ✅ P3-04 — Outcome / Battle Outcome Runtime Continuation Validation

Objectif :
Valider la continuation runtime après `emitOutcome` et battle outcome minimal.

Résultat attendu :
Preuve que les outcomes scénario et battle restent séparés et interprétables.

Résultat P3-04 :

- rapport créé :
  `reports/roadmap/phase_3/p3_04_outcome_battle_outcome_runtime_continuation_validation.md` ;
- fixture technique non-Selbrume créée :
  `packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/` ;
- test ciblé créé :
  `packages/map_runtime/test/p3_outcome_battle_continuation_test.dart` ;
- preuve scenario outcome :
  - vrai `project.json` chargé par `loadRuntimeMapBundle` ;
  - `emitOutcome p3.outcome.continuation` pose
    `scenario.outcome.p3.outcome.continuation` ;
  - le dispatch automatique `emitOutcome -> outcomeReceived` atteint le
    scénario global `sourceOutcome` et pose `p3.outcome.received` ;
  - `outcomeReceived` explicite fonctionne aussi ;
  - un mauvais `outcomeId` ne déclenche rien ;
- preuve battle outcome :
  - `startTrainerBattle` retourne `ScenarioRuntimeEffectType.battle` avec
    `battleId=p3_battle_test`, `trainerId=p3_trainer_test`,
    `npcEntityId=p3_battle_npc` ;
  - `battle:p3_battle_test:victory` et `battle:p3_battle_test:defeat` restent
    séparés de `scenario.outcome.*` ;
  - `dispatchContinuation` reprend après le node battle et branche sur victory
    ou defeat selon le flag battle actif ;
- niveau de preuve : Level 4 partiel pour disque + Level 2/3 contrôlé pour
  executor/continuation ;
- non prouvé volontairement : boucle complète `PlayableMapGame`,
  `_onBattleFinished` réel, combat engine complet, rewards, money, XP,
  save/load roundtrip, World Rules ;
- tests lancés :
  - `cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_scenario_runtime_golden_path_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart`
  - `cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart`
  - `cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart`
  - `cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart`
  - `cd packages/map_runtime && dart format --set-exit-if-changed test/p3_outcome_battle_continuation_test.dart`

Décision :
P3-05 devient le prochain lot exact, car P3-04 a prouvé la continuation outcome
et battle outcome minimale sans ouvrir save/load, World Rules ou battle complet.

### ✅ P3-05 — Fact / World Rule Runtime Projection Validation

Objectif :
Valider que les vérités techniques et predicates existants projettent le monde
sans créer de nouvelle source de vérité.

Résultat attendu :
Preuve ou gaps sur flags, steps, chapter derivation, visibility rules et
conditional dialogues.

Résultat P3-05 :

- rapport créé :
  `reports/roadmap/phase_3/p3_05_fact_world_rule_runtime_projection_validation.md` ;
- fixture technique non-Selbrume créée :
  `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/` ;
- test ciblé créé :
  `packages/map_runtime/test/p3_fact_world_rule_projection_test.dart` ;
- preuve obtenue :
  - vrai `project.json` chargé par `loadRuntimeMapBundle` ;
  - `visibilityRule` lit passivement `GameState.storyFlags.activeFlags` ;
  - `visibilityRule` lit passivement `completedStepIds` ;
  - `visibilityRule` lit passivement `completedCutsceneIds` ;
  - `scenario.outcome.*` est lisible comme flag technique ;
  - `battle:*` est lisible comme flag technique ;
  - `chapterCompleted` est dérivé via `GlobalStoryChapterStepIndex` sans état
    stocké de chapitre ;
  - `Step Studio world presence` projette passivement la présence PNJ depuis
    metadata `authoring.stepStudioDocument` et `completedStepIds` ;
  - `conditionalDialogues` résout le dialogue attendu selon les predicates
    existants ;
  - les cas négatifs mauvais flag/step/cutscene/outcome/battle/chapter ne
    déclenchent pas de projection ;
  - les évaluations ne mutent pas `GameState` ;
- niveau de preuve : Level 4 partiel pour disque + Level 2/3 contrôlé pour
  predicates/projection runtime ;
- non prouvé volontairement : `PlayableMapGame` complet, host smoke,
  save/load roundtrip, UI authoring, FactRegistry, WorldRuleRegistry ;
- tests lancés :
  - `cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart`
  - `cd packages/map_runtime && flutter test test/npc_runtime_presence_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_event_source_bridge_validation_test.dart`
  - `cd packages/map_runtime && dart format --set-exit-if-changed test/p3_fact_world_rule_projection_test.dart`

Décision :
P3-06 devient le prochain lot exact, car P3-05 a prouvé que les vérités
techniques existantes peuvent projeter passivement le monde sans nouvelle source
de vérité. Le roundtrip save/load de ces vérités reste volontairement hors P3-05.

### ✅ P3-06 — Save/Load Narrative State Roundtrip Validation

Objectif :
Valider le roundtrip save/load des états narratifs nécessaires au flux minimal.

Résultat attendu :
Preuve ciblée pour story flags, completed steps, outcomes et états connexes.

Résultat P3-06 :

- rapport créé :
  `reports/roadmap/phase_3/p3_06_save_load_narrative_state_roundtrip_validation.md` ;
- test ciblé créé :
  `packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart` ;
- fixture P3-05 réutilisée sans modification :
  `packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/` ;
- preuve obtenue :
  - vrai fichier de sauvegarde temporaire écrit et relu via
    `FileGameSaveRepository`, `SaveGameUseCase` et `LoadGameUseCase` ;
  - `storyFlags.activeFlags` survit au roundtrip ;
  - `completedStepIds` survit au roundtrip ;
  - `completedCutsceneIds` survit au roundtrip ;
  - `scenario.outcome.*` survit comme flag technique ;
  - `battle:*:victory` et `battle:*:defeat` survivent comme flags techniques
    séparés ;
  - `consumedEventIds` survit au roundtrip dans le chemin `GameState` courant ;
  - `currentMapId`, position et orientation joueur sont conservés pour le flux
    runtime minimal ;
  - les projections P3-05 restent actives après reload :
    `visibilityRule`, `conditionalDialogues`, `chapterCompleted` dérivé et
    Step Studio world presence ;
  - les cas négatifs après reload restent false ou fallback ;
  - les projections relues après reload ne mutent pas `GameState` ;
- niveau de preuve : Level 4 partiel pour vrai save/load disque temporaire et
  fixture `project.json` P3-05, Level 2/3 contrôlé pour repository/use cases et
  predicates runtime ;
- non prouvé volontairement : `PlayableMapGame` complet, host smoke, UI save
  menu, combat complet, rewards, money, XP, Selbrume final ;
- tests lancés :
  - `cd packages/map_runtime && dart format --set-exit-if-changed test/p3_save_load_narrative_state_roundtrip_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_save_load_narrative_state_roundtrip_test.dart`
  - `cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart`
  - `cd packages/map_runtime && flutter test test/step_studio_save_reload_visibility_integration_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_fact_world_rule_projection_test.dart`
  - `cd packages/map_runtime && flutter test test/p3_outcome_battle_continuation_test.dart`

Décision :
P3-07 devient le prochain lot exact, car P3-06 a prouvé que les vérités
narratives techniques produites ou lues par P3-02 à P3-05 survivent au
roundtrip save/load disque sans créer de nouveau modèle, registry ou migration.

### P3-07 — Playable Runtime Host Narrative Smoke Test

Objectif :
Ajouter ou auditer un smoke test runtime host ciblé, si les lots précédents
montrent que le périmètre est prêt.

Résultat attendu :
Preuve d'exécution end-to-end minimale ou décision documentée de report.

### P3-CHECKPOINT-01 — Runtime & Disk Readiness Review

Objectif :
Clôturer Phase 3, vérifier les preuves runtime/disk et décider le passage vers
Phase 4.

Résultat attendu :
Verdict Phase 3, roadmaps mises à jour, prochain lot exact fixé.

## 8. Critères de sortie Phase 3

Phase 3 pourra être clôturée si :

- les chemins runtime/disk essentiels sont prouvés ou leurs gaps sont explicites ;
- les limites Level 2 / Level 3 / Level 4 ne sont plus ambiguës ;
- les validations ciblées passent ;
- aucun contenu Selbrume final n'a été créé par accident ;
- l'UI authoring reste reportée à Phase 4 ;
- les gaps gameplay restent reportés à Phase 5 ;
- la roadmap globale est mise à jour au checkpoint.

## 9. Décisions à valider avant ou pendant P3-00

- Valider cette roadmap Phase 3.
- Définir le degré de preuve runtime attendu.
- Choisir projet disque minimal ou fixture technique.
- Définir le périmètre du runtime smoke test.
- Confirmer que Phase 3 ne crée pas Selbrume final.
- Confirmer que l'UI authoring reste Phase 4.
- Confirmer que rewards / money / XP restent Phase 5.

## 10. Rappels permanents

```text
Phase 3 prouve runtime/disk.
Phase 3 ne crée pas Selbrume final.
Phase 3 ne crée pas UI premium.
Phase 3 n'ouvre pas les gaps gameplay hors lot explicite.
```

Le prochain lot exact est :

```text
P3-07 — Playable Runtime Host Narrative Smoke Test
```
