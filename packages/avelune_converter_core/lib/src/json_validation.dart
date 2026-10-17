part of '../avelune_converter_core.dart';

Object? _freezeJson(Object? input, ContractLimits limits,
    {bool canonicalObjectKeys = false}) {
  if (limits.maxDepth < 1 ||
      limits.maxNodes < 1 ||
      limits.maxStringCodeUnits < 1 ||
      limits.maxTextCodeUnits < 1) {
    throw ArgumentError('Validation limits must be positive');
  }
  var nodes = 0;
  var textCodeUnits = 0;
  final active = HashSet<Object>.identity();
  void countText(String value, String path) {
    textCodeUnits += value.length;
    if (value.length > limits.maxStringCodeUnits ||
        textCodeUnits > limits.maxTextCodeUnits) {
      throw ContractError('json.textQuota', path, 'JSON text budget exceeded');
    }
  }

  Object? visit(Object? value, String path, int depth) {
    if (++nodes > limits.maxNodes || depth > limits.maxDepth) {
      throw ContractError(
          'json.quota', path, 'JSON validation budget exceeded');
    }
    if (value is String) {
      countText(value, path);
      return value;
    }
    if (value == null || value is bool || value is int) {
      return value;
    }
    if (value is double) {
      if (!value.isFinite) {
        throw ContractError('json.number', path, 'Non-finite number');
      }
      return value == value.truncateToDouble() &&
              value.abs() <= 9007199254740991
          ? value.toInt()
          : value;
    }
    if (value is! Map && value is! List) {
      throw ContractError(
          'json.inert', path, 'Only inert JSON values are permitted');
    }
    if (!active.add(value)) {
      throw ContractError('json.cycle', path, 'Cyclic JSON graph');
    }
    try {
      if (value is List) {
        return List<Object?>.unmodifiable([
          for (var i = 0; i < value.length; i++)
            visit(value[i], '$path[$i]', depth + 1),
        ]);
      }
      final map = value as Map;
      if (map.keys.any((key) => key is! String)) {
        throw ContractError('json.key', path, 'JSON keys must be strings');
      }
      final copy = <String, Object?>{};
      for (final key in map.keys.cast<String>()) {
        countText(key, path);
        copy[key] = visit(map[key], '$path.$key', depth + 1);
      }
      if (canonicalObjectKeys) {
        final keys = copy.keys.toList()..sort();
        return Map<String, Object?>.unmodifiable(
            {for (final key in keys) key: copy[key]});
      }
      return Map<String, Object?>.unmodifiable(copy);
    } finally {
      active.remove(value);
    }
  }

  return visit(input, r'$', 0);
}

void _validateShape(Object? value, Map<String, Object?> schema, String path) {
  Never fail(String code, String message) =>
      throw ContractError('shape.$code', path, message);
  if (schema.containsKey('const') && value != schema['const']) {
    fail('const', 'Unexpected constant');
  }
  if (schema['enum'] case final List allowed) {
    if (!allowed.contains(value)) {
      fail('enum', 'Unknown enum value');
    }
  }
  if (schema['anyOf'] case final List alternatives) {
    var matched = false;
    for (final option in alternatives) {
      try {
        _validateShape(value, (option as Map).cast<String, Object?>(), path);
        matched = true;
        break;
      } on ContractError {
        matched = false;
      }
    }
    if (!matched) {
      fail('union', 'Value matches no allowed type');
    }
  }
  final type = schema['type'];
  final matches = switch (type) {
    null => true,
    'object' => value is Map<String, Object?>,
    'array' => value is List,
    'string' => value is String,
    'boolean' => value is bool,
    'integer' =>
      value is num && value.isFinite && value == value.truncateToDouble(),
    'number' => value is num && value.isFinite,
    'null' => value == null,
    _ => throw StateError('Unknown internal schema type'),
  };
  if (!matches) {
    fail('type', 'Expected $type');
  }
  if (value is num) {
    if (schema['minimum'] case final num min) {
      if (value < min) {
        fail('minimum', 'Number below minimum');
      }
    }
    if (schema['maximum'] case final num max) {
      if (value > max) {
        fail('maximum', 'Number above maximum');
      }
    }
  }
  if (value is String) {
    if (schema['maxLength'] case final int max) {
      if (value.runes.length > max) {
        fail('maxLength', 'String exceeds maximum length');
      }
    }
    if (schema['pattern'] case final String pattern) {
      if (!RegExp(pattern).hasMatch(value)) {
        fail('pattern', 'String does not match pattern');
      }
    }
  }
  if (value is List) {
    if (schema['minItems'] case final int min) {
      if (value.length < min) {
        fail('minItems', 'Too few items');
      }
    }
    if (schema['maxItems'] case final int max) {
      if (value.length > max) {
        fail('maxItems', 'Too many items');
      }
    }
    if (schema['items'] case final Map item) {
      for (var i = 0; i < value.length; i++) {
        _validateShape(value[i], item.cast<String, Object?>(), '$path[$i]');
      }
    }
  }
  if (value is Map<String, Object?>) {
    final properties =
        (schema['properties'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{};
    for (final key
        in (schema['required'] as List? ?? const <Object?>[]).cast<String>()) {
      if (!value.containsKey(key)) {
        throw ContractError('shape.required', '$path.$key', 'Missing property');
      }
    }
    if (schema['additionalProperties'] == false) {
      for (final key in value.keys) {
        if (!properties.containsKey(key)) {
          throw ContractError(
              'shape.unknown', '$path.$key', 'Unknown property');
        }
      }
    }
    for (final key in value.keys) {
      if (properties[key] case final Map child) {
        _validateShape(value[key], child.cast<String, Object?>(), '$path.$key');
      }
    }
  }
  for (final condition in schema['allOf'] as List? ?? const <Object?>[]) {
    final branch = (condition as Map).cast<String, Object?>();
    if (branch['if'] case final Map predicate) {
      var applies = true;
      try {
        _validateShape(value, predicate.cast<String, Object?>(), path);
      } on ContractError {
        applies = false;
      }
      if (applies && branch['then'] is Map) {
        _validateShape(
            value, (branch['then'] as Map).cast<String, Object?>(), path);
      }
    } else {
      _validateShape(value, branch, path);
    }
  }
}

Object? immutableCanonicalJsonOf(Object? input,
        {ContractLimits limits = const ContractLimits()}) =>
    _freezeJson(input, limits, canonicalObjectKeys: true);

String canonicalJsonOf(Object? input,
    {ContractLimits limits = const ContractLimits()}) {
  Object? sort(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return {for (final key in keys) key: sort(value[key])};
    }
    if (value is List) {
      return [for (final item in value) sort(item)];
    }
    return value;
  }

  return jsonEncode(sort(_freezeJson(input, limits)));
}

Sha256Hash canonicalHashOf(Object? input,
        {ContractLimits limits = const ContractLimits()}) =>
    Sha256Hash(sha256
        .convert(
          utf8.encode(canonicalJsonOf(input, limits: limits)),
        )
        .toString());
