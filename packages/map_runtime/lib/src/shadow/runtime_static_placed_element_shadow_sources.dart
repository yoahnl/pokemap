import 'package:map_core/map_core.dart';

import '../application/runtime_map_bundle.dart';
import 'runtime_static_placed_element_shadow_collection.dart';
import 'shadow_runtime_instruction_collection.dart';
import 'static_placed_element_shadow_runtime_resolver.dart';

List<RuntimeStaticPlacedElementShadowSource>
    buildRuntimeStaticPlacedElementShadowSources({
  required RuntimeMapBundle bundle,
  Iterable<MapPlacedElement>? instances,
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
  for (final placed in instances ?? bundle.map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    if (_hasResolvableProjectedBuildingShadow(
      manifest: bundle.manifest,
      element: element,
    )) {
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
    final geometry = resolveMapPlacedElementGeometry(
      instance: placed,
      element: element,
      tileSize: PixelSize(
          width: bundle.manifest.settings.tileWidth,
          height: bundle.manifest.settings.tileHeight),
    );
    sources.add(
      RuntimeStaticPlacedElementShadowSource(
        id: placed.id,
        elementId: placed.elementId,
        elementShadow: element.shadow,
        placedOverride: placed.shadowOverride,
        metrics: StaticPlacedElementShadowRuntimeMetrics(
          sourceVisualWidth: source.width * cellWidth,
          sourceVisualHeight: source.height * cellHeight,
          quarterTurns: placed.quarterTurns,
          worldLeft: geometry.logicalRect.leftPx *
              cellWidth /
              bundle.manifest.settings.tileWidth,
          worldTop: geometry.logicalRect.topPx *
              cellHeight /
              bundle.manifest.settings.tileHeight,
          visualWidth: geometry.pixelSize.width *
              cellWidth /
              bundle.manifest.settings.tileWidth,
          visualHeight: geometry.pixelSize.height *
              cellHeight /
              bundle.manifest.settings.tileHeight,
        ),
      ),
    );
  }
  return List<RuntimeStaticPlacedElementShadowSource>.unmodifiable(sources);
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

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
  required RuntimeMapBundle bundle,
  Iterable<MapPlacedElement>? instances,
}) {
  return buildRuntimeStaticPlacedElementShadowCollection(
    catalog: bundle.manifest.shadowCatalog,
    sources: buildRuntimeStaticPlacedElementShadowSources(
        bundle: bundle, instances: instances),
  );
}
