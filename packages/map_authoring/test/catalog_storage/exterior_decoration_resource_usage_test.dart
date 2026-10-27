import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/references/exterior_decoration_references.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/exterior_decoration_fixture.dart';

void main() {
  late Directory root;
  late LocalMapExteriorDecorationAuthoring service;
  late CatalogStorageStore store;
  late CatalogEditingSession session;
  late ProjectManifest fixtureProject;
  final model = CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'oak');
  setUp(() async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring');
    await base.create(recursive: true);
    root = await base.createTemp('usage_');
    store = await CatalogStorageStore.open(projectRoot: root.path);
    final project = fixtureProject =
        exteriorDecorationFixtureProject().copyWith(maps: const [
      ProjectMapEntry(
          id: 'route', name: 'Route', relativePath: 'maps/route.json'),
      ProjectMapEntry(
          id: 'other', name: 'Other', relativePath: 'maps/other.json'),
    ]);
    await WorkingProjectCatalog.create(
        store: store, projectId: 'usage', project: project);
    await FileIdempotencyStore(
            filePath: '${root.path}/.pokemap/authoring/idempotency.jsonl')
        .prepareIncrementalStorage();
    service = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()));
    for (final id in ['route', 'other']) {
      final file = File('${root.path}/maps/$id.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(MapData(
              id: id,
              name: id,
              version: ProjectVersion.v9,
              size: const GridSize(width: 16, height: 16),
              spatialScene: MapSpatialScene(width: 16, depth: 16))
          .toJson()));
      await service.configure(
          projectRoot: root.path,
          mapId: id,
          expectedRevision:
              (await service.inspect(projectRoot: root.path, mapId: id))
                  .revision,
          decoration: MapExteriorDecoration(
              mapId: id, playableWidth: 16, playableDepth: 16, west: 16),
          operationId: 'configure_$id');
    }
    session = await CatalogEditingSession.open(
        store: store,
        projectId: 'usage',
        actorId: 'author',
        incrementalHistory: true);
  });
  tearDown(() async {
    await session.close();
    await root.delete(recursive: true);
  });
  ExteriorDecorationSector sector({double x = 2}) => ExteriorDecorationSector(
      id: 'west',
      originX: -16,
      originZ: 0,
      scene: MapSpatialScene(width: 16, depth: 16, instances: [
        SpatialModelInstance(
            id: 'outside',
            modelId: 'oak',
            position: Model3dVector3(x: x, y: 0, z: 2))
      ]));
  Future<MapExteriorDecorationMutation> place(String id, String op,
          {double x = 2}) async =>
      service.setSector(
          projectRoot: root.path,
          mapId: id,
          expectedRevision:
              (await service.inspect(projectRoot: root.path, mapId: id))
                  .revision,
          sector: sector(x: x),
          operationId: op);
  test(
      'two maps sharing one model retain the other owner through undo and redo',
      () async {
    await place('other', 'second');
    final first = await place('route', 'first');
    expect(
        decodeExteriorReferenceOwners(
                await store.gateway
                    .readResource(exteriorReferenceIndexPath(model)),
                model)
            .length,
        2);
    final undone = await service.undo(
        projectRoot: root.path,
        mapId: 'route',
        mutation: first,
        operationId: 'undo');
    expect(
        decodeExteriorReferenceOwners(
                await store.gateway
                    .readResource(exteriorReferenceIndexPath(model)),
                model)
            .keys,
        ['other:sector:west']);
    await service.redoReceipt(
        projectRoot: root.path,
        mapId: 'route',
        receiptId: first.receipt.receiptId,
        expectedRevision: undone.afterRevision,
        operationId: 'redo');
    expect(
        decodeExteriorReferenceOwners(
                await store.gateway
                    .readResource(exteriorReferenceIndexPath(model)),
                model)
            .length,
        2);
  });
  test('deleting an exterior-only model is refused before catalog publication',
      () async {
    await place('route', 'first');
    final head = await File('${root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(
        session.planPatch(
            upserts: const [], removals: [model], idempotencyKey: 'delete'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('exterior.resource_in_use'))));
    expect(await File('${root.path}/catalog/HEAD.json').readAsBytes(), head);
  });
  test('deleting an unused definition stays possible', () async {
    await place('route', 'first');
    final key = CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'unused');
    await session.apply(await session.planPatch(upserts: [
      CatalogDefinitionUnit(key: key, payload: {'id': 'unused'})
    ], idempotencyKey: 'unused-add'));
    await session.apply(await session.planPatch(
        upserts: const [], removals: [key], idempotencyKey: 'unused-delete'));
    expect(await session.snapshot.lookup(key), isNull);
  });
  test('an alpha map requires explicit targeted reference preparation',
      () async {
    await place('route', 'first');
    await File('${root.path}/${exteriorReferenceAdmissionPath('route')}')
        .delete();
    final reopened = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()));
    final before =
        await reopened.inspect(projectRoot: root.path, mapId: 'route');
    await expectLater(
        reopened.setSector(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: before.revision,
            sector: sector(x: 3),
            operationId: 'blocked'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('reference_index_recovery_required'))));
    await reopened.prepareIncomingReferences(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: before.revision,
        operationId: 'prepare');
    await reopened.setSector(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: before.revision,
        sector: sector(x: 3),
        operationId: 'allowed');
  });
  test(
      'JSONL prepares alpha references explicitly and reports their saved usages',
      () async {
    await place('route', 'first');
    await File('${root.path}/${exteriorReferenceAdmissionPath('route')}')
        .delete();
    await File('${root.path}/${exteriorReferenceIndexPath(model)}').delete();
    final assets = File('${root.path}/$assetCatalogStorageKey');
    await assets.parent.create(recursive: true);
    await assets.writeAsString(jsonEncode(AssetCatalog(records: [
      for (final item in fixtureProject.models3d)
        AssetRecord(
            id: item.sourceAssetId,
            logicalPath: item.relativePath,
            artifact: ContentArtifactRef.fromBytes([1],
                mediaType: 'model/gltf-binary')),
    ]).toJson()));
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: const LocalProjectFileReader(),
                handles: handles),
            snapshotLoader: loader),
        mapExteriorDecoration:
            LocalMapExteriorDecorationAuthoring(policy: policy));
    addTearDown(worker.close);
    var sequence = 0;
    Future<Map<String, dynamic>> call(
        String command, Map<String, Object?> args) async {
      final response = jsonDecode(await worker.processLine(jsonEncode(
              {'id': 'usage-${sequence++}', 'command': command, 'args': args})))
          as Map<String, dynamic>;
      expect(response['status'], 'success', reason: jsonEncode(response));
      return response['data'] as Map<String, dynamic>;
    }

    final state = await service.inspect(projectRoot: root.path, mapId: 'route');
    final prepared = await call('map_exterior_decoration_references_prepare', {
      'projectRoot': root.path,
      'mapId': 'route',
      'expectedRevision': state.revision,
      'operationId': 'jsonl-prepare'
    });
    expect(prepared['afterRevision'], state.revision);
    final opened = await call('open', {'projectRoot': root.path});
    final result = await call('query', {
      'projectHandle': opened['projectHandle'],
      'request': AuthoringQueryRequest(
          resourceKind: 'resourceUsage',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: const ['models3d:oak']).toJson()
    });
    final report = (result['items'] as List).single as Map;
    expect(
        (report['entries'] as List)
            .any((entry) => entry['entityId'] == 'exterior:sector:west'),
        isTrue);
    expect(
        (report['fingerprints'] as Map)
            .keys
            .any((key) => '$key'.startsWith('exteriorReference:')),
        isTrue);
  });
  test(
      'preparing an admitted map is durable and idempotent without changing content',
      () async {
    final placed = await place('route', 'tree');
    final before =
        await File('${root.path}/maps/route.decoration.json').readAsBytes();
    final prepared = await service.prepareIncomingReferences(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: placed.afterRevision,
        operationId: 'already-admitted');
    final replay = await service.prepareIncomingReferences(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: placed.afterRevision,
        operationId: 'already-admitted');
    expect(prepared.receipt.toJson(), replay.receipt.toJson());
    expect(prepared.afterRevision, placed.afterRevision);
    expect(await File('${root.path}/maps/route.decoration.json').readAsBytes(),
        before);
    await service.undo(
        projectRoot: root.path,
        mapId: 'route',
        mutation: placed,
        operationId: 'undo-after-prepare');
  });
  test(
      'missing known incoming index refuses deletion and targeted repair preserves other maps',
      () async {
    await place('other', 'second');
    await place('route', 'first');
    await File('${root.path}/${exteriorReferenceIndexPath(model)}').delete();
    await expectLater(
        session.planPatch(
            upserts: const [],
            removals: [model],
            idempotencyKey: 'corrupt-delete'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('reference_index_recovery_required'))));
    await service.prepareIncomingReferences(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision:
            (await service.inspect(projectRoot: root.path, mapId: 'route'))
                .revision,
        operationId: 'repair-known-index');
    final owners = decodeExteriorReferenceOwners(
        await store.gateway.readResource(exteriorReferenceIndexPath(model)),
        model);
    expect(owners.keys,
        unorderedEquals(['route:sector:west', 'other:sector:west']));
  });
  test('usage projection reads only the incoming key and declared owners',
      () async {
    await place('route', 'first');
    final paths = <String>[];
    final report = await projectExteriorReferenceUsages(
        ResourceUsageReport(
            target: const ResourceUsageTarget(family: 'models3d', id: 'oak'),
            revision: 'sha256:${'1' * 64}',
            fingerprints: const {},
            entries: const [],
            coverageIssues: const []), (path, maximumBytes) async {
      paths.add(path);
      return store.gateway.readResource(path);
    });
    expect(report.complete, isTrue);
    expect(report.entries.single.mapId, 'route');
    expect(report.entries.single.entityId, 'exterior:sector:west');
    expect(report.entries.single.location, contains('sector:west'));
    expect(paths,
        [exteriorReferenceIndexPath(model), 'maps/route.decoration/west.json']);
    expect(report.fingerprints.keys.single, startsWith('exteriorReference:'));
  });
  test('a native exterior material blocks direct catalog removal', () async {
    await service.setSector(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision:
            (await service.inspect(projectRoot: root.path, mapId: 'route'))
                .revision,
        sector: ExteriorDecorationSector(
            id: 'west',
            originX: -16,
            originZ: 0,
            scene: MapSpatialScene(width: 16, depth: 16)),
        operationId: 'empty');
    await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision:
            (await service.inspect(projectRoot: root.path, mapId: 'route'))
                .revision,
        expectedCatalogRevision: await service.inspectNativeCatalogRevision(
            projectRoot: root.path, mapId: 'route'),
        operationId: 'ground',
        edit: {
          'kind': 'terrain.paint',
          'sectorId': 'west',
          'presetId': 'grass',
          'cells': [
            {'x': -2, 'z': 2}
          ]
        });
    final key =
        CatalogDefinitionKey(CatalogDefinitionKind.smartTileMaterial, 'grass');
    await expectLater(
        session.planPatch(
            upserts: const [],
            removals: [key],
            idempotencyKey: 'remove-material'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('exterior.resource_in_use'))));
  });
  test(
      'moving a model with identical references performs zero reference-index IO',
      () async {
    await place('route', 'first');
    service = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()));
    await service.inspect(projectRoot: root.path, mapId: 'route');
    final denied = <String>[];
    final parent = Zone.current;
    await IOOverrides.runZoned(() => place('route', 'move', x: 3),
        createFile: (path) {
      final file = parent.run(() => File(path));
      return path.contains('/authoring/exterior-decoration/references/') ||
              path.contains('/authoring/exterior-decoration/owners/')
          ? _NoReferenceIO(file, denied)
          : file;
    });
    expect(denied, isEmpty);
  });
  test('a model added outside after deletion planning blocks apply', () async {
    final planned = await session.planPatch(
        upserts: const [], removals: [model], idempotencyKey: 'race');
    await place('route', 'late-owner');
    final before = await File('${root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(
        session.apply(planned),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('exterior.resource_in_use'))));
    expect(await File('${root.path}/catalog/HEAD.json').readAsBytes(), before);
  });
  test(
      'crashed reference promotion blocks other writers and retry preserves owners',
      () async {
    await place('other', 'other-owner');
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    var failed = false;
    final crashing = LocalMapExteriorDecorationAuthoring(
        policy: policy,
        faultInjector: (point) {
          if (!failed &&
              point.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              point.storageKey == exteriorReferenceIndexPath(model)) {
            failed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    final revision =
        (await service.inspect(projectRoot: root.path, mapId: 'route'))
            .revision;
    await expectLater(
        crashing.setSector(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: revision,
            sector: sector(),
            operationId: 'crash'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await expectLater(
        place('other', 'during-crash', x: 3), throwsA(isA<FormatException>()));
    final reopened = LocalMapExteriorDecorationAuthoring(policy: policy);
    await reopened.setSector(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        sector: sector(),
        operationId: 'crash');
    final owners = decodeExteriorReferenceOwners(
        await store.gateway.readResource(exteriorReferenceIndexPath(model)),
        model);
    expect(owners.keys,
        unorderedEquals(['route:sector:west', 'other:sector:west']));
    await place('other', 'after-recovery', x: 3);
  });
}

final class _NoReferenceIO implements File {
  _NoReferenceIO(this.file, this.denied);
  final File file;
  final List<String> denied;
  Never fail() {
    denied.add(file.path);
    throw StateError('Unexpected reference IO: ${file.path}');
  }

  @override
  String get path => file.path;
  @override
  Future<Uint8List> readAsBytes() async => fail();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => fail();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      fail();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => fail();
  @override
  Future<bool> exists() async => fail();
  @override
  Future<FileStat> stat() async => fail();
  @override
  Future<String> resolveSymbolicLinks() async => fail();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
