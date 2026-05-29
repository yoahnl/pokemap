import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class SceneGraphReadOnlyView extends StatelessWidget {
  const SceneGraphReadOnlyView({
    super.key,
    required this.scene,
  });

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final layout = _SceneGraphLayoutPlan.fromScene(scene);

    return PokeMapCard(
      key: const ValueKey('scene-graph-read-only-view'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.flowchart,
                tone: PokeMapTone.narrative,
                size: 34,
                iconSize: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Graph read-only',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SceneGraphBadge(
                key: ValueKey(
                  layout.usesPersistedLayout
                      ? 'scene-graph-layout-source-real'
                      : 'scene-graph-layout-source-derived',
                ),
                label: layout.usesPersistedLayout
                    ? 'Layout réel'
                    : 'Layout dérivé',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: layout.canvasHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.backgroundShell,
                  border: Border.all(color: colors.borderSubtle),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SceneGraphEdgePainter(
                          edges: scene.graph.edges,
                          positions: layout.positions,
                          lineColor: colors.borderStrong,
                          labelColor: colors.textSecondary,
                          labelBackground: colors.cardSurface,
                        ),
                      ),
                    ),
                    for (final node in scene.graph.nodes)
                      _SceneGraphNodeCard(
                        node: node,
                        position: layout.positions[node.id]!,
                      ),
                    for (final edge in scene.graph.edges)
                      _SceneGraphEdgeLabel(
                        edge: edge,
                        position: layout.edgeLabelPosition(edge),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneGraphNodeCard extends StatelessWidget {
  const _SceneGraphNodeCard({
    required this.node,
    required this.position,
  });

  final SceneNode node;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _toneForNode(node.kind);
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _SceneGraphLayoutPlan.nodeWidth,
      height: _SceneGraphLayoutPlan.nodeHeight,
      child: PokeMapCard(
        key: ValueKey('scene-graph-node-${node.id}'),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PokeMapIconTile(
                  icon: _iconForNode(node.kind),
                  tone: tone,
                  size: 24,
                  iconSize: 13,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    node.title ?? _nodeKindLabel(node.kind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _nodeKindLabel(node.kind),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (node.description != null) ...[
              const SizedBox(height: 4),
              Text(
                node.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneGraphEdgeLabel extends StatelessWidget {
  const _SceneGraphEdgeLabel({
    required this.edge,
    required this.position,
  });

  final SceneEdge edge;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: ValueKey('scene-graph-edge-${edge.id}'),
      left: position.dx,
      top: position.dy,
      child: _SceneGraphBadge(
        label:
            edge.label ?? '${_edgeKindLabel(edge.kind)} · ${edge.fromPortId}',
      ),
    );
  }
}

class _SceneGraphBadge extends StatelessWidget {
  const _SceneGraphBadge({
    super.key,
    required this.label,
  });

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SceneGraphEdgePainter extends CustomPainter {
  const _SceneGraphEdgePainter({
    required this.edges,
    required this.positions,
    required this.lineColor,
    required this.labelColor,
    required this.labelBackground,
  });

  final List<SceneEdge> edges;
  final Map<String, Offset> positions;
  final Color lineColor;
  final Color labelColor;
  final Color labelBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = positions[edge.fromNodeId];
      final to = positions[edge.toNodeId];
      if (from == null || to == null) {
        continue;
      }
      final start = Offset(
        from.dx + _SceneGraphLayoutPlan.nodeWidth,
        from.dy + (_SceneGraphLayoutPlan.nodeHeight / 2),
      );
      final end = Offset(
        to.dx,
        to.dy + (_SceneGraphLayoutPlan.nodeHeight / 2),
      );
      final controlDistance = math.max(48, (end.dx - start.dx).abs() / 2);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + controlDistance,
          start.dy,
          end.dx - controlDistance,
          end.dy,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, paint);
      _drawArrow(canvas, paint, end);
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset end) {
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 7, end.dy - 4)
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 7, end.dy + 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SceneGraphEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.positions != positions ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.labelBackground != labelBackground;
  }
}

class _SceneGraphLayoutPlan {
  const _SceneGraphLayoutPlan({
    required this.positions,
    required this.usesPersistedLayout,
    required this.canvasHeight,
  });

  static const nodeWidth = 168.0;
  static const nodeHeight = 104.0;
  static const horizontalGap = 92.0;
  static const verticalGap = 34.0;

  final Map<String, Offset> positions;
  final bool usesPersistedLayout;
  final double canvasHeight;

  static _SceneGraphLayoutPlan fromScene(NarrativeSceneSummary scene) {
    final persisted = {
      for (final layout in scene.layout.nodeLayouts)
        layout.nodeId: Offset(layout.x, layout.y),
    };
    final hasCompleteLayout =
        scene.graph.nodes.every((node) => persisted.containsKey(node.id));
    final positions = hasCompleteLayout
        ? persisted
        : _derivePositions(scene.graph.nodes, scene.graph.edges);

    final maxY = positions.values.fold<double>(
      0,
      (value, position) => math.max(value, position.dy),
    );
    return _SceneGraphLayoutPlan(
      positions: positions,
      usesPersistedLayout: hasCompleteLayout && positions.isNotEmpty,
      canvasHeight: math.max(280, maxY + nodeHeight + 32),
    );
  }

  static Map<String, Offset> _derivePositions(
    List<SceneNode> nodes,
    List<SceneEdge> edges,
  ) {
    if (nodes.isEmpty) {
      return {};
    }

    final nodeIds = nodes.map((node) => node.id).toSet();
    final adjacency = <String, List<String>>{
      for (final node in nodes) node.id: <String>[],
    };
    final incomingCount = <String, int>{
      for (final node in nodes) node.id: 0,
    };

    for (final edge in edges) {
      if (!nodeIds.contains(edge.fromNodeId) ||
          !nodeIds.contains(edge.toNodeId)) {
        continue;
      }
      adjacency[edge.fromNodeId]!.add(edge.toNodeId);
      incomingCount[edge.toNodeId] = (incomingCount[edge.toNodeId] ?? 0) + 1;
    }

    final levels = <String, int>{};
    final visited = <String>{};

    void traverseFrom(String startNodeId) {
      if (!visited.add(startNodeId)) {
        return;
      }
      levels[startNodeId] = 0;
      final queue = <String>[startNodeId];
      for (var cursor = 0; cursor < queue.length; cursor++) {
        final current = queue[cursor];
        final currentLevel = levels[current] ?? 0;
        for (final next in adjacency[current] ?? const <String>[]) {
          if (!visited.add(next)) {
            continue;
          }
          levels[next] = currentLevel + 1;
          queue.add(next);
        }
      }
    }

    final roots = [
      for (final node in nodes)
        if ((incomingCount[node.id] ?? 0) == 0) node.id,
    ];
    for (final root in roots.isEmpty ? <String>[nodes.first.id] : roots) {
      traverseFrom(root);
    }

    for (var index = 0; index < nodes.length; index++) {
      final nodeId = nodes[index].id;
      if (!visited.contains(nodeId)) {
        traverseFrom(nodeId);
      }
      levels.putIfAbsent(nodeId, () => index);
    }

    final rowByLevel = <int, int>{};
    final positions = <String, Offset>{};
    for (final node in nodes) {
      final level = levels[node.id] ?? 0;
      final row =
          rowByLevel.update(level, (value) => value + 1, ifAbsent: () => 0);
      positions[node.id] = Offset(
        24 + (level * (nodeWidth + horizontalGap)),
        42 + (row * (nodeHeight + verticalGap)),
      );
    }
    return positions;
  }

  Offset edgeLabelPosition(SceneEdge edge) {
    final from = positions[edge.fromNodeId];
    final to = positions[edge.toNodeId];
    if (from == null || to == null) {
      return const Offset(12, 12);
    }
    return Offset(
      (from.dx + to.dx + nodeWidth) / 2 - 38,
      (from.dy + to.dy + nodeHeight) / 2 - 14,
    );
  }
}

PokeMapTone _toneForNode(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => PokeMapTone.success,
    SceneNodeKind.end => PokeMapTone.info,
    SceneNodeKind.yarnDialogue => PokeMapTone.info,
    SceneNodeKind.condition => PokeMapTone.warning,
    SceneNodeKind.action => PokeMapTone.warning,
    SceneNodeKind.battle => PokeMapTone.danger,
    SceneNodeKind.cinematic => PokeMapTone.narrative,
    SceneNodeKind.branchByOutcome => PokeMapTone.narrative,
    SceneNodeKind.merge => PokeMapTone.neutral,
  };
}

IconData _iconForNode(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => CupertinoIcons.play_circle,
    SceneNodeKind.end => CupertinoIcons.flag,
    SceneNodeKind.yarnDialogue => CupertinoIcons.text_bubble,
    SceneNodeKind.condition => CupertinoIcons.check_mark_circled,
    SceneNodeKind.action => CupertinoIcons.bolt,
    SceneNodeKind.battle => CupertinoIcons.asterisk_circle,
    SceneNodeKind.cinematic => CupertinoIcons.film,
    SceneNodeKind.branchByOutcome => CupertinoIcons.arrow_branch,
    SceneNodeKind.merge => CupertinoIcons.arrow_merge,
  };
}

String _nodeKindLabel(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => 'Début',
    SceneNodeKind.end => 'Fin',
    SceneNodeKind.yarnDialogue => 'Dialogue Yarn',
    SceneNodeKind.condition => 'Condition',
    SceneNodeKind.action => 'Action',
    SceneNodeKind.battle => 'Combat',
    SceneNodeKind.cinematic => 'Cinématique',
    SceneNodeKind.branchByOutcome => 'Branche',
    SceneNodeKind.merge => 'Merge',
  };
}

String _edgeKindLabel(SceneEdgeKind kind) {
  return switch (kind) {
    SceneEdgeKind.defaultFlow => 'default',
    SceneEdgeKind.conditionTrue => 'true',
    SceneEdgeKind.conditionFalse => 'false',
    SceneEdgeKind.dialogueOutcome => 'dialogue',
    SceneEdgeKind.battleVictory => 'victory',
    SceneEdgeKind.battleDefeat => 'defeat',
    SceneEdgeKind.cinematicCompleted => 'cinematic',
    SceneEdgeKind.actionCompleted => 'action',
    SceneEdgeKind.branchOutcome => 'branch',
    SceneEdgeKind.error => 'error',
    SceneEdgeKind.blocked => 'blocked',
  };
}
