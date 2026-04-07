import '../models/geometry.dart';
import 'pixel_rect.dart';

/// Conventions **figées V1** pour le joueur : position sprite, hitbox déplacement.
///
/// Document de référence produit (addendum validé) :
/// - [playerSpriteTopLeftPx] : coin haut-gauche du rectangle de **rendu** du sprite
///   dans le repère monde pixels ;
/// - hitbox déplacement : rectangle 12×8 px, **centré horizontalement** dans le
///   sprite, **bord bas du rectangle = bord bas du sprite**.
///
/// La projection vers la grille (warps, triggers, interactions) utilise le
/// **centre du bord inférieur** de la hitbox, puis `floor(x / tileWidth)`,
/// pas la position sprite seule.
class PlayerCollisionConventionsV1 {
  PlayerCollisionConventionsV1._();

  /// Taille d’affichage par défaut du sprite joueur (V1).
  /// Peut être remplacée par des métadonnées projet plus tard ; tant que ce
  /// n’est pas le cas, gameplay et runtime utilisent ces constantes.
  static const int defaultSpriteWidthPx = 32;
  static const int defaultSpriteHeightPx = 32;

  /// Hitbox déplacement : largeur / hauteur (addendum).
  static const int playerHitboxWidthPx = 12;
  static const int playerHitboxHeightPx = 8;

  /// Déplacement par intention [MoveIntent] : nombre de pixels essayés le long
  /// d’un axe cardinal (une « pulsation » de déplacement, pas une case cible).
  static const int defaultMoveStepPixels = 16;

  /// Hitbox joueur dans le repère monde, dérivée du coin haut-gauche sprite.
  static PixelRect playerCollisionRectFromSpriteTopLeft({
    required PixelPosition spriteTopLeftPx,
    required int spriteWidthPx,
    required int spriteHeightPx,
  }) {
    final w = playerHitboxWidthPx;
    final h = playerHitboxHeightPx;
    final left =
        spriteTopLeftPx.leftPx + (spriteWidthPx - w) ~/ 2;
    final top = spriteTopLeftPx.topPx + spriteHeightPx - h;
    return PixelRect(
      leftPx: left,
      topPx: top,
      widthPx: w,
      heightPx: h,
    );
  }

  /// Place le sprite pour que le personnage « tienne » dans la cellule de grille
  /// `(cellX, cellY)` : bas du sprite aligné sur le bas de la cellule, centré
  /// horizontalement (ex. tile 16×16, sprite 32×32 → coin haut-gauche
  /// `(cellX*16 + 8, (cellY+1)*16 - 32)`).
  static PixelPosition playerSpriteTopLeftFromSpawnCell({
    required int cellX,
    required int cellY,
    required int tileWidthPx,
    required int tileHeightPx,
    required int spriteWidthPx,
    required int spriteHeightPx,
  }) {
    return PixelPosition(
      leftPx: cellX * tileWidthPx + (tileWidthPx - spriteWidthPx) ~/ 2,
      topPx: (cellY + 1) * tileHeightPx - spriteHeightPx,
    );
  }

  /// Projection **grille** officielle : centre du bas de la hitbox → cellule.
  ///
  /// Utilisée uniquement pour warps / triggers / interactions (systèmes encore
  /// indexés par cellule). **Ne pas** utiliser comme primitive de collision
  /// déplacement.
  static GridPos projectFeetAnchorToCell({
    required PixelRect playerCollisionRectPx,
    required int tileWidthPx,
    required int tileHeightPx,
    required int mapWidthCells,
    required int mapHeightCells,
  }) {
    final bc = playerCollisionRectPx.bottomCenterPx;
    final maxX = mapWidthCells * tileWidthPx - 1;
    final maxY = mapHeightCells * tileHeightPx - 1;
    final x = bc.xPx.clamp(0, maxX);
    final y = bc.yPx.clamp(0, maxY);
    return GridPos(
      x: x ~/ tileWidthPx,
      y: y ~/ tileHeightPx,
    );
  }
}
