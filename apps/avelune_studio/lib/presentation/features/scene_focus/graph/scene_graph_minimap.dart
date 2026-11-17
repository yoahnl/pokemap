import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneGraphMinimap extends StatelessWidget {
  const SceneGraphMinimap({
    super.key,
    required this.view,
    required this.bounds,
    required this.viewport,
    required this.camera,
    required this.onCenter,
  });

  static const _size = Size(140, 76);
  final SceneGraphView view;
  final Rect bounds;
  final Size viewport;
  final ValueListenable<SceneGraphCamera> camera;
  final ValueChanged<Offset> onCenter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final map = SceneGraphCamera.fit(bounds, _size, margin: StudioSpacing.s);
    void navigate(Offset point) {
      final world = map.toWorld(point);
      onCenter(
        Offset(
          world.dx.clamp(bounds.left, bounds.right),
          world.dy.clamp(bounds.top, bounds.bottom),
        ),
      );
    }

    return Semantics(
      label: context.l10n.sceneGraphNavigationOverview,
      child: Material(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          key: const ValueKey('scene-graph-minimap'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => navigate(details.localPosition),
          onPanUpdate: (details) => navigate(details.localPosition),
          child: ValueListenableBuilder(
            valueListenable: camera,
            builder: (context, current, _) => CustomPaint(
              size: _size,
              painter: _OverviewPainter(
                view: view,
                map: map,
                visible: Rect.fromPoints(
                  current.toWorld(Offset.zero),
                  current.toWorld(viewport.bottomRight(Offset.zero)),
                ),
                nodeColor: scheme.onSurfaceVariant,
                frameColor: StudioColors.of(context).canvasSelection,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewPainter extends CustomPainter {
  const _OverviewPainter({
    required this.view,
    required this.map,
    required this.visible,
    required this.nodeColor,
    required this.frameColor,
  });

  final SceneGraphView view;
  final SceneGraphCamera map;
  final Rect visible;
  final Color nodeColor;
  final Color frameColor;

  Rect _project(Rect world) => Rect.fromPoints(
    map.toScreen(world.topLeft),
    map.toScreen(world.bottomRight),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final node = Paint()..color = nodeColor;
    for (final card in view.cards) {
      canvas.drawRect(_project(sceneGraphCardRect(card)).inflate(.35), node);
    }
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = frameColor;
    final rectangle = _project(visible)
        .intersect((Offset.zero & size).deflate(2));
    if (!rectangle.isEmpty) canvas.drawRect(rectangle, frame);
  }

  @override
  bool shouldRepaint(_OverviewPainter oldDelegate) =>
      oldDelegate.view != view ||
      oldDelegate.map != map ||
      oldDelegate.visible != visible ||
      oldDelegate.nodeColor != nodeColor ||
      oldDelegate.frameColor != frameColor;
}
