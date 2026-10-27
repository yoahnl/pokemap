import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'map creation accepts an observed full revision and rejects it after a concurrent commit',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final full = await fixture.snapshots.load(fixture.opened.projectHandle);
    Future<AuthoringMutationPlanResult> plan(String id) => fixture.api
        .planMutation(
            fixture.opened.projectHandle,
            AuthoringRequest(
                requestId: id,
                actionId: 'map.create',
                actionVersion: 1,
                workspaceHandle: fixture.opened.workspaceHandle.value,
                expectedRevision: full.revision,
                idempotencyKey: id,
                parameters: _parameters(id)));
    fixture.reader.paths.clear();
    final first = await plan('legacy');
    expect(first.plan.request.expectedRevision, full.revision);
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: first.planId, operationId: 'legacy');
    await expectLater(
        plan('stale'),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
    expect(
        fixture.reader.paths
            .where((path) => path == '.pokemap/authoring/history.jsonl'),
        isEmpty);
    expect(fixture.reader.paths.length, lessThan(240));
  });

  test(
      'observed full revisions preserve metadata and camera checks on the selected map',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final created = await fixture.plan('room');
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: created.planId, operationId: 'room');
    for (final (action, parameters) in [
      (
        'map.update_metadata',
        <String, Object?>{'mapId': 'room', 'isIndoor': true}
      ),
      (
        'map3d.camera.configure',
        <String, Object?>{
          'mapId': 'room',
          'camera': SpatialCameraProfile(distance: 60).toJson()
        }
      ),
    ]) {
      final full = await fixture.snapshots.load(fixture.opened.projectHandle);
      final plan = await fixture.api.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: action,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: full.revision,
              idempotencyKey: action,
              parameters: parameters));
      await fixture.api.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: action);
    }
    final full = await fixture.snapshots.load(fixture.opened.projectHandle);
    final path = File('${fixture.root.path}/maps/room.json');
    final map = MapData.fromJson(jsonDecode(await path.readAsString()));
    await path
        .writeAsString(jsonEncode(map.copyWith(name: 'Concurrent').toJson()));
    await expectLater(
        fixture.api.planMutation(
            fixture.opened.projectHandle,
            AuthoringRequest(
                requestId: 'stale-map',
                actionId: 'map.update_metadata',
                actionVersion: 1,
                workspaceHandle: fixture.opened.workspaceHandle.value,
                expectedRevision: full.revision,
                idempotencyKey: 'stale-map',
                parameters: {'mapId': 'room', 'isIndoor': false})),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
  });

  test(
      'observed revision bindings are evicted on close, detach and expiry independently',
      () async {
    var now = DateTime.utc(2026, 10, 27);
    final fixture = await _Fixture.open(0, clock: () => now);
    addTearDown(fixture.close);
    await fixture.snapshots.load(fixture.opened.projectHandle);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: fixture.reader);
    final second = await ProjectOpenService(
        policy: policy,
        fileReader: fixture.reader,
        handles: fixture.handles,
        catalogMetadataFields: {}).openProject(fixture.root.path);
    await fixture.snapshots.load(second.projectHandle);
    expect(fixture.snapshots.retainedCatalogRevisionCount, 2);
    fixture.handles.closeWorkspace(second.workspaceHandle);
    expect(fixture.snapshots.retainedCatalogRevisionCount, 1);
    await expectLater(
        fixture.snapshots.acceptsObservedCatalogRevision(second.projectHandle,
            expectedRevision: null, rootRevision: ''),
        throwsA(isA<WorkspaceHandleException>()));
    await fixture.api.detachWorkspace(fixture.opened.workspaceHandle);
    expect(fixture.snapshots.retainedCatalogRevisionCount, 0);
    await fixture.snapshots.load(fixture.opened.projectHandle);
    expect(fixture.snapshots.retainedCatalogRevisionCount, 1);
    now = now.add(const Duration(hours: 3));
    await expectLater(
        fixture.snapshots.acceptsObservedCatalogRevision(
            fixture.opened.projectHandle,
            expectedRevision: null,
            rootRevision: ''),
        throwsA(isA<WorkspaceHandleException>().having(
            (error) => error.code, 'code', 'workspace.handle_expired')));
    expect(fixture.snapshots.retainedCatalogRevisionCount, 0);
  });

  test('map metadata and camera edits persist without reading foreign maps',
      () async {
    final fixture = await _Fixture.open(80, foreignNewGame: true);
    addTearDown(fixture.close);
    final creation = await fixture.plan('interior');
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: creation.planId, operationId: 'interior');
    final camera = SpatialCameraProfile(distance: 60);
    final actions = [
      (
        'map.update_metadata',
        <String, Object?>{
          'mapId': 'interior',
          'name': 'Interior',
          'role': 'interior',
          'isIndoor': true
        }
      ),
      (
        'map3d.camera.configure',
        <String, Object?>{'mapId': 'interior', 'camera': camera.toJson()}
      ),
    ];
    fixture.reader.paths.clear();
    for (final (action, parameters) in actions) {
      fixture.reader.paths.clear();
      fixture.reader.probes.clear();
      final beforeObjects =
          await Directory('${fixture.root.path}/catalog/objects').list().length;
      final selected = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      final plan = await fixture.api.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: action,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: selected.revision,
              idempotencyKey: action,
              parameters: parameters));
      expect(plan.plan.changeSet.changes.length, 2);
      await fixture.api.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: action);
      expect(fixture.reader.paths.length, lessThan(170));
      expect(fixture.reader.probes.length, lessThan(130));
      final afterObjects =
          await Directory('${fixture.root.path}/catalog/objects').list().length;
      expect(afterObjects - beforeObjects, lessThan(30));
      expect(
          fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
    }
    await fixture.reopen();
    final bytes =
        await File('${fixture.root.path}/maps/interior.json').readAsString();
    final map = MapData.fromJson(jsonDecode(bytes) as Map<String, dynamic>);
    expect(map.name, 'Interior');
    expect(map.mapMetadata.isIndoor, isTrue);
    expect(map.spatialScene!.camera, camera);
    final selected = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'map.update_metadata',
        parameters: {'mapId': 'interior', 'isIndoor': false});
    expect(selected.manifest.maps.single.role, MapRole.interior);
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
  });

  for (final unrelated in [0, 80]) {
    test('map creation stays local with $unrelated unrelated maps and assets',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final timings = <int>[];
      final reads = <int>[];
      for (var attempt = 0; attempt < 2; attempt++) {
        fixture.reader.paths.clear();
        fixture.reader.probes.clear();
        final beforeObjects =
            await Directory('${fixture.root.path}/catalog/objects')
                .list()
                .length;
        final timer = Stopwatch()..start();
        final plan = await fixture.plan('created-$attempt');
        expect(
            plan.plan.changeSet.changes
                .map((change) => change.storageKey)
                .toSet(),
            {'catalog/HEAD.json', 'maps/created-$attempt.json'});
        final result = await fixture.api.applyMutation(
            fixture.opened.projectHandle,
            planId: plan.planId,
            operationId: 'create-$attempt');
        timer.stop();
        timings.add(timer.elapsedMilliseconds);
        reads.add(fixture.reader.paths.length);
        expect(fixture.reader.paths.length, lessThan(160));
        expect(fixture.reader.probes.length, lessThan(120));
        final afterObjects =
            await Directory('${fixture.root.path}/catalog/objects')
                .list()
                .length;
        expect(afterObjects - beforeObjects, lessThan(30));
        expect(fixture.reader.paths.where(fixture.unrelatedPaths.contains),
            isEmpty);
        final map = MapData.fromJson(jsonDecode(
            await File('${fixture.root.path}/maps/created-$attempt.json')
                .readAsString()) as Map<String, dynamic>);
        expect(map.id, 'created-$attempt');
        expect(map.spatialScene, isNotNull);
        expect(map.size, const GridSize(width: 64, height: 32));
        final replay = await fixture.api.applyMutation(
            fixture.opened.projectHandle,
            planId: plan.planId,
            operationId: 'create-$attempt');
        expect(replay.receipt.receiptId, result.receipt.receiptId);
      }
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.reopen();
      final duplicate = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'map.create',
          parameters: _parameters('created-1'));
      expect(duplicate.manifest.maps.map((map) => map.id), ['created-1']);
      await expectLater(
          fixture.plan('created-1'), throwsA(isA<MapAuthoringException>()));
      print(jsonEncode({
        'unrelated': unrelated,
        'reads': reads,
        'firstRepeatedMs': timings
      }));
    });
  }
  test(
      'map creation checks missing-file ownership and portable path collisions',
      () async {
    final fixture = await _Fixture.open(0, extraMaps: const [
      ProjectMapEntry(
          id: 'owner', name: 'Owner', relativePath: 'maps/TARGET.json'),
    ]);
    addTearDown(fixture.close);
    final head = await fixture.store.readHead();
    await expectLater(
        fixture.plan('target'),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', 'map.path_conflict')));
    expect(await fixture.store.readHead(), head);
    expect(
        await File('${fixture.root.path}/maps/target.json').exists(), isFalse);
  });

  test('map creation rejects an orphan file without replacing its bytes',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final file = File('${fixture.root.path}/maps/orphan.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('preserve orphan');
    final head = await fixture.store.readHead();
    await expectLater(() async {
      final plan = await fixture.plan('orphan');
      await fixture.api.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: 'orphan');
    }(), throwsA(anything));
    expect(await file.readAsString(), 'preserve orphan');
    expect(await fixture.store.readHead(), head);
  });

  test('map creation rejects a stale catalog plan without losing another map',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final first = await fixture.plan('first');
    final second = await fixture.plan('second');
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: second.planId, operationId: 'second');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: first.planId, operationId: 'first'),
        throwsA(anything));
    expect(
        await File('${fixture.root.path}/maps/first.json').exists(), isFalse);
    expect(
        await File('${fixture.root.path}/maps/second.json').exists(), isTrue);
  });

  test('map creation undo removes both map and metadata after reopening',
      () async {
    final fixture = await _Fixture.open(80);
    addTearDown(fixture.close);
    final plan = await fixture.plan('undoable');
    final created = await fixture.api.applyMutation(
        fixture.opened.projectHandle,
        planId: plan.planId,
        operationId: 'undoable');
    await fixture.reopen();
    fixture.reader.paths.clear();
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: created.receipt.receiptId, idempotencyKey: 'undo-map');
    expect(await File('${fixture.root.path}/maps/undoable.json').exists(),
        isFalse);
    final selection = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'map.create',
        parameters: _parameters('undoable'));
    expect(selection.manifest.maps, isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
    final recreated = await fixture.plan('undoable');
    expect(recreated.applicable, isTrue);
  });

  test('map creation recovers a crash after the map document promotion',
      () async {
    var crashed = false;
    final fixture = await _Fixture.open(80, faultInjector: (context) {
      if (!crashed &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.storageKey == 'maps/recovered.json') {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    final plan = await fixture.plan('recovered');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: 'recovered'),
        throwsA(anything));
    expect(crashed, isTrue);
    await fixture.api.recoverMutation(fixture.opened.projectHandle,
        operationId: 'recovered');
    final selection = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'map.create',
        parameters: _parameters('recovered'));
    expect(selection.manifest.maps.single.id, 'recovered');
    expect(await File('${fixture.root.path}/maps/recovered.json').exists(),
        isTrue);
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
  });

  test('old ownership index requires explicit preparation of map metadata only',
      () async {
    final fixture = await _Fixture.open(80, legacyOwnership: true);
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    await expectLater(
        fixture.plan('prepared'),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('map_ownership_preparation_required'))));
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
    await fixture.api.prepareWorkshopDocument(fixture.opened.projectHandle,
        scope: 'mapCreation');
    expect(
        fixture.reader.paths.where(fixture.unrelatedPaths.contains), isEmpty);
    final plan = await fixture.plan('prepared');
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'prepared');
    expect(
        await File('${fixture.root.path}/maps/prepared.json').exists(), isTrue);
  });
}

Map<String, Object?> _parameters(String id) => {
      'mapId': id,
      'name': 'Created map',
      'width': 64,
      'height': 32,
      'role': 'exterior',
    };

final class _Fixture {
  _Fixture(this.root, this.store, this.opened, this.handles, this.api,
      this.reader, this.unrelatedPaths, this.descriptor, this.snapshots);
  final Directory root;
  final CatalogStorageStore store;
  OpenedProject opened;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  ProjectSnapshotLoader snapshots;
  final _CountingReader reader;
  final Set<String> unrelatedPaths;
  final List<int> descriptor;

  static Future<_Fixture> open(
    int unrelated, {
    List<ProjectMapEntry> extraMaps = const [],
    AuthoringTransactionFaultInjector? faultInjector,
    bool legacyOwnership = false,
    bool foreignNewGame = false,
    DateTime Function()? clock,
  }) async {
    final root = Directory(
        '/Users/karim/Library/Caches/AveluneQA/hgss-mauville-maps/api/fixture');
    await root.create(recursive: true);
    final project = ProjectManifest(
      name: 'Map creation',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
          defaultPlayerCharacterId: foreignNewGame ? 'foreign-avatar' : null),
      newGame: foreignNewGame
          ? const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'foreign-0',
              initialFacts: {'foreign-fact': true},
              playerAvatarCharacterIds: ['foreign-avatar'])
          : const ProjectNewGameConfig(),
      maps: [
        ...extraMaps,
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
              id: 'foreign-$i',
              name: 'Foreign $i',
              relativePath: 'maps/foreign-$i.json')
      ],
      tilesets: [
        for (var i = 0; i < unrelated; i++)
          ProjectTilesetEntry(
              id: 'foreign-$i',
              name: 'Foreign $i',
              relativePath: 'assets/foreign-$i.png')
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'map-creation', project: project);
    if (legacyOwnership) {
      final key = CatalogMetadataDocuments.fieldKey('maps');
      final state = (await working.catalog.snapshot.lookup(key))!;
      final patch = await working.catalog.snapshot.patch(upserts: [
        CatalogDefinitionUnit(
            key: key,
            payload: {...state.payload}..remove('mapOwnershipVersion')),
      ], removals: [
        for (final map in project.maps) ...[
          CatalogMetadataDocuments.mapOwnershipKey('id', map.id),
          CatalogMetadataDocuments.mapOwnershipKey('path', map.relativePath),
        ]
      ]);
      await store.gateway.withExclusiveWriteLock(() async {
        await store.publishObjectsUnderLock(patch.objects);
        await File('${root.path}/catalog/HEAD.json')
            .writeAsBytes(CatalogStorageStore.encodeHead(patch.root));
        final snapshot = await patch.nextSnapshot(readObject: store.readObject);
        await store.publishIndexAdmissionUnderLock(snapshot);
        await store.publishMetadataIndexAdmissionUnderLock(snapshot);
      });
    }
    final unrelatedPaths = <String>{};
    if (foreignNewGame) {
      for (final field in ['newGame', 'pokemon']) {
        final key = CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
            jsonEncode(['projectAggregateHeader', field]));
        final entry = await working.catalog.snapshot.indexEntry(key);
        if (entry == null) continue;
        final path = 'catalog/objects/${entry.reference.sha256}.json';
        unrelatedPaths.add(path);
        await File('${root.path}/$path')
            .writeAsString('unrelated gameplay aggregate must remain unread');
      }
    }
    for (var i = 0; i < unrelated; i++) {
      final mapPath = 'maps/foreign-$i.json';
      unrelatedPaths.add(mapPath);
      final file = File('${root.path}/$mapPath');
      await file.parent.create(recursive: true);
      await file.writeAsString('foreign map must remain unread');
      for (final key in [
        if (!legacyOwnership)
          CatalogMetadataDocuments.definitionKey('maps', i + extraMaps.length),
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'foreign-$i')
      ]) {
        final entry = (await working.catalog.snapshot.indexEntry(key))!;
        final path = 'catalog/objects/${entry.reference.sha256}.json';
        unrelatedPaths.add(path);
        await File('${root.path}/$path')
            .writeAsString('foreign definition must remain unread');
      }
    }
    final descriptor = await File('${root.path}/project.json').readAsBytes();
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore(clock: clock);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        faultInjector: faultInjector,
        snapshotLoader: snapshots,
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString('foreign old history must remain unread\n' *
        (unrelated == 0 ? 100 : 10000));
    return _Fixture(root, store, opened, handles, api, reader, unrelatedPaths,
        descriptor, snapshots);
  }

  Future<AuthoringMutationPlanResult> plan(String id) async {
    final parameters = _parameters(id);
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: 'map.create', parameters: parameters);
    return api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'plan-$id',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'plan-$id',
            parameters: parameters));
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
    snapshots = ProjectSnapshotLoader(handles: handles);
    api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, catalogFileReader: reader);
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
  final probes = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource(
      {required String projectRoot, required String relativePath}) {
    probes.add(relativePath);
    return delegate.probeResource(
        projectRoot: projectRoot, relativePath: relativePath);
  }

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
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
