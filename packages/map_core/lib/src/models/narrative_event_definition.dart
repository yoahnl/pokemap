import 'package:meta/meta.dart' show immutable;

import 'narrative_event_source_ref.dart';
import 'narrative_event_wire.dart';

final RegExp narrativeEventIdPattern = RegExp(
  r'^evt_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

const Set<String> _conditionWireFields = {
  'kind',
  'factId',
  'eventId',
  'expectedValue',
};

const Set<String> _definitionWireFields = {
  'id',
  'name',
  'source',
  'conditions',
  'sceneId',
  'reusePolicy',
  'priority',
  'order',
};

const Set<String> _definitionKnownFields = {
  ..._definitionWireFields,
  'enabled',
  'state',
  'draft',
  'definition',
};

const Set<String> _draftWireFields = {
  'id',
  'name',
  'source',
  'conditions',
  'sceneId',
  'reusePolicy',
  'priority',
  'order',
};

const Set<String> _recordWireFields = {
  'state',
  'draft',
  'definition',
  'enabled',
};

enum NarrativeEventReusePolicy { oneShot, reusable }

@immutable
sealed class NarrativeEventCondition {
  const NarrativeEventCondition._();

  factory NarrativeEventCondition.fact(
    String factId,
    bool expectedValue,
  ) = _FactNarrativeEventCondition;

  factory NarrativeEventCondition.narrativeEventConsumed(
    String eventId,
    bool expectedValue,
  ) = _ConsumedNarrativeEventCondition;

  factory NarrativeEventCondition.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'condition');
    final kind = NarrativeEventWire.requiredString(
      object,
      'kind',
      path: 'condition',
    );
    switch (kind) {
      case 'fact':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'factId', 'expectedValue'},
          path: 'condition',
          knownFields: _conditionWireFields,
        );
        return NarrativeEventCondition.fact(
          NarrativeEventWire.requiredIdentity(
            object,
            'factId',
            path: 'condition',
          ),
          NarrativeEventWire.requiredBool(
            object,
            'expectedValue',
            path: 'condition',
          ),
        );
      case 'narrativeEventConsumed':
        NarrativeEventWire.expectExactFields(
          object,
          const {'kind', 'eventId', 'expectedValue'},
          path: 'condition',
          knownFields: _conditionWireFields,
        );
        return NarrativeEventCondition.narrativeEventConsumed(
          _decodeEventId(
            NarrativeEventWire.requiredIdentity(
              object,
              'eventId',
              path: 'condition',
            ),
            path: 'condition.eventId',
          ),
          NarrativeEventWire.requiredBool(
            object,
            'expectedValue',
            path: 'condition',
          ),
        );
      default:
        return NarrativeEventWire.unsupported(
          'Unknown condition kind "$kind".',
          path: 'condition.kind',
          source: kind,
        );
    }
  }

  bool get expectedValue;

  T when<T>({
    required T Function(String factId, bool expectedValue) fact,
    required T Function(String eventId, bool expectedValue)
        narrativeEventConsumed,
  });

  Map<String, Object?> toJson();
}

final class _FactNarrativeEventCondition extends NarrativeEventCondition {
  _FactNarrativeEventCondition(String factId, this.expectedValue)
      : factId = _validateIdentityArgument(factId, 'factId'),
        super._();

  final String factId;

  @override
  final bool expectedValue;

  @override
  T when<T>({
    required T Function(String factId, bool expectedValue) fact,
    required T Function(String eventId, bool expectedValue)
        narrativeEventConsumed,
  }) =>
      fact(factId, expectedValue);

  @override
  Map<String, Object?> toJson() => {
        'kind': 'fact',
        'factId': factId,
        'expectedValue': expectedValue,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FactNarrativeEventCondition &&
          other.factId == factId &&
          other.expectedValue == expectedValue;

  @override
  int get hashCode => Object.hash('fact', factId, expectedValue);
}

final class _ConsumedNarrativeEventCondition extends NarrativeEventCondition {
  _ConsumedNarrativeEventCondition(String eventId, this.expectedValue)
      : eventId = _validateEventIdArgument(eventId, 'eventId'),
        super._();

  final String eventId;

  @override
  final bool expectedValue;

  @override
  T when<T>({
    required T Function(String factId, bool expectedValue) fact,
    required T Function(String eventId, bool expectedValue)
        narrativeEventConsumed,
  }) =>
      narrativeEventConsumed(eventId, expectedValue);

  @override
  Map<String, Object?> toJson() => {
        'kind': 'narrativeEventConsumed',
        'eventId': eventId,
        'expectedValue': expectedValue,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ConsumedNarrativeEventCondition &&
          other.eventId == eventId &&
          other.expectedValue == expectedValue;

  @override
  int get hashCode =>
      Object.hash('narrativeEventConsumed', eventId, expectedValue);
}

@immutable
final class NarrativeEventDefinition {
  NarrativeEventDefinition({
    required String id,
    required String name,
    required this.source,
    required List<NarrativeEventCondition> conditions,
    required String sceneId,
    required this.reusePolicy,
    required this.priority,
    required int order,
  })  : id = _validateEventIdArgument(id, 'id'),
        name = _validateName(name),
        conditions = List.unmodifiable(conditions),
        sceneId = _validateIdentityArgument(sceneId, 'sceneId'),
        order = _validateOrder(order);

  factory NarrativeEventDefinition.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'definition');
    NarrativeEventWire.expectExactFields(
      object,
      _definitionWireFields,
      path: 'definition',
      knownFields: _definitionKnownFields,
    );
    return NarrativeEventDefinition(
      id: _decodeEventId(
        NarrativeEventWire.requiredIdentity(object, 'id', path: 'definition'),
        path: 'definition.id',
      ),
      name: _decodeName(object, path: 'definition'),
      source: NarrativeEventSourceRef.fromJson(
        NarrativeEventWire.requiredObject(
          object,
          'source',
          path: 'definition',
        ),
      ),
      conditions: _decodeConditions(object, path: 'definition'),
      sceneId: NarrativeEventWire.requiredIdentity(
        object,
        'sceneId',
        path: 'definition',
      ),
      reusePolicy: _decodeReusePolicy(object, path: 'definition'),
      priority: NarrativeEventWire.requiredInt(
        object,
        'priority',
        path: 'definition',
      ),
      order: _decodeOrder(object, path: 'definition'),
    );
  }

  final String id;
  final String name;
  final NarrativeEventSourceRef source;
  final List<NarrativeEventCondition> conditions;
  final String sceneId;
  final NarrativeEventReusePolicy reusePolicy;
  final int priority;
  final int order;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'source': source.toJson(),
        'conditions': [for (final condition in conditions) condition.toJson()],
        'sceneId': sceneId,
        'reusePolicy': reusePolicy.name,
        'priority': priority,
        'order': order,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventDefinition &&
          other.id == id &&
          other.name == name &&
          other.source == source &&
          _listEquals(other.conditions, conditions) &&
          other.sceneId == sceneId &&
          other.reusePolicy == reusePolicy &&
          other.priority == priority &&
          other.order == order;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        source,
        Object.hashAll(conditions),
        sceneId,
        reusePolicy,
        priority,
        order,
      );
}

@immutable
final class NarrativeEventDraft {
  NarrativeEventDraft({
    required String id,
    required String name,
    this.source,
    required List<NarrativeEventCondition> conditions,
    String? sceneId,
    this.reusePolicy,
    required this.priority,
    required int order,
  })  : id = _validateEventIdArgument(id, 'id'),
        name = _validateName(name),
        conditions = List.unmodifiable(conditions),
        sceneId = sceneId == null
            ? null
            : _validateIdentityArgument(sceneId, 'sceneId'),
        order = _validateOrder(order);

  factory NarrativeEventDraft.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'draft');
    NarrativeEventWire.expectExactFields(
      object,
      _draftWireFields,
      path: 'draft',
      knownFields: _definitionKnownFields,
    );
    final sourceJson = object['source'];
    final sceneIdJson = object['sceneId'];
    final reusePolicyJson = object['reusePolicy'];
    return NarrativeEventDraft(
      id: _decodeEventId(
        NarrativeEventWire.requiredIdentity(object, 'id', path: 'draft'),
        path: 'draft.id',
      ),
      name: _decodeName(object, path: 'draft'),
      source: sourceJson == null
          ? null
          : NarrativeEventSourceRef.fromJson(sourceJson),
      conditions: _decodeConditions(object, path: 'draft'),
      sceneId: sceneIdJson == null
          ? null
          : _decodeOptionalIdentity(sceneIdJson, 'sceneId', path: 'draft'),
      reusePolicy: reusePolicyJson == null
          ? null
          : _decodeReusePolicyValue(reusePolicyJson, path: 'draft.reusePolicy'),
      priority: NarrativeEventWire.requiredInt(
        object,
        'priority',
        path: 'draft',
      ),
      order: _decodeOrder(object, path: 'draft'),
    );
  }

  final String id;
  final String name;
  final NarrativeEventSourceRef? source;
  final List<NarrativeEventCondition> conditions;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;

  bool get isComplete =>
      source != null && sceneId != null && reusePolicy != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (source != null) 'source': source!.toJson(),
        'conditions': [for (final condition in conditions) condition.toJson()],
        if (sceneId != null) 'sceneId': sceneId,
        if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
        'priority': priority,
        'order': order,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventDraft &&
          other.id == id &&
          other.name == name &&
          other.source == source &&
          _listEquals(other.conditions, conditions) &&
          other.sceneId == sceneId &&
          other.reusePolicy == reusePolicy &&
          other.priority == priority &&
          other.order == order;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        source,
        Object.hashAll(conditions),
        sceneId,
        reusePolicy,
        priority,
        order,
      );
}

@immutable
sealed class NarrativeEventRecord {
  const NarrativeEventRecord._();

  factory NarrativeEventRecord.draft(NarrativeEventDraft draft) =
      _NarrativeEventDraftRecord;

  factory NarrativeEventRecord.configured(
    NarrativeEventDefinition definition, {
    required bool enabled,
  }) = _NarrativeEventConfiguredRecord;

  factory NarrativeEventRecord.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'record');
    final state = NarrativeEventWire.requiredString(
      object,
      'state',
      path: 'record',
    );
    switch (state) {
      case 'draft':
        NarrativeEventWire.expectExactFields(
          object,
          const {'state', 'draft'},
          path: 'record',
          knownFields: _recordWireFields,
        );
        return NarrativeEventRecord.draft(
          NarrativeEventDraft.fromJson(
            NarrativeEventWire.requiredObject(
              object,
              'draft',
              path: 'record',
            ),
          ),
        );
      case 'configured':
        NarrativeEventWire.expectExactFields(
          object,
          const {'state', 'definition', 'enabled'},
          path: 'record',
          knownFields: _recordWireFields,
        );
        return NarrativeEventRecord.configured(
          NarrativeEventDefinition.fromJson(
            NarrativeEventWire.requiredObject(
              object,
              'definition',
              path: 'record',
            ),
          ),
          enabled: NarrativeEventWire.requiredBool(
            object,
            'enabled',
            path: 'record',
          ),
        );
      default:
        return NarrativeEventWire.unsupported(
          'Unknown record state "$state".',
          path: 'record.state',
          source: state,
        );
    }
  }

  String get id;
  NarrativeEventDraft? get draftOrNull;
  NarrativeEventDefinition? get definitionOrNull;
  bool? get enabledOrNull;

  T when<T>({
    required T Function(NarrativeEventDraft draft) draft,
    required T Function(NarrativeEventDefinition definition, bool enabled)
        configured,
  });

  Map<String, Object?> toJson();
}

final class _NarrativeEventDraftRecord extends NarrativeEventRecord {
  const _NarrativeEventDraftRecord(this.draft) : super._();

  final NarrativeEventDraft draft;

  @override
  String get id => draft.id;

  @override
  NarrativeEventDraft get draftOrNull => draft;

  @override
  NarrativeEventDefinition? get definitionOrNull => null;

  @override
  bool? get enabledOrNull => null;

  @override
  T when<T>({
    required T Function(NarrativeEventDraft draft) draft,
    required T Function(NarrativeEventDefinition definition, bool enabled)
        configured,
  }) =>
      draft(this.draft);

  @override
  Map<String, Object?> toJson() => {
        'state': 'draft',
        'draft': draft.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NarrativeEventDraftRecord && other.draft == draft;

  @override
  int get hashCode => Object.hash('draft', draft);
}

final class _NarrativeEventConfiguredRecord extends NarrativeEventRecord {
  const _NarrativeEventConfiguredRecord(
    this.definition, {
    required this.enabled,
  }) : super._();

  final NarrativeEventDefinition definition;
  final bool enabled;

  @override
  String get id => definition.id;

  @override
  NarrativeEventDraft? get draftOrNull => null;

  @override
  NarrativeEventDefinition get definitionOrNull => definition;

  @override
  bool get enabledOrNull => enabled;

  @override
  T when<T>({
    required T Function(NarrativeEventDraft draft) draft,
    required T Function(NarrativeEventDefinition definition, bool enabled)
        configured,
  }) =>
      configured(definition, enabled);

  @override
  Map<String, Object?> toJson() => {
        'state': 'configured',
        'definition': definition.toJson(),
        'enabled': enabled,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NarrativeEventConfiguredRecord &&
          other.definition == definition &&
          other.enabled == enabled;

  @override
  int get hashCode => Object.hash('configured', definition, enabled);
}

String _decodeName(Map<String, Object?> object, {required String path}) {
  final value = NarrativeEventWire.requiredString(object, 'name', path: path);
  if (value.trim().isEmpty) {
    return NarrativeEventWire.invalid(
      'Name must be non-empty after trimming.',
      path: '$path.name',
      source: value,
    );
  }
  return value;
}

List<NarrativeEventCondition> _decodeConditions(
  Map<String, Object?> object, {
  required String path,
}) {
  final values = NarrativeEventWire.requiredList(
    object,
    'conditions',
    path: path,
  );
  return [
    for (var index = 0; index < values.length; index++)
      NarrativeEventCondition.fromJson(values[index]),
  ];
}

NarrativeEventReusePolicy _decodeReusePolicy(
  Map<String, Object?> object, {
  required String path,
}) {
  return _decodeReusePolicyValue(
    NarrativeEventWire.requiredString(object, 'reusePolicy', path: path),
    path: '$path.reusePolicy',
  );
}

NarrativeEventReusePolicy _decodeReusePolicyValue(
  Object? value, {
  required String path,
}) {
  if (value is! String) {
    return NarrativeEventWire.invalid(
      'Reuse policy must be a string.',
      path: path,
      source: value,
    );
  }
  return switch (value) {
    'oneShot' => NarrativeEventReusePolicy.oneShot,
    'reusable' => NarrativeEventReusePolicy.reusable,
    _ => NarrativeEventWire.unsupported(
        'Unknown reuse policy "$value".',
        path: path,
        source: value,
      ),
  };
}

int _decodeOrder(Map<String, Object?> object, {required String path}) {
  final order = NarrativeEventWire.requiredInt(object, 'order', path: path);
  if (order < 0) {
    return NarrativeEventWire.invalid(
      'Order must be zero or positive.',
      path: '$path.order',
      source: order,
    );
  }
  return order;
}

String _decodeEventId(String value, {required String path}) {
  if (!narrativeEventIdPattern.hasMatch(value)) {
    return NarrativeEventWire.invalid(
      'Invalid Narrative Event ID.',
      path: path,
      source: value,
    );
  }
  return value;
}

String _decodeOptionalIdentity(
  Object? value,
  String field, {
  required String path,
}) {
  if (value is! String || value.isEmpty || value.trim() != value) {
    return NarrativeEventWire.invalid(
      'Identity "$field" must be a non-empty, already-trimmed string.',
      path: '$path.$field',
      source: value,
    );
  }
  return value;
}

String _validateName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(
        value, 'name', 'must be non-empty after trimming');
  }
  return trimmed;
}

String _validateIdentityArgument(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
        value, name, 'must be non-empty and already trimmed');
  }
  return value;
}

String _validateEventIdArgument(String value, String name) {
  _validateIdentityArgument(value, name);
  if (!narrativeEventIdPattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'must match the Event V2 ID format');
  }
  return value;
}

int _validateOrder(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'order', 'must be zero or positive');
  }
  return value;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
