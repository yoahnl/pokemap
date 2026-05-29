import 'package:map_core/map_core.dart';

enum StorylineGraphNodeKind {
  storyline,
  chapter,
  step,
  emptyStepPlaceholder,
  sideQuest,
}

enum StorylineGraphEdgeKind {
  authorOrder,
  contains,
  sideQuestAttachment,
}

final class StorylineGraphViewModel {
  StorylineGraphViewModel._({
    required this.storylineId,
    required this.title,
    required this.type,
    required this.chapterCount,
    required this.stepCount,
    required this.sideQuestCountOutsideSelected,
    required this.sideQuestAttachments,
    required this.chapters,
    required this.nodes,
    required this.edges,
  });

  factory StorylineGraphViewModel.fromStoryline(
    StorylineAsset storyline, {
    List<StorylineAsset> storylines = const <StorylineAsset>[],
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
    final sideQuestAttachments = _attachedSideQuests(
      storyline,
      storylines,
      graphChapters,
    );
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
            subtitle: 'Structure uniquement',
            order: 0,
            chapterId: chapter.id,
          ),
        );
      } else {
        for (final step in chapter.steps) {
          final stepNodeId = StorylineGraphViewModel.stepNodeId(step.id);
          nodes.add(
            StorylineGraphNode(
              id: stepNodeId,
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
              toNodeId: stepNodeId,
              kind: StorylineGraphEdgeKind.contains,
            ),
          );
        }
      }
      for (final attachment in sideQuestAttachmentsForChapter(
        sideQuestAttachments,
        chapter.id,
      )) {
        nodes.add(
          StorylineGraphNode(
            id: sideQuestNodeId(attachment.sideQuestId),
            kind: StorylineGraphNodeKind.sideQuest,
            title: attachment.title,
            subtitle: attachment.anchorLabel,
            order: attachment.order,
            chapterId: chapter.id,
          ),
        );
        edges.add(
          StorylineGraphEdge(
            id: 'attachment:${attachment.relationshipId}',
            fromNodeId: attachment.anchorNodeId,
            toNodeId: sideQuestNodeId(attachment.sideQuestId),
            kind: StorylineGraphEdgeKind.sideQuestAttachment,
          ),
        );
      }
    }

    return StorylineGraphViewModel._(
      storylineId: storyline.id,
      title: storyline.title,
      type: storyline.type,
      chapterCount: graphChapters.length,
      stepCount: stepCount,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
      sideQuestAttachments: sideQuestAttachments,
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
  final List<StorylineGraphSideQuestAttachment> sideQuestAttachments;
  final List<StorylineGraphChapter> chapters;
  final List<StorylineGraphNode> nodes;
  final List<StorylineGraphEdge> edges;

  bool get isSideQuest => type == StorylineType.sideQuest;

  bool get hasChapters => chapters.isNotEmpty;

  bool get hasSideQuestNote =>
      type == StorylineType.main && sideQuestCountOutsideSelected > 0;

  int get unattachedSideQuestCount =>
      sideQuestCountOutsideSelected - sideQuestAttachments.length;

  static String storylineNodeId(String storylineId) => 'storyline:$storylineId';

  static String chapterNodeId(String chapterId) => 'chapter:$chapterId';

  static String stepNodeId(String stepId) => 'step:$stepId';

  static String emptyStepNodeId(String chapterId) => 'empty-step:$chapterId';

  static String sideQuestNodeId(String sideQuestId) => 'sideQuest:$sideQuestId';
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

final class StorylineGraphSideQuestAttachment {
  const StorylineGraphSideQuestAttachment({
    required this.sideQuestId,
    required this.relationshipId,
    required this.title,
    required this.chapterCount,
    required this.stepCount,
    required this.chapterId,
    required this.anchorKind,
    required this.anchorId,
    required this.anchorLabel,
    required this.anchorNodeId,
    required this.order,
  });

  final String sideQuestId;
  final String relationshipId;
  final String title;
  final int chapterCount;
  final int stepCount;
  final String chapterId;
  final StorylineAnchorKind anchorKind;
  final String anchorId;
  final String anchorLabel;
  final String anchorNodeId;
  final int order;
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

List<StorylineGraphSideQuestAttachment> sideQuestAttachmentsForChapter(
  List<StorylineGraphSideQuestAttachment> attachments,
  String chapterId,
) {
  return [
    for (final attachment in attachments)
      if (attachment.chapterId == chapterId) attachment,
  ];
}

List<StorylineGraphSideQuestAttachment> _attachedSideQuests(
  StorylineAsset storyline,
  List<StorylineAsset> storylines,
  List<StorylineGraphChapter> chapters,
) {
  if (storyline.type != StorylineType.main) {
    return const <StorylineGraphSideQuestAttachment>[];
  }
  final chapterById = {for (final chapter in chapters) chapter.id: chapter};
  final chapterOrder = {
    for (var index = 0; index < chapters.length; index += 1)
      chapters[index].id: index,
  };
  final stepById = <String, StorylineStep>{};
  final stepChapterById = <String, StorylineGraphChapter>{};
  for (final chapter in chapters) {
    for (final step in chapter.steps) {
      stepById[step.id] = step;
      stepChapterById[step.id] = chapter;
    }
  }

  final attachments = <StorylineGraphSideQuestAttachment>[];
  for (final sideQuest in storylines) {
    if (sideQuest.type != StorylineType.sideQuest) continue;
    for (final relationship in sideQuest.relationships) {
      if (!_isSideQuestAttachment(relationship, storyline.id)) continue;
      final anchor =
          relationship.availability?.startAnchor ?? relationship.anchor;
      if (anchor == null) continue;
      StorylineGraphSideQuestAttachment? attachment;
      if (anchor.kind == StorylineAnchorKind.chapter) {
        attachment = _chapterAttachment(
          sideQuest,
          relationship,
          anchor,
          chapterById[anchor.targetId],
          chapterOrder[anchor.targetId] ?? 0,
        );
      } else if (anchor.kind == StorylineAnchorKind.step) {
        final chapter = stepChapterById[anchor.targetId];
        attachment = _stepAttachment(
          sideQuest,
          relationship,
          anchor,
          stepById[anchor.targetId],
          chapter,
          chapterOrder[chapter?.id] ?? 0,
        );
      }
      if (attachment != null) {
        attachments.add(attachment);
        break;
      }
    }
  }
  attachments.sort((left, right) {
    final order = left.order.compareTo(right.order);
    if (order != 0) return order;
    final title = left.title.compareTo(right.title);
    if (title != 0) return title;
    return left.sideQuestId.compareTo(right.sideQuestId);
  });
  return attachments;
}

StorylineGraphSideQuestAttachment? _chapterAttachment(
  StorylineAsset sideQuest,
  StorylineRelationship relationship,
  StorylineAnchor anchor,
  StorylineGraphChapter? chapter,
  int order,
) {
  if (chapter == null) return null;
  return StorylineGraphSideQuestAttachment(
    sideQuestId: sideQuest.id,
    relationshipId: relationship.id,
    title: sideQuest.title,
    chapterCount: sideQuest.chapters.length,
    stepCount: _storylineStepCount(sideQuest),
    chapterId: chapter.id,
    anchorKind: anchor.kind,
    anchorId: anchor.targetId,
    anchorLabel: 'Chapitre · ${chapter.title}',
    anchorNodeId: StorylineGraphViewModel.chapterNodeId(chapter.id),
    order: order,
  );
}

StorylineGraphSideQuestAttachment? _stepAttachment(
  StorylineAsset sideQuest,
  StorylineRelationship relationship,
  StorylineAnchor anchor,
  StorylineStep? step,
  StorylineGraphChapter? chapter,
  int order,
) {
  if (step == null || chapter == null) return null;
  return StorylineGraphSideQuestAttachment(
    sideQuestId: sideQuest.id,
    relationshipId: relationship.id,
    title: sideQuest.title,
    chapterCount: sideQuest.chapters.length,
    stepCount: _storylineStepCount(sideQuest),
    chapterId: chapter.id,
    anchorKind: anchor.kind,
    anchorId: anchor.targetId,
    anchorLabel: 'Étape · ${step.title}',
    anchorNodeId: StorylineGraphViewModel.stepNodeId(step.id),
    order: order,
  );
}

bool _isSideQuestAttachment(
  StorylineRelationship relationship,
  String mainStorylineId,
) {
  return relationship.targetStorylineId == mainStorylineId &&
      (relationship.kind ==
              StorylineRelationshipKind.sideQuestAvailableDuring ||
          relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy);
}

int _storylineStepCount(StorylineAsset storyline) {
  return storyline.chapters.fold<int>(
    0,
    (total, chapter) => total + chapter.steps.length,
  );
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
