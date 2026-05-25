# P4-07 — Minimal Authoring Golden Path Test V0

## 1. Résumé exécutif

P4-07 est validable.

Le lot ajoute une preuve exécutable pure dans `map_core` :

```text
read models P4-01
-> sélection de références
-> source draft P4-03
-> scenario draft P4-02
-> outcome/battle authoring P4-04
-> predicate/visibility/conditional dialogue P4-05
-> ScenarioAsset compilé
-> narrative validator
-> vues authoring P4-06
```

Aucun code de production n'a été modifié. Le lot ajoute uniquement un test
golden path, met à jour la roadmap Phase 4 et crée ce rapport.

Prochain lot exact :

```text
P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
```

## 2. Scope du lot

Inclus :

- `ProjectManifest` et `MapData` in-memory techniques non-Selbrume ;
- read models : scenarios, event sources, outcomes, battles, predicates ;
- conversion picker event source -> source draft ;
- création d'un `NarrativeScenarioAuthoringDraft` ;
- ajout `declaredOutcome`, `emitOutcome`, `startTrainerBattle` ;
- source `outcomeReceived` ;
- predicates techniques `storyFlag`, `storyStep`, `scenario.outcome.*`,
  `battle:*` ;
- compilation visibility rule et conditional dialogue vers payloads runtime ;
- compilation draft -> `ScenarioAsset` ;
- validation narrative existante ;
- adaptation de diagnostics validator vers vues authoring ;
- preuve d'absence d'auto-fix, registry, UI premium et contenu Selbrume.

Exclus :

- UI, widget Flutter, Scene Builder, Cinematic Builder, Validator UI ;
- auto-fix ;
- registry persistant, `EventRegistry`, `FactRegistry`,
  `WorldRuleRegistry`, `OutcomeRegistry`, `BattleRegistry` ;
- modification de `ProjectManifest`, `ScenarioAsset`, `GameState`,
  `SaveData`, `MapEntity`, `narrative_validator.dart` ;
- runtime, playable host, fixture disque ;
- Selbrume final, rewards, money, XP, level-up ;
- P4-CHECKPOINT-01.

## 3. Sources lues

Sources principales :

- `AGENTS.md` fourni dans le prompt ;
- `skills/README.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- `MVP Selbrume/road_map_global.md` ;
- `MVP Selbrume/road_map_phase_4.md` ;
- `reports/roadmap/phase_4/p4_06_narrative_validator_authoring_adapter.md` ;
- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart` ;
- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart` ;
- `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart` ;
- `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart` ;
- `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart` ;
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart` ;
- `packages/map_core/lib/src/models/project_manifest.dart` ;
- `packages/map_core/lib/src/models/map_data.dart` ;
- `packages/map_core/lib/src/models/map_entity_payloads.dart` ;
- `packages/map_core/lib/src/models/project_trainer.dart` ;
- `packages/map_core/lib/src/models/scenario_asset.dart` ;
- `packages/map_core/lib/src/operations/narrative_validator.dart` ;
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart` ;
- `packages/map_core/test/narrative_validator_authoring_adapter_test.dart` ;
- `packages/map_core/test/narrative_validator_test.dart`.

Note de lecture :

- `packages/map_core/lib/src/models/map_entity.dart` n'existe pas ; l'entité
  persistante `MapEntity` est définie dans
  `packages/map_core/lib/src/models/map_data.dart`.

## 4. Golden path authoring testé

Le test crée un `ProjectManifest` technique nommé `P4 Authoring Golden Path`
et une map `p4_authoring_map`, sans fixture disque.

Le workflow principal vérifie :

- options de scenario présentes ;
- option event source `entityInteract:p4_authoring_map:p4_authoring_npc` ;
- option outcome `p4.outcome.done` déclarée, émise et consommée ;
- option battle `p4_battle` liée à `p4_trainer` et
  `p4_authoring_npc` ;
- option predicate story flag `p4.flag.visible` ;
- option predicate story step `p4.step.completed` ;
- option predicate `scenario.outcome.p4.outcome.done` ;
- option predicate `battle:p4_battle:victory`.

Le scenario draft compilé contient :

- source `sourceEntityInteract` ;
- action `setFlag` ;
- action `completeStep` ;
- action `emitOutcome` ;
- action `startTrainerBattle` ;
- un start node, un end node et des edge ids déterministes.

## 5. Read models utilisés

Fonctions appelées par le test :

- `buildNarrativeScenarioPickerOptions(...)` ;
- `buildNarrativeEventSourcePickerOptions(...)` ;
- `buildNarrativeOutcomePickerOptions(...)` ;
- `buildNarrativeBattleReferencePickerOptions(...)` ;
- `buildNarrativePredicateReferencePickerOptions(...)`.

Le test s'appuie sur :

- `ProjectManifest.maps` pour `mapEnter` ;
- `MapData.triggers` pour `triggerEnter` disponible dans les options ;
- `MapData.entities` pour `entityInteract` ;
- `ScenarioAsset.declaredOutcomes` et `emitOutcome` / `sourceOutcome` pour
  les outcomes ;
- `startTrainerBattle` pour la référence battle ;
- Step Studio metadata pour la référence `storyStep` ;
- helpers P4-04 pour vérifier `scenario.outcome.*` et `battle:*`.

## 6. Draft scenario / source / outcome

P4-07 utilise les APIs P4-02, P4-03 et P4-04 :

- `createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(...)` ;
- `narrativeEventSourceIdForAuthoringSourceDraft(...)` ;
- `findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(...)` ;
- `validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(...)` ;
- `NarrativeScenarioAuthoringDraft` ;
- `addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(...)` ;
- `addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(...)` ;
- `createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(...)` ;
- `addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(...)` ;
- `validateNarrativeScenarioAuthoringDraft(...)` ;
- `validateNarrativeOutcomeAuthoringDraft(...)` ;
- `compileNarrativeScenarioAuthoringDraftToScenarioAsset(...)`.

Le test confirme que les diagnostics de draft et d'outcome authoring sont vides
sur le chemin nominal.

## 7. Predicate / visibility / conditional dialogue

P4-07 utilise les APIs P4-05 :

- `createNarrativePredicateAuthoringDraftFromReferenceOption(...)` ;
- `compileNarrativePredicateAuthoringDraftToRuntimePredicate(...)` ;
- `compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(...)` ;
- `compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(...)`.

Le test prouve que :

- `scenario.outcome.p4.outcome.done` compile comme
  `MapEntityRuntimePredicateKind.storyFlagSet` ;
- `battle:p4_battle:victory` compile comme
  `MapEntityRuntimePredicateKind.storyFlagSet` ;
- ces deux références restent des flags techniques lisibles, pas des registries ;
- une visibility rule `visibleWhen` compile vers
  `MapEntityNpcVisibilityRule` ;
- un conditional dialogue compile vers `MapEntityConditionalDialogue`.

## 8. Validator authoring adapter

Le test appelle `diagnoseNarrativeProject(...)` sur le scenario compilé et la
map authored, puis `buildNarrativeAuthoringDiagnosticViews(...)`.

Le test ajoute aussi un cas volontairement invalide :

```text
MapEntityNpcVisibilityRule(mode: visibleWhen, predicate: null)
```

Il vérifie le diagnostic :

```text
visibilityRuleConditionalMissingPredicate
```

et sa vue authoring :

- catégorie `predicateAuthoring` ;
- action kind `fixPredicate` ;
- sévérité conservée ;
- `path`, `mapId`, `entityId` conservés ;
- `hasAutomaticFix == false` ;
- liste de vues immuable.

## 9. Limites et reports vers P4-CHECKPOINT / Phase 5 / Phase 7

Limites assumées :

- preuve in-memory pure, pas fixture disque ;
- pas d'UI editor ;
- pas de PlayableMapGame ou runtime host ;
- pas de correction automatique ;
- pas de création de contenu final ;
- pas de branchement gameplay rewards/money/XP.

Reporté à P4-CHECKPOINT-01 :

- décider si la Phase 4 est clôturable avec ces preuves authoring minimales ;
- classifier les réserves restantes.

Reporté à Phase 5 :

- rewards, money, XP, level-up et gaps gameplay.

Reporté à Phase 7 :

- UI premium, builders riches, navigation visuelle des diagnostics.

## 10. Tests exécutés

Cycle TDD red initial :

```bash
cd packages/map_core && dart test test/narrative_authoring_golden_path_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_authoring_golden_path_test.dart
00:00 +0 -1: loading test/narrative_authoring_golden_path_test.dart [E]
  Failed to load "test/narrative_authoring_golden_path_test.dart": Does not exist.

To run this test again: dart test test/narrative_authoring_golden_path_test.dart -p vm --plain-name 'loading test/narrative_authoring_golden_path_test.dart'
00:00 +0 -1: Some tests failed.
```

Test ciblé final :

```bash
cd packages/map_core && dart test test/narrative_authoring_golden_path_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_authoring_golden_path_test.dart
00:00 +0: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics
00:00 +1: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics
00:00 +1: P4-07 minimal authoring golden path adapts validator diagnostics into authoring views without auto-fix
00:00 +2: P4-07 minimal authoring golden path adapts validator diagnostics into authoring views without auto-fix
00:00 +2: All tests passed!
```

Régressions ciblées :

```bash
cd packages/map_core && dart test test/narrative_validator_authoring_adapter_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_validator_authoring_adapter_test.dart
00:00 +0: Narrative validator authoring adapter maps declaredOutcomeNeverEmitted to outcome authoring view
00:00 +1: Narrative validator authoring adapter maps declaredOutcomeNeverEmitted to outcome authoring view
00:00 +1: Narrative validator authoring adapter maps emitOutcomeNotDeclared to outcome authoring view
00:00 +2: Narrative validator authoring adapter maps emitOutcomeNotDeclared to outcome authoring view
00:00 +2: Narrative validator authoring adapter maps predicate diagnostics to predicate authoring views
00:00 +3: Narrative validator authoring adapter maps predicate diagnostics to predicate authoring views
00:00 +3: Narrative validator authoring adapter maps unsupported choice node to runtime support view
00:00 +4: Narrative validator authoring adapter maps unsupported choice node to runtime support view
00:00 +4: Narrative validator authoring adapter preserves severity and technical context fields
00:00 +5: Narrative validator authoring adapter preserves severity and technical context fields
00:00 +5: Narrative validator authoring adapter maps trainer battle diagnostics to trainer battle reference view
00:00 +6: Narrative validator authoring adapter maps trainer battle diagnostics to trainer battle reference view
00:00 +6: Narrative validator authoring adapter maps unmapped diagnostics to unknown without automatic fix
00:00 +7: Narrative validator authoring adapter maps unmapped diagnostics to unknown without automatic fix
00:00 +7: Narrative validator authoring adapter builds stable immutable lists without auto-fix metadata
00:00 +8: Narrative validator authoring adapter builds stable immutable lists without auto-fix metadata
00:00 +8: Narrative validator authoring adapter does not hardcode Selbrume identifiers
00:00 +9: Narrative validator authoring adapter does not hardcode Selbrume identifiers
00:00 +9: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_predicate_authoring_draft_test.dart
00:00 +0: Narrative predicate authoring draft creates predicate drafts from reference picker options
00:00 +1: Narrative predicate authoring draft creates predicate drafts from reference picker options
00:00 +1: Narrative predicate authoring draft compiles predicate drafts to runtime predicates
00:00 +2: Narrative predicate authoring draft compiles predicate drafts to runtime predicates
00:00 +2: Narrative predicate authoring draft diagnoses empty predicate reference ids
00:00 +3: Narrative predicate authoring draft diagnoses empty predicate reference ids
00:00 +3: Narrative predicate authoring draft compiles visibleWhen visibility rule to NPC visibility rule
00:00 +4: Narrative predicate authoring draft compiles visibleWhen visibility rule to NPC visibility rule
00:00 +4: Narrative predicate authoring draft diagnoses conditional visibility rule without predicate
00:00 +5: Narrative predicate authoring draft diagnoses conditional visibility rule without predicate
00:00 +5: Narrative predicate authoring draft compiles conditional dialogue to runtime conditional dialogue
00:00 +6: Narrative predicate authoring draft compiles conditional dialogue to runtime conditional dialogue
00:00 +6: Narrative predicate authoring draft diagnoses empty dialogue ids and missing conditional predicates
00:00 +7: Narrative predicate authoring draft diagnoses empty dialogue ids and missing conditional predicates
00:00 +7: Narrative predicate authoring draft accepts scenario outcome and battle outcome as technical flag refs
00:00 +8: Narrative predicate authoring draft accepts scenario outcome and battle outcome as technical flag refs
00:00 +8: Narrative predicate authoring draft diagnoses technical outcome refs used as non-flag predicates
00:00 +9: Narrative predicate authoring draft diagnoses technical outcome refs used as non-flag predicates
00:00 +9: Narrative predicate authoring draft does not create registries or hardcode Selbrume identifiers
00:00 +10: Narrative predicate authoring draft does not create registries or hardcode Selbrume identifiers
00:00 +10: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_outcome_authoring_operations_test.dart
00:00 +0: Narrative outcome authoring operations adds and dedupes declared outcomes without mutating the original
00:00 +1: Narrative outcome authoring operations adds and dedupes declared outcomes without mutating the original
00:00 +1: Narrative outcome authoring operations adds emitOutcome action without auto-declaring by default
00:00 +2: Narrative outcome authoring operations adds emitOutcome action without auto-declaring by default
00:00 +2: Narrative outcome authoring operations diagnoses undeclared emits and declared outcomes never emitted
00:00 +3: Narrative outcome authoring operations diagnoses undeclared emits and declared outcomes never emitted
00:00 +3: Narrative outcome authoring operations creates outcomeReceived source from outcome picker option
00:00 +4: Narrative outcome authoring operations creates outcomeReceived source from outcome picker option
00:00 +4: Narrative outcome authoring operations compiles outcomeReceived source with setFlag into sourceOutcome
00:00 +5: Narrative outcome authoring operations compiles outcomeReceived source with setFlag into sourceOutcome
00:00 +5: Narrative outcome authoring operations adds startTrainerBattle action from battle reference option
00:00 +6: Narrative outcome authoring operations adds startTrainerBattle action from battle reference option
00:00 +6: Narrative outcome authoring operations compiles entityInteract with startTrainerBattle bindings
00:00 +7: Narrative outcome authoring operations compiles entityInteract with startTrainerBattle bindings
00:00 +7: Narrative outcome authoring operations builds scenario and battle outcome flag references separately
00:00 +8: Narrative outcome authoring operations builds scenario and battle outcome flag references separately
00:00 +8: Narrative outcome authoring operations diagnoses battle option and battle reference problems
00:00 +9: Narrative outcome authoring operations diagnoses battle option and battle reference problems
00:00 +9: Narrative outcome authoring operations diagnoses scenario outcome and battle outcome confusion
00:00 +10: Narrative outcome authoring operations diagnoses scenario outcome and battle outcome confusion
00:00 +10: Narrative outcome authoring operations throws for empty direct flag references
00:00 +11: Narrative outcome authoring operations throws for empty direct flag references
00:00 +11: Narrative outcome authoring operations does not hardcode Selbrume identifiers
00:00 +12: Narrative outcome authoring operations does not hardcode Selbrume identifiers
00:00 +12: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_event_source_authoring_operations_test.dart
00:00 +0: Narrative event source authoring operations converts picker options into source drafts
00:00 +1: Narrative event source authoring operations converts picker options into source drafts
00:00 +1: Narrative event source authoring operations calculates stable source ids aligned with picker options
00:00 +2: Narrative event source authoring operations calculates stable source ids aligned with picker options
00:00 +2: Narrative event source authoring operations finds matching picker options and returns null when unavailable
00:00 +3: Narrative event source authoring operations finds matching picker options and returns null when unavailable
00:00 +3: Narrative event source authoring operations validates empty references and unavailable options
00:00 +4: Narrative event source authoring operations validates empty references and unavailable options
00:00 +4: Narrative event source authoring operations replaces draft source without mutating the original draft
00:00 +5: Narrative event source authoring operations replaces draft source without mutating the original draft
00:00 +5: Narrative event source authoring operations compiles updated drafts with the correct source node for every source
00:00 +6: Narrative event source authoring operations compiles updated drafts with the correct source node for every source
00:00 +6: Narrative event source authoring operations does not hardcode Selbrume identifiers
00:00 +7: Narrative event source authoring operations does not hardcode Selbrume identifiers
00:00 +7: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_scenario_authoring_draft_test.dart
00:00 +0: NarrativeScenarioAuthoringDraft validation accepts a minimal authoring draft
00:00 +1: NarrativeScenarioAuthoringDraft validation accepts a minimal authoring draft
00:00 +1: NarrativeScenarioAuthoringDraft validation rejects empty scenario id and name
00:00 +2: NarrativeScenarioAuthoringDraft validation rejects empty scenario id and name
00:00 +2: NarrativeScenarioAuthoringDraft validation rejects missing source and required source references
00:00 +3: NarrativeScenarioAuthoringDraft validation rejects missing source and required source references
00:00 +3: NarrativeScenarioAuthoringDraft validation rejects actions with missing required references
00:00 +4: NarrativeScenarioAuthoringDraft validation rejects actions with missing required references
00:00 +4: NarrativeScenarioAuthoringDraft validation detects emitted and declared outcome drift
00:00 +5: NarrativeScenarioAuthoringDraft validation detects emitted and declared outcome drift
00:00 +5: compileNarrativeScenarioAuthoringDraftToScenarioAsset compiles mapEnter with linear actions into a deterministic asset
00:00 +6: compileNarrativeScenarioAuthoringDraftToScenarioAsset compiles mapEnter with linear actions into a deterministic asset
00:00 +6: compileNarrativeScenarioAuthoringDraftToScenarioAsset compiles entityInteract with startTrainerBattle using source entity
00:00 +7: compileNarrativeScenarioAuthoringDraftToScenarioAsset compiles entityInteract with startTrainerBattle using source entity
00:00 +7: compileNarrativeScenarioAuthoringDraftToScenarioAsset does not mutate input lists and exposes immutable lists
00:00 +8: compileNarrativeScenarioAuthoringDraftToScenarioAsset does not mutate input lists and exposes immutable lists
00:00 +8: compileNarrativeScenarioAuthoringDraftToScenarioAsset does not hardcode Selbrume identifiers
00:00 +9: compileNarrativeScenarioAuthoringDraftToScenarioAsset does not hardcode Selbrume identifiers
00:00 +9: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_reference_picker_read_models_test.dart
00:00 +0: Narrative reference picker read models builds scenario picker options with stable labels and counts
00:00 +1: Narrative reference picker read models builds scenario picker options with stable labels and counts
00:00 +1: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids
00:00 +2: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids
00:00 +2: Narrative reference picker read models builds battle reference picker options from trainer battle nodes
00:00 +3: Narrative reference picker read models builds battle reference picker options from trainer battle nodes
00:00 +3: Narrative reference picker read models builds story step picker options from Step Studio metadata
00:00 +4: Narrative reference picker read models builds story step picker options from Step Studio metadata
00:00 +4: Narrative reference picker read models dedupes story steps and keeps legacy metadata as fallback
00:00 +5: Narrative reference picker read models dedupes story steps and keeps legacy metadata as fallback
00:00 +5: Narrative reference picker read models builds event source picker options from maps entities and outcomes
00:00 +6: Narrative reference picker read models builds event source picker options from maps entities and outcomes
00:00 +6: Narrative reference picker read models builds predicate reference picker options from derived facts
00:00 +7: Narrative reference picker read models builds predicate reference picker options from derived facts
00:00 +7: Narrative reference picker read models returns empty missing read model options for empty sources
00:00 +8: Narrative reference picker read models returns empty missing read model options for empty sources
00:00 +8: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_validator_test.dart
```

Sortie :

```text
00:00 +0: loading test/narrative_validator_test.dart
00:00 +0: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 declared outcome never emitted produces warning
00:00 +14: Narrative Validator Minimal V0 declared outcome never emitted produces warning
00:00 +14: Narrative Validator Minimal V0 emitOutcome not declared by scenario produces warning
00:00 +15: Narrative Validator Minimal V0 emitOutcome not declared by scenario produces warning
00:00 +15: Narrative Validator Minimal V0 conditional visibility rule without predicate produces error
00:00 +16: Narrative Validator Minimal V0 conditional visibility rule without predicate produces error
00:00 +16: Narrative Validator Minimal V0 world rule predicate with empty refId produces error
00:00 +17: Narrative Validator Minimal V0 world rule predicate with empty refId produces error
00:00 +17: Narrative Validator Minimal V0 choice node produces runtime unsupported warning
00:00 +18: Narrative Validator Minimal V0 choice node produces runtime unsupported warning
00:00 +18: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +19: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +19: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +20: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +20: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +21: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +21: All tests passed!
```

Analyse statique :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Format :

Premier passage après création du test :

```bash
cd packages/map_core && dart format --set-exit-if-changed test/narrative_authoring_golden_path_test.dart
```

Sortie :

```text
Formatted test/narrative_authoring_golden_path_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Vérification finale :

```bash
cd packages/map_core && dart format --set-exit-if-changed test/narrative_authoring_golden_path_test.dart
```

Sortie finale :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

## 11. Modifications effectuées

Fichiers créés :

- `packages/map_core/test/narrative_authoring_golden_path_test.dart`
- `reports/roadmap/phase_4/p4_07_minimal_authoring_golden_path_test.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_4.md`

Fichiers non modifiés explicitement contrôlés :

- `MVP Selbrume/road_map_global.md`
- `packages/map_core/lib/src/**`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/**`
- `packages/map_runtime/**`
- `examples/playable_runtime_host/**`

## 12. Evidence Pack

### Git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
<sortie vide>
```

### Commandes exécutées

```bash
git status --short --untracked-files=all

sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,940p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_06_narrative_validator_authoring_adapter.md

sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
sed -n '1,620p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart

rg -n "buildNarrativeAuthoringDiagnosticViews|buildNarrativeAuthoringDiagnosticView|NarrativeAuthoringDiagnosticView|NarrativeScenarioAuthoringDraft|NarrativeEventSourcePickerOption|NarrativeOutcomePickerOption|NarrativePredicateReferencePickerOption|compileNarrativeScenarioAuthoringDraftToScenarioAsset|ProjectManifest|MapData|MapEntity|MapTrigger" packages/map_core --glob '!build/**' --glob '!**/.dart_tool/**'

find packages/map_core/test -type f | sort | rg "narrative|authoring|validator|predicate|outcome|event|scenario|picker|golden"

sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,360p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,360p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,620p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,260p' packages/map_core/test/narrative_validator_authoring_adapter_test.dart
sed -n '1,620p' packages/map_core/test/narrative_reference_picker_read_models_test.dart

cd packages/map_core && dart test test/narrative_authoring_golden_path_test.dart
cd packages/map_core && dart test test/narrative_validator_authoring_adapter_test.dart
cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed test/narrative_authoring_golden_path_test.dart

git diff -- "MVP Selbrume/road_map_phase_4.md"
git diff -- packages/map_core/test/narrative_authoring_golden_path_test.dart
git status --short --untracked-files=all
git diff --name-only -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages/map_core/lib/src packages/map_core/lib/map_core.dart packages/map_editor packages/map_runtime examples/playable_runtime_host

git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### Sorties utiles des lectures

`road_map_global.md` indique encore P4-00 comme lot courant/prochain lot. Cette
roadmap globale n'a pas été modifiée par P4-07, conformément au contrat. Ce
décalage est reporté au checkpoint.

`road_map_phase_4.md` indiquait P4-07 comme prochain lot avant modification et
indique maintenant :

```text
P4-07 : ✅ terminé
P4-CHECKPOINT-01 : 🔜 prochain lot exact
```

`rg` a confirmé la présence des APIs authoring P4-01 à P4-06 :

- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`

`find packages/map_core/test ...` a confirmé les tests de régression
pertinents :

```text
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
packages/map_core/test/narrative_outcome_authoring_operations_test.dart
packages/map_core/test/narrative_predicate_authoring_draft_test.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/test/narrative_scenario_authoring_draft_test.dart
packages/map_core/test/narrative_validator_authoring_adapter_test.dart
packages/map_core/test/narrative_validator_test.dart
```

### Contenu complet du nouveau test

Chemin :

```text
packages/map_core/test/narrative_authoring_golden_path_test.dart
```

Contenu :

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _projectName = 'P4 Authoring Golden Path';
const _mapId = 'p4_authoring_map';
const _entityId = 'p4_authoring_npc';
const _triggerId = 'p4_authoring_trigger';
const _scenarioId = 'p4_authoring_scene';
const _receiverScenarioId = 'p4_authoring_outcome_receiver';
const _referenceScenarioId = 'p4_authoring_reference_scene';
const _storyScenarioId = 'p4_authoring_story';
const _outcomeId = 'p4.outcome.done';
const _flagName = 'p4.flag.visible';
const _stepId = 'p4.step.completed';
const _cutsceneId = 'p4_authoring_cutscene';
const _battleId = 'p4_battle';
const _trainerId = 'p4_trainer';
const _dialogueId = 'p4.dialogue.visible';

void main() {
  group('P4-07 minimal authoring golden path', () {
    test(
        'chains read models, drafts, operations, predicates, validation, and '
        'authoring diagnostics', () {
      final referenceMap = _map();
      final referenceManifest = _manifest(
        scenarios: [
          _referenceScenario(),
          _referenceOutcomeReceiverScenario(),
          _referenceStoryScenario(),
        ],
      );

      final scenarioOptions =
          buildNarrativeScenarioPickerOptions(referenceManifest);
      final eventSourceOptions = buildNarrativeEventSourcePickerOptions(
        referenceManifest,
        maps: [referenceMap],
      );
      final outcomeOptions =
          buildNarrativeOutcomePickerOptions(referenceManifest);
      final battleOptions =
          buildNarrativeBattleReferencePickerOptions(referenceManifest);
      final predicateOptions =
          buildNarrativePredicateReferencePickerOptions(referenceManifest);

      expect(scenarioOptions.map((option) => option.scenarioId),
          contains(_referenceScenarioId));
      final eventOption = _eventSourceOption(
        eventSourceOptions,
        NarrativeEventSourceKind.entityInteract,
      );
      expect(eventOption.sourceId, 'entityInteract:$_mapId:$_entityId');
      final outcomeOption = _outcomeOption(outcomeOptions, _outcomeId);
      expect(outcomeOption.isDeclared, isTrue);
      expect(outcomeOption.isEmitted, isTrue);
      expect(outcomeOption.isConsumed, isTrue);
      final battleOption = _battleOption(battleOptions, _battleId);
      expect(battleOption.trainerId, _trainerId);
      expect(battleOption.npcEntityId, _entityId);

      final sourceDraft =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        eventOption,
      );
      expect(sourceDraft.kind,
          NarrativeScenarioAuthoringSourceKind.entityInteract);
      expect(sourceDraft.mapId, _mapId);
      expect(sourceDraft.entityId, _entityId);
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(sourceDraft),
        eventOption.sourceId,
      );
      expect(
        findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
          sourceDraft,
          eventSourceOptions,
        ),
        eventOption,
      );
      expect(
        validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
          sourceDraft,
          eventSourceOptions,
        ),
        isEmpty,
      );

      var draft = NarrativeScenarioAuthoringDraft(
        scenarioId: _scenarioId,
        name: 'P4 Authoring Scene',
        description: 'Generic minimal authoring flow',
        scope: ScenarioScope.localEventFlow,
        source: sourceDraft,
        actions: const [
          NarrativeScenarioAuthoringActionDraft.setFlag(
            flagName: _flagName,
          ),
          NarrativeScenarioAuthoringActionDraft.completeStep(
            stepId: _stepId,
          ),
        ],
        declaredOutcomes: const [],
      );
      draft = addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
        draft,
        _outcomeId,
      );
      draft = addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
        draft,
        _outcomeId,
      );
      draft = addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        draft,
        battleOption,
        npcEntityId: _entityId,
      );

      expect(validateNarrativeScenarioAuthoringDraft(draft), isEmpty);
      expect(
        validateNarrativeOutcomeAuthoringDraft(
          draft,
          battleOptions: battleOptions,
        ),
        isEmpty,
      );
      expect(
        narrativeScenarioOutcomeFlagReference(_outcomeId),
        'scenario.outcome.$_outcomeId',
      );
      expect(
        narrativeBattleOutcomeFlagReference(
          _battleId,
          NarrativeBattleOutcomeKind.victory,
        ),
        'battle:$_battleId:victory',
      );

      final receiverSourceDraft =
          createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
        outcomeOption,
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(receiverSourceDraft),
        'outcomeReceived:$_outcomeId',
      );
      expect(
        validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
          receiverSourceDraft,
          eventSourceOptions,
        ),
        isEmpty,
      );

      final flagPredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.storyFlag,
          _flagName,
        ),
      );
      final stepPredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.storyStep,
          _stepId,
        ),
      );
      final scenarioOutcomePredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.scenarioOutcome,
          narrativeScenarioOutcomeFlagReference(_outcomeId),
        ),
      );
      final battleOutcomePredicate =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          predicateOptions,
          NarrativePredicateReferenceKind.battleOutcome,
          narrativeBattleOutcomeFlagReference(
            _battleId,
            NarrativeBattleOutcomeKind.victory,
          ),
        ),
      );

      final runtimeScenarioOutcomePredicate =
          compileNarrativePredicateAuthoringDraftToRuntimePredicate(
        scenarioOutcomePredicate,
      );
      final runtimeBattleOutcomePredicate =
          compileNarrativePredicateAuthoringDraftToRuntimePredicate(
        battleOutcomePredicate,
      );
      expect(
        runtimeScenarioOutcomePredicate.kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(
        runtimeScenarioOutcomePredicate.refId,
        'scenario.outcome.$_outcomeId',
      );
      expect(
        runtimeBattleOutcomePredicate.kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(runtimeBattleOutcomePredicate.refId, 'battle:$_battleId:victory');

      final visibilityRule =
          compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
        NarrativeVisibilityRuleAuthoringDraft.visibleWhen(
          predicate: flagPredicate,
        ),
      );
      final conditionalDialogue =
          compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
        NarrativeConditionalDialogueAuthoringDraft(
          dialogueId: _dialogueId,
          predicate: stepPredicate,
        ),
      );
      expect(visibilityRule.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(visibilityRule.predicate?.refId, _flagName);
      expect(conditionalDialogue.when.kind,
          MapEntityRuntimePredicateKind.stepCompleted);
      expect(conditionalDialogue.when.refId, _stepId);
      expect(conditionalDialogue.dialogue.dialogueId, _dialogueId);

      final scenarioAsset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);
      final receiverAsset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        NarrativeScenarioAuthoringDraft(
          scenarioId: _receiverScenarioId,
          name: 'P4 Authoring Outcome Receiver',
          source: receiverSourceDraft,
          actions: const [],
          declaredOutcomes: const [],
        ),
      );

      expect(scenarioAsset.id, _scenarioId);
      expect(scenarioAsset.name, 'P4 Authoring Scene');
      expect(scenarioAsset.scope, ScenarioScope.localEventFlow);
      expect(scenarioAsset.entryNodeId, '${_scenarioId}__start');
      expect(scenarioAsset.declaredOutcomes, [_outcomeId]);
      expect(
        scenarioAsset.nodes
            .where((node) => node.type == ScenarioNodeType.start),
        hasLength(1),
      );
      expect(
        scenarioAsset.nodes.where((node) => node.type == ScenarioNodeType.end),
        hasLength(1),
      );
      expect(_node(scenarioAsset, '${_scenarioId}__source').payload.actionKind,
          'sourceEntityInteract');
      expect(
          _node(scenarioAsset, '${_scenarioId}__source').binding.mapId, _mapId);
      expect(_node(scenarioAsset, '${_scenarioId}__source').binding.entityId,
          _entityId);
      expect(_node(scenarioAsset, '${_scenarioId}__action_0').binding.flagName,
          _flagName);
      expect(
        _node(scenarioAsset, '${_scenarioId}__action_1')
            .payload
            .params['stepId'],
        _stepId,
      );
      expect(_node(scenarioAsset, '${_scenarioId}__action_2').binding.outcomeId,
          _outcomeId);
      expect(_node(scenarioAsset, '${_scenarioId}__action_3').binding.trainerId,
          _trainerId);
      expect(_node(scenarioAsset, '${_scenarioId}__action_3').binding.entityId,
          _entityId);
      expect(
        _node(scenarioAsset, '${_scenarioId}__action_3')
            .payload
            .params['battleId'],
        _battleId,
      );
      expect(scenarioAsset.edges.map((edge) => edge.id), [
        '${_scenarioId}__edge_start_to_source',
        '${_scenarioId}__edge_source_to_action_0',
        '${_scenarioId}__edge_action_0_to_action_1',
        '${_scenarioId}__edge_action_1_to_action_2',
        '${_scenarioId}__edge_action_2_to_action_3',
        '${_scenarioId}__edge_action_3_to_end',
      ]);
      expect(
        _node(receiverAsset, '${_receiverScenarioId}__source')
            .payload
            .actionKind,
        'sourceOutcome',
      );

      final authoredMap = _map(
        visibilityRule: visibilityRule,
        conditionalDialogues: [conditionalDialogue],
      );
      final validationReport = diagnoseNarrativeProject(
        _manifest(scenarios: [scenarioAsset, receiverAsset]),
        maps: [authoredMap],
      );

      expect(validationReport.hasErrors, isFalse);
      expect(
        validationReport
            .byKind(NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared),
        isEmpty,
      );
      expect(
        validationReport.byKind(
          NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted,
        ),
        isEmpty,
      );
      expect(
        validationReport.byKind(
          NarrativeValidationDiagnosticKind
              .sourceEntityInteractReferencesUnknownMap,
        ),
        isEmpty,
      );
      expect(
        validationReport.byKind(
          NarrativeValidationDiagnosticKind
              .sourceEntityInteractReferencesUnknownEntity,
        ),
        isEmpty,
      );
      final validationViews = buildNarrativeAuthoringDiagnosticViews(
        validationReport.diagnostics,
      );
      expect(validationViews, hasLength(validationReport.diagnostics.length));
      expect(validationViews.every((view) => !view.hasAutomaticFix), isTrue);
      expect(
        validationViews.map((view) => view.severity),
        validationReport.diagnostics.map((diagnostic) => diagnostic.severity),
      );

      final serializedEvidence = [
        scenarioOptions.map((option) => option.humanLabel).join('|'),
        eventSourceOptions
            .map((option) => option.debugTechnicalLabel)
            .join('|'),
        outcomeOptions.map((option) => option.debugTechnicalLabel).join('|'),
        battleOptions.map((option) => option.debugTechnicalLabel).join('|'),
        predicateOptions.map((option) => option.debugTechnicalLabel).join('|'),
        scenarioAsset.toJson().toString(),
        receiverAsset.toJson().toString(),
        authoredMap.toJson().toString(),
        validationViews.map((view) => view.debugTechnicalLabel).join('|'),
      ].join('\n').toLowerCase();
      expect(serializedEvidence, isNot(contains('selbrume')));
      expect(serializedEvidence, isNot(contains('lysa')));
      expect(serializedEvidence, isNot(contains('mael')));
      expect(serializedEvidence, isNot(contains('maël')));
      expect(serializedEvidence, isNot(contains('mado')));
      expect(serializedEvidence, isNot(contains('registry')));
      expect(serializedEvidence, isNot(contains('reward')));
      expect(serializedEvidence, isNot(contains('money')));
      expect(serializedEvidence, isNot(contains('level-up')));
    });

    test('adapts validator diagnostics into authoring views without auto-fix',
        () {
      final invalidMap = _map(
        visibilityRule: const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
        ),
      );
      final report = diagnoseNarrativeProject(
        _manifest(scenarios: const []),
        maps: [invalidMap],
      );

      final diagnostic = report
          .byKind(
            NarrativeValidationDiagnosticKind
                .visibilityRuleConditionalMissingPredicate,
          )
          .single;
      final views = buildNarrativeAuthoringDiagnosticViews(report.diagnostics);
      final view = views.singleWhere(
        (candidate) => candidate.technicalKind == diagnostic.kind,
      );

      expect(view.category,
          NarrativeAuthoringDiagnosticCategory.predicateAuthoring);
      expect(
          view.actionKind, NarrativeAuthoringDiagnosticActionKind.fixPredicate);
      expect(view.severity, diagnostic.severity);
      expect(view.path, diagnostic.path);
      expect(view.mapId, _mapId);
      expect(view.entityId, _entityId);
      expect(view.hasAutomaticFix, isFalse);
      expect(
        () => views.add(view),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

ProjectManifest _manifest({
  required List<ScenarioAsset> scenarios,
}) {
  return ProjectManifest(
    name: _projectName,
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'P4 Authoring Field',
        relativePath: 'maps/p4_authoring_field.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: _dialogueId,
        name: 'P4 Visible Dialogue',
        relativePath: 'dialogues/p4_visible.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'P4 Trainer',
        trainerClass: 'Authoring Tester',
      ),
    ],
    scenarios: scenarios,
  );
}

MapData _map({
  MapEntityNpcVisibilityRule? visibilityRule,
  List<MapEntityConditionalDialogue> conditionalDialogues = const [],
}) {
  return MapData(
    id: _mapId,
    name: 'P4 Authoring Field',
    size: const GridSize(width: 8, height: 8),
    entities: [
      MapEntity(
        id: _entityId,
        name: 'P4 Authoring NPC',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          displayName: 'P4 Authoring Guide',
          dialogue: const DialogueRef(dialogueId: _dialogueId),
          trainerId: _trainerId,
          visibilityRule: visibilityRule,
          conditionalDialogues: conditionalDialogues,
        ),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: _triggerId,
        name: 'P4 Authoring Trigger',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
        ),
      ),
    ],
  );
}

ScenarioAsset _referenceScenario() {
  return ScenarioAsset(
    id: _referenceScenarioId,
    name: 'P4 Authoring Reference Scene',
    entryNodeId: 'source',
    declaredOutcomes: const [_outcomeId],
    nodes: const [
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(mapId: _mapId, entityId: _entityId),
        payload: ScenarioNodePayload(actionKind: 'sourceEntityInteract'),
      ),
      ScenarioNode(
        id: 'set_flag',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(flagName: _flagName),
        payload: ScenarioNodePayload(actionKind: 'setFlag'),
      ),
      ScenarioNode(
        id: 'complete_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: 'completeStep',
          params: {'stepId': _stepId},
        ),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(outcomeId: _outcomeId),
        payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
      ),
      ScenarioNode(
        id: 'battle',
        type: ScenarioNodeType.action,
        binding: ScenarioNodeBinding(
          trainerId: _trainerId,
          entityId: _entityId,
        ),
        payload: ScenarioNodePayload(
          actionKind: 'startTrainerBattle',
          params: {'battleId': _battleId},
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const [
      ScenarioEdge(
          id: 'source_to_flag', fromNodeId: 'source', toNodeId: 'set_flag'),
      ScenarioEdge(
        id: 'flag_to_step',
        fromNodeId: 'set_flag',
        toNodeId: 'complete_step',
      ),
      ScenarioEdge(
        id: 'step_to_emit',
        fromNodeId: 'complete_step',
        toNodeId: 'emit',
      ),
      ScenarioEdge(
          id: 'emit_to_battle', fromNodeId: 'emit', toNodeId: 'battle'),
      ScenarioEdge(id: 'battle_to_end', fromNodeId: 'battle', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _referenceOutcomeReceiverScenario() {
  return const ScenarioAsset(
    id: 'p4_authoring_reference_receiver',
    name: 'P4 Authoring Reference Receiver',
    entryNodeId: 'source',
    nodes: [
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(outcomeId: _outcomeId),
        payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(id: 'source_to_end', fromNodeId: 'source', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _referenceStoryScenario() {
  return const ScenarioAsset(
    id: _storyScenarioId,
    name: 'P4 Authoring Story',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: [
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        binding: ScenarioNodeBinding(outcomeId: _outcomeId),
        payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(id: 'source_to_end', fromNodeId: 'source', toNodeId: 'end'),
    ],
    metadata: {
      'authoring.stepStudioDocument': '''
{
  "schemaVersion": "step_studio_v1",
  "globalStoryScenarioId": "$_storyScenarioId",
  "steps": [
    {
      "id": "$_stepId",
      "name": "P4 Step Completed",
      "description": "Generic authoring step",
      "order": 0,
      "activation": {"mode": "whenFlagTrue", "flagName": "$_flagName"},
      "completion": {
        "mode": "whenCutsceneEnds",
        "cutsceneId": "$_cutsceneId"
      },
      "cutscenes": [
        {"cutsceneId": "$_cutsceneId", "role": "main"}
      ],
      "outcomes": [
        {
          "label": "P4 Outcome Done",
          "scope": "progression",
          "outcomeId": "$_outcomeId"
        }
      ]
    }
  ]
}
''',
    },
  );
}

NarrativeEventSourcePickerOption _eventSourceOption(
  List<NarrativeEventSourcePickerOption> options,
  NarrativeEventSourceKind kind,
) {
  return options.singleWhere(
    (option) =>
        option.sourceKind == kind &&
        option.mapId == _mapId &&
        option.entityId == _entityId,
  );
}

NarrativeOutcomePickerOption _outcomeOption(
  List<NarrativeOutcomePickerOption> options,
  String outcomeId,
) {
  return options.singleWhere((option) => option.outcomeId == outcomeId);
}

NarrativeBattleReferencePickerOption _battleOption(
  List<NarrativeBattleReferencePickerOption> options,
  String battleId,
) {
  return options.singleWhere((option) => option.battleId == battleId);
}

NarrativePredicateReferencePickerOption _predicateOption(
  List<NarrativePredicateReferencePickerOption> options,
  NarrativePredicateReferenceKind kind,
  String referenceId,
) {
  return options.singleWhere(
    (option) =>
        option.referenceKind == kind && option.referenceId == referenceId,
  );
}

ScenarioNode _node(ScenarioAsset scenario, String nodeId) {
  return scenario.nodes.singleWhere((node) => node.id == nodeId);
}
```

### Diff complet du fichier modifié `road_map_phase_4.md`

```diff
diff --git a/MVP Selbrume/road_map_phase_4.md b/MVP Selbrume/road_map_phase_4.md
index 6f3b6d54..f31a1e9d 100644
--- a/MVP Selbrume/road_map_phase_4.md	
+++ b/MVP Selbrume/road_map_phase_4.md	
@@ -6,9 +6,9 @@ Phase 4 — Authoring Workflows Minimal
 
 Statut : 🔜 Phase courante en exécution
 
-Lot courant : P4-07 — Minimal Authoring Golden Path Test V0
+Lot courant : P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 
-Prochain lot exact : P4-07 — Minimal Authoring Golden Path Test V0
+Prochain lot exact : P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 
 Suivi des lots :
 
@@ -19,8 +19,8 @@ Suivi des lots :
 - ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0
 - ✅ P4-05 — Predicate / World Rule Authoring Draft V0
 - ✅ P4-06 — Narrative Validator Authoring Adapter V0
-- 🔜 P4-07 — Minimal Authoring Golden Path Test V0
-- P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
+- ✅ P4-07 — Minimal Authoring Golden Path Test V0
+- 🔜 P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 
 P4-00 : ✅ terminé
 
@@ -36,7 +36,9 @@ P4-05 : ✅ terminé
 
 P4-06 : ✅ terminé
 
-P4-07 : 🔜 prochain lot exact
+P4-07 : ✅ terminé
+
+P4-CHECKPOINT-01 : 🔜 prochain lot exact
 
 ## 2. Objectif de la Phase 4
 
@@ -352,8 +354,8 @@ Preuve concrète, pure et testée :
 Objectif :
 Prouver un workflow authoring minimal complet sans UI premium.
 
-Résultat attendu :
-Preuve concrète et testée :
+Résultat :
+Preuve concrète et testée ajoutée :
 
 - sélection de références via read models ;
 - draft scenario minimal ;
@@ -362,6 +364,12 @@ Preuve concrète et testée :
 - predicate/world rule passive ;
 - diagnostics authoring ;
 - export ou conversion vers structures existantes, sans créer Selbrume final.
+- test ciblé :
+  `packages/map_core/test/narrative_authoring_golden_path_test.dart` ;
+- rapport :
+  `reports/roadmap/phase_4/p4_07_minimal_authoring_golden_path_test.md` ;
+- aucun code de production modifié, aucune UI, aucun registry persistant,
+  aucun auto-fix, aucun reward/money/XP et aucun contenu Selbrume final créé.
 
 ### P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 
@@ -408,5 +416,5 @@ Phase 4 doit produire des preuves authoring concrètes après P4-00.
 Le prochain lot exact est :
 
 ```text
-P4-07 — Minimal Authoring Golden Path Test V0
+P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 ```
```

### Contrôles hors scope intermédiaires

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md"
```

Sortie :

```text
<sortie vide>
```

Commande :

```bash
git diff --name-only -- packages/map_core/lib/src packages/map_core/lib/map_core.dart packages/map_editor packages/map_runtime examples/playable_runtime_host
```

Sortie :

```text
<sortie vide>
```

### git diff --check exact

```text
<sortie vide>
```

### git diff --stat exact

```text
 MVP Selbrume/road_map_phase_4.md | 24 ++++++++++++++++--------
 1 file changed, 16 insertions(+), 8 deletions(-)
```

### git diff --name-only exact

```text
MVP Selbrume/road_map_phase_4.md
```

### git status final exact

```text
 M "MVP Selbrume/road_map_phase_4.md"
?? packages/map_core/test/narrative_authoring_golden_path_test.dart
?? reports/roadmap/phase_4/p4_07_minimal_authoring_golden_path_test.md
```

### Contrôles explicites

- `road_map_global.md` non modifié : confirmé par `git diff --name-only`.
- P4-CHECKPOINT-01 non exécuté : aucun rapport checkpoint créé, aucun test ou
  audit checkpoint lancé.
- Selbrume final non créé : aucun fichier ou id Selbrume ajouté.
- Aucune UI premium créée : aucune modification `map_editor`, aucun widget
  Flutter ajouté.
- Aucun auto-fix créé : aucun code de production modifié, test vérifie
  `hasAutomaticFix == false`.
- Aucun registry persistant créé : aucun `EventRegistry`, `FactRegistry`,
  `WorldRuleRegistry`, `OutcomeRegistry` ou `BattleRegistry` ajouté.
- Aucun reward/money/XP ajouté : aucun fichier gameplay/récompense modifié.

## 13. Auto-review critique

Points forts :

- le test prouve un chaînage complet des briques P4-01 à P4-06 ;
- la preuve reste pure Dart, in-memory, sans I/O et sans UI ;
- `scenario.outcome.*` et `battle:*` restent des références techniques lues
  par predicates, pas des registries ;
- le validator et l'adapter sont exercés ensemble ;
- aucune API de production n'a été ajoutée.

Réserves :

- le golden path ne prouve pas une expérience editor interactive ;
- la validation reste au niveau `map_core`, pas runtime ;
- le test utilise des données techniques construites en mémoire, pas un projet
  disque ;
- le checkpoint devra décider si ces preuves sont suffisantes pour clôturer
  Phase 4.

Verdict :

```text
P4-07 : terminé.
Prochain lot exact : P4-CHECKPOINT-01 — Authoring Workflow Readiness Review.
```

## 14. Regard critique sur le prompt

Le prompt est bien calibré pour empêcher une dérive UI ou registry. Sa contrainte
"test principalement" est utile : P4-07 devait prouver l'intégration des briques
existantes, pas ajouter une nouvelle surface authoring.

La seule ambiguïté notable concerne le niveau de diagnostics attendu : un golden
path nominal pourrait chercher zéro diagnostic, mais le prompt demande aussi de
prouver l'adapter. Le lot résout cela avec deux preuves séparées :

- un workflow nominal sans erreurs bloquantes ;
- un cas volontairement invalide pour vérifier la lisibilité authoring d'un
  diagnostic validator.
