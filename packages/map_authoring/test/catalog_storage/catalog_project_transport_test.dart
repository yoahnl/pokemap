import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('classified catalogue queries scan indexes without per-resource rereads',
      () async {
    final root = await Directory.systemTemp.createTemp('catalog-classified-');
    addTearDown(() => root.delete(recursive: true));
    String id(int index) => 'tile-${index.toString().padLeft(3, '0')}';
    final project = ProjectManifest(
      name: 'Classified library',
      maps: const [],
      tilesets: [
        for (var index = 0; index < 400; index++)
          ProjectTilesetEntry(
            id: id(index),
            name: 'Image $index',
            relativePath: 'assets/image.png',
          ),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
        for (var index = 0; index < 400; index++)
          if (index % 3 != 0)
            ResourceLibraryEntry(
              resourceKind: 'tileset',
              resourceId: id(index),
              description: index.isEven ? 'Chambre $index' : 'Jardin $index',
              placementContext: index.isEven
                  ? ResourcePlacementContext.interior
                  : ResourcePlacementContext.exterior,
            ),
      ]),
    );
    final publication = PortableCatalogPublication.encodeProject(project);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await store.publish(publication.storage, expectedRootRevision: null);
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      WorkingProjectCatalogDescriptor(projectId: 'classified').toJson(),
    ));
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    final opened = await api.openProject(root.path);
    addTearDown(() => api.closeWorkspace(opened.workspaceHandle));
    final indexPaths = <String>{};
    final definitionPaths = <String>{};
    for (final object in publication.storage.objects.entries) {
      final json = jsonDecode(utf8.decode(object.value)) as Map;
      final path = 'catalog/objects/${object.key}.json';
      if (const {'root', 'branch', 'leaf'}.contains(json['type'])) {
        indexPaths.add(path);
      }
      if ((json['key'] as Map?)?['kind'] == 'tileset') {
        definitionPaths.add(path);
      }
    }
    final request = AuthoringQueryRequest(
      resourceKind: 'tileset',
      operation: AuthoringQueryOperation.search,
      searchTerm: 'Chambre',
      filters: const {'placementContext': 'interior'},
      pageSize: 20,
    );
    reader.paths.clear();
    final first = await api.queryProject(opened.projectHandle, request);
    expect(first.totalAvailable, 133);
    expect(first.items.first['id'], 'tile-002');
    expect(first.items.first['description'], 'Chambre 2');
    expect(first.items.every((row) => row['placementContext'] == 'interior'),
        isTrue);
    expect(reader.paths.where(definitionPaths.contains), isEmpty);
    expect(reader.paths.where(indexPaths.contains).length,
        lessThan(indexPaths.length * 16));
    final worker = JsonlWorker(api: api);
    final response = await _command(worker, 'query', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson(),
    });
    expect(response, first.toJson());
    final second = await api.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'tileset',
        operation: AuthoringQueryOperation.search,
        searchTerm: 'Chambre',
        filters: const {'placementContext': 'interior'},
        pageSize: 20,
        cursor: first.nextCursor,
      ),
    );
    expect(second.totalAvailable, 133);
    expect(second.items, hasLength(20));
    expect(
        second.items
            .map((row) => row['id'])
            .toSet()
            .intersection(first.items.map((row) => row['id']).toSet()),
        isEmpty);
    final direct = await api.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'tileset',
        operation: AuthoringQueryOperation.batchGet,
        ids: const ['tile-398', 'tile-000', 'tile-002'],
      ),
    );
    expect(direct.items.map((row) => row['id']),
        ['tile-000', 'tile-002', 'tile-398']);
    expect(direct.items.first['description'], isNull);
    expect(direct.items.last['description'], 'Chambre 398');
    final loader = ProjectSnapshotLoader(handles: handles);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
    final before = await loader.load(opened.projectHandle);
    reader.paths.clear();
    final planned = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'create-classified-map',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: 'create-classified-map',
            parameters: const {
              'mapId': 'garden',
              'name': 'Garden',
              'width': 8,
              'height': 6,
            }));
    expect(planned.plan.changeSet.changes.map((change) => change.storageKey),
        containsAll(['catalog/HEAD.json', 'maps/garden.json']));
  });

  test(
      'API and JSONL query working catalog pages without decoding all definitions',
      () async {
    final root = await Directory.systemTemp.createTemp('catalog-transport-');
    addTearDown(() => root.delete(recursive: true));
    final project = ProjectManifest(
        name: 'Large library',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: [
          for (var i = 0; i < 260; i++)
            ProjectTilesetEntry(
                id: 'tile-$i',
                name: 'Object $i',
                relativePath: 'assets/object.png'),
        ]);
    final publication = PortableCatalogPublication.encodeProject(project);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await store.publish(publication.storage, expectedRootRevision: null);
    await File('${root.path}/project.json').writeAsString(jsonEncode({
      'format': 'avelune.working-catalog',
      'version': 1,
      'kind': 'project',
      'projectId': 'test-project'
    }));
    final handles = WorkspaceHandleStore();
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final worker = JsonlWorker(api: api);
    final opened = await api.openProject(root.path);
    final unitPaths = {
      for (final entry in publication.storage.objects.entries)
        if ((jsonDecode(utf8.decode(entry.value)) as Map)['key']
            case {'kind': 'tileset'})
          'catalog/objects/${entry.key}.json'
    };
    reader.paths.clear();
    final fullRequest = AuthoringQueryRequest(
        resourceKind: 'project',
        operation: AuthoringQueryOperation.get,
        ids: const ['project'],
        view: AuthoringQueryView.detail);
    await expectLater(
        api.queryProject(opened.projectHandle, fullRequest),
        throwsA(isA<AuthoringQueryException>().having(
            (error) => error.code, 'code', 'query.materialization_required')));
    expect(reader.paths.where(unitPaths.contains), isEmpty);
    final deniedFull = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'full',
      'command': 'query',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'request': fullRequest.toJson()
      }
    }))) as Map;
    expect(((deniedFull['error'] as Map)['details'] as Map)['domainCode'],
        'query.materialization_required');
    expect(reader.paths.where(unitPaths.contains), isEmpty);
    final first = await api.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.list,
            pageSize: 200));
    expect(reader.paths.where(unitPaths.contains), isEmpty);
    expect(first.returned, 200);
    expect(first.totalAvailable, 260);
    final request = AuthoringQueryRequest(
        resourceKind: 'tileset',
        operation: AuthoringQueryOperation.list,
        pageSize: 200,
        cursor: first.nextCursor);
    final direct = await api.queryProject(opened.projectHandle, request);
    final response = jsonDecode(await worker.processLine(jsonEncode({
      'id': 'page',
      'command': 'query',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'request': request.toJson()
      }
    }))) as Map;
    expect(response['data'], direct.toJson());
    expect(direct.returned, 60);
    expect(direct.nextCursor, isNull);
    reader.paths.clear();
    final detail = await api.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.get,
            ids: const ['tile-259'],
            view: AuthoringQueryView.detail));
    expect(reader.paths.where(unitPaths.contains).toSet(), hasLength(1));
    expect(detail.items.single['name'], 'Object 259');
    expect(detail.items.single['definition'], containsPair('id', 'tile-259'));
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final beforeDescriptor =
        await File('${root.path}/project.json').readAsBytes();
    final planned = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'edit',
            actionId: 'catalog.definition.update',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: detail.snapshotRevision,
            idempotencyKey: 'edit',
            parameters: {
              'resourceKind': 'tileset',
              'id': 'tile-259',
              'name': 'Renamed object',
              'description': 'A quiet tree',
              'placementContext': 'exterior'
            }));
    final applied = await mutations.applyMutation(opened.projectHandle,
        planId: planned.planId, operationId: 'catalog-edit');
    expect(applied.receipt.actionId, 'catalog.definition.update');
    expect(
        (await mutations.applyMutation(opened.projectHandle,
                planId: planned.planId, operationId: 'catalog-edit'))
            .receipt
            .toJson(),
        applied.receipt.toJson());
    expect(await File('${root.path}/project.json').readAsBytes(),
        beforeDescriptor);
    await expectLater(
        api.queryProject(opened.projectHandle, request),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_stale')));
    final found = await api.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.search,
            searchTerm: 'quiet tree',
            filters: const {'placementContext': 'exterior'}));
    expect(found.items.single['name'], 'Renamed object');
    expect(found.items.single['description'], 'A quiet tree');
    expect(found.items.single['placementContext'], 'exterior');
    expect(found.totalAvailable, 1);
    final exported = await (await WorkingProjectCatalog.open(
            store: store,
            descriptor:
                WorkingProjectCatalogDescriptor(projectId: 'test-project')))
        .exportProject();
    expect(
        exported.tilesets.singleWhere((entry) => entry.id == 'tile-259').name,
        'Renamed object');
    expect(exported.resourceLibraryCatalog.entries.single.description,
        'A quiet tree');
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
  });
  test('catalog metadata masks and rejected cursors never decode definitions',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.close);
    final first = await f.api.queryProject(
        f.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.list,
            pageSize: 1));
    f.reader.paths.clear();
    await f.api.queryProject(
        f.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['b'],
            fieldMask: const ['id', 'name', 'revision']));
    expect(f.reader.paths.where(f.unitPaths.contains), isEmpty);
    await expectLater(
        f.api.queryProject(
            f.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'tileset',
                operation: AuthoringQueryOperation.search,
                searchTerm: 'a',
                pageSize: 1,
                cursor: first.nextCursor)),
        throwsA(isA<AuthoringQueryException>()
            .having((e) => e.code, 'code', 'query.cursor_mismatch')));
    for (final cursor in [
      'not-a-cursor',
      base64Url.encode(utf8.encode(
          '{"version":1,"version":1,"revision":"${first.snapshotRevision}","signature":"x","offset":0}'))
    ]) {
      await expectLater(
          f.api.queryProject(
              f.opened.projectHandle,
              AuthoringQueryRequest(
                  resourceKind: 'tileset',
                  operation: AuthoringQueryOperation.list,
                  cursor: cursor)),
          throwsA(isA<AuthoringQueryException>()
              .having((e) => e.code, 'code', 'query.cursor_invalid')));
    }
    await expectLater(
        f.api.queryProject(
            f.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'tileset',
                operation: AuthoringQueryOperation.list,
                sort: const [AuthoringQuerySort(field: 'name')])),
        throwsA(isA<AuthoringQueryException>()
            .having((e) => e.code, 'code', 'query.catalog_sort_unsupported')));
    await expectLater(
        f.api.queryProject(
            f.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'tileset',
                operation: AuthoringQueryOperation.list,
                filters: const {'definition.relativePath': 'secret'})),
        throwsA(isA<AuthoringQueryException>().having(
            (e) => e.code, 'code', 'query.catalog_filter_unsupported')));
  });

  test(
      'portable publications stay read only and permission denial precedes editing admission',
      () async {
    for (final portable in [false, true]) {
      final f = await _Fixture.create(
          portable: portable, actor: AuthoringActor(actorId: 'reader'));
      try {
        final before = await f.inventory();
        await f.api.queryProject(
            f.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'tileset',
                operation: AuthoringQueryOperation.list));
        await expectLater(
            f.mutations
                .planMutation(f.opened.projectHandle, f.request('blocked')),
            throwsA(isA<AuthoringAuthorizationException>()));
        expect(await f.inventory(), before);
      } finally {
        await f.close();
      }
    }
  });

  test('portable mutation paths reject writes before resolving editing state',
      () async {
    final f = await _Fixture.create(portable: true);
    addTearDown(f.close);
    final before = await f.inventory();
    final denied = throwsA(isA<AuthoringAuthorizationException>()
        .having((error) => error.code, 'code', 'catalog.read_only'));
    await expectLater(
        f.mutations
            .planMutation(f.opened.projectHandle, f.request('portable-write')),
        denied);
    await expectLater(
        f.mutations.applyMutation(f.opened.projectHandle,
            planId: 'unknown-plan', operationId: 'unknown-operation'),
        denied);
    await expectLater(
        f.mutations.undoMutation(f.opened.projectHandle,
            entryId: 'unknown-entry', idempotencyKey: 'unknown-undo'),
        denied);
    expect(await f.inventory(), before);
  });

  test(
      'JSONL edits preserve public actions, stale revisions and history after reopening',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.close);
    final worker = JsonlWorker(api: f.api, mutations: f.mutations);
    final stale = f.request('stale');
    final planned = await f.mutations
        .planMutation(f.opened.projectHandle, f.request('rename'));
    final applied = await f.mutations.applyMutation(f.opened.projectHandle,
        planId: planned.planId, operationId: 'rename-operation');
    await expectLater(
        f.mutations.planMutation(f.opened.projectHandle, stale),
        throwsA(isA<AuthoringPlanException>()
            .having((e) => e.code, 'code', 'plan.stale')));
    final queried = await f.api.queryProject(
        f.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.get,
            ids: const ['b']));
    final request = AuthoringRequest(
        requestId: 'jsonl-edit',
        actionId: 'catalog.definition.update',
        actionVersion: 1,
        workspaceHandle: f.opened.workspaceHandle.value,
        expectedRevision: queried.snapshotRevision,
        idempotencyKey: 'jsonl-edit',
        parameters: const {
          'resourceKind': 'tileset',
          'id': 'b',
          'description': 'new description',
          'placementContext': 'interior'
        });
    final p = await _command(worker, 'plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson()
    });
    final result = await _command(worker, 'apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': p['planId'],
      'operationId': 'jsonl-operation'
    });
    expect((result['receipt'] as Map)['actionId'], 'catalog.definition.update');
    final history = await f.mutations
        .listMutationHistory(f.opened.projectHandle, limit: 10);
    expect(history.entries, hasLength(2));
    final undone = await f.mutations.undoMutation(f.opened.projectHandle,
        entryId: (result['receipt'] as Map)['receiptId'] as String,
        idempotencyKey: 'undo-jsonl');
    expect(undone.snapshotRevision, applied.snapshotRevision);
    await f.mutations.detachWorkspace(f.opened.workspaceHandle);
    await f.api.closeWorkspace(f.opened.workspaceHandle);
    final reopened = await f.api.openProject(f.root.path);
    await f.mutations.attachProject(
        projectRootPath: f.root.path,
        workspaceHandle: reopened.workspaceHandle,
        projectHandle: reopened.projectHandle);
    final after = await f.api.queryProject(
        reopened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'tileset',
            operation: AuthoringQueryOperation.get,
            ids: const ['b']));
    expect(after.items.single['name'], 'Renamed');
    expect(after.items.single['description'], isNull);
    expect(
        (await f.mutations
                .listMutationHistory(reopened.projectHandle, limit: 10))
            .entries,
        hasLength(3));
    await f.mutations.detachWorkspace(reopened.workspaceHandle);
    await f.api.closeWorkspace(reopened.workspaceHandle);
  });
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final delegate = const LocalProjectFileReader();
  final paths = <String>[];
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    if (relativePath.startsWith('catalog/objects/')) {
      throw StateError('Unbounded catalog reads forbidden');
    }
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
}

Future<Map<String, dynamic>> _command(
    JsonlWorker worker, String command, Map<String, Object?> args) async {
  final result = jsonDecode(await worker.processLine(
          jsonEncode({'id': command, 'command': command, 'args': args})))
      as Map<String, dynamic>;
  expect(result['status'], 'success', reason: jsonEncode(result));
  return Map<String, dynamic>.from(result['data'] as Map);
}

final class _Fixture {
  _Fixture(this.root, this.reader, this.api, this.mutations, this.opened,
      this.unitPaths);
  final Directory root;
  final _CountingReader reader;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final OpenedProject opened;
  final Set<String> unitPaths;
  static Future<_Fixture> create(
      {bool portable = false, AuthoringActor? actor}) async {
    final root = await Directory.systemTemp.createTemp('catalog-guards-');
    final project = ProjectManifest(
        name: 'Guarded',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(id: 'a', name: 'First', relativePath: 'a.png'),
          ProjectTilesetEntry(id: 'b', name: 'Second', relativePath: 'b.png')
        ]);
    final publication = PortableCatalogPublication.encodeProject(project);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await store.publish(publication.storage, expectedRootRevision: null);
    await File('${root.path}/project.json').writeAsString(jsonEncode(portable
        ? publication.descriptor
        : WorkingProjectCatalogDescriptor(projectId: 'guards').toJson()));
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: loader, actor: actor);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final paths = {
      for (final entry in publication.storage.objects.entries)
        if ((jsonDecode(utf8.decode(entry.value)) as Map)['key']
            case {'kind': 'tileset'})
          'catalog/objects/${entry.key}.json'
    };
    return _Fixture(root, reader, api, mutations, opened, paths);
  }

  AuthoringRequest request(String key) => AuthoringRequest(
          requestId: key,
          actionId: 'catalog.definition.update',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: opened.fingerprint,
          idempotencyKey: key,
          parameters: const {
            'resourceKind': 'tileset',
            'id': 'b',
            'name': 'Renamed'
          });
  Future<Map<String, String>> inventory() async => {
        for (final entity in await root
            .list(recursive: true)
            .where((e) => e is File)
            .toList())
          entity.path: base64Encode(await File(entity.path).readAsBytes())
      };
  Future<void> close() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
