import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'storylines_graph_model.dart';
import 'storylines_graph_painter.dart';

class StorylinesGraphView extends StatelessWidget {
  const StorylinesGraphView({
    super.key,
    required this.storyline,
    required this.storylines,
    required this.sideQuestCountOutsideSelected,
  });

  final StorylineAsset storyline;
  final List<StorylineAsset> storylines;
  final int sideQuestCountOutsideSelected;

  @override
  Widget build(BuildContext context) {
    final sideQuestAttached = storyline.type == StorylineType.sideQuest &&
        storyline.relationships.any(_isSideQuestAttachment);
    final model = StorylineGraphViewModel.fromStoryline(
      storyline,
      storylines: storylines,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
    );
    final colors = context.pokeMapColors;
    return Column(
      key: const ValueKey('storylines-graph-from-asset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.arrow_branch,
              tone: PokeMapTone.narrative,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Graph de compréhension',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vue read-only générée depuis les StorylineAsset et leurs relations explicites.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _StorylinesGraphBadge(label: 'Read-only'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _StorylinesGraphBadge(
              label: 'Lignes = ordre auteur',
            ),
            if (model.isSideQuest)
              _StorylinesGraphBadge(
                label: sideQuestAttached
                    ? 'Quête annexe attachée'
                    : 'Quête annexe indépendante',
              ),
            if (model.isSideQuest)
              _StorylinesGraphBadge(
                label: sideQuestAttached
                    ? 'Relation principale explicite'
                    : 'Non reliée au graph principal pour l’instant',
              ),
            if (model.hasSideQuestNote && model.sideQuestAttachments.isEmpty)
              _StorylinesGraphBadge(
                label:
                    'Quêtes annexes créées : ${model.sideQuestCountOutsideSelected} — attachement explicite requis',
              ),
            if (model.sideQuestAttachments.isNotEmpty)
              _StorylinesGraphBadge(
                label:
                    'Quêtes annexes attachées : ${model.sideQuestAttachments.length}',
              ),
            if (model.unattachedSideQuestCount > 0 &&
                model.sideQuestAttachments.isNotEmpty)
              _StorylinesGraphBadge(
                label:
                    '${model.unattachedSideQuestCount} quête(s) annexe(s) non attachée(s)',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _StorylineGraphCanvas(model: model)),
      ],
    );
  }
}

class _StorylineGraphCanvas extends StatelessWidget {
  const _StorylineGraphCanvas({required this.model});

  static const double _rootWidth = 240;
  static const double _rootHeight = 172;
  static const double _chapterWidth = 276;
  static const double _chapterGap = 46;
  static const double _rootToChapterGap = 76;
  static const double _leftPadding = 28;
  static const double _topPadding = 24;
  static const double _stepHeight = 54;

  final StorylineGraphViewModel model;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxItemCount = model.chapters.fold<int>(
          0,
          (current, chapter) => math.max(
            current,
            _graphItemCountForChapter(chapter),
          ),
        );
        final chapterHeight = _chapterHeight(maxItemCount);
        final contentWidth = _leftPadding +
            _rootWidth +
            _rootToChapterGap +
            math.max(1, model.chapters.length) * (_chapterWidth + _chapterGap) +
            _leftPadding;
        final contentHeight = math.max(
          _topPadding + chapterHeight + 60,
          _topPadding + _rootHeight + 160,
        );
        final canvasWidth = math
            .max(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 900,
              contentWidth,
            )
            .toDouble();
        final canvasHeight = math
            .max(
              constraints.maxHeight.isFinite ? constraints.maxHeight : 520,
              contentHeight,
            )
            .toDouble();
        final rootRect = Rect.fromLTWH(
          _leftPadding,
          math.max(_topPadding, (canvasHeight - _rootHeight) / 2),
          _rootWidth,
          _rootHeight,
        );
        final chapterRects = <String, Rect>{};
        for (var index = 0; index < model.chapters.length; index += 1) {
          final chapter = model.chapters[index];
          chapterRects[chapter.id] = Rect.fromLTWH(
            _leftPadding +
                _rootWidth +
                _rootToChapterGap +
                index * (_chapterWidth + _chapterGap),
            _topPadding,
            _chapterWidth,
            _chapterHeight(_graphItemCountForChapter(chapter)),
          );
        }
        final paintEdges = _paintEdges(rootRect, chapterRects);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  key: const ValueKey('storylines-graph-canvas'),
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: StorylinesGraphPainter(
                            edges: paintEdges,
                            gridColor: colors.borderSubtle,
                            authorOrderColor: colors.brandPrimaryBorder,
                            containsColor: colors.controlBorder,
                          ),
                        ),
                      ),
                      _GraphNodePosition(
                        rect: rootRect,
                        child: _GraphRootNode(model: model),
                      ),
                      for (final chapter in model.chapters)
                        _GraphNodePosition(
                          rect: chapterRects[chapter.id]!,
                          child: _GraphChapterNode(
                            chapter: chapter,
                            attachments: sideQuestAttachmentsForChapter(
                              model.sideQuestAttachments,
                              chapter.id,
                            ),
                          ),
                        ),
                      for (final marker in _edgeMarkers(rootRect, chapterRects))
                        Positioned(
                          key: ValueKey(marker.key),
                          left: marker.position.dx,
                          top: marker.position.dy,
                          child: const SizedBox(width: 1, height: 1),
                        ),
                      if (!model.hasChapters)
                        Positioned(
                          left: rootRect.right + 46,
                          top: rootRect.top + 18,
                          width: 320,
                          child: const _GraphEmptyHint(
                            key: ValueKey(
                              'storylines-graph-empty-storyline-message',
                            ),
                            title: 'Ajoutez un chapitre dans Structure',
                            body:
                                'Le graph se construit uniquement depuis les données auteur existantes.',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _graphItemCountForChapter(StorylineGraphChapter chapter) {
    final attachmentCount = sideQuestAttachmentsForChapter(
      model.sideQuestAttachments,
      chapter.id,
    ).length;
    return math.max(1, chapter.steps.length) + attachmentCount;
  }

  double _chapterHeight(int itemCount) {
    final effectiveItems = math.max(1, itemCount);
    return 142 + effectiveItems * (_stepHeight + 8);
  }

  List<StorylineGraphPaintEdge> _paintEdges(
    Rect rootRect,
    Map<String, Rect> chapterRects,
  ) {
    if (model.chapters.isEmpty) return const [];
    final edges = <StorylineGraphPaintEdge>[];
    final firstChapter = model.chapters.first;
    edges.add(
      StorylineGraphPaintEdge(
        from: Offset(rootRect.right, rootRect.center.dy),
        to: Offset(
          chapterRects[firstChapter.id]!.left,
          chapterRects[firstChapter.id]!.center.dy,
        ),
        kind: StorylineGraphEdgeKind.authorOrder,
      ),
    );
    for (var index = 0; index < model.chapters.length - 1; index += 1) {
      final current = chapterRects[model.chapters[index].id]!;
      final next = chapterRects[model.chapters[index + 1].id]!;
      edges.add(
        StorylineGraphPaintEdge(
          from: Offset(current.right, current.center.dy),
          to: Offset(next.left, next.center.dy),
          kind: StorylineGraphEdgeKind.authorOrder,
        ),
      );
    }
    return edges;
  }

  List<_EdgeMarker> _edgeMarkers(
    Rect rootRect,
    Map<String, Rect> chapterRects,
  ) {
    if (model.chapters.isEmpty) return const [];
    final markers = <_EdgeMarker>[
      _EdgeMarker(
        key: 'storylines-graph-edge-root-${model.chapters.first.id}',
        position: Offset(
          (rootRect.right + chapterRects[model.chapters.first.id]!.left) / 2,
          (rootRect.center.dy +
                  chapterRects[model.chapters.first.id]!.center.dy) /
              2,
        ),
      ),
    ];
    for (var index = 0; index < model.chapters.length - 1; index += 1) {
      final current = model.chapters[index];
      final next = model.chapters[index + 1];
      final currentRect = chapterRects[current.id]!;
      final nextRect = chapterRects[next.id]!;
      markers.add(
        _EdgeMarker(
          key: 'storylines-graph-edge-${current.id}-${next.id}',
          position: Offset(
            (currentRect.right + nextRect.left) / 2,
            (currentRect.center.dy + nextRect.center.dy) / 2,
          ),
        ),
      );
    }
    for (final attachment in model.sideQuestAttachments) {
      final chapterRect = chapterRects[attachment.chapterId];
      if (chapterRect == null) continue;
      markers.add(
        _EdgeMarker(
          key: 'storylines-graph-edge-sidequest-${attachment.relationshipId}',
          position: Offset(chapterRect.right - 18, chapterRect.bottom - 18),
        ),
      );
    }
    return markers;
  }
}

class _GraphNodePosition extends StatelessWidget {
  const _GraphNodePosition({
    required this.rect,
    required this.child,
  });

  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );
  }
}

class _GraphRootNode extends StatelessWidget {
  const _GraphRootNode({required this.model});

  final StorylineGraphViewModel model;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: ValueKey('storylines-graph-node-storyline-${model.storylineId}'),
      child: PokeMapCard(
        selected: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _StorylinesGraphBadge(label: _storylineTypeLabel(model.type)),
                const _StorylinesGraphBadge(label: 'Brouillon'),
              ],
            ),
            const Spacer(),
            Text(
              '${_formatCount(model.chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(model.stepCount, 'étape', 'étapes')}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphChapterNode extends StatelessWidget {
  const _GraphChapterNode({
    required this.chapter,
    required this.attachments,
  });

  final StorylineGraphChapter chapter;
  final List<StorylineGraphSideQuestAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final items = <Widget>[
      if (chapter.steps.isEmpty)
        _GraphEmptyHint(
          key: ValueKey('storylines-graph-empty-steps-${chapter.id}'),
          title: 'Aucune étape narrative.',
          body: 'Les étapes restent créées depuis Structure.',
        )
      else
        for (final step in chapter.steps) _GraphStepChip(step: step),
      if (attachments.isNotEmpty)
        _GraphSectionCaption(
          key: ValueKey('storylines-graph-sidequest-caption-${chapter.id}'),
          label: 'Quêtes annexes disponibles ici',
        ),
      for (final attachment in attachments)
        _GraphSideQuestChip(attachment: attachment),
    ];
    return KeyedSubtree(
      key: ValueKey('storylines-graph-node-chapter-${chapter.id}'),
      child: PokeMapCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ordre ${chapter.order} · ${_formatCount(chapter.steps.length, 'étape', 'étapes')}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (chapter.description != null) ...[
              const SizedBox(height: 6),
              Text(
                chapter.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => items[index],
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphStepChip extends StatelessWidget {
  const _GraphStepChip({required this.step});

  final StorylineStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key: ValueKey('storylines-graph-node-step-${step.id}'),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _sceneLinkLabel(step.sceneLinkIds.length),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphSideQuestChip extends StatelessWidget {
  const _GraphSideQuestChip({required this.attachment});

  final StorylineGraphSideQuestAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key:
          ValueKey('storylines-graph-node-sidequest-${attachment.sideQuestId}'),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.brandPrimaryBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.link,
              tone: PokeMapTone.narrative,
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Relation explicite · ${attachment.anchorLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphSectionCaption extends StatelessWidget {
  const _GraphSectionCaption({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GraphEmptyHint extends StatelessWidget {
  const _GraphEmptyHint({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeMarker {
  const _EdgeMarker({
    required this.key,
    required this.position,
  });

  final String key;
  final Offset position;
}

class _StorylinesGraphBadge extends StatelessWidget {
  const _StorylinesGraphBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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

bool _isSideQuestAttachment(StorylineRelationship relationship) {
  return relationship.kind ==
          StorylineRelationshipKind.sideQuestAvailableDuring ||
      relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy;
}
