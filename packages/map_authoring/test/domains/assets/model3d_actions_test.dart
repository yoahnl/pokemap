import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

void main() {
  test('source replacement exposes a revision checked recoverable contract',
      () {
    final descriptor = Model3dActions.descriptors
        .singleWhere((action) => action.id == 'model3d.source.replace');
    expect(descriptor.requiredPermissions,
        contains(AuthoringPermission.importRun));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.idempotent));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.revisionChecked));
    expect(descriptor.guarantees, isNot(contains(AuthoringGuarantee.atomic)));
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(schema['required'], ['modelId', 'artifactHandle']);
    expect((schema['properties'] as Map).keys,
        unorderedEquals(['modelId', 'artifactHandle']));
  });

  test('JSONL source replacement preserves configured model and placed map',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    expect(
        (await f.apply(await f.planAction('model3d.configure', {
          'modelId': 'house',
          'name': 'Configured house',
          'scale': 2.5,
          'pivot': {'x': 1, 'y': 2, 'z': -3}
        })))
            .status,
        AuthoringResultStatus.success);
    final mapFile = await f.addPlacement();
    final beforeMap = await mapFile.readAsBytes();
    final before = (await f.snapshots.load(f.project)).manifest.models3d.single;
    final plan = await f.planReplacement(animatedGlb());
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
    expect((await f.apply(plan)).status, AuthoringResultStatus.success);
    final after = (await f.snapshots.load(f.project)).manifest.models3d.single;
    expect(after.id, before.id);
    expect(after.name, before.name);
    expect(after.scale, before.scale);
    expect(after.pivot, before.pivot);
    expect(after.relativePath, before.relativePath);
    expect(after.sourceAssetId, before.sourceAssetId);
    expect(after.inspection.animations.single.name, 'Wind');
    expect(await mapFile.readAsBytes(), beforeMap);
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        animatedGlb());
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('source replacement undo restores bytes and inspection together',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final before = (await f.snapshots.load(f.project)).manifest.models3d.single;
    expect((await f.apply(await f.planReplacement(animatedGlb()))).status,
        AuthoringResultStatus.success);
    final history = await f
        .request('history', {'projectHandle': f.project.value, 'limit': 10});
    final entry = (history.data['entries'] as List).cast<Map>().firstWhere(
        (e) => (e['receipt'] as Map)['actionId'] == 'model3d.source.replace');
    final undone = await f.request('undo', {
      'projectHandle': f.project.value,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-model-source-replace'
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: jsonEncode(undone.toJson()));
    expect(
        (await f.snapshots.load(f.project)).manifest.models3d.single, before);
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
  });

  test('source replacement refuses removing a placed animation', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await File('${f.root.path}/input.glb').writeAsBytes(animatedGlb());
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final map = await f.addPlacement(animationIndex: 0);
    final before = await f.projectFile.readAsBytes();
    final beforeMap = await map.readAsBytes();
    final plan = await f.planReplacement(triangleGlb());
    expect(plan.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    expect(await map.readAsBytes(), beforeMap);
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        animatedGlb());
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('source replacement rejects invalid bytes and unknown models', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final before = await f.projectFile.readAsBytes();
    expect((await f.planReplacement([0, 1, 2])).status,
        AuthoringResultStatus.failure);
    expect((await f.planReplacement(animatedGlb(), modelId: 'unknown')).status,
        AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('source replacement refuses a stale revision without changing bytes',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final plan = await f.planReplacement(animatedGlb());
    final manifest = (await f.snapshots.load(f.project))
        .manifest
        .copyWith(name: 'Concurrent edit');
    await f.projectFile.writeAsString(jsonEncode(manifest.toJson()));
    expect((await f.apply(plan)).status, AuthoringResultStatus.failure);
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
  });

  test(
      'direct source replacement replays the same receipt and skips identical bytes',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    await File('${f.root.path}/replacement.glb').writeAsBytes(animatedGlb());
    final staged = await f.mutations
        .stageArtifactFile(sourcePath: '${f.root.path}/replacement.glb');
    final snapshot = await f.snapshots.load(f.project);
    final plan = await f.mutations.planMutation(
        f.project,
        AuthoringRequest(
            requestId: 'direct-replace',
            actionId: 'model3d.source.replace',
            actionVersion: 1,
            workspaceHandle: f.workspace.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'direct-replace',
            parameters: {
              'modelId': 'house',
              'artifactHandle': staged.reference.handle
            }));
    final applied = await f.mutations.applyMutation(f.project,
        planId: plan.planId, operationId: 'direct-replace');
    final replay = await f.mutations.applyMutation(f.project,
        planId: plan.planId, operationId: 'direct-replace');
    expect(replay.receipt.receiptId, applied.receipt.receiptId);
    expect(f.mutations.artifacts.list(), isEmpty);
    final before = await f.projectFile.readAsBytes();
    final identical = await f.planReplacement(animatedGlb());
    expect(identical.status, AuthoringResultStatus.success,
        reason: jsonEncode(identical.toJson()));
    expect(await f.projectFile.readAsBytes(), before);
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('JSONL discovers and atomically imports a project owned model',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        jsonEncode((await f.request('describe')).toJson())
            .contains('model3d.import'),
        isTrue);
    final plan = await f.plan();
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isFalse);
    final result = await f.apply(plan);
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    final manifest = (await f.snapshots.load(f.project)).manifest.toJson();
    expect((manifest['models3d'] as List).single['id'], 'house');
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
  });

  test(
      'configures and queries a model after reopening through JSONL and direct API',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final configured = await f.apply(await f.planAction('model3d.configure', {
      'modelId': 'house',
      'name': 'Cottage',
      'scale': 2.5,
      'pivot': {'x': 1, 'y': 0, 'z': -2}
    }));
    expect(configured.status, AuthoringResultStatus.success,
        reason: configured.toJson().toString());
    final snapshot = await f.snapshots.load(f.project);
    final query = AuthoringQueryRequest(
        resourceKind: 'model3d',
        operation: AuthoringQueryOperation.get,
        ids: ['house'],
        view: AuthoringQueryView.detail);
    final direct = const ProjectQueryService().query(snapshot, query);
    expect(direct.items.single['name'], 'Cottage');
    expect(direct.items.single['scale'], 2.5);
    final jsonl = await f.request(
        'query', {'projectHandle': f.project.value, 'request': query.toJson()});
    expect(jsonl.status, AuthoringResultStatus.success);
    expect(jsonl.data['items'], direct.toJson()['items']);
    final listed = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
            resourceKind: 'model3d', operation: AuthoringQueryOperation.list));
    expect(listed.totalAvailable, 1);
  });

  test('rejects invalid GLB without publishing project files', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await File('${f.root.path}/input.glb').writeAsBytes(
        triangleGlb(edit: (j) => j['buffers'][0]['uri'] = 'outside.bin'));
    final before = await f.projectFile.readAsBytes();
    expect((await f.plan()).status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    expect(await Directory('${f.root.path}/assets').exists(), isFalse);
  });

  test('underlying asset deletion is blocked while model owns it', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final before = await f.projectFile.readAsBytes();
    final plan =
        await f.planAction('asset.delete', {'assetId': 'model3d_house'});
    expect(plan.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isTrue);
  });

  test(
      'delete removes unused model bytes and undo restores the complete resource',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final plan = await f.planAction('model3d.delete', {'modelId': 'house'});
    expect(plan.status, AuthoringResultStatus.success,
        reason: plan.toJson().toString());
    final deleted = await f.apply(plan, confirm: true);
    expect(deleted.status, AuthoringResultStatus.success,
        reason: deleted.toJson().toString());
    expect((await f.snapshots.load(f.project)).manifest.models3d, isEmpty);
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isFalse);
    final history = await f
        .request('history', {'projectHandle': f.project.value, 'limit': 10});
    final entries = history.data['entries'] as List;
    final entry = entries.cast<Map>().firstWhere(
        (e) => (e['receipt'] as Map)['actionId'] == 'model3d.delete');
    final undone = await f.request('undo', {
      'projectHandle': f.project.value,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-model-delete'
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: undone.toJson().toString());
    expect((await f.snapshots.load(f.project)).manifest.models3d.single.id,
        'house');
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
  });

  test(
      'a damaged logical model source fails reopen despite intact history blob',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    await File('${f.root.path}/assets/models3d/house.glb')
        .writeAsBytes([1, 2, 3]);
    await expectLater(
        f.snapshots.load(f.project), throwsA(isA<ProjectSnapshotException>()));
  });

  test('concurrent manifest changes invalidate model plans', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final plan = await f.plan();
    final manifest = (await f.snapshots.load(f.project))
        .manifest
        .copyWith(name: 'Concurrent');
    await f.projectFile.writeAsString(jsonEncode(manifest.toJson()));
    expect((await f.apply(plan)).status, AuthoringResultStatus.failure);
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isFalse);
  });

  test('invalid scale does not alter a stored model', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final before = await f.projectFile.readAsBytes();
    expect(
        (await f.planAction(
                'model3d.configure', {'modelId': 'house', 'scale': 0}))
            .status,
        AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
  });

  test('typed spatial placements prevent model deletion', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final snapshot = await f.snapshots.load(f.project);
    final map = MapData(
        id: 'room',
        name: 'Room',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        layers: [],
        spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
          SpatialModelInstance(
              id: 'placed',
              modelId: 'house',
              position: Model3dVector3(x: 1, y: 0, z: 1))
        ]));
    final file = File('${f.root.path}/maps/room.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    await f.projectFile.writeAsString(jsonEncode(snapshot.manifest.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        maps: [
          const ProjectMapEntry(
              id: 'room', name: 'Room', relativePath: 'maps/room.json')
        ]).toJson()));
    final before = await f.projectFile.readAsBytes();
    final result = await f.planAction('model3d.delete', {'modelId': 'house'});
    expect(result.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
  });

  test('interrupted model publication is recoverable', () async {
    final f = await _Fixture.create(failAfterPromotion: true);
    addTearDown(f.dispose);
    final result = await f.apply(await f.plan());
    expect(result.status, AuthoringResultStatus.failure);
    final recovered = await f.request('recover',
        {'projectHandle': f.project.value, 'operationId': f.lastOperation});
    expect(recovered.status, AuthoringResultStatus.success,
        reason: recovered.toJson().toString());
    expect((await f.snapshots.load(f.project)).manifest.models3d.single.id,
        'house');
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
  });

  test('generic asset replacements cannot bypass model inspection', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    await File('${f.root.path}/invalid.bin').writeAsBytes([0, 1, 2]);
    final staged = await f.request(
        'stage_artifact', {'sourcePath': '${f.root.path}/invalid.bin'});
    final result = await f.planAction('asset.replace', {
      'assetId': 'model3d_house',
      'artifactHandle': staged.data['artifactHandle']
    });
    expect(result.status, AuthoringResultStatus.failure);
    expect(await File('${f.root.path}/assets/models3d/house.glb').readAsBytes(),
        triangleGlb());
  });

  test('direct API imports and idempotent apply preserves one model', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final staged = await f.mutations
        .stageArtifactFile(sourcePath: '${f.root.path}/input.glb');
    expect(staged.reference.mediaType, 'model/gltf-binary');
    final snapshot = await f.snapshots.load(f.project);
    final plan = await f.mutations.planMutation(
        f.project,
        AuthoringRequest(
            requestId: 'direct',
            actionId: 'model3d.import',
            actionVersion: 1,
            workspaceHandle: f.workspace.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'direct-import',
            parameters: {
              'artifactHandle': staged.reference.handle,
              'modelId': 'direct',
              'name': 'Direct model'
            }));
    final applied = await f.mutations.applyMutation(f.project,
        planId: plan.planId, operationId: 'direct-operation');
    final replay = await f.mutations.applyMutation(f.project,
        planId: plan.planId, operationId: 'direct-operation');
    expect(replay.receipt.receiptId, applied.receipt.receiptId);
    expect((await f.snapshots.load(f.project)).manifest.models3d.single.id,
        'direct');
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('reference created under the write lock invalidates model deletion',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    expect(
        (await f.apply(await f.plan())).status, AuthoringResultStatus.success);
    final snapshot = await f.snapshots.load(f.project);
    final map = MapData(
        id: 'room',
        name: 'Room',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        layers: [],
        spatialScene: MapSpatialScene(width: 4, depth: 4));
    final file = File('${f.root.path}/maps/room.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    await f.projectFile.writeAsString(jsonEncode(snapshot.manifest.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        maps: [
          const ProjectMapEntry(
              id: 'room', name: 'Room', relativePath: 'maps/room.json')
        ]).toJson()));
    final plan = await f.planAction('model3d.delete', {'modelId': 'house'});
    expect(plan.status, AuthoringResultStatus.success,
        reason: plan.toJson().toString());
    final confirmation = await f.mutations
        .confirmMutation(f.project, planId: plan.data['planId'] as String);
    await expectLater(
        f.mutations.applyMutation(f.project,
            planId: plan.data['planId'] as String,
            operationId: 'locked-delete',
            confirmationToken: confirmation.toJson()['confirmationToken']
                as String, precondition: () async {
          final referenced = map.copyWith(
              spatialScene: map.spatialScene!.copyWith(instances: [
            SpatialModelInstance(
                id: 'placed',
                modelId: 'house',
                position: Model3dVector3(x: 1, y: 0, z: 1))
          ]));
          await file.writeAsString(jsonEncode(referenced.toJson()));
        }),
        throwsA(isA<AuthoringPlanException>()));
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isTrue);
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
    final root = await Directory.systemTemp.createTemp('tileset-image-import-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      ProjectManifest(name: 'Image import', maps: [], tilesets: []).toJson(),
    ));
    await File('${root.path}/input.glb').writeAsBytes(triangleGlb());
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

  Future<AuthoringResult> planReplacement(List<int> bytes,
      {String modelId = 'house'}) async {
    await File('${root.path}/replacement.glb').writeAsBytes(bytes);
    final staged = await request(
        'stage_artifact', {'sourcePath': '${root.path}/replacement.glb'});
    expect(staged.status, AuthoringResultStatus.success);
    return planAction('model3d.source.replace',
        {'modelId': modelId, 'artifactHandle': staged.data['artifactHandle']});
  }

  Future<File> addPlacement({int? animationIndex}) async {
    final snapshot = await snapshots.load(project);
    final map = MapData(
        id: 'room',
        name: 'Room',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        layers: [],
        spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
          SpatialModelInstance(
              id: 'placed',
              modelId: 'house',
              position: Model3dVector3(x: 1, y: 0, z: 1),
              animationIndex: animationIndex,
              animationLoop: false,
              animationSpeed: 1.5)
        ]));
    final file = File('${root.path}/maps/room.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    await projectFile.writeAsString(jsonEncode(snapshot.manifest.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        maps: [
          const ProjectMapEntry(
              id: 'room', name: 'Room', relativePath: 'maps/room.json')
        ]).toJson()));
    return file;
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

  Future<void> dispose() => root.delete(recursive: true);
}
