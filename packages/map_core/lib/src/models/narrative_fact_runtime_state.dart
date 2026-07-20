import 'package:meta/meta.dart' show immutable;

import 'narrative_value.dart';

@immutable
final class NarrativeFactRuntimeState {
  const NarrativeFactRuntimeState.empty()
      : valuesByFactId = const <String, NarrativeValue>{};

  factory NarrativeFactRuntimeState({
    Map<String, bool> overridesByFactId = const <String, bool>{},
  }) =>
      NarrativeFactRuntimeState.typed(
        valuesByFactId: {
          for (final entry in overridesByFactId.entries)
            entry.key: NarrativeValue.boolean(entry.value),
        },
      );

  factory NarrativeFactRuntimeState.typed({
    Map<String, NarrativeValue> valuesByFactId =
        const <String, NarrativeValue>{},
  }) {
    final entries = valuesByFactId.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final sorted = <String, NarrativeValue>{};
    for (final entry in entries) {
      _validateFactId(entry.key);
      sorted[entry.key] = entry.value;
    }
    return NarrativeFactRuntimeState._(Map.unmodifiable(sorted));
  }

  const NarrativeFactRuntimeState._(this.valuesByFactId);

  factory NarrativeFactRuntimeState.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final isV2 = schemaVersion == 2;
    final allowedKeys = isV2
        ? const {'schemaVersion', 'valuesByFactId'}
        : const {'overridesByFactId'};
    final keys = json.keys.toSet();
    if (keys.length != allowedKeys.length ||
        keys.difference(allowedKeys).isNotEmpty ||
        !keys.containsAll(allowedKeys)) {
      throw FormatException(
        'NarrativeFactRuntimeState schema does not match '
        '${isV2 ? 'V2' : 'V1'}.',
      );
    }
    final rawOverrides = json[isV2 ? 'valuesByFactId' : 'overridesByFactId'];
    if (rawOverrides is! Map) {
      throw const FormatException('overridesByFactId must be an object.');
    }
    final overrides = <String, NarrativeValue>{};
    for (final entry in rawOverrides.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) {
        throw const FormatException('Fact runtime keys must be strings.');
      }
      final NarrativeValue parsed;
      try {
        parsed = NarrativeValue.fromJson(value);
      } on ArgumentError catch (error) {
        throw FormatException(
          error.message?.toString() ?? 'Invalid Fact runtime value.',
        );
      }
      if (!isV2 && parsed.kind != NarrativeValueKind.boolean) {
        throw const FormatException(
          'V1 overridesByFactId must contain boolean values.',
        );
      }
      overrides[key] = parsed;
    }
    try {
      return NarrativeFactRuntimeState.typed(valuesByFactId: overrides);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid Fact ID.');
    }
  }

  final Map<String, NarrativeValue> valuesByFactId;

  Map<String, bool> get overridesByFactId => Map.unmodifiable({
        for (final entry in valuesByFactId.entries)
          if (entry.value.kind == NarrativeValueKind.boolean)
            entry.key: entry.value.boolValue,
      });

  NarrativeValue? valueFor(String factId) => valuesByFactId[factId];

  bool hasOverride(String factId) => valuesByFactId.containsKey(factId);

  Map<String, dynamic> toJson() {
    final containsTypedValue = valuesByFactId.values
        .any((value) => value.kind != NarrativeValueKind.boolean);
    if (!containsTypedValue) {
      return <String, dynamic>{
        'overridesByFactId': <String, bool>{...overridesByFactId},
      };
    }
    return <String, dynamic>{
      'schemaVersion': 2,
      'valuesByFactId': {
        for (final entry in valuesByFactId.entries)
          entry.key: entry.value.toJson(),
      },
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NarrativeFactRuntimeState ||
        other.valuesByFactId.length != valuesByFactId.length) {
      return false;
    }
    for (final entry in valuesByFactId.entries) {
      if (!other.valuesByFactId.containsKey(entry.key) ||
          other.valuesByFactId[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        valuesByFactId.entries.map(
          (entry) => Object.hash(entry.key, entry.value),
        ),
      );
}

Object? readNarrativeFactRuntimeStateJson(
  Map<dynamic, dynamic> json,
  String key,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value == null) {
    throw FormatException('$key must not be null.');
  }
  return value;
}

void _validateFactId(String factId) {
  if (factId.isEmpty || factId.trim() != factId) {
    throw ArgumentError.value(
      factId,
      'factId',
      'must be non-empty and trim-exact',
    );
  }
}
