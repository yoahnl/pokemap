/// Paramètres documentés pour l’auto-génération **Pokémon-like** des collisions
/// d’éléments posés.
///
/// **Deux notions distinctes** (ne pas confondre) :
/// - **Occupation visuelle** : où le sprite est opaque (décoration, feuillage).
/// - **Zone bloquante gameplay** : où le joueur doit être arrêté (tronc, mur bas,
///   base de meuble).
///
/// Seule la seconde est écrite dans [ElementCollisionProfile]. L’analyse
/// combine le canal alpha avec une **restriction verticale** explicite : la
/// matière haute du sprite ne suffit pas à bloquer — il faut de la matière
/// dans la **bande basse** du sprite et, dans chaque cellule, dans la partie
/// basse de la case (empreinte « au sol »).
class PlacedElementCollisionGenerationParams {
  const PlacedElementCollisionGenerationParams({
    this.alphaThreshold = kCollisionAlphaOpaqueThreshold,
    this.spriteGameplayBandBottomFraction =
        kCollisionSpriteGameplayBandBottomFraction,
    this.cellGroundFootprintFraction = kCollisionCellGroundFootprintFraction,
    this.minimumOpaqueRatioInGroundSample =
        kCollisionMinimumOpaqueRatioInGroundSample,
  });

  /// Pixels avec `alpha <= alphaThreshold` sont ignorés (transparents).
  final int alphaThreshold;

  /// Fraction de la **hauteur du sprite** (après clip padding), mesurée depuis
  /// le **bas**, dans laquelle la matière opaque peut contribuer à une
  /// collision.
  ///
  /// Ex. `0.52` → seule la moitié **inférieure** du rectangle sprite est prise
  /// en compte pour le blocage. Le feuillage / toit au-dessus peut être visible
  /// sans générer de collision pleine hauteur.
  ///
  /// Doit être dans `]0, 1]`.
  final double spriteGameplayBandBottomFraction;

  /// Dans chaque **cellule** grille, fraction **basse** (de la hauteur de case
  /// en pixels) utilisée pour l’échantillon « sol ». Réduit les faux positifs
  /// quand une case contient à la fois du vide en bas et du décor en haut.
  ///
  /// Doit être dans `]0, 1]`.
  final double cellGroundFootprintFraction;

  /// Ratio minimal `opaques / pixels_échantillonnés` dans la zone **sol**
  /// (bande sprite ∩ empreinte cellule) pour marquer la cellule bloquante.
  ///
  /// `0.0` = au moins un pixel opaque dans cette zone suffit.
  final double minimumOpaqueRatioInGroundSample;

  static const PlacedElementCollisionGenerationParams defaults =
      PlacedElementCollisionGenerationParams();
}

/// Seuil alpha : au-dessus = matière « visible » pour l’analyse.
const int kCollisionAlphaOpaqueThreshold = 24;

/// Par défaut : ~moitié basse du sprite = zone où un obstacle gameplay peut
/// exister (tronc, façade basse, base de lit).
const double kCollisionSpriteGameplayBandBottomFraction = 0.52;

/// Par défaut : moitié basse de chaque case = empreinte de contact au sol.
const double kCollisionCellGroundFootprintFraction = 0.5;

/// Filtre léger le bruit anti-alias (réglable ; 0 = désactivé).
const double kCollisionMinimumOpaqueRatioInGroundSample = 0.06;
