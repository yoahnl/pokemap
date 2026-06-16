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
