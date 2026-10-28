import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../../support/glb_fixture.dart';

void main() {
  test(
      'navigation attachment preserves its owner pose through direct and JSONL while supported props follow',
      () async {
    for (final direct in [false, true]) {
      final host = await stairFixture(ProjectManifest(
          name: 'Attach authored stair',
          maps: [],
          tilesets: [],
          version: ProjectVersion.v9,
          settings: ProjectSettings(
              dimension: ProjectDimension.threeD,
              spatialCamera: SpatialCameraProfile())));
      addTearDown(host.dispose);
      final modelFile = File('${host.root.path}/stair.glb');
      await modelFile.writeAsBytes(triangleGlb());
      final staged =
          await host.command('stage_artifact', {'sourcePath': modelFile.path});
      await host.mutate('model3d.import', {
        'modelId': 'stairs',
        'name': 'Escalier complet',
        'artifactHandle': staged.data['artifactHandle']
      });
      final manifest = await host.read();
      final stair = SpatialModelInstance(
          id: 'stairs_a',
          modelId: 'stairs',
          position: Model3dVector3(x: 3.5, y: 1, z: 5),
          blocksMovement: false);
      final prop = SpatialModelInstance(
          id: 'supported_prop',
          modelId: 'stairs',
          position: Model3dVector3(x: 3.5, y: 1, z: 5),
          blocksMovement: false);
      final source = MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v9,
          size: const GridSize(width: 12, height: 12),
          spatialScene: MapSpatialScene(
              width: 12,
              depth: 12,
              heightLevels: List.filled(144, 1),
              instances: [stair, prop]));
      final file = File('${host.root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(source.toJson()));
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(manifest.copyWith(maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ]).toJson()));
      final navigation = SpatialNavigationProfile(ramps: [
        SpatialRamp(
            id: 'stair-surface',
            x: 3,
            z: 4,
            width: 1,
            depth: 2,
            lowLevel: 1,
            highLevel: 3,
            direction: SpatialRampDirection.north,
            surfaceInstanceId: stair.id),
      ]);
      MapData readMap() =>
          MapData.fromJson(jsonDecode(file.readAsStringSync()));
      Future<void> configure(
          SpatialNavigationProfile profile, String id) async {
        final parameters = {'mapId': 'map', 'navigation': profile.toJson()};
        if (direct) {
          final snapshot =
              await host.snapshots.load(ProjectHandle(host.project));
          final planned = await host.mutations.plan(
              ProjectHandle(host.project),
              AuthoringRequest(
                  requestId: id,
                  actionId: 'map3d.navigation.configure',
                  actionVersion: 1,
                  workspaceHandle: host.workspace,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: id,
                  parameters: parameters));
          await host.mutations.apply(ProjectHandle(host.project),
              planId: planned['planId'] as String, operationId: id);
        } else {
          await host.mutate('map3d.navigation.configure', parameters);
        }
      }

      await configure(navigation, 'attach');
      final attached = readMap();
      expect(attached.spatialScene!.instances.first, stair);
      expect(attached.spatialScene!.instances.last.position.y, 2);
      expect(attached.spatialScene!.navigation, navigation);
      final repeated = await host.plan('map3d.navigation.configure',
          {'mapId': 'map', 'navigation': navigation.toJson()});
      expect(repeated.status, AuthoringResultStatus.failure);
      expect(repeated.error!.details['domainCode'], 'map.no_change');
      expect(readMap(), attached);
      await configure(SpatialNavigationProfile(), 'remove');
      expect(readMap().spatialScene!.instances, [stair, prop]);
      expect(readMap().spatialScene!.navigation.ramps, isEmpty);
      final history =
          await host.mutations.history(ProjectHandle(host.project), limit: 1);
      await host.mutations.undo(ProjectHandle(host.project),
          entryId: (history['entries'] as List).single['entryId'] as String,
          idempotencyKey: 'undo-remove');
      expect(readMap(), attached);
      await host.command('close', {'projectHandle': host.project});
      final reopened =
          await host.command('open', {'projectRoot': host.root.path});
      final handle = ProjectHandle(reopened.data['projectHandle'] as String);
      expect((await host.snapshots.load(handle)).maps.single, attached);
      await host.command('close', {'projectHandle': handle.value});
    }
  });
  test(
      'stair profiles configure through JSONL then attach move delete undo and reopen',
      () async {
    final manifest = ProjectManifest(
        name: 'Attached stairs',
        maps: [],
        tilesets: [],
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()));
    final host = await stairFixture(manifest);
    addTearDown(host.dispose);
    final modelFile = File('${host.root.path}/stair.glb');
    await modelFile.writeAsBytes(triangleGlb());
    final staged =
        await host.command('stage_artifact', {'sourcePath': modelFile.path});
    await host.mutate('model3d.import', {
      'modelId': 'stairs',
      'name': 'Escalier',
      'artifactHandle': staged.data['artifactHandle']
    });
    final configured = await host.plan('model3d.configure', {
      'modelId': 'stairs',
      'rampProfile': {
        'x': -.5,
        'z': -2,
        'width': 1,
        'depth': 2,
        'lowHeight': 0,
        'highHeight': 1,
        'direction': 'north',
      }
    });
    expect(configured.status, AuthoringResultStatus.success,
        reason: configured.toJson().toString());
    expect(
        (await host.apply(configured)).status, AuthoringResultStatus.success);
    final project = await host.read();
    final source = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 12, height: 12),
        spatialScene: MapSpatialScene(width: 12, depth: 12, levelHeight: .25));
    final file = File('${host.root.path}/maps/map.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(source.toJson()));
    await File('${host.root.path}/project.json')
        .writeAsString(jsonEncode(project.copyWith(maps: [
      const ProjectMapEntry(
          id: 'map', name: 'Map', relativePath: 'maps/map.json'),
    ]).toJson()));
    var instance = SpatialModelInstance(
        id: 'stairs_a',
        modelId: 'stairs',
        position: Model3dVector3(x: 3.5, y: 0, z: 5));
    await host.mutate('map3d.instance.upsert',
        {'mapId': 'map', 'instance': instance.toJson()});
    MapData readMap() => MapData.fromJson(jsonDecode(file.readAsStringSync()));
    expect(readMap().spatialScene!.navigation.ramps.single.surfaceInstanceId,
        instance.id);
    expect(readMap().spatialScene!.instances.single.blocksMovement, isFalse);
    final snapshot = await host.snapshots.load(ProjectHandle(host.project));
    instance = instance.copyWith(
        position: Model3dVector3(x: 6, y: .5, z: 7), rotationDegrees: 90);
    final direct = await host.mutations.plan(
        ProjectHandle(host.project),
        AuthoringRequest(
          requestId: 'move',
          actionId: 'map3d.instance.upsert',
          actionVersion: 1,
          workspaceHandle: host.workspace,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'move',
          parameters: {'mapId': 'map', 'instance': instance.toJson()},
        ));
    await host.mutations.apply(ProjectHandle(host.project),
        planId: direct['planId'] as String, operationId: 'move');
    final moved = readMap();
    final ramp = moved.spatialScene!.navigation.ramps.single;
    expect((
      ramp.x,
      ramp.z,
      ramp.width,
      ramp.depth,
      ramp.direction,
      ramp.lowLevel,
      ramp.highLevel
    ), (
      4,
      6.5,
      2,
      1,
      SpatialRampDirection.west,
      2,
      6
    ));
    await host.mutate('model3d.configure', {
      'modelId': 'stairs',
      'rampProfile': {
        ...project.models3d.single.rampProfile!.toJson(),
        'highHeight': 2
      }
    });
    expect(readMap().spatialScene!.navigation.ramps.single.highLevel, 10);
    final configuredHistory =
        await host.mutations.history(ProjectHandle(host.project), limit: 1);
    await host.mutations.undo(ProjectHandle(host.project),
        entryId:
            (configuredHistory['entries'] as List).single['entryId'] as String,
        idempotencyKey: 'undo-profile');
    expect(readMap(), moved);
    expect((await host.read()).models3d.single.rampProfile!.highHeight, 1);
    await host.mutate(
        'map3d.terrain.configure_height', {'mapId': 'map', 'levelHeight': .5});
    expect(readMap().spatialScene!.navigation.ramps.single.highLevel, 3);
    expect(readMap().spatialScene!.navigation.ramps.single.lowLevel, 1);
    await host.mutate(
        'map3d.terrain.configure_height', {'mapId': 'map', 'levelHeight': .25});
    expect(readMap(), moved);
    final detached = moved.spatialScene!.navigation.copyWith(ramps: const []);
    final detachPlan = await host.plan('map3d.navigation.configure',
        {'mapId': 'map', 'navigation': detached.toJson()});
    expect(detachPlan.status, AuthoringResultStatus.failure);
    await host.mutate(
        'map3d.instance.delete', {'mapId': 'map', 'instanceId': instance.id});
    expect(readMap().spatialScene!.navigation.ramps, isEmpty);
    final history =
        await host.mutations.history(ProjectHandle(host.project), limit: 1);
    await host.mutations.undo(ProjectHandle(host.project),
        entryId: (history['entries'] as List).single['entryId'] as String,
        idempotencyKey: 'undo-delete');
    expect(readMap(), moved);
    await host.command('close', {'projectHandle': host.project});
    final opened = await host.command('open', {'projectRoot': host.root.path});
    final handle = ProjectHandle(opened.data['projectHandle'] as String);
    final reopened = await host.snapshots.load(handle);
    expect(reopened.maps.single, moved);
    expect(reopened.manifest.models3d.single.rampProfile!.direction,
        SpatialRampDirection.north);
    await host.command('close', {'projectHandle': handle.value});
  });
}

Future<ResourceInformationFixture> stairFixture(
    ProjectManifest manifest) async {
  final root = await Directory.systemTemp.createTemp('stair-attachment-');
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: LocalArtifactStore(
          allowedSourceRoots: [root.path], maximumArtifactBytes: 1048576));
  final worker = JsonlWorker(
      api: AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots),
      mutations: mutations);
  final opened =
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
    'id': 'open',
    'command': 'open',
    'args': {'projectRoot': root.path},
  }))));
  expect(opened.status, AuthoringResultStatus.success);
  return ResourceInformationFixture(
      root,
      snapshots,
      worker,
      opened.data['projectHandle'] as String,
      opened.data['workspaceHandle'] as String,
      mutations);
}
