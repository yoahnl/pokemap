import '../models/narrative_fact.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';
import 'narrative_fact_authoring_operations.dart';
import 'storyline_authoring_operations.dart';

part 'storyline_archive_and_chapter_operations.dart';
part 'storyline_milestone_scene_operations.dart';

final class StorylineStepLocation {
  const StorylineStepLocation({
    required this.storylineId,
    required this.chapterId,
    required this.stepId,
  });

  final String storylineId;
  final String chapterId;
  final String stepId;

  Map<String, Object?> toJson() => {
    'storylineId': storylineId,
    'chapterId': chapterId,
    'stepId': stepId,
  };
}

final class StorylineMilestoneMutation {
  StorylineMilestoneMutation(
    this.result, {
    this.fact,
    this.previousFact,
    List<StorylineStepLocation> detachedFrom = const [],
  }) : detachedFrom = List.unmodifiable(detachedFrom);

  final StorylineMutationResult result;
  final NarrativeFactDefinition? fact;
  final NarrativeFactDefinition? previousFact;
  final List<StorylineStepLocation> detachedFrom;
}

String? storylineMilestoneCompletionFactId(StorylineStep step) {
  final condition = step.completionCondition;
  if (condition == null ||
      condition.type != ScriptConditionType.factEquals ||
      condition.params[ScriptConditionParams.valueType] !=
          NarrativeValueKind.boolean.wireName ||
      condition.params[ScriptConditionParams.value] != 'true') {
    return null;
  }
  final factId = condition.params[ScriptConditionParams.factId]?.trim();
  return factId == null || factId.isEmpty ? null : factId;
}

StorylineMilestoneMutation createStorylineMilestone(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String title,
  int? index,
}) {
  final storyline = _storyline(project, storylineId);
  final chapter = _chapter(storyline, chapterId);
  if (storyline == null || chapter == null) {
    return StorylineMilestoneMutation(
      _rejected(
        project,
        'chapterNotFound',
        'The StorylineChapter does not exist.',
      ),
    );
  }
  if (!_isIdentity(stepId)) {
    return StorylineMilestoneMutation(
      _rejected(
        project,
        'stepIdInvalid',
        'A milestone id must be a nonblank trimmed string.',
      ),
    );
  }
  if (title.trim().isEmpty) {
    return StorylineMilestoneMutation(
      _rejected(project, 'stepTitleRequired', 'A milestone needs a title.'),
    );
  }
  if (_locate(project, (step) => step.id == stepId).isNotEmpty) {
    return StorylineMilestoneMutation(
      _rejected(
        project,
        'stepIdAlreadyExists',
        'A StorylineStep already uses this id.',
      ),
    );
  }
  final created = addNarrativeFact(project, label: title.trim());
  final fact = created.createdFact;
  final steps = [...chapter.steps];
  steps.insert(
    (index ?? steps.length).clamp(0, steps.length),
    StorylineStep(
      id: stepId,
      title: title.trim(),
      order: 0,
      completionCondition: ScriptConditionFactory.factEquals(
        fact.id,
        const NarrativeValue.boolean(true),
      ),
    ),
  );
  final updatedChapter = chapter.copyWith(
    steps: [
      for (var position = 0; position < steps.length; position++)
        steps[position].copyWith(order: position),
    ],
  );
  final updated = updateStorylineChapter(
    created.updatedProject,
    storylineId: storyline.id,
    chapterId: chapter.id,
    chapter: updatedChapter,
  );
  return StorylineMilestoneMutation(
    _rebased(
      project,
      updated,
      step: updatedChapter.steps.firstWhere((step) => step.id == stepId),
    ),
    fact: fact,
  );
}

StorylineMilestoneMutation renameStorylineMilestone(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String title,
}) {
  final step = _step(project, storylineId, chapterId, stepId);
  if (step == null) {
    return StorylineMilestoneMutation(
      _rejected(project, 'stepNotFound', 'The milestone does not exist.'),
    );
  }
  if (title.trim().isEmpty) {
    return StorylineMilestoneMutation(
      _rejected(project, 'stepTitleRequired', 'A milestone needs a title.'),
    );
  }
  final renamed = updateStorylineStep(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
    step: step.copyWith(title: title.trim()),
  );
  final factId = storylineMilestoneCompletionFactId(step);
  final facts = project.facts.where((fact) => fact.id == factId).toList();
  if (!renamed.isApplied ||
      facts.length != 1 ||
      facts.single.label != step.title) {
    return StorylineMilestoneMutation(renamed);
  }
  final previous = facts.single;
  final relabelled = updateNarrativeFact(
    renamed.after,
    factId: previous.id,
    label: title.trim(),
    description: previous.description,
    category: previous.category,
    initialValue: previous.initialValue,
    tags: previous.tags,
    legacyFlagName: previous.legacyFlagName,
  );
  return StorylineMilestoneMutation(
    _rebased(project, renamed, after: relabelled.updatedProject),
    fact: relabelled.updatedFact,
    previousFact: previous,
  );
}

StorylineStatus? _archivedStatus(
  StorylineStatus? current, {
  required bool archived,
}) => archived
    ? StorylineStatus.archived
    : current == StorylineStatus.archived
    ? null
    : current;

bool _isIdentity(String value) => value.isNotEmpty && value.trim() == value;

StorylineAsset? _storyline(ProjectManifest project, String storylineId) {
  final matches = project.storylines
      .where((asset) => asset.id == storylineId)
      .toList();
  return matches.length == 1 ? matches.single : null;
}

StorylineChapter? _chapter(StorylineAsset? storyline, String chapterId) {
  if (storyline == null) return null;
  for (final chapter in storyline.chapters) {
    if (chapter.id == chapterId) return chapter;
  }
  return null;
}

StorylineStep? _step(
  ProjectManifest project,
  String storylineId,
  String chapterId,
  String stepId,
) {
  final chapter = _chapter(_storyline(project, storylineId), chapterId);
  if (chapter == null) return null;
  for (final step in chapter.steps) {
    if (step.id == stepId) return step;
  }
  return null;
}

List<(StorylineStepLocation, StorylineStep)> _locate(
  ProjectManifest project,
  bool Function(StorylineStep step) test,
) => [
  for (final storyline in project.storylines)
    for (final chapter in storyline.chapters)
      for (final step in chapter.steps)
        if (test(step))
          (
            StorylineStepLocation(
              storylineId: storyline.id,
              chapterId: chapter.id,
              stepId: step.id,
            ),
            step,
          ),
];

StorylineMutationResult _rebased(
  ProjectManifest before,
  StorylineMutationResult result, {
  ProjectManifest? after,
  StorylineStep? step,
}) {
  if (result.disposition == StorylineMutationDisposition.rejected) {
    return _rejected(
      before,
      result.code ?? 'storylineRejected',
      result.message ?? 'The Storyline operation was rejected.',
    );
  }
  return StorylineMutationResult(
    before: before,
    after: after ?? result.after,
    disposition: result.disposition,
    storyline: result.storyline,
    previousStoryline: _storyline(before, result.storyline?.id ?? ''),
    chapter: result.chapter,
    previousChapter: result.previousChapter,
    step: step ?? result.step,
    previousStep: result.previousStep,
    code: result.code,
    message: result.message,
  );
}

StorylineMutationResult _rejected(
  ProjectManifest project,
  String code,
  String message,
) => StorylineMutationResult(
  before: project,
  after: project,
  disposition: StorylineMutationDisposition.rejected,
  code: code,
  message: message,
);
