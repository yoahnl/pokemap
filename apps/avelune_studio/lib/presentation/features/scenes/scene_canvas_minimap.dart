import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';

class SceneCanvasMinimap extends StatelessWidget {
  const SceneCanvasMinimap({
    super.key,
    required this.geometry,
    required this.viewport,
  });
  final SceneCanvasGeometry geometry;
  final SceneGraphViewport viewport;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bounds = geometry.bounds({}).inflate(40);
    void center(Offset local, Size size) => viewport.centerOn(
      Offset(
        local.dx / size.width * bounds.width + bounds.left,
        local.dy / size.height * bounds.height + bounds.top,
      ),
    );
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: SizedBox(
        width: 176,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mini-carte', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    key: const ValueKey('scene-minimap'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (e) =>
                        center(e.localPosition, constraints.biggest),
                    onPanUpdate: (e) =>
                        center(e.localPosition, constraints.biggest),
                    child: CustomPaint(
                      size: constraints.biggest,
                      painter: _MiniPainter(
                        geometry,
                        viewport,
                        bounds,
                        colors.primary,
                        colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(
    this.geometry,
    this.view,
    this.bounds,
    this.primary,
    this.secondary,
  );
  final SceneCanvasGeometry geometry;
  final SceneGraphViewport view;
  final Rect bounds;
  final Color primary, secondary;
  @override
  void paint(Canvas canvas, Size size) {
    Rect project(Rect rect) => Rect.fromLTRB(
      (rect.left - bounds.left) / bounds.width * size.width,
      (rect.top - bounds.top) / bounds.height * size.height,
      (rect.right - bounds.left) / bounds.width * size.width,
      (rect.bottom - bounds.top) / bounds.height * size.height,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final id in geometry.nodes.keys) {
      canvas.drawRect(
        project(geometry.nodeRect(id, {})),
        Paint()..color = secondary.withValues(alpha: .65),
      );
    }
    final visible = Rect.fromPoints(
      view.localToWorld(Offset.zero),
      view.localToWorld(view.size.bottomRight(Offset.zero)),
    );
    canvas.drawRect(
      project(visible),
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniPainter oldDelegate) => true;
}
