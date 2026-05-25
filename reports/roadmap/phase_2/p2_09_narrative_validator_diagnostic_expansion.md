# P2-09 — Narrative Validator Diagnostic Expansion

## 1. Résumé exécutif

P2-09 ajoute un premier batch borné de diagnostics au validator narratif
existant, sans créer de validator parallèle, sans registry, sans modèle
persistant et sans modification `ProjectManifest`.

Diagnostics implémentés :

1. `declaredOutcomeNeverEmitted`
2. `emitOutcomeNotDeclared`
3. `visibilityRuleConditionalMissingPredicate`
4. `worldRulePredicateEmptyRefId`
5. `scenarioChoiceNodeRuntimeUnsupported`

Fichiers modifiés :

- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `MVP Selbrume/road_map_phase_2.md`

Fichier créé :

- `reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md`

Tests / analyze :

- test rouge initial observé sur les nouveaux enum manquants ;
- `dart test test/narrative_validator_test.dart` passe ;
- `dart analyze` passe dans `packages/map_core`.

Le prochain lot exact est :

```text
P2-10 — Reference Picker Read Models
```

## 2. Scope du lot

Inclus :

- extension ciblée du validator existant ;
- diagnostics actionnables sur outcomes, World Rule predicates et support
  runtime Scene ;
- tests ciblés dans `packages/map_core/test/narrative_validator_test.dart` ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md` ;
- rapport P2-09 avec Evidence Pack.

Exclus :

- nouveau validator ;
- nouveaux modèles persistants ;
- registries ;
- modification `ProjectManifest` ;
- modification `GameState` / `SaveData` ;
- JSON / migration / build_runner ;
- UI ;
- runtime/editor/gameplay/battle ;
- auto-fix ;
- P2-10 ;
- Selbrume final.

## 3. Sources lues

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
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`

Code et tests :

- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_core/test/scenario_assets_test.dart`

Instructions et skills :

- `AGENTS.md`
- `skills/README.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`

## 4. Rappel Phase 1 / P2-01 à P2-08

Rappels utiles :

- Event déclenche.
- Scene orchestre.
- Fact nomme.
- World Rule projette passivement.
- Validator diagnostique.
- Validator ne corrige pas.
- Les adapters/read models restent futurs.
- Aucun registry persistant n'a été justifié en P2-02 à P2-08.

P2-09 ajoute donc seulement des diagnostics ciblés dans l'existant.

## 5. Problème à résoudre

Les lots P2-02 à P2-08 ont fait émerger beaucoup de diagnostics possibles :
steps, outcomes, battle refs, Fact Presentation, World Rule, Scene runtime
support et side quests.

Le besoin P2-09 est volontairement plus petit :

```text
Ajouter un premier batch utile, actionnable, testé.
Ne pas transformer le validator en usine.
```

## 6. Inventaire diagnostics existants

| Diagnostic | Statut avant P2-09 | Test existant | Action P2-09 |
|---|---|---:|---|
| `scenarioNodeReferencesUnknownNode` | existant | oui | pas touché |
| `scenarioGraphHasUnreachableNode` | existant | oui | pas touché |
| `scenarioGraphHasNoSource` | existant | oui | pas touché |
| `openDialogueReferencesUnknownDialogue` | existant | oui | pas touché |
| `startTrainerBattleMissingTrainerId` | existant | oui | pas touché |
| `startTrainerBattleReferencesUnknownTrainer` | existant | oui | pas touché |
| `startTrainerBattleMissingNpcEntityId` | existant | oui | pas touché |
| `startTrainerBattleBlankBattleId` | existant | oui | pas touché |
| `sourceEntityInteractReferencesUnknownMap` | existant | oui | pas touché |
| `sourceEntityInteractReferencesUnknownEntity` | existant | oui | pas touché |
| `sourceOutcomeWithoutMatchingEmitOutcome` | existant | oui | pas touché |
| `emitOutcomeWithoutMatchingSourceOutcome` | existant | oui | pas touché |
| `conditionalDialogueReferencesUnknownDialogue` | existant | oui | pas touché |
| `flagReadNeverProduced` | existant | oui | pas touché |
| `setFlagNeverRead` | existant | oui | pas touché |
| `stepReadNeverCompleted` | existant | oui | pas touché |
| `completeStepNeverRead` | existant | oui | pas touché |

Conclusion :

Les diagnostics proches demandés existent déjà pour flags, steps, sourceOutcome
et startTrainerBattle. P2-09 ne les duplique pas.

## 7. Diagnostics candidats

Évalués :

- `stepReadNeverCompleted` : déjà existant.
- `completeStepNeverRead` : déjà existant.
- `flagReadNeverProduced` : déjà existant.
- `setFlagNeverRead` : déjà existant.
- `sourceOutcomeWithoutMatchingEmitOutcome` : déjà existant.
- `emitOutcomeWithoutMatchingSourceOutcome` : déjà existant.
- `declaredOutcomeNeverEmitted` : choisi.
- `emitOutcomeNotDeclared` : choisi.
- `startTrainerBattleMissingTrainerId` : déjà existant.
- `startTrainerBattleReferencesUnknownTrainer` : déjà existant.
- `startTrainerBattleMissingNpcEntityId` : déjà existant.
- `startTrainerBattleBlankBattleId` : déjà existant.
- `battleReferenceVictoryNeverRead` : reporté, convention post-battle pas assez
  stabilisée.
- `battleReferenceDefeatNeverRead` : reporté, même raison.
- `battleReferenceUnsupportedOutcomeKind` : reporté à P2-10/Phase future.
- `visibilityRuleConditionalMissingPredicate` : choisi.
- `worldRulePredicateEmptyRefId` : choisi.
- `conditionalDialogueReferencesUnknownDialogue` : déjà existant.
- `conditionalDialoguePredicateEmptyRefId` : couvert par
  `worldRulePredicateEmptyRefId`.
- `stepStudioWorldPresenceTargetUnknown` : reporté, metadata Step Studio non
  modifiée dans P2-09.
- `stepStudioWorldPresenceSourceStepUnknown` : reporté, idem.
- `worldPresenceConflictsWithVisibilityRule` : reporté, nécessite une stratégie
  de conflit plus large.
- `scenarioChoiceNodeRuntimeUnsupported` : choisi.
- `scenarioReferenceNodeRuntimeUnsupported` : reporté, trop proche des source
  nodes runtime existants.
- `sceneSourceOnlyWithoutExecutableAction` : reporté, risque de faux positifs.
- `sceneActionAuthoringPlaceholder` : reporté, nécessite inventaire runtime plus
  fin.
- `technicalFlagExposedAsAuthorFact` : reporté, FactPresentationReadModel non
  créé.
- `scenarioOutcomePromotedToFactWithoutDecision` : reporté.
- `battleOutcomePromotedToFactWithoutDecision` : reporté.

## 8. Sélection des diagnostics P2-09

Batch retenu :

| Diagnostic | Source | Raison | Severity | Test | Risque |
|---|---|---|---|---|---|
| `declaredOutcomeNeverEmitted` | `ScenarioAsset.declaredOutcomes` + `emitOutcome` | Outcome déclaré mais jamais produit | warning | scénario déclare `unused_outcome` | warning peut accompagner d'autres diagnostics outcome |
| `emitOutcomeNotDeclared` | node `emitOutcome` | Outcome produit sans déclaration auteur | warning | scénario émet `test_outcome` sans le déclarer | ne pas confondre avec sourceOutcome |
| `visibilityRuleConditionalMissingPredicate` | `MapEntityNpcVisibilityRule` | Rule conditionnelle impossible à évaluer | error | `visibleWhen` sans predicate | ne pas toucher aux rules `always` |
| `worldRulePredicateEmptyRefId` | `MapEntityRuntimePredicate` | Predicate sans cible utile | error | predicate `stepCompleted` avec ref vide | message doit rester général |
| `scenarioChoiceNodeRuntimeUnsupported` | `ScenarioNodeType.choice` | Choice accepté structurellement mais non supporté runtime | warning | node choice reachable | ne pas bloquer ProjectValidator |

Fichiers impactés :

- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/test/narrative_validator_test.dart`

Tests prévus :

- un test dédié par diagnostic ajouté ;
- maintien du test golden minimal sans diagnostics ;
- maintien du tri stable.

## 9. Diagnostics implémentés

### `declaredOutcomeNeverEmitted`

- Fichier : `narrative_validator.dart`.
- Logique : collecte les `declaredOutcomes` par scénario, puis vérifie s'ils
  sont émis dans le même scénario par un node `emitOutcome`.
- Message : `Outcome "<id>" is declared but never emitted.`
- Severity : `warning`.
- Test : `declared outcome never emitted produces warning`.

### `emitOutcomeNotDeclared`

- Fichier : `narrative_validator.dart`.
- Logique : quand un node `emitOutcome` porte un outcome non vide, vérifie que
  cet outcome est dans `scenario.declaredOutcomes`.
- Message : `Outcome "<id>" is emitted but not declared by scenario "<id>".`
- Severity : `warning`.
- Test : `emitOutcome not declared by scenario produces warning`.

### `visibilityRuleConditionalMissingPredicate`

- Fichier : `narrative_validator.dart`.
- Logique : une visibility rule `visibleWhen` ou `hiddenWhen` sans predicate
  produit un diagnostic.
- Message : `NPC "<entityId>" has a conditional visibility rule without a predicate.`
- Severity : `error`.
- Test : `conditional visibility rule without predicate produces error`.

### `worldRulePredicateEmptyRefId`

- Fichier : `narrative_validator.dart`.
- Logique : tout `MapEntityRuntimePredicate` lu par visibility rule ou
  conditional dialogue est diagnostiqué si `refId` est vide/blanc.
- Message : `World rule predicate "<kind>" has an empty refId.`
- Severity : `error`.
- Test : `world rule predicate with empty refId produces error`.

### `scenarioChoiceNodeRuntimeUnsupported`

- Fichier : `narrative_validator.dart`.
- Logique : un node `ScenarioNodeType.choice` produit un warning de support
  runtime, sans modifier `ProjectValidator`.
- Message : `Choice node "<nodeId>" is not supported by the scenario runtime yet.`
- Severity : `warning`.
- Test : `choice node produces runtime unsupported warning`.

## 10. Diagnostics reportés

Reportés avec raison :

- `battleReferenceVictoryNeverRead` : nécessite convention de lecture post-battle.
- `battleReferenceDefeatNeverRead` : idem.
- `battleReferenceUnsupportedOutcomeKind` : P2-06 a limité V0 à victory/defeat,
  mais l'outillage n'est pas encore stabilisé.
- `stepStudioWorldPresenceTargetUnknown` : demande un parse robuste des metadata
  Step Studio.
- `stepStudioWorldPresenceSourceStepUnknown` : idem.
- `worldPresenceConflictsWithVisibilityRule` : nécessite stratégie de conflit.
- `scenarioReferenceNodeRuntimeUnsupported` : risque de doublon avec source
  nodes `reference` supportés.
- `sceneSourceOnlyWithoutExecutableAction` : risque de faux positif.
- `sceneActionAuthoringPlaceholder` : demande inventaire runtime plus fin.
- `technicalFlagExposedAsAuthorFact` : FactPresentationReadModel absent.
- `scenarioOutcomePromotedToFactWithoutDecision` : Fact Presentation reporté.
- `battleOutcomePromotedToFactWithoutDecision` : Fact Presentation reporté.
- diagnostics side quest : pas de Quest Engine / Quest Journal en Phase 2.

## 11. Design d’implémentation

Le design reste local :

- enum `NarrativeValidationDiagnosticKind` étendu dans le validator existant ;
- logique ajoutée dans `diagnoseNarrativeProject` via helpers privés ;
- aucune classe publique nouvelle hors enum ;
- aucun nouveau fichier de production ;
- aucune architecture parallèle.

Helpers ajoutés :

- `_collectWorldRulePredicateDiagnostics` ;
- `_collectDeclaredOutcomeDiagnostics`.

Responsabilités inchangées :

- `ProjectValidator` reste structurel/throw-based ;
- `NarrativeValidator` reste diagnostic/report-based ;
- pas d'auto-fix.

## 12. Fichiers modifiés

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/test/narrative_validator_test.dart
MVP Selbrume/road_map_phase_2.md
```

## 13. Tests ajoutés ou modifiés

Tests ajoutés dans `packages/map_core/test/narrative_validator_test.dart` :

- `declared outcome never emitted produces warning`
- `emitOutcome not declared by scenario produces warning`
- `conditional visibility rule without predicate produces error`
- `world rule predicate with empty refId produces error`
- `choice node produces runtime unsupported warning`

Helpers de test ajustés :

- `_map` accepte une `visibilityRule` optionnelle.
- `_localScenario` déclare `test_outcome` par défaut pour que le golden minimal
  reste propre avec le nouveau diagnostic `emitOutcomeNotDeclared`.

## 14. Résultats des tests / analyze

Commande rouge TDD :

```bash
cd packages/map_core && dart test test/narrative_validator_test.dart
```

Résultat attendu observé :

```text
Failed to load "test/narrative_validator_test.dart":
test/narrative_validator_test.dart:259:43: Error: Member not found: 'declaredOutcomeNeverEmitted'.
test/narrative_validator_test.dart:275:43: Error: Member not found: 'emitOutcomeNotDeclared'.
test/narrative_validator_test.dart:296:14: Error: Member not found: 'visibilityRuleConditionalMissingPredicate'.
test/narrative_validator_test.dart:321:43: Error: Member not found: 'worldRulePredicateEmptyRefId'.
test/narrative_validator_test.dart:359:43: Error: Member not found: 'scenarioChoiceNodeRuntimeUnsupported'.
Some tests failed.
```

Les sorties finales exactes sont dans l'Evidence Pack.

## 15. Impacts sur P2-10

P2-10 pourra utiliser ces diagnostics comme garde-fous pour les futurs read
models de pickers :

- outcome picker : afficher outcomes déclarés mais jamais émis et outcomes émis
  non déclarés ;
- World Rule picker : bloquer les rules conditionnelles sans predicate et les
  predicates sans `refId` ;
- Scene picker : signaler les choice nodes comme runtime-unsupported tant que le
  runtime ne les supporte pas.

P2-10 ne doit pas créer d'UI Flutter ; il doit rester sur des sources pures.

## 16. Risques et garde-fous

| Risque | Garde-fou appliqué |
|---|---|
| Trop de diagnostics | Batch limité à 5 |
| Diagnostic non actionnable | Chaque message pointe un path et une cause |
| Faux positifs World Rule | `always` sans predicate n'est pas diagnostiqué |
| Doublon ProjectValidator | ProjectValidator reste structurel, NarrativeValidator reste report-based |
| Registry caché | Aucun stockage, aucun registry |
| Scope creep read model | Aucun read model P2-10 créé |
| Runtime/editor touché | Aucun package hors `map_core` modifié |
| Tests fragiles | Tests dédiés dans `narrative_validator_test.dart` |

## 17. Ce que P2-09 décide

- Cinq diagnostics sont ajoutés.
- Les diagnostics existants ne sont pas dupliqués.
- Le validator existant est étendu.
- Aucun nouveau validator n'est créé.
- Aucun registry n'est créé.
- Aucun modèle persistant n'est créé.
- Aucun auto-fix n'est ajouté.
- P2-10 devient le prochain lot exact.

## 18. Ce que P2-09 ne décide pas

- Read models P2-10.
- UI.
- `ProjectManifest`.
- JSON / migration.
- Selbrume réel.
- Adapters runtime.
- FactRegistry.
- WorldRuleRegistry.
- OutcomeRegistry.
- BattleRegistry.
- Support runtime final des choice nodes.

## 19. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` est mise à jour pour indiquer :

- `P2-09 : ✅ terminé` ;
- `P2-10 : 🔜 prochain lot exact`.

Résumé ajouté :

```text
P2-09 ajoute un premier batch borné de 5 diagnostics NarrativeValidator :
declaredOutcomeNeverEmitted, emitOutcomeNotDeclared,
visibilityRuleConditionalMissingPredicate, worldRulePredicateEmptyRefId et
scenarioChoiceNodeRuntimeUnsupported.
```

## 20. Evidence Pack

### 20.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 20.2 Fichiers lus

```text
AGENTS.md
skills/README.md
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
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/scenario_assets_test.dart
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
```

### 20.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
```

### 20.4 Fichiers modifiés

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/test/narrative_validator_test.dart
MVP Selbrume/road_map_phase_2.md
```

### 20.5 Commandes exécutées

```text
git status --short --untracked-files=all
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,260p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
find .. -name AGENTS.md -print
sed -n '1,260p' AGENTS.md
sed -n '1,220p' "MVP Selbrume/road_map_global.md" && sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md" && sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"
grep -nE "P2-09|diagnostic|Validator|declaredOutcomeNeverEmitted|emitOutcomeNotDeclared|visibilityRuleConditionalMissingPredicate|worldRulePredicateEmptyRefId|scenarioChoiceNodeRuntimeUnsupported|scenarioReferenceNodeRuntimeUnsupported|Outcome|World Rule|Fact|Battle|Scene|Event|Story Step|registry|ProjectManifest" reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md || true
find packages/map_core/test -type f -name '*test.dart' | sort
rg -n "NarrativeValidator|NarrativeDiagnostic|ProjectValidator|flagReadNeverProduced|stepReadNeverCompleted|sourceOutcomeWithoutMatchingEmitOutcome|conditionalDialogueReferencesUnknownDialogue|startTrainerBattleMissingTrainerId|startTrainerBattleReferencesUnknownTrainer|startTrainerBattleMissingNpcEntityId|startTrainerBattleBlankBattleId|declaredOutcomes|emitOutcome|sourceOutcome|choice|reference|authoringPlaceholder|visibilityRule" packages/map_core/test packages/map_core/lib
sed -n '1,220p' packages/map_core/lib/src/operations/narrative_validator.dart && sed -n '220,520p' packages/map_core/lib/src/operations/narrative_validator.dart && sed -n '520,860p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,260p' packages/map_core/test/narrative_validator_test.dart && sed -n '260,560p' packages/map_core/test/narrative_validator_test.dart
sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart && sed -n '1,240p' packages/map_core/lib/src/models/map_entity_payloads.dart && sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '760,980p' packages/map_core/lib/src/validation/validators.dart && sed -n '980,1160p' packages/map_core/lib/src/validation/validators.dart
dart test test/narrative_validator_test.dart
nl -ba packages/map_core/lib/src/operations/narrative_validator.dart | sed -n '1,260p'
nl -ba packages/map_core/lib/src/operations/narrative_validator.dart | sed -n '260,760p'
nl -ba packages/map_core/test/narrative_validator_test.dart | sed -n '220,400p'
dart test test/narrative_validator_test.dart
dart format lib/src/operations/narrative_validator.dart test/narrative_validator_test.dart
dart test test/narrative_validator_test.dart
dart analyze
git diff -- packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/test/narrative_validator_test.dart
git status --short --untracked-files=all
sed -n '700,900p' "MVP Selbrume/road_map_phase_2.md"
grep -nE "declaredOutcomeNeverEmitted|emitOutcomeNotDeclared|visibilityRuleConditionalMissingPredicate|worldRulePredicateEmptyRefId|scenarioChoiceNodeRuntimeUnsupported|P2-09|P2-10" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/test/narrative_validator_test.dart "MVP Selbrume/road_map_phase_2.md"
dart test --reporter compact test/narrative_validator_test.dart
dart analyze
NO_COLOR=1 dart test --reporter compact test/narrative_validator_test.dart
NO_COLOR=1 dart analyze
dart test --reporter json test/narrative_validator_test.dart | tail -n 5
dart analyze | tail -n 2
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle packages/map_runtime packages/map_editor packages/map_gameplay examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
grep -nE "Lot courant|Prochain lot exact|P2-09 :|P2-10 :|P2-10 — Reference Picker Read Models" "MVP Selbrume/road_map_phase_2.md"
```

### 20.6 git diff --check

```text

```

### 20.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md                   |  69 +++++++++-
 .../lib/src/operations/narrative_validator.dart    | 140 +++++++++++++++++++-
 .../map_core/test/narrative_validator_test.dart    | 147 +++++++++++++++++++--
 3 files changed, 335 insertions(+), 21 deletions(-)
```

### 20.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/test/narrative_validator_test.dart
```

### 20.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
 M packages/map_core/lib/src/operations/narrative_validator.dart
 M packages/map_core/test/narrative_validator_test.dart
?? reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
```

### 20.10 Tests / analyze

```text
Commande : cd packages/map_core && dart test --reporter json test/narrative_validator_test.dart | tail -n 5

{"test":{"id":23,"name":"Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused","suiteID":0,"groupIDs":[2,3],"metadata":{"skip":false,"skipReason":null},"line":382,"column":5,"url":"file:///Users/karim/Project/pokemonProject/packages/map_core/test/narrative_validator_test.dart"},"type":"testStart","time":474}
{"testID":23,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":475}
{"test":{"id":24,"name":"Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically","suiteID":0,"groupIDs":[2,3],"metadata":{"skip":false,"skipReason":null},"line":398,"column":5,"url":"file:///Users/karim/Project/pokemonProject/packages/map_core/test/narrative_validator_test.dart"},"type":"testStart","time":475}
{"testID":24,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":476}
{"success":true,"type":"done","time":481}

Commande : cd packages/map_core && dart analyze | tail -n 2

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

```

### 20.12 git diff --no-index --check du rapport créé

Commande :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md || true
```

Sortie :

```text

```

## 21. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui. Les changements code/test sont limités à map_core, avec roadmap Phase 2 et
rapport P2-09.
```

Le rapport P2-09 existe-t-il au bon chemin ?

```text
Oui : reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md.
```

`road_map_phase_2.md` a-t-elle été mise à jour ?

```text
Oui.
```

`road_map_global.md` est-elle restée intacte ?

```text
Oui. Le contrôle hors scope final est vide.
```

Aucun package hors `map_core` n'a-t-il été modifié ?

```text
Oui. Le contrôle hors scope final est vide.
```

Aucun registry n'a-t-il été créé ?

```text
Oui. Aucun registry n'a été créé.
```

Aucun `ProjectManifest` / JSON / migration n'a-t-il été modifié ?

```text
Oui. Aucun `ProjectManifest`, JSON ou migration n'a été modifié.
```

Les diagnostics ajoutés sont-ils actionnables ?

```text
Oui. Chaque diagnostic indique un path, une cause et un id/contexte utile.
```

Les tests ciblés passent-ils ?

```text
Oui. `dart test --reporter json test/narrative_validator_test.dart | tail -n 5`
termine avec `{"success":true,"type":"done","time":481}`.
```

L'analyze `map_core` est-il propre ou les dettes sont-elles documentées ?

```text
Oui. `dart analyze | tail -n 2` retourne `No issues found!`.
```

P2-10 n'a-t-il pas été commencé ?

```text
Oui. P2-10 est seulement le prochain lot exact.
```

Le prochain lot exact est-il clair ?

```text
Oui : P2-10 — Reference Picker Read Models.
```

Regard critique sur le prompt :

```text
Le prompt donne une bonne tension : il autorise enfin le code, mais force un
batch petit et vérifiable. La recommandation 3 à 5 diagnostics évite de gonfler
le validator avec des idées non stabilisées.
```
