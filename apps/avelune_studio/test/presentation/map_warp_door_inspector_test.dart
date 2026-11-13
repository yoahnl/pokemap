import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {

  test('passive arrival explicitly clears local door', () {
    final document = _document(_boundMap());
    WarpEditingCommands(
      document,
      _project(),
    ).retarget('house', triggerMode: MapWarpTriggerMode.sceneOnly);
    expect(
      document.current.warps.single.triggerMode,
      MapWarpTriggerMode.sceneOnly,
    );
    expect(document.current.warps.single.door, isNull);
    document.restore(redo: false);
    expect(document.current, _boundMap());
  });

  test('duplicate instance identities are refused by the scene contract', () {
    final map = _map();
    final instance = map.spatialScene!.instances.single;
    expect(
      () => map.spatialScene!.copyWith(instances: [instance, instance]),
      throwsFormatException,
    );
  });

  test('retargeting keeps door and geometry', () {
    final map = _boundMap();
    final document = _document(map);
    WarpEditingCommands(
      document,
      _project(),
    ).retarget('house', targetPos: const GridPos(x: 3, y: 2));
    expect(document.current.warps.single.door, map.warps.single.door);
    expect(document.current.spatialScene, map.spatialScene);
    document.restore(redo: false);
    expect(document.current, map);
  });
}

EditableMapDocument _document(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
);

MapData _boundMap() {
  final map = _map();
  return map.copyWith(
    warps: [
      map.warps.single.copyWith(
        door: const MapWarpDoor(
          instanceId: 'house-door',
          openAnimationIndex: 0,
          closeAnimationIndex: 1,
          exitPos: GridPos(x: 4, y: 4),
        ),
      ),
    ],
  );
}

MapData _map() => MapData(
  id: 'village',
  name: 'Village',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: 'house-door',
        modelId: 'door-model',
        position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
        blocksMovement: false,
      ),
    ],
  ),
  warps: [
    MapWarp(
      id: 'house',
      pos: const GridPos(x: 4, y: 3),
      targetMapId: 'room',
      targetPos: const GridPos(x: 2, y: 2),
    ),
  ],
);

ProjectManifest _project({bool singleClip = false}) => ProjectManifest(
  name: 'Doors',
  version: ProjectVersion.v9,
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  maps: const [
    ProjectMapEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'village.json',
    ),
    ProjectMapEntry(id: 'room', name: 'Maison', relativePath: 'room.json'),
  ],
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'door-model',
      name: 'Porte de la maison',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door-model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 2,
        animations: [
          Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: .25),
          if (!singleClip)
            Model3dAnimation(index: 1, name: 'Fermer', durationSeconds: .25),
        ],
      ),
    ),
  ],
);
