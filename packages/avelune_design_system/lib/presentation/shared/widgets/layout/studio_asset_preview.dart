import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';

class StudioAssetPreview extends StatelessWidget {
  const StudioAssetPreview({
    super.key,
    required this.child,
    this.height,
    this.checkerboard = true,
  });
  final Widget child;
  final double? height;
  final bool checkerboard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _PreviewBackground(
            colors.surfaceContainerLowest,
            colors.surfaceContainer,
            checkerboard,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _PreviewBackground extends CustomPainter {
  const _PreviewBackground(this.base, this.alternate, this.checkerboard);
  final Color base, alternate;
  final bool checkerboard;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    if (!checkerboard) return;
    final paint = Paint()..color = alternate;
    for (var row = 0; row * 12 < size.height; row++) {
      for (var col = row % 2; col * 12 < size.width; col += 2) {
        canvas.drawRect(Rect.fromLTWH(col * 12, row * 12, 12, 12), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewBackground old) =>
      base != old.base ||
      alternate != old.alternate ||
      checkerboard != old.checkerboard;
}
