import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

void paintMapWarpTransition(
  Canvas canvas,
  Size size,
  MapWarpTransition transition,
  double coverage, {
  required bool revealing,
}) {
  if (!coverage.isFinite ||
      size.isEmpty ||
      transition.type == MapWarpTransitionType.none) {
    return;
  }
  final covered = coverage.clamp(0.0, 1.0);
  if (covered == 0) return;
  final paint = Paint()..color = const Color(0xff000000);
  if (transition.type == MapWarpTransitionType.hgss && revealing) {
    final height = size.height * covered / 2;
    if (height <= 0) return;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, height), paint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - height, size.width, height),
      paint,
    );
    return;
  }
  paint.color = paint.color.withValues(alpha: covered);
  canvas.drawRect(Offset.zero & size, paint);
}

class MapWarpTransitionOverlay extends StatelessWidget {
  const MapWarpTransitionOverlay({
    super.key,
    required this.transition,
    required this.coverage,
    required this.revealing,
  });

  final MapWarpTransition transition;
  final double coverage;
  final bool revealing;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _MapWarpTransitionPainter(transition, coverage, revealing),
      size: Size.infinite,
    ),
  );
}

class _MapWarpTransitionPainter extends CustomPainter {
  const _MapWarpTransitionPainter(
    this.transition,
    this.coverage,
    this.revealing,
  );

  final MapWarpTransition transition;
  final double coverage;
  final bool revealing;

  @override
  void paint(Canvas canvas, Size size) => paintMapWarpTransition(
    canvas,
    size,
    transition,
    coverage,
    revealing: revealing,
  );

  @override
  bool shouldRepaint(_MapWarpTransitionPainter oldDelegate) =>
      transition != oldDelegate.transition ||
      coverage != oldDelegate.coverage ||
      revealing != oldDelegate.revealing;
}

class MapWarpTransitionPreview extends StatefulWidget {
  const MapWarpTransitionPreview({
    super.key,
    required this.transition,
    required this.child,
  });

  final MapWarpTransition transition;
  final Widget child;

  @override
  State<MapWarpTransitionPreview> createState() =>
      _MapWarpTransitionPreviewState();
}

class _MapWarpTransitionPreviewState extends State<MapWarpTransitionPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const _holdSeconds = .15;
  double get _seconds => widget.transition.durationSeconds * 2 + _holdSeconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _play();
  }

  @override
  void didUpdateWidget(MapWarpTransitionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transition != widget.transition) _play();
  }

  void _play() {
    _controller.duration = Duration(microseconds: (_seconds * 1000000).round());
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final elapsed = _controller.value * _seconds;
      final duration = widget.transition.durationSeconds;
      final revealing = elapsed >= duration + _holdSeconds;
      final coverage = widget.transition.type == MapWarpTransitionType.none
          ? 0.0
          : elapsed < duration
          ? elapsed / duration
          : !revealing
          ? 1.0
          : 1 - (elapsed - duration - _holdSeconds) / duration;
      return Stack(
        fit: StackFit.expand,
        children: [
          child!,
          MapWarpTransitionOverlay(
            transition: widget.transition,
            coverage: coverage.clamp(0.0, 1.0),
            revealing: revealing,
          ),
        ],
      );
    },
  );
}
