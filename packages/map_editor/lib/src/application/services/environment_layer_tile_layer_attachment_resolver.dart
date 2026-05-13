import 'package:map_core/map_core.dart';

List<EnvironmentLayer> validEnvironmentLayerAttachmentsForTileLayer(
  MapData map,
  String tileLayerId,
) {
  final targetId = tileLayerId.trim();
  if (targetId.isEmpty) {
    return const [];
  }

  final layersById = {
    for (final layer in map.layers) layer.id: layer,
  };
  final targetLayer = layersById[targetId];
  if (targetLayer is! TileLayer) {
    return const [];
  }

  final attachments = <EnvironmentLayer>[];
  for (final layer in map.layers) {
    if (layer is! EnvironmentLayer) {
      continue;
    }
    final attachedTargetId = layer.content.targetTileLayerId?.trim();
    if (attachedTargetId == null || attachedTargetId.isEmpty) {
      continue;
    }
    final attachedTarget = layersById[attachedTargetId];
    if (attachedTarget is! TileLayer) {
      continue;
    }
    if (attachedTarget.id == targetLayer.id) {
      attachments.add(layer);
    }
  }
  return List<EnvironmentLayer>.unmodifiable(attachments);
}

bool layerHasValidEnvironmentAttachments(
  MapData map,
  String layerId,
) {
  return validEnvironmentLayerAttachmentsForTileLayer(map, layerId).isNotEmpty;
}
