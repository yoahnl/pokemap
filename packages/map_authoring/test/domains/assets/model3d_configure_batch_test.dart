import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/glb_fixture.dart';

void main() {
  test('released catalogue plans replay their key under another operation id',
      () async {
    final f = await _Fixture.create(snapshotCache: ProjectSnapshotCache());
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final planned = await f.mutations.planMutation(
        f.project,
        f.authoringRequest({
          'models': [
            {'modelId': 'model-0', 'name': 'Replay-safe model'}
          ]
        }, expectedRevision: before.revision));
    final applied = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'catalogue-first-operation');
    expect(planned.plan.appliedPayloadReleased, isTrue);
    final projectBytes = await f.projectFile.readAsBytes();
    final replay = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'catalogue-second-operation');
    expect(replay.receipt.receiptId, applied.receipt.receiptId);
    expect(replay.snapshotRevision, applied.snapshotRevision);
    expect(await f.projectFile.readAsBytes(), projectBytes);
    expect(
        (await f.snapshot()).manifest.models3d.first.name, 'Replay-safe model');
    expect(
        (await f.mutations.listMutationHistory(f.project, limit: 10)).entries,
        hasLength(1));
  });

  test('catalogue publication skips map projection and matches a cold snapshot',
      () async {
    final cache = ProjectSnapshotCache();
    final f = await _Fixture.create(ramps: true, snapshotCache: cache);
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final rejections = cache.adoptionRejections;
    final planned = await f.mutations.planMutation(
        f.project,
        f.authoringRequest({
          'models': [
            {'modelId': 'model-0', 'name': 'Updated stairs', 'scale': 2}
          ]
        }, expectedRevision: before.revision));
    final applied = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'catalogue-cold-parity');
    expect(cache.adoptions, 0);
    expect(cache.adoptionRejections, rejections);
    final after = await f.snapshot();
    final query = AuthoringQueryRequest(
        resourceKind: 'model3d',
        operation: AuthoringQueryOperation.get,
        ids: ['model-0'],
        view: AuthoringQueryView.detail);
    final queried = await f.request(
        'query', {'projectHandle': f.project.value, 'request': query.toJson()});
    expect(queried.status, AuthoringResultStatus.success);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [f.root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(f.root.path);
    addTearDown(() => opener.closeWorkspace(opened.workspaceHandle));
    final cold = await ProjectSnapshotLoader(handles: handles)
        .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
    expect(applied.snapshotRevision, cold.revision);
    expect(after.revision, cold.revision);
    expect(after.manifest, cold.manifest);
    expect(after.maps, cold.maps);
    expect(after.resourceFingerprints, cold.resourceFingerprints);
    expect(queried.data['items'],
        const ProjectQueryService().query(cold, query).toJson()['items']);
    expect(cold.manifest.models3d.first.name, 'Updated stairs');
    expect(cold.maps.single.spatialScene!.instances,
        before.maps.single.spatialScene!.instances);
    expect(
        cold.maps.single.spatialScene!.navigation.ramps
            .singleWhere((ramp) => ramp.surfaceInstanceId == 'placed-0')
            .width,
        2);
  });

  test('discovers bounded recoverable model configuration batches', () {
    final descriptor = Model3dActions.descriptors
        .singleWhere((action) => action.id == 'model3d.configure_batch');
    expect(descriptor.guarantees, isNot(contains(AuthoringGuarantee.atomic)));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.revisionChecked));
    expect(descriptor.requiredPermissions, [AuthoringPermission.projectWrite]);
    expect(descriptor.resourceKinds, contains('map'));
    expect(descriptor.extensions['maximumModelCount'], 50);
    expect(descriptor.extensions['publicationSemantics'],
        'recoverable_cross_file');
    final schema = descriptor.extensions['inputSchema'] as Map;
    final models = (schema['properties'] as Map)['models'] as Map;
    expect(models['minItems'], 1);
    expect(models['maxItems'], 50);
    final item = models['items'] as Map;
    expect(item['required'], ['modelId']);
    expect(item['additionalProperties'], false);
    final single = Model3dActions.descriptors
        .singleWhere((action) => action.id == 'model3d.configure');
    expect(item['properties'],
        (single.extensions['inputSchema'] as Map)['properties']);
  });

  test('publishes fifty configurations with one manifest and bounded diffs',
      () async {
    final f = await _Fixture.create(count: 50);
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final planned = await f.mutations.planMutation(
        f.project,
        f.authoringRequest({
          'models': [
            for (final model in before.manifest.models3d)
              {'modelId': model.id, 'blocksMovementByDefault': false}
          ]
        }, expectedRevision: before.revision));
    expect(planned.plan.changeSet.changes.map((c) => c.storageKey),
        ['project.json']);
    expect(planned.plan.changeSet.diff.entries, hasLength(50));
    expect(
        utf8.encode(jsonEncode(planned.toJson())).length, lessThan(256 * 1024));
    expect(await f.projectFile.readAsBytes(), before.resourceBytes('project'));
    final applied = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'configure-fifty');
    final replay = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'configure-fifty');
    expect(replay.receipt.receiptId, applied.receipt.receiptId);
    final after = await f.snapshot();
    expect(
        after.manifest.models3d.every((m) => !m.blocksMovementByDefault), true);
    expect(after.manifest.models3d.map((m) => m.inspection),
        before.manifest.models3d.map((m) => m.inspection));
    expect(await f.assetFile.readAsBytes(), f.assetBefore);
  });

  test(
      'batch agrees with single configuration including omission and explicit clears',
      () async {
    final f = await _Fixture.create(ramps: true);
    addTearDown(f.dispose);
    final snapshot = await f.snapshot();
    final inputs = [
      {
        'modelId': 'model-0',
        'name': 'Renamed',
        'scale': 2,
        'pivot': {'x': 0.25, 'y': 0, 'z': -0.25},
        'collisionBounds': {
          'min': {'x': 0, 'y': 0, 'z': 0},
          'max': {'x': 1, 'y': 2, 'z': 1}
        },
        'blocksMovementByDefault': false
      },
      {'modelId': 'model-1', 'collisionBounds': null, 'rampProfile': null},
    ];
    final batch = await f.build(snapshot, {'models': inputs});
    final batchManifest = batch.projectedProject!;
    for (final input in inputs) {
      final single =
          await f.build(snapshot, input, action: 'model3d.configure');
      expect(
          batchManifest.models3d.singleWhere((m) => m.id == input['modelId']),
          single.projectedProject!.models3d
              .singleWhere((m) => m.id == input['modelId']));
    }
    expect(batchManifest.models3d.first.rampProfile,
        snapshot.manifest.models3d.first.rampProfile);
    expect(batchManifest.models3d.last.rampProfile, isNull);
    expect(batchManifest.models3d.last.collisionBounds, isNull);
  });

  test(
      'aggregates two attached ramp changes into one map and supports undo reopen',
      () async {
    final f = await _Fixture.create(ramps: true);
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final beforeMap = before.maps.single;
    expect(beforeMap.spatialScene!.navigation.ramps, hasLength(2));
    final plan = await f.mutations.planMutation(
        f.project,
        f.authoringRequest({
          'models': [
            {'modelId': 'model-0', 'scale': 2},
            {'modelId': 'model-1', 'rampProfile': null}
          ]
        }, expectedRevision: before.revision));
    expect(plan.plan.changeSet.changes.map((c) => c.storageKey).toSet(),
        {'project.json', 'maps/room.json'});
    expect(plan.plan.changeSet.changes, hasLength(2));
    await f.mutations.applyMutation(f.project,
        planId: plan.planId, operationId: 'two-ramp-configurations');
    final after = await f.snapshot();
    final scene = after.maps.single.spatialScene!;
    expect(scene.instances, beforeMap.spatialScene!.instances);
    expect(scene.navigation.ramps, hasLength(1));
    expect(scene.navigation.ramps.single.surfaceInstanceId, 'placed-0');
    expect(scene.navigation.ramps.single.highLevel, 1);
    expect(scene.navigation.ramps.single.width, 2);
    final reopened = await f.request('open', {'projectRoot': f.root.path});
    expect(reopened.status, AuthoringResultStatus.success,
        reason: jsonEncode(reopened.toJson()));
    final history = await f
        .request('history', {'projectHandle': f.project.value, 'limit': 10});
    final entry = (history.data['entries'] as List).cast<Map>().single;
    final undo = await f.request('undo', {
      'projectHandle': f.project.value,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-configurations'
    });
    expect(undo.status, AuthoringResultStatus.success,
        reason: jsonEncode(undo.toJson()));
    final restored = await f.snapshot();
    expect(restored.manifest.models3d, before.manifest.models3d);
    expect(restored.maps.single, beforeMap);
  });

  test(
      'default blocking only changes future placements and mixed noops are omitted',
      () async {
    final f = await _Fixture.create(ramps: true);
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final mapBytes = await f.mapFile.readAsBytes();
    final plan = await f.mutations.planMutation(
        f.project,
        f.authoringRequest({
          'models': [
            {'modelId': 'model-0', 'blocksMovementByDefault': false},
            {'modelId': 'model-1'}
          ]
        }, expectedRevision: before.revision));
    expect(
        plan.plan.changeSet.changes.map((c) => c.storageKey), ['project.json']);
    expect(plan.plan.changeSet.diff.entries, hasLength(1));
    await f.mutations.applyMutation(f.project,
        planId: plan.planId, operationId: 'default-only');
    expect(await f.mapFile.readAsBytes(), mapBytes);
    final noop = await f.plan({
      'models': [
        {'modelId': 'model-0', 'blocksMovementByDefault': false},
        {'modelId': 'model-1', 'blocksMovementByDefault': true}
      ]
    });
    expect(noop.status, AuthoringResultStatus.success);
    expect(noop.data['applicable'], false);
    expect((noop.data['plan'] as Map)['nonApplicableReason'], 'no_changes');
  });

  test('updates two ramps and preserves an unrelated ramp in one map write',
      () async {
    final f = await _Fixture.create(count: 3, ramps: true);
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final draft = await f.build(before, {
      'models': [
        {'modelId': 'model-0', 'scale': 2},
        {'modelId': 'model-1', 'scale': 3}
      ]
    });
    final change =
        draft.changeSet.changes.singleWhere((c) => c.resource.kind == 'map');
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>);
    final ramps = {
      for (final r in map.spatialScene!.navigation.ramps) r.surfaceInstanceId: r
    };
    expect(ramps, hasLength(3));
    expect(ramps['placed-0']!.highLevel, 1);
    expect(ramps['placed-1']!.highLevel, 1.5);
    expect(
        ramps['placed-2'],
        before.maps.single.spatialScene!.navigation.ramps
            .singleWhere((r) => r.surfaceInstanceId == 'placed-2'));
    expect(map.spatialScene!.instances,
        before.maps.single.spatialScene!.instances);
  });

  test('large inspections keep complete postimages and bounded JSONL diffs',
      () async {
    final f = await _Fixture.create(largeInspection: true);
    addTearDown(f.dispose);
    final before = await f.snapshot();
    final planned = await f.plan({
      'models': [
        {'modelId': 'model-0', 'name': 'Large configured'}
      ]
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final wire = jsonEncode(planned.toJson());
    expect(utf8.encode(wire).length, lessThan(64 * 1024));
    expect(wire, isNot(contains('Material 499')));
    final diff = AuthoringDiff.fromJson(
        ((planned.data['plan'] as Map)['changeSet'] as Map)['diff']);
    final summary = (diff.entries.single.after as Map)['modelSummary'] as Map;
    expect((summary['inspection'] as Map)['materialCount'], 500);
    final applied = await f.request('apply', {
      'projectHandle': f.project.value,
      'planId': planned.data['planId'],
      'operationId': 'large-configuration'
    });
    expect(applied.status, AuthoringResultStatus.success);
    final after = await f.snapshot();
    expect(after.manifest.models3d.first.inspection,
        before.manifest.models3d.first.inspection);
    expect(after.manifest.models3d.last, before.manifest.models3d.last);
  });

  test('interrupted manifest and ramp publication recovers the complete batch',
      () async {
    final f = await _Fixture.create(ramps: true, failAfterPromotion: true);
    addTearDown(f.dispose);
    final planned = await f.plan({
      'models': [
        {'modelId': 'model-0', 'scale': 2},
        {'modelId': 'model-1', 'rampProfile': null}
      ]
    });
    final applied = await f.request('apply', {
      'projectHandle': f.project.value,
      'planId': planned.data['planId'],
      'operationId': 'recover-configurations'
    });
    expect(applied.status, AuthoringResultStatus.failure);
    final recovered = await f.request('recover', {
      'projectHandle': f.project.value,
      'operationId': 'recover-configurations'
    });
    expect(recovered.status, AuthoringResultStatus.success,
        reason: jsonEncode(recovered.toJson()));
    final after = await f.snapshot();
    expect(after.manifest.models3d.first.scale, 2);
    expect(after.manifest.models3d.last.rampProfile, isNull);
    expect(
        after.maps.single.spatialScene!.navigation.ramps.single.highLevel, 1);
    expect(await f.assetFile.readAsBytes(), f.assetBefore);
  });

  final invalid = <String, Object?>{
    'empty': [],
    'too many': [
      for (var i = 0; i < 51; i++) {'modelId': 'model-$i'}
    ],
    'duplicate': [
      {'modelId': 'model-0'},
      {'modelId': 'model-0'}
    ],
    'unknown': [
      {'modelId': 'model-0', 'scale': 2},
      {'modelId': 'missing'}
    ],
    'trailing nonobject': [
      {'modelId': 'model-0', 'scale': 2},
      'oops'
    ],
    'unknown field': [
      {'modelId': 'model-0', 'inspection': {}}
    ],
    'invalid id': [
      {'modelId': '../model'}
    ],
    'scale': [
      {'modelId': 'model-0', 'scale': 2},
      {'modelId': 'model-1', 'scale': 0}
    ],
    'null boolean': [
      {'modelId': 'model-0', 'blocksMovementByDefault': null}
    ],
    'string boolean': [
      {'modelId': 'model-0', 'blocksMovementByDefault': 'false'}
    ],
    'null pivot': [
      {'modelId': 'model-0', 'pivot': null}
    ],
    'string scale': [
      {'modelId': 'model-0', 'scale': '2'}
    ],
    'invalid bounds': [
      {
        'modelId': 'model-0',
        'collisionBounds': {
          'min': {'x': 0, 'y': 0, 'z': 0},
          'max': {'x': 0, 'y': 1, 'z': 1}
        }
      }
    ],
    'invalid ramp': [
      {
        'modelId': 'model-0',
        'rampProfile': {'x': 0}
      }
    ],
  };
  for (final entry in invalid.entries) {
    test('JSONL rejects ${entry.key} before any write or history', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.projectFile.readAsBytes();
      final result = await f.plan({'models': entry.value});
      expect(result.status, AuthoringResultStatus.failure,
          reason: jsonEncode(result.toJson()));
      expect(await f.projectFile.readAsBytes(), before);
      expect(await f.assetFile.readAsBytes(), f.assetBefore);
      expect(
          (await f.mutations.listMutationHistory(f.project, limit: 10)).entries,
          isEmpty);
    });
  }

  test('JSONL applies one configuration and rejects stale revisions', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final stale = await f.snapshot();
    final plan = await f.plan({
      'models': [
        {'modelId': 'model-0', 'name': 'Configured through JSONL'}
      ]
    });
    final result = await f.request('apply', {
      'projectHandle': f.project.value,
      'planId': plan.data['planId'],
      'operationId': 'jsonl-configure'
    });
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    expect((await f.snapshot()).manifest.models3d.first.name,
        'Configured through JSONL');
    await expectLater(
        f.mutations.planMutation(
            f.project,
            f.authoringRequest({
              'models': [
                {'modelId': 'model-1', 'scale': 2}
              ]
            }, expectedRevision: stale.revision)),
        throwsA(isA<AuthoringPlanException>()));
  });
}

final class _Fixture {
  _Fixture(this.root, this.snapshots, this.worker, this.project, this.workspace,
      this.mutations, this.assetBefore);

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final LocalMapAuthoringMutationApi mutations;
  final List<int> assetBefore;
  int sequence = 0;
  File get projectFile => File('${root.path}/project.json');
  File get assetFile => File('${root.path}/$assetCatalogStorageKey');
  File get mapFile => File('${root.path}/maps/room.json');
  Future<ProjectSnapshot> snapshot() => snapshots.load(project);

  static Future<_Fixture> create(
      {int count = 2,
      bool ramps = false,
      bool largeInspection = false,
      bool failAfterPromotion = false,
      ProjectSnapshotCache? snapshotCache}) async {
    final root =
        await Directory.systemTemp.createTemp('model3d-configure-batch-');
    final bytes = triangleGlb(
        edit: largeInspection
            ? (doc) {
                doc['materials'] = [
                  for (var i = 0; i < 500; i++)
                    {'name': 'Material $i ${'x' * 240}'}
                ];
                doc['meshes'][0]['primitives'][0]['material'] = 0;
              }
            : null);
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final models = [
      for (var i = 0; i < count; i++)
        ProjectModel3dEntry(
            id: 'model-$i',
            name: 'Model $i',
            sourceAssetId: 'model3d_model-$i',
            relativePath: 'assets/models3d/model-$i.glb',
            inspection: const GlbModel3dInspector().inspect(bytes),
            rampProfile: ramps
                ? Model3dRampProfile(
                    x: 0,
                    z: 0,
                    width: 1,
                    depth: 1,
                    lowHeight: 0,
                    highHeight: 0.5,
                    direction: SpatialRampDirection.east)
                : null)
    ];
    var map = MapData(
        id: 'room',
        name: 'Room',
        version: ProjectVersion.v9,
        size: const GridSize(width: 12, height: 12),
        layers: [],
        spatialScene: MapSpatialScene(width: 12, depth: 12));
    if (ramps) {
      map = const SpatialMapOperations().upsertInstances(
          map,
          [
            for (var i = 0; i < count; i++)
              SpatialModelInstance(
                  id: 'placed-$i',
                  modelId: 'model-$i',
                  position: Model3dVector3(x: 1 + i * 3, y: 0, z: 2),
                  blocksMovement: i == 0)
          ],
          models: models);
      final file = File('${root.path}/maps/room.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map.toJson()));
    }
    final manifest = ProjectManifest(
        name: 'Configure batches',
        version: ProjectVersion.v9,
        maps: ramps
            ? [
                const ProjectMapEntry(
                    id: 'room', name: 'Room', relativePath: 'maps/room.json')
              ]
            : [],
        tilesets: [],
        models3d: models,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    for (final model in models) {
      final file = File('${root.path}/${model.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }
    final catalog = File('${root.path}/$assetCatalogStorageKey');
    await catalog.writeAsString(jsonEncode(AssetCatalog(records: [
      for (final model in models)
        AssetRecord(
            id: model.sourceAssetId,
            logicalPath: model.relativePath,
            artifact: artifact)
    ]).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots =
        ProjectSnapshotLoader(handles: handles, snapshotCache: snapshotCache);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final api =
        AuthoringReadApi(openService: opener, snapshotLoader: snapshots);
    var failed = false;
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        faultInjector: failAfterPromotion
            ? (context) {
                if (!failed &&
                    context.checkpoint ==
                        AuthoringTransactionCheckpoint.afterResourcePromoted) {
                  failed = true;
                  throw const FileSystemException(
                      'Injected configuration publication failure');
                }
              }
            : null);
    final opened = await opener.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        root,
        snapshots,
        JsonlWorker(api: api, mutations: mutations),
        opened.projectHandle,
        opened.workspaceHandle,
        mutations,
        await catalog.readAsBytes());
  }

  AuthoringRequest authoringRequest(Map<String, Object?> parameters,
          {String action = 'model3d.configure_batch',
          String? expectedRevision}) =>
      AuthoringRequest(
          requestId: 'configure-${sequence++}',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: workspace.value,
          expectedRevision: expectedRevision,
          idempotencyKey: 'configure-${sequence++}',
          parameters: parameters);

  Future<AuthoringMutationDraft> build(
          ProjectSnapshot snapshot, Map<String, Object?> parameters,
          {String action = 'model3d.configure_batch'}) =>
      const Model3dActions().build(AuthoringPlanningContext(
          snapshot: snapshot,
          request: authoringRequest(parameters, action: action),
          planId: 'build',
          seed: 1));

  Future<AuthoringResult> request(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'request-${sequence++}',
        'command': command,
        'args': args
      }))) as Map<String, dynamic>);

  Future<AuthoringResult> plan(Map<String, Object?> parameters) async {
    final current = await snapshot();
    return request('plan', {
      'projectHandle': project.value,
      'request':
          authoringRequest(parameters, expectedRevision: current.revision)
              .toJson()
    });
  }

  Future<void> dispose() => root.delete(recursive: true);
}
