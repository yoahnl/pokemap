# P4-04 — Outcome / Battle Outcome Authoring Operations V0

## 1. Résumé exécutif

P4-04 est validable.

Le lot ajoute une couche authoring pure dans `map_core` pour authorer les outcomes scénario et les battle outcomes sans UI, sans registry persistant et sans modifier les modèles persistants.

Preuve obtenue :

- un draft peut recevoir un `declaredOutcome` dédupliqué sans mutation ;
- un draft peut recevoir une action `emitOutcome` sans auto-déclaration implicite ;
- `emitOutcome` non déclaré et `declaredOutcome` jamais émis produisent des diagnostics authoring ;
- une `NarrativeOutcomePickerOption` peut produire une source draft `outcomeReceived` ;
- un draft `outcomeReceived + setFlag` compile en `ScenarioAsset` avec `sourceOutcome` ;
- une `NarrativeBattleReferencePickerOption` peut produire une action `startTrainerBattle` ;
- un draft `entityInteract + startTrainerBattle` compile avec `battleId`, `trainerId` et `npcEntityId` ;
- les helpers `scenario.outcome.*` et `battle:*` sont séparés et testés ;
- les erreurs de battle reference et de confusion scenario/battle sont diagnostiquées.

Le prochain lot exact est :

```text
P4-05 — Predicate / World Rule Authoring Draft V0
```

## 2. Scope du lot

Inclus :

- opérations outcome authoring pures ;
- opérations battle outcome authoring pures ;
- helpers de flags runtime narratifs ;
- diagnostics authoring Outcome/Battle V0 ;
- export public depuis `map_core.dart` ;
- tests unitaires ciblés ;
- mise à jour de `MVP Selbrume/road_map_phase_4.md` ;
- rapport et Evidence Pack.

Exclus :

- UI, widget Flutter, Outcome Builder UI, Battle Builder UI ;
- OutcomeRegistry, BattleRegistry, EventRegistry, FactRegistry, WorldRuleRegistry ;
- modification de `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData` ;
- migration JSON ;
- runtime, host, editor UI ;
- Selbrume final ;
- rewards, money, XP, level-up ;
- P4-05.

## 3. Sources lues

Fichiers principaux lus :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_4.md`
- `reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md`
- `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- `packages/map_core/test/narrative_scenario_authoring_draft_test.dart`
- `packages/map_core/lib/map_core.dart`

Observations utiles :

- P4-01 expose `NarrativeOutcomePickerOption`,
  `NarrativeBattleReferencePickerOption`, `NarrativeBattleOutcomeKind`,
  `buildNarrativeOutcomePickerOptions(...)` et
  `buildNarrativeBattleReferencePickerOptions(...)`.
- P4-02 expose le draft et les actions `emitOutcome` /
  `startTrainerBattle`, plus la compilation vers `ScenarioAsset`.
- P4-03 expose les opérations Event Source et confirme que `outcomeReceived`
  correspond au source node runtime `sourceOutcome`.
- `NarrativeBattleReferencePickerOption` porte déjà `battleId`, `trainerId`,
  `npcEntityId` et les outcome kinds `victory` / `defeat`.

## 4. Opérations Outcome ajoutées

Fichier créé :

```text
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
```

APIs outcome ajoutées :

```text
addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(...)
addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(...)
createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(...)
narrativeScenarioOutcomeFlagReference(...)
validateNarrativeOutcomeAuthoringDraft(...)
```

Comportement :

- les outcome ids sont trimés ;
- les ids vides sont refusés par les helpers directs ou diagnostiqués par le validator ;
- `declaredOutcomes` est dédupliqué en conservant l'ordre ;
- `emitOutcome` n'auto-déclare pas l'outcome, pour garder le diagnostic `outcomeNotDeclared` utile ;
- `NarrativeOutcomePickerOption.outcomeId` devient une source draft `outcomeReceived`.

## 5. Opérations Battle Outcome ajoutées

APIs battle ajoutées :

```text
addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(...)
narrativeBattleOutcomeFlagReference(...)
validateNarrativeOutcomeAuthoringDraft(...)
```

Comportement :

- `NarrativeBattleReferencePickerOption.battleId` et `.trainerId` alimentent une action `startTrainerBattle` ;
- `npcEntityId` vient de l'option ou de l'override optionnel ;
- la fonction retourne un nouveau draft sans muter l'original ;
- le helper battle outcome produit explicitement :
  `battle:<battleId>:victory` ou `battle:<battleId>:defeat` ;
- aucune registry battle persistante n'est créée.

## 6. Diagnostics authoring

Diagnostic V0 ajouté :

```text
NarrativeOutcomeAuthoringDiagnostic
NarrativeOutcomeAuthoringDiagnosticSeverity
NarrativeOutcomeAuthoringDiagnosticKind
```

Kinds ajoutés :

```text
emptyOutcomeId
emptyBattleId
outcomeNotDeclared
declaredOutcomeNeverEmitted
battleOptionNotFound
missingTrainerReference
missingNpcEntityReference
scenarioOutcomeBattleOutcomeConfusion
```

Cas testés :

- `emitOutcome` non déclaré ;
- `declaredOutcome` jamais émis ;
- battleId vide ;
- trainerId vide ;
- npcEntityId manquant quand la source ne fournit pas d'entity ;
- battle option absente ;
- confusion entre raw outcome ids, `scenario.outcome.*` et `battle:*`.

## 7. Séparation scenario.outcome.* / battle:*

Helpers ajoutés :

```text
narrativeScenarioOutcomeFlagReference("p4.outcome.done")
// scenario.outcome.p4.outcome.done

narrativeBattleOutcomeFlagReference("p4_battle", NarrativeBattleOutcomeKind.victory)
// battle:p4_battle:victory

narrativeBattleOutcomeFlagReference("p4_battle", NarrativeBattleOutcomeKind.defeat)
// battle:p4_battle:defeat
```

Le test vérifie aussi que :

- `scenario.outcome.*` ne commence pas par `battle:` ;
- `battle:*` ne commence pas par `scenario.outcome.` ;
- les helpers directs refusent les ids vides ;
- le validator diagnostique les ids déjà préfixés utilisés au mauvais endroit.

## 8. Compilation vers ScenarioAsset

P4-04 ne modifie pas le compilateur P4-02. Il prouve que les drafts produits par les opérations P4-04 restent compilables.

Cas prouvés :

- `outcomeReceived + setFlag` compile vers un source node `sourceOutcome` avec `binding.outcomeId` ;
- `entityInteract + startTrainerBattle` compile vers une action `startTrainerBattle` avec :
  - `payload.params['battleId']` ;
  - `binding.trainerId` ;
  - `binding.entityId`.

## 9. Lien avec P4-01 / P4-02 / P4-03

P4-01 :

- fournit les options `NarrativeOutcomePickerOption` et
  `NarrativeBattleReferencePickerOption` utilisées par P4-04 ;
- fournit `NarrativeBattleOutcomeKind.victory/defeat` pour les helpers `battle:*`.

P4-02 :

- fournit `NarrativeScenarioAuthoringDraft`,
  `NarrativeScenarioAuthoringActionDraft.emitOutcome`,
  `NarrativeScenarioAuthoringActionDraft.startTrainerBattle` et la compilation
  `draft -> ScenarioAsset`.

P4-03 :

- fournit le pont Event Source ;
- P4-04 reste cohérent avec `outcomeReceived` et `sourceOutcome`.

P4-04 :

- ajoute les opérations de mutation immutable du draft pour outcomes/battles ;
- ajoute les diagnostics authoring spécialisés ;
- ajoute les helpers de flags narratifs séparés.

## 10. Limites et reports vers P4-05 / P4-06

Limites volontaires :

- pas d'Outcome Builder UI ;
- pas de Battle Builder UI ;
- pas d'OutcomeRegistry ou BattleRegistry ;
- pas de rewards, money, XP ou level-up ;
- pas de validation globale complète remplaçant `narrative_validator`.

Reports :

- P4-05 doit traiter les drafts de predicates/world rules passifs.
- P4-06 doit adapter les diagnostics authoring vers une présentation auteur plus exploitable.

## 11. Tests exécutés

Commandes exécutées :

```bash
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_outcome_authoring_operations.dart test/narrative_outcome_authoring_operations_test.dart
```

Résultats :

- `narrative_outcome_authoring_operations_test.dart` : `+12`, vert.
- `narrative_event_source_authoring_operations_test.dart` : `+7`, vert.
- `narrative_scenario_authoring_draft_test.dart` : `+9`, vert.
- `narrative_reference_picker_read_models_test.dart` : `+8`, vert.
- `narrative_validator_test.dart` : `+21`, vert.
- `dart analyze` : `No issues found!`.
- `dart format --set-exit-if-changed` : sortie finale `Formatted 2 files (0 changed)`.

## 12. Modifications effectuées

Fichiers créés :

```text
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
packages/map_core/test/narrative_outcome_authoring_operations_test.dart
reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

Aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` ou
`examples/playable_runtime_host` n'a été modifié.

## 13. Evidence Pack

### 13.1 Git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text

```

### 13.2 Commandes exécutées

```bash
git status --short --untracked-files=all

sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,760p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md

sed -n '1,520p' packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
sed -n '1,420p' packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
sed -n '1,520p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,260p' packages/map_core/lib/map_core.dart

rg -n "NarrativeOutcomePickerOption|NarrativeBattleReferencePickerOption|NarrativeBattleOutcomeKind|declaredOutcomes|emitOutcome|sourceOutcome|outcomeReceived|startTrainerBattle|battle:|scenario.outcome|trainerId|battleId|npcEntityId|NarrativeScenarioAuthoringActionDraft" packages/map_core packages/map_editor packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'

find packages/map_core/lib/src/authoring -type f | sort
find packages/map_core/test -type f | sort | rg "narrative|scenario|authoring|event|source|outcome|battle|picker|validator"

cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_outcome_authoring_operations.dart test/narrative_outcome_authoring_operations_test.dart

git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 13.3 Sorties utiles des commandes de lecture

`find packages/map_core/lib/src/authoring -type f | sort` :

```text
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
```

`find packages/map_core/test -type f | sort | rg "narrative|scenario|authoring|event|source|outcome|battle|picker|validator"` :

```text
packages/map_core/test/environment_authoring_diagnostics_test.dart
packages/map_core/test/map_events_test.dart
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/test/narrative_scenario_authoring_draft_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/scenario_assets_test.dart
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
packages/map_core/test/tall_grass_authoring_view_test.dart
```

Signaux utiles du `rg` obligatoire :

```text
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:22:enum NarrativeBattleOutcomeKind
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:258:final class NarrativeOutcomePickerOption
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:310:final class NarrativeBattleReferencePickerOption
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:398:List<NarrativeOutcomePickerOption> buildNarrativeOutcomePickerOptions
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:580:sourceId: 'outcomeReceived:$outcomeId'
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:590:debugTechnicalLabel: 'sourceOutcome:$outcomeId'
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:610:List<NarrativeBattleReferencePickerOption>
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:753:referenceId: 'battle:${battle.battleId}:$suffix'
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:129:const NarrativeScenarioAuthoringActionDraft.emitOutcome
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:138:const NarrativeScenarioAuthoringActionDraft.startTrainerBattle
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:489:NarrativeScenarioAuthoringSourceKind.outcomeReceived => ScenarioNodeBinding
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:542:case NarrativeScenarioAuthoringActionKind.startTrainerBattle
```

La sortie complète du `rg` obligatoire était très longue, donc seuls les signaux pertinents au lot sont repris ici.

### 13.4 TDD RED

Commande :

```bash
cd packages/map_core && dart test test/narrative_outcome_authoring_operations_test.dart
```

Sortie utile avant implémentation :

```text
Failed to load "test/narrative_outcome_authoring_operations_test.dart":
Error: Type 'NarrativeOutcomeAuthoringDiagnosticKind' not found.
Error: Type 'NarrativeOutcomeAuthoringDiagnostic' not found.
Error: Method not found: 'addDeclaredOutcomeToNarrativeScenarioAuthoringDraft'.
Error: Method not found: 'addEmitOutcomeActionToNarrativeScenarioAuthoringDraft'.
Error: Method not found: 'validateNarrativeOutcomeAuthoringDraft'.
Error: Method not found: 'createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption'.
Error: Method not found: 'addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft'.
Error: Method not found: 'narrativeScenarioOutcomeFlagReference'.
Error: Method not found: 'narrativeBattleOutcomeFlagReference'.
```

### 13.5 Contenu complet du fichier créé

`packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../read_models/narrative_reference_picker_read_models.dart';
import 'narrative_scenario_authoring_draft.dart';

const String _scenarioOutcomePrefix = 'scenario.outcome.';
const String _battleOutcomePrefix = 'battle:';

enum NarrativeOutcomeAuthoringDiagnosticSeverity {
  error,
  warning,
}

enum NarrativeOutcomeAuthoringDiagnosticKind {
  emptyOutcomeId,
  emptyBattleId,
  outcomeNotDeclared,
  declaredOutcomeNeverEmitted,
  battleOptionNotFound,
  missingTrainerReference,
  missingNpcEntityReference,
  scenarioOutcomeBattleOutcomeConfusion,
}

@immutable
final class NarrativeOutcomeAuthoringDiagnostic {
  const NarrativeOutcomeAuthoringDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativeOutcomeAuthoringDiagnosticSeverity severity;
  final NarrativeOutcomeAuthoringDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

NarrativeScenarioAuthoringDraft
    addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
  String outcomeId,
) {
  final trimmedOutcomeId = _requireRawScenarioOutcomeId(outcomeId);
  return _copyDraft(
    draft,
    declaredOutcomes: _dedupeTrimmed([
      ...draft.declaredOutcomes,
      trimmedOutcomeId,
    ]),
  );
}

NarrativeScenarioAuthoringDraft
    addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
  String outcomeId,
) {
  final trimmedOutcomeId = _requireRawScenarioOutcomeId(outcomeId);
  return _copyDraft(
    draft,
    actions: [
      ...draft.actions,
      NarrativeScenarioAuthoringActionDraft.emitOutcome(
        outcomeId: trimmedOutcomeId,
      ),
    ],
  );
}

NarrativeScenarioAuthoringSourceDraft
    createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
  NarrativeOutcomePickerOption option,
) {
  return NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
    outcomeId: _requireRawScenarioOutcomeId(option.outcomeId),
  );
}

NarrativeScenarioAuthoringDraft
    addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
  NarrativeBattleReferencePickerOption battleOption, {
  String? npcEntityId,
}) {
  final battleId = _requireRawBattleId(battleOption.battleId);
  final trainerId = battleOption.trainerId.trim();
  if (trainerId.isEmpty) {
    throw ArgumentError.value(
      battleOption.trainerId,
      'battleOption.trainerId',
      'Trainer id is required.',
    );
  }

  return _copyDraft(
    draft,
    actions: [
      ...draft.actions,
      NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
        trainerId: trainerId,
        battleId: battleId,
        npcEntityId: (npcEntityId ?? battleOption.npcEntityId).trim(),
      ),
    ],
  );
}

String narrativeScenarioOutcomeFlagReference(String outcomeId) {
  final trimmedOutcomeId = _requireRawScenarioOutcomeId(outcomeId);
  return '$_scenarioOutcomePrefix$trimmedOutcomeId';
}

String narrativeBattleOutcomeFlagReference(
  String battleId,
  NarrativeBattleOutcomeKind outcomeKind,
) {
  final trimmedBattleId = _requireRawBattleId(battleId);
  return '$_battleOutcomePrefix$trimmedBattleId:${outcomeKind.name}';
}

List<NarrativeOutcomeAuthoringDiagnostic>
    validateNarrativeOutcomeAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft, {
  Iterable<NarrativeBattleReferencePickerOption> battleOptions = const [],
}) {
  final diagnostics = <NarrativeOutcomeAuthoringDiagnostic>[];
  final declaredOutcomeIds = <String>{};
  final emittedOutcomeIds = <String>{};

  for (final rawOutcomeId in draft.declaredOutcomes) {
    final outcomeId = rawOutcomeId.trim();
    if (outcomeId.isEmpty) {
      _addDiagnostic(
        diagnostics,
        kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyOutcomeId,
        message: 'Declared outcome id is required.',
        path: 'declaredOutcomes',
      );
      continue;
    }
    _diagnoseScenarioOutcomeConfusion(
      diagnostics,
      outcomeId: outcomeId,
      path: 'declaredOutcomes',
    );
    declaredOutcomeIds.add(outcomeId);
  }

  final source = draft.source;
  if (source?.kind == NarrativeScenarioAuthoringSourceKind.outcomeReceived) {
    final outcomeId = source?.outcomeId.trim() ?? '';
    if (outcomeId.isEmpty) {
      _addDiagnostic(
        diagnostics,
        kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyOutcomeId,
        message: 'Outcome received source requires an outcome id.',
        path: 'source.outcomeId',
      );
    } else {
      _diagnoseScenarioOutcomeConfusion(
        diagnostics,
        outcomeId: outcomeId,
        path: 'source.outcomeId',
      );
    }
  }

  for (var index = 0; index < draft.actions.length; index++) {
    final action = draft.actions[index];
    switch (action.kind) {
      case NarrativeScenarioAuthoringActionKind.emitOutcome:
        final outcomeId = action.outcomeId.trim();
        if (outcomeId.isEmpty) {
          _addDiagnostic(
            diagnostics,
            kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyOutcomeId,
            message: 'Emitted outcome id is required.',
            path: 'actions[$index].outcomeId',
          );
          break;
        }
        _diagnoseScenarioOutcomeConfusion(
          diagnostics,
          outcomeId: outcomeId,
          path: 'actions[$index].outcomeId',
        );
        emittedOutcomeIds.add(outcomeId);
        if (!declaredOutcomeIds.contains(outcomeId)) {
          _addDiagnostic(
            diagnostics,
            severity: NarrativeOutcomeAuthoringDiagnosticSeverity.warning,
            kind: NarrativeOutcomeAuthoringDiagnosticKind.outcomeNotDeclared,
            message: 'Outcome "$outcomeId" is emitted but not declared.',
            path: 'actions[$index].outcomeId',
            referencedId: outcomeId,
          );
        }
      case NarrativeScenarioAuthoringActionKind.startTrainerBattle:
        _validateBattleAction(
          action,
          source: source,
          index: index,
          battleOptions: battleOptions,
          diagnostics: diagnostics,
        );
      case NarrativeScenarioAuthoringActionKind.setFlag:
      case NarrativeScenarioAuthoringActionKind.completeStep:
        break;
    }
  }

  for (final outcomeId in declaredOutcomeIds) {
    if (!emittedOutcomeIds.contains(outcomeId)) {
      _addDiagnostic(
        diagnostics,
        severity: NarrativeOutcomeAuthoringDiagnosticSeverity.warning,
        kind:
            NarrativeOutcomeAuthoringDiagnosticKind.declaredOutcomeNeverEmitted,
        message: 'Declared outcome "$outcomeId" is never emitted.',
        path: 'declaredOutcomes',
        referencedId: outcomeId,
      );
    }
  }

  return List<NarrativeOutcomeAuthoringDiagnostic>.unmodifiable(diagnostics);
}

NarrativeScenarioAuthoringDraft _copyDraft(
  NarrativeScenarioAuthoringDraft draft, {
  List<NarrativeScenarioAuthoringActionDraft>? actions,
  List<String>? declaredOutcomes,
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: draft.scenarioId,
    name: draft.name,
    description: draft.description,
    scope: draft.scope,
    source: draft.source,
    actions: actions ?? draft.actions,
    declaredOutcomes: declaredOutcomes ?? draft.declaredOutcomes,
    metadata: draft.metadata,
  );
}

void _validateBattleAction(
  NarrativeScenarioAuthoringActionDraft action, {
  required NarrativeScenarioAuthoringSourceDraft? source,
  required int index,
  required Iterable<NarrativeBattleReferencePickerOption> battleOptions,
  required List<NarrativeOutcomeAuthoringDiagnostic> diagnostics,
}) {
  final battleId = action.battleId.trim();
  final trainerId = action.trainerId.trim();
  final explicitNpcEntityId = action.npcEntityId.trim();
  final sourceNpcEntityId =
      source?.kind == NarrativeScenarioAuthoringSourceKind.entityInteract
          ? source?.entityId.trim() ?? ''
          : '';

  if (battleId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyBattleId,
      message: 'Battle id is required.',
      path: 'actions[$index].battleId',
    );
  } else {
    _diagnoseBattleOutcomeConfusion(
      diagnostics,
      battleId: battleId,
      path: 'actions[$index].battleId',
    );
  }

  if (trainerId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.missingTrainerReference,
      message: 'Trainer id is required for startTrainerBattle.',
      path: 'actions[$index].trainerId',
    );
  }

  if (explicitNpcEntityId.isEmpty && sourceNpcEntityId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.missingNpcEntityReference,
      message: 'NPC entity id is required for startTrainerBattle.',
      path: 'actions[$index].npcEntityId',
    );
  }

  if (battleId.isEmpty || battleOptions.isEmpty) {
    return;
  }

  final optionFound = battleOptions.any((option) {
    final sameBattleId = option.battleId.trim() == battleId;
    final optionTrainerId = option.trainerId.trim();
    return sameBattleId && (trainerId.isEmpty || optionTrainerId == trainerId);
  });
  if (!optionFound) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.battleOptionNotFound,
      message: 'No selectable battle option matches "$battleId".',
      path: 'actions[$index].battleId',
      referencedId: battleId,
    );
  }
}

void _diagnoseScenarioOutcomeConfusion(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics, {
  required String outcomeId,
  required String path,
}) {
  if (!_looksLikeScenarioOrBattleFlag(outcomeId)) {
    return;
  }
  _addDiagnostic(
    diagnostics,
    kind: NarrativeOutcomeAuthoringDiagnosticKind
        .scenarioOutcomeBattleOutcomeConfusion,
    message:
        'Use a raw scenario outcome id here, not a scenario.outcome.* or battle:* flag.',
    path: path,
    referencedId: outcomeId,
  );
}

void _diagnoseBattleOutcomeConfusion(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics, {
  required String battleId,
  required String path,
}) {
  if (!_looksLikeScenarioOrBattleFlag(battleId)) {
    return;
  }
  _addDiagnostic(
    diagnostics,
    kind: NarrativeOutcomeAuthoringDiagnosticKind
        .scenarioOutcomeBattleOutcomeConfusion,
    message:
        'Use a raw battle id here, not a scenario.outcome.* or battle:* flag.',
    path: path,
    referencedId: battleId,
  );
}

void _addDiagnostic(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics, {
  required NarrativeOutcomeAuthoringDiagnosticKind kind,
  required String message,
  required String path,
  String? referencedId,
  NarrativeOutcomeAuthoringDiagnosticSeverity severity =
      NarrativeOutcomeAuthoringDiagnosticSeverity.error,
}) {
  diagnostics.add(
    NarrativeOutcomeAuthoringDiagnostic(
      severity: severity,
      kind: kind,
      message: message,
      path: path,
      referencedId: referencedId,
    ),
  );
}

String _requireRawScenarioOutcomeId(String outcomeId) {
  final trimmedOutcomeId = outcomeId.trim();
  if (trimmedOutcomeId.isEmpty) {
    throw ArgumentError.value(
        outcomeId, 'outcomeId', 'Outcome id is required.');
  }
  if (_looksLikeScenarioOrBattleFlag(trimmedOutcomeId)) {
    throw ArgumentError.value(
      outcomeId,
      'outcomeId',
      'Expected a raw scenario outcome id, not a stored outcome flag.',
    );
  }
  return trimmedOutcomeId;
}

String _requireRawBattleId(String battleId) {
  final trimmedBattleId = battleId.trim();
  if (trimmedBattleId.isEmpty) {
    throw ArgumentError.value(battleId, 'battleId', 'Battle id is required.');
  }
  if (_looksLikeScenarioOrBattleFlag(trimmedBattleId)) {
    throw ArgumentError.value(
      battleId,
      'battleId',
      'Expected a raw battle id, not a stored outcome flag.',
    );
  }
  return trimmedBattleId;
}

bool _looksLikeScenarioOrBattleFlag(String value) {
  return value.startsWith(_scenarioOutcomePrefix) ||
      value.startsWith(_battleOutcomePrefix);
}

List<String> _dedupeTrimmed(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    result.add(trimmed);
  }
  return List<String>.unmodifiable(result);
}
```

### 13.6 Contenu complet du test créé

`packages/map_core/test/narrative_outcome_authoring_operations_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative outcome authoring operations', () {
    test('adds and dedupes declared outcomes without mutating the original',
        () {
      final original = _draft();

      final withOutcome = addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
        original,
        ' p4.outcome.done ',
      );
      final deduped = addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
        withOutcome,
        'p4.outcome.done',
      );

      expect(original.declaredOutcomes, isEmpty);
      expect(withOutcome.declaredOutcomes, ['p4.outcome.done']);
      expect(deduped.declaredOutcomes, ['p4.outcome.done']);
      expect(identical(withOutcome, original), isFalse);
    });

    test('adds emitOutcome action without auto-declaring by default', () {
      final original = _draft();

      final updated = addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
        original,
        ' p4.outcome.done ',
      );

      expect(original.actions, hasLength(1));
      expect(updated.actions, hasLength(2));
      expect(updated.actions.last.kind,
          NarrativeScenarioAuthoringActionKind.emitOutcome);
      expect(updated.actions.last.outcomeId, 'p4.outcome.done');
      expect(updated.declaredOutcomes, isEmpty);
    });

    test('diagnoses undeclared emits and declared outcomes never emitted', () {
      final undeclared = validateNarrativeOutcomeAuthoringDraft(
        addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
          _draft(),
          'p4.outcome.undeclared',
        ),
      );
      expect(
        _outcomeDiagnosticKinds(undeclared),
        contains(NarrativeOutcomeAuthoringDiagnosticKind.outcomeNotDeclared),
      );
      expect(undeclared.single.referencedId, 'p4.outcome.undeclared');

      final declaredOnly = validateNarrativeOutcomeAuthoringDraft(
        addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
          _draft(),
          'p4.outcome.never_emitted',
        ),
      );
      expect(
        _outcomeDiagnosticKinds(declaredOnly),
        contains(
          NarrativeOutcomeAuthoringDiagnosticKind.declaredOutcomeNeverEmitted,
        ),
      );
      expect(declaredOnly.single.referencedId, 'p4.outcome.never_emitted');
    });

    test('creates outcomeReceived source from outcome picker option', () {
      final option = _outcomeOption('p4.outcome.done');

      final source = createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
        option,
      );

      expect(source.kind, NarrativeScenarioAuthoringSourceKind.outcomeReceived);
      expect(source.outcomeId, 'p4.outcome.done');
    });

    test('compiles outcomeReceived source with setFlag into sourceOutcome', () {
      final source = createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
        _outcomeOption('p4.outcome.done'),
      );

      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        _draft(source: source),
      );
      final sourceNode = asset.nodes.singleWhere(
        (node) => node.id == 'p4_authoring_outcome__source',
      );

      expect(sourceNode.payload.actionKind, 'sourceOutcome');
      expect(sourceNode.binding.outcomeId, 'p4.outcome.done');
      expect(asset.nodes.last.type, ScenarioNodeType.end);
    });

    test('adds startTrainerBattle action from battle reference option', () {
      final original = _draft(
        source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );
      final option = _battleOption();

      final updated =
          addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        original,
        option,
      );

      expect(original.actions, hasLength(1));
      expect(updated.actions, hasLength(2));
      final action = updated.actions.last;
      expect(
          action.kind, NarrativeScenarioAuthoringActionKind.startTrainerBattle);
      expect(action.battleId, 'p4_battle');
      expect(action.trainerId, 'p4_trainer');
      expect(action.npcEntityId, 'p4_npc');
    });

    test('compiles entityInteract with startTrainerBattle bindings', () {
      final draft =
          addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        _draft(
          source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: 'p4_map',
            entityId: 'p4_npc',
          ),
        ),
        _battleOption(),
      );

      final asset =
          compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);
      final battleNode = asset.nodes.singleWhere(
        (node) => node.id == 'p4_authoring_outcome__action_1',
      );

      expect(battleNode.payload.actionKind, 'startTrainerBattle');
      expect(battleNode.payload.params['battleId'], 'p4_battle');
      expect(battleNode.binding.trainerId, 'p4_trainer');
      expect(battleNode.binding.entityId, 'p4_npc');
    });

    test('builds scenario and battle outcome flag references separately', () {
      final scenarioOutcome =
          narrativeScenarioOutcomeFlagReference(' p4.outcome.done ');
      final battleVictory = narrativeBattleOutcomeFlagReference(
        ' p4_battle ',
        NarrativeBattleOutcomeKind.victory,
      );
      final battleDefeat = narrativeBattleOutcomeFlagReference(
        'p4_battle',
        NarrativeBattleOutcomeKind.defeat,
      );

      expect(scenarioOutcome, 'scenario.outcome.p4.outcome.done');
      expect(battleVictory, 'battle:p4_battle:victory');
      expect(battleDefeat, 'battle:p4_battle:defeat');
      expect(scenarioOutcome.startsWith('battle:'), isFalse);
      expect(battleVictory.startsWith('scenario.outcome.'), isFalse);
      expect(battleDefeat.startsWith('scenario.outcome.'), isFalse);
    });

    test('diagnoses battle option and battle reference problems', () {
      final diagnostics = validateNarrativeOutcomeAuthoringDraft(
        _draft(
          source: const NarrativeScenarioAuthoringSourceDraft.mapEnter(
            mapId: 'p4_map',
          ),
          actions: const [
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              battleId: ' ',
              trainerId: ' ',
            ),
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              battleId: 'missing_battle',
              trainerId: 'p4_trainer',
              npcEntityId: 'p4_npc',
            ),
          ],
        ),
        battleOptions: [_battleOption()],
      );

      expect(
        _outcomeDiagnosticKinds(diagnostics),
        containsAll([
          NarrativeOutcomeAuthoringDiagnosticKind.emptyBattleId,
          NarrativeOutcomeAuthoringDiagnosticKind.missingTrainerReference,
          NarrativeOutcomeAuthoringDiagnosticKind.missingNpcEntityReference,
          NarrativeOutcomeAuthoringDiagnosticKind.battleOptionNotFound,
        ]),
      );
    });

    test('diagnoses scenario outcome and battle outcome confusion', () {
      final diagnostics = validateNarrativeOutcomeAuthoringDraft(
        _draft(
          declaredOutcomes: const ['battle:p4_battle:victory'],
          actions: const [
            NarrativeScenarioAuthoringActionDraft.emitOutcome(
              outcomeId: 'scenario.outcome.p4.already_prefixed',
            ),
            NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
              battleId: 'scenario.outcome.p4_battle',
              trainerId: 'p4_trainer',
              npcEntityId: 'p4_npc',
            ),
          ],
        ),
        battleOptions: [_battleOption()],
      );

      expect(
        _outcomeDiagnosticKinds(diagnostics),
        contains(
          NarrativeOutcomeAuthoringDiagnosticKind
              .scenarioOutcomeBattleOutcomeConfusion,
        ),
      );
    });

    test('throws for empty direct flag references', () {
      expect(
        () => narrativeScenarioOutcomeFlagReference(' '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => narrativeBattleOutcomeFlagReference(
          ' ',
          NarrativeBattleOutcomeKind.victory,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not hardcode Selbrume identifiers', () {
      final draft =
          addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
        addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
          addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
            _draft(),
            'p4.outcome.done',
          ),
          'p4.outcome.done',
        ),
        _battleOption(),
        npcEntityId: 'p4_npc',
      );
      final serialized = {
        narrativeScenarioOutcomeFlagReference('p4.outcome.done'),
        narrativeBattleOutcomeFlagReference(
          'p4_battle',
          NarrativeBattleOutcomeKind.victory,
        ),
        compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft)
            .toJson()
            .toString(),
      }.join('\n').toLowerCase();

      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativeScenarioAuthoringDraft _draft({
  NarrativeScenarioAuthoringSourceDraft source =
      const NarrativeScenarioAuthoringSourceDraft.mapEnter(mapId: 'p4_map'),
  List<NarrativeScenarioAuthoringActionDraft> actions = const [
    NarrativeScenarioAuthoringActionDraft.setFlag(
      flagName: 'p4.outcome.authoring.executed',
    ),
  ],
  List<String> declaredOutcomes = const [],
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: 'p4_authoring_outcome',
    name: 'P4 Authoring Outcome',
    description: 'Technical outcome authoring draft.',
    scope: source.kind == NarrativeScenarioAuthoringSourceKind.outcomeReceived
        ? ScenarioScope.globalStory
        : ScenarioScope.localEventFlow,
    source: source,
    actions: actions,
    declaredOutcomes: declaredOutcomes,
    metadata: const {'authoring.test': 'p4-04'},
  );
}

NarrativeOutcomePickerOption _outcomeOption(String outcomeId) {
  return buildNarrativeOutcomePickerOptions(
    ProjectManifest(
      name: 'P4 Outcome Authoring Test',
      maps: const [],
      tilesets: const [],
      scenarios: [
        ScenarioAsset(
          id: 'p4_outcome_source',
          name: 'P4 Outcome Source',
          entryNodeId: 'source',
          declaredOutcomes: [outcomeId],
          nodes: [
            ScenarioNode(
              id: 'source',
              type: ScenarioNodeType.reference,
              payload: const ScenarioNodePayload(actionKind: 'sourceMapEnter'),
            ),
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(outcomeId: outcomeId),
              payload: const ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
          ],
          edges: const [],
        ),
      ],
    ),
  ).singleWhere((option) => option.outcomeId == outcomeId);
}

NarrativeBattleReferencePickerOption _battleOption() {
  return buildNarrativeBattleReferencePickerOptions(
    ProjectManifest(
      name: 'P4 Battle Authoring Test',
      maps: const [],
      tilesets: const [],
      trainers: const [
        ProjectTrainerEntry(
          id: 'p4_trainer',
          name: 'P4 Trainer',
          trainerClass: 'Tester',
        ),
      ],
      scenarios: const [
        ScenarioAsset(
          id: 'p4_battle_provider',
          name: 'P4 Battle Provider',
          entryNodeId: 'source',
          nodes: [
            ScenarioNode(
              id: 'battle',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(
                trainerId: 'p4_trainer',
                entityId: 'p4_npc',
              ),
              payload: ScenarioNodePayload(
                actionKind: 'startTrainerBattle',
                params: {'battleId': 'p4_battle'},
              ),
            ),
          ],
          edges: [],
        ),
      ],
    ),
  ).single;
}

List<NarrativeOutcomeAuthoringDiagnosticKind> _outcomeDiagnosticKinds(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}
```

### 13.7 Diff complet des fichiers modifiés

`packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 5bfbbaf8..7d0549e8 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -72,6 +72,7 @@ export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/narrative_validator.dart';
 export 'src/authoring/narrative_event_source_authoring_operations.dart';
+export 'src/authoring/narrative_outcome_authoring_operations.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/operations/static_shadow_geometry.dart';
```

`MVP Selbrume/road_map_phase_4.md`

```diff
diff --git a/MVP Selbrume/road_map_phase_4.md b/MVP Selbrume/road_map_phase_4.md
index 79329b9e..14a6f116 100644
--- a/MVP Selbrume/road_map_phase_4.md	
+++ b/MVP Selbrume/road_map_phase_4.md	
@@ -6,9 +6,9 @@ Phase 4 — Authoring Workflows Minimal
 
 Statut : 🔜 Phase courante en exécution
 
-Lot courant : P4-04 — Outcome / Battle Outcome Authoring Operations V0
+Lot courant : P4-05 — Predicate / World Rule Authoring Draft V0
 
-Prochain lot exact : P4-04 — Outcome / Battle Outcome Authoring Operations V0
+Prochain lot exact : P4-05 — Predicate / World Rule Authoring Draft V0
 
 Suivi des lots :
 
@@ -16,8 +16,8 @@ Suivi des lots :
 - ✅ P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0
 - ✅ P4-02 — Scenario Authoring Draft Model V0
 - ✅ P4-03 — Event Source Authoring Draft Operations V0
-- 🔜 P4-04 — Outcome / Battle Outcome Authoring Operations V0
-- P4-05 — Predicate / World Rule Authoring Draft V0
+- ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0
+- 🔜 P4-05 — Predicate / World Rule Authoring Draft V0
 - P4-06 — Narrative Validator Authoring Adapter V0
 - P4-07 — Minimal Authoring Golden Path Test V0
 - P4-CHECKPOINT-01 — Authoring Workflow Readiness Review
@@ -30,7 +30,9 @@ P4-02 : ✅ terminé
 
 P4-03 : ✅ terminé
 
-P4-04 : 🔜 prochain lot exact
+P4-04 : ✅ terminé
+
+P4-05 : 🔜 prochain lot exact
 
 ## 2. Objectif de la Phase 4
 
@@ -249,7 +251,7 @@ Résultat P4-03 :
   migration, aucun runtime, aucun contenu Selbrume et aucun reward/money/XP
   créé.
 
-### 🔜 P4-04 — Outcome / Battle Outcome Authoring Operations V0
+### ✅ P4-04 — Outcome / Battle Outcome Authoring Operations V0
 
 Objectif :
 Rendre authorables les outcomes scénario et battle outcomes sans registry.
@@ -262,7 +264,33 @@ Preuve concrète, pure et testée :
 - opérations ou read models pour brancher victory/defeat V0 ;
 - diagnostics ou validation contre OutcomeRegistry/BattleRegistry implicites.
 
-### P4-05 — Predicate / World Rule Authoring Draft V0
+Résultat P4-04 :
+
+- rapport créé :
+  `reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md` ;
+- opérations authoring pures ajoutées dans `map_core` :
+  `addDeclaredOutcomeToNarrativeScenarioAuthoringDraft`,
+  `addEmitOutcomeActionToNarrativeScenarioAuthoringDraft`,
+  `createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption`,
+  `addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft`,
+  `narrativeScenarioOutcomeFlagReference`,
+  `narrativeBattleOutcomeFlagReference`,
+  `validateNarrativeOutcomeAuthoringDraft` ;
+- diagnostics Outcome/Battle V0 ajoutés :
+  `emptyOutcomeId`, `emptyBattleId`, `outcomeNotDeclared`,
+  `declaredOutcomeNeverEmitted`, `battleOptionNotFound`,
+  `missingTrainerReference`, `missingNpcEntityReference`,
+  `scenarioOutcomeBattleOutcomeConfusion` ;
+- séparation explicite `scenario.outcome.*` / `battle:*` prouvée ;
+- compilation `draft -> ScenarioAsset` prouvée pour `sourceOutcome` et
+  `startTrainerBattle` ;
+- tests ciblés ajoutés dans
+  `packages/map_core/test/narrative_outcome_authoring_operations_test.dart` ;
+- aucun widget UI, aucun OutcomeRegistry/BattleRegistry, aucun registry
+  persistant, aucune migration, aucun runtime, aucun contenu Selbrume et aucun
+  reward/money/XP créé.
+
+### 🔜 P4-05 — Predicate / World Rule Authoring Draft V0
 
 Objectif :
 Rendre authorables les predicates et world rules passives sans créer
@@ -352,5 +380,5 @@ Phase 4 doit produire des preuves authoring concrètes après P4-00.
 Le prochain lot exact est :
 
 ```text
-P4-04 — Outcome / Battle Outcome Authoring Operations V0
+P4-05 — Predicate / World Rule Authoring Draft V0
 ```
```

### 13.8 Sortie complète du test ciblé

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

### 13.9 Sorties complètes des régressions ciblées

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

### 13.10 Sortie dart analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

### 13.11 Sortie dart format

Commande :

```bash
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_outcome_authoring_operations.dart test/narrative_outcome_authoring_operations_test.dart
```

Sortie finale :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

Note : une première exécution de `dart format --set-exit-if-changed` a formaté les deux nouveaux fichiers et a donc retourné un statut non nul attendu pour ce mode. La sortie finale ci-dessus prouve que le format est stabilisé.

### 13.12 git diff --check exact

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

### 13.13 git diff --stat exact

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map_phase_4.md    | 44 ++++++++++++++++++++++++++++++-------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 37 insertions(+), 8 deletions(-)
```

### 13.14 git diff --name-only exact

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

### 13.15 git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
?? packages/map_core/test/narrative_outcome_authoring_operations_test.dart
?? reports/roadmap/phase_4/p4_04_outcome_battle_outcome_authoring_operations.md
```

### 13.16 Contrôles explicites hors scope

- `road_map_global.md` n'a pas été modifié.
- P4-05 n'a pas été exécuté.
- Aucun contenu Selbrume final n'a été créé.
- Aucune UI premium n'a été créée.
- Aucun widget Flutter n'a été créé.
- Aucun registry persistant n'a été créé.
- Aucun OutcomeRegistry ou BattleRegistry n'a été créé.
- Aucun reward/money/XP n'a été ajouté.
- Aucun fichier `ProjectManifest`, `ScenarioAsset`, `GameState` ou `SaveData`
  n'a été modifié.
- Aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` ou
  `examples/playable_runtime_host` n'a été modifié.

Commandes de contrôle hors scope :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation
```

Sortie exacte pour les trois commandes :

```text

```

## 14. Auto-review critique

Points solides :

- la preuve n'est pas audit-only ;
- les opérations sont pures, déterministes, sans I/O et sans registry ;
- la séparation `scenario.outcome.*` / `battle:*` est testée explicitement ;
- la compilation vers `ScenarioAsset` est prouvée pour `sourceOutcome` et
  `startTrainerBattle` ;
- P4-01/P4-02/P4-03 restent verts.

Limites :

- les diagnostics P4-04 ne remplacent pas le validator narratif global ;
- les helpers directs refusent les ids déjà préfixés, choix volontaire pour éviter
  la confusion authoring V0 ;
- aucun workflow UI n'est prouvé, conformément au scope ;
- les predicates/world rules restent reportés à P4-05.

Verdict :

```text
P4-04 : clôturable.
Prochain lot exact : P4-05 — Predicate / World Rule Authoring Draft V0.
```

## 15. Regard critique sur le prompt

Le prompt force la bonne séparation : outcomes scénario et battle outcomes doivent devenir authorables, mais sans créer de registry prématuré. C'est la bonne contrainte pour Phase 4.

Le principal risque était d'ajouter implicitement un `OutcomeRegistry` ou de masquer la différence entre `scenario.outcome.*` et `battle:*`. Le lot évite ce piège en produisant uniquement des opérations dérivées, des helpers explicites et des diagnostics.

P4-05 devra garder la même discipline : rendre les predicates/world rules authorables sans créer `FactRegistry` ou `WorldRuleRegistry`.
