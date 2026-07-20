import 'package:meta/meta.dart' show immutable;

import 'narrative_value.dart';

@immutable
final class NarrativeFactDefinition {
  NarrativeFactDefinition({
    required String id,
    required String label,
    String description = '',
    String category = '',
    bool defaultValue = false,
    NarrativeValue? initialValue,
    List<String> tags = const <String>[],
    String? legacyFlagName,
  })  : id = _requireTrimmed(id, 'NarrativeFactDefinition.id'),
        label = _requireTrimmed(label, 'NarrativeFactDefinition.label'),
        description = description.trim(),
        category = category.trim(),
        initialValue = initialValue ?? NarrativeValue.boolean(defaultValue),
        tags = _stableTags(tags),
        legacyFlagName = _trimOptional(legacyFlagName) {
    if (this.initialValue.kind != NarrativeValueKind.boolean &&
        this.legacyFlagName != null) {
      throw ArgumentError.value(
        legacyFlagName,
        'legacyFlagName',
        'is only compatible with bool Facts',
      );
    }
  }

  factory NarrativeFactDefinition.fromJson(Map<String, dynamic> json) {
    return NarrativeFactDefinition(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description') ?? '',
      category: _readOptionalString(json, 'category') ?? '',
      initialValue: _readNarrativeDefaultValue(json),
      tags: _readStringList(json, 'tags'),
      legacyFlagName: _readOptionalString(json, 'legacyFlagName'),
    );
  }

  final String id;
  final String label;
  final String description;
  final String category;
  final NarrativeValue initialValue;

  NarrativeValueKind get valueKind => initialValue.kind;

  /// Compatibility view for historical bool-only callers.
  bool get defaultValue => initialValue.boolValue;
  final List<String> tags;
  final String? legacyFlagName;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'label': label,
        'description': description,
        'category': category,
        if (valueKind != NarrativeValueKind.boolean)
          'valueType': valueKind.wireName,
        'defaultValue': initialValue.toJson(),
        'tags': tags,
        'legacyFlagName': legacyFlagName,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeFactDefinition &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.category == category &&
          other.initialValue == initialValue &&
          _listEquals(other.tags, tags) &&
          other.legacyFlagName == legacyFlagName;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        description,
        category,
        initialValue,
        Object.hashAll(tags),
        legacyFlagName,
      );
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return trimmed;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

List<String> _stableTags(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    result.add(trimmed);
  }
  return List<String>.unmodifiable(result);
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, key, 'must be a non-empty string');
  }
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ArgumentError.value(value, key, 'must be a string');
  }
  return value;
}

NarrativeValue _readNarrativeDefaultValue(Map<String, dynamic> json) {
  final rawKind = json['valueType'];
  if (rawKind != null && rawKind is! String) {
    throw ArgumentError.value(rawKind, 'valueType', 'must be a string');
  }
  final kind = rawKind == null
      ? NarrativeValueKind.boolean
      : NarrativeValueKind.fromWireName(rawKind as String);
  final value = json.containsKey('defaultValue')
      ? json['defaultValue']
      : kind == NarrativeValueKind.boolean
          ? false
          : throw ArgumentError.value(
              null,
              'defaultValue',
              'is required for typed Facts',
            );
  try {
    return NarrativeValue.fromJson(value, declaredKind: kind);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'defaultValue', error.message);
  }
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const <String>[];
  }
  if (value is! List) {
    throw ArgumentError.value(value, key, 'must be a list');
  }
  return [
    for (final item in value)
      if (item is String) item else throw ArgumentError.value(item, key),
  ];
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
