import 'package:map_core/map_core.dart';

/// Résolution de déplacement **pixel** par essais séparés horizontal / vertical.
///
/// Pas de cible `(tx, ty)` en case : on translate [spriteTopLeftPx] puis on teste
/// la hitbox déplacement ([PlayerCollisionConventionsV1]) contre le monde statique.
class PixelMovementResolverV1 {
  PixelMovementResolverV1._();

  /// Retourne la nouvelle position coin haut-gauche sprite si au moins un axe
  /// peut bouger ; sinon retourne la position d’entrée (blocage complet).
  static PixelPosition resolveSeparateAxis({
    required PixelPosition spriteTopLeftPx,
    required int deltaXPx,
    required int deltaYPx,
    required int spriteWidthPx,
    required int spriteHeightPx,
    required bool Function(PixelRect rect) worldStaticObstaclesCollidePixelRect,
  }) {
    PixelRect hitboxAt(PixelPosition topLeft) =>
        PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: topLeft,
          spriteWidthPx: spriteWidthPx,
          spriteHeightPx: spriteHeightPx,
        );

    bool pathIsClear(PixelPosition target) {
      final dx = target.leftPx - spriteTopLeftPx.leftPx;
      final dy = target.topPx - spriteTopLeftPx.topPx;
      final steps = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
      if (steps == 0) {
        return !worldStaticObstaclesCollidePixelRect(hitboxAt(target));
      }
      for (var step = 1; step <= steps; step++) {
        final position = PixelPosition(
          leftPx: spriteTopLeftPx.leftPx + (dx * step / steps).round(),
          topPx: spriteTopLeftPx.topPx + (dy * step / steps).round(),
        );
        if (worldStaticObstaclesCollidePixelRect(hitboxAt(position))) {
          return false;
        }
      }
      return true;
    }

    final tryFull = PixelPosition(
      leftPx: spriteTopLeftPx.leftPx + deltaXPx,
      topPx: spriteTopLeftPx.topPx + deltaYPx,
    );
    if (pathIsClear(tryFull)) {
      return tryFull;
    }
    final tryX = PixelPosition(
      leftPx: spriteTopLeftPx.leftPx + deltaXPx,
      topPx: spriteTopLeftPx.topPx,
    );
    if (pathIsClear(tryX)) {
      return tryX;
    }
    final tryY = PixelPosition(
      leftPx: spriteTopLeftPx.leftPx,
      topPx: spriteTopLeftPx.topPx + deltaYPx,
    );
    if (pathIsClear(tryY)) {
      return tryY;
    }
    return spriteTopLeftPx;
  }
}
