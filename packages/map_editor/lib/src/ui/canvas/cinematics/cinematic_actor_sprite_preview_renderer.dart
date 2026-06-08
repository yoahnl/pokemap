import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'cinematic_actor_sprite_preview_plan.dart';

class CinematicActorSpritePainter extends CustomPainter {
  const CinematicActorSpritePainter({
    required this.image,
    required this.spriteRef,
    required this.tileWidth,
    required this.tileHeight,
    required this.outOfBoundsColor,
  });

  final ui.Image image;
  final CinematicActorSpriteRef spriteRef;
  final int tileWidth;
  final int tileHeight;
  final Color outOfBoundsColor;

  @override
  void paint(Canvas canvas, Size size) {
    final src = spriteRef.sourceTileRect;
    final frameW = spriteRef.frameWidthTiles * tileWidth;
    final frameH = spriteRef.frameHeightTiles * tileHeight;
    final srcRect = Rect.fromLTWH(
      src.x * frameW.toDouble(),
      src.y * frameH.toDouble(),
      frameW.toDouble(),
      frameH.toDouble(),
    );

    if (srcRect.left < 0 ||
        srcRect.top < 0 ||
        srcRect.right > image.width ||
        srcRect.bottom > image.height) {
      // Out of bounds fallback: draw a crossed box with error color
      debugPrint(
        'WARNING (Painter): Actor sprite source rect is out of bounds. '
        'Source rect: $srcRect. Tileset image size: ${image.width}x${image.height}.',
      );
      final paint = Paint()
        ..color = outOfBoundsColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(Offset.zero & size, paint);
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
      return;
    }

    final destRect = Offset.zero & size;

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.drawImageRect(image, srcRect, destRect, paint);
  }

  @override
  bool shouldRepaint(covariant CinematicActorSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.spriteRef != spriteRef ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.outOfBoundsColor != outOfBoundsColor;
  }
}
