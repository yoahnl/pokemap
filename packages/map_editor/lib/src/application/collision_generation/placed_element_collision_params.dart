/// Paramètres d’auto-génération **sans heuristique grille** (addendum produit).
///
/// L’auto-génération V1 copie l’occupation visuelle (alpha) vers le masque
/// gameplay pixel à pixel. L’utilisateur affine ensuite manuellement dans l’éditeur.
/// Aucune « bande basse », « empreinte de cellule » ou « ratio par cellule » ici.
class PlacedElementCollisionGenerationParams {
  const PlacedElementCollisionGenerationParams({
    this.alphaThreshold = kCollisionAlphaOpaqueThreshold,
  });

  /// Pixels avec `alpha <= alphaThreshold` sont transparents pour le masque.
  final int alphaThreshold;

  static const PlacedElementCollisionGenerationParams defaults =
      PlacedElementCollisionGenerationParams();
}

/// Seuil alpha : au-dessus = pixel potentiellement solide dans le masque auto.
const int kCollisionAlphaOpaqueThreshold = 24;
