import 'package:map_core/map_core.dart';

import 'projected_building_shadow_runtime_adapter.dart';
import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeInstructionCollection
    buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
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

  for (final placed in mapData.placedElements) {
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

    final geometry = resolveProjectedBuildingShadowGeometry(
      config: config,
      preset: preset,
      metrics: StaticShadowVisualMetrics(
        left: placed.pos.x * cellWidth,
        top: placed.pos.y * cellHeight,
        visualWidth: source.width * cellWidth,
        visualHeight: source.height * cellHeight,
      ),
    );
    if (geometry == null) {
      continue;
    }

    instructions.add(
      createProjectedBuildingShadowRuntimeInstruction(geometry),
    );
  }

  return ShadowRuntimeInstructionCollection(instructions: instructions);
}
