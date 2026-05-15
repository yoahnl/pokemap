import 'package:map_core/map_core.dart';

import '../application/runtime_map_bundle.dart';
import 'runtime_static_placed_element_shadow_collection.dart';
import 'shadow_runtime_instruction_collection.dart';
import 'static_placed_element_shadow_runtime_resolver.dart';

List<RuntimeStaticPlacedElementShadowSource>
    buildRuntimeStaticPlacedElementShadowSources({
  required RuntimeMapBundle bundle,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in bundle.manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in bundle.map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty ||
      visibleTileLayerById.isEmpty ||
      bundle.map.placedElements.isEmpty) {
    return const <RuntimeStaticPlacedElementShadowSource>[];
  }

  final sources = <RuntimeStaticPlacedElementShadowSource>[];
  final cellWidth = bundle.cellWidth;
  final cellHeight = bundle.cellHeight;
  for (final placed in bundle.map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final frame = element.frames.first;
    final source = frame.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : element.tilesetId.trim();
    if (tilesetId.isEmpty) {
      continue;
    }
    sources.add(
      RuntimeStaticPlacedElementShadowSource(
        id: placed.id,
        elementId: placed.elementId,
        elementShadow: element.shadow,
        placedOverride: placed.shadowOverride,
        metrics: StaticPlacedElementShadowRuntimeMetrics(
          worldLeft: placed.pos.x * cellWidth,
          worldTop: placed.pos.y * cellHeight,
          visualWidth: source.width * cellWidth,
          visualHeight: source.height * cellHeight,
        ),
      ),
    );
  }
  return List<RuntimeStaticPlacedElementShadowSource>.unmodifiable(sources);
}

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
  required RuntimeMapBundle bundle,
}) {
  return buildRuntimeStaticPlacedElementShadowCollection(
    catalog: bundle.manifest.shadowCatalog,
    sources: buildRuntimeStaticPlacedElementShadowSources(bundle: bundle),
  );
}
