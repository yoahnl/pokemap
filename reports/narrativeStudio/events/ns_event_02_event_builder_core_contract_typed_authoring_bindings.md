# NS-EVENT-02 — Event Builder Core Contract / Typed Authoring Bindings Prep

## 1. Résumé exécutif

NS-EVENT-02 est implémenté côté `map_core` uniquement. Le lot ajoute un contrat pur et typé pour le futur Event Builder MVP, sans créer de `EventAsset` parallèle et sans modifier l'UI, le runtime, `map_gameplay`, Selbrume ou les règles du monde.

Verdict : `NS-EVENT-02 : DONE`.

Le contrat repose sur les surfaces existantes :

- `MapEventDefinition` / `MapEventPage` restent canoniques ;
- `MapEventPage.sceneTarget` porte l'action principale "Jouer une scène" ;
- `ScriptCondition` porte les conditions MVP compilables ;
- `MapEventPage.metadata` porte uniquement la policy Event Builder via helpers typés ;
- les champs legacy `script`, `message`, metadata inconnues et conditions non supportées sont préservés.

## 2. Décisions prises

| Sujet | Décision | Justification |
|---|---|---|
| Modèle Event | Réutiliser `MapEventDefinition` et `MapEventPage`. | Conforme à NS-EVENT-01, évite un second système Event. |
| Action principale MVP | `EventBuilderSceneActionBinding` -> `MapEventSceneTarget`. | L'Event Builder MVP déclenche une Scene, pas un dialogue/combat/cinématique direct. |
| Conditions Fact | `factIsTrue` -> `ScriptCondition.flagIsSet`, `factIsFalse` -> `flagIsUnset`. | Mapping existant, typé, testable. |
| Conditions Event consumed | `eventConsumed` -> `ScriptCondition.eventIsConsumed`, `eventNotConsumed` -> `not(eventIsConsumed)`. | Mapping existant lié à `GameState.consumedEventIds`. |
| Conditions Story Step | Binding typé ajouté, mais compilation refusée en NS-EVENT-02. | Le modèle `ScriptCondition` n'a pas de condition Story Step dédiée ; encoder en flag opaque serait fragile et interdit par le prompt. |
| Behavior | `oneShot` / `reusable` via metadata encapsulée. | Aucun changement runtime ; la policy prépare NS-EVENT-03/04 sans muter `GameState`. |
| World impact preview | Preview minimale `consumedEvent` pour `oneShot`. | Suffisant pour annoncer les futures projections World Rules sans exécuter de règles. |
| Legacy | Diagnostics warning/error, préservation sans migration. | Backward-compatible et sans suppression hors scope. |

## 3. Contrat Event Builder ajouté

Nouveau fichier : `packages/map_core/lib/src/authoring/event_builder_contract.dart`.

Surfaces principales :

- `EventBuilderTriggerKind`
- `EventBuilderTriggerBinding`
- `EventBuilderSourceBinding`
- `EventBuilderConditionKind`
- `EventBuilderConditionBinding`
- `EventBuilderSceneActionBinding`
- `EventBuilderReusePolicy`
- `EventBuilderBehaviorBinding`
- `EventBuilderWorldImpactPreview`
- `EventBuilderContractDiagnostic`
- `EventBuilderContractView`
- `compileEventBuilderConditionsToScriptCondition`

Le contrat expose des value objects no-code. Les métadonnées restent encapsulées par `EventBuilderMetadataKeys` et ne deviennent pas une API libre de l'UI.

## 4. Stockage retenu

Le stockage reste l'existant :

```text
MapEventDefinition
└── MapEventPage
    ├── condition: ScriptCondition?
    ├── sceneTarget: MapEventSceneTarget?
    ├── script/message: legacy préservé
    └── metadata:
        ├── eventBuilder.schemaVersion = 1
        └── eventBuilder.reusePolicy = oneShot | reusable
```

Aucun nouveau catalogue, manifest section ou asset n'a été créé.

## 5. Gestion de MapEventDefinition / MapEventPage

Nouveau fichier : `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`.

Opérations ajoutées :

- `readEventBuilderContractFromMapEvent`
- `createEventBuilderDraftForMapEvent`
- `applyEventBuilderContractToMapEvent`
- `updateEventBuilderTrigger`
- `updateEventBuilderSceneAction`
- `addEventBuilderCondition`
- `removeEventBuilderCondition`
- `updateEventBuilderBehavior`

La lecture sélectionne par défaut la page au plus petit `pageNumber`, ou une page précise si `pageNumber` est fourni.

## 6. Gestion de MapEventSceneTarget

`EventBuilderSceneActionBinding(sceneId: ...)` est la seule action principale MVP. À l'application du contrat, elle écrit :

```dart
MapEventSceneTarget(sceneId: contract.sceneAction!.sceneId)
```

Les actions directes dialogue/cinématique/battle/récompense/téléport/heal sont volontairement absentes.

## 7. Gestion des conditions Fact / Event consumed / Step

Conditions supportées et compilées :

| Binding | ScriptCondition |
|---|---|
| `factIsTrue(id)` | `flagIsSet(id)` |
| `factIsFalse(id)` | `flagIsUnset(id)` |
| `eventConsumed(id)` | `eventIsConsumed(id)` |
| `eventNotConsumed(id)` | `not(eventIsConsumed(id))` |

Story Step :

- `storyStepCompleted(id)` et `storyStepNotCompleted(id)` existent comme bindings typés ;
- ils produisent un diagnostic `unsupportedStoryStepCondition` lors de la compilation ;
- `applyEventBuilderContractToMapEvent` refuse de les écrire dans `ScriptCondition` en lançant `UnsupportedError` ;
- aucun flag opaque ou variable bricolée n'est généré.

Décision future recommandée : un lot dédié doit ajouter un support propre Story Step -> condition runtime, probablement via une extension explicite de `ScriptConditionType` ou une autre surface narrative canonique.

## 8. Gestion du behavior oneShot/reusable

`EventBuilderBehaviorBinding` expose :

- `oneShot`
- `reusable`

La lecture d'une page sans metadata Event Builder retourne `oneShot` par défaut. Une metadata inconnue est diagnostiquée avec `metadataMalformed` et retombe sur `oneShot` sans crash.

Ce lot ne change pas :

- `SceneEventRuntimeHook`
- `SceneConsequenceRuntimeWriter`
- `GameState`
- `map_gameplay`

## 9. Gestion des metadata

Clés créées :

```text
eventBuilder.schemaVersion
eventBuilder.reusePolicy
```

Les metadata inconnues existantes sont préservées par écriture additive.

## 10. Compatibilité legacy

Cas couverts :

- event legacy sans metadata : lisible ;
- page legacy avec `sceneTarget` : lue comme action Scene ;
- `script` et `message` legacy : préservés et diagnostiqués en warning ;
- conditions legacy non MVP : préservées si le contrat ne remplace pas les conditions ;
- conditions legacy mal formées : diagnostic au lieu d'un crash ;
- metadata inconnues : préservées.

## 11. Tests ajoutés

Fichiers créés :

- `packages/map_core/test/event_builder_contract_test.dart`
- `packages/map_core/test/event_builder_authoring_operations_test.dart`

Couverture ajoutée :

- validation des IDs vides ;
- compilation Fact/Event consumed ;
- refus Story Step comme flag opaque ;
- lecture legacy ;
- écriture `MapEventSceneTarget` ;
- préservation `script`, `message`, metadata ;
- robustesse condition legacy mal formée.

## 12. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart
```

Sortie utile exacte :

```text
Failed to load "test/event_builder_contract_test.dart":
Error: Method not found: 'EventBuilderSourceBinding'.
Error: Undefined name 'EventBuilderConditionBinding'.
Error: Method not found: 'EventBuilderSceneActionBinding'.
Error: Couldn't find constructor 'EventBuilderBehaviorBinding.oneShot'.
Error: Method not found: 'compileEventBuilderConditionsToScriptCondition'.
Failed to load "test/event_builder_authoring_operations_test.dart":
Error: Method not found: 'readEventBuilderContractFromMapEvent'.
Error: Method not found: 'applyEventBuilderContractToMapEvent'.
Error: Undefined name 'EventBuilderMetadataKeys'.
Some tests failed.
```

### Format

Commande :

```bash
cd packages/map_core && dart format lib/src/authoring/event_builder_authoring_operations.dart test/event_builder_authoring_operations_test.dart
```

Sortie exacte :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

### Tests ciblés GREEN

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart
```

Sortie finale exacte :

```text
00:00 +14: All tests passed!
```

### Régression complète map_core

Commande :

```bash
cd packages/map_core && dart test --reporter=compact
```

Sortie finale utile exacte :

```text
00:05 +2545: All tests passed!
EXIT_CODE=0
```

### Analyse complète map_core

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
EXIT_CODE=0
```

## 13. Limites

- Les conditions Story Step sont typées mais non compilables dans ce lot.
- Les conséquences `SceneConsequence` sont seulement préparées conceptuellement via preview/diagnostics ; NS-EVENT-02 ne modifie aucun writer runtime.
- La preview World Rules reste minimale et non exécutée.
- Aucun read model UI Event Builder n'est encore construit ; c'est le rôle de NS-EVENT-03.
- Aucun validator global Event Builder n'est créé dans ce lot.

## 14. Impact sur NS-EVENT-03

NS-EVENT-03 peut maintenant consommer une surface typée au lieu de lire directement :

- `MapEventPage.condition`
- `MapEventPage.sceneTarget`
- `MapEventPage.metadata`
- `script/message` legacy

Prochain lot recommandé :

```text
NS-EVENT-03 — Event Builder Read Model / Diagnostics V0
```

Objectif recommandé : construire la vue no-code de lecture, grouper les diagnostics et préparer les labels UX, sans UI complète.

## 15. Peut-on grouper NS-EVENT-03 avec autre chose ?

Décision : possible uniquement avec un petit lot diagnostics/read model, mais déconseillé de grouper avec UI.

- Grouper avec UI shell : non, trop gros.
- Grouper avec runtime bridge : non, trop tôt.
- Grouper avec Story Step condition support : non, décision modèle à part.
- Grouper avec diagnostics read model : oui si le lot reste `map_core` pur.

## 16. Evidence Pack complet

### Gate 0 initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
f16314fe NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
```

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

### Règles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `pokemap_roadmap_mecaniques_fangame.md`

### Fichiers lus

- `reports/narrativeStudio/events/ns_event_01_existing_surface_contract_alignment.md`
- `reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/checklist_beta_pokemap.md`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/operations/map_events.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_core/test/map_events_test.dart`
- `packages/map_core/test/event_scene_link_diagnostics_test.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_editor/test/event_properties_panel_scene_target_test.dart`

### Fichiers créés

- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/test/event_builder_contract_test.dart`
- `packages/map_core/test/event_builder_authoring_operations_test.dart`
- `reports/narrativeStudio/events/ns_event_02_event_builder_core_contract_typed_authoring_bindings.md`

### Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

Modification :

```dart
export 'src/authoring/event_builder_authoring_operations.dart';
export 'src/authoring/event_builder_contract.dart';
```

### Fichiers supprimés

Aucun.

### Contenu complet des nouveaux fichiers de code

#### `packages/map_core/lib/src/authoring/event_builder_contract.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/map_event_definition.dart';
import '../models/script_conditions.dart';

/// Clés de metadata réservées au contrat Event Builder.
///
/// Le stockage canonique reste [MapEventDefinition] / [MapEventPage].
/// Ces clés ne sont qu'un petit pont backward-compatible pour les propriétés
/// MVP qui n'existent pas encore comme champs typés sur [MapEventPage].
abstract final class EventBuilderMetadataKeys {
  static const String schemaVersion = 'eventBuilder.schemaVersion';
  static const String currentSchemaVersion = '1';
  static const String reusePolicy = 'eventBuilder.reusePolicy';
}

enum EventBuilderTriggerKind {
  interaction,
  zoneEnter,
}

enum EventBuilderConditionKind {
  factIsTrue,
  factIsFalse,
  eventConsumed,
  eventNotConsumed,
  storyStepCompleted,
  storyStepNotCompleted,
}

enum EventBuilderReusePolicy {
  oneShot,
  reusable,
}

enum EventBuilderWorldImpactKind {
  fact,
  storyStep,
  consumedEvent,
}

enum EventBuilderContractDiagnosticSeverity {
  info,
  warning,
  error,
}

enum EventBuilderContractDiagnosticKind {
  unsupportedLegacyCondition,
  unsupportedLegacyScript,
  unsupportedLegacyMessage,
  missingSceneAction,
  unsupportedStoryStepCondition,
  metadataMalformed,
}

/// Source stable utilisée par le futur Event Builder.
///
/// Elle encapsule le [MapEventDefinition] sans exposer au workflow normal les
/// détails de pages ou de metadata. Le mapId n'est pas ici : le lot reste centré
/// sur un event déjà fourni par un contexte de map.
@immutable
final class EventBuilderSourceBinding {
  EventBuilderSourceBinding({
    required String eventId,
    required String eventTitle,
    required this.eventType,
    required this.position,
  })  : eventId = _requireTrimmed(eventId, 'eventId'),
        eventTitle = eventTitle.trim();

  final String eventId;
  final String eventTitle;
  final MapEventType eventType;
  final EventPosition position;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBuilderSourceBinding &&
          other.eventId == eventId &&
          other.eventTitle == eventTitle &&
          other.eventType == eventType &&
          other.position == position;

  @override
  int get hashCode => Object.hash(eventId, eventTitle, eventType, position);
}

@immutable
final class EventBuilderTriggerBinding {
  const EventBuilderTriggerBinding({
    required this.kind,
    required this.source,
  });

  final EventBuilderTriggerKind kind;
  final EventBuilderSourceBinding source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBuilderTriggerBinding &&
          other.kind == kind &&
          other.source == source;

  @override
  int get hashCode => Object.hash(kind, source);
}

/// Condition no-code MVP.
///
/// Les factories refusent les IDs vides pour éviter que le futur UI affiche un
/// état "configuré" qui ne pourrait pas être compilé ou diagnostiqué proprement.
@immutable
final class EventBuilderConditionBinding {
  EventBuilderConditionBinding._({
    required this.kind,
    required String referenceId,
    this.label,
  }) : referenceId = _requireTrimmed(referenceId, 'referenceId');

  factory EventBuilderConditionBinding.factIsTrue(
    String factId, {
    String? label,
  }) {
    return EventBuilderConditionBinding._(
      kind: EventBuilderConditionKind.factIsTrue,
      referenceId: factId,
      label: _trimOptional(label),
    );
  }

  factory EventBuilderConditionBinding.factIsFalse(
    String factId, {
    String? label,
  }) {
    return EventBuilderConditionBinding._(
      kind: EventBuilderConditionKind.factIsFalse,
      referenceId: factId,
      label: _trimOptional(label),
    );
  }

  factory EventBuilderConditionBinding.eventConsumed(
    String eventId, {
    String? label,
  }) {
    return EventBuilderConditionBinding._(
      kind: EventBuilderConditionKind.eventConsumed,
      referenceId: eventId,
      label: _trimOptional(label),
    );
  }

  factory EventBuilderConditionBinding.eventNotConsumed(
    String eventId, {
    String? label,
  }) {
    return EventBuilderConditionBinding._(
      kind: EventBuilderConditionKind.eventNotConsumed,
      referenceId: eventId,
      label: _trimOptional(label),
    );
  }

  factory EventBuilderConditionBinding.storyStepCompleted(
    String stepId, {
    String? label,
  }) {
    return EventBuilderConditionBinding._(
      kind: EventBuilderConditionKind.storyStepCompleted,
      referenceId: stepId,
      label: _trimOptional(label),
    );
  }

  factory EventBuilderConditionBinding.storyStepNotCompleted(
    String stepId, {
    String? label,
  }) {
    return EventBuilderConditionBinding._(
      kind: EventBuilderConditionKind.storyStepNotCompleted,
      referenceId: stepId,
      label: _trimOptional(label),
    );
  }

  final EventBuilderConditionKind kind;
  final String referenceId;
  final String? label;

  /// Compile seulement le sous-ensemble que [ScriptCondition] sait exprimer
  /// sans mensonge.
  ///
  /// Les Story Steps restent typés ici, mais non compilés : le modèle actuel
  /// n'a pas de `ScriptConditionType.storyStepCompleted`. Les encoder comme un
  /// flag ou une variable opaque casserait la frontière produit du lot.
  ScriptCondition? toScriptCondition() {
    return switch (kind) {
      EventBuilderConditionKind.factIsTrue =>
        ScriptConditionFactory.flagIsSet(referenceId),
      EventBuilderConditionKind.factIsFalse =>
        ScriptConditionFactory.flagIsUnset(referenceId),
      EventBuilderConditionKind.eventConsumed =>
        ScriptConditionFactory.eventIsConsumed(referenceId),
      EventBuilderConditionKind.eventNotConsumed => ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed(referenceId),
        ),
      EventBuilderConditionKind.storyStepCompleted ||
      EventBuilderConditionKind.storyStepNotCompleted =>
        null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBuilderConditionBinding &&
          other.kind == kind &&
          other.referenceId == referenceId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, referenceId, label);
}

@immutable
final class EventBuilderSceneActionBinding {
  EventBuilderSceneActionBinding({
    required String sceneId,
    String? label,
  })  : sceneId = _requireTrimmed(sceneId, 'sceneId'),
        label = _trimOptional(label);

  final String sceneId;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBuilderSceneActionBinding &&
          other.sceneId == sceneId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(sceneId, label);
}

@immutable
final class EventBuilderBehaviorBinding {
  const EventBuilderBehaviorBinding({
    required this.reusePolicy,
  });

  const EventBuilderBehaviorBinding.oneShot()
      : this(reusePolicy: EventBuilderReusePolicy.oneShot);

  const EventBuilderBehaviorBinding.reusable()
      : this(reusePolicy: EventBuilderReusePolicy.reusable);

  final EventBuilderReusePolicy reusePolicy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBuilderBehaviorBinding && other.reusePolicy == reusePolicy;

  @override
  int get hashCode => reusePolicy.hashCode;
}

@immutable
final class EventBuilderWorldImpactPreview {
  EventBuilderWorldImpactPreview({
    required this.kind,
    required String sourceId,
    String? label,
    String? reason,
  })  : sourceId = _requireTrimmed(sourceId, 'sourceId'),
        label = _trimOptional(label),
        reason = _trimOptional(reason);

  final EventBuilderWorldImpactKind kind;
  final String sourceId;
  final String? label;
  final String? reason;
}

@immutable
final class EventBuilderContractDiagnostic {
  const EventBuilderContractDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final EventBuilderContractDiagnosticSeverity severity;
  final EventBuilderContractDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

@immutable
final class EventBuilderConditionCompileResult {
  const EventBuilderConditionCompileResult({
    required this.condition,
    required this.diagnostics,
  });

  final ScriptCondition? condition;
  final List<EventBuilderContractDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == EventBuilderContractDiagnosticSeverity.error,
      );
}

/// Vue contractuelle minimale consommable par le futur read model Event Builder.
///
/// [legacyConditionToPreserve] protège les anciennes conditions non supportées :
/// les lire ne doit pas les effacer lors d'une application qui ne touche pas
/// explicitement les conditions.
@immutable
final class EventBuilderContractView {
  EventBuilderContractView({
    required this.source,
    required this.trigger,
    required List<EventBuilderConditionBinding> conditions,
    required this.sceneAction,
    required this.behavior,
    required List<EventBuilderWorldImpactPreview> worldImpactPreviews,
    required List<EventBuilderContractDiagnostic> diagnostics,
    this.legacyConditionToPreserve,
  })  : conditions =
            List<EventBuilderConditionBinding>.unmodifiable(conditions),
        worldImpactPreviews = List<EventBuilderWorldImpactPreview>.unmodifiable(
          worldImpactPreviews,
        ),
        diagnostics =
            List<EventBuilderContractDiagnostic>.unmodifiable(diagnostics);

  final EventBuilderSourceBinding source;
  final EventBuilderTriggerBinding trigger;
  final List<EventBuilderConditionBinding> conditions;
  final EventBuilderSceneActionBinding? sceneAction;
  final EventBuilderBehaviorBinding behavior;
  final List<EventBuilderWorldImpactPreview> worldImpactPreviews;
  final List<EventBuilderContractDiagnostic> diagnostics;
  final ScriptCondition? legacyConditionToPreserve;

  EventBuilderContractView copyWith({
    EventBuilderSourceBinding? source,
    EventBuilderTriggerBinding? trigger,
    List<EventBuilderConditionBinding>? conditions,
    EventBuilderSceneActionBinding? sceneAction,
    bool clearSceneAction = false,
    EventBuilderBehaviorBinding? behavior,
    List<EventBuilderWorldImpactPreview>? worldImpactPreviews,
    List<EventBuilderContractDiagnostic>? diagnostics,
    ScriptCondition? legacyConditionToPreserve,
    bool clearLegacyConditionToPreserve = false,
  }) {
    return EventBuilderContractView(
      source: source ?? this.source,
      trigger: trigger ?? this.trigger,
      conditions: conditions ?? this.conditions,
      sceneAction: clearSceneAction ? null : (sceneAction ?? this.sceneAction),
      behavior: behavior ?? this.behavior,
      worldImpactPreviews: worldImpactPreviews ?? this.worldImpactPreviews,
      diagnostics: diagnostics ?? this.diagnostics,
      legacyConditionToPreserve: clearLegacyConditionToPreserve
          ? null
          : (legacyConditionToPreserve ?? this.legacyConditionToPreserve),
    );
  }
}

EventBuilderConditionCompileResult
    compileEventBuilderConditionsToScriptCondition(
  List<EventBuilderConditionBinding> bindings,
) {
  final diagnostics = <EventBuilderContractDiagnostic>[];
  final compiled = <ScriptCondition>[];

  for (var i = 0; i < bindings.length; i++) {
    final binding = bindings[i];
    final condition = binding.toScriptCondition();
    if (condition == null) {
      diagnostics.add(
        EventBuilderContractDiagnostic(
          severity: EventBuilderContractDiagnosticSeverity.error,
          kind:
              EventBuilderContractDiagnosticKind.unsupportedStoryStepCondition,
          message: 'Story Step conditions are typed but not compiled in '
              'NS-EVENT-02.',
          path: 'conditions[$i]',
          referencedId: binding.referenceId,
        ),
      );
      continue;
    }
    compiled.add(condition);
  }

  final condition = switch (compiled.length) {
    0 => null,
    1 => compiled.single,
    _ => ScriptConditionFactory.allOf(compiled),
  };

  return EventBuilderConditionCompileResult(
    condition: condition,
    diagnostics: List<EventBuilderContractDiagnostic>.unmodifiable(
      diagnostics,
    ),
  );
}

String _requireTrimmed(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, '$name is required.');
  }
  return trimmed;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

```

#### `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`

```dart
import '../models/map_event_definition.dart';
import '../models/script_conditions.dart';
import 'event_builder_contract.dart';

/// Lit une page de [MapEventDefinition] comme contrat Event Builder MVP.
///
/// Cette fonction ne migre rien et ne supprime rien. Elle traduit seulement le
/// sous-ensemble no-code supporté par NS-EVENT-02, puis transporte les limites
/// legacy sous forme de diagnostics.
EventBuilderContractView readEventBuilderContractFromMapEvent(
  MapEventDefinition event, {
  int? pageNumber,
}) {
  final page = _selectPage(event, pageNumber: pageNumber);
  final source = EventBuilderSourceBinding(
    eventId: event.id,
    eventTitle: event.title,
    eventType: event.type,
    position: event.position,
  );
  final trigger = EventBuilderTriggerBinding(
    kind: _triggerKindForEventType(event.type),
    source: source,
  );
  final diagnostics = <EventBuilderContractDiagnostic>[];
  final conditions = _readConditionBindings(
    page.condition,
    diagnostics,
    path: 'page.condition',
  );
  final sceneAction = _readSceneAction(page.sceneTarget);
  final behavior = _readBehaviorBinding(page.metadata, diagnostics);

  if (sceneAction == null) {
    diagnostics.add(
      EventBuilderContractDiagnostic(
        severity: EventBuilderContractDiagnosticSeverity.error,
        kind: EventBuilderContractDiagnosticKind.missingSceneAction,
        message: 'Event Builder MVP requires a Scene action.',
        path: 'page.sceneTarget',
      ),
    );
  }
  if (page.script != null) {
    diagnostics.add(
      EventBuilderContractDiagnostic(
        severity: EventBuilderContractDiagnosticSeverity.warning,
        kind: EventBuilderContractDiagnosticKind.unsupportedLegacyScript,
        message: 'Legacy script references are preserved but not part of the '
            'Event Builder MVP contract.',
        path: 'page.script',
        referencedId: page.script?.scriptId,
      ),
    );
  }
  if ((page.message ?? '').trim().isNotEmpty) {
    diagnostics.add(
      EventBuilderContractDiagnostic(
        severity: EventBuilderContractDiagnosticSeverity.warning,
        kind: EventBuilderContractDiagnosticKind.unsupportedLegacyMessage,
        message: 'Legacy page messages are preserved but not part of the '
            'Event Builder MVP contract.',
        path: 'page.message',
      ),
    );
  }

  return EventBuilderContractView(
    source: source,
    trigger: trigger,
    conditions: conditions,
    sceneAction: sceneAction,
    behavior: behavior,
    worldImpactPreviews: _buildWorldImpactPreviews(
      source: source,
      behavior: behavior,
    ),
    diagnostics: diagnostics,
    legacyConditionToPreserve: conditions.isEmpty ? page.condition : null,
  );
}

EventBuilderContractView createEventBuilderDraftForMapEvent(
  MapEventDefinition event, {
  int? pageNumber,
}) {
  return readEventBuilderContractFromMapEvent(
    event,
    pageNumber: pageNumber,
  );
}

/// Applique un contrat Event Builder sur une page existante.
///
/// La fonction écrit seulement les surfaces MVP : [MapEventSceneTarget],
/// [ScriptCondition] compilable et metadata typée Event Builder. Les champs
/// legacy tels que `script` ou `message` sont volontairement préservés.
MapEventDefinition applyEventBuilderContractToMapEvent(
  MapEventDefinition event,
  EventBuilderContractView contract, {
  int? pageNumber,
}) {
  final pageIndex = _selectPageIndex(event, pageNumber: pageNumber);
  final page = event.pages[pageIndex];
  final compiled = compileEventBuilderConditionsToScriptCondition(
    contract.conditions,
  );
  if (compiled.hasErrors) {
    throw UnsupportedError(
      'Event Builder contract contains conditions that cannot be compiled '
      'to ScriptCondition in NS-EVENT-02.',
    );
  }

  final nextCondition = compiled.condition ??
      (contract.conditions.isEmpty ? contract.legacyConditionToPreserve : null);
  final nextPage = page.copyWith(
    sceneTarget: contract.sceneAction == null
        ? null
        : MapEventSceneTarget(sceneId: contract.sceneAction!.sceneId),
    condition: nextCondition,
    metadata: _writeBehaviorMetadata(
      page.metadata,
      contract.behavior,
    ),
  );
  final nextPages = List<MapEventPage>.from(event.pages, growable: false);
  nextPages[pageIndex] = nextPage;
  return event.copyWith(pages: nextPages);
}

EventBuilderContractView updateEventBuilderTrigger(
  EventBuilderContractView contract,
  EventBuilderTriggerBinding trigger,
) {
  return contract.copyWith(
    source: trigger.source,
    trigger: trigger,
  );
}

EventBuilderContractView updateEventBuilderSceneAction(
  EventBuilderContractView contract,
  EventBuilderSceneActionBinding action,
) {
  return contract.copyWith(sceneAction: action);
}

EventBuilderContractView addEventBuilderCondition(
  EventBuilderContractView contract,
  EventBuilderConditionBinding condition,
) {
  return contract.copyWith(
    conditions: [...contract.conditions, condition],
    clearLegacyConditionToPreserve: true,
  );
}

EventBuilderContractView removeEventBuilderCondition(
  EventBuilderContractView contract,
  int index,
) {
  if (index < 0 || index >= contract.conditions.length) {
    throw RangeError.index(index, contract.conditions, 'index');
  }
  final nextConditions = contract.conditions.toList(growable: true)
    ..removeAt(index);
  return contract.copyWith(
    conditions: nextConditions,
    clearLegacyConditionToPreserve: true,
  );
}

EventBuilderContractView updateEventBuilderBehavior(
  EventBuilderContractView contract,
  EventBuilderBehaviorBinding behavior,
) {
  return contract.copyWith(behavior: behavior);
}

MapEventPage _selectPage(
  MapEventDefinition event, {
  required int? pageNumber,
}) {
  final pageIndex = _selectPageIndex(event, pageNumber: pageNumber);
  return event.pages[pageIndex];
}

int _selectPageIndex(
  MapEventDefinition event, {
  required int? pageNumber,
}) {
  if (event.pages.isEmpty) {
    throw ArgumentError.value(event.id, 'event', 'Map event has no pages.');
  }
  if (pageNumber == null) {
    var selectedIndex = 0;
    for (var i = 1; i < event.pages.length; i++) {
      if (event.pages[i].pageNumber < event.pages[selectedIndex].pageNumber) {
        selectedIndex = i;
      }
    }
    return selectedIndex;
  }
  final index = event.pages.indexWhere((page) => page.pageNumber == pageNumber);
  if (index < 0) {
    throw ArgumentError.value(
      pageNumber,
      'pageNumber',
      'Map event page not found.',
    );
  }
  return index;
}

EventBuilderTriggerKind _triggerKindForEventType(MapEventType type) {
  return switch (type) {
    MapEventType.triggerZone => EventBuilderTriggerKind.zoneEnter,
    MapEventType.actor ||
    MapEventType.object ||
    MapEventType.effect =>
      EventBuilderTriggerKind.interaction,
  };
}

EventBuilderSceneActionBinding? _readSceneAction(
  MapEventSceneTarget? sceneTarget,
) {
  final sceneId = sceneTarget?.sceneId.trim();
  if (sceneId == null || sceneId.isEmpty) {
    return null;
  }
  return EventBuilderSceneActionBinding(sceneId: sceneId);
}

EventBuilderBehaviorBinding _readBehaviorBinding(
  Map<String, String> metadata,
  List<EventBuilderContractDiagnostic> diagnostics,
) {
  final raw = metadata[EventBuilderMetadataKeys.reusePolicy]?.trim();
  if (raw == null || raw.isEmpty) {
    return const EventBuilderBehaviorBinding.oneShot();
  }
  for (final policy in EventBuilderReusePolicy.values) {
    if (policy.name == raw) {
      return EventBuilderBehaviorBinding(reusePolicy: policy);
    }
  }
  diagnostics.add(
    EventBuilderContractDiagnostic(
      severity: EventBuilderContractDiagnosticSeverity.warning,
      kind: EventBuilderContractDiagnosticKind.metadataMalformed,
      message: 'Unknown Event Builder reuse policy "$raw"; defaulting to '
          'oneShot.',
      path: 'page.metadata.${EventBuilderMetadataKeys.reusePolicy}',
    ),
  );
  return const EventBuilderBehaviorBinding.oneShot();
}

Map<String, String> _writeBehaviorMetadata(
  Map<String, String> current,
  EventBuilderBehaviorBinding behavior,
) {
  return Map<String, String>.unmodifiable({
    ...current,
    EventBuilderMetadataKeys.schemaVersion:
        EventBuilderMetadataKeys.currentSchemaVersion,
    EventBuilderMetadataKeys.reusePolicy: behavior.reusePolicy.name,
  });
}

List<EventBuilderConditionBinding> _readConditionBindings(
  ScriptCondition? condition,
  List<EventBuilderContractDiagnostic> diagnostics, {
  required String path,
}) {
  if (condition == null) {
    return const <EventBuilderConditionBinding>[];
  }
  final bindings = <EventBuilderConditionBinding>[];
  _appendConditionBindings(condition, bindings, diagnostics, path: path);
  return List<EventBuilderConditionBinding>.unmodifiable(bindings);
}

void _appendConditionBindings(
  ScriptCondition condition,
  List<EventBuilderConditionBinding> bindings,
  List<EventBuilderContractDiagnostic> diagnostics, {
  required String path,
}) {
  switch (condition.type) {
    case ScriptConditionType.flagIsSet:
      final flagName = condition.params[ScriptConditionParams.flagName];
      if ((flagName ?? '').trim().isNotEmpty) {
        bindings.add(EventBuilderConditionBinding.factIsTrue(flagName!));
        return;
      }
    case ScriptConditionType.flagIsUnset:
      final flagName = condition.params[ScriptConditionParams.flagName];
      if ((flagName ?? '').trim().isNotEmpty) {
        bindings.add(EventBuilderConditionBinding.factIsFalse(flagName!));
        return;
      }
    case ScriptConditionType.eventIsConsumed:
      final eventId = condition.params[ScriptConditionParams.eventId];
      if ((eventId ?? '').trim().isNotEmpty) {
        bindings.add(EventBuilderConditionBinding.eventConsumed(eventId!));
        return;
      }
    case ScriptConditionType.not:
      final child =
          condition.children.length == 1 ? condition.children.single : null;
      if (child?.type == ScriptConditionType.eventIsConsumed) {
        final eventId = child?.params[ScriptConditionParams.eventId];
        if ((eventId ?? '').trim().isNotEmpty) {
          bindings.add(EventBuilderConditionBinding.eventNotConsumed(eventId!));
          return;
        }
      }
    case ScriptConditionType.allOf:
      for (var i = 0; i < condition.children.length; i++) {
        _appendConditionBindings(
          condition.children[i],
          bindings,
          diagnostics,
          path: '$path.children[$i]',
        );
      }
      return;
    case ScriptConditionType.anyOf:
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
    case ScriptConditionType.playerOnMap:
      break;
  }

  diagnostics.add(
    EventBuilderContractDiagnostic(
      severity: EventBuilderContractDiagnosticSeverity.warning,
      kind: EventBuilderContractDiagnosticKind.unsupportedLegacyCondition,
      message: 'Existing ScriptCondition is preserved but is not part of '
          'the Event Builder MVP no-code subset.',
      path: path,
    ),
  );
}

List<EventBuilderWorldImpactPreview> _buildWorldImpactPreviews({
  required EventBuilderSourceBinding source,
  required EventBuilderBehaviorBinding behavior,
}) {
  if (behavior.reusePolicy != EventBuilderReusePolicy.oneShot) {
    return const <EventBuilderWorldImpactPreview>[];
  }
  return [
    EventBuilderWorldImpactPreview(
      kind: EventBuilderWorldImpactKind.consumedEvent,
      sourceId: source.eventId,
      label: source.eventTitle.isEmpty ? source.eventId : source.eventTitle,
      reason: 'A one-shot event can drive World Rules through consumed event '
          'state after the Scene succeeds.',
    ),
  ];
}

```

#### `packages/map_core/test/event_builder_contract_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder contract bindings', () {
    test('EventBuilderTriggerBinding refuses empty source ids', () {
      expect(
        () => EventBuilderSourceBinding(
          eventId: ' ',
          eventTitle: 'Rival',
          eventType: MapEventType.actor,
          position: const EventPosition(layerId: 'actors', x: 2, y: 3),
        ),
        throwsArgumentError,
      );
    });

    test('EventBuilderConditionBinding refuses empty ids', () {
      expect(
        () => EventBuilderConditionBinding.factIsTrue(' '),
        throwsArgumentError,
      );
      expect(
        () => EventBuilderConditionBinding.eventConsumed(' '),
        throwsArgumentError,
      );
    });

    test('EventBuilderSceneActionBinding refuses empty scene ids', () {
      expect(
        () => EventBuilderSceneActionBinding(sceneId: ' '),
        throwsArgumentError,
      );
    });

    test('EventBuilderBehaviorBinding supports oneShot and reusable', () {
      expect(
        const EventBuilderBehaviorBinding.oneShot().reusePolicy,
        EventBuilderReusePolicy.oneShot,
      );
      expect(
        const EventBuilderBehaviorBinding.reusable().reusePolicy,
        EventBuilderReusePolicy.reusable,
      );
    });

    test('fact conditions compile to script conditions', () {
      expect(
        EventBuilderConditionBinding.factIsTrue('fact_rival_seen')
            .toScriptCondition(),
        ScriptConditionFactory.flagIsSet('fact_rival_seen'),
      );
      expect(
        EventBuilderConditionBinding.factIsFalse('fact_rival_seen')
            .toScriptCondition(),
        ScriptConditionFactory.flagIsUnset('fact_rival_seen'),
      );
    });

    test('event consumed conditions compile to script conditions', () {
      expect(
        EventBuilderConditionBinding.eventConsumed('evt_rival')
            .toScriptCondition(),
        ScriptConditionFactory.eventIsConsumed('evt_rival'),
      );
      expect(
        EventBuilderConditionBinding.eventNotConsumed('evt_rival')
            .toScriptCondition(),
        ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed('evt_rival'),
        ),
      );
    });

    test('story step conditions stay typed but unsupported for ScriptCondition',
        () {
      final binding =
          EventBuilderConditionBinding.storyStepCompleted('step_go_port');

      expect(binding.kind, EventBuilderConditionKind.storyStepCompleted);
      expect(binding.toScriptCondition(), isNull);

      final result = compileEventBuilderConditionsToScriptCondition([binding]);
      expect(result.condition, isNull);
      expect(
        result.diagnostics.single.kind,
        EventBuilderContractDiagnosticKind.unsupportedStoryStepCondition,
      );
    });
  });
}

```

#### `packages/map_core/test/event_builder_authoring_operations_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder authoring operations', () {
    test('reads legacy event without Event Builder metadata', () {
      final event = _event(
        page: const MapEventPage(pageNumber: 0),
      );

      final contract = readEventBuilderContractFromMapEvent(event);

      expect(contract.source.eventId, 'evt_rival');
      expect(contract.sceneAction, isNull);
      expect(contract.behavior.reusePolicy, EventBuilderReusePolicy.oneShot);
      expect(
        contract.diagnostics.single.kind,
        EventBuilderContractDiagnosticKind.missingSceneAction,
      );
    });

    test('reads scene action from MapEventPage.sceneTarget', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
        ),
      );

      final contract = readEventBuilderContractFromMapEvent(event);

      expect(contract.sceneAction?.sceneId, 'scene_rival');
      expect(contract.diagnostics, isEmpty);
    });

    test('applies scene action without deleting legacy script or message', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          script: ScriptRef(scriptId: 'legacy_script'),
          message: 'legacy message',
          metadata: {'legacy': 'keep'},
        ),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
        behavior: const EventBuilderBehaviorBinding.reusable(),
      );

      final updated = applyEventBuilderContractToMapEvent(event, contract);
      final page = updated.pages.single;

      expect(
          page.sceneTarget, const MapEventSceneTarget(sceneId: 'scene_rival'));
      expect(page.script, const ScriptRef(scriptId: 'legacy_script'));
      expect(page.message, 'legacy message');
      expect(page.metadata['legacy'], 'keep');
      expect(
        page.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.reusable.name,
      );
    });

    test('compiles supported conditions into allOf ScriptCondition', () {
      final event = _event(
        page: const MapEventPage(pageNumber: 0),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
        conditions: [
          EventBuilderConditionBinding.factIsTrue('fact_started'),
          EventBuilderConditionBinding.eventNotConsumed('evt_rival'),
        ],
      );

      final updated = applyEventBuilderContractToMapEvent(event, contract);
      final condition = updated.pages.single.condition;

      expect(condition?.type, ScriptConditionType.allOf);
      expect(
        condition?.children,
        [
          ScriptConditionFactory.flagIsSet('fact_started'),
          ScriptConditionFactory.not(
            ScriptConditionFactory.eventIsConsumed('evt_rival'),
          ),
        ],
      );
    });

    test('preserves unknown metadata when applying contract', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          metadata: {'customKey': 'customValue'},
        ),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
      );

      final updated = applyEventBuilderContractToMapEvent(event, contract);

      expect(updated.pages.single.metadata['customKey'], 'customValue');
      expect(
        updated.pages.single.metadata[EventBuilderMetadataKeys.schemaVersion],
        EventBuilderMetadataKeys.currentSchemaVersion,
      );
    });

    test('does not apply unsupported story step condition as opaque flag', () {
      final event = _event(
        page: const MapEventPage(pageNumber: 0),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
        conditions: [
          EventBuilderConditionBinding.storyStepCompleted('step_go_port'),
        ],
      );

      expect(
        () => applyEventBuilderContractToMapEvent(event, contract),
        throwsUnsupportedError,
      );
    });

    test('keeps malformed legacy conditions as diagnostic instead of crashing',
        () {
      final malformedLegacyCondition = ScriptConditionFactory.not(
        ScriptConditionFactory.allOf([
          ScriptConditionFactory.eventIsConsumed('evt_a'),
          ScriptConditionFactory.eventIsConsumed('evt_b'),
        ]),
      );
      final event = _event(
        page: MapEventPage(
          pageNumber: 0,
          condition: malformedLegacyCondition,
        ),
      );

      final contract = readEventBuilderContractFromMapEvent(event);

      expect(contract.conditions, isEmpty);
      expect(contract.legacyConditionToPreserve, malformedLegacyCondition);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.kind),
        contains(EventBuilderContractDiagnosticKind.unsupportedLegacyCondition),
      );
    });
  });
}

MapEventDefinition _event({required MapEventPage page}) {
  return MapEventDefinition(
    id: 'evt_rival',
    title: 'Rival au port',
    position: const EventPosition(layerId: 'events', x: 4, y: 5),
    type: MapEventType.actor,
    pages: [page],
  );
}

```

### Anti-scope

Aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `map_battle`, `examples`, `assets`, `selbrume` ou `pubspec.yaml` n'a été modifié par NS-EVENT-02.

### Sub-agents / passes

Aucun sub-agent externe n'a été lancé : le lot était assez contenu pour être traité par une passe principale + une passe de robustesse + une auto-review. Verdict des passes :

- Passe TDD : GREEN.
- Passe robustesse legacy : GREEN.
- Passe anti-scope : conforme.
- Passe auto-review : conforme avec limite Story Step assumée.

## 17. Auto-review critique

- Aucun `EventAsset` ou catalogue parallèle n'a été créé.
- L'API publique ne demande pas à manipuler des metadata libres.
- Les fields legacy sont conservés ; le contrat ne migre rien en silence.
- Le mapping Fact/Event consumed est propre et testé.
- Story Step n'est pas faussement encodé en flag opaque ; c'est volontairement une limite.
- Le world impact preview reste minimal, peut-être trop minimal pour V1 UI, mais suffisant pour préparer NS-EVENT-03 sans runtime.
- Risque restant : NS-EVENT-03 devra décider comment afficher les conditions legacy non supportées sans pousser l'utilisateur vers JSON brut.

## 18. Critique du prompt

Le prompt est bien borné et cohérent avec NS-EVENT-01. Le point le plus délicat était Story Step : il demande une capacité produit importante, mais le modèle de condition existant ne fournit pas encore de support canonique. Le choix le plus sûr est donc l'Option B : binding typé sans compilation.

Une amélioration possible du prompt futur serait de séparer clairement :

```text
NS-EVENT-03 — read model/diagnostics
NS-EVENT-04 — Story Step condition model support
NS-EVENT-05 — UI shell/list
```

Cela évitera de mélanger contrat, diagnostics, UI et runtime dans un même lot.

## 19. Final gate

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
?? packages/map_core/lib/src/authoring/event_builder_contract.dart
?? packages/map_core/test/event_builder_authoring_operations_test.dart
?? packages/map_core/test/event_builder_contract_test.dart
?? reports/narrativeStudio/events/ns_event_02_event_builder_core_contract_typed_authoring_bindings.md
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 packages/map_core/lib/map_core.dart | 2 ++
 1 file changed, 2 insertions(+)
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_core/lib/map_core.dart
```

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

Commande anti-scope :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```
