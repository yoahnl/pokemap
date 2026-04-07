/// Coordonnées d’un **point** dans le repère monde (pixels entiers).
///
/// Distinct de [PixelPosition] : ce type sert aux ancres ponctuelles (ex. centre
/// du bas de la hitbox) alors que [PixelPosition] modélise le coin haut-gauche
/// du sprite joueur dans les conventions V1.
class PixelPoint {
  const PixelPoint({required this.xPx, required this.yPx});

  final int xPx;
  final int yPx;
}

/// Coin haut-gauche d’un sprite ou d’un rectangle logique dans le monde (px).
class PixelPosition {
  const PixelPosition({
    required this.leftPx,
    required this.topPx,
  });

  final int leftPx;
  final int topPx;
}

/// Rectangle axis-aligned en pixels monde (grille continue, pas la grille case).
class PixelRect {
  const PixelRect({
    required this.leftPx,
    required this.topPx,
    required this.widthPx,
    required this.heightPx,
  });

  final int leftPx;
  final int topPx;
  final int widthPx;
  final int heightPx;

  /// Centre du bord **inférieur** (pixels entiers, bord inclusif du rectangle).
  ///
  /// C’est l’ancre officielle pour la projection grille
  /// [PlayerCollisionConventionsV1.projectFeetAnchorToCell] — à ne pas confondre
  /// avec le coin bas-gauche ni avec le centre géométrique du rectangle.
  PixelPoint get bottomCenterPx => PixelPoint(
        xPx: leftPx + widthPx ~/ 2,
        yPx: topPx + heightPx - 1,
      );
}
