import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioRoleThumbnailPainter extends CustomPainter {
  const SurfaceStudioRoleThumbnailPainter({
    required this.role,
    required this.assigned,
  });

  final SurfaceVariantRole role;
  final bool assigned;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = assigned
          ? const Color(0xFF1D6EEB).withValues(alpha: 0.92)
          : SurfaceStudioDesignTokens.backgroundDeep;
    final accent = Paint()
      ..color = assigned
          ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.48)
          : SurfaceStudioDesignTokens.textMuted.withValues(alpha: 0.42);
    final shape = Paint()
      ..color = assigned
          ? const Color(0xFF7BCFFF).withValues(alpha: 0.88)
          : SurfaceStudioDesignTokens.borderStrong;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
      bg,
    );

    final inset = size.shortestSide * 0.18;
    final inner = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    Rect bandTop() =>
        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.35);
    Rect bandBottom() => Rect.fromLTWH(inner.left,
        inner.bottom - inner.height * 0.35, inner.width, inner.height * 0.35);
    Rect bandLeft() =>
        Rect.fromLTWH(inner.left, inner.top, inner.width * 0.35, inner.height);
    Rect bandRight() => Rect.fromLTWH(inner.right - inner.width * 0.35,
        inner.top, inner.width * 0.35, inner.height);
    Rect bandH() => Rect.fromLTWH(
        inner.left,
        inner.center.dy - inner.height * 0.18,
        inner.width,
        inner.height * 0.36);
    Rect bandV() => Rect.fromLTWH(inner.center.dx - inner.width * 0.18,
        inner.top, inner.width * 0.36, inner.height);

    void draw(Rect rect) => canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          shape,
        );

    switch (role) {
      case SurfaceVariantRole.isolated:
        draw(inner);
      case SurfaceVariantRole.endNorth:
        draw(bandTop());
      case SurfaceVariantRole.endEast:
        draw(bandRight());
      case SurfaceVariantRole.endSouth:
        draw(bandBottom());
      case SurfaceVariantRole.endWest:
        draw(bandLeft());
      case SurfaceVariantRole.horizontal:
        draw(bandH());
      case SurfaceVariantRole.vertical:
        draw(bandV());
      case SurfaceVariantRole.cornerNW:
        draw(bandTop());
        draw(bandLeft());
      case SurfaceVariantRole.cornerNE:
        draw(bandTop());
        draw(bandRight());
      case SurfaceVariantRole.cornerSW:
        draw(bandBottom());
        draw(bandLeft());
      case SurfaceVariantRole.cornerSE:
        draw(bandBottom());
        draw(bandRight());
      case SurfaceVariantRole.innerCornerNW:
        draw(Rect.fromLTWH(inner.center.dx, inner.center.dy, inner.width / 2,
            inner.height / 2));
      case SurfaceVariantRole.innerCornerNE:
        draw(Rect.fromLTWH(
            inner.left, inner.center.dy, inner.width / 2, inner.height / 2));
      case SurfaceVariantRole.innerCornerSW:
        draw(Rect.fromLTWH(
            inner.center.dx, inner.top, inner.width / 2, inner.height / 2));
      case SurfaceVariantRole.innerCornerSE:
        draw(Rect.fromLTWH(
            inner.left, inner.top, inner.width / 2, inner.height / 2));
      case SurfaceVariantRole.teeNorth:
        draw(bandTop());
        draw(bandV());
      case SurfaceVariantRole.teeEast:
        draw(bandRight());
        draw(bandH());
      case SurfaceVariantRole.teeSouth:
        draw(bandBottom());
        draw(bandV());
      case SurfaceVariantRole.teeWest:
        draw(bandLeft());
        draw(bandH());
      case SurfaceVariantRole.cross:
        draw(bandH());
        draw(bandV());
    }

    final stroke = Paint()
      ..color = accent.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioRoleThumbnailPainter oldDelegate) =>
      oldDelegate.role != role || oldDelegate.assigned != assigned;
}
