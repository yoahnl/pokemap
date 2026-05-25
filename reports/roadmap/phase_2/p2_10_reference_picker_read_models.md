# P2-10 — Reference Picker Read Models

## 1. Résumé exécutif

P2-10 implémente un premier batch borné de read models purs dans `map_core`.

Read models ajoutés :

- `NarrativeScenarioPickerOption`
- `NarrativeOutcomePickerOption`
- `NarrativeBattleReferencePickerOption`

Fonctions de dérivation ajoutées :

- `buildNarrativeScenarioPickerOptions(ProjectManifest)`
- `buildNarrativeOutcomePickerOptions(ProjectManifest)`
- `buildNarrativeBattleReferencePickerOptions(ProjectManifest)`

Ces read models sont dérivés de `ProjectManifest`, `ScenarioAsset`, des nodes
`emitOutcome`, `sourceOutcome`, `startTrainerBattle` et des
`ProjectTrainerEntry`. Ils ne créent aucune persistence, aucun registry, aucune
UI et aucune nouvelle source de vérité.

Read models reportés :

- Story Step picker ;
- Fact Presentation picker ;
- World Rule picker ;
- Event Source picker.

Fichiers modifiés ou créés :

- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- `packages/map_core/lib/map_core.dart`
- `MVP Selbrume/road_map_phase_2.md`
- `reports/roadmap/phase_2/p2_10_reference_picker_read_models.md`

Tests et validations :

- test rouge initial observé sur API absente ;
- test ciblé P2-10 vert ;
- test ciblé `narrative_validator_test.dart` vert ;
- `dart analyze` vert dans `packages/map_core`.

Prochain lot exact :

```text
P2-CHECKPOINT-01 — Domain Contracts Readiness Review
```

## 2. Scope du lot

Inclus :

- read models purs ;
- fonctions pures de construction depuis `ProjectManifest` ;
- tests ciblés ;
- export `map_core` ;
- mise à jour roadmap ;
- rapport P2-10 avec Evidence Pack.

Exclus :

- widgets ;
- UI ;
- runtime ;
- editor ;
- gameplay ;
- battle ;
- registries ;
- `ProjectManifest` ;
- `GameState` / `SaveData` ;
- JSON / migration ;
- build_runner ;
- P2-CHECKPOINT.

## 3. Sources lues

Instructions et skills :

- `AGENTS.md` : règles repo, boundaries, Git safety, validation package par package.
- `skills/README.md` : index local des workflows.
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `MVP Selbrume/road_map_phase_1.md`
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md`
- `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`
- `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md`
- `reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md`
- `reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md`
- `reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md`
- `reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md`
- `reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md`
- `reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md`
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`

Code et tests :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_core/test/scenario_assets_test.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`

## 4. Rappel Phase 1 / P2-01 à P2-09

Rappels utiles :

- Event déclenche.
- Scene orchestre.
- Outcome clarifie branches et résultats.
- Battle outcome reste séparé du scenario outcome.
- Fact nomme sans recopier `GameState`.
- World Rule projette passivement.
- Validator diagnostique.
- Picker read models dérivent sans persister.

P2-04 a recommandé une vue produit Scene non persistante dérivée de
`ScenarioAsset`.

P2-05 a recommandé un `OutcomeReferenceReadModel` futur sans
`OutcomeRegistry`.

P2-06 a recommandé un `BattleReferenceReadModel` futur sans `BattleRegistry`,
avec V0 conceptuel limité à `victory` / `defeat`.

P2-09 a ajouté les diagnostics `declaredOutcomeNeverEmitted`,
`emitOutcomeNotDeclared`, `visibilityRuleConditionalMissingPredicate`,
`worldRulePredicateEmptyRefId` et `scenarioChoiceNodeRuntimeUnsupported`.

P2-10 transforme la partie la plus stable de cette trajectoire en sources pures
de pickers.

## 5. Problème à résoudre

Les futurs pickers Phase 4 ne doivent pas lire directement des graphes
techniques ni exposer les IDs bruts comme langage principal.

Ils ont besoin de sources :

- pures Dart ;
- dérivées des modèles persistants existants ;
- stables dans leur tri ;
- testées ;
- lisibles côté auteur ;
- capables de garder les IDs techniques comme debug/source, pas comme unique
  label principal.

P2-10 doit produire ces sources sans créer de widget, registry, JSON, migration
ou nouvelle source de vérité.

## 6. Inventaire des sources de picker existantes

| Source | Utilisation P2-10 | Statut |
|---|---|---|
| `ProjectManifest.scenarios` | Base des options Scenario/Scene et outcome/battle traversal. | Source persistante existante. |
| `ProjectManifest.trainers` | Résolution des labels de trainer pour battle refs. | Source persistante existante. |
| `ScenarioAsset.id/name/description/scope/entryNodeId` | Label et contexte des options Scenario/Scene. | Source persistante existante. |
| `ScenarioAsset.declaredOutcomes` | Outcomes déclarés. | Source persistante existante, pas registry global. |
| `ScenarioAsset.nodes` | Traversal des nodes `emitOutcome`, `sourceOutcome`, `startTrainerBattle`. | Source persistante existante. |
| `ScenarioNodeBinding.outcomeId` | Outcome émis ou consommé. | Source technique existante. |
| `ScenarioNodeBinding.trainerId/entityId` | Référence trainer et NPC d'un battle node. | Source technique existante. |
| `ScenarioNodePayload.actionKind` | Détection des actions et source nodes utiles. | Convention existante. |
| `ScenarioNodePayload.params['battleId']` | Battle id authoré optionnel. | Convention existante, fallback sur trainer id. |
| `NarrativeWorkspaceProjection` editor | Inspiration seulement. | Non modifiée, pas source de vérité domaine. |
| Diagnostics P2-09 | Contexte de qualité pour outcomes et runtime support. | Non consommés directement par le read model V0. |

## 7. Read models candidats

| Candidat | Verdict | Raison |
|---|---|---|
| Scenario / Scene picker | Implémenté | Source stable, dérivable de `ProjectManifest.scenarios`, utile Phase 4. |
| Outcome picker | Implémenté | Source stable, dérivable de declared/emitted/consumed outcomes, cohérent P2-05/P2-09. |
| Battle reference picker | Implémenté | Source stable, dérivable de `startTrainerBattle` + trainers, cohérent P2-06. |
| Story Step picker | Reporté | Metadata Step Studio / Global Story encore trop spécifique editor pour P2-10 V0. |
| Fact presentation picker | Reporté | P2-07 a gardé Fact Presentation conceptuel, pas de read model stabilisé. |
| World Rule picker | Reporté | Requiert stratégie de conflits/priorités plus large. |
| Event source picker | Reporté | Utile, mais P2-10 garde un petit batch et P2-03 l'a cadré comme futur read model. |

## 8. Sélection des read models P2-10

Batch retenu :

1. `NarrativeScenarioPickerOption`
2. `NarrativeOutcomePickerOption`
3. `NarrativeBattleReferencePickerOption`

Raisons :

- sources stables ;
- dérivable de `ProjectManifest` + `ScenarioAsset` ;
- pas de migration ;
- pas de registry ;
- pas d'UI ;
- utile à Phase 4 authoring ;
- testable en pure Dart ;
- cohérent avec P2-04, P2-05, P2-06 et P2-09.

Fichiers impactés :

- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`

Tests prévus :

- tri stable et fallback label Scenario/Scene ;
- agrégation Outcome déclaré / émis / consommé ;
- Battle reference connue et inconnue, fallback `battleId`, outcomes V0.

Risques :

- transformer le read model en registry ;
- dupliquer `ScenarioAsset` ;
- donner des labels trop “UI finale” ;
- aspirer Step/Fact/World Rule/Event Source dans le même lot.

## 9. Read models implémentés

### `NarrativeScenarioPickerOption`

Fichier :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
```

Logique :

- parcourt `ProjectManifest.scenarios` ;
- expose `scenarioId`, `humanLabel`, `description`, `scope`, `entryNodeId`,
  `declaredOutcomeIds`, `nodeCount`, `edgeCount`, `debugTechnicalLabel` ;
- label = `ScenarioAsset.name.trim()` si non vide, sinon `scenarioId` ;
- `declaredOutcomeIds` est trim / dédupliqué / trié ;
- tri stable par label puis `scenarioId`.

Test associé :

```text
builds scenario picker options with stable labels and counts
```

### `NarrativeOutcomePickerOption`

Fichier :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
```

Logique :

- collecte `ScenarioAsset.declaredOutcomes` ;
- collecte les nodes `emitOutcome` ;
- collecte les nodes `sourceOutcome` ;
- expose `outcomeId`, `humanLabel`, `declaredByScenarioIds`,
  `emittedByScenarioIds`, `consumedByScenarioIds`, `isDeclared`, `isEmitted`,
  `isConsumed`, `isOrphan`, `debugTechnicalLabel` ;
- supporte `binding.outcomeId` et fallback défensif `payload.params['outcomeId']` ;
- label humain minimal par humanisation de l'ID technique ;
- tri stable par label puis `outcomeId`.

Test associé :

```text
builds outcome picker options from declared emitted and consumed ids
```

### `NarrativeBattleReferencePickerOption`

Fichier :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
```

Logique :

- collecte les nodes `startTrainerBattle` ;
- résout `ProjectManifest.trainers` par `trainerId` ;
- expose `battleReferenceId`, `battleId`, `humanLabel`, `sourceScenarioId`,
  `sourceNodeId`, `trainerId`, `trainerLabel`, `trainerClass`, `npcEntityId`,
  `isTrainerKnown`, `supportedOutcomeKinds`, `debugTechnicalLabel` ;
- `battleReferenceId = sourceScenarioId:sourceNodeId` ;
- `battleId = params['battleId']`, sinon `trainerId`, sinon
  `sourceScenarioId:sourceNodeId` ;
- label = classe + nom du trainer connu, sinon fallback technique ;
- outcomes supportés V0 = `victory` / `defeat` via
  `NarrativeBattleOutcomeKind` ;
- tri stable par label puis `battleReferenceId`.

Test associé :

```text
builds battle reference picker options from trainer battle nodes
```

## 10. Read models reportés

Story Step picker :

- reporté car P2-02 a confirmé que les steps restent metadata + read model
  futur ;
- il faut éviter de transformer `completedStepIds` en registry ou de faire des
  metadata editor une source de vérité domaine implicite.

Fact Presentation picker :

- reporté car P2-07 a explicitement refusé un `FactRegistry` ;
- les flags/outcomes/battle flags ne deviennent pas automatiquement des Facts.

World Rule picker :

- reporté car P2-08 a gardé `MapEntityRuntimePredicate` et Step Studio world
  presence comme sources techniques ;
- il manque encore une stratégie de conflits/priorités.

Event Source picker :

- reporté car P2-03 l'a recommandé comme read model futur ;
- le batch Scenario/Outcome/Battle couvre déjà le budget utile P2-10.

## 11. Design d’implémentation

Design retenu :

- un fichier `src/read_models/narrative_reference_picker_read_models.dart` ;
- types `final class` immuables, sans JSON, sans Freezed ;
- fonctions pures depuis `ProjectManifest` ;
- export public dans `map_core.dart` ;
- listes exposées en `List.unmodifiable` ;
- tri stable case-insensitive puis tie-break technique ;
- labels avec fallback sur ID ;
- IDs techniques conservés dans les champs source/debug ;
- aucun stockage et aucun registry.

Le read model ne contient ni `ScenarioAsset`, ni `ProjectManifest`, ni objet
runtime/editor. Il expose seulement des options dérivées.

## 12. Fichiers modifiés

Fichiers créés :

- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- `reports/roadmap/phase_2/p2_10_reference_picker_read_models.md`

Fichiers modifiés :

- `packages/map_core/lib/map_core.dart`
- `MVP Selbrume/road_map_phase_2.md`

## 13. Tests ajoutés ou modifiés

Fichier ajouté :

- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`

Tests ajoutés :

- `builds scenario picker options with stable labels and counts`
- `builds outcome picker options from declared emitted and consumed ids`
- `builds battle reference picker options from trainer battle nodes`

Tests existants exécutés :

- `packages/map_core/test/narrative_validator_test.dart`

## 14. Résultats des tests / analyze

Test rouge initial :

```text
dart test test/narrative_reference_picker_read_models_test.dart
```

Résultat observé :

```text
Failed to load "test/narrative_reference_picker_read_models_test.dart":
Type 'NarrativeOutcomePickerOption' not found.
Method not found: 'buildNarrativeScenarioPickerOptions'.
Method not found: 'buildNarrativeOutcomePickerOptions'.
Method not found: 'buildNarrativeBattleReferencePickerOptions'.
Undefined name 'NarrativeBattleOutcomeKind'.
```

Résultats finaux :

```text
dart format lib/src/read_models/narrative_reference_picker_read_models.dart lib/map_core.dart test/narrative_reference_picker_read_models_test.dart
Formatted 3 files (0 changed) in 0.01 seconds.

dart test --reporter json test/narrative_reference_picker_read_models_test.dart | tail -n 1
{"success":true,"type":"done","time":477}

dart test --reporter json test/narrative_validator_test.dart | tail -n 1
{"success":true,"type":"done","time":512}

dart analyze
Analyzing map_core...
No issues found!
```

## 15. Impacts sur P2-CHECKPOINT et Phase 4

P2-CHECKPOINT pourra vérifier que Phase 2 possède désormais :

- des diagnostics P2-09 ;
- des sources de picker pures P2-10 ;
- des décisions explicites contre les registries persistants prématurés ;
- une base `map_core` consommable par Phase 4 sans UI codée ici.

Phase 4 pourra utiliser :

- `NarrativeScenarioPickerOption` pour Scene/Event target pickers ;
- `NarrativeOutcomePickerOption` pour outcome pickers et diagnostics
  actionnables ;
- `NarrativeBattleReferencePickerOption` pour battle pickers et labels trainer.

## 16. Risques et garde-fous

| Risque | Garde-fou P2-10 |
|---|---|
| Read model qui devient registry | Aucune persistence, aucune mutation, aucune source globale nouvelle. |
| Read model trop large | Batch limité à trois familles. |
| Labels humains trompeurs | Labels minimalistes, fallback technique conservé. |
| Duplication de `ScenarioAsset` | Les read models exposent des options, pas un graphe parallèle. |
| Tri instable | Tri explicite par label puis ID. |
| Tests fragiles | Tests sur sorties stables et champs contractuels. |
| Scope creep vers UI | Aucun package Flutter modifié. |
| Dépendance editor/runtime accidentelle | Implémentation localisée dans `map_core`, imports uniquement modèles core. |

## 17. Ce que P2-10 décide

- Ajouter un batch de read models purs Scenario/Outcome/Battle.
- Garder `ProjectManifest` et `ScenarioAsset` comme sources techniques.
- Garder les read models dérivés et non persistants.
- Exporter les read models depuis `map_core`.
- Reporter Story Step, Fact, World Rule et Event Source pickers.
- Ne créer aucun registry.
- Ne créer aucune UI.
- Ne créer aucune migration.
- Prochain lot = checkpoint Phase 2.

## 18. Ce que P2-10 ne décide pas

- UI Phase 4.
- Widgets Flutter.
- Scene Builder.
- Workflow authoring final.
- Selbrume réel.
- Migration `ProjectManifest`.
- Registries persistants.
- Runtime execution.
- Story Step picker final.
- Fact Presentation picker final.
- World Rule picker final.
- Event Source picker final.

## 19. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` a été mise à jour.

Statut attendu appliqué :

```text
P2-10 : ✅ terminé
P2-CHECKPOINT-01 : 🔜 prochain lot exact
```

Résumé court :

- read models purs Scenario/Outcome/Battle ajoutés ;
- tests ciblés ajoutés ;
- `map_core.dart` exporte les nouveaux read models ;
- aucun package hors `map_core` modifié ;
- prochain lot exact = `P2-CHECKPOINT-01 — Domain Contracts Readiness Review`.

## 20. Evidence Pack

### 20.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 20.2 Fichiers lus

```text
AGENTS.md
skills/README.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/scenario_assets_test.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
```

### 20.3 Fichiers créés

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
```

### 20.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
packages/map_core/lib/map_core.dart
```

### 20.5 Commandes exécutées

```text
git status --short --untracked-files=all
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,260p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
find .. -name AGENTS.md -print
sed -n '1,240p' AGENTS.md
sed -n '1,220p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,180p' "MVP Selbrume/road_map_global.md"
sed -n '1,160p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,220p' reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
sed -n '1,180p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
sed -n '1,180p' reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
sed -n '1,180p' reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
sed -n '1,170p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
sed -n '1,190p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '1,180p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
sed -n '1,180p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
sed -n '1,170p' reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
sed -n '1,180p' reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
sed -n '1,170p' reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
sed -n '1,170p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
find packages/map_core/lib -maxdepth 4 -type f | sort
find packages/map_core/test -type f -name '*test.dart' | sort
rg -n "ReadModel|Picker|Reference|Projection|ScenarioAsset|declaredOutcomes|emitOutcome|sourceOutcome|startTrainerBattle|ProjectTrainerEntry|NarrativeWorkspaceProjection" packages/map_core packages/map_editor
sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,240p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,220p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '220,560p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '760,880p' packages/map_core/lib/src/validation/validators.dart
sed -n '560,900p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,240p' packages/map_core/test/scenario_assets_test.dart
sed -n '1,220p' packages/map_core/test/narrative_validator_test.dart
sed -n '119,240p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,118p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '240,360p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '220,520p' packages/map_core/test/scenario_assets_test.dart
sed -n '220,520p' packages/map_core/test/narrative_validator_test.dart
sed -n '520,900p' packages/map_core/test/narrative_validator_test.dart
sed -n '360,460p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
find packages/map_core/lib/src -maxdepth 2 -type d | sort
rg -n "ProjectTrainerEntry|trainerClass|battleId|startTrainerBattle" packages/map_core/test packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation
dart test test/narrative_reference_picker_read_models_test.dart
dart format lib/src/read_models/narrative_reference_picker_read_models.dart lib/map_core.dart test/narrative_reference_picker_read_models_test.dart
dart test test/narrative_reference_picker_read_models_test.dart
dart format test/narrative_reference_picker_read_models_test.dart && dart test test/narrative_reference_picker_read_models_test.dart
sed -n '1,260p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,320p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
git diff -- packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart packages/map_core/lib/map_core.dart packages/map_core/test/narrative_reference_picker_read_models_test.dart
sed -n '260,620p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
dart analyze
dart test test/narrative_validator_test.dart
rg -n "P2-09|P2-10|P2-CHECKPOINT" "MVP Selbrume/road_map_phase_2.md"
sed -n '520,760p' "MVP Selbrume/road_map_phase_2.md"
git diff --stat
git status --short --untracked-files=all
sed -n '760,940p' "MVP Selbrume/road_map_phase_2.md"
dart format lib/src/read_models/narrative_reference_picker_read_models.dart lib/map_core.dart test/narrative_reference_picker_read_models_test.dart
NO_COLOR=1 dart test --reporter compact test/narrative_reference_picker_read_models_test.dart
NO_COLOR=1 dart test --reporter compact test/narrative_validator_test.dart
dart test --reporter expanded test/narrative_reference_picker_read_models_test.dart
dart test --reporter expanded test/narrative_validator_test.dart
dart test --reporter json test/narrative_reference_picker_read_models_test.dart | tail -n 1
dart test --reporter json test/narrative_validator_test.dart | tail -n 1
dart analyze
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle packages/map_runtime packages/map_editor packages/map_gameplay examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_10_reference_picker_read_models.md || true
git diff --no-index --check /dev/null packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart || true
git diff --no-index --check /dev/null packages/map_core/test/narrative_reference_picker_read_models_test.dart || true
```

### 20.6 git diff --check

```text
Sortie vide — aucun problème détecté.
```

### 20.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md    | 102 +++++++++++++++++++++++++++++++++---
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 96 insertions(+), 7 deletions(-)
```

### 20.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
packages/map_core/lib/map_core.dart
```

### 20.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
?? packages/map_core/test/narrative_reference_picker_read_models_test.dart
?? reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
```

### 20.10 Tests / analyze

```text
dart format lib/src/read_models/narrative_reference_picker_read_models.dart lib/map_core.dart test/narrative_reference_picker_read_models_test.dart
Formatted 3 files (0 changed) in 0.01 seconds.

dart test --reporter json test/narrative_reference_picker_read_models_test.dart | tail -n 1
{"success":true,"type":"done","time":477}

dart test --reporter json test/narrative_validator_test.dart | tail -n 1
{"success":true,"type":"done","time":512}

dart analyze
Analyzing map_core...
No issues found!
```

### 20.11 Contrôle hors scope

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle packages/map_runtime packages/map_editor packages/map_gameplay examples/playable_runtime_host
```

Sortie :

```text
Sortie vide — aucun changement hors scope détecté.
```

### 20.12 Contrôle packages sans code hors scope

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
```

Sortie :

```text
packages/map_core/lib/map_core.dart
```

### 20.13 Contrôle rapport créé

Commande :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_10_reference_picker_read_models.md || true
```

Sortie :

```text
Sortie vide — aucun problème détecté.
```

## 21. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui. Les modifications sont limitées à map_core, au rapport P2-10 et à la roadmap Phase 2.
```

Le rapport P2-10 existe-t-il au bon chemin ?

```text
Oui : reports/roadmap/phase_2/p2_10_reference_picker_read_models.md.
```

road_map_phase_2.md a-t-elle été mise à jour ?

```text
Oui.
```

road_map_global.md est-elle restée intacte ?

```text
Oui, aucun changement attendu ni observé dans road_map_global.md.
```

Aucun package hors map_core n’a-t-il été modifié ?

```text
Oui.
```

Aucun widget UI n’a-t-il été créé ?

```text
Oui.
```

Aucun registry n’a-t-il été créé ?

```text
Oui.
```

Aucun ProjectManifest/JSON/migration n’a-t-il été modifié ?

```text
Oui. ProjectManifest n'est pas modifié, aucun JSON/migration n'est créé.
```

Les read models sont-ils dérivés de l’existant ?

```text
Oui. Ils dérivent de ProjectManifest, ScenarioAsset, ScenarioNode et ProjectTrainerEntry.
```

Les read models ont-ils un tri stable ?

```text
Oui. Tri case-insensitive par label puis par identifiant technique.
```

Les labels ont-ils un fallback robuste ?

```text
Oui. Scenario fallback sur scenarioId, outcome humanisé depuis outcomeId, battle fallback sur trainerId/battleId/referenceId.
```

Les tests ciblés passent-ils ?

```text
Oui. Le test P2-10 et le test narrative_validator ciblé passent.
```

L’analyze map_core est-il propre ou les dettes sont-elles documentées ?

```text
Oui. `dart analyze` est propre dans packages/map_core.
```

P2-CHECKPOINT n’a-t-il pas été commencé ?

```text
Oui. Il est seulement marqué comme prochain lot exact.
```

Le prochain lot exact est-il clair ?

```text
Oui : P2-CHECKPOINT-01 — Domain Contracts Readiness Review.
```

Regard critique sur le prompt :

```text
Le prompt est très cadrant et protège bien le lot contre le glissement vers UI,
registries ou persistence. Sa recommandation de batch 2 à 4 familles est utile :
elle permet de produire un socle réel sans ouvrir Story Step, Fact, World Rule
et Event Source trop tôt. Le point le plus délicat est que `git diff --check`
ne couvre pas les fichiers non suivis ; P2-10 compense par format, tests,
analyze et contrôle no-index du rapport.
```
