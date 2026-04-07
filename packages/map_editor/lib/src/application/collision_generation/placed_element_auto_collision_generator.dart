import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'element_visual_occupancy_analyzer.dart';
import 'placed_element_collision_params.dart';
import 'placed_element_mask_heuristics_v1.dart';

/// Orchestre le décodage image → [ElementCollisionProfile] avec **trois** rôles :
/// [ElementCollisionProfile.visualMask], [ElementCollisionProfile.collisionMask],
/// [ElementCollisionProfile.occlusionMask].
///
/// Pipeline (V2 produit) :
/// 1. occupation visuelle binaire (`ElementVisualOccupancyAnalyzer`) ;
/// 2. encodage du **visuel** tel quel ;
/// 3. **collision** et **occlusion** dérivés par [PlacedElementMaskHeuristicsV1]
///    (pas de copie « opaque = bloquant ») ;
/// 4. encodage `packed_bits_v1` pour chaque masque.
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
    final visualPixels = List<bool>.from(visual.visiblePixels);
    final derived = PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(
      visualOpaque: visualPixels,
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
    );

    final visualMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: visualPixels,
      ),
    );
    final collisionMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: derived.collision,
      ),
    );
    final occlusionMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: derived.occlusion,
      ),
    );

    return ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      visualMask: visualMask,
      collisionMask: collisionMask,
      occlusionMask: occlusionMask,
      padding: padding,
      cells: const [],
    );
  }
}
