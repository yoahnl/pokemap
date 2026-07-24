final class EvaluationEvent {
  EvaluationEvent({
    required String runId,
    required this.sequence,
    required String type,
    required Map<String, Object?> payload,
  })  : runId = _nonBlank(runId, 'runId'),
        type = _nonBlank(type, 'type'),
        payload = _freezeMap(payload) {
    if (sequence < 1) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'Event sequences start at 1.',
      );
    }
  }

  static const schemaVersion = 1;

  final String runId;
  final int sequence;
  final String type;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'runId': runId,
      'sequence': sequence,
      'type': type,
      'payload': payload,
    };
  }
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, item) => MapEntry<String, Object?>(key, _freezeValue(item)),
    ),
  );
}

Object? _freezeValue(Object? value) {
  return switch (value) {
    Map<String, Object?> map => _freezeMap(map),
    Map map => _freezeMap(Map<String, Object?>.from(map)),
    List list => List<Object?>.unmodifiable(list.map(_freezeValue)),
    double number when !number.isFinite => throw ArgumentError.value(
        value,
        'payload',
        'Event numbers must be finite.',
      ),
    null || bool() || num() || String() => value,
    _ => throw ArgumentError.value(
        value,
        'payload',
        'Event payloads must be JSON-compatible.',
      ),
  };
}
