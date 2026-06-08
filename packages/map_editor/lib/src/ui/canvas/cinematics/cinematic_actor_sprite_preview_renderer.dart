import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'cinematic_actor_sprite_preview_plan.dart';

class CinematicActorSpritePainter extends CustomPainter {
  const CinematicActorSpritePainter({
    required this.image,
    required this.spriteRef,
    required this.tileWidth,
    required this.tileHeight,
  });

  final ui.Image image;
  final CinematicActorSpriteRef spriteRef;
  final int tileWidth;
  final int tileHeight;

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
        oldDelegate.tileHeight != tileHeight;
  }
}
