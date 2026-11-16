import 'package:map_core/map_core_domain.dart';

import 'storyline_trame_controller.dart';
import 'storyline_trame_edits.dart';

bool editableStorylineCondition(ScriptCondition? condition) =>
    condition == null ||
    condition.type == ScriptConditionType.factEquals &&
        condition.children.isEmpty &&
        condition.params.length == 3 &&
        condition.params[ScriptConditionParams.factId]?.isNotEmpty == true &&
        condition.params[ScriptConditionParams.valueType] ==
            NarrativeValueKind.boolean.wireName &&
        const {
          'true',
          'false',
        }.contains(condition.params[ScriptConditionParams.value]);

extension StorylineConditionEdits on StorylineTrameController {
  Future<bool> setSimpleCondition(
    String storylineId,
    String chapterId,
    String stepId, {
    required bool entry,
    required String? factId,
    bool expected = true,
  }) => edit((project) {
    final story = project.storylines
        .where((story) => story.id == storylineId)
        .firstOrNull;
    final chapter = story?.chapters
        .where((chapter) => chapter.id == chapterId)
        .firstOrNull;
    final step = chapter?.steps.where((step) => step.id == stepId).firstOrNull;
    final current = entry ? step?.entryCondition : step?.completionCondition;
    final fact = project.facts.where((fact) => fact.id == factId).firstOrNull;
    if (step == null ||
        !editableStorylineCondition(current) ||
        factId != null &&
            fact?.initialValue.kind != NarrativeValueKind.boolean) {
      return StorylineMilestoneMutation(
        StorylineMutationResult(
          before: project,
          after: project,
          disposition: StorylineMutationDisposition.rejected,
          code: 'conditionUnsupported',
        ),
      );
    }
    final condition = factId == null
        ? null
        : ScriptConditionFactory.factEquals(
            factId,
            NarrativeValue.boolean(expected),
          );
    return StorylineMilestoneMutation(
      updateStorylineStep(
        project,
        storylineId: storylineId,
        chapterId: chapterId,
        stepId: stepId,
        step: entry
            ? step.copyWith(entryCondition: condition)
            : step.copyWith(completionCondition: condition),
      ),
    );
  });
}
