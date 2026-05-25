# Phase 2 Roadmap — Domain Model & Contracts

## 1. Statut de la phase

Phase 2 — Domain Model & Contracts

Statut : 🔜 En cours

Lot courant : P2-10 — Reference Picker Read Models

Prochain lot exact : P2-10 — Reference Picker Read Models

Suivi des lots :

- ✅ P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
- ✅ P2-01 — Existing Narrative Domain Inventory
- ✅ P2-02 — Story Step Descriptor / Storyline Metadata Decision
- ✅ P2-03 — Event Authoring Source Contract
- ✅ P2-04 — Scene / ScenarioAsset Adapter Contract
- ✅ P2-05 — Outcome Reference Contracts
- ✅ P2-06 — Battle Reference / Outcome Contract
- ✅ P2-07 — Fact Descriptor / Presentation Layer
- ✅ P2-08 — World Rule Predicate Adapter Contract
- ✅ P2-09 — Narrative Validator Diagnostic Expansion
- 🔜 P2-10 — Reference Picker Read Models
- P2-CHECKPOINT-01 — Domain Contracts Readiness Review

P2-00 : ✅ terminé

P2-01 : ✅ terminé

P2-02 : ✅ terminé

P2-03 : ✅ terminé

P2-04 : ✅ terminé

P2-05 : ✅ terminé

P2-06 : ✅ terminé

P2-07 : ✅ terminé

P2-08 : ✅ terminé

P2-09 : ✅ terminé

P2-10 : 🔜 prochain lot exact

## 2. Objectif de la Phase 2

Transformer la grammaire produit Phase 1 en socle domaine minimal, testable et
utilisable par les phases suivantes.

La Phase 2 doit construire ou stabiliser seulement les contrats qui ont des
consumers explicites :

- `map_core` diagnostics / contracts / read models ;
- `map_gameplay` condition et GameState si nécessaire ;
- `map_runtime` adapters d’exécution plus tard ;
- `map_editor` authoring workflows et picker sources plus tard ;
- save/load et project disk si un besoin persistant est prouvé.

Règle centrale :

```text
Pas de modèle sans consumer clair.
Pas de registry sans usage clair.
Pas de JSON/migration si le besoin n’est pas justifié.
```

## 3. Pourquoi cette phase existe

La Phase 1 a fermé la grammaire produit :

```text
Storyline organise.
Chapter sectionne.
Story Step jalonne.
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Yarn produit des outcomes.
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
World Rule projette passivement.
Validator diagnostique.
```

La Phase 2 doit maintenant vérifier comment cette grammaire se raccorde aux
structures existantes : `ScenarioAsset`, metadata editor, `completedStepIds`,
`storyFlags`, predicates runtime, `ProjectManifest`, `NarrativeValidator` et
sources de picker futures.

## 4. Préconditions

- Phase 1 clôturée avec réserves mineures.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 2.
- Selbrume reste une référence conceptuelle.

## 5. Périmètre Phase 2

Inclus :

- audit de l’existant narratif ;
- décisions descriptor / adapter / contrat / report ;
- contrats domaine pure Dart si nécessaires ;
- diagnostics Validator prioritaires ;
- read models et sources de picker sans UI ;
- stratégie persistence / JSON / migration ;
- package boundaries.

Exclus :

- UI moderne ou premium ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- runtime Flame Golden Slice ;
- projet disque Selbrume ;
- contenu Selbrume final ;
- Reward Model unifié ;
- Quest Engine ;
- Quest Journal ;
- money / XP / level-up ;
- static wild authoring complet ;
- Door/Warp Engine complet.

## 6. Non-objectifs stricts

- Ne pas créer Selbrume final.
- Ne pas créer de `project.json` Selbrume.
- Ne pas lancer Phase 3 runtime/disk.
- Ne pas lancer Phase 4 authoring UI.
- Ne pas lancer Phase 7 UI premium.
- Ne pas coupler `map_battle` au Narrative Studio.
- Ne pas faire de `map_editor` la source de vérité domaine.
- Ne pas modifier `ProjectManifest` sans décision explicite et migration
  documentée.

## 7. Lots Phase 2 proposés

### ✅ P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Objectif :
Vérifier le découpage Phase 2, cadrer l’audit domaine, clarifier la frontière
avec P2-01 et confirmer les premiers lots de contrats sans inventaire exhaustif.

Résultat :
P2-00 valide la roadmap Phase 2 avec une réserve de wording : P2-00 cadre
l’audit, tandis que P2-01 fera l’inventaire détaillé. Le lot confirme
l’approche audit-first, liste les zones à inventorier et prépare P2-01 sans
créer de contrat ni modifier de code.

Fichiers créés :

- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `test -f "MVP Selbrume/road_map_phase_2.md" ...`
- `sed -n '1,260p' "MVP Selbrume/road_map_global.md"`
- `sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '261,520p' "MVP Selbrume/road_map_phase_2.md"`
- `rg -n ...` sur les rapports Phase 1 et documents de contexte
- `rg --files ...` sur les zones code candidates
- `rg -n ...` sur les zones code candidates
- `find .. -name AGENTS.md -print`
- `ls -la reports/roadmap && ls -la reports/roadmap/phase_1`
- `mkdir -p reports/roadmap/phase_2`

Décisions utilisateur nouvelles :
Aucune décision nouvelle imposée. Les décisions ouvertes restent à valider
pendant P2-01 ou les lots de contrats.

Changements de périmètre :
Aucun changement de périmètre. Clarification uniquement : P2-00 prépare la
carte, P2-01 explore le territoire.

Zones probables à inventorier en P2-01 :

- `reports/roadmap/phase_1/*`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `packages/map_core/lib/src/models/*`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/*`
- `packages/map_editor/lib/src/features/narrative/*`

Risque :
Créer trop tôt des modèles au lieu de caractériser l’existant.

Tests probables :
Pas de test obligatoire si le lot reste audit/documentaire. Si un audit outillé
est ajouté, il doit rester borné et justifié.

Non-objectifs :
Pas de contrat codé, pas de modèle `map_core`, pas de JSON, pas de migration,
pas de Selbrume final.

Dépendances :
P1-CHECKPOINT-01.

### ✅ P2-01 — Existing Narrative Domain Inventory

Objectif :
Inventorier `ScenarioAsset`, metadata narrative, validators, runtime source
events, predicates, save state et authoring projections.

Résultat :
P2-01 produit l’inventaire technique détaillé de l’existant narratif :
`ScenarioAsset`, `ProjectManifest`, `GameState` / `SaveData`,
`ScriptCondition`, predicates de map entity, validators, runtime events,
executor, flags de battle outcome, metadata Global Story / Step Studio,
projections editor et use cases scénario. Le lot sépare vérité observée,
interprétation prudente, risques et décisions à reporter.

Fichiers créés :

- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `sed -n ...` sur les roadmaps et rapports Phase 1 / Phase 2 ciblés
- `rg -n ...` sur les concepts narratifs, rapports NS-GS et tests associés
- `wc -l ...` sur les fichiers code critiques
- `rg --files ...` sur `scenario_runtime` et `features/narrative`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

Décisions utilisateur nouvelles :
Aucune décision imposée. P2-01 reporte explicitement à P2-02+ les choix
Story Step Descriptor, Storyline/Chapter metadata, FactDescriptor,
WorldRule adapter, Outcome adapter, Scene/ScenarioAsset adapter et éventuelle
migration `ProjectManifest`.

Changements de périmètre :
Aucun changement de périmètre. P2-01 confirme que l’approche Phase 2 doit
rester audit-first puis décision par contrat, sans modèle persistant tant que
les consumers ne sont pas clairs.

Risque :
Sous-estimer les conventions déjà présentes dans metadata editor.

Tests probables :
Caractérisation si des read models d’inventaire sont créés.

Non-objectifs :
Pas de nouveau modèle persistant.

Dépendances :
P2-00.

### ✅ P2-02 — Story Step Descriptor / Storyline Metadata Decision

Objectif :
Décider si Storyline / Chapter / Story Step démarrent comme descriptors,
metadata légère, adapter, ou report partiel.

Résultat :
P2-02 recommande une trajectoire adapter/read model non persistant pour
Storyline / Chapter / Story Step. Les metadata Step Studio / Global Story
Studio restent la source authoring actuelle, `completedStepIds` reste la source
de completion, et les descriptors persistants / migrations `ProjectManifest`
sont refusés pour l'instant. P2-02 prépare P2-03 sans créer de modèle, contrat,
JSON, adapter, read model ni diagnostic implémenté.

Fichiers créés :

- `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `find .. -name AGENTS.md -print`
- `sed -n '1,260p' "MVP Selbrume/road_map_global.md"`
- `sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"`
- `sed -n '1,260p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `sed -n '261,620p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `sed -n '621,1040p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `sed -n '1041,1380p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `sed -n '1,240p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
- `rg -n "Storyline|Chapter|Story Step|Descriptor|metadata|adapter|read model|completedStepIds|ProjectManifest|P2-02|Fact|World Rule|Validator|picker|persistence|migration" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`
- `sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart`
- `sed -n '1,180p' packages/map_core/lib/src/models/game_state.dart`
- `rg -n "storyFlags|completedStepIds|completedCutsceneIds|normalizeLoadedGameState|gameStateFromSaveData|saveDataFromGameState|PlayerProgression|StoryFlags" packages/map_core/lib/src/models/save_data.dart`
- `sed -n '1,220p' packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `sed -n '1,260p' packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short`

Décisions utilisateur nouvelles :
La trajectoire recommandée est adapter/read model non persistant avant toute
persistence. Les décisions restant à valider portent sur le moment exact où ce
read model sera implémenté, et sur les seuils qui justifieraient plus tard une
migration `ProjectManifest`.

Changements de périmètre :
Aucun changement de périmètre. P2-02 confirme que Phase 2 reste audit-first et
contractuelle, sans Selbrume final, sans UI et sans modèle persistant prématuré.

Risque :
Dupliquer `completedStepIds` ou transformer Story Step en flag technique brut.

Tests probables :
Diagnostics pure Dart sur steps inconnus, orphelins ou jamais complétés si un
contrat est créé.

Non-objectifs :
Pas de Quest Engine, pas de Quest Journal.

Dépendances :
P2-01.

### ✅ P2-03 — Event Authoring Source Contract

Objectif :
Formaliser les sources auteur d’Event sans dupliquer inutilement les runtime
source events.

Résultat :
P2-03 reste design-only. Le lot audite `ScenarioRuntimeSourceEvent`, les nodes
`sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract` et
`sourceOutcome`, puis refuse tout modèle persistant, toute migration
`ProjectManifest` et toute modification runtime. La trajectoire recommandée est
un `EventAuthoringSourceReadModel` non persistant futur, dérivé de
`ScenarioAsset` et de ses source nodes existants. Event reste un déclencheur :
source + condition + target, sans orchestration.

Fichiers créés :

- `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `sed -n '1,260p' "MVP Selbrume/road_map_global.md"`
- `sed -n '1,360p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"`
- `sed -n '1,260p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md`
- `sed -n '1,260p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
- `sed -n '1,320p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `sed -n '1,260p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`
- `rg -n "Event|ScenarioRuntimeSourceEvent|ScenarioRuntimeSourceType|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|ScenarioNodeBinding|activationCondition|Validator|authoring source|P2-03" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`
- `sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart`
- `sed -n '1,260p' packages/map_core/lib/src/models/script_conditions.dart`
- `sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart`
- `sed -n '1,320p' packages/map_core/lib/src/operations/narrative_validator.dart`
- `sed -n '1,260p' packages/map_core/lib/src/validation/validators.dart`
- `sed -n '1,320p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `sed -n '1,360p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `sed -n '1,360p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short`

Décisions utilisateur nouvelles :
La décision recommandée est de ne pas créer de contrat Dart maintenant. Le
contrat conceptuel `EventAuthoringSourceReadModel` est reporté jusqu'à ce que
P2-04 stabilise la relation Scene / `ScenarioAsset`, puis P2-09/P2-10 précisent
diagnostics et picker read models.

Changements de périmètre :
Aucun changement de périmètre. P2-03 confirme que l'authoring source adapte
l'existant et que le runtime reste runtime.

Risque :
Transformer Event en mini-Scene.

Tests probables :
Validation de références source / target si contrat créé.

Non-objectifs :
Pas de runtime Flame.

Dépendances :
P2-01.

### ✅ P2-04 — Scene / ScenarioAsset Adapter Contract

Objectif :
Décider si Scene est le nom produit de `ScenarioAsset`, un wrapper, ou un
adapter/read model.

Résultat :
P2-04 reste design-only. Le lot décide que `ScenarioAsset` demeure le substrat
technique persistant et exécutable, tandis que Scene est la vue produit
d'orchestration à dériver de ce substrat. La trajectoire recommandée est un
futur `SceneReadModel` / `SceneScenarioAdapter` non persistant, attendu après
P2-05/P2-09/P2-10 si les outcomes, diagnostics et picker sources le justifient.
Aucun wrapper Scene persistant, aucune migration `ProjectManifest`, aucun code
et aucun Scene Builder ne sont créés.

Fichiers créés :

- `reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `sed -n '1,260p' "MVP Selbrume/road_map_global.md"`
- `sed -n '1,420p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"`
- `sed -n '1,260p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md`
- `sed -n '1,260p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
- `sed -n '1,380p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `sed -n '1,320p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`
- `sed -n '1,360p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md`
- `sed -n '1,320p' reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
- `sed -n '1,320p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`
- `sed -n '1,260p' reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`
- `sed -n '1,220p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md`
- `sed -n '1,220p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`
- `sed -n '1,320p' packages/map_core/lib/src/models/scenario_asset.dart`
- `sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart`
- `sed -n '1,320p' packages/map_core/lib/src/operations/narrative_validator.dart`
- `sed -n '1,320p' packages/map_core/lib/src/validation/validators.dart`
- `sed -n '321,760p' packages/map_core/lib/src/operations/narrative_validator.dart`
- `sed -n '321,760p' packages/map_core/lib/src/validation/validators.dart`
- `sed -n '1,360p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `sed -n '1,420p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `sed -n '421,920p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `rg -n "_validateScenarios|declaredOutcomes|activationCondition|entryNodeId|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|emitOutcome|openDialogue|startTrainerBattle|flowMerge|authoringPlaceholder" packages/map_core/lib/src/validation/validators.dart`
- `sed -n '760,1180p' packages/map_core/lib/src/validation/validators.dart`
- `sed -n '760,980p' packages/map_core/lib/src/operations/narrative_validator.dart`
- `sed -n '920,1260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `sed -n '1,360p' packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `sed -n '1,420p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `sed -n '1,360p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `sed -n '1260,1480p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `sed -n '360,780p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `sed -n '1,420p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart`
- `rg -n "ScenarioAsset|ScenarioScope|globalStory|localEventFlow|ScenarioNode|ScenarioNodeType|ScenarioEdge|ScenarioNodePayload|ScenarioNodeBinding|declaredOutcomes|activationCondition|entryNodeId|ProjectValidator|NarrativeValidator|ScenarioRuntimeExecutor|ScenarioRuntimeEffect|ScenarioRuntimeEffectType|openDialogue|runScript|showMessage|startTrainerBattle|completeStep|emitOutcome|authoringPlaceholder|flowMerge" packages/map_core/lib/src packages/map_runtime/lib/src/application/scenario_runtime packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart packages/map_editor/lib/src/features/narrative/application/cutscene_studio`
- `sed -n '420,860p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart`
- `sed -n '780,1180p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `sed -n '1,220p' AGENTS.md`
- `sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`
- `sed -n '1,360p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '360,760p' "MVP Selbrume/road_map_phase_2.md"`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host`
- `git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short`

Décisions utilisateur nouvelles :
La décision recommandée est de ne pas créer de contrat Dart maintenant. Scene
devient la vue produit d'orchestration dérivée de `ScenarioAsset`, sans
persistence dédiée. Les décisions restant à valider portent sur le moment exact
où le read model sera implémenté et sur les champs stabilisés par P2-05/P2-09/P2-10.

Changements de périmètre :
Aucun changement de périmètre. P2-04 confirme l'approche adapter avant
persistence, sans code, sans JSON, sans UI et sans Selbrume final.

Risque :
Casser `ScenarioAsset` ou créer un modèle parallèle inutile.

Tests probables :
Adapter/read model et diagnostics de nodes/outcomes si contrat créé.

Non-objectifs :
Pas de Scene Builder complet.

Dépendances :
P2-01, P2-03.

### ✅ P2-05 — Outcome Reference Contracts

Objectif :
Rendre les outcomes Yarn / Scenario sélectionnables et validables sans exposer
`scenario.outcome.*` comme UX principale.

Résultat :
P2-05 reste design-only. Le lot refuse un `OutcomeRegistry` persistant, garde
`declaredOutcomes`, `emitOutcome` et `sourceOutcome` comme sources techniques
actuelles, et recommande un futur `OutcomeReferenceReadModel` non persistant
dérivé de `ScenarioAsset`. Le rapport distingue outcome déclaré, émis,
consommé et persisté sous flag technique `scenario.outcome.*`, sans transformer
automatiquement outcome en Fact et sans fusionner battle outcomes avant P2-06.
Aucun code, aucun JSON, aucune migration et aucun package ne sont modifiés.

Fichiers créés :

- `reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `ctx_search(sort="timeline", source="session-events", queries=[...], limit=3)`
- `ctx_batch_execute(commands=[P2-05 Required Roadmap And Reports Outcome Terms, Scenario Outcome Model And Runtime Terms, Scenario Runtime Executor Outcome Focus, Narrative Validator Outcome Diagnostics Focus, Project Validator Declared Outcome Focus, Narrative Workspace Outcome Projection Focus, Cutscene Studio Outcome Compile Focus], queries=[...])`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host`
- `git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short`

Décisions utilisateur nouvelles :
La décision recommandée est de ne pas créer de contrat Dart maintenant. Les
outcomes restent dérivés de `ScenarioAsset`; un read model outcome pourra être
créé plus tard si P2-09/P2-10 le justifient.

Changements de périmètre :
Aucun changement de périmètre. P2-05 confirme que Battle outcome reste séparé
jusqu'à P2-06 et que Fact Descriptor reste à P2-07.

Risque :
Créer un OutcomeRegistry trop tôt.

Tests probables :
Outcomes déclarés / émis / consommés / orphelins.

Non-objectifs :
Pas de parser Yarn complet.

Dépendances :
P2-04.

### ✅ P2-06 — Battle Reference / Outcome Contract

Objectif :
Stabiliser un contrat minimal de référence battle et outcomes `victory` /
`defeat`.

Résultat :
P2-06 reste design-only. Le lot décide de ne créer aucun modèle persistant,
aucun `BattleRegistry`, aucune migration `ProjectManifest` et aucune
modification `map_battle`. Les sources techniques actuelles restent
`startTrainerBattle`, `ProjectManifest.trainers`, `ScenarioRuntimeEffect.battle`
et les flags `battle:<battleId>:<suffix>`. Le V0 narratif recommandé se limite
à `victory` / `defeat` ; `flee` et `captured` sont reconnus comme suffixes
techniques existants mais restent hors contrat narratif V0. Rewards, money, XP,
level-up, capture authoring et static wild authoring restent reportés hors
P2-06. La trajectoire recommandée est un futur `BattleReferenceReadModel` non
persistant dérivé de `ScenarioAsset` + `ProjectManifest.trainers`, si P2-09 /
P2-10 le justifient.

Fichiers créés :

- `reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `find .. -name AGENTS.md -print`
- `test -f skills/README.md && sed -n '1,220p' skills/README.md || true`
- `ctx_search(sort="timeline", source="session-events", queries=[...], limit=3)`
- `ctx_batch_execute(commands=[P2-06 mandatory roadmap and report references, Battle source grep in core runtime editor, ScenarioAsset battle-related definitions, Scenario runtime models battle effect, Scenario runtime executor battle handling, Scenario battle outcome flags, Narrative validator battle diagnostics, ProjectManifest trainers, Map battle and battle package outcome search, Narrative workspace battle summaries], queries=[...])`
- `ctx_search(queries=[...], limit=5)`
- `sed -n '1,420p' "MVP Selbrume/road_map_phase_2.md"`
- `sed -n '420,820p' "MVP Selbrume/road_map_phase_2.md"`
- `grep -nE "class ProjectTrainerEntry|ProjectTrainerEntry|trainerClass|team|party|pokemon|name" packages/map_core/lib/src/models/project_trainer.dart packages/map_core/lib/src/models/project_manifest.dart`
- `find packages/map_runtime/lib/src/application packages/map_battle/lib -type f -name '*.dart' -print | xargs grep -nE "BattleOutcome|outcome|victory|defeat|flee|captured|capture|reward|money|xp|level|ScenarioRuntimeEffectType\\.battle|scenarioBattleOutcomeFlagName" || true`
- `sed -n '1,120p' packages/map_core/lib/src/models/project_trainer.dart`
- `sed -n '1,220p' packages/map_battle/lib/src/domain/battle/battle_outcome.dart`
- `grep -nE "scenarioBattleOutcomeFlagName|kBattleOutcomeSuffix|battle:<|BattleOutcome|isVictory|isDefeat|victory|defeat|flee|captured|capture|trainer_defeated|onBattleFinished|BattleOutcome" packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart packages/map_runtime/lib/src/application/story_flags_manager.dart packages/map_runtime/lib/src/application/scenario_conditions.dart packages/map_runtime/lib/src/application/runtime_battle*.dart packages/map_battle/lib/src/domain/battle/battle_outcome.dart packages/map_battle/lib/src/battle_state.dart`
- `grep -nE "startTrainerBattle|trainerId|battleId|npcEntityId|ScenarioRuntimeEffectType\\.battle|Graphe suspendu|battle handoff" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `sed -n '160,240p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `sed -n '1,110p' packages/map_runtime/lib/src/application/scenario_conditions.dart && sed -n '1,80p' packages/map_runtime/lib/src/application/story_flags_manager.dart`
- `sed -n '760,890p' packages/map_core/lib/src/validation/validators.dart && sed -n '1110,1155p' packages/map_core/lib/src/validation/validators.dart`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host`
- `git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

Décisions utilisateur nouvelles :
Aucune décision utilisateur imposée. La décision recommandée pour la suite est
de garder battle outcome séparé de scenario outcome et de réserver un éventuel
`BattleReferenceReadModel` non persistant à P2-09/P2-10 si les diagnostics ou
pickers le justifient.

Changements de périmètre :
Aucun changement de périmètre. P2-06 confirme que rewards, money, XP,
level-up, capture authoring, flee authoring et static wild authoring restent
hors Phase 2 contractuelle immédiate et hors P2-06.

Risque :
Aspirer money, XP, static wild et rewards dans Phase 2.

Tests probables :
Référence trainer/battle absente, outcome non géré, branch post-battle absente.

Non-objectifs :
Pas de static wild complet, pas de money/XP, pas de Reward Model unifié.

Dépendances :
P2-04.

### ✅ P2-07 — Fact Descriptor / Presentation Layer

Objectif :
Fournir des labels humains et relations de source/consumer pour les vérités du
monde, sans dupliquer le GameState.

Résultat :
P2-07 reste design-only. Le lot refuse un `FactRegistry` persistant, toute
modification `ProjectManifest`, toute modification `GameState` / `SaveData` et
toute duplication de `storyFlags` ou `completedStepIds`. Les vérités techniques
actuelles restent portées par `GameState`, `SaveData`, les flags
`scenario.outcome.*`, les flags `battle:<battleId>:<suffix>`, les flags
`trainer_defeated:<trainerId>`, les conditions et les predicates runtime. La
trajectoire recommandée est une future `FactPresentationReadModel` non
persistante, dérivée des sources techniques et des producers/consumers, si
P2-09/P2-10 le justifient. Outcomes, battle outcomes et World Rules ne
deviennent pas automatiquement Facts.

Fichiers créés :

- `reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md`
- `sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`
- `ctx_batch_execute(commands=[P2-07 roadmap and report fact references, Fact technical truth grep in core gameplay runtime editor, GameState and SaveData truth fields, ScriptCondition truth reads, GameState mutations truth writes, ScenarioAsset fact-producing actions and bindings, Narrative validator fact diagnostics, Runtime outcome and battle facts, World rule predicate truth reads, Narrative workspace fact/outcome projection], queries=[...])`
- `ctx_batch_execute(commands=[MapEntityRuntimePredicate definitions, Validator enum diagnostics exact], queries=[...])`
- `ctx_batch_execute(commands=[SaveData GameState conversion storyFlags mapping], queries=[...])`
- `ctx_batch_execute(commands=[SaveData conversion functions search], queries=[...])`
- `ctx_batch_execute(commands=[GameState persistence mapping], queries=[...])`
- `sed -n '1,840p' "MVP Selbrume/road_map_phase_2.md"`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host`
- `git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

Décisions utilisateur nouvelles :
Aucune décision utilisateur imposée. La décision recommandée pour la suite est
de garder Fact comme présentation lisible non persistante et de laisser P2-08
traiter World Rule séparément comme projection passive.

Changements de périmètre :
Aucun changement de périmètre. P2-07 confirme que les Facts ne créent pas une
nouvelle source de vérité et que tous les flags techniques ne deviennent pas des
Facts auteur.

Risque :
Créer un FactRegistry lourd ou exposer des flags bruts avec un label cosmétique.

Tests probables :
Fact inconnu, jamais écrit, jamais lu, technique sans label humain.

Non-objectifs :
Pas de duplication automatique de state.

Dépendances :
P2-02, P2-05.

### ✅ P2-08 — World Rule Predicate Adapter Contract

Objectif :
Adapter les predicates et projections conditionnelles existantes à la grammaire
World Rule.

Résultat :
P2-08 reste design-only. Le lot refuse un `WorldRuleRegistry` persistant, toute
modification `ProjectManifest`, toute modification `GameState` / `SaveData` et
toute duplication de `MapEntityRuntimePredicate` ou de Step Studio world
presence. Les sources techniques actuelles restent
`MapEntityRuntimePredicate`, `visibilityRule`, `conditionalDialogues`, Step
Studio world presence et `GlobalStoryChapterStepIndex`. La trajectoire
recommandée est une future `WorldRuleReadModel` /
`WorldRulePredicateAdapter` non persistante, dérivée des predicates et metadata
existants si P2-09/P2-10 le justifient. World Rule reste passive : elle lit une
vérité et projette le monde, sans déclencher Event/Scene, sans écrire Fact, sans
compléter Step et sans émettre Outcome.

Fichiers créés :

- `reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `test -f skills/README.md && sed -n '1,220p' skills/README.md || true`
- `sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md`
- `sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`
- `grep -nE ...` sur les roadmaps, rapports P1/P2 et termes World Rule
- `grep -nE ...` sur predicates, visibility rules, conditional dialogues,
  Step Studio world presence et diagnostics validator
- `sed -n ...` sur `map_entity_payloads.dart`,
  `map_entity_runtime_predicate_evaluator.dart`,
  `step_studio_world_presence_runtime.dart`,
  `global_story_chapter_runtime.dart`,
  `step_studio_authoring.dart`,
  `global_story_studio_authoring.dart`,
  `narrative_workspace_projection.dart`,
  `narrative_validator.dart` et `scenario_runtime_executor.dart`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host`
- `git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

Décisions utilisateur nouvelles :
Aucune décision utilisateur imposée. La décision recommandée pour la suite est
de garder World Rule comme projection passive non persistante et de laisser
P2-09 traiter l'expansion des diagnostics sans créer de registry.

Changements de périmètre :
Aucun changement de périmètre. P2-08 confirme que Fact nomme, World Rule
projette, Event déclenche et Scene orchestre.

Risque :
Créer un WorldRuleRegistry prématuré ou laisser World Rule déclencher des
Scenes.

Tests probables :
Condition absente, target absent, conflit de rules, rule utilisée comme Event.

Non-objectifs :
Pas de World Rule qui écrit des Facts ou complète des Steps.

Dépendances :
P2-07.

### ✅ P2-09 — Narrative Validator Diagnostic Expansion

Objectif :
Étendre les diagnostics narratifs prioritaires par domaine : Story Step, Event,
Scene, outcomes, Battle, Fact, World Rule et side quest.

Résultat :
P2-09 ajoute un premier batch borné de diagnostics au validator narratif
existant, sans créer de validator parallèle, registry, modèle persistant,
JSON/migration ou UI. Le lot implémente cinq diagnostics actionnables :
`declaredOutcomeNeverEmitted`, `emitOutcomeNotDeclared`,
`visibilityRuleConditionalMissingPredicate`, `worldRulePredicateEmptyRefId` et
`scenarioChoiceNodeRuntimeUnsupported`. Les tests ciblés
`packages/map_core/test/narrative_validator_test.dart` couvrent chaque nouveau
diagnostic, et `dart analyze` passe dans `packages/map_core`.

Fichiers créés :

- `reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md`

Fichiers modifiés :

- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `MVP Selbrume/road_map_phase_2.md`

Commandes exécutées :

- `git status --short --untracked-files=all`
- `find packages/map_core/test -type f -name '*test.dart' | sort`
- `rg -n "NarrativeValidator|NarrativeDiagnostic|ProjectValidator|flagReadNeverProduced|stepReadNeverCompleted|sourceOutcomeWithoutMatchingEmitOutcome|conditionalDialogueReferencesUnknownDialogue|startTrainerBattleMissingTrainerId|startTrainerBattleReferencesUnknownTrainer|startTrainerBattleMissingNpcEntityId|startTrainerBattleBlankBattleId|declaredOutcomes|emitOutcome|sourceOutcome|choice|reference|authoringPlaceholder|visibilityRule" packages/map_core/test packages/map_core/lib`
- `dart test test/narrative_validator_test.dart`
- `dart format lib/src/operations/narrative_validator.dart test/narrative_validator_test.dart`
- `dart test --reporter compact test/narrative_validator_test.dart`
- `dart analyze`
- `git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md || true`
- `git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle packages/map_runtime packages/map_editor packages/map_gameplay examples/playable_runtime_host`
- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- `git status --short --untracked-files=all`

Diagnostics ajoutés :

- `declaredOutcomeNeverEmitted`
- `emitOutcomeNotDeclared`
- `visibilityRuleConditionalMissingPredicate`
- `worldRulePredicateEmptyRefId`
- `scenarioChoiceNodeRuntimeUnsupported`

Diagnostics reportés :

- diagnostics post-battle victory/defeat jamais lus ;
- diagnostics Step Studio world presence target/source ;
- conflit world presence / visibility rule ;
- diagnostics Fact Presentation ;
- diagnostics side quest ;
- diagnostics runtime placeholder plus larges.

Risque :
Produire trop de diagnostics non actionnables.

Tests probables :
Tests unitaires ciblés par diagnostic.

Non-objectifs :
Pas d’auto-correction.

Dépendances :
P2-02 à P2-08.

### P2-10 — Reference Picker Read Models

Objectif :
Préparer les sources pures de pickers Phase 4 sans créer de widgets UI.

Risque :
Confondre read model et widget Flutter.

Tests probables :
Tri stable, labels humains, références cassées, listes filtrées.

Non-objectifs :
Pas d’UI Flutter, pas de design system.

Dépendances :
P2-09.

### P2-CHECKPOINT-01 — Domain Contracts Readiness Review

Objectif :
Clôturer Phase 2, vérifier les contrats créés/adaptés/reportés, les diagnostics
et les package boundaries.

Risque :
Clôturer avec des migrations ou duplications d’état cachées.

Tests probables :
Commandes ciblées selon les packages réellement modifiés en Phase 2.

Non-objectifs :
Pas de Phase 3 démarrée.

Dépendances :
P2-10.

## 8. Critères de sortie Phase 2

Phase 2 pourra être clôturée si :

- les contrats domaine nécessaires au Narrative Studio sont créés, adaptés ou
  explicitement reportés ;
- les diagnostics essentiels sont présents ou reportés avec justification ;
- les pickers Phase 4 disposent de sources de données propres ;
- les package boundaries restent respectées ;
- tout modèle persistant a une justification claire ;
- aucune migration `ProjectManifest` inutile n’est introduite ;
- aucun contenu Selbrume final n’est créé ;
- Phase 3 peut valider runtime/disk sur une base stable.

## 9. Règle permanente de maintenance

À chaque lot Phase 2, l’agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire `MVP Selbrume/road_map_phase_2.md`.
3. Lire les rapports Phase 1 pertinents.
4. Respecter le prochain lot exact.
5. Ne pas démarrer un autre lot.
6. Distinguer création, adaptation et report.
7. Justifier chaque nouveau contrat par des consumers explicites.
8. Fournir un Evidence Pack complet.
9. Mettre à jour cette roadmap vivante.
10. Ne modifier `road_map_global.md` qu’au checkpoint ou sur demande explicite.

## 10. Décisions à valider avant ou pendant P2-00

- Valider la roadmap Phase 2 proposée.
- Confirmer audit-first avant création directe de contrats.
- Décider si Scene est `ScenarioAsset`, wrapper ou adapter/read model.
- Décider FactDescriptor / Fact Presentation Layer avant FactRegistry.
- Décider World Rule Predicate Adapter avant WorldRuleRegistry.
- Décider si Storyline / Chapter deviennent persistants dès Phase 2.
- Confirmer que rewards, Quest Journal et UI premium restent reportés.

## 11. Rappels permanents

```text
Phase 2 construit les contrats utiles.
Phase 2 ne construit pas Selbrume.
Phase 2 ne construit pas l’UI premium.
Phase 2 ne prouve pas le runtime Flame complet.
```

Le prochain lot exact est :

```text
P2-10 — Reference Picker Read Models
```
