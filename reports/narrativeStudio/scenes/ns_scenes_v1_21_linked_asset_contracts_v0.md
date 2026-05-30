# NS-SCENES-V1-21 — Linked Asset Contracts V0

## Resume executif

NS-SCENES-V1-21 est realise.

Le lot ajoute dans `map_core` des contrats publics/read models purs pour les assets lies au Scene Builder :

- `DialoguePublicContract`
- `BattlePublicContract`
- `CinematicPublicContract`
- `OutcomeProducerPublicContract`
- `LinkedAssetContractsSnapshot`
- diagnostics communs `LinkedAssetContractDiagnostic`

Decision principale : les futurs Payload Pickers doivent consommer ces contrats publics, pas lire directement les IDs bruts ni les details internes de Dialogue Studio, Cutscene Studio, Scenario runtime ou battle engine.

Aucun runtime, aucune UI picker, aucun modele persiste, aucun `CinematicAsset`, aucune Action Registry, aucun Event -> Scene, aucun `StorylineStep.sceneLinkIds`, aucune migration ScenarioAsset et aucune donnee Selbrume ne sont ajoutes.

Prochain lot exact recommande :

```text
NS-SCENES-V1-22 — Payload Pickers V0
```

## Design / Architecture Gate

Questions tranchees :

| Question | Decision |
|---|---|
| Quels contrats coder maintenant ? | Coder `DialoguePublicContract`, `BattlePublicContract`, `CinematicPublicContract` bridge explicite, `OutcomeProducerPublicContract` battle et `LinkedAssetContractsSnapshot`. |
| Quels contrats resteront documentaires ? | `ActionPublicContract`, `ConsequencePublicContract` et le mapping complet `OutcomeProducer -> BranchByOutcome` restent futurs. |
| Ou placer les contrats publics ? | Nouveau fichier `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`, exporte depuis `map_core.dart`. |
| Etendre `narrative_reference_picker_read_models.dart` ? | Non. Ce fichier existe deja pour des pickers narratifs legacy/Scenario. Un fichier dedie evite de melanger les futurs contrats Scene V1 avec les read models existants. |
| Comment eviter les doublons ? | Les contrats restent plus generiques et publics que les picker options existantes. Ils ne remplacent pas encore `buildNarrativeBattleReferencePickerOptions`, mais fournissent une surface future pour Payload Pickers V0. |
| Dialogue sans parser tout Yarn ? | `ProjectManifest.dialogues` donne id, name, relativePath et defaultStartNode. `availableStartNodes` reste vide et `declaredOutcomes` reste vide avec diagnostic `missingOutcomeContract`. Aucun fichier Yarn disque n'est lu. |
| Battle sans coupler `map_core` a `map_battle` ? | Le contrat lit seulement `ProjectManifest.trainers` et expose `BattlePublicContractKind.trainer` avec outcomes textuels `victory` / `defeat`. Aucun import `map_battle`. |
| Cinematic sans faire de `ScenarioAsset` le modele final ? | Le contrat ne reconnait que les scenarios marques Cutscene Studio par metadata `authoring.cutsceneSchema`; statut `bridgeOnly` et diagnostic `legacyBridge`. |
| Action / Consequence ? | Disabled. Les actions restent dispersees entre scripts, scenario runtime, facts et world rules. Pas de registry Action dans ce lot. |
| BranchByOutcome ? | Disabled. Le snapshot expose seulement des producteurs battle, mais ne cree aucun mapping outcome -> edge. |

## Scope realise

- Nouveau read model pur `linked_asset_public_contracts.dart`.
- Export public dans `map_core.dart`.
- Tests map_core dedies.
- Roadmaps mises a jour.
- Rapport de lot cree.

## Contrats codes

### DialoguePublicContract

Source : `ProjectManifest.dialogues`.

Champs exposes :

- `id`
- `label`
- `sourceRef`
- `defaultStartNode`
- `availableStartNodes`
- `declaredOutcomes`
- `diagnostics`
- `status`

Regles :

- label lisible depuis `ProjectDialogueEntry.name`;
- fallback controle sur id avec diagnostics `missingLabel` et `rawTechnicalLabel`;
- `availableStartNodes` vide en V0, car `map_core` ne parse pas les fichiers Yarn;
- `declaredOutcomes` vide en V0, diagnostic `missingOutcomeContract`;
- aucun outcome invente.

### BattlePublicContract

Source : `ProjectManifest.trainers`.

Champs exposes :

- `id`
- `battleRefId`
- `label`
- `battleKind`
- `trainerId`
- `trainerLabel`
- `possibleOutcomes`
- `diagnostics`
- `status`

Regles :

- V0 = trainer battle uniquement;
- `battleRefId = trainer:<trainerId>`;
- outcomes exposes : `victory`, `defeat`;
- warning `emptyTrainerTeam` si l'equipe trainer est vide;
- aucune dependance `map_battle`.

### CinematicPublicContract

Source : `ProjectManifest.scenarios` uniquement si metadata Cutscene Studio presente.

Champs exposes :

- `id`
- `label`
- `sourceKind`
- `status`
- `linear`
- `requiredActors`
- `mapId`
- `declaredOutputs`
- `diagnostics`

Regles :

- `sourceKind = scenarioBridge`;
- `status = bridgeOnly`;
- `linear = null` car non garanti comme contrat canonique;
- `requiredActors = []`;
- `mapId = null`;
- output expose : `completed`;
- diagnostic `legacyBridge`.

### LinkedAssetContractsSnapshot

Le snapshot agrege :

- dialogues;
- battles;
- cinematics bridge;
- outcome producers battle;
- statut `actionContractsAvailable = false`;
- statut `branchByOutcomeAvailable = false`;
- diagnostics info `unsupportedSource` pour Action/Consequence et BranchByOutcome.

## Contrats documentes seulement

`ActionPublicContract` reste futur :

```text
actionKind
label
category
inputs
writes
possibleOutcomes
diagnostics
```

`ConsequencePublicContract` reste futur :

```text
targetKind
writeKind
requiredRefs
readableLabel
diagnostics
```

Mapping complet `OutcomeProducerPublicContract -> BranchByOutcome` reste futur :

```text
producerKind
producerRef
outcomes
mapping outcomeId -> edge/target
fallbackPolicy
diagnostics
```

## Familles supportees

| Famille | Statut V1-21 | Commentaire |
|---|---|---|
| Dialogue / Yarn | supported contract | Contrat depuis manifest, sans parser Yarn disque. Outcomes non inventes. |
| Battle / Trainer | supported contract | Trainer battles uniquement, outcomes `victory` / `defeat`. |
| Cinematic / Cutscene | bridgeOnly | ScenarioAsset reconnu seulement comme bridge Cutscene Studio explicite. |
| Action / Consequence | disabled | Trop disperse, pas de registry Action V0. |
| BranchByOutcome | disabled | Outcome producers partiels, pas de mapping outcome -> edge. |

## Decisions techniques

- Nouveau fichier dedie plutot qu'extension du read model de pickers existant.
- Classes immuables manuelles, style aligne sur `narrative_reference_picker_read_models.dart`.
- Listes exposees via `List.unmodifiable`.
- Builders purs et deterministes, tri par label puis id.
- Aucun parsing disque, aucune lecture runtime, aucun import Flutter/Flame/runtime/battle.
- `CinematicPublicContract` utilise les cles metadata persistantes Cutscene Studio comme marqueur de bridge, sans importer `map_editor`.

## Fichiers crees/modifies

Fichiers crees :

```text
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/test/linked_asset_public_contracts_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
```

Fichiers modifies :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Tests executes

### Red phase TDD

Commande :

```bash
cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/linked_asset_public_contracts_test.dart
00:00 +0 -1: loading test/linked_asset_public_contracts_test.dart [E]
  Failed to load "test/linked_asset_public_contracts_test.dart":
  test/linked_asset_public_contracts_test.dart:7:25: Error: Method not found: 'buildDialoguePublicContracts'.
        final contracts = buildDialoguePublicContracts(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:28:31: Error: Undefined name 'LinkedAssetContractStatus'.
        expect(contract.status, LinkedAssetContractStatus.available);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:31:18: Error: Undefined name 'LinkedAssetContractDiagnosticCode'.
          contains(LinkedAssetContractDiagnosticCode.missingOutcomeContract),
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:37:25: Error: Method not found: 'buildDialoguePublicContracts'.
        final contracts = buildDialoguePublicContracts(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:54:11: Error: Undefined name 'LinkedAssetContractDiagnosticCode'.
            LinkedAssetContractDiagnosticCode.missingLabel,
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:55:11: Error: Undefined name 'LinkedAssetContractDiagnosticCode'.
            LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:61:25: Error: Method not found: 'buildBattlePublicContracts'.
        final contracts = buildBattlePublicContracts(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:81:35: Error: Undefined name 'BattlePublicContractKind'.
        expect(contract.battleKind, BattlePublicContractKind.trainer);
                                    ^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:84:31: Error: Undefined name 'LinkedAssetContractStatus'.
        expect(contract.status, LinkedAssetContractStatus.available);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:93:25: Error: Method not found: 'buildBattlePublicContracts'.
        final contracts = buildBattlePublicContracts(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:107:18: Error: Undefined name 'LinkedAssetContractDiagnosticCode'.
          contains(LinkedAssetContractDiagnosticCode.emptyTrainerTeam),
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:113:25: Error: Method not found: 'buildCinematicPublicContracts'.
        final contracts = buildCinematicPublicContracts(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:134:9: Error: Undefined name 'CinematicPublicContractSourceKind'.
          CinematicPublicContractSourceKind.scenarioBridge,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:136:31: Error: Undefined name 'LinkedAssetContractStatus'.
        expect(contract.status, LinkedAssetContractStatus.bridgeOnly);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:145:18: Error: Undefined name 'LinkedAssetContractDiagnosticCode'.
          contains(LinkedAssetContractDiagnosticCode.legacyBridge),
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:150:25: Error: Method not found: 'buildCinematicPublicContracts'.
        final contracts = buildCinematicPublicContracts(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:167:24: Error: Method not found: 'buildLinkedAssetContractsSnapshot'.
        final snapshot = buildLinkedAssetContractsSnapshot(
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:216:18: Error: Undefined name 'LinkedAssetContractDiagnosticCode'.
          contains(LinkedAssetContractDiagnosticCode.unsupportedSource),
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:237:21: Error: Method not found: 'buildDialoguePublicContracts'.
        final first = buildDialoguePublicContracts(manifest);
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/linked_asset_public_contracts_test.dart:238:22: Error: Method not found: 'buildDialoguePublicContracts'.
        final second = buildDialoguePublicContracts(manifest);
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Some tests failed.
```

La phase rouge prouve que les tests ciblaient bien les nouveaux symboles non encore implementes.

### Test cible final

Commande :

```bash
cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/linked_asset_public_contracts_test.dart
00:00 +0: Linked asset public contracts builds dialogue contracts from manifest dialogues
00:00 +1: Linked asset public contracts builds dialogue contracts from manifest dialogues
00:00 +1: Linked asset public contracts reports a diagnostic when dialogue label falls back to technical id
00:00 +2: Linked asset public contracts reports a diagnostic when dialogue label falls back to technical id
00:00 +2: Linked asset public contracts builds trainer battle contracts without exposing map_battle types
00:00 +3: Linked asset public contracts builds trainer battle contracts without exposing map_battle types
00:00 +3: Linked asset public contracts warns when a trainer battle has an empty team
00:00 +4: Linked asset public contracts warns when a trainer battle has an empty team
00:00 +4: Linked asset public contracts builds cinematic scenario bridge contracts from cutscene metadata
00:00 +5: Linked asset public contracts builds cinematic scenario bridge contracts from cutscene metadata
00:00 +5: Linked asset public contracts does not expose regular scenarios as cinematic contracts
00:00 +6: Linked asset public contracts does not expose regular scenarios as cinematic contracts
00:00 +6: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled
00:00 +7: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled
00:00 +7: Linked asset public contracts builders are deterministic and do not mutate the manifest
00:00 +8: Linked asset public contracts builders are deterministic and do not mutate the manifest
00:00 +8: All tests passed!
```

### Analyze final

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## Git status initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sorties exactes :

```text
/Users/karim/Project/pokemonProject
main
Sortie git status initial : <vide>
Sortie git diff --stat initial : <vide>
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
```

## Git status final

Etat capture avant le dernier `git diff --check` :

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
?? packages/map_core/test/linked_asset_public_contracts_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
```

## Git diff --stat final

Etat capture avant le dernier `git diff --check` :

```text
 packages/map_core/lib/map_core.dart                  |  1 +
 .../scenes/road_map_scene_builder_authoring.md       | 14 ++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md    | 20 ++++++++++++++++----
 3 files changed, 29 insertions(+), 6 deletions(-)
```

Note : `git diff --stat` n'inclut pas les fichiers non suivis tant qu'ils ne sont pas indexes par Git.

## Git diff --name-only final

Etat capture avant le dernier `git diff --check` :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` n'inclut pas les fichiers non suivis tant qu'ils ne sont pas indexes par Git.

## Git diff --check final

Sortie exacte :

```text
Sortie : <vide>
```

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
```

### Liste des fichiers lus

Tous les chemins attendus ci-dessous etaient presents.

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_prep_linked_asset_public_contracts_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_flow.dart
packages/map_runtime/lib/src/application/trainer_battle_request.dart
packages/map_runtime/lib/src/application/battle_start_request.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_battle/lib/map_battle.dart
```

### Contenu complet de `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import '../models/scenario_asset.dart';

const String _cutsceneStudioSchemaMetadataKey = 'authoring.cutsceneSchema';
const String _completedOutcomeId = 'completed';
const String _victoryOutcomeId = 'victory';
const String _defeatOutcomeId = 'defeat';

enum LinkedAssetContractDiagnosticSeverity {
  info,
  warning,
  error,
}

enum LinkedAssetContractDiagnosticCode {
  missingRef,
  unknownRef,
  missingLabel,
  rawTechnicalLabel,
  missingOutcomeContract,
  legacyBridge,
  unsupportedSource,
  emptyTrainerTeam,
}

enum LinkedAssetContractStatus {
  available,
  bridgeOnly,
  unavailable,
}

enum BattlePublicContractKind {
  trainer,
}

enum CinematicPublicContractSourceKind {
  scenarioBridge,
}

enum OutcomeProducerPublicContractKind {
  battle,
}

@immutable
final class LinkedAssetContractDiagnostic {
  const LinkedAssetContractDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.sourceId,
  });

  final LinkedAssetContractDiagnosticCode code;
  final LinkedAssetContractDiagnosticSeverity severity;
  final String message;
  final String? sourceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedAssetContractDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(code, severity, message, sourceId);
}

@immutable
final class LinkedAssetOutcomeContract {
  const LinkedAssetOutcomeContract({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedAssetOutcomeContract &&
          other.id == id &&
          other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

@immutable
final class DialoguePublicContract {
  DialoguePublicContract({
    required this.id,
    required this.label,
    required this.sourceRef,
    required this.defaultStartNode,
    required List<String> availableStartNodes,
    required List<LinkedAssetOutcomeContract> declaredOutcomes,
    required List<LinkedAssetContractDiagnostic> diagnostics,
    required this.status,
  })  : availableStartNodes = List<String>.unmodifiable(availableStartNodes),
        declaredOutcomes =
            List<LinkedAssetOutcomeContract>.unmodifiable(declaredOutcomes),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final String sourceRef;
  final String? defaultStartNode;
  final List<String> availableStartNodes;
  final List<LinkedAssetOutcomeContract> declaredOutcomes;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final LinkedAssetContractStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialoguePublicContract &&
          other.id == id &&
          other.label == label &&
          other.sourceRef == sourceRef &&
          other.defaultStartNode == defaultStartNode &&
          _listEquals(other.availableStartNodes, availableStartNodes) &&
          _listEquals(other.declaredOutcomes, declaredOutcomes) &&
          _listEquals(other.diagnostics, diagnostics) &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        sourceRef,
        defaultStartNode,
        Object.hashAll(availableStartNodes),
        Object.hashAll(declaredOutcomes),
        Object.hashAll(diagnostics),
        status,
      );
}

@immutable
final class BattlePublicContract {
  BattlePublicContract({
    required this.id,
    required this.battleRefId,
    required this.label,
    required this.battleKind,
    required this.trainerId,
    required this.trainerLabel,
    required List<LinkedAssetOutcomeContract> possibleOutcomes,
    required List<LinkedAssetContractDiagnostic> diagnostics,
    required this.status,
  })  : possibleOutcomes =
            List<LinkedAssetOutcomeContract>.unmodifiable(possibleOutcomes),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String battleRefId;
  final String label;
  final BattlePublicContractKind battleKind;
  final String trainerId;
  final String trainerLabel;
  final List<LinkedAssetOutcomeContract> possibleOutcomes;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final LinkedAssetContractStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattlePublicContract &&
          other.id == id &&
          other.battleRefId == battleRefId &&
          other.label == label &&
          other.battleKind == battleKind &&
          other.trainerId == trainerId &&
          other.trainerLabel == trainerLabel &&
          _listEquals(other.possibleOutcomes, possibleOutcomes) &&
          _listEquals(other.diagnostics, diagnostics) &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        id,
        battleRefId,
        label,
        battleKind,
        trainerId,
        trainerLabel,
        Object.hashAll(possibleOutcomes),
        Object.hashAll(diagnostics),
        status,
      );
}

@immutable
final class CinematicPublicContract {
  CinematicPublicContract({
    required this.id,
    required this.label,
    required this.sourceKind,
    required this.status,
    required this.linear,
    required List<String> requiredActors,
    required this.mapId,
    required List<LinkedAssetOutcomeContract> declaredOutputs,
    required List<LinkedAssetContractDiagnostic> diagnostics,
  })  : requiredActors = List<String>.unmodifiable(requiredActors),
        declaredOutputs =
            List<LinkedAssetOutcomeContract>.unmodifiable(declaredOutputs),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final CinematicPublicContractSourceKind sourceKind;
  final LinkedAssetContractStatus status;
  final bool? linear;
  final List<String> requiredActors;
  final String? mapId;
  final List<LinkedAssetOutcomeContract> declaredOutputs;
  final List<LinkedAssetContractDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPublicContract &&
          other.id == id &&
          other.label == label &&
          other.sourceKind == sourceKind &&
          other.status == status &&
          other.linear == linear &&
          _listEquals(other.requiredActors, requiredActors) &&
          other.mapId == mapId &&
          _listEquals(other.declaredOutputs, declaredOutputs) &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        sourceKind,
        status,
        linear,
        Object.hashAll(requiredActors),
        mapId,
        Object.hashAll(declaredOutputs),
        Object.hashAll(diagnostics),
      );
}

@immutable
final class OutcomeProducerPublicContract {
  OutcomeProducerPublicContract({
    required this.producerKind,
    required this.producerRef,
    required this.label,
    required this.status,
    required List<LinkedAssetOutcomeContract> outcomes,
    required List<LinkedAssetContractDiagnostic> diagnostics,
  })  : outcomes = List<LinkedAssetOutcomeContract>.unmodifiable(outcomes),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final OutcomeProducerPublicContractKind producerKind;
  final String producerRef;
  final String label;
  final LinkedAssetContractStatus status;
  final List<LinkedAssetOutcomeContract> outcomes;
  final List<LinkedAssetContractDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutcomeProducerPublicContract &&
          other.producerKind == producerKind &&
          other.producerRef == producerRef &&
          other.label == label &&
          other.status == status &&
          _listEquals(other.outcomes, outcomes) &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        producerKind,
        producerRef,
        label,
        status,
        Object.hashAll(outcomes),
        Object.hashAll(diagnostics),
      );
}

@immutable
final class LinkedAssetContractsSnapshot {
  LinkedAssetContractsSnapshot({
    required List<DialoguePublicContract> dialogues,
    required List<BattlePublicContract> battles,
    required List<CinematicPublicContract> cinematics,
    required List<OutcomeProducerPublicContract> outcomeProducers,
    required this.actionContractsAvailable,
    required this.branchByOutcomeAvailable,
    required List<LinkedAssetContractDiagnostic> diagnostics,
  })  : dialogues = List<DialoguePublicContract>.unmodifiable(dialogues),
        battles = List<BattlePublicContract>.unmodifiable(battles),
        cinematics = List<CinematicPublicContract>.unmodifiable(cinematics),
        outcomeProducers =
            List<OutcomeProducerPublicContract>.unmodifiable(outcomeProducers),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final List<DialoguePublicContract> dialogues;
  final List<BattlePublicContract> battles;
  final List<CinematicPublicContract> cinematics;
  final List<OutcomeProducerPublicContract> outcomeProducers;
  final bool actionContractsAvailable;
  final bool branchByOutcomeAvailable;
  final List<LinkedAssetContractDiagnostic> diagnostics;
}

List<DialoguePublicContract> buildDialoguePublicContracts(
  ProjectManifest project,
) {
  final contracts = project.dialogues.map((entry) {
    final id = entry.id.trim();
    final label = _labelOrId(entry.name, id);
    final diagnostics = <LinkedAssetContractDiagnostic>[
      ..._labelDiagnostics(
        rawLabel: entry.name,
        fallbackId: id,
        sourceId: id,
      ),
      const LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.missingOutcomeContract,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'Dialogue outcomes are not exposed by a public contract yet.',
      ),
    ];
    if (id.isEmpty) {
      diagnostics.add(
        const LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.missingRef,
          severity: LinkedAssetContractDiagnosticSeverity.error,
          message: 'Dialogue id is required for a stable Scene reference.',
        ),
      );
    }

    return DialoguePublicContract(
      id: id,
      label: label,
      sourceRef: entry.relativePath.trim(),
      defaultStartNode: _trimOrNull(entry.defaultStartNode),
      availableStartNodes: const [],
      declaredOutcomes: const [],
      diagnostics: diagnostics,
      status: id.isEmpty
          ? LinkedAssetContractStatus.unavailable
          : LinkedAssetContractStatus.available,
    );
  }).toList(growable: false);

  contracts.sort(
    _compareByLabelThen(
      (contract) => contract.label,
      (contract) => contract.id,
    ),
  );
  return List<DialoguePublicContract>.unmodifiable(contracts);
}
```

Suite du meme fichier :

```dart
List<BattlePublicContract> buildBattlePublicContracts(ProjectManifest project) {
  final contracts = project.trainers.map((trainer) {
    final trainerId = trainer.id.trim();
    final trainerLabel = _labelOrId(trainer.name, trainerId);
    final battleRefId = 'trainer:$trainerId';
    final label = _battleLabel(trainer, trainerLabel, trainerId);
    final diagnostics = <LinkedAssetContractDiagnostic>[
      ..._labelDiagnostics(
        rawLabel: trainer.name,
        fallbackId: trainerId,
        sourceId: trainerId,
      ),
    ];
    if (trainerId.isEmpty) {
      diagnostics.add(
        const LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.missingRef,
          severity: LinkedAssetContractDiagnosticSeverity.error,
          message: 'Trainer id is required for a stable battle reference.',
        ),
      );
    }
    if (trainer.team.isEmpty) {
      diagnostics.add(
        LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.emptyTrainerTeam,
          severity: LinkedAssetContractDiagnosticSeverity.warning,
          message: 'Trainer battle has no authored team yet.',
          sourceId: trainerId.isEmpty ? null : trainerId,
        ),
      );
    }

    return BattlePublicContract(
      id: battleRefId,
      battleRefId: battleRefId,
      label: label,
      battleKind: BattlePublicContractKind.trainer,
      trainerId: trainerId,
      trainerLabel: trainerLabel,
      possibleOutcomes: const [
        LinkedAssetOutcomeContract(
          id: _victoryOutcomeId,
          label: 'Victory',
        ),
        LinkedAssetOutcomeContract(
          id: _defeatOutcomeId,
          label: 'Defeat',
        ),
      ],
      diagnostics: diagnostics,
      status: trainerId.isEmpty
          ? LinkedAssetContractStatus.unavailable
          : LinkedAssetContractStatus.available,
    );
  }).toList(growable: false);

  contracts.sort(
    _compareByLabelThen(
      (contract) => contract.label,
      (contract) => contract.id,
    ),
  );
  return List<BattlePublicContract>.unmodifiable(contracts);
}

List<CinematicPublicContract> buildCinematicPublicContracts(
  ProjectManifest project,
) {
  final contracts = <CinematicPublicContract>[];
  for (final scenario in project.scenarios) {
    if (!_isCutsceneStudioScenarioBridge(scenario)) {
      continue;
    }
    final id = scenario.id.trim();
    final label = _labelOrId(scenario.name, id);
    final diagnostics = <LinkedAssetContractDiagnostic>[
      ..._labelDiagnostics(
        rawLabel: scenario.name,
        fallbackId: id,
        sourceId: id,
      ),
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.legacyBridge,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message:
            'This cinematic contract is a ScenarioAsset bridge, not a canonical CinematicAsset.',
        sourceId: id,
      ),
    ];
    if (id.isEmpty) {
      diagnostics.add(
        const LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.missingRef,
          severity: LinkedAssetContractDiagnosticSeverity.error,
          message:
              'Scenario id is required for a stable cinematic bridge reference.',
        ),
      );
    }

    contracts.add(
      CinematicPublicContract(
        id: id,
        label: label,
        sourceKind: CinematicPublicContractSourceKind.scenarioBridge,
        status: LinkedAssetContractStatus.bridgeOnly,
        linear: null,
        requiredActors: const [],
        mapId: null,
        declaredOutputs: const [
          LinkedAssetOutcomeContract(
            id: _completedOutcomeId,
            label: 'Completed',
          ),
        ],
        diagnostics: diagnostics,
      ),
    );
  }

  contracts.sort(
    _compareByLabelThen(
      (contract) => contract.label,
      (contract) => contract.id,
    ),
  );
  return List<CinematicPublicContract>.unmodifiable(contracts);
}

LinkedAssetContractsSnapshot buildLinkedAssetContractsSnapshot(
  ProjectManifest project,
) {
  final dialogues = buildDialoguePublicContracts(project);
  final battles = buildBattlePublicContracts(project);
  final cinematics = buildCinematicPublicContracts(project);
  final outcomeProducers = <OutcomeProducerPublicContract>[
    for (final battle in battles)
      OutcomeProducerPublicContract(
        producerKind: OutcomeProducerPublicContractKind.battle,
        producerRef: battle.battleRefId,
        label: battle.label,
        status: battle.status,
        outcomes: battle.possibleOutcomes,
        diagnostics: battle.diagnostics,
      ),
  ];

  final diagnostics = <LinkedAssetContractDiagnostic>[
    const LinkedAssetContractDiagnostic(
      code: LinkedAssetContractDiagnosticCode.unsupportedSource,
      severity: LinkedAssetContractDiagnosticSeverity.info,
      message:
          'Action/Consequence public contracts are not available in V0; ActionNode remains disabled.',
      sourceId: 'action',
    ),
    const LinkedAssetContractDiagnostic(
      code: LinkedAssetContractDiagnosticCode.unsupportedSource,
      severity: LinkedAssetContractDiagnosticSeverity.info,
      message:
          'BranchByOutcome remains disabled until outcome producers and mappings are explicit.',
      sourceId: 'branchByOutcome',
    ),
  ];

  return LinkedAssetContractsSnapshot(
    dialogues: dialogues,
    battles: battles,
    cinematics: cinematics,
    outcomeProducers: outcomeProducers,
    actionContractsAvailable: false,
    branchByOutcomeAvailable: false,
    diagnostics: diagnostics,
  );
}

String _battleLabel(
  ProjectTrainerEntry trainer,
  String trainerLabel,
  String trainerId,
) {
  final trainerClass = trainer.trainerClass.trim();
  if (trainerClass.isEmpty) {
    return trainerLabel;
  }
  if (trainerLabel == trainerId) {
    return trainerClass;
  }
  return '$trainerClass $trainerLabel';
}

bool _isCutsceneStudioScenarioBridge(ScenarioAsset scenario) {
  final schemaVersion =
      scenario.metadata[_cutsceneStudioSchemaMetadataKey]?.trim();
  return schemaVersion != null && schemaVersion.isNotEmpty;
}

List<LinkedAssetContractDiagnostic> _labelDiagnostics({
  required String rawLabel,
  required String fallbackId,
  required String sourceId,
}) {
  final trimmedLabel = rawLabel.trim();
  final diagnostics = <LinkedAssetContractDiagnostic>[];
  if (trimmedLabel.isEmpty) {
    diagnostics.add(
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.missingLabel,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'Readable label is missing; technical id is used as fallback.',
        sourceId: sourceId.isEmpty ? null : sourceId,
      ),
    );
    diagnostics.add(
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'The public contract label falls back to a technical id.',
        sourceId: sourceId.isEmpty ? null : sourceId,
      ),
    );
  } else if (trimmedLabel == fallbackId && fallbackId.isNotEmpty) {
    diagnostics.add(
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'Readable label matches the technical id.',
        sourceId: sourceId,
      ),
    );
  }
  return diagnostics;
}

String _labelOrId(String label, String fallbackId) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isNotEmpty) {
    return trimmedLabel;
  }
  return fallbackId;
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

int Function(T, T) _compareByLabelThen<T>(
  String Function(T value) labelOf,
  String Function(T value) idOf,
) {
  return (a, b) {
    final byLabel = _compareStringsCaseInsensitive(labelOf(a), labelOf(b));
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(idOf(a), idOf(b));
  };
}

int _compareStringsCaseInsensitive(String a, String b) {
  final lowerA = a.toLowerCase();
  final lowerB = b.toLowerCase();
  final byLower = lowerA.compareTo(lowerB);
  if (byLower != 0) {
    return byLower;
  }
  return a.compareTo(b);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
```

### Contenu complet de `packages/map_core/test/linked_asset_public_contracts_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Linked asset public contracts', () {
    test('builds dialogue contracts from manifest dialogues', () {
      final contracts = buildDialoguePublicContracts(
        _manifest(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_intro',
              name: 'Introduction',
              relativePath: 'dialogues/intro.yarn',
              defaultStartNode: 'Start',
            ),
          ],
        ),
      );

      expect(contracts, hasLength(1));
      final contract = contracts.single;
      expect(contract.id, 'dialogue_intro');
      expect(contract.label, 'Introduction');
      expect(contract.sourceRef, 'dialogues/intro.yarn');
      expect(contract.defaultStartNode, 'Start');
      expect(contract.availableStartNodes, isEmpty);
      expect(contract.declaredOutcomes, isEmpty);
      expect(contract.status, LinkedAssetContractStatus.available);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.missingOutcomeContract),
      );
    });

    test('reports a diagnostic when dialogue label falls back to technical id',
        () {
      final contracts = buildDialoguePublicContracts(
        _manifest(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_intro',
              name: '   ',
              relativePath: 'dialogues/intro.yarn',
            ),
          ],
        ),
      );

      final contract = contracts.single;
      expect(contract.label, 'dialogue_intro');
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          LinkedAssetContractDiagnosticCode.missingLabel,
          LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
        ]),
      );
    });

    test('builds trainer battle contracts without exposing map_battle types',
        () {
      final contracts = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_scout',
              name: 'Mina',
              trainerClass: 'Scout',
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
              ],
            ),
          ],
        ),
      );

      expect(contracts, hasLength(1));
      final contract = contracts.single;
      expect(contract.id, 'trainer:trainer_scout');
      expect(contract.battleRefId, 'trainer:trainer_scout');
      expect(contract.label, 'Scout Mina');
      expect(contract.battleKind, BattlePublicContractKind.trainer);
      expect(contract.trainerId, 'trainer_scout');
      expect(contract.trainerLabel, 'Mina');
      expect(contract.status, LinkedAssetContractStatus.available);
      expect(contract.possibleOutcomes.map((outcome) => outcome.id), [
        'victory',
        'defeat',
      ]);
      expect(contract.diagnostics, isEmpty);
    });

    test('warns when a trainer battle has an empty team', () {
      final contracts = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_empty',
              name: 'Noa',
              trainerClass: 'Guide',
            ),
          ],
        ),
      );

      expect(
        contracts.single.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.emptyTrainerTeam),
      );
    });

    test('builds cinematic scenario bridge contracts from cutscene metadata',
        () {
      final contracts = buildCinematicPublicContracts(
        _manifest(
          scenarios: const [
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Bridge Cutscene',
              entryNodeId: 'start',
              metadata: {
                'authoring.cutsceneSchema': 'cutscene_studio_v2',
              },
            ),
          ],
        ),
      );

      expect(contracts, hasLength(1));
      final contract = contracts.single;
      expect(contract.id, 'scenario_cutscene');
      expect(contract.label, 'Bridge Cutscene');
      expect(
        contract.sourceKind,
        CinematicPublicContractSourceKind.scenarioBridge,
      );
      expect(contract.status, LinkedAssetContractStatus.bridgeOnly);
      expect(contract.linear, isNull);
      expect(contract.requiredActors, isEmpty);
      expect(contract.mapId, isNull);
      expect(contract.declaredOutputs.map((outcome) => outcome.id), [
        'completed',
      ]);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.legacyBridge),
      );
    });

    test('does not expose regular scenarios as cinematic contracts', () {
      final contracts = buildCinematicPublicContracts(
        _manifest(
          scenarios: const [
            ScenarioAsset(
              id: 'regular_scenario',
              name: 'Regular Scenario',
              entryNodeId: 'start',
            ),
          ],
        ),
      );

      expect(contracts, isEmpty);
    });

    test('snapshot aggregates contracts and keeps action and branch disabled',
        () {
      final snapshot = buildLinkedAssetContractsSnapshot(
        _manifest(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_intro',
              name: 'Introduction',
              relativePath: 'dialogues/intro.yarn',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_scout',
              name: 'Mina',
              trainerClass: 'Scout',
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
              ],
            ),
          ],
          scenarios: const [
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Bridge Cutscene',
              entryNodeId: 'start',
              metadata: {
                'authoring.cutsceneSchema': 'cutscene_studio_v2',
              },
            ),
          ],
        ),
      );

      expect(snapshot.dialogues.map((contract) => contract.id), [
        'dialogue_intro',
      ]);
      expect(snapshot.battles.map((contract) => contract.id), [
        'trainer:trainer_scout',
      ]);
      expect(snapshot.cinematics.map((contract) => contract.id), [
        'scenario_cutscene',
      ]);
      expect(snapshot.actionContractsAvailable, isFalse);
      expect(snapshot.branchByOutcomeAvailable, isFalse);
      expect(
        snapshot.outcomeProducers.map((producer) => producer.producerRef),
        contains('trainer:trainer_scout'),
      );
      expect(
        snapshot.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.unsupportedSource),
      );
    });

    test('builders are deterministic and do not mutate the manifest', () {
      final manifest = _manifest(
        dialogues: const [
          ProjectDialogueEntry(
            id: 'z_dialogue',
            name: 'Zeta',
            relativePath: 'dialogues/z.yarn',
          ),
          ProjectDialogueEntry(
            id: 'a_dialogue',
            name: 'Alpha',
            relativePath: 'dialogues/a.yarn',
          ),
        ],
      );
      final originalDialogues = manifest.dialogues;

      final first = buildDialoguePublicContracts(manifest);
      final second = buildDialoguePublicContracts(manifest);

      expect(first.map((contract) => contract.id), [
        'a_dialogue',
        'z_dialogue',
      ]);
      expect(second, first);
      expect(manifest.dialogues, originalDialogues);
    });
  });
}

ProjectManifest _manifest({
  List<ProjectDialogueEntry> dialogues = const [],
  List<ProjectTrainerEntry> trainers = const [],
  List<ScenarioAsset> scenarios = const [],
}) {
  return ProjectManifest(
    name: 'Linked Asset Contract Test Project',
    maps: const [],
    tilesets: const [],
    dialogues: dialogues,
    trainers: trainers,
    scenarios: scenarios,
  );
}
```

### Contenu complet de `reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md`

Le contenu complet du rapport cree est le present document.

### Diff complet de `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 8555f81b..e95acdf3 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -87,6 +87,7 @@ export 'src/authoring/world_rule_authoring_operations.dart';
 export 'src/authoring/narrative_validator_authoring_adapter.dart';
 export 'src/authoring/storyline_legacy_import_preview.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
+export 'src/read_models/linked_asset_public_contracts.dart';
 export 'src/projection/world_rule_projection.dart';
 export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/static_shadow_family_projection.dart';
```

### Diff complet de `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index adfd6fae..84f851e2 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-21 — Linked Asset Contracts V0
+NS-SCENES-V1-22 — Payload Pickers V0
 ```
@@ -42,7 +42,7 @@ NS-SCENES-V1-21 — Linked Asset Contracts V0
-| NS-SCENES-V1-21 | Linked Asset Contracts V0 | core / doc | Formaliser les contrats/read models publics minimaux consommes par Scene Builder : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes. | Pas de runtime, pas de UI picker complet, pas de CinematicAsset final improvise, pas de ScenarioAsset canonique pour Scene. | read models/contract docs selon decision, diagnostics refs si bornes. | Tests contrats/read models purs si code ; sinon `git diff --check`. | Sur-modeliser ; exposer trop d'internals ; retarder inutilement Yarn/Battle prets. | Scene Builder sait ce qu'il peut afficher/brancher/diagnostiquer sans lire l'interne complet des assets. | V1-21-prep. |
+| NS-SCENES-V1-21 | Linked Asset Contracts V0 | core / doc | Formaliser les contrats/read models publics minimaux consommes par Scene Builder : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes. | Pas de runtime, pas de UI picker complet, pas de CinematicAsset final improvise, pas de ScenarioAsset canonique pour Scene. | read models/contract docs selon decision, diagnostics refs si bornes. | DONE : tests contrats/read models purs + `dart analyze`. | Sur-modeliser ; exposer trop d'internals ; retarder inutilement Yarn/Battle prets. | DONE : Dialogue/Battle/Cinematic bridge exposent contrats publics ; Action/Branch restent disabled. | V1-21-prep. |
@@ -225,6 +225,16 @@ Limites : aucun code, widget, modele, test, build_runner, runtime, Event -> Scen
 
 Prochain lot exact : `NS-SCENES-V1-21 — Linked Asset Contracts V0`.
 
+## Mise a jour V1-21
+
+Statut : `NS-SCENES-V1-21 — Linked Asset Contracts V0` est DONE.
+
+Decision : V1-21 ajoute un read model public pur dans `map_core` pour que les futurs pickers Scene Builder ne lisent pas directement des IDs bruts ni des details internes. `DialoguePublicContract` expose les dialogues du manifest avec label/source/start node et diagnostic d'outcomes absents. `BattlePublicContract` expose uniquement les trainer battles depuis `ProjectManifest.trainers`, avec outcomes `victory` / `defeat`, sans importer `map_battle`. `CinematicPublicContract` existe seulement comme bridge explicite `scenarioBridge` pour les scenarios marques Cutscene Studio, avec statut `bridgeOnly` et diagnostic `legacyBridge`.
+
+Limites : pas de Payload Picker UI, pas de runtime, pas de `CinematicAsset`, pas d'Action Registry, pas de Consequence authoring, pas de BranchByOutcome mapping, pas d'Event -> Scene, pas de StorylineStep link et aucune donnee Selbrume.
+
+Prochain lot exact : `NS-SCENES-V1-22 — Payload Pickers V0`.
```

### Diff complet de `reports/narrativeStudio/scenes/road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index bde3b56e..fe580d69 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -63,7 +63,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
-| NS-SCENES-V1-21 — Linked Asset Contracts V0 | TODO | Formaliser les contrats/read models publics minimaux des assets lies : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes, sans runtime. |
+| NS-SCENES-V1-21 — Linked Asset Contracts V0 | DONE | Contrats/read models publics minimaux dans `map_core` : Dialogue, Battle trainer, Cinematic scenarioBridge, snapshot agrege, diagnostics, statuts et outcomes disponibles, sans runtime ni UI picker. |
@@ -75,14 +75,26 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 ## Prochain lot recommande
 
-`NS-SCENES-V1-21 — Linked Asset Contracts V0`
+`NS-SCENES-V1-22 — Payload Pickers V0`
 
-Raison : le checkpoint V1-20 confirme que le Scene Builder doit maintenant pointer vers de vrais contenus metier. L'audit V1-21-prep precise cependant qu'un picker direct risquerait de redevenir un selecteur d'ID brut tant que Dialogue, Cinematic, Battle, Action et BranchByOutcome n'exposent pas un contrat public minimal lisible par Scene Builder : label, existence, statut, diagnostics, outputs/outcomes et contraintes. Le prochain blocage produit est donc de cadrer/produire ces contrats publics avant l'UI de pickers.
+Raison : V1-21 a produit les contrats publics minimaux que les futurs pickers doivent consommer. Le Scene Builder peut maintenant lire des refs stables, labels, statuts, diagnostics et outcomes disponibles pour Dialogue, Battle trainer et Cinematic bridge explicite, sans ouvrir les entrailles des assets. Le prochain blocage produit redevient donc l'UI de pickers/drafts honnetes pour configurer les payloads metier sans IDs bruts ni fake refs.
 
-Ordre corrige : Linked Asset Contracts V0, puis Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
 
 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
+## Decisions V1-21
+
+- `DialoguePublicContract` est code depuis `ProjectManifest.dialogues` : id stable, label lisible, sourceRef, defaultStartNode, start nodes disponibles vides sans parsing disque, outcomes non inventes et diagnostic `missingOutcomeContract`.
+- `BattlePublicContract` est code depuis `ProjectManifest.trainers` : battleRef `trainer:<trainerId>`, label lisible, battleKind `trainer`, trainerId/trainerLabel, outcomes standards `victory` / `defeat`, warning si equipe vide, sans dependance `map_battle`.
+- `CinematicPublicContract` est code uniquement comme `scenarioBridge` pour les `ScenarioAsset` marques par metadata Cutscene Studio ; statut `bridgeOnly`, output `completed`, diagnostic `legacyBridge`, aucun `CinematicAsset` final improvise.
+- `LinkedAssetContractsSnapshot` agrege dialogues, battles, cinematics et producteurs d'outcomes battle, mais garde `ActionNode` et `BranchByOutcome` disabled.
+- `ActionPublicContract`, `ConsequencePublicContract` et le mapping complet `OutcomeProducer -> BranchByOutcome` restent documentes/futurs ; aucune registry Action ou Consequence n'est creee.
+- Aucun runtime, UI picker, Event -> Scene, StorylineStep link, migration ScenarioAsset, fake data ou donnee Selbrume n'est ajoute.
+- Tests executes : `cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart` puis `cd packages/map_core && dart analyze`.
+
+Prochain lot exact : `NS-SCENES-V1-22 — Payload Pickers V0`.
```

## Auto-review critique

- Ce qui est prouve : les builders publics Dialogue/Battle/Cinematic/snapshot existent, sont exportes, passent les tests ciblés, restent purs, deterministes et ne mutent pas le manifest.
- Ce qui est volontairement non fait : aucune UI de picker, aucune activation de node metier, aucun runtime, aucune Action Registry, aucun CinematicAsset canonique.
- Risque restant : `CinematicPublicContract` reconnait un bridge ScenarioAsset par metadata persistante sans parser le flow Cutscene Studio. C'est intentionnel pour V0, mais V1-22 devra afficher ce statut `bridgeOnly` de facon tres claire.
- Risque restant : `OutcomeProducerPublicContract` couvre seulement les battles trainer fiables ; BranchByOutcome reste disabled tant que les mappings outcome -> edge n'existent pas.
- Verification : test cible et `dart analyze` map_core passent.

## Regard critique sur le prompt

Le prompt etait bien cadre : il separait clairement contrat public et picker UI, et il insistait sur le piege `Asset -> ID brut`. Le point difficile est l'exigence Evidence Pack tres large pour un lot de code relativement petit : elle cree une duplication importante dans le rapport. La contrainte reste utile car elle force a prouver que `ScenarioAsset` n'est pas transforme en Cinematic canonique et que `map_battle` / runtime ne sont pas importes.
