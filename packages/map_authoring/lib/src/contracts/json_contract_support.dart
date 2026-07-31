/// Shared strict JSON helpers for public Authoring API contracts.
///
/// Unknown top-level fields are rejected. Forward-compatible vendor data must
/// live under `extensions`, where it is preserved but cannot shadow a reserved
/// contract key.
void rejectUnknownContractKeys(
  Map<String, dynamic> json,
  Set<String> allowedKeys,
) {
  final unknown = json.keys.where((key) => !allowedKeys.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw FormatException(
      'Unknown contract field(s): ${unknown.join(', ')}',
    );
  }
}

String requireContractString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-blank string');
  }
  return value.trim();
}

String? readOptionalContractString(Object? value, String field) {
  if (value == null) return null;
  return requireContractString(value, field);
}

int requirePositiveContractVersion(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

bool requireContractBool(Object? value, String field) {
  if (value is! bool) {
    throw FormatException('$field must be a boolean');
  }
  return value;
}

List<String> readContractStringList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be a list of strings');
  }
  return normalizedContractStrings(value, field);
}

List<String> normalizedContractStrings(
  Iterable<Object?> values,
  String field,
) {
  final normalized = values
      .map((value) => requireContractString(value, field))
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(normalized);
}

List<T> normalizedContractEnums<T>(
  Iterable<T> values,
  String Function(T value) wireName,
) {
  final normalized = values.toSet().toList()
    ..sort((left, right) => wireName(left).compareTo(wireName(right)));
  return List.unmodifiable(normalized);
}

Map<String, Object?> validateContractExtensions(
  Map<String, Object?> extensions, {
  required Set<String> reservedKeys,
}) {
  final collisions = extensions.keys
      .where((key) => reservedKeys.contains(key))
      .toList()
    ..sort();
  if (collisions.isNotEmpty) {
    throw ArgumentError.value(
      collisions,
      'extensions',
      'Extension keys collide with reserved contract fields',
    );
  }
  return freezeContractJsonObject(extensions, field: 'extensions');
}

Map<String, Object?> readContractExtensions(
  Object? value, {
  required Set<String> reservedKeys,
}) {
  if (value == null) return const {};
  if (value is! Map) {
    throw const FormatException('extensions must be a JSON object');
  }
  final object = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('extensions keys must be strings');
    }
    object[entry.key as String] = entry.value;
  }
  try {
    return validateContractExtensions(object, reservedKeys: reservedKeys);
  } on ArgumentError catch (error) {
    throw FormatException(error.message.toString());
  }
}

Map<String, Object?> freezeContractJsonObject(
  Map<String, Object?> value, {
  required String field,
}) {
  final sortedKeys = value.keys.toList()..sort();
  final frozen = <String, Object?>{};
  for (final key in sortedKeys) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, field, 'JSON keys must not be blank');
    }
    frozen[key] = _freezeJsonValue(value[key], '$field.$key');
  }
  return Map.unmodifiable(frozen);
}

Object? _freezeJsonValue(Object? value, String field) {
  if (value == null || value is String || value is bool || value is num) {
    if (value is double && !value.isFinite) {
      throw ArgumentError.value(value, field, 'must be finite JSON number');
    }
    return value;
  }
  if (value is List) {
    return List.unmodifiable([
      for (var index = 0; index < value.length; index++)
        _freezeJsonValue(value[index], '$field[$index]'),
    ]);
  }
  if (value is Map) {
    final object = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError.value(
          entry.key,
          field,
          'JSON object keys must be strings',
        );
      }
      object[entry.key as String] = entry.value;
    }
    return freezeContractJsonObject(object, field: field);
  }
  throw ArgumentError.value(
    value,
    field,
    'must contain only JSON-compatible values',
  );
}

Object? freezeContractJsonValue(Object? value, {required String field}) {
  return _freezeJsonValue(value, field);
}

void writeContractExtensions(
  Map<String, Object?> target,
  Map<String, Object?> extensions,
) {
  if (extensions.isNotEmpty) {
    target['extensions'] = extensions;
  }
}
