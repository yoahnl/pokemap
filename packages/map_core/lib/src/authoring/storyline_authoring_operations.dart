import '../models/project_manifest.dart';
import '../models/storyline_asset.dart';
import '../read_models/narrative_dependency_index.dart';

/// Outcome of one pure Storyline lifecycle operation.
///
/// Rejected and no-op operations always keep [before] and [after] identical so
/// an editor cannot accidentally publish a partial projection.
enum StorylineMutationDisposition { applied, noChange, rejected }

/// Immutable before/after envelope returned by Storyline authoring commands.
final class StorylineMutationResult {
  StorylineMutationResult({
    required this.before,
    required this.after,
    required this.disposition,
    this.storyline,
    this.previousStoryline,
    this.code,
    this.message,
    List<String> referencePaths = const <String>[],
  }) : referencePaths = List<String>.unmodifiable(referencePaths);

  final ProjectManifest before;
  final ProjectManifest after;
  final StorylineMutationDisposition disposition;
  final StorylineAsset? storyline;
  final StorylineAsset? previousStoryline;
  final String? code;
  final String? message;
  final List<String> referencePaths;

  bool get isApplied => disposition == StorylineMutationDisposition.applied;
}

/// Adds an already validated Storyline asset without replacing an existing id.
StorylineMutationResult createStoryline(
  ProjectManifest project, {
  required StorylineAsset storyline,
}) {
  if (project.storylines.any((candidate) => candidate.id == storyline.id)) {
    return _storylineRejected(
      project,
      code: 'storylineIdAlreadyExists',
      message: 'A StorylineAsset already uses this id.',
    );
  }
  return _storylineApplied(
    project,
    project.copyWith(storylines: [...project.storylines, storyline]),
    storyline: storyline,
  );
}

/// Replaces one Storyline atomically while preserving its stable technical id.
StorylineMutationResult updateStoryline(
  ProjectManifest project, {
  required String storylineId,
  required StorylineAsset storyline,
}) {
  final id = storylineId.trim();
  final matches = project.storylines.where((asset) => asset.id == id).toList();
  if (matches.isEmpty) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to update does not exist.',
    );
  }
  if (matches.length > 1) {
    return _storylineRejected(
      project,
      code: 'storylineIdAmbiguous',
      message: 'The StorylineAsset id is ambiguous.',
    );
  }
  final previous = matches.single;
  if (storyline.id != id) {
    return _storylineRejected(
      project,
      code: 'storylineIdMismatch',
      message: 'A StorylineAsset update cannot change its stable id.',
    );
  }
  if (previous == storyline) {
    return StorylineMutationResult(
      before: project,
      after: project,
      disposition: StorylineMutationDisposition.noChange,
      storyline: previous,
      previousStoryline: previous,
      code: 'storylineUnchanged',
      message: 'The StorylineAsset already has these values.',
    );
  }
  return _storylineApplied(
    project,
    project.copyWith(
      storylines: [
        for (final asset in project.storylines)
          if (asset.id == id) storyline else asset,
      ],
    ),
    storyline: storyline,
    previousStoryline: previous,
  );
}

/// Deep-clones a Storyline and remaps every id owned by the copied asset.
StorylineMutationResult duplicateStoryline(
  ProjectManifest project, {
  required String storylineId,
  required String duplicateId,
  String? title,
}) {
  final source = _findStoryline(project, storylineId);
  if (source == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to duplicate does not exist.',
    );
  }
  final id = duplicateId.trim();
  if (id.isEmpty) {
    return _storylineRejected(
      project,
      code: 'blankStorylineId',
      message: 'The duplicated StorylineAsset requires an id.',
    );
  }
  if (project.storylines.any((candidate) => candidate.id == id)) {
    return _storylineRejected(
      project,
      code: 'storylineIdAlreadyExists',
      message: 'A StorylineAsset already uses the duplicate id.',
    );
  }
  try {
    final duplicate = _duplicateStorylineAsset(
      source,
      duplicateId: id,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : '${source.title} (copie)',
    );
    return createStoryline(project, storyline: duplicate);
  } on Object catch (error) {
    return _storylineRejected(
      project,
      code: 'invalidStorylineDuplicate',
      message: 'The StorylineAsset duplicate is invalid: $error',
    );
  }
}

/// Moves a Storyline to the archived lifecycle state without deleting content.
StorylineMutationResult archiveStoryline(
  ProjectManifest project, {
  required String storylineId,
}) {
  final source = _findStoryline(project, storylineId);
  if (source == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to archive does not exist.',
    );
  }
  return updateStoryline(
    project,
    storylineId: source.id,
    storyline: source.copyWith(status: StorylineStatus.archived),
  );
}

/// Deletes a Storyline only when no external narrative consumer references it.
///
/// Outgoing references owned by the Storyline do not block its own deletion.
StorylineMutationResult deleteStoryline(
  ProjectManifest project, {
  required String storylineId,
}) {
  final source = _findStoryline(project, storylineId);
  if (source == null) {
    return _storylineRejected(
      project,
      code: 'storylineNotFound',
      message: 'The StorylineAsset to delete does not exist.',
    );
  }
  final target = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.storyline,
    source.id,
  );
  final externalUsages = buildNarrativeDependencyIndex(project: project)
      .usagesFor(target)
      .where((usage) => usage.owner != target)
      .toList(growable: false);
  if (externalUsages.isNotEmpty) {
    return _storylineRejected(
      project,
      code: 'storylineReferenced',
      message: 'The StorylineAsset is still used by narrative consumers.',
      referencePaths: [for (final usage in externalUsages) usage.path],
    );
  }
  return _storylineApplied(
    project,
    project.copyWith(
      storylines: [
        for (final asset in project.storylines)
          if (asset.id != source.id) asset,
      ],
    ),
    previousStoryline: source,
  );
}

final class StorylineStepSceneLinkResult {
  const StorylineStepSceneLinkResult({
    required this.updatedProject,
    required this.updatedStoryline,
    required this.updatedStep,
  });

  final ProjectManifest updatedProject;
  final StorylineAsset updatedStoryline;
  final StorylineStep updatedStep;
}

StorylineStepSceneLinkResult linkSceneToStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
}) {
  final normalizedSceneId = _normalizeSceneId(sceneId);
  _requireKnownScene(project, normalizedSceneId);
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  if (target.step.sceneLinkIds.contains(normalizedSceneId)) {
    throw ArgumentError.value(
      sceneId,
      'sceneId',
      'StorylineStep already links this Scene.',
    );
  }
  return _replaceStepSceneLinks(
    project,
    target,
    [...target.step.sceneLinkIds, normalizedSceneId],
  );
}

StorylineStepSceneLinkResult unlinkSceneFromStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
}) {
  final normalizedSceneId = _normalizeSceneId(sceneId);
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  return _replaceStepSceneLinks(
    project,
    target,
    target.step.sceneLinkIds
        .where((current) => current != normalizedSceneId)
        .toList(growable: false),
  );
}

StorylineStepSceneLinkResult replaceStorylineStepSceneLinks(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required List<String> sceneIds,
}) {
  final normalizedSceneIds = _uniqueSceneIds(sceneIds);
  for (final sceneId in normalizedSceneIds) {
    _requireKnownScene(project, sceneId);
  }
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  return _replaceStepSceneLinks(project, target, normalizedSceneIds);
}

StorylineStepSceneLinkResult clearStorylineStepSceneLinks(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
}) {
  final target = _findStorylineStepTarget(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
  );
  return _replaceStepSceneLinks(project, target, const <String>[]);
}

StorylineStepSceneLinkResult _replaceStepSceneLinks(
  ProjectManifest project,
  _StorylineStepTarget target,
  List<String> sceneLinkIds,
) {
  final updatedStep = _copyStepWith(
    target.step,
    sceneLinkIds: sceneLinkIds,
  );
  final updatedChapter = _copyChapterWith(
    target.chapter,
    steps: target.chapter.steps
        .map((step) => step.id == target.step.id ? updatedStep : step)
        .toList(growable: false),
  );
  final updatedStoryline = _copyStorylineWith(
    target.storyline,
    chapters: target.storyline.chapters
        .map((chapter) =>
            chapter.id == target.chapter.id ? updatedChapter : chapter)
        .toList(growable: false),
  );
  final updatedProject = project.copyWith(
    storylines: project.storylines
        .map((storyline) =>
            storyline.id == target.storyline.id ? updatedStoryline : storyline)
        .toList(growable: false),
  );
  return StorylineStepSceneLinkResult(
    updatedProject: updatedProject,
    updatedStoryline: updatedStoryline,
    updatedStep: updatedStep,
  );
}

_StorylineStepTarget _findStorylineStepTarget(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
}) {
  final normalizedStorylineId = _requireNotBlank(storylineId, 'storylineId');
  final normalizedChapterId = _requireNotBlank(chapterId, 'chapterId');
  final normalizedStepId = _requireNotBlank(stepId, 'stepId');

  StorylineAsset? storyline;
  for (final candidate in project.storylines) {
    if (candidate.id == normalizedStorylineId) {
      storyline = candidate;
      break;
    }
  }
  if (storyline == null) {
    throw ArgumentError.value(
      storylineId,
      'storylineId',
      'Unknown StorylineAsset.',
    );
  }

  StorylineChapter? chapter;
  for (final candidate in storyline.chapters) {
    if (candidate.id == normalizedChapterId) {
      chapter = candidate;
      break;
    }
  }
  if (chapter == null) {
    throw ArgumentError.value(
      chapterId,
      'chapterId',
      'Unknown StorylineChapter.',
    );
  }

  StorylineStep? step;
  for (final candidate in chapter.steps) {
    if (candidate.id == normalizedStepId) {
      step = candidate;
      break;
    }
  }
  if (step == null) {
    throw ArgumentError.value(
      stepId,
      'stepId',
      'Unknown StorylineStep.',
    );
  }

  return _StorylineStepTarget(
    storyline: storyline,
    chapter: chapter,
    step: step,
  );
}

String _normalizeSceneId(String sceneId) {
  final normalized = _requireNotBlank(sceneId, 'sceneId');
  return normalized;
}

List<String> _uniqueSceneIds(List<String> sceneIds) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final sceneId in sceneIds) {
    final value = _normalizeSceneId(sceneId);
    if (seen.add(value)) {
      normalized.add(value);
    }
  }
  return List<String>.unmodifiable(normalized);
}

void _requireKnownScene(ProjectManifest project, String sceneId) {
  if (!project.scenes.any((scene) => scene.id == sceneId)) {
    throw ArgumentError.value(sceneId, 'sceneId', 'Unknown SceneAsset.');
  }
}

String _requireNotBlank(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'Value must not be blank.');
  }
  return trimmed;
}

StorylineAsset _copyStorylineWith(
  StorylineAsset storyline, {
  List<StorylineChapter>? chapters,
}) {
  return StorylineAsset(
    id: storyline.id,
    schemaVersion: storyline.schemaVersion,
    type: storyline.type,
    status: storyline.status,
    title: storyline.title,
    description: storyline.description,
    sortOrder: storyline.sortOrder,
    locale: storyline.locale,
    chapters: chapters ?? storyline.chapters,
    sceneLinks: storyline.sceneLinks,
    relationships: storyline.relationships,
    legacySource: storyline.legacySource,
    authorNotes: storyline.authorNotes,
    metadata: storyline.metadata,
  );
}

StorylineChapter _copyChapterWith(
  StorylineChapter chapter, {
  List<StorylineStep>? steps,
}) {
  return StorylineChapter(
    id: chapter.id,
    title: chapter.title,
    description: chapter.description,
    order: chapter.order,
    steps: steps ?? chapter.steps,
    directSceneLinkIds: chapter.directSceneLinkIds,
    status: chapter.status,
    authorNotes: chapter.authorNotes,
    metadata: chapter.metadata,
  );
}

StorylineStep _copyStepWith(
  StorylineStep step, {
  List<String>? sceneLinkIds,
}) {
  return StorylineStep(
    id: step.id,
    title: step.title,
    description: step.description,
    order: step.order,
    entryCondition: step.entryCondition,
    completionCondition: step.completionCondition,
    sceneLinkIds: sceneLinkIds ?? step.sceneLinkIds,
    expectedOutcomeIds: step.expectedOutcomeIds,
    status: step.status,
    authorNotes: step.authorNotes,
    metadata: step.metadata,
  );
}

final class _StorylineStepTarget {
  const _StorylineStepTarget({
    required this.storyline,
    required this.chapter,
    required this.step,
  });

  final StorylineAsset storyline;
  final StorylineChapter chapter;
  final StorylineStep step;
}

StorylineAsset? _findStoryline(ProjectManifest project, String storylineId) {
  final id = storylineId.trim();
  StorylineAsset? match;
  for (final candidate in project.storylines) {
    if (candidate.id != id) continue;
    if (match != null) return null;
    match = candidate;
  }
  return match;
}

StorylineMutationResult _storylineApplied(
  ProjectManifest before,
  ProjectManifest after, {
  StorylineAsset? storyline,
  StorylineAsset? previousStoryline,
}) {
  return StorylineMutationResult(
    before: before,
    after: after,
    disposition: StorylineMutationDisposition.applied,
    storyline: storyline,
    previousStoryline: previousStoryline,
  );
}

StorylineMutationResult _storylineRejected(
  ProjectManifest project, {
  required String code,
  required String message,
  List<String> referencePaths = const <String>[],
}) {
  return StorylineMutationResult(
    before: project,
    after: project,
    disposition: StorylineMutationDisposition.rejected,
    code: code,
    message: message,
    referencePaths: referencePaths,
  );
}

StorylineAsset _duplicateStorylineAsset(
  StorylineAsset source, {
  required String duplicateId,
  required String title,
}) {
  // Chapter and step ids are asset-owned. Keeping them unchanged would create
  // ambiguous authoring targets as soon as the duplicate is inserted.
  final chapterIds = <String, String>{
    for (final chapter in source.chapters)
      chapter.id: '${duplicateId}__${chapter.id}',
  };
  final stepIds = <String, String>{
    for (final chapter in source.chapters)
      for (final step in chapter.steps) step.id: '${duplicateId}__${step.id}',
  };

  StorylineAnchor remapAnchor(StorylineAnchor anchor) {
    final targetId = switch (anchor.kind) {
      StorylineAnchorKind.storyline when anchor.targetId == source.id =>
        duplicateId,
      StorylineAnchorKind.chapter =>
        chapterIds[anchor.targetId] ?? anchor.targetId,
      StorylineAnchorKind.step => stepIds[anchor.targetId] ?? anchor.targetId,
      _ => anchor.targetId,
    };
    return StorylineAnchor(kind: anchor.kind, targetId: targetId);
  }

  StorylineEffect remapEffect(StorylineEffect effect) {
    final targetId = switch (effect.type) {
      StorylineEffectType.activateStep ||
      StorylineEffectType.completeStep =>
        stepIds[effect.targetId] ?? effect.targetId,
      StorylineEffectType.unlockStoryline when effect.targetId == source.id =>
        duplicateId,
      _ => effect.targetId,
    };
    return StorylineEffect(
      type: effect.type,
      targetId: targetId,
      value: effect.value,
    );
  }

  return StorylineAsset(
    id: duplicateId,
    schemaVersion: source.schemaVersion,
    type: source.type,
    status: StorylineStatus.draft,
    title: title,
    description: source.description,
    sortOrder: source.sortOrder,
    locale: source.locale,
    chapters: [
      for (final chapter in source.chapters)
        StorylineChapter(
          id: chapterIds[chapter.id]!,
          title: chapter.title,
          description: chapter.description,
          order: chapter.order,
          steps: [
            for (final step in chapter.steps)
              StorylineStep(
                id: stepIds[step.id]!,
                title: step.title,
                description: step.description,
                order: step.order,
                entryCondition: step.entryCondition,
                completionCondition: step.completionCondition,
                sceneLinkIds: step.sceneLinkIds,
                expectedOutcomeIds: step.expectedOutcomeIds,
                status: step.status,
                authorNotes: step.authorNotes,
                metadata: step.metadata,
              ),
          ],
          directSceneLinkIds: chapter.directSceneLinkIds,
          status: chapter.status,
          authorNotes: chapter.authorNotes,
          metadata: chapter.metadata,
        ),
    ],
    sceneLinks: [
      for (final link in source.sceneLinks)
        StorylineSceneLink(
          id: '${duplicateId}__${link.id}',
          chapterId: chapterIds[link.chapterId]!,
          stepId: link.stepId == null ? null : stepIds[link.stepId!],
          label: link.label,
          state: link.state,
          role: link.role,
          sceneRef: link.sceneRef,
          order: link.order,
          expectedOutcomeIds: link.expectedOutcomeIds,
          outcomeLinks: [
            for (final outcome in link.outcomeLinks)
              StorylineSceneOutcomeLink(
                id: '${duplicateId}__${outcome.id}',
                outcomeId: outcome.outcomeId,
                label: outcome.label,
                effects: [
                  for (final effect in outcome.effects) remapEffect(effect)
                ],
                notes: outcome.notes,
                metadata: outcome.metadata,
              ),
          ],
          authorNotes: link.authorNotes,
          metadata: link.metadata,
        ),
    ],
    relationships: [
      for (final relationship in source.relationships)
        StorylineRelationship(
          id: '${duplicateId}__${relationship.id}',
          kind: relationship.kind,
          sourceStorylineId: duplicateId,
          targetStorylineId: relationship.targetStorylineId,
          anchor: relationship.anchor == null
              ? null
              : remapAnchor(relationship.anchor!),
          availability: relationship.availability == null
              ? null
              : SideQuestAvailability(
                  startAnchor:
                      remapAnchor(relationship.availability!.startAnchor),
                  endAnchor: relationship.availability!.endAnchor == null
                      ? null
                      : remapAnchor(relationship.availability!.endAnchor!),
                  availabilityCondition:
                      relationship.availability!.availabilityCondition,
                  expiresCondition: relationship.availability!.expiresCondition,
                  requiredOutcomeIds:
                      relationship.availability!.requiredOutcomeIds,
                ),
          condition: relationship.condition,
          notes: relationship.notes,
          metadata: relationship.metadata,
        ),
    ],
    authorNotes: source.authorNotes,
    metadata: <String, String>{
      for (final entry in source.metadata.entries)
        if (entry.key != 'legacyImportPreview' && entry.key != 'legacyImported')
          entry.key: entry.value,
      'duplicatedFrom': source.id,
    },
  );
}
