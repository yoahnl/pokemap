final class PartyCompanionVisual {
  const PartyCompanionVisual({
    required this.speciesId,
    required this.formId,
    required this.characterId,
  });

  final String speciesId;
  final String formId;
  final String characterId;

  factory PartyCompanionVisual.fromJson(Map<String, dynamic> json) {
    if (json.length != 3 ||
        json.keys.any(
          (key) => !const {'speciesId', 'formId', 'characterId'}.contains(key),
        )) {
      throw const FormatException(
        'A companion visual requires species, form and character identities.',
      );
    }
    String identity(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty || value.trim() != value) {
        throw FormatException(
          'Companion $key must be a nonempty canonical identity.',
        );
      }
      return value;
    }

    return PartyCompanionVisual(
      speciesId: identity('speciesId'),
      formId: identity('formId'),
      characterId: identity('characterId'),
    );
  }

  Map<String, Object?> toJson() => {
    'speciesId': speciesId,
    'formId': formId,
    'characterId': characterId,
  };

  @override
  bool operator ==(Object other) =>
      other is PartyCompanionVisual &&
      speciesId == other.speciesId &&
      formId == other.formId &&
      characterId == other.characterId;

  @override
  int get hashCode => Object.hash(speciesId, formId, characterId);
}

final class ProjectPartyCompanionConfig {
  const ProjectPartyCompanionConfig({
    this.enabled = false,
    this.mappings = const [],
  });

  final bool enabled;
  final List<PartyCompanionVisual> mappings;

  factory ProjectPartyCompanionConfig.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        json['enabled'] is! bool ||
        json['mappings'] is! List ||
        json.keys.any((key) => !const {'enabled', 'mappings'}.contains(key))) {
      throw const FormatException(
        'A companion configuration requires enabled and mappings.',
      );
    }
    final values = <PartyCompanionVisual>[];
    final identities = <(String, String)>{};
    for (final raw in json['mappings'] as List) {
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw const FormatException('A companion visual must be an object.');
      }
      final value = PartyCompanionVisual.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (!identities.add((value.speciesId, value.formId))) {
        throw const FormatException(
          'A companion species/form may only have one visual.',
        );
      }
      values.add(value);
    }
    return ProjectPartyCompanionConfig(
      enabled: json['enabled'] as bool,
      mappings: List.unmodifiable(values),
    );
  }

  PartyCompanionVisual? resolve(String speciesId, String formId) {
    for (final mapping in mappings) {
      if (mapping.speciesId == speciesId && mapping.formId == formId)
        return mapping;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'mappings': [for (final value in mappings) value.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectPartyCompanionConfig &&
      enabled == other.enabled &&
      mappings.length == other.mappings.length &&
      List.generate(
        mappings.length,
        (index) => mappings[index] == other.mappings[index],
      ).every((value) => value);

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(mappings));
}
