import 'dart:math' as math;
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'alpha_collision_params.dart';

/// Construit la liste des cellules **bloquantes** à partir du canal alpha.
///
/// Règle :
/// - on parcourt chaque pixel de chaque cellule (hors [padding] appliqué au
///   rectangle source) ;
/// - pixel avec `alpha > alphaThreshold` → compte comme matière visible ;
/// - si `opaqueCount / sampledCount >= minimumOpaquePixelRatioPerCell`, la
///   cellule est bloquante.
class AlphaCollisionGridBuilder {
  const AlphaCollisionGridBuilder();

  /// Retourne les [GridPos] locaux (origine haut-gauche de l’élément) marqués
  /// comme collision de déplacement.
  List<GridPos> buildCells({
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
    required AlphaCollisionGenerationParams params,
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
    final minRatio = params.minimumOpaquePixelRatioPerCell.clamp(0.0, 1.0);

    for (var cellY = 0; cellY < cellCountY; cellY++) {
      for (var cellX = 0; cellX < cellCountX; cellX++) {
        var opaqueCount = 0;
        var sampledCount = 0;
        final pixelStartX = srcLeft + cellX * cellPixelWidth;
        final pixelStartY = srcTop + cellY * cellPixelHeight;
        for (var py = 0; py < cellPixelHeight; py++) {
          final localY = cellY * cellPixelHeight + py;
          if (localY < clipTop || localY >= clipBottom) {
            continue;
          }
          final y = pixelStartY + py;
          for (var px = 0; px < cellPixelWidth; px++) {
            final localX = cellX * cellPixelWidth + px;
            if (localX < clipLeft || localX >= clipRight) {
              continue;
            }
            sampledCount++;
            final x = pixelStartX + px;
            final pixelIndex = (y * imageWidth + x) * 4;
            final alpha = bytesData.getUint8(pixelIndex + 3);
            if (alpha > threshold) {
              opaqueCount++;
            }
          }
        }
        if (sampledCount <= 0) {
          continue;
        }
        final ratio = opaqueCount / sampledCount;
        final blocks = minRatio <= 0
            ? opaqueCount > 0
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
