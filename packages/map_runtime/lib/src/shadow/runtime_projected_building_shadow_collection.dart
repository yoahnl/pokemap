import 'package:map_core/map_core.dart';

import 'projected_building_shadow_runtime_adapter.dart';
import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeInstructionCollection
    buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
  Iterable<MapPlacedElement>? instances,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in mapData.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty ||
      visibleTileLayerById.isEmpty ||
      mapData.placedElements.isEmpty) {
    return ShadowRuntimeInstructionCollection();
  }

  final cellWidth =
      manifest.settings.tileWidth * manifest.settings.displayScale;
  final cellHeight =
      manifest.settings.tileHeight * manifest.settings.displayScale;
  final instructions = <ShadowRuntimeRenderInstruction>[];

  for (final placed in instances ?? mapData.placedElements) {
    if (placed.opacity <= 0 ||
        !visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }

    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }

    final config = element.projectedBuildingShadow;
    if (config == null || !config.enabled) {
      continue;
    }

    final preset = manifest.projectedBuildingShadowCatalog.presetById(
      config.presetId,
    );
    if (preset == null) {
      continue;
    }

    final source = element.frames.first.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }
    final target = resolveMapPlacedElementGeometry(
      instance: placed,
      element: element,
      tileSize: PixelSize(
          width: manifest.settings.tileWidth,
          height: manifest.settings.tileHeight),
    );

    final geometry = resolveProjectedBuildingShadowGeometry(
      config: config,
      preset: preset,
      metrics: StaticShadowVisualMetrics(
        left: 0,
        top: 0,
        visualWidth: source.width * cellWidth,
        visualHeight: source.height * cellHeight,
      ),
    );
    if (geometry == null) {
      continue;
    }

    final scale = manifest.settings.displayScale;
    final width = target.pixelSize.width * scale;
    final height = target.pixelSize.height * scale;
    final direction = preset.direction.normalized;
    final length =
        preset.geometryMode == ProjectedBuildingShadowGeometryMode.directional
            ? source.height * cellHeight * preset.shape.lengthRatio
            : 0.0;
    final points = <ProjectedBuildingShadowPoint>[];
    if (preset.geometryMode ==
        ProjectedBuildingShadowGeometryMode.directional) {
      final u = config.anchor.xRatio +
          config.localOffset.x / (source.width * cellWidth);
      final v = config.anchor.yRatio +
          config.localOffset.y / (source.height * cellHeight);
      final (x, y) = switch (placed.quarterTurns) {
        0 => (u, v),
        1 => (1 - v, u),
        2 => (1 - u, 1 - v),
        _ => (v, 1 - u),
      };
      final anchorX = target.logicalRect.leftPx * scale + x * width;
      final anchorY = target.logicalRect.topPx * scale + y * height;
      final near = width * preset.shape.nearWidthRatio / 2;
      final far = width * preset.shape.farWidthRatio / 2;
      points.addAll([
        ProjectedBuildingShadowPoint(
            x: anchorX + direction.y * near, y: anchorY - direction.x * near),
        ProjectedBuildingShadowPoint(
            x: anchorX - direction.y * near, y: anchorY + direction.x * near),
        ProjectedBuildingShadowPoint(
            x: anchorX + direction.x * length - direction.y * far,
            y: anchorY + direction.y * length + direction.x * far),
        ProjectedBuildingShadowPoint(
            x: anchorX + direction.x * length + direction.y * far,
            y: anchorY + direction.y * length - direction.x * far),
      ]);
    } else {
      for (var i = 0; i < geometry.points.length; i++) {
        final point = geometry.points[i];
        final dx = i >= 2 ? direction.x * length : 0.0;
        final dy = i >= 2 ? direction.y * length : 0.0;
        final u = (point.x - dx) / (source.width * cellWidth);
        final v = (point.y - dy) / (source.height * cellHeight);
        final (x, y) = switch (placed.quarterTurns) {
          0 => (u, v),
          1 => (1 - v, u),
          2 => (1 - u, 1 - v),
          _ => (v, 1 - u),
        };
        points.add(ProjectedBuildingShadowPoint(
            x: target.logicalRect.leftPx * scale + x * width + dx,
            y: target.logicalRect.topPx * scale + y * height + dy));
      }
    }
    instructions.add(createProjectedBuildingShadowRuntimeInstruction(
        ProjectedBuildingShadowGeometry(
            points: points,
            opacity: geometry.opacity,
            colorHexRgb: geometry.colorHexRgb)));
  }

  return ShadowRuntimeInstructionCollection(instructions: instructions);
}
