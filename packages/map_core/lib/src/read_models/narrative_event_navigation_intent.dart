import 'package:meta/meta.dart' show immutable;

import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../compatibility/legacy_scenario_source_projection.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../operations/build_narrative_outcome_event_source_catalog.dart';
import '../operations/build_narrative_spatial_event_source_catalog.dart';

enum NarrativeEditorDestinationKind {
  openMap,
  focusEntity,
  focusTrigger,
  openScene,
  openFact,
  openNarrativeEvent,
  openLegacyScenario,
  openMigrationReview,
  openOutcomeProducer,
}

enum NarrativeEditorFocusTargetKind { map, entity, trigger }

enum NarrativeEventNavigationDiagnosticSeverity { info, warning, error }

enum NarrativeEventRecommendedAction {
  viewOnMap,
  openScene,
  openFact,
  openNarrativeEvent,
  openLegacyScenario,
  examineMigration,
  openOutcomeProducer,
  chooseSource,
  changeSource,
  repairReference,
  none,
}

extension NarrativeEventRecommendedActionLabel
    on NarrativeEventRecommendedAction {
  String get humanLabel => switch (this) {
        NarrativeEventRecommendedAction.viewOnMap => 'Voir sur la carte',
        NarrativeEventRecommendedAction.openScene => 'Ouvrir la Scene',
        NarrativeEventRecommendedAction.openFact => 'Ouvrir le Fact',
        NarrativeEventRecommendedAction.openNarrativeEvent =>
          'Ouvrir l’Event référencé',
        NarrativeEventRecommendedAction.openLegacyScenario =>
          'Ouvrir le parcours existant',
        NarrativeEventRecommendedAction.examineMigration =>
          'Examiner la migration',
        NarrativeEventRecommendedAction.openOutcomeProducer =>
          'Ouvrir le producteur du résultat',
        NarrativeEventRecommendedAction.chooseSource => 'Choisir une source',
        NarrativeEventRecommendedAction.changeSource => 'Changer de source',
        NarrativeEventRecommendedAction.repairReference =>
          'Réparer la référence',
        NarrativeEventRecommendedAction.none => 'Aucune navigation disponible',
      };
}

@immutable
final class NarrativeEditorDestination {
  NarrativeEditorDestination._({
    required this.kind,
    this.mapId,
    this.entityId,
    this.triggerId,
    this.sceneId,
    this.factId,
    this.eventId,
    this.scenarioId,
    this.nodeId,
    this.provenance,
    this.outcome,
  });

  factory NarrativeEditorDestination.openMap(String mapId) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openMap,
      mapId: _identity(mapId, 'mapId'),
    );
  }

  factory NarrativeEditorDestination.focusEntity(
    String mapId,
    String entityId,
  ) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.focusEntity,
      mapId: _identity(mapId, 'mapId'),
      entityId: _identity(entityId, 'entityId'),
    );
  }

  factory NarrativeEditorDestination.focusTrigger(
    String mapId,
    String triggerId,
  ) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.focusTrigger,
      mapId: _identity(mapId, 'mapId'),
      triggerId: _identity(triggerId, 'triggerId'),
    );
  }

  factory NarrativeEditorDestination.openScene(String sceneId) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openScene,
      sceneId: _identity(sceneId, 'sceneId'),
    );
  }

  factory NarrativeEditorDestination.openFact(String factId) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openFact,
      factId: _identity(factId, 'factId'),
    );
  }

  factory NarrativeEditorDestination.openNarrativeEvent(String eventId) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openNarrativeEvent,
      eventId: _identity(eventId, 'eventId'),
    );
  }

  factory NarrativeEditorDestination.openLegacyScenario(
    String scenarioId,
    String nodeId,
  ) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openLegacyScenario,
      scenarioId: _identity(scenarioId, 'scenarioId'),
      nodeId: _identity(nodeId, 'nodeId'),
    );
  }

  factory NarrativeEditorDestination.openMigrationReview(
    LegacySourceRef provenance,
  ) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openMigrationReview,
      provenance: provenance,
    );
  }

  factory NarrativeEditorDestination.openOutcomeProducer(
    NarrativeOutcomeRef outcome,
  ) {
    return NarrativeEditorDestination._(
      kind: NarrativeEditorDestinationKind.openOutcomeProducer,
      outcome: outcome,
    );
  }

  final NarrativeEditorDestinationKind kind;
  final String? mapId;
  final String? entityId;
  final String? triggerId;
  final String? sceneId;
  final String? factId;
  final String? eventId;
  final String? scenarioId;
  final String? nodeId;
  final LegacySourceRef? provenance;
  final NarrativeOutcomeRef? outcome;

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        if (mapId != null) 'mapId': mapId,
        if (entityId != null) 'entityId': entityId,
        if (triggerId != null) 'triggerId': triggerId,
        if (sceneId != null) 'sceneId': sceneId,
        if (factId != null) 'factId': factId,
        if (eventId != null) 'eventId': eventId,
        if (scenarioId != null) 'scenarioId': scenarioId,
        if (nodeId != null) 'nodeId': nodeId,
        if (provenance != null) 'provenance': provenance!.toJson(),
        if (outcome != null) 'outcome': outcome!.toJson(),
      };
}

@immutable
final class NarrativeEditorFocusTarget {
  NarrativeEditorFocusTarget._({
    required this.kind,
    required this.mapId,
    this.ownerId,
    this.bounds,
  });

  factory NarrativeEditorFocusTarget.map(String mapId) {
    return NarrativeEditorFocusTarget._(
      kind: NarrativeEditorFocusTargetKind.map,
      mapId: _identity(mapId, 'mapId'),
    );
  }

  factory NarrativeEditorFocusTarget.entity(
    String mapId,
    String entityId,
    MapRect bounds,
  ) {
    return NarrativeEditorFocusTarget._(
      kind: NarrativeEditorFocusTargetKind.entity,
      mapId: _identity(mapId, 'mapId'),
      ownerId: _identity(entityId, 'entityId'),
      bounds: _validBounds(bounds),
    );
  }

  factory NarrativeEditorFocusTarget.trigger(
    String mapId,
    String triggerId,
    MapRect bounds,
  ) {
    return NarrativeEditorFocusTarget._(
      kind: NarrativeEditorFocusTargetKind.trigger,
      mapId: _identity(mapId, 'mapId'),
      ownerId: _identity(triggerId, 'triggerId'),
      bounds: _validBounds(bounds),
    );
  }

  final NarrativeEditorFocusTargetKind kind;
  final String mapId;
  final String? ownerId;
  final MapRect? bounds;

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        'mapId': mapId,
        if (ownerId != null) 'ownerId': ownerId,
        if (bounds != null)
          'bounds': {
            'pos': {'x': bounds!.pos.x, 'y': bounds!.pos.y},
            'size': {
              'width': bounds!.size.width,
              'height': bounds!.size.height,
            },
          },
      };
}

@immutable
final class NarrativeEventNavigationIntent {
  NarrativeEventNavigationIntent._({
    required this.destination,
    required this.focusTarget,
    required this.absenceReason,
  });

  factory NarrativeEventNavigationIntent.navigate(
    NarrativeEditorDestination destination, {
    NarrativeEditorFocusTarget? focusTarget,
  }) {
    if (_destinationRequiresFocus(destination) && focusTarget == null) {
      throw ArgumentError(
        'A spatial navigation destination requires an exact focus target.',
      );
    }
    if (focusTarget != null && !_focusMatches(destination, focusTarget)) {
      throw ArgumentError(
        'The focus target must match the navigation destination.',
      );
    }
    return NarrativeEventNavigationIntent._(
      destination: destination,
      focusTarget: focusTarget,
      absenceReason: null,
    );
  }

  factory NarrativeEventNavigationIntent.noDestination(String reason) {
    return NarrativeEventNavigationIntent._(
      destination: null,
      focusTarget: null,
      absenceReason: _identity(reason, 'reason'),
    );
  }

  final NarrativeEditorDestination? destination;
  final NarrativeEditorFocusTarget? focusTarget;
  final String? absenceReason;

  bool get available => destination != null;

  Map<String, Object?> toDebugJson() => {
        if (destination != null) 'destination': destination!.toDebugJson(),
        if (focusTarget != null) 'focusTarget': focusTarget!.toDebugJson(),
        if (absenceReason != null) 'absenceReason': absenceReason,
      };
}

@immutable
final class NarrativeEventDiagnosticDestination {
  NarrativeEventDiagnosticDestination({
    required String code,
    required this.severity,
    required String message,
    required this.recommendedAction,
    required this.navigation,
    Map<String, String> debugReferences = const {},
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message'),
        debugReferences = _debugReferences(debugReferences);

  final String code;
  final NarrativeEventNavigationDiagnosticSeverity severity;
  final String message;
  final NarrativeEventRecommendedAction recommendedAction;
  final NarrativeEventNavigationIntent navigation;
  final Map<String, String> debugReferences;

  NarrativeEditorDestination? get destination => navigation.destination;
  NarrativeEditorFocusTarget? get focusTarget => navigation.focusTarget;
  String? get absenceReason => navigation.absenceReason;

  Map<String, Object?> toDebugJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'recommendedAction': {
          'kind': recommendedAction.name,
          'humanLabel': recommendedAction.humanLabel,
        },
        ...navigation.toDebugJson(),
        'debugReferences': debugReferences,
      };
}

@immutable
final class NarrativeEventNavigationIndex {
  NarrativeEventNavigationIndex._({
    required Map<NarrativeEventSourceRef,
            List<NarrativeSpatialEventSourceOption>>
        spatialBySource,
    required Map<NarrativeOutcomeRef, List<NarrativeOutcomeEventSourceOption>>
        outcomesByRef,
    required Map<String, List<SceneAsset>> scenesById,
    required Map<String, List<NarrativeFactDefinition>> factsById,
    required Map<String, List<NarrativeEventRecord>> eventsById,
    required Map<String, List<ScenarioAsset>> scenariosById,
    required Map<(String, String), int> scenarioNodeCounts,
    required Map<LegacySourceRef, int> provenanceCounts,
    required Map<String, int> mapDataCounts,
    required Map<(NarrativeOutcomeProducerKind, String), int>
        outcomeProducerCounts,
  })  : _spatialBySource = spatialBySource,
        _outcomesByRef = outcomesByRef,
        _scenesById = scenesById,
        _factsById = factsById,
        _eventsById = eventsById,
        _scenariosById = scenariosById,
        _scenarioNodeCounts = Map.unmodifiable(scenarioNodeCounts),
        _provenanceCounts = Map.unmodifiable(provenanceCounts),
        _mapDataCounts = Map.unmodifiable(mapDataCounts),
        _outcomeProducerCounts = Map.unmodifiable(outcomeProducerCounts);

  final Map<NarrativeEventSourceRef, List<NarrativeSpatialEventSourceOption>>
      _spatialBySource;
  final Map<NarrativeOutcomeRef, List<NarrativeOutcomeEventSourceOption>>
      _outcomesByRef;
  final Map<String, List<SceneAsset>> _scenesById;
  final Map<String, List<NarrativeFactDefinition>> _factsById;
  final Map<String, List<NarrativeEventRecord>> _eventsById;
  final Map<String, List<ScenarioAsset>> _scenariosById;
  final Map<(String, String), int> _scenarioNodeCounts;
  final Map<LegacySourceRef, int> _provenanceCounts;
  final Map<String, int> _mapDataCounts;
  final Map<(NarrativeOutcomeProducerKind, String), int> _outcomeProducerCounts;

  NarrativeEventNavigationIntent navigationForSource(
    NarrativeEventSourceRef source,
  ) {
    return source.when(
      entityInteract: (_, __) => _spatialNavigation(source),
      triggerEnter: (_, __) => _spatialNavigation(source),
      mapEnter: (_) => _spatialNavigation(source),
      outcomeReceived: navigationForOutcomeProducer,
    );
  }

  NarrativeEventNavigationIntent mapNavigationForSource(
    NarrativeEventSourceRef source,
  ) {
    return source.when(
      entityInteract: (_, __) => _spatialNavigation(source),
      triggerEnter: (_, __) => _spatialNavigation(source),
      mapEnter: (_) => _spatialNavigation(source),
      outcomeReceived: (_) => NarrativeEventNavigationIntent.noDestination(
        'Ce résultat n’a pas de position sur une carte.',
      ),
    );
  }

  NarrativeEventNavigationIntent navigationForScene(String sceneId) {
    final matches = _scenesById[sceneId] ?? const [];
    if (matches.length != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        matches.isEmpty
            ? 'La Scene référencée n’existe plus.'
            : 'Plusieurs Scenes correspondent à cette référence.',
      );
    }
    return NarrativeEventNavigationIntent.navigate(
      NarrativeEditorDestination.openScene(sceneId),
    );
  }

  NarrativeEventNavigationIntent navigationForFact(String factId) {
    final matches = _factsById[factId] ?? const [];
    if (matches.length != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        matches.isEmpty
            ? 'Le Fact référencé n’existe plus.'
            : 'Plusieurs Facts correspondent à cette référence.',
      );
    }
    return NarrativeEventNavigationIntent.navigate(
      NarrativeEditorDestination.openFact(factId),
    );
  }

  NarrativeEventNavigationIntent navigationForNarrativeEvent(String eventId) {
    final matches = _eventsById[eventId] ?? const [];
    if (matches.length != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        matches.isEmpty
            ? 'L’Event référencé n’existe plus.'
            : 'Plusieurs Events correspondent à cette référence.',
      );
    }
    return NarrativeEventNavigationIntent.navigate(
      NarrativeEditorDestination.openNarrativeEvent(eventId),
    );
  }

  NarrativeEventNavigationIntent navigationForLegacyScenario(
    String scenarioId,
    String nodeId,
  ) {
    final scenarioMatches = _scenariosById[scenarioId] ?? const [];
    final nodeCount = _scenarioNodeCounts[(scenarioId, nodeId)] ?? 0;
    if (scenarioMatches.length != 1 || nodeCount != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        scenarioMatches.isEmpty || nodeCount == 0
            ? 'Le parcours existant référencé n’existe plus.'
            : 'Le parcours existant référencé n’est pas unique.',
      );
    }
    return NarrativeEventNavigationIntent.navigate(
      NarrativeEditorDestination.openLegacyScenario(scenarioId, nodeId),
    );
  }

  NarrativeEventNavigationIntent navigationForMigrationReview(
    LegacySourceRef provenance,
  ) {
    final count = _provenanceCounts[provenance] ?? 0;
    if (count != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        count == 0
            ? 'La donnée existante référencée n’existe plus.'
            : 'La donnée existante référencée n’est pas unique.',
      );
    }
    return NarrativeEventNavigationIntent.navigate(
      NarrativeEditorDestination.openMigrationReview(provenance),
    );
  }

  NarrativeEventNavigationIntent navigationForOutcomeProducer(
    NarrativeOutcomeRef outcome,
  ) {
    final producerCount =
        _outcomeProducerCounts[(outcome.producerKind, outcome.producerId)] ?? 0;
    if (producerCount != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        producerCount == 0
            ? 'Le producteur de ce résultat n’existe plus.'
            : 'Plusieurs producteurs correspondent à ce résultat.',
      );
    }
    return NarrativeEventNavigationIntent.navigate(
      NarrativeEditorDestination.openOutcomeProducer(outcome),
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForSource(
    NarrativeEventSourceRef source,
  ) {
    final navigation = navigationForSource(source);
    if (!navigation.available) {
      return NarrativeEventDiagnosticDestination(
        code: 'sourceNavigationUnavailable',
        severity: NarrativeEventNavigationDiagnosticSeverity.error,
        message: 'La source référencée doit être réparée.',
        recommendedAction: NarrativeEventRecommendedAction.repairReference,
        navigation: navigation,
        debugReferences: _sourceDebugReferences(source),
      );
    }

    return source.when(
      entityInteract: (_, __) => _spatialDiagnostic(source, navigation),
      triggerEnter: (_, __) => _spatialDiagnostic(source, navigation),
      mapEnter: (_) => _spatialDiagnostic(source, navigation),
      outcomeReceived: (outcome) {
        final matches = _outcomesByRef[outcome] ?? const [];
        final option = matches.length == 1 ? matches.single : null;
        final selectable = option?.selectable == true;
        return NarrativeEventDiagnosticDestination(
          code: selectable
              ? 'outcomeNavigationAvailable'
              : 'outcomeNeedsAttention',
          severity: selectable
              ? NarrativeEventNavigationDiagnosticSeverity.info
              : NarrativeEventNavigationDiagnosticSeverity.warning,
          message: selectable
              ? 'Le producteur du résultat est disponible.'
              : option?.unavailableReason ??
                  'Ce résultat doit être vérifié auprès de son producteur.',
          recommendedAction:
              NarrativeEventRecommendedAction.openOutcomeProducer,
          navigation: navigation,
          debugReferences: _sourceDebugReferences(source),
        );
      },
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForScene(String sceneId) {
    return _referenceDiagnostic(
      codePrefix: 'sceneNavigation',
      navigation: navigationForScene(sceneId),
      availableMessage: 'La Scene référencée peut être ouverte.',
      unavailableMessage: 'La référence vers la Scene doit être réparée.',
      availableAction: NarrativeEventRecommendedAction.openScene,
      unavailableAction: NarrativeEventRecommendedAction.repairReference,
      debugReferences: _validDebugIds({'sceneId': sceneId}),
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForFact(String factId) {
    return _referenceDiagnostic(
      codePrefix: 'factNavigation',
      navigation: navigationForFact(factId),
      availableMessage: 'Le Fact référencé peut être ouvert.',
      unavailableMessage: 'La référence vers le Fact doit être réparée.',
      availableAction: NarrativeEventRecommendedAction.openFact,
      unavailableAction: NarrativeEventRecommendedAction.repairReference,
      debugReferences: _validDebugIds({'factId': factId}),
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForNarrativeEvent(
    String eventId,
  ) {
    return _referenceDiagnostic(
      codePrefix: 'eventNavigation',
      navigation: navigationForNarrativeEvent(eventId),
      availableMessage: 'L’Event référencé peut être ouvert.',
      unavailableMessage: 'La référence vers l’Event doit être réparée.',
      availableAction: NarrativeEventRecommendedAction.openNarrativeEvent,
      unavailableAction: NarrativeEventRecommendedAction.repairReference,
      debugReferences: _validDebugIds({'eventId': eventId}),
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForOutcomeProducer(
    NarrativeOutcomeRef outcome,
  ) {
    return _referenceDiagnostic(
      codePrefix: 'outcomeProducerNavigation',
      navigation: navigationForOutcomeProducer(outcome),
      availableMessage: 'Le producteur du résultat peut être ouvert.',
      unavailableMessage: 'La référence vers le producteur doit être réparée.',
      availableAction: NarrativeEventRecommendedAction.openOutcomeProducer,
      unavailableAction: NarrativeEventRecommendedAction.repairReference,
      debugReferences: _sourceDebugReferences(
        NarrativeEventSourceRef.outcomeReceived(outcome),
      ),
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForLegacyScenario(
    String scenarioId,
    String nodeId,
  ) {
    return _referenceDiagnostic(
      codePrefix: 'legacyScenarioNavigation',
      navigation: navigationForLegacyScenario(scenarioId, nodeId),
      availableMessage: 'Le parcours existant peut être ouvert.',
      unavailableMessage: 'Cette donnée existante doit être examinée.',
      availableAction: NarrativeEventRecommendedAction.openLegacyScenario,
      unavailableAction: NarrativeEventRecommendedAction.examineMigration,
      debugReferences: _validDebugIds({
        'scenarioId': scenarioId,
        'nodeId': nodeId,
      }),
    );
  }

  NarrativeEventDiagnosticDestination diagnosticForMigrationReview(
    LegacySourceRef provenance,
  ) {
    return _referenceDiagnostic(
      codePrefix: 'migrationReviewNavigation',
      navigation: navigationForMigrationReview(provenance),
      availableMessage: 'Cette donnée existante peut être examinée.',
      unavailableMessage: 'Cette donnée de migration doit être examinée.',
      availableAction: NarrativeEventRecommendedAction.examineMigration,
      unavailableAction: NarrativeEventRecommendedAction.examineMigration,
      debugReferences: _provenanceDebugReferences(provenance),
    );
  }

  NarrativeEventDiagnosticDestination _referenceDiagnostic({
    required String codePrefix,
    required NarrativeEventNavigationIntent navigation,
    required String availableMessage,
    required String unavailableMessage,
    required NarrativeEventRecommendedAction availableAction,
    required NarrativeEventRecommendedAction unavailableAction,
    required Map<String, String> debugReferences,
  }) {
    final available = navigation.available;
    return NarrativeEventDiagnosticDestination(
      code: '$codePrefix${available ? 'Available' : 'Unavailable'}',
      severity: available
          ? NarrativeEventNavigationDiagnosticSeverity.info
          : NarrativeEventNavigationDiagnosticSeverity.error,
      message: available ? availableMessage : unavailableMessage,
      recommendedAction: available ? availableAction : unavailableAction,
      navigation: navigation,
      debugReferences: debugReferences,
    );
  }

  NarrativeEventNavigationIntent _spatialNavigation(
    NarrativeEventSourceRef source,
  ) {
    final matches = _spatialBySource[source] ?? const [];
    if (matches.length != 1) {
      return NarrativeEventNavigationIntent.noDestination(
        matches.isEmpty
            ? _missingSpatialReason(source)
            : 'Plusieurs éléments correspondent à cette source.',
      );
    }
    final option = matches.single;
    if (option.availability ==
        NarrativeSpatialEventSourceAvailability.missing) {
      return NarrativeEventNavigationIntent.noDestination(
        option.unavailableReason ?? 'Les données de cette map sont absentes.',
      );
    }
    return source.when(
      entityInteract: (mapId, entityId) {
        final bounds = option.geometry.bounds;
        if (bounds == null) {
          return NarrativeEventNavigationIntent.noDestination(
            'La position de l’entité référencée est indisponible.',
          );
        }
        return NarrativeEventNavigationIntent.navigate(
          NarrativeEditorDestination.focusEntity(mapId, entityId),
          focusTarget:
              NarrativeEditorFocusTarget.entity(mapId, entityId, bounds),
        );
      },
      triggerEnter: (mapId, triggerId) {
        final bounds = option.geometry.bounds;
        if (bounds == null) {
          return NarrativeEventNavigationIntent.noDestination(
            'La surface de la zone référencée est indisponible.',
          );
        }
        return NarrativeEventNavigationIntent.navigate(
          NarrativeEditorDestination.focusTrigger(mapId, triggerId),
          focusTarget:
              NarrativeEditorFocusTarget.trigger(mapId, triggerId, bounds),
        );
      },
      mapEnter: (mapId) {
        final mapCount = _mapDataCounts[mapId] ?? 0;
        if (mapCount != 1) {
          return NarrativeEventNavigationIntent.noDestination(
            mapCount == 0
                ? 'Les données de cette map sont absentes.'
                : 'Plusieurs fichiers décrivent cette même map.',
          );
        }
        return NarrativeEventNavigationIntent.navigate(
          NarrativeEditorDestination.openMap(mapId),
          focusTarget: NarrativeEditorFocusTarget.map(mapId),
        );
      },
      outcomeReceived: (_) => throw StateError(
        'An outcome cannot be resolved as a spatial source.',
      ),
    );
  }

  NarrativeEventDiagnosticDestination _spatialDiagnostic(
    NarrativeEventSourceRef source,
    NarrativeEventNavigationIntent navigation,
  ) {
    final option = (_spatialBySource[source] ?? const []).single;
    return NarrativeEventDiagnosticDestination(
      code: option.selectable
          ? 'sourceNavigationAvailable'
          : 'sourceNeedsAttention',
      severity: option.selectable
          ? NarrativeEventNavigationDiagnosticSeverity.info
          : NarrativeEventNavigationDiagnosticSeverity.warning,
      message: option.selectable
          ? 'La source est disponible sur la carte.'
          : option.unavailableReason ?? 'Cette source doit être vérifiée.',
      recommendedAction: option.selectable
          ? NarrativeEventRecommendedAction.viewOnMap
          : NarrativeEventRecommendedAction.changeSource,
      navigation: navigation,
      debugReferences: _sourceDebugReferences(source),
    );
  }
}

NarrativeEventNavigationIndex buildNarrativeEventNavigationIndex({
  required ProjectManifest project,
  required List<MapData> maps,
}) {
  final spatialCatalog = buildNarrativeSpatialEventSourceCatalog(
    project: project,
    maps: maps,
  );
  final outcomeCatalog = buildNarrativeOutcomeEventSourceCatalog(
    project: project,
    maps: maps,
  );
  final scenarioNodeCounts = <(String, String), int>{};
  final provenanceCounts = <LegacySourceRef, int>{};
  final mapDataCounts = <String, int>{};
  final outcomeProducerCounts = <(NarrativeOutcomeProducerKind, String), int>{};
  for (final scene in project.scenes) {
    outcomeProducerCounts.update(
      (NarrativeOutcomeProducerKind.scene, scene.id),
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  for (final scenario in project.scenarios) {
    outcomeProducerCounts.update(
      (NarrativeOutcomeProducerKind.legacyScenario, scenario.id),
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    for (final node in scenario.nodes.where(isLegacyScenarioSourceNode)) {
      final key = (scenario.id, node.id);
      scenarioNodeCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
      final provenance = LegacySourceRef.scenarioSourceNode(
        scenario.id,
        node.id,
      );
      provenanceCounts.update(
        provenance,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }
  for (final trainer in project.trainers) {
    outcomeProducerCounts.update(
      (NarrativeOutcomeProducerKind.battle, 'trainer:${trainer.id}'),
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  for (final map in maps) {
    mapDataCounts.update(map.id, (count) => count + 1, ifAbsent: () => 1);
    for (final event in map.events) {
      final provenance = LegacySourceRef.mapEvent(map.id, event.id);
      provenanceCounts.update(
        provenance,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  return NarrativeEventNavigationIndex._(
    spatialBySource: _indexPresent(
      spatialCatalog.options,
      (option) => option.source,
    ),
    outcomesByRef: _indexPresent(
      outcomeCatalog.options,
      (option) => option.outcome,
    ),
    scenesById: _index(project.scenes, (scene) => scene.id),
    factsById: _index(project.facts, (fact) => fact.id),
    eventsById: _index(
      project.eventRegistry?.records ?? const [],
      (record) => record.id,
    ),
    scenariosById: _index(project.scenarios, (scenario) => scenario.id),
    scenarioNodeCounts: scenarioNodeCounts,
    provenanceCounts: provenanceCounts,
    mapDataCounts: mapDataCounts,
    outcomeProducerCounts: outcomeProducerCounts,
  );
}

bool _focusMatches(
  NarrativeEditorDestination destination,
  NarrativeEditorFocusTarget focus,
) {
  return switch ((destination.kind, focus.kind)) {
    (
      NarrativeEditorDestinationKind.openMap,
      NarrativeEditorFocusTargetKind.map,
    ) =>
      destination.mapId == focus.mapId,
    (
      NarrativeEditorDestinationKind.focusEntity,
      NarrativeEditorFocusTargetKind.entity,
    ) =>
      destination.mapId == focus.mapId && destination.entityId == focus.ownerId,
    (
      NarrativeEditorDestinationKind.focusTrigger,
      NarrativeEditorFocusTargetKind.trigger,
    ) =>
      destination.mapId == focus.mapId &&
          destination.triggerId == focus.ownerId,
    _ => false,
  };
}

bool _destinationRequiresFocus(NarrativeEditorDestination destination) {
  return switch (destination.kind) {
    NarrativeEditorDestinationKind.openMap ||
    NarrativeEditorDestinationKind.focusEntity ||
    NarrativeEditorDestinationKind.focusTrigger =>
      true,
    _ => false,
  };
}

MapRect _validBounds(MapRect bounds) {
  if (bounds.size.width <= 0 || bounds.size.height <= 0) {
    throw ArgumentError.value(bounds, 'bounds', 'must have a positive size');
  }
  return bounds;
}

String _missingSpatialReason(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (_, __) => 'L’entité référencée n’existe plus.',
    triggerEnter: (_, __) => 'La zone référencée n’existe plus.',
    mapEnter: (_) => 'La map référencée n’existe plus.',
    outcomeReceived: (_) =>
        'Le producteur ou le résultat référencé n’existe plus.',
  );
}

Map<String, String> _sourceDebugReferences(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, entityId) => {
      'sourceKind': source.kind.name,
      'mapId': mapId,
      'entityId': entityId,
    },
    triggerEnter: (mapId, triggerId) => {
      'sourceKind': source.kind.name,
      'mapId': mapId,
      'triggerId': triggerId,
    },
    mapEnter: (mapId) => {
      'sourceKind': source.kind.name,
      'mapId': mapId,
    },
    outcomeReceived: (outcome) => {
      'sourceKind': source.kind.name,
      'producerKind': outcome.producerKind.name,
      'producerId': outcome.producerId,
      'outcomeId': outcome.outcomeId,
    },
  );
}

Map<String, String> _provenanceDebugReferences(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => {
      'provenanceKind': 'mapEvent',
      'mapId': mapId,
      'eventId': eventId,
    },
    scenarioSourceNode: (scenarioId, nodeId) => {
      'provenanceKind': 'scenarioSourceNode',
      'scenarioId': scenarioId,
      'nodeId': nodeId,
    },
  );
}

Map<String, String> _validDebugIds(Map<String, String> values) {
  return {
    for (final entry in values.entries)
      if (entry.value.isNotEmpty && entry.value.trim() == entry.value)
        entry.key: entry.value,
  };
}

Map<String, String> _debugReferences(Map<String, String> values) {
  final result = <String, String>{};
  final keys = values.keys.toList()..sort();
  for (final key in keys) {
    result[_identity(key, 'debugReferences key')] =
        _identity(values[key]!, 'debugReferences value');
  }
  return Map.unmodifiable(result);
}

Map<K, List<T>> _indexPresent<K, T>(
  List<T> values,
  K? Function(T value) keyOf,
) {
  final result = <K, List<T>>{};
  for (final value in values) {
    final key = keyOf(value);
    if (key == null) continue;
    result.putIfAbsent(key, () => []).add(value);
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<T>.unmodifiable(entry.value),
  });
}

Map<K, List<T>> _index<K, T>(
  List<T> values,
  K Function(T value) keyOf,
) {
  final result = <K, List<T>>{};
  for (final value in values) {
    result.putIfAbsent(keyOf(value), () => []).add(value);
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<T>.unmodifiable(entry.value),
  });
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
