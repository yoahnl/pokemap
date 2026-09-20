import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_node.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';

class SceneCanvasLayer extends StatelessWidget {
  const SceneCanvasLayer({
    super.key,
    required this.geometry,
    required this.viewport,
    required this.positions,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onCancel,
    required this.onWireStart,
    required this.onWireMove,
    required this.onWireEnd,
    this.selectedNodeId,
    this.sourceNodeId,
    this.targetNodeId,
    this.highlighted = const {},
    this.summary,
  });
  final SceneCanvasGeometry geometry;
  final SceneGraphViewport viewport;
  final Map<String, Offset> positions;
  final String? selectedNodeId, sourceNodeId, targetNodeId;
  final Set<String> highlighted;
  final ValueChanged<String> onSelect, onDragStart;
  final ValueChanged<Offset> onDragMove, onWireMove;
  final VoidCallback onDragEnd, onCancel, onWireEnd;
  final void Function(String, String) onWireStart;
  final String Function(SceneNode)? summary;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      for (final node in geometry.nodes.values) _node(context, node),
      for (final node in geometry.nodes.values) ..._ports(context, node),
    ],
  );
  Widget _node(BuildContext context, SceneNode node) {
    final position = viewport.worldToLocal(
      positions[node.id] ?? geometry.positions[node.id]!,
    );
    final size = geometry.nodeSize(node.id);
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: size.width * viewport.zoom,
      height: size.height * viewport.zoom,
      child: Transform.scale(
        scale: viewport.zoom,
        alignment: Alignment.topLeft,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: SceneCanvasNode(
            node: node,
            size: size,
            selected: selectedNodeId == node.id,
            highlighted: highlighted.contains(node.id),
            summary: summary?.call(node),
            onSelect: () => onSelect(node.id),
            onStart: () => onDragStart(node.id),
            onMove: (delta) => onDragMove(delta * viewport.zoom),
            onEnd: onDragEnd,
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }

  List<Widget> _ports(BuildContext context, SceneNode node) {
    final color = sceneNodeColor(context, node.kind);
    final compatible =
        sourceNodeId != null &&
        sourceNodeId != node.id &&
        node.kind != SceneNodeKind.start;
    return [
      if (node.kind != SceneNodeKind.start)
        _port(
          viewport.worldToLocal(geometry.input(node.id, positions)),
          SceneCanvasPort(
            key: ValueKey('scene-graph-input-port-${node.id}-in'),
            label: 'Entrée · ${node.title ?? sceneKindLabel(node.kind)}',
            color: color,
            compatible: compatible,
            hovered: targetNodeId == node.id,
          ),
        ),
      for (final port
          in geometry.ports[node.id] ?? <SceneAuthorableOutputPort>[]) ...[
        _port(
          viewport.worldToLocal(geometry.output(node.id, port.id, positions)),
          SceneCanvasPort(
            key: ValueKey('scene-graph-output-port-${node.id}-${port.id}'),
            output: true,
            label: scenePortLabel(port.id),
            color: color,
            disabled: geometry.occupied.contains('${node.id}:${port.id}'),
            onStart: () => onWireStart(node.id, port.id),
            onMove: onWireMove,
            onEnd: onWireEnd,
            onCancel: onCancel,
          ),
        ),
        Positioned(
          left:
              viewport
                  .worldToLocal(geometry.output(node.id, port.id, positions))
                  .dx -
              126 * viewport.zoom,
          top:
              viewport
                  .worldToLocal(geometry.output(node.id, port.id, positions))
                  .dy -
              9 * viewport.zoom,
          width: 110 * viewport.zoom,
          height: 20 * viewport.zoom,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 110,
                height: 20,
                child: Text(
                  scenePortLabel(port.id),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ),
          ),
        ),
      ],
    ];
  }

  Widget _port(Offset point, Widget child) =>
      Positioned(left: point.dx - 14, top: point.dy - 14, child: child);
}
