import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import 'border_blueprint_json_codec.dart';
import 'spatial_border_resolution.dart';

enum Model3dMergeRefusal {
  environmentOwned,
  borderNotSpatial,
  borderStale,
  borderNotApplicable,
  borderOutputChanged,
}

final class Model3dMergeException implements Exception {
  const Model3dMergeException(this.reason, {this.mapId, this.featureId});

  final Model3dMergeRefusal reason;
  final String? mapId;
  final String? featureId;

  @override
  String toString() =>
      'Model3dMergeException(${reason.name}, map: $mapId, feature: $featureId)';
}

MapData repointModelInMap(
  MapData map, {
  required ProjectManifest before,
  required ProjectManifest after,
  required String modelId,
  required String replacementId,
  required Set<String> blueprintIds,
  bool keepStaleBorders = false,
}) {
  final scene = map.spatialScene;
  final features = [
    for (final layer in map.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        if (blueprintIds.contains(feature.blueprintId)) (layer.id, feature),
  ];
  if (scene == null) {
    if (features.isNotEmpty) {
      throw Model3dMergeException(
        Model3dMergeRefusal.borderNotSpatial,
        mapId: map.id,
        featureId: features.first.$2.id,
      );
    }
    return map;
  }
  for (final instance in scene.instances) {
    if (instance.modelId == modelId && instance.id.startsWith('env3d_')) {
      throw Model3dMergeException(
        Model3dMergeRefusal.environmentOwned,
        mapId: map.id,
      );
    }
  }
  final previous = <(String, BorderFeature), SpatialBorderResolutionResult>{};
  for (final entry in features) {
    final (layerId, feature) = entry;
    final materialization = feature.materialization;
    if (materialization == null) continue;
    final resolved = resolveSpatialBorderFeature(
      manifest: before,
      map: map,
      layerId: layerId,
      featureId: feature.id,
      resolverVersion: materialization.receipt.resolverVersion,
    );
    if (!spatialBorderMaterializationIsFresh(resolved, materialization, map)) {
      if (keepStaleBorders) continue;
      throw Model3dMergeException(
        Model3dMergeRefusal.borderStale,
        mapId: map.id,
        featureId: feature.id,
      );
    }
    previous[entry] = resolved;
  }
  SpatialModelInstance repoint(SpatialModelInstance instance) =>
      instance.modelId == modelId
      ? instance.copyWith(modelId: replacementId)
      : instance;
  var next = map.copyWith(
    spatialScene: scene.copyWith(
      instances: [for (final instance in scene.instances) repoint(instance)],
    ),
  );
  for (final MapEntry(key: (layerId, feature), value: old)
      in previous.entries) {
    final resolved = resolveSpatialBorderFeature(
      manifest: after,
      map: next,
      layerId: layerId,
      featureId: feature.id,
      resolverVersion: feature.materialization!.receipt.resolverVersion,
    );
    if (!resolved.result.canApply) {
      throw Model3dMergeException(
        Model3dMergeRefusal.borderNotApplicable,
        mapId: map.id,
        featureId: feature.id,
      );
    }
    final placements = resolved.result.materialization!.spatialPlacements;
    final oldPlacements = old.result.materialization!.spatialPlacements;
    final samePlacements =
        placements.length == oldPlacements.length &&
        [
          for (var index = 0; index < placements.length; index++)
            placements[index].slotKey == oldPlacements[index].slotKey &&
                placements[index].primitiveId ==
                    oldPlacements[index].primitiveId &&
                placements[index].instanceId == oldPlacements[index].instanceId,
        ].every((same) => same);
    final expected = [
      for (final instance in old.modelInstances) repoint(instance),
    ];
    final sameInstances =
        expected.length == resolved.modelInstances.length &&
        [
          for (var index = 0; index < expected.length; index++)
            expected[index] == resolved.modelInstances[index],
        ].every((same) => same);
    if (!samePlacements || !sameInstances) {
      throw Model3dMergeException(
        Model3dMergeRefusal.borderOutputChanged,
        mapId: map.id,
        featureId: feature.id,
      );
    }
    next = applySpatialBorderFeaturePreview(
      next,
      manifest: after,
      proposedResult: resolved,
    );
  }
  return next;
}

bool borderRecordUsesModel(
  BorderBlueprintRecord record,
  String modelId, {
  required int formatVersion,
}) => _usesModel(
  encodeBorderBlueprintRecordJson(record, formatVersion: formatVersion),
  modelId,
);

BorderBlueprintRecord repointModelInBorderRecord(
  BorderBlueprintRecord record, {
  required String modelId,
  required String replacementId,
  required int formatVersion,
}) {
  final json = Map<String, Object?>.from(
    encodeBorderBlueprintRecordJson(record, formatVersion: formatVersion),
  );
  final published = json['latestPublished'];
  final draft = json['draft'];
  final next = <String, Object?>{
    for (final MapEntry(:key, :value) in json.entries)
      key: _repointModel(value, modelId, replacementId),
  };
  if (published is Map && _usesModel(published, modelId)) {
    final revision = published['revision'] as int;
    next['latestPublished'] = {
      ...(next['latestPublished'] as Map<String, Object?>),
      'revision': revision + 1,
    };
    if (draft is Map && draft['baseRevision'] == revision) {
      next['draft'] = {
        ...(next['draft'] as Map<String, Object?>),
        'baseRevision': revision + 1,
      };
    }
  }
  return decodeBorderBlueprintRecordJson(next, formatVersion: formatVersion);
}

bool _usesModel(Object? value, String modelId) => switch (value) {
  Map() => value.entries.any(
    (entry) =>
        (entry.key == 'sourceModelId' && entry.value == modelId) ||
        _usesModel(entry.value, modelId),
  ),
  List() => value.any((item) => _usesModel(item, modelId)),
  _ => false,
};

Object? _repointModel(Object? value, String modelId, String replacementId) =>
    switch (value) {
      Map() => <String, Object?>{
        for (final MapEntry(:key, :value) in value.entries)
          key as String: key == 'sourceModelId' && value == modelId
              ? replacementId
              : _repointModel(value, modelId, replacementId),
      },
      List() => [
        for (final item in value) _repointModel(item, modelId, replacementId),
      ],
      _ => value,
    };
