# P4-03 — Event Source Authoring Draft Operations V0

## 1. Résumé exécutif

P4-03 est validable.

Le lot ajoute une brique authoring pure dans `map_core` pour transformer une option de picker Event Source P4-01 en source draft P4-02, vérifier qu'elle correspond aux options disponibles, remplacer la source d'un draft sans mutation, puis compiler un `ScenarioAsset` avec le bon source node.

Preuve obtenue :

- `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived` sont convertis depuis `NarrativeEventSourcePickerOption` vers `NarrativeScenarioAuthoringSourceDraft`.
- Les source ids authoring sont déterministes et alignés avec P4-01 :
  `mapEnter:<mapId>`, `triggerEnter:<mapId>:<triggerId>`,
  `entityInteract:<mapId>:<entityId>`, `outcomeReceived:<outcomeId>`.
- Une source draft peut retrouver son option picker ou produire un diagnostic si l'option n'existe pas.
- Les références vides sont diagnostiquées avant compilation.
- `replaceNarrativeScenarioAuthoringDraftSource(...)` retourne un nouveau draft et ne mute pas l'original.
- La compilation `draft -> ScenarioAsset` est prouvée pour les quatre sources.

Le prochain lot exact reste :

```text
P4-04 — Outcome / Battle Outcome Authoring Operations V0
```

## 2. Scope du lot

Inclus :

- opérations authoring pures Event Source ;
- diagnostics V0 pour références sources vides ou options absentes ;
- export public depuis `map_core.dart` ;
- tests unitaires ciblés ;
- mise à jour de `MVP Selbrume/road_map_phase_4.md` ;
- rapport et Evidence Pack.

Exclus :

- UI, widget Flutter, Event Builder UI ;
- EventRegistry, FactRegistry, WorldRuleRegistry, OutcomeRegistry, BattleRegistry ;
- modification de `ProjectManifest`, `ScenarioAsset`, `GameState`, `SaveData` ;
- runtime, host, editor UI ;
- Selbrume final ;
- rewards, money, XP, level-up ;
- P4-04.

## 3. Sources lues

Fichiers principaux lus :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_4.md`
- `reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md`
- `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_scenario_authoring_draft_test.dart`
- `packages/map_core/test/narrative_reference_picker_read_models_test.dart`
- `packages/map_core/lib/map_core.dart`

Observations utiles :

- P4-01 expose déjà `NarrativeEventSourcePickerOption`,
  `NarrativeEventSourceKind` et
  `buildNarrativeEventSourcePickerOptions(...)`.
- P4-01 utilise déjà les source ids stables :
  `mapEnter:<mapId>`, `triggerEnter:<mapId>:<triggerId>`,
  `entityInteract:<mapId>:<entityId>`, `outcomeReceived:<outcomeId>`.
- P4-02 expose déjà `NarrativeScenarioAuthoringDraft`,
  `NarrativeScenarioAuthoringSourceDraft`,
  `NarrativeScenarioAuthoringActionDraft`,
  `validateNarrativeScenarioAuthoringDraft(...)` et
  `compileNarrativeScenarioAuthoringDraftToScenarioAsset(...)`.
- P4-02 compile déjà les quatre source nodes runtime attendus :
  `sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract`,
  `sourceOutcome`.

## 4. Opérations Event Source ajoutées

Fichier créé :

```text
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
```

APIs ajoutées :

```text
createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(...)
narrativeEventSourceIdForAuthoringSourceDraft(...)
findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(...)
validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(...)
replaceNarrativeScenarioAuthoringDraftSource(...)
```

Conversion couverte :

| Picker P4-01 | Source draft P4-02 |
|---|---|
| `NarrativeEventSourceKind.mapEnter` | `NarrativeScenarioAuthoringSourceDraft.mapEnter(mapId)` |
| `NarrativeEventSourceKind.triggerEnter` | `NarrativeScenarioAuthoringSourceDraft.triggerEnter(mapId, triggerId)` |
| `NarrativeEventSourceKind.entityInteract` | `NarrativeScenarioAuthoringSourceDraft.entityInteract(mapId, entityId)` |
| `NarrativeEventSourceKind.outcomeReceived` | `NarrativeScenarioAuthoringSourceDraft.outcomeReceived(outcomeId)` |

Les références sont trimées lors de la conversion et lors du calcul du source id.

## 5. Validation des sources Event

Diagnostic V0 ajouté :

```text
NarrativeEventSourceAuthoringDiagnostic
NarrativeEventSourceAuthoringDiagnosticSeverity
NarrativeEventSourceAuthoringDiagnosticKind
```

Kinds ajoutés :

```text
missingSourceReference
sourceOptionNotFound
unsupportedEventSourceKind
```

Comportement testé :

- `triggerEnter` sans `triggerId` produit `missingSourceReference`.
- `outcomeReceived` avec un `outcomeId` absent des options produit
  `sourceOptionNotFound`.
- Les diagnostics sont retournés sans I/O, sans mutation et sans registry.

`unsupportedEventSourceKind` est exposé pour garder une surface V0 stable si une source future sort du set connu, mais aucun cas runtime actuel ne le déclenche car les enums sont exhaustifs.

## 6. Remplacement de source dans un draft

L'opération :

```text
replaceNarrativeScenarioAuthoringDraftSource(draft, source)
```

retourne un nouveau `NarrativeScenarioAuthoringDraft` avec :

- même `scenarioId` ;
- même `name` ;
- même `description` ;
- même `scope` ;
- nouvelle `source` ;
- mêmes `actions` ;
- mêmes `declaredOutcomes` ;
- mêmes `metadata`.

Le test vérifie que le draft original conserve sa source initiale et que l'objet retourné n'est pas identique à l'original.

## 7. Compilation vers ScenarioAsset

P4-03 ne modifie pas la compilation P4-02. Il prouve que les drafts mis à jour par les opérations P4-03 restent compilables.

Le test compile quatre drafts mis à jour et vérifie le source node :

| Source draft | `ScenarioNodePayload.actionKind` attendu |
|---|---|
| `mapEnter` | `sourceMapEnter` |
| `triggerEnter` | `sourceTriggerEnter` |
| `entityInteract` | `sourceEntityInteract` |
| `outcomeReceived` | `sourceOutcome` |

Pour chaque cas, le test vérifie aussi les bindings attendus :

- `mapId` ;
- `triggerId` ;
- `entityId` ;
- `outcomeId`.

## 8. Lien avec P4-01 / P4-02

Lien avec P4-01 :

- les opérations consomment `NarrativeEventSourcePickerOption` ;
- les source ids sont alignés avec ceux produits par
  `buildNarrativeEventSourcePickerOptions(...)` ;
- une source draft peut retrouver l'option sélectionnable correspondante.

Lien avec P4-02 :

- les opérations produisent `NarrativeScenarioAuthoringSourceDraft` ;
- le remplacement de source garde intact le reste du
  `NarrativeScenarioAuthoringDraft` ;
- la compilation existante P4-02 est réutilisée sans changement.

## 9. Limites et reports vers P4-04 / P4-05

Limites volontaires :

- pas d'Event Builder UI ;
- pas de registry de sources ;
- pas de modification du modèle persistant ;
- pas de validation croisée complète avec diagnostics narratifs globaux ;
- pas d'authoring outcome/battle au-delà de la source `outcomeReceived`.

Reports :

- P4-04 doit traiter les opérations authoring `emitOutcome`,
  `sourceOutcome`, `startTrainerBattle` et la séparation scenario/battle outcomes.
- P4-05 doit traiter les authoring drafts de predicates/world rules.

## 10. Tests exécutés

Commandes exécutées :

```bash
cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_event_source_authoring_operations.dart test/narrative_event_source_authoring_operations_test.dart
```

Résultats :

- `narrative_event_source_authoring_operations_test.dart` : `+7`, vert.
- `narrative_scenario_authoring_draft_test.dart` : `+9`, vert.
- `narrative_reference_picker_read_models_test.dart` : `+8`, vert.
- `narrative_validator_test.dart` : `+21`, vert.
- `dart analyze` : `No issues found!`.
- `dart format --set-exit-if-changed` : `Formatted 2 files (0 changed)`.

## 11. Modifications effectuées

Fichiers créés :

```text
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

Aucun fichier de production hors `map_core` n'a été modifié.
Aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` ou
`examples/playable_runtime_host` n'a été modifié.

## 12. Evidence Pack

### 12.1 Git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text

```

### 12.2 Commandes obligatoires exécutées

```bash
git status --short --untracked-files=all

test -f skills/README.md && sed -n '1,220p' skills/README.md || true

sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,700p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_02_scenario_authoring_draft_model.md

sed -n '1,460p' packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
sed -n '1,420p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,260p' packages/map_core/test/narrative_scenario_authoring_draft_test.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart

rg -n "NarrativeEventSourcePickerOption|NarrativeEventSourceKind|NarrativeScenarioAuthoringSourceDraft|NarrativeScenarioAuthoringDraft|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|outcomeReceived|mapEnter|triggerEnter|entityInteract" packages/map_core packages/map_editor --glob '!build/**' --glob '!**/.dart_tool/**'

find packages/map_core/lib/src/authoring -type f | sort
find packages/map_core/test -type f | sort | rg "narrative|scenario|authoring|event|source|picker|validator"

cd packages/map_core && dart test test/narrative_event_source_authoring_operations_test.dart
cd packages/map_core && dart test test/narrative_scenario_authoring_draft_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_event_source_authoring_operations.dart test/narrative_event_source_authoring_operations_test.dart

git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 12.3 Sorties utiles des commandes de lecture

`find packages/map_core/lib/src/authoring -type f | sort` avant ajout P4-03 :

```text
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
```

`find packages/map_core/test -type f | sort | rg "narrative|scenario|authoring|event|source|picker|validator"` :

```text
packages/map_core/test/environment_authoring_diagnostics_test.dart
packages/map_core/test/map_events_test.dart
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
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:32:enum NarrativeEventSourceKind
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:162:final class NarrativeEventSourcePickerOption
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:482:List<NarrativeEventSourcePickerOption> buildNarrativeEventSourcePickerOptions
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:522:sourceId: 'mapEnter:$mapId'
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:540:sourceId: 'triggerEnter:$mapId:$triggerId'
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:561:sourceId: 'entityInteract:$mapId:$entityId'
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:586:sourceId: 'outcomeReceived:$outcomeId'
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:40:final class NarrativeScenarioAuthoringDraft
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:80:enum NarrativeScenarioAuthoringSourceKind
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:87:final class NarrativeScenarioAuthoringSourceDraft
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:422:String _sourceActionKind(NarrativeScenarioAuthoringSourceKind kind)
```

### 12.4 Contenu complet du fichier créé

`packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../read_models/narrative_reference_picker_read_models.dart';
import 'narrative_scenario_authoring_draft.dart';

enum NarrativeEventSourceAuthoringDiagnosticSeverity {
  error,
  warning,
}

enum NarrativeEventSourceAuthoringDiagnosticKind {
  missingSourceReference,
  sourceOptionNotFound,
  unsupportedEventSourceKind,
}

@immutable
final class NarrativeEventSourceAuthoringDiagnostic {
  const NarrativeEventSourceAuthoringDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativeEventSourceAuthoringDiagnosticSeverity severity;
  final NarrativeEventSourceAuthoringDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

NarrativeScenarioAuthoringSourceDraft
    createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
  NarrativeEventSourcePickerOption option,
) {
  return switch (option.sourceKind) {
    NarrativeEventSourceKind.mapEnter =>
      NarrativeScenarioAuthoringSourceDraft.mapEnter(
        mapId: option.mapId.trim(),
      ),
    NarrativeEventSourceKind.triggerEnter =>
      NarrativeScenarioAuthoringSourceDraft.triggerEnter(
        mapId: option.mapId.trim(),
        triggerId: option.triggerId.trim(),
      ),
    NarrativeEventSourceKind.entityInteract =>
      NarrativeScenarioAuthoringSourceDraft.entityInteract(
        mapId: option.mapId.trim(),
        entityId: option.entityId.trim(),
      ),
    NarrativeEventSourceKind.outcomeReceived =>
      NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
        outcomeId: option.outcomeId.trim(),
      ),
  };
}

String narrativeEventSourceIdForAuthoringSourceDraft(
  NarrativeScenarioAuthoringSourceDraft source,
) {
  return switch (source.kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter =>
      'mapEnter:${source.mapId.trim()}',
    NarrativeScenarioAuthoringSourceKind.triggerEnter =>
      'triggerEnter:${source.mapId.trim()}:${source.triggerId.trim()}',
    NarrativeScenarioAuthoringSourceKind.entityInteract =>
      'entityInteract:${source.mapId.trim()}:${source.entityId.trim()}',
    NarrativeScenarioAuthoringSourceKind.outcomeReceived =>
      'outcomeReceived:${source.outcomeId.trim()}',
  };
}

NarrativeEventSourcePickerOption?
    findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
  NarrativeScenarioAuthoringSourceDraft source,
  Iterable<NarrativeEventSourcePickerOption> options,
) {
  final expectedSourceId =
      narrativeEventSourceIdForAuthoringSourceDraft(source);
  for (final option in options) {
    if (option.sourceId.trim() == expectedSourceId) {
      return option;
    }
  }
  return null;
}

List<NarrativeEventSourceAuthoringDiagnostic>
    validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
  NarrativeScenarioAuthoringSourceDraft source,
  Iterable<NarrativeEventSourcePickerOption> options,
) {
  final diagnostics = <NarrativeEventSourceAuthoringDiagnostic>[];
  _collectMissingReferenceDiagnostics(source, diagnostics);
  if (diagnostics.isNotEmpty) {
    return List<NarrativeEventSourceAuthoringDiagnostic>.unmodifiable(
      diagnostics,
    );
  }

  final option = findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
    source,
    options,
  );
  if (option == null) {
    final sourceId = narrativeEventSourceIdForAuthoringSourceDraft(source);
    diagnostics.add(
      NarrativeEventSourceAuthoringDiagnostic(
        severity: NarrativeEventSourceAuthoringDiagnosticSeverity.error,
        kind: NarrativeEventSourceAuthoringDiagnosticKind.sourceOptionNotFound,
        message: 'No selectable event source option matches "$sourceId".',
        path: 'source',
        referencedId: sourceId,
      ),
    );
  }

  return List<NarrativeEventSourceAuthoringDiagnostic>.unmodifiable(
    diagnostics,
  );
}

NarrativeScenarioAuthoringDraft replaceNarrativeScenarioAuthoringDraftSource(
  NarrativeScenarioAuthoringDraft draft,
  NarrativeScenarioAuthoringSourceDraft source,
) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: draft.scenarioId,
    name: draft.name,
    description: draft.description,
    scope: draft.scope,
    source: source,
    actions: draft.actions,
    declaredOutcomes: draft.declaredOutcomes,
    metadata: draft.metadata,
  );
}

void _collectMissingReferenceDiagnostics(
  NarrativeScenarioAuthoringSourceDraft source,
  List<NarrativeEventSourceAuthoringDiagnostic> diagnostics,
) {
  switch (source.kind) {
    case NarrativeScenarioAuthoringSourceKind.mapEnter:
      _requireReference(source.mapId, path: 'source.mapId', diagnostics);
    case NarrativeScenarioAuthoringSourceKind.triggerEnter:
      _requireReference(source.mapId, path: 'source.mapId', diagnostics);
      _requireReference(
          source.triggerId, path: 'source.triggerId', diagnostics);
    case NarrativeScenarioAuthoringSourceKind.entityInteract:
      _requireReference(source.mapId, path: 'source.mapId', diagnostics);
      _requireReference(source.entityId, path: 'source.entityId', diagnostics);
    case NarrativeScenarioAuthoringSourceKind.outcomeReceived:
      _requireReference(
          source.outcomeId, path: 'source.outcomeId', diagnostics);
  }
}

void _requireReference(
  String value,
  List<NarrativeEventSourceAuthoringDiagnostic> diagnostics, {
  required String path,
}) {
  if (value.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeEventSourceAuthoringDiagnostic(
      severity: NarrativeEventSourceAuthoringDiagnosticSeverity.error,
      kind: NarrativeEventSourceAuthoringDiagnosticKind.missingSourceReference,
      message: 'Event source reference is required.',
      path: path,
    ),
  );
}
```

### 12.5 Contenu complet du test créé

`packages/map_core/test/narrative_event_source_authoring_operations_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative event source authoring operations', () {
    test('converts picker options into source drafts', () {
      final options = _eventSourceOptions();

      final mapEnter =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.mapEnter),
      );
      expect(mapEnter.kind, NarrativeScenarioAuthoringSourceKind.mapEnter);
      expect(mapEnter.mapId, 'p4_map');

      final triggerEnter =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.triggerEnter),
      );
      expect(
          triggerEnter.kind, NarrativeScenarioAuthoringSourceKind.triggerEnter);
      expect(triggerEnter.mapId, 'p4_map');
      expect(triggerEnter.triggerId, 'p4_trigger');

      final entityInteract =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.entityInteract),
      );
      expect(
        entityInteract.kind,
        NarrativeScenarioAuthoringSourceKind.entityInteract,
      );
      expect(entityInteract.mapId, 'p4_map');
      expect(entityInteract.entityId, 'p4_npc');

      final outcomeReceived =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.outcomeReceived),
      );
      expect(
        outcomeReceived.kind,
        NarrativeScenarioAuthoringSourceKind.outcomeReceived,
      );
      expect(outcomeReceived.outcomeId, 'p4.outcome.ready');
    });

    test('calculates stable source ids aligned with picker options', () {
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.mapEnter(
            mapId: ' p4_map ',
          ),
        ),
        'mapEnter:p4_map',
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
            mapId: ' p4_map ',
            triggerId: ' p4_trigger ',
          ),
        ),
        'triggerEnter:p4_map:p4_trigger',
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: ' p4_map ',
            entityId: ' p4_npc ',
          ),
        ),
        'entityInteract:p4_map:p4_npc',
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
            outcomeId: ' p4.outcome.ready ',
          ),
        ),
        'outcomeReceived:p4.outcome.ready',
      );
    });

    test('finds matching picker options and returns null when unavailable', () {
      final options = _eventSourceOptions();
      final source = const NarrativeScenarioAuthoringSourceDraft.entityInteract(
        mapId: 'p4_map',
        entityId: 'p4_npc',
      );

      final found = findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
        source,
        options,
      );

      expect(found, isNotNull);
      expect(found!.sourceId, 'entityInteract:p4_map:p4_npc');

      final missing =
          findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
        const NarrativeScenarioAuthoringSourceDraft.entityInteract(
          mapId: 'p4_map',
          entityId: 'missing_npc',
        ),
        options,
      );
      expect(missing, isNull);
    });

    test('validates empty references and unavailable options', () {
      final missingReference =
          validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
        const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
          mapId: 'p4_map',
          triggerId: ' ',
        ),
        _eventSourceOptions(),
      );
      expect(
        _diagnosticKinds(missingReference),
        contains(
            NarrativeEventSourceAuthoringDiagnosticKind.missingSourceReference),
      );
      expect(missingReference.single.path, 'source.triggerId');

      final unavailable =
          validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
        const NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
          outcomeId: 'p4.outcome.missing',
        ),
        _eventSourceOptions(),
      );
      expect(
        _diagnosticKinds(unavailable),
        contains(
            NarrativeEventSourceAuthoringDiagnosticKind.sourceOptionNotFound),
      );
      expect(unavailable.single.referencedId,
          'outcomeReceived:p4.outcome.missing');
    });

    test('replaces draft source without mutating the original draft', () {
      final original = _draft(
        source: const NarrativeScenarioAuthoringSourceDraft.mapEnter(
          mapId: 'p4_map',
        ),
      );
      final nextSource =
          const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
        mapId: 'p4_map',
        triggerId: 'p4_trigger',
      );

      final replaced =
          replaceNarrativeScenarioAuthoringDraftSource(original, nextSource);

      expect(
          original.source!.kind, NarrativeScenarioAuthoringSourceKind.mapEnter);
      expect(replaced.source!.kind,
          NarrativeScenarioAuthoringSourceKind.triggerEnter);
      expect(replaced.scenarioId, original.scenarioId);
      expect(replaced.name, original.name);
      expect(replaced.description, original.description);
      expect(replaced.scope, original.scope);
      expect(replaced.actions, original.actions);
      expect(replaced.declaredOutcomes, original.declaredOutcomes);
      expect(replaced.metadata, original.metadata);
      expect(identical(replaced, original), isFalse);
    });

    test(
        'compiles updated drafts with the correct source node for every source',
        () {
      final cases = <_CompiledSourceExpectation>[
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.mapEnter(
            mapId: 'p4_map',
          ),
          actionKind: 'sourceMapEnter',
          mapId: 'p4_map',
        ),
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
            mapId: 'p4_map',
            triggerId: 'p4_trigger',
          ),
          actionKind: 'sourceTriggerEnter',
          mapId: 'p4_map',
          triggerId: 'p4_trigger',
        ),
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: 'p4_map',
            entityId: 'p4_npc',
          ),
          actionKind: 'sourceEntityInteract',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
            outcomeId: 'p4.outcome.ready',
          ),
          actionKind: 'sourceOutcome',
          outcomeId: 'p4.outcome.ready',
          scope: ScenarioScope.globalStory,
        ),
      ];

      for (final entry in cases) {
        final draft = replaceNarrativeScenarioAuthoringDraftSource(
          _draft(scope: entry.scope),
          entry.source,
        );
        final asset =
            compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);
        final sourceNode = asset.nodes.singleWhere(
          (node) => node.id == 'p4_authoring_event_source__source',
        );

        expect(sourceNode.type, ScenarioNodeType.reference);
        expect(sourceNode.payload.actionKind, entry.actionKind);
        expect(sourceNode.binding.mapId, entry.mapId);
        expect(sourceNode.binding.triggerId, entry.triggerId);
        expect(sourceNode.binding.entityId, entry.entityId);
        expect(sourceNode.binding.outcomeId, entry.outcomeId);
      }
    });

    test('does not hardcode Selbrume identifiers', () {
      final source =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(_eventSourceOptions(), NarrativeEventSourceKind.mapEnter),
      );
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        replaceNarrativeScenarioAuthoringDraftSource(_draft(), source),
      );

      final serialized = {
        narrativeEventSourceIdForAuthoringSourceDraft(source),
        asset.toJson().toString(),
      }.join('\n').toLowerCase();

      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

List<NarrativeEventSourcePickerOption> _eventSourceOptions() {
  return buildNarrativeEventSourcePickerOptions(
    ProjectManifest(
      name: 'P4 Event Source Operations Test',
      maps: const [
        ProjectMapEntry(
          id: 'p4_map',
          name: 'P4 Map',
          relativePath: 'maps/p4_map.json',
        ),
      ],
      tilesets: const [],
      scenarios: const [
        ScenarioAsset(
          id: 'p4_outcome_provider',
          name: 'P4 Outcome Provider',
          entryNodeId: 'source',
          declaredOutcomes: ['p4.outcome.ready'],
          nodes: [
            ScenarioNode(
              id: 'source',
              type: ScenarioNodeType.reference,
              payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
            ),
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(outcomeId: 'p4.outcome.ready'),
              payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
          ],
          edges: [
            ScenarioEdge(
                id: 'source_to_emit', fromNodeId: 'source', toNodeId: 'emit'),
          ],
        ),
      ],
    ),
    maps: const [
      MapData(
        id: 'p4_map',
        name: 'P4 Runtime Map',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
            id: 'p4_npc',
            name: 'P4 NPC',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 3),
            npc: MapEntityNpcData(displayName: 'P4 NPC'),
          ),
        ],
        triggers: [
          MapTrigger(
            id: 'p4_trigger',
            name: 'P4 Trigger',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
      ),
    ],
  );
}

NarrativeScenarioAuthoringDraft _draft({
  NarrativeScenarioAuthoringSourceDraft source =
      const NarrativeScenarioAuthoringSourceDraft.mapEnter(mapId: 'p4_map'),
  ScenarioScope scope = ScenarioScope.localEventFlow,
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: 'p4_authoring_event_source',
    name: 'P4 Authoring Event Source',
    description: 'Technical source replacement draft.',
    scope: scope,
    source: source,
    actions: const [
      NarrativeScenarioAuthoringActionDraft.setFlag(
        flagName: 'p4.authoring.source.executed',
      ),
    ],
    declaredOutcomes: const [],
    metadata: const {'authoring.test': 'p4-03'},
  );
}

NarrativeEventSourcePickerOption _bySourceKind(
  List<NarrativeEventSourcePickerOption> options,
  NarrativeEventSourceKind kind,
) {
  return options.singleWhere((option) => option.sourceKind == kind);
}

List<NarrativeEventSourceAuthoringDiagnosticKind> _diagnosticKinds(
  List<NarrativeEventSourceAuthoringDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}

final class _CompiledSourceExpectation {
  const _CompiledSourceExpectation({
    required this.source,
    required this.actionKind,
    this.mapId,
    this.triggerId,
    this.entityId,
    this.outcomeId,
    this.scope = ScenarioScope.localEventFlow,
  });

  final NarrativeScenarioAuthoringSourceDraft source;
  final String actionKind;
  final String? mapId;
  final String? triggerId;
  final String? entityId;
  final String? outcomeId;
  final ScenarioScope scope;
}
```

### 12.6 Diff complet des fichiers modifiés

`packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 48cb8ae9..5bfbbaf8 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -71,6 +71,7 @@ export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/narrative_validator.dart';
+export 'src/authoring/narrative_event_source_authoring_operations.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/operations/static_shadow_geometry.dart';
```

`MVP Selbrume/road_map_phase_4.md`

```diff
diff --git a/MVP Selbrume/road_map_phase_4.md b/MVP Selbrume/road_map_phase_4.md
index ea19e09d..79329b9e 100644
--- a/MVP Selbrume/road_map_phase_4.md	
+++ b/MVP Selbrume/road_map_phase_4.md	
@@ -6,17 +6,17 @@ Phase 4 — Authoring Workflows Minimal
 
 Statut : 🔜 Phase courante en exécution
 
-Lot courant : P4-03 — Event Source Authoring Draft Operations V0
+Lot courant : P4-04 — Outcome / Battle Outcome Authoring Operations V0
 
-Prochain lot exact : P4-03 — Event Source Authoring Draft Operations V0
+Prochain lot exact : P4-04 — Outcome / Battle Outcome Authoring Operations V0
 
 Suivi des lots :
 
 - ✅ P4-00 — Phase 4 Roadmap Recalibration / Authoring Workflow Audit
 - ✅ P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0
 - ✅ P4-02 — Scenario Authoring Draft Model V0
-- 🔜 P4-03 — Event Source Authoring Draft Operations V0
-- P4-04 — Outcome / Battle Outcome Authoring Operations V0
+- ✅ P4-03 — Event Source Authoring Draft Operations V0
+- 🔜 P4-04 — Outcome / Battle Outcome Authoring Operations V0
 - P4-05 — Predicate / World Rule Authoring Draft V0
 - P4-06 — Narrative Validator Authoring Adapter V0
 - P4-07 — Minimal Authoring Golden Path Test V0
@@ -28,7 +28,9 @@ P4-01 : ✅ terminé
 
 P4-02 : ✅ terminé
 
-P4-03 : 🔜 prochain lot exact
+P4-03 : ✅ terminé
+
+P4-04 : 🔜 prochain lot exact
 
 ## 2. Objectif de la Phase 4
 
@@ -210,7 +212,7 @@ Résultat P4-02 :
 - aucun widget UI, aucun registry persistant, aucune migration, aucun runtime,
   aucun contenu Selbrume et aucun reward/money/XP créé.
 
-### 🔜 P4-03 — Event Source Authoring Draft Operations V0
+### ✅ P4-03 — Event Source Authoring Draft Operations V0
 
 Objectif :
 Rendre authorables les sources `mapEnter`, `triggerEnter`, `entityInteract` et
@@ -225,7 +227,29 @@ Preuve concrète, pure et testée :
 - cas négatifs pour éviter les faux déclenchements ;
 - pas d'EventRegistry.
 
-### P4-04 — Outcome / Battle Outcome Authoring Operations V0
+Résultat P4-03 :
+
+- rapport créé :
+  `reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md` ;
+- opérations authoring pures ajoutées dans `map_core` :
+  `createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption`,
+  `narrativeEventSourceIdForAuthoringSourceDraft`,
+  `findNarrativeEventSourcePickerOptionForAuthoringSourceDraft`,
+  `validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions`,
+  `replaceNarrativeScenarioAuthoringDraftSource` ;
+- diagnostics Event Source V0 ajoutés :
+  `missingSourceReference`, `sourceOptionNotFound`,
+  `unsupportedEventSourceKind` ;
+- conversion depuis `NarrativeEventSourcePickerOption` prouvée pour
+  `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived` ;
+- compilation `draft -> ScenarioAsset` prouvée pour les quatre sources ;
+- tests ciblés ajoutés dans
+  `packages/map_core/test/narrative_event_source_authoring_operations_test.dart` ;
+- aucun widget UI, aucun EventRegistry, aucun registry persistant, aucune
+  migration, aucun runtime, aucun contenu Selbrume et aucun reward/money/XP
+  créé.
+
+### 🔜 P4-04 — Outcome / Battle Outcome Authoring Operations V0
 
 Objectif :
 Rendre authorables les outcomes scénario et battle outcomes sans registry.
@@ -328,5 +352,5 @@ Phase 4 doit produire des preuves authoring concrètes après P4-00.
 Le prochain lot exact est :
 
 ```text
-P4-03 — Event Source Authoring Draft Operations V0
+P4-04 — Outcome / Battle Outcome Authoring Operations V0
 ```
```

### 12.7 Sortie complète du test ciblé

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

### 12.8 Sorties complètes des régressions ciblées

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

### 12.9 Sortie dart analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

### 12.10 Sortie dart format

Commande :

```bash
cd packages/map_core && dart format --set-exit-if-changed lib/src/authoring/narrative_event_source_authoring_operations.dart test/narrative_event_source_authoring_operations_test.dart
```

Sortie finale :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

Note : une première exécution de `dart format --set-exit-if-changed` a formaté les deux fichiers nouvellement créés et a donc retourné un statut non nul attendu pour ce mode. La sortie finale ci-dessus prouve que le format est stabilisé.

### 12.11 git diff --check exact

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

### 12.12 git diff --stat exact

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map_phase_4.md    | 40 +++++++++++++++++++++++++++++--------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 33 insertions(+), 8 deletions(-)
```

### 12.13 git diff --name-only exact

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/map_core.dart
```

### 12.14 git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
?? packages/map_core/test/narrative_event_source_authoring_operations_test.dart
?? reports/roadmap/phase_4/p4_03_event_source_authoring_draft_operations.md
```

### 12.15 Contrôles explicites hors scope

- `road_map_global.md` n'a pas été modifié.
- P4-04 n'a pas été exécuté.
- Aucun contenu Selbrume final n'a été créé.
- Aucune UI premium n'a été créée.
- Aucun widget Flutter n'a été créé.
- Aucun EventRegistry ni registry persistant n'a été créé.
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

## 13. Auto-review critique

Points solides :

- la preuve est exécutable et couvre les quatre sources demandées ;
- les opérations restent pures, déterministes, sans I/O ni registry ;
- le comportement P4-02 n'est pas modifié ;
- les tests couvrent conversion, source ids, recherche d'option, diagnostics,
  remplacement non mutatif et compilation.

Limites :

- `unsupportedEventSourceKind` est une surface préventive non déclenchée par les enums actuels ;
- les diagnostics P4-03 ne sont pas encore branchés au validator narratif global ;
- l'authoring outcome/battle reste volontairement reporté à P4-04 ;
- aucun workflow UI n'est prouvé, conformément au scope.

Verdict :

```text
P4-03 : clôturable.
Prochain lot exact : P4-04 — Outcome / Battle Outcome Authoring Operations V0.
```

## 14. Regard critique sur le prompt

Le prompt est bien borné : il demande une brique authoring concrète sans basculer dans l'UI ou dans un registry persistant.

Le point le plus important était de ne pas transformer P4-03 en Event Builder. La bonne coupe est restée : picker option lisible -> source draft -> validation contre options -> remplacement non mutatif -> compilation existante.

Le prochain risque de scope est P4-04 : les outcomes et battle outcomes peuvent vite pousser vers un registry. Il faudra garder la même discipline que P4-03 : opérations pures, dérivation depuis les données existantes, diagnostics, tests, pas de nouvelle source de vérité persistante.
