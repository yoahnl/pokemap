# P4-06 — Narrative Validator Authoring Adapter V0

## 1. Résumé exécutif

P4-06 est validable.

Le lot ajoute un adapter pur dans `map_core` qui transforme les diagnostics techniques du validator narratif existant en vues authoring lisibles :

- catégorie authoring ;
- titre court ;
- message explicatif ;
- action hint non automatique ;
- action kind ;
- contexte technique conservé.

Le validator existant n'a pas été modifié. L'adapter ne crée aucune UI, aucun auto-fix et aucun registry. Il conserve la sévérité originale `NarrativeValidationSeverity` et les champs techniques utiles (`path`, `referencedId`, `scenarioId`, `nodeId`, `mapId`, `entityId`).

Prochain lot exact confirmé :

```text
P4-07 — Minimal Authoring Golden Path Test V0
```

## 2. Scope du lot

Inclus :

- adapter pur `NarrativeValidationDiagnostic -> NarrativeAuthoringDiagnosticView` ;
- catégories authoring V0 ;
- action hints V0 sans auto-fix ;
- conservation de la sévérité et du contexte technique ;
- couverture explicite des diagnostics P2-09 ;
- tests ciblés et régressions authoring/validator.

Exclus :

- UI, widget Flutter, Validator UI ;
- auto-fix, mutation de manifest/scenario/graph/draft ;
- modification de `narrative_validator.dart` ;
- modification de `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData`, `MapEntity` ;
- registry persistant, `FactRegistry`, `WorldRuleRegistry`, `OutcomeRegistry`, `BattleRegistry` ;
- runtime, playable host, migration ;
- Selbrume final, rewards, money, XP, level-up ;
- P4-07.

## 3. Sources lues

Fichiers principaux lus :

- `AGENTS.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_4.md`
- `reports/roadmap/phase_4/p4_05_predicate_world_rule_authoring_draft.md`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/narrative_validator_test.dart`

Signaux structurants :

- `NarrativeValidationDiagnostic` est la source de vérité technique.
- `NarrativeValidationDiagnosticKind` contient les diagnostics P2-09 attendus.
- `NarrativeValidationDiagnostic` expose déjà `severity`, `message`, `path`, `referencedId`, `scenarioId`, `nodeId`, `mapId`, `entityId`.
- Le bon niveau P4-06 est donc un read/adapter pur, pas un nouveau validator.

## 4. Adapter authoring ajouté

Fichier créé :

```text
packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
```

API publique ajoutée :

- `NarrativeAuthoringDiagnosticView`
- `NarrativeAuthoringDiagnosticCategory`
- `NarrativeAuthoringDiagnosticActionKind`
- `buildNarrativeAuthoringDiagnosticView(...)`
- `buildNarrativeAuthoringDiagnosticViews(...)`

Export ajouté :

```dart
export 'src/authoring/narrative_validator_authoring_adapter.dart';
```

La liste produite par `buildNarrativeAuthoringDiagnosticViews` est immuable.

## 5. Mapping des diagnostics

Diagnostics P2-09 couverts :

| Diagnostic technique | Catégorie | Action kind |
|---|---|---|
| `declaredOutcomeNeverEmitted` | `outcomeAuthoring` | `emitOutcome` |
| `emitOutcomeNotDeclared` | `outcomeAuthoring` | `declareOutcome` |
| `visibilityRuleConditionalMissingPredicate` | `predicateAuthoring` | `fixPredicate` |
| `worldRulePredicateEmptyRefId` | `predicateAuthoring` | `fixPredicate` |
| `scenarioChoiceNodeRuntimeUnsupported` | `runtimeSupport` | `replaceUnsupportedNode` |

Autres diagnostics couverts :

- `scenarioNodeReferencesUnknownNode`
- `scenarioGraphHasUnreachableNode`
- `scenarioGraphHasNoSource`
- `openDialogueReferencesUnknownDialogue`
- `conditionalDialogueReferencesUnknownDialogue`
- `startTrainerBattleMissingTrainerId`
- `startTrainerBattleReferencesUnknownTrainer`
- `startTrainerBattleMissingNpcEntityId`
- `startTrainerBattleBlankBattleId`
- `sourceEntityInteractReferencesUnknownMap`
- `sourceEntityInteractReferencesUnknownEntity`
- `sourceOutcomeWithoutMatchingEmitOutcome`
- `emitOutcomeWithoutMatchingSourceOutcome`

Fallback testé :

- `flagReadNeverProduced` -> `unknown` + `noAutomaticFix`.

## 6. Catégories et action hints

Catégories V0 :

- `scenarioStructure`
- `eventSource`
- `dialogueReference`
- `trainerBattleReference`
- `outcomeAuthoring`
- `predicateAuthoring`
- `runtimeSupport`
- `unknown`

Action kinds V0 :

- `inspectScenario`
- `selectValidReference`
- `declareOutcome`
- `emitOutcome`
- `addOutcomeReceiver`
- `fixPredicate`
- `replaceUnsupportedNode`
- `noAutomaticFix`

Ces actions sont des hints de présentation. Elles ne mutent rien.

## 7. Conservation de la vérité validator

La vue authoring conserve :

- `technicalKind`
- `severity`
- `technicalMessage`
- `path`
- `referencedId`
- `scenarioId`
- `nodeId`
- `mapId`
- `entityId`
- `debugTechnicalLabel`

La sévérité n'est ni recalculée ni abaissée. Une erreur reste une erreur, un warning reste un warning.

## 8. Absence d’auto-fix

P4-06 n'ajoute aucune fonction d'auto-fix.

La vue expose :

```dart
bool get hasAutomaticFix => false;
```

Les tests vérifient que toutes les vues produites ont `hasAutomaticFix == false`.

## 9. Lien avec P4-01 / P4-02 / P4-03 / P4-04 / P4-05

P4-01 :

- fournit les read models / références sélectionnables.
- P4-06 indique quand sélectionner une référence valide.

P4-02 :

- fournit le scenario draft.
- P4-06 rend lisibles les diagnostics structurels et source manquante.

P4-03 :

- fournit les opérations Event Source.
- P4-06 catégorise les erreurs de source comme `eventSource`.

P4-04 :

- fournit les opérations Outcome/Battle.
- P4-06 rend actionnables `declareOutcome`, `emitOutcome`, `addOutcomeReceiver` et les erreurs battle reference.

P4-05 :

- fournit les drafts Predicate/World Rule.
- P4-06 catégorise les erreurs de predicate comme `predicateAuthoring`.

## 10. Limites et reports vers P4-07 / Phase 7

Reporté à P4-07 :

- chaîner read models, drafts, opérations et diagnostics dans un golden path authoring minimal.

Reporté à Phase 7 :

- présentation UI, tri visuel, grouping par écran, navigation vers panel editor.

Non prouvé ici :

- UI editor ;
- auto-fix ;
- navigation vers un champ précis ;
- correction automatique ;
- génération de contenu.

## 11. Tests exécutés

Test ciblé :

```bash
cd packages/map_core && dart test test/narrative_validator_authoring_adapter_test.dart
```

Résultat : 9 tests, tous passés.

Régressions ciblées :

```bash
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart analyze
```

Résultat : toutes passées, `dart analyze` sans issue.

Format :

```bash
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_validator_authoring_adapter.dart test/narrative_validator_authoring_adapter_test.dart
```

Résultat final : 0 fichier changé.

## 12. Modifications effectuées

Fichiers créés :

- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`
- `packages/map_core/test/narrative_validator_authoring_adapter_test.dart`
- `reports/roadmap/phase_4/p4_06_narrative_validator_authoring_adapter.md`

Fichiers modifiés :

- `packages/map_core/lib/map_core.dart`
- `MVP Selbrume/road_map_phase_4.md`

Aucun fichier `packages/map_core/lib/src/operations/narrative_validator.dart` modifié.

## 13. Evidence Pack

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
sed -n '1,880p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_05_predicate_world_rule_authoring_draft.md

sed -n '1,620p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
sed -n '1,260p' packages/map_core/lib/map_core.dart

rg -n "declaredOutcomeNeverEmitted|emitOutcomeNotDeclared|visibilityRuleConditionalMissingPredicate|worldRulePredicateEmptyRefId|scenarioChoiceNodeRuntimeUnsupported|unknown.*dialogue|unknown.*trainer|sourceOutcome|emitOutcome|choice|diagnostic|Diagnostic|severity|referencedId|path" packages/map_core packages/map_editor --glob '!build/**' --glob '!**/.dart_tool/**'

find packages/map_core/lib/src/authoring -type f | sort
find packages/map_core/test -type f | sort | rg "narrative|validator|authoring|predicate|outcome|picker"

cd packages/map_core && dart test test/narrative_validator_authoring_adapter_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_validator_authoring_adapter.dart test/narrative_validator_authoring_adapter_test.dart

git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### Sorties utiles des lectures

`narrative_validator.dart` expose :

```text
enum NarrativeValidationSeverity {
  error,
  warning,
}

enum NarrativeValidationDiagnosticKind {
  scenarioNodeReferencesUnknownNode,
  scenarioGraphHasUnreachableNode,
  scenarioGraphHasNoSource,
  openDialogueReferencesUnknownDialogue,
  startTrainerBattleMissingTrainerId,
  startTrainerBattleReferencesUnknownTrainer,
  startTrainerBattleMissingNpcEntityId,
  startTrainerBattleBlankBattleId,
  sourceEntityInteractReferencesUnknownMap,
  sourceEntityInteractReferencesUnknownEntity,
  sourceOutcomeWithoutMatchingEmitOutcome,
  emitOutcomeWithoutMatchingSourceOutcome,
  declaredOutcomeNeverEmitted,
  emitOutcomeNotDeclared,
  conditionalDialogueReferencesUnknownDialogue,
  visibilityRuleConditionalMissingPredicate,
  worldRulePredicateEmptyRefId,
  scenarioChoiceNodeRuntimeUnsupported,
  flagReadNeverProduced,
  setFlagNeverRead,
  stepReadNeverCompleted,
  completeStepNeverRead,
}
```

`NarrativeValidationDiagnostic` expose :

```text
severity, kind, message, path, referencedId, scenarioId, nodeId, mapId, entityId
```

`find packages/map_core/lib/src/authoring -type f | sort`

```text
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
```

`find packages/map_core/test -type f | sort | rg "..."`

```text
packages/map_core/test/environment_authoring_diagnostics_test.dart
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
packages/map_core/test/narrative_outcome_authoring_operations_test.dart
packages/map_core/test/narrative_predicate_authoring_draft_test.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/test/narrative_scenario_authoring_draft_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
packages/map_core/test/tall_grass_authoring_view_test.dart
```

La commande `rg` obligatoire a produit une sortie très longue. Signaux utiles observés :

- `packages/map_core/lib/src/operations/narrative_validator.dart` contient tous les diagnostics ciblés ;
- `packages/map_core/test/narrative_validator_test.dart` couvre déjà les diagnostics techniques ;
- les autres résultats sont principalement des occurrences de diagnostics génériques, chemins et fichiers generated/editor sans besoin de modification pour P4-06.

### TDD rouge initial

Commande :

```bash
cd packages/map_core && dart test test/narrative_validator_authoring_adapter_test.dart
```

Sortie utile :

```text
Failed to load "test/narrative_validator_authoring_adapter_test.dart":
Error: Method not found: 'buildNarrativeAuthoringDiagnosticView'.
Error: Undefined name 'NarrativeAuthoringDiagnosticCategory'.
Error: Undefined name 'NarrativeAuthoringDiagnosticActionKind'.
Error: Method not found: 'buildNarrativeAuthoringDiagnosticViews'.
Some tests failed.
```

### Contenu complet du fichier créé : `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../operations/narrative_validator.dart';

enum NarrativeAuthoringDiagnosticCategory {
  scenarioStructure,
  eventSource,
  dialogueReference,
  trainerBattleReference,
  outcomeAuthoring,
  predicateAuthoring,
  runtimeSupport,
  unknown,
}

enum NarrativeAuthoringDiagnosticActionKind {
  inspectScenario,
  selectValidReference,
  declareOutcome,
  emitOutcome,
  addOutcomeReceiver,
  fixPredicate,
  replaceUnsupportedNode,
  noAutomaticFix,
}

@immutable
final class NarrativeAuthoringDiagnosticView {
  const NarrativeAuthoringDiagnosticView({
    required this.technicalKind,
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    required this.actionHint,
    required this.actionKind,
    required this.path,
    required this.debugTechnicalLabel,
    required this.technicalMessage,
    this.referencedId,
    this.scenarioId,
    this.nodeId,
    this.mapId,
    this.entityId,
  });

  final NarrativeValidationDiagnosticKind technicalKind;
  final NarrativeValidationSeverity severity;
  final NarrativeAuthoringDiagnosticCategory category;
  final String title;
  final String message;
  final String actionHint;
  final NarrativeAuthoringDiagnosticActionKind actionKind;
  final String path;
  final String? referencedId;
  final String? scenarioId;
  final String? nodeId;
  final String? mapId;
  final String? entityId;
  final String debugTechnicalLabel;
  final String technicalMessage;

  bool get hasAutomaticFix => false;
}

List<NarrativeAuthoringDiagnosticView> buildNarrativeAuthoringDiagnosticViews(
  Iterable<NarrativeValidationDiagnostic> diagnostics,
) {
  return List<NarrativeAuthoringDiagnosticView>.unmodifiable(
    diagnostics.map(buildNarrativeAuthoringDiagnosticView),
  );
}

NarrativeAuthoringDiagnosticView buildNarrativeAuthoringDiagnosticView(
  NarrativeValidationDiagnostic diagnostic,
) {
  final template = _templateForDiagnosticKind(diagnostic.kind);
  return NarrativeAuthoringDiagnosticView(
    technicalKind: diagnostic.kind,
    severity: diagnostic.severity,
    category: template.category,
    title: template.title,
    message: template.message,
    actionHint: template.actionHint,
    actionKind: template.actionKind,
    path: diagnostic.path,
    referencedId: diagnostic.referencedId,
    scenarioId: diagnostic.scenarioId,
    nodeId: diagnostic.nodeId,
    mapId: diagnostic.mapId,
    entityId: diagnostic.entityId,
    technicalMessage: diagnostic.message,
    debugTechnicalLabel: _debugTechnicalLabel(diagnostic),
  );
}

_NarrativeAuthoringDiagnosticTemplate _templateForDiagnosticKind(
  NarrativeValidationDiagnosticKind kind,
) {
  return switch (kind) {
    NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome declared but never emitted',
        message: 'This scenario declares an outcome, but no action emits it. '
            'It cannot continue a narrative branch until it is emitted.',
        actionHint: 'Add an emitOutcome action, or remove the declaration if '
            'the outcome is not needed.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.emitOutcome,
      ),
    NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome emitted without declaration',
        message: 'An action emits an outcome that is emitted but is not '
            'declared by this scenario.',
        actionHint: 'Declare this outcome on the scenario, or choose an '
            'existing declared outcome.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.declareOutcome,
      ),
    NarrativeValidationDiagnosticKind
          .visibilityRuleConditionalMissingPredicate =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.predicateAuthoring,
        title: 'Visibility rule has no condition',
        message: 'A conditional visibility rule exists, but no predicate is '
            'defined for it.',
        actionHint: 'Choose a predicate for the visibility rule, or make the '
            'entity always visible.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.fixPredicate,
      ),
    NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.predicateAuthoring,
        title: 'Predicate reference is incomplete',
        message:
            'A world rule predicate exists, but its reference id is empty.',
        actionHint: 'Select a valid predicate reference from the predicate '
            'picker.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.fixPredicate,
      ),
    NarrativeValidationDiagnosticKind.scenarioChoiceNodeRuntimeUnsupported =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.runtimeSupport,
        title: 'Choice node is not runtime-supported yet',
        message: 'This choice node is present in the scenario graph, but the '
            'current runtime does not support it yet.',
        actionHint: 'Replace it with a linear V0 flow, or postpone this '
            'branching behavior.',
        actionKind:
            NarrativeAuthoringDiagnosticActionKind.replaceUnsupportedNode,
      ),
    NarrativeValidationDiagnosticKind.scenarioNodeReferencesUnknownNode =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.scenarioStructure,
        title: 'Scenario edge points to a missing node',
        message: 'A scenario edge references a node that does not exist.',
        actionHint: 'Inspect the scenario graph and reconnect the edge to an '
            'existing node.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.inspectScenario,
      ),
    NarrativeValidationDiagnosticKind.scenarioGraphHasUnreachableNode =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.scenarioStructure,
        title: 'Scenario contains an unreachable node',
        message: 'A node exists in the scenario graph but cannot be reached '
            'from the runtime source.',
        actionHint: 'Connect the node to the flow, or remove it if it is not '
            'part of the scenario.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.inspectScenario,
      ),
    NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.eventSource,
        title: 'Scenario has no runtime source',
        message: 'This scenario has no mapEnter, triggerEnter, entityInteract, '
            'or outcomeReceived source node.',
        actionHint: 'Choose a runtime source for this scenario before it can '
            'run.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue ||
    NarrativeValidationDiagnosticKind
          .conditionalDialogueReferencesUnknownDialogue =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.dialogueReference,
        title: 'Dialogue reference is invalid',
        message: 'A scenario or conditional dialogue references a dialogue '
            'that is not available in the project.',
        actionHint: 'Select an existing dialogue reference, or create the '
            'missing dialogue before using it.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind.startTrainerBattleMissingTrainerId ||
    NarrativeValidationDiagnosticKind
        .startTrainerBattleReferencesUnknownTrainer ||
    NarrativeValidationDiagnosticKind.startTrainerBattleMissingNpcEntityId ||
    NarrativeValidationDiagnosticKind.startTrainerBattleBlankBattleId =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.trainerBattleReference,
        title: 'Trainer battle reference is invalid',
        message: 'A startTrainerBattle action is missing a required trainer, '
            'NPC, or battle reference.',
        actionHint: 'Select a valid trainer battle reference and ensure the '
            'NPC entity and battle id are filled.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind
        .sourceEntityInteractReferencesUnknownMap ||
    NarrativeValidationDiagnosticKind
          .sourceEntityInteractReferencesUnknownEntity =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.eventSource,
        title: 'Event source reference is invalid',
        message: 'An entityInteract source references a map or entity that is '
            'not available.',
        actionHint: 'Select a valid map and entity from the event source '
            'picker.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind.sourceOutcomeWithoutMatchingEmitOutcome =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome receiver has no emitter',
        message: 'An outcomeReceived source exists, but no scenario emits the '
            'same outcome.',
        actionHint: 'Add an emitOutcome action for this outcome, or choose an '
            'outcome that is already emitted.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.emitOutcome,
      ),
    NarrativeValidationDiagnosticKind.emitOutcomeWithoutMatchingSourceOutcome =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome has no receiver',
        message: 'A scenario emits an outcome, but no outcomeReceived source '
            'uses it yet.',
        actionHint: 'Add an outcomeReceived source if this outcome should '
            'continue another flow.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.addOutcomeReceiver,
      ),
    NarrativeValidationDiagnosticKind.flagReadNeverProduced ||
    NarrativeValidationDiagnosticKind.setFlagNeverRead ||
    NarrativeValidationDiagnosticKind.stepReadNeverCompleted ||
    NarrativeValidationDiagnosticKind.completeStepNeverRead =>
      _unknownTemplate,
  };
}

String _debugTechnicalLabel(NarrativeValidationDiagnostic diagnostic) {
  final context = <String>[
    diagnostic.kind.name,
    diagnostic.severity.name,
    diagnostic.path,
    if (diagnostic.referencedId != null) 'ref=${diagnostic.referencedId}',
    if (diagnostic.scenarioId != null) 'scenario=${diagnostic.scenarioId}',
    if (diagnostic.nodeId != null) 'node=${diagnostic.nodeId}',
    if (diagnostic.mapId != null) 'map=${diagnostic.mapId}',
    if (diagnostic.entityId != null) 'entity=${diagnostic.entityId}',
  ];
  return context.join(' | ');
}

const _unknownTemplate = _NarrativeAuthoringDiagnosticTemplate(
  category: NarrativeAuthoringDiagnosticCategory.unknown,
  title: 'Narrative diagnostic',
  message: 'The validator reported a narrative diagnostic that does not have a '
      'specific authoring message yet.',
  actionHint:
      'Inspect this diagnostic manually. No automatic fix is available.',
  actionKind: NarrativeAuthoringDiagnosticActionKind.noAutomaticFix,
);

@immutable
final class _NarrativeAuthoringDiagnosticTemplate {
  const _NarrativeAuthoringDiagnosticTemplate({
    required this.category,
    required this.title,
    required this.message,
    required this.actionHint,
    required this.actionKind,
  });

  final NarrativeAuthoringDiagnosticCategory category;
  final String title;
  final String message;
  final String actionHint;
  final NarrativeAuthoringDiagnosticActionKind actionKind;
}
```

### Contenu complet du fichier créé : `packages/map_core/test/narrative_validator_authoring_adapter_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative validator authoring adapter', () {
    test('maps declaredOutcomeNeverEmitted to outcome authoring view', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted,
          severity: NarrativeValidationSeverity.warning,
          path: 'scenarios.p4_scene.declaredOutcomes.0',
          referencedId: 'p4.outcome.done',
          scenarioId: 'p4_scene',
        ),
      );

      expect(view.technicalKind,
          NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted);
      expect(view.severity, NarrativeValidationSeverity.warning);
      expect(
          view.category, NarrativeAuthoringDiagnosticCategory.outcomeAuthoring);
      expect(
          view.actionKind, NarrativeAuthoringDiagnosticActionKind.emitOutcome);
      expect(view.title, 'Outcome declared but never emitted');
      expect(view.actionHint, contains('emitOutcome'));
    });

    test('maps emitOutcomeNotDeclared to outcome authoring view', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared,
          severity: NarrativeValidationSeverity.warning,
          referencedId: 'p4.outcome.done',
        ),
      );

      expect(
          view.category, NarrativeAuthoringDiagnosticCategory.outcomeAuthoring);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.declareOutcome);
      expect(view.title, 'Outcome emitted without declaration');
      expect(view.message, contains('is emitted but is not declared'));
    });

    test('maps predicate diagnostics to predicate authoring views', () {
      final visibility = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .visibilityRuleConditionalMissingPredicate,
          severity: NarrativeValidationSeverity.error,
          path: 'maps.p4_map.entities.p4_npc.visibilityRule.predicate',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );
      final emptyRef = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId,
          severity: NarrativeValidationSeverity.error,
          path: 'maps.p4_map.entities.p4_npc.visibilityRule.predicate.refId',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );

      expect(visibility.category,
          NarrativeAuthoringDiagnosticCategory.predicateAuthoring);
      expect(visibility.actionKind,
          NarrativeAuthoringDiagnosticActionKind.fixPredicate);
      expect(visibility.title, 'Visibility rule has no condition');
      expect(emptyRef.category,
          NarrativeAuthoringDiagnosticCategory.predicateAuthoring);
      expect(emptyRef.actionKind,
          NarrativeAuthoringDiagnosticActionKind.fixPredicate);
      expect(emptyRef.title, 'Predicate reference is incomplete');
    });

    test('maps unsupported choice node to runtime support view', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .scenarioChoiceNodeRuntimeUnsupported,
          severity: NarrativeValidationSeverity.warning,
          scenarioId: 'p4_scene',
          nodeId: 'p4_choice',
        ),
      );

      expect(
          view.category, NarrativeAuthoringDiagnosticCategory.runtimeSupport);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.replaceUnsupportedNode);
      expect(view.title, 'Choice node is not runtime-supported yet');
    });

    test('preserves severity and technical context fields', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .openDialogueReferencesUnknownDialogue,
          severity: NarrativeValidationSeverity.error,
          path: 'scenarios.p4_scene.nodes.p4_dialogue.binding.dialogueId',
          referencedId: 'p4_missing_dialogue',
          scenarioId: 'p4_scene',
          nodeId: 'p4_dialogue',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );

      expect(view.category,
          NarrativeAuthoringDiagnosticCategory.dialogueReference);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.selectValidReference);
      expect(view.severity, NarrativeValidationSeverity.error);
      expect(
          view.path, 'scenarios.p4_scene.nodes.p4_dialogue.binding.dialogueId');
      expect(view.referencedId, 'p4_missing_dialogue');
      expect(view.scenarioId, 'p4_scene');
      expect(view.nodeId, 'p4_dialogue');
      expect(view.mapId, 'p4_map');
      expect(view.entityId, 'p4_npc');
      expect(
        view.debugTechnicalLabel,
        contains('openDialogueReferencesUnknownDialogue'),
      );
    });

    test('maps trainer battle diagnostics to trainer battle reference view',
        () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .startTrainerBattleReferencesUnknownTrainer,
          severity: NarrativeValidationSeverity.error,
          referencedId: 'p4_missing_trainer',
        ),
      );

      expect(view.category,
          NarrativeAuthoringDiagnosticCategory.trainerBattleReference);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.selectValidReference);
      expect(view.title, 'Trainer battle reference is invalid');
      expect(view.actionHint, contains('trainer'));
    });

    test('maps unmapped diagnostics to unknown without automatic fix', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.flagReadNeverProduced,
          severity: NarrativeValidationSeverity.warning,
          referencedId: 'p4.flag.never.produced',
        ),
      );

      expect(view.category, NarrativeAuthoringDiagnosticCategory.unknown);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.noAutomaticFix);
      expect(view.title, 'Narrative diagnostic');
      expect(view.actionHint, contains('Inspect this diagnostic manually'));
    });

    test('builds stable immutable lists without auto-fix metadata', () {
      final diagnostics = [
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared,
          severity: NarrativeValidationSeverity.warning,
          referencedId: 'p4.outcome.done',
        ),
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource,
          severity: NarrativeValidationSeverity.error,
          scenarioId: 'p4_scene',
        ),
      ];

      final first = buildNarrativeAuthoringDiagnosticViews(diagnostics);
      final second = buildNarrativeAuthoringDiagnosticViews(diagnostics);

      expect(first.map((view) => view.debugTechnicalLabel),
          second.map((view) => view.debugTechnicalLabel));
      expect(
        () => first.add(first.first),
        throwsA(isA<UnsupportedError>()),
      );
      expect(first.every((view) => !view.hasAutomaticFix), isTrue);
    });

    test('does not hardcode Selbrume identifiers', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .scenarioChoiceNodeRuntimeUnsupported,
          severity: NarrativeValidationSeverity.warning,
          scenarioId: 'p4_scene',
          nodeId: 'p4_choice',
        ),
      );

      final serialized = [
        view.title,
        view.message,
        view.actionHint,
        view.debugTechnicalLabel,
      ].join('\n').toLowerCase();

      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativeValidationDiagnostic _diagnostic({
  required NarrativeValidationDiagnosticKind kind,
  required NarrativeValidationSeverity severity,
  String path = 'p4.path',
  String? referencedId,
  String? scenarioId,
  String? nodeId,
  String? mapId,
  String? entityId,
}) {
  return NarrativeValidationDiagnostic(
    severity: severity,
    kind: kind,
    message: 'technical message for ${kind.name}',
    path: path,
    referencedId: referencedId,
    scenarioId: scenarioId,
    nodeId: nodeId,
    mapId: mapId,
    entityId: entityId,
  );
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/MVP Selbrume/road_map_phase_4.md b/MVP Selbrume/road_map_phase_4.md
index 54ad7551..6f3b6d54 100644
--- a/MVP Selbrume/road_map_phase_4.md	
+++ b/MVP Selbrume/road_map_phase_4.md	
@@ -6,9 +6,9 @@ Phase 4 — Authoring Workflows Minimal
 
 Statut : 🔜 Phase courante en exécution
 
-Lot courant : P4-06 — Narrative Validator Authoring Adapter V0
+Lot courant : P4-07 — Minimal Authoring Golden Path Test V0
 
-Prochain lot exact : P4-06 — Narrative Validator Authoring Adapter V0
+Prochain lot exact : P4-07 — Minimal Authoring Golden Path Test V0
 
 Suivi des lots :
 
@@ -18,8 +18,8 @@ Suivi des lots :
 - ✅ P4-03 — Event Source Authoring Draft Operations V0
 - ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0
 - ✅ P4-05 — Predicate / World Rule Authoring Draft V0
-- 🔜 P4-06 — Narrative Validator Authoring Adapter V0
-- P4-07 — Minimal Authoring Golden Path Test V0
+- ✅ P4-06 — Narrative Validator Authoring Adapter V0
+- 🔜 P4-07 — Minimal Authoring Golden Path Test V0
 - P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 
 P4-00 : ✅ terminé
@@ -34,7 +34,9 @@ P4-04 : ✅ terminé
 
 P4-05 : ✅ terminé
 
-P4-06 : 🔜 prochain lot exact
+P4-06 : ✅ terminé
+
+P4-07 : 🔜 prochain lot exact
 
 ## 2. Objectif de la Phase 4
 
@@ -313,7 +315,7 @@ Preuve concrète, pure et testée :
 - aucun widget UI, aucun FactRegistry/WorldRuleRegistry, aucune migration,
   aucun runtime, aucun contenu Selbrume et aucun reward/money/XP créé.
 
-### P4-06 — Narrative Validator Authoring Adapter V0
+### ✅ P4-06 — Narrative Validator Authoring Adapter V0
 
 Objectif :
 Créer un adapter pur qui transforme les diagnostics narratifs existants en
@@ -322,10 +324,28 @@ messages authoring exploitables, sans auto-fix et sans UI premium.
 Résultat attendu :
 Preuve concrète, pure et testée :
 
-- mapping diagnostics P2-09 vers libellés/action hints auteur ;
-- filtrage/sévérité conservant la vérité du validator ;
-- aucune correction automatique ;
-- tests sur diagnostics outcome, predicate, choice runtime unsupported.
+- adapter pur ajouté dans `map_core` :
+  `buildNarrativeAuthoringDiagnosticView`,
+  `buildNarrativeAuthoringDiagnosticViews`,
+  `NarrativeAuthoringDiagnosticView` ;
+- catégories authoring V0 :
+  `scenarioStructure`, `eventSource`, `dialogueReference`,
+  `trainerBattleReference`, `outcomeAuthoring`, `predicateAuthoring`,
+  `runtimeSupport`, `unknown` ;
+- action hints V0 sans auto-fix :
+  `inspectScenario`, `selectValidReference`, `declareOutcome`, `emitOutcome`,
+  `addOutcomeReceiver`, `fixPredicate`, `replaceUnsupportedNode`,
+  `noAutomaticFix` ;
+- diagnostics P2-09 couverts :
+  `declaredOutcomeNeverEmitted`, `emitOutcomeNotDeclared`,
+  `visibilityRuleConditionalMissingPredicate`,
+  `worldRulePredicateEmptyRefId`,
+  `scenarioChoiceNodeRuntimeUnsupported` ;
+- sévérité, path, referencedId et contexte technique conservés ;
+- tests ciblés ajoutés dans
+  `packages/map_core/test/narrative_validator_authoring_adapter_test.dart` ;
+- aucun widget UI, aucun auto-fix, aucun registry persistant, aucune migration,
+  aucun runtime, aucun contenu Selbrume et aucun reward/money/XP créé.
 
 ### P4-07 — Minimal Authoring Golden Path Test V0
 
@@ -388,5 +408,5 @@ Phase 4 doit produire des preuves authoring concrètes après P4-00.
 Le prochain lot exact est :
 
 ```text
-P4-06 — Narrative Validator Authoring Adapter V0
+P4-07 — Minimal Authoring Golden Path Test V0
 ```
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 3647ef12..120f3d4b 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -75,6 +75,7 @@ export 'src/authoring/narrative_event_source_authoring_operations.dart';
 export 'src/authoring/narrative_outcome_authoring_operations.dart';
 export 'src/authoring/narrative_predicate_authoring_draft.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
+export 'src/authoring/narrative_validator_authoring_adapter.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/static_shadow_family_projection.dart';
```

### Sortie complète du test ciblé

Commande :

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

### Sortie complète des régressions ciblées

Commande :

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

Commande :

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

Commande :

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

Commande :

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

### Sortie dart analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

### Sortie dart format

Première exécution :

```text
Formatted lib/src/authoring/narrative_validator_authoring_adapter.dart
Formatted test/narrative_validator_authoring_adapter_test.dart
Formatted 2 files (2 changed) in 0.01 seconds.
```

Exécution finale :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

### Contrôles finaux

Les sorties finales exactes sont renseignées après création de ce rapport.

`git diff --check exact` :

```text
<sortie vide>
```

`git diff --stat exact` :

```text
 MVP Selbrume/road_map_phase_4.md    | 42 +++++++++++++++++++++++++++----------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 32 insertions(+), 11 deletions(-)
```

`git diff --name-only exact` :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

`git status final exact` :

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
?? packages/map_core/test/narrative_validator_authoring_adapter_test.dart
?? reports/roadmap/phase_4/p4_06_narrative_validator_authoring_adapter.md
```

### Contrôles hors scope

- `MVP Selbrume/road_map_global.md` n'a pas été modifié.
- P4-07 n'a pas été exécuté.
- Aucun Selbrume final n'a été créé.
- Aucune UI premium n'a été créée.
- Aucun auto-fix n'a été créé.
- Aucun registry persistant n'a été créé.
- Aucun reward/money/XP n'a été ajouté.
- `packages/map_core/lib/src/operations/narrative_validator.dart` n'a pas été modifié.
- `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData` et les payloads persistants `MapEntity` n'ont pas été modifiés.

## 14. Auto-review critique

Points solides :

- le lot n'est pas audit-only ;
- l'adapter consomme directement les diagnostics existants ;
- les diagnostics P2-09 demandés sont couverts explicitement ;
- la sévérité du validator est conservée ;
- les vues restent immuables et sans auto-fix ;
- les tests ciblés et régressions map_core sont verts.

Limites assumées :

- les messages sont V0 et en anglais technique clair ;
- pas de grouping UI, pas de navigation vers champ editor ;
- certains diagnostics non prioritaires tombent volontairement dans `unknown` pour éviter de surpromettre un workflow authoring non conçu.

## 15. Regard critique sur le prompt

Le prompt est bien borné : il impose un adapter concret tout en interdisant la modification du validator et l'auto-fix. La contrainte utile est de garder la vérité côté `narrative_validator.dart`; P4-06 doit seulement rendre cette vérité présentable pour P4-07 et plus tard pour une UI Phase 7.
