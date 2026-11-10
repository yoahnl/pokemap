import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_warp_drafts.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('model clips and cardinal exit save atomically and are undoable', () {
    final document = _document(_map());
    final original = document.current;
    final draft = _draft(original)..enable(true);
    expect(document.current, same(original));
    expect(draft.candidates.single.id, 'house-door');
    expect(draft.problem, isNull);
    draft.value = draft.value!.copyWith(
      openAnimationIndex: 1,
      closeAnimationIndex: 0,
      exitPos: const GridPos(x: 5, y: 3),
    );
    WarpEditingCommands(
      document,
      _project(),
    ).configureDoor('house', draft.value);
    expect(
      document.current.warps.single.door,
      const MapWarpDoor(
        instanceId: 'house-door',
        openAnimationIndex: 1,
        closeAnimationIndex: 0,
        exitPos: GridPos(x: 5, y: 3),
      ),
    );
    expect(document.current.spatialScene, original.spatialScene);
    expect(document.current.layers, original.layers);
    expect(document.current.warps.single.targetMapId, 'room');
    expect(document.current.warps.single.targetPos, const GridPos(x: 2, y: 2));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, original);
    document.restore(redo: true);
    expect(document.current.warps.single.door!.openAnimationIndex, 1);
  });

  test('removing a door preserves normal passage and undo', () {
    final document = _document(_boundMap());
    final original = document.current;
    final draft = _draft(original)..enable(false);
    expect(draft.changed, isTrue);
    WarpEditingCommands(
      document,
      _project(),
    ).configureDoor('house', draft.enabled ? draft.value : null);
    expect(document.current.warps.single.door, isNull);
    expect(
      document.current.warps.single.targetPos,
      original.warps.single.targetPos,
    );
    expect(document.current.spatialScene, original.spatialScene);
    document.restore(redo: false);
    expect(document.current, original);
  });

  test('single valid clip is available for opening and closing', () {
    final map = _map();
    final project = _project(singleClip: true);
    final draft = MapWarpDoorDraft(map, project, map.warps.single)
      ..enable(true);
    expect(draft.value!.openAnimationIndex, 0);
    expect(draft.value!.closeAnimationIndex, 0);
    expect(draft.problem, isNull);
    final document = _document(map);
    WarpEditingCommands(document, project).configureDoor('house', draft.value);
    expect(document.current.warps.single.door, draft.value);
  });

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

  test('unresolved saved model stays explicit and never silently rebinds', () {
    final map = _boundMap();
    final draft = MapWarpDoorDraft(
      map,
      _project().copyWith(models3d: []),
      map.warps.single,
    );
    expect(draft.candidates, isEmpty);
    expect(draft.problem, isNotNull);
    expect(draft.value, map.warps.single.door);
    expect(draft.changed, isFalse);
    draft.enable(false);
    expect(draft.problem, isNull);
    expect(draft.changed, isTrue);
    expect(map, _boundMap());
  });

  test('autoplaying instances are excluded from door choices', () {
    final map = _map();
    final instance = map.spatialScene!.instances.single;
    final source = map.copyWith(
      spatialScene: map.spatialScene!.copyWith(
        instances: [instance.copyWith(animationIndex: 0)],
      ),
    );
    final draft = _draft(source)..enable(true);
    expect(draft.candidates, isEmpty);
    expect(draft.problem, isNotNull);
  });

  test('duplicate instance identities are refused by the scene contract', () {
    final map = _map();
    final instance = map.spatialScene!.instances.single;
    expect(
      () => map.spatialScene!.copyWith(instances: [instance, instance]),
      throwsFormatException,
    );
  });

  test('chosen local instance is bound rather than its shared model', () {
    final map = _map();
    final first = map.spatialScene!.instances.single;
    final source = map.copyWith(
      spatialScene: map.spatialScene!.copyWith(
        instances: [
          first,
          SpatialModelInstance(
            id: 'second-door',
            modelId: first.modelId,
            position: Model3dVector3(x: 6.5, y: 0, z: 3.5),
            blocksMovement: false,
          ),
        ],
      ),
    );
    final draft = _draft(source)..enable(true);
    draft.value = draft.binding(draft.candidates.last, draft.value!.exitPos);
    final document = _document(source);
    WarpEditingCommands(
      document,
      _project(),
    ).configureDoor('house', draft.value);
    expect(document.current.warps.single.door!.instanceId, 'second-door');
    expect(document.current.spatialScene!.instances, hasLength(2));
  });

  test('exits are cardinal cells inside map and exclude blocked areas', () {
    final map = _map();
    final source = map.copyWith(
      warps: [map.warps.single.copyWith(pos: const GridPos(x: 0, y: 0))],
    );
    expect(_draft(source).exits(), {
      const GridPos(x: 0, y: 1): 'Sud',
      const GridPos(x: 1, y: 0): 'Est',
    });
    final blocked = source.copyWith(
      spatialScene: source.spatialScene!.copyWith(
        navigation: source.spatialScene!.navigation.copyWith(
          blockedAreas: [SpatialBlockedArea(x: 1, z: 0, width: 1, depth: 1)],
        ),
      ),
    );
    expect(_draft(blocked).exits(), {const GridPos(x: 0, y: 1): 'Sud'});
  });

  test('invalid clip never mutates document or history', () {
    final map = _map();
    final document = _document(map);
    final draft = _draft(map)..enable(true);
    draft.value = draft.value!.copyWith(openAnimationIndex: 99);
    expect(draft.problem, isNotNull);
    expect(
      () => WarpEditingCommands(
        document,
        _project(),
      ).configureDoor('house', draft.value),
      throwsA(isA<ValidationException>()),
    );
    expect(document.current, same(map));
    expect(document.undoCount, 0);
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

MapWarpDoorDraft _draft(MapData map) =>
    MapWarpDoorDraft(map, _project(), map.warps.single);
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
