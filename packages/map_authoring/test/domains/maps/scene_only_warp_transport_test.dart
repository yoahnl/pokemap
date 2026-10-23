import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

Map<String, Object?> _point({int x = 1}) => {
      'id': 'arrival',
      'pos': {'x': x, 'y': 1},
      'triggerMode': 'scene_only',
    };

void main() {
  test('warp descriptors expose the typed native door contract', () {
    for (final id in [
      'warp.create',
      'warp.update',
      'warp.create_reciprocal_apply',
      'warp.update_pair_apply'
    ]) {
      final descriptor =
          WarpConnectionActions.descriptors.singleWhere((d) => d.id == id);
      expect(descriptor.extensions['nativeDoor'], isA<Map>());
    }
  });

  for (final wire in [false, true]) {
    test(
        'native door survives ${wire ? 'JSONL' : 'API'} create, replace, pair and cold reopen',
        () async {
      final f = await _Fixture.create(spatial: true);
      addTearDown(f.dispose);
      final warp = const MapWarp(
        id: 'entrance',
        pos: GridPos(x: 1, y: 1),
        targetMapId: 'beta',
        targetPos: GridPos(x: 2, y: 1),
        door: MapWarpDoor(
            instanceId: 'door',
            openAnimationIndex: 0,
            closeAnimationIndex: 1,
            exitPos: GridPos(x: 1, y: 2)),
      );
      await f.mutate(
          'warp.create_reciprocal_apply',
          {
            'warp': warp.toJson(),
            'reciprocalWarpId': 'return',
          },
          wire);
      await f.reopen();
      var snapshot = await f.snapshots.load(f.project);
      expect(snapshot.mapById('alpha')!.warps.single.door, warp.door);
      expect(snapshot.mapById('beta')!.warps.single.door, isNull);
      await f.mutate(
          'map3d.instance.upsert',
          {
            'mapId': 'beta',
            'instance': SpatialModelInstance(
              id: 'target-door',
              modelId: 'door-model',
              position: Model3dVector3(x: 2, y: 0, z: 1),
              blocksMovement: false,
            ).toJson()
          },
          wire);
      const targetDoor = MapWarpDoor(
          instanceId: 'target-door',
          openAnimationIndex: 0,
          closeAnimationIndex: 1,
          exitPos: GridPos(x: 2, y: 2));
      await f.mutate(
          'warp.update',
          {
            'mapId': 'beta',
            'warpId': 'return',
            'warp': snapshot
                .mapById('beta')!
                .warps
                .single
                .copyWith(door: targetDoor)
                .toJson()
          },
          wire);
      final replacement = warp.copyWith(
          door: warp.door!.copyWith(exitPos: const GridPos(x: 0, y: 1)));
      await f.mutate(
          'warp.update_pair_apply',
          {
            'warpId': 'entrance',
            'warp': replacement.toJson(),
            'reciprocalWarpId': 'return',
          },
          wire);
      await f.reopen();
      snapshot = await f.snapshots.load(f.project);
      expect(snapshot.mapById('alpha')!.warps.single.door, replacement.door);
      expect(snapshot.mapById('beta')!.warps.single.door, targetDoor);
      for (final action in [
        'map3d.instance.delete',
        'map3d.instance.delete_batch'
      ]) {
        await f.reject(
            action,
            {
              if (action.endsWith('_batch'))
                'instanceIds': ['door']
              else
                'instanceId': 'door',
            },
            wire);
      }
      await f.reject(
          'map3d.instance.upsert',
          {
            'instance': SpatialModelInstance(
              id: 'door',
              modelId: 'door-model',
              position: Model3dVector3(x: 1, y: 0, z: 1),
              animationIndex: 0,
            ).toJson()
          },
          wire);
      await f.mutate(
          'warp.update',
          {
            'warpId': 'entrance',
            'warp': replacement.copyWith(door: null).toJson()
          },
          wire);
      expect(
          (await f.snapshots.load(f.project))
              .mapById('alpha')!
              .warps
              .single
              .door,
          isNull);
    });
  }
  test('warp actions discover conditional passive destination contracts', () {
    for (final id in ['warp.create', 'warp.update']) {
      final contract = WarpConnectionActions.descriptors
          .singleWhere((d) => d.id == id)
          .extensions['warpDestinationContract'] as Map?;
      expect(contract, isNotNull);
      expect(contract!['triggerModeValues'],
          ['on_enter', 'on_bump', 'scene_only']);
      expect(contract['activeRequiredFields'], ['targetMapId', 'targetPos']);
      expect(contract['sceneOnly'], {
        'automaticTraversal': false,
        'reciprocal': false,
        'targetMapId': 'owningMapId',
        'targetPos': 'pos',
        'explicitConflictingTarget': 'rejected',
      });
      expect(contract['sceneOnlyToActiveRequiresExplicitDestination'], true);
    }
  });

  test('a passive point contributes no automatic graph or reciprocal edge',
      () async {
    final f = await _Fixture.create(seeded: true);
    addTearDown(f.dispose);
    final snapshot = await f.snapshots.load(f.project);
    expect(const WorldGraphQueries().inspect(snapshot).edges, isEmpty);
    expect(const WarpConnectionActions().validateWarpPairs(snapshot.maps),
        isEmpty);
    expect(
        const WorldGraphQueries().listConnected(snapshot, fromMapId: 'alpha'),
        ['alpha']);
  });

  for (final wire in [false, true]) {
    final label = wire ? 'JSONL' : 'direct API';
    test('$label creates and moves an inert point then cold reopens it',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final manifestBefore = await f.manifest.readAsBytes();
      final betaBefore = await f.beta.readAsBytes();
      await f.mutate('warp.create', {'warp': _point()}, wire);
      await f.mutate(
          'warp.update', {'warpId': 'arrival', 'warp': _point(x: 2)}, wire);
      await f.reopen();
      final point =
          (await f.snapshots.load(f.project)).mapById('alpha')!.warps.single;
      expect(point.triggerMode, MapWarpTriggerMode.sceneOnly);
      expect(point.pos, const GridPos(x: 2, y: 1));
      expect(point.targetMapId, 'alpha');
      expect(point.targetPos, point.pos);
      expect(await f.beta.readAsBytes(), betaBefore);
      expect(await f.manifest.readAsBytes(), manifestBefore);
    });

    test(
        '$label changes modes with explicit active targets and canonical passive targets',
        () async {
      final f = await _Fixture.create(seeded: true);
      addTearDown(f.dispose);
      await f.reject(
          'warp.update',
          {
            'warpId': 'arrival',
            'warp': {
              ..._point(),
              'triggerMode': 'on_bump',
            }
          },
          wire);
      await f.mutate(
          'warp.update',
          {
            'warpId': 'arrival',
            'warp': {
              ..._point(),
              'triggerMode': 'on_bump',
              'targetMapId': 'beta',
              'targetPos': {'x': 2, 'y': 2},
            }
          },
          wire);
      expect(
          (await f.snapshots.load(f.project))
              .mapById('alpha')!
              .warps
              .single
              .targetMapId,
          'beta');
      await f.mutate(
          'warp.update', {'warpId': 'arrival', 'warp': _point()}, wire);
      final point =
          (await f.snapshots.load(f.project)).mapById('alpha')!.warps.single;
      expect(point.targetMapId, 'alpha');
      expect(point.targetPos, point.pos);
    });

    test('$label refuses malformed or incompatible points before writes',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      for (final warp in <Map<String, Object?>>[
        {..._point(), 'targetMapId': 'beta'},
        {
          ..._point(),
          'targetPos': {'x': 2, 'y': 1}
        },
        {..._point(), 'targetMapId': null},
        {..._point(), 'targetPos': null},
        {..._point(), 'triggerMode': 'sceneOnly'},
        {..._point(), 'sceneOnly': true},
        {..._point(), 'unknown': true},
        _point(x: 9),
        {..._point(), 'triggerMode': 'on_enter'},
        {..._point(), 'triggerMode': 'on_bump'},
      ]) {
        await f.reject('warp.create', {'warp': warp}, wire);
      }
    });

    test('$label cannot clone, update or delete a point as a reciprocal portal',
        () async {
      final f = await _Fixture.create(seeded: true);
      addTearDown(f.dispose);
      for (final (action, parameters) in <(String, Map<String, Object?>)>[
        (
          'warp.create_reciprocal_apply',
          {
            'warp': {..._point(), 'id': 'other'}
          }
        ),
        ('warp.update_pair_apply', {'warpId': 'arrival', 'warp': _point(x: 2)}),
        ('warp.delete_pair_apply', {'warpId': 'arrival'}),
      ]) {
        await f.reject(action, parameters, wire,
            code: 'warp.scene_only_not_reciprocal');
      }
    });
  }
}

final class _Fixture {
  _Fixture(this.directory, this.snapshots, this.mutations, this.worker);
  final Directory directory;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;
  File get manifest => File('${directory.path}/project.json');
  File get alpha => File('${directory.path}/maps/alpha.json');
  File get beta => File('${directory.path}/maps/beta.json');

  static Future<_Fixture> create(
      {bool seeded = false, bool spatial = false}) async {
    final directory = await Directory.systemTemp.createTemp('scene-only-api-');
    await Directory('${directory.path}/maps').create();
    final manifest = ProjectManifest(
        name: 'Native arrival',
        version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: ProjectSettings(
            dimension:
                spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
            spatialCamera: spatial ? SpatialCameraProfile() : null),
        tilesets: const [],
        maps: const [
          ProjectMapEntry(
              id: 'alpha', name: 'Alpha', relativePath: 'maps/alpha.json'),
          ProjectMapEntry(
              id: 'beta', name: 'Beta', relativePath: 'maps/beta.json'),
        ]);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    for (final id in ['alpha', 'beta']) {
      final map = MapData(
          id: id,
          name: id,
          version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
          spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
          size: const GridSize(width: 4, height: 4),
          warps: [
            if (seeded && id == 'alpha')
              const MapWarp(
                  id: 'arrival',
                  pos: GridPos(x: 1, y: 1),
                  targetMapId: 'alpha',
                  targetPos: GridPos(x: 1, y: 1),
                  triggerMode: MapWarpTriggerMode.sceneOnly),
          ]);
      await File('${directory.path}/maps/$id.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: LocalArtifactStore(
          allowedSourceRoots: [directory.path], maximumArtifactBytes: 1048576),
    );
    final f = _Fixture(directory, snapshots, mutations,
        JsonlWorker(api: api, mutations: mutations));
    await f.open();
    if (spatial) {
      final source = File('${directory.path}/door.glb');
      await source.writeAsBytes(animatedGlb(edit: (json) {
        final animations = json['animations'] as List;
        animations.add({...animations.single as Map, 'name': 'Close'});
      }));
      final staged =
          await f.command('stage_artifact', {'sourcePath': source.path});
      expect(staged.status, AuthoringResultStatus.success,
          reason: jsonEncode(staged.toJson()));
      await f.mutate(
          'model3d.import',
          {
            'artifactHandle': staged.data['artifactHandle'],
            'modelId': 'door-model',
            'name': 'Door'
          },
          false);
      await f.mutate(
          'map3d.instance.upsert',
          {
            'instance': SpatialModelInstance(
              id: 'door',
              modelId: 'door-model',
              position: Model3dVector3(x: 1, y: 0, z: 1),
              blocksMovement: false,
            ).toJson()
          },
          false);
    }
    return f;
  }

  Future<AuthoringResult> command(
          String name, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'wire-${++sequence}',
        'command': name,
        'args': args,
      }))) as Map<String, dynamic>);
  Future<void> open() async {
    final result = await command('open', {'projectRoot': directory.path});
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    workspace = WorkspaceHandle(result.data['workspaceHandle'] as String);
    project = ProjectHandle(result.data['projectHandle'] as String);
  }

  Future<void> reopen() async {
    await command('close', {'workspaceHandle': workspace.value});
    await open();
  }

  Future<AuthoringRequest> request(
      String action, Map<String, Object?> parameters) async {
    final id = 'arrival-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: {
          if (!action.startsWith('model3d.')) 'mapId': 'alpha',
          ...parameters
        });
  }

  Future<void> mutate(
      String action, Map<String, Object?> parameters, bool wire) async {
    final before = await alpha.readAsBytes();
    final input = await request(action, parameters);
    final Map<String, Object?> planned;
    if (wire) {
      final result = await command(
          'plan', {'projectHandle': project.value, 'request': input.toJson()});
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
      planned = result.data;
    } else {
      planned = await mutations.plan(project, input);
    }
    expect(await alpha.readAsBytes(), before);
    final operation = 'apply-${++sequence}';
    if (wire) {
      final result = await command('apply', {
        'projectHandle': project.value,
        'planId': planned['planId'],
        'operationId': operation
      });
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
    } else {
      await mutations.apply(project,
          planId: planned['planId'] as String, operationId: operation);
    }
  }

  Future<void> reject(String action, Map<String, Object?> parameters, bool wire,
      {String? code}) async {
    final before = [
      await manifest.readAsBytes(),
      await alpha.readAsBytes(),
      await beta.readAsBytes()
    ];
    final input = await request(action, parameters);
    if (wire) {
      final result = await command(
          'plan', {'projectHandle': project.value, 'request': input.toJson()});
      expect(result.status, AuthoringResultStatus.failure,
          reason: jsonEncode(result.toJson()));
      if (code != null) expect(result.error!.details['domainCode'], code);
    } else {
      await expectLater(
          mutations.plan(project, input),
          throwsA(code == null
              ? isA<MapAuthoringException>()
              : isA<MapAuthoringException>()
                  .having((e) => e.code, 'code', code)));
    }
    expect(await manifest.readAsBytes(), before[0]);
    expect(await alpha.readAsBytes(), before[1]);
    expect(await beta.readAsBytes(), before[2]);
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}
