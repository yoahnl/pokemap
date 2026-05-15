import 'dart:typed_data';

/// Lecture bas niveau du buffer RGBA tileset : **occupation visuelle** pixel à
/// pixel (sans décision gameplay).
///
/// Sert à centraliser le test `opaque ?` et à documenter l’accès mémoire.
/// Le masque gameplay est produit ailleurs par heuristiques, pas par copie brute
/// de cette occupation visuelle.
class ElementVisualOccupancyRaster {
  const ElementVisualOccupancyRaster();

  /// `true` si le pixel est considéré comme matière visible (alpha strictement
  /// au-dessus du seuil).
  bool isOpaquePixel({
    required ByteData bytesData,
    required int imageWidth,
    required int x,
    required int y,
    required int alphaThreshold,
  }) {
    final pixelIndex = (y * imageWidth + x) * 4;
    final alpha = bytesData.getUint8(pixelIndex + 3);
    return alpha > alphaThreshold;
  }
}
