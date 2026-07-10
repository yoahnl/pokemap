import 'package:meta/meta.dart' show immutable;

import 'narrative_event_wire.dart';

const Set<String> _sourceWireFields = {
  'kind',
  'mapId',
  'entityId',
  'triggerId',
  'outcome',
};

/// Ordering is retained from the V1 picker because existing option sorting
/// observes [values]. Wire encoding always uses names instead of enum indexes.
enum NarrativeEventSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}

enum NarrativeOutcomeProducerKind {
  scene,
  battle,
  legacyScenario,
}

@immutable
final class NarrativeOutcomeRef {
  factory NarrativeOutcomeRef({
    required NarrativeOutcomeProducerKind producerKind,
    required String producerId,
    required String outcomeId,
  }) {
    return NarrativeOutcomeRef._(
      producerKind: producerKind,
      producerId: _validateIdentityArgument(producerId, 'producerId'),
      outcomeId: _validateIdentityArgument(outcomeId, 'outcomeId'),
    );
  }

  const NarrativeOutcomeRef._({
    required this.producerKind,
    required this.producerId,
    required this.outcomeId,
  });

  factory NarrativeOutcomeRef.fromJson(Object? json) {
    return _decodeNarrativeOutcomeRef(json, path: 'outcome');
  }

  final NarrativeOutcomeProducerKind producerKind;
  final String producerId;
  final String outcomeId;

  Map<String, Object?> toJson() => <String, Object?>{
        'producerKind': _producerKindWireName(producerKind),
        'producerId': producerId,
        'outcomeId': outcomeId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeOutcomeRef &&
          other.producerKind == producerKind &&
          other.producerId == producerId &&
          other.outcomeId == outcomeId;

  @override
  int get hashCode => Object.hash(producerKind, producerId, outcomeId);
}

/// Closed union of the four source identities ratified for Event V2 V0.
///
/// Payloads are deliberately available only through [when], keeping invalid
/// cross-variant field combinations unrepresentable.
@immutable
sealed class NarrativeEventSourceRef {
  const NarrativeEventSourceRef._();

  factory NarrativeEventSourceRef.entityInteract(
    String mapId,
    String entityId,
  ) = _EntityInteractSourceRef;

  factory NarrativeEventSourceRef.triggerEnter(
    String mapId,
    String triggerId,
  ) = _TriggerEnterSourceRef;

  factory NarrativeEventSourceRef.mapEnter(
    String mapId,
  ) = _MapEnterSourceRef;

  factory NarrativeEventSourceRef.outcomeReceived(
    NarrativeOutcomeRef outcome,
  ) = _OutcomeReceivedSourceRef;

  factory NarrativeEventSourceRef.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'source');
    final kind = NarrativeEventWire.requiredString(
      object,
      'kind',
      path: 'source',
    );

    switch (kind) {
      case 'entityInteract':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'mapId', 'entityId'},
          path: 'source',
          knownFields: _sourceWireFields,
        );
        return NarrativeEventSourceRef.entityInteract(
          NarrativeEventWire.requiredIdentity(
            object,
            'mapId',
            path: 'source',
          ),
          NarrativeEventWire.requiredIdentity(
            object,
            'entityId',
            path: 'source',
          ),
        );
      case 'triggerEnter':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'mapId', 'triggerId'},
          path: 'source',
          knownFields: _sourceWireFields,
        );
        return NarrativeEventSourceRef.triggerEnter(
          NarrativeEventWire.requiredIdentity(
            object,
            'mapId',
            path: 'source',
          ),
          NarrativeEventWire.requiredIdentity(
            object,
            'triggerId',
            path: 'source',
          ),
        );
      case 'mapEnter':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'mapId'},
          path: 'source',
          knownFields: _sourceWireFields,
        );
        return NarrativeEventSourceRef.mapEnter(
          NarrativeEventWire.requiredIdentity(
            object,
            'mapId',
            path: 'source',
          ),
        );
      case 'outcomeReceived':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'outcome'},
          path: 'source',
          knownFields: _sourceWireFields,
        );
        return NarrativeEventSourceRef.outcomeReceived(
          _decodeNarrativeOutcomeRef(
            NarrativeEventWire.requiredObject(
              object,
              'outcome',
              path: 'source',
            ),
            path: 'source.outcome',
          ),
        );
      default:
        return NarrativeEventWire.unsupported(
          'Unknown source kind "$kind".',
          path: 'source.kind',
          source: kind,
        );
    }
  }

  NarrativeEventSourceKind get kind;

  T when<T>({
    required T Function(String mapId, String entityId) entityInteract,
    required T Function(String mapId, String triggerId) triggerEnter,
    required T Function(String mapId) mapEnter,
    required T Function(NarrativeOutcomeRef outcome) outcomeReceived,
  });

  Map<String, Object?> toJson();
}

final class _EntityInteractSourceRef extends NarrativeEventSourceRef {
  _EntityInteractSourceRef(String mapId, String entityId)
      : mapId = _validateIdentityArgument(mapId, 'mapId'),
        entityId = _validateIdentityArgument(entityId, 'entityId'),
        super._();

  final String mapId;
  final String entityId;

  @override
  NarrativeEventSourceKind get kind => NarrativeEventSourceKind.entityInteract;

  @override
  T when<T>({
    required T Function(String mapId, String entityId) entityInteract,
    required T Function(String mapId, String triggerId) triggerEnter,
    required T Function(String mapId) mapEnter,
    required T Function(NarrativeOutcomeRef outcome) outcomeReceived,
  }) =>
      entityInteract(mapId, entityId);

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'entityInteract',
        'mapId': mapId,
        'entityId': entityId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EntityInteractSourceRef &&
          other.mapId == mapId &&
          other.entityId == entityId;

  @override
  int get hashCode => Object.hash(kind, mapId, entityId);
}

final class _TriggerEnterSourceRef extends NarrativeEventSourceRef {
  _TriggerEnterSourceRef(String mapId, String triggerId)
      : mapId = _validateIdentityArgument(mapId, 'mapId'),
        triggerId = _validateIdentityArgument(triggerId, 'triggerId'),
        super._();

  final String mapId;
  final String triggerId;

  @override
  NarrativeEventSourceKind get kind => NarrativeEventSourceKind.triggerEnter;

  @override
  T when<T>({
    required T Function(String mapId, String entityId) entityInteract,
    required T Function(String mapId, String triggerId) triggerEnter,
    required T Function(String mapId) mapEnter,
    required T Function(NarrativeOutcomeRef outcome) outcomeReceived,
  }) =>
      triggerEnter(mapId, triggerId);

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'triggerEnter',
        'mapId': mapId,
        'triggerId': triggerId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TriggerEnterSourceRef &&
          other.mapId == mapId &&
          other.triggerId == triggerId;

  @override
  int get hashCode => Object.hash(kind, mapId, triggerId);
}

final class _MapEnterSourceRef extends NarrativeEventSourceRef {
  _MapEnterSourceRef(String mapId)
      : mapId = _validateIdentityArgument(mapId, 'mapId'),
        super._();

  final String mapId;

  @override
  NarrativeEventSourceKind get kind => NarrativeEventSourceKind.mapEnter;

  @override
  T when<T>({
    required T Function(String mapId, String entityId) entityInteract,
    required T Function(String mapId, String triggerId) triggerEnter,
    required T Function(String mapId) mapEnter,
    required T Function(NarrativeOutcomeRef outcome) outcomeReceived,
  }) =>
      mapEnter(mapId);

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'mapEnter',
        'mapId': mapId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MapEnterSourceRef && other.mapId == mapId;

  @override
  int get hashCode => Object.hash(kind, mapId);
}

final class _OutcomeReceivedSourceRef extends NarrativeEventSourceRef {
  _OutcomeReceivedSourceRef(this.outcome) : super._();

  final NarrativeOutcomeRef outcome;

  @override
  NarrativeEventSourceKind get kind => NarrativeEventSourceKind.outcomeReceived;

  @override
  T when<T>({
    required T Function(String mapId, String entityId) entityInteract,
    required T Function(String mapId, String triggerId) triggerEnter,
    required T Function(String mapId) mapEnter,
    required T Function(NarrativeOutcomeRef outcome) outcomeReceived,
  }) =>
      outcomeReceived(outcome);

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'outcomeReceived',
        'outcome': outcome.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OutcomeReceivedSourceRef && other.outcome == outcome;

  @override
  int get hashCode => Object.hash(kind, outcome);
}

NarrativeOutcomeRef _decodeNarrativeOutcomeRef(
  Object? raw, {
  required String path,
}) {
  final object = NarrativeEventWire.object(raw, path: path);
  NarrativeEventWire.expectExactFields(
    object,
    const {'producerKind', 'producerId', 'outcomeId'},
    path: path,
  );
  final producerKindName = NarrativeEventWire.requiredString(
    object,
    'producerKind',
    path: path,
  );
  final producerKind = switch (producerKindName) {
    'scene' => NarrativeOutcomeProducerKind.scene,
    'battle' => NarrativeOutcomeProducerKind.battle,
    'legacyScenario' => NarrativeOutcomeProducerKind.legacyScenario,
    _ => NarrativeEventWire.unsupported(
        'Unknown producer kind "$producerKindName".',
        path: '$path.producerKind',
        source: producerKindName,
      ),
  };

  return NarrativeOutcomeRef(
    producerKind: producerKind,
    producerId: NarrativeEventWire.requiredIdentity(
      object,
      'producerId',
      path: path,
    ),
    outcomeId: NarrativeEventWire.requiredIdentity(
      object,
      'outcomeId',
      path: path,
    ),
  );
}

String _producerKindWireName(NarrativeOutcomeProducerKind kind) {
  return switch (kind) {
    NarrativeOutcomeProducerKind.scene => 'scene',
    NarrativeOutcomeProducerKind.battle => 'battle',
    NarrativeOutcomeProducerKind.legacyScenario => 'legacyScenario',
  };
}

String _validateIdentityArgument(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
      value,
      name,
      'must be non-empty and already trimmed',
    );
  }
  return value;
}
