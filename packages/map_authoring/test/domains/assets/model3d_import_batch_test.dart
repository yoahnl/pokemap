import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/glb_fixture.dart';

void main() {
  test('discovers a bounded recoverable model import contract', () {
    final descriptor = Model3dActions.descriptors
        .singleWhere((action) => action.id == 'model3d.import_batch');
    expect(descriptor.version, 1);
    expect(descriptor.guarantees, isNot(contains(AuthoringGuarantee.atomic)));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
    expect(descriptor.requiredPermissions,
        contains(AuthoringPermission.importRun));
    expect(descriptor.extensions['maximumModelCount'], 50);
    expect(descriptor.extensions['maximumTotalByteLength'], 64 * 1024 * 1024);
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(schema['additionalProperties'], isFalse);
    expect(schema['required'], ['models']);
    final models = (schema['properties'] as Map)['models'] as Map;
    expect(models['minItems'], 1);
    expect(models['maxItems'], 50);
    expect((models['items'] as Map)['additionalProperties'], isFalse);
  });

  test('direct API publishes one manifest and catalog and replays one receipt',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await f.importSingle('existing');
    final before = await f.snapshot();
    final entries = await f.models(['house', 'tree']);
    final planned = await f.mutations.planMutation(f.project,
        f.authoringRequest(entries, expectedRevision: before.revision));
    final changes = planned.plan.changeSet.changes;
    expect(changes.where((change) => change.storageKey == 'project.json'),
        hasLength(1));
    expect(
        changes.where((change) => change.storageKey == assetCatalogStorageKey),
        hasLength(1));
    expect(
        changes
            .singleWhere((change) => change.storageKey == 'project.json')
            .beforeBytes,
        before.resourceBytes('project'));
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isFalse);
    final applied = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'models-direct');
    final replay = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'models-direct');
    expect(replay.receipt.receiptId, applied.receipt.receiptId);
    final after = await f.snapshot();
    expect(after.manifest.models3d.map((model) => model.id),
        ['existing', 'house', 'tree']);
    final catalog = AssetCatalog.fromJson(jsonDecode(
            utf8.decode(after.resourceBytes(assetCatalogResourceIdentity)))
        as Map<String, dynamic>);
    expect(catalog.records.map((asset) => asset.id).toSet(),
        {'model3d_existing', 'model3d_house', 'model3d_tree'});
    for (final id in ['existing', 'house', 'tree']) {
      expect(await File('${f.root.path}/assets/models3d/$id.glb').readAsBytes(),
          triangleGlb());
    }
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('JSONL imports fifty models while sharing one inspected blob', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final handle = await f.stage('shared');
    final entries = [for (var i = 0; i < 50; i++) _model('tree-$i', handle)];
    final planned = await f.plan(entries);
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final applied = await f.apply(planned);
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    expect((await f.snapshot()).manifest.models3d, hasLength(50));
    final blobs =
        await Directory('${f.root.path}/assets/.pokemap-store').list().toList();
    expect(blobs.whereType<File>(), hasLength(1));
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('idempotent replay preserves another staging lease for the same blob',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final entries = await f.models(['house', 'tree']);
    final otherLease = await f.stage('other-lease');
    final planned = await f.mutations.planMutation(
        f.project,
        f.authoringRequest(entries,
            expectedRevision: (await f.snapshot()).revision));
    final applied = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'lease-batch');
    expect(f.mutations.artifacts.inspect(otherLease), isNotNull);
    final replay = await f.mutations.applyMutation(f.project,
        planId: planned.planId, operationId: 'lease-batch');
    expect(replay.receipt.receiptId, applied.receipt.receiptId);
    expect(f.mutations.artifacts.inspect(otherLease), isNotNull);
    await f.mutations.artifacts.release(otherLease);
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  final invalid = <String, Object? Function(String)>{
    'empty batch': (_) => [],
    'too many models': (handle) =>
        [for (var i = 0; i < 51; i++) _model('tree-$i', handle)],
    'duplicate identities': (handle) =>
        [_model('tree', handle), _model('tree', handle)],
    'invalid identity': (handle) =>
        [_model('tree', handle), _model('../house', handle)],
    'unknown field': (handle) => [
          _model('tree', handle),
          {..._model('house', handle), 'scale': 2}
        ],
    'missing name': (handle) => [
          _model('tree', handle),
          {'modelId': 'house', 'artifactHandle': handle}
        ],
    'overlong name': (handle) => [
          _model('tree', handle),
          {..._model('house', handle), 'name': 'x' * 257}
        ],
    'trailing non-object': (handle) => [_model('tree', handle), 'house'],
    'unavailable artifact': (handle) =>
        [_model('tree', handle), _model('house', 'missing')],
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key} without publishing any model', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final handle = await f.stage('shared');
      final before = await f.projectFile.readAsBytes();
      final result = await f.plan(entry.value(handle));
      expect(result.status, AuthoringResultStatus.failure);
      expect(await f.projectFile.readAsBytes(), before);
      expect(await Directory('${f.root.path}/assets').exists(), isFalse);
    });
  }

  test('rejects a trailing invalid GLB without retaining the valid first model',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final good = await f.stage('good');
    final bad = await f.stage('bad',
        bytes: triangleGlb(
            edit: (json) => json['buffers'][0]['uri'] = 'outside.bin'));
    final before = await f.projectFile.readAsBytes();
    final result = await f.plan([_model('good', good), _model('bad', bad)]);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    expect(await Directory('${f.root.path}/assets').exists(), isFalse);
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  for (final count in [1, 2]) {
    test('rejects the byte budget before reading $count declared models',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final bytes = triangleGlb();
      final real =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
      final store = _ProbeArtifactStore(
          ContentArtifactRef(
              digest: real.digest,
              mediaType: real.mediaType,
              byteLength: (64 * 1024 * 1024) ~/ count + 1),
          bytes);
      final entries = [
        for (var i = 0; i < count; i++) _model('model-$i', real.handle)
      ];
      await expectLater(
          Model3dActions(artifactStore: store).build(AuthoringPlanningContext(
              snapshot: await f.snapshot(),
              request: f.authoringRequest(entries),
              planId: 'budget',
              seed: 1)),
          throwsA(isA<FormatException>().having(
              (error) => error.message, 'message', contains('64 MiB'))));
      expect(store.readCount, 0);
      expect(await Directory('${f.root.path}/assets').exists(), isFalse);
    });
  }

  test('frozen imported bytes must retain the staged content identity',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final bytes = triangleGlb();
    final reference =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final changed = [...bytes]..[bytes.length - 1] ^= 1;
    final store = _ProbeArtifactStore(reference, changed);
    await expectLater(
        Model3dActions(artifactStore: store).build(AuthoringPlanningContext(
            snapshot: await f.snapshot(),
            request: f.authoringRequest([_model('changed', reference.handle)]),
            planId: 'changed',
            seed: 1)),
        throwsA(isA<FormatException>().having(
            (error) => error.message, 'message', contains('content changed'))));
    expect(await Directory('${f.root.path}/assets').exists(), isFalse);
  });

  test(
      'rejects existing model and asset identities while preserving all preimages',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await f.importSingle('existing');
    final before = await f.projectFile.readAsBytes();
    final catalogBefore =
        await File('${f.root.path}/$assetCatalogStorageKey').readAsBytes();
    final result = await f.plan(await f.models(['new', 'existing']));
    expect(result.status, AuthoringResultStatus.failure);
    expect(await f.projectFile.readAsBytes(), before);
    expect(await File('${f.root.path}/$assetCatalogStorageKey').readAsBytes(),
        catalogBefore);
    expect(
        await File('${f.root.path}/assets/models3d/new.glb').exists(), isFalse);
  });

  test('dry run releases staged bytes and publishes nothing', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final entries = await f.models(['house', 'tree']);
    final request = f.authoringRequest(entries,
        dryRun: true, expectedRevision: (await f.snapshot()).revision);
    final planned = await f.mutations.planMutation(f.project, request);
    expect(planned.applicable, isFalse);
    expect((await f.snapshot()).manifest.models3d, isEmpty);
    expect(await Directory('${f.root.path}/assets').exists(), isFalse);
    expect(f.mutations.artifacts.list(), isEmpty);
  });

  test('undo removes the complete batch and restores the previous catalog',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await f.importSingle('existing');
    final before = await f.projectFile.readAsBytes();
    final catalogBefore =
        await File('${f.root.path}/$assetCatalogStorageKey').readAsBytes();
    final result =
        await f.apply(await f.plan(await f.models(['house', 'tree'])));
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    final history = await f
        .request('history', {'projectHandle': f.project.value, 'limit': 10});
    final batch = (history.data['entries'] as List).cast<Map>().singleWhere(
        (entry) =>
            (entry['receipt'] as Map)['actionId'] == 'model3d.import_batch');
    final undone = await f.request('undo', {
      'projectHandle': f.project.value,
      'entryId': batch['entryId'],
      'idempotencyKey': 'undo-model-batch'
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: jsonEncode(undone.toJson()));
    expect(await f.projectFile.readAsBytes(), before);
    expect(await File('${f.root.path}/$assetCatalogStorageKey').readAsBytes(),
        catalogBefore);
    expect((await f.snapshot()).manifest.models3d.single.id, 'existing');
    expect(await File('${f.root.path}/assets/models3d/house.glb').exists(),
        isFalse);
    expect(await File('${f.root.path}/assets/models3d/tree.glb').exists(),
        isFalse);
  });

  test('interrupted cross-file publication recovers the whole batch', () async {
    final f = await _Fixture.create(failAfterPromotion: true);
    addTearDown(f.dispose);
    final result =
        await f.apply(await f.plan(await f.models(['house', 'tree'])));
    expect(result.status, AuthoringResultStatus.failure);
    final recovered = await f.request('recover',
        {'projectHandle': f.project.value, 'operationId': f.lastOperation});
    expect(recovered.status, AuthoringResultStatus.success,
        reason: jsonEncode(recovered.toJson()));
    expect((await f.snapshot()).manifest.models3d.map((model) => model.id),
        ['house', 'tree']);
    for (final id in ['house', 'tree']) {
      expect(await File('${f.root.path}/assets/models3d/$id.glb').readAsBytes(),
          triangleGlb());
    }
    expect(f.mutations.artifacts.list(), isEmpty);
    final otherLease = await f.stage('post-recovery-lease');
    final replay = await f.request('recover',
        {'projectHandle': f.project.value, 'operationId': f.lastOperation});
    expect(replay.status, AuthoringResultStatus.success,
        reason: jsonEncode(replay.toJson()));
    expect(f.mutations.artifacts.inspect(otherLease), isNotNull);
    await f.mutations.artifacts.release(otherLease);
  });

  test('manifest races reject the entire pending batch', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final planned = await f.plan(await f.models(['house', 'tree']));
    final changed = (await f.snapshot()).manifest.copyWith(name: 'Concurrent');
    await f.projectFile.writeAsString(jsonEncode(changed.toJson()));
    final result = await f.apply(planned);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await Directory('${f.root.path}/assets').exists(), isFalse);
    expect(
        jsonDecode(await f.projectFile.readAsString())['name'], 'Concurrent');
  });

  test('real CLI discovers and imports a batch that reopens', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    await File('${f.root.path}/cli.glb').writeAsBytes(triangleGlb());
    final process = await Process.start(
        'dart', ['bin/pokemap_authoring.dart', '--root', f.root.path]);
    final lines = StreamIterator<String>(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()));
    final errors = process.stderr.transform(utf8.decoder).join();
    addTearDown(() async {
      await process.stdin.close();
      await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
        process.kill();
        return process.exitCode;
      });
      await lines.cancel();
    });
    var sequence = 0;
    Future<AuthoringResult> send(String command,
        [Map<String, Object?> args = const {}]) async {
      process.stdin.writeln(jsonEncode(
          {'id': 'model-cli-${sequence++}', 'command': command, 'args': args}));
      await process.stdin.flush();
      expect(await lines.moveNext(), isTrue);
      final result = AuthoringResult.fromJson(
          jsonDecode(lines.current) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
      return result;
    }

    final described = await send('describe');
    expect(
        (described.data['mutationActions'] as List)
            .where((action) => action['id'] == 'model3d.import_batch'),
        hasLength(1));
    final opened = await send('open', {'projectRoot': f.root.path});
    final staged =
        await send('stage_artifact', {'sourcePath': '${f.root.path}/cli.glb'});
    final planned = await send('plan', {
      'projectHandle': opened.data['projectHandle'],
      'request': AuthoringRequest(
          requestId: 'model-cli',
          actionId: 'model3d.import_batch',
          actionVersion: 1,
          workspaceHandle: opened.data['workspaceHandle'] as String,
          expectedRevision: (await f.snapshot()).revision,
          idempotencyKey: 'model-cli',
          parameters: {
            'models': [
              _model('cli-house', staged.data['artifactHandle'] as String),
              _model('cli-tree', staged.data['artifactHandle'] as String)
            ]
          }).toJson()
    });
    await send('apply', {
      'projectHandle': opened.data['projectHandle'],
      'planId': planned.data['planId'],
      'operationId': 'model-cli'
    });
    await send('close', {'workspaceHandle': opened.data['workspaceHandle']});
    expect((await f.snapshot()).manifest.models3d.map((model) => model.id),
        ['cli-house', 'cli-tree']);
    await process.stdin.close();
    expect(await process.exitCode, 0);
    expect(await errors, isEmpty);
  });
}

Map<String, Object?> _model(String id, String handle) =>
    {'modelId': id, 'name': id, 'artifactHandle': handle};

final class _ProbeArtifactStore implements ArtifactStore {
  _ProbeArtifactStore(this.reference, this.bytes);

  final ContentArtifactRef reference;
  final List<int> bytes;
  int readCount = 0;

  @override
  ContentArtifactRef? inspect(String handle) =>
      handle == reference.handle ? reference : null;

  @override
  List<ContentArtifactRef> list() => [reference];

  @override
  Future<StoredArtifact> put(List<int> bytes, {String? declaredMediaType}) =>
      throw UnsupportedError('Read probe');

  @override
  Future<List<int>> read(String handle) async {
    readCount++;
    return bytes;
  }

  @override
  Future<bool> release(String handle) async => true;
}

final class _Fixture {
  _Fixture(this.root, this.snapshots, this.worker, this.project, this.workspace,
      this.mutations);

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final LocalMapAuthoringMutationApi mutations;
  int sequence = 0;
  String? lastOperation;

  File get projectFile => File('${root.path}/project.json');
  Future<ProjectSnapshot> snapshot() => snapshots.load(project);

  static Future<_Fixture> create({bool failAfterPromotion = false}) async {
    final root = await Directory.systemTemp.createTemp('model3d-import-batch-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(name: 'Models', maps: [], tilesets: []).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final api =
        AuthoringReadApi(openService: opener, snapshotLoader: snapshots);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        artifactStore: LocalArtifactStore(
            allowedSourceRoots: [root.path], maximumArtifactBytes: 1048576),
        faultInjector: failAfterPromotion
            ? (context) {
                if (context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted) {
                  throw const FileSystemException(
                      'Injected batch write failure');
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
        mutations);
  }

  Future<String> stage(String id, {List<int>? bytes}) async {
    final path = '${root.path}/$id.glb';
    await File(path).writeAsBytes(bytes ?? triangleGlb());
    final staged = await mutations.stageArtifactFile(sourcePath: path);
    return staged.reference.handle;
  }

  Future<List<Map<String, Object?>>> models(List<String> ids) async {
    final handle = await stage('models-${sequence++}');
    return [for (final id in ids) _model(id, handle)];
  }

  AuthoringRequest authoringRequest(Object? entries,
          {bool dryRun = false,
          String? expectedRevision,
          String action = 'model3d.import_batch'}) =>
      AuthoringRequest(
          requestId: 'model-batch-${sequence++}',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: workspace.value,
          idempotencyKey: 'model-batch-${sequence++}',
          dryRun: dryRun,
          expectedRevision: expectedRevision,
          parameters: action == 'model3d.import_batch'
              ? {'models': entries}
              : entries as Map<String, Object?>);

  Future<AuthoringResult> request(String command,
      [Map<String, Object?> args = const {}]) async {
    final response = await worker.processLine(jsonEncode({
      'id': 'model-request-${sequence++}',
      'command': command,
      'args': args
    }));
    return AuthoringResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>);
  }

  Future<AuthoringResult> plan(Object? entries,
      {String action = 'model3d.import_batch'}) async {
    final request = authoringRequest(entries, action: action);
    final current = await snapshot();
    return this.request('plan', {
      'projectHandle': project.value,
      'request': {...request.toJson(), 'expectedRevision': current.revision}
    });
  }

  Future<AuthoringResult> apply(AuthoringResult planned) {
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    lastOperation = 'model-apply-${sequence++}';
    return request('apply', {
      'projectHandle': project.value,
      'planId': planned.data['planId'],
      'operationId': lastOperation
    });
  }

  Future<void> importSingle(String id) async {
    final result = await apply(await plan(_model(id, await stage('single')),
        action: 'model3d.import'));
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
  }

  Future<void> dispose() => root.delete(recursive: true);
}
