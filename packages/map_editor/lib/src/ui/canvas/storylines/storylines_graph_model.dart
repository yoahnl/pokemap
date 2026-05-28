import 'package:map_core/map_core.dart';

enum StorylineGraphNodeKind {
  storyline,
  chapter,
  step,
  emptyStepPlaceholder,
}

enum StorylineGraphEdgeKind {
  authorOrder,
  contains,
}

final class StorylineGraphViewModel {
  StorylineGraphViewModel._({
    required this.storylineId,
    required this.title,
    required this.type,
    required this.chapterCount,
    required this.stepCount,
    required this.sideQuestCountOutsideSelected,
    required this.chapters,
    required this.nodes,
    required this.edges,
  });

  factory StorylineGraphViewModel.fromStoryline(
    StorylineAsset storyline, {
    int sideQuestCountOutsideSelected = 0,
  }) {
    final chapters = [...storyline.chapters]
      ..sort(_compareChaptersByAuthorOrder);
    final graphChapters = [
      for (final chapter in chapters)
        StorylineGraphChapter(
          id: chapter.id,
          title: chapter.title,
          description: chapter.description,
          order: chapter.order,
          steps: ([...chapter.steps]..sort(_compareStepsByAuthorOrder)),
        ),
    ];
    final stepCount = graphChapters.fold<int>(
      0,
      (total, chapter) => total + chapter.steps.length,
    );

    final nodes = <StorylineGraphNode>[
      StorylineGraphNode(
        id: storylineNodeId(storyline.id),
        kind: StorylineGraphNodeKind.storyline,
        title: storyline.title,
        subtitle: _storylineTypeLabel(storyline.type),
        order: 0,
      ),
    ];
    final edges = <StorylineGraphEdge>[];
    String? previousChapterNodeId;
    for (final chapter in graphChapters) {
      final chapterNodeId = StorylineGraphViewModel.chapterNodeId(chapter.id);
      nodes.add(
        StorylineGraphNode(
          id: chapterNodeId,
          kind: StorylineGraphNodeKind.chapter,
          title: chapter.title,
          subtitle: _formatCount(chapter.steps.length, 'étape', 'étapes'),
          order: chapter.order,
          chapterId: chapter.id,
        ),
      );
      if (previousChapterNodeId == null) {
        edges.add(
          StorylineGraphEdge(
            id: 'edge:${storyline.id}:${chapter.id}',
            fromNodeId: storylineNodeId(storyline.id),
            toNodeId: chapterNodeId,
            kind: StorylineGraphEdgeKind.authorOrder,
          ),
        );
      } else {
        edges.add(
          StorylineGraphEdge(
            id: 'edge:$previousChapterNodeId:$chapterNodeId',
            fromNodeId: previousChapterNodeId,
            toNodeId: chapterNodeId,
            kind: StorylineGraphEdgeKind.authorOrder,
          ),
        );
      }
      previousChapterNodeId = chapterNodeId;

      if (chapter.steps.isEmpty) {
        nodes.add(
          StorylineGraphNode(
            id: emptyStepNodeId(chapter.id),
            kind: StorylineGraphNodeKind.emptyStepPlaceholder,
            title: 'Aucune étape narrative',
            subtitle: 'Ajoutez une étape dans Structure.',
            order: chapter.order,
            chapterId: chapter.id,
          ),
        );
      } else {
        for (final step in chapter.steps) {
          nodes.add(
            StorylineGraphNode(
              id: stepNodeId(step.id),
              kind: StorylineGraphNodeKind.step,
              title: step.title,
              subtitle: _sceneLinkLabel(step.sceneLinkIds.length),
              order: step.order,
              chapterId: chapter.id,
              stepId: step.id,
            ),
          );
          edges.add(
            StorylineGraphEdge(
              id: 'contains:${chapter.id}:${step.id}',
              fromNodeId: chapterNodeId,
              toNodeId: stepNodeId(step.id),
              kind: StorylineGraphEdgeKind.contains,
            ),
          );
        }
      }
    }

    return StorylineGraphViewModel._(
      storylineId: storyline.id,
      title: storyline.title,
      type: storyline.type,
      chapterCount: graphChapters.length,
      stepCount: stepCount,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
      chapters: graphChapters,
      nodes: nodes,
      edges: edges,
    );
  }

  final String storylineId;
  final String title;
  final StorylineType type;
  final int chapterCount;
  final int stepCount;
  final int sideQuestCountOutsideSelected;
  final List<StorylineGraphChapter> chapters;
  final List<StorylineGraphNode> nodes;
  final List<StorylineGraphEdge> edges;

  bool get isSideQuest => type == StorylineType.sideQuest;

  bool get hasChapters => chapters.isNotEmpty;

  bool get hasSideQuestNote =>
      type == StorylineType.main && sideQuestCountOutsideSelected > 0;

  static String storylineNodeId(String storylineId) => 'storyline:$storylineId';

  static String chapterNodeId(String chapterId) => 'chapter:$chapterId';

  static String stepNodeId(String stepId) => 'step:$stepId';

  static String emptyStepNodeId(String chapterId) => 'empty-step:$chapterId';
}

final class StorylineGraphChapter {
  const StorylineGraphChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.steps,
  });

  final String id;
  final String title;
  final String? description;
  final int order;
  final List<StorylineStep> steps;
}

final class StorylineGraphNode {
  const StorylineGraphNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.order,
    this.chapterId,
    this.stepId,
  });

  final String id;
  final StorylineGraphNodeKind kind;
  final String title;
  final String subtitle;
  final int order;
  final String? chapterId;
  final String? stepId;
}

final class StorylineGraphEdge {
  const StorylineGraphEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.kind,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final StorylineGraphEdgeKind kind;
}

int _compareChaptersByAuthorOrder(
  StorylineChapter left,
  StorylineChapter right,
) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final title = left.title.compareTo(right.title);
  if (title != 0) return title;
  return left.id.compareTo(right.id);
}

int _compareStepsByAuthorOrder(StorylineStep left, StorylineStep right) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final title = left.title.compareTo(right.title);
  if (title != 0) return title;
  return left.id.compareTo(right.id);
}

String _storylineTypeLabel(StorylineType type) {
  return switch (type) {
    StorylineType.main => 'Histoire principale',
    StorylineType.sideQuest => 'Quête annexe',
    StorylineType.tutorial => 'Tutoriel',
    StorylineType.epilogue => 'Épilogue',
    StorylineType.episode => 'Épisode',
    StorylineType.postGame => 'Post-game',
    StorylineType.hiddenEvent => 'Événement caché',
  };
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

String _sceneLinkLabel(int count) {
  if (count == 0) return 'Aucune scène liée';
  return _formatCount(count, 'scène liée', 'scènes liées');
}
