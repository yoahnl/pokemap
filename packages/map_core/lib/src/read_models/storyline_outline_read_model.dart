import '../authoring/storyline_milestone_operations.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/storyline_asset.dart';

enum StorylineMilestoneIssue {
  noBehaviour,
  noCompletionFact,
  completionFactShared,
  completionFactCanReset,
}

typedef StorylineOutlineScene = ({String id, String title});

final class StorylineOutline {
  StorylineOutline({
    required List<StorylineOutlineStoryline> storylines,
    required List<StorylineOutlineScene> scenesOutsideStorylines,
  }) : storylines = List.unmodifiable(storylines),
       scenesOutsideStorylines = List.unmodifiable(scenesOutsideStorylines);

  final List<StorylineOutlineStoryline> storylines;
  final List<StorylineOutlineScene> scenesOutsideStorylines;
}

final class StorylineOutlineStoryline {
  StorylineOutlineStoryline({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required List<StorylineOutlineChapter> chapters,
  }) : chapters = List.unmodifiable(chapters);

  final String id;
  final String title;
  final StorylineType type;
  final StorylineStatus status;
  final List<StorylineOutlineChapter> chapters;
}

final class StorylineOutlineChapter {
  StorylineOutlineChapter({
    required this.id,
    required this.title,
    required this.status,
    required List<StorylineOutlineMilestone> milestones,
  }) : milestones = List.unmodifiable(milestones);

  final String id;
  final String title;
  final StorylineStatus? status;
  final List<StorylineOutlineMilestone> milestones;
}

final class StorylineOutlineMilestone {
  StorylineOutlineMilestone({
    required this.id,
    required this.title,
    required this.status,
    required List<String> sceneIds,
    required List<String> mapIds,
    required this.completionFactId,
    required Set<StorylineMilestoneIssue> issues,
  }) : sceneIds = List.unmodifiable(sceneIds),
       mapIds = List.unmodifiable(mapIds),
       issues = Set.unmodifiable(issues);

  final String id;
  final String title;
  final StorylineStatus? status;
  final List<String> sceneIds;
  final List<String> mapIds;
  final String? completionFactId;
  final Set<StorylineMilestoneIssue> issues;
}

StorylineOutline projectStorylineOutline(
  ProjectManifest project, {
  List<StorylineOutlineScene>? scenes,
}) {
  final factIds = {for (final fact in project.facts) fact.id};
  final completionFacts = <String, int>{};
  for (final storyline in project.storylines) {
    for (final chapter in storyline.chapters) {
      for (final step in chapter.steps) {
        final factId = storylineMilestoneCompletionFactId(step);
        if (factId != null) {
          completionFacts[factId] = (completionFacts[factId] ?? 0) + 1;
        }
      }
    }
  }
  final resettable = _factsWrittenFalse(project);
  final sceneMaps = _sceneMapIds(project);
  final attached = <String>{};
  StorylineOutlineMilestone milestone(StorylineStep step) {
    attached.addAll(step.sceneLinkIds);
    final factId = storylineMilestoneCompletionFactId(step);
    return StorylineOutlineMilestone(
      id: step.id,
      title: step.title,
      status: step.status,
      sceneIds: step.sceneLinkIds,
      mapIds: ({
        for (final sceneId in step.sceneLinkIds) ...?sceneMaps[sceneId],
      }.toList()..sort()),
      completionFactId: factId,
      issues: {
        if (step.sceneLinkIds.isEmpty) StorylineMilestoneIssue.noBehaviour,
        if (factId == null || !factIds.contains(factId))
          StorylineMilestoneIssue.noCompletionFact,
        if (factId != null && completionFacts[factId]! > 1)
          StorylineMilestoneIssue.completionFactShared,
        if (factId != null && resettable.contains(factId))
          StorylineMilestoneIssue.completionFactCanReset,
      },
    );
  }

  final storylines = [
    for (final storyline in project.storylines)
      StorylineOutlineStoryline(
        id: storyline.id,
        title: storyline.title,
        type: storyline.type,
        status: storyline.status,
        chapters: [
          for (final chapter in [
            ...storyline.chapters,
          ]..sort((a, b) => a.order.compareTo(b.order)))
            StorylineOutlineChapter(
              id: chapter.id,
              title: chapter.title,
              status: chapter.status,
              milestones: [
                for (final step in [
                  ...chapter.steps,
                ]..sort((a, b) => a.order.compareTo(b.order)))
                  milestone(step),
              ],
            ),
        ],
      ),
  ];
  return StorylineOutline(
    storylines: storylines,
    scenesOutsideStorylines: [
      for (final scene
          in scenes ??
              [
                for (final scene in project.scenes)
                  (id: scene.id, title: scene.name),
              ])
        if (!attached.contains(scene.id)) scene,
    ],
  );
}

Set<String> _factsWrittenFalse(ProjectManifest project) => {
  for (final scene in project.scenes)
    for (final node in scene.graph.nodes)
      if (node.payload
          case SceneActionPayload(
            consequence: SceneSetFactConsequence(
              :final factId,
              :final narrativeValue,
            ),
          )
          when narrativeValue.kind == NarrativeValueKind.boolean &&
              !narrativeValue.boolValue)
        factId,
};

Map<String, Set<String>> _sceneMapIds(ProjectManifest project) {
  final result = <String, Set<String>>{};
  for (final record in project.eventRegistry?.records ?? const []) {
    final definition = record.definitionOrNull;
    final mapId = definition?.source.toJson()['mapId'];
    if (definition != null && mapId is String) {
      result.putIfAbsent(definition.sceneId, () => {}).add(mapId);
    }
  }
  return result;
}
