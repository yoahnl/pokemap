import 'package:meta/meta.dart' show immutable;

import '../authoring/event_builder_authoring_operations.dart';
import '../authoring/event_builder_contract.dart';
import '../models/map_event_definition.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';

const String _triggerSection = 'trigger';
const String _conditionsSection = 'conditions';
const String _actionsSection = 'actions';
const String _behaviorSection = 'behavior';
const String _worldSection = 'world';
const String _eventSection = 'event';

enum EventBuilderEventStatus {
  active,
  draft,
  inactive,
  invalid,
}

enum EventBuilderDiagnosticReadModelSeverity {
  info,
  warning,
  error,
}

enum EventBuilderDiagnosticReadModelKind {
  missingSceneAction,
  unsupportedLegacyCondition,
  unsupportedLegacyScript,
  unsupportedLegacyMessage,
  unsupportedStoryStepCondition,
  metadataMalformed,
  eventPageMissing,
}

enum EventBuilderSceneOutcomesProjectionStatus {
  noSceneTarget,
  missingScene,
  noDeclaredOutcomes,
  hasDeclaredOutcomes,
}

enum EventBuilderSceneOutcomeProjectionSource {
  sceneDeclaredOutcome,
}

enum EventBuilderLifecycleProjectionStatus {
  reusableNoConsumptionNeeded,
  oneShotIntentOnly,
  oneShotExplicitSceneConsequenceForThisEvent,
  oneShotExplicitSceneConsequenceForAnotherEvent,
  oneShotNoSceneTarget,
  oneShotMissingScene,
}

@immutable
final class EventBuilderReadModel {
  EventBuilderReadModel({
    required List<EventBuilderEventSummary> events,
    this.mapId,
    this.mapTitle,
  })  : events = List<EventBuilderEventSummary>.unmodifiable(events),
        diagnostics = List<EventBuilderDiagnosticReadModel>.unmodifiable(
          events.expand((event) => event.diagnostics),
        );

  final List<EventBuilderEventSummary> events;
  final List<EventBuilderDiagnosticReadModel> diagnostics;
  final String? mapId;
  final String? mapTitle;
}

@immutable
final class EventBuilderEventSummary {
  EventBuilderEventSummary({
    required this.eventId,
    required this.displayName,
    required this.technicalId,
    required this.status,
    required this.statusLabel,
    required this.groupKey,
    required this.position,
    required this.trigger,
    required List<EventBuilderConditionReadModel> conditions,
    required this.sceneAction,
    required this.behavior,
    required this.sceneOutcomes,
    required this.lifecycle,
    required List<EventBuilderWorldImpactReadModel> worldImpacts,
    required List<EventBuilderDiagnosticReadModel> diagnostics,
    required List<EventBuilderSectionReadModel> sections,
    required this.conditionEditingLocked,
    required this.conditionEditingMessage,
  })  : conditions = List<EventBuilderConditionReadModel>.unmodifiable(
          conditions,
        ),
        worldImpacts = List<EventBuilderWorldImpactReadModel>.unmodifiable(
          worldImpacts,
        ),
        diagnostics = List<EventBuilderDiagnosticReadModel>.unmodifiable(
          diagnostics,
        ),
        sections = List<EventBuilderSectionReadModel>.unmodifiable(sections);

  final String eventId;
  final String displayName;
  final String technicalId;
  final EventBuilderEventStatus status;
  final String statusLabel;
  final String groupKey;
  final EventPosition position;
  final EventBuilderTriggerReadModel trigger;
  final List<EventBuilderConditionReadModel> conditions;
  final EventBuilderSceneActionReadModel sceneAction;
  final EventBuilderBehaviorReadModel behavior;
  final EventBuilderSceneOutcomesProjection sceneOutcomes;
  final EventBuilderLifecycleProjection lifecycle;
  final List<EventBuilderWorldImpactReadModel> worldImpacts;
  final List<EventBuilderDiagnosticReadModel> diagnostics;
  final List<EventBuilderSectionReadModel> sections;
  final bool conditionEditingLocked;
  final String? conditionEditingMessage;
}

@immutable
final class EventBuilderSectionReadModel {
  const EventBuilderSectionReadModel({
    required this.key,
    required this.title,
    required this.summary,
    required this.diagnosticCount,
    required this.hasBlockingDiagnostic,
  });

  final String key;
  final String title;
  final String summary;
  final int diagnosticCount;
  final bool hasBlockingDiagnostic;
}

@immutable
final class EventBuilderTriggerReadModel {
  const EventBuilderTriggerReadModel({
    required this.kind,
    required this.label,
    required this.sourceId,
    required this.sourceLabel,
    required this.technicalLabel,
  });

  final EventBuilderTriggerKind kind;
  final String label;
  final String sourceId;
  final String sourceLabel;
  final String technicalLabel;
}

@immutable
final class EventBuilderConditionReadModel {
  const EventBuilderConditionReadModel({
    required this.kind,
    required this.referenceId,
    required this.referenceLabel,
    required this.label,
    required this.isSupported,
    required this.isEditable,
  });

  final EventBuilderConditionKind kind;
  final String referenceId;
  final String referenceLabel;
  final String label;
  final bool isSupported;
  final bool isEditable;
}

@immutable
final class EventBuilderSceneActionReadModel {
  const EventBuilderSceneActionReadModel({
    required this.sceneId,
    required this.sceneLabel,
    required this.label,
    required this.isMissing,
  });

  final String? sceneId;
  final String sceneLabel;
  final String label;
  final bool isMissing;
}

@immutable
final class EventBuilderBehaviorReadModel {
  const EventBuilderBehaviorReadModel({
    required this.reusePolicy,
    required this.label,
  });

  final EventBuilderReusePolicy reusePolicy;
  final String label;
}

/// Projection read-only des outcomes déclarés par la Scene liée.
///
/// NS-EVENT-26 garde les outcomes Scene-owned : ce read model expose seulement
/// la vérité utile à l'UI, sans créer de résultat côté [MapEventDefinition].
@immutable
final class EventBuilderSceneOutcomesProjection {
  EventBuilderSceneOutcomesProjection({
    required this.status,
    required this.label,
    required this.sceneId,
    required this.sceneLabel,
    required List<EventBuilderSceneOutcomeReadModel> outcomes,
  }) : outcomes = List<EventBuilderSceneOutcomeReadModel>.unmodifiable(
          outcomes,
        );

  final EventBuilderSceneOutcomesProjectionStatus status;
  final String label;
  final String? sceneId;
  final String sceneLabel;
  final List<EventBuilderSceneOutcomeReadModel> outcomes;
}

@immutable
final class EventBuilderSceneOutcomeReadModel {
  const EventBuilderSceneOutcomeReadModel({
    required this.id,
    required this.label,
    required this.description,
    required this.source,
    required this.sourceLabel,
    required this.isReadOnly,
  });

  final String id;
  final String label;
  final String? description;
  final EventBuilderSceneOutcomeProjectionSource source;
  final String sourceLabel;
  final bool isReadOnly;
}

/// Projection du lifecycle Event Builder.
///
/// `oneShot` reste une intention authoring tant qu'un runtime lifecycle dédié
/// ne consomme pas l'event appelant. Une conséquence Scene explicite est donc
/// signalée comme compatibilité, pas comme nouveau contrat runtime canonique.
@immutable
final class EventBuilderLifecycleProjection {
  const EventBuilderLifecycleProjection({
    required this.status,
    required this.label,
    required this.reusePolicy,
    required this.isRuntimeGuaranteed,
    this.warningMessage,
    this.explicitConsumedEventId,
  });

  final EventBuilderLifecycleProjectionStatus status;
  final String label;
  final EventBuilderReusePolicy reusePolicy;
  final bool isRuntimeGuaranteed;
  final String? warningMessage;
  final String? explicitConsumedEventId;
}

@immutable
final class EventBuilderWorldImpactReadModel {
  const EventBuilderWorldImpactReadModel({
    required this.kind,
    required this.sourceId,
    required this.label,
    required this.reason,
  });

  final EventBuilderWorldImpactKind kind;
  final String sourceId;
  final String label;
  final String reason;
}

@immutable
final class EventBuilderDiagnosticReadModel {
  const EventBuilderDiagnosticReadModel({
    required this.severity,
    required this.kind,
    required this.title,
    required this.message,
    required this.path,
    required this.sectionTarget,
    this.referencedId,
  });

  final EventBuilderDiagnosticReadModelSeverity severity;
  final EventBuilderDiagnosticReadModelKind kind;
  final String title;
  final String message;
  final String path;
  final String sectionTarget;
  final String? referencedId;
}

EventBuilderReadModel buildEventBuilderReadModel({
  required List<MapEventDefinition> events,
  String? mapId,
  String? mapTitle,
  Map<String, String> sceneLabels = const <String, String>{},
  Map<String, SceneAsset> scenes = const <String, SceneAsset>{},
  Map<String, String> factLabels = const <String, String>{},
  Map<String, String> eventLabels = const <String, String>{},
  Map<String, String> storyStepLabels = const <String, String>{},
}) {
  final eventLabelLookup = <String, String>{
    for (final event in events) event.id: _eventDisplayName(event),
    ...eventLabels,
  };
  final summaries = [
    for (final event in events)
      _buildEventSummary(
        event,
        mapId: mapId,
        groupKey: mapId ?? 'events',
        sceneLabels: sceneLabels,
        scenes: scenes,
        factLabels: factLabels,
        eventLabels: eventLabelLookup,
        storyStepLabels: storyStepLabels,
      ),
  ]..sort(_compareEventSummaries);

  return EventBuilderReadModel(
    events: summaries,
    mapId: _trimOptional(mapId),
    mapTitle: _trimOptional(mapTitle),
  );
}

EventBuilderEventSummary _buildEventSummary(
  MapEventDefinition event, {
  required String? mapId,
  required String groupKey,
  required Map<String, String> sceneLabels,
  required Map<String, SceneAsset> scenes,
  required Map<String, String> factLabels,
  required Map<String, String> eventLabels,
  required Map<String, String> storyStepLabels,
}) {
  if (event.pages.isEmpty) {
    return _buildInvalidPageSummary(event, groupKey: groupKey);
  }

  final page = _selectedPage(event);
  final contract = readEventBuilderContractFromMapEvent(event);
  final diagnostics = [
    for (final diagnostic in contract.diagnostics)
      _mapContractDiagnostic(diagnostic),
  ];
  final conditions = [
    for (final condition in contract.conditions)
      _buildConditionReadModel(
        condition,
        factLabels: factLabels,
        eventLabels: eventLabels,
        storyStepLabels: storyStepLabels,
        locked: contract.legacyConditionToPreserve != null,
      ),
  ];
  final sceneAction = _buildSceneActionReadModel(
    contract.sceneAction,
    sceneLabels: sceneLabels,
  );
  final behavior = _buildBehaviorReadModel(contract.behavior);
  final sceneOutcomes = _buildSceneOutcomesProjection(
    sceneAction: contract.sceneAction,
    sceneLabels: sceneLabels,
    scenes: scenes,
  );
  final lifecycle = _buildLifecycleProjection(
    eventId: event.id,
    mapId: mapId,
    behavior: contract.behavior,
    sceneAction: contract.sceneAction,
    scenes: scenes,
  );
  final worldImpacts = [
    for (final impact in contract.worldImpactPreviews)
      _buildWorldImpactReadModel(impact),
  ];
  final conditionEditingLocked = contract.legacyConditionToPreserve != null;
  final conditionEditingMessage = conditionEditingLocked
      ? 'Cette condition contient une partie avancée préservée. '
          'Elle ne peut pas être éditée partiellement.'
      : null;
  final status = _statusFor(
    page: page,
    sceneAction: contract.sceneAction,
    diagnostics: diagnostics,
  );

  return EventBuilderEventSummary(
    eventId: event.id,
    displayName: _eventDisplayName(event),
    technicalId: event.id,
    status: status,
    statusLabel: _statusLabel(status),
    groupKey: groupKey,
    position: event.position,
    trigger: _buildTriggerReadModel(contract.trigger),
    conditions: conditions,
    sceneAction: sceneAction,
    behavior: behavior,
    sceneOutcomes: sceneOutcomes,
    lifecycle: lifecycle,
    worldImpacts: worldImpacts,
    diagnostics: diagnostics,
    sections: _buildSections(
      conditions: conditions,
      sceneAction: sceneAction,
      behavior: behavior,
      worldImpacts: worldImpacts,
      diagnostics: diagnostics,
      conditionEditingMessage: conditionEditingMessage,
    ),
    conditionEditingLocked: conditionEditingLocked,
    conditionEditingMessage: conditionEditingMessage,
  );
}

EventBuilderEventSummary _buildInvalidPageSummary(
  MapEventDefinition event, {
  required String groupKey,
}) {
  const diagnostic = EventBuilderDiagnosticReadModel(
    severity: EventBuilderDiagnosticReadModelSeverity.error,
    kind: EventBuilderDiagnosticReadModelKind.eventPageMissing,
    title: 'Page événement manquante',
    message: 'Cet événement ne contient aucune page authorable.',
    path: 'event.pages',
    sectionTarget: _eventSection,
  );
  const sceneAction = EventBuilderSceneActionReadModel(
    sceneId: null,
    sceneLabel: '',
    label: 'Action principale manquante',
    isMissing: true,
  );
  const behavior = EventBuilderBehaviorReadModel(
    reusePolicy: EventBuilderReusePolicy.oneShot,
    label: 'Une seule fois',
  );
  final sceneOutcomes = EventBuilderSceneOutcomesProjection(
    status: EventBuilderSceneOutcomesProjectionStatus.noSceneTarget,
    label: 'Aucune scène liée',
    sceneId: null,
    sceneLabel: '',
    outcomes: const <EventBuilderSceneOutcomeReadModel>[],
  );
  const lifecycle = EventBuilderLifecycleProjection(
    status: EventBuilderLifecycleProjectionStatus.oneShotNoSceneTarget,
    label: 'Une seule fois - aucune Scene liée, consommation non vérifiable.',
    reusePolicy: EventBuilderReusePolicy.oneShot,
    isRuntimeGuaranteed: false,
    warningMessage: 'Lifecycle one-shot non vérifiable sans Scene liée.',
  );
  const diagnostics = [diagnostic];

  return EventBuilderEventSummary(
    eventId: event.id,
    displayName: _eventDisplayName(event),
    technicalId: event.id,
    status: EventBuilderEventStatus.invalid,
    statusLabel: _statusLabel(EventBuilderEventStatus.invalid),
    groupKey: groupKey,
    position: event.position,
    trigger: _fallbackTriggerReadModel(event),
    conditions: const <EventBuilderConditionReadModel>[],
    sceneAction: sceneAction,
    behavior: behavior,
    sceneOutcomes: sceneOutcomes,
    lifecycle: lifecycle,
    worldImpacts: const <EventBuilderWorldImpactReadModel>[],
    diagnostics: diagnostics,
    sections: _buildSections(
      conditions: const <EventBuilderConditionReadModel>[],
      sceneAction: sceneAction,
      behavior: behavior,
      worldImpacts: const <EventBuilderWorldImpactReadModel>[],
      diagnostics: diagnostics,
      conditionEditingMessage: null,
    ),
    conditionEditingLocked: false,
    conditionEditingMessage: null,
  );
}

MapEventPage _selectedPage(MapEventDefinition event) {
  var selected = event.pages.first;
  for (final page in event.pages.skip(1)) {
    if (page.pageNumber < selected.pageNumber) {
      selected = page;
    }
  }
  return selected;
}

EventBuilderEventStatus _statusFor({
  required MapEventPage page,
  required EventBuilderSceneActionBinding? sceneAction,
  required List<EventBuilderDiagnosticReadModel> diagnostics,
}) {
  if (page.isDisabled) {
    return EventBuilderEventStatus.inactive;
  }
  if (sceneAction == null) {
    return EventBuilderEventStatus.draft;
  }
  if (diagnostics.any((diagnostic) =>
      diagnostic.severity == EventBuilderDiagnosticReadModelSeverity.error)) {
    return EventBuilderEventStatus.invalid;
  }
  return EventBuilderEventStatus.active;
}

EventBuilderTriggerReadModel _buildTriggerReadModel(
  EventBuilderTriggerBinding trigger,
) {
  return EventBuilderTriggerReadModel(
    kind: trigger.kind,
    label: _triggerLabel(trigger.source.eventType),
    sourceId: trigger.source.eventId,
    sourceLabel: _sourceLabel(trigger.source),
    technicalLabel: trigger.source.eventId,
  );
}

EventBuilderTriggerReadModel _fallbackTriggerReadModel(
  MapEventDefinition event,
) {
  return EventBuilderTriggerReadModel(
    kind: _triggerKindForEventType(event.type),
    label: _triggerLabel(event.type),
    sourceId: event.id,
    sourceLabel: _eventDisplayName(event),
    technicalLabel: event.id,
  );
}

EventBuilderConditionReadModel _buildConditionReadModel(
  EventBuilderConditionBinding condition, {
  required Map<String, String> factLabels,
  required Map<String, String> eventLabels,
  required Map<String, String> storyStepLabels,
  required bool locked,
}) {
  final referenceLabel = switch (condition.kind) {
    EventBuilderConditionKind.factIsTrue ||
    EventBuilderConditionKind.factIsFalse =>
      condition.label ??
          factLabels[condition.referenceId] ??
          condition.referenceId,
    EventBuilderConditionKind.eventConsumed ||
    EventBuilderConditionKind.eventNotConsumed =>
      condition.label ??
          eventLabels[condition.referenceId] ??
          condition.referenceId,
    EventBuilderConditionKind.storyStepCompleted ||
    EventBuilderConditionKind.storyStepNotCompleted =>
      condition.label ??
          storyStepLabels[condition.referenceId] ??
          condition.referenceId,
  };
  final supported = switch (condition.kind) {
    EventBuilderConditionKind.storyStepCompleted ||
    EventBuilderConditionKind.storyStepNotCompleted =>
      false,
    _ => true,
  };
  return EventBuilderConditionReadModel(
    kind: condition.kind,
    referenceId: condition.referenceId,
    referenceLabel: referenceLabel,
    label: _conditionLabel(condition.kind, referenceLabel),
    isSupported: supported,
    isEditable: supported && !locked,
  );
}

EventBuilderSceneActionReadModel _buildSceneActionReadModel(
  EventBuilderSceneActionBinding? action, {
  required Map<String, String> sceneLabels,
}) {
  if (action == null) {
    return const EventBuilderSceneActionReadModel(
      sceneId: null,
      sceneLabel: '',
      label: 'Action principale manquante',
      isMissing: true,
    );
  }
  final sceneLabel =
      action.label ?? sceneLabels[action.sceneId] ?? action.sceneId;
  return EventBuilderSceneActionReadModel(
    sceneId: action.sceneId,
    sceneLabel: sceneLabel,
    label: 'Jouer la scène "$sceneLabel"',
    isMissing: false,
  );
}

EventBuilderBehaviorReadModel _buildBehaviorReadModel(
  EventBuilderBehaviorBinding behavior,
) {
  return EventBuilderBehaviorReadModel(
    reusePolicy: behavior.reusePolicy,
    label: _reusePolicyLabel(behavior.reusePolicy),
  );
}

EventBuilderSceneOutcomesProjection _buildSceneOutcomesProjection({
  required EventBuilderSceneActionBinding? sceneAction,
  required Map<String, String> sceneLabels,
  required Map<String, SceneAsset> scenes,
}) {
  if (sceneAction == null) {
    return EventBuilderSceneOutcomesProjection(
      status: EventBuilderSceneOutcomesProjectionStatus.noSceneTarget,
      label: 'Aucune scène liée',
      sceneId: null,
      sceneLabel: '',
      outcomes: const <EventBuilderSceneOutcomeReadModel>[],
    );
  }

  final sceneLabel = sceneAction.label ??
      sceneLabels[sceneAction.sceneId] ??
      sceneAction.sceneId;
  final scene = scenes[sceneAction.sceneId];
  if (scene == null) {
    return EventBuilderSceneOutcomesProjection(
      status: EventBuilderSceneOutcomesProjectionStatus.missingScene,
      label: 'Scène introuvable',
      sceneId: sceneAction.sceneId,
      sceneLabel: sceneLabel,
      outcomes: const <EventBuilderSceneOutcomeReadModel>[],
    );
  }

  if (scene.declaredOutcomes.isEmpty) {
    return EventBuilderSceneOutcomesProjection(
      status: EventBuilderSceneOutcomesProjectionStatus.noDeclaredOutcomes,
      label: 'Aucun résultat déclaré',
      sceneId: scene.id,
      sceneLabel: scene.name,
      outcomes: const <EventBuilderSceneOutcomeReadModel>[],
    );
  }

  return EventBuilderSceneOutcomesProjection(
    status: EventBuilderSceneOutcomesProjectionStatus.hasDeclaredOutcomes,
    label: '${scene.declaredOutcomes.length} résultat(s) déclarés par la Scene',
    sceneId: scene.id,
    sceneLabel: scene.name,
    outcomes: [
      for (final outcome in scene.declaredOutcomes)
        EventBuilderSceneOutcomeReadModel(
          id: outcome.id,
          label: outcome.label,
          description: outcome.description,
          source: EventBuilderSceneOutcomeProjectionSource.sceneDeclaredOutcome,
          sourceLabel: 'Scene déclarée',
          isReadOnly: true,
        ),
    ],
  );
}

EventBuilderLifecycleProjection _buildLifecycleProjection({
  required String eventId,
  required String? mapId,
  required EventBuilderBehaviorBinding behavior,
  required EventBuilderSceneActionBinding? sceneAction,
  required Map<String, SceneAsset> scenes,
}) {
  if (behavior.reusePolicy == EventBuilderReusePolicy.reusable) {
    return const EventBuilderLifecycleProjection(
      status: EventBuilderLifecycleProjectionStatus.reusableNoConsumptionNeeded,
      label: 'Réutilisable - aucune consommation nécessaire.',
      reusePolicy: EventBuilderReusePolicy.reusable,
      isRuntimeGuaranteed: true,
    );
  }

  if (sceneAction == null) {
    return const EventBuilderLifecycleProjection(
      status: EventBuilderLifecycleProjectionStatus.oneShotNoSceneTarget,
      label: 'Une seule fois - aucune Scene liée, consommation non vérifiable.',
      reusePolicy: EventBuilderReusePolicy.oneShot,
      isRuntimeGuaranteed: false,
      warningMessage: 'Lifecycle one-shot non vérifiable sans Scene liée.',
    );
  }

  final scene = scenes[sceneAction.sceneId];
  if (scene == null) {
    return const EventBuilderLifecycleProjection(
      status: EventBuilderLifecycleProjectionStatus.oneShotMissingScene,
      label: 'Une seule fois - Scene introuvable, consommation non vérifiable.',
      reusePolicy: EventBuilderReusePolicy.oneShot,
      isRuntimeGuaranteed: false,
      warningMessage: 'Scene introuvable, consommation non vérifiable.',
    );
  }

  final consumedConsequences = _markEventConsumedConsequences(scene).toList();
  if (consumedConsequences.isEmpty) {
    return const EventBuilderLifecycleProjection(
      status: EventBuilderLifecycleProjectionStatus.oneShotIntentOnly,
      label:
          'Une seule fois - intention authoring, runtime lifecycle dédié pas encore branché.',
      reusePolicy: EventBuilderReusePolicy.oneShot,
      isRuntimeGuaranteed: false,
      warningMessage: 'Intention non garantie au runtime.',
    );
  }

  final matchesCurrentEvent = consumedConsequences.any(
    (consequence) =>
        consequence.eventId == eventId &&
        mapId != null &&
        consequence.mapId == mapId,
  );
  if (matchesCurrentEvent) {
    return EventBuilderLifecycleProjection(
      status: EventBuilderLifecycleProjectionStatus
          .oneShotExplicitSceneConsequenceForThisEvent,
      label: 'Une seule fois - conséquence Scene explicite trouvée.',
      reusePolicy: EventBuilderReusePolicy.oneShot,
      isRuntimeGuaranteed: true,
      warningMessage: 'Couvert par conséquence Scene explicite - compatible, '
          'mais fragile si la Scene est réutilisée.',
      explicitConsumedEventId: eventId,
    );
  }

  return EventBuilderLifecycleProjection(
    status: EventBuilderLifecycleProjectionStatus
        .oneShotExplicitSceneConsequenceForAnotherEvent,
    label: 'Une seule fois - la Scene consomme un autre event.',
    reusePolicy: EventBuilderReusePolicy.oneShot,
    isRuntimeGuaranteed: false,
    warningMessage: 'La Scene consomme un autre event.',
    explicitConsumedEventId: consumedConsequences.first.eventId,
  );
}

Iterable<SceneMarkEventConsumedConsequence> _markEventConsumedConsequences(
  SceneAsset scene,
) sync* {
  for (final node in scene.graph.nodes) {
    if (node.kind != SceneNodeKind.action) {
      continue;
    }
    final payload = node.payload as SceneActionPayload;
    final consequence = payload.consequence;
    if (consequence is SceneMarkEventConsumedConsequence) {
      yield consequence;
    }
  }
}

EventBuilderWorldImpactReadModel _buildWorldImpactReadModel(
  EventBuilderWorldImpactPreview impact,
) {
  final label = impact.label ?? impact.sourceId;
  return EventBuilderWorldImpactReadModel(
    kind: impact.kind,
    sourceId: impact.sourceId,
    label: _worldImpactLabel(impact.kind, label),
    reason: impact.reason ?? '',
  );
}

List<EventBuilderSectionReadModel> _buildSections({
  required List<EventBuilderConditionReadModel> conditions,
  required EventBuilderSceneActionReadModel sceneAction,
  required EventBuilderBehaviorReadModel behavior,
  required List<EventBuilderWorldImpactReadModel> worldImpacts,
  required List<EventBuilderDiagnosticReadModel> diagnostics,
  required String? conditionEditingMessage,
}) {
  return [
    EventBuilderSectionReadModel(
      key: _triggerSection,
      title: 'Déclencheur',
      summary: 'Déclencheur configuré',
      diagnosticCount: _diagnosticCount(diagnostics, _triggerSection),
      hasBlockingDiagnostic: _hasBlockingDiagnostic(
        diagnostics,
        _triggerSection,
      ),
    ),
    EventBuilderSectionReadModel(
      key: _conditionsSection,
      title: 'Conditions',
      summary: conditionEditingMessage ??
          (conditions.isEmpty
              ? 'Aucune condition'
              : '${conditions.length} condition(s)'),
      diagnosticCount: _diagnosticCount(diagnostics, _conditionsSection),
      hasBlockingDiagnostic: _hasBlockingDiagnostic(
        diagnostics,
        _conditionsSection,
      ),
    ),
    EventBuilderSectionReadModel(
      key: _actionsSection,
      title: 'Action principale',
      summary: sceneAction.label,
      diagnosticCount: _diagnosticCount(diagnostics, _actionsSection),
      hasBlockingDiagnostic: _hasBlockingDiagnostic(
        diagnostics,
        _actionsSection,
      ),
    ),
    EventBuilderSectionReadModel(
      key: _behaviorSection,
      title: 'Comportement',
      summary: behavior.label,
      diagnosticCount: _diagnosticCount(diagnostics, _behaviorSection),
      hasBlockingDiagnostic: _hasBlockingDiagnostic(
        diagnostics,
        _behaviorSection,
      ),
    ),
    EventBuilderSectionReadModel(
      key: _worldSection,
      title: 'Changements du monde',
      summary: worldImpacts.isEmpty
          ? 'Aucun impact monde prévisible'
          : '${worldImpacts.length} impact(s) prévisible(s)',
      diagnosticCount: _diagnosticCount(diagnostics, _worldSection),
      hasBlockingDiagnostic: _hasBlockingDiagnostic(diagnostics, _worldSection),
    ),
  ];
}

EventBuilderDiagnosticReadModel _mapContractDiagnostic(
  EventBuilderContractDiagnostic diagnostic,
) {
  final kind = _diagnosticKind(diagnostic.kind);
  return EventBuilderDiagnosticReadModel(
    severity: _diagnosticSeverity(diagnostic.severity),
    kind: kind,
    title: _diagnosticTitle(kind),
    message: _diagnosticMessage(kind),
    path: diagnostic.path,
    sectionTarget: _diagnosticSection(kind),
    referencedId: diagnostic.referencedId,
  );
}

int _compareEventSummaries(
  EventBuilderEventSummary a,
  EventBuilderEventSummary b,
) {
  final byY = a.position.y.compareTo(b.position.y);
  if (byY != 0) {
    return byY;
  }
  final byX = a.position.x.compareTo(b.position.x);
  if (byX != 0) {
    return byX;
  }
  final byName = a.displayName.compareTo(b.displayName);
  if (byName != 0) {
    return byName;
  }
  return a.eventId.compareTo(b.eventId);
}

int _diagnosticCount(
  List<EventBuilderDiagnosticReadModel> diagnostics,
  String section,
) {
  return diagnostics
      .where((diagnostic) => diagnostic.sectionTarget == section)
      .length;
}

bool _hasBlockingDiagnostic(
  List<EventBuilderDiagnosticReadModel> diagnostics,
  String section,
) {
  return diagnostics.any(
    (diagnostic) =>
        diagnostic.sectionTarget == section &&
        diagnostic.severity == EventBuilderDiagnosticReadModelSeverity.error,
  );
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

String _triggerLabel(MapEventType type) {
  return switch (type) {
    MapEventType.actor => 'Interaction avec un PNJ',
    MapEventType.object => 'Interaction avec un objet',
    MapEventType.triggerZone => 'Entrée dans une zone',
    MapEventType.effect => 'Interaction / effet',
  };
}

String _sourceLabel(EventBuilderSourceBinding source) {
  return source.eventTitle.isEmpty ? source.eventId : source.eventTitle;
}

String _conditionLabel(
  EventBuilderConditionKind kind,
  String referenceLabel,
) {
  return switch (kind) {
    EventBuilderConditionKind.factIsTrue => 'Fact "$referenceLabel" est vrai',
    EventBuilderConditionKind.factIsFalse => 'Fact "$referenceLabel" est faux',
    EventBuilderConditionKind.eventConsumed =>
      'Événement "$referenceLabel" déjà consommé',
    EventBuilderConditionKind.eventNotConsumed =>
      'Événement "$referenceLabel" pas encore consommé',
    EventBuilderConditionKind.storyStepCompleted =>
      'Story Step "$referenceLabel" terminée - non supporté dans ce lot',
    EventBuilderConditionKind.storyStepNotCompleted =>
      'Story Step "$referenceLabel" pas terminée - non supporté dans ce lot',
  };
}

String _reusePolicyLabel(EventBuilderReusePolicy policy) {
  return switch (policy) {
    EventBuilderReusePolicy.oneShot => 'Une seule fois',
    EventBuilderReusePolicy.reusable => 'Réutilisable',
  };
}

String _worldImpactLabel(EventBuilderWorldImpactKind kind, String label) {
  return switch (kind) {
    EventBuilderWorldImpactKind.fact => 'Fact : $label',
    EventBuilderWorldImpactKind.storyStep => 'Étape : $label',
    EventBuilderWorldImpactKind.consumedEvent => 'Événement consommé : $label',
  };
}

String _statusLabel(EventBuilderEventStatus status) {
  return switch (status) {
    EventBuilderEventStatus.active => 'Actif',
    EventBuilderEventStatus.draft => 'Brouillon',
    EventBuilderEventStatus.inactive => 'Inactif',
    EventBuilderEventStatus.invalid => 'Invalide',
  };
}

EventBuilderDiagnosticReadModelSeverity _diagnosticSeverity(
  EventBuilderContractDiagnosticSeverity severity,
) {
  return switch (severity) {
    EventBuilderContractDiagnosticSeverity.info =>
      EventBuilderDiagnosticReadModelSeverity.info,
    EventBuilderContractDiagnosticSeverity.warning =>
      EventBuilderDiagnosticReadModelSeverity.warning,
    EventBuilderContractDiagnosticSeverity.error =>
      EventBuilderDiagnosticReadModelSeverity.error,
  };
}

EventBuilderDiagnosticReadModelKind _diagnosticKind(
  EventBuilderContractDiagnosticKind kind,
) {
  return switch (kind) {
    EventBuilderContractDiagnosticKind.missingSceneAction =>
      EventBuilderDiagnosticReadModelKind.missingSceneAction,
    EventBuilderContractDiagnosticKind.unsupportedLegacyCondition =>
      EventBuilderDiagnosticReadModelKind.unsupportedLegacyCondition,
    EventBuilderContractDiagnosticKind.unsupportedLegacyScript =>
      EventBuilderDiagnosticReadModelKind.unsupportedLegacyScript,
    EventBuilderContractDiagnosticKind.unsupportedLegacyMessage =>
      EventBuilderDiagnosticReadModelKind.unsupportedLegacyMessage,
    EventBuilderContractDiagnosticKind.unsupportedStoryStepCondition =>
      EventBuilderDiagnosticReadModelKind.unsupportedStoryStepCondition,
    EventBuilderContractDiagnosticKind.metadataMalformed =>
      EventBuilderDiagnosticReadModelKind.metadataMalformed,
  };
}

String _diagnosticTitle(EventBuilderDiagnosticReadModelKind kind) {
  return switch (kind) {
    EventBuilderDiagnosticReadModelKind.missingSceneAction =>
      'Action principale manquante',
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyCondition =>
      'Condition avancée préservée',
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyScript =>
      'Script legacy préservé',
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyMessage =>
      'Message legacy préservé',
    EventBuilderDiagnosticReadModelKind.unsupportedStoryStepCondition =>
      'Condition Story Step non supportée',
    EventBuilderDiagnosticReadModelKind.metadataMalformed =>
      'Réglage Event Builder illisible',
    EventBuilderDiagnosticReadModelKind.eventPageMissing =>
      'Page événement manquante',
  };
}

String _diagnosticMessage(EventBuilderDiagnosticReadModelKind kind) {
  return switch (kind) {
    EventBuilderDiagnosticReadModelKind.missingSceneAction =>
      'Ajoutez une scène à jouer pour compléter cet événement.',
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyCondition =>
      'Une partie avancée de la condition est préservée sans être éditable '
          'partiellement.',
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyScript =>
      'Le script legacy reste conservé, mais il ne fait pas partie du flux '
          'Event Builder MVP.',
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyMessage =>
      'Le message legacy reste conservé, mais il ne fait pas partie du flux '
          'Event Builder MVP.',
    EventBuilderDiagnosticReadModelKind.unsupportedStoryStepCondition =>
      'Les conditions Story Step sont typées mais non compilées dans ce lot.',
    EventBuilderDiagnosticReadModelKind.metadataMalformed =>
      'Un réglage Event Builder est illisible. Une valeur sûre est utilisée.',
    EventBuilderDiagnosticReadModelKind.eventPageMissing =>
      'Cet événement doit contenir au moins une page pour être authorable.',
  };
}

String _diagnosticSection(EventBuilderDiagnosticReadModelKind kind) {
  return switch (kind) {
    EventBuilderDiagnosticReadModelKind.missingSceneAction => _actionsSection,
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyCondition ||
    EventBuilderDiagnosticReadModelKind.unsupportedStoryStepCondition =>
      _conditionsSection,
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyScript ||
    EventBuilderDiagnosticReadModelKind.unsupportedLegacyMessage =>
      _actionsSection,
    EventBuilderDiagnosticReadModelKind.metadataMalformed => _behaviorSection,
    EventBuilderDiagnosticReadModelKind.eventPageMissing => _eventSection,
  };
}

String _eventDisplayName(MapEventDefinition event) {
  final title = event.title.trim();
  return title.isEmpty ? event.id : title;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
