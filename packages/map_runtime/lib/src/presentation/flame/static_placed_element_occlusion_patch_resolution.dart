import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';

final class StaticPlacedElementOcclusionPatchInstruction {
  const StaticPlacedElementOcclusionPatchInstruction({
    required this.mapId,
    required this.placedElementId,
    required this.elementId,
    required this.layerId,
    required this.tilesetId,
    required this.sourceLeftPx,
    required this.sourceTopPx,
    required this.sourceWidthPx,
    required this.sourceHeightPx,
    required this.worldLeft,
    required this.worldTop,
    required this.visualWidth,
    required this.visualHeight,
    required this.depthSortY,
    required this.flamePriority,
    required this.opacity,
    required this.occlusionMask,
  });

  final String mapId;
  final String placedElementId;
  final String elementId;
  final String layerId;
  final String tilesetId;
  final int sourceLeftPx;
  final int sourceTopPx;
  final int sourceWidthPx;
  final int sourceHeightPx;
  final double worldLeft;
  final double worldTop;
  final double visualWidth;
  final double visualHeight;
  final double depthSortY;
  final int flamePriority;
  final double opacity;
  final ElementCollisionPixelMask occlusionMask;
}

List<StaticPlacedElementOcclusionPatchInstruction>
    resolveStaticPlacedElementOcclusionPatchInstructions({
  required RuntimeMapBundle bundle,
  required int originCellX,
  required int originCellY,
}) {
  final settings = bundle.manifest.settings;
  final tileWidth = settings.tileWidth;
  final tileHeight = settings.tileHeight;
  if (tileWidth <= 0 ||
      tileHeight <= 0 ||
      bundle.cellWidth <= 0 ||
      bundle.cellHeight <= 0) {
    return const [];
  }

  final elementById = {
    for (final element in bundle.manifest.elements) element.id: element,
  };
  final instructions = <StaticPlacedElementOcclusionPatchInstruction>[];

  for (final instance in bundle.map.placedElements) {
    final element = elementById[instance.elementId];
    if (element == null) {
      continue;
    }

    final instruction = _resolveInstruction(
      bundle: bundle,
      instance: instance,
      element: element,
      originCellX: originCellX,
      originCellY: originCellY,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    if (instruction != null) {
      instructions.add(instruction);
    }
  }

  return instructions;
}

StaticPlacedElementOcclusionPatchInstruction? _resolveInstruction({
  required RuntimeMapBundle bundle,
  required MapPlacedElement instance,
  required ProjectElementEntry element,
  required int originCellX,
  required int originCellY,
  required int tileWidth,
  required int tileHeight,
}) {
  if (_isAnimatedInV0(instance, element)) {
    return null;
  }

  final mask = element.collisionProfile?.occlusionMask;
  if (mask == null) {
    return null;
  }

  final frame = element.frames.primaryFrame;
  final source = frame.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }

  final sourceWidthPx = source.width * tileWidth;
  final sourceHeightPx = source.height * tileHeight;
  if (mask.widthPx != sourceWidthPx || mask.heightPx != sourceHeightPx) {
    return null;
  }

  if (!_maskHasAnySolidPixel(mask)) {
    return null;
  }

  final tilesetId = _resolveTilesetId(frame, element);
  if (tilesetId.isEmpty) {
    return null;
  }

  final worldLeft = (originCellX + instance.pos.x) * bundle.cellWidth;
  final worldTop = (originCellY + instance.pos.y) * bundle.cellHeight;
  final visualWidth = source.width * bundle.cellWidth;
  final visualHeight = source.height * bundle.cellHeight;
  final depthSortY = worldTop + visualHeight;

  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: bundle.map.id,
    placedElementId: instance.id,
    elementId: instance.elementId,
    layerId: instance.layerId,
    tilesetId: tilesetId,
    sourceLeftPx: source.x * tileWidth,
    sourceTopPx: source.y * tileHeight,
    sourceWidthPx: sourceWidthPx,
    sourceHeightPx: sourceHeightPx,
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    depthSortY: depthSortY,
    flamePriority: (1000 + depthSortY).round(),
    opacity: instance.opacity.clamp(0.0, 1.0).toDouble(),
    occlusionMask: mask,
  );
}

bool _isAnimatedInV0(
  MapPlacedElement instance,
  ProjectElementEntry element,
) {
  if (element.frames.length != 1) {
    return true;
  }
  final animation = instance.animation;
  if (animation == null || !animation.enabled) {
    return false;
  }
  return animation.mode != MapPlacedElementAnimationMode.none;
}

String _resolveTilesetId(
  TilesetVisualFrame frame,
  ProjectElementEntry element,
) {
  final frameTilesetId = frame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) {
    return frameTilesetId;
  }
  return element.tilesetId.trim();
}

bool _maskHasAnySolidPixel(ElementCollisionPixelMask mask) {
  try {
    final pixels = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: mask.widthPx,
      heightPx: mask.heightPx,
      dataBase64: mask.dataBase64,
    );
    return pixels.any((pixel) => pixel);
  } on FormatException {
    return false;
  } on ArgumentError {
    return false;
  }
}
