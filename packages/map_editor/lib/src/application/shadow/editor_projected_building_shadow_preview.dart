import 'package:map_core/map_core.dart';

import 'editor_static_shadow_preview.dart';

List<EditorStaticShadowPreviewInstruction>
buildEditorProjectedBuildingShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
  EditorShadowPreviewViewport? viewport,
}) {
  if (!tileWidth.isFinite ||
      !tileHeight.isFinite ||
      tileWidth <= 0 ||
      tileHeight <= 0 ||
      (viewport?.isEmpty ?? false) ||
      map.placedElements.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty || visibleTileLayerById.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final instructions = <EditorStaticShadowPreviewInstruction>[];
  for (final placed in map.placedElements) {
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
        height: manifest.settings.tileHeight,
      ),
    );

    final geometry = resolveProjectedBuildingShadowGeometry(
      config: config,
      preset: preset,
      metrics: StaticShadowVisualMetrics(
        left: 0,
        top: 0,
        visualWidth: source.width * tileWidth,
        visualHeight: source.height * tileHeight,
      ),
    );
    if (geometry == null) {
      continue;
    }

    final scaleX = tileWidth / manifest.settings.tileWidth;
    final scaleY = tileHeight / manifest.settings.tileHeight;
    final width = target.pixelSize.width * scaleX;
    final height = target.pixelSize.height * scaleY;
    final direction = preset.direction.normalized;
    final length =
        preset.geometryMode == ProjectedBuildingShadowGeometryMode.directional
        ? source.height * tileHeight * preset.shape.lengthRatio
        : 0.0;
    final transformedPoints = <ProjectedBuildingShadowPoint>[];
    if (preset.geometryMode ==
        ProjectedBuildingShadowGeometryMode.directional) {
      final u =
          config.anchor.xRatio +
          config.localOffset.x / (source.width * tileWidth);
      final v =
          config.anchor.yRatio +
          config.localOffset.y / (source.height * tileHeight);
      final (x, y) = switch (placed.quarterTurns) {
        0 => (u, v),
        1 => (1 - v, u),
        2 => (1 - u, 1 - v),
        _ => (v, 1 - u),
      };
      final anchorX = target.logicalRect.leftPx * scaleX + x * width;
      final anchorY = target.logicalRect.topPx * scaleY + y * height;
      final near = width * preset.shape.nearWidthRatio / 2;
      final far = width * preset.shape.farWidthRatio / 2;
      transformedPoints.addAll([
        ProjectedBuildingShadowPoint(
          x: anchorX + direction.y * near,
          y: anchorY - direction.x * near,
        ),
        ProjectedBuildingShadowPoint(
          x: anchorX - direction.y * near,
          y: anchorY + direction.x * near,
        ),
        ProjectedBuildingShadowPoint(
          x: anchorX + direction.x * length - direction.y * far,
          y: anchorY + direction.y * length + direction.x * far,
        ),
        ProjectedBuildingShadowPoint(
          x: anchorX + direction.x * length + direction.y * far,
          y: anchorY + direction.y * length - direction.x * far,
        ),
      ]);
    } else {
      for (var i = 0; i < geometry.points.length; i++) {
        final point = geometry.points[i];
        final dx = i >= 2 ? direction.x * length : 0.0;
        final dy = i >= 2 ? direction.y * length : 0.0;
        final u = (point.x - dx) / (source.width * tileWidth);
        final v = (point.y - dy) / (source.height * tileHeight);
        final (x, y) = switch (placed.quarterTurns) {
          0 => (u, v),
          1 => (1 - v, u),
          2 => (1 - u, 1 - v),
          _ => (v, 1 - u),
        };
        transformedPoints.add(
          ProjectedBuildingShadowPoint(
            x: target.logicalRect.leftPx * scaleX + x * width + dx,
            y: target.logicalRect.topPx * scaleY + y * height + dy,
          ),
        );
      }
    }
    final points = transformedPoints
        .map((point) => EditorStaticShadowPreviewPoint(x: point.x, y: point.y))
        .toList(growable: false);
    final bounds = _boundsFromEditorPreviewPoints(points);
    if (viewport != null &&
        !viewport.intersects(
          left: bounds.left,
          top: bounds.top,
          width: bounds.width,
          height: bounds.height,
        )) {
      continue;
    }

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
        opacity: geometry.opacity,
        colorHexRgb: geometry.colorHexRgb,
        polygonPoints: points,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}

_EditorProjectedShadowPreviewBounds _boundsFromEditorPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _EditorProjectedShadowPreviewBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _EditorProjectedShadowPreviewBounds {
  const _EditorProjectedShadowPreviewBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}
