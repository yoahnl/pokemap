import 'dart:math' as math;

/// Heuristiques **V1** pour dériver collision et occlusion à partir du masque
/// visuel (pixels opaques).
///
/// ## Problème résolu
/// L’ancien pipeline copiait `visual = opaque` → `collision`, donc **ombres** et
/// **décors hauts** devenaient des murs. Ici on **sépare** explicitement :
/// - **visuel** : matière affichée (référence, éditeur) ;
/// - **collision** : sous-ensemble du visuel, **sans** bande d’ombre basse ;
/// - **occlusion** : sous-ensemble du visuel (bande haute du « volume ») pour
///   le rendu « passer derrière », **sans** influencer la collision.
///
/// ## Limites (honnêtes)
/// - Sans ML : on ne « comprend » pas une scène ; on applique des règles
///   géométriques sur le bbox des pixels opaques.
/// - Les assets très atypiques devront être **corrigés à la main** dans l’éditeur.
/// - L’occlusion auto est une **approximation** (bande haute du bbox) : le
///   runtime peut l’affiner plus tard (split dynamique).
class PlacedElementMaskHeuristicsV1 {
  PlacedElementMaskHeuristicsV1._();

  /// Fraction de la hauteur du bbox (depuis le haut) considérée comme zone
  /// d’occlusion « toit / couronne » (à recouvrir quand le joueur est derrière).
  static const double occlusionBandTopFraction = 0.38;

  /// Hauteur minimale de bande d’ombre basse : fraction du bbox (depuis le bas).
  static const double shadowBandMaxFraction = 0.22;

  /// Une ligne est candidate « ombre » si sa densité d’opacité est inférieure à
  /// ce ratio par rapport à la ligne la plus dense du bbox.
  static const double shadowDensityRatioVsMaxRow = 0.48;

  // ---------------------------------------------------------------------------
  // Entrée / sortie
  // ---------------------------------------------------------------------------

  /// [visualOpaque] : `true` = pixel opaque (alpha > seuil), repère local
  /// `(widthPx, heightPx)`, index `y * widthPx + x`.
  ///
  /// Retourne trois listes booléennes **même taille** : collision et occlusion
  /// sont des sous-ensembles du visuel (pas des pixels hors sprite).
  static MaskTriple deriveFromVisualOccupancy({
    required List<bool> visualOpaque,
    required int widthPx,
    required int heightPx,
  }) {
    if (widthPx <= 0 ||
        heightPx <= 0 ||
        visualOpaque.length != widthPx * heightPx) {
      return MaskTriple(
        collision: List<bool>.from(visualOpaque),
        occlusion: List<bool>.filled(widthPx * heightPx, false),
      );
    }

    final bbox = _boundingBoxOfOpaque(visualOpaque, widthPx, heightPx);
    if (bbox == null) {
      return MaskTriple(
        collision: List<bool>.filled(visualOpaque.length, false),
        occlusion: List<bool>.filled(visualOpaque.length, false),
      );
    }

    final shadowRows = _inferShadowRowsFromVisualDensity(
      visualOpaque,
      widthPx,
      heightPx,
      bbox,
    );

    final collision = List<bool>.filled(visualOpaque.length, false);
    final occlusion = List<bool>.filled(visualOpaque.length, false);

    final occTopY =
        bbox.minY + (bbox.height * occlusionBandTopFraction).floor();
    for (var y = bbox.minY; y <= bbox.maxY; y++) {
      for (var x = bbox.minX; x <= bbox.maxX; x++) {
        final i = y * widthPx + x;
        if (i < 0 || i >= visualOpaque.length) {
          continue;
        }
        if (!visualOpaque[i]) {
          continue;
        }
        final inShadow = shadowRows[y];
        if (!inShadow) {
          collision[i] = true;
        }
        if (y < occTopY) {
          occlusion[i] = true;
        }
      }
    }

    return MaskTriple(collision: collision, occlusion: occlusion);
  }

  static _BBox? _boundingBoxOfOpaque(
    List<bool> visual,
    int widthPx,
    int heightPx,
  ) {
    var minX = widthPx;
    var minY = heightPx;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < heightPx; y++) {
      for (var x = 0; x < widthPx; x++) {
        if (!visual[y * widthPx + x]) {
          continue;
        }
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
    if (maxX < minX || maxY < minY) {
      return null;
    }
    return _BBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  /// Infère les lignes d’ombre comme une **bande basse** du bbox : on part du
  /// bas et on remonte tant que la ligne est « moins pleine » que le maximum
  /// (typique ombre projetée semi-transparente agrégée en bool).
  static List<bool> _inferShadowRowsFromVisualDensity(
    List<bool> visual,
    int widthPx,
    int heightPx,
    _BBox bbox,
  ) {
    final shadowRows = List<bool>.filled(heightPx, false);
    final rowCounts = List<int>.filled(heightPx, 0);
    var maxCount = 0;
    for (var y = bbox.minY; y <= bbox.maxY; y++) {
      var c = 0;
      for (var x = bbox.minX; x <= bbox.maxX; x++) {
        if (visual[y * widthPx + x]) {
          c++;
        }
      }
      rowCounts[y] = c;
      maxCount = math.max(maxCount, c);
    }
    if (maxCount <= 0) {
      return shadowRows;
    }

    final threshold =
        math.max(1, (maxCount * shadowDensityRatioVsMaxRow).ceil());
    final maxShadowRows = math.max(
        1, ((bbox.maxY - bbox.minY + 1) * shadowBandMaxFraction).ceil());

    var consecutive = 0;
    for (var y = bbox.maxY;
        y >= bbox.minY && consecutive < maxShadowRows;
        y--) {
      if (rowCounts[y] <= threshold && rowCounts[y] < maxCount) {
        shadowRows[y] = true;
        consecutive++;
      } else {
        // On arrête la remontée si on touche la « structure » dense (façade).
        break;
      }
    }
    return shadowRows;
  }
}

class MaskTriple {
  const MaskTriple({
    required this.collision,
    required this.occlusion,
  });

  /// Pixels bloquants gameplay (sans ombre basse heuristique).
  final List<bool> collision;

  /// Pixels qui participent à la couverture visuelle « devant / derrière ».
  final List<bool> occlusion;
}

class _BBox {
  const _BBox({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}
