import 'package:meta/meta.dart' show immutable;

enum SceneConsequenceKind {
  setFact,
  markEventConsumed,
}

@immutable
abstract base class SceneConsequence {
  const SceneConsequence();

  factory SceneConsequence.setFact({
    required String factId,
    required bool value,
    String? label,
    String? notes,
  }) = SceneSetFactConsequence;

  factory SceneConsequence.markEventConsumed({
    required String mapId,
    required String eventId,
    String? label,
    String? notes,
  }) = SceneMarkEventConsumedConsequence;

  factory SceneConsequence.fromJson(Map<String, dynamic> json) {
    final kind = _readKind(json['kind']);
    return switch (kind) {
      SceneConsequenceKind.setFact => SceneSetFactConsequence.fromJson(json),
      SceneConsequenceKind.markEventConsumed =>
        SceneMarkEventConsumedConsequence.fromJson(json),
    };
  }

  SceneConsequenceKind get kind;

  Map<String, dynamic> toJson();
}

@immutable
final class SceneSetFactConsequence extends SceneConsequence {
  SceneSetFactConsequence({
    required String factId,
    required this.value,
    String? label,
    String? notes,
  })  : factId = factId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneSetFactConsequence.fromJson(Map<String, dynamic> json) {
    return SceneSetFactConsequence(
      factId: _readRequiredString(json, 'factId'),
      value: _readRequiredBool(json, 'value'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.setFact;

  final String factId;
  final bool value;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'factId': factId,
        'value': value,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSetFactConsequence &&
          other.factId == factId &&
          other.value == value &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(factId, value, label, notes);
}

@immutable
final class SceneMarkEventConsumedConsequence extends SceneConsequence {
  SceneMarkEventConsumedConsequence({
    required String mapId,
    required String eventId,
    String? label,
    String? notes,
  })  : mapId = mapId.trim(),
        eventId = eventId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneMarkEventConsumedConsequence.fromJson(
    Map<String, dynamic> json,
  ) {
    return SceneMarkEventConsumedConsequence(
      mapId: _readRequiredString(json, 'mapId'),
      eventId: _readRequiredString(json, 'eventId'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.markEventConsumed;

  final String mapId;
  final String eventId;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'mapId': mapId,
        'eventId': eventId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneMarkEventConsumedConsequence &&
          other.mapId == mapId &&
          other.eventId == eventId &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(mapId, eventId, label, notes);
}

SceneConsequenceKind _readKind(Object? value) {
  if (value is! String) {
    throw FormatException(
      'SceneConsequence.kind must be one of: '
      '${SceneConsequenceKind.values.map(_kindToJson).join(', ')}.',
    );
  }
  for (final kind in SceneConsequenceKind.values) {
    if (_kindToJson(kind) == value) {
      return kind;
    }
  }
  throw FormatException('Unknown SceneConsequence.kind: $value.');
}

String _kindToJson(SceneConsequenceKind kind) {
  return switch (kind) {
    SceneConsequenceKind.setFact => 'setFact',
    SceneConsequenceKind.markEventConsumed => 'markEventConsumed',
  };
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('SceneConsequence.$key must be a string.');
  }
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('SceneConsequence.$key must be a string.');
  }
  return value;
}

bool _readRequiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('SceneConsequence.$key must be a boolean.');
  }
  return value;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}
