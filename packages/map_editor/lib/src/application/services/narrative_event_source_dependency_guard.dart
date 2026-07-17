import 'package:map_core/map_core.dart';

final class NarrativeEventSourceDependencyDecision {
  NarrativeEventSourceDependencyDecision._({
    required this.isAllowed,
    required List<String> linkedEventIds,
    required this.message,
  }) : linkedEventIds = List.unmodifiable(linkedEventIds);

  factory NarrativeEventSourceDependencyDecision.allowed() {
    return NarrativeEventSourceDependencyDecision._(
      isAllowed: true,
      linkedEventIds: const [],
      message: null,
    );
  }

  factory NarrativeEventSourceDependencyDecision.blocked({
    required List<String> linkedEventIds,
    required String operation,
  }) {
    return NarrativeEventSourceDependencyDecision._(
      isAllowed: false,
      linkedEventIds: linkedEventIds,
      message: 'Action bloquée ($operation) : source utilisée par '
          '${linkedEventIds.join(', ')}.',
    );
  }

  final bool isAllowed;
  final List<String> linkedEventIds;
  final String? message;
}

/// Protects physical identities referenced by every Event V2 record state.
///
/// This guard deliberately scans the registry records directly. The runtime
/// source index excludes drafts and disabled configured records and therefore
/// cannot be used for destructive editor decisions.
final class NarrativeEventSourceDependencyGuard {
  const NarrativeEventSourceDependencyGuard();

  NarrativeEventSourceDependencyDecision inspectMapRename({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required String newMapId,
  }) {
    if (mapId == newMapId) {
      return NarrativeEventSourceDependencyDecision.allowed();
    }
    return _decision(
      registry: registry,
      matches: (source) => _mapId(source) == mapId,
      operation: 'renommage de la map $mapId',
    );
  }

  NarrativeEventSourceDependencyDecision inspectMapDelete({
    required NarrativeEventRegistry? registry,
    required String mapId,
  }) {
    return _decision(
      registry: registry,
      matches: (source) => _mapId(source) == mapId,
      operation: 'suppression de la map $mapId',
    );
  }

  /// Blocks only degradations introduced by a history transition.
  ///
  /// A source which was already unresolved in [current] is deliberately
  /// ignored so an unrelated undo/redo, or a transition repairing that
  /// source, cannot become trapped by stale registry data.
  NarrativeEventSourceDependencyDecision inspectMapTransition({
    required NarrativeEventRegistry? registry,
    required MapData current,
    required MapData candidate,
    required String operation,
  }) {
    return _decision(
      registry: registry,
      matches: (source) =>
          _isResolvedByMap(source, current) &&
          !_isResolvedByMap(source, candidate),
      operation: operation,
    );
  }

  NarrativeEventSourceDependencyDecision inspectEntityUpdate({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required MapEntity current,
    required MapEntity next,
  }) {
    final breaksIdentity = current.id != next.id;
    final becomesSpawn =
        current.kind != MapEntityKind.spawn && next.kind == MapEntityKind.spawn;
    if (!breaksIdentity && !becomesSpawn) {
      return NarrativeEventSourceDependencyDecision.allowed();
    }
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.entityInteract(mapId, current.id),
      operation: breaksIdentity
          ? 'renommage de l’entité ${current.id}'
          : 'conversion de l’entité ${current.id} en spawn',
    );
  }

  NarrativeEventSourceDependencyDecision inspectEntityDelete({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required String entityId,
  }) {
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.entityInteract(mapId, entityId),
      operation: 'suppression de l’entité $entityId',
    );
  }

  NarrativeEventSourceDependencyDecision inspectTriggerUpdate({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required MapTrigger current,
    required MapTrigger next,
  }) {
    final breaksIdentity = current.id != next.id;
    final leavesEventSourceKinds = _isEventSourceTrigger(current.type) &&
        !_isEventSourceTrigger(next.type);
    if (!breaksIdentity && !leavesEventSourceKinds) {
      return NarrativeEventSourceDependencyDecision.allowed();
    }
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.triggerEnter(mapId, current.id),
      operation: breaksIdentity
          ? 'renommage du déclencheur ${current.id}'
          : 'conversion système du déclencheur ${current.id}',
    );
  }

  NarrativeEventSourceDependencyDecision inspectTriggerDelete({
    required NarrativeEventRegistry? registry,
    required String mapId,
    required String triggerId,
  }) {
    return _decision(
      registry: registry,
      matches: (source) =>
          source == NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
      operation: 'suppression du déclencheur $triggerId',
    );
  }
}

NarrativeEventSourceDependencyDecision _decision({
  required NarrativeEventRegistry? registry,
  required bool Function(NarrativeEventSourceRef source) matches,
  required String operation,
}) {
  final eventIds = <String>[
    for (final record in registry?.records ?? const <NarrativeEventRecord>[])
      if (record.when(
        draft: (draft) => draft.source != null && matches(draft.source!),
        configured: (definition, _) => matches(definition.source),
      ))
        record.id,
  ]..sort(compareNarrativeEventUtf16);
  if (eventIds.isEmpty) {
    return NarrativeEventSourceDependencyDecision.allowed();
  }
  return NarrativeEventSourceDependencyDecision.blocked(
    linkedEventIds: eventIds,
    operation: operation,
  );
}

String? _mapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => null,
  );
}

bool _isEventSourceTrigger(TriggerType type) {
  return type == TriggerType.event || type == TriggerType.custom;
}

bool _isResolvedByMap(NarrativeEventSourceRef source, MapData map) {
  return source.when(
    entityInteract: (mapId, entityId) =>
        mapId == map.id &&
        map.entities.any(
          (entity) =>
              entity.id == entityId && entity.kind != MapEntityKind.spawn,
        ),
    triggerEnter: (mapId, triggerId) =>
        mapId == map.id &&
        map.triggers.any(
          (trigger) =>
              trigger.id == triggerId && _isEventSourceTrigger(trigger.type),
        ),
    mapEnter: (mapId) => mapId == map.id,
    outcomeReceived: (_) => false,
  );
}
