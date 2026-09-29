import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';
import 'overworld_render_priority.dart';

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
    required this.quarterTurns,
    required this.destinationWidthPx,
    required this.destinationHeightPx,
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
  final int quarterTurns;
  final int destinationWidthPx;
  final int destinationHeightPx;
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
  Iterable<MapPlacedElement>? instances,
  Map<ElementCollisionPixelMask, bool>? maskValidityCache,
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

  for (final instance in instances ?? bundle.map.placedElements) {
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
      maskValidityCache: maskValidityCache,
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
  Map<ElementCollisionPixelMask, bool>? maskValidityCache,
}) {
  final layer =
      bundle.map.layers.where((e) => e.id == instance.layerId).firstOrNull;
  if (layer == null ||
      !layer.isVisible ||
      layer.opacity <= 0 ||
      instance.opacity <= 0) {
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

  final hasSolidPixel =
      maskValidityCache?.putIfAbsent(mask, () => _maskHasAnySolidPixel(mask)) ??
          _maskHasAnySolidPixel(mask);
  if (!hasSolidPixel) {
    return null;
  }

  final tilesetId = _resolveTilesetId(frame, element);
  if (tilesetId.isEmpty) {
    return null;
  }

  final geometry = resolveMapPlacedElementGeometry(
    instance: instance,
    element: element,
    tileSize: PixelSize(width: tileWidth, height: tileHeight),
  );
  final tileset =
      bundle.manifest.tilesets.where((e) => e.id == tilesetId).firstOrNull;
  final visual = resolveMapPlacedElementVisualRect(
      geometry: geometry, tilesetSource: tileset?.source);
  final worldLeft = originCellX * bundle.cellWidth +
      visual.leftPx * bundle.cellWidth / tileWidth;
  final worldTop = originCellY * bundle.cellHeight +
      visual.topPx * bundle.cellHeight / tileHeight;
  final destinationWidthPx = geometry.pixelSize.width;
  final destinationHeightPx = geometry.pixelSize.height;
  final visualWidth = geometry.pixelSize.width * bundle.cellWidth / tileWidth;
  final visualHeight =
      geometry.pixelSize.height * bundle.cellHeight / tileHeight;
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
    quarterTurns: instance.quarterTurns,
    destinationWidthPx: destinationWidthPx,
    destinationHeightPx: destinationHeightPx,
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    depthSortY: depthSortY,
    flamePriority: overworldActorRenderPriority(depthSortY),
    opacity: (instance.opacity * layer.opacity).clamp(0.0, 1.0).toDouble(),
    occlusionMask: mask,
  );
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
