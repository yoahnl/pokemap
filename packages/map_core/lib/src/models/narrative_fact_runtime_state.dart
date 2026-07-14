import 'package:meta/meta.dart' show immutable;

@immutable
final class NarrativeFactRuntimeState {
  const NarrativeFactRuntimeState.empty()
      : overridesByFactId = const <String, bool>{};

  factory NarrativeFactRuntimeState({
    Map<String, bool> overridesByFactId = const <String, bool>{},
  }) {
    final entries = overridesByFactId.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final sorted = <String, bool>{};
    for (final entry in entries) {
      _validateFactId(entry.key);
      sorted[entry.key] = entry.value;
    }
    return NarrativeFactRuntimeState._(Map.unmodifiable(sorted));
  }

  const NarrativeFactRuntimeState._(this.overridesByFactId);

  factory NarrativeFactRuntimeState.fromJson(Map<String, dynamic> json) {
    if (json.length != 1 || !json.containsKey('overridesByFactId')) {
      throw const FormatException(
        'NarrativeFactRuntimeState must contain only overridesByFactId.',
      );
    }
    final rawOverrides = json['overridesByFactId'];
    if (rawOverrides is! Map) {
      throw const FormatException('overridesByFactId must be an object.');
    }
    final overrides = <String, bool>{};
    for (final entry in rawOverrides.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! bool) {
        throw const FormatException(
          'overridesByFactId must contain boolean values keyed by Fact ID.',
        );
      }
      overrides[key] = value;
    }
    try {
      return NarrativeFactRuntimeState(overridesByFactId: overrides);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid Fact ID.');
    }
  }

  final Map<String, bool> overridesByFactId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'overridesByFactId': <String, bool>{...overridesByFactId},
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NarrativeFactRuntimeState ||
        other.overridesByFactId.length != overridesByFactId.length) {
      return false;
    }
    for (final entry in overridesByFactId.entries) {
      if (!other.overridesByFactId.containsKey(entry.key) ||
          other.overridesByFactId[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        overridesByFactId.entries.map(
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
