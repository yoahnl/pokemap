import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../../support/glb_fixture.dart';

void main() {
  test(
      'ramp model surfaces share direct and JSONL validation save reopen clear and undo',
      () async {
    for (final direct in [false, true]) {
      var manifest = ProjectManifest(
        name: 'Escalier',
        maps: const [],
        tilesets: const [],
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
      );
      final host = await _surfaceFixture(manifest);
      addTearDown(host.dispose);
      final modelFile = File('${host.root.path}/stair.glb');
      await modelFile.writeAsBytes(triangleGlb());
      final staged =
          await host.command('stage_artifact', {'sourcePath': modelFile.path});
      expect(staged.status, AuthoringResultStatus.success);
      await host.mutate('model3d.import', {
        'modelId': 'stair-model',
        'name': 'Escalier',
        'artifactHandle': staged.data['artifactHandle']
      });
      manifest = await host.read();
      final original = _sourceMap();
      final source = original.copyWith(
          spatialScene: original.spatialScene!.copyWith(instances: [
        SpatialModelInstance(
            id: 'stairs',
            modelId: 'stair-model',
            position: Model3dVector3(x: 57.5, y: .75, z: 14),
            blocksMovement: false),
      ]));
      final file = File('${host.root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(source.toJson()));
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(manifest.copyWith(maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Escalier', relativePath: 'maps/map.json'),
      ]).toJson()));
      final before = await file.readAsBytes();
      final navigation = source.spatialScene!.navigation.toJson();
      (navigation['ramps'] as List).single['surfaceInstanceId'] = 'stairs';
      final parameters = <String, Object?>{
        'mapId': 'map',
        'navigation': navigation
      };
      if (direct) {
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final plan = await host.mutations.plan(
            ProjectHandle(host.project),
            AuthoringRequest(
              requestId: 'surface',
              actionId: 'map3d.navigation.configure',
              actionVersion: 1,
              workspaceHandle: host.workspace,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'surface',
              parameters: parameters,
            ));
        expect(await file.readAsBytes(), before);
        await host.mutations.apply(ProjectHandle(host.project),
            planId: plan['planId'] as String, operationId: 'surface');
      } else {
        final plan = await host.plan('map3d.navigation.configure', parameters);
        expect(plan.status, AuthoringResultStatus.success,
            reason: plan.toJson().toString());
        expect(await file.readAsBytes(), before);
        expect((await host.apply(plan)).status, AuthoringResultStatus.success);
      }
      final stored = MapData.fromJson(jsonDecode(await file.readAsString()));
      expect(
          stored.spatialScene!.navigation.ramps.single
              .toJson()['surfaceInstanceId'],
          'stairs');
      expect(stored.spatialScene!.instances, source.spatialScene!.instances);
      final invalid =
          jsonDecode(jsonEncode(navigation)) as Map<String, dynamic>;
      (invalid['ramps'] as List).single['surfaceInstanceId'] = 'missing';
      final invalidPlan = await host.plan('map3d.navigation.configure',
          {'mapId': 'map', 'navigation': invalid});
      expect(invalidPlan.status, AuthoringResultStatus.failure);
      expect(
          invalidPlan.error!.details['domainCode'], 'map3d.parameters_invalid');
      final deletePlan = await host.plan(
          'map3d.instance.delete', {'mapId': 'map', 'instanceId': 'stairs'});
      expect(deletePlan.status, AuthoringResultStatus.success);
      final linkedBytes = await file.readAsBytes();
      final cleared = stored.spatialScene!.navigation.toJson();
      (cleared['ramps'] as List).single['surfaceInstanceId'] = null;
      final clearPlan = await host.plan('map3d.navigation.configure',
          {'mapId': 'map', 'navigation': cleared});
      expect(clearPlan.status, AuthoringResultStatus.success,
          reason: clearPlan.toJson().toString());
      expect(
          (await host.apply(clearPlan)).status, AuthoringResultStatus.success);
      expect(MapData.fromJson(jsonDecode(await file.readAsString())), source);
      final history =
          await host.mutations.history(ProjectHandle(host.project), limit: 1);
      await host.mutations.undo(ProjectHandle(host.project),
          entryId: (history['entries'] as List).single['entryId'] as String,
          idempotencyKey: 'undo-clear');
      expect(await file.readAsBytes(), linkedBytes);
      await host.command('close', {'projectHandle': host.project});
      final opened =
          await host.command('open', {'projectRoot': host.root.path});
      expect(opened.status, AuthoringResultStatus.success);
      final reopened = await host.snapshots
          .load(ProjectHandle(opened.data['projectHandle'] as String));
      expect(reopened.maps.single, stored);
      await host
          .command('close', {'projectHandle': opened.data['projectHandle']});
    }
    final action = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere((d) => d.id == 'map3d.navigation.configure');
    final properties = action.extensions['inputSchema'] as Map;
    final rampProperties = ((((properties['properties'] as Map)['navigation']
        as Map)['properties'] as Map)['ramps'] as Map)['items'] as Map;
    expect(
        (rampProperties['properties'] as Map).containsKey('surfaceInstanceId'),
        isTrue);
  });

  test(
      'precise existing ramp editing uses the same direct and JSONL contract with query reopen and undo',
      () async {
    final results = <List<int>>[];
    for (final direct in [true, false]) {
      final manifest = ProjectManifest(
          name: 'Pente précise',
          maps: const [],
          tilesets: const [],
          version: ProjectVersion.v9,
          settings: const ProjectSettings(dimension: ProjectDimension.threeD));
      final host = await ResourceInformationFixture.create(manifest);
      addTearDown(host.dispose);
      final source = _sourceMap();
      final file = File('${host.root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(source.toJson()));
      final projectFile = File('${host.root.path}/project.json');
      await projectFile.writeAsString(jsonEncode(manifest.copyWith(maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Pente précise', relativePath: 'maps/map.json'),
      ]).toJson()));
      final before = await file.readAsBytes();
      final projectBefore = await projectFile.readAsBytes();
      final oldRamp = source.spatialScene!.navigation.ramps.single;
      final navigation = source.spatialScene!.navigation.copyWith(ramps: [
        oldRamp.copyWith(x: oldRamp.x + .125, width: oldRamp.width - .125),
      ]);
      final parameters = <String, Object?>{
        'mapId': 'map',
        'navigation': navigation.toJson()
      };
      final expected =
          const SpatialMapOperations().configureNavigation(source, navigation);
      if (direct) {
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final plan = await host.mutations.plan(
            ProjectHandle(host.project),
            AuthoringRequest(
              requestId: 'precise-direct',
              actionId: 'map3d.navigation.configure',
              actionVersion: 1,
              workspaceHandle: host.workspace,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'precise-direct',
              parameters: parameters,
            ));
        expect(await file.readAsBytes(), before);
        await host.mutations.apply(ProjectHandle(host.project),
            planId: plan['planId']! as String, operationId: 'precise-direct');
      } else {
        final plan = await host.plan('map3d.navigation.configure', parameters);
        expect(plan.status, AuthoringResultStatus.success,
            reason: plan.toJson().toString());
        expect(await file.readAsBytes(), before);
        final applied = await host.apply(plan);
        expect(applied.status, AuthoringResultStatus.success,
            reason: applied.toJson().toString());
      }
      final stored = MapData.fromJson(jsonDecode(await file.readAsString()));
      expect(stored, expected);
      expect(stored.spatialScene!.navigation.ramps.single.x, 55.123046875);
      expect(stored.spatialScene!.navigation.ramps.single.width, 4.876953125);
      expect(stored.warps, source.warps);
      expect(await projectFile.readAsBytes(), projectBefore);
      results.add(await file.readAsBytes());
      final invalid = navigation
          .copyWith(ramps: [navigation.ramps.single.copyWith(lowLevel: 0)]);
      final invalidPlan = await host.plan('map3d.navigation.configure',
          {'mapId': 'map', 'navigation': invalid.toJson()});
      expect(invalidPlan.status, AuthoringResultStatus.failure);
      expect(
          invalidPlan.error!.details['domainCode'], 'map3d.parameters_invalid');
      expect(await file.readAsBytes(), results.last);
      await host.command('close', {'projectHandle': host.project});
      final reopened =
          await host.command('open', {'projectRoot': host.root.path});
      expect(reopened.status, AuthoringResultStatus.success);
      final handle = ProjectHandle(reopened.data['projectHandle']! as String);
      expect((await host.snapshots.load(handle)).maps.single, expected);
      final queried = await host.command('query', {
        'projectHandle': handle.value,
        'request': AuthoringQueryRequest(
                resourceKind: 'map',
                operation: AuthoringQueryOperation.get,
                ids: ['map'],
                view: AuthoringQueryView.detail)
            .toJson(),
      });
      expect(queried.status, AuthoringResultStatus.success);
      final data =
          Map<String, dynamic>.from((queried.data['items'] as List).single);
      data.remove('resourceKind');
      expect(MapData.fromJson(data), expected);
      final history = await host.mutations.history(handle, limit: 1);
      await host.mutations.undo(handle,
          entryId: (history['entries'] as List).single['entryId'] as String,
          idempotencyKey: 'undo-precise-ramp');
      expect(await file.readAsBytes(), before);
      await host.command('close', {'projectHandle': handle.value});
    }
    expect(results[0], results[1]);
    final descriptor = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere(
            (descriptor) => descriptor.id == 'map3d.navigation.configure');
    expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
  });
}

Future<ResourceInformationFixture> _surfaceFixture(
    ProjectManifest manifest) async {
  final root = await Directory.systemTemp.createTemp('ramp-surface-authoring-');
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final mutations = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: snapshots,
    artifactStore: LocalArtifactStore(
        allowedSourceRoots: [root.path], maximumArtifactBytes: 1048576),
  );
  final worker = JsonlWorker(
      api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
      mutations: mutations);
  final opened =
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
    'id': 'open',
    'command': 'open',
    'args': {'projectRoot': root.path}
  }))));
  expect(opened.status, AuthoringResultStatus.success,
      reason: opened.toJson().toString());
  return ResourceInformationFixture(
      root,
      snapshots,
      worker,
      opened.data['projectHandle'] as String,
      opened.data['workspaceHandle'] as String,
      mutations);
}

MapData _sourceMap() {
  final ramp = SpatialRamp(
      id: 'stair',
      x: 54.998046875,
      z: 13.125,
      width: 5.001953125,
      depth: 1.75,
      lowLevel: 3,
      highLevel: 23,
      direction: SpatialRampDirection.east);
  return MapData(
    id: 'map',
    name: 'Pente précise',
    version: ProjectVersion.v9,
    size: const GridSize(width: 64, height: 24),
    warps: const [
      MapWarp(
          id: 'keep',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'map',
          targetPos: GridPos(x: 2, y: 2))
    ],
    spatialScene: MapSpatialScene(
        width: 64,
        depth: 24,
        levelHeight: .25,
        heightLevels:
            List.generate(64 * 24, (index) => index % 64 >= 60 ? 23 : 3),
        navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 1.5, z: 1.5),
            allowDiagonalMovement: true,
            ramps: [
              ramp
            ],
            blockedAreas: [
              SpatialBlockedArea(x: 2, z: 4, width: 1, depth: 1)
            ])),
  );
}
