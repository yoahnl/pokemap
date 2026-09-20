import 'package:flutter/material.dart';

class StudioConnectionDiagram extends StatelessWidget {
  const StudioConnectionDiagram({
    super.key,
    required this.mask,
    this.size = 36,
  });
  final int mask;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ConnectionPainter(mask, Theme.of(context).colorScheme),
    ),
  );
}

class _ConnectionPainter extends CustomPainter {
  const _ConnectionPainter(this.mask, this.colors);
  final int mask;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 3;
    final cells = <(int, int, bool)>[
      (1, 0, mask & 1 != 0),
      (2, 1, mask & 2 != 0),
      (1, 2, mask & 4 != 0),
      (0, 1, mask & 8 != 0),
      (1, 1, true),
    ];
    for (final (x, y, active) in cells) {
      final rect = Rect.fromLTWH(
        x * cell + 1,
        y * cell + 1,
        cell - 2,
        cell - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = active ? colors.primary : colors.surfaceContainerHighest,
      );
      if (x == 1 && y == 1) {
        canvas.drawCircle(
          rect.center,
          cell * .14,
          Paint()..color = colors.onPrimary,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter old) =>
      mask != old.mask || colors != old.colors;
}
