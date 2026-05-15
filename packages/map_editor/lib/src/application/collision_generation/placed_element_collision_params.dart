/// Paramètres d’auto-génération des masques collision.
///
/// Le générateur part de l’occupation visuelle alpha, puis applique les
/// heuristiques V1 pour dériver `collisionMask` et `occlusionMask`.
/// `cells` reste une projection de compatibilité du `collisionMask`, pas une
/// source de vérité séparée.
class PlacedElementCollisionGenerationParams {
  const PlacedElementCollisionGenerationParams({
    this.alphaThreshold = kCollisionAlphaOpaqueThreshold,
  });

  /// Pixels avec `alpha <= alphaThreshold` sont transparents pour le masque.
  final int alphaThreshold;

  static const PlacedElementCollisionGenerationParams defaults =
      PlacedElementCollisionGenerationParams();
}

/// Seuil alpha : au-dessus = pixel visible pour l’analyse automatique.
const int kCollisionAlphaOpaqueThreshold = 24;
