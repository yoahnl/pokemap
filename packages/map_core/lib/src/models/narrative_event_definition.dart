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
  'conditionExpression',
  'resetPolicy',
};

const Set<String> _definitionKnownFields = {
  ..._definitionWireFields,
  'enabled',
  'state',
  'draft',
  'definition',
};

const Set<String> _recordWireFields = {
  'state',
  'draft',
  'definition',
  'enabled',
};

enum NarrativeEventReusePolicy { oneShot, reusable }

enum NarrativeEventConditionExpressionKind { leaf, all, any, not }

/// Bounded boolean expression used by authoring and runtime dispatch.
///
/// Historical `conditions` lists are represented as `all(leaves)` in memory.
/// Empty root `all` is the intentional unconditional Event; nested empty
/// groups are rejected so the UI cannot create surprising constants.
@immutable
sealed class NarrativeEventConditionExpression {
  const NarrativeEventConditionExpression._();

  factory NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition condition,
  ) = NarrativeEventConditionLeaf;

  factory NarrativeEventConditionExpression.all(
    List<NarrativeEventConditionExpression> children,
  ) = NarrativeEventConditionAll;

  factory NarrativeEventConditionExpression.any(
    List<NarrativeEventConditionExpression> children,
  ) = NarrativeEventConditionAny;

  factory NarrativeEventConditionExpression.not(
    NarrativeEventConditionExpression child,
  ) = NarrativeEventConditionNot;

  factory NarrativeEventConditionExpression.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'conditionExpression');
    final kind = NarrativeEventWire.requiredString(
      object,
      'kind',
      path: 'conditionExpression',
    );
    return switch (kind) {
      'leaf' => _decodeExpressionLeaf(object),
      'all' => NarrativeEventConditionExpression.all(
          _decodeExpressionChildren(object),
        ),
      'any' => NarrativeEventConditionExpression.any(
          _decodeExpressionChildren(object),
        ),
      'not' => _decodeExpressionNot(object),
      _ => NarrativeEventWire.unsupported(
          'Unknown condition expression kind "$kind".',
          path: 'conditionExpression.kind',
          source: kind,
        ),
    };
  }

  NarrativeEventConditionExpressionKind get kind;
  List<NarrativeEventCondition> get leaves;
  Map<String, Object?> toJson();
}

final class NarrativeEventConditionLeaf
    extends NarrativeEventConditionExpression {
  const NarrativeEventConditionLeaf(this.condition) : super._();

  final NarrativeEventCondition condition;
  @override
  NarrativeEventConditionExpressionKind get kind =>
      NarrativeEventConditionExpressionKind.leaf;
  @override
  List<NarrativeEventCondition> get leaves => [condition];
  @override
  Map<String, Object?> toJson() => {
        'kind': 'leaf',
        'condition': condition.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is NarrativeEventConditionLeaf && other.condition == condition;
  @override
  int get hashCode => Object.hash(kind, condition);
}

sealed class _NarrativeEventConditionGroup
    extends NarrativeEventConditionExpression {
  _NarrativeEventConditionGroup(List<NarrativeEventConditionExpression> values)
      : children = List.unmodifiable(values),
        super._();

  final List<NarrativeEventConditionExpression> children;
  @override
  List<NarrativeEventCondition> get leaves =>
      List.unmodifiable(children.expand((child) => child.leaves));

  @override
  bool operator ==(Object other) =>
      other is _NarrativeEventConditionGroup &&
      other.kind == kind &&
      _listEquals(other.children, children);
  @override
  int get hashCode => Object.hash(kind, Object.hashAll(children));
}

final class NarrativeEventConditionAll extends _NarrativeEventConditionGroup {
  NarrativeEventConditionAll(super.children);
  @override
  NarrativeEventConditionExpressionKind get kind =>
      NarrativeEventConditionExpressionKind.all;
  @override
  Map<String, Object?> toJson() => {
        'kind': 'all',
        'children': [for (final child in children) child.toJson()],
      };
}

final class NarrativeEventConditionAny extends _NarrativeEventConditionGroup {
  NarrativeEventConditionAny(super.children);
  @override
  NarrativeEventConditionExpressionKind get kind =>
      NarrativeEventConditionExpressionKind.any;
  @override
  Map<String, Object?> toJson() => {
        'kind': 'any',
        'children': [for (final child in children) child.toJson()],
      };
}

final class NarrativeEventConditionNot
    extends NarrativeEventConditionExpression {
  const NarrativeEventConditionNot(this.child) : super._();

  final NarrativeEventConditionExpression child;
  @override
  NarrativeEventConditionExpressionKind get kind =>
      NarrativeEventConditionExpressionKind.not;
  @override
  List<NarrativeEventCondition> get leaves => child.leaves;
  @override
  Map<String, Object?> toJson() => {'kind': 'not', 'child': child.toJson()};

  @override
  bool operator ==(Object other) =>
      other is NarrativeEventConditionNot && other.child == child;
  @override
  int get hashCode => Object.hash(kind, child);
}

@immutable
sealed class NarrativeEventResetPolicy {
  const NarrativeEventResetPolicy._();

  const factory NarrativeEventResetPolicy.never() = NarrativeEventResetNever;
  const factory NarrativeEventResetPolicy.onMapReentry() =
      NarrativeEventResetOnMapReentry;
  factory NarrativeEventResetPolicy.onOutcomeReceived(
    NarrativeOutcomeRef outcome,
  ) = NarrativeEventResetOnOutcomeReceived;

  factory NarrativeEventResetPolicy.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'resetPolicy');
    final kind = NarrativeEventWire.requiredString(
      object,
      'kind',
      path: 'resetPolicy',
    );
    return switch (kind) {
      'never' => _decodeResetNever(object),
      'onMapReentry' => _decodeResetOnMapReentry(object),
      'onOutcomeReceived' => _decodeResetOnOutcomeReceived(object),
      _ => NarrativeEventWire.unsupported(
          'Unknown reset policy kind "$kind".',
          path: 'resetPolicy.kind',
          source: kind,
        ),
    };
  }

  Map<String, Object?> toJson();
}

final class NarrativeEventResetNever extends NarrativeEventResetPolicy {
  const NarrativeEventResetNever() : super._();
  @override
  Map<String, Object?> toJson() => const {'kind': 'never'};
  @override
  bool operator ==(Object other) => other is NarrativeEventResetNever;
  @override
  int get hashCode => 0;
}

final class NarrativeEventResetOnMapReentry extends NarrativeEventResetPolicy {
  const NarrativeEventResetOnMapReentry() : super._();
  @override
  Map<String, Object?> toJson() => const {'kind': 'onMapReentry'};
  @override
  bool operator ==(Object other) => other is NarrativeEventResetOnMapReentry;
  @override
  int get hashCode => 1;
}

final class NarrativeEventResetOnOutcomeReceived
    extends NarrativeEventResetPolicy {
  NarrativeEventResetOnOutcomeReceived(this.outcome) : super._();
  final NarrativeOutcomeRef outcome;
  @override
  Map<String, Object?> toJson() => {
        'kind': 'onOutcomeReceived',
        'outcome': outcome.toJson(),
      };
  @override
  bool operator ==(Object other) =>
      other is NarrativeEventResetOnOutcomeReceived && other.outcome == outcome;
  @override
  int get hashCode => Object.hash(2, outcome);
}

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
    NarrativeEventConditionExpression? conditionExpression,
    this.resetPolicy = const NarrativeEventResetPolicy.never(),
  })  : id = _validateEventIdArgument(id, 'id'),
        name = _validateName(name),
        conditionExpression = _validatedExpression(
          conditionExpression ?? _legacyAndExpression(conditions),
          allowEmptyRootAll: true,
          expectedLeaves: conditionExpression == null ? null : conditions,
        ),
        conditions = List.unmodifiable(
          (conditionExpression ?? _legacyAndExpression(conditions)).leaves,
        ),
        sceneId = _validateIdentityArgument(sceneId, 'sceneId'),
        order = _validateOrder(order) {
    _validateConfiguredResetPolicy(
      source: source,
      reusePolicy: reusePolicy,
      resetPolicy: resetPolicy,
    );
  }

  factory NarrativeEventDefinition.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'definition');
    final expectedFields = <String>{
      'id',
      'name',
      'source',
      'conditions',
      'sceneId',
      'reusePolicy',
      'priority',
      'order',
      if (object.containsKey('conditionExpression')) 'conditionExpression',
      if (object.containsKey('resetPolicy')) 'resetPolicy',
    };
    NarrativeEventWire.expectExactFields(object, expectedFields,
        path: 'definition', knownFields: _definitionKnownFields);
    final expressionJson = object['conditionExpression'];
    final resetJson = object['resetPolicy'];
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
      conditionExpression: expressionJson == null
          ? null
          : NarrativeEventConditionExpression.fromJson(expressionJson),
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
      resetPolicy: resetJson == null
          ? const NarrativeEventResetPolicy.never()
          : NarrativeEventResetPolicy.fromJson(resetJson),
    );
  }

  final String id;
  final String name;
  final NarrativeEventSourceRef source;
  final List<NarrativeEventCondition> conditions;
  final NarrativeEventConditionExpression conditionExpression;
  final String sceneId;
  final NarrativeEventReusePolicy reusePolicy;
  final int priority;
  final int order;
  final NarrativeEventResetPolicy resetPolicy;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'source': source.toJson(),
        'conditions': [for (final condition in conditions) condition.toJson()],
        if (!_isLegacyAndExpression(conditionExpression, conditions))
          'conditionExpression': conditionExpression.toJson(),
        'sceneId': sceneId,
        'reusePolicy': reusePolicy.name,
        'priority': priority,
        'order': order,
        if (resetPolicy is! NarrativeEventResetNever)
          'resetPolicy': resetPolicy.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventDefinition &&
          other.id == id &&
          other.name == name &&
          other.source == source &&
          _listEquals(other.conditions, conditions) &&
          other.conditionExpression == conditionExpression &&
          other.sceneId == sceneId &&
          other.reusePolicy == reusePolicy &&
          other.priority == priority &&
          other.order == order &&
          other.resetPolicy == resetPolicy;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        source,
        Object.hashAll(conditions),
        conditionExpression,
        sceneId,
        reusePolicy,
        priority,
        order,
        resetPolicy,
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
    NarrativeEventConditionExpression? conditionExpression,
    this.resetPolicy = const NarrativeEventResetPolicy.never(),
  })  : id = _validateEventIdArgument(id, 'id'),
        name = _validateName(name),
        conditionExpression = _validatedExpression(
          conditionExpression ?? _legacyAndExpression(conditions),
          allowEmptyRootAll: true,
          expectedLeaves: conditionExpression == null ? null : conditions,
        ),
        conditions = List.unmodifiable(
          (conditionExpression ?? _legacyAndExpression(conditions)).leaves,
        ),
        sceneId = sceneId == null
            ? null
            : _validateIdentityArgument(sceneId, 'sceneId'),
        order = _validateOrder(order) {
    _validateDraftResetPolicy(
      source: source,
      reusePolicy: reusePolicy,
      resetPolicy: resetPolicy,
    );
  }

  factory NarrativeEventDraft.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'draft');
    final expectedFields = <String>{
      'id',
      'name',
      if (object.containsKey('source')) 'source',
      'conditions',
      if (object.containsKey('sceneId')) 'sceneId',
      if (object.containsKey('reusePolicy')) 'reusePolicy',
      'priority',
      'order',
      if (object.containsKey('conditionExpression')) 'conditionExpression',
      if (object.containsKey('resetPolicy')) 'resetPolicy',
    };
    NarrativeEventWire.expectExactFields(object, expectedFields,
        path: 'draft', knownFields: _definitionKnownFields);
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
      conditionExpression: object['conditionExpression'] == null
          ? null
          : NarrativeEventConditionExpression.fromJson(
              object['conditionExpression'],
            ),
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
      resetPolicy: object['resetPolicy'] == null
          ? const NarrativeEventResetPolicy.never()
          : NarrativeEventResetPolicy.fromJson(object['resetPolicy']),
    );
  }

  final String id;
  final String name;
  final NarrativeEventSourceRef? source;
  final List<NarrativeEventCondition> conditions;
  final NarrativeEventConditionExpression conditionExpression;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;
  final NarrativeEventResetPolicy resetPolicy;

  bool get isComplete =>
      source != null && sceneId != null && reusePolicy != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (source != null) 'source': source!.toJson(),
        'conditions': [for (final condition in conditions) condition.toJson()],
        if (!_isLegacyAndExpression(conditionExpression, conditions))
          'conditionExpression': conditionExpression.toJson(),
        if (sceneId != null) 'sceneId': sceneId,
        if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
        'priority': priority,
        'order': order,
        if (resetPolicy is! NarrativeEventResetNever)
          'resetPolicy': resetPolicy.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventDraft &&
          other.id == id &&
          other.name == name &&
          other.source == source &&
          _listEquals(other.conditions, conditions) &&
          other.conditionExpression == conditionExpression &&
          other.sceneId == sceneId &&
          other.reusePolicy == reusePolicy &&
          other.priority == priority &&
          other.order == order &&
          other.resetPolicy == resetPolicy;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        source,
        Object.hashAll(conditions),
        conditionExpression,
        sceneId,
        reusePolicy,
        priority,
        order,
        resetPolicy,
      );
}

@immutable
sealed class NarrativeEventRecord {
  const NarrativeEventRecord._();

  factory NarrativeEventRecord.draft(NarrativeEventDraft draft) =
      _NarrativeEventDraftRecord;

  /// Builds the configured wire state without contextual claim validation.
  factory NarrativeEventRecord.configuredStructurallyUnchecked(
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
        return NarrativeEventRecord.configuredStructurallyUnchecked(
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

const int _maximumConditionExpressionDepth = 8;
const int _maximumConditionExpressionNodes = 128;

NarrativeEventConditionExpression _decodeExpressionLeaf(
  Map<String, Object?> object,
) {
  NarrativeEventWire.expectExactFields(
    object,
    const {'kind', 'condition'},
    path: 'conditionExpression',
  );
  return NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition.fromJson(
      NarrativeEventWire.requiredObject(
        object,
        'condition',
        path: 'conditionExpression',
      ),
    ),
  );
}

List<NarrativeEventConditionExpression> _decodeExpressionChildren(
  Map<String, Object?> object,
) {
  NarrativeEventWire.expectExactFields(
    object,
    const {'kind', 'children'},
    path: 'conditionExpression',
  );
  final values = NarrativeEventWire.requiredList(
    object,
    'children',
    path: 'conditionExpression',
  );
  return [
    for (final value in values)
      NarrativeEventConditionExpression.fromJson(value),
  ];
}

NarrativeEventConditionExpression _decodeExpressionNot(
  Map<String, Object?> object,
) {
  NarrativeEventWire.expectExactFields(
    object,
    const {'kind', 'child'},
    path: 'conditionExpression',
  );
  return NarrativeEventConditionExpression.not(
    NarrativeEventConditionExpression.fromJson(
      NarrativeEventWire.requiredObject(
        object,
        'child',
        path: 'conditionExpression',
      ),
    ),
  );
}

NarrativeEventResetPolicy _decodeResetNever(Map<String, Object?> object) {
  NarrativeEventWire.expectExactFields(
    object,
    const {'kind'},
    path: 'resetPolicy',
  );
  return const NarrativeEventResetPolicy.never();
}

NarrativeEventResetPolicy _decodeResetOnMapReentry(
  Map<String, Object?> object,
) {
  NarrativeEventWire.expectExactFields(
    object,
    const {'kind'},
    path: 'resetPolicy',
  );
  return const NarrativeEventResetPolicy.onMapReentry();
}

NarrativeEventResetPolicy _decodeResetOnOutcomeReceived(
  Map<String, Object?> object,
) {
  NarrativeEventWire.expectExactFields(
    object,
    const {'kind', 'outcome'},
    path: 'resetPolicy',
  );
  return NarrativeEventResetPolicy.onOutcomeReceived(
    NarrativeOutcomeRef.fromJson(
      NarrativeEventWire.requiredObject(
        object,
        'outcome',
        path: 'resetPolicy',
      ),
    ),
  );
}

NarrativeEventConditionExpression _legacyAndExpression(
  Iterable<NarrativeEventCondition> conditions,
) {
  return NarrativeEventConditionExpression.all([
    for (final condition in conditions)
      NarrativeEventConditionExpression.leaf(condition),
  ]);
}

NarrativeEventConditionExpression _validatedExpression(
  NarrativeEventConditionExpression expression, {
  required bool allowEmptyRootAll,
  Iterable<NarrativeEventCondition>? expectedLeaves,
}) {
  var nodeCount = 0;

  void visit(
    NarrativeEventConditionExpression current, {
    required int depth,
    required bool isRoot,
  }) {
    nodeCount++;
    if (nodeCount > _maximumConditionExpressionNodes) {
      throw ArgumentError.value(
        expression,
        'conditionExpression',
        'must contain at most $_maximumConditionExpressionNodes nodes',
      );
    }
    if (depth > _maximumConditionExpressionDepth) {
      throw ArgumentError.value(
        expression,
        'conditionExpression',
        'must be at most $_maximumConditionExpressionDepth levels deep',
      );
    }
    switch (current) {
      case NarrativeEventConditionLeaf():
        return;
      case NarrativeEventConditionAll(:final children):
        if (children.isEmpty && !(isRoot && allowEmptyRootAll)) {
          throw ArgumentError.value(
            expression,
            'conditionExpression',
            'all groups must not be empty unless they are the root',
          );
        }
        for (final child in children) {
          visit(child, depth: depth + 1, isRoot: false);
        }
      case NarrativeEventConditionAny(:final children):
        if (children.isEmpty) {
          throw ArgumentError.value(
            expression,
            'conditionExpression',
            'any groups must not be empty',
          );
        }
        for (final child in children) {
          visit(child, depth: depth + 1, isRoot: false);
        }
      case NarrativeEventConditionNot(:final child):
        visit(child, depth: depth + 1, isRoot: false);
    }
  }

  visit(expression, depth: 1, isRoot: true);
  final expected = expectedLeaves?.toList(growable: false);
  if (expected != null && !_listEquals(expected, expression.leaves)) {
    throw ArgumentError.value(
      expression,
      'conditionExpression',
      'leaves must match the compatibility conditions list',
    );
  }
  return expression;
}

bool _isLegacyAndExpression(
  NarrativeEventConditionExpression expression,
  List<NarrativeEventCondition> conditions,
) {
  return expression is NarrativeEventConditionAll &&
      expression.children.every(
        (child) => child is NarrativeEventConditionLeaf,
      ) &&
      _listEquals(expression.leaves, conditions);
}

void _validateConfiguredResetPolicy({
  required NarrativeEventSourceRef source,
  required NarrativeEventReusePolicy reusePolicy,
  required NarrativeEventResetPolicy resetPolicy,
}) {
  if (reusePolicy == NarrativeEventReusePolicy.reusable &&
      resetPolicy is! NarrativeEventResetNever) {
    throw ArgumentError.value(
      resetPolicy,
      'resetPolicy',
      'is only meaningful for one-shot Events',
    );
  }
  if (resetPolicy is NarrativeEventResetOnMapReentry &&
      source.kind == NarrativeEventSourceKind.outcomeReceived) {
    throw ArgumentError.value(
      resetPolicy,
      'resetPolicy',
      'onMapReentry requires a spatial Event source',
    );
  }
}

void _validateDraftResetPolicy({
  required NarrativeEventSourceRef? source,
  required NarrativeEventReusePolicy? reusePolicy,
  required NarrativeEventResetPolicy resetPolicy,
}) {
  if (reusePolicy == NarrativeEventReusePolicy.reusable &&
      resetPolicy is! NarrativeEventResetNever) {
    throw ArgumentError.value(
      resetPolicy,
      'resetPolicy',
      'is only meaningful for one-shot Events',
    );
  }
  if (source?.kind == NarrativeEventSourceKind.outcomeReceived &&
      resetPolicy is NarrativeEventResetOnMapReentry) {
    throw ArgumentError.value(
      resetPolicy,
      'resetPolicy',
      'onMapReentry requires a spatial Event source',
    );
  }
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
