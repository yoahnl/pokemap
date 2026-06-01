import 'package:meta/meta.dart' show immutable;

enum CinematicTimelineStepKind {
  wait,
  camera,
  actorMove,
  actorFace,
  actorEmote,
  dialogueLine,
  sound,
  music,
  fade,
  shake,
  fx,
  marker,
}

enum CinematicLegacyBridgeSourceKind {
  scenarioAsset,
  cutsceneStudio,
  unknown,
}

@immutable
final class CinematicAsset {
  CinematicAsset({
    required String id,
    required String title,
    String? description,
    String? storylineId,
    String? chapterId,
    String? mapId,
    List<String> tags = const <String>[],
    List<CinematicActorRef> requiredActors = const <CinematicActorRef>[],
    List<CinematicMovementTargetRef> movementTargets =
        const <CinematicMovementTargetRef>[],
    required this.timeline,
    String? notes,
    Map<String, String> metadata = const <String, String>{},
    this.legacyBridge,
  })  : id = _requireTrimmed(id, 'CinematicAsset.id'),
        title = _requireTrimmed(title, 'CinematicAsset.title'),
        description = _trimOptional(description),
        storylineId = _trimOptional(storylineId),
        chapterId = _trimOptional(chapterId),
        mapId = _trimOptional(mapId),
        tags = _stableStringList(tags),
        requiredActors = List<CinematicActorRef>.unmodifiable(requiredActors),
        movementTargets =
            List<CinematicMovementTargetRef>.unmodifiable(movementTargets),
        notes = _trimOptional(notes),
        metadata = Map<String, String>.unmodifiable(metadata);

  factory CinematicAsset.fromJson(Map<String, dynamic> json) {
    return CinematicAsset(
      id: _readRequiredString(json, 'id'),
      title: _readRequiredString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      storylineId: _readOptionalString(json, 'storylineId'),
      chapterId: _readOptionalString(json, 'chapterId'),
      mapId: _readOptionalString(json, 'mapId'),
      tags: _readStringList(json, 'tags'),
      requiredActors: _readObjectList(
        json,
        'requiredActors',
        CinematicActorRef.fromJson,
      ),
      movementTargets: _readObjectList(
        json,
        'movementTargets',
        CinematicMovementTargetRef.fromJson,
      ),
      timeline: _readOptionalObject(
            json,
            'timeline',
            CinematicTimeline.fromJson,
          ) ??
          CinematicTimeline(),
      notes: _readOptionalString(json, 'notes'),
      metadata: _readStringMap(json, 'metadata'),
      legacyBridge: _readOptionalObject(
        json,
        'legacyBridge',
        CinematicLegacyBridge.fromJson,
      ),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? storylineId;
  final String? chapterId;
  final String? mapId;
  final List<String> tags;
  final List<CinematicActorRef> requiredActors;
  final List<CinematicMovementTargetRef> movementTargets;
  final CinematicTimeline timeline;
  final String? notes;
  final Map<String, String> metadata;

  /// Optional legacy metadata. It documents provenance only; runtime V1 must
  /// not execute a ScenarioAsset through this bridge.
  final CinematicLegacyBridge? legacyBridge;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'title': title,
        'description': description,
        'storylineId': storylineId,
        'chapterId': chapterId,
        'mapId': mapId,
        'tags': tags,
        'requiredActors':
            requiredActors.map((actor) => actor.toJson()).toList(),
        'movementTargets':
            movementTargets.map((target) => target.toJson()).toList(),
        'timeline': timeline.toJson(),
        'notes': notes,
        'metadata': metadata,
        'legacyBridge': legacyBridge?.toJson(),
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicAsset &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.storylineId == storylineId &&
          other.chapterId == chapterId &&
          other.mapId == mapId &&
          _listEquals(other.tags, tags) &&
          _listEquals(other.requiredActors, requiredActors) &&
          _listEquals(other.movementTargets, movementTargets) &&
          other.timeline == timeline &&
          other.notes == notes &&
          _mapEquals(other.metadata, metadata) &&
          other.legacyBridge == legacyBridge;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        storylineId,
        chapterId,
        mapId,
        Object.hashAll(tags),
        Object.hashAll(requiredActors),
        Object.hashAll(movementTargets),
        timeline,
        notes,
        _mapHash(metadata),
        legacyBridge,
      );
}

@immutable
final class CinematicTimeline {
  CinematicTimeline({
    List<CinematicTimelineStep> steps = const <CinematicTimelineStep>[],
  }) : steps = List<CinematicTimelineStep>.unmodifiable(steps);

  factory CinematicTimeline.fromJson(Map<String, dynamic> json) {
    return CinematicTimeline(
      steps: _readObjectList(
        json,
        'steps',
        CinematicTimelineStep.fromJson,
      ),
    );
  }

  final List<CinematicTimelineStep> steps;

  Map<String, dynamic> toJson() => {
        'steps': steps.map((step) => step.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicTimeline && _listEquals(other.steps, steps);

  @override
  int get hashCode => Object.hashAll(steps);
}

@immutable
final class CinematicTimelineStep {
  CinematicTimelineStep({
    required String id,
    required this.kind,
    String? label,
    this.durationMs,
    String? actorId,
    String? targetId,
    String? dialogueText,
    String? assetRef,
    Map<String, String> metadata = const <String, String>{},
  })  : id = _requireTrimmed(id, 'CinematicTimelineStep.id'),
        label = _trimOptional(label),
        actorId = _trimOptional(actorId),
        targetId = _trimOptional(targetId),
        dialogueText = _trimOptional(dialogueText),
        assetRef = _trimOptional(assetRef),
        metadata = Map<String, String>.unmodifiable(metadata);

  factory CinematicTimelineStep.fromJson(Map<String, dynamic> json) {
    return CinematicTimelineStep(
      id: _readRequiredString(json, 'id'),
      kind: _readEnum(
        CinematicTimelineStepKind.values,
        json['kind'],
        'kind',
      ),
      label: _readOptionalString(json, 'label'),
      durationMs: _readOptionalInt(json, 'durationMs'),
      actorId: _readOptionalString(json, 'actorId'),
      targetId: _readOptionalString(json, 'targetId'),
      dialogueText: _readOptionalString(json, 'dialogueText'),
      assetRef: _readOptionalString(json, 'assetRef'),
      metadata: _readStringMap(json, 'metadata'),
    );
  }

  final String id;
  final CinematicTimelineStepKind kind;
  final String? label;
  final int? durationMs;
  final String? actorId;
  final String? targetId;
  final String? dialogueText;
  final String? assetRef;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'kind': kind.name,
        'label': label,
        'durationMs': durationMs,
        'actorId': actorId,
        'targetId': targetId,
        'dialogueText': dialogueText,
        'assetRef': assetRef,
        'metadata': metadata,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicTimelineStep &&
          other.id == id &&
          other.kind == kind &&
          other.label == label &&
          other.durationMs == durationMs &&
          other.actorId == actorId &&
          other.targetId == targetId &&
          other.dialogueText == dialogueText &&
          other.assetRef == assetRef &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        label,
        durationMs,
        actorId,
        targetId,
        dialogueText,
        assetRef,
        _mapHash(metadata),
      );
}

@immutable
final class CinematicActorRef {
  CinematicActorRef({
    required String actorId,
    String? label,
    String? entityId,
    String? role,
  })  : actorId = _requireTrimmed(actorId, 'CinematicActorRef.actorId'),
        label = _trimOptional(label),
        entityId = _trimOptional(entityId),
        role = _trimOptional(role);

  factory CinematicActorRef.fromJson(Map<String, dynamic> json) {
    return CinematicActorRef(
      actorId: _readRequiredString(json, 'actorId'),
      label: _readOptionalString(json, 'label'),
      entityId: _readOptionalString(json, 'entityId'),
      role: _readOptionalString(json, 'role'),
    );
  }

  final String actorId;
  final String? label;
  final String? entityId;
  final String? role;

  Map<String, dynamic> toJson() => _withoutNulls({
        'actorId': actorId,
        'label': label,
        'entityId': entityId,
        'role': role,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorRef &&
          other.actorId == actorId &&
          other.label == label &&
          other.entityId == entityId &&
          other.role == role;

  @override
  int get hashCode => Object.hash(actorId, label, entityId, role);
}

@immutable
final class CinematicMovementTargetRef {
  CinematicMovementTargetRef({
    required String targetId,
    required String label,
    String? description,
  })  : targetId = _requireTrimmed(
          targetId,
          'CinematicMovementTargetRef.targetId',
        ),
        label = _requireTrimmed(
          label,
          'CinematicMovementTargetRef.label',
        ),
        description = _trimOptional(description);

  factory CinematicMovementTargetRef.fromJson(Map<String, dynamic> json) {
    return CinematicMovementTargetRef(
      targetId: _readRequiredString(json, 'targetId'),
      label: _readRequiredString(json, 'label'),
      description: _readOptionalString(json, 'description'),
    );
  }

  final String targetId;
  final String label;
  final String? description;

  Map<String, dynamic> toJson() => _withoutNulls({
        'targetId': targetId,
        'label': label,
        'description': description,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicMovementTargetRef &&
          other.targetId == targetId &&
          other.label == label &&
          other.description == description;

  @override
  int get hashCode => Object.hash(targetId, label, description);
}

@immutable
final class CinematicLegacyBridge {
  CinematicLegacyBridge({
    required this.sourceKind,
    String? scenarioId,
    String? cutsceneSchema,
    String? notes,
  })  : scenarioId = _trimOptional(scenarioId),
        cutsceneSchema = _trimOptional(cutsceneSchema),
        notes = _trimOptional(notes);

  factory CinematicLegacyBridge.fromJson(Map<String, dynamic> json) {
    return CinematicLegacyBridge(
      sourceKind: _readEnum(
        CinematicLegacyBridgeSourceKind.values,
        json['sourceKind'],
        'sourceKind',
      ),
      scenarioId: _readOptionalString(json, 'scenarioId'),
      cutsceneSchema: _readOptionalString(json, 'cutsceneSchema'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  final CinematicLegacyBridgeSourceKind sourceKind;
  final String? scenarioId;
  final String? cutsceneSchema;
  final String? notes;

  Map<String, dynamic> toJson() => _withoutNulls({
        'sourceKind': sourceKind.name,
        'scenarioId': scenarioId,
        'cutsceneSchema': cutsceneSchema,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicLegacyBridge &&
          other.sourceKind == sourceKind &&
          other.scenarioId == scenarioId &&
          other.cutsceneSchema == cutsceneSchema &&
          other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(sourceKind, scenarioId, cutsceneSchema, notes);
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

int? _readOptionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw ArgumentError.value(value, key, 'must be an int');
  }
  return value;
}

T? _readOptionalObject<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) parse,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw ArgumentError.value(value, key, 'must be an object');
  }
  return parse(_stringKeyedMap(value, key));
}

List<T> _readObjectList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) parse,
) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw ArgumentError.value(value, key, 'must be a list');
  }
  return List<T>.unmodifiable([
    for (final item in value)
      if (item is Map)
        parse(_stringKeyedMap(item, key))
      else
        throw ArgumentError.value(item, key, 'must contain objects'),
  ]);
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw ArgumentError.value(value, key, 'must be a list');
  }
  return _stableStringList([
    for (final item in value)
      if (item is String)
        item
      else
        throw ArgumentError.value(item, key, 'must contain strings'),
  ]);
}

Map<String, String> _readStringMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return const {};
  }
  if (value is! Map) {
    throw ArgumentError.value(value, key, 'must be an object');
  }
  return Map<String, String>.unmodifiable(value.map((rawKey, rawValue) {
    if (rawKey is! String || rawValue is! String) {
      throw ArgumentError.value(value, key, 'must map strings to strings');
    }
    return MapEntry(rawKey, rawValue);
  }));
}

T _readEnum<T extends Enum>(List<T> values, Object? value, String key) {
  if (value is! String) {
    throw ArgumentError.value(value, key, 'must be a string enum value');
  }
  for (final candidate in values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  throw ArgumentError.value(value, key, 'is not supported');
}

Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> value, String key) {
  return value.map((rawKey, rawValue) {
    if (rawKey is! String) {
      throw ArgumentError.value(value, key, 'object keys must be strings');
    }
    return MapEntry(rawKey, rawValue);
  });
}

List<String> _stableStringList(List<String> values) {
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

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) {
  return Object.hashAll(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
