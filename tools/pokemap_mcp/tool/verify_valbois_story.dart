import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

void require(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main(List<String> args) async {
  if (args.length != 2)
    throw ArgumentError('Expected project root and story definitions');
  final root = Directory(args[0]).resolveSymbolicLinksSync();
  final definitions =
      jsonDecode(await File(args[1]).readAsString()) as Map<String, dynamic>;
  final project = ProjectManifest.fromJson(
    jsonDecode(await File('$root/project.json').readAsString())
        as Map<String, dynamic>,
  );
  require(
    project.settings.dimension == ProjectDimension.threeD,
    'Expected a 3D project',
  );
  final maps = <String, MapData>{};
  for (final entry in project.maps) {
    maps[entry.id] = MapData.fromJson(
      jsonDecode(await File('$root/${entry.relativePath}').readAsString())
          as Map<String, dynamic>,
    );
  }
  final door = definitions['door'] as Map<String, dynamic>;
  final instance = SpatialModelInstance.fromJson(
    door['instance'] as Map<String, dynamic>,
  );
  final model = project.models3d
      .firstWhere((model) => model.id == instance.modelId)
      .copyWith(
        pivot: Model3dVector3.fromJson(door['pivot'] as Map<String, dynamic>),
      );
  final models = project.models3d
      .map((entry) => entry.id == model.id ? model : entry)
      .toList();
  final village = maps['first-map']!;
  final scene = village.spatialScene!;
  final navigation = scene.navigation.toJson();
  final areas = (navigation['blockedAreas'] as List)
      .cast<Map<String, dynamic>>();
  final original = areas.indexWhere(
    (area) =>
        area['x'] == 5 &&
        area['z'] == 4 &&
        area['width'] == 5 &&
        area['depth'] == 4,
  );
  if (original >= 0) {
    areas.replaceRange(original, original + 1, [
      {'x': 5, 'z': 4, 'width': 5, 'depth': 3},
      {'x': 5, 'z': 7, 'width': 2, 'depth': 1},
      {'x': 8, 'z': 7, 'width': 2, 'depth': 1},
    ]);
  }
  navigation['blockedAreas'] = areas;
  final proposed = village.copyWith(
    spatialScene: scene.copyWith(
      navigation: SpatialNavigationProfile.fromJson(navigation),
      instances: [
        ...scene.instances.where((value) => value.id != instance.id),
        instance,
      ],
    ),
    warps: [
      for (final warp in village.warps)
        warp.id == 'home-door'
            ? MapWarp.fromJson(door['warp'] as Map<String, dynamic>)
            : warp,
    ],
  );
  maps['first-map'] = proposed;
  final closed = SpatialMovementController.fromMap(
    map: proposed,
    models: models,
    spatialArrival: PlayerSpatialPosition(x: 7.5, z: 10),
  );
  final closedWarps = SpatialWarpController(
    map: proposed,
    x: closed.x,
    z: closed.z,
  );
  closed.setInput(x: 0, z: -1);
  for (var frame = 0; frame < 180; frame++) {
    closed.update(1 / 60);
    require(
      closedWarps.update(
            x: closed.x,
            z: closed.z,
            facing: closed.facing,
            bumpedCell: closed.bumpedCell,
          ) ==
          null,
      'The closed door allowed the interior warp',
    );
  }
  require(
    closed.z >= 8 && closed.z < 9,
    'The closed door is not blocking at the entrance: ${closed.z}',
  );
  final open = SpatialMovementController.fromMap(
    map: proposed,
    models: models,
    spatialArrival: PlayerSpatialPosition(x: 7.5, z: 10),
    modelStateProvider: (id) => id == instance.id
        ? SpatialModelRuntimeState(
            modelId: model.id,
            animationIndex: 0,
            normalizedTime: 1,
            blocksMovement: false,
          )
        : null,
  );
  final openWarps = SpatialWarpController(map: proposed, x: open.x, z: open.z);
  open.setInput(x: 0, z: -1);
  MapWarp? reached;
  for (var frame = 0; frame < 180 && reached == null; frame++) {
    open.update(1 / 60);
    reached = openWarps.update(
      x: open.x,
      z: open.z,
      facing: open.facing,
      bumpedCell: open.bumpedCell,
    );
  }
  require(
    reached?.id == 'home-door',
    'The opened door cannot reach the canonical home warp',
  );
  final arrival = SpatialMovementController.fromMap(
    map: proposed,
    models: models,
    arrival: const GridPos(x: 7, y: 7),
    modelStateProvider: (id) => id == instance.id
        ? SpatialModelRuntimeState(
            modelId: model.id,
            animationIndex: 0,
            normalizedTime: 1,
            blocksMovement: false,
          )
        : null,
  );
  final returnWarps = SpatialWarpController(
    map: proposed,
    x: arrival.x,
    z: arrival.z,
  );
  require(
    returnWarps.update(
          x: arrival.x,
          z: arrival.z,
          facing: EntityFacing.south,
        ) ==
        null,
    'The reciprocal arrival immediately enters the interior again',
  );
  arrival.setInput(x: 0, z: 1);
  for (var frame = 0; frame < 45; frame++) arrival.update(1 / 60);
  require(
    arrival.z > 8.5,
    'The opened reciprocal arrival cannot leave the entrance',
  );
  final cinematics = (definitions['cinematics'] as List)
      .map((value) => CinematicAsset.fromJson(value as Map<String, dynamic>))
      .toList();
  final scenes = (definitions['scenes'] as List)
      .map((value) => SceneAsset.fromJson(value as Map<String, dynamic>))
      .toList();
  final dialogues = (definitions['dialogues'] as List)
      .map(
        (value) => ProjectDialogueEntry(
          id: value['id'] as String,
          name: value['id'] as String,
          relativePath: 'dialogues/${value['id']}.yarn',
          defaultStartNode: 'Accueil',
        ),
      )
      .toList();
  final targetProject = project.copyWith(
    models3d: models,
    facts: [
      ...project.facts.where(
        (value) => value.id != (door['fact'] as Map)['id'],
      ),
      NarrativeFactDefinition.fromJson(door['fact'] as Map<String, dynamic>),
    ],
    dialogues: [
      ...project.dialogues.where(
        (value) => !dialogues.any((replacement) => replacement.id == value.id),
      ),
      ...dialogues,
    ],
    cinematics: [
      ...project.cinematics.where(
        (value) => !cinematics.any((replacement) => replacement.id == value.id),
      ),
      ...cinematics,
    ],
    scenes: [
      ...project.scenes.where(
        (value) => !scenes.any((replacement) => replacement.id == value.id),
      ),
      ...scenes,
    ],
  );
  final routeReceipts = <Map<String, Object?>>[];
  for (final asset in cinematics) {
    final inspected = const CinematicAuthoringInspector().inspect(
      project: targetProject,
      cinematic: asset,
    );
    require(
      inspected.canPublish,
      'Cinematic ${asset.id}: ${inspected.preflightIssues} / ${inspected.previewDiagnostics}',
    );
    final context = asset.stageContext!;
    final points = {for (final point in context.stagePoints) point.id: point};
    final returning = asset.id == 'valbois-guide-return-cinematic';
    var start = points[returning ? 'guide-door-side' : 'guide-start']!;
    final movement = SpatialMovementController.fromMap(
      map: proposed,
      models: models,
      spatialArrival: PlayerSpatialPosition(x: 14.5, z: 14.5),
    );
    for (final path in context.manualPaths) {
      for (final id in path.waypointStagePointIds) {
        final target = points[id]!;
        require(
          movement.canTraverseActor(
            start.x,
            start.y,
            target.x,
            target.y,
            ignoredEntityId: 'valbois-guide',
            collideWithPlayer: true,
            playerPosition: returning
                ? PlayerSpatialPosition(x: 8.5, z: 10.5)
                : PlayerSpatialPosition(x: 13.5, z: 12.5),
          ),
          'Cinematic ${asset.id} crosses a real collision ${start.id}→$id',
        );
        require(
          proposed.spatialScene!.worldHeightAt(target.x, target.y) == 0,
          'Guide route height changed',
        );
        routeReceipts.add({
          'cinematicId': asset.id,
          'from': [start.x, start.y],
          'to': [target.x, target.y],
        });
        start = target;
      }
    }
  }
  for (final asset in scenes) {
    final report = diagnoseSceneAgainstProject(
      asset,
      targetProject,
      mapsById: maps,
    );
    require(
      !report.hasErrors,
      'Scene ${asset.id}: ${report.diagnostics.map((value) => '${value.code.name}: ${value.message}').join('\n')}',
    );
    require(
      buildSceneRuntimePlan(asset).canBuild,
      'Scene ${asset.id} cannot build a runtime plan',
    );
  }
  stdout.writeln(
    jsonEncode({
      'verified': true,
      'closedStopZ': closed.z,
      'openedWarpZ': open.z,
      'returnExitZ': arrival.z,
      'scenes': scenes.length,
      'cinematics': cinematics.length,
      'routes': routeReceipts,
      'projectWrites': 0,
      'proof': 'Pure Dart physical movement, authoring preflight and typed Scene runtime plans',
    }),
  );
}
