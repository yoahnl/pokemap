import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class PokeMapMediaPreviewSurface extends StatelessWidget {
  const PokeMapMediaPreviewSurface({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.checkerboard = true,
    this.borderRadius = 10,
  });

  final String semanticLabel;
  final Widget child;
  final bool checkerboard;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (checkerboard)
                CustomPaint(
                  key: const ValueKey<String>(
                    'pokemap-media-preview-checkerboard',
                  ),
                  painter: _PokeMapCheckerboardPainter(
                    first: colors.surfaceBase,
                    second: colors.surfaceSubtle,
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

final class _PokeMapCheckerboardPainter extends CustomPainter {
  const _PokeMapCheckerboardPainter({
    required this.first,
    required this.second,
  });

  final Color first;
  final Color second;

  @override
  void paint(Canvas canvas, Size size) {
    const extent = 12.0;
    for (var y = 0.0; y < size.height; y += extent) {
      for (var x = 0.0; x < size.width; x += extent) {
        final even = (x ~/ extent + y ~/ extent).isEven;
        canvas.drawRect(
          Rect.fromLTWH(x, y, extent, extent),
          Paint()..color = even ? first : second,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PokeMapCheckerboardPainter oldDelegate) {
    return oldDelegate.first != first || oldDelegate.second != second;
  }
}
