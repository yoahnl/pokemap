import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Fond de scène par défaut pour le lot 1.
///
/// Garde-fous de périmètre :
/// - ce composant vit côté `map_runtime` parce qu'il ne transporte aucune
///   vérité métier battle ; il ne fait que peindre une ambiance de scène ;
/// - il reste volontairement statique et local à ce lot ;
/// - il n'essaie pas de résoudre un biome, une map ou un contexte trainer/wild :
///   ce vrai seam appartient explicitement au lot 2.
class BattleSceneBackdropComponent extends PositionComponent {
  BattleSceneBackdropComponent({
    required Vector2 size,
  }) : super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 0,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);

    // Le lot 1 assume un seul fond par défaut :
    // - suffisamment riche pour sortir du panneau noir central ;
    // - suffisamment simple pour ne pas singer le futur resolver contextuel.
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.y),
        const <Color>[
          Color(0xFF16243B),
          Color(0xFF263B5D),
          Color(0xFF4F7A79),
          Color(0xFF99A56E),
        ],
        const <double>[0.0, 0.36, 0.72, 1.0],
      );
    canvas.drawRect(rect, skyPaint);

    final horizonGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * 0.52, size.y * 0.42),
        size.x * 0.42,
        const <Color>[
          Color(0x55FFF7C8),
          Color(0x11FFF7C8),
          Color(0x00000000),
        ],
        const <double>[0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, horizonGlowPaint);

    final bandPaint = Paint()..color = const Color(0x12FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.08, size.y * 0.18, size.x * 0.62, 22),
        const Radius.circular(14),
      ),
      bandPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.28, size.x * 0.52, 18),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0x10FFFFFF),
    );

    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.y * 0.58),
        Offset(0, size.y),
        const <Color>[
          Color(0x14000000),
          Color(0x4411161E),
          Color(0xCC0B0E14),
        ],
        const <double>[0.0, 0.34, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.58, size.x, size.y * 0.42),
      floorPaint,
    );
  }
}
