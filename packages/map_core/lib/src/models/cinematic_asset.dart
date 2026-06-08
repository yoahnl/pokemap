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

enum CinematicStageBackdropMode {
  none,
  projectMap,
}

enum CinematicActorBindingKind {
  player,
  mapEntity,
  cinematicOnly,
  unbound,
}

enum CinematicActorInitialPlacementKind {
  unset,
  fromMapEntity,
  fromMovementTarget,
}

enum CinematicMovementTargetBindingKind {
  abstractPoint,
  mapEntity,
  mapEvent,
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
    this.stageContext,
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
      stageContext: _readOptionalObject(
        json,
        'stageContext',
        CinematicStageContext.fromJson,
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
  final CinematicStageContext? stageContext;
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
        'stageContext': stageContext?.toJson(),
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
          other.stageContext == stageContext &&
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
        stageContext,
        timeline,
        notes,
        _mapHash(metadata),
        legacyBridge,
      );
}

@immutable
final class CinematicStageContext {
  CinematicStageContext({
    this.backdropMode = CinematicStageBackdropMode.none,
    List<CinematicActorBinding> actorBindings = const <CinematicActorBinding>[],
    List<CinematicActorAppearanceBinding> actorAppearanceBindings =
        const <CinematicActorAppearanceBinding>[],
    List<CinematicActorInitialPlacement> initialPlacements =
        const <CinematicActorInitialPlacement>[],
    List<CinematicMovementTargetBinding> movementTargetBindings =
        const <CinematicMovementTargetBinding>[],
    List<CinematicStagePoint> stagePoints = const <CinematicStagePoint>[],
  })  : actorBindings = List<CinematicActorBinding>.unmodifiable(actorBindings),
        actorAppearanceBindings =
            List<CinematicActorAppearanceBinding>.unmodifiable(
          actorAppearanceBindings,
        ),
        initialPlacements = List<CinematicActorInitialPlacement>.unmodifiable(
          initialPlacements,
        ),
        movementTargetBindings =
            List<CinematicMovementTargetBinding>.unmodifiable(
          movementTargetBindings,
        ),
        stagePoints = List<CinematicStagePoint>.unmodifiable(stagePoints);

  factory CinematicStageContext.fromJson(Map<String, dynamic> json) {
    return CinematicStageContext(
      backdropMode: _readEnum(
        CinematicStageBackdropMode.values,
        json['backdropMode'] ?? CinematicStageBackdropMode.none.name,
        'backdropMode',
      ),
      actorBindings: _readObjectList(
        json,
        'actorBindings',
        CinematicActorBinding.fromJson,
      ),
      actorAppearanceBindings: _readObjectList(
        json,
        'actorAppearanceBindings',
        CinematicActorAppearanceBinding.fromJson,
      ),
      initialPlacements: _readObjectList(
        json,
        'initialPlacements',
        CinematicActorInitialPlacement.fromJson,
      ),
      movementTargetBindings: _readObjectList(
        json,
        'movementTargetBindings',
        CinematicMovementTargetBinding.fromJson,
      ),
      stagePoints: _readObjectList(
        json,
        'stagePoints',
        CinematicStagePoint.fromJson,
      ),
    );
  }

  final CinematicStageBackdropMode backdropMode;
  final List<CinematicActorBinding> actorBindings;
  final List<CinematicActorAppearanceBinding> actorAppearanceBindings;
  final List<CinematicActorInitialPlacement> initialPlacements;
  final List<CinematicMovementTargetBinding> movementTargetBindings;
  final List<CinematicStagePoint> stagePoints;

  Map<String, dynamic> toJson() => {
        'backdropMode': backdropMode.name,
        'actorBindings':
            actorBindings.map((binding) => binding.toJson()).toList(),
        'actorAppearanceBindings':
            actorAppearanceBindings.map((binding) => binding.toJson()).toList(),
        'initialPlacements':
            initialPlacements.map((placement) => placement.toJson()).toList(),
        'movementTargetBindings':
            movementTargetBindings.map((binding) => binding.toJson()).toList(),
        'stagePoints':
            stagePoints.map((point) => point.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicStageContext &&
          other.backdropMode == backdropMode &&
          _listEquals(other.actorBindings, actorBindings) &&
          _listEquals(
            other.actorAppearanceBindings,
            actorAppearanceBindings,
          ) &&
          _listEquals(other.initialPlacements, initialPlacements) &&
          _listEquals(other.movementTargetBindings, movementTargetBindings) &&
          _listEquals(other.stagePoints, stagePoints);

  @override
  int get hashCode => Object.hash(
        backdropMode,
        Object.hashAll(actorBindings),
        Object.hashAll(actorAppearanceBindings),
        Object.hashAll(initialPlacements),
        Object.hashAll(movementTargetBindings),
        Object.hashAll(stagePoints),
      );
}

@immutable
final class CinematicActorBinding {
  CinematicActorBinding({
    required String actorId,
    required this.kind,
    String? mapEntityId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorBinding.actorId',
        ),
        mapEntityId = _trimOptional(mapEntityId);

  factory CinematicActorBinding.fromJson(Map<String, dynamic> json) {
    return CinematicActorBinding(
      actorId: _readRequiredString(json, 'actorId'),
      kind: _readEnum(
        CinematicActorBindingKind.values,
        json['kind'],
        'kind',
      ),
      mapEntityId: _readOptionalString(json, 'mapEntityId'),
    );
  }

  final String actorId;
  final CinematicActorBindingKind kind;
  final String? mapEntityId;

  Map<String, dynamic> toJson() => _withoutNulls({
        'actorId': actorId,
        'kind': kind.name,
        'mapEntityId': mapEntityId,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorBinding &&
          other.actorId == actorId &&
          other.kind == kind &&
          other.mapEntityId == mapEntityId;

  @override
  int get hashCode => Object.hash(actorId, kind, mapEntityId);
}

@immutable
final class CinematicActorAppearanceBinding {
  CinematicActorAppearanceBinding({
    required String actorId,
    required String characterId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorAppearanceBinding.actorId',
        ),
        characterId = _requireTrimmed(
          characterId,
          'CinematicActorAppearanceBinding.characterId',
        );

  factory CinematicActorAppearanceBinding.fromJson(
    Map<String, dynamic> json,
  ) {
    return CinematicActorAppearanceBinding(
      actorId: _readRequiredString(json, 'actorId'),
      characterId: _readRequiredString(json, 'characterId'),
    );
  }

  final String actorId;
  final String characterId;

  Map<String, dynamic> toJson() => {
        'actorId': actorId,
        'characterId': characterId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorAppearanceBinding &&
          other.actorId == actorId &&
          other.characterId == characterId;

  @override
  int get hashCode => Object.hash(actorId, characterId);
}

@immutable
final class CinematicActorInitialPlacement {
  CinematicActorInitialPlacement({
    required String actorId,
    required this.kind,
    String? targetId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorInitialPlacement.actorId',
        ),
        targetId = _trimOptional(targetId);

  factory CinematicActorInitialPlacement.fromJson(Map<String, dynamic> json) {
    return CinematicActorInitialPlacement(
      actorId: _readRequiredString(json, 'actorId'),
      kind: _readEnum(
        CinematicActorInitialPlacementKind.values,
        json['kind'],
        'kind',
      ),
      targetId: _readOptionalString(json, 'targetId'),
    );
  }

  final String actorId;
  final CinematicActorInitialPlacementKind kind;
  final String? targetId;

  Map<String, dynamic> toJson() => _withoutNulls({
        'actorId': actorId,
        'kind': kind.name,
        'targetId': targetId,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorInitialPlacement &&
          other.actorId == actorId &&
          other.kind == kind &&
          other.targetId == targetId;

  @override
  int get hashCode => Object.hash(actorId, kind, targetId);
}

@immutable
final class CinematicMovementTargetBinding {
  CinematicMovementTargetBinding({
    required String targetId,
    required this.kind,
    String? sourceId,
  })  : targetId = _requireTrimmed(
          targetId,
          'CinematicMovementTargetBinding.targetId',
        ),
        sourceId = _trimOptional(sourceId);

  factory CinematicMovementTargetBinding.fromJson(Map<String, dynamic> json) {
    return CinematicMovementTargetBinding(
      targetId: _readRequiredString(json, 'targetId'),
      kind: _readEnum(
        CinematicMovementTargetBindingKind.values,
        json['kind'],
        'kind',
      ),
      sourceId: _readOptionalString(json, 'sourceId'),
    );
  }

  final String targetId;
  final CinematicMovementTargetBindingKind kind;
  final String? sourceId;

  Map<String, dynamic> toJson() => _withoutNulls({
        'targetId': targetId,
        'kind': kind.name,
        'sourceId': sourceId,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicMovementTargetBinding &&
          other.targetId == targetId &&
          other.kind == kind &&
          other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(targetId, kind, sourceId);
}

@immutable
final class CinematicStagePoint {
  CinematicStagePoint({
    required String id,
    required String label,
    required this.x,
    required this.y,
    String? description,
  })  : id = _requireTrimmed(id, 'CinematicStagePoint.id'),
        label = _requireTrimmed(label, 'CinematicStagePoint.label'),
        description = _trimOptional(description);

  factory CinematicStagePoint.fromJson(Map<String, dynamic> json) {
    return CinematicStagePoint(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      x: _readRequiredDouble(json, 'x'),
      y: _readRequiredDouble(json, 'y'),
      description: _readOptionalString(json, 'description'),
    );
  }

  final String id;
  final String label;
  final double x;
  final double y;
  final String? description;

  Map<String, dynamic> toJson() => _withoutNulls({
        'id': id,
        'label': label,
        'x': x,
        'y': y,
        'description': description,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicStagePoint &&
          other.id == id &&
          other.label == label &&
          other.x == x &&
          other.y == y &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, label, x, y, description);
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

double _readRequiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw ArgumentError.value(value, key, 'must be a double');
  }
  return value.toDouble();
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
