import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'storylines_graph_model.dart';
import 'storylines_graph_painter.dart';

const int _maxVisibleStepsPerChapter = 3;

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
    return Column(
      key: const ValueKey('storylines-graph-from-asset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StorylinesGraphToolbar(
          model: model,
          sideQuestAttached: sideQuestAttached,
        ),
        const SizedBox(height: 6),
        Expanded(child: _StorylineGraphCanvas(model: model)),
      ],
    );
  }
}

class _StorylinesGraphToolbar extends StatelessWidget {
  const _StorylinesGraphToolbar({
    required this.model,
    required this.sideQuestAttached,
  });

  final StorylineGraphViewModel model;
  final bool sideQuestAttached;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key: const ValueKey('storylines-graph-toolbar'),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.arrow_branch,
                  tone: PokeMapTone.narrative,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Text(
                  'Graph read-only',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                const _StorylinesGraphBadge(label: 'Read-only'),
                const Spacer(),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _GraphStatusBadges(
                      model: model,
                      sideQuestAttached: sideQuestAttached,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const _StorylinesGraphLegend(compact: true),
          ],
        ),
      ),
    );
  }
}

class _StorylineGraphCanvas extends StatelessWidget {
  const _StorylineGraphCanvas({required this.model});

  static const double _rootWidth = 220;
  static const double _rootHeight = 188;
  static const double _chapterWidth = 270;
  static const double _chapterGap = 36;
  static const double _sideQuestWidth = 224;
  static const double _sideQuestHeight = 112;
  static const double _rootToChapterGap = 56;
  static const double _leftPadding = 28;
  static const double _topPadding = 22;
  static const double _sideQuestBandHeight = 132;
  static const double _sideQuestGap = 24;
  static const double _stepHeight = 42;

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
        final sideQuestRowsAbove = _sideQuestRowsAbove();
        final sideQuestBandAbove = sideQuestRowsAbove == 0
            ? 0.0
            : sideQuestRowsAbove * (_sideQuestHeight + _sideQuestGap);
        final chapterTop = _topPadding + sideQuestBandAbove;
        final sideQuestRowsBelow = _sideQuestRowsBelow();
        final sideQuestBandBelow = sideQuestRowsBelow == 0
            ? 0.0
            : _sideQuestGap +
                sideQuestRowsBelow * (_sideQuestHeight + _sideQuestGap);
        final contentWidth = _leftPadding +
            _rootWidth +
            _rootToChapterGap +
            math.max(1, model.chapters.length) * (_chapterWidth + _chapterGap) +
            _leftPadding;
        final contentHeight = math.max(
          chapterTop + chapterHeight + sideQuestBandBelow + _topPadding,
          _topPadding + _sideQuestBandHeight + _rootHeight + 220,
        );
        final canvasWidth = math
            .max(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 900,
              contentWidth,
            )
            .toDouble();
        final canvasHeight = math
            .max(
              constraints.maxHeight.isFinite ? constraints.maxHeight : 640,
              contentHeight,
            )
            .clamp(640.0, double.infinity)
            .toDouble();
        final rootRect = Rect.fromLTWH(
          _leftPadding,
          chapterTop + (chapterHeight - _rootHeight) / 2,
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
            chapterTop,
            _chapterWidth,
            _chapterHeight(_graphItemCountForChapter(chapter)),
          );
        }
        final sideQuestRects = _sideQuestRects(chapterRects);
        final paintEdges = _paintEdges(rootRect, chapterRects, sideQuestRects);
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
                            sideQuestAvailabilityColor: colors.warning,
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
                      for (final attachment in model.sideQuestAttachments)
                        if (sideQuestRects[attachment.relationshipId] != null)
                          _GraphNodePosition(
                            rect: sideQuestRects[attachment.relationshipId]!,
                            child: _GraphSideQuestNode(
                              attachment: attachment,
                            ),
                          ),
                      for (final marker in _edgeMarkers(
                        rootRect,
                        chapterRects,
                        sideQuestRects,
                      ))
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
                                'Le graph restera vide tant qu’aucun chapitre réel n’existe.',
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
    if (chapter.steps.isEmpty) return 1;
    return math.min(chapter.steps.length, _maxVisibleStepsPerChapter) +
        (chapter.steps.length > _maxVisibleStepsPerChapter ? 1 : 0);
  }

  double _chapterHeight(int itemCount) {
    final effectiveItems = math.max(1, itemCount);
    return 144 + effectiveItems * (_stepHeight + 8);
  }

  int _sideQuestRowsBelow() {
    var maxRows = 0;
    for (final chapter in model.chapters) {
      final count = sideQuestAttachmentsForChapter(
        model.sideQuestAttachments,
        chapter.id,
      ).length;
      maxRows = math.max(maxRows, count ~/ 2);
    }
    return maxRows;
  }

  int _sideQuestRowsAbove() {
    var maxRows = 0;
    for (final chapter in model.chapters) {
      final count = sideQuestAttachmentsForChapter(
        model.sideQuestAttachments,
        chapter.id,
      ).length;
      maxRows = math.max(maxRows, (count + 1) ~/ 2);
    }
    return maxRows;
  }

  Map<String, Rect> _sideQuestRects(Map<String, Rect> chapterRects) {
    final rects = <String, Rect>{};
    for (final chapter in model.chapters) {
      final chapterRect = chapterRects[chapter.id];
      if (chapterRect == null) continue;
      final attachments = sideQuestAttachmentsForChapter(
        model.sideQuestAttachments,
        chapter.id,
      );
      for (var index = 0; index < attachments.length; index += 1) {
        final attachment = attachments[index];
        final row = index ~/ 2;
        final above = index.isEven;
        final xOffset = index.isEven ? -18.0 : 18.0;
        final left = chapterRect.center.dx - _sideQuestWidth / 2 + xOffset;
        final top = above
            ? _topPadding + row * (_sideQuestHeight + _sideQuestGap)
            : chapterRect.bottom +
                _sideQuestGap +
                row * (_sideQuestHeight + _sideQuestGap);
        rects[attachment.relationshipId] = Rect.fromLTWH(
          left,
          top,
          _sideQuestWidth,
          _sideQuestHeight,
        );
      }
    }
    return rects;
  }

  List<StorylineGraphPaintEdge> _paintEdges(
    Rect rootRect,
    Map<String, Rect> chapterRects,
    Map<String, Rect> sideQuestRects,
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
    for (final attachment in model.sideQuestAttachments) {
      final chapterRect = chapterRects[attachment.chapterId];
      final sideQuestRect = sideQuestRects[attachment.relationshipId];
      if (chapterRect == null || sideQuestRect == null) continue;
      final sideQuestAbove = sideQuestRect.center.dy < chapterRect.center.dy;
      edges.add(
        StorylineGraphPaintEdge(
          from: sideQuestAbove
              ? Offset(chapterRect.center.dx, chapterRect.top)
              : Offset(chapterRect.center.dx, chapterRect.bottom),
          to: sideQuestAbove
              ? Offset(sideQuestRect.center.dx, sideQuestRect.bottom)
              : Offset(sideQuestRect.center.dx, sideQuestRect.top),
          kind: StorylineGraphEdgeKind.sideQuestAttachment,
        ),
      );
    }
    return edges;
  }

  List<_EdgeMarker> _edgeMarkers(
    Rect rootRect,
    Map<String, Rect> chapterRects,
    Map<String, Rect> sideQuestRects,
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
      final sideQuestRect = sideQuestRects[attachment.relationshipId];
      if (sideQuestRect == null) continue;
      markers.add(
        _EdgeMarker(
          key: 'storylines-graph-edge-sidequest-${attachment.relationshipId}',
          position: sideQuestRect.center,
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
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storyline',
              style: TextStyle(
                color: colors.brandPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
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
    final visibleSteps =
        chapter.steps.take(_maxVisibleStepsPerChapter).toList();
    final hiddenStepCount = chapter.steps.length - visibleSteps.length;
    final items = <Widget>[
      if (chapter.steps.isEmpty)
        _GraphEmptyHint(
          key: ValueKey('storylines-graph-empty-steps-${chapter.id}'),
          title: 'Aucune étape narrative.',
          body: 'Les étapes restent créées depuis Structure.',
        )
      else ...[
        for (final step in visibleSteps) _GraphStepChip(step: step),
        if (hiddenStepCount > 0)
          _GraphOverflowChip(
            hiddenStepCount: hiddenStepCount,
          ),
      ],
    ];
    return KeyedSubtree(
      key: ValueKey('storylines-graph-node-chapter-${chapter.id}'),
      child: PokeMapCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chapitre ${chapter.order + 1}',
              style: TextStyle(
                color: colors.brandPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              [
                'Ordre ${chapter.order}',
                _formatCount(chapter.steps.length, 'étape', 'étapes'),
                if (attachments.isNotEmpty)
                  _formatCount(
                    attachments.length,
                    'quête disponible',
                    'quêtes disponibles',
                  ),
              ].join(' · '),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (chapter.description != null) ...[
              const SizedBox(height: 5),
              Text(
                chapter.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < items.length; index += 1) ...[
                    items[index],
                    if (index < items.length - 1) const SizedBox(height: 6),
                  ],
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
            const SizedBox(height: 3),
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

class _GraphOverflowChip extends StatelessWidget {
  const _GraphOverflowChip({required this.hiddenStepCount});

  final int hiddenStepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key: const ValueKey('storylines-graph-steps-overflow'),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Text(
          '+$hiddenStepCount ${hiddenStepCount == 1 ? 'étape' : 'étapes'}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GraphSideQuestNode extends StatelessWidget {
  const _GraphSideQuestNode({required this.attachment});

  final StorylineGraphSideQuestAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key:
          ValueKey('storylines-graph-node-sidequest-${attachment.sideQuestId}'),
      decoration: BoxDecoration(
        color: colors.warningSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.warningBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StorylinesGraphBadge(label: 'Quête annexe'),
            const SizedBox(height: 7),
            Text(
              attachment.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quête annexe · ${_formatCount(attachment.chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(attachment.stepCount, 'étape', 'étapes')}\nDisponible depuis ${attachment.anchorLabel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10.5,
                height: 1.18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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

class _StorylinesGraphLegend extends StatelessWidget {
  const _StorylinesGraphLegend({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final legend = Wrap(
      spacing: compact ? 10 : 14,
      runSpacing: compact ? 6 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _GraphLegendSwatch(
          label: 'Storyline',
          color: colors.brandPrimaryBorder,
        ),
        _GraphLegendSwatch(
          label: 'Chapitre',
          color: colors.controlBorder,
        ),
        _GraphLegendSwatch(
          label: 'Étape narrative',
          color: colors.borderSubtle,
        ),
        _GraphLegendSwatch(
          label: 'Quête annexe',
          color: colors.warningBorder,
        ),
        _GraphLegendLine(
          key: const ValueKey('storylines-graph-legend-author-order'),
          label: 'Ordre auteur',
          color: colors.brandPrimaryBorder,
        ),
        _GraphLegendLine(
          key: const ValueKey(
            'storylines-graph-legend-sidequest-availability',
          ),
          label: 'Disponibilité quête annexe',
          color: colors.warning,
          dashed: true,
        ),
      ],
    );
    if (compact) {
      return KeyedSubtree(
        key: const ValueKey('storylines-graph-legend'),
        child: legend,
      );
    }
    return DecoratedBox(
      key: const ValueKey('storylines-graph-legend'),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: legend,
      ),
    );
  }
}

class _GraphLegendSwatch extends StatelessWidget {
  const _GraphLegendSwatch({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: const SizedBox(width: 14, height: 10),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GraphLegendLine extends StatelessWidget {
  const _GraphLegendLine({
    super.key,
    required this.label,
    required this.color,
    this.dashed = false,
  });

  final String label;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final segments = dashed ? 3 : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < segments; index += 1) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: SizedBox(width: dashed ? 8 : 26, height: 2),
              ),
              if (dashed && index < segments - 1) const SizedBox(width: 3),
            ],
          ],
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GraphStatusBadges extends StatelessWidget {
  const _GraphStatusBadges({
    required this.model,
    required this.sideQuestAttached,
  });

  final StorylineGraphViewModel model;
  final bool sideQuestAttached;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
    );
  }
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
