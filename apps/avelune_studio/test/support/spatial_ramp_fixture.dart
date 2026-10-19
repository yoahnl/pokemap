import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:map_core/map_core.dart';

MapData precisionRampMap({bool instances = true}) {
  final ramp = SpatialRamp(
    id: 'north',
    x: 2.125,
    z: 3,
    width: 3.625,
    depth: 3,
    lowLevel: 4,
    highLevel: 8,
    direction: SpatialRampDirection.north,
  );
  final other = SpatialRamp(
    id: 'other',
    x: 9,
    z: 3,
    width: 2.75,
    depth: 3,
    lowLevel: 4,
    highLevel: 8,
    direction: SpatialRampDirection.north,
  );
  final scene = MapSpatialScene(
    width: 16,
    depth: 12,
    levelHeight: .25,
    generateCliffs: false,
    heightLevels: List.generate(
      192,
      (index) => index ~/ 16 < 3
          ? 8
          : index ~/ 16 >= 5
          ? 4
          : 6,
    ),
    navigation: SpatialNavigationProfile(
      spawn: SpatialSpawn(x: 12.5, z: 10.5),
      allowDiagonalMovement: true,
      ramps: [ramp, other],
      blockedAreas: [SpatialBlockedArea(x: 14, z: 8, width: 1, depth: 1)],
    ),
  );
  return MapData(
    id: 'ramp-map',
    name: 'Pentes précises',
    version: ProjectVersion.v9,
    size: const GridSize(width: 16, height: 12),
    warps: const [
      MapWarp(
        id: 'exit',
        pos: GridPos(x: 12, y: 11),
        targetMapId: 'ramp-map',
        targetPos: GridPos(x: 12, y: 10),
      ),
    ],
    layers: instances
        ? [
            MapLayer.environment(
              id: 'forest',
              name: 'Arbres',
              content: EnvironmentLayerContent(
                targetsSpatialTerrain: true,
                areas: [
                  EnvironmentArea(
                    id: 'trees',
                    name: 'Arbres',
                    presetId: 'trees',
                    seed: 9,
                    mask: EnvironmentAreaMask(
                      width: 16,
                      height: 12,
                      cells: List.filled(192, false),
                    ),
                    generatedPlacementIds: ['supported', 'other-supported'],
                    manualPlacementIds: ['other-supported'],
                  ),
                ],
              ),
            ),
          ]
        : [],
    spatialScene: scene.copyWith(
      instances: instances
          ? [
              SpatialModelInstance(
                id: 'supported',
                modelId: 'tree',
                position: Model3dVector3(
                  x: 3.5,
                  y: scene.worldHeightAt(3.5, 4.5) - .375,
                  z: 4.5,
                ),
                rotationDegrees: 37,
                scale: .8,
                animationIndex: 1,
                animationLoop: false,
                animationSpeed: .75,
                blocksMovement: false,
              ),
              SpatialModelInstance(
                id: 'other-supported',
                modelId: 'tree',
                position: Model3dVector3(
                  x: 10.5,
                  y: scene.worldHeightAt(10.5, 4.5) + .125,
                  z: 4.5,
                ),
              ),
              SpatialModelInstance(
                id: 'outside',
                modelId: 'tree',
                position: Model3dVector3(x: 12.5, y: 1.25, z: 10.5),
              ),
            ]
          : [],
    ),
  );
}

EditableMapDocument rampDocument(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r1'),
);

MapData sourceRampFootprint(SpatialRamp ramp) {
  if (ramp.lowLevel != ramp.lowLevel.toInt() ||
      ramp.highLevel != ramp.highLevel.toInt()) {
    throw ArgumentError('This grid-only fixture requires integral endpoints.');
  }
  final alongZ =
      ramp.direction == SpatialRampDirection.north ||
      ramp.direction == SpatialRampDirection.south;
  final negativeHigh =
      ramp.direction == SpatialRampDirection.north ||
      ramp.direction == SpatialRampDirection.west;
  final levels = List.generate(128 * 64, (index) {
    final coordinate = alongZ ? index ~/ 128 : index % 128;
    final start = alongZ ? ramp.z : ramp.x;
    final end = start + (alongZ ? ramp.depth : ramp.width);
    if (coordinate < start) {
      return (negativeHigh ? ramp.highLevel : ramp.lowLevel).toInt();
    }
    if (coordinate >= end.floor()) {
      return (negativeHigh ? ramp.lowLevel : ramp.highLevel).toInt();
    }
    return ramp.lowLevel.toInt();
  });
  return MapData(
    id: ramp.id,
    name: ramp.id,
    version: ProjectVersion.v9,
    size: const GridSize(width: 128, height: 64),
    spatialScene: MapSpatialScene(
      width: 128,
      depth: 64,
      levelHeight: .25,
      heightLevels: levels,
      navigation: SpatialNavigationProfile(ramps: [ramp]),
    ),
  );
}
