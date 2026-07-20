import 'package:map_core/map_core.dart';

enum StorylineGraphNodeKind {
  storyline,
  chapter,
  step,
  sideQuest,
  sceneOutcome,
  fact,
  condition,
}

enum StorylineGraphEdgeKind {
  authorOrder,
  contains,
  sideQuestAttachment,
  outcomeActivatesStep,
  outcomeCompletesStep,
  requires,
  blocks,
  convergesTo,
  entryCondition,
  completionCondition,
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
    required this.projection,
    required this.nodes,
    required this.edges,
  });

  factory StorylineGraphViewModel.fromStoryline(
    StorylineAsset storyline, {
    List<StorylineAsset> storylines = const <StorylineAsset>[],
    int sideQuestCountOutsideSelected = 0,
  }) {
    final assets = storylines.any((asset) => asset.id == storyline.id)
        ? storylines
        : <StorylineAsset>[storyline, ...storylines];
    return StorylineGraphViewModel.fromProject(
      ProjectManifest(
        name: 'Storyline graph projection',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        storylines: assets,
      ),
      storylineId: storyline.id,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
    );
  }

  factory StorylineGraphViewModel.fromProject(
    ProjectManifest project, {
    required String storylineId,
    int sideQuestCountOutsideSelected = 0,
  }) {
    final storyline = project.storylines.singleWhere(
      (asset) => asset.id == storylineId,
    );
    final storylines = project.storylines;
    final projection = buildStorylineProgressionProjection(
      project: project,
      storylineId: storyline.id,
    );
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

    final chapterById = {
      for (final chapter in graphChapters) chapter.id: chapter,
    };
    final stepById = {
      for (final chapter in graphChapters)
        for (final step in chapter.steps) step.id: step,
    };
    final storylineById = {
      for (final asset in storylines) asset.id: asset,
    };
    final nodes = <StorylineGraphNode>[
      for (final node in projection.nodes)
        StorylineGraphNode(
          id: node.id,
          kind: _graphNodeKind(node, storylineById, storyline.id),
          title: node.label,
          subtitle: _graphNodeSubtitle(
            node,
            storylineById,
            stepById,
          ),
          order: node.kind == StorylineProgressionNodeKind.chapter
              ? chapterById[node.canonicalId]?.order ?? 0
              : node.kind == StorylineProgressionNodeKind.step
                  ? stepById[node.canonicalId]?.order ?? 0
                  : 0,
          chapterId: node.chapterId,
          stepId: node.stepId,
          canonicalId: node.canonicalId,
          isMissing: node.isMissing,
        ),
    ];
    final edges = <StorylineGraphEdge>[
      for (final edge in projection.edges)
        StorylineGraphEdge(
          id: edge.id,
          fromNodeId: edge.fromNodeId,
          toNodeId: edge.toNodeId,
          kind: _graphEdgeKind(edge.kind),
          semanticLabel: _edgeSemanticLabel(edge.kind),
          editability: edge.editability,
          readOnlyReason: edge.readOnlyReason,
          source: edge.source,
        ),
    ];

    return StorylineGraphViewModel._(
      storylineId: storyline.id,
      title: storyline.title,
      type: storyline.type,
      chapterCount: graphChapters.length,
      stepCount: stepCount,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
      sideQuestAttachments: sideQuestAttachments,
      chapters: graphChapters,
      projection: projection,
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
  final StorylineProgressionProjection projection;
  final List<StorylineGraphNode> nodes;
  final List<StorylineGraphEdge> edges;

  List<StorylineGraphEdge> get semanticEdges => List.unmodifiable(
        edges.where(
          (edge) =>
              edge.kind != StorylineGraphEdgeKind.contains &&
              edge.kind != StorylineGraphEdgeKind.authorOrder,
        ),
      );

  bool get isSideQuest => type == StorylineType.sideQuest;

  bool get hasChapters => chapters.isNotEmpty;

  bool get hasSideQuestNote =>
      type == StorylineType.main && sideQuestCountOutsideSelected > 0;

  int get unattachedSideQuestCount =>
      sideQuestCountOutsideSelected - sideQuestAttachments.length;

  static String storylineNodeId(String storylineId) => 'storyline:$storylineId';

  static String chapterNodeId(String chapterId) => 'chapter:$chapterId';

  static String stepNodeId(String stepId) => 'step:$stepId';

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
    required this.canonicalId,
    this.isMissing = false,
  });

  final String id;
  final StorylineGraphNodeKind kind;
  final String title;
  final String subtitle;
  final int order;
  final String? chapterId;
  final String? stepId;
  final String canonicalId;
  final bool isMissing;
}

final class StorylineGraphEdge {
  const StorylineGraphEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.kind,
    required this.semanticLabel,
    required this.editability,
    required this.source,
    this.readOnlyReason,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final StorylineGraphEdgeKind kind;
  final String semanticLabel;
  final StorylineProgressionEdgeEditability editability;
  final String? readOnlyReason;
  final StorylineProgressionSource source;

  bool get isReversible =>
      editability == StorylineProgressionEdgeEditability.reversible;
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

StorylineGraphNodeKind _graphNodeKind(
  StorylineProgressionNode node,
  Map<String, StorylineAsset> storylineById,
  String selectedStorylineId,
) {
  return switch (node.kind) {
    StorylineProgressionNodeKind.storyline =>
      node.canonicalId != selectedStorylineId &&
              storylineById[node.canonicalId]?.type == StorylineType.sideQuest
          ? StorylineGraphNodeKind.sideQuest
          : StorylineGraphNodeKind.storyline,
    StorylineProgressionNodeKind.chapter => StorylineGraphNodeKind.chapter,
    StorylineProgressionNodeKind.step => StorylineGraphNodeKind.step,
    StorylineProgressionNodeKind.sceneOutcome =>
      StorylineGraphNodeKind.sceneOutcome,
    StorylineProgressionNodeKind.fact => StorylineGraphNodeKind.fact,
    StorylineProgressionNodeKind.condition => StorylineGraphNodeKind.condition,
  };
}

String _graphNodeSubtitle(
  StorylineProgressionNode node,
  Map<String, StorylineAsset> storylineById,
  Map<String, StorylineStep> stepById,
) {
  if (node.isMissing) return 'Référence introuvable';
  return switch (node.kind) {
    StorylineProgressionNodeKind.storyline => _storylineTypeLabel(
        storylineById[node.canonicalId]?.type ?? StorylineType.main,
      ),
    StorylineProgressionNodeKind.chapter => 'Chapitre canonique',
    StorylineProgressionNodeKind.step =>
      _sceneLinkLabel(stepById[node.canonicalId]?.sceneLinkIds.length ?? 0),
    StorylineProgressionNodeKind.sceneOutcome => 'Résultat de Scene',
    StorylineProgressionNodeKind.fact => 'Fact du projet',
    StorylineProgressionNodeKind.condition => 'Condition composée',
  };
}

StorylineGraphEdgeKind _graphEdgeKind(StorylineProgressionEdgeKind kind) {
  return switch (kind) {
    StorylineProgressionEdgeKind.contains => StorylineGraphEdgeKind.contains,
    StorylineProgressionEdgeKind.authorOrder =>
      StorylineGraphEdgeKind.authorOrder,
    StorylineProgressionEdgeKind.outcomeActivatesStep =>
      StorylineGraphEdgeKind.outcomeActivatesStep,
    StorylineProgressionEdgeKind.outcomeCompletesStep =>
      StorylineGraphEdgeKind.outcomeCompletesStep,
    StorylineProgressionEdgeKind.requires => StorylineGraphEdgeKind.requires,
    StorylineProgressionEdgeKind.blocks => StorylineGraphEdgeKind.blocks,
    StorylineProgressionEdgeKind.convergesTo =>
      StorylineGraphEdgeKind.convergesTo,
    StorylineProgressionEdgeKind.sideQuestAvailability =>
      StorylineGraphEdgeKind.sideQuestAttachment,
    StorylineProgressionEdgeKind.entryCondition =>
      StorylineGraphEdgeKind.entryCondition,
    StorylineProgressionEdgeKind.completionCondition =>
      StorylineGraphEdgeKind.completionCondition,
  };
}

String _edgeSemanticLabel(StorylineProgressionEdgeKind kind) {
  return switch (kind) {
    StorylineProgressionEdgeKind.contains => 'Contient',
    StorylineProgressionEdgeKind.authorOrder => 'Ordre auteur',
    StorylineProgressionEdgeKind.outcomeActivatesStep => 'Active l’étape',
    StorylineProgressionEdgeKind.outcomeCompletesStep => 'Complète l’étape',
    StorylineProgressionEdgeKind.requires => 'Requiert',
    StorylineProgressionEdgeKind.blocks => 'Bloque',
    StorylineProgressionEdgeKind.convergesTo => 'Converge vers',
    StorylineProgressionEdgeKind.sideQuestAvailability =>
      'Disponibilité de quête annexe',
    StorylineProgressionEdgeKind.entryCondition => 'Condition d’entrée',
    StorylineProgressionEdgeKind.completionCondition =>
      'Condition de complétion',
  };
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
