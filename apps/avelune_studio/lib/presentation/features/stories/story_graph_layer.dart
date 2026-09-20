import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'story_graph_geometry.dart';
import 'story_view_state.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';

class StoryGraphLayer extends StatelessWidget {
  const StoryGraphLayer({
    super.key,
    required this.graph,
    required this.state,
    required this.positions,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onCancel,
    required this.onWireStart,
    required this.onWireMove,
    required this.onWireEnd,
    required this.onAddStep,
    this.selection,
    this.targetId,
    this.onOpenScene,
  });
  final StoryGraphGeometry graph;
  final StoryViewState state;
  final Map<String, Offset> positions;
  final StoryGraphSelection? selection;
  final String? targetId;
  final ValueChanged<StorylineProgressionNode> onSelect, onWireStart;
  final ValueChanged<String> onDragStart, onAddStep;
  final ValueChanged<Offset> onDragMove, onWireMove;
  final VoidCallback onDragEnd, onCancel, onWireEnd;
  final ValueChanged<String>? onOpenScene;
  @override
  Widget build(BuildContext context) {
    final view = state.viewport;
    final visible = Rect.fromPoints(
      view.localToWorld(Offset.zero),
      view.localToWorld(view.size.bottomRight(Offset.zero)),
    ).inflate(80);
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        for (final id in graph.defaults.keys)
          if (graph.rect(id, positions).overlaps(visible))
            Positioned(
              left: view.worldToLocal(graph.rect(id, positions).topLeft).dx,
              top: view.worldToLocal(graph.rect(id, positions).topLeft).dy,
              width: graph.rect(id, positions).width * view.zoom,
              height: graph.rect(id, positions).height * view.zoom,
              child: Transform.scale(
                scale: view.zoom,
                alignment: Alignment.topLeft,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxWidth: graph.rect(id, positions).width,
                  minWidth: graph.rect(id, positions).width,
                  maxHeight: graph.rect(id, positions).height,
                  minHeight: graph.rect(id, positions).height,
                  child: Tooltip(
                    message: graph.nodes[id]!.label,
                    child: _card(context, graph.nodes[id]!),
                  ),
                ),
              ),
            ),
        for (final node in graph.nodes.values)
          if (graph.rect(node.id, positions).overlaps(visible)) ...[
            if (graph.canSource(node)) _port(context, node, true, colors),
            if (node.kind == StorylineProgressionNodeKind.step ||
                node.kind == StorylineProgressionNodeKind.storyline)
              _port(context, node, false, colors),
          ],
      ],
    );
  }

  Widget _card(BuildContext context, StorylineProgressionNode node) {
    final colors = Theme.of(context).colorScheme;
    final selected = selection?.id == node.id;
    final chapter = node.kind == StorylineProgressionNodeKind.chapter;
    var trackpad = false;
    return StudioGraphCard(
      selected: selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: ValueKey('story-graph-node-${node.id}'),
            onTap: () => onSelect(node),
            onPanStart: (e) {
              trackpad = e.kind == PointerDeviceKind.trackpad;
              if (!trackpad) onDragStart(node.id);
            },
            onPanUpdate: (e) {
              if (!trackpad && !state.viewport.trackpadActive) {
                onDragMove(e.delta * state.viewport.zoom);
              }
            },
            onPanEnd: (_) {
              if (!trackpad && !state.viewport.trackpadActive) onDragEnd();
            },
            onPanCancel: () {
              if (!trackpad) onCancel();
            },
            child: SizedBox(
              height: graph.headerHeight,
              child: ColoredBox(
                color: colors.primary.withValues(alpha: chapter ? .22 : .08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        chapter
                            ? Icons.auto_stories_outlined
                            : _icon(node.kind),
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (node.isMissing)
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: colors.error,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (chapter) ...[
            const SizedBox(height: 10),
            for (final step
                in graph.steps[node.id] ?? <StorylineProgressionNode>[])
              SizedBox(
                height: graph.stepHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Material(
                    color: selection?.id == step.id
                        ? colors.primaryContainer
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      key: ValueKey('story-graph-node-${step.id}'),
                      onTap: () => onSelect(step),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.radio_button_unchecked,
                              size: 12,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: graph.footerHeight,
              child: TextButton.icon(
                onPressed: () => onAddStep(node.canonicalId),
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'Ajouter une étape',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                _kindLabel(node.kind),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _port(
    BuildContext context,
    StorylineProgressionNode node,
    bool output,
    ColorScheme colors,
  ) {
    final world = output
        ? graph.output(node.id, positions)
        : graph.input(node.id, positions);
    final point = state.viewport.worldToLocal(world);
    return Positioned(
      left: point.dx - 14,
      top: point.dy - 14,
      width: 28,
      height: 28,
      child: Tooltip(
        message: '${output ? 'Relier depuis' : 'Cible'} : ${node.label}',
        child: Listener(
          key: ValueKey(
            'story-graph-${output ? 'output' : 'input'}-${node.id}',
          ),
          behavior: HitTestBehavior.opaque,
          onPointerDown: output ? (_) => onWireStart(node) : null,
          onPointerMove: output ? (e) => onWireMove(e.position) : null,
          onPointerUp: output ? (_) => onWireEnd() : null,
          onPointerCancel: output ? (_) => onCancel() : null,
          child: Center(
            child: Container(
              width: targetId == node.id ? 18 : 12,
              height: targetId == node.id ? 18 : 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: output ? colors.primary : colors.surface,
                border: Border.all(color: colors.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(StorylineProgressionNodeKind kind) => switch (kind) {
    StorylineProgressionNodeKind.fact => Icons.flag_outlined,
    StorylineProgressionNodeKind.sceneOutcome => Icons.movie_outlined,
    StorylineProgressionNodeKind.condition => Icons.rule,
    _ => Icons.route_outlined,
  };
  String _kindLabel(StorylineProgressionNodeKind kind) => switch (kind) {
    StorylineProgressionNodeKind.fact => 'Fait du monde',
    StorylineProgressionNodeKind.sceneOutcome => 'Résultat de scénario',
    StorylineProgressionNodeKind.condition =>
      'Condition composée · lecture seule',
    StorylineProgressionNodeKind.step => 'Étape introuvable',
    _ => 'Histoire',
  };
}
