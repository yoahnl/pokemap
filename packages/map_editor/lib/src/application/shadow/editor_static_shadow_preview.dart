import 'package:map_core/map_core.dart';

final class EditorStaticShadowPreviewInstruction {
  const EditorStaticShadowPreviewInstruction({
    required this.instanceId,
    required this.elementId,
    required this.shape,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String instanceId;
  final String elementId;
  final ShadowCasterMode shape;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;

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
          other.colorHexRgb == colorHexRgb;

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
      );
}

List<EditorStaticShadowPreviewInstruction>
    buildEditorStaticShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
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
  for (final placed in map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
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
    final anchorX = baseLeft + visualWidth * 0.5;
    final anchorY = baseTop + visualHeight;
    final shadowWidth = visualWidth * 0.75 * resolved.scaleX;
    final shadowHeight = visualHeight * 0.25 * resolved.scaleY;
    if (shadowWidth <= 0 || shadowHeight <= 0) {
      continue;
    }
    final centerX = anchorX + resolved.offsetX;
    final centerY = anchorY + resolved.offsetY;

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: resolved.mode,
        left: centerX - shadowWidth / 2,
        top: centerY - shadowHeight / 2,
        width: shadowWidth,
        height: shadowHeight,
        opacity: resolved.opacity,
        colorHexRgb: resolved.colorHexRgb,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}
