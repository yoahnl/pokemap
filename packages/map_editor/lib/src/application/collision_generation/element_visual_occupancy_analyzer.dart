import 'dart:math' as math;
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

/// Représente l'occupation visuelle binaire d'un élément en pixels.
///
/// - `true`  => pixel visible (alpha > seuil)
/// - `false` => pixel transparent / ignoré
///
/// Le repère est local au rectangle source de l'élément:
/// - `(0,0)` = coin haut-gauche du sprite source
/// - index = `y * widthPx + x`
class ElementVisualOccupancyMask {
  const ElementVisualOccupancyMask({
    required this.widthPx,
    required this.heightPx,
    required this.visiblePixels,
  });

  final int widthPx;
  final int heightPx;
  final List<bool> visiblePixels;
}

/// Analyse un rectangle source RGBA et produit une occupation visuelle
/// pixel-level.
///
/// Cette étape ne décide pas encore le gameplay; elle répond uniquement:
/// "où le sprite est visuellement présent ?"
class ElementVisualOccupancyAnalyzer {
  const ElementVisualOccupancyAnalyzer();

  ElementVisualOccupancyMask analyze({
    required ByteData bytesData,
    required int imageWidth,
    required int srcLeft,
    required int srcTop,
    required int srcWidth,
    required int srcHeight,
    required WarpTriggerPadding padding,
    required int alphaThreshold,
  }) {
    final widthPx = math.max(0, srcWidth);
    final heightPx = math.max(0, srcHeight);
    final visible = List<bool>.filled(widthPx * heightPx, false);
    if (widthPx <= 0 || heightPx <= 0) {
      return ElementVisualOccupancyMask(
        widthPx: widthPx,
        heightPx: heightPx,
        visiblePixels: visible,
      );
    }

    final padLeft = padding.left.clamp(0, widthPx);
    final padRight = padding.right.clamp(0, widthPx);
    final padTop = padding.top.clamp(0, heightPx);
    final padBottom = padding.bottom.clamp(0, heightPx);
    final clipLeft = padLeft;
    final clipTop = padTop;
    final clipRight = math.max(clipLeft, widthPx - padRight);
    final clipBottom = math.max(clipTop, heightPx - padBottom);
    final threshold = alphaThreshold.clamp(0, 255);

    for (var y = 0; y < heightPx; y++) {
      for (var x = 0; x < widthPx; x++) {
        if (x < clipLeft || x >= clipRight || y < clipTop || y >= clipBottom) {
          continue;
        }
        final worldX = srcLeft + x;
        final worldY = srcTop + y;
        final pixelIndex = (worldY * imageWidth + worldX) * 4;
        final alpha = bytesData.getUint8(pixelIndex + 3);
        if (alpha > threshold) {
          visible[y * widthPx + x] = true;
        }
      }
    }

    return ElementVisualOccupancyMask(
      widthPx: widthPx,
      heightPx: heightPx,
      visiblePixels: visible,
    );
  }
}
