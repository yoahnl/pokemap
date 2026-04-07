/// Paramètres **nommés et documentés** pour la génération « Pixel Alpha ».
///
/// Aucune heuristique cachée : seulement le canal alpha et un ratio minimal
/// optionnel par cellule (anti-bruit d’échantillonnage).
class AlphaCollisionGenerationParams {
  const AlphaCollisionGenerationParams({
    this.alphaThreshold = kAlphaCollisionOpaqueThreshold,
    this.minimumOpaquePixelRatioPerCell =
        kAlphaCollisionMinOpaqueRatioPerCell,
  });

  /// Seuil d’opacité (0–255). Un pixel avec `alpha <= alphaThreshold` est
  /// traité comme **transparent** → ne contribue pas à la collision.
  ///
  /// Valeur basse (ex. 24) : les semi-transparents très légers sont ignorés.
  final int alphaThreshold;

  /// Dans chaque cellule, proportion minimale de pixels **opaques** (au-dessus
  /// du seuil) pour marquer la cellule comme bloquante.
  ///
  /// - `0.0` : **au moins un pixel** opaque suffit (fidélité maximale au sprite).
  /// - `0.01` : au moins ~1 % de la surface de la cellule (filtre un peu de bruit).
  final double minimumOpaquePixelRatioPerCell;

  /// Valeurs par défaut du produit (prévisibles, documentées).
  static const AlphaCollisionGenerationParams defaults =
      AlphaCollisionGenerationParams();
}

/// Seuil par défaut : en dessous, le pixel est considéré comme transparent.
const int kAlphaCollisionOpaqueThreshold = 24;

/// Par défaut : toute cellule contenant au moins un pixel opaque compte.
const double kAlphaCollisionMinOpaqueRatioPerCell = 0.0;
