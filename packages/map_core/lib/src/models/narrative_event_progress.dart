import 'package:meta/meta.dart' show immutable;

import 'narrative_event_definition.dart';
import 'narrative_event_source_ref.dart';
import 'narrative_event_wire.dart';

final RegExp narrativeOutcomeDeliveryIdPattern = RegExp(
  r'^outd_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final RegExp narrativeEventExecutionIdPattern = RegExp(
  r'^evx_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final RegExp narrativeEventCorrelationIdPattern = RegExp(
  r'^corr_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

const _deliveryFields = {
  'deliveryId',
  'outcome',
  'causationExecutionId',
  'rootCorrelationId',
  'depth',
  'attemptCount',
};

const _progressFields = {
  'consumedNarrativeEventIds',
  'pendingNarrativeOutcomeDeliveries',
  'deliveredNarrativeOutcomeDeliveryIds',
};

@immutable
final class NarrativeOutcomeDelivery {
  NarrativeOutcomeDelivery({
    required String deliveryId,
    required this.outcome,
    String? causationExecutionId,
    required String rootCorrelationId,
    required int depth,
    required int attemptCount,
  })  : deliveryId = _validatePattern(
          deliveryId,
          'deliveryId',
          narrativeOutcomeDeliveryIdPattern,
          'outd_<uuid-v7>',
        ),
        causationExecutionId = causationExecutionId == null
            ? null
            : _validatePattern(
                causationExecutionId,
                'causationExecutionId',
                narrativeEventExecutionIdPattern,
                'evx_<uuid-v7>',
              ),
        rootCorrelationId = _validatePattern(
          rootCorrelationId,
          'rootCorrelationId',
          narrativeEventCorrelationIdPattern,
          'corr_<uuid-v7>',
        ),
        depth = _validateNonNegative(depth, 'depth'),
        attemptCount = _validateNonNegative(attemptCount, 'attemptCount');

  factory NarrativeOutcomeDelivery.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'delivery');
    NarrativeEventWire.expectExactFields(
      object,
      _deliveryFields,
      path: 'delivery',
    );
    final rawCausation = _requiredNullableValue(
      object,
      'causationExecutionId',
      path: 'delivery',
    );
    try {
      return NarrativeOutcomeDelivery(
        deliveryId: NarrativeEventWire.requiredString(
          object,
          'deliveryId',
          path: 'delivery',
        ),
        outcome: NarrativeOutcomeRef.fromJson(
          NarrativeEventWire.requiredObject(
            object,
            'outcome',
            path: 'delivery',
          ),
        ),
        causationExecutionId: rawCausation == null
            ? null
            : _requireString(
                rawCausation,
                path: 'delivery.causationExecutionId',
              ),
        rootCorrelationId: NarrativeEventWire.requiredString(
          object,
          'rootCorrelationId',
          path: 'delivery',
        ),
        depth: NarrativeEventWire.requiredInt(
          object,
          'depth',
          path: 'delivery',
        ),
        attemptCount: NarrativeEventWire.requiredInt(
          object,
          'attemptCount',
          path: 'delivery',
        ),
      );
    } on ArgumentError catch (error) {
      return NarrativeEventWire.invalid(
        error.message?.toString() ?? 'Invalid delivery invariant.',
        path: 'delivery',
        source: object,
      );
    }
  }

  final String deliveryId;
  final NarrativeOutcomeRef outcome;
  final String? causationExecutionId;
  final String rootCorrelationId;
  final int depth;
  final int attemptCount;

  Map<String, Object?> toJson() => <String, Object?>{
        'deliveryId': deliveryId,
        'outcome': outcome.toJson(),
        'causationExecutionId': causationExecutionId,
        'rootCorrelationId': rootCorrelationId,
        'depth': depth,
        'attemptCount': attemptCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeOutcomeDelivery &&
          other.deliveryId == deliveryId &&
          other.outcome == outcome &&
          other.causationExecutionId == causationExecutionId &&
          other.rootCorrelationId == rootCorrelationId &&
          other.depth == depth &&
          other.attemptCount == attemptCount;

  @override
  int get hashCode => Object.hash(
        deliveryId,
        outcome,
        causationExecutionId,
        rootCorrelationId,
        depth,
        attemptCount,
      );
}

@immutable
final class NarrativeEventProgress {
  const NarrativeEventProgress.empty()
      : consumedNarrativeEventIds = const <String>{},
        pendingNarrativeOutcomeDeliveries = const <NarrativeOutcomeDelivery>[],
        deliveredNarrativeOutcomeDeliveryIds = const <String>{};

  factory NarrativeEventProgress({
    Iterable<String> consumedNarrativeEventIds = const <String>[],
    Iterable<NarrativeOutcomeDelivery> pendingNarrativeOutcomeDeliveries =
        const <NarrativeOutcomeDelivery>[],
    Iterable<String> deliveredNarrativeOutcomeDeliveryIds = const <String>[],
  }) {
    final consumed = _validatedUniqueIds(
      consumedNarrativeEventIds,
      'consumedNarrativeEventIds',
      narrativeEventIdPattern,
      'evt_<uuid-v7>',
    );
    final pending = pendingNarrativeOutcomeDeliveries.toList(growable: false);
    final pendingIds = <String>{};
    for (final delivery in pending) {
      if (!pendingIds.add(delivery.deliveryId)) {
        throw ArgumentError.value(
          pendingNarrativeOutcomeDeliveries,
          'pendingNarrativeOutcomeDeliveries',
          'must not contain duplicate delivery IDs',
        );
      }
    }
    final delivered = _validatedUniqueIds(
      deliveredNarrativeOutcomeDeliveryIds,
      'deliveredNarrativeOutcomeDeliveryIds',
      narrativeOutcomeDeliveryIdPattern,
      'outd_<uuid-v7>',
    );
    final overlap = pendingIds.intersection(delivered);
    if (overlap.isNotEmpty) {
      throw ArgumentError.value(
        overlap,
        'pendingNarrativeOutcomeDeliveries',
        'delivery IDs must not also be terminal',
      );
    }
    return NarrativeEventProgress._(
      Set.unmodifiable(consumed),
      List.unmodifiable(pending),
      Set.unmodifiable(delivered),
    );
  }

  const NarrativeEventProgress._(
    this.consumedNarrativeEventIds,
    this.pendingNarrativeOutcomeDeliveries,
    this.deliveredNarrativeOutcomeDeliveryIds,
  );

  factory NarrativeEventProgress.fromJson(Object? json) {
    final object = NarrativeEventWire.object(json, path: 'progress');
    NarrativeEventWire.expectExactFields(
      object,
      _progressFields,
      path: 'progress',
    );
    final consumedValues = NarrativeEventWire.requiredList(
      object,
      'consumedNarrativeEventIds',
      path: 'progress',
    );
    final pendingValues = NarrativeEventWire.requiredList(
      object,
      'pendingNarrativeOutcomeDeliveries',
      path: 'progress',
    );
    final deliveredValues = NarrativeEventWire.requiredList(
      object,
      'deliveredNarrativeOutcomeDeliveryIds',
      path: 'progress',
    );
    try {
      return NarrativeEventProgress(
        consumedNarrativeEventIds: [
          for (var index = 0; index < consumedValues.length; index++)
            _requireString(
              consumedValues[index],
              path: 'progress.consumedNarrativeEventIds[$index]',
            ),
        ],
        pendingNarrativeOutcomeDeliveries: [
          for (final value in pendingValues)
            NarrativeOutcomeDelivery.fromJson(value),
        ],
        deliveredNarrativeOutcomeDeliveryIds: [
          for (var index = 0; index < deliveredValues.length; index++)
            _requireString(
              deliveredValues[index],
              path: 'progress.deliveredNarrativeOutcomeDeliveryIds[$index]',
            ),
        ],
      );
    } on ArgumentError catch (error) {
      return NarrativeEventWire.invalid(
        error.message?.toString() ?? 'Invalid progress invariant.',
        path: 'progress',
        source: object,
      );
    }
  }

  final Set<String> consumedNarrativeEventIds;
  final List<NarrativeOutcomeDelivery> pendingNarrativeOutcomeDeliveries;
  final Set<String> deliveredNarrativeOutcomeDeliveryIds;

  Map<String, Object?> toJson() {
    final consumed = consumedNarrativeEventIds.toList()..sort();
    final delivered = deliveredNarrativeOutcomeDeliveryIds.toList()..sort();
    return <String, Object?>{
      'consumedNarrativeEventIds': consumed,
      'pendingNarrativeOutcomeDeliveries': [
        for (final delivery in pendingNarrativeOutcomeDeliveries)
          delivery.toJson(),
      ],
      'deliveredNarrativeOutcomeDeliveryIds': delivered,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventProgress &&
          _setEquals(
            other.consumedNarrativeEventIds,
            consumedNarrativeEventIds,
          ) &&
          _listEquals(
            other.pendingNarrativeOutcomeDeliveries,
            pendingNarrativeOutcomeDeliveries,
          ) &&
          _setEquals(
            other.deliveredNarrativeOutcomeDeliveryIds,
            deliveredNarrativeOutcomeDeliveryIds,
          );

  @override
  int get hashCode => Object.hash(
        Object.hashAll(consumedNarrativeEventIds.toList()..sort()),
        Object.hashAll(pendingNarrativeOutcomeDeliveries),
        Object.hashAll(deliveredNarrativeOutcomeDeliveryIds.toList()..sort()),
      );
}

Object? readNarrativeEventProgressJson(
  Map<dynamic, dynamic> json,
  String key,
) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) {
    throw FormatException('$key must not be null.');
  }
  return value;
}

Map<String, Object?> narrativeEventProgressToJson(
  NarrativeEventProgress progress,
) {
  return progress.toJson();
}

String _validatePattern(
  String value,
  String name,
  RegExp pattern,
  String expected,
) {
  if (!pattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'must match $expected');
  }
  return value;
}

int _validateNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be non-negative');
  }
  return value;
}

Set<String> _validatedUniqueIds(
  Iterable<String> values,
  String name,
  RegExp pattern,
  String expected,
) {
  final result = <String>{};
  for (final value in values) {
    _validatePattern(value, name, pattern, expected);
    if (!result.add(value)) {
      throw ArgumentError.value(values, name, 'must not contain duplicates');
    }
  }
  return result;
}

Object? _requiredNullableValue(
  Map<String, Object?> object,
  String field, {
  required String path,
}) {
  if (!object.containsKey(field)) {
    return NarrativeEventWire.invalid(
      'Required field "$field" is missing.',
      path: '$path.$field',
      source: object,
    );
  }
  return object[field];
}

String _requireString(Object? value, {required String path}) {
  if (value is! String) {
    return NarrativeEventWire.invalid(
      'Expected a string.',
      path: path,
      source: value,
    );
  }
  return value;
}

bool _setEquals<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
