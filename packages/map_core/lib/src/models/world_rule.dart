import 'package:meta/meta.dart' show immutable;

enum WorldRuleSourceKind {
  fact,
  storyStepCompletion,
  consumedEvent,
}

enum WorldRuleSourcePredicate {
  isTrue,
  isFalse,
  completed,
  notCompleted,
  consumed,
  notConsumed,
}

enum WorldRuleTargetKind {
  mapEntity,
  npcDialogue,
  mapEvent,
}

enum WorldRuleEffectKind {
  entityVisible,
  entityHidden,
  npcDialogueOverride,
  eventEnabled,
  eventDisabled,
  eventHidden,
}

@immutable
final class WorldRuleSource {
  const WorldRuleSource({
    required this.kind,
    required this.sourceId,
    required this.predicate,
    this.label,
    this.debugTechnicalLabel,
  });

  factory WorldRuleSource.fromJson(Map<String, dynamic> json) {
    return WorldRuleSource(
      kind: _readEnum(WorldRuleSourceKind.values, json['kind'], 'kind'),
      sourceId: _readOptionalString(json, 'sourceId') ?? '',
      predicate: _readEnum(
        WorldRuleSourcePredicate.values,
        json['predicate'],
        'predicate',
      ),
      label: _readOptionalString(json, 'label'),
      debugTechnicalLabel: _readOptionalString(json, 'debugTechnicalLabel'),
    );
  }

  final WorldRuleSourceKind kind;
  final String sourceId;
  final WorldRuleSourcePredicate predicate;
  final String? label;
  final String? debugTechnicalLabel;

  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': kind.name,
        'sourceId': sourceId,
        'predicate': predicate.name,
        'label': label,
        'debugTechnicalLabel': debugTechnicalLabel,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleSource &&
          other.kind == kind &&
          other.sourceId == sourceId &&
          other.predicate == predicate &&
          other.label == label &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode =>
      Object.hash(kind, sourceId, predicate, label, debugTechnicalLabel);
}

@immutable
final class WorldRuleTarget {
  const WorldRuleTarget({
    required this.kind,
    required this.mapId,
    this.entityId,
    this.eventId,
    this.label,
  });

  factory WorldRuleTarget.fromJson(Map<String, dynamic> json) {
    return WorldRuleTarget(
      kind: _readEnum(WorldRuleTargetKind.values, json['kind'], 'kind'),
      mapId: _readOptionalString(json, 'mapId') ?? '',
      entityId: _readOptionalString(json, 'entityId'),
      eventId: _readOptionalString(json, 'eventId'),
      label: _readOptionalString(json, 'label'),
    );
  }

  final WorldRuleTargetKind kind;
  final String mapId;
  final String? entityId;
  final String? eventId;
  final String? label;

  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': kind.name,
        'mapId': mapId,
        'entityId': entityId,
        'eventId': eventId,
        'label': label,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleTarget &&
          other.kind == kind &&
          other.mapId == mapId &&
          other.entityId == entityId &&
          other.eventId == eventId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, mapId, entityId, eventId, label);
}

@immutable
final class WorldRuleEffect {
  const WorldRuleEffect({
    required this.kind,
    this.dialogueId,
    this.label,
  });

  factory WorldRuleEffect.fromJson(Map<String, dynamic> json) {
    return WorldRuleEffect(
      kind: _readEnum(WorldRuleEffectKind.values, json['kind'], 'kind'),
      dialogueId: _readOptionalString(json, 'dialogueId'),
      label: _readOptionalString(json, 'label'),
    );
  }

  final WorldRuleEffectKind kind;
  final String? dialogueId;
  final String? label;

  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': kind.name,
        'dialogueId': dialogueId,
        'label': label,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleEffect &&
          other.kind == kind &&
          other.dialogueId == dialogueId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, dialogueId, label);
}

@immutable
final class WorldRuleDefinition {
  WorldRuleDefinition({
    required String id,
    required String label,
    String description = '',
    this.enabled = true,
    required this.source,
    required this.target,
    required this.effect,
    this.priority = 0,
    List<String> tags = const <String>[],
    String? debugTechnicalLabel,
  })  : id = _requireTrimmed(id, 'WorldRuleDefinition.id'),
        label = _requireTrimmed(label, 'WorldRuleDefinition.label'),
        description = description.trim(),
        tags = _stableTags(tags),
        debugTechnicalLabel = _trimOptional(debugTechnicalLabel);

  factory WorldRuleDefinition.fromJson(Map<String, dynamic> json) {
    return WorldRuleDefinition(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description') ?? '',
      enabled: _readBool(json, 'enabled', defaultValue: true),
      source: WorldRuleSource.fromJson(_readObject(json, 'source')),
      target: WorldRuleTarget.fromJson(_readObject(json, 'target')),
      effect: WorldRuleEffect.fromJson(_readObject(json, 'effect')),
      priority: _readInt(json, 'priority'),
      tags: _readStringList(json, 'tags'),
      debugTechnicalLabel: _readOptionalString(json, 'debugTechnicalLabel'),
    );
  }

  final String id;
  final String label;
  final String description;
  final bool enabled;
  final WorldRuleSource source;
  final WorldRuleTarget target;
  final WorldRuleEffect effect;
  final int priority;
  final List<String> tags;
  final String? debugTechnicalLabel;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'label': label,
        'description': description,
        'enabled': enabled,
        'source': source.toJson(),
        'target': target.toJson(),
        'effect': effect.toJson(),
        'priority': priority,
        'tags': tags,
        'debugTechnicalLabel': debugTechnicalLabel,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleDefinition &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.enabled == enabled &&
          other.source == source &&
          other.target == target &&
          other.effect == effect &&
          other.priority == priority &&
          _listEquals(other.tags, tags) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        description,
        enabled,
        source,
        target,
        effect,
        priority,
        Object.hashAll(tags),
        debugTechnicalLabel,
      );
}

bool isWorldRuleSourcePredicateCompatible(
  WorldRuleSourceKind kind,
  WorldRuleSourcePredicate predicate,
) {
  return switch (kind) {
    WorldRuleSourceKind.fact => predicate == WorldRuleSourcePredicate.isTrue ||
        predicate == WorldRuleSourcePredicate.isFalse,
    WorldRuleSourceKind.storyStepCompletion =>
      predicate == WorldRuleSourcePredicate.completed ||
          predicate == WorldRuleSourcePredicate.notCompleted,
    WorldRuleSourceKind.consumedEvent =>
      predicate == WorldRuleSourcePredicate.consumed ||
          predicate == WorldRuleSourcePredicate.notConsumed,
  };
}

bool isWorldRuleEffectCompatibleWithTarget(
  WorldRuleTargetKind targetKind,
  WorldRuleEffectKind effectKind,
) {
  return switch (targetKind) {
    WorldRuleTargetKind.mapEntity =>
      effectKind == WorldRuleEffectKind.entityVisible ||
          effectKind == WorldRuleEffectKind.entityHidden,
    WorldRuleTargetKind.npcDialogue =>
      effectKind == WorldRuleEffectKind.npcDialogueOverride,
    WorldRuleTargetKind.mapEvent =>
      effectKind == WorldRuleEffectKind.eventEnabled ||
          effectKind == WorldRuleEffectKind.eventDisabled ||
          effectKind == WorldRuleEffectKind.eventHidden,
  };
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return trimmed;
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, key, 'must be a non-empty string');
  }
  return value.trim();
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ArgumentError.value(value, key, 'must be a string');
  }
  return _trimOptional(value);
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  bool defaultValue = false,
}) {
  final value = json[key];
  if (value == null) {
    return defaultValue;
  }
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return 0;
  }
  if (value is! int) {
    throw ArgumentError.value(value, key, 'must be an integer');
  }
  return value;
}

T _readEnum<T extends Enum>(List<T> values, Object? value, String key) {
  if (value is! String || value.trim().isEmpty) {
    throw ArgumentError.value(value, key, 'must be a non-empty enum string');
  }
  final trimmed = value.trim();
  for (final enumValue in values) {
    if (enumValue.name == trimmed) {
      return enumValue;
    }
  }
  throw ArgumentError.value(value, key, 'unsupported enum value');
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw ArgumentError.value(value, key, 'must be a JSON object');
  }
  return value.map((key, value) {
    if (key is! String) {
      throw ArgumentError.value(key, 'JSON key', 'must be a string');
    }
    return MapEntry(key, value);
  });
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
