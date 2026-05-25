# P2-CHECKPOINT-01 — Domain Contracts Readiness Review

## 1. Résumé exécutif

Verdict :

```text
⚠️ Phase 2 clôturable avec réserves mineures.
```

La Phase 2 a rempli son objectif : transformer la grammaire produit Phase 1 en
socle domaine minimal, testable et utile, sans migration prématurée, sans
registry persistant, sans duplication volontaire des sources de vérité et sans
UI.

Livrables concrets produits :

- décisions domaine P2-00 à P2-08, majoritairement design-first ;
- diagnostics P2-09 dans le `NarrativeValidator` existant ;
- read models purs P2-10 dans `map_core` ;
- exports `map_core` pour les read models ;
- rapports P2-00 à P2-10 ;
- roadmap Phase 2 tenue et nettoyée par P2-10-bis ;
- roadmap Phase 3 recommandée et créée sans démarrer P3-00.

Diagnostics ajoutés :

- `declaredOutcomeNeverEmitted` ;
- `emitOutcomeNotDeclared` ;
- `visibilityRuleConditionalMissingPredicate` ;
- `worldRulePredicateEmptyRefId` ;
- `scenarioChoiceNodeRuntimeUnsupported`.

Read models ajoutés :

- `NarrativeScenarioPickerOption` ;
- `NarrativeOutcomePickerOption` ;
- `NarrativeBattleReferencePickerOption`.

Contrats refusés ou reportés :

- pas de `FactRegistry`, `WorldRuleRegistry`, `OutcomeRegistry` ou
  `BattleRegistry` ;
- pas de wrapper `Scene` persistant ;
- pas de descriptor Storyline / Chapter / Story Step persistant immédiat ;
- pas de migration `ProjectManifest` ;
- pas de Reward Model, Quest Journal, UI ou Selbrume réel en Phase 2.

La Phase 3 peut commencer après validation utilisateur. Prochain lot exact :

```text
P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit
```

## 2. Scope du checkpoint

Inclus :

- audit P2-00 à P2-10 ;
- vérification des décisions domaine ;
- vérification des diagnostics P2-09 ;
- vérification des read models P2-10 ;
- tests ciblés `map_core` ;
- analyse `map_core` ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md` ;
- mise à jour de `MVP Selbrume/road_map_global.md` ;
- création de `MVP Selbrume/road_map_phase_3.md` ;
- rapport de checkpoint avec Evidence Pack.

Exclus :

- nouveaux contrats ;
- nouveaux diagnostics ;
- nouveaux read models ;
- runtime ;
- project disk ;
- UI ;
- Selbrume final ;
- JSON / migration ;
- registries ;
- exécution de P3-00.

## 3. Sources lues

Roadmaps :

- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `MVP Selbrume/road_map_phase_1.md`

Rapports Phase 2 :

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
- `reports/roadmap/phase_2/p2_10_reference_picker_read_models.md`

P2-10-bis :

- aucun rapport dédié `p2_10_bis_roadmap_history_cleanup.md` n'a été trouvé ;
- la correction P2-10-bis a été lue dans `MVP Selbrume/road_map_phase_2.md`.

Rapports Phase 1 utiles :

- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`

Code et tests lus en lecture seule :

- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/validation/validators.dart`

Instructions et skills :

- `AGENTS.md`
- `skills/README.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/writing-plans/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`

## 4. Verdict global Phase 2

```text
⚠️ Phase 2 clôturable avec réserves mineures.
```

Justification :

- tous les lots P2-00 à P2-10 existent et sont terminés ;
- P2-02 à P2-08 ont pris des décisions explicites sans sur-modéliser ;
- P2-09 a ajouté un premier batch de diagnostics actionnables et testés ;
- P2-10 a ajouté un premier batch de read models purs, dérivés et testés ;
- `ProjectManifest`, `GameState` et `SaveData` n'ont pas été migrés ;
- aucun registry persistant n'a été créé ;
- `map_battle` reste indépendant du Narrative Studio ;
- les tests ciblés `map_core` et `dart analyze` passent.

Réserves mineures :

- la Phase 2 ne prouve pas le runtime Flame ;
- la Phase 2 ne prouve pas le chargement d'un vrai projet disque ;
- les read models P2-10 ne sont pas encore consommés par `map_editor` ;
- plusieurs adapters restent conceptuels ;
- Selbrume reste une référence conceptuelle.

## 5. Évaluation lot par lot

| Lot | Livrable | Statut | Valeur produite | Code ? | Tests ? | Réserve éventuelle | Verdict |
|---|---|---|---|---|---|---|---|
| P2-00 | Rapport bootstrap | terminé | Cadrage Phase 2 audit-first et frontière P2-00/P2-01. | non | non | Lot volontairement documentaire. | validé |
| P2-01 | Inventaire narratif existant | terminé | Cartographie `ScenarioAsset`, validators, runtime, metadata, GameState. | non | non | Inventaire, pas décision finale. | validé |
| P2-02 | Décision Story Step / metadata | terminé | Refus descriptor persistant, `completedStepIds` reste source de completion. | non | non | Adapter/read model futur non créé. | validé |
| P2-03 | Décision Event Authoring Source | terminé | Event reste déclencheur ; futur read model dérivé des source nodes. | non | non | Pas de picker Event encore. | validé |
| P2-04 | Décision Scene / ScenarioAsset | terminé | `ScenarioAsset` reste substrat ; Scene = vue produit future. | non | non | Pas de `SceneReadModel` encore. | validé |
| P2-05 | Décision Outcome Reference | terminé | Outcomes déclarés/émis/consommés gardés sans `OutcomeRegistry`. | non | non | Battle outcomes séparés. | validé |
| P2-06 | Décision Battle Reference | terminé | V0 conceptuel battle = victory/defeat ; pas de `BattleRegistry`. | non | non | Rewards, money, XP reportés. | validé |
| P2-07 | Décision Fact Presentation | terminé | Fact = présentation lisible, `GameState` garde la vérité. | non | non | Pas de Fact picker encore. | validé |
| P2-08 | Décision World Rule | terminé | World Rule passive dérivée des predicates existants, pas registry. | non | non | Conflits world presence reportés. | validé |
| P2-09 | Diagnostics validator | terminé | 5 diagnostics actionnables ajoutés au validator existant. | oui, `map_core` | oui | Batch volontairement non exhaustif. | validé |
| P2-10 | Picker read models | terminé | 3 read models purs pour Scenario, Outcome, Battle Reference. | oui, `map_core` | oui | Step/Fact/World Rule/Event pickers reportés. | validé |

## 6. Décisions domaine stabilisées

- Pas de modèle sans consumer clair.
- Adapter/read model avant persistence.
- Pas de registry prématuré.
- Storyline / Chapter / Story Step : metadata + read model futur, pas
  persistence maintenant.
- `completedStepIds` reste source de completion.
- Event : source dérivée, pas mini-Scene.
- Scene : vue produit de `ScenarioAsset`, pas wrapper persistant.
- Outcome : declared / emitted / consumed restent sources techniques, pas
  `OutcomeRegistry`.
- Battle Reference : V0 limité à victory / defeat, pas `BattleRegistry`,
  `map_battle` reste indépendant.
- Fact : présentation lisible, pas source de vérité.
- World Rule : projection passive, pas Event, pas écriture de Fact.
- Validator : diagnostique, pas auto-fix.
- Picker read models : sources pures sans UI.

## 7. Contrats / adapters / read models créés

Éléments réellement créés ou étendus :

- diagnostics P2-09 dans `packages/map_core/lib/src/operations/narrative_validator.dart` ;
- tests diagnostics dans `packages/map_core/test/narrative_validator_test.dart` ;
- read models P2-10 dans `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart` ;
- tests read models dans `packages/map_core/test/narrative_reference_picker_read_models_test.dart` ;
- export public dans `packages/map_core/lib/map_core.dart`.

Aucun modèle persistant, JSON, migration ou registry n'a été créé.

## 8. Contrats explicitement refusés

- `FactRegistry` ;
- `WorldRuleRegistry` ;
- `OutcomeRegistry` ;
- `BattleRegistry` ;
- wrapper `Scene` persistant ;
- descriptor Storyline / Chapter / Story Step persistant immédiat ;
- migration `ProjectManifest` prématurée ;
- Reward Model en Phase 2 ;
- UI en Phase 2 ;
- Selbrume final en Phase 2.

## 9. Contrats explicitement reportés

- Story Step picker ;
- Fact Presentation picker ;
- World Rule picker ;
- Event Source picker ;
- diagnostics post-battle victory/defeat jamais lus ;
- diagnostics Step Studio world presence target/source ;
- conflit world presence / visibility rule ;
- diagnostics Fact Presentation ;
- side quest / Quest Journal ;
- Reward Model ;
- money / XP / level-up ;
- static wild authoring ;
- Door/Warp complet.

## 10. Diagnostics ajoutés

| Diagnostic | Utilité | Fichier | Test associé |
|---|---|---|---|
| `declaredOutcomeNeverEmitted` | Signale un outcome déclaré mais jamais produit par la scène. | `narrative_validator.dart` | `declared outcome never emitted produces warning` |
| `emitOutcomeNotDeclared` | Signale un outcome produit sans déclaration dans le scénario. | `narrative_validator.dart` | `emitOutcome not declared by scenario produces warning` |
| `visibilityRuleConditionalMissingPredicate` | Signale une rule de visibilité conditionnelle impossible à évaluer. | `narrative_validator.dart` | `conditional visibility rule without predicate produces error` |
| `worldRulePredicateEmptyRefId` | Signale un predicate World Rule sans cible utile. | `narrative_validator.dart` | `world rule predicate with empty refId produces error` |
| `scenarioChoiceNodeRuntimeUnsupported` | Signale qu'un node choice est authorable mais pas encore supporté runtime. | `narrative_validator.dart` | `choice node produces runtime unsupported warning` |

## 11. Read models ajoutés

| Read model | Source | Fonction builder | Tri | Fallback label | Test associé |
|---|---|---|---|---|---|
| `NarrativeScenarioPickerOption` | `ProjectManifest.scenarios`, `ScenarioAsset` | `buildNarrativeScenarioPickerOptions` | label puis `scenarioId` | `scenarioId` si `name` vide | `builds scenario picker options with stable labels and counts` |
| `NarrativeOutcomePickerOption` | `declaredOutcomes`, nodes `emitOutcome`, nodes `sourceOutcome` | `buildNarrativeOutcomePickerOptions` | label puis `outcomeId` | humanisation de l'ID technique | `builds outcome picker options from declared emitted and consumed ids` |
| `NarrativeBattleReferencePickerOption` | nodes `startTrainerBattle`, `ProjectManifest.trainers` | `buildNarrativeBattleReferencePickerOptions` | label puis `battleReferenceId` | trainerId / battleId / source fallback | `builds battle reference picker options from trainer battle nodes` |

`NarrativeBattleOutcomeKind` expose uniquement `victory` et `defeat` pour le V0
conceptuel P2-06.

## 12. Package boundaries

Vérification :

- `map_core` a reçu diagnostics et read models purs ;
- `map_runtime` n'est pas modifié par le checkpoint ;
- `map_editor` n'est pas modifié par le checkpoint ;
- `map_gameplay` n'est pas modifié par le checkpoint ;
- `map_battle` n'est pas modifié et reste indépendant du Narrative Studio ;
- aucun JSON ou migration n'est créé ;
- `ProjectManifest`, `GameState` et `SaveData` ne sont pas modifiés ;
- aucune UI ou widget Flutter n'est créé.

## 13. Tests et qualité

Validations exécutées pendant le checkpoint :

```bash
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart analyze
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md || true
git diff --no-index --check /dev/null "MVP Selbrume/road_map_phase_3.md" || true
```

Résultats :

- `narrative_validator_test.dart` : 21 tests, succès ;
- `narrative_reference_picker_read_models_test.dart` : 3 tests, succès ;
- `dart analyze` : `No issues found!`.

## 14. Réserves et limites

- Phase 2 ne prouve pas runtime Flame.
- Phase 2 ne prouve pas projet disque.
- Phase 2 ne crée pas UI authoring.
- Les adapters/read models Story Step, Fact, World Rule et Event Source restent
  reportés.
- Les picker read models ne sont pas encore consommés par `map_editor`.
- P2-09 est un premier batch de diagnostics, pas un diagnostic exhaustif.
- P2-10 n'inclut pas Story Step / Fact / World Rule / Event Source pickers.
- Selbrume reste conceptuel.

## 15. Gaps reportés hors Phase 2

Phase 3 — Runtime / Application / Flame / Disk Validation :

- runtime/disk validation ;
- scenario execution bridge sur projet disque ;
- save/load réel sur flux ;
- golden path minimal runtime.

Phase 4 — Authoring Workflows Minimal :

- intégration des picker read models dans editor ;
- authoring minimal Narrative Studio ;
- workflows Event / Scene / Outcome / Battle / Facts / World Rules.

Phase 5 — Gameplay Gaps Prioritaires :

- rewards ;
- money ;
- XP / level-up ;
- static wild authoring ;
- Door/Warp complet ;
- Quest Journal si nécessaire.

Phase 6 — Selbrume Golden Slice réel :

- mini-projet Selbrume réel ;
- maps / scenes / dialogues / battle / facts / world rules réels.

Phase 7 — UI/UX moderne finale :

- design system ;
- UI premium ;
- Scene Builder complet ;
- Cinematic Builder complet.

## 16. Validation du passage vers Phase 3

Phase 3 peut commencer après validation utilisateur.

Critères satisfaits :

- contrats/adapters clés décidés ;
- diagnostics de base présents ;
- picker read models de base présents ;
- package boundaries respectées ;
- pas de migration inutile ;
- tests `map_core` verts ;
- gaps runtime/disk bien identifiés.

Phase 3 doit prouver runtime/disk. Elle ne doit pas créer Selbrume final ni UI
premium.

## 17. Roadmap Phase 3 recommandée

Objectif proposé :

```text
Valider que les contrats et read models Phase 2 peuvent être reliés à un vrai
projet disque et à l'exécution runtime, sans créer encore Selbrume final ni UI
premium.
```

Lots recommandés :

- P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit
- P3-01 — Project Disk Narrative Asset Loading Audit
- P3-02 — ScenarioAsset Runtime Execution Golden Path
- P3-03 — Event Source to Scenario Runtime Bridge Validation
- P3-04 — Outcome / Battle Outcome Runtime Continuation Validation
- P3-05 — Fact / World Rule Runtime Projection Validation
- P3-06 — Save/Load Narrative State Roundtrip Validation
- P3-07 — Playable Runtime Host Narrative Smoke Test
- P3-CHECKPOINT-01 — Runtime & Disk Readiness Review

Garde-fous :

- ne pas transformer Phase 3 en Selbrume réel ;
- ne pas ajouter UI premium ;
- ne pas ouvrir les gaps gameplay Phase 5 hors lot explicite.

## 18. Roadmap Phase 3 vivante

Comme la Phase 2 est clôturable, une roadmap Phase 3 vivante est créée :

```text
MVP Selbrume/road_map_phase_3.md
```

Elle fixe :

- statut Phase 3 : à démarrer ;
- objectif : Runtime / Application / Flame / Disk Validation ;
- prochain lot exact : P3-00 ;
- lots proposés P3-00 à P3-CHECKPOINT-01 ;
- garde-fous : pas Selbrume final, pas UI premium, pas gameplay gaps hors lot.

Créer cette roadmap ne démarre pas P3-00.

## 19. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` est mise à jour pour :

- marquer la Phase 2 comme clôturée avec réserves mineures ;
- marquer P2-CHECKPOINT-01 comme terminé ;
- pointer vers P3-00 comme prochain lot exact ;
- résumer les décisions stabilisées ;
- lister les diagnostics P2-09 et read models P2-10 ;
- documenter les réserves et le passage vers Phase 3.

## 20. Mise à jour de road_map_global.md

`MVP Selbrume/road_map_global.md` est mise à jour pour :

- marquer Phase 2 comme clôturée avec réserves mineures ;
- passer la phase courante à Phase 3 ;
- pointer la roadmap courante vers `MVP Selbrume/road_map_phase_3.md` ;
- fixer le prochain lot exact à P3-00 ;
- conserver l'historique NS-GS et Phase 1.

## 21. Décisions à valider par l’utilisateur

- Valider la roadmap Phase 3.
- Définir le degré de preuve runtime attendu.
- Choisir projet disque minimal ou fixture technique.
- Définir le périmètre du runtime smoke test.
- Confirmer que Phase 3 ne crée pas Selbrume final.
- Confirmer que l'UI authoring reste Phase 4.
- Confirmer que rewards / money / XP restent Phase 5.

## 22. Evidence Pack

### 22.1 git status initial

```text
Sortie vide — aucun changement détecté au début du checkpoint.
```

### 22.2 Fichiers lus

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
reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/validation/validators.dart
```

### 22.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
MVP Selbrume/road_map_phase_3.md
```

### 22.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_global.md
```

### 22.5 Commandes exécutées

```text
git status --short --untracked-files=all
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/writing-plans/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,220p' AGENTS.md
sed -n '1,220p' "MVP Selbrume/road_map_global.md"
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,160p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
sed -n '1,280p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '1,260p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
test -f reports/roadmap/phase_2/p2_10_bis_roadmap_history_cleanup.md && sed -n '1,220p' reports/roadmap/phase_2/p2_10_bis_roadmap_history_cleanup.md || true
rg -n "^## (1\\. Résumé exécutif|14\\. Décision d.implementation P2-03|14\\. Décision d’implémentation P2-03|16\\. Décision d.implementation P2-05|16\\. Décision d’implémentation P2-05|17\\. Décision d.implementation P2-08|17\\. Décision d’implémentation P2-08|9\\. Diagnostics implémentés|9\\. Read models implémentés|10\\. Diagnostics reportés|10\\. Read models reportés|19\\. Ce que P2|20\\. Ce que P2|21\\. Ce que P2|22\\. Ce que P2|23\\. Implémentation éventuelle|24\\. Tests|25\\. Recommandation|26\\. Mise à jour|27\\. Evidence|28\\. Auto-review|11\\. Read models ajoutés|10\\. Diagnostics ajoutés|4\\. Verdict global|5\\. Évaluation lot par lot|6\\. Décisions domaine stabilisées)" reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
sed -n '1,220p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
sed -n '1,220p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
sed -n '1,220p' reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
sed -n '1,230p' reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
sed -n '1,230p' reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
sed -n '1,240p' reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
sed -n '1,360p' reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
sed -n '1,380p' reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
rg -n "P2-10-bis|narrative_reference_picker_read_models|p2_10_reference_picker" "MVP Selbrume/road_map_phase_2.md"
sed -n '1,220p' reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
sed -n '1,180p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
sed -n '1,170p' reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
sed -n '1,170p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '1,170p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '880,980p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,260p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,360p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,440p' packages/map_core/test/narrative_validator_test.dart
sed -n '1,360p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
rg -n "declaredOutcomeNeverEmitted|emitOutcomeNotDeclared|visibilityRuleConditionalMissingPredicate|worldRulePredicateEmptyRefId|scenarioChoiceNodeRuntimeUnsupported|_collectDeclaredOutcomeDiagnostics|_collectWorldRulePredicateDiagnostics|export .*narrative_reference" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/map_core.dart
sed -n '260,620p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,220p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,180p' packages/map_core/lib/src/models/project_trainer.dart
rg -n "MapEntityRuntimePredicate|MapEntityRuntimePredicateKind|storyFlags|completedStepIds|scriptVariables|consumedEventIds|SaveData|GameState" packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart
sed -n '1,220p' packages/map_core/lib/src/validation/validators.dart
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,180p' "MVP Selbrume/road_map_phase_2.md"
sed -n '820,980p' "MVP Selbrume/road_map_phase_2.md"
wc -l "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md"
sed -n '260,520p' "MVP Selbrume/road_map_global.md"
sed -n '520,720p' "MVP Selbrume/road_map_global.md"
sed -n '980,1060p' "MVP Selbrume/road_map_phase_2.md"
rg -n "Phase 2|Phase 3|Lot courant|Prochain lot exact|P2-CHECKPOINT" "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md"
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart analyze
```

### 22.6 Tests / analyze

```text
cd packages/map_core && dart test test/narrative_validator_test.dart
00:00 +21: All tests passed!

cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
00:00 +3: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

### 22.7 git diff --check

```text
Sortie vide — aucune erreur whitespace détectée dans les fichiers suivis modifiés.
```

### 22.8 git diff --stat

```text
 MVP Selbrume/road_map_global.md  | 98 +++++++++++++++++++++++++++++-----------
 MVP Selbrume/road_map_phase_2.md | 81 ++++++++++++++++++++++++++++++---
 2 files changed, 147 insertions(+), 32 deletions(-)
```

### 22.9 git diff --name-only

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
```

### 22.10 git status final

```text
 M "MVP Selbrume/road_map_global.md"
 M "MVP Selbrume/road_map_phase_2.md"
?? "MVP Selbrume/road_map_phase_3.md"
?? reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
```

Contrôles hors scope obligatoires :

```text
git diff --name-only -- packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle examples/playable_runtime_host
Sortie vide — aucun changement hors scope package/runtime/editor/battle/gameplay/host.
```

Contrôle code `map_core` :

```text
git diff --name-only -- packages/map_core
Sortie vide — aucun changement code `map_core` pendant le checkpoint.
```

Contrôles no-index :

```text
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md || true
Sortie vide — le rapport checkpoint ne contient pas d'erreur whitespace.

git diff --no-index --check /dev/null "MVP Selbrume/road_map_phase_3.md" || true
Sortie vide — la roadmap Phase 3 ne contient pas d'erreur whitespace.
```

## 23. Auto-review critique

- Le checkpoint a-t-il modifié uniquement ce qui était autorisé ? Oui :
  rapport, roadmaps Phase 2/global et roadmap Phase 3.
- Le rapport checkpoint existe-t-il au bon chemin ? Oui.
- `road_map_phase_2.md` est-elle mise à jour ? Oui.
- `road_map_global.md` est-elle mise à jour ? Oui.
- `road_map_phase_3.md` existe-t-elle seulement si justifié ? Oui, car la Phase
  2 est clôturable avec réserves mineures.
- Aucun code n'a-t-il été modifié ? Oui, le checkpoint ne modifie aucun fichier
  de code.
- Les tests `map_core` passent-ils ? Oui.
- L'analyze `map_core` passe-t-il ? Oui.
- La Phase 2 est-elle clôturable ? Oui, avec réserves mineures.
- Les réserves sont-elles honnêtes ? Oui : runtime, disk, UI, Selbrume réel et
  adapters reportés sont explicités.
- Les reports hors Phase 2 sont-ils explicites ? Oui.
- P3-00 n'a-t-il pas été exécuté ? Oui.
- Selbrume final n'a-t-il pas été créé ? Oui.
- Le prochain lot exact est-il clair ? Oui :
  `P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk Validation Audit`.

Regard critique sur le prompt :

Le prompt est strict mais sain : il oblige à clore la Phase 2 par les preuves
réelles plutôt que par une impression de progression. La création conditionnelle
de la roadmap Phase 3 est utile, mais elle exige de répéter clairement que P3-00
n'est pas démarré. La demande d'Evidence Pack complet dans un rapport qui est
lui-même modifié par l'ajout de l'Evidence Pack crée une petite récursion
documentaire ; le garde-fou retenu est de relancer les contrôles après édition
finale et de conserver les sorties finales dans cette section.
