import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'script_conditions.dart';

enum StorylineType {
  main,
  sideQuest,
  tutorial,
  epilogue,
  episode,
  postGame,
  hiddenEvent,
}

enum StorylineStatus {
  draft,
  active,
  archived,
  disabled,
}

enum StorylineSceneLinkState {
  placeholder,
  linkedScenario,
  brokenLink,
  needsImplementation,
}

enum StorylineSceneLinkRole {
  primary,
  optional,
  branch,
  convergence,
  setup,
  payoff,
}

enum StorylineRelationshipKind {
  sideQuestAvailableDuring,
  sideQuestUnlockedBy,
  sideQuestAffectsMain,
  convergesTo,
  requires,
  blocks,
}

enum StorylineValidationSeverity {
  info,
  warning,
  error,
  blocking,
}

enum StorylineEffectType {
  activateStep,
  completeStep,
  unlockStoryline,
  emitFact,
  setWorldRule,
  affectRelationship,
}

enum StorylineAnchorKind {
  storyline,
  chapter,
  step,
  sceneOutcome,
}

enum StorylineSceneRefKind {
  scenario,
}

@immutable
final class StorylineAsset {
  StorylineAsset({
    required this.id,
    this.schemaVersion = 1,
    required this.type,
    this.status = StorylineStatus.draft,
    required this.title,
    this.description,
    this.sortOrder,
    this.locale,
    List<StorylineChapter> chapters = const <StorylineChapter>[],
    List<StorylineSceneLink> sceneLinks = const <StorylineSceneLink>[],
    List<StorylineRelationship> relationships = const <StorylineRelationship>[],
    this.legacySource,
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : chapters = List<StorylineChapter>.unmodifiable(chapters),
        sceneLinks = List<StorylineSceneLink>.unmodifiable(sceneLinks),
        relationships = List<StorylineRelationship>.unmodifiable(relationships),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineAsset.id');
    if (schemaVersion <= 0) {
      throw const ValidationException(
        'StorylineAsset.schemaVersion must be greater than 0',
      );
    }
    _requireNotBlank(title, 'StorylineAsset.title');
    _validateUniqueIds(
      this.chapters.map((chapter) => chapter.id),
      'StorylineAsset.chapters',
    );
    _validateUniqueIds(
      _allSteps(this.chapters).map((step) => step.id),
      'StorylineAsset.steps',
    );
    _validateUniqueIds(
      this.sceneLinks.map((sceneLink) => sceneLink.id),
      'StorylineAsset.sceneLinks',
    );
    _validateUniqueIds(
      this.relationships.map((relationship) => relationship.id),
      'StorylineAsset.relationships',
    );
    _validateSceneLinkReferences(this.chapters, this.sceneLinks);
    for (final relationship in this.relationships) {
      if (relationship.sourceStorylineId != id) {
        throw ValidationException(
          'StorylineAsset.relationships sourceStorylineId must match $id',
        );
      }
    }
  }

  final String id;
  final int schemaVersion;
  final StorylineType type;
  final StorylineStatus status;
  final String title;
  final String? description;
  final int? sortOrder;
  final String? locale;
  final List<StorylineChapter> chapters;
  final List<StorylineSceneLink> sceneLinks;
  final List<StorylineRelationship> relationships;
  final StorylineLegacySource? legacySource;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineAsset &&
          other.id == id &&
          other.schemaVersion == schemaVersion &&
          other.type == type &&
          other.status == status &&
          other.title == title &&
          other.description == description &&
          other.sortOrder == sortOrder &&
          other.locale == locale &&
          _listEquals(other.chapters, chapters) &&
          _listEquals(other.sceneLinks, sceneLinks) &&
          _listEquals(other.relationships, relationships) &&
          other.legacySource == legacySource &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        schemaVersion,
        type,
        status,
        title,
        description,
        sortOrder,
        locale,
        Object.hashAll(chapters),
        Object.hashAll(sceneLinks),
        Object.hashAll(relationships),
        legacySource,
        authorNotes,
        _mapHash(metadata),
      );

  @override
  String toString() =>
      'StorylineAsset(id: $id, type: $type, status: $status, title: $title)';
}

@immutable
final class StorylineChapter {
  StorylineChapter({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    List<StorylineStep> steps = const <StorylineStep>[],
    List<String> directSceneLinkIds = const <String>[],
    this.status,
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : steps = List<StorylineStep>.unmodifiable(steps),
        directSceneLinkIds = _immutableNonBlankUniqueStrings(
            directSceneLinkIds, 'StorylineChapter.directSceneLinkIds'),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineChapter.id');
    _requireNotBlank(title, 'StorylineChapter.title');
    _requireNonNegative(order, 'StorylineChapter.order');
    _validateUniqueIds(
      this.steps.map((step) => step.id),
      'StorylineChapter.steps',
    );
  }

  final String id;
  final String title;
  final String? description;
  final int order;
  final List<StorylineStep> steps;
  final List<String> directSceneLinkIds;
  final StorylineStatus? status;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineChapter &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.order == order &&
          _listEquals(other.steps, steps) &&
          _listEquals(other.directSceneLinkIds, directSceneLinkIds) &&
          other.status == status &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        order,
        Object.hashAll(steps),
        Object.hashAll(directSceneLinkIds),
        status,
        authorNotes,
        _mapHash(metadata),
      );

  @override
  String toString() => 'StorylineChapter(id: $id, title: $title)';
}

@immutable
final class StorylineStep {
  StorylineStep({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    this.entryCondition,
    this.completionCondition,
    List<String> sceneLinkIds = const <String>[],
    List<String> expectedOutcomeIds = const <String>[],
    this.status,
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : sceneLinkIds = _immutableNonBlankUniqueStrings(
          sceneLinkIds,
          'StorylineStep.sceneLinkIds',
        ),
        expectedOutcomeIds = _immutableNonBlankUniqueStrings(
          expectedOutcomeIds,
          'StorylineStep.expectedOutcomeIds',
        ),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineStep.id');
    _requireNotBlank(title, 'StorylineStep.title');
    _requireNonNegative(order, 'StorylineStep.order');
  }

  final String id;
  final String title;
  final String? description;
  final int order;
  final ScriptCondition? entryCondition;
  final ScriptCondition? completionCondition;
  final List<String> sceneLinkIds;
  final List<String> expectedOutcomeIds;
  final StorylineStatus? status;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineStep &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.order == order &&
          other.entryCondition == entryCondition &&
          other.completionCondition == completionCondition &&
          _listEquals(other.sceneLinkIds, sceneLinkIds) &&
          _listEquals(other.expectedOutcomeIds, expectedOutcomeIds) &&
          other.status == status &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        order,
        entryCondition,
        completionCondition,
        Object.hashAll(sceneLinkIds),
        Object.hashAll(expectedOutcomeIds),
        status,
        authorNotes,
        _mapHash(metadata),
      );
}

@immutable
final class StorylineSceneLink {
  StorylineSceneLink({
    required this.id,
    required this.chapterId,
    this.stepId,
    required this.label,
    required this.state,
    required this.role,
    this.sceneRef,
    required this.order,
    List<String> expectedOutcomeIds = const <String>[],
    List<StorylineSceneOutcomeLink> outcomeLinks =
        const <StorylineSceneOutcomeLink>[],
    this.authorNotes,
    Map<String, String> metadata = const <String, String>{},
  })  : expectedOutcomeIds = _immutableNonBlankUniqueStrings(
          expectedOutcomeIds,
          'StorylineSceneLink.expectedOutcomeIds',
        ),
        outcomeLinks =
            List<StorylineSceneOutcomeLink>.unmodifiable(outcomeLinks),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineSceneLink.id');
    _requireNotBlank(chapterId, 'StorylineSceneLink.chapterId');
    if (stepId != null) {
      _requireNotBlank(stepId!, 'StorylineSceneLink.stepId');
    }
    _requireNotBlank(label, 'StorylineSceneLink.label');
    _requireNonNegative(order, 'StorylineSceneLink.order');
    _validateUniqueIds(
      this.outcomeLinks.map((outcomeLink) => outcomeLink.id),
      'StorylineSceneLink.outcomeLinks',
    );
    _validateSceneLinkState(state, sceneRef);
  }

  final String id;
  final String chapterId;
  final String? stepId;
  final String label;
  final StorylineSceneLinkState state;
  final StorylineSceneLinkRole role;
  final StorylineSceneRef? sceneRef;
  final int order;
  final List<String> expectedOutcomeIds;
  final List<StorylineSceneOutcomeLink> outcomeLinks;
  final String? authorNotes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneLink &&
          other.id == id &&
          other.chapterId == chapterId &&
          other.stepId == stepId &&
          other.label == label &&
          other.state == state &&
          other.role == role &&
          other.sceneRef == sceneRef &&
          other.order == order &&
          _listEquals(other.expectedOutcomeIds, expectedOutcomeIds) &&
          _listEquals(other.outcomeLinks, outcomeLinks) &&
          other.authorNotes == authorNotes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        chapterId,
        stepId,
        label,
        state,
        role,
        sceneRef,
        order,
        Object.hashAll(expectedOutcomeIds),
        Object.hashAll(outcomeLinks),
        authorNotes,
        _mapHash(metadata),
      );
}

@immutable
final class StorylineSceneRef {
  StorylineSceneRef({
    required this.kind,
    required this.targetId,
  }) {
    _requireNotBlank(targetId, 'StorylineSceneRef.targetId');
  }

  final StorylineSceneRefKind kind;
  final String targetId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneRef &&
          other.kind == kind &&
          other.targetId == targetId;

  @override
  int get hashCode => Object.hash(kind, targetId);
}

@immutable
final class StorylineSceneOutcomeLink {
  StorylineSceneOutcomeLink({
    required this.id,
    required this.outcomeId,
    this.label,
    required List<StorylineEffect> effects,
    this.notes,
    Map<String, String> metadata = const <String, String>{},
  })  : effects = List<StorylineEffect>.unmodifiable(effects),
        metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineSceneOutcomeLink.id');
    _requireNotBlank(outcomeId, 'StorylineSceneOutcomeLink.outcomeId');
    if (this.effects.isEmpty) {
      throw const ValidationException(
        'StorylineSceneOutcomeLink.effects must not be empty',
      );
    }
  }

  final String id;
  final String outcomeId;
  final String? label;
  final List<StorylineEffect> effects;
  final String? notes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneOutcomeLink &&
          other.id == id &&
          other.outcomeId == outcomeId &&
          other.label == label &&
          _listEquals(other.effects, effects) &&
          other.notes == notes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        outcomeId,
        label,
        Object.hashAll(effects),
        notes,
        _mapHash(metadata),
      );
}

@immutable
final class StorylineEffect {
  StorylineEffect({
    required this.type,
    required this.targetId,
    this.value,
  }) {
    _requireNotBlank(targetId, 'StorylineEffect.targetId');
  }

  final StorylineEffectType type;
  final String targetId;
  final String? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineEffect &&
          other.type == type &&
          other.targetId == targetId &&
          other.value == value;

  @override
  int get hashCode => Object.hash(type, targetId, value);
}

@immutable
final class StorylineRelationship {
  StorylineRelationship({
    required this.id,
    required this.kind,
    required this.sourceStorylineId,
    required this.targetStorylineId,
    this.anchor,
    this.availability,
    this.condition,
    this.notes,
    Map<String, String> metadata = const <String, String>{},
  }) : metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(id, 'StorylineRelationship.id');
    _requireNotBlank(
      sourceStorylineId,
      'StorylineRelationship.sourceStorylineId',
    );
    _requireNotBlank(
      targetStorylineId,
      'StorylineRelationship.targetStorylineId',
    );
    if (sourceStorylineId == targetStorylineId) {
      throw const ValidationException(
        'StorylineRelationship source and target must differ',
      );
    }
  }

  final String id;
  final StorylineRelationshipKind kind;
  final String sourceStorylineId;
  final String targetStorylineId;
  final StorylineAnchor? anchor;
  final SideQuestAvailability? availability;
  final ScriptCondition? condition;
  final String? notes;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineRelationship &&
          other.id == id &&
          other.kind == kind &&
          other.sourceStorylineId == sourceStorylineId &&
          other.targetStorylineId == targetStorylineId &&
          other.anchor == anchor &&
          other.availability == availability &&
          other.condition == condition &&
          other.notes == notes &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        sourceStorylineId,
        targetStorylineId,
        anchor,
        availability,
        condition,
        notes,
        _mapHash(metadata),
      );
}

@immutable
final class SideQuestAvailability {
  SideQuestAvailability({
    required this.startAnchor,
    this.endAnchor,
    this.availabilityCondition,
    this.expiresCondition,
    List<String> requiredOutcomeIds = const <String>[],
  }) : requiredOutcomeIds = _immutableNonBlankUniqueStrings(
          requiredOutcomeIds,
          'SideQuestAvailability.requiredOutcomeIds',
        );

  final StorylineAnchor startAnchor;
  final StorylineAnchor? endAnchor;
  final ScriptCondition? availabilityCondition;
  final ScriptCondition? expiresCondition;
  final List<String> requiredOutcomeIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SideQuestAvailability &&
          other.startAnchor == startAnchor &&
          other.endAnchor == endAnchor &&
          other.availabilityCondition == availabilityCondition &&
          other.expiresCondition == expiresCondition &&
          _listEquals(other.requiredOutcomeIds, requiredOutcomeIds);

  @override
  int get hashCode => Object.hash(
        startAnchor,
        endAnchor,
        availabilityCondition,
        expiresCondition,
        Object.hashAll(requiredOutcomeIds),
      );
}

@immutable
final class StorylineAnchor {
  StorylineAnchor({
    required this.kind,
    required this.targetId,
  }) {
    _requireNotBlank(targetId, 'StorylineAnchor.targetId');
  }

  final StorylineAnchorKind kind;
  final String targetId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineAnchor &&
          other.kind == kind &&
          other.targetId == targetId;

  @override
  int get hashCode => Object.hash(kind, targetId);
}

@immutable
final class StorylineValidationIssue {
  StorylineValidationIssue({
    this.id,
    required this.severity,
    required this.targetRef,
    required this.ruleId,
    required this.message,
  }) {
    if (id != null) {
      _requireNotBlank(id!, 'StorylineValidationIssue.id');
    }
    _requireNotBlank(targetRef, 'StorylineValidationIssue.targetRef');
    _requireNotBlank(ruleId, 'StorylineValidationIssue.ruleId');
    _requireNotBlank(message, 'StorylineValidationIssue.message');
  }

  final String? id;
  final StorylineValidationSeverity severity;
  final String targetRef;
  final String ruleId;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineValidationIssue &&
          other.id == id &&
          other.severity == severity &&
          other.targetRef == targetRef &&
          other.ruleId == ruleId &&
          other.message == message;

  @override
  int get hashCode => Object.hash(id, severity, targetRef, ruleId, message);
}

@immutable
final class StorylineLegacySource {
  StorylineLegacySource({
    required this.kind,
    required this.sourceId,
    Map<String, String> metadata = const <String, String>{},
  }) : metadata = Map<String, String>.unmodifiable(metadata) {
    _requireNotBlank(kind, 'StorylineLegacySource.kind');
    _requireNotBlank(sourceId, 'StorylineLegacySource.sourceId');
  }

  final String kind;
  final String sourceId;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineLegacySource &&
          other.kind == kind &&
          other.sourceId == sourceId &&
          _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        kind,
        sourceId,
        _mapHash(metadata),
      );
}

Iterable<StorylineStep> _allSteps(List<StorylineChapter> chapters) sync* {
  for (final chapter in chapters) {
    yield* chapter.steps;
  }
}

void _validateSceneLinkReferences(
  List<StorylineChapter> chapters,
  List<StorylineSceneLink> sceneLinks,
) {
  final chapterIds = chapters.map((chapter) => chapter.id).toSet();
  final stepToChapter = <String, String>{};
  for (final chapter in chapters) {
    for (final step in chapter.steps) {
      stepToChapter[step.id] = chapter.id;
    }
  }

  for (final sceneLink in sceneLinks) {
    if (!chapterIds.contains(sceneLink.chapterId)) {
      throw ValidationException(
        'StorylineSceneLink ${sceneLink.id} references missing chapter '
        '${sceneLink.chapterId}',
      );
    }
    final stepId = sceneLink.stepId;
    if (stepId != null && !stepToChapter.containsKey(stepId)) {
      throw ValidationException(
        'StorylineSceneLink ${sceneLink.id} references missing step $stepId',
      );
    }
    if (stepId != null && stepToChapter[stepId] != sceneLink.chapterId) {
      throw ValidationException(
        'StorylineSceneLink ${sceneLink.id} step $stepId does not belong to '
        'chapter ${sceneLink.chapterId}',
      );
    }
  }
}

void _validateSceneLinkState(
  StorylineSceneLinkState state,
  StorylineSceneRef? sceneRef,
) {
  switch (state) {
    case StorylineSceneLinkState.placeholder:
      if (sceneRef != null) {
        throw const ValidationException(
          'placeholder StorylineSceneLink must not have sceneRef',
        );
      }
    case StorylineSceneLinkState.linkedScenario:
      if (sceneRef == null) {
        throw const ValidationException(
          'linkedScenario StorylineSceneLink requires sceneRef',
        );
      }
      if (sceneRef.kind != StorylineSceneRefKind.scenario) {
        throw const ValidationException(
          'linkedScenario StorylineSceneLink requires scenario sceneRef',
        );
      }
    case StorylineSceneLinkState.brokenLink:
      break;
    case StorylineSceneLinkState.needsImplementation:
      if (sceneRef != null) {
        throw const ValidationException(
          'needsImplementation StorylineSceneLink must not have sceneRef',
        );
      }
  }
}

List<String> _immutableNonBlankUniqueStrings(
  List<String> values,
  String fieldName,
) {
  for (final value in values) {
    _requireNotBlank(value, fieldName);
  }
  _validateUniqueIds(values, fieldName);
  return List<String>.unmodifiable(values);
}

void _validateUniqueIds(Iterable<String> ids, String fieldName) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw ValidationException('$fieldName contains duplicate id $id');
    }
  }
}

void _requireNotBlank(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ValidationException('$fieldName must not be empty');
  }
}

void _requireNonNegative(int value, String fieldName) {
  if (value < 0) {
    throw ValidationException('$fieldName must be >= 0');
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
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
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
