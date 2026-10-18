import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError('Expected explicit project root and spatial QA recipe');
  }
  stdout.writeln(
    jsonEncode(
      await verifySpatialRecipe(
        Directory(args[0]),
        jsonDecode(await File(args[1]).readAsString()) as Map<String, dynamic>,
      ),
    ),
  );
}

Future<Map<String, Object?>> verifySpatialRecipe(
  Directory root,
  Map<String, dynamic> recipe,
) async {
  if (recipe['schemaVersion'] != 1 ||
      recipe['id'] is! String ||
      recipe.keys.any(
        (key) => !{
          'schemaVersion',
          'id',
          'provenance',
          'cases',
          'cinematicRoutes',
          'sceneIds',
        }.contains(key),
      )) {
    throw const FormatException('Invalid spatial QA recipe');
  }
  final cases = recipe['cases'] as List;
  final routes = recipe['cinematicRoutes'] as List? ?? [];
  if (cases.isEmpty && routes.isEmpty) {
    throw const FormatException('A spatial QA recipe must contain checks');
  }
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ),
    snapshotLoader: snapshots,
  );
  final opened = await api.openProject(root.path);
  try {
    final snapshot = await snapshots.load(opened.projectHandle);
    final project = snapshot.manifest;
    final maps = {for (final map in snapshot.maps) map.id: map};
    final receipts = <Map<String, Object?>>[];
    for (final value in cases) {
      final check = Map<String, dynamic>.from(value as Map);
      final map = maps[check['mapId']] ?? (throw StateError('Unknown QA map'));
      final initial = Map<String, dynamic>.from(check['initial'] as Map);
      final expected = Map<String, dynamic>.from(check['expected'] as Map);
      final frames = check['frames'];
      final dt = (check['dt'] as num).toDouble();
      if (frames is! int ||
          frames < 0 ||
          frames > 10000 ||
          !dt.isFinite ||
          dt <= 0 ||
          dt > 1) {
        throw const FormatException('Invalid bounded simulation duration');
      }
      final states = Map<String, dynamic>.from(
        check['modelStates'] as Map? ?? {},
      );
      final movement = SpatialMovementController.fromMap(
        map: map,
        models: project.models3d,
        spatialArrival: initial['position'] == null
            ? null
            : PlayerSpatialPosition(
                x: (initial['position']['x'] as num).toDouble(),
                z: (initial['position']['z'] as num).toDouble(),
              ),
        arrival: initial['grid'] == null
            ? null
            : GridPos.fromJson(
                Map<String, dynamic>.from(initial['grid'] as Map),
              ),
        modelStateProvider: (id) {
          final state = states[id];
          return state == null
              ? null
              : SpatialModelRuntimeState(
                  modelId: state['modelId'] as String,
                  animationIndex: state['animationIndex'] as int?,
                  normalizedTime: (state['normalizedTime'] as num).toDouble(),
                  blocksMovement: state['blocksMovement'] as bool,
                );
        },
      );
      final warps = SpatialWarpController(
        map: map,
        x: movement.x,
        z: movement.z,
      );
      MapWarp? reached;
      if (expected.containsKey('initialWarpId')) {
        reached = warps.update(
          x: movement.x,
          z: movement.z,
          facing: EntityFacing.values.byName(initial['facing'] as String),
        );
        _require(
          reached?.id == expected['initialWarpId'],
          '${check['id']}: unexpected initial warp',
        );
      }
      final input = check['input'] as Map;
      movement.setInput(x: input['x'] as int, z: input['z'] as int);
      for (var frame = 0; frame < frames; frame++) {
        movement.update(dt);
        reached ??= warps.update(
          x: movement.x,
          z: movement.z,
          facing: movement.facing,
          bumpedCell: movement.bumpedCell,
        );
      }
      _require(
        !expected.containsKey('warpId') || reached?.id == expected['warpId'],
        '${check['id']}: unexpected warp ${reached?.id}',
      );
      for (final (key, actual) in [('x', movement.x), ('z', movement.z)]) {
        if (expected['${key}Min'] != null) {
          _require(
            actual >= (expected['${key}Min'] as num),
            '${check['id']}: $key below bound',
          );
        }
        if (expected['${key}MaxExclusive'] != null) {
          _require(
            actual < (expected['${key}MaxExclusive'] as num),
            '${check['id']}: $key above bound',
          );
        }
        if (expected['${key}GreaterThan'] != null) {
          _require(
            actual > (expected['${key}GreaterThan'] as num),
            '${check['id']}: $key below strict bound',
          );
        }
      }
      receipts.add({
        'id': check['id'],
        'mapId': map.id,
        'frames': frames,
        'x': movement.x,
        'z': movement.z,
        'warpId': reached?.id,
      });
    }
    for (final value in routes) {
      final check = Map<String, dynamic>.from(value as Map);
      final asset = project.cinematics.singleWhere(
        (entry) => entry.id == check['cinematicId'],
      );
      final inspected = const CinematicAuthoringInspector().inspect(
        project: project,
        cinematic: asset,
      );
      _require(inspected.canPublish, 'Cinematic ${asset.id} cannot publish');
      final map = maps[asset.mapId]!;
      final context = asset.stageContext!;
      final points = {for (final point in context.stagePoints) point.id: point};
      var start = points[check['startStagePointId']]!;
      final position = check['playerPosition'] as Map;
      final movement = SpatialMovementController.fromMap(
        map: map,
        models: project.models3d,
      );
      for (final path in context.manualPaths) {
        for (final id in path.waypointStagePointIds) {
          final target = points[id]!;
          _require(
            movement.canTraverseActor(
              start.x,
              start.y,
              target.x,
              target.y,
              ignoredEntityId: check['ignoredEntityId'] as String,
              collideWithPlayer: true,
              playerPosition: PlayerSpatialPosition(
                x: (position['x'] as num).toDouble(),
                z: (position['z'] as num).toDouble(),
              ),
            ),
            'Cinematic ${asset.id} crosses a collision ${start.id}→$id',
          );
          _require(
            map.spatialScene!.worldHeightAt(target.x, target.y) ==
                (check['expectedHeight'] as num).toDouble(),
            'Cinematic ${asset.id} route height changed',
          );
          receipts.add({'cinematicId': asset.id, 'from': start.id, 'to': id});
          start = target;
        }
      }
    }
    for (final id in recipe['sceneIds'] as List? ?? []) {
      final scene = project.scenes.singleWhere((entry) => entry.id == id);
      final report = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: maps,
      );
      _require(
        !report.hasErrors && buildSceneRuntimePlan(scene).canBuild,
        'Scene $id cannot build',
      );
      receipts.add({'sceneId': id});
    }
    return {
      'schemaVersion': 1,
      'recipeId': recipe['id'],
      'projectRevision': snapshot.revision,
      'checks': receipts,
      'passed': true,
    };
  } finally {
    await api.closeWorkspace(opened.workspaceHandle);
  }
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
