# P2-01 — Existing Narrative Domain Inventory

## 1. Résumé exécutif

P2-01 a inventorié l’existant narratif réel du repo avant toute création de
contrat Phase 2. Le lot confirme que PokeMap possède déjà plusieurs briques
techniques narratives, mais qu’elles ne sont pas encore un modèle domaine
canonique complet.

Vérité technique principale observée :

- `ScenarioAsset` est aujourd’hui le graphe scénario persistant principal :
  scopes, nodes, edges, bindings, payloads, outcomes déclarés, condition
  d’activation et metadata.
- `ProjectManifest` agrège les scénarios, dialogues, scripts, trainers, maps et
  autres assets. Toute extension persistante doit donc être justifiée par des
  consumers et une stratégie migration.
- `GameState` / `SaveData` stockent déjà des vérités durables : `storyFlags`,
  `progression.completedStepIds`, variables, bag, party, money et progression.
- `ScriptCondition` et `ScriptConditionEvaluator` fournissent une base de
  conditions pure gameplay, surtout orientée flags, variables, abilities,
  moves, events consommés et map courante.
- `MapEntityRuntimePredicate` et son evaluator constituent déjà une base
  passive de World Rules pour présence/dialogue d’entités, avec lecture de
  flags, steps, cutscenes et chapters.
- `NarrativeValidator` existe comme validator narratif multi-diagnostics V0,
  distinct du `ProjectValidator` structurel et throw-based.
- `ScenarioRuntimeExecutor` exécute les scénarios via events runtime, actions,
  outcomes, battle handoff, `giveItem`, `givePokemon`, `setFlag`,
  `clearFlag` et `completeStep`.
- Les metadata editor Step Studio, Global Story Studio et Cutscene Studio
  portent déjà beaucoup d’intention produit, mais elles vivent principalement
  côté `map_editor` et dans `ScenarioAsset.metadata`.

Éléments manquants ou non canoniques :

- aucun contrat pur `map_core` Storyline / Chapter / Story Step n’a été observé ;
- aucun FactDescriptor / FactRegistry canonique n’a été observé ;
- aucun WorldRuleRegistry canonique n’a été observé ;
- aucune source de picker domaine stabilisée n’a été observée ;
- aucune décision définitive ne peut encore être prise sur Scene =
  `ScenarioAsset`, wrapper ou adapter ;
- les side quests sont prouvées comme pattern, pas comme Quest Engine.

P2-01 ne décide pas quoi construire. Il prépare les décisions P2-02+ en
séparant observation technique, interprétation prudente, risques et questions.

Prochain lot exact :

```text
P2-02 — Story Step Descriptor / Storyline Metadata Decision
```

## 2. Scope du lot

Inclus :

- inventaire technique détaillé des zones narratives existantes ;
- lecture des modèles, validators, runtime sources et authoring projections ;
- séparation observation / interprétation / décision future ;
- identification des sources de vérité, metadata, consumers et risques ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- contrats domaine implémentés ;
- modèles `map_core` ;
- JSON, schémas, migrations ;
- fichiers Freezed / JsonSerializable ;
- tests nouveaux ou modifiés ;
- `build_runner` ;
- P2-02 ;
- contenu final Selbrume.

Fichiers créés :

- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Fichiers explicitement non modifiés :

- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- `packages/map_core`
- `packages/map_gameplay`
- `packages/map_battle`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`

## 3. Sources lues

Roadmaps et rapports Phase 2 / Phase 1 :

- `MVP Selbrume/road_map_global.md` — contexte global, lu sans modification.
- `MVP Selbrume/road_map_phase_2.md` — roadmap vivante active, mise à jour.
- `MVP Selbrume/road_map_phase_1.md` — statut Phase 1 clôturée, lu sans
  modification.
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
  — frontière P2-00/P2-01 et zones à inventorier.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  — verdict Phase 1 et passage vers Phase 2.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` —
  candidats de contrats Phase 2.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` —
  workflows no-code, pickers, validations.
- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` —
  mapping conceptuel Selbrume.
- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` —
  Storyline / Chapter / Story Step.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` —
  Fact / World Rule.
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` —
  Event / Scene / Cinematic.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` —
  grammaire produit canonique.

Rapports NS-GS lus ou inspectés pour niveau de preuve :

- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md`
  — distinction Level 2 / runtime Flame / projet disque.
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md`
  — correction de labels de preuve.
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` —
  origine et limites du validator narratif V0.
- `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md`
  — side quest comme pattern sans Quest Engine.
- `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` —
  limites reward, money, XP.

Fichiers de code lus ou inspectés en lecture seule :

- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_authoring.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`

Tests repérés par recherche, sans exécution :

- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_core/test/map_entity_runtime_rules_serialization_test.dart`
- `packages/map_gameplay/test/complete_step_test.dart`
- `packages/map_runtime/test/scenario_runtime_executor_test.dart`
- `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart`
- `packages/map_runtime/test/world_rules_conditional_presence_readiness_test.dart`
- `packages/map_runtime/test/global_story_chapter_runtime_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/test/cutscene_studio_authoring_test.dart`
- `packages/map_editor/test/step_studio_workspace_regression_test.dart`

## 4. Méthode d’inventaire

Méthode appliquée :

- lecture ciblée des roadmaps et rapports Phase 1 / Phase 2 ;
- recherche `rg` sur les symboles narratifs et tests associés ;
- lecture des fichiers critiques listés par P2-00 ;
- séparation stricte entre observation technique, interprétation prudente,
  risque et décision à reporter ;
- aucune modification de code ;
- aucun test/analyze Dart/Flutter lancé.

La granularité est volontairement détaillée mais bornée : P2-01 décrit les
structures et leurs responsabilités actuelles, sans proposer d’implémentation
de contrat.

## 5. Vue d’ensemble des zones narratives existantes

| Zone | Package | Rôle actuel | Lien avec grammaire Phase 1 | Niveau de stabilité | Risque |
|---|---|---|---|---|---|
| `ScenarioAsset` | `map_core` | Graphe scénario persistant | Base technique de Scene / global story / local event flow | Élevé comme modèle existant | Le surcharger ou le dupliquer |
| `ProjectManifest` | `map_core` | Agrégation projet | Référence scenarios/dialogues/trainers/maps | Élevé | Migration prématurée |
| `GameState` | `map_core` | État runtime durable | Facts techniques, steps, variables | Élevé | Duplication `storyFlags` / progression |
| `SaveData` | `map_core` | Persistance save/load | Story flags, steps, bag, party, money | Élevé | Ajouter des champs narratifs non justifiés |
| `ScriptCondition` | `map_core` / `map_gameplay` | DSL conditionnel existant | Conditions Event / Scene / availability | Moyen | Nouveau DSL concurrent |
| `MapEntityRuntimePredicate` | `map_core` / `map_runtime` | Predicates passifs entités | World Rule V0 | Moyen | Transformer en Event déguisé |
| `NarrativeValidator` | `map_core` | Multi-diagnostics narratifs V0 | Validator diagnostique | Moyen | Diverger de `ProjectValidator` |
| `ProjectValidator` | `map_core` | Validation structurelle throw-based | Cohérence manifest/scenarios | Élevé | Confondre validation structurelle et diagnostics auteur |
| `ScenarioRuntimeSourceEvent` | `map_runtime` | Événements runtime | Event déclenche | Moyen | Dupliquer côté authoring |
| `ScenarioRuntimeExecutor` | `map_runtime` | Exécution scénario | Scene orchestre, Battle handoff, outcomes | Moyen | En faire source de vérité domaine |
| Battle outcome flags | `map_runtime` | Convention flags battle | Battle outcome | Moyen | Étendre money/XP trop tôt |
| Global Story runtime | `map_runtime` | Lecture metadata chapters | Chapter runtime dérivé | Faible à moyen | Metadata editor cachée |
| Step Studio runtime | `map_runtime` | Présence monde depuis steps | World Rule/Step metadata | Faible à moyen | Deux systèmes de world rules |
| Narrative workspace projection | `map_editor` | Projection read-only editor | Picker/read model potentiel | Moyen | Confondre projection UI et domaine |
| Step Studio authoring | `map_editor` | Metadata Step dans scénario global | Story Step authoring | Moyen | Source de vérité editor-side |
| Global Story Studio authoring | `map_editor` | Metadata chapters/flow | Storyline / Chapter metadata | Moyen | Persistant caché dans metadata |
| Project scenario use cases | `map_editor` | CRUD `ScenarioAsset` | Scene authoring persistence | Moyen | Adapter Scene non coordonné |

## 6. Inventory — ScenarioAsset

Fichier :

```text
packages/map_core/lib/src/models/scenario_asset.dart
```

Observation technique :

- `ScenarioAsset` est un modèle Freezed/JsonSerializable déjà existant.
- Champs observés :
  - `id`
  - `name`
  - `description`
  - `scope`
  - `entryNodeId`
  - `declaredOutcomes`
  - `activationCondition`
  - `nodes`
  - `edges`
  - `metadata`
- `ScenarioScope` expose :
  - `globalStory`
  - `localEventFlow`
- `ScenarioNode` expose :
  - `id`
  - `type`
  - `title`
  - `description`
  - `position`
  - `binding`
  - `payload`
  - `metadata`
- `ScenarioNodeType` expose :
  - `start`
  - `dialogue`
  - `action`
  - `condition`
  - `choice`
  - `reference`
  - `end`
- `ScenarioNodeBinding` expose notamment :
  - `mapId`
  - `eventId`
  - `entityId`
  - `warpId`
  - `triggerId`
  - `trainerId`
  - `dialogueId`
  - `scriptId`
  - `outcomeId`
  - `flagName`
  - `variableName`
- `ScenarioNodePayload` expose :
  - `actionKind`
  - `message`
  - `condition`
  - `choiceLabels`
  - `params`
- `ScenarioEdge` expose :
  - `id`
  - `fromNodeId`
  - `toNodeId`
  - `label`
  - `kind`
  - `order`
  - `metadata`
- `ScenarioEdgeKind` expose :
  - `next`
  - `trueBranch`
  - `falseBranch`
  - `choice`
  - `reference`

Metadata disponibles :

- `ScenarioAsset.metadata` est une `Map<String, String>`.
- Les studios editor y stockent déjà :
  - `authoring.stepStudioDocument`
  - `authoring.stepStudioSchema`
  - `authoring.globalStoryStudioDocument`
  - `authoring.globalStoryStudioSchema`
  - `authoring.cutsceneFlow`
  - `authoring.cutsceneSchema`
  - des metadata legacy `step.*`

Usages connus :

- `ProjectManifest.scenarios` persiste les scénarios.
- `ProjectValidator` valide les scénarios structurellement.
- `NarrativeValidator` lit les nodes, edges, bindings, action kinds et
  outcomes.
- `ScenarioRuntimeExecutor` exécute les scénarios.
- `map_editor` crée, met à jour et projette les scénarios.

Lien avec Scene :

- Observation : `ScenarioAsset` est déjà le support technique de graphes de
  scène/scénario.
- Interprétation prudente : Scene pourrait être le nom produit de
  `ScenarioAsset`, ou un adapter/read model au-dessus de lui.
- Décision future : P2-04 doit trancher.

Risques :

- créer un `SceneContract` qui duplique `ScenarioAsset` ;
- surcharger `ScenarioAsset` avec toute la grammaire produit ;
- traiter `metadata` comme contrat stable sans validation domaine ;
- exposer `ScenarioNodeBinding` / `payload.params` comme UX normale.

Questions P2-04 :

- Scene est-elle strictement `ScenarioAsset` ?
- Faut-il un adapter/read model `Scene` pour labels, diagnostics et pickers ?
- Les metadata editor doivent-elles rester metadata ou migrer vers contrats ?
- Les `choice` nodes restent-ils authoring-only ou runtime V0 ?

## 7. Inventory — ProjectManifest

Fichier :

```text
packages/map_core/lib/src/models/project_manifest.dart
```

Observation technique :

- `ProjectManifest` agrège les assets du projet.
- Les scénarios vivent dans `scenarios: List<ScenarioAsset>`.
- Les dialogues, scripts et trainers ont des entrées dédiées.
- Les maps, encounter tables, characters et assets sont aussi agrégés par le
  manifest.

Liens narratifs observés :

- `ProjectDialogueEntry` porte un `id`, un nom, un chemin relatif, des tags,
  une description, un `defaultStartNode`, un folder et un ordre.
- `ProjectScriptEntry` porte un `ScriptAsset`.
- `ProjectTrainerEntry` est utilisé par validators et runtime battle refs.
- `ProjectValidator` valide les références manifest/scenarios.
- Les use cases editor créent et mettent à jour `ProjectManifest.scenarios`.

Interprétation prudente :

- `ProjectManifest` est une source de vérité projet, mais pas nécessairement le
  bon endroit pour ajouter Storyline / Chapter / Fact / World Rule dès P2-02.
- Les contrats persistants nouveaux doivent être évités tant que les consumers
  ne sont pas explicitement confirmés.

Risque :

- modifier `ProjectManifest` trop tôt impose JSON, migrations et compatibilité
  projet.

Conclusion :

```text
Toute modification ProjectManifest doit être justifiée par consumers + migration.
```

## 8. Inventory — GameState / SaveData

Fichiers :

```text
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
```

Observation technique :

- `GameState` contient notamment :
  - `saveId`
  - `currentMapId`
  - `playerPosition`
  - `playerFacing`
  - `movementMode`
  - `party`
  - `trainerProfile`
  - `bag`
  - `progression`
  - `scriptVariables`
  - `storyFlags`
  - `consumedEventIds`
  - `metadata`
- `StoryFlags.activeFlags` est un `Set<String>`.
- `ScriptVariables.values` est une map de `ScriptVariableValue`.
- `PlayerProgression` contient notamment :
  - `unlockedFieldAbilities`
  - `storyFlags`
  - `completedStepIds`
  - `completedCutsceneIds`
  - species vues/capturées.
- `SaveData` persiste progression, bag, party, trainer profile et money via
  `TrainerProfile.money`.

Facts et steps :

- Les facts techniques existants sont portés par plusieurs sources :
  - `storyFlags.activeFlags`
  - `progression.completedStepIds`
  - `scriptVariables`
  - bag/items
  - party
  - trainer profile / money
  - consumed events
- `completedStepIds` est la source technique observée pour Step completion.
- `storyFlags` est la source technique observée pour plusieurs facts.

Save/load :

- Les tests repérés couvrent la persistance de `storyFlags` et
  `completedStepIds`.
- La normalisation de save hydrate les story flags depuis progression si les
  flags runtime sont vides, et garde les flags runtime explicites sinon.

Interprétation prudente :

- Un FactDescriptor futur ne doit pas dupliquer l’état durable.
- Un Story Step Descriptor futur ne doit pas réécrire `completedStepIds`.
- Availability peut être dérivée de conditions, flags, steps ou metadata, mais
  aucune grammaire canonique n’est encore stabilisée.

Risque :

- dupliquer un Fact dans `storyFlags`, `completedStepIds` et un futur registry ;
- transformer Fact en simple label cosmétique de flag brut ;
- créer une save migration sans besoin prouvé.

## 9. Inventory — ScriptCondition / condition evaluator

Fichiers :

```text
packages/map_core/lib/src/models/script_conditions.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
```

Observation technique :

- `ScriptCondition` contient :
  - `type`
  - `params`
  - `children`
- Types observés :
  - `allOf`
  - `anyOf`
  - `not`
  - `flagIsSet`
  - `flagIsUnset`
  - `variableEquals`
  - `variableGreaterThan`
  - `variableLessThan`
  - `fieldAbilityUnlocked`
  - `partyHasMove`
  - `partyHasUsableMove`
  - `eventIsConsumed`
  - `playerOnMap`
- Params observés :
  - `flagName`
  - `variableName`
  - `value`
  - `ability`
  - `moveId`
  - `eventId`
  - `mapId`
- `ScriptConditionEvaluator` lit le `GameState` :
  - story flags ;
  - variables ;
  - abilities ;
  - party moves ;
  - consumed events ;
  - current map.

Mapping possible vers no-code :

- `flagIsSet` / `flagIsUnset` peuvent alimenter des phrases du type
  “si le fait X est vrai/faux”.
- `variableEquals` et comparaisons peuvent rester avancées.
- `playerOnMap` peut alimenter des conditions authoring.

Absences observées :

- pas de condition générique directe `stepCompleted` dans `ScriptCondition` ;
- pas de condition directe bag/item/money observée dans ce DSL ;
- pas de DSL de Fact humain séparé.

Interprétation prudente :

- Il vaut mieux envisager une couche de présentation/adapter pour phrases
  no-code avant de créer un nouveau DSL.

Risque :

- divergence entre conditions runtime, validator et authoring ;
- créer un DSL concurrent au lieu d’adapter `ScriptCondition`.

## 10. Inventory — MapEntityRuntimePredicate / World Rule base

Fichiers :

```text
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
```

Observation technique :

- `MapEntityRuntimePredicateKind` expose :
  - `storyFlagSet`
  - `storyFlagUnset`
  - `stepCompleted`
  - `stepNotCompleted`
  - `chapterCompleted`
  - `chapterNotCompleted`
  - `cutsceneCompleted`
  - `cutsceneNotCompleted`
- `MapEntityNpcVisibilityRule` combine un mode et un predicate.
- Modes de visibilité NPC :
  - `always`
  - `visibleWhen`
  - `hiddenWhen`
- `MapEntityConditionalDialogue` associe un predicate à un dialogue.
- L’evaluator lit :
  - `gameState.storyFlags.activeFlags`
  - `gameState.progression.completedStepIds`
  - `gameState.progression.completedCutsceneIds`
  - un index de chapter runtime.
- `isNpcPresentOnMap` applique la visibility rule aux NPCs.
- `resolveNpcDialogue` choisit le premier dialogue conditionnel vrai, puis
  retombe sur le dialogue de base.

Observation importante :

- Ces predicates sont passifs : ils lisent l’état et projettent présence /
  dialogue.
- Ils ne déclenchent pas de scène.
- Ils n’écrivent pas de facts.
- Ils ne complètent pas de steps.

Interprétation prudente :

- La base technique World Rule existe déjà pour présence/dialogue NPC.
- Un WorldRuleRegistry complet n’est pas prouvé nécessaire.
- Un adapter de predicate vers vocabulaire World Rule semble plus probable
  qu’un nouveau registry, mais P2-08 doit décider.

Risques :

- deux chemins World Rule coexistent déjà : predicates map entity et Step Studio
  world presence runtime ;
- conflits possibles si les deux règles touchent la même entité ;
- validation actuelle incomplète sur les collisions de rules.

## 11. Inventory — NarrativeValidator / ProjectValidator

Fichiers :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
```

Observation technique — `NarrativeValidator` :

- `diagnoseNarrativeProject(ProjectManifest, {Iterable<MapData> maps})`
  produit un rapport multi-diagnostics.
- Sévérités observées :
  - `error`
  - `warning`
- Diagnostics observés :
  - `scenarioNodeReferencesUnknownNode`
  - `scenarioGraphHasUnreachableNode`
  - `scenarioGraphHasNoSource`
  - `openDialogueReferencesUnknownDialogue`
  - `startTrainerBattleMissingTrainerId`
  - `startTrainerBattleReferencesUnknownTrainer`
  - `startTrainerBattleMissingNpcEntityId`
  - `startTrainerBattleBlankBattleId`
  - `sourceEntityInteractReferencesUnknownMap`
  - `sourceEntityInteractReferencesUnknownEntity`
  - `sourceOutcomeWithoutMatchingEmitOutcome`
  - `emitOutcomeWithoutMatchingSourceOutcome`
  - `conditionalDialogueReferencesUnknownDialogue`
  - `flagReadNeverProduced`
  - `setFlagNeverRead`
  - `stepReadNeverCompleted`
  - `completeStepNeverRead`
- Inputs :
  - `ProjectManifest`
  - maps optionnelles.
- Le validator collecte :
  - dialogues connus ;
  - trainers connus ;
  - maps et entities connues ;
  - outcomes émis/consommés ;
  - flags produits/lus ;
  - steps complétés/lus.

Observation technique — `ProjectValidator` :

- `ProjectValidator` valide structurellement le projet et lève une exception.
- Il valide notamment :
  - ids/noms de scénarios ;
  - uniqueness ;
  - nodes et edges ;
  - start node unique ;
  - entry node ;
  - references dialogue/script/map/trainer ;
  - contraintes de scope ;
  - conditions de payload ;
  - edges choice/condition/end.

Ce qui manque côté diagnostics narratifs :

- diagnostics Storyline / Chapter canoniques ;
- diagnostics FactDescriptor ;
- diagnostics World Rule conflits ;
- diagnostics availability Storyline/Step ;
- diagnostics Quest Journal/Quest Engine, qui restent hors scope ;
- diagnostics reward/money/XP.

Interprétation prudente :

- Phase 2 doit étendre le validator existant plutôt que créer un second
  validator concurrent.
- `ProjectValidator` doit rester la validation structurelle stricte.
- `NarrativeValidator` doit rester diagnostic auteur.

## 12. Inventory — Scenario runtime events / executor / effects

Fichiers :

```text
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
```

Observation technique — source events :

- `ScenarioRuntimeSourceType` expose :
  - `mapEnter`
  - `triggerEnter`
  - `entityInteract`
  - `outcomeReceived`
- `ScenarioRuntimeSourceEvent` expose des factories :
  - `mapEnter(mapId)`
  - `triggerEnter(mapId, triggerId)`
  - `entityInteract(mapId, entityId)`
  - `outcomeReceived(outcomeId)`

Observation technique — effect types :

- `ScenarioRuntimeEffectType` expose :
  - `dialogue`
  - `script`
  - `message`
  - `battle`
  - `none`
- `ScenarioRuntimeEffect` peut porter :
  - `dialogueId`
  - `scriptId`
  - `message`
  - `battleId`
  - `trainerId`
  - `npcEntityId`

Observation technique — executor :

- Sources scenario reconnues par action kind :
  - `sourceMapEnter`
  - `sourceTriggerEnter`
  - `sourceEntityInteract`
  - `sourceOutcome`
- Actions runtime observées :
  - `runScript`
  - `openDialogue`
  - `showMessage`
  - `moveCharacter`
  - `followCharacter`
  - `faceCharacter`
  - `transitionMap`
  - `setFlag`
  - `clearFlag`
  - `emitOutcome`
  - `startTrainerBattle`
  - `givePokemon`
  - `giveItem`
  - `completeStep`
  - `flowMerge`
  - `authoringPlaceholder`
- `emitOutcome` persiste un flag `scenario.outcome.<outcomeId>`.
- `startTrainerBattle` retourne un effet battle et suspend le graphe.
- `completeStep` appelle `GameStateMutations.completeStep`.
- Les nodes `choice` sont explicitement bloqués dans l’executor MVP.
- Les références non-source restent authoring-only / bloquées.

Relation avec Event / Scene / Yarn / Battle :

- Event runtime existe déjà comme source.
- Scene est actuellement exécutée par `ScenarioRuntimeExecutor` sur
  `ScenarioAsset`.
- Outcomes locaux peuvent router vers global story via `outcomeReceived`.
- Battle est lancé comme effet, puis la continuation runtime reprend ensuite.

Question P2-03 :

```text
Comment formaliser Event côté auteur sans dupliquer ScenarioRuntimeSourceEvent ?
```

Question P2-04 :

```text
Scene doit-elle rester ScenarioAsset + executor, ou recevoir un adapter produit ?
```

## 13. Inventory — Battle outcome flags

Fichier :

```text
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
```

Observation technique :

- Préfixe de flag :
  - `battle:`
- Suffixes observés :
  - `victory`
  - `defeat`
  - `flee`
  - `captured`
- Helper observé :
  - `scenarioBattleOutcomeFlagName(battleId, outcomeSuffix)`

Interprétation prudente :

- Le code connaît déjà plus que `victory` / `defeat`, mais P1/P2 propose de
  limiter le contrat V0 battle à `victory` / `defeat` tant que capture/flee et
  static wild ne sont pas stabilisés.
- Cette limitation doit être une décision P2-06, pas une conclusion P2-01.

Risques :

- aspirer capture, flee, static wild, money, XP et rewards dans Phase 2 ;
- faire du battle outcome le moteur narratif principal ;
- coupler `map_battle` au Narrative Studio.

## 14. Inventory — Global Story / Step Studio runtime metadata

Fichiers :

```text
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
```

Observation technique — Global Story runtime :

- Lit `authoring.globalStoryStudioDocument` depuis les metadata de scénarios
  `globalStory`.
- Construit un `GlobalStoryChapterStepIndex`.
- Mappe chapter id vers step ids.
- Un chapter est completed si :
  - le chapter existe ;
  - il a des steps ;
  - tous les step ids sont présents dans `completedStepIds`.
- Un chapter inconnu ou vide n’est pas completed.
- JSON invalide ou metadata absente sont ignorés silencieusement.

Observation technique — Step Studio world presence runtime :

- Lit `authoring.stepStudioDocument`.
- Extrait les `worldChanges` des steps.
- Rules observées :
  - `visibleBeforeStepCompletion`
  - `visibleAfterStepCompletion`
  - `hiddenAfterStepCompletion`
  - `visibleOnlyWhenCompleted`
- Applique les règles aux NPCs.
- Combine les règles correspondantes avec une logique stricte.
- Les changements non-NPC sont signalés comme sans effet runtime actuel dans
  les commentaires.

Interprétation prudente :

- Storyline / Chapter / Step ont déjà une présence editor/runtime via metadata.
- Cette présence n’est pas encore un contrat domaine pur `map_core`.
- P2-02 doit décider si ces metadata suffisent, si un descriptor minimal est
  nécessaire, ou si un adapter read-only est préférable.

Risques :

- metadata editor cachée utilisée comme source de vérité sans diagnostic ;
- duplication avec `completedStepIds` ;
- double système World Rule avec map entity predicates.

## 15. Inventory — Narrative editor projections and authoring

Fichiers :

```text
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
```

Observation technique — Narrative workspace projection :

- Produit une projection read-only depuis `ProjectManifest.scenarios`.
- Résumés observés :
  - `NarrativeScenarioSummary`
  - `NarrativeStepSummary`
  - `NarrativeOutcomeSummary`
  - `NarrativeWorkspaceProjection`
- Sépare global stories, local event flows, steps et outcomes.
- Parse Step Studio depuis les scénarios globaux.
- Collecte outcomes déclarés, émis et consommés.
- Sert déjà de base naturelle à des picker sources futures.

Observation technique — Step Studio authoring :

- Metadata keys :
  - `authoring.stepStudioSchema`
  - `authoring.stepStudioDocument`
- Concepts observés :
  - activation modes ;
  - completion modes ;
  - cutscene roles ;
  - outcome scopes ;
  - world changes ;
  - step ids, names, descriptions, order.
- Les helpers écrivent dans `ScenarioAsset.metadata`.
- Les metadata legacy `step.*` sont encore écrites pour compatibilité.
- `flowUnlocksStepId` est documenté comme annotation sans effet runtime.

Observation technique — Global Story Studio authoring :

- Metadata keys :
  - `authoring.globalStoryStudioSchema`
  - `authoring.globalStoryStudioDocument`
- Concepts observés :
  - entry step ;
  - nodes ;
  - chapters ;
  - step links ;
  - exit modes.
- Diagnostics editor observés :
  - entry invalide ;
  - step node manquant ;
  - lien invalide ;
  - branche incomplète ;
  - step orphelin ;
  - dead end.

Observation technique — Cutscene Studio :

- Metadata keys :
  - `authoring.cutsceneSchema`
  - `authoring.cutsceneFlow`
- Le document d’authoring se compile vers `ScenarioAsset`.
- Les blocs incluent dialogue, narration, movement, transition, scene result,
  runScript, set/clear flag, emit outcome, question joueur et placeholders.
- Le runtime ne supporte pas tous les blocs : certains compilent en
  `authoringPlaceholder`.

Interprétation prudente :

- `map_editor` contient déjà beaucoup de vocabulaire no-code.
- Ces classes ne doivent pas devenir la source de vérité domaine simplement
  parce qu’elles existent.
- Une future source de picker pourrait s’appuyer sur
  `NarrativeWorkspaceProjection`, mais P2-10 doit décider.

## 16. Inventory — Project scenario use cases

Fichier :

```text
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
```

Observation technique :

- Les use cases permettent de créer, mettre à jour et supprimer des
  `ScenarioAsset`.
- Les ids sont générés de façon unique à partir d’un nom normalisé.
- La création/update/delete passe par `ProjectValidator.validate(updated)`.
- Le repository projet est sauvegardé après validation.

Interprétation prudente :

- Les use cases editor persistent aujourd’hui des `ScenarioAsset`, pas des
  `Scene` product contracts distincts.
- Si P2-04 introduit un adapter Scene, ces use cases devront probablement être
  adaptés ou encadrés, mais P2-01 ne décide rien.

Risques :

- créer un wrapper Scene sans intégrer les use cases existants ;
- contourner `ProjectValidator` ;
- faire de l’éditeur la seule source de vérité d’un contrat domaine.

## 17. Cross-cutting source-of-truth map

| Concept Phase 1 | Source technique actuelle | Nature | Consumer actuel | Consumer futur probable | Risque |
|---|---|---|---|---|---|
| Storyline | `ScenarioAsset.scope == globalStory`, Global Story metadata | Metadata / scenario | Editor projection, runtime chapter index | Picker / validator / descriptor éventuel | Créer modèle persistant prématuré |
| Chapter | `authoring.globalStoryStudioDocument.chapters` | Metadata editor lue runtime | Runtime chapter predicates | Step/Story diagnostics | Chapter caché dans metadata |
| Story Step | Step Studio metadata + `completedStepIds` | Metadata + stockage durable | Runtime world presence, predicates | Step descriptor / picker | Dupliquer completion |
| Event | `ScenarioRuntimeSourceEvent` + source nodes | Runtime + scenario nodes | Runtime executor | Event authoring adapter | Dupliquer source events |
| Scene | `ScenarioAsset` | Persisté | Runtime executor, editor use cases | Scene adapter/read model | Wrapper inutile |
| Cinematic | Cutscene Studio metadata compilée en scénario | Metadata / authoring | Editor, scenario runtime partiel | Cinematic reference contract | Promettre builder complet |
| Yarn outcome | `declaredOutcomes`, `emitOutcome`, `sourceOutcome`, flags `scenario.outcome.*` | Scenario + flag | Runtime + validator | Outcome reference contract | OutcomeRegistry trop tôt |
| Battle reference | `startTrainerBattle` binding/payload | Scenario action | Runtime battle handoff | Battle reference contract | Aspirer rewards/XP |
| Battle outcome | `battle:<battleId>:<suffix>` flags | Convention runtime | Runtime continuation/tests | Outcome contract V0 | Étendre trop vite |
| Fact | `storyFlags`, variables, steps, bag, party, money | Stocké ou dérivé | Conditions/predicates/runtime | Fact descriptor/presentation | Dupliquer état |
| World Rule | Map entity predicates + Step Studio world presence | Predicate/runtime adapter | Runtime map entity filtering | Predicate adapter | Rules concurrentes |
| Validator | `NarrativeValidator`, `ProjectValidator` | Diagnostics + validation | Tests, future editor | Diagnostics expanded | Validators concurrents |
| Picker source | `NarrativeWorkspaceProjection`, manifest entries | Read-only projection | Editor | Picker read models | Confondre widget et read model |

## 18. Candidate contract implications

| Contrat candidat | Implication P2-01 | Statut provisoire | Consumer attendu | Attention |
|---|---|---|---|---|
| Story Step Descriptor | Step metadata + `completedStepIds` existent déjà | Descriptor possible, à décider P2-02 | Validator, picker, editor | Ne pas dupliquer completion |
| Storyline metadata | `ScenarioScope.globalStory` + Global Story metadata existent | Adapter probable, à décider P2-02 | Editor, validator | Persistence à challenger |
| Event Authoring Source | Runtime source events existent | Adapter probable | Editor/pickers, validator | Ne pas dupliquer runtime |
| Scene / ScenarioAsset Adapter | `ScenarioAsset` existe | Adapter/read model probable, décision P2-04 | Editor, runtime, validator | Wrapper inutile possible |
| Outcome Reference Contract | Outcomes déclarés/émis/consommés existent | Nouveau contrat léger ou adapter | Validator, picker | Pas de registry lourd trop tôt |
| Battle Reference / Outcome Contract | `startTrainerBattle` + flags existent | Contrat minimal probable | Scene adapter, validator | Limiter V0 à décider |
| Fact Descriptor / Presentation Layer | State existe déjà | Presentation layer à challenger | Picker, labels, validator | Pas de duplication state |
| World Rule Predicate Adapter | Predicates existent | Adapter probable | Validator, editor, runtime | Conflits rules à diagnostiquer |
| Validator diagnostics | Validator V0 existe | Extension probable | Editor, CI, authoring | Pas d’autocorrection |
| Reference Picker Read Models | Projection editor existe | Read models probables plus tard | Phase 4 authoring | Pas de widget en Phase 2 |

## 19. Decisions to defer to P2-02+

Décisions reportées :

- Scene = `ScenarioAsset`, adapter ou wrapper ?
- Story Step Descriptor nécessaire ou metadata suffisante ?
- Storyline / Chapter persistants ou metadata/adapters ?
- FactDescriptor, Fact Presentation Layer ou FactRegistry ?
- WorldRuleRegistry ou Predicate Adapter ?
- OutcomeRegistry ou adapter de declared/emitted/consumed outcomes ?
- Battle outcome V0 limité à `victory` / `defeat` ou inclut `flee` /
  `captured` comme valeurs connues mais non utilisées ?
- Migration `ProjectManifest` nécessaire ou à refuser pour l’instant ?
- Les metadata editor doivent-elles rester dans `ScenarioAsset.metadata` ou
  recevoir un contrat `map_core` minimal ?

Décision immédiate de P2-01 :

```text
Aucune création de contrat. L’inventaire prépare les décisions P2-02+.
```

## 20. Risks and inconsistencies found

| Risque / incohérence | Observation | Impact possible | Garde-fou recommandé |
|---|---|---|---|
| Duplication d’état | `storyFlags`, progression story flags et `completedStepIds` coexistent | Facts incohérents | Source-of-truth par vérité avant contrat |
| Metadata editor comme source cachée | Step/Global Story/Cutscene stockent du JSON dans `ScenarioAsset.metadata` | Domaine difficile à valider | Adapter + diagnostics avant migration |
| Runtime source events dupliqués | Event authoring pourrait recréer ses propres sources | Divergence runtime/editor | Réutiliser ou adapter les source events |
| Validator divergent du runtime | Validator lit subset des actions/predicates | Faux positifs/négatifs | Tests ciblés par diagnostic Phase 2 |
| Migration ProjectManifest prématurée | Manifest est surface persistante centrale | Churn JSON et compatibilité | Aucune migration sans consumer clair |
| UI source de vérité | Editor authoring contient beaucoup de modèle produit | Couplage Flutter/domaine | Extraire seulement si besoin prouvé |
| ScenarioAsset surchargé | Tout peut être mis dans metadata/nodes | Modèle illisible | Adapter/read model borné |
| Fact flag cosmétique | Flag brut renommé en label humain | UX trompeuse | FactDescriptor doit nommer source et consumer |
| World Rule active déguisée | Predicate pourrait lancer ou compléter | Violation Phase 1 | World Rule lit/projette seulement |
| Reward/money/XP aspirés | NS-GS-18 montre gaps | Phase 2 gonflée | Reporter hors contrats narratifs V0 |

## 21. What P2-01 proves

P2-01 prouve seulement :

- l’état technique réel des structures narratives existantes ;
- les sources de vérité actuelles ;
- les metadata et projections déjà présentes ;
- les consumers observés ;
- les zones à risque ;
- les décisions qui devront être tranchées en P2-02+.

## 22. What P2-01 does not prove

P2-01 ne prouve pas :

- qu’un contrat doit être créé ;
- qu’un modèle `map_core` doit exister ;
- que JSON/migration est nécessaire ;
- que l’UI no-code existe ;
- que le runtime Flame complet fonctionne ;
- que Selbrume existe ;
- que Phase 2 est terminée ;
- que Scene doit forcément être un wrapper ;
- que FactRegistry ou WorldRuleRegistry sont nécessaires.

## 23. Recommended focus for P2-02

Focus recommandé :

```text
P2-02 — Story Step Descriptor / Storyline Metadata Decision
```

P2-02 devra décider, sur la base de P2-01 :

- si les metadata Step Studio et Global Story Studio suffisent en V0 ;
- si un descriptor minimal de Story Step est nécessaire ;
- comment éviter de dupliquer `completedStepIds` ;
- si Storyline / Chapter restent metadata/adapters ou deviennent contrats ;
- quels diagnostics Step/Storyline sont possibles immédiatement ;
- si les labels humains et picker sources nécessitent un read model pur ;
- quelle frontière garder entre `map_editor` authoring metadata et `map_core`
  domaine.

Recommandation prudente :

```text
Commencer P2-02 par la question Step Descriptor vs metadata adapter,
pas par la création d’un modèle persistant.
```

## 24. Mise à jour de road_map_phase_2.md

Mise à jour effectuée :

- `P2-01` marqué `✅ terminé`.
- `P2-02` marqué `🔜 prochain lot exact`.
- Résumé P2-01 ajouté.
- Fichiers créés/modifiés ajoutés.
- Commandes exécutées ajoutées.
- Décisions ouvertes et changements de périmètre ajoutés.

Prochain lot exact :

```text
P2-02 — Story Step Descriptor / Storyline Metadata Decision
```

`MVP Selbrume/road_map_global.md` n’a pas été modifiée.

## 25. Evidence Pack

### 25.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 25.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
```

### 25.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
```

### 25.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 25.5 Commandes exécutées

Note P2-01-bis :
Les commandes abrégées de la première version du rapport ont été remplacées par
les commandes exactes ou exploitables disponibles dans l’historique du lot. Les
commandes de recherche très longues sont conservées comme commandes complètes
sur une seule ligne dans le bloc ci-dessous.

```text
git status --short --untracked-files=all
sed -n '1,220p' skills/README.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
wc -l "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md" "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,220p' "MVP Selbrume/road_map_global.md"
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,220p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
sed -n '221,520p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
sed -n '261,520p' "MVP Selbrume/road_map_phase_2.md"
rg -n "Verdict|Phase 1|P2-00|P2-01|P2-02|Concepts figés|Frontières validées|Décisions restantes|réserves|ScenarioAsset|Fact|World Rule|Story Step|Storyline|Chapter|Validator|Evidence Pack|Auto-review" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
rg -n "Storyline|Chapter|Story Step|Event|Scene|Cinematic|Yarn|Battle|Fact|World Rule|Validator|Selbrume|Golden Slice|side quest|Outcome|P2|Phase 2|anti-pattern|source|metadata" reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
wc -l packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_gameplay/lib/src/script_condition_evaluator.dart packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
rg --files packages/map_runtime/lib/src/application/scenario_runtime packages/map_editor/lib/src/features/narrative | sort
rg -n "Level|preuve|validator|NarrativeValidator|side quest|optional storyline|completedStepIds|storyFlags|reward|money|XP|battle|World Rule|Fact|Step|ScenarioAsset|diagnostic|gap|limite" reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
rg -n "ScenarioAsset|NarrativeValidator|diagnoseNarrativeProject|ScenarioRuntimeExecutor|StepStudio|GlobalStoryStudio|scenarioBattleOutcomeFlagName|completedStepIds|storyFlags|ProjectValidator|sourceOutcome|emitOutcome|completeStep|MapEntityRuntimePredicate" packages/map_core/test packages/map_gameplay/test packages/map_runtime/test packages/map_editor/test examples/playable_runtime_host/test
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
rg -n "metadata|ScenarioAsset|declaredOutcomes|ScenarioNode|emitOutcome|sourceOutcome|battle|trainer|dialogue|cutscene|ScenarioScope|authoring" packages/map_editor/lib/src/features/narrative/application/cutscene_studio packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart packages/map_editor/lib/src/features/narrative/application/cutscene_studio_runtime_advisories.dart
sed -n '1,220p' "MVP Selbrume/road_map_phase_2.md"
sed -n '221,520p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,240p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff -- "MVP Selbrume/road_map_phase_2.md"
git diff --no-prefix --unified=0 -- "MVP Selbrume/road_map_phase_2.md"
git diff --no-prefix -- "MVP Selbrume/road_map_phase_2.md" | sed 's/[[:blank:]]$//'
perl -pi -e 's/[ \t]+$//' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
```

### 25.6 git diff --check

```text
```

### 25.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 61 ++++++++++++++++++++++++++++++++--------
 1 file changed, 49 insertions(+), 12 deletions(-)
```

### 25.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 25.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
```

### 25.10 Tests / analyze

```text
Non exécutés — P2-01 est documentaire et ne modifie aucun code.
```

### 25.11 Contrôle rapport P2-01 créé

Commande :

```text
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md || true
```

Sortie exacte :

```text
```

### 25.12 Contrôle hors scope

Commande :

```text
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host
```

Sortie exacte :

```text
```

### 25.13 Preuve Markdown créée/modifiée

Le contenu complet du rapport créé est le présent fichier, sections 1 à 26.

Diff complet de la roadmap modifiée :

````text
diff --git a/MVP Selbrume/road_map_phase_2.md b/MVP Selbrume/road_map_phase_2.md
index b23748c9..0375b235 100644
--- a/MVP Selbrume/road_map_phase_2.md
+++ b/MVP Selbrume/road_map_phase_2.md
@@ -6,15 +6,15 @@ Phase 2 — Domain Model & Contracts

 Statut : 🔜 En cours

-Lot courant : P2-01 — Existing Narrative Domain Inventory
+Lot courant : P2-02 — Story Step Descriptor / Storyline Metadata Decision

-Prochain lot exact : P2-01 — Existing Narrative Domain Inventory
+Prochain lot exact : P2-02 — Story Step Descriptor / Storyline Metadata Decision

 Suivi des lots :

 - ✅ P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
-- 🔜 P2-01 — Existing Narrative Domain Inventory
-- P2-02 — Story Step Descriptor / Storyline Metadata Decision
+- ✅ P2-01 — Existing Narrative Domain Inventory
+- 🔜 P2-02 — Story Step Descriptor / Storyline Metadata Decision
 - P2-03 — Event Authoring Source Contract
 - P2-04 — Scene / ScenarioAsset Adapter Contract
 - P2-05 — Outcome Reference Contracts
@@ -27,7 +27,9 @@ Suivi des lots :

 P2-00 : ✅ terminé

-P2-01 : 🔜 prochain lot exact
+P2-01 : ✅ terminé
+
+P2-02 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 2

@@ -190,17 +192,52 @@ pas de Selbrume final.
 Dépendances :
 P1-CHECKPOINT-01.

-### 🔜 P2-01 — Existing Narrative Domain Inventory
+### ✅ P2-01 — Existing Narrative Domain Inventory

 Objectif :
 Inventorier `ScenarioAsset`, metadata narrative, validators, runtime source
 events, predicates, save state et authoring projections.

-Frontière héritée de P2-00 :
-P2-01 doit produire l’inventaire technique détaillé que P2-00 a volontairement
-laissé hors scope : champs, usages, sources de vérité, conventions metadata,
-risques de migration et preuves exactes. P2-01 ne doit pas encore créer les
-contrats Phase 2.
+Résultat :
+P2-01 produit l’inventaire technique détaillé de l’existant narratif :
+`ScenarioAsset`, `ProjectManifest`, `GameState` / `SaveData`,
+`ScriptCondition`, predicates de map entity, validators, runtime events,
+executor, flags de battle outcome, metadata Global Story / Step Studio,
+projections editor et use cases scénario. Le lot sépare vérité observée,
+interprétation prudente, risques et décisions à reporter.
+
+Fichiers créés :
+
+- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
+
+Fichiers modifiés :
+
+- `MVP Selbrume/road_map_phase_2.md`
+
+Commandes exécutées :
+
+- `git status --short --untracked-files=all`
+- `sed -n '1,220p' "MVP Selbrume/road_map_global.md"` et commandes `sed -n` listées exactement en section 25.5 du rapport P2-01
+- `rg -n "Verdict|Phase 1|P2-00|P2-01|P2-02|Concepts figés|Frontières validées|Décisions restantes|réserves|ScenarioAsset|Fact|World Rule|Story Step|Storyline|Chapter|Validator|Evidence Pack|Auto-review" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`
+- `wc -l packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_gameplay/lib/src/script_condition_evaluator.dart packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
+- `rg --files packages/map_runtime/lib/src/application/scenario_runtime packages/map_editor/lib/src/features/narrative | sort`
+- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md || true`
+- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host`
+- `git diff --check`
+- `git diff --stat`
+- `git diff --name-only`
+- `git status --short --untracked-files=all`
+
+Décisions utilisateur nouvelles :
+Aucune décision imposée. P2-01 reporte explicitement à P2-02+ les choix
+Story Step Descriptor, Storyline/Chapter metadata, FactDescriptor,
+WorldRule adapter, Outcome adapter, Scene/ScenarioAsset adapter et éventuelle
+migration `ProjectManifest`.
+
+Changements de périmètre :
+Aucun changement de périmètre. P2-01 confirme que l’approche Phase 2 doit
+rester audit-first puis décision par contrat, sans modèle persistant tant que
+les consumers ne sont pas clairs.

 Risque :
 Sous-estimer les conventions déjà présentes dans metadata editor.
@@ -446,5 +483,5 @@ Phase 2 ne prouve pas le runtime Flame complet.
 Le prochain lot exact est :

```text
-P2-01 — Existing Narrative Domain Inventory
+P2-02 — Story Step Descriptor / Storyline Metadata Decision
```
````

## 26. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

- Oui. Seuls le rapport P2-01 et la roadmap Phase 2 vivante sont modifiés.

Le rapport P2-01 existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`.

`road_map_phase_2.md` a-t-elle été mise à jour ?

- Oui, P2-01 est marqué terminé et P2-02 devient le prochain lot exact.

`road_map_global.md` est-elle restée intacte ?

- Oui, contrôle hors scope ajouté dans l’Evidence Pack.

Aucun code n’a-t-il été modifié ?

- Oui. Aucun fichier sous `packages` ou `examples/playable_runtime_host` n’a
  été modifié.

Aucun test/analyze Dart/Flutter n’a-t-il été lancé ?

- Oui. P2-01 est documentaire.

P2-02 n’a-t-il pas été commencé ?

- Oui. P2-02 est seulement recommandé comme prochain focus.

L’inventaire est-il détaillé mais borné ?

- Oui. Il couvre les zones demandées sans documenter chaque champ secondaire
  de tous les modèles du repo.

Les observations sont-elles séparées des recommandations ?

- Oui. Les sections distinguent observation technique, interprétation prudente,
  risques et décisions futures.

Les décisions à trancher sont-elles claires ?

- Oui. Elles sont listées en section 19 et orientent P2-02+.

Le prochain lot exact est-il clair ?

- Oui : `P2-02 — Story Step Descriptor / Storyline Metadata Decision`.

Regard critique sur le prompt :

- Le prompt demande un inventaire précis mais interdit de décider les contrats.
  La frontière est saine, mais elle exige une discipline forte dans la section
  “Candidate contract implications” : les statuts sont donc formulés comme
  provisoires.
- La demande de preuve Markdown complète peut devenir récursive pour le rapport
  créé lui-même. Le présent rapport contient son propre contenu complet et
  ajoute les validations Git exactes pour éviter un renvoi vague au dépôt.
