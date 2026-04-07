import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'element_visual_occupancy_analyzer.dart';
import 'placed_element_collision_params.dart';

/// Orchestre le décodage image → [ElementCollisionProfile] avec **pixelMask** uniquement.
///
/// Pipeline V1 (pas de dérivation grille) :
/// 1. occupation visuelle (`ElementVisualOccupancyAnalyzer`) ;
/// 2. **copie directe** visuel → masque gameplay (même géométrie, même taille) ;
/// 3. encodage `packed_bits_v1`.
///
/// [ElementCollisionProfile.cells] reste vide : legacy réservé migration JSON hors runtime.
class PlacedElementAutoCollisionGenerator {
  const PlacedElementAutoCollisionGenerator({
    ElementVisualOccupancyAnalyzer? visualOccupancyAnalyzer,
  }) : _visualOccupancyAnalyzer =
            visualOccupancyAnalyzer ?? const ElementVisualOccupancyAnalyzer();

  final ElementVisualOccupancyAnalyzer _visualOccupancyAnalyzer;

  Future<ElementCollisionProfile> generate({
    required String tilesetImagePath,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
    PlacedElementCollisionGenerationParams params =
        PlacedElementCollisionGenerationParams.defaults,
  }) async {
    final normalizedPath = tilesetImagePath.trim();
    if (normalizedPath.isEmpty) {
      throw const FormatException('Tileset image path is empty');
    }
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw const FormatException('Tile size must be strictly positive');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw const FormatException(
        'Element source size must be strictly positive',
      );
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw FileSystemException('Tileset image not found', normalizedPath);
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Tileset image is empty');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final srcLeft = source.x * tileWidth;
    final srcTop = source.y * tileHeight;
    final srcWidth = source.width * tileWidth;
    final srcHeight = source.height * tileHeight;
    if (srcLeft < 0 ||
        srcTop < 0 ||
        srcLeft + srcWidth > image.width ||
        srcTop + srcHeight > image.height) {
      throw const FormatException(
        'Element source rectangle is outside tileset bounds',
      );
    }

    final bytesData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytesData == null) {
      throw const FormatException('Unable to read tileset image pixels');
    }

    final maskWidthPx = source.width * tileWidth;
    final maskHeightPx = source.height * tileHeight;
    final visual = _visualOccupancyAnalyzer.analyze(
      bytesData: bytesData,
      imageWidth: image.width,
      srcLeft: srcLeft,
      srcTop: srcTop,
      srcWidth: srcWidth,
      srcHeight: srcHeight,
      padding: padding,
      alphaThreshold: params.alphaThreshold,
    );
    // Masque gameplay auto = copie directe de l’occupation visuelle (pas de grille).
    final pixelMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: List<bool>.from(visual.visiblePixels),
      ),
    );

    return ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      pixelMask: pixelMask,
      padding: padding,
      cells: const [],
    );
  }
}
