# P4-00 — Phase 4 Roadmap Recalibration / Authoring Workflow Audit

## 1. Résumé exécutif

Verdict : la Phase 4 peut commencer, mais la roadmap initiale était trop
documentaire dans sa forme.

Le diagnostic est volontairement direct : les lots initiaux étaient cohérents
sur le fond, mais trop nombreux à promettre seulement un `Review`, un `Design`,
une `Readiness` ou une `Proposal`. Pour une phase censée rendre les mécaniques
narratives authorables, ce vocabulaire risquait de produire une belle série de
rapports sans livrer assez de briques exploitables.

Décision P4-00 :

- P4-00 reste un lot audit/recalibration ;
- P4-01 et suivants doivent produire des preuves authoring concrètes ;
- les preuves attendues sont des read models manquants, draft models,
  opérations pures, adapters validator et tests ciblés ;
- l'UI premium, Scene Builder complet, Cinematic Builder complet, Selbrume final
  et rewards / money / XP restent hors Phase 4 ;
- prochain lot exact :
  `P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0`.

## 2. Scope du lot

Inclus :

- lecture des roadmaps et checkpoints P2/P3 ;
- audit critique de la roadmap Phase 4 existante ;
- inventaire authoring/editor existant ;
- inventaire pickers/read models ;
- inventaire validator/diagnostics ;
- recalibration de `MVP Selbrume/road_map_phase_4.md` ;
- rapport P4-00 avec Evidence Pack.

Exclus :

- code de production ;
- tests ;
- fixtures ;
- UI ;
- widgets Flutter ;
- Scene Builder / Cinematic Builder complet ;
- modification `road_map_global.md` ;
- modification `packages/` ou `examples/` ;
- P4-01 ;
- Selbrume final ;
- rewards / money / XP.

## 3. Sources lues

Roadmaps et rapports :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_4.md`
- `reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md`
- `reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md`
- `reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md`
- `reports/roadmap/phase_2/p2_10_reference_picker_read_models.md`

Inventaire code lu en lecture seule :

- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart`
- `packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart`
- `packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_editor_mapping.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- tests editor/core ciblés listés dans l'Evidence Pack.

## 4. Diagnostic de la roadmap Phase 4 actuelle

Réponse courte : oui, la roadmap actuelle était trop documentaire.

Elle avait les bons sujets, mais pas assez d'engagement sur les preuves :

| Lot initial | Document only ? | Preuve concrète nécessaire ? | Décision P4-00 | Risque UI premium | Risque registry |
| --- | --- | --- | --- | --- | --- |
| P4-00 — Roadmap Bootstrap / Audit | Oui, acceptable | Non, c'est le lot de cadrage | Renommé en recalibration | Faible | Faible |
| P4-01 — Picker Coverage Review | Trop review | Oui, read models manquants V0 | Remplacé par Coverage & Missing Read Models V0 | Faible | Moyen si on crée un registry |
| P4-02 — Scenario Workflow Design | Trop design | Oui, draft model + validation | Remplacé par Scenario Authoring Draft Model V0 | Moyen | Faible |
| P4-03 — Event Source Workflow Design | Trop design | Oui, operations source nodes | Remplacé par Event Source Draft Operations V0 | Moyen | Moyen si EventRegistry |
| P4-04 — Outcome / Battle Workflow Design | Trop design | Oui, operations outcome/battle | Remplacé par Outcome / Battle Operations V0 | Moyen | Élevé si Outcome/BattleRegistry |
| P4-05 — Fact / World Rule Workflow Design | Trop design | Oui, predicate/world rule draft | Remplacé par Predicate / World Rule Draft V0 | Moyen | Élevé si Fact/WorldRuleRegistry |
| P4-06 — Validator Integration Readiness | Trop readiness | Oui, adapter diagnostics authoring | Remplacé par Validator Authoring Adapter V0 | Faible | Faible |
| P4-07 — Golden Path Proposal | Trop proposal | Oui, golden path test | Remplacé par Golden Path Test V0 | Moyen | Moyen |

Les lots qui peuvent rester design-only :

- P4-00 uniquement ;
- éventuellement une sous-partie de P4-CHECKPOINT, car c'est un checkpoint.

Les lots qui doivent produire du code pur/testable :

- P4-01 ;
- P4-02 ;
- P4-03 ;
- P4-04 ;
- P4-05 ;
- P4-06 ;
- P4-07.

## 5. Inventaire authoring/editor existant

État observé côté editor :

- `NarrativeWorkspaceProjection` expose déjà des summaries Scenario, Step et
  Outcome pour les panneaux narratifs ;
- `NarrativeLibraryPanel` et `NarrativeInspectorPanel` sont des surfaces UI
  existantes, mais pas des preuves suffisantes pour Phase 4 ;
- `StepStudio` et `GlobalStoryStudio` portent déjà des metadata d'authoring
  autour des steps et chapitres ;
- `CutsceneStudio` contient un modèle d'authoring et un compilateur vers
  `ScenarioAsset` ;
- `ProjectScenarioUseCases` sait créer, mettre à jour et supprimer un
  `ScenarioAsset`, mais il reçoit déjà un scenario construit ;
- `npc_runtime_rules_authoring_catalog.dart` fournit un catalogue auteur pour
  flags, steps, chapters et cutscenes ;
- `npc_runtime_rules_editor_mapping.dart` fournit déjà des mappings purs pour
  visibility rules et conditional dialogues ;
- les tests editor existent pour Step Studio, Global Story Studio, Cutscene
  Studio, projections, use cases scénario et règles PNJ.

Conclusion :

L'éditeur a des surfaces et des morceaux de logique authoring, mais la Phase 4
ne doit pas commencer par l'UI. Elle doit extraire ou compléter des contrats
purs et testables pour éviter que les workflows narratifs restent dispersés dans
des panneaux et metadata.

Éléments à réutiliser avec prudence :

- `CutsceneStudioDocument -> ScenarioAsset` comme preuve existante de conversion
  draft/document vers scenario ;
- `NpcRuntimeAuthoringCatalog` comme inspiration pour Fact/Predicate pickers ;
- `ProjectScenarioUseCases` comme persistance finale, pas comme draft model.

Éléments dangereux :

- considérer les panneaux existants comme "authoring minimal complet" ;
- exposer `outcome.id`, `flagName`, `refId` directement comme expérience auteur ;
- créer un registry persistant pour combler un picker manquant.

Ce qui doit attendre Phase 7 :

- UI premium ;
- design system final ;
- Scene Builder visuel complet ;
- Cinematic Builder complet.

## 6. Inventaire pickers/read models

Pickers/read models existants en `map_core` :

- `NarrativeScenarioPickerOption`
- `NarrativeOutcomePickerOption`
- `NarrativeBattleReferencePickerOption`
- `buildNarrativeScenarioPickerOptions`
- `buildNarrativeOutcomePickerOptions`
- `buildNarrativeBattleReferencePickerOptions`

Couverture actuelle :

- Scenario selection : couvert V0 ;
- Outcome declaration/emission/consumption : couvert V0 côté lecture ;
- Battle reference selection : couvert V0 côté lecture ;
- victory/defeat V0 : couvert via `NarrativeBattleOutcomeKind`.

Gaps de picker à classer pour P4-01 :

- Story Step picker : prioritaire si dérivable de Step Studio / Global Story
  metadata sans registry ;
- Event Source picker : prioritaire, car P4-03 aura besoin de map/trigger/entity
  et outcomeReceived ;
- Predicate / Fact reference picker : prioritaire sous forme de références
  dérivées des flags/steps/cutscenes/outcomes/battle flags observables ;
- World Rule picker : à traiter comme Predicate/World Rule authoring draft, pas
  comme WorldRuleRegistry ;
- Dialogue picker : probablement déjà dérivable de `ProjectManifest.dialogues`,
  mais peut rester hors P4-01 si le batch devient trop large ;
- Map picker / NPC entity picker / Trigger picker : nécessaires aux Event
  sources, mais leur emplacement peut être `map_core` ou `map_editor` selon les
  sources disponibles ;
- Cinematic picker : probablement report Phase 7 ou lié à local event flows ;
- Condition/predicate picker : à cadrer dans P4-01/P4-05.

Recommandation P4-01 :

Produire un petit batch concret de read models manquants, pas tous les pickers
imaginables. Candidats les plus sains :

1. `NarrativeEventSourcePickerOption` ou équivalent ;
2. `NarrativeStoryStepPickerOption` dérivé des metadata Step Studio ;
3. `NarrativePredicateReferencePickerOption` ou petit set flag/step/cutscene
   si les sources sont stables.

## 7. Inventaire validator/diagnostics

Diagnostics P2-09 prêts à relier aux workflows authoring :

- `declaredOutcomeNeverEmitted` : prêt pour outcome authoring ;
- `emitOutcomeNotDeclared` : prêt pour outcome authoring ;
- `visibilityRuleConditionalMissingPredicate` : prêt pour predicate/world rule
  authoring ;
- `worldRulePredicateEmptyRefId` : prêt pour predicate/world rule authoring ;
- `scenarioChoiceNodeRuntimeUnsupported` : prêt pour scenario/cutscene authoring
  pour prévenir un support runtime partiel.

Diagnostics préexistants utiles :

- source outcome sans emit matching ;
- emit outcome sans source matching ;
- flag read/produced ;
- step read/completed ;
- trainer battle references missing/unknown ;
- conditional dialogue unknown dialogue.

Gap Phase 4 :

Il manque un adapter authoring qui transforme ces diagnostics en messages et
actions lisibles pour un workflow auteur. Cet adapter ne doit pas corriger les
données, ni masquer la sévérité du validator.

## 8. Matrice workflows authoring

| Workflow authoring | État actuel | Preuve / fichiers observés | Ce que la roadmap actuelle prévoit | Risque documentaire | Preuve concrète recommandée | Lot Phase 4 recommandé | Décision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Scenario selection | Couvert V0 | `NarrativeScenarioPickerOption` | Review picker | Moyen | confirmer coverage + tests | P4-01 | Conserver et réutiliser |
| Scenario creation / edit | Partiel | `ProjectScenarioUseCases`, Cutscene compiler | Design workflow | Élevé | draft model + validation + conversion | P4-02 | Recalibrer en code pur |
| Outcome declaration | Couvert lecture, pas opérations | Outcome picker, Cutscene compiler | Design | Élevé | operation declare outcome | P4-04 | Recalibrer |
| Outcome emission | Couvert runtime, partiel authoring | `emitOutcome`, Cutscene Studio | Design | Élevé | operation add emit node / result | P4-04 | Recalibrer |
| Outcome received | Couvert runtime, partiel authoring | `sourceOutcome`, P3-03/P3-04 | Design | Élevé | operation source outcome node | P4-03/P4-04 | Recalibrer |
| Battle reference selection | Couvert V0 | `NarrativeBattleReferencePickerOption` | Review picker | Moyen | confirmer + gaps NPC/trainer labels | P4-01/P4-04 | Conserver |
| Event source mapEnter | Modèle Cutscene + runtime | Cutscene source config | Design | Élevé | source draft operation | P4-03 | Recalibrer |
| Event source triggerEnter | Modèle Cutscene + runtime | Cutscene source config | Design | Élevé | trigger source operation + picker gap | P4-03 | Recalibrer |
| Event source entityInteract | Modèle Cutscene + runtime | Cutscene source config | Design | Élevé | entity source operation + picker gap | P4-03 | Recalibrer |
| Event source outcomeReceived | Runtime prouvé, authoring faible | sourceOutcome, outcome picker | Design | Élevé | outcome source operation | P4-03/P4-04 | Recalibrer |
| Story Step reference | Partiel editor metadata | Step Studio, projection | Picker reporté | Moyen | Story Step read model V0 | P4-01 | Ajouter preuve |
| Fact / flag reference | Partiel PNJ catalog | `NpcRuntimeAuthoringCatalog` | Design World Rule | Moyen | Fact/predicate reference read model | P4-01/P4-05 | Ajouter preuve |
| Predicate authoring | Partiel PNJ mapping | `npc_runtime_rules_editor_mapping.dart` | Design | Moyen | draft predicate + validation | P4-05 | Recalibrer |
| Visibility rule authoring | Partiel | mapping + tests PNJ | Design | Moyen | generalized draft/mapping test | P4-05 | Recalibrer |
| Conditional dialogue authoring | Partiel | mapping + dialogue refs | Design | Moyen | draft rows + diagnostics | P4-05 | Recalibrer |
| Step Studio world presence authoring | Partiel metadata | Step Studio document/runtime | Design | Moyen | clarify draft source or report | P4-05 | Recalibrer |
| Validator diagnostics exposure | Diagnostics existent | P2-09 validator | Readiness | Élevé | adapter authoring messages | P4-06 | Recalibrer |
| Golden path authoring proposal | Non prouvé | pieces dispersed | Proposal | Très élevé | test authoring golden path | P4-07 | Recalibrer |

## 9. Risque de phase trop documentaire

Le risque est réel.

La roadmap initiale risquait de produire :

- un audit de pickers sans nouveaux read models ;
- un design scenario sans draft model ;
- un design Event Source sans opérations ;
- un design Outcome/Battle sans helpers testés ;
- une readiness validator sans adapter ;
- une proposal golden path sans test.

Ce serait insuffisant, parce que Phase 4 doit commencer à fermer le gap qui
reste entre "runtime prouvé" et "créateur capable d'authorer". Elle ne doit pas
devenir Phase 7 UI premium, mais elle doit laisser des briques consommables par
Phase 7.

## 10. Roadmap Phase 4 recalibrée

Roadmap retenue :

1. P4-00 — Phase 4 Roadmap Recalibration / Authoring Workflow Audit
2. P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0
3. P4-02 — Scenario Authoring Draft Model V0
4. P4-03 — Event Source Authoring Draft Operations V0
5. P4-04 — Outcome / Battle Outcome Authoring Operations V0
6. P4-05 — Predicate / World Rule Authoring Draft V0
7. P4-06 — Narrative Validator Authoring Adapter V0
8. P4-07 — Minimal Authoring Golden Path Test V0
9. P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

Critère clé de la recalibration :

```text
Après P4-00, chaque lot principal doit produire une preuve authoring concrète
ou justifier strictement pourquoi le design-only reste nécessaire.
```

## 11. Prochain lot exact

```text
P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0
```

Justification :

Les pickers/read models sont le premier point de friction no-code. Sans sources
de références lisibles pour steps, event sources et predicates, les drafts
suivants retomberont dans les IDs bruts. P4-01 doit donc compléter la base de
sélection avant les opérations authoring.

## 12. Modifications effectuées

Fichier créé :

- `reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md`

Fichier modifié :

- `MVP Selbrume/road_map_phase_4.md`

Aucun code, test, fixture, widget, runtime ou rapport P4-01 n'a été créé.

## 13. Evidence Pack

### 13.1 git status initial exact

```text
(aucune sortie)
```

### 13.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_4.md
reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md
reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart
packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_editor_mapping.dart
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/test/project_scenario_use_cases_test.dart
packages/map_editor/test/narrative_workspace_projection_test.dart
packages/map_editor/test/npc_runtime_rules_authoring_catalog_test.dart
packages/map_editor/test/npc_runtime_rules_editor_mapping_test.dart
packages/map_editor/test/cutscene_studio_authoring_test.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
```

### 13.3 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,420p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md
sed -n '1,280p' reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
sed -n '1,320p' reports/roadmap/phase_2/p2_09_narrative_validator_diagnostic_expansion.md
sed -n '1,320p' reports/roadmap/phase_2/p2_10_reference_picker_read_models.md
rg -n "NarrativeScenarioPickerOption|NarrativeOutcomePickerOption|NarrativeBattleReferencePickerOption|buildNarrativeScenarioPickerOptions|buildNarrativeOutcomePickerOptions|buildNarrativeBattleReferencePickerOptions|declaredOutcomeNeverEmitted|emitOutcomeNotDeclared|visibilityRuleConditionalMissingPredicate|worldRulePredicateEmptyRefId|scenarioChoiceNodeRuntimeUnsupported" packages/map_core packages/map_editor --glob '!build/**' --glob '!**/.dart_tool/**'
rg -n "Narrative|ScenarioAsset|Scenario|Storyline|Story Step|Step Studio|Event Source|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|outcomeReceived|emitOutcome|startTrainerBattle|Fact|World Rule|Predicate|visibilityRule|conditionalDialogues|Validator|Diagnostics|Picker|ReadModel|Draft|Authoring" packages/map_editor packages/map_core packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_editor/lib -type f | sort
find packages/map_core/lib/src/read_models -type f 2>/dev/null | sort
find packages/map_core/lib/src/operations -type f | sort | rg "narrative|validator|picker|scenario|world|predicate|story|step|dialogue|battle"
find packages/map_editor/lib/src/features -maxdepth 5 -type f | sort | rg "narrative|scenario|story|step|event|dialogue|validator|author|picker|map|entity|trigger"
sed -n '1,260p' AGENTS.md
if test -f skills/README.md; then sed -n '1,260p' skills/README.md; else echo 'skills/README.md absent'; fi
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '1,260p' packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart
sed -n '1,280p' packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
sed -n '1,280p' packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
sed -n '1,280p' packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
find packages/map_editor/test -type f | sort | rg "narrative|step|global|cutscene|dialogue|runtime|scenario|authoring|npc|predicate|validator"
sed -n '1,240p' packages/map_editor/test/project_scenario_use_cases_test.dart
sed -n '1,260p' packages/map_editor/test/narrative_workspace_projection_test.dart
sed -n '1,260p' packages/map_editor/test/npc_runtime_rules_authoring_catalog_test.dart
sed -n '1,220p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
sed -n '1,360p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,220p' packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_editor_mapping.dart
sed -n '1,220p' packages/map_core/lib/src/models/map_entity_runtime_predicate.dart
rg -n "enum MapEntityRuntimePredicateKind|class MapEntityRuntimePredicate|class MapEntityNpcVisibilityRule|class MapEntityConditionalDialogue" packages/map_core/lib/src/models packages/map_core/lib/src --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '40,130p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,180p' packages/map_editor/lib/src/ui/panels/entity_properties/entity_properties_npc_runtime.dart
rg -n "class .*Draft|Draft|create.*Scenario|ScenarioAsset\\(|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|emitOutcome|startTrainerBattle|ProjectValidator.validate|narrativeWorkspaceProjectionProvider" packages/map_editor/lib/src/features/narrative packages/map_editor/lib/src/application/use_cases packages/map_editor/test --glob '!build/**' --glob '!**/.dart_tool/**'
find reports/roadmap -maxdepth 2 -type d | sort
ls -ld reports/roadmap/phase_4 2>/dev/null || true
mkdir -p reports/roadmap/phase_4
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- "MVP Selbrume/road_map_global.md"
find reports/roadmap/phase_4 -maxdepth 1 -type f | sort
git diff --no-index --check /dev/null reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md || true
```

Les commandes finales de validation sont listées en 13.7 à 13.10.

### 13.4 Sorties utiles

Signaux utiles observés :

- `git status --short --untracked-files=all` initial : aucune sortie.
- `MVP Selbrume/road_map_phase_4.md` contenait une roadmap cohérente mais
  dominée par `Review`, `Design`, `Readiness`, `Proposal`.
- `map_core` contient seulement un fichier read models narratifs :
  `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`.
- Les diagnostics P2-09 sont présents dans
  `packages/map_core/lib/src/operations/narrative_validator.dart`.
- `map_editor` contient déjà :
  - `NarrativeWorkspaceProjection` ;
  - Step Studio / Global Story Studio authoring ;
  - Cutscene Studio authoring + compiler ;
  - `ProjectScenarioUseCases` ;
  - `NpcRuntimeAuthoringCatalog` ;
  - `npc_runtime_rules_editor_mapping.dart`.
- Tests editor observés :
  - `project_scenario_use_cases_test.dart` ;
  - `narrative_workspace_projection_test.dart` ;
  - `npc_runtime_rules_authoring_catalog_test.dart` ;
  - `npc_runtime_rules_editor_mapping_test.dart` ;
  - `cutscene_studio_authoring_test.dart`.
- La commande
  `sed -n '1,220p' packages/map_core/lib/src/models/map_entity_runtime_predicate.dart`
  a échoué car ce fichier n'existe pas ; le modèle est dans
  `packages/map_core/lib/src/models/map_entity_payloads.dart`.
- `reports/roadmap/phase_4` était absent avant création.

### 13.5 Fichiers créés

```text
reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md
```

### 13.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_4.md
```

### 13.7 git diff --check exact

```text
(aucune sortie)
```

### 13.8 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_4.md | 167 ++++++++++++++++++++++++++-------------
 1 file changed, 112 insertions(+), 55 deletions(-)
```

### 13.9 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_4.md
```

### 13.10 git status final exact

```text
 M "MVP Selbrume/road_map_phase_4.md"
?? reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md
```

### 13.11 Contrôles explicites

- Aucun code modifié :
  `git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host`
  n'a produit aucune sortie.
- `road_map_global.md` non modifiée :
  `git diff --name-only -- "MVP Selbrume/road_map_global.md"` n'a produit
  aucune sortie.
- P4-01 non exécuté :
  `find reports/roadmap/phase_4 -maxdepth 1 -type f | sort` liste uniquement
  `reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md`.
- Selbrume final non créé.
- Aucune UI premium créée.
- Aucun reward / money / XP ajouté.
- Tests non exécutés : P4-00 est documentaire ; aucune modification de code ne
  nécessite un test.
- Rapport P4-00 vérifié :
  `git diff --no-index --check /dev/null reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md || true`
  n'a produit aucune sortie.

## 14. Auto-review critique

- Le rapport P4-00 existe-t-il ?
  Oui.
- La roadmap Phase 4 a-t-elle été réellement critiquée ?
  Oui : le risque documentaire est explicitement jugé réel.
- La roadmap a-t-elle été recalibrée ?
  Oui : P4-01 à P4-07 ont maintenant des preuves concrètes attendues.
- `road_map_global.md` est-elle restée intacte ?
  Oui.
- Aucun code n'a-t-il été modifié ?
  Oui.
- Aucun widget UI / Scene Builder / Cinematic Builder n'a-t-il été créé ?
  Oui.
- P4-01 n'a-t-il pas été exécuté ?
  Oui.
- Le prochain lot exact est-il clair ?
  Oui : P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0.

## 15. Regard critique sur le prompt

Le prompt corrige un vrai risque de gouvernance : après trois phases de
validation, la tentation était de rester dans des lots très propres mais trop
papier. La demande force une bonne tension : produire des preuves authoring
concrètes sans basculer prématurément dans l'UI premium ou les registries. La
recalibration proposée garde cette tension en rendant P4-01 à P4-07 testables.
