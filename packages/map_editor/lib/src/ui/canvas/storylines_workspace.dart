import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class StorylinesWorkspace extends StatefulWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;

  @override
  State<StorylinesWorkspace> createState() => _StorylinesWorkspaceState();
}

class _StorylinesWorkspaceState extends State<StorylinesWorkspace> {
  _StorylineContentTab _selectedTab = _StorylineContentTab.graph;

  @override
  Widget build(BuildContext context) {
    final selectedStory = _selectedStory;
    final relatedSteps = selectedStory == null
        ? <NarrativeStepSummary>[]
        : widget.projection.steps
            .where((step) => step.globalScenarioId == selectedStory.id)
            .toList(growable: false);
    final relatedChapters = selectedStory == null
        ? <NarrativeChapterSummary>[]
        : widget.projection.chapters
            .where((chapter) => chapter.globalScenarioId == selectedStory.id)
            .toList(growable: false);
    final stepCountsByStoryId = <String, int>{
      for (final story in widget.projection.globalStories)
        story.id: widget.projection.steps
            .where((step) => step.globalScenarioId == story.id)
            .length,
    };
    final linkedCutsceneCount = relatedSteps
        .expand((step) => step.linkedCutsceneIds)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .length;

    return PokeMapPageSurface(
      key: const ValueKey('storylines-workspace-shell'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: _StorylinesSecondaryPanel(
              stories: widget.projection.globalStories,
              selectedStoryId: selectedStory?.id,
              stepCountsByStoryId: stepCountsByStoryId,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StorylineMainPanel(
              selectedStory: selectedStory,
              steps: relatedSteps,
              chapters: relatedChapters,
              selectedTab: _selectedTab,
              onTabSelected: _selectTab,
              stepCount: relatedSteps.length,
              chapterCount: relatedChapters.length,
              globalStoryCount: widget.projection.globalStories.length,
              linkedCutsceneCount: linkedCutsceneCount,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: _StorylineInspectorPanel(
              selectedStory: selectedStory,
              stepCount: relatedSteps.length,
              linkedCutsceneCount: linkedCutsceneCount,
            ),
          ),
        ],
      ),
    );
  }

  NarrativeScenarioSummary? get _selectedStory {
    for (final story in widget.projection.globalStories) {
      if (story.id == widget.selectedGlobalStoryId) {
        return story;
      }
    }
    return widget.projection.globalStories.isEmpty
        ? null
        : widget.projection.globalStories.first;
  }

  void _selectTab(_StorylineContentTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }
}

class _StorylinesSecondaryPanel extends StatelessWidget {
  const _StorylinesSecondaryPanel({
    required this.stories,
    required this.selectedStoryId,
    required this.stepCountsByStoryId,
  });

  final List<NarrativeScenarioSummary> stories;
  final String? selectedStoryId;
  final Map<String, int> stepCountsByStoryId;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('storylines-secondary-panel'),
      expandChild: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Storylines',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Semantics(
              key: const ValueKey('storylines-secondary-create-action'),
              button: true,
              enabled: false,
              label: 'Créer une storyline - à venir',
              child: const PokeMapButton(
                onPressed: null,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: Icon(CupertinoIcons.add),
                child: Text('+'),
              ),
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PokeMapStatusTile(
              key: ValueKey('storylines-secondary-search-disabled'),
              label: 'Recherche à venir',
              value: 'Filtrage bientôt disponible',
              icon: CupertinoIcons.search,
              tone: PokeMapTone.neutral,
            ),
            const SizedBox(height: 12),
            _StorylinesSectionLabel(
              label: 'Histoire principale',
              color: colors.textSecondary,
            ),
            const SizedBox(height: 8),
            if (stories.isEmpty)
              Text(
                'Aucune storyline principale disponible.',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              )
            else
              ...stories.map(
                (story) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylineSummaryRow(
                    story: story,
                    selected: story.id == selectedStoryId,
                    stepCount: stepCountsByStoryId[story.id] ?? 0,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _StorylinesSectionLabel(
              label: 'Quêtes annexes',
              color: colors.textSecondary,
            ),
            const SizedBox(height: 8),
            const PokeMapStatusTile(
              key: ValueKey('storylines-secondary-side-quests-disabled'),
              label: 'Quêtes annexes',
              value: 'À venir',
              icon: CupertinoIcons.lock,
              tone: PokeMapTone.neutral,
            ),
            const SizedBox(height: 8),
            Text(
              'À venir — aucun modèle de quête annexe n’est encore branché.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesSectionLabel extends StatelessWidget {
  const _StorylinesSectionLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StorylineSummaryRow extends StatelessWidget {
  const _StorylineSummaryRow({
    required this.story,
    required this.selected,
    required this.stepCount,
  });

  final NarrativeScenarioSummary story;
  final bool selected;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = story.description.trim();
    return PokeMapCard(
      key: ValueKey('storylines-secondary-row-${story.id}'),
      selected: selected,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.book,
            tone: PokeMapTone.narrative,
            size: 30,
            iconSize: 15,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.name,
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
                  description.isEmpty
                      ? 'Description non renseignée.'
                      : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Storyline principale',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatStepCount(stepCount),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Read-only / Source réelle',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatStepCount(int count) {
    return count == 1 ? '1 étape narrative' : '$count étapes narratives';
  }
}

class _StorylineMainPanel extends StatelessWidget {
  const _StorylineMainPanel({
    required this.selectedStory,
    required this.steps,
    required this.chapters,
    required this.selectedTab,
    required this.onTabSelected,
    required this.stepCount,
    required this.chapterCount,
    required this.globalStoryCount,
    required this.linkedCutsceneCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final List<NarrativeStepSummary> steps;
  final List<NarrativeChapterSummary> chapters;
  final _StorylineContentTab selectedTab;
  final ValueChanged<_StorylineContentTab> onTabSelected;
  final int stepCount;
  final int chapterCount;
  final int globalStoryCount;
  final int linkedCutsceneCount;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey('storylines-main-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylineHeaderSection(
            selectedStory: selectedStory,
          ),
          const SizedBox(height: 12),
          _StorylineTabsRow(
            selectedTab: selectedTab,
            onTabSelected: onTabSelected,
          ),
          const SizedBox(height: 12),
          _StorylineKpiStrip(
            globalStoryCount: globalStoryCount,
            stepCount: stepCount,
            chapterCount: chapterCount,
            linkedCutsceneCount: linkedCutsceneCount,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: selectedTab == _StorylineContentTab.chapters
                ? _StorylineChaptersSection(chapters: chapters)
                : _StorylineGraphSection(
                    chapters: chapters,
                    steps: steps,
                  ),
          ),
        ],
      ),
    );
  }
}

enum _StorylineContentTab {
  graph,
  chapters,
}

class _StorylineGraphSection extends StatelessWidget {
  const _StorylineGraphSection({
    required this.chapters,
    required this.steps,
  });

  final List<NarrativeChapterSummary> chapters;
  final List<NarrativeStepSummary> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final hasChapters = chapters.isNotEmpty;
    return PokeMapPageSurface(
      key: const ValueKey('storylines-graph-target-read-only'),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableCanvasHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight - 56
              : 380.0;
          final canvasHeight =
              availableCanvasHeight < 360 ? 360.0 : availableCanvasHeight;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PokeMapIconTile(
                      icon: CupertinoIcons.arrow_branch,
                      tone: PokeMapTone.narrative,
                      size: 34,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Graph read-only',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasChapters
                                ? 'Canvas spatial issu de Global Story Studio. Les steps restent visibles en aperçu, sans relations inventées.'
                                : 'Lecture linéaire prudente depuis Step Studio. Les relations détaillées restent non branchées.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (chapters.isEmpty && steps.isEmpty)
                  const _StorylineGraphEmptyState()
                else
                  SizedBox(
                    height: canvasHeight,
                    child: _StorylineGraphCanvas(
                      chapters: chapters,
                      steps: steps,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StorylineGraphCanvas extends StatelessWidget {
  const _StorylineGraphCanvas({
    required this.chapters,
    required this.steps,
  });

  final List<NarrativeChapterSummary> chapters;
  final List<NarrativeStepSummary> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 48
                ? constraints.maxWidth - 24
                : 720.0;
        final canvasHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 360.0;
        final nodes =
            chapters.isNotEmpty ? _chapterSpatialNodes() : _stepSpatialNodes();
        final geometry = _StorylineGraphGeometry.compute(
          size: Size(canvasWidth, canvasHeight),
          nodeCount: nodes.length,
        );
        return Container(
          key: const ValueKey('storylines-graph-canvas'),
          constraints: BoxConstraints(
            minWidth: canvasWidth,
            minHeight: canvasHeight,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StorylineGraphGridPainter(
                    lineColor: colors.borderSubtle.withValues(alpha: 0.46),
                    accentLineColor:
                        colors.brandPrimaryBorder.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned.fill(
                child: KeyedSubtree(
                  key: const ValueKey('storylines-graph-main-flow'),
                  child: KeyedSubtree(
                    key: const ValueKey('storylines-graph-spatial-layer'),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            key: const ValueKey('storylines-graph-edge-layer'),
                            painter: _StorylineGraphEdgePainter(
                              edges: geometry.edges,
                              lineColor:
                                  colors.textMuted.withValues(alpha: 0.72),
                              arrowColor: colors.brandPrimaryBorder
                                  .withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                        for (var index = 0; index < nodes.length; index++)
                          Positioned(
                            left: geometry.positions[index].left,
                            top: geometry.positions[index].top,
                            width: geometry.positions[index].width,
                            child: nodes[index],
                          ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 10,
                            children: [
                              _StorylineGraphLegend(
                                chapterCount: chapters.length,
                                stepCount: steps.length,
                              ),
                              const _StorylineGraphReadOnlyControls(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _chapterSpatialNodes() {
    return <Widget>[
      const _StorylineGraphBoundaryNode(
        key: ValueKey('storylines-graph-node-start'),
        title: 'Début de lecture',
        subtitle: 'Projection read-only',
        icon: CupertinoIcons.play_circle,
        tone: PokeMapTone.success,
      ),
      for (final chapter in chapters)
        _StorylineGraphChapterNode(chapter: chapter),
      const _StorylineGraphBoundaryNode(
        key: ValueKey('storylines-graph-node-read-only-note'),
        title: 'Relations à venir',
        subtitle: 'Aucune branche inventée',
        icon: CupertinoIcons.lock,
        tone: PokeMapTone.neutral,
      ),
    ];
  }

  List<Widget> _stepSpatialNodes() {
    return <Widget>[
      const _StorylineGraphBoundaryNode(
        key: ValueKey('storylines-graph-node-start'),
        title: 'Début de lecture',
        subtitle: 'Projection read-only',
        icon: CupertinoIcons.play_circle,
        tone: PokeMapTone.success,
      ),
      for (var index = 0; index < steps.length; index++)
        _StorylineGraphStepNode(
          step: steps[index],
          position: index + 1,
        ),
      const _StorylineGraphBoundaryNode(
        key: ValueKey('storylines-graph-node-read-only-note'),
        title: 'Relations à venir',
        subtitle: 'Aucune branche inventée',
        icon: CupertinoIcons.lock,
        tone: PokeMapTone.neutral,
      ),
    ];
  }
}

class _StorylineGraphGeometry {
  const _StorylineGraphGeometry({
    required this.positions,
    required this.edges,
  });

  final List<_StorylineGraphNodePosition> positions;
  final List<_StorylineGraphEdge> edges;

  static _StorylineGraphGeometry compute({
    required Size size,
    required int nodeCount,
  }) {
    final compact = size.width < 760;
    final nodeWidth = compact ? 152.0 : 172.0;
    final nodeHeight = compact ? 112.0 : 124.0;
    final positions = <_StorylineGraphNodePosition>[];

    if (compact) {
      const horizontalPadding = 24.0;
      const topPadding = 26.0;
      final columnGap =
          _bounded(size.width - horizontalPadding * 2 - nodeWidth * 2, 28, 96);
      const leftColumn = horizontalPadding;
      final rightColumn = horizontalPadding + nodeWidth + columnGap;
      final rowCount = (nodeCount / 2).ceil().clamp(1, 4);
      final rowSpacing = _bounded(
        (size.height - 104 - topPadding - nodeHeight) / rowCount,
        104,
        150,
      );
      for (var index = 0; index < nodeCount; index++) {
        final row = index ~/ 2;
        final left = index.isEven ? leftColumn : rightColumn;
        positions.add(
          _StorylineGraphNodePosition(
            left: left,
            top: topPadding + row * rowSpacing,
            width: nodeWidth,
            height: nodeHeight,
          ),
        );
      }
    } else {
      const horizontalPadding = 26.0;
      final availableWidth = size.width - horizontalPadding * 2 - nodeWidth;
      final step = nodeCount <= 1 ? 0.0 : availableWidth / (nodeCount - 1);
      final baseTop = _bounded(
        (size.height - 92 - nodeHeight) / 2,
        42,
        130,
      );
      for (var index = 0; index < nodeCount; index++) {
        final isChapterNode = index > 0 && index < nodeCount - 1;
        final amplitude = nodeCount > 4 && size.height > 430 ? 38.0 : 0.0;
        final lift = isChapterNode && index.isOdd ? -amplitude : 0.0;
        final drop = isChapterNode && index.isEven ? amplitude : 0.0;
        positions.add(
          _StorylineGraphNodePosition(
            left: horizontalPadding + step * index,
            top: baseTop + lift + drop,
            width: nodeWidth,
            height: nodeHeight,
          ),
        );
      }
    }

    return _StorylineGraphGeometry(
      positions: positions,
      edges: _buildEdges(positions),
    );
  }

  static List<_StorylineGraphEdge> _buildEdges(
    List<_StorylineGraphNodePosition> positions,
  ) {
    final edges = <_StorylineGraphEdge>[];
    for (var index = 0; index < positions.length - 1; index++) {
      final from = positions[index];
      final to = positions[index + 1];
      edges.add(
        _StorylineGraphEdge(
          from: to.left > from.left ? from.centerRight : from.bottomCenter,
          to: to.left > from.left ? to.centerLeft : to.topCenter,
        ),
      );
    }
    return edges;
  }

  static double _bounded(double value, double min, double max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

class _StorylineGraphNodePosition {
  const _StorylineGraphNodePosition({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  Offset get centerLeft => Offset(left, top + height / 2);
  Offset get centerRight => Offset(left + width, top + height / 2);
  Offset get topCenter => Offset(left + width / 2, top);
  Offset get bottomCenter => Offset(left + width / 2, top + height);
}

class _StorylineGraphEdge {
  const _StorylineGraphEdge({
    required this.from,
    required this.to,
  });

  final Offset from;
  final Offset to;
}

class _StorylineGraphChapterNode extends StatelessWidget {
  const _StorylineGraphChapterNode({
    required this.chapter,
  });

  final NarrativeChapterSummary chapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final visibleSteps = chapter.steps.take(2).toList(growable: false);
    final remainingStepCount = chapter.steps.length - visibleSteps.length;
    return PokeMapCard(
      key: ValueKey('storylines-graph-node-${chapter.id}'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.book,
                tone: PokeMapTone.narrative,
                size: 28,
                iconSize: 13,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapitre ${chapter.order + 1}',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      chapter.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatFrenchCount(
              chapter.steps.length,
              singular: 'étape narrative liée',
              plural: 'étapes narratives liées',
            ),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (visibleSteps.isEmpty)
            Text(
              'Aucune étape narrative liée à ce chapitre.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.25,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in visibleSteps) ...[
                  _StorylineGraphStepPreview(step: step),
                  if (step != visibleSteps.last) const SizedBox(height: 6),
                ],
                if (remainingStepCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+ ${_formatFrenchCount(
                      remainingStepCount,
                      singular: 'étape narrative réelle',
                      plural: 'étapes narratives réelles',
                    )}',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StorylineGraphStepNode extends StatelessWidget {
  const _StorylineGraphStepNode({
    required this.step,
    required this.position,
  });

  final NarrativeStepSummary step;
  final int position;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = step.description.trim();
    return PokeMapCard(
      key: ValueKey('storylines-graph-step-node-${step.id}'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.smallcircle_fill_circle,
                tone: PokeMapTone.info,
                size: 28,
                iconSize: 12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Étape narrative $position',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StorylineGraphStepPreview extends StatelessWidget {
  const _StorylineGraphStepPreview({
    required this.step,
  });

  final NarrativeStepSummary step;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = step.description.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokeMapIconTile(
          icon: CupertinoIcons.smallcircle_fill_circle,
          tone: PokeMapTone.info,
          size: 20,
          iconSize: 8,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StorylineGraphBoundaryNode extends StatelessWidget {
  const _StorylineGraphBoundaryNode({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PokeMapIconTile(
            icon: icon,
            tone: tone,
            size: 28,
            iconSize: 13,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylineGraphEdgePainter extends CustomPainter {
  const _StorylineGraphEdgePainter({
    required this.edges,
    required this.lineColor,
    required this.arrowColor,
  });

  final List<_StorylineGraphEdge> edges;
  final Color lineColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) {
      return;
    }
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    for (final edge in edges) {
      final path = Path()..moveTo(edge.from.dx, edge.from.dy);
      final horizontalDistance = edge.to.dx - edge.from.dx;
      if (horizontalDistance.abs() > 36) {
        path.cubicTo(
          edge.from.dx + horizontalDistance * 0.44,
          edge.from.dy,
          edge.to.dx - horizontalDistance * 0.44,
          edge.to.dy,
          edge.to.dx,
          edge.to.dy,
        );
      } else {
        final midY = (edge.from.dy + edge.to.dy) / 2;
        path.cubicTo(
          edge.from.dx,
          midY,
          edge.to.dx,
          midY,
          edge.to.dx,
          edge.to.dy,
        );
      }
      canvas.drawPath(path, linePaint);
      _drawArrow(canvas, edge, arrowPaint);
    }
  }

  void _drawArrow(Canvas canvas, _StorylineGraphEdge edge, Paint paint) {
    final direction = (edge.to - edge.from).direction;
    const arrowSize = 7.5;
    final arrow = Path()
      ..moveTo(edge.to.dx, edge.to.dy)
      ..lineTo(
        edge.to.dx - arrowSize * math.cos(direction - 0.46),
        edge.to.dy - arrowSize * math.sin(direction - 0.46),
      )
      ..lineTo(
        edge.to.dx - arrowSize * math.cos(direction + 0.46),
        edge.to.dy - arrowSize * math.sin(direction + 0.46),
      )
      ..close();
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant _StorylineGraphEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.arrowColor != arrowColor;
  }
}

class _StorylineGraphLegend extends StatelessWidget {
  const _StorylineGraphLegend({
    required this.chapterCount,
    required this.stepCount,
  });

  final int chapterCount;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: const ValueKey('storylines-graph-legend'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Wrap(
            spacing: 10,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _StorylineGraphLegendItem(
                icon: CupertinoIcons.play_circle,
                tone: PokeMapTone.success,
                label: 'Début / lecture',
                value: 'Projection',
              ),
              _StorylineGraphLegendItem(
                icon: CupertinoIcons.book,
                tone: PokeMapTone.narrative,
                label: 'Chapitre réel',
                value: '$chapterCount',
              ),
              _StorylineGraphLegendItem(
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.info,
                label: 'Étape narrative',
                value: '$stepCount',
              ),
              const _StorylineGraphLegendItem(
                icon: CupertinoIcons.lock,
                tone: PokeMapTone.neutral,
                label: 'Relations à venir',
                value: 'Read-only',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineGraphLegendItem extends StatelessWidget {
  const _StorylineGraphLegendItem({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final PokeMapTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapIconTile(
          icon: icon,
          tone: tone,
          size: 22,
          iconSize: 9,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label · $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StorylineGraphReadOnlyControls extends StatelessWidget {
  const _StorylineGraphReadOnlyControls();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: const ValueKey('storylines-graph-read-only-controls'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.lock,
                tone: PokeMapTone.neutral,
                size: 22,
                iconSize: 9,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Relations détaillées à venir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Contrôles non actifs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineGraphGridPainter extends CustomPainter {
  const _StorylineGraphGridPainter({
    required this.lineColor,
    required this.accentLineColor,
  });

  final Color lineColor;
  final Color accentLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = accentLineColor
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var x = 0.0; x <= size.width; x += 112) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    for (var y = 0.0; y <= size.height; y += 112) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StorylineGraphGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.accentLineColor != accentLineColor;
  }
}

class _StorylineGraphEmptyState extends StatelessWidget {
  const _StorylineGraphEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-graph-empty-state'),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.tray,
            tone: PokeMapTone.neutral,
            size: 34,
            iconSize: 15,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucune étape narrative disponible pour cette storyline.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylineChaptersSection extends StatefulWidget {
  const _StorylineChaptersSection({
    required this.chapters,
  });

  final List<NarrativeChapterSummary> chapters;

  @override
  State<_StorylineChaptersSection> createState() =>
      _StorylineChaptersSectionState();
}

class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
  String? _selectedChapterId;

  NarrativeChapterSummary? get _selectedChapter {
    if (widget.chapters.isEmpty) {
      return null;
    }
    final selectedId = _selectedChapterId;
    if (selectedId != null) {
      for (final chapter in widget.chapters) {
        if (chapter.id == selectedId) {
          return chapter;
        }
      }
    }
    return widget.chapters.first;
  }

  void _selectChapter(NarrativeChapterSummary chapter) {
    setState(() {
      _selectedChapterId = chapter.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selectedChapter = _selectedChapter;
    return PokeMapPageSurface(
      key: const ValueKey('storylines-chapters-read-only'),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.square_list,
                  tone: PokeMapTone.narrative,
                  size: 34,
                  iconSize: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapitres',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lecture read-only des chapitres issus de Global Story Studio.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const PokeMapButton(
                  key: ValueKey('storylines-chapters-create-action'),
                  onPressed: null,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: Icon(CupertinoIcons.plus, size: 14),
                  child: Text('Nouveau chapitre'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PokeMapStatusTile(
                  label: 'Chapitres réels',
                  value: '${widget.chapters.length}',
                  icon: CupertinoIcons.square_list,
                  tone: PokeMapTone.info,
                ),
                const PokeMapStatusTile(
                  label: 'Source',
                  value: 'Global Story Studio',
                  icon: CupertinoIcons.doc_text,
                  tone: PokeMapTone.neutral,
                ),
                const PokeMapStatusTile(
                  label: 'Mode',
                  value: 'Lecture seule',
                  icon: CupertinoIcons.lock,
                  tone: PokeMapTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.chapters.isEmpty)
              const _StorylineChaptersEmptyState()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final list = _StorylineChapterList(
                    chapters: widget.chapters,
                    selectedChapterId: selectedChapter?.id,
                    onChapterSelected: _selectChapter,
                  );
                  final inspector = _StorylineChapterInspector(
                    chapter: selectedChapter,
                  );
                  if (constraints.maxWidth < 740) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        list,
                        const SizedBox(height: 12),
                        inspector,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: math.min(330, constraints.maxWidth * 0.38),
                        child: list,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: inspector),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StorylineChapterList extends StatelessWidget {
  const _StorylineChapterList({
    required this.chapters,
    required this.selectedChapterId,
    required this.onChapterSelected,
  });

  final List<NarrativeChapterSummary> chapters;
  final String? selectedChapterId;
  final ValueChanged<NarrativeChapterSummary> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('storylines-chapter-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final chapter in chapters) ...[
          _StorylineChapterCard(
            chapter: chapter,
            selected: chapter.id == selectedChapterId,
            onTap: () => onChapterSelected(chapter),
          ),
          if (chapter != chapters.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StorylineChapterCard extends StatelessWidget {
  const _StorylineChapterCard({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final NarrativeChapterSummary chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = chapter.description.trim();
    final card = PokeMapCard(
      key: ValueKey('storylines-chapter-card-${chapter.id}'),
      padding: const EdgeInsets.all(12),
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.book,
                tone: PokeMapTone.narrative,
                size: 30,
                iconSize: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapitre ${chapter.order + 1}',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description.isEmpty
                          ? 'Description de chapitre non renseignée.'
                          : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapStatusTile(
                label: 'Étapes narratives liées',
                value: _formatFrenchCount(
                  chapter.steps.length,
                  singular: 'étape narrative',
                  plural: 'étapes narratives',
                ),
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.info,
              ),
              const PokeMapStatusTile(
                label: 'État',
                value: 'Lecture seule',
                icon: CupertinoIcons.lock,
                tone: PokeMapTone.neutral,
              ),
              if (chapter.missingStepIds.isNotEmpty)
                PokeMapStatusTile(
                  label: 'Références manquantes',
                  value: _formatFrenchCount(
                    chapter.missingStepIds.length,
                    singular: 'step absente',
                    plural: 'steps absentes',
                  ),
                  icon: CupertinoIcons.exclamationmark_triangle,
                  tone: PokeMapTone.warning,
                ),
            ],
          ),
        ],
      ),
    );
    if (!selected) {
      return card;
    }
    return KeyedSubtree(
      key: ValueKey('storylines-selected-chapter-${chapter.id}'),
      child: card,
    );
  }
}

class _StorylineChapterInspector extends StatelessWidget {
  const _StorylineChapterInspector({
    required this.chapter,
  });

  final NarrativeChapterSummary? chapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selectedChapter = chapter;
    if (selectedChapter == null) {
      return const _StorylineChapterInspectorEmptyState();
    }
    final description = selectedChapter.description.trim();
    return PokeMapCard(
      key: const ValueKey('storylines-chapter-inspector'),
      padding: const EdgeInsets.all(14),
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.book_fill,
                tone: PokeMapTone.narrative,
                size: 34,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du chapitre',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      selectedChapter.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description.isEmpty
                          ? 'Description de chapitre non renseignée.'
                          : description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapStatusTile(
                label: 'Ordre',
                value: '${selectedChapter.order + 1}',
                icon: CupertinoIcons.number,
                tone: PokeMapTone.info,
              ),
              const PokeMapStatusTile(
                label: 'Source Global Story Studio',
                value: 'Lecture seule',
                icon: CupertinoIcons.doc_text,
                tone: PokeMapTone.neutral,
              ),
              const PokeMapStatusTile(
                label: 'Mode',
                value: 'Lecture seule',
                icon: CupertinoIcons.lock,
                tone: PokeMapTone.neutral,
              ),
              PokeMapStatusTile(
                label: 'Étapes liées',
                value: _formatFrenchCount(
                  selectedChapter.steps.length,
                  singular: 'étape narrative',
                  plural: 'étapes narratives',
                ),
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.info,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Étapes narratives du chapitre',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ordre des étapes narratives',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _StorylineChapterStepOrderList(steps: selectedChapter.steps),
          if (selectedChapter.missingStepIds.isNotEmpty) ...[
            const SizedBox(height: 14),
            _StorylineMissingStepIds(ids: selectedChapter.missingStepIds),
          ],
          const SizedBox(height: 14),
          const PokeMapStatusTile(
            label: 'Données à venir',
            value: 'Modèle détaillé non branché',
            icon: CupertinoIcons.clock,
            tone: PokeMapTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _StorylineChapterStepOrderList extends StatelessWidget {
  const _StorylineChapterStepOrderList({
    required this.steps,
  });

  final List<NarrativeStepSummary> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    if (steps.isEmpty) {
      return Text(
        'Aucune étape narrative liée à ce chapitre.',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _StorylineChapterStepOrderRow(
            index: index,
            step: steps[index],
          ),
          if (index != steps.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _StorylineChapterStepOrderRow extends StatelessWidget {
  const _StorylineChapterStepOrderRow({
    required this.index,
    required this.step,
  });

  final int index;
  final NarrativeStepSummary step;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final order = (index + 1).toString().padLeft(2, '0');
    return Row(
      key: ValueKey('storylines-chapter-step-order-${step.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Center(
              child: Text(
                order,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Étape narrative',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.description.trim().isEmpty
                    ? 'Description d’étape narrative non renseignée.'
                    : step.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StorylineMissingStepIds extends StatelessWidget {
  const _StorylineMissingStepIds({
    required this.ids,
  });

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Étapes manquantes',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final id in ids) ...[
          PokeMapStatusTile(
            label: id,
            value: 'Référence read-only',
            icon: CupertinoIcons.exclamationmark_triangle,
            tone: PokeMapTone.warning,
          ),
          if (id != ids.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StorylineChapterInspectorEmptyState extends StatelessWidget {
  const _StorylineChapterInspectorEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-chapter-inspector'),
      padding: const EdgeInsets.all(14),
      child: Text(
        'Aucun chapitre sélectionné.',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StorylineChaptersEmptyState extends StatelessWidget {
  const _StorylineChaptersEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-chapters-empty-state'),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.tray,
            tone: PokeMapTone.neutral,
            size: 34,
            iconSize: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucun chapitre disponible pour cette storyline.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylineHeaderSection extends StatelessWidget {
  const _StorylineHeaderSection({
    required this.selectedStory,
  });

  final NarrativeScenarioSummary? selectedStory;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = selectedStory?.description.trim();
    return KeyedSubtree(
      key: const ValueKey('storylines-header-section'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.link,
            tone: PokeMapTone.narrative,
            size: 46,
            iconSize: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStory?.name ?? 'Storyline non disponible',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description == null || description.isEmpty
                      ? 'Description non renseignée dans le scénario.'
                      : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PokeMapStatusTile(
                      label: 'Type',
                      value: 'Storyline principale',
                      icon: CupertinoIcons.book,
                      tone: PokeMapTone.narrative,
                    ),
                    PokeMapStatusTile(
                      label: 'État',
                      value: 'Lecture seule',
                      icon: CupertinoIcons.lock,
                      tone: PokeMapTone.info,
                    ),
                    PokeMapStatusTile(
                      label: 'Source',
                      value: 'Source réelle',
                      icon: CupertinoIcons.doc_text,
                      tone: PokeMapTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const PokeMapStatusTile(
            label: 'Mode lecture seule',
            value: 'Storylines V0',
            icon: CupertinoIcons.lock,
            tone: PokeMapTone.info,
          ),
        ],
      ),
    );
  }
}

class _StorylineTabsRow extends StatelessWidget {
  const _StorylineTabsRow({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _StorylineContentTab selectedTab;
  final ValueChanged<_StorylineContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('storylines-tabs'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: PokeMapSegmentedTabs(
          tabs: [
            PokeMapSegmentedTab(
              label: 'Graph',
              selected: selectedTab == _StorylineContentTab.graph,
              icon: CupertinoIcons.arrow_branch,
              onTap: () => onTabSelected(_StorylineContentTab.graph),
            ),
            PokeMapSegmentedTab(
              label: 'Chapitres',
              selected: selectedTab == _StorylineContentTab.chapters,
              icon: CupertinoIcons.square_list,
              onTap: () => onTabSelected(_StorylineContentTab.chapters),
            ),
            const PokeMapSegmentedTab(
              label: 'Étapes',
              selected: false,
              icon: CupertinoIcons.list_bullet,
            ),
            const PokeMapSegmentedTab(
              label: 'Scènes',
              selected: false,
              icon: CupertinoIcons.film,
            ),
            const PokeMapSegmentedTab(
              label: 'Statistiques',
              selected: false,
              icon: CupertinoIcons.chart_bar,
            ),
            const PokeMapSegmentedTab(
              label: 'Tests',
              selected: false,
              icon: CupertinoIcons.checkmark_shield,
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylineKpiStrip extends StatelessWidget {
  const _StorylineKpiStrip({
    required this.globalStoryCount,
    required this.stepCount,
    required this.chapterCount,
    required this.linkedCutsceneCount,
  });

  final int globalStoryCount;
  final int stepCount;
  final int chapterCount;
  final int linkedCutsceneCount;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('storylines-kpi-strip'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              key: const ValueKey('storylines-kpi-global-stories'),
              width: 150,
              height: 128,
              child: PokeMapMetricCard(
                title: 'Storylines globales',
                value: '$globalStoryCount',
                subtitle: 'Source manifest',
                icon: CupertinoIcons.link,
                tone: PokeMapTone.narrative,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              key: const ValueKey('storylines-kpi-steps'),
              width: 150,
              height: 128,
              child: PokeMapMetricCard(
                title: 'Étapes narratives',
                value: '$stepCount',
                subtitle: 'Source Step Studio',
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.info,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              key: const ValueKey('storylines-kpi-cutscenes'),
              width: 150,
              height: 128,
              child: PokeMapMetricCard(
                title: 'Cutscenes liées',
                value: '$linkedCutsceneCount',
                subtitle: 'Références Step',
                icon: CupertinoIcons.film,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              key: const ValueKey('storylines-kpi-chapters'),
              width: 150,
              height: 128,
              child: PokeMapMetricCard(
                title: 'Chapitres',
                value: '$chapterCount',
                subtitle: 'Source Global Story',
                icon: CupertinoIcons.square_list,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            const SizedBox(
              key: ValueKey('storylines-kpi-diagnostics'),
              width: 150,
              height: 128,
              child: PokeMapMetricCard(
                title: 'Avertissements structurels',
                value: 'À venir',
                subtitle: 'Validator absent',
                icon: CupertinoIcons.exclamationmark_triangle,
                tone: PokeMapTone.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylineInspectorPanel extends StatelessWidget {
  const _StorylineInspectorPanel({
    required this.selectedStory,
    required this.stepCount,
    required this.linkedCutsceneCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final int stepCount;
  final int linkedCutsceneCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 96
                ? constraints.maxHeight - 88
                : 360.0;
        return PokeMapInspectorPanel(
          key: const ValueKey('storylines-inspector-read-only'),
          header: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              'Détails de la storyline',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: bodyHeight,
            child: SingleChildScrollView(
              child: selectedStory == null
                  ? const _StorylineInspectorEmptyState()
                  : _StorylineInspectorContent(
                      selectedStory: selectedStory!,
                      stepCount: stepCount,
                      linkedCutsceneCount: linkedCutsceneCount,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _StorylineInspectorContent extends StatelessWidget {
  const _StorylineInspectorContent({
    required this.selectedStory,
    required this.stepCount,
    required this.linkedCutsceneCount,
  });

  final NarrativeScenarioSummary selectedStory;
  final int stepCount;
  final int linkedCutsceneCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = selectedStory.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.link,
              tone: PokeMapTone.narrative,
              size: 38,
              iconSize: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedStory.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description.isEmpty
                        ? 'Description non renseignée dans le scénario.'
                        : description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const PokeMapStatusTile(
          label: 'Type',
          value: 'Storyline principale',
          icon: CupertinoIcons.book,
          tone: PokeMapTone.narrative,
        ),
        const SizedBox(height: 8),
        const PokeMapStatusTile(
          label: 'Source',
          value: 'ScenarioAsset globalStory',
          icon: CupertinoIcons.doc_text,
          tone: PokeMapTone.neutral,
        ),
        const SizedBox(height: 8),
        const PokeMapStatusTile(
          label: 'Mode',
          value: 'Lecture seule',
          icon: CupertinoIcons.lock,
          tone: PokeMapTone.info,
        ),
        const SizedBox(height: 12),
        _StorylineInspectorSection(
          title: 'Structure',
          child: PokeMapCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StorylineInspectorTextLine(
                  label: 'Étapes narratives',
                  value: _formatFrenchCount(
                    stepCount,
                    singular: 'étape narrative',
                    plural: 'étapes narratives',
                  ),
                ),
                const SizedBox(height: 6),
                _StorylineInspectorTextLine(
                  label: 'Cutscenes liées',
                  value: _formatFrenchCount(
                    linkedCutsceneCount,
                    singular: 'cutscene liée',
                    plural: 'cutscenes liées',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _StorylineInspectorFutureSection(),
      ],
    );
  }
}

class _StorylineInspectorSection extends StatelessWidget {
  const _StorylineInspectorSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _StorylineInspectorTextLine extends StatelessWidget {
  const _StorylineInspectorTextLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StorylineInspectorFutureSection extends StatelessWidget {
  const _StorylineInspectorFutureSection();

  @override
  Widget build(BuildContext context) {
    return const _StorylineInspectorSection(
      title: 'Fonctionnalités à venir',
      child: PokeMapCard(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StorylineInspectorTextLine(label: 'Tags', value: 'À venir'),
            SizedBox(height: 6),
            _StorylineInspectorTextLine(
              label: 'Règles du monde',
              value: 'Non branché',
            ),
            SizedBox(height: 6),
            _StorylineInspectorTextLine(label: 'Facts', value: 'Non branché'),
            SizedBox(height: 6),
            _StorylineInspectorTextLine(
              label: 'Activité récente',
              value: 'À venir',
            ),
            SizedBox(height: 6),
            _StorylineInspectorTextLine(
              label: 'Quêtes liées',
              value: 'Modèle absent en V0',
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylineInspectorEmptyState extends StatelessWidget {
  const _StorylineInspectorEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokeMapIconTile(
          icon: CupertinoIcons.tray,
          tone: PokeMapTone.neutral,
          size: 34,
          iconSize: 15,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Aucune storyline sélectionnée.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatFrenchCount(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count <= 1 ? singular : plural}';
}
