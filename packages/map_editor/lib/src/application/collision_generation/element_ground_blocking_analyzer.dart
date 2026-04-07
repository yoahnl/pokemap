import 'dart:math' as math;
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'element_visual_occupancy_raster.dart';
import 'placed_element_collision_params.dart';

/// Déduit les cellules **bloquantes gameplay** à partir du raster et des
/// paramètres [PlacedElementCollisionGenerationParams].
///
/// **Sémantique** : on n’utilise que les pixels situés dans
/// 1) le rectangle source rogné par [padding],
/// 2) la **bande basse** du sprite (hauteur `spriteGameplayBandBottomFraction`),
/// 3) l’**empreinte basse** de chaque cellule (`cellGroundFootprintFraction`).
///
/// Ainsi, le feuillage / toit / partie haute décorative ne remplit pas toute
/// la grille de collisions : seule la base « ancrée » du sprite contribue, ce
/// qui autorise le joueur à passer **derrière** la partie haute visuellement.
class ElementGroundBlockingAnalyzer {
  const ElementGroundBlockingAnalyzer({
    ElementVisualOccupancyRaster? occupancyRaster,
  }) : _raster = occupancyRaster ?? const ElementVisualOccupancyRaster();

  final ElementVisualOccupancyRaster _raster;

  /// Cellules locales (origine haut-gauche de l’élément) marquées bloquantes.
  List<GridPos> computeBlockingCells({
    required ByteData bytesData,
    required int imageWidth,
    required int srcLeft,
    required int srcTop,
    required int srcWidth,
    required int srcHeight,
    required int cellCountX,
    required int cellCountY,
    required int cellPixelWidth,
    required int cellPixelHeight,
    required WarpTriggerPadding padding,
    required PlacedElementCollisionGenerationParams params,
  }) {
    final out = <GridPos>[];
    if (cellPixelWidth <= 0 || cellPixelHeight <= 0) {
      return out;
    }

    final padLeft = padding.left.clamp(0, srcWidth);
    final padRight = padding.right.clamp(0, srcWidth);
    final padTop = padding.top.clamp(0, srcHeight);
    final padBottom = padding.bottom.clamp(0, srcHeight);
    final clipLeft = padLeft;
    final clipTop = padTop;
    final clipRight = math.max(clipLeft, srcWidth - padRight);
    final clipBottom = math.max(clipTop, srcHeight - padBottom);

    final threshold = params.alphaThreshold.clamp(0, 255);
    final bandFrac = params.spriteGameplayBandBottomFraction.clamp(1e-6, 1.0);
    final footFrac = params.cellGroundFootprintFraction.clamp(1e-6, 1.0);
    final minRatio = params.minimumOpaqueRatioInGroundSample.clamp(0.0, 1.0);

    // Ligne minimale (coordonnée locale Y dans le rectangle source) à partir
    // de laquelle un pixel peut compter pour le gameplay : bas du sprite.
    final bandStartLocalY =
        ((1.0 - bandFrac) * (clipBottom - clipTop)).ceil();
    final blockingBandMinLocalY = clipTop + bandStartLocalY;

    final footprintMinPyInCell =
        ((1.0 - footFrac) * cellPixelHeight).ceil();

    for (var cellY = 0; cellY < cellCountY; cellY++) {
      for (var cellX = 0; cellX < cellCountX; cellX++) {
        var opaqueInGroundSample = 0;
        var groundSampleCount = 0;
        final pixelStartX = srcLeft + cellX * cellPixelWidth;
        final pixelStartY = srcTop + cellY * cellPixelHeight;

        for (var py = 0; py < cellPixelHeight; py++) {
          if (py < footprintMinPyInCell) {
            continue;
          }
          final localY = cellY * cellPixelHeight + py;
          if (localY < clipTop || localY >= clipBottom) {
            continue;
          }
          if (localY < blockingBandMinLocalY) {
            continue;
          }
          final y = pixelStartY + py;
          for (var px = 0; px < cellPixelWidth; px++) {
            final localX = cellX * cellPixelWidth + px;
            if (localX < clipLeft || localX >= clipRight) {
              continue;
            }
            groundSampleCount++;
            final x = pixelStartX + px;
            if (_raster.isOpaquePixel(
              bytesData: bytesData,
              imageWidth: imageWidth,
              x: x,
              y: y,
              alphaThreshold: threshold,
            )) {
              opaqueInGroundSample++;
            }
          }
        }

        if (groundSampleCount <= 0) {
          continue;
        }
        final ratio = opaqueInGroundSample / groundSampleCount;
        final blocks = minRatio <= 0
            ? opaqueInGroundSample > 0
            : ratio >= minRatio;
        if (blocks) {
          out.add(GridPos(x: cellX, y: cellY));
        }
      }
    }

    out.sort((a, b) {
      final c = a.y.compareTo(b.y);
      if (c != 0) {
        return c;
      }
      return a.x.compareTo(b.x);
    });
    return out;
  }
}
