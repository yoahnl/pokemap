# P4-02 — Scenario Authoring Draft Model V0

## 1. Résumé exécutif

P4-02 est validable : le lot ne reste pas documentaire et ajoute une première
brique authoring concrète, pure et testée.

Résultat principal :

```text
NarrativeScenarioAuthoringDraft
-> validation authoring V0
-> compilation déterministe draft -> ScenarioAsset
```

Le draft V0 permet de décrire un scénario minimal avec :

- `scenarioId`, `name`, `description`, `scope` ;
- une source runtime principale `mapEnter`, `triggerEnter`, `entityInteract`
  ou `outcomeReceived` ;
- des actions linéaires `setFlag`, `completeStep`, `emitOutcome`,
  `startTrainerBattle` ;
- des outcomes déclarés ;
- des métadonnées optionnelles.

La conversion produit un graphe linéaire déterministe :

```text
start -> source -> action_0 -> action_1 -> ... -> end
```

Verdict :

```text
P4-02 : clôturable.
Prochain lot exact : P4-03 — Event Source Authoring Draft Operations V0.
```

## 2. Scope du lot

Inclus :

- audit du modèle `ScenarioAsset` existant ;
- relecture des read models P4-01 ;
- ajout d'un draft model pur dans `map_core` ;
- ajout de diagnostics authoring ciblés ;
- ajout d'une compilation pure `draft -> ScenarioAsset` ;
- tests unitaires ciblés ;
- mise à jour de `MVP Selbrume/road_map_phase_4.md` ;
- rapport P4-02.

Exclus :

- UI / widget Flutter ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- registry persistant ;
- migration JSON ;
- modification `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData` ;
- runtime, editor, host ;
- Selbrume final ;
- rewards / money / XP ;
- P4-03.

## 3. Sources lues

Fichiers principaux lus :

```text
AGENTS.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_4.md
reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md
reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
reports/roadmap/phase_4/p4_01_bis_narrative_reference_picker_evidence_pack_completion.md
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/test/scenario_assets_test.dart
```

Observations utiles :

- `ScenarioAsset` expose déjà `scope`, `entryNodeId`, `declaredOutcomes`,
  `nodes`, `edges`, `metadata`.
- Les sources runtime reconnues par l'exécuteur sont portées par des nodes
  `ScenarioNodeType.reference` avec `payload.actionKind` :
  `sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract`,
  `sourceOutcome`.
- Les actions V0 supportées côté runtime utilisent :
  `setFlag` via `binding.flagName`,
  `completeStep` via `payload.params['stepId']`,
  `emitOutcome` via `binding.outcomeId`,
  `startTrainerBattle` via `binding.trainerId`, `binding.entityId` et
  `payload.params['battleId']`.
- P4-01 fournit les read models qui alimentent conceptuellement ce draft :
  `NarrativeEventSourcePickerOption`,
  `NarrativeOutcomePickerOption`,
  `NarrativeBattleReferencePickerOption`,
  `NarrativeStoryStepPickerOption`.

## 4. Modèle de draft ajouté

Fichier créé :

```text
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
```

API publique ajoutée :

- `NarrativeScenarioAuthoringDraft`
- `NarrativeScenarioAuthoringSourceDraft`
- `NarrativeScenarioAuthoringActionDraft`
- `NarrativeScenarioAuthoringSourceKind`
- `NarrativeScenarioAuthoringActionKind`
- `NarrativeScenarioAuthoringDraftDiagnostic`
- `NarrativeScenarioAuthoringDraftDiagnosticSeverity`
- `NarrativeScenarioAuthoringDraftDiagnosticKind`
- `validateNarrativeScenarioAuthoringDraft(...)`
- `compileNarrativeScenarioAuthoringDraftToScenarioAsset(...)`

Le draft reste volontairement petit, immutable côté listes/maps exposées et sans
I/O.

## 5. Validation du draft

Diagnostics V0 ajoutés :

| Kind | Sévérité | Usage |
|---|---:|---|
| `emptyScenarioId` | error | `scenarioId` vide après trim |
| `emptyScenarioName` | error | `name` vide après trim |
| `missingSource` | error | source absente |
| `missingSourceReference` | error | référence source requise absente |
| `emptyActionReference` | error | référence action requise absente |
| `emitOutcomeNotDeclared` | warning | action emitOutcome non déclarée |
| `declaredOutcomeNeverEmitted` | warning | outcome déclaré jamais émis |
| `unsupportedDraftShape` | non utilisé en V0 | réserve explicite sans ouvrir de scope |

Règles source :

- `mapEnter` exige `mapId` ;
- `triggerEnter` exige `mapId + triggerId` ;
- `entityInteract` exige `mapId + entityId` ;
- `outcomeReceived` exige `outcomeId`.

Règles action :

- `setFlag` exige `flagName` ;
- `completeStep` exige `stepId` ;
- `emitOutcome` exige `outcomeId` ;
- `startTrainerBattle` exige `trainerId + battleId`, et un `npcEntityId`
  explicite ou dérivable d'une source `entityInteract`.

## 6. Compilation draft -> ScenarioAsset

La conversion est implémentée et testée.

Principes :

- pas d'I/O ;
- pas de mutation du draft ;
- graph linéaire déterministe ;
- `entryNodeId = <scenarioId>__start` ;
- source node en `ScenarioNodeType.reference` ;
- actions en `ScenarioNodeType.action` ;
- exactement un start node et un end node ;
- node ids déterministes ;
- edge ids déterministes ;
- `declaredOutcomes` trim/dedup en ordre d'apparition ;
- `metadata` propagée sans inventer de nouveau format persistant.

IDs produits :

```text
<scenarioId>__start
<scenarioId>__source
<scenarioId>__action_0
<scenarioId>__action_1
<scenarioId>__end
```

La conversion n'ouvre pas branches complexes, choices, dialogue Yarn,
cinématique riche, transitions map, rewards, money ou XP.

## 7. Lien avec les read models P4-01

Les read models P4-01 alimentent ce draft sans devenir des dépendances fortes :

| Read model P4-01 | Usage P4-02 / futur |
|---|---|
| `NarrativeEventSourcePickerOption` | alimente `NarrativeScenarioAuthoringSourceDraft` |
| `NarrativeOutcomePickerOption` | alimente `declaredOutcomes`, `emitOutcome`, `outcomeReceived` |
| `NarrativeBattleReferencePickerOption` | alimente `startTrainerBattle` |
| `NarrativeStoryStepPickerOption` | alimente `completeStep` |
| `NarrativePredicateReferencePickerOption` | surtout P4-05, hors draft scenario V0 |

P4-02 ne consomme pas directement les options P4-01 pour garder le modèle pur et
simple. P4-03/P4-04 pourront ajouter des opérations de transformation plus
strictes depuis ces options.

## 8. Limites et reports vers P4-03 / P4-04 / P4-05

Reportés à P4-03 :

- opérations authoring dédiées pour construire/mettre à jour les sources Event ;
- validation cross-source avec options map/trigger/entity/outcome ;
- ergonomie autour de source `triggerEnter` et `entityInteract`.

Reportés à P4-04 :

- opérations outcome / battle outcome plus riches ;
- helpers auteur pour distinguer `scenario.outcome.*` et `battle:*` ;
- authoring de continuation battle victory/defeat.

Reportés à P4-05 :

- predicates ;
- visibility rules ;
- conditional dialogues ;
- world presence / world rules passives.

Non prouvé par P4-02 :

- UI auteur ;
- persistence projet ;
- exécution runtime de ce draft compilé ;
- Scene Builder / Cinematic Builder complet ;
- golden path authoring complet.

## 9. Tests exécutés

Tests ciblés et régressions :

```bash
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_scenario_authoring_draft.dart test/narrative_scenario_authoring_draft_test.dart
```

Résultats :

```text
dart test test/narrative_scenario_authoring_draft_test.dart : All tests passed, +9
dart test test/narrative_reference_picker_read_models_test.dart : All tests passed, +8
dart test test/narrative_validator_test.dart : All tests passed, +21
dart analyze : No issues found
dart format --set-exit-if-changed : Formatted 2 files (0 changed)
```

## 10. Modifications effectuées

Fichiers créés :

```text
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
packages/map_core/test/narrative_scenario_authoring_draft_test.dart
reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

Contrôles :

```text
road_map_global.md non modifié.
ProjectManifest non modifié.
ScenarioAsset non modifié.
GameState non modifié.
SaveData non modifié.
map_editor non modifié.
map_runtime non modifié.
map_gameplay non modifié.
map_battle non modifié.
examples/playable_runtime_host non modifié.
P4-03 non exécuté.
Selbrume final non créé.
Aucune UI premium créée.
Aucun registry persistant créé.
Aucun reward/money/XP ajouté.
```

## 11. Evidence Pack

### 11.1 git status initial exact

```text

```

Le statut initial était propre.

### 11.2 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,620p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md
sed -n '1,260p' reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
sed -n '1,260p' reports/roadmap/phase_4/p4_01_bis_narrative_reference_picker_evidence_pack_completion.md
sed -n '1,420p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,420p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,260p' packages/map_core/lib/map_core.dart
rg -n "ScenarioAsset|ScenarioNode|ScenarioEdge|ScenarioNodeType|ScenarioNodePayload|ScenarioNodeBinding|ScenarioScope|emitOutcome|setFlag|completeStep|startTrainerBattle|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|outcomeReceived|NarrativeScenarioAuthoring|Draft|Authoring" packages/map_core packages/map_editor --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_core/lib/src -maxdepth 3 -type f | sort | rg "authoring|scenario|narrative|draft|read_models|operations"
find packages/map_core/test -type f | sort | rg "narrative|scenario|authoring|draft|picker|validator"
sed -n '760,980p' packages/map_core/lib/src/validation/validators.dart
sed -n '420,620p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '880,1020p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
rg -n "completeStep|setFlag|startTrainerBattle|battleId|scenarioBattle|trainerId|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome" packages/map_runtime packages/map_core/lib/src/operations packages/map_core/test --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,80p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '470,680p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '960,1190p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '600,730p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,180p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '180,360p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '360,470p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '500,610p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
rg -n "_findMatchingSourceNode|_matches" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1220,1325p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1325,1365p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,140p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
sed -n '1,120p' packages/map_core/test/scenario_assets_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_scenario_authoring_draft.dart test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
git diff -- packages/map_core/lib/map_core.dart "MVP Selbrume/road_map_phase_4.md"
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 11.3 Sorties utiles des commandes d'audit

`find packages/map_core/lib/src -maxdepth 3 ...` :

```text
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/scenario_asset.freezed.dart
packages/map_core/lib/src/models/scenario_asset.g.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
```

`find packages/map_core/test ...` :

```text
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/scenario_assets_test.dart
```

Signaux `rg` utiles :

```text
packages/map_core/lib/src/operations/narrative_validator.dart:9:const String _sourceMapEnter = 'sourceMapEnter';
packages/map_core/lib/src/operations/narrative_validator.dart:10:const String _sourceTriggerEnter = 'sourceTriggerEnter';
packages/map_core/lib/src/operations/narrative_validator.dart:11:const String _sourceEntityInteract = 'sourceEntityInteract';
packages/map_core/lib/src/operations/narrative_validator.dart:12:const String _sourceOutcome = 'sourceOutcome';
packages/map_core/lib/src/operations/narrative_validator.dart:14:const String _actionSetFlag = 'setFlag';
packages/map_core/lib/src/operations/narrative_validator.dart:16:const String _actionStartTrainerBattle = 'startTrainerBattle';
packages/map_core/lib/src/operations/narrative_validator.dart:17:const String _actionCompleteStep = 'completeStep';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:12:const String kScenarioSourceMapEnter = 'sourceMapEnter';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:13:const String kScenarioSourceTriggerEnter = 'sourceTriggerEnter';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:14:const String kScenarioSourceEntityInteract = 'sourceEntityInteract';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:15:const String kScenarioSourceOutcome = 'sourceOutcome';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:25:const String kScenarioActionSetFlag = 'setFlag';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:41:const String kScenarioActionStartTrainerBattle = 'startTrainerBattle';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:71:const String kScenarioActionCompleteStep = 'completeStep';
```

### 11.4 TDD — premier test rouge exact utile

```text
Failed to load "test/narrative_scenario_authoring_draft_test.dart":
test/narrative_scenario_authoring_draft_test.dart:252:1: Error: Type 'NarrativeScenarioAuthoringDraft' not found.
NarrativeScenarioAuthoringDraft _minimalDraft({
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
...
Error: Method not found: 'validateNarrativeScenarioAuthoringDraft'.
Error: Method not found: 'compileNarrativeScenarioAuthoringDraftToScenarioAsset'.
Some tests failed.
```

Ce rouge était attendu : le test a été écrit avant l'API.

### 11.5 Contenu complet du fichier créé `narrative_scenario_authoring_draft.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/scenario_asset.dart';

const String _sourceMapEnter = 'sourceMapEnter';
const String _sourceTriggerEnter = 'sourceTriggerEnter';
const String _sourceEntityInteract = 'sourceEntityInteract';
const String _sourceOutcome = 'sourceOutcome';
const String _actionSetFlag = 'setFlag';
const String _actionCompleteStep = 'completeStep';
const String _actionEmitOutcome = 'emitOutcome';
const String _actionStartTrainerBattle = 'startTrainerBattle';
const String _stepIdParam = 'stepId';
const String _battleIdParam = 'battleId';

enum NarrativeScenarioAuthoringSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}

enum NarrativeScenarioAuthoringActionKind {
  setFlag,
  completeStep,
  emitOutcome,
  startTrainerBattle,
}

enum NarrativeScenarioAuthoringDraftDiagnosticSeverity {
  error,
  warning,
}

enum NarrativeScenarioAuthoringDraftDiagnosticKind {
  emptyScenarioId,
  emptyScenarioName,
  missingSource,
  missingSourceReference,
  emptyActionReference,
  emitOutcomeNotDeclared,
  declaredOutcomeNeverEmitted,
  unsupportedDraftShape,
}

@immutable
final class NarrativeScenarioAuthoringDraft {
  NarrativeScenarioAuthoringDraft({
    required this.scenarioId,
    required this.name,
    this.description = '',
    this.scope = ScenarioScope.localEventFlow,
    required this.source,
    required List<NarrativeScenarioAuthoringActionDraft> actions,
    required List<String> declaredOutcomes,
    Map<String, String> metadata = const {},
  })  : actions =
            List<NarrativeScenarioAuthoringActionDraft>.unmodifiable(actions),
        declaredOutcomes = List<String>.unmodifiable(declaredOutcomes),
        metadata = Map<String, String>.unmodifiable(metadata);

  final String scenarioId;
  final String name;
  final String description;
  final ScenarioScope scope;
  final NarrativeScenarioAuthoringSourceDraft? source;
  final List<NarrativeScenarioAuthoringActionDraft> actions;
  final List<String> declaredOutcomes;
  final Map<String, String> metadata;
}

@immutable
final class NarrativeScenarioAuthoringSourceDraft {
  const NarrativeScenarioAuthoringSourceDraft.mapEnter({
    required this.mapId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.mapEnter,
        triggerId = '',
        entityId = '',
        outcomeId = '';

  const NarrativeScenarioAuthoringSourceDraft.triggerEnter({
    required this.mapId,
    required this.triggerId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.triggerEnter,
        entityId = '',
        outcomeId = '';

  const NarrativeScenarioAuthoringSourceDraft.entityInteract({
    required this.mapId,
    required this.entityId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.entityInteract,
        triggerId = '',
        outcomeId = '';

  const NarrativeScenarioAuthoringSourceDraft.outcomeReceived({
    required this.outcomeId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.outcomeReceived,
        mapId = '',
        triggerId = '',
        entityId = '';

  final NarrativeScenarioAuthoringSourceKind kind;
  final String mapId;
  final String triggerId;
  final String entityId;
  final String outcomeId;
}

@immutable
final class NarrativeScenarioAuthoringActionDraft {
  const NarrativeScenarioAuthoringActionDraft.setFlag({
    required this.flagName,
  })  : kind = NarrativeScenarioAuthoringActionKind.setFlag,
        stepId = '',
        outcomeId = '',
        battleId = '',
        trainerId = '',
        npcEntityId = '';

  const NarrativeScenarioAuthoringActionDraft.completeStep({
    required this.stepId,
  })  : kind = NarrativeScenarioAuthoringActionKind.completeStep,
        flagName = '',
        outcomeId = '',
        battleId = '',
        trainerId = '',
        npcEntityId = '';

  const NarrativeScenarioAuthoringActionDraft.emitOutcome({
    required this.outcomeId,
  })  : kind = NarrativeScenarioAuthoringActionKind.emitOutcome,
        flagName = '',
        stepId = '',
        battleId = '',
        trainerId = '',
        npcEntityId = '';

  const NarrativeScenarioAuthoringActionDraft.startTrainerBattle({
    required this.trainerId,
    required this.battleId,
    this.npcEntityId = '',
  })  : kind = NarrativeScenarioAuthoringActionKind.startTrainerBattle,
        flagName = '',
        stepId = '',
        outcomeId = '';

  final NarrativeScenarioAuthoringActionKind kind;
  final String flagName;
  final String stepId;
  final String outcomeId;
  final String battleId;
  final String trainerId;
  final String npcEntityId;
}

@immutable
final class NarrativeScenarioAuthoringDraftDiagnostic {
  const NarrativeScenarioAuthoringDraftDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativeScenarioAuthoringDraftDiagnosticSeverity severity;
  final NarrativeScenarioAuthoringDraftDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

List<NarrativeScenarioAuthoringDraftDiagnostic>
    validateNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
) {
  final diagnostics = <NarrativeScenarioAuthoringDraftDiagnostic>[];
  final declaredOutcomeIds = _dedupeTrimmed(draft.declaredOutcomes).toSet();
  final emittedOutcomeIds = <String>{};

  if (draft.scenarioId.trim().isEmpty) {
    diagnostics.add(
      const NarrativeScenarioAuthoringDraftDiagnostic(
        severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
        kind: NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioId,
        message: 'Scenario id is required.',
        path: 'scenarioId',
      ),
    );
  }
  if (draft.name.trim().isEmpty) {
    diagnostics.add(
      const NarrativeScenarioAuthoringDraftDiagnostic(
        severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
        kind: NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioName,
        message: 'Scenario name is required.',
        path: 'name',
      ),
    );
  }

  final source = draft.source;
  if (source == null) {
    diagnostics.add(
      const NarrativeScenarioAuthoringDraftDiagnostic(
        severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
        kind: NarrativeScenarioAuthoringDraftDiagnosticKind.missingSource,
        message: 'A scenario authoring draft requires one runtime source.',
        path: 'source',
      ),
    );
  } else {
    _validateSource(source, diagnostics);
  }

  for (var index = 0; index < draft.actions.length; index++) {
    final action = draft.actions[index];
    _validateAction(
      action,
      source: source,
      index: index,
      diagnostics: diagnostics,
    );
    final emittedOutcomeId = action.outcomeId.trim();
    if (action.kind == NarrativeScenarioAuthoringActionKind.emitOutcome &&
        emittedOutcomeId.isNotEmpty) {
      emittedOutcomeIds.add(emittedOutcomeId);
      if (!declaredOutcomeIds.contains(emittedOutcomeId)) {
        diagnostics.add(
          NarrativeScenarioAuthoringDraftDiagnostic(
            severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.warning,
            kind: NarrativeScenarioAuthoringDraftDiagnosticKind
                .emitOutcomeNotDeclared,
            message: 'Outcome "$emittedOutcomeId" is emitted but not declared.',
            path: 'actions[$index].outcomeId',
            referencedId: emittedOutcomeId,
          ),
        );
      }
    }
  }

  for (final declaredOutcomeId in declaredOutcomeIds) {
    if (!emittedOutcomeIds.contains(declaredOutcomeId)) {
      diagnostics.add(
        NarrativeScenarioAuthoringDraftDiagnostic(
          severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.warning,
          kind: NarrativeScenarioAuthoringDraftDiagnosticKind
              .declaredOutcomeNeverEmitted,
          message: 'Declared outcome "$declaredOutcomeId" is never emitted.',
          path: 'declaredOutcomes',
          referencedId: declaredOutcomeId,
        ),
      );
    }
  }

  return List<NarrativeScenarioAuthoringDraftDiagnostic>.unmodifiable(
    diagnostics,
  );
}

ScenarioAsset compileNarrativeScenarioAuthoringDraftToScenarioAsset(
  NarrativeScenarioAuthoringDraft draft,
) {
  final blockingDiagnostics = validateNarrativeScenarioAuthoringDraft(draft)
      .where((diagnostic) =>
          diagnostic.severity ==
          NarrativeScenarioAuthoringDraftDiagnosticSeverity.error)
      .toList(growable: false);
  if (blockingDiagnostics.isNotEmpty) {
    throw StateError(
      'Cannot compile invalid narrative scenario authoring draft: '
      '${blockingDiagnostics.map((diagnostic) => diagnostic.path).join(', ')}',
    );
  }

  final scenarioId = draft.scenarioId.trim();
  final source = draft.source!;
  final nodes = <ScenarioNode>[
    ScenarioNode(
      id: _startNodeId(scenarioId),
      type: ScenarioNodeType.start,
      title: 'Start',
      position: const ScenarioNodePosition(x: 0, y: 0),
    ),
    _compileSourceNode(scenarioId, source),
  ];

  for (var index = 0; index < draft.actions.length; index++) {
    nodes.add(
      _compileActionNode(
        scenarioId: scenarioId,
        index: index,
        action: draft.actions[index],
        source: source,
      ),
    );
  }

  nodes.add(
    ScenarioNode(
      id: _endNodeId(scenarioId),
      type: ScenarioNodeType.end,
      title: 'End',
      position: ScenarioNodePosition(
        x: _nodeX(draft.actions.length + 2),
        y: 0,
      ),
    ),
  );

  return ScenarioAsset(
    id: scenarioId,
    name: draft.name.trim(),
    description: draft.description.trim(),
    scope: draft.scope,
    entryNodeId: _startNodeId(scenarioId),
    declaredOutcomes: _dedupeTrimmed(draft.declaredOutcomes),
    nodes: nodes,
    edges: _compileLinearEdges(
      scenarioId: scenarioId,
      actionCount: draft.actions.length,
    ),
    metadata: draft.metadata,
  );
}

void _validateSource(
  NarrativeScenarioAuthoringSourceDraft source,
  List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
) {
  switch (source.kind) {
    case NarrativeScenarioAuthoringSourceKind.mapEnter:
      _requireSourceRef(
        source.mapId,
        path: 'source.mapId',
        label: 'mapId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringSourceKind.triggerEnter:
      _requireSourceRef(
        source.mapId,
        path: 'source.mapId',
        label: 'mapId',
        diagnostics: diagnostics,
      );
      _requireSourceRef(
        source.triggerId,
        path: 'source.triggerId',
        label: 'triggerId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringSourceKind.entityInteract:
      _requireSourceRef(
        source.mapId,
        path: 'source.mapId',
        label: 'mapId',
        diagnostics: diagnostics,
      );
      _requireSourceRef(
        source.entityId,
        path: 'source.entityId',
        label: 'entityId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringSourceKind.outcomeReceived:
      _requireSourceRef(
        source.outcomeId,
        path: 'source.outcomeId',
        label: 'outcomeId',
        diagnostics: diagnostics,
      );
  }
}

void _validateAction(
  NarrativeScenarioAuthoringActionDraft action, {
  required NarrativeScenarioAuthoringSourceDraft? source,
  required int index,
  required List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
}) {
  switch (action.kind) {
    case NarrativeScenarioAuthoringActionKind.setFlag:
      _requireActionRef(
        action.flagName,
        path: 'actions[$index].flagName',
        label: 'flagName',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringActionKind.completeStep:
      _requireActionRef(
        action.stepId,
        path: 'actions[$index].stepId',
        label: 'stepId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringActionKind.emitOutcome:
      _requireActionRef(
        action.outcomeId,
        path: 'actions[$index].outcomeId',
        label: 'outcomeId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringActionKind.startTrainerBattle:
      _requireActionRef(
        action.trainerId,
        path: 'actions[$index].trainerId',
        label: 'trainerId',
        diagnostics: diagnostics,
      );
      _requireActionRef(
        action.battleId,
        path: 'actions[$index].battleId',
        label: 'battleId',
        diagnostics: diagnostics,
      );
      final explicitNpcEntityId = action.npcEntityId.trim();
      final sourceNpcEntityId =
          source?.kind == NarrativeScenarioAuthoringSourceKind.entityInteract
              ? source?.entityId.trim() ?? ''
              : '';
      if (explicitNpcEntityId.isEmpty && sourceNpcEntityId.isEmpty) {
        _requireActionRef(
          '',
          path: 'actions[$index].npcEntityId',
          label: 'npcEntityId',
          diagnostics: diagnostics,
        );
      }
  }
}

void _requireSourceRef(
  String value, {
  required String path,
  required String label,
  required List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
}) {
  if (value.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeScenarioAuthoringDraftDiagnostic(
      severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
      kind:
          NarrativeScenarioAuthoringDraftDiagnosticKind.missingSourceReference,
      message: 'Source reference "$label" is required.',
      path: path,
    ),
  );
}

void _requireActionRef(
  String value, {
  required String path,
  required String label,
  required List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
}) {
  if (value.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeScenarioAuthoringDraftDiagnostic(
      severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
      kind: NarrativeScenarioAuthoringDraftDiagnosticKind.emptyActionReference,
      message: 'Action reference "$label" is required.',
      path: path,
    ),
  );
}

ScenarioNode _compileSourceNode(
  String scenarioId,
  NarrativeScenarioAuthoringSourceDraft source,
) {
  final binding = switch (source.kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter => ScenarioNodeBinding(
        mapId: source.mapId.trim(),
      ),
    NarrativeScenarioAuthoringSourceKind.triggerEnter => ScenarioNodeBinding(
        mapId: source.mapId.trim(),
        triggerId: source.triggerId.trim(),
      ),
    NarrativeScenarioAuthoringSourceKind.entityInteract => ScenarioNodeBinding(
        mapId: source.mapId.trim(),
        entityId: source.entityId.trim(),
      ),
    NarrativeScenarioAuthoringSourceKind.outcomeReceived => ScenarioNodeBinding(
        outcomeId: source.outcomeId.trim(),
      ),
  };
  return ScenarioNode(
    id: _sourceNodeId(scenarioId),
    type: ScenarioNodeType.reference,
    title: _sourceTitle(source.kind),
    position: ScenarioNodePosition(x: _nodeX(1), y: 0),
    binding: binding,
    payload: ScenarioNodePayload(
      actionKind: _sourceActionKind(source.kind),
    ),
  );
}

ScenarioNode _compileActionNode({
  required String scenarioId,
  required int index,
  required NarrativeScenarioAuthoringActionDraft action,
  required NarrativeScenarioAuthoringSourceDraft source,
}) {
  final position = ScenarioNodePosition(x: _nodeX(index + 2), y: 0);
  switch (action.kind) {
    case NarrativeScenarioAuthoringActionKind.setFlag:
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Set flag',
        position: position,
        binding: ScenarioNodeBinding(flagName: action.flagName.trim()),
        payload: const ScenarioNodePayload(actionKind: _actionSetFlag),
      );
    case NarrativeScenarioAuthoringActionKind.completeStep:
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Complete step',
        position: position,
        payload: ScenarioNodePayload(
          actionKind: _actionCompleteStep,
          params: {_stepIdParam: action.stepId.trim()},
        ),
      );
    case NarrativeScenarioAuthoringActionKind.emitOutcome:
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Emit outcome',
        position: position,
        binding: ScenarioNodeBinding(outcomeId: action.outcomeId.trim()),
        payload: const ScenarioNodePayload(actionKind: _actionEmitOutcome),
      );
    case NarrativeScenarioAuthoringActionKind.startTrainerBattle:
      final npcEntityId = action.npcEntityId.trim().isNotEmpty
          ? action.npcEntityId.trim()
          : source.entityId.trim();
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Start trainer battle',
        position: position,
        binding: ScenarioNodeBinding(
          trainerId: action.trainerId.trim(),
          entityId: npcEntityId,
        ),
        payload: ScenarioNodePayload(
          actionKind: _actionStartTrainerBattle,
          params: {_battleIdParam: action.battleId.trim()},
        ),
      );
  }
}

List<ScenarioEdge> _compileLinearEdges({
  required String scenarioId,
  required int actionCount,
}) {
  final edges = <ScenarioEdge>[
    ScenarioEdge(
      id: '${scenarioId}__edge_start_to_source',
      fromNodeId: _startNodeId(scenarioId),
      toNodeId: _sourceNodeId(scenarioId),
      order: 0,
    ),
  ];

  if (actionCount == 0) {
    edges.add(
      ScenarioEdge(
        id: '${scenarioId}__edge_source_to_end',
        fromNodeId: _sourceNodeId(scenarioId),
        toNodeId: _endNodeId(scenarioId),
        order: 1,
      ),
    );
    return List<ScenarioEdge>.unmodifiable(edges);
  }

  edges.add(
    ScenarioEdge(
      id: '${scenarioId}__edge_source_to_action_0',
      fromNodeId: _sourceNodeId(scenarioId),
      toNodeId: _actionNodeId(scenarioId, 0),
      order: 1,
    ),
  );

  for (var index = 0; index < actionCount; index++) {
    final isLast = index == actionCount - 1;
    edges.add(
      ScenarioEdge(
        id: isLast
            ? '${scenarioId}__edge_action_${index}_to_end'
            : '${scenarioId}__edge_action_${index}_to_action_${index + 1}',
        fromNodeId: _actionNodeId(scenarioId, index),
        toNodeId: isLast
            ? _endNodeId(scenarioId)
            : _actionNodeId(scenarioId, index + 1),
        order: index + 2,
      ),
    );
  }

  return List<ScenarioEdge>.unmodifiable(edges);
}

String _sourceActionKind(NarrativeScenarioAuthoringSourceKind kind) {
  return switch (kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter => _sourceMapEnter,
    NarrativeScenarioAuthoringSourceKind.triggerEnter => _sourceTriggerEnter,
    NarrativeScenarioAuthoringSourceKind.entityInteract =>
      _sourceEntityInteract,
    NarrativeScenarioAuthoringSourceKind.outcomeReceived => _sourceOutcome,
  };
}

String _sourceTitle(NarrativeScenarioAuthoringSourceKind kind) {
  return switch (kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter => 'Map enter',
    NarrativeScenarioAuthoringSourceKind.triggerEnter => 'Trigger enter',
    NarrativeScenarioAuthoringSourceKind.entityInteract => 'Entity interact',
    NarrativeScenarioAuthoringSourceKind.outcomeReceived => 'Outcome received',
  };
}

List<String> _dedupeTrimmed(Iterable<String> values) {
  final out = <String>[];
  final seen = <String>{};
  for (final rawValue in values) {
    final value = rawValue.trim();
    if (value.isEmpty || !seen.add(value)) {
      continue;
    }
    out.add(value);
  }
  return List<String>.unmodifiable(out);
}

String _startNodeId(String scenarioId) => '${scenarioId}__start';

String _sourceNodeId(String scenarioId) => '${scenarioId}__source';

String _actionNodeId(String scenarioId, int index) =>
    '${scenarioId}__action_$index';

String _endNodeId(String scenarioId) => '${scenarioId}__end';

double _nodeX(int index) => index * 240;
```

### 11.6 Contenu complet du test créé `narrative_scenario_authoring_draft_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeScenarioAuthoringDraft validation', () {
    test('accepts a minimal authoring draft', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(),
      );

      expect(diagnostics, isEmpty);
    });

    test('rejects empty scenario id and name', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(scenarioId: ' ', name: ' '),
      );

      expect(
          _kinds(diagnostics),
          containsAll([
            NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioId,
            NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioName,
          ]));
      expect(
        diagnostics.every((diagnostic) =>
            diagnostic.severity ==
            NarrativeScenarioAuthoringDraftDiagnosticSeverity.error),
        isTrue,
      );
    });

    test('rejects missing source and required source references', () {
      final missingSource = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(source: null),
      );
      expect(
          _kinds(missingSource),
          contains(
            NarrativeScenarioAuthoringDraftDiagnosticKind.missingSource,
          ));

      final incompleteTrigger = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(
          source: const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
            mapId: 'p4_test_map',
            triggerId: ' ',
          ),
        ),
      );
      expect(
          _kinds(incompleteTrigger),
          contains(
            NarrativeScenarioAuthoringDraftDiagnosticKind
                .missingSourceReference,
          ));
      expect(incompleteTrigger.single.path, 'source.triggerId');
    });

    test('rejects actions with missing required references', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(
          declaredOutcomes: const [],
          actions: const [
            NarrativeScenarioAuthoringActionDraft.setFlag(flagName: ' '),
            NarrativeScenarioAuthoringActionDraft.completeStep(stepId: ' '),
            NarrativeScenarioAuthoringActionDraft.emitOutcome(outcomeId: ' '),
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              trainerId: ' ',
              battleId: ' ',
            ),
          ],
        ),
      );

      expect(
        diagnostics
            .where((diagnostic) =>
                diagnostic.kind ==
                NarrativeScenarioAuthoringDraftDiagnosticKind
                    .emptyActionReference)
            .length,
        6,
      );
      expect(
        diagnostics.every((diagnostic) =>
            diagnostic.severity ==
            NarrativeScenarioAuthoringDraftDiagnosticSeverity.error),
        isTrue,
      );
    });

    test('detects emitted and declared outcome drift', () {
      final diagnostics = validateNarrativeScenarioAuthoringDraft(
        _minimalDraft(
          declaredOutcomes: const ['p4.outcome.declared_only'],
          actions: const [
            NarrativeScenarioAuthoringActionDraft.emitOutcome(
              outcomeId: 'p4.outcome.emitted_only',
            ),
          ],
        ),
      );

      expect(
          _kinds(diagnostics),
          containsAll([
            NarrativeScenarioAuthoringDraftDiagnosticKind
                .emitOutcomeNotDeclared,
            NarrativeScenarioAuthoringDraftDiagnosticKind
                .declaredOutcomeNeverEmitted,
          ]));
      expect(
        diagnostics.every((diagnostic) =>
            diagnostic.severity ==
            NarrativeScenarioAuthoringDraftDiagnosticSeverity.warning),
        isTrue,
      );
    });
  });

  group('compileNarrativeScenarioAuthoringDraftToScenarioAsset', () {
    test('compiles mapEnter with linear actions into a deterministic asset',
        () {
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _minimalDraft(),
      );

      expect(asset.id, 'p4_test_scenario');
      expect(asset.name, 'P4 Test Scenario');
      expect(asset.description, 'Technical authoring draft test.');
      expect(asset.scope, ScenarioScope.localEventFlow);
      expect(asset.entryNodeId, 'p4_test_scenario__start');
      expect(asset.declaredOutcomes, ['p4.outcome.done']);

      expect(asset.nodes.map((node) => node.id), [
        'p4_test_scenario__start',
        'p4_test_scenario__source',
        'p4_test_scenario__action_0',
        'p4_test_scenario__action_1',
        'p4_test_scenario__action_2',
        'p4_test_scenario__end',
      ]);
      expect(asset.edges.map((edge) => edge.id), [
        'p4_test_scenario__edge_start_to_source',
        'p4_test_scenario__edge_source_to_action_0',
        'p4_test_scenario__edge_action_0_to_action_1',
        'p4_test_scenario__edge_action_1_to_action_2',
        'p4_test_scenario__edge_action_2_to_end',
      ]);

      final source = asset.nodes[1];
      expect(source.type, ScenarioNodeType.reference);
      expect(source.payload.actionKind, 'sourceMapEnter');
      expect(source.binding.mapId, 'p4_test_map');

      final setFlag = asset.nodes[2];
      expect(setFlag.type, ScenarioNodeType.action);
      expect(setFlag.payload.actionKind, 'setFlag');
      expect(setFlag.binding.flagName, 'p4.flag.executed');

      final completeStep = asset.nodes[3];
      expect(completeStep.payload.actionKind, 'completeStep');
      expect(completeStep.payload.params['stepId'], 'p4.step.completed');

      final emitOutcome = asset.nodes[4];
      expect(emitOutcome.payload.actionKind, 'emitOutcome');
      expect(emitOutcome.binding.outcomeId, 'p4.outcome.done');

      expect(
        asset.nodes.where((node) => node.type == ScenarioNodeType.start),
        hasLength(1),
      );
      expect(
        asset.nodes.where((node) => node.type == ScenarioNodeType.end),
        hasLength(1),
      );
    });

    test('compiles entityInteract with startTrainerBattle using source entity',
        () {
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _minimalDraft(
          source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: 'p4_battle_map',
            entityId: 'p4_npc',
          ),
          actions: const [
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              trainerId: 'p4_trainer',
              battleId: 'p4_battle',
            ),
          ],
          declaredOutcomes: const [],
        ),
      );

      final source = asset.nodes[1];
      expect(source.payload.actionKind, 'sourceEntityInteract');
      expect(source.binding.mapId, 'p4_battle_map');
      expect(source.binding.entityId, 'p4_npc');

      final battle = asset.nodes[2];
      expect(battle.payload.actionKind, 'startTrainerBattle');
      expect(battle.binding.trainerId, 'p4_trainer');
      expect(battle.binding.entityId, 'p4_npc');
      expect(battle.payload.params['battleId'], 'p4_battle');
    });

    test('does not mutate input lists and exposes immutable lists', () {
      final actions = [
        const NarrativeScenarioAuthoringActionDraft.setFlag(
          flagName: 'p4.flag.original',
        ),
      ];
      final declaredOutcomes = ['p4.outcome.original'];
      final draft = _minimalDraft(
        actions: actions,
        declaredOutcomes: declaredOutcomes,
      );

      actions.add(
        const NarrativeScenarioAuthoringActionDraft.setFlag(
          flagName: 'p4.flag.mutated',
        ),
      );
      declaredOutcomes.add('p4.outcome.mutated');

      final asset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);

      expect(
        asset.nodes
            .where((node) => node.payload.actionKind == 'setFlag')
            .map((node) => node.binding.flagName),
        ['p4.flag.original'],
      );
      expect(asset.declaredOutcomes, ['p4.outcome.original']);
      expect(
        () => draft.actions.add(
          const NarrativeScenarioAuthoringActionDraft.setFlag(
            flagName: 'p4.flag.illegal',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(() => draft.declaredOutcomes.add('p4.outcome.illegal'),
          throwsUnsupportedError);
    });

    test('does not hardcode Selbrume identifiers', () {
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _minimalDraft(),
      );

      final serialized = asset.toJson().toString().toLowerCase();
      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativeScenarioAuthoringDraft _minimalDraft({
  String scenarioId = 'p4_test_scenario',
  String name = 'P4 Test Scenario',
  NarrativeScenarioAuthoringSourceDraft? source =
      const NarrativeScenarioAuthoringSourceDraft.mapEnter(
    mapId: 'p4_test_map',
  ),
  List<NarrativeScenarioAuthoringActionDraft> actions = const [
    NarrativeScenarioAuthoringActionDraft.setFlag(
      flagName: 'p4.flag.executed',
    ),
    NarrativeScenarioAuthoringActionDraft.completeStep(
      stepId: 'p4.step.completed',
    ),
    NarrativeScenarioAuthoringActionDraft.emitOutcome(
      outcomeId: 'p4.outcome.done',
    ),
  ],
  List<String> declaredOutcomes = const ['p4.outcome.done'],
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: scenarioId,
    name: name,
    description: 'Technical authoring draft test.',
    scope: ScenarioScope.localEventFlow,
    source: source,
    actions: actions,
    declaredOutcomes: declaredOutcomes,
  );
}

List<NarrativeScenarioAuthoringDraftDiagnosticKind> _kinds(
  List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}
```

### 11.7 Diff complet des fichiers modifiés

```diff
diff --git a/MVP Selbrume/road_map_phase_4.md b/MVP Selbrume/road_map_phase_4.md
index 5c5deffc..ea19e09d 100644
--- a/MVP Selbrume/road_map_phase_4.md	
+++ b/MVP Selbrume/road_map_phase_4.md	
@@ -6,16 +6,16 @@ Phase 4 — Authoring Workflows Minimal
 
 Statut : 🔜 Phase courante en exécution
 
-Lot courant : P4-02 — Scenario Authoring Draft Model V0
+Lot courant : P4-03 — Event Source Authoring Draft Operations V0
 
-Prochain lot exact : P4-02 — Scenario Authoring Draft Model V0
+Prochain lot exact : P4-03 — Event Source Authoring Draft Operations V0
 
 Suivi des lots :
 
 - ✅ P4-00 — Phase 4 Roadmap Recalibration / Authoring Workflow Audit
 - ✅ P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0
-- 🔜 P4-02 — Scenario Authoring Draft Model V0
-- P4-03 — Event Source Authoring Draft Operations V0
+- ✅ P4-02 — Scenario Authoring Draft Model V0
+- 🔜 P4-03 — Event Source Authoring Draft Operations V0
 - P4-04 — Outcome / Battle Outcome Authoring Operations V0
 - P4-05 — Predicate / World Rule Authoring Draft V0
 - P4-06 — Narrative Validator Authoring Adapter V0
@@ -26,7 +26,9 @@ P4-00 : ✅ terminé
 
 P4-01 : ✅ terminé
 
-P4-02 : 🔜 prochain lot exact
+P4-02 : ✅ terminé
+
+P4-03 : 🔜 prochain lot exact
 
 ## 2. Objectif de la Phase 4
 
@@ -173,7 +175,7 @@ Résultat P4-01 :
 - aucun widget UI, aucun registry persistant, aucune migration, aucun runtime,
   aucun contenu Selbrume et aucun reward/money/XP créé.
 
-### 🔜 P4-02 — Scenario Authoring Draft Model V0
+### ✅ P4-02 — Scenario Authoring Draft Model V0
 
 Objectif :
 Créer ou stabiliser un draft model pur permettant de décrire un scenario minimal
@@ -188,7 +190,27 @@ Preuve concrète, pure et testée :
   conversion est prématurée ;
 - tests unitaires sans UI.
 
-### P4-03 — Event Source Authoring Draft Operations V0
+Résultat P4-02 :
+
+- rapport créé :
+  `reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md` ;
+- draft model pur ajouté dans `map_core` :
+  `NarrativeScenarioAuthoringDraft`,
+  `NarrativeScenarioAuthoringSourceDraft`,
+  `NarrativeScenarioAuthoringActionDraft` ;
+- diagnostics authoring V0 ajoutés :
+  `emptyScenarioId`, `emptyScenarioName`, `missingSource`,
+  `missingSourceReference`, `emptyActionReference`,
+  `emitOutcomeNotDeclared`, `declaredOutcomeNeverEmitted` ;
+- compilation déterministe `draft -> ScenarioAsset` ajoutée :
+  graphe linéaire `start -> source -> actions -> end`,
+  node ids et edge ids stables, outcomes déclarés conservés ;
+- tests ciblés ajoutés dans
+  `packages/map_core/test/narrative_scenario_authoring_draft_test.dart` ;
+- aucun widget UI, aucun registry persistant, aucune migration, aucun runtime,
+  aucun contenu Selbrume et aucun reward/money/XP créé.
+
+### 🔜 P4-03 — Event Source Authoring Draft Operations V0
 
 Objectif :
 Rendre authorables les sources `mapEnter`, `triggerEnter`, `entityInteract` et
@@ -306,5 +328,5 @@ Phase 4 doit produire des preuves authoring concrètes après P4-00.
 Le prochain lot exact est :
 
 ```text
-P4-02 — Scenario Authoring Draft Model V0
+P4-03 — Event Source Authoring Draft Operations V0
 ```
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index efe45483..48cb8ae9 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -71,6 +71,7 @@ export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/narrative_validator.dart';
+export 'src/authoring/narrative_scenario_authoring_draft.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/static_shadow_family_projection.dart';
```

### 11.8 Sortie complète du test ciblé final

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

### 11.9 Sortie complète des régressions ciblées

`dart test test/narrative_reference_picker_read_models_test.dart` :

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

`dart test test/narrative_validator_test.dart` :

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

### 11.10 dart analyze

```text
Analyzing map_core...
No issues found!
```

### 11.11 dart format --set-exit-if-changed

Premier passage utile :

```text
Formatted lib/src/authoring/narrative_scenario_authoring_draft.dart
Formatted test/narrative_scenario_authoring_draft_test.dart
Formatted 2 files (2 changed) in 0.01 seconds.
```

Passage final :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

### 11.12 git diff --check exact

```text

```

### 11.13 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_4.md    | 38 +++++++++++++++++++++++++++++--------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 31 insertions(+), 8 deletions(-)
```

### 11.14 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

### 11.15 git status final exact

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
?? packages/map_core/test/narrative_scenario_authoring_draft_test.dart
?? reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md
```

### 11.16 Contrôles hors scope

```text
road_map_global.md non modifié : oui.
P4-03 non exécuté : oui.
Selbrume final non créé : oui.
Aucune UI premium créée : oui.
Aucun registry persistant créé : oui.
Aucun reward/money/XP ajouté : oui.
ProjectManifest non modifié : oui.
ScenarioAsset non modifié : oui.
GameState non modifié : oui.
SaveData non modifié : oui.
map_editor non modifié : oui.
map_runtime non modifié : oui.
map_gameplay non modifié : oui.
map_battle non modifié : oui.
examples/playable_runtime_host non modifié : oui.
```

## 12. Auto-review critique

Points solides :

- P4-02 produit bien du code pur/testé, pas seulement un rapport.
- Le draft ne modifie aucune source de vérité persistante existante.
- La conversion vers `ScenarioAsset` est déterministe et compatible avec les
  strings runtime observées.
- `startTrainerBattle` reste minimal et ne lance pas rewards/money/XP.
- Les tests couvrent validation, compilation, déterminisme, immutabilité et
  absence d'IDs Selbrume.

Réserves :

- `unsupportedDraftShape` est réservé mais non utilisé en V0 ; il faudra décider
  en P4-03/P4-04 si certains shapes doivent être bloquants plutôt que hors
  modèle.
- Le draft ne valide pas les références contre un manifest. C'est volontaire :
  P4-03/P4-04 doivent ajouter les opérations branchées aux read models/pickers.
- Le graph compilé n'est pas exécuté dans runtime dans ce lot ; Phase 3 a déjà
  couvert runtime/disk, P4-02 couvre l'authoring draft pur.

## 13. Regard critique sur le prompt

Le prompt est strict et utile : il empêche de transformer P4-02 en UI ou en
Scene Builder. La tension principale est que le lot demande à la fois un draft
minimal et une conversion `ScenarioAsset`; c'est faisable ici parce que les
types de source/action V0 sont déjà stabilisés par Phase 3. La séparation reste
saine : P4-02 pose la structure, P4-03/P4-04 durciront les opérations auteur.
