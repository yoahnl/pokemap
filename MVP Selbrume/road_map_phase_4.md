# Phase 4 Roadmap — Authoring Workflows Minimal

## 1. Statut de la phase

Phase 4 — Authoring Workflows Minimal

Statut : 🔜 Phase courante en exécution

Lot courant : P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

Prochain lot exact : P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

Suivi des lots :

- ✅ P4-00 — Phase 4 Roadmap Recalibration / Authoring Workflow Audit
- ✅ P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0
- ✅ P4-02 — Scenario Authoring Draft Model V0
- ✅ P4-03 — Event Source Authoring Draft Operations V0
- ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0
- ✅ P4-05 — Predicate / World Rule Authoring Draft V0
- ✅ P4-06 — Narrative Validator Authoring Adapter V0
- ✅ P4-07 — Minimal Authoring Golden Path Test V0
- 🔜 P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

P4-00 : ✅ terminé

P4-01 : ✅ terminé

P4-02 : ✅ terminé

P4-03 : ✅ terminé

P4-04 : ✅ terminé

P4-05 : ✅ terminé

P4-06 : ✅ terminé

P4-07 : ✅ terminé

P4-CHECKPOINT-01 : 🔜 prochain lot exact

## 2. Objectif de la Phase 4

Rendre les mécaniques narratives prouvées en Phase 3 authorables de manière
fonctionnelle et no-code minimal, sans UI premium.

Phase 4 doit répondre à la question :

```text
Un créateur peut-il préparer un flux narratif minimal sans éditer directement
les graphes techniques ou les IDs bruts comme langage principal ?
```

## 3. Pourquoi cette phase existe

La Phase 3 a prouvé que les contrats domaine Phase 2 peuvent alimenter le disque
et le runtime. Elle n'a pas créé l'expérience d'authoring.

La Phase 4 doit transformer ces preuves en workflows auteur minimaux :

- choisir des références avec des pickers/read models ;
- construire ou décrire un scenario minimal ;
- choisir les sources Event runtime ;
- authorer outcomes et battle refs sans registry ;
- préparer facts, predicates et world rules passives ;
- intégrer les diagnostics existants avant runtime.

## 4. Préconditions

- Phase 1 clôturée avec réserves mineures.
- Phase 2 clôturée avec réserves mineures.
- Phase 3 clôturée avec réserves mineures.
- `reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 4.
- Selbrume reste une référence conceptuelle, pas du contenu à générer.

## 5. Périmètre Phase 4

Inclus :

- audit des workflows authoring existants ;
- couverture des read models de pickers ;
- read models manquants strictement dérivés ;
- draft models purs pour authoring minimal ;
- opérations pures testées pour produire ou modifier des fragments
  `ScenarioAsset` ;
- adapters diagnostics/validator orientés authoring ;
- golden path authoring minimal testé ;
- checkpoint Phase 4.

Exclus :

- UI premium ;
- design system final ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- Selbrume final ;
- rewards, money, XP, level-up ;
- gameplay gaps Phase 5 ;
- migration ProjectManifest opportuniste ;
- registry persistant ;
- runtime/disk proof supplémentaire hors besoin P4 explicite.

## 6. Règles de maintenance

À chaque lot Phase 4, l'agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire `MVP Selbrume/road_map_phase_4.md`.
3. Respecter le prochain lot exact.
4. Ne pas démarrer un autre lot.
5. Distinguer authoring workflow, UI premium, runtime et gameplay gaps.
6. Ne pas créer Selbrume final.
7. Ne pas créer Scene Builder complet ou Cinematic Builder complet.
8. Ne pas ouvrir rewards / money / XP hors demande explicite.
9. Fournir un Evidence Pack complet.
10. Mettre à jour cette roadmap vivante.
11. Ne modifier `road_map_global.md` qu'au checkpoint ou sur demande explicite.

## 7. Lots Phase 4 recalibrés

### ✅ P4-00 — Phase 4 Roadmap Recalibration / Authoring Workflow Audit

Objectif :
Auditer l'existant côté editor/authoring, critiquer la roadmap Phase 4 initiale
et la recalibrer pour éviter une phase uniquement documentaire.

Résultat attendu :
Roadmap Phase 4 recalibrée, risques authoring listés, prochains lots orientés
preuves concrètes, prochain lot P4-01 clarifié.

Non-objectifs :
Pas de widget UI, pas de Scene Builder, pas de Selbrume final, pas de gameplay
rewards.

Résultat P4-00 :

- rapport créé :
  `reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md` ;
- diagnostic :
  la roadmap initiale était cohérente mais trop documentaire dans son vocabulaire
  et risquait de produire des reviews/designs sans briques authoring exploitables ;
- décision :
  P4-01 à P4-07 doivent produire des preuves authoring concrètes, surtout des
  read models manquants, drafts, opérations pures, adapters validator et tests ;
- `road_map_global.md` non modifiée ;
- aucun code, test, widget, registry, runtime ou contenu Selbrume créé.

### ✅ P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0

Objectif :
Compléter la couverture de pickers strictement nécessaire au démarrage des
workflows authoring minimaux.

Résultat attendu :
Preuve concrète, pure et testée :

- confirmer les read models existants Scenario / Outcome / Battle ;
- ajouter seulement les read models manquants V0 qui partagent les sources
  stables existantes, en priorité Event Source, Story Step et Predicate/Fact
  reference si l'audit du lot les confirme ;
- garder Dialogue / Map / NPC / Trigger pickers comme consommateurs potentiels
  de sources déjà existantes ou comme reports si le scope gonfle ;
- aucun widget UI, aucun registry, aucune persistence.

Résultat P4-01 :

- rapport créé :
  `reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md` ;
- read models existants Scenario / Outcome / Battle confirmés et conservés ;
- batch V0 ajouté dans `map_core` :
  `NarrativeStoryStepPickerOption`, `NarrativeEventSourcePickerOption`,
  `NarrativePredicateReferencePickerOption` ;
- builders ajoutés :
  `buildNarrativeStoryStepPickerOptions`,
  `buildNarrativeEventSourcePickerOptions`,
  `buildNarrativePredicateReferencePickerOptions` ;
- sources strictement dérivées :
  `ScenarioAsset.metadata`, `ProjectManifest.maps`, `MapData.entities`,
  `MapData.triggers`, outcomes déclarés/émis/consommés, battle refs ;
- tests ciblés ajoutés dans
  `packages/map_core/test/narrative_reference_picker_read_models_test.dart` ;
- aucun widget UI, aucun registry persistant, aucune migration, aucun runtime,
  aucun contenu Selbrume et aucun reward/money/XP créé.

### ✅ P4-02 — Scenario Authoring Draft Model V0

Objectif :
Créer ou stabiliser un draft model pur permettant de décrire un scenario minimal
sans saisir directement le graphe technique.

Résultat attendu :
Preuve concrète, pure et testée :

- draft minimal avec id/name/scope/source/actions/outcomes ;
- validation draft ciblée ;
- conversion draft -> `ScenarioAsset` ou recommandation documentée si une
  conversion est prématurée ;
- tests unitaires sans UI.

Résultat P4-02 :

- rapport créé :
  `reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md` ;
- draft model pur ajouté dans `map_core` :
  `NarrativeScenarioAuthoringDraft`,
  `NarrativeScenarioAuthoringSourceDraft`,
  `NarrativeScenarioAuthoringActionDraft` ;
- diagnostics authoring V0 ajoutés :
  `emptyScenarioId`, `emptyScenarioName`, `missingSource`,
  `missingSourceReference`, `emptyActionReference`,
  `emitOutcomeNotDeclared`, `declaredOutcomeNeverEmitted` ;
- compilation déterministe `draft -> ScenarioAsset` ajoutée :
  graphe linéaire `start -> source -> actions -> end`,
  node ids et edge ids stables, outcomes déclarés conservés ;
- tests ciblés ajoutés dans
  `packages/map_core/test/narrative_scenario_authoring_draft_test.dart` ;
- aucun widget UI, aucun registry persistant, aucune migration, aucun runtime,
  aucun contenu Selbrume et aucun reward/money/XP créé.

### ✅ P4-03 — Event Source Authoring Draft Operations V0

Objectif :
Rendre authorables les sources `mapEnter`, `triggerEnter`, `entityInteract` et
`outcomeReceived` via opérations pures.

Résultat attendu :
Preuve concrète, pure et testée :

- draft/operation pour produire des source nodes valides ;
- validation des références map/trigger/entity/outcome à partir des sources
  existantes ;
- cas négatifs pour éviter les faux déclenchements ;
- pas d'EventRegistry.

Résultat P4-03 :

- rapport créé :
  `reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md` ;
- opérations authoring pures ajoutées dans `map_core` :
  `createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption`,
  `narrativeEventSourceIdForAuthoringSourceDraft`,
  `findNarrativeEventSourcePickerOptionForAuthoringSourceDraft`,
  `validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions`,
  `replaceNarrativeScenarioAuthoringDraftSource` ;
- diagnostics Event Source V0 ajoutés :
  `missingSourceReference`, `sourceOptionNotFound`,
  `unsupportedEventSourceKind` ;
- conversion depuis `NarrativeEventSourcePickerOption` prouvée pour
  `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived` ;
- compilation `draft -> ScenarioAsset` prouvée pour les quatre sources ;
- tests ciblés ajoutés dans
  `packages/map_core/test/narrative_event_source_authoring_operations_test.dart` ;
- aucun widget UI, aucun EventRegistry, aucun registry persistant, aucune
  migration, aucun runtime, aucun contenu Selbrume et aucun reward/money/XP
  créé.

### ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0

Objectif :
Rendre authorables les outcomes scénario et battle outcomes sans registry.

Résultat attendu :
Preuve concrète, pure et testée :

- opérations pour déclarer / émettre / recevoir un outcome scénario ;
- helpers authoring pour distinguer `scenario.outcome.*` et `battle:*` ;
- opérations ou read models pour brancher victory/defeat V0 ;
- diagnostics ou validation contre OutcomeRegistry/BattleRegistry implicites.

Résultat P4-04 :

- rapport créé :
  `reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md` ;
- opérations authoring pures ajoutées dans `map_core` :
  `addDeclaredOutcomeToNarrativeScenarioAuthoringDraft`,
  `addEmitOutcomeActionToNarrativeScenarioAuthoringDraft`,
  `createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption`,
  `addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft`,
  `narrativeScenarioOutcomeFlagReference`,
  `narrativeBattleOutcomeFlagReference`,
  `validateNarrativeOutcomeAuthoringDraft` ;
- diagnostics Outcome/Battle V0 ajoutés :
  `emptyOutcomeId`, `emptyBattleId`, `outcomeNotDeclared`,
  `declaredOutcomeNeverEmitted`, `battleOptionNotFound`,
  `missingTrainerReference`, `missingNpcEntityReference`,
  `scenarioOutcomeBattleOutcomeConfusion` ;
- séparation explicite `scenario.outcome.*` / `battle:*` prouvée ;
- compilation `draft -> ScenarioAsset` prouvée pour `sourceOutcome` et
  `startTrainerBattle` ;
- tests ciblés ajoutés dans
  `packages/map_core/test/narrative_outcome_authoring_operations_test.dart` ;
- aucun widget UI, aucun OutcomeRegistry/BattleRegistry, aucun registry
  persistant, aucune migration, aucun runtime, aucun contenu Selbrume et aucun
  reward/money/XP créé.

### ✅ P4-05 — Predicate / World Rule Authoring Draft V0

Objectif :
Rendre authorables les predicates et world rules passives sans créer
FactRegistry ni WorldRuleRegistry.

Résultat attendu :
Preuve concrète, pure et testée :

- draft de predicate / visibility rule / conditional dialogue minimal ajouté ;
- mapping pur vers `MapEntityRuntimePredicate`,
  `MapEntityNpcVisibilityRule` et `MapEntityConditionalDialogue` ;
- diagnostics authoring `emptyReferenceId`, `emptyDialogueId`,
  `missingPredicate` et `scenarioOutcomeBattleOutcomeConfusion` ;
- `scenario.outcome.*` et `battle:*` restent des flags techniques lisibles,
  pas des registries persistants ;
- tests ciblés ajoutés dans
  `packages/map_core/test/narrative_predicate_authoring_draft_test.dart` ;
- aucun widget UI, aucun FactRegistry/WorldRuleRegistry, aucune migration,
  aucun runtime, aucun contenu Selbrume et aucun reward/money/XP créé.

### ✅ P4-06 — Narrative Validator Authoring Adapter V0

Objectif :
Créer un adapter pur qui transforme les diagnostics narratifs existants en
messages authoring exploitables, sans auto-fix et sans UI premium.

Résultat attendu :
Preuve concrète, pure et testée :

- adapter pur ajouté dans `map_core` :
  `buildNarrativeAuthoringDiagnosticView`,
  `buildNarrativeAuthoringDiagnosticViews`,
  `NarrativeAuthoringDiagnosticView` ;
- catégories authoring V0 :
  `scenarioStructure`, `eventSource`, `dialogueReference`,
  `trainerBattleReference`, `outcomeAuthoring`, `predicateAuthoring`,
  `runtimeSupport`, `unknown` ;
- action hints V0 sans auto-fix :
  `inspectScenario`, `selectValidReference`, `declareOutcome`, `emitOutcome`,
  `addOutcomeReceiver`, `fixPredicate`, `replaceUnsupportedNode`,
  `noAutomaticFix` ;
- diagnostics P2-09 couverts :
  `declaredOutcomeNeverEmitted`, `emitOutcomeNotDeclared`,
  `visibilityRuleConditionalMissingPredicate`,
  `worldRulePredicateEmptyRefId`,
  `scenarioChoiceNodeRuntimeUnsupported` ;
- sévérité, path, referencedId et contexte technique conservés ;
- tests ciblés ajoutés dans
  `packages/map_core/test/narrative_validator_authoring_adapter_test.dart` ;
- aucun widget UI, aucun auto-fix, aucun registry persistant, aucune migration,
  aucun runtime, aucun contenu Selbrume et aucun reward/money/XP créé.

### P4-07 — Minimal Authoring Golden Path Test V0

Objectif :
Prouver un workflow authoring minimal complet sans UI premium.

Résultat :
Preuve concrète et testée ajoutée :

- sélection de références via read models ;
- draft scenario minimal ;
- source Event ;
- outcome émis/reçu ;
- predicate/world rule passive ;
- diagnostics authoring ;
- export ou conversion vers structures existantes, sans créer Selbrume final.
- test ciblé :
  `packages/map_core/test/narrative_authoring_golden_path_test.dart` ;
- rapport :
  `reports/roadmap/phase_4/p4_07_minimal_authoring_golden_path_test.md` ;
- aucun code de production modifié, aucune UI, aucun registry persistant,
  aucun auto-fix, aucun reward/money/XP et aucun contenu Selbrume final créé.

### P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

Objectif :
Clôturer Phase 4, vérifier les preuves authoring minimales et décider le
passage vers la phase suivante.

Résultat attendu :
Verdict Phase 4, roadmaps mises à jour, prochain lot exact fixé.

## 8. Critères de sortie Phase 4

Phase 4 pourra être clôturée si :

- les workflows authoring minimaux sont définis ou prouvés ;
- les pickers/read models nécessaires sont couverts ou reportés clairement ;
- les diagnostics utilisables avant runtime sont intégrables ;
- les limites UI premium restent explicites ;
- aucun registry persistant prématuré n'est créé ;
- aucun contenu Selbrume final n'est créé ;
- les gaps gameplay restent reportés à Phase 5 ;
- la roadmap globale est mise à jour au checkpoint.

## 9. Décisions à valider avant ou pendant P4-00

- Confirmer cette roadmap Phase 4.
- Choisir le niveau de preuve authoring attendu.
- Confirmer que P4-01 et suivants produisent des preuves authoring concrètes.
- Confirmer que l'UI premium reste Phase 7.
- Confirmer que rewards / money / XP restent Phase 5.
- Confirmer que Selbrume final reste Phase 6.

## 10. Rappels permanents

```text
Phase 4 prépare l'authoring minimal.
Phase 4 ne crée pas UI premium.
Phase 4 ne crée pas Selbrume final.
Phase 4 ne crée pas de registry persistant.
Phase 4 n'ouvre pas rewards / money / XP.
Phase 4 doit produire des preuves authoring concrètes après P4-00.
```

Le prochain lot exact est :

```text
P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
```
