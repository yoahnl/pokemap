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

    final tryFull = PixelPosition(
      leftPx: spriteTopLeftPx.leftPx + deltaXPx,
      topPx: spriteTopLeftPx.topPx + deltaYPx,
    );
    if (!worldStaticObstaclesCollidePixelRect(hitboxAt(tryFull))) {
      return tryFull;
    }
    final tryX = PixelPosition(
      leftPx: spriteTopLeftPx.leftPx + deltaXPx,
      topPx: spriteTopLeftPx.topPx,
    );
    if (!worldStaticObstaclesCollidePixelRect(hitboxAt(tryX))) {
      return tryX;
    }
    final tryY = PixelPosition(
      leftPx: spriteTopLeftPx.leftPx,
      topPx: spriteTopLeftPx.topPx + deltaYPx,
    );
    if (!worldStaticObstaclesCollidePixelRect(hitboxAt(tryY))) {
      return tryY;
    }
    return spriteTopLeftPx;
  }
}
