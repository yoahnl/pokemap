import '../models/enums.dart';
import '../models/spatial_lift.dart';
import '../models/geometry.dart';
import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/spatial_day_night_cycle.dart';
import '../models/spatial_navigation.dart';
import '../models/spatial_terrain_surface.dart';
import '../models/project_model3d.dart';
import '../models/smart_tile.dart';
import 'spatial_stair_attachment.dart';

final class SpatialCellLevel {
  const SpatialCellLevel({
    required this.x,
    required this.z,
    required this.level,
  });
  final int x, z, level;
}

final class SpatialMapOperations {
  const SpatialMapOperations();

  MapData upsertLifts(MapData map, List<SpatialLiftDefinition> lifts) {
    final scene = _scene(map);
    if (lifts.isEmpty || lifts.length > 64 || lifts.map((v) => v.id).toSet().length != lifts.length) throw const FormatException('A lift batch requires unique bounded identities.');
    final updates = {for (final lift in lifts) lift.id:lift};
    final ids = scene.lifts.map((v)=>v.id).toSet();
    return map.copyWith(spatialScene:scene.copyWith(lifts:[for(final lift in scene.lifts)updates[lift.id] ?? lift,for(final lift in lifts)if(!ids.contains(lift.id))lift]));
  }
  MapData deleteLifts(MapData map, List<String> ids) {
    final scene = _scene(map);
    if (ids.isEmpty || ids.length > 64 || ids.toSet().length != ids.length || ids.any((id)=>!scene.lifts.any((v)=>v.id==id))) throw const FormatException('Lift deletion requires existing unique identities.');
    return map.copyWith(spatialScene:scene.copyWith(lifts:scene.lifts.where((v)=>!ids.contains(v.id))));
  }

  MapData upsertTerrainSurfaces(
    MapData map,
    List<SpatialTerrainSurface> surfaces, {
    bool reanchorInstances = true,
    bool pinBorderOwnedInstances = false,
  }) {
    final scene = _scene(map);
    _surfaceIds(surfaces.map((surface) => surface.id).toList());
    final replacements = {for (final surface in surfaces) surface.id: surface};
    final existingIds = scene.terrainSurfaces.surfaces
        .map((surface) => surface.id)
        .toSet();
    final after = scene.copyWith(
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          for (final surface in scene.terrainSurfaces.surfaces)
            replacements[surface.id] ?? surface,
          for (final surface in surfaces)
            if (!existingIds.contains(surface.id)) surface,
        ],
      ),
    );
    return map.copyWith(
      spatialScene: reanchorInstances
          ? _reanchor(
              scene,
              after,
              pinned: pinBorderOwnedInstances
                  ? _borderOwnedInstanceIds(map)
                  : const {},
            )
          : after,
    );
  }

  MapData deleteTerrainSurfaces(
    MapData map,
    List<String> surfaceIds, {
    bool reanchorInstances = true,
    bool pinBorderOwnedInstances = false,
  }) {
    final scene = _scene(map);
    _surfaceIds(surfaceIds);
    final ids = surfaceIds.toSet();
    final existing = scene.terrainSurfaces.surfaces
        .map((surface) => surface.id)
        .toSet();
    if (!existing.containsAll(ids)) {
      throw const FormatException(
        'A continuous terrain surface does not exist.',
      );
    }
    final after = scene.copyWith(
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: scene.terrainSurfaces.surfaces.where(
          (surface) => !ids.contains(surface.id),
        ),
      ),
    );
    return map.copyWith(
      spatialScene: reanchorInstances
          ? _reanchor(
              scene,
              after,
              pinned: pinBorderOwnedInstances
                  ? _borderOwnedInstanceIds(map)
                  : const {},
            )
          : after,
    );
  }

  void _surfaceIds(List<String> ids) {
    if (ids.isEmpty ||
        ids.length > maximumSpatialTerrainSurfaces ||
        ids.toSet().length != ids.length ||
        ids.any((id) => !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id))) {
      throw const FormatException(
        'Terrain batches require 1 to 128 distinct surface identities.',
      );
    }
  }

  MapData setLevels(MapData map, List<SpatialCellLevel> cells) {
    final scene = _scene(map);
    final levels = scene.heightLevels.toList();
    for (final cell in cells) {
      if (cell.x < 0 ||
          cell.z < 0 ||
          cell.x >= scene.width ||
          cell.z >= scene.depth ||
          cell.level < 0 ||
          cell.level > MapSpatialScene.maximumTerrainLevel) {
        throw const FormatException(
          'Spatial cells must be inside the map with levels from 0 to 64.',
        );
      }
      final covered = scene.terrainSurfaces
          .candidatesAtCell(cell.x, cell.z)
          .where((surface) => surface.overlapsCell(cell.x, cell.z))
          .map((surface) => surface.id)
          .toList();
      if (covered.isNotEmpty) {
        throw ValidationException(
          'This cell belongs to a continuous terrain surface. Edit that surface instead of its underlying grid.',
          code: 'spatial.terrain.surface_grid_conflict',
          details: {'surfaceIds': covered, 'x': cell.x, 'z': cell.z},
        );
      }
      levels[cell.z * scene.width + cell.x] = cell.level;
    }
    return map.copyWith(
      spatialScene: _reanchor(scene, scene.copyWith(heightLevels: levels)),
    );
  }

  MapData upsertInstance(
    MapData map,
    SpatialModelInstance instance, {
    ProjectModel3dEntry? model,
  }) => upsertInstances(map, [
    instance,
  ], models: model == null ? const [] : [model]);

  MapData upsertInstances(
    MapData map,
    List<SpatialModelInstance> instances, {
    Iterable<ProjectModel3dEntry> models = const [],
  }) {
    final scene = _scene(map);
    final replacements = {for (final value in instances) value.id: value};
    if (replacements.length != instances.length) {
      throw const FormatException('Instance identities must be distinct.');
    }
    final definitions = {for (final model in models) model.id: model};
    final previous = {for (final value in scene.instances) value.id: value};
    final ramps = scene.navigation.ramps.toList();
    const attachment = SpatialStairAttachment();
    for (final instance in instances) {
      _requireAuthoredInstance(instance.id);
      final model = definitions[instance.modelId];
      final linked = ramps
          .where((ramp) => ramp.surfaceInstanceId == instance.id)
          .toList();
      if (model?.rampProfile != null) {
        if (linked.length > 1) {
          throw const FormatException(
            'A stair profile requires a single attached ramp.',
          );
        }
        final rampId = linked.firstOrNull?.id ?? instance.id;
        if (ramps.any(
          (ramp) => ramp.id == rampId && ramp.surfaceInstanceId != instance.id,
        )) {
          throw const FormatException(
            'The stair ramp identity is already in use.',
          );
        }
        ramps.removeWhere((ramp) => ramp.surfaceInstanceId == instance.id);
        ramps.add(
          attachment.fromModel(
            model!,
            instance,
            scene.levelHeight,
            rampId: rampId,
          ),
        );
        replacements[instance.id] = instance.copyWith(blocksMovement: false);
      } else if (linked.isNotEmpty) {
        final before = previous[instance.id]!;
        if (before.modelId != instance.modelId) {
          ramps.removeWhere((ramp) => ramp.surfaceInstanceId == instance.id);
          continue;
        }
        for (final ramp in linked) {
          ramps[ramps.indexOf(ramp)] = attachment.transform(
            ramp,
            before,
            instance,
            scene.levelHeight,
          );
        }
      }
    }
    final sceneResult = map.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          for (final value in scene.instances) replacements[value.id] ?? value,
          for (final value in instances)
            if (!previous.containsKey(value.id)) replacements[value.id]!,
        ],
        navigation: scene.navigation.copyWith(ramps: ramps),
      ),
    );
    final bindings = {
      for (final instance in sceneResult.spatialScene!.instances)
        if (instance.entityId != null)
          instance.entityId!: instance.supportPosition,
    };
    final result = sceneResult.copyWith(
      entities: [
        for (final entity in sceneResult.entities)
          if (bindings[entity.id] case final position?)
            entity.copyWith(
              pos: GridPos(x: position.x.floor(), y: position.z.floor()),
            )
          else
            entity,
      ],
    );
    validateSpatialEntityModelBindings(result);
    return result;
  }

  MapData deleteInstance(MapData map, String instanceId) {
    _requireAuthoredInstance(instanceId);
    if (map.warps.any((warp) => warp.door?.instanceId == instanceId)) {
      throw const ValidationException(
        'A native door still references this model instance.',
        code: 'map3d.instance_referenced',
      );
    }
    final scene = _scene(map);
    if (!scene.instances.any((value) => value.id == instanceId)) {
      throw const FormatException('The spatial instance does not exist.');
    }
    return map.copyWith(
      spatialScene: scene.copyWith(
        instances: scene.instances.where((value) => value.id != instanceId),
        navigation: scene.navigation.copyWith(
          ramps: scene.navigation.ramps.where(
            (ramp) => ramp.surfaceInstanceId != instanceId,
          ),
        ),
      ),
    );
  }

  MapData configureDayNightCycle(MapData map, SpatialDayNightCycle? cycle) =>
      map.copyWith(
        spatialScene: _scene(
          map,
        ).copyWith(dayNightCycle: cycle, clearDayNightCycle: cycle == null),
      );

  MapData configureCamera(MapData map, SpatialCameraProfile camera) =>
      map.copyWith(spatialScene: _scene(map).copyWith(camera: camera));

  MapData configureNavigation(
    MapData map,
    SpatialNavigationProfile navigation, {
    Iterable<ProjectModel3dEntry> models = const [],
  }) {
    final scene = _scene(map);
    final result = map.copyWith(
      spatialScene: _reanchor(
        scene,
        scene.copyWith(navigation: navigation),
        reanchorAttached: false,
      ),
    );
    final modelIds = models
        .where((model) => model.rampProfile != null)
        .map((model) => model.id)
        .toSet();
    final stairs = result.spatialScene!.instances
        .where((instance) => modelIds.contains(instance.modelId))
        .toList();
    if (stairs.isNotEmpty) {
      final expected = upsertInstances(
        result,
        stairs,
        models: models,
      ).spatialScene!.navigation.ramps;
      final actual = {for (final ramp in navigation.ramps) ramp.id: ramp};
      if (actual.length != expected.length ||
          expected.any((ramp) => actual[ramp.id] != ramp)) {
        throw const FormatException(
          'Stair ramps are derived from their model profile. Edit the staircase instead.',
        );
      }
    }
    return result;
  }

  MapData configureTerrainAppearance(
    MapData map, {
    SmartTileFrameRef? cliffFrame,
    bool? generateCliffs,
  }) => map.copyWith(
    spatialScene: _scene(
      map,
    ).copyWith(cliffFrame: cliffFrame, generateCliffs: generateCliffs),
  );

  MapData configureLevelHeight(MapData map, double levelHeight) {
    final scene = _scene(map);
    final after = MapSpatialScene(
      width: scene.width,
      depth: scene.depth,
      heightLevels: scene.heightLevels,
      terrainSurfaces: scene.terrainSurfaces,
      levelHeight: levelHeight,
      cliffFrame: scene.cliffFrame,
      generateCliffs: scene.generateCliffs,
      instances: scene.instances,
      camera: scene.camera,
      dayNightCycle: scene.dayNightCycle,
      navigation: scene.navigation,
    );
    return map.copyWith(spatialScene: _reanchor(scene, after));
  }

  Set<String> _borderOwnedInstanceIds(MapData map) => {
    for (final layer in map.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        ...feature.generatedPlacementIds,
  };

  MapSpatialScene _reanchor(
    MapSpatialScene before,
    MapSpatialScene after, {
    bool reanchorAttached = true,
    Set<String> pinned = const {},
  }) {
    final attached = {
      ...before.navigation.ramps,
      ...after.navigation.ramps,
    }.map((ramp) => ramp.surfaceInstanceId).whereType<String>().toSet();
    final owners = <String, SpatialModelInstance>{};
    for (final instance in before.instances.where(
      (instance) => attached.contains(instance.id),
    )) {
      final p = instance.position;
      final delta = reanchorAttached
          ? after.worldHeightAt(p.x, p.z, excludingRampSurface: instance.id) -
                before.worldHeightAt(
                  p.x,
                  p.z,
                  excludingRampSurface: instance.id,
                )
          : 0.0;
      owners[instance.id] = delta == 0
          ? instance
          : instance.copyWith(
              position: Model3dVector3(x: p.x, y: p.y + delta, z: p.z),
            );
    }
    final previous = {
      for (final instance in before.instances) instance.id: instance,
    };
    final positioned = after.copyWith(
      instances: after.instances.map(
        (instance) => owners[instance.id] ?? instance,
      ),
      navigation: after.navigation.copyWith(
        ramps: after.navigation.ramps.map((ramp) {
          final id = ramp.surfaceInstanceId;
          if (!reanchorAttached || id == null || owners[id] == null) {
            return ramp;
          }
          return const SpatialStairAttachment().transform(
            ramp,
            previous[id]!,
            owners[id]!,
            after.levelHeight,
            sourceLevelHeight: before.levelHeight,
          );
        }),
      ),
    );
    return positioned.copyWith(
      instances: positioned.instances.map((instance) {
        if (attached.contains(instance.id) || pinned.contains(instance.id)) {
          return instance;
        }
        final p = instance.position;
        final support = instance.supportPosition;
        final delta =
            positioned.worldHeightAt(support.x, support.z) -
            before.worldHeightAt(support.x, support.z);
        return delta == 0
            ? instance
            : instance.copyWith(
                position: Model3dVector3(x: p.x, y: p.y + delta, z: p.z),
              );
      }),
    );
  }

  MapSpatialScene _scene(MapData map) {
    if (map.version != ProjectVersion.v9 || map.spatialScene == null) {
      throw const FormatException('This operation requires a 3D map.');
    }
    validateSpatialMapStructure(map);
    return map.spatialScene!;
  }

  void _requireAuthoredInstance(String id) {
    if (id.startsWith('smt_')) {
      throw const FormatException(
        'Smart Tile models must be edited through their painted layer.',
      );
    }
  }
}
