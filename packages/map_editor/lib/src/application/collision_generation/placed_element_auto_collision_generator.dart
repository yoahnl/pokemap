import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'element_ground_blocking_mask_analyzer.dart';
import 'element_visual_occupancy_analyzer.dart';
import 'placed_element_collision_params.dart';

/// Orchestre le décodage image et la production d’un [ElementCollisionProfile].
///
/// Pipeline:
/// 1. Occupation visuelle pixel-level (`ElementVisualOccupancyAnalyzer`);
/// 2. Masque gameplay pixel-level (`ElementGroundBlockingMaskAnalyzer`);
/// 3. Encodage `pixelMask` + projection legacy `cells` pour compatibilité.
class PlacedElementAutoCollisionGenerator {
  const PlacedElementAutoCollisionGenerator({
    ElementVisualOccupancyAnalyzer? visualOccupancyAnalyzer,
    ElementGroundBlockingMaskAnalyzer? groundBlockingMaskAnalyzer,
  })  : _visualOccupancyAnalyzer =
            visualOccupancyAnalyzer ?? const ElementVisualOccupancyAnalyzer(),
        _groundBlockingMaskAnalyzer =
            groundBlockingMaskAnalyzer ?? const ElementGroundBlockingMaskAnalyzer();

  final ElementVisualOccupancyAnalyzer _visualOccupancyAnalyzer;
  final ElementGroundBlockingMaskAnalyzer _groundBlockingMaskAnalyzer;

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
    final gameplayMask = _groundBlockingMaskAnalyzer.analyze(
      occupancy: visual,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      cellCountX: source.width,
      cellCountY: source.height,
      params: params,
    );
    final pixelMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: gameplayMask.solidPixels,
      ),
    );
    final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: pixelMask,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceWidthInTiles: source.width,
      sourceHeightInTiles: source.height,
      minimumSolidRatioPerCell: params.minimumOpaqueRatioInGroundSample,
    );

    return ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      pixelMask: pixelMask,
      padding: padding,
      cells: cells,
    );
  }
}
