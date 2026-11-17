part of 'dialogue_localization.dart';

DialogueLocalization _decodeLocalization(Map<String, dynamic> json) {
  try {
    _fields(json, {'format', 'sourceLocale', 'units'});
    if (json['format'] is! int ||
        json['format'] != 1 ||
        json['units'] is! List) {
      throw const FormatException('Unsupported dialogue localization format.');
    }
    return DialogueLocalization(
      sourceLocale: _string(json['sourceLocale']),
      units: [
        for (final value in json['units'] as List) _decodeUnit(_object(value)),
      ],
    );
  } on ArgumentError catch (error) {
    throw FormatException(error.message.toString());
  }
}

DialogueTextUnit _decodeUnit(Map<String, dynamic> json) {
  _fields(json, {'id', 'binding', 'kind', 'source', 'translations'});
  final kind = DialogueTextKind.values
      .where((kind) => kind.name == json['kind'])
      .firstOrNull;
  if (kind == null) throw const FormatException('Unknown dialogue text kind.');
  return DialogueTextUnit(
    id: _string(json['id']),
    binding: _string(json['binding']),
    kind: kind,
    source: _string(json['source']),
    translations: {
      for (final entry in _object(json['translations']).entries)
        entry.key: _decodeTranslation(_object(entry.value)),
    },
  );
}

DialogueTranslation _decodeTranslation(Map<String, dynamic> json) {
  _fields(json, {'text', 'source'});
  return DialogueTranslation(
    text: _string(json['text']),
    source: _string(json['source']),
  );
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected a dialogue localization object.');
  }
  return Map<String, dynamic>.from(value);
}

void _fields(Map<String, dynamic> json, Set<String> expected) {
  if (json.length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw const FormatException('Invalid dialogue localization fields.');
  }
}

String _string(Object? value) {
  if (value is! String) throw const FormatException('Expected dialogue text.');
  return value;
}

String _identifier(String value) {
  if (value != value.trim()) {
    throw ArgumentError('Invalid dialogue text identity.');
  }
  return _text(value);
}

String _text(String value) {
  if (value.trim().isEmpty || value.contains('\u0000')) {
    throw ArgumentError('Dialogue text must be nonempty and contain no NUL.');
  }
  return value;
}

String _locale(String value) {
  return normalizeProjectLocale(value);
}
