import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_model_geometry.dart';
import 'package:test/test.dart';

import '../support/glb_fixture.dart';

void main() {
  test('scoped model source reads do not stage temporary payload files',
      () async {
    final fixture = await _Fixture.open(80);
    addTearDown(fixture.close);
    final temp = _CountingTempDirectory(Directory.systemTemp);
    final snapshot = await IOOverrides.runZoned(
      fixture.selected,
      getSystemTempDirectory: () => temp,
    );
    expect(snapshot.resourceBytes('model3d:house'), _volumeGlb());
    expect(temp.created, isEmpty);
  });

  for (final unrelated in [0, 80]) {
    test(
        'one-shot selection avoids reloading source bytes with $unrelated unrelated definitions',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final bytes = _volumeGlb(
          edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]);
      final prepared =
          await fixture.request(bytes, 'one-shot', batch: unrelated > 0);
      final request = AuthoringRequest.fromJson({
        ...prepared.toJson(),
        'parameters': Map<String, Object?>.fromEntries(
            prepared.parameters.entries.toList().reversed)
      });
      fixture.reader.paths.clear();
      final source = _CountingSourceFile(
          File('${fixture.root.path}/assets/models3d/house.glb'));
      final io = IOOverrides.current ?? _DefaultIOOverrides();
      Future<AuthoringMutationPlanResult> plan(AuthoringRequest value) =>
          IOOverrides.runZoned(
            () => fixture.api.planMutation(fixture.opened.projectHandle, value),
            createFile: (path) =>
                path == source.path ? source : io.createFile(path),
          );
      final planned = await plan(request);
      expect(planned.applicable, isTrue);
      expect(source.byteReads, 0);
      expect(source.streamReads, greaterThan(0));
      expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
          isEmpty);
      expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
          isEmpty);
      source.byteReads = 0;
      final next = AuthoringRequest.fromJson({
        ...request.toJson(),
        'requestId': 'consumed',
        'idempotencyKey': 'consumed'
      });
      expect((await plan(next)).applicable, isTrue);
      expect(source.byteReads, greaterThan(0));
    });
  }

  for (final unrelated in [0, 80]) {
    test(
        'model replacement stays local cold and repeated with $unrelated unrelated definitions',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        fixture.promoted.clear();
        final bytes = _volumeGlb(edit: (json) {
          json['nodes'][0]['translation'] = [10 + repeat, 3, -1];
        });
        final planned =
            await fixture.plan(bytes, 'replace-$repeat', batch: repeat == 1);
        expect(planned.projectedProject!.models3d.single.id, 'house');
        expect(planned.projectedProject!.models3d.single.scale, 1.25);
        expect(
            planned.plan.changeSet.changes.map((change) => change.storageKey),
            unorderedEquals([
              CatalogStorageStore.headStorageKey,
              assetCatalogStorageKey,
              'assets/models3d/house.glb',
              assetBlobStorageKey(ContentArtifactRef.fromBytes(bytes,
                  mediaType: 'model/gltf-binary')),
            ]));
        final storageKeys = planned.plan.changeSet.changes
            .map((change) => change.storageKey)
            .toList();
        final applied = await fixture.api.applyMutation(
            fixture.opened.projectHandle,
            planId: planned.planId,
            operationId: 'replace-$repeat');
        expect(
            applied.receipt.actionId,
            repeat == 0
                ? 'model3d.source.replace'
                : 'model3d.source.replace_batch');
        expect(
            await File('${fixture.root.path}/assets/models3d/house.glb')
                .readAsBytes(),
            bytes);
        expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
            isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
            isEmpty);
        expect(fixture.reader.paths.length, lessThan(220));
        expect(fixture.promoted, unorderedEquals(storageKeys));
        expect(await File('${fixture.root.path}/project.json').readAsBytes(),
            fixture.descriptor);
        await fixture.reopen();
        final selected = await fixture.selected();
        expect(selected.maps, isEmpty);
        expect(selected.manifest.models3d.single.inspection.bounds.min.y, 3);
      }
    });
  }
  for (final path in [
    'assets/models3d/house.glb',
    assetCatalogStorageKey,
    'project.json',
    CatalogStorageStore.headStorageKey
  ]) {
    test('one-shot selection rejects changed dependency $path before planning',
        () async {
      final fixture = await _Fixture.open(0);
      addTearDown(fixture.close);
      final request = await fixture.request(
          _volumeGlb(
              edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]),
          'changed');
      final file = File('${fixture.root.path}/$path');
      final changed = [...await file.readAsBytes(), 32];
      await file.writeAsBytes(changed);
      await expectLater(
          fixture.api.planMutation(fixture.opened.projectHandle, request),
          throwsA(anyOf(isA<AuthoringPlanException>(), isA<FormatException>(),
              isA<CatalogStorageException>())));
      expect(await file.readAsBytes(), changed);
      expect(fixture.promoted, isEmpty);
    });
  }

  for (final removed in [false, true]) {
    test(
        'one-shot selection rejects targeted object corruption removed=$removed',
        () async {
      final fixture = await _Fixture.open(0);
      addTearDown(fixture.close);
      final store =
          await CatalogStorageStore.open(projectRoot: fixture.root.path);
      final published = await store.openRoot((await store.readHead())!);
      final entry = (await published.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'house')))!;
      final file = File(
          '${fixture.root.path}/catalog/objects/${entry.reference.sha256}.json');
      final request = await fixture.request(
          _volumeGlb(
              edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]),
          'corrupt');
      if (removed) {
        await file.delete();
      } else {
        await file.writeAsString('corrupted selected model');
      }
      await expectLater(
          fixture.api.planMutation(fixture.opened.projectHandle, request),
          throwsA(anyOf(isA<FormatException>(), isA<CatalogStorageException>(),
              isA<FileSystemException>())));
      expect(fixture.promoted, isEmpty);
    });
  }

  for (final bad in ['parameters', 'revision']) {
    test('one-shot selection rejects wrong $bad', () async {
      final fixture = await _Fixture.open(0);
      addTearDown(fixture.close);
      final request = await fixture.request(
          _volumeGlb(
              edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]),
          'wrong');
      final changed = AuthoringRequest.fromJson({
        ...request.toJson(),
        if (bad == 'parameters')
          'parameters': {...request.parameters, 'unknown': true},
        if (bad == 'revision') 'expectedRevision': 'sha256:${'0' * 64}',
      });
      await expectLater(
          fixture.api.planMutation(fixture.opened.projectHandle, changed),
          throwsA(
              anyOf(isA<FormatException>(), isA<AuthoringPlanException>())));
      expect(fixture.promoted, isEmpty);
    });
  }

  test('one-shot selection still rejects recovery created after snapshot',
      () async {
    final fixture = await _Fixture.open(0, faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalPrepared) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(fixture.close);
    final bytes = _volumeGlb(
        edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]);
    final pending = await fixture.plan(bytes, 'pending');
    final request = await fixture.request(bytes, 'after-pending');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: pending.planId, operationId: 'pending'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await expectLater(
        fixture.api.planMutation(fixture.opened.projectHandle, request),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.recovery_required')));
    expect(fixture.promoted, isEmpty);
  });

  for (final batch in [false, true]) {
    for (final explicit in [false, true]) {
      test(
          'replacement preserves effective collision geometry batch=$batch explicit=$explicit',
          () async {
        final configured = explicit
            ? Model3dBounds(
                min: Model3dVector3(x: 9, y: 1, z: -3),
                max: Model3dVector3(x: 14, y: 4, z: 2),
              )
            : null;
        final fixture = await _Fixture.open(80, collisionBounds: configured);
        addTearDown(fixture.close);
        final before = (await fixture.selected()).manifest.models3d.single;
        expect(before.blocksMovementByDefault, false);
        final bytes = _volumeGlb(edit: (json) {
          json['nodes'][0]['translation'] = [-4, 6, 9];
          json['nodes'][0]['scale'] = [4, 3, 2];
        });
        fixture.reader.paths.clear();
        final plan = await fixture.plan(bytes, 'collision', batch: batch);
        final after = plan.projectedProject!.models3d.single;
        expect(after.collisionBounds, configured ?? before.inspection.bounds);
        expect(after.inspection.bounds, isNot(before.inspection.bounds));
        for (final angle in [0.0, 37.0, 90.0, 213.0]) {
          for (final scale in [0.5, 2.5]) {
            final instance = SpatialModelInstance(
              id: 'placed',
              modelId: before.id,
              position: Model3dVector3(x: 20, y: 3, z: -8),
              rotationDegrees: angle,
              scale: scale,
              blocksMovement: true,
            );
            final original = spatialModelWorldGeometry(instance, before,
                useCollisionBounds: true);
            final replaced = spatialModelWorldGeometry(instance, after,
                useCollisionBounds: true);
            expect(replaced.polygon, original.polygon);
            expect(replaced.minY, original.minY);
            expect(replaced.maxY, original.maxY);
            expect(spatialModelWorldGeometry(instance, after).polygon,
                isNot(spatialModelWorldGeometry(instance, before).polygon));
          }
        }
        expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
            isEmpty);
        final applied = await fixture.api.applyMutation(
            fixture.opened.projectHandle,
            planId: plan.planId,
            operationId: 'collision');
        await fixture.reopen();
        expect(
            (await fixture.selected()).manifest.models3d.single.collisionBounds,
            configured ?? before.inspection.bounds);
        await fixture.api.undoMutation(fixture.opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-collision');
        expect(
            (await fixture.selected()).manifest.models3d.single.collisionBounds,
            configured);
      });
    }
    test('changed implicit degenerate collision rejects safely batch=$batch',
        () async {
      final fixture = await _Fixture.open(0, source: triangleGlb());
      addTearDown(fixture.close);
      final before = await fixture.selected();
      await expectLater(
          fixture.plan(_volumeGlb(), 'degenerate', batch: batch),
          throwsA(isA<AuthoringPlanException>().having(
              (failure) => failure.code,
              'code',
              'model3d.source_collision_bounds_required')));
      expect(fixture.promoted, isEmpty);
      expect(fixture.api.artifacts.inspect(fixture.lastArtifact!), isNull);
      final after = await fixture.selected();
      expect(after.revision, before.revision);
      expect(after.resourceBytes('model3d:house'),
          before.resourceBytes('model3d:house'));
    });
  }

  test(
      'source contract rejects new animation capabilities without reading usages',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    await expectLater(
        fixture.plan(animatedGlb(), 'animate'),
        throwsA(isA<AuthoringPlanException>().having((error) => error.code,
            'code', 'catalog.model_source_usage_proof_required')));
    expect(fixture.api.artifacts.inspect(fixture.lastArtifact!), isNull);
    expect(fixture.promoted, isEmpty);
    expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
        isEmpty);
    expect(
        await File('${fixture.root.path}/assets/models3d/house.glb')
            .readAsBytes(),
        _volumeGlb());
  });

  test(
      'source contract preserves unused clips for saved poses and accepts additional clips',
      () async {
    final fixture = await _Fixture.open(0, source: _animated(2));
    addTearDown(fixture.close);
    await expectLater(
        fixture.plan(_animated(1), 'remove-unused', batch: true),
        throwsA(isA<AuthoringPlanException>().having((error) => error.code,
            'code', 'catalog.model_source_usage_proof_required')));
    final added = await fixture.plan(_animated(3), 'add-clip', batch: true);
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: added.planId, operationId: 'add-clip');
    expect(
        (await fixture.selected())
            .manifest
            .models3d
            .single
            .inspection
            .animations
            .map((clip) => clip.index),
        [0, 1, 2]);
  });

  test(
      'unchanged source is a no-op and snapshots expose real catalog document bytes',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final selected = await fixture.selected();
    expect(selected.resourceBytes('catalogDescriptor'),
        await File('${fixture.root.path}/project.json').readAsBytes());
    expect(selected.resourceBytes('catalogHead'),
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes());
    final plan = await fixture.plan(_volumeGlb(), 'same');
    expect(plan.applicable, false);
    expect(plan.nonApplicableReason, 'no_changes');
    expect(plan.plan.changeSet.changes, isEmpty);
    expect(fixture.promoted, isEmpty);
    expect((await fixture.selected()).revision, selected.revision);
  });

  test('source selection rejects bytes differing from the registered artifact',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    await File('${fixture.root.path}/assets/models3d/house.glb').writeAsBytes(
        _volumeGlb(
            edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]));
    await expectLater(
        fixture.selected(),
        throwsA(isA<AuthoringPlanException>().having((error) => error.code,
            'code', 'catalog.model_source_artifact_mismatch')));
    expect(fixture.promoted, isEmpty);
  });

  for (final path in [
    'assets/models3d/house.glb',
    assetCatalogStorageKey,
    'project.json'
  ]) {
    test(
        'concurrent change to $path rejects publication without overwriting it',
        () async {
      final fixture = await _Fixture.open(0);
      addTearDown(fixture.close);
      final plan = await fixture.plan(
          _volumeGlb(
              edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]),
          'stale');
      final file = File('${fixture.root.path}/$path');
      final current = await file.readAsBytes();
      final concurrent = [...current, 32];
      await file.writeAsBytes(concurrent);
      final head =
          await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
      await expectLater(
          fixture.api.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: 'stale'),
          throwsA(path == 'project.json'
              ? isA<AuthoringPlanException>()
                  .having((error) => error.code, 'code', 'plan.stale')
              : isA<CatalogStorageException>().having((error) => error.code,
                  'code', 'catalog.project_revision_conflict')));
      expect(fixture.promoted, isEmpty);
      expect(await file.readAsBytes(), concurrent);
      expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
          head);
    });
  }

  test('replacement replay and undo remain scoped after reopening', () async {
    final fixture = await _Fixture.open(80);
    addTearDown(fixture.close);
    final before = await fixture.selected();
    final plan = await fixture.plan(
        _volumeGlb(
            edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]),
        'replace-undo');
    final result = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'replace-undo');
    fixture.promoted.clear();
    final replay = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'replace-undo');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    expect(fixture.promoted, isEmpty);
    await fixture.reopen();
    fixture.reader.paths.clear();
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-replace');
    final after = await fixture.selected();
    expect(after.manifest.models3d.single, before.manifest.models3d.single);
    expect(after.resourceBytes('model3d:house'),
        before.resourceBytes('model3d:house'));
    expect(after.resourceBytes(assetCatalogResourceIdentity),
        before.resourceBytes(assetCatalogResourceIdentity));
    expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  test(
      'replacement recovery completes its interrupted storage units after reopening',
      () async {
    var crash = true;
    final fixture = await _Fixture.open(0, faultInjector: (context) {
      if (crash &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.storageKey == 'assets/models3d/house.glb') {
        crash = false;
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(fixture.close);
    final bytes = _volumeGlb(
        edit: (json) => json['nodes'][0]['translation'] = [10, 4, -1]);
    final plan = await fixture.plan(bytes, 'crash');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: 'crash'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await fixture.reopen();
    await expectLater(
        fixture.selected(),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.recovery_required')));
    await expectLater(
        fixture.api.planMutation(
            fixture.opened.projectHandle,
            AuthoringRequest(
                requestId: 'pending',
                actionId: 'model3d.source.replace',
                actionVersion: 1,
                workspaceHandle: fixture.opened.workspaceHandle.value,
                expectedRevision: plan.snapshotRevision,
                idempotencyKey: 'pending',
                parameters: const {
                  'modelId': 'house',
                  'artifactHandle': 'unavailable'
                })),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.recovery_required')));
    final unauthorized = LocalMapAuthoringMutationApi(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [fixture.root.path], fileReader: fixture.reader),
        snapshotLoader: ProjectSnapshotLoader(handles: fixture.handles));
    await expectLater(
        unauthorized.attachProject(
            projectRootPath: '${fixture.root.path}/../outside',
            workspaceHandle: fixture.opened.workspaceHandle,
            projectHandle: fixture.opened.projectHandle),
        throwsA(isA<WorkspaceAccessException>().having(
            (error) => error.code, 'code', 'workspace.path_traversal')));
    final recovered = await fixture.api
        .recoverMutation(fixture.opened.projectHandle, operationId: 'crash');
    expect(recovered.receipt.actionId, 'model3d.source.replace');
    final selected = await fixture.selected();
    expect(selected.resourceBytes('model3d:house'), bytes);
    expect(selected.manifest.models3d.single.inspection.bounds.min.y, 4);
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        fixture.descriptor);
  });
}

List<int> _volumeGlb({void Function(Map<String, dynamic>)? edit}) =>
    triangleGlb(edit: (json) {
      json['nodes'][0]
          ['rotation'] = [0, 0.3826834323650898, 0, 0.9238795325112867];
      edit?.call(json);
    });

List<int> _animated(int count) => animatedGlb(edit: (json) {
      final animation = (json['animations'] as List).single;
      json['animations'] = [
        for (var index = 0; index < count; index++)
          {...animation as Map, 'name': 'Clip $index'}
      ];
    });

final class _Fixture {
  _Fixture(this.root, this.opened, this.handles, this.api, this.reader,
      this.unrelatedObjects, this.descriptor, this.promoted);

  final Directory root;
  OpenedProject opened;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  final _CountingReader reader;
  final Set<String> unrelatedObjects;
  final List<int> descriptor;
  final List<String> promoted;
  String? lastArtifact;

  static Future<_Fixture> open(int unrelated,
      {List<int>? source,
      Model3dBounds? collisionBounds,
      AuthoringTransactionFaultInjector? faultInjector}) async {
    final root = await Directory.systemTemp.createTemp('catalog-model-source-');
    final bytes = source ?? _volumeGlb();
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final model = ProjectModel3dEntry(
        id: 'house',
        name: 'House',
        sourceAssetId: 'house-source',
        relativePath: 'assets/models3d/house.glb',
        scale: 1.25,
        blocksMovementByDefault: false,
        collisionBounds: collisionBounds,
        pivot: Model3dVector3(x: 12, y: 2, z: -1),
        inspection: const GlbModel3dInspector().inspect(bytes));
    final project = ProjectManifest(
        name: 'Source replacement',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        maps: [
          for (var i = 0; i <= unrelated; i++)
            ProjectMapEntry(
                id: 'foreign-$i',
                name: 'Foreign $i',
                relativePath: 'maps/foreign-$i.json'),
        ],
        tilesets: const [],
        models3d: [
          model,
          for (var i = 0; i < unrelated; i++)
            ProjectModel3dEntry.fromJson({
              ...model.toJson(),
              'id': 'foreign-$i',
              'name': 'Foreign $i',
              'sourceAssetId': 'foreign-source-$i',
              'relativePath': 'assets/models3d/foreign-$i.glb'
            }),
        ]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'model-source', project: project);
    final unrelatedObjects = <String>{};
    for (var i = 0; i < unrelated; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'foreign-$i')))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedObjects.add(path);
      await File('${root.path}/$path')
          .writeAsString('unrelated model must not be decoded');
    }
    for (var i = 0; i <= unrelated; i++) {
      final file = File('${root.path}/maps/foreign-$i.json');
      await file.parent.create(recursive: true);
      await file.writeAsString('unrelated map must not be decoded');
    }
    final sourceFile = File('${root.path}/assets/models3d/house.glb');
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsBytes(bytes);
    await File('${root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact),
      for (var i = 0; i < unrelated; i++)
        AssetRecord(
            id: 'foreign-source-$i',
            logicalPath: 'assets/models3d/foreign-$i.glb',
            artifact: artifact),
    ]).toJson()));
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final promoted = <String>[];
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader,
        faultInjector: (context) async {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            promoted.add(context.storageKey!);
          }
          await faultInjector?.call(context);
        });
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString(
        'unrelated legacy history must not be replayed\n' * (unrelated + 1));
    return _Fixture(root, opened, handles, api, reader, unrelatedObjects,
        await File('${root.path}/project.json').readAsBytes(), promoted);
  }

  Future<ProjectSnapshot> selected() =>
      api.readWorkshopSnapshot(opened.projectHandle,
          actionId: 'model3d.source.replace',
          parameters: const {'modelId': 'house'});

  Future<AuthoringMutationPlanResult> plan(List<int> bytes, String operation,
          {bool batch = false}) async =>
      api.planMutation(
          opened.projectHandle, await request(bytes, operation, batch: batch));

  Future<AuthoringRequest> request(List<int> bytes, String operation,
      {bool batch = false}) async {
    final artifact =
        await api.artifacts.put(bytes, declaredMediaType: 'model/gltf-binary');
    lastArtifact = artifact.reference.handle;
    final parameters = batch
        ? <String, Object?>{
            'models': [
              {'modelId': 'house', 'artifactHandle': artifact.reference.handle},
            ]
          }
        : <String, Object?>{
            'modelId': 'house',
            'artifactHandle': artifact.reference.handle
          };
    final action =
        batch ? 'model3d.source.replace_batch' : 'model3d.source.replace';
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    return AuthoringRequest(
        requestId: operation,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: operation,
        parameters: parameters);
  }

  Future<void> reopen() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            promoted.add(context.storageKey!);
          }
        });
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

final class _CountingTempDirectory implements Directory {
  _CountingTempDirectory(this.delegate);
  final Directory delegate;
  final List<String?> created = [];

  @override
  Future<Directory> createTemp([String? prefix]) {
    created.add(prefix);
    return delegate.createTemp(prefix);
  }

  @override
  String get path => delegate.path;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected temporary directory operation.');
}

final class _CountingSourceFile implements File {
  _CountingSourceFile(this.delegate);
  final File delegate;
  int byteReads = 0;
  int streamReads = 0;

  @override
  String get path => delegate.path;

  @override
  Future<FileStat> stat() => delegate.stat();

  @override
  Future<bool> exists() => delegate.exists();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      delegate.open(mode: mode);

  @override
  Future<Uint8List> readAsBytes() {
    byteReads++;
    return delegate.readAsBytes();
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    streamReads++;
    return delegate.openRead(start, end);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
      'Unexpected source operation: ${invocation.memberName}');
}

final class _DefaultIOOverrides extends IOOverrides {}
