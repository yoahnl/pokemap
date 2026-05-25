# P4-05 — Predicate / World Rule Authoring Draft V0

## 1. Résumé exécutif

P4-05 est validable.

Le lot ajoute une brique authoring pure dans `map_core` pour décrire des predicates, visibility rules et conditional dialogues sous forme de drafts lisibles, puis les compiler vers les modèles runtime existants :

- `MapEntityRuntimePredicate`
- `MapEntityNpcVisibilityRule`
- `MapEntityConditionalDialogue`

La preuve reste volontairement V0 : aucun modèle persistant n'est modifié, aucun registry n'est créé, aucun runtime/editor/UI n'est touché. Les références `scenario.outcome.*` et `battle:*` sont acceptées comme flags techniques lus par les predicates existants, pas comme nouvelles sources de vérité.

Prochain lot exact confirmé :

```text
P4-06 — Narrative Validator Authoring Adapter V0
```

## 2. Scope du lot

Inclus :

- draft predicate authoring ;
- draft visibility rule authoring ;
- draft conditional dialogue authoring ;
- mapping depuis `NarrativePredicateReferencePickerOption` ;
- compilation vers les modèles runtime existants ;
- diagnostics authoring ciblés ;
- tests unitaires ciblés et régressions P4-01 à P4-04.

Exclus :

- UI, widget Flutter, Predicate Builder, World Rule Builder ;
- `FactRegistry`, `WorldRuleRegistry`, registry persistant ;
- modification de `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData`, `MapEntity` ou payloads persistants ;
- runtime, playable host, editor, migration ;
- Selbrume final, rewards, money, XP, level-up ;
- P4-06.

## 3. Sources lues

Fichiers principaux lus :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_4.md`
- `reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md`
- `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/map_core.dart`

Signaux importants :

- `NarrativePredicateReferencePickerOption` expose les références `storyFlag`, `storyStep`, `cutscene`, `scenarioOutcome`, `battleOutcome`.
- `MapEntityRuntimePredicateKind` supporte déjà `storyFlagSet`, `stepCompleted`, `cutsceneCompleted`, `chapterCompleted`.
- `MapEntityNpcVisibilityRule` supporte `always`, `visibleWhen`, `hiddenWhen`.
- `MapEntityConditionalDialogue` associe `when: MapEntityRuntimePredicate` à `dialogue: DialogueRef`.
- Les lots P4-01 à P4-04 ont déjà posé les read models et helpers outcome/battle nécessaires.

## 4. Predicate authoring draft ajouté

Fichier ajouté :

```text
packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
```

API publique ajoutée :

- `NarrativePredicateAuthoringKind`
- `NarrativePredicateAuthoringDraft`
- `createNarrativePredicateAuthoringDraftFromReferenceOption(...)`
- `compileNarrativePredicateAuthoringDraftToRuntimePredicate(...)`
- `validateNarrativePredicateAuthoringDraft(...)`

Mapping authoring :

| Picker kind | Draft kind | Runtime kind |
|---|---|---|
| `storyFlag` | `storyFlagSet` | `storyFlagSet` |
| `storyStep` | `stepCompleted` | `stepCompleted` |
| `cutscene` | `cutsceneCompleted` | `cutsceneCompleted` |
| `scenarioOutcome` | `storyFlagSet` | `storyFlagSet` |
| `battleOutcome` | `storyFlagSet` | `storyFlagSet` |

Décision importante :

`scenario.outcome.*` et `battle:*` ne créent pas de type persistant dédié. Ils restent des `storyFlagSet` techniques parce que c'est le contrat prouvé en P3-05 et P3-06.

## 5. Visibility rule authoring draft ajouté

API publique ajoutée :

- `NarrativeVisibilityRuleAuthoringMode`
- `NarrativeVisibilityRuleAuthoringDraft`
- `compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(...)`
- `validateNarrativeVisibilityRuleAuthoringDraft(...)`

Modes V0 :

- `always`
- `visibleWhen(predicate)`
- `hiddenWhen(predicate)`

Le mapping est direct vers `MapEntityNpcVisibilityMode`.

## 6. Conditional dialogue authoring draft ajouté

API publique ajoutée :

- `NarrativeConditionalDialogueAuthoringDraft`
- `compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(...)`
- `validateNarrativeConditionalDialogueAuthoringDraft(...)`

Le draft contient :

- `dialogueId`
- `predicate`
- `scriptPathRelative`
- `startNode`

La compilation produit un `MapEntityConditionalDialogue` sans modifier le manifest, sans créer de dialogue, et sans ajouter de registry.

## 7. Diagnostics authoring

Diagnostics ajoutés :

- `NarrativePredicateAuthoringDiagnosticSeverity`
- `NarrativePredicateAuthoringDiagnosticKind`
- `NarrativePredicateAuthoringDiagnostic`

Kinds disponibles :

- `emptyReferenceId`
- `emptyDialogueId`
- `missingPredicate`
- `unsupportedPredicateKind`
- `unsupportedVisibilityRuleMode`
- `scenarioOutcomeBattleOutcomeConfusion`

Cas testés :

- `refId` vide ;
- `dialogueId` vide ;
- visibility rule conditionnelle sans predicate ;
- conditional dialogue sans predicate ;
- `battle:*` utilisé comme `stepCompleted` diagnostiqué comme confusion ;
- `scenario.outcome.*` et `battle:*` acceptés comme `storyFlagSet` techniques.

Les kinds `unsupportedPredicateKind` et `unsupportedVisibilityRuleMode` sont présents pour conserver une surface diagnostic claire, mais aucun cas runtime actuel ne les déclenche car les enums authoring V0 sont fermées.

## 8. Séparation facts techniques / registries persistants

P4-05 ne crée pas de `FactRegistry`, `WorldRuleRegistry`, `OutcomeRegistry`, `BattleRegistry` ou `EventRegistry`.

La séparation est la suivante :

- `scenario.outcome.<outcomeId>` : flag technique scénario, lisible par `storyFlagSet`.
- `battle:<battleId>:victory|defeat` : flag technique battle outcome, lisible par `storyFlagSet`.
- `stepCompleted`, `cutsceneCompleted`, `chapterCompleted` restent des predicate kinds existants.

Le test vérifie que `scenario.outcome.*` ne commence pas par `battle:` et que `battle:*` ne commence pas par `scenario.outcome.`.

## 9. Compilation vers modèles runtime existants

Compilation prouvée :

- `NarrativePredicateAuthoringDraft` -> `MapEntityRuntimePredicate`
- `NarrativeVisibilityRuleAuthoringDraft` -> `MapEntityNpcVisibilityRule`
- `NarrativeConditionalDialogueAuthoringDraft` -> `MapEntityConditionalDialogue`

Les conversions trimment les références, ne mutent pas les drafts, et lancent une `StateError` si des diagnostics erreur sont présents.

## 10. Lien avec P4-01 / P4-02 / P4-03 / P4-04

P4-01 :

- fournit `NarrativePredicateReferencePickerOption` et `NarrativePredicateReferenceKind`.
- P4-05 convertit ces options en drafts predicates.

P4-02 :

- fournit le socle des drafts scenario.
- P4-05 reste indépendant du graphe scenario, car les world rules passives se compilent vers les payloads runtime existants.

P4-03 :

- fournit les opérations Event Source.
- P4-05 n'ajoute pas de nouvelle source Event.

P4-04 :

- fournit `narrativeScenarioOutcomeFlagReference(...)` et `narrativeBattleOutcomeFlagReference(...)`.
- P4-05 utilise ces flags comme références techniques lisibles par predicates.

## 11. Limites et reports vers P4-06 / P4-07

Reporté à P4-06 :

- adapter les diagnostics runtime/narrative existants vers des messages authoring plus guidés ;
- relier les diagnostics P4-05 aux diagnostics plus larges du validator sans dupliquer tout `narrative_validator`.

Reporté à P4-07 :

- preuve golden path authoring minimal complet ;
- chaînage read model -> draft scenario -> source -> outcome -> predicate -> validation authoring.

Non prouvé ici :

- UI editor ;
- validation d'existence contre un manifest complet ;
- save/load ;
- runtime Flame ou PlayableMapGame ;
- Step Studio world presence authoring complet.

## 12. Tests exécutés

Test ciblé :

```bash
cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
```

Résultat : 10 tests, tous passés.

Régressions ciblées :

```bash
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
```

Résultat : toutes passées, `dart analyze` sans issue.

Format :

```bash
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_predicate_authoring_draft.dart test/narrative_predicate_authoring_draft_test.dart
```

Résultat final : 0 fichier changé.

## 13. Modifications effectuées

Fichiers créés :

- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`
- `packages/map_core/test/narrative_predicate_authoring_draft_test.dart`
- `reports/roadmap/phase_4/p4_05_predicate_world_rule_authoring_draft.md`

Fichiers modifiés :

- `packages/map_core/lib/map_core.dart`
- `MVP Selbrume/road_map_phase_4.md`

Aucun fichier de production runtime/editor/gameplay/battle/host n'a été modifié.

## 14. Evidence Pack

### Git status initial exact

```text
<sortie vide>
```

Commande :

```bash
git status --short --untracked-files=all
```

### Commandes obligatoires exécutées

```bash
git status --short --untracked-files=all

sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,820p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md

sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
sed -n '1,520p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,420p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,260p' packages/map_core/lib/map_core.dart

rg -n "MapEntityRuntimePredicate|MapEntityNpcVisibilityRule|MapEntityConditionalDialogue|storyFlagSet|stepCompleted|cutsceneCompleted|chapterCompleted|visibilityRule|conditionalDialogues|NarrativePredicateReferencePickerOption|NarrativePredicateReferenceKind|scenario.outcome|battle:" packages/map_core packages/map_editor packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'

find packages/map_core/lib/src/authoring -type f | sort
find packages/map_core/test -type f | sort | rg "narrative|scenario|authoring|event|source|outcome|battle|predicate|world|picker|validator"

cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_predicate_authoring_draft.dart test/narrative_predicate_authoring_draft_test.dart

git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### Sorties utiles des lectures

`find packages/map_core/lib/src/authoring -type f | sort`

```text
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
```

`find packages/map_core/test -type f | sort | rg "..."`

```text
packages/map_core/test/environment_authoring_diagnostics_test.dart
packages/map_core/test/map_events_test.dart
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
packages/map_core/test/narrative_outcome_authoring_operations_test.dart
packages/map_core/test/narrative_predicate_authoring_draft_test.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/test/narrative_scenario_authoring_draft_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/scenario_assets_test.dart
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
packages/map_core/test/tall_grass_authoring_view_test.dart
```

Le fichier `narrative_predicate_authoring_draft_test.dart` était déjà présent comme fichier non suivi au moment de l'audit local du lot. Le test a été utilisé comme test rouge, puis complété par un cas `scenarioOutcomeBattleOutcomeConfusion`.

### TDD rouge initial

Commande :

```bash
cd packages/map_core && dart test test/narrative_predicate_authoring_draft_test.dart
```

Sortie utile :

```text
Failed to load "test/narrative_predicate_authoring_draft_test.dart":
test/narrative_predicate_authoring_draft_test.dart:229:6: Error: Type 'NarrativePredicateAuthoringDiagnosticKind' not found.
test/narrative_predicate_authoring_draft_test.dart:230:8: Error: Type 'NarrativePredicateAuthoringDiagnostic' not found.
...
Error: Method not found: 'createNarrativePredicateAuthoringDraftFromReferenceOption'.
Error: Undefined name 'NarrativePredicateAuthoringKind'.
Error: Method not found: 'compileNarrativePredicateAuthoringDraftToRuntimePredicate'.
Error: Method not found: 'validateNarrativePredicateAuthoringDraft'.
Error: Couldn't find constructor 'NarrativeVisibilityRuleAuthoringDraft.visibleWhen'.
Error: Method not found: 'compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule'.
Error: Couldn't find constructor 'NarrativeConditionalDialogueAuthoringDraft'.
Error: Method not found: 'compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue'.
Some tests failed.
```

### Contenu complet du fichier créé : `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/map_entity_payloads.dart';
import '../read_models/narrative_reference_picker_read_models.dart';

const String _scenarioOutcomePrefix = 'scenario.outcome.';
const String _battleOutcomePrefix = 'battle:';

enum NarrativePredicateAuthoringKind {
  storyFlagSet,
  stepCompleted,
  cutsceneCompleted,
  chapterCompleted,
}

enum NarrativeVisibilityRuleAuthoringMode {
  always,
  visibleWhen,
  hiddenWhen,
}

enum NarrativePredicateAuthoringDiagnosticSeverity {
  error,
  warning,
}

enum NarrativePredicateAuthoringDiagnosticKind {
  emptyReferenceId,
  emptyDialogueId,
  missingPredicate,
  unsupportedPredicateKind,
  unsupportedVisibilityRuleMode,
  scenarioOutcomeBattleOutcomeConfusion,
}

@immutable
final class NarrativePredicateAuthoringDraft {
  const NarrativePredicateAuthoringDraft({
    required this.kind,
    required this.refId,
  });

  final NarrativePredicateAuthoringKind kind;
  final String refId;
}

@immutable
final class NarrativeVisibilityRuleAuthoringDraft {
  const NarrativeVisibilityRuleAuthoringDraft.always()
      : mode = NarrativeVisibilityRuleAuthoringMode.always,
        predicate = null;

  const NarrativeVisibilityRuleAuthoringDraft.visibleWhen({
    this.predicate,
  }) : mode = NarrativeVisibilityRuleAuthoringMode.visibleWhen;

  const NarrativeVisibilityRuleAuthoringDraft.hiddenWhen({
    this.predicate,
  }) : mode = NarrativeVisibilityRuleAuthoringMode.hiddenWhen;

  final NarrativeVisibilityRuleAuthoringMode mode;
  final NarrativePredicateAuthoringDraft? predicate;
}

@immutable
final class NarrativeConditionalDialogueAuthoringDraft {
  const NarrativeConditionalDialogueAuthoringDraft({
    required this.dialogueId,
    this.predicate,
    this.scriptPathRelative = '',
    this.startNode,
  });

  final String dialogueId;
  final NarrativePredicateAuthoringDraft? predicate;
  final String scriptPathRelative;
  final String? startNode;
}

@immutable
final class NarrativePredicateAuthoringDiagnostic {
  const NarrativePredicateAuthoringDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativePredicateAuthoringDiagnosticSeverity severity;
  final NarrativePredicateAuthoringDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

NarrativePredicateAuthoringDraft
    createNarrativePredicateAuthoringDraftFromReferenceOption(
  NarrativePredicateReferencePickerOption option,
) {
  final referenceId = option.referenceId.trim();
  return NarrativePredicateAuthoringDraft(
    kind: switch (option.referenceKind) {
      NarrativePredicateReferenceKind.storyFlag =>
        NarrativePredicateAuthoringKind.storyFlagSet,
      NarrativePredicateReferenceKind.storyStep =>
        NarrativePredicateAuthoringKind.stepCompleted,
      NarrativePredicateReferenceKind.cutscene =>
        NarrativePredicateAuthoringKind.cutsceneCompleted,
      NarrativePredicateReferenceKind.scenarioOutcome =>
        NarrativePredicateAuthoringKind.storyFlagSet,
      NarrativePredicateReferenceKind.battleOutcome =>
        NarrativePredicateAuthoringKind.storyFlagSet,
    },
    refId: referenceId,
  );
}

MapEntityRuntimePredicate
    compileNarrativePredicateAuthoringDraftToRuntimePredicate(
  NarrativePredicateAuthoringDraft draft,
) {
  _throwIfInvalid(validateNarrativePredicateAuthoringDraft(draft));
  return MapEntityRuntimePredicate(
    kind: _runtimePredicateKindForAuthoringKind(draft.kind),
    refId: draft.refId.trim(),
  );
}

MapEntityNpcVisibilityRule
    compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
  NarrativeVisibilityRuleAuthoringDraft draft,
) {
  _throwIfInvalid(validateNarrativeVisibilityRuleAuthoringDraft(draft));
  return switch (draft.mode) {
    NarrativeVisibilityRuleAuthoringMode.always =>
      const MapEntityNpcVisibilityRule(mode: MapEntityNpcVisibilityMode.always),
    NarrativeVisibilityRuleAuthoringMode.visibleWhen =>
      MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.visibleWhen,
        predicate: compileNarrativePredicateAuthoringDraftToRuntimePredicate(
          draft.predicate!,
        ),
      ),
    NarrativeVisibilityRuleAuthoringMode.hiddenWhen =>
      MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: compileNarrativePredicateAuthoringDraftToRuntimePredicate(
          draft.predicate!,
        ),
      ),
  };
}

MapEntityConditionalDialogue
    compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
  NarrativeConditionalDialogueAuthoringDraft draft,
) {
  _throwIfInvalid(validateNarrativeConditionalDialogueAuthoringDraft(draft));
  return MapEntityConditionalDialogue(
    when: compileNarrativePredicateAuthoringDraftToRuntimePredicate(
      draft.predicate!,
    ),
    dialogue: DialogueRef(
      dialogueId: draft.dialogueId.trim(),
      scriptPathRelative: draft.scriptPathRelative.trim(),
      startNode: _trimOptional(draft.startNode),
    ),
  );
}

List<NarrativePredicateAuthoringDiagnostic>
    validateNarrativePredicateAuthoringDraft(
  NarrativePredicateAuthoringDraft draft,
) {
  final diagnostics = <NarrativePredicateAuthoringDiagnostic>[];
  final refId = draft.refId.trim();

  if (refId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind.emptyReferenceId,
      message: 'Predicate reference id is required.',
      path: 'refId',
    );
  } else if (draft.kind != NarrativePredicateAuthoringKind.storyFlagSet &&
      _isTechnicalFlagReference(refId)) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind
          .scenarioOutcomeBattleOutcomeConfusion,
      message:
          'Scenario outcome and battle outcome references must stay technical '
          'story flag predicates.',
      path: 'refId',
      referencedId: refId,
    );
  }

  return List<NarrativePredicateAuthoringDiagnostic>.unmodifiable(diagnostics);
}

List<NarrativePredicateAuthoringDiagnostic>
    validateNarrativeVisibilityRuleAuthoringDraft(
  NarrativeVisibilityRuleAuthoringDraft draft,
) {
  final diagnostics = <NarrativePredicateAuthoringDiagnostic>[];
  switch (draft.mode) {
    case NarrativeVisibilityRuleAuthoringMode.always:
      break;
    case NarrativeVisibilityRuleAuthoringMode.visibleWhen:
    case NarrativeVisibilityRuleAuthoringMode.hiddenWhen:
      final predicate = draft.predicate;
      if (predicate == null) {
        _addDiagnostic(
          diagnostics,
          kind: NarrativePredicateAuthoringDiagnosticKind.missingPredicate,
          message: 'Conditional visibility requires a predicate.',
          path: 'predicate',
        );
      } else {
        diagnostics.addAll(validateNarrativePredicateAuthoringDraft(predicate));
      }
  }

  return List<NarrativePredicateAuthoringDiagnostic>.unmodifiable(diagnostics);
}

List<NarrativePredicateAuthoringDiagnostic>
    validateNarrativeConditionalDialogueAuthoringDraft(
  NarrativeConditionalDialogueAuthoringDraft draft,
) {
  final diagnostics = <NarrativePredicateAuthoringDiagnostic>[];
  if (draft.dialogueId.trim().isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind.emptyDialogueId,
      message: 'Conditional dialogue id is required.',
      path: 'dialogueId',
    );
  }

  final predicate = draft.predicate;
  if (predicate == null) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind.missingPredicate,
      message: 'Conditional dialogue requires a predicate.',
      path: 'predicate',
    );
  } else {
    diagnostics.addAll(validateNarrativePredicateAuthoringDraft(predicate));
  }

  return List<NarrativePredicateAuthoringDiagnostic>.unmodifiable(diagnostics);
}

MapEntityRuntimePredicateKind _runtimePredicateKindForAuthoringKind(
  NarrativePredicateAuthoringKind kind,
) {
  return switch (kind) {
    NarrativePredicateAuthoringKind.storyFlagSet =>
      MapEntityRuntimePredicateKind.storyFlagSet,
    NarrativePredicateAuthoringKind.stepCompleted =>
      MapEntityRuntimePredicateKind.stepCompleted,
    NarrativePredicateAuthoringKind.cutsceneCompleted =>
      MapEntityRuntimePredicateKind.cutsceneCompleted,
    NarrativePredicateAuthoringKind.chapterCompleted =>
      MapEntityRuntimePredicateKind.chapterCompleted,
  };
}

void _throwIfInvalid(
  List<NarrativePredicateAuthoringDiagnostic> diagnostics,
) {
  if (diagnostics.any(
    (diagnostic) =>
        diagnostic.severity ==
        NarrativePredicateAuthoringDiagnosticSeverity.error,
  )) {
    final summary = diagnostics
        .map((diagnostic) => '${diagnostic.kind.name}:${diagnostic.path}')
        .join(', ');
    throw StateError('Invalid narrative predicate authoring draft: $summary');
  }
}

void _addDiagnostic(
  List<NarrativePredicateAuthoringDiagnostic> diagnostics, {
  required NarrativePredicateAuthoringDiagnosticKind kind,
  required String message,
  required String path,
  NarrativePredicateAuthoringDiagnosticSeverity severity =
      NarrativePredicateAuthoringDiagnosticSeverity.error,
  String? referencedId,
}) {
  diagnostics.add(
    NarrativePredicateAuthoringDiagnostic(
      severity: severity,
      kind: kind,
      message: message,
      path: path,
      referencedId: referencedId,
    ),
  );
}

bool _isTechnicalFlagReference(String refId) =>
    refId.startsWith(_scenarioOutcomePrefix) ||
    refId.startsWith(_battleOutcomePrefix);

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
```

### Contenu complet du fichier créé : `packages/map_core/test/narrative_predicate_authoring_draft_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative predicate authoring draft', () {
    test('creates predicate drafts from reference picker options', () {
      final storyFlag =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.storyFlag,
          referenceId: 'p4.flag.visible',
        ),
      );
      expect(storyFlag.kind, NarrativePredicateAuthoringKind.storyFlagSet);
      expect(storyFlag.refId, 'p4.flag.visible');

      final storyStep =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.storyStep,
          referenceId: 'p4.step.visible',
        ),
      );
      expect(storyStep.kind, NarrativePredicateAuthoringKind.stepCompleted);
      expect(storyStep.refId, 'p4.step.visible');

      final cutscene =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.cutscene,
          referenceId: 'p4_cutscene_visible',
        ),
      );
      expect(cutscene.kind, NarrativePredicateAuthoringKind.cutsceneCompleted);
      expect(cutscene.refId, 'p4_cutscene_visible');

      final scenarioOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.scenarioOutcome,
          referenceId: narrativeScenarioOutcomeFlagReference('p4.outcome.done'),
        ),
      );
      expect(
          scenarioOutcome.kind, NarrativePredicateAuthoringKind.storyFlagSet);
      expect(scenarioOutcome.refId, 'scenario.outcome.p4.outcome.done');

      final battleOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.battleOutcome,
          referenceId: narrativeBattleOutcomeFlagReference(
            'p4_battle',
            NarrativeBattleOutcomeKind.victory,
          ),
        ),
      );
      expect(battleOutcome.kind, NarrativePredicateAuthoringKind.storyFlagSet);
      expect(battleOutcome.refId, 'battle:p4_battle:victory');
    });

    test('compiles predicate drafts to runtime predicates', () {
      final predicate =
          compileNarrativePredicateAuthoringDraftToRuntimePredicate(
        const NarrativePredicateAuthoringDraft(
          kind: NarrativePredicateAuthoringKind.chapterCompleted,
          refId: ' p4.chapter.done ',
        ),
      );

      expect(predicate.kind, MapEntityRuntimePredicateKind.chapterCompleted);
      expect(predicate.refId, 'p4.chapter.done');
    });

    test('diagnoses empty predicate reference ids', () {
      final diagnostics = validateNarrativePredicateAuthoringDraft(
        const NarrativePredicateAuthoringDraft(
          kind: NarrativePredicateAuthoringKind.storyFlagSet,
          refId: ' ',
        ),
      );

      expect(
        _diagnosticKinds(diagnostics),
        [NarrativePredicateAuthoringDiagnosticKind.emptyReferenceId],
      );
    });

    test('compiles visibleWhen visibility rule to NPC visibility rule', () {
      final rule =
          compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
        const NarrativeVisibilityRuleAuthoringDraft.visibleWhen(
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.storyFlagSet,
            refId: 'p4.flag.visible',
          ),
        ),
      );

      expect(rule.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(rule.predicate!.kind, MapEntityRuntimePredicateKind.storyFlagSet);
      expect(rule.predicate!.refId, 'p4.flag.visible');
    });

    test('diagnoses conditional visibility rule without predicate', () {
      final diagnostics = validateNarrativeVisibilityRuleAuthoringDraft(
        const NarrativeVisibilityRuleAuthoringDraft.visibleWhen(),
      );

      expect(
        _diagnosticKinds(diagnostics),
        [NarrativePredicateAuthoringDiagnosticKind.missingPredicate],
      );
    });

    test('compiles conditional dialogue to runtime conditional dialogue', () {
      final dialogue =
          compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
        const NarrativeConditionalDialogueAuthoringDraft(
          dialogueId: ' p4.dialogue.flag ',
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.stepCompleted,
            refId: ' p4.step.visible ',
          ),
        ),
      );

      expect(dialogue.dialogue.dialogueId, 'p4.dialogue.flag');
      expect(dialogue.dialogue.scriptPathRelative, '');
      expect(dialogue.when.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(dialogue.when.refId, 'p4.step.visible');
    });

    test('diagnoses empty dialogue ids and missing conditional predicates', () {
      final diagnostics = validateNarrativeConditionalDialogueAuthoringDraft(
        const NarrativeConditionalDialogueAuthoringDraft(dialogueId: ' '),
      );

      expect(
        _diagnosticKinds(diagnostics),
        containsAll([
          NarrativePredicateAuthoringDiagnosticKind.emptyDialogueId,
          NarrativePredicateAuthoringDiagnosticKind.missingPredicate,
        ]),
      );
    });

    test('accepts scenario outcome and battle outcome as technical flag refs',
        () {
      final scenarioOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.scenarioOutcome,
          referenceId: narrativeScenarioOutcomeFlagReference('p4.outcome.done'),
        ),
      );
      final battleOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.battleOutcome,
          referenceId: narrativeBattleOutcomeFlagReference(
            'p4_battle',
            NarrativeBattleOutcomeKind.defeat,
          ),
        ),
      );

      expect(
          validateNarrativePredicateAuthoringDraft(scenarioOutcome), isEmpty);
      expect(validateNarrativePredicateAuthoringDraft(battleOutcome), isEmpty);
      expect(
        compileNarrativePredicateAuthoringDraftToRuntimePredicate(
          scenarioOutcome,
        ).kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(
        compileNarrativePredicateAuthoringDraftToRuntimePredicate(battleOutcome)
            .kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(scenarioOutcome.refId.startsWith('battle:'), isFalse);
      expect(battleOutcome.refId.startsWith('scenario.outcome.'), isFalse);
    });

    test('diagnoses technical outcome refs used as non-flag predicates', () {
      final diagnostics = validateNarrativePredicateAuthoringDraft(
        const NarrativePredicateAuthoringDraft(
          kind: NarrativePredicateAuthoringKind.stepCompleted,
          refId: 'battle:p4_battle:victory',
        ),
      );

      expect(
        _diagnosticKinds(diagnostics),
        [
          NarrativePredicateAuthoringDiagnosticKind
              .scenarioOutcomeBattleOutcomeConfusion,
        ],
      );
    });

    test('does not create registries or hardcode Selbrume identifiers', () {
      final visibility =
          compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
        const NarrativeVisibilityRuleAuthoringDraft.hiddenWhen(
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.storyFlagSet,
            refId: 'battle:p4_battle:victory',
          ),
        ),
      );
      final dialogue =
          compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
        const NarrativeConditionalDialogueAuthoringDraft(
          dialogueId: 'p4.dialogue.battle',
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.storyFlagSet,
            refId: 'scenario.outcome.p4.outcome.done',
          ),
        ),
      );

      final serialized = {
        visibility.toJson().toString(),
        dialogue.toJson().toString(),
      }.join('\n').toLowerCase();

      expect(serialized, isNot(contains('registry')));
      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativePredicateReferencePickerOption _predicateOption({
  required NarrativePredicateReferenceKind kind,
  required String referenceId,
}) {
  return NarrativePredicateReferencePickerOption(
    referenceId: referenceId,
    referenceKind: kind,
    humanLabel: referenceId,
    sourceScenarioIds: const ['p4_source'],
    debugTechnicalLabel: referenceId,
  );
}

List<NarrativePredicateAuthoringDiagnosticKind> _diagnosticKinds(
  List<NarrativePredicateAuthoringDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/MVP Selbrume/road_map_phase_4.md b/MVP Selbrume/road_map_phase_4.md
index 14a6f116..54ad7551 100644
--- a/MVP Selbrume/road_map_phase_4.md	
+++ b/MVP Selbrume/road_map_phase_4.md	
@@ -6,9 +6,9 @@ Phase 4 — Authoring Workflows Minimal
 
 Statut : 🔜 Phase courante en exécution
 
-Lot courant : P4-05 — Predicate / World Rule Authoring Draft V0
+Lot courant : P4-06 — Narrative Validator Authoring Adapter V0
 
-Prochain lot exact : P4-05 — Predicate / World Rule Authoring Draft V0
+Prochain lot exact : P4-06 — Narrative Validator Authoring Adapter V0
 
 Suivi des lots :
 
@@ -17,8 +17,8 @@ Suivi des lots :
 - ✅ P4-02 — Scenario Authoring Draft Model V0
 - ✅ P4-03 — Event Source Authoring Draft Operations V0
 - ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0
-- 🔜 P4-05 — Predicate / World Rule Authoring Draft V0
-- P4-06 — Narrative Validator Authoring Adapter V0
+- ✅ P4-05 — Predicate / World Rule Authoring Draft V0
+- 🔜 P4-06 — Narrative Validator Authoring Adapter V0
 - P4-07 — Minimal Authoring Golden Path Test V0
 - P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
 
@@ -32,7 +32,9 @@ P4-03 : ✅ terminé
 
 P4-04 : ✅ terminé
 
-P4-05 : 🔜 prochain lot exact
+P4-05 : ✅ terminé
+
+P4-06 : 🔜 prochain lot exact
 
 ## 2. Objectif de la Phase 4
 
@@ -290,7 +292,7 @@ Résultat P4-04 :
   persistant, aucune migration, aucun runtime, aucun contenu Selbrume et aucun
   reward/money/XP créé.
 
-### 🔜 P4-05 — Predicate / World Rule Authoring Draft V0
+### ✅ P4-05 — Predicate / World Rule Authoring Draft V0
 
 Objectif :
 Rendre authorables les predicates et world rules passives sans créer
@@ -299,11 +301,17 @@ FactRegistry ni WorldRuleRegistry.
 Résultat attendu :
 Preuve concrète, pure et testée :
 
-- draft de predicate / visibility rule / conditional dialogue minimal ;
+- draft de predicate / visibility rule / conditional dialogue minimal ajouté ;
 - mapping pur vers `MapEntityRuntimePredicate`,
   `MapEntityNpcVisibilityRule` et `MapEntityConditionalDialogue` ;
-- réutilisation ou généralisation prudente des helpers PNJ existants ;
-- cas négatifs refId vide / cible inconnue.
+- diagnostics authoring `emptyReferenceId`, `emptyDialogueId`,
+  `missingPredicate` et `scenarioOutcomeBattleOutcomeConfusion` ;
+- `scenario.outcome.*` et `battle:*` restent des flags techniques lisibles,
+  pas des registries persistants ;
+- tests ciblés ajoutés dans
+  `packages/map_core/test/narrative_predicate_authoring_draft_test.dart` ;
+- aucun widget UI, aucun FactRegistry/WorldRuleRegistry, aucune migration,
+  aucun runtime, aucun contenu Selbrume et aucun reward/money/XP créé.
 
 ### P4-06 — Narrative Validator Authoring Adapter V0
 
@@ -380,5 +388,5 @@ Phase 4 doit produire des preuves authoring concrètes après P4-00.
 Le prochain lot exact est :
 
 ```text
-P4-05 — Predicate / World Rule Authoring Draft V0
+P4-06 — Narrative Validator Authoring Adapter V0
 ```
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 7d0549e8..3647ef12 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -73,6 +73,7 @@ export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/narrative_validator.dart';
 export 'src/authoring/narrative_event_source_authoring_operations.dart';
 export 'src/authoring/narrative_outcome_authoring_operations.dart';
+export 'src/authoring/narrative_predicate_authoring_draft.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/operations/static_shadow_geometry.dart';
```

### Sortie complète du test ciblé

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

### Sortie complète des régressions ciblées

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

Commande :

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

Première exécution après implementation :

```text
Formatted lib/src/authoring/narrative_predicate_authoring_draft.dart
Formatted test/narrative_predicate_authoring_draft_test.dart
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
 MVP Selbrume/road_map_phase_4.md    | 28 ++++++++++++++++++----------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 19 insertions(+), 10 deletions(-)
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
?? packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
?? packages/map_core/test/narrative_predicate_authoring_draft_test.dart
?? reports/roadmap/phase_4/p4_05_predicate_world_rule_authoring_draft.md
```

### Contrôles hors scope

- `MVP Selbrume/road_map_global.md` n'a pas été modifié.
- P4-06 n'a pas été exécuté.
- Aucun Selbrume final n'a été créé.
- Aucune UI premium n'a été créée.
- Aucun registry persistant n'a été créé.
- Aucun `FactRegistry` / `WorldRuleRegistry` n'a été créé.
- Aucun reward/money/XP n'a été ajouté.
- Aucun modèle persistant `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData`, `MapEntity` ou payload MapEntity n'a été modifié.

## 15. Auto-review critique

Points solides :

- le lot n'est pas audit-only ;
- les mappings sont directs vers les modèles runtime existants ;
- les flags techniques outcome/battle restent des facts lus, pas des registries ;
- les tests couvrent happy paths, diagnostics et hors scope ;
- les régressions authoring précédentes et le validator restent verts.

Limites assumées :

- pas de validation contre un manifest complet ;
- pas d'adapter de diagnostic auteur enrichi, reporté à P4-06 ;
- pas de workflow authoring end-to-end, reporté à P4-07 ;
- `unsupportedPredicateKind` et `unsupportedVisibilityRuleMode` ne sont pas déclenchés actuellement car les enums V0 sont fermées.

## 16. Regard critique sur le prompt

Le prompt est bien borné : il impose une preuve concrète sans ouvrir de registry ni UI. Le point le plus délicat est la notion de "world rule" : dans l'état actuel du modèle, la preuve raisonnable est une projection passive via `MapEntityRuntimePredicate`, `MapEntityNpcVisibilityRule` et `MapEntityConditionalDialogue`, pas un nouveau modèle `WorldRule`. Cette interprétation est cohérente avec les non-objectifs et avec P3-05.
