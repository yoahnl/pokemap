import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

void main() {
  test('instance batch persists byte-identically through direct API and JSONL and undoes', () async {
    final results = <List<int>>[];
    for (final direct in [true, false]) {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      expect((await f.apply(await f.plan())).status, AuthoringResultStatus.success);
      await f.executeAction('map3d.instance.upsert', {'mapId': 'first-map',
        'instance': _batchInstance('keep').toJson()}, direct: direct);
      final file = File('${f.root.path}/maps/first-map.json');
      final beforeMap = await file.readAsBytes();
      final beforeProject = await f.projectFile.readAsBytes();
      final invalid = {'mapId': 'first-map', 'instances': [
        _batchInstance('valid').toJson(),
        {..._batchInstance('missing').toJson(), 'modelId': 'missing'},
      ]};
      if (direct) {
        await expectLater(f.executeAction('map3d.instance.upsert_batch', invalid,
          direct: true), throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'map3d.instance.model_not_found')));
      } else {
        final rejected = await f.planAction('map3d.instance.upsert_batch', invalid);
        expect(rejected.status, AuthoringResultStatus.failure);
        expect(rejected.error?.details['domainCode'], 'map3d.instance.model_not_found');
      }
      expect(await file.readAsBytes(), beforeMap);
      expect(await f.projectFile.readAsBytes(), beforeProject);
      await f.executeAction('map3d.instance.upsert_batch', {'mapId': 'first-map',
        'instances': [_batchInstance('keep', x: 1.5).toJson(),
          _batchInstance('new', x: 2.5).toJson()]}, direct: direct);
      final snapshot = await f.snapshots.load(f.project);
      final instances = snapshot.mapById('first-map')!.spatialScene!.instances;
      expect(instances, [_batchInstance('keep', x: 1.5), _batchInstance('new', x: 2.5)]);
      expect(await f.projectFile.readAsBytes(), beforeProject);
      results.add(await file.readAsBytes());
      final history = await f.request('history', {'projectHandle': f.project.value, 'limit': 1});
      final entry = (history.data['entries'] as List).single as Map;
      final undone = await f.request('undo', {'projectHandle': f.project.value,
        'entryId': entry['entryId'], 'idempotencyKey': 'undo-instance-batch'});
      expect(undone.status, AuthoringResultStatus.success, reason: undone.toJson().toString());
      expect(await file.readAsBytes(), beforeMap);
    }
    expect(results[0], results[1]);
  });

  test('instance batch is discoverable and persisted through canonical CLI', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect((await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final process = await Process.start('dart',
      ['run', 'bin/pokemap_authoring.dart', '--root', f.root.path]);
    final errors = process.stderr.transform(utf8.decoder).join();
    final lines = StreamIterator(process.stdout.transform(utf8.decoder)
      .transform(const LineSplitter()));
    var sequence = 0;
    Future<Map<String, Object?>> send(String command, Map<String, Object?> args) async {
      process.stdin.writeln(jsonEncode({'id': 'instance-cli-${sequence++}', 'command': command, 'args': args}));
      await process.stdin.flush();
      expect(await lines.moveNext().timeout(const Duration(seconds: 20)), isTrue);
      final result = AuthoringResult.fromJson(jsonDecode(lines.current) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success, reason: result.toJson().toString());
      return result.data;
    }
    try {
      final described = await send('describe', {});
      expect((described['mutationActions'] as List).where((action) => action['id'] == 'map3d.instance.upsert_batch'), hasLength(1));
      final opened = await send('open', {'projectRoot': f.root.path});
      final validation = await send('validate', {'projectHandle': opened['projectHandle']});
      final plan = await send('plan', {'projectHandle': opened['projectHandle'],
        'request': AuthoringRequest(requestId: 'instance-cli', actionId: 'map3d.instance.upsert_batch',
          actionVersion: 1, workspaceHandle: opened['workspaceHandle'] as String,
          expectedRevision: validation['snapshotRevision'] as String, idempotencyKey: 'instance-cli',
          parameters: {'mapId': 'first-map', 'instances': [_batchInstance('first').toJson(), _batchInstance('second', x: 2.5).toJson()]}).toJson()});
      await send('apply', {'projectHandle': opened['projectHandle'], 'planId': plan['planId'], 'operationId': 'instance-cli'});
      final snapshot = await f.snapshots.load(f.project);
      expect(snapshot.mapById('first-map')!.spatialScene!.instances.map((instance) => instance.id), ['first', 'second']);
      await send('close', {'workspaceHandle': opened['workspaceHandle']});
    } finally {
      await process.stdin.close();
      await lines.cancel();
      expect(await process.exitCode.timeout(const Duration(seconds: 20), onTimeout: () { process.kill(); return -1; }), 0, reason: await errors);
    }
  });

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
                animationIndex: 0,
                animationLoop: false,
                animationSpeed: .25,
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
      final animated = map.spatialScene!.instances.single;
      expect(animated.animationIndex, 0);
      expect(animated.animationLoop, isFalse);
      expect(animated.animationSpeed, .25);
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

  for (final direct in [false, true]) {
    test(
        'terrain physical height preserves anchors and undo through ${direct ? "direct API" : "JSONL"}',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      expect((await f.apply(await f.plan())).status,
          AuthoringResultStatus.success);
      final catalog = await f.request('describe');
      final actions = (catalog.data['mutationActions'] as List).where(
          (action) => action['id'] == 'map3d.terrain.configure_height');
      expect(actions, hasLength(1));
      final schema = actions.single['extensions']['inputSchema'] as Map;
      expect(schema['required'], ['mapId', 'levelHeight']);
      expect(schema['properties']['levelHeight'], {
        'type': 'number',
        'exclusiveMinimum': 0,
        'maximum': 16,
      });
      await f.executeAction('map3d.terrain.configure_appearance', {
        'mapId': 'first-map',
        'cliffFrame': {'atlasId': 'cliff', 'column': 0, 'row': 0},
      });
      await f.executeAction('map3d.terrain.set_levels', {
        'mapId': 'first-map',
        'cells': [
          {'x': 1, 'z': 2, 'level': 3},
          {'x': 2, 'z': 0, 'level': 2},
        ],
      });
      await f.executeAction('map3d.navigation.configure', {
        'mapId': 'first-map',
        'navigation': SpatialNavigationProfile(ramps: [
          SpatialRamp(
              id: 'stairs',
              x: 2,
              z: 1,
              width: 1,
              depth: 1,
              lowLevel: 0,
              highLevel: 2,
              direction: SpatialRampDirection.north),
        ]).toJson(),
      });
      final ground = SpatialModelInstance(
          id: 'ground',
          modelId: 'house',
          position: Model3dVector3(x: 1.2, y: 3.5, z: 2.7),
          rotationDegrees: 90,
          scale: 1.25,
          animationIndex: 0,
          animationLoop: false,
          animationSpeed: .5,
          blocksMovement: false);
      final ramp = SpatialModelInstance(
          id: 'ramp',
          modelId: 'house',
          position: Model3dVector3(x: 2.4, y: 1.75, z: 1.25));
      for (final instance in [ground, ramp]) {
        await f.executeAction('map3d.instance.upsert', {
          'mapId': 'first-map',
          'instance': instance.toJson(),
        });
      }
      final before = (await f.snapshots.load(f.project))
          .mapById('first-map')!;
      final file = File('${f.root.path}/maps/first-map.json');
      final originalBytes = await file.readAsBytes();
      final planned = await f.planAction('map3d.terrain.configure_height', {
        'mapId': 'first-map',
        'levelHeight': .5,
      });
      expect(planned.status, AuthoringResultStatus.success,
          reason: planned.toJson().toString());
      expect(await file.readAsBytes(), originalBytes);
      if (direct) {
        await f.executeAction('map3d.terrain.configure_height', {
          'mapId': 'first-map',
          'levelHeight': .5,
        }, direct: true);
      } else {
        expect((await f.apply(planned)).status,
            AuthoringResultStatus.success);
      }
      final after = (await f.snapshots.load(f.project))
          .mapById('first-map')!;
      final scene = after.spatialScene!;
      expect(scene.levelHeight, .5);
      expect(scene.heightAt(1, 2), 1.5);
      expect(scene.worldHeightAt(2.4, 1.25), .75);
      expect(scene.heightLevels, before.spatialScene!.heightLevels);
      expect(scene.navigation, before.spatialScene!.navigation);
      expect(scene.camera, before.spatialScene!.camera);
      expect(scene.cliffFrame, before.spatialScene!.cliffFrame);
      expect(scene.instances, [
        ground.copyWith(
            position: Model3dVector3(x: 1.2, y: 2, z: 2.7)),
        ramp.copyWith(
            position: Model3dVector3(x: 2.4, y: 1, z: 1.25)),
      ]);
      final query = await f.request('query', {
        'projectHandle': f.project.value,
        'request': AuthoringQueryRequest(
                resourceKind: 'map',
                operation: AuthoringQueryOperation.get,
                ids: ['first-map'],
                view: AuthoringQueryView.detail)
            .toJson(),
      });
      expect(query.status, AuthoringResultStatus.success);
      expect((query.data['items'] as List).single['spatialScene'],
          scene.toJson());
      final scaledBytes = await file.readAsBytes();
      final invalidRampContact = await f.planAction('map3d.terrain.set_levels', {
        'mapId': 'first-map',
        'cells': [
          {'x': 2, 'z': 0, 'level': 1},
        ],
      });
      expect(invalidRampContact.status, AuthoringResultStatus.failure);
      expect(invalidRampContact.error!.details['domainCode'],
          'map3d.parameters_invalid');
      expect(await file.readAsBytes(), scaledBytes);
      final history = await f.request(
          'history', {'projectHandle': f.project.value, 'limit': 1});
      final entry = (history.data['entries'] as List).single as Map;
      final undo = await f.request('undo', {
        'projectHandle': f.project.value,
        'entryId': entry['entryId'],
        'idempotencyKey': 'undo-height',
      });
      expect(undo.status, AuthoringResultStatus.success);
      expect((await f.snapshots.load(f.project)).mapById('first-map'), before);
    });
  }

  test('repeated terrain height configuration keeps fractional offsets intact',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect((await f.apply(await f.plan())).status,
        AuthoringResultStatus.success);
    await f.executeAction('map3d.terrain.set_levels', {
      'mapId': 'first-map',
      'cells': [
        {'x': 1, 'z': 1, 'level': 3},
      ],
    });
    await f.executeAction('map3d.terrain.configure_height', {
      'mapId': 'first-map',
      'levelHeight': .5,
    });
    await f.executeAction('map3d.instance.upsert', {
      'mapId': 'first-map',
      'instance': SpatialModelInstance(
              id: 'offset',
              modelId: 'house',
              position: Model3dVector3(x: 1.5, y: 1.502, z: 1.5))
          .toJson(),
    });
    final file = File('${f.root.path}/maps/first-map.json');
    final before = await file.readAsBytes();
    final repeated = await f.planAction('map3d.terrain.configure_height', {
      'mapId': 'first-map',
      'levelHeight': .5,
    });
    expect(repeated.status, AuthoringResultStatus.failure);
    expect(repeated.error!.details['domainCode'], 'map.no_change');
    expect(await file.readAsBytes(), before);
  });

  test('terrain height accepts the upper limit and rejects non-finite input',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await f.executeAction('map3d.terrain.configure_height', {
      'mapId': 'first-map',
      'levelHeight': 16,
    });
    expect((await f.snapshots.load(f.project))
        .mapById('first-map')!.spatialScene!.levelHeight, 16);
    final file = File('${f.root.path}/maps/first-map.json');
    final before = await file.readAsBytes();
    final snapshot = await f.snapshots.load(f.project);
    for (final value in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
          () => AuthoringRequest(
              requestId: 'non-finite',
              actionId: 'map3d.terrain.configure_height',
              actionVersion: 1,
              workspaceHandle: f.workspace.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'non-finite',
              parameters: {'mapId': 'first-map', 'levelHeight': value}),
          throwsArgumentError);
      expect(await file.readAsBytes(), before);
    }
  });

  test('terrain physical height persists through the real CLI', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final process = await Process.start('dart', [
      'bin/pokemap_authoring.dart',
      '--root',
      f.root.path,
    ]);
    final lines = StreamIterator<String>(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()));
    final errors = process.stderr.transform(utf8.decoder).join();
    addTearDown(() async {
      await process.stdin.close();
      await process.exitCode.timeout(const Duration(seconds: 5),
          onTimeout: () {
        process.kill();
        return process.exitCode;
      });
      await lines.cancel();
    });
    var sequence = 0;
    Future<AuthoringResult> send(String command,
        [Map<String, Object?> args = const {}]) async {
      process.stdin.writeln(jsonEncode({
        'id': 'height-cli-${sequence++}',
        'command': command,
        'args': args,
      }));
      await process.stdin.flush();
      expect(await lines.moveNext(), isTrue);
      final result = AuthoringResult.fromJson(
          jsonDecode(lines.current) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success,
          reason: result.toJson().toString());
      return result;
    }
    final described = await send('describe');
    expect(
        (described.data['mutationActions'] as List)
            .where((action) => action['id'] == 'map3d.terrain.configure_height'),
        hasLength(1));
    final opened = await send('open', {'projectRoot': f.root.path});
    final snapshot = await f.snapshots.load(f.project);
    final planned = await send('plan', {
      'projectHandle': opened.data['projectHandle'],
      'request': AuthoringRequest(
              requestId: 'height-cli',
              actionId: 'map3d.terrain.configure_height',
              actionVersion: 1,
              workspaceHandle: opened.data['workspaceHandle'] as String,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'height-cli',
              parameters: {'mapId': 'first-map', 'levelHeight': .5})
          .toJson(),
    });
    await send('apply', {
      'projectHandle': opened.data['projectHandle'],
      'planId': planned.data['planId'],
      'operationId': 'height-cli',
    });
    expect((await f.snapshots.load(f.project))
        .mapById('first-map')!.spatialScene!.levelHeight, .5);
    await send('close', {'workspaceHandle': opened.data['workspaceHandle']});
    await process.stdin.close();
    expect(await process.exitCode, 0);
    expect(await errors, isEmpty);
  });

  for (final direct in [false, true]) {
    for (final reference in ['scene', 'modelInteract']) {
      test(
          'referenced decor deletion is rejected without writes through ${direct ? "direct API" : "JSONL"} for $reference',
          () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        expect((await f.apply(await f.plan())).status,
            AuthoringResultStatus.success);
        expect(
            (await f.apply(await f.planAction('map3d.instance.upsert', {
              'mapId': 'first-map',
              'instance': SpatialModelInstance(
                      id: 'door',
                      modelId: 'house',
                      position: Model3dVector3.zero)
                  .toJson(),
            })))
                .status,
            AuthoringResultStatus.success);
        if (reference == 'scene') {
          final snapshot = await f.snapshots.load(f.project);
          final scene = _modelScene();
          final diagnostics = diagnoseSceneAgainstProject(
              scene, snapshot.manifest.copyWith(scenes: [scene]),
              mapsById: {for (final map in snapshot.maps) map.id: map});
          expect(diagnostics.hasErrors, isFalse,
              reason: diagnostics.diagnostics
                  .map((d) => '${d.code.name}: ${d.message}')
                  .join('\n'));
          final runtime = buildSceneRuntimePlan(scene);
          expect(runtime.canBuild, isTrue,
              reason: runtime.diagnostics.toString());
          final planned = await f.mutations.planMutation(
              f.project,
              AuthoringRequest(
                  requestId: 'scene-direct',
                  actionId: 'scene.upsert',
                  actionVersion: 1,
                  workspaceHandle: f.workspace.value,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'scene-direct',
                  parameters: {'scene': _modelScene().toJson()}));
          await f.mutations.applyMutation(f.project,
              planId: planned.planId, operationId: 'scene-direct');
        }
        final authored = reference == 'scene'
            ? null
            : await f.planAction('event_v2.create_draft', {
                'name': 'Open door',
                'rawUuid': '019a6190-0000-7000-8000-000000000001',
                'initialSource':
                    NarrativeEventSourceRef.modelInteract('first-map', 'door')
                        .toJson(),
              });
        if (authored != null) {
          expect(authored.status, AuthoringResultStatus.success,
              reason: authored.toJson().toString());
          expect(
              (await f.apply(authored)).status, AuthoringResultStatus.success);
        }
        final mapFile = File('${f.root.path}/maps/first-map.json');
        final mapBefore = await mapFile.readAsBytes();
        final projectBefore = await f.projectFile.readAsBytes();
        final parameters = {'mapId': 'first-map', 'instanceId': 'door'};
        if (direct) {
          final snapshot = await f.snapshots.load(f.project);
          await expectLater(
              f.mutations.planMutation(
                  f.project,
                  AuthoringRequest(
                      requestId: 'delete-direct',
                      actionId: 'map3d.instance.delete',
                      actionVersion: 1,
                      workspaceHandle: f.workspace.value,
                      expectedRevision: snapshot.revision,
                      idempotencyKey: 'delete-direct',
                      parameters: parameters)),
              throwsA(isA<MapAuthoringException>()
                  .having((e) => e.code, 'code', 'map3d.instance_referenced')));
        } else {
          final result =
              await f.planAction('map3d.instance.delete', parameters);
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.code, AuthoringErrorCode.validationFailed);
          expect(
              result.error!.details['domainCode'], 'map3d.instance_referenced');
          expect(result.error!.details['references'], isNotEmpty);
        }
        expect(await mapFile.readAsBytes(), mapBefore);
        expect(await f.projectFile.readAsBytes(), projectBefore);
      });
    }
  }

  test(
      'invalid edits, model references, dimension mixing and resize cannot publish',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final file = File('${f.root.path}/maps/first-map.json');
    final before = await file.readAsBytes();
    final cases = <(String, Map<String, Object?>)>[
      ('map3d.terrain.configure_height', {'mapId': 'first-map'}),
      for (final value in [null, false, '0.5', 0, -.5, 16.01])
        (
          'map3d.terrain.configure_height',
          {'mapId': 'first-map', 'levelHeight': value},
        ),
      (
        'map3d.terrain.configure_height',
        {'mapId': 'first-map', 'levelHeight': .5, 'extra': true},
      ),
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
              animationIndex: 9)
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
    for (final (action, parameters) in [
      (
        'map3d.terrain.set_levels',
        {
          'mapId': 'first-map',
          'cells': [
            {'x': 0, 'z': 0, 'level': 1},
          ],
        },
      ),
      (
        'map3d.terrain.configure_height',
        {'mapId': 'first-map', 'levelHeight': .5},
      ),
    ]) {
      final result = await f.planAction(action, parameters);
      expect(result.status, AuthoringResultStatus.failure);
      expect(await f.projectFile.readAsBytes(), before);
    }
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

SpatialModelInstance _batchInstance(String id, {num x = .5}) => SpatialModelInstance(
  id: id, modelId: 'house', position: Model3dVector3(x: x, y: 0, z: .5),
  animationIndex: 0, animationLoop: false, animationSpeed: .5, blocksMovement: false,
);

SceneAsset _modelScene() => SceneAsset(
    id: 'open',
    name: 'Open door',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'play',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.playModelAnimation(
                  mapId: 'first-map', instanceId: 'door', animationIndex: 0))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'begin',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'play',
          kind: SceneEdgeKind.defaultFlow),
      for (final port in ['completed', 'blocked', 'cancelled'])
        SceneEdge(
            id: port,
            fromNodeId: 'play',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow),
    ]));

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
    await File('${root.path}/input.glb').writeAsBytes(animatedGlb());
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

  Future<void> executeAction(String action, Map<String, Object?> parameters,
      {bool direct = false}) async {
    if (direct) {
      final snapshot = await snapshots.load(project);
      final planned = await mutations.planMutation(
          project,
          AuthoringRequest(
              requestId: 'direct-${sequence++}',
              actionId: action,
              actionVersion: 1,
              workspaceHandle: workspace.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'direct-${sequence++}',
              parameters: parameters));
      await mutations.applyMutation(project,
          planId: planned.planId, operationId: 'direct-${sequence++}');
    } else {
      final planned = await planAction(action, parameters);
      expect(planned.status, AuthoringResultStatus.success,
          reason: planned.toJson().toString());
      final applied = await apply(planned);
      expect(applied.status, AuthoringResultStatus.success,
          reason: applied.toJson().toString());
    }
  }

  Future<void> dispose() => root.parent.delete(recursive: true);
}
