import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_placed_element_origin.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/project_model3d.dart';
import 'map_placed_element_footprint.dart';
import 'map_placed_elements.dart';
import 'spatial_map_operations.dart';

enum MapResourceReplacementRefusal {
  instanceMissing,
  environmentOwned,
  movingProp,
  outOfBounds,
  paintedTerrain,
  borderOwned,
}

final class MapResourceReplacementException implements Exception {
  const MapResourceReplacementException(this.reason, this.instanceId);

  final MapResourceReplacementRefusal reason;
  final String instanceId;

  @override
  String toString() =>
      'MapResourceReplacementException(${reason.name}): $instanceId';
}

MapData replaceMapPlacedElementResource(
  MapData map, {
  required String instanceId,
  required ProjectElementEntry element,
  required PixelSize tileSize,
}) {
  final instance =
      map.placedElements.where((placed) => placed.id == instanceId).firstOrNull;
  if (instance == null) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.instanceMissing, instanceId);
  }
  if (environmentOwnedMapPlacedElementIds(map).contains(instanceId) ||
      instance.properties[pokemapPlacementOriginProperty]?.trim() ==
          pokemapPlacementOriginEnvironment) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.environmentOwned, instanceId);
  }
  if (map.movingProps.any((prop) => prop.placedElementId == instanceId)) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.movingProp, instanceId);
  }
  final next = instance.copyWith(
    elementId: element.id,
    pixelSize: null,
    animation: null,
  );
  try {
    validateMapPlacedElementGeometryBounds(
      geometry: resolveMapPlacedElementGeometry(
        instance: next,
        element: element,
        tileSize: tileSize,
      ),
      mapSize: map.size,
      tileSize: tileSize,
    );
  } on ValidationException {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.outOfBounds, instanceId);
  }
  return upsertMapPlacedElement(map, instance: next);
}

MapData replaceSpatialInstanceModel(
  MapData map, {
  required String instanceId,
  required ProjectModel3dEntry model,
}) {
  if (instanceId.startsWith('smt_')) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.paintedTerrain, instanceId);
  }
  if (map.layers.whereType<BorderLayer>().any((layer) => layer.content.features
      .any((feature) => feature.generatedPlacementIds.contains(instanceId)))) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.borderOwned, instanceId);
  }
  if (map.layers.whereType<EnvironmentLayer>().any((layer) =>
      layer.content.targetsSpatialTerrain &&
      layer.content.areas
          .any((area) => area.generatedPlacementIds.contains(instanceId)))) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.environmentOwned, instanceId);
  }
  final instance = map.spatialScene?.instances
      .where((candidate) => candidate.id == instanceId)
      .firstOrNull;
  if (instance == null) {
    throw MapResourceReplacementException(
        MapResourceReplacementRefusal.instanceMissing, instanceId);
  }
  return const SpatialMapOperations().upsertInstance(
    map,
    SpatialModelInstance(
      id: instance.id,
      modelId: model.id,
      position: instance.position,
      rotationDegrees: instance.rotationDegrees,
      scale: instance.scale,
      blocksMovement: instance.blocksMovement,
      castsShadows: instance.castsShadows,
      entityId: instance.entityId,
      visibilityCondition: instance.visibilityCondition,
    ),
    model: model,
  );
}
