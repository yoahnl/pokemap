import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'storylines_graph_model.dart';
import 'storylines_graph_painter.dart';

const int _maxVisibleStepsPerChapter = 3;

class StorylinesGraphView extends StatefulWidget {
  const StorylinesGraphView({
    super.key,
    this.project,
    required this.storyline,
    required this.storylines,
    required this.sideQuestCountOutsideSelected,
    this.onConnectEdge,
    this.onDisconnectEdge,
    this.onNodeSelected,
  });

  final ProjectManifest? project;
  final StorylineAsset storyline;
  final List<StorylineAsset> storylines;
  final int sideQuestCountOutsideSelected;
  final Future<bool> Function(StorylineProgressionConnectRequest request)?
      onConnectEdge;
  final Future<bool> Function(String edgeId)? onDisconnectEdge;
  final ValueChanged<StorylineGraphNode>? onNodeSelected;

  @override
  State<StorylinesGraphView> createState() => _StorylinesGraphViewState();
}

class _StorylinesGraphViewState extends State<StorylinesGraphView> {
  final Set<String> _selectedNodeIds = <String>{};
  final Map<String, Offset> _visualOffsets = <String, Offset>{};
  String? _selectedEdgeId;

  StorylineGraphViewModel _model() {
    final project = widget.project;
    if (project != null) {
      return StorylineGraphViewModel.fromProject(
        project,
        storylineId: widget.storyline.id,
        sideQuestCountOutsideSelected: widget.sideQuestCountOutsideSelected,
      );
    }
    return StorylineGraphViewModel.fromStoryline(
      widget.storyline,
      storylines: widget.storylines,
      sideQuestCountOutsideSelected: widget.sideQuestCountOutsideSelected,
    );
  }

  void _selectNode(StorylineGraphNode node, {required bool additive}) {
    setState(() {
      if (!additive) _selectedNodeIds.clear();
      if (additive && _selectedNodeIds.contains(node.id)) {
        _selectedNodeIds.remove(node.id);
      } else {
        _selectedNodeIds.add(node.id);
      }
      _selectedEdgeId = null;
    });
    widget.onNodeSelected?.call(node);
  }

  void _moveNode(String nodeId, Offset delta) {
    setState(() {
      final movingIds = _selectedNodeIds.contains(nodeId)
          ? _selectedNodeIds
          : <String>{nodeId};
      for (final id in movingIds) {
        _visualOffsets[id] = (_visualOffsets[id] ?? Offset.zero) + delta;
      }
    });
  }

  void _resetLayout() => setState(_visualOffsets.clear);

  void _selectEdge(String edgeId) {
    setState(() {
      _selectedEdgeId = edgeId;
      _selectedNodeIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sideQuestAttached =
        widget.storyline.type == StorylineType.sideQuest &&
            widget.storyline.relationships.any(_isSideQuestAttachment);
    final model = _model();
    final selectedEdge =
        model.edges.where((edge) => edge.id == _selectedEdgeId).firstOrNull;
    return Column(
      key: const ValueKey('storylines-graph-from-asset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StorylinesGraphToolbar(
          model: model,
          sideQuestAttached: sideQuestAttached,
          selectedNodeCount: _selectedNodeIds.length,
          canResetLayout: _visualOffsets.isNotEmpty,
          canConnect: widget.project != null && widget.onConnectEdge != null,
          onResetLayout: _resetLayout,
          onConnect: widget.project == null || widget.onConnectEdge == null
              ? null
              : () => _openConnectionSheet(model),
        ),
        const SizedBox(height: 6),
        if (model.semanticEdges.isNotEmpty) ...[
          _StorylineSemanticEdgeRail(
            model: model,
            selectedEdgeId: _selectedEdgeId,
            onEdgeSelected: _selectEdge,
          ),
          const SizedBox(height: 6),
        ],
        if (selectedEdge != null) ...[
          _StorylineSelectedEdgePanel(
            edge: selectedEdge,
            onDisconnect:
                !selectedEdge.isReversible || widget.onDisconnectEdge == null
                    ? null
                    : () => widget.onDisconnectEdge!(selectedEdge.id),
          ),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: _StorylineGraphCanvas(
            model: model,
            selectedNodeIds: _selectedNodeIds,
            visualOffsets: _visualOffsets,
            onNodeSelected: _selectNode,
            onNodeMoved: _moveNode,
          ),
        ),
      ],
    );
  }

  Future<void> _openConnectionSheet(StorylineGraphViewModel model) async {
    final project = widget.project;
    final onConnect = widget.onConnectEdge;
    if (project == null || onConnect == null) return;
    final request =
        await showPokeMapDesktopSideSheet<StorylineProgressionConnectRequest>(
      context: context,
      title: 'Ajouter une relation de progression',
      semanticLabel: 'Nouvelle relation de progression Storyline',
      width: 480,
      builder: (context) => _StorylineGraphConnectionSheet(
        project: project,
        storyline: widget.storyline,
      ),
    );
    if (request == null || !mounted) return;
    await onConnect(request);
  }
}

class _StorylinesGraphToolbar extends StatelessWidget {
  const _StorylinesGraphToolbar({
    required this.model,
    required this.sideQuestAttached,
    required this.selectedNodeCount,
    required this.canResetLayout,
    required this.canConnect,
    required this.onResetLayout,
    required this.onConnect,
  });

  final StorylineGraphViewModel model;
  final bool sideQuestAttached;
  final int selectedNodeCount;
  final bool canResetLayout;
  final bool canConnect;
  final VoidCallback onResetLayout;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 840 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        if (!compact) {
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
                        'Graph sémantique',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _StorylinesGraphBadge(
                        label: 'Projection canonique',
                      ),
                      if (selectedNodeCount > 0) ...[
                        const SizedBox(width: 8),
                        _StorylinesGraphBadge(
                          label: _selectionLabel(selectedNodeCount),
                        ),
                      ],
                      const Spacer(),
                      PokeMapIconButton(
                        key: const ValueKey('storylines-graph-reset-layout'),
                        onPressed: canResetLayout ? onResetLayout : null,
                        tooltip: 'Réinitialiser le placement visuel',
                        variant: PokeMapIconButtonVariant.soft,
                        icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                      ),
                      const SizedBox(width: 6),
                      PokeMapButton(
                        key: const ValueKey('storylines-graph-connect-action'),
                        onPressed: canConnect ? onConnect : null,
                        variant: PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.link, size: 14),
                        child: const Text('Connecter'),
                      ),
                      const SizedBox(width: 10),
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
        final identity = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.arrow_branch,
              tone: PokeMapTone.narrative,
              size: 32,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Graph sémantique',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const _StorylinesGraphBadge(label: 'Projection canonique'),
          ],
        );
        final status = _GraphStatusBadges(
          model: model,
          sideQuestAttached: sideQuestAttached,
        );
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
                identity,
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (selectedNodeCount > 0)
                      _StorylinesGraphBadge(
                        label: _selectionLabel(selectedNodeCount),
                      ),
                    PokeMapIconButton(
                      key: const ValueKey('storylines-graph-reset-layout'),
                      onPressed: canResetLayout ? onResetLayout : null,
                      tooltip: 'Réinitialiser le placement visuel',
                      variant: PokeMapIconButtonVariant.soft,
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                    ),
                    PokeMapButton(
                      key: const ValueKey('storylines-graph-connect-action'),
                      onPressed: canConnect ? onConnect : null,
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.link, size: 14),
                      child: const Text('Connecter'),
                    ),
                    status,
                  ],
                ),
                const SizedBox(height: 6),
                const _StorylinesGraphLegend(compact: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StorylineSemanticEdgeRail extends StatelessWidget {
  const _StorylineSemanticEdgeRail({
    required this.model,
    required this.selectedEdgeId,
    required this.onEdgeSelected,
  });

  final StorylineGraphViewModel model;
  final String? selectedEdgeId;
  final ValueChanged<String> onEdgeSelected;

  @override
  Widget build(BuildContext context) {
    String nodeLabel(String nodeId) {
      return model.nodes
              .where((node) => node.id == nodeId)
              .map((node) => node.title)
              .firstOrNull ??
          nodeId;
    }

    return PokeMapPanel(
      key: const ValueKey('storylines-graph-semantic-edge-rail'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      borderRadius: 10,
      child: SizedBox(
        height: 32,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0;
                  index < model.semanticEdges.length;
                  index += 1) ...[
                PokeMapButton(
                  key: ValueKey(
                    'storylines-graph-semantic-edge-${model.semanticEdges[index].id}',
                  ),
                  onPressed: () =>
                      onEdgeSelected(model.semanticEdges[index].id),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: model.semanticEdges[index].id == selectedEdgeId,
                  leading: Icon(
                    model.semanticEdges[index].isReversible
                        ? CupertinoIcons.link
                        : CupertinoIcons.lock,
                    size: 13,
                  ),
                  child: Text(
                    '${model.semanticEdges[index].semanticLabel} · ${nodeLabel(model.semanticEdges[index].fromNodeId)} → ${nodeLabel(model.semanticEdges[index].toNodeId)}',
                  ),
                ),
                if (index < model.semanticEdges.length - 1)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineSelectedEdgePanel extends StatelessWidget {
  const _StorylineSelectedEdgePanel({
    required this.edge,
    required this.onDisconnect,
  });

  final StorylineGraphEdge edge;
  final Future<bool> Function()? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('storylines-graph-selected-edge-panel'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      borderRadius: 10,
      child: Row(
        children: [
          Icon(
            edge.isReversible ? CupertinoIcons.link : CupertinoIcons.lock,
            color: edge.isReversible ? colors.success : colors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edge.semanticLabel,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  edge.isReversible
                      ? 'Cette relation possède une opération inverse atomique.'
                      : edge.readOnlyReason ??
                          'Cette relation canonique est en lecture seule.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StorylinesGraphBadge(
            label: edge.isReversible ? 'Réversible' : 'Lecture seule',
          ),
          if (onDisconnect != null) ...[
            const SizedBox(width: 8),
            PokeMapButton(
              key: ValueKey('storylines-graph-disconnect-${edge.id}'),
              onPressed: () async => onDisconnect!(),
              variant: PokeMapButtonVariant.danger,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.minus_circle, size: 14),
              child: const Text('Déconnecter'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StorylineGraphCanvas extends StatelessWidget {
  const _StorylineGraphCanvas({
    required this.model,
    required this.selectedNodeIds,
    required this.visualOffsets,
    required this.onNodeSelected,
    required this.onNodeMoved,
  });

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
  final Set<String> selectedNodeIds;
  final Map<String, Offset> visualOffsets;
  final void Function(StorylineGraphNode node, {required bool additive})
      onNodeSelected;
  final void Function(String nodeId, Offset delta) onNodeMoved;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context)
            .scale(1)
            .clamp(1.0, 1.5)
            .toDouble();
        final usesScaledGeometry = textScale > 1;
        final rootHeight =
            usesScaledGeometry ? _rootHeight * textScale + 12 : _rootHeight;
        final sideQuestHeight = usesScaledGeometry
            ? _sideQuestHeight * textScale
            : _sideQuestHeight;
        final maxItemCount = model.chapters.fold<int>(
          0,
          (current, chapter) => math.max(
            current,
            _graphItemCountForChapter(chapter),
          ),
        );
        final chapterHeight = _chapterHeight(maxItemCount, textScale);
        final sideQuestRowsAbove = _sideQuestRowsAbove();
        final sideQuestBandAbove = sideQuestRowsAbove == 0
            ? 0.0
            : sideQuestRowsAbove * (sideQuestHeight + _sideQuestGap);
        final chapterTop = _topPadding + sideQuestBandAbove;
        final sideQuestRowsBelow = _sideQuestRowsBelow();
        final sideQuestBandBelow = sideQuestRowsBelow == 0
            ? 0.0
            : _sideQuestGap +
                sideQuestRowsBelow * (sideQuestHeight + _sideQuestGap);
        final contentWidth = _leftPadding +
            _rootWidth +
            _rootToChapterGap +
            math.max(1, model.chapters.length) * (_chapterWidth + _chapterGap) +
            _leftPadding;
        final contentHeight = math.max(
          chapterTop + chapterHeight + sideQuestBandBelow + _topPadding,
          _topPadding + _sideQuestBandHeight * textScale + rootHeight + 220,
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
        final rootNode = model.nodes.singleWhere(
          (node) =>
              node.kind == StorylineGraphNodeKind.storyline &&
              node.canonicalId == model.storylineId,
        );
        final rootRect = Rect.fromLTWH(
          _leftPadding,
          chapterTop + (chapterHeight - rootHeight) / 2,
          _rootWidth,
          rootHeight,
        ).shift(visualOffsets[rootNode.id] ?? Offset.zero);
        final chapterRects = <String, Rect>{};
        for (var index = 0; index < model.chapters.length; index += 1) {
          final chapter = model.chapters[index];
          final nodeId = StorylineGraphViewModel.chapterNodeId(chapter.id);
          chapterRects[chapter.id] = Rect.fromLTWH(
            _leftPadding +
                _rootWidth +
                _rootToChapterGap +
                index * (_chapterWidth + _chapterGap),
            chapterTop,
            _chapterWidth,
            _chapterHeight(_graphItemCountForChapter(chapter), textScale),
          ).shift(visualOffsets[nodeId] ?? Offset.zero);
        }
        final sideQuestRects = _sideQuestRects(
          chapterRects,
          sideQuestHeight: sideQuestHeight,
        );
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
                            outcomeColor: colors.success,
                            conditionColor: colors.brandPrimary,
                            relationshipColor: colors.textSecondary,
                          ),
                        ),
                      ),
                      _GraphNodePosition(
                        rect: rootRect,
                        child: _GraphNodeInteraction(
                          node: rootNode,
                          selected: selectedNodeIds.contains(rootNode.id),
                          onSelected: onNodeSelected,
                          onMoved: onNodeMoved,
                          child: _GraphRootNode(model: model),
                        ),
                      ),
                      for (final chapter in model.chapters)
                        _GraphNodePosition(
                          rect: chapterRects[chapter.id]!,
                          child: _GraphNodeInteraction(
                            node: model.nodes.singleWhere(
                              (node) =>
                                  node.id ==
                                  StorylineGraphViewModel.chapterNodeId(
                                    chapter.id,
                                  ),
                            ),
                            selected: selectedNodeIds.contains(
                              StorylineGraphViewModel.chapterNodeId(chapter.id),
                            ),
                            onSelected: onNodeSelected,
                            onMoved: onNodeMoved,
                            child: _GraphChapterNode(
                              chapter: chapter,
                              stepNodes: {
                                for (final node in model.nodes)
                                  if (node.kind ==
                                          StorylineGraphNodeKind.step &&
                                      node.chapterId == chapter.id)
                                    node.canonicalId: node,
                              },
                              selectedNodeIds: selectedNodeIds,
                              onNodeSelected: onNodeSelected,
                              attachments: sideQuestAttachmentsForChapter(
                                model.sideQuestAttachments,
                                chapter.id,
                              ),
                            ),
                          ),
                        ),
                      for (final attachment in model.sideQuestAttachments)
                        if (sideQuestRects[attachment.relationshipId] != null)
                          _GraphNodePosition(
                            rect: sideQuestRects[attachment.relationshipId]!,
                            child: _GraphNodeInteraction(
                              node: model.nodes.singleWhere(
                                (node) =>
                                    node.canonicalId ==
                                        attachment.sideQuestId &&
                                    node.kind ==
                                        StorylineGraphNodeKind.sideQuest,
                              ),
                              selected: selectedNodeIds.contains(
                                'storyline:${attachment.sideQuestId}',
                              ),
                              onSelected: onNodeSelected,
                              onMoved: onNodeMoved,
                              child: _GraphSideQuestNode(
                                attachment: attachment,
                              ),
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

  double _chapterHeight(int itemCount, double textScale) {
    final effectiveItems = math.max(1, itemCount);
    final nominalHeight = 144 + effectiveItems * (_stepHeight + 8);
    if (textScale <= 1) return nominalHeight.toDouble();
    return nominalHeight * textScale + 12;
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

  Map<String, Rect> _sideQuestRects(
    Map<String, Rect> chapterRects, {
    required double sideQuestHeight,
  }) {
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
            ? _topPadding + row * (sideQuestHeight + _sideQuestGap)
            : chapterRect.bottom +
                _sideQuestGap +
                row * (sideQuestHeight + _sideQuestGap);
        rects[attachment.relationshipId] = Rect.fromLTWH(
          left,
          top,
          _sideQuestWidth,
          sideQuestHeight,
        ).shift(
          visualOffsets['storyline:${attachment.sideQuestId}'] ?? Offset.zero,
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
    final edges = <StorylineGraphPaintEdge>[];
    Rect? rectFor(String nodeId) {
      if (nodeId == 'storyline:${model.storylineId}') return rootRect;
      if (nodeId.startsWith('chapter:')) {
        return chapterRects[nodeId.substring('chapter:'.length)];
      }
      if (nodeId.startsWith('storyline:')) {
        final storylineId = nodeId.substring('storyline:'.length);
        for (final attachment in model.sideQuestAttachments) {
          if (attachment.sideQuestId == storylineId) {
            return sideQuestRects[attachment.relationshipId];
          }
        }
      }
      return null;
    }

    for (final edge in model.edges) {
      if (edge.kind != StorylineGraphEdgeKind.contains &&
          edge.kind != StorylineGraphEdgeKind.authorOrder &&
          edge.kind != StorylineGraphEdgeKind.sideQuestAttachment) {
        continue;
      }
      final fromRect = rectFor(edge.fromNodeId);
      final toRect = rectFor(edge.toNodeId);
      if (fromRect == null || toRect == null) continue;
      final leftToRight = fromRect.center.dx <= toRect.center.dx;
      edges.add(
        StorylineGraphPaintEdge(
          from: Offset(
            leftToRight ? fromRect.right : fromRect.left,
            fromRect.center.dy,
          ),
          to: Offset(
            leftToRight ? toRect.left : toRect.right,
            toRect.center.dy,
          ),
          kind: edge.kind,
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

class _GraphNodeInteraction extends StatefulWidget {
  const _GraphNodeInteraction({
    required this.node,
    required this.selected,
    required this.onSelected,
    required this.onMoved,
    required this.child,
    this.allowMove = true,
  });

  final StorylineGraphNode node;
  final bool selected;
  final void Function(StorylineGraphNode node, {required bool additive})
      onSelected;
  final void Function(String nodeId, Offset delta) onMoved;
  final Widget child;
  final bool allowMove;

  @override
  State<_GraphNodeInteraction> createState() => _GraphNodeInteractionState();
}

class _GraphNodeInteractionState extends State<_GraphNodeInteraction> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Storyline graph node');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _select({required bool additive}) {
    _focusNode.requestFocus();
    widget.onSelected(widget.node, additive: additive);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.node.title}, ${widget.node.subtitle}',
      child: FocusableActionDetector(
        focusNode: _focusNode,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _select(additive: false);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _select(additive: false),
          onLongPress: () => _select(additive: true),
          onPanUpdate: widget.allowMove
              ? (details) => widget.onMoved(widget.node.id, details.delta)
              : null,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected
                    ? colors.brandPrimary
                    : colors.borderSubtle.withValues(alpha: 0),
                width: widget.selected ? 2 : 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
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
    required this.stepNodes,
    required this.selectedNodeIds,
    required this.onNodeSelected,
    required this.attachments,
  });

  final StorylineGraphChapter chapter;
  final Map<String, StorylineGraphNode> stepNodes;
  final Set<String> selectedNodeIds;
  final void Function(StorylineGraphNode node, {required bool additive})
      onNodeSelected;
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
        for (final step in visibleSteps)
          _GraphNodeInteraction(
            node: stepNodes[step.id]!,
            selected: selectedNodeIds.contains('step:${step.id}'),
            onSelected: onNodeSelected,
            onMoved: (_, __) {},
            allowMove: false,
            child: _GraphStepChip(step: step),
          ),
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

enum _GraphConnectionKind { outcome, relationship, condition }

final class _GraphOutcomeSource {
  const _GraphOutcomeSource({
    required this.key,
    required this.sceneLinkId,
    required this.outcomeLinkId,
    required this.label,
  });

  final String key;
  final String sceneLinkId;
  final String outcomeLinkId;
  final String label;
}

final class _GraphStepChoice {
  const _GraphStepChoice({
    required this.chapterId,
    required this.step,
    required this.label,
  });

  final String chapterId;
  final StorylineStep step;
  final String label;
}

class _StorylineGraphConnectionSheet extends StatefulWidget {
  const _StorylineGraphConnectionSheet({
    required this.project,
    required this.storyline,
  });

  final ProjectManifest project;
  final StorylineAsset storyline;

  @override
  State<_StorylineGraphConnectionSheet> createState() =>
      _StorylineGraphConnectionSheetState();
}

class _StorylineGraphConnectionSheetState
    extends State<_StorylineGraphConnectionSheet> {
  late _GraphConnectionKind _kind;
  late final List<_GraphOutcomeSource> _outcomes;
  late final List<_GraphStepChoice> _steps;
  late final List<StorylineAsset> _otherStorylines;
  late final List<NarrativeFactDefinition> _facts;
  String? _outcomeKey;
  String? _targetStepId;
  String? _targetStorylineId;
  String? _conditionStepId;
  String? _factId;
  StorylineEffectType _effectType = StorylineEffectType.completeStep;
  StorylineRelationshipKind _relationshipKind =
      StorylineRelationshipKind.requires;
  StorylineProgressionConditionSlot _conditionSlot =
      StorylineProgressionConditionSlot.entry;
  bool _expectedValue = true;

  @override
  void initState() {
    super.initState();
    _steps = [
      for (final chapter in widget.storyline.chapters)
        for (final step in chapter.steps)
          _GraphStepChoice(
            chapterId: chapter.id,
            step: step,
            label: '${chapter.title} · ${step.title}',
          ),
    ];
    final scenarioById = {
      for (final scenario in widget.project.scenarios) scenario.id: scenario,
    };
    _outcomes = [
      for (final link in widget.storyline.sceneLinks)
        for (final outcome in link.outcomeLinks)
          _GraphOutcomeSource(
            key: '${link.id}::${outcome.id}',
            sceneLinkId: link.id,
            outcomeLinkId: outcome.id,
            label:
                '${scenarioById[link.sceneRef?.targetId]?.name ?? link.label} · ${outcome.label ?? outcome.outcomeId}',
          ),
    ];
    _otherStorylines = widget.project.storylines
        .where((storyline) => storyline.id != widget.storyline.id)
        .toList(growable: false);
    _facts = widget.project.facts;
    _outcomeKey = _outcomes.firstOrNull?.key;
    _targetStepId = _steps.firstOrNull?.step.id;
    _targetStorylineId = _otherStorylines.firstOrNull?.id;
    final conditionSteps = _conditionSteps;
    _conditionStepId = conditionSteps.firstOrNull?.step.id;
    _factId = _facts.firstOrNull?.id;
    _kind = _availableKinds.firstOrNull ?? _GraphConnectionKind.outcome;
    _normalizeConditionSlot();
  }

  List<_GraphConnectionKind> get _availableKinds => [
        if (_outcomes.isNotEmpty && _steps.isNotEmpty)
          _GraphConnectionKind.outcome,
        if (_otherStorylines.isNotEmpty) _GraphConnectionKind.relationship,
        if (_conditionSteps.isNotEmpty && _facts.isNotEmpty)
          _GraphConnectionKind.condition,
      ];

  List<_GraphStepChoice> get _conditionSteps => _steps
      .where(
        (choice) =>
            choice.step.entryCondition == null ||
            choice.step.completionCondition == null,
      )
      .toList(growable: false);

  _GraphStepChoice? get _selectedConditionStep => _conditionSteps
      .where((choice) => choice.step.id == _conditionStepId)
      .firstOrNull;

  void _normalizeConditionSlot() {
    final step = _selectedConditionStep?.step;
    if (step == null) return;
    if (_conditionSlot == StorylineProgressionConditionSlot.entry &&
        step.entryCondition != null) {
      _conditionSlot = StorylineProgressionConditionSlot.completion;
    }
    if (_conditionSlot == StorylineProgressionConditionSlot.completion &&
        step.completionCondition != null) {
      _conditionSlot = StorylineProgressionConditionSlot.entry;
    }
  }

  StorylineProgressionConnectRequest? _request() {
    switch (_kind) {
      case _GraphConnectionKind.outcome:
        final outcome =
            _outcomes.where((item) => item.key == _outcomeKey).firstOrNull;
        if (outcome == null || _targetStepId == null) return null;
        return StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: widget.storyline.id,
          sceneLinkId: outcome.sceneLinkId,
          outcomeLinkId: outcome.outcomeLinkId,
          effectType: _effectType,
          targetStepId: _targetStepId!,
        );
      case _GraphConnectionKind.relationship:
        if (_targetStorylineId == null) return null;
        return StorylineProgressionConnectRequest.relationship(
          relationshipId: _nextRelationshipId(
            widget.project,
            widget.storyline.id,
            _relationshipKind,
            _targetStorylineId!,
          ),
          kind: _relationshipKind,
          sourceStorylineId: widget.storyline.id,
          targetStorylineId: _targetStorylineId!,
        );
      case _GraphConnectionKind.condition:
        final step = _selectedConditionStep;
        if (step == null || _factId == null) return null;
        return StorylineProgressionConnectRequest.factCondition(
          storylineId: widget.storyline.id,
          chapterId: step.chapterId,
          stepId: step.step.id,
          slot: _conditionSlot,
          factId: _factId!,
          expectedValue: _expectedValue,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableKinds;
    if (available.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: PokeMapEmptyState(
          title: 'Aucune connexion disponible',
          description:
              'Ajoutez des Steps, Facts, outcomes ou une autre Storyline avant de créer une relation.',
          icon: Icon(CupertinoIcons.link),
        ),
      );
    }
    return Column(
      key: const ValueKey('storylines-graph-connection-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PokeMapSegmentedTabs(
                tabs: [
                  PokeMapSegmentedTab(
                    key: const ValueKey('storylines-graph-connect-outcome'),
                    label: 'Outcome',
                    icon: CupertinoIcons.flag,
                    selected: _kind == _GraphConnectionKind.outcome,
                    onTap: available.contains(_GraphConnectionKind.outcome)
                        ? () => setState(
                              () => _kind = _GraphConnectionKind.outcome,
                            )
                        : null,
                  ),
                  PokeMapSegmentedTab(
                    key:
                        const ValueKey('storylines-graph-connect-relationship'),
                    label: 'Storyline',
                    icon: CupertinoIcons.arrow_branch,
                    selected: _kind == _GraphConnectionKind.relationship,
                    onTap: available.contains(_GraphConnectionKind.relationship)
                        ? () => setState(
                              () => _kind = _GraphConnectionKind.relationship,
                            )
                        : null,
                  ),
                  PokeMapSegmentedTab(
                    key: const ValueKey('storylines-graph-connect-condition'),
                    label: 'Condition',
                    icon: CupertinoIcons.checkmark_shield,
                    selected: _kind == _GraphConnectionKind.condition,
                    onTap: available.contains(_GraphConnectionKind.condition)
                        ? () => setState(
                              () => _kind = _GraphConnectionKind.condition,
                            )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              switch (_kind) {
                _GraphConnectionKind.outcome => _outcomeForm(),
                _GraphConnectionKind.relationship => _relationshipForm(),
                _GraphConnectionKind.condition => _conditionForm(),
              },
              const SizedBox(height: 12),
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.info,
                title: 'Source canonique',
                message:
                    'Le graph modifiera le champ narratif correspondant. Le placement visuel et les coordonnées ne seront jamais enregistrés.',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PokeMapButton(
                key: const ValueKey('storylines-graph-connect-cancel'),
                onPressed: () => Navigator.of(context).pop(),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const ValueKey('storylines-graph-connect-submit'),
                onPressed: _request() == null
                    ? null
                    : () => Navigator.of(context).pop(_request()),
                variant: PokeMapButtonVariant.success,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.link, size: 14),
                child: const Text('Créer la relation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _outcomeForm() {
    return Column(
      children: [
        PokeMapDropdownField<String>(
          key: const ValueKey('storylines-graph-connect-outcome-source'),
          label: 'Résultat source',
          value: _outcomeKey ?? '',
          items: [
            for (final outcome in _outcomes)
              PokeMapDropdownItem(value: outcome.key, label: outcome.label),
          ],
          onChanged: (value) => setState(() => _outcomeKey = value),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<StorylineEffectType>(
          key: const ValueKey('storylines-graph-connect-outcome-effect'),
          label: 'Effet de progression',
          value: _effectType,
          items: const [
            PokeMapDropdownItem(
              value: StorylineEffectType.activateStep,
              label: 'Activer l’étape',
            ),
            PokeMapDropdownItem(
              value: StorylineEffectType.completeStep,
              label: 'Compléter l’étape',
            ),
          ],
          onChanged: (value) => setState(() => _effectType = value),
        ),
        const SizedBox(height: 12),
        _stepDropdown(
          key: const ValueKey('storylines-graph-connect-outcome-step'),
          label: 'Étape cible',
          choices: _steps,
          value: _targetStepId,
          onChanged: (value) => setState(() => _targetStepId = value),
        ),
      ],
    );
  }

  Widget _relationshipForm() {
    return Column(
      children: [
        PokeMapDropdownField<StorylineRelationshipKind>(
          key: const ValueKey('storylines-graph-connect-relationship-kind'),
          label: 'Sémantique',
          value: _relationshipKind,
          items: const [
            PokeMapDropdownItem(
              value: StorylineRelationshipKind.requires,
              label: 'Requiert',
            ),
            PokeMapDropdownItem(
              value: StorylineRelationshipKind.blocks,
              label: 'Bloque',
            ),
            PokeMapDropdownItem(
              value: StorylineRelationshipKind.convergesTo,
              label: 'Converge vers',
            ),
          ],
          onChanged: (value) => setState(() => _relationshipKind = value),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('storylines-graph-connect-storyline-target'),
          label: 'Storyline cible',
          value: _targetStorylineId ?? '',
          items: [
            for (final storyline in _otherStorylines)
              PokeMapDropdownItem(
                value: storyline.id,
                label: storyline.title,
              ),
          ],
          onChanged: (value) => setState(() => _targetStorylineId = value),
        ),
      ],
    );
  }

  Widget _conditionForm() {
    final selected = _selectedConditionStep?.step;
    final slots = <StorylineProgressionConditionSlot>[
      if (selected?.entryCondition == null)
        StorylineProgressionConditionSlot.entry,
      if (selected?.completionCondition == null)
        StorylineProgressionConditionSlot.completion,
    ];
    return Column(
      children: [
        _stepDropdown(
          key: const ValueKey('storylines-graph-connect-condition-step'),
          label: 'Étape cible',
          choices: _conditionSteps,
          value: _conditionStepId,
          onChanged: (value) => setState(() {
            _conditionStepId = value;
            _normalizeConditionSlot();
          }),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<StorylineProgressionConditionSlot>(
          key: const ValueKey('storylines-graph-connect-condition-slot'),
          label: 'Rôle de la condition',
          value: _conditionSlot,
          items: [
            for (final slot in slots)
              PokeMapDropdownItem(
                value: slot,
                label: slot == StorylineProgressionConditionSlot.entry
                    ? 'Entrée dans l’étape'
                    : 'Complétion de l’étape',
              ),
          ],
          onChanged: (value) => setState(() => _conditionSlot = value),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('storylines-graph-connect-condition-fact'),
          label: 'Fact du projet',
          value: _factId ?? '',
          items: [
            for (final fact in _facts)
              PokeMapDropdownItem(value: fact.id, label: fact.label),
          ],
          onChanged: (value) => setState(() => _factId = value),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<bool>(
          key: const ValueKey('storylines-graph-connect-condition-value'),
          label: 'Valeur attendue',
          value: _expectedValue,
          items: const [
            PokeMapDropdownItem(value: true, label: 'Vrai'),
            PokeMapDropdownItem(value: false, label: 'Faux'),
          ],
          onChanged: (value) => setState(() => _expectedValue = value),
        ),
      ],
    );
  }

  Widget _stepDropdown({
    required Key key,
    required String label,
    required List<_GraphStepChoice> choices,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return PokeMapDropdownField<String>(
      key: key,
      label: label,
      value: value ?? '',
      items: [
        for (final choice in choices)
          PokeMapDropdownItem(value: choice.step.id, label: choice.label),
      ],
      onChanged: onChanged,
    );
  }
}

String _nextRelationshipId(
  ProjectManifest project,
  String sourceId,
  StorylineRelationshipKind kind,
  String targetId,
) {
  final existing = project.storylines
      .expand((storyline) => storyline.relationships)
      .map((relationship) => relationship.id)
      .toSet();
  final stem = 'relationship_${_graphIdPart(sourceId)}_${kind.name}_'
      '${_graphIdPart(targetId)}';
  if (!existing.contains(stem)) return stem;
  var suffix = 2;
  while (existing.contains('${stem}_$suffix')) {
    suffix += 1;
  }
  return '${stem}_$suffix';
}

String _graphIdPart(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), '');
  return normalized.isEmpty ? 'storyline' : normalized;
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

String _selectionLabel(int count) {
  return '$count ${count == 1 ? 'nœud sélectionné' : 'nœuds sélectionnés'}';
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
