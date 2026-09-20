import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import 'story_graph_source_picker.dart';
import 'story_graph_geometry.dart';
import 'story_view_state.dart';

class StoryGraphControls extends StatelessWidget {
  const StoryGraphControls({
    super.key,
    required this.graph,
    required this.state,
    required this.positions,
    this.selection,
  });
  final StoryGraphGeometry graph;
  final StoryViewState state;
  final Map<String, Offset> positions;
  final StoryGraphSelection? selection;
  @override
  Widget build(BuildContext context) {
    final view = state.viewport;
    return StudioGraphCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudioTool(
            key: const ValueKey('story-graph-zoom-out'),
            label: 'Dézoomer',
            onPressed: () =>
                view.zoomAt(view.zoom * .9, view.size.center(Offset.zero)),
            icon: Icons.remove,
          ),
          Text(
            '${(view.zoom * 100).round()} %',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          StudioTool(
            key: const ValueKey('story-graph-zoom-in'),
            label: 'Zoomer',
            onPressed: () =>
                view.zoomAt(view.zoom * 1.1, view.size.center(Offset.zero)),
            icon: Icons.add,
          ),
          StudioTool(
            label: 'Cadrer l’histoire',
            onPressed: () => state.fit(graph.bounds(positions)),
            icon: Icons.fit_screen,
          ),
          if (selection?.node != null && graph.nodes.containsKey(selection!.id))
            StudioTool(
              label: 'Cadrer la sélection',
              onPressed: () =>
                  view.centerOn(graph.rect(selection!.id, positions).center),
              icon: Icons.center_focus_strong,
            ),
          StudioTool(
            label: 'Annuler le déplacement visuel',
            onPressed: state.canUndo ? state.undo : null,
            icon: Icons.undo,
          ),
          StudioTool(
            label: 'Rétablir le déplacement visuel',
            onPressed: state.canRedo ? state.redo : null,
            icon: Icons.redo,
          ),
          StudioTool(
            label: 'Afficher une source',
            icon: Icons.add_link,
            onPressed: () async {
              final id = await chooseStoryGraphSource(context, graph);
              if (!context.mounted || id == null) return;
              id.startsWith('fact:')
                  ? state.revealFact(id.substring(5))
                  : state.revealStory(id.substring(10));
            },
          ),
          StudioTool(
            label: 'Mini-carte',
            onPressed: state.toggleMinimap,
            icon: Icons.map_outlined,
          ),
        ],
      ),
    );
  }
}

class StoryGraphMinimap extends StatelessWidget {
  const StoryGraphMinimap({
    super.key,
    required this.graph,
    required this.state,
    required this.positions,
  });
  final StoryGraphGeometry graph;
  final StoryViewState state;
  final Map<String, Offset> positions;
  @override
  Widget build(BuildContext context) {
    final bounds = graph.bounds(positions).inflate(40);
    const size = Size(166, 100);
    void move(Offset point) => state.viewport.centerOn(
      Offset(
        bounds.left + point.dx / size.width * bounds.width,
        bounds.top + point.dy / size.height * bounds.height,
      ),
    );
    return StudioGraphCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vue d’ensemble', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 6),
            GestureDetector(
              key: const ValueKey('story-graph-minimap'),
              onTapDown: (e) => move(e.localPosition),
              onPanUpdate: (e) => move(e.localPosition),
              child: CustomPaint(
                size: size,
                painter: _MiniPainter(
                  graph,
                  state,
                  positions,
                  bounds,
                  Theme.of(context).colorScheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(
    this.graph,
    this.state,
    this.positions,
    this.bounds,
    this.colors,
  );
  final StoryGraphGeometry graph;
  final StoryViewState state;
  final Map<String, Offset> positions;
  final Rect bounds;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    Rect project(Rect r) => Rect.fromLTWH(
      (r.left - bounds.left) / bounds.width * size.width,
      (r.top - bounds.top) / bounds.height * size.height,
      r.width / bounds.width * size.width,
      r.height / bounds.height * size.height,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final id in graph.defaults.keys) {
      canvas.drawRect(
        project(graph.rect(id, positions)),
        Paint()..color = colors.secondary.withValues(alpha: .55),
      );
    }
    final view = state.viewport;
    canvas.drawRect(
      project(
        Rect.fromPoints(
          view.localToWorld(Offset.zero),
          view.localToWorld(view.size.bottomRight(Offset.zero)),
        ),
      ),
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniPainter oldDelegate) => true;
}
