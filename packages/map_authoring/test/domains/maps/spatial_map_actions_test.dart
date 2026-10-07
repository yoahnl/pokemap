import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

void main() {
  for (final direct in [false, true]) {
    test(
        'spatial actions persist and query with ${direct ? "direct API" : "JSONL"}',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      expect((await f.apply(await f.plan())).status,
          AuthoringResultStatus.success);
      final described = jsonEncode((await f.request('describe')).toJson());
      Future<void> execute(String action, Map<String, Object?> values) async {
        expect(described.contains(action), isTrue);
        final parameters = {'mapId': 'first-map', ...values};
        if (direct) {
          final snapshot = await f.snapshots.load(f.project);
          final plan = await f.mutations.planMutation(
              f.project,
              AuthoringRequest(
                  requestId: 'direct-${f.sequence++}',
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: f.workspace.value,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'direct-${f.sequence++}',
                  parameters: parameters));
          await f.mutations.applyMutation(f.project,
              planId: plan.planId, operationId: 'direct-${f.sequence++}');
        } else {
          final plan = await f.planAction(action, parameters);
          expect(plan.status, AuthoringResultStatus.success,
              reason: plan.toJson().toString());
          final applied = await f.apply(plan);
          expect(applied.status, AuthoringResultStatus.success,
              reason: applied.toJson().toString());
        }
      }

      await execute('map3d.terrain.configure_appearance', {
        'cliffFrame': {
          'atlasId': 'cliff',
          'column': 0,
          'row': 0,
        }
      });
      expect(
          (await f.snapshots.load(f.project))
              .mapById('first-map')!
              .spatialScene!
              .cliffFrame,
          const SmartTileFrameRef(atlasId: 'cliff', column: 0, row: 0));
      await execute('map3d.terrain.configure_appearance', {'cliffFrame': null});
      await execute('map3d.terrain.set_levels', {
        'cells': [
          {'x': 1, 'z': 2, 'level': 3}
        ]
      });
      await execute('map3d.instance.upsert', {
        'instance': SpatialModelInstance(
                id: 'placed',
                modelId: 'house',
                position: Model3dVector3(x: 1.2, y: 3, z: 2.7))
            .toJson()
      });
      await execute('map3d.camera.configure',
          {'camera': SpatialCameraProfile(distance: 60).toJson()});
      await execute('map3d.terrain.set_levels', {
        'cells': [
          {'x': 2, 'z': 0, 'level': 1}
        ]
      });
      await execute('map3d.navigation.configure', {
        'navigation': SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 2, z: 3),
            allowDiagonalMovement: true,
            ramps: [
              SpatialRamp(
                  id: 'stairs',
                  x: 2,
                  z: 1,
                  width: 1,
                  depth: 1,
                  lowLevel: 0,
                  highLevel: 1,
                  direction: SpatialRampDirection.north)
            ]).toJson()
      });
      await execute('map.create', {'mapId': 'second', 'width': 4, 'height': 4});
      await execute('entity.create', {
        'entity': const MapEntity(
                id: 'start',
                kind: MapEntityKind.spawn,
                pos: GridPos(x: 2, y: 3),
                blocksMovement: false,
                spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart))
            .toJson()
      });
      await execute('map.apply_operations', {
        'operations': [
          {
            'kind': 'layer.add',
            'layerKind': 'collision',
            'layerId': 'solid',
            'name': 'Collisions'
          }
        ]
      });
      await execute('collision_layer.paint',
          {'layerId': 'solid', 'x': 0, 'y': 0, 'width': 2, 'height': 1});
      await execute('warp.create_reciprocal_apply', {
        'warp': const MapWarp(
                id: 'out',
                pos: GridPos(x: 3, y: 3),
                targetMapId: 'second',
                targetPos: GridPos(x: 1, y: 1))
            .toJson(),
        'reciprocalWarpId': 'back'
      });
      await execute('connection.create_bidirectional_apply', {
        'direction': 'east',
        'targetMapId': 'second',
        'offset': 1,
      });
      final snapshot = await f.snapshots.load(f.project);
      final map = snapshot.mapById('first-map')!;
      expect(map.version, ProjectVersion.v9);
      expect(map.entities.single.id, 'start');
      expect(map.layers.whereType<CollisionLayer>().single.collisions.take(2),
          [true, true]);
      expect(map.warps.single.targetMapId, 'second');
      expect(snapshot.mapById('second')!.warps.single.targetMapId, 'first-map');
      expect(
          map.connections.single,
          const MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: 'second',
              offset: 1));
      expect(
          snapshot.mapById('second')!.connections.single,
          const MapConnection(
              direction: MapConnectionDirection.west,
              targetMapId: 'first-map',
              offset: -1));
      expect(map.spatialScene!.heightAt(1, 2), 3);
      expect(map.spatialScene!.instances.single.id, 'placed');
      expect(map.spatialScene!.instances.single.position,
          Model3dVector3(x: 1.2, y: 3, z: 2.7));
      expect(map.spatialScene!.camera.distance, 60);
      expect(map.spatialScene!.navigation.spawn, SpatialSpawn(x: 2, z: 3));
      expect(map.spatialScene!.navigation.allowDiagonalMovement, isTrue);
      final queried = await f.request('query', {
        'projectHandle': f.project.value,
        'request': AuthoringQueryRequest(
                resourceKind: 'map',
                operation: AuthoringQueryOperation.get,
                ids: ['first-map'],
                view: AuthoringQueryView.detail)
            .toJson()
      });
      expect(queried.status, AuthoringResultStatus.success);
      expect((queried.data['items'] as List).single['spatialScene'],
          map.spatialScene!.toJson());
      expect((queried.data['items'] as List).single['connections'],
          map.connections.map((connection) => connection.toJson()).toList());
      await execute(
          'connection.delete_bidirectional_apply', {'direction': 'east'});
      final disconnected = await f.snapshots.load(f.project);
      expect(disconnected.mapById('first-map')!.connections, isEmpty);
      expect(disconnected.mapById('second')!.connections, isEmpty);
      await execute('map3d.instance.delete', {'instanceId': 'placed'});
      expect(
          (await f.snapshots.load(f.project))
              .mapById('first-map')!
              .spatialScene!
              .instances,
          isEmpty);
    });
  }

  test(
      'invalid edits, model references, dimension mixing and resize cannot publish',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final file = File('${f.root.path}/maps/first-map.json');
    final before = await file.readAsBytes();
    final cases = <(String, Map<String, Object?>)>[
      ('map3d.terrain.configure_appearance', {'mapId': 'first-map'}),
      (
        'map3d.terrain.configure_appearance',
        {
          'mapId': 'first-map',
          'cliffFrame': {'atlasId': 'missing', 'column': 0, 'row': 0}
        }
      ),
      (
        'map3d.terrain.configure_appearance',
        {
          'mapId': 'first-map',
          'cliffFrame': {
            'atlasId': 'cliff',
            'column': 0,
            'row': 0,
            'columnSpan': 3
          }
        }
      ),
      (
        'map3d.terrain.configure_appearance',
        {
          'mapId': 'first-map',
          'cliffFrame': {
            'atlasId': 'cliff',
            'column': 0,
            'row': 0,
            'extra': true
          }
        }
      ),
      (
        'map3d.terrain.set_levels',
        {
          'mapId': 'first-map',
          'cells': [
            {'x': 4, 'z': 0, 'level': 1}
          ]
        }
      ),
      (
        'map3d.terrain.set_levels',
        {
          'mapId': 'first-map',
          'cells': [
            {'x': 0, 'z': 0, 'level': 33}
          ]
        }
      ),
      (
        'map3d.instance.upsert',
        {
          'mapId': 'first-map',
          'instance': SpatialModelInstance(
                  id: 'bad', modelId: 'missing', position: Model3dVector3.zero)
              .toJson()
        }
      ),
      (
        'map3d.camera.configure',
        {
          'mapId': 'first-map',
          'camera': {...SpatialCameraProfile().toJson(), 'distance': 0}
        }
      ),
      (
        'map3d.instance.delete',
        {'mapId': 'first-map', 'instanceId': 'missing'}
      ),
      ('map.resize_apply', {'mapId': 'first-map', 'width': 3, 'height': 3}),
      (
        'map.save',
        {
          'map': MapData(
                  id: 'first-map',
                  name: '2D',
                  size: const GridSize(width: 4, height: 4))
              .toJson()
        }
      ),
    ];
    for (final (action, parameters) in cases) {
      final result = await f.planAction(action, parameters);
      expect(result.status, AuthoringResultStatus.failure, reason: action);
      expect(await file.readAsBytes(), before);
    }
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final invalidAnimation = await f.planAction('map3d.instance.upsert', {
      'mapId': 'first-map',
      'instance': SpatialModelInstance(
              id: 'bad',
              modelId: 'house',
              position: Model3dVector3.zero,
              animationIndex: 0)
          .toJson()
    });
    expect(invalidAnimation.status, AuthoringResultStatus.failure);
  });

  test('cliff references block shrinking their atlas before publication',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final configured =
        await f.apply(await f.planAction('map3d.terrain.configure_appearance', {
      'mapId': 'first-map',
      'cliffFrame': {'atlasId': 'cliff', 'column': 1, 'row': 0}
    }));
    expect(configured.status, AuthoringResultStatus.success);
    final before = await f.projectFile.readAsBytes();
    final rejected = await f.planAction('smart_tile.atlas.upsert', {
      'atlas': const ProjectSmartTileAtlas(
              id: 'cliff',
              name: 'Cliff',
              tilesetId: 'rock',
              cellWidth: 1,
              cellHeight: 1,
              columns: 1,
              rows: 1)
          .toJson()
    });
    expect(rejected.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    final map = (await f.snapshots.load(f.project)).mapById('first-map')!;
    expect(map.spatialScene!.cliffFrame!.column, 1);
  });

  test(
      'snapshot reopening rejects missing model references and dimension mixing',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final map = (await f.snapshots.load(f.project)).mapById('first-map')!;
    final file = File('${f.root.path}/maps/first-map.json');
    await file.writeAsString(jsonEncode(map
        .copyWith(
            spatialScene: map.spatialScene!.copyWith(instances: [
          SpatialModelInstance(
              id: 'missing', modelId: 'missing', position: Model3dVector3.zero)
        ]))
        .toJson()));
    await expectLater(
        f.snapshots.load(f.project),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.spatial_map_invalid')));
    await file.writeAsString(jsonEncode(
        map.copyWith(version: ProjectVersion.v8, spatialScene: null).toJson()));
    await expectLater(
        f.snapshots.load(f.project),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.map_dimension_mismatch')));
  });

  test('spatial actions refuse a valid 2D project', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.snapshots.load(f.project);
    final manifest = snapshot.manifest.copyWith(
        version: ProjectVersion.v8, settings: const ProjectSettings());
    final map = snapshot.maps.single
        .copyWith(version: ProjectVersion.v8, spatialScene: null);
    await f.projectFile.writeAsString(jsonEncode(manifest.toJson()));
    await File('${f.root.path}/maps/first-map.json')
        .writeAsString(jsonEncode(map.toJson()));
    final before = await f.projectFile.readAsBytes();
    final result = await f.planAction('map3d.terrain.set_levels', {
      'mapId': 'first-map',
      'cells': [
        {'x': 0, 'z': 0, 'level': 1}
      ]
    });
    expect(result.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
  });

  test('map.create inherits 3D dimension and project camera', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final result = await f.apply(await f.planAction(
        'map.create', {'mapId': 'second', 'width': 6, 'height': 5}));
    expect(result.status, AuthoringResultStatus.success,
        reason: result.toJson().toString());
    final snapshot = await f.snapshots.load(f.project);
    final map = snapshot.mapById('second')!;
    expect(map.version, ProjectVersion.v9);
    expect(map.layers, isEmpty);
    expect(map.spatialScene!.heightLevels, hasLength(30));
    expect(map.spatialScene!.camera, snapshot.manifest.settings.spatialCamera);
  });

  test('spatial transaction undo restores the complete scene', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = (await f.snapshots.load(f.project)).mapById('first-map');
    final result =
        await f.apply(await f.planAction('map3d.terrain.set_levels', {
      'mapId': 'first-map',
      'cells': [
        {'x': 0, 'z': 0, 'level': 4}
      ]
    }));
    expect(result.status, AuthoringResultStatus.success);
    final history = await f
        .request('history', {'projectHandle': f.project.value, 'limit': 10});
    final entry = (history.data['entries'] as List).first as Map;
    final applied = await f.request('undo', {
      'projectHandle': f.project.value,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-spatial'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    expect((await f.snapshots.load(f.project)).mapById('first-map'), before);
  });
}

final class _Fixture {
  _Fixture(this.root, this.snapshots, this.worker, this.project, this.workspace,
      this.mutations);

  final LocalMapAuthoringMutationApi mutations;
  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  int sequence = 0;
  String? lastOperation;

  File get projectFile => File('${root.path}/project.json');

  static Future<_Fixture> create({bool failAfterPromotion = false}) async {
    final parent = await Directory.systemTemp.createTemp('spatial-actions-');
    final receipt = await const LocalProjectCreationService().create(
        ProjectCreationRequest(
            name: '3D',
            folderName: 'game',
            parentPath: parent.path,
            template: ProjectCreationTemplate.empty,
            dimension: ProjectDimension.threeD,
            mapWidth: 4,
            mapHeight: 4));
    final root = Directory(receipt.projectPath);
    await File('${root.path}/input.glb').writeAsBytes(triangleGlb());
    final projectFile = File('${root.path}/project.json');
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>);
    await Directory('${root.path}/assets').create(recursive: true);
    await File('${root.path}/assets/cliff.png').writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAYAAAD0In+KAAAAC0lEQVR4nGP4DwUAI+UH+Yo0eLMAAAAASUVORK5CYII='));
    await projectFile.writeAsString(jsonEncode(manifest.copyWith(
      tilesets: const [
        ProjectTilesetEntry(
            id: 'rock', name: 'Rock', relativePath: 'assets/cliff.png')
      ],
      smartTileCatalog: ProjectSmartTileCatalog(atlases: const [
        ProjectSmartTileAtlas(
            id: 'cliff',
            name: 'Cliff',
            tilesetId: 'rock',
            cellWidth: 1,
            cellHeight: 1,
            columns: 2,
            rows: 1)
      ]),
    ).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final readApi =
        AuthoringReadApi(openService: opener, snapshotLoader: snapshots);
    final artifacts = LocalArtifactStore(
        allowedSourceRoots: [root.path], maximumArtifactBytes: 1048576);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
      faultInjector: failAfterPromotion
          ? (context) {
              if (context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
                throw const FileSystemException('Injected write failure');
              }
            }
          : null,
    );
    final opened = await opener.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        root,
        snapshots,
        JsonlWorker(api: readApi, mutations: mutations),
        opened.projectHandle,
        opened.workspaceHandle,
        mutations);
  }

  Future<AuthoringResult> request(String command,
      [Map<String, Object?> args = const {}]) async {
    final response = await worker.processLine(jsonEncode({
      'id': 'request-${sequence++}',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>);
  }

  Future<AuthoringResult> plan() async {
    final staged = await request(
        'stage_artifact', {'sourcePath': '${root.path}/input.glb'});
    expect(staged.status, AuthoringResultStatus.success);
    return planAction('model3d.import', {
      'artifactHandle': staged.data['artifactHandle'],
      'modelId': 'house',
      'name': 'Maison',
    });
  }

  Future<AuthoringResult> planAction(
      String action, Map<String, Object?> parameters) async {
    final snapshot = await snapshots.load(project);
    return request('plan', {
      'projectHandle': project.value,
      'request': AuthoringRequest(
        requestId: 'plan-${sequence++}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'operation-${sequence++}',
      ).toJson(),
    });
  }

  Future<AuthoringResult> apply(AuthoringResult plan,
      {bool confirm = false}) async {
    String? token;
    if (confirm) {
      final confirmation = await request('confirm',
          {'projectHandle': project.value, 'planId': plan.data['planId']});
      token = confirmation.data['confirmationToken'] as String?;
    }
    lastOperation = 'apply-${sequence++}';
    return request('apply', {
      'projectHandle': project.value,
      'planId': plan.data['planId'],
      'operationId': lastOperation,
      if (token != null) 'confirmationToken': token,
    });
  }

  Future<void> dispose() => root.parent.delete(recursive: true);
}
