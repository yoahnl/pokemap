import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> doorJson() => {
  'instanceId': 'door',
  'openAnimationIndex': 0,
  'closeAnimationIndex': 1,
  'exitPos': {'x': 2, 'y': 3},
};

MapWarp warp({Map<String, dynamic>? door, String mode = 'on_enter'}) =>
    MapWarp.fromJson({
      'id': 'entrance',
      'pos': {'x': 2, 'y': 2},
      'targetMapId': mode == 'scene_only' ? 'village' : 'room',
      'targetPos': {'x': 2, 'y': 2},
      'triggerMode': mode,
      'door': door,
    });

MapData map(MapWarp warp, {bool spatial = true, bool instance = true}) =>
    MapData(
      id: 'village',
      name: 'Village',
      size: const GridSize(width: 6, height: 6),
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      spatialScene: spatial
          ? MapSpatialScene(
              width: 6,
              depth: 6,
              instances: [
                if (instance)
                  SpatialModelInstance(
                    id: 'door',
                    modelId: 'door-model',
                    position: Model3dVector3(x: 2, y: 0, z: 2),
                    blocksMovement: false,
                  ),
              ],
            )
          : null,
      warps: [warp],
    );

ProjectManifest project({bool closeClip = true, double duration = .25}) =>
    ProjectManifest(
      name: 'Doors',
      version: ProjectVersion.v9,
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      maps: const [],
      tilesets: const [],
      models3d: [
        ProjectModel3dEntry(
          id: 'door-model',
          name: 'Door',
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
              Model3dAnimation(
                index: 0,
                name: 'Open',
                durationSeconds: duration,
              ),
              if (closeClip)
                Model3dAnimation(index: 1, name: 'Close', durationSeconds: .25),
            ],
          ),
        ),
      ],
    );

void main() {
  test('native door binding survives typed JSON without scenes or events', () {
    final input = doorJson();
    expect(warp(door: input).toJson()['door'], input);
    expect(warp().toJson(), isNot(contains('door')));
  });

  test('valid native door map passes contextual validation', () {
    MapValidator.validate(
      map(warp(door: doorJson())),
      projectDialogueContext: project(),
    );
  });

  for (final invalid in [
    {...doorJson(), 'instanceId': ''},
    {...doorJson(), 'openAnimationIndex': -1},
    {...doorJson(), 'closeAnimationIndex': -1},
    {
      ...doorJson(),
      'exitPos': {'x': 2, 'y': 2},
    },
    {
      ...doorJson(),
      'exitPos': {'x': 3, 'y': 3},
    },
    {
      ...doorJson(),
      'exitPos': {'x': 2, 'y': 6},
    },
  ]) {
    test('invalid native binding is rejected: $invalid', () {
      expect(
        () => MapValidator.validate(map(warp(door: invalid))),
        throwsA(isA<ValidationException>()),
      );
    });
  }

  test(
    'native doors reject 2D, passive anchors and missing local instance',
    () {
      for (final candidate in [
        map(warp(door: doorJson()), spatial: false),
        map(warp(door: doorJson(), mode: 'scene_only')),
        map(warp(door: doorJson()), instance: false),
      ]) {
        expect(
          () => MapValidator.validate(candidate),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );

  test('contextual native doors reject missing clips', () {
    for (final candidate in [project(closeClip: false)]) {
      expect(
        () => MapValidator.validate(
          map(warp(door: doorJson())),
          projectDialogueContext: candidate,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('native doors own playback and reject ambient animation', () {
    final candidate = map(warp(door: doorJson()));
    final scene = candidate.spatialScene!;
    expect(
      () => MapValidator.validate(
        candidate.copyWith(
          spatialScene: scene.copyWith(
            instances: [scene.instances.single.copyWith(animationIndex: 0)],
          ),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test(
    'native doors require animation capability without story capability',
    () {
      final candidate = map(warp(door: doorJson()));
      expect(
        SpatialGameplayCapabilities.requiresModelAnimation(
          project(),
          maps: [candidate],
        ),
        isTrue,
      );
      expect(SpatialGameplayCapabilities.requiresStory(project()), isFalse);
    },
  );

  test(
    'partial warp edits preserve, replace and explicitly clear the door',
    () {
      final candidate = map(warp(door: doorJson()));
      final original = candidate.warps.single.door;
      final unchanged = updateWarpOnMap(
        candidate,
        warpId: 'entrance',
        targetPos: const GridPos(x: 1, y: 1),
      );
      expect(unchanged.warps.single.door, original);
      final replaced = updateWarpOnMap(
        unchanged,
        warpId: 'entrance',
        door: original!.copyWith(exitPos: const GridPos(x: 3, y: 2)),
      );
      expect(replaced.warps.single.door!.exitPos, const GridPos(x: 3, y: 2));
      expect(
        updateWarpOnMap(
          replaced,
          warpId: 'entrance',
          clearDoor: true,
        ).warps.single.door,
        isNull,
      );
    },
  );

  test(
    'moving a door preserves exit direction and undo restores both positions',
    () {
      final candidate = map(warp(door: doorJson()));
      final moved = updateWarpOnMap(
        candidate,
        warpId: 'entrance',
        pos: const GridPos(x: 3, y: 3),
      );
      expect(moved.warps.single.door!.exitPos, const GridPos(x: 3, y: 4));
      final undone = updateWarpOnMap(
        moved,
        warpId: 'entrance',
        pos: candidate.warps.single.pos,
      );
      expect(undone, candidate);
      expect(
        () => updateWarpOnMap(
          candidate,
          warpId: 'entrance',
          pos: const GridPos(x: 2, y: 5),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(candidate.warps.single.pos, const GridPos(x: 2, y: 2));
    },
  );

  test('renaming a bound warp preserves its own local door', () {
    final candidate = map(warp(door: doorJson()));
    final renamed = updateWarpOnMap(
      candidate,
      warpId: 'entrance',
      id: 'front-door',
    );
    expect(renamed.warps.single.id, 'front-door');
    expect(renamed.warps.single.door, candidate.warps.single.door);
  });

  test('collision paint rejects an authored blocked exit', () {
    final candidate = map(warp(door: doorJson())).copyWith(
      layers: [
        CollisionLayer(
          id: 'walls',
          name: 'Walls',
          collisions: List<bool>.filled(36, false)..[3 * 6 + 2] = true,
        ),
      ],
    );
    expect(
      () => MapValidator.validate(candidate),
      throwsA(isA<ValidationException>()),
    );
  });

  test('a native door records its local model-instance dependency', () {
    final candidate = map(warp(door: doorJson()));
    final index = buildNarrativeDependencyIndex(
      project: project(),
      maps: [candidate],
    );
    expect(
      index
          .usagesFor(
            NarrativeDependencyKey.mapSource(
              mapId: 'village',
              sourceKind: 'modelInstance',
              sourceId: 'door',
            ),
          )
          .map((usage) => usage.path),
      contains('maps[village].warps[entrance].door.instanceId'),
    );
  });

  test('direct spatial removal refuses a native door owner', () {
    expect(
      () => const SpatialMapOperations().deleteInstance(
        map(warp(door: doorJson())),
        'door',
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
