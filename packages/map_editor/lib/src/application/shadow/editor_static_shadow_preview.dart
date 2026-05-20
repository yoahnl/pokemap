import 'package:map_core/map_core.dart';

import 'editor_shadow_light_preview.dart';

enum EditorStaticShadowPreviewShapeKind {
  oval,
  projectedPolygon,
}

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

final class EditorStaticShadowPreviewPoint {
  EditorStaticShadowPreviewPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'EditorStaticShadowPreviewPoint.x');
    _validateFinite(y, 'EditorStaticShadowPreviewPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class EditorStaticShadowPreviewInstruction {
  EditorStaticShadowPreviewInstruction({
    required this.instanceId,
    required this.elementId,
    required this.shape,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.colorHexRgb,
    Iterable<EditorStaticShadowPreviewPoint> polygonPoints = const [],
  }) : polygonPoints =
            List<EditorStaticShadowPreviewPoint>.unmodifiable(polygonPoints) {
    _validateNonBlank(
      instanceId,
      'EditorStaticShadowPreviewInstruction.instanceId',
    );
    _validateNonBlank(
      elementId,
      'EditorStaticShadowPreviewInstruction.elementId',
    );
    _validateFinite(left, 'EditorStaticShadowPreviewInstruction.left');
    _validateFinite(top, 'EditorStaticShadowPreviewInstruction.top');
    _validatePositiveFinite(
      width,
      'EditorStaticShadowPreviewInstruction.width',
    );
    _validatePositiveFinite(
      height,
      'EditorStaticShadowPreviewInstruction.height',
    );
    _validateOpacity(opacity);
    _validateColorHexRgb(colorHexRgb);
    _validatePreviewPolygon(shape, this.polygonPoints);
  }

  final String instanceId;
  final String elementId;
  final EditorStaticShadowPreviewShapeKind shape;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final List<EditorStaticShadowPreviewPoint> polygonPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewInstruction &&
          other.instanceId == instanceId &&
          other.elementId == elementId &&
          other.shape == shape &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          _previewPointsEqual(other.polygonPoints, polygonPoints);

  @override
  int get hashCode => Object.hash(
        instanceId,
        elementId,
        shape,
        left,
        top,
        width,
        height,
        opacity,
        colorHexRgb,
        Object.hashAll(polygonPoints),
      );
}

List<EditorStaticShadowPreviewInstruction>
    buildEditorStaticShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
  EditorShadowLightPreviewPreset? lightPreviewPreset,
}) {
  if (!tileWidth.isFinite ||
      !tileHeight.isFinite ||
      tileWidth <= 0 ||
      tileHeight <= 0 ||
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
  final resolvedLightPreviewPreset =
      lightPreviewPreset ?? neutralEditorShadowLightPreviewPreset;
  for (final placed in map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    if (_hasResolvableProjectedBuildingShadow(
      manifest: manifest,
      element: element,
    )) {
      continue;
    }
    final source = element.frames.first.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }

    final resolution = resolveShadowConfig(
      catalog: manifest.shadowCatalog,
      elementShadow: element.shadow,
      placedOverride: placed.shadowOverride,
    );
    final resolved = resolution.resolved;
    if (resolved == null ||
        resolved.renderPass != ShadowRenderPass.groundStatic ||
        resolved.mode == ShadowCasterMode.none) {
      continue;
    }

    final visualWidth = source.width * tileWidth;
    final visualHeight = source.height * tileHeight;
    final baseLeft = placed.pos.x * tileWidth;
    final baseTop = placed.pos.y * tileHeight;
    final metrics = StaticShadowVisualMetrics(
      left: baseLeft,
      top: baseTop,
      visualWidth: visualWidth,
      visualHeight: visualHeight,
    );
    final geometry = resolveStaticShadowGeometry(
      metrics: metrics,
      shadowConfig: resolved,
      elementFootprint: element.shadow?.footprint,
      overrideFootprint: placed.shadowOverride?.footprint,
    );
    final family = resolveStaticShadowFamily(
      elementFamily: element.shadow?.family,
      overrideFamily: placed.shadowOverride?.family,
    );
    final projectedGeometry = family == StaticShadowFamily.building
        ? resolveBuildingStaticShadowContactLedgeGeometry(
            baseGeometry: geometry,
            metrics: metrics,
          )
        : resolveProjectedStaticShadowGeometry(
            baseGeometry: geometry,
            metrics: metrics,
            projectionSpec: resolveStaticShadowFamilyProjectionSpec(
              family: family,
              baseProjectionSpec: _projectionSpecForEditorLightPreview(
                resolvedLightPreviewPreset,
              ),
            ),
          );
    final points = _editorPreviewPointsFromProjection(projectedGeometry);
    final bounds = _boundsFromEditorPreviewPoints(points);

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
        opacity: _opacityForEditorLightPreview(
          resolved.opacity,
          resolvedLightPreviewPreset,
        ),
        colorHexRgb: resolved.colorHexRgb,
        polygonPoints: points,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}

bool _hasResolvableProjectedBuildingShadow({
  required ProjectManifest manifest,
  required ProjectElementEntry element,
}) {
  final config = element.projectedBuildingShadow;
  if (config == null || !config.enabled) {
    return false;
  }
  return manifest.projectedBuildingShadowCatalog.presetById(
        config.presetId,
      ) !=
      null;
}

StaticShadowProjectionSpec _projectionSpecForEditorLightPreview(
  EditorShadowLightPreviewPreset preset,
) {
  final hasDirection = preset.directionX != 0 || preset.directionY != 0;
  final lengthRatio = preset.lengthMultiplier > 0
      ? preset.lengthMultiplier
      : defaultStaticShadowProjectionLengthRatio * preset.scaleYMultiplier;

  return StaticShadowProjectionSpec(
    directionX: hasDirection
        ? preset.directionX
        : defaultStaticShadowProjectionDirectionX,
    directionY: hasDirection
        ? preset.directionY
        : defaultStaticShadowProjectionDirectionY,
    lengthRatio: lengthRatio,
    nearWidthMultiplier: defaultStaticShadowProjectionNearWidthMultiplier *
        preset.scaleXMultiplier,
    farWidthMultiplier: defaultStaticShadowProjectionFarWidthMultiplier *
        preset.scaleXMultiplier,
  );
}

double _opacityForEditorLightPreview(
  double opacity,
  EditorShadowLightPreviewPreset preset,
) {
  final nextOpacity = opacity * preset.opacityMultiplier;
  if (nextOpacity < 0) {
    return 0;
  }
  if (nextOpacity > 1) {
    return 1;
  }
  return nextOpacity;
}

List<EditorStaticShadowPreviewPoint> _editorPreviewPointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<EditorStaticShadowPreviewPoint>.unmodifiable(
    geometry.points.map(
      (point) => EditorStaticShadowPreviewPoint(x: point.x, y: point.y),
    ),
  );
}

_EditorStaticShadowPreviewBounds _boundsFromEditorPreviewPoints(
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
  return _EditorStaticShadowPreviewBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _EditorStaticShadowPreviewBounds {
  const _EditorStaticShadowPreviewBounds({
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

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException('$name must not be blank');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be greater than 0');
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'EditorStaticShadowPreviewInstruction.opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'EditorStaticShadowPreviewInstruction.opacity must be between 0 and 1',
    );
  }
}

void _validateColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'EditorStaticShadowPreviewInstruction.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
}

void _validatePreviewPolygon(
  EditorStaticShadowPreviewShapeKind shape,
  List<EditorStaticShadowPreviewPoint> points,
) {
  switch (shape) {
    case EditorStaticShadowPreviewShapeKind.oval:
      if (points.isNotEmpty) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction polygonPoints are only allowed for projectedPolygon',
        );
      }
    case EditorStaticShadowPreviewShapeKind.projectedPolygon:
      if (points.length < 3) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon requires at least 3 points',
        );
      }
      if (_previewPolygonArea(points) <= 0) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon must be non-degenerate',
        );
      }
  }
}

double _previewPolygonArea(List<EditorStaticShadowPreviewPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

bool _previewPointsEqual(
  List<EditorStaticShadowPreviewPoint> a,
  List<EditorStaticShadowPreviewPoint> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
