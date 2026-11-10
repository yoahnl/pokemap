import 'package:map_core/map_core_domain.dart';

import 'story_graph_sources.dart';
import 'story_labels.dart';

import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';

class StoryDocumentCommands {
  const StoryDocumentCommands(this.controller);
  final StoryWorkspaceController controller;

  void associateScene({
    required String storyId,
    required String chapterId,
    required String stepId,
    required String sceneId,
    required bool linked,
  }) => controller.mutate(
    (project) => linked
        ? linkSceneToStorylineStep(
            project,
            storylineId: storyId,
            chapterId: chapterId,
            stepId: stepId,
            sceneId: sceneId,
          ).updatedProject
        : unlinkSceneFromStorylineStep(
            project,
            storylineId: storyId,
            chapterId: chapterId,
            stepId: stepId,
            sceneId: sceneId,
          ).updatedProject,
  );

  void expectScenarioOutcome(
    String storyId,
    String linkId,
    String outcomeId,
    bool expected,
  ) => patchScenarioLink(
    storyId,
    linkId,
    (latest) => {
      'expectedOutcomeIds': expected
          ? {...latest.expectedOutcomeIds, outcomeId}.toList()
          : latest.expectedOutcomeIds
                .where((value) => value != outcomeId)
                .toList(),
    },
  );

  void moveChapter(String storyId, String chapterId, int delta) {
    final story = controller.stories
        .where((story) => story.id == storyId)
        .firstOrNull;
    if (story == null) return;
    final ids = orderedStoryChapters(story)
        .map((chapter) => chapter.id)
        .toList();
    final index = ids.indexOf(chapterId);
    if (index < 0 ||
        index + delta < 0 ||
        index + delta >= ids.length ||
        delta == 0) {
      return;
    }
    ids.insert(index + delta, ids.removeAt(index));
    controller.apply(
      reorderStorylineChapters(
        controller.project,
        storylineId: storyId,
        orderedChapterIds: ids,
      ),
    );
  }

  void moveStep(String storyId, String chapterId, String stepId, int delta) {
    final chapter = controller.stories
        .where((story) => story.id == storyId)
        .firstOrNull
        ?.chapters
        .where((chapter) => chapter.id == chapterId)
        .firstOrNull;
    if (chapter == null) return;
    final ids = orderedStorySteps(chapter).map((step) => step.id).toList();
    final index = ids.indexOf(stepId);
    if (index < 0 ||
        index + delta < 0 ||
        index + delta >= ids.length ||
        delta == 0) {
      return;
    }
    ids.insert(index + delta, ids.removeAt(index));
    controller.apply(
      reorderStorylineSteps(
        controller.project,
        storylineId: storyId,
        chapterId: chapterId,
        orderedStepIds: ids,
      ),
    );
  }

  static StorylineProgressionConnectRequest connectionRequest({
    required StorylineProgressionNode source,
    required StorylineProgressionNode target,
    required int choice,
    StoryGraphOutcomeSource? outcome,
    required String Function() relationshipId,
  }) {
    if (source.kind == StorylineProgressionNodeKind.sceneOutcome) {
      return StorylineProgressionConnectRequest.outcomeEffect(
        storylineId: source.storylineId!,
        sceneLinkId: outcome!.link.id,
        outcomeLinkId: outcome.outcomeLinkId,
        outcomeId: outcome.pending ? outcome.outcomeId : null,
        effectType: choice == 0
            ? StorylineEffectType.activateStep
            : StorylineEffectType.completeStep,
        targetStepId: target.stepId!,
      );
    }
    if (source.kind == StorylineProgressionNodeKind.fact) {
      return StorylineProgressionConnectRequest.factCondition(
        storylineId: target.storylineId!,
        chapterId: target.chapterId!,
        stepId: target.stepId!,
        slot: choice < 2
            ? StorylineProgressionConditionSlot.entry
            : StorylineProgressionConditionSlot.completion,
        factId: source.canonicalId,
        expectedValue: choice.isEven,
      );
    }
    return StorylineProgressionConnectRequest.relationship(
      relationshipId: relationshipId(),
      kind: [
        StorylineRelationshipKind.requires,
        StorylineRelationshipKind.blocks,
        StorylineRelationshipKind.convergesTo,
      ][choice],
      sourceStorylineId: source.canonicalId,
      targetStorylineId: target.canonicalId,
    );
  }

  void expectOutcome({
    required String storyId,
    required String chapterId,
    required String stepId,
    required String outcomeId,
    required bool expected,
  }) {
    final latest = controller.stories
        .where((candidate) => candidate.id == storyId)
        .firstOrNull
        ?.chapters
        .where((chapter) => chapter.id == chapterId)
        .firstOrNull
        ?.steps
        .where((candidate) => candidate.id == stepId)
        .firstOrNull;
    if (latest == null) return;
    final next = expected
        ? {...latest.expectedOutcomeIds, outcomeId}.toList()
        : latest.expectedOutcomeIds
              .where((value) => value != outcomeId)
              .toList();
    if (next.length == latest.expectedOutcomeIds.length &&
        next.every(latest.expectedOutcomeIds.contains)) {
      return;
    }
    controller.apply(
      updateStorylineStep(
        controller.project,
        storylineId: storyId,
        chapterId: chapterId,
        stepId: stepId,
        step: latest.copyWith(expectedOutcomeIds: next),
      ),
    );
  }

  void patchScenarioLink(
    String storyId,
    String id,
    Map<String, dynamic> Function(StorylineSceneLink) fields,
  ) {
    final story = controller.stories
        .where((story) => story.id == storyId)
        .firstOrNull;
    final link = story?.sceneLinks.where((l) => l.id == id).firstOrNull;
    if (story == null || link == null) return;
    final next = StorylineSceneLink.fromJson({
      ...link.toJson(),
      ...fields(link),
    });
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(
          sceneLinks: [
            for (final candidate in story.sceneLinks)
              candidate.id == id ? next : candidate,
          ],
        ),
      ),
    );
  }

  void addScenarioLink(
    String storyId,
    String chapterId,
    String? stepId,
    String id,
  ) {
    final story = controller.stories
        .where((story) => story.id == storyId)
        .firstOrNull;
    final scenario = controller.project.scenarios
        .where((s) => s.id == id)
        .firstOrNull;
    if (story == null ||
        scenario == null ||
        !story.chapters.any(
          (c) =>
              c.id == chapterId &&
              (stepId == null || c.steps.any((s) => s.id == stepId)),
        )) {
      return;
    }
    final link = StorylineSceneLink(
      id: controller.narrative.identity('scenario-link'),
      chapterId: chapterId,
      stepId: stepId,
      label: scenario.name,
      state: StorylineSceneLinkState.linkedScenario,
      role: StorylineSceneLinkRole.primary,
      sceneRef: StorylineSceneRef(
        kind: StorylineSceneRefKind.scenario,
        targetId: id,
      ),
      order:
          story.sceneLinks.fold<int>(
            -1,
            (max, link) => link.order > max ? link.order : max,
          ) +
          1,
      expectedOutcomeIds: scenario.declaredOutcomes,
    );
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(sceneLinks: [...story.sceneLinks, link]),
      ),
    );
  }

  void removeScenarioLink(String storyId, String id) {
    final story = controller.stories
        .where((story) => story.id == storyId)
        .firstOrNull;
    final link = story?.sceneLinks.where((l) => l.id == id).firstOrNull;
    if (story == null ||
        link == null ||
        link.outcomeLinks.isNotEmpty ||
        storySceneLinkIsReferenced(story, id)) {
      return;
    }
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(
          sceneLinks: story.sceneLinks.where((l) => l.id != id).toList(),
        ),
      ),
    );
  }

  void metadata(
    String storyId,
    String? chapterId,
    String? stepId,
    String field,
    String value,
  ) {
    final story = controller.stories.where((s) => s.id == storyId).firstOrNull;
    if (story == null || (field == 'title' && value.trim().isEmpty)) return;
    final text = value.trim().isEmpty ? null : value;
    final status = StorylineStatus.values
        .where((s) => s.name == value)
        .firstOrNull;
    final chapter = story.chapters.where((c) => c.id == chapterId).firstOrNull;
    final step = chapter?.steps.where((s) => s.id == stepId).firstOrNull;
    if ((chapterId != null && chapter == null) ||
        (stepId != null && step == null)) {
      return;
    }
    if (step != null) {
      final next = switch (field) {
        'title' => step.copyWith(title: value.trim()),
        'description' => step.copyWith(description: text),
        'notes' => step.copyWith(authorNotes: text),
        'status' => step.copyWith(status: status),
        _ => step,
      };
      controller.apply(
        updateStorylineStep(
          controller.project,
          storylineId: storyId,
          chapterId: chapter!.id,
          stepId: step.id,
          step: next,
        ),
      );
    } else if (chapter != null) {
      final next = switch (field) {
        'title' => chapter.copyWith(title: value.trim()),
        'description' => chapter.copyWith(description: text),
        'notes' => chapter.copyWith(authorNotes: text),
        'status' => chapter.copyWith(status: status),
        _ => chapter,
      };
      controller.apply(
        updateStorylineChapter(
          controller.project,
          storylineId: storyId,
          chapterId: chapter.id,
          chapter: next,
        ),
      );
    } else {
      final next = switch (field) {
        'title' => story.copyWith(title: value.trim()),
        'description' => story.copyWith(description: text),
        'notes' => story.copyWith(authorNotes: text),
        'status' => story.copyWith(status: status ?? story.status),
        'type' => story.copyWith(
          type: StorylineType.values.firstWhere((v) => v.name == value),
        ),
        _ => story,
      };
      controller.apply(
        updateStoryline(
          controller.project,
          storylineId: storyId,
          storyline: next,
        ),
      );
    }
  }

  void addChapter(String storyId, String name) {
    final story = controller.stories.firstWhere((s) => s.id == storyId);
    final order =
        story.chapters.fold(-1, (n, c) => c.order > n ? c.order : n) + 1;
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(
          chapters: [
            ...story.chapters,
            StorylineChapter(
              id: controller.narrative.identity('chapitre'),
              title: name,
              order: order,
            ),
          ],
        ),
      ),
    );
  }

  void addStep(String storyId, String chapterId, String name) {
    final chapter = controller.stories
        .firstWhere((s) => s.id == storyId)
        .chapters
        .firstWhere((c) => c.id == chapterId);
    final order =
        chapter.steps.fold(-1, (n, s) => s.order > n ? s.order : n) + 1;
    controller.apply(
      updateStorylineChapter(
        controller.project,
        storylineId: storyId,
        chapterId: chapterId,
        chapter: chapter.copyWith(
          steps: [
            ...chapter.steps,
            StorylineStep(
              id: controller.narrative.identity('etape'),
              title: name,
              order: order,
            ),
          ],
        ),
      ),
    );
  }

  void remove(String storyId, String? chapterId, String? stepId) {
    final project = controller.project;
    controller.apply(
      stepId != null
          ? deleteStorylineStep(
              project,
              storylineId: storyId,
              chapterId: chapterId!,
              stepId: stepId,
            )
          : chapterId != null
          ? deleteStorylineChapter(
              project,
              storylineId: storyId,
              chapterId: chapterId,
            )
          : deleteStoryline(project, storylineId: storyId),
    );
  }

  void duplicate(String storyId, String? chapterId, String? stepId) {
    final project = controller.project;
    controller.apply(
      stepId != null
          ? duplicateStorylineStep(
              project,
              storylineId: storyId,
              chapterId: chapterId!,
              stepId: stepId,
              duplicateStepId: controller.narrative.identity('etape'),
            )
          : chapterId != null
          ? duplicateStorylineChapter(
              project,
              storylineId: storyId,
              chapterId: chapterId,
              duplicateChapterId: controller.narrative.identity('chapitre'),
            )
          : duplicateStoryline(
              project,
              storylineId: storyId,
              duplicateId: controller.narrative.identity('histoire'),
            ),
    );
  }
}

String storyConditionText(ScriptCondition? condition, ProjectManifest project) {
  if (condition == null) return 'Aucune condition définie';
  final flag = condition.params[ScriptConditionParams.flagName];
  final label =
      project.facts
          .where((f) => (f.legacyFlagName ?? f.id) == flag || f.id == flag)
          .firstOrNull
          ?.label ??
      'État introuvable conservé : $flag';
  return switch (condition.type) {
    ScriptConditionType.flagIsSet => '$label = Oui',
    ScriptConditionType.flagIsUnset => '$label = Non',
    ScriptConditionType.allOf =>
      'Toutes ces conditions : ${condition.children.map((c) => storyConditionText(c, project)).join(' ; ')}',
    ScriptConditionType.anyOf =>
      'Au moins une condition : ${condition.children.map((c) => storyConditionText(c, project)).join(' ; ')}',
    ScriptConditionType.not =>
      'Inverse de : ${condition.children.map((c) => storyConditionText(c, project)).join(' ; ')}',
    _ =>
      'Condition avancée conservée (${condition.type.name}). Son édition n’est pas proposée ici.',
  };
}

bool storySceneLinkIsReferenced(StorylineAsset story, String id) =>
    story.chapters.any(
      (c) =>
          c.directSceneLinkIds.contains(id) ||
          c.steps.any((s) => s.sceneLinkIds.contains(id)),
    );
