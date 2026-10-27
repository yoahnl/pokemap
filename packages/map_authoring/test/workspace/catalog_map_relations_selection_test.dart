import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:test/test.dart';

const _actions = [
  'warp.create',
  'connection.upsert',
  'connection.create_bidirectional_apply'
];
Map<String, Object?> _parameters(String action, {String id = 'new-entry'}) => {
      'mapId': 'source',
      if (action == 'warp.create')
        'warp': {
          'id': id,
          'pos': {'x': 3, 'y': 4},
          'targetMapId': 'target',
          'targetPos': {'x': 2, 'y': 3}
        },
      if (action != 'warp.create') ...{
        'direction': id == 'new-entry' ? 'east' : 'north',
        'targetMapId': 'target',
        'offset': 1
      },
    };
void main() {
  for (final action in _actions) {
    final counts = <List<int>>[];
    final decodedUnits = <Map<String, int>>[];
    for (final unrelated in [0, 80]) {
      test('$action stays bounded with $unrelated foreign maps and history',
          () async {
        final f = await _Fixture.open(unrelated);
        addTearDown(f.close);
        for (final id in ['new-entry', 'repeat']) {
          f.reader.paths.clear();
          f.reader.probes.clear();
          f.reader.units.clear();
          final beforeObjects =
              await Directory('${f.root.path}/catalog/objects').list().length;
          final timer = Stopwatch()..start();
          final plan = await f.plan(action, _parameters(action, id: id));
          expect(plan.plan.changeSet.changes.map((c) => c.storageKey).toSet(), {
            'catalog/HEAD.json',
            'maps/source.json',
            if (action.endsWith('bidirectional_apply')) 'maps/target.json'
          });
          final result = await f.api.applyMutation(f.opened.projectHandle,
              planId: plan.planId, operationId: id);
          timer.stop();
          expect(f.reader.paths.where(f.forbidden.contains), isEmpty);
          expect(
              f.reader.paths.where((p) =>
                  p.startsWith('maps/') &&
                  !{'maps/source.json', 'maps/target.json'}.contains(p)),
              isEmpty);
          expect(f.reader.paths.where((p) => p.endsWith('history.jsonl')),
              isEmpty);
          expect(f.reader.paths.length, lessThan(100));
          expect(f.reader.probes.length, lessThan(40));
          expect(
              await Directory('${f.root.path}/catalog/objects').list().length -
                  beforeObjects,
              lessThan(20));
          if (id == 'new-entry') {
            decodedUnits.add(Map.of(f.reader.units));
            counts.add([
              f.reader.paths.where((p) => p.startsWith('maps/')).length,
              f.reader.probes.where((p) => p.startsWith('maps/')).length
            ]);
          }
          print(
              '$action foreign=$unrelated $id reads=${f.reader.paths.length} probes=${f.reader.probes.length} elapsedUs=${timer.elapsedMicroseconds}');
          final replay = await f.api.applyMutation(f.opened.projectHandle,
              planId: plan.planId, operationId: id);
          expect(replay.receipt.receiptId, result.receipt.receiptId);
        }
        if (counts.length == 2) {
          expect(counts.last, counts.first);
          expect(decodedUnits.last, decodedUnits.first);
        }
        await f.reopen();
        final after =
            MapData.fromJson(jsonDecode(await f.source.readAsString()));
        expect(after.properties, f.map.properties);
        expect(after.spatialScene, f.map.spatialScene);
        expect(after.warps.first, f.warp);
        if (action == 'warp.create') {
          expect(after.warps.length, 3);
        } else {
          expect(after.connections.length, 2);
        }
        if (!action.endsWith('bidirectional_apply')) {
          expect(await f.target.readAsBytes(), f.targetBytes);
        }
        expect(await File('${f.root.path}/project.json').readAsBytes(),
            f.descriptor);
      });
    }
    test('$action accepts an observed full revision and rejects a stale target',
        () async {
      final f = await _Fixture.open(0, simple: true);
      addTearDown(f.close);
      final full = await f.snapshots.load(f.opened.projectHandle);
      Future<AuthoringMutationPlanResult> plan(String id) => f.api.planMutation(
          f.opened.projectHandle,
          AuthoringRequest(
              requestId: id,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: f.opened.workspaceHandle.value,
              expectedRevision: full.revision,
              idempotencyKey: id,
              parameters: _parameters(action)));
      f.reader.paths.clear();
      final result = await plan('observed');
      expect(result.plan.request.expectedRevision, full.revision);
      expect(f.reader.paths.where((p) => p.endsWith('history.jsonl')), isEmpty);
      await f.target.writeAsString(
          jsonEncode(f.destination.copyWith(name: 'Concurrent').toJson()));
      await expectLater(
          plan('stale'),
          throwsA(isA<AuthoringPlanException>()
              .having((e) => e.code, 'code', 'plan.stale')));
      expect(await f.source.readAsBytes(), f.sourceBytes);
    });
    test(
        '$action rejects missing destinations and invalid geometry without writes',
        () async {
      final f = await _Fixture.open(3);
      addTearDown(f.close);
      for (final missing in [false, true]) {
        final parameters = _parameters(action);
        if (action == 'warp.create') {
          parameters['warp'] = {
            ...(parameters['warp'] as Map<String, Object?>),
            'targetMapId': missing ? 'missing' : 'target',
            'targetPos': {'x': 99, 'y': 99}
          };
        } else {
          parameters['targetMapId'] = missing ? 'missing' : 'target';
          parameters['offset'] = 99;
        }
        try {
          final plan = await f.plan(action, parameters);
          expect(plan.applicable, isFalse);
        } catch (error) {
          expect(error, isA<Exception>());
        }
        expect(await f.source.readAsBytes(), f.sourceBytes);
        expect(await f.target.readAsBytes(), f.targetBytes);
      }
    });
    test('$action undo after reopen restores both maps', () async {
      final f = await _Fixture.open(3);
      addTearDown(f.close);
      final plan = await f.plan(action, _parameters(action));
      final result = await f.api.applyMutation(f.opened.projectHandle,
          planId: plan.planId, operationId: 'apply');
      await f.reopen();
      await f.api.undoMutation(f.opened.projectHandle,
          entryId: result.receipt.receiptId, idempotencyKey: 'undo');
      expect(await f.source.readAsBytes(), f.sourceBytes);
      expect(await f.target.readAsBytes(), f.targetBytes);
    });
    for (final destination in [false, true]) {
      test(
          '$action refuses a concurrent ${destination ? 'destination' : 'source'} write',
          () async {
        final f = await _Fixture.open(3);
        addTearDown(f.close);
        final plan = await f.plan(action, _parameters(action));
        final file = destination ? f.target : f.source;
        final bytes = utf8.encode(jsonEncode(
            (destination ? f.destination : f.map)
                .copyWith(properties: {'external': 'preserve'}).toJson()));
        await file.writeAsBytes(bytes);
        await expectLater(
            f.api.applyMutation(f.opened.projectHandle,
                planId: plan.planId, operationId: 'stale'),
            throwsA(isA<Exception>()));
        expect(await file.readAsBytes(), bytes);
        expect(await (destination ? f.source : f.target).readAsBytes(),
            destination ? f.sourceBytes : f.targetBytes);
      });
    }
  }
  test('warp.create validates only the selected animated door', () async {
    final f = await _Fixture.open(80);
    addTearDown(f.close);
    final door = MapWarpDoor(
        instanceId: 'door-instance',
        openAnimationIndex: 0,
        closeAnimationIndex: 1,
        exitPos: const GridPos(x: 2, y: 5));
    Map<String, Object?> parameters(MapWarpDoor value) => {
          'mapId': 'source',
          'warp': f.warp.copyWith(id: 'new-door', door: value).toJson()
        };
    final valid = await f.plan('warp.create', parameters(door));
    expect(valid.applicable, isTrue);
    expect(f.reader.paths.where(f.forbidden.contains), isEmpty);
    await expectLater(
        f.plan(
            'warp.create', parameters(door.copyWith(closeAnimationIndex: 99))),
        throwsA(isA<Exception>()));
    await expectLater(
        f.plan('warp.create', {'mapId': 'source', 'warp': f.warp.toJson()}),
        throwsA(isA<Exception>()));
    expect(await f.source.readAsBytes(), f.sourceBytes);
  });
  test('connection pair recovers a crash after the first map promotion',
      () async {
    var crashed = false;
    final f = await _Fixture.open(80, faultInjector: (context) {
      if (!crashed &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.storageKey == 'maps/source.json') {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(f.close);
    final plan = await f.plan('connection.create_bidirectional_apply',
        _parameters('connection.create_bidirectional_apply'));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId, operationId: 'recover'),
        throwsA(anything));
    expect(crashed, isTrue);
    await f.api.recoverMutation(f.opened.projectHandle, operationId: 'recover');
    await f.reopen();
    final source = MapData.fromJson(jsonDecode(await f.source.readAsString()));
    final target = MapData.fromJson(jsonDecode(await f.target.readAsString()));
    expect(
        source.connections.single,
        const MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'target',
            offset: 1));
    expect(
        target.connections.single,
        const MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'source',
            offset: -1));
    expect(f.reader.paths.where(f.forbidden.contains), isEmpty);
  });
}

final class _Fixture {
  _Fixture(
      this.root,
      this.opened,
      this.handles,
      this.api,
      this.reader,
      this.forbidden,
      this.map,
      this.destination,
      this.warp,
      this.sourceBytes,
      this.targetBytes,
      this.descriptor,
      this.snapshots);
  final Directory root;
  OpenedProject opened;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  final _Reader reader;
  final ProjectSnapshotLoader snapshots;
  final Set<String> forbidden;
  final MapData map, destination;
  final MapWarp warp;
  final List<int> sourceBytes, targetBytes, descriptor;
  File get source => File('${root.path}/maps/${map.id}.json');
  File get target => File('${root.path}/maps/target.json');
  Map<String, Object?> parameters({MapWarp? warp}) => {
        'mapId': map.id,
        'warpId': this.warp.id,
        'warp':
            (warp ?? this.warp.copyWith(targetPos: const GridPos(x: 2, y: 3)))
                .toJson()
      };
  Future<AuthoringMutationPlanResult> plan(
      String action, Map<String, Object?> parameters) async {
    final selected = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    expect(selected.maps.map((m) => m.id).toSet(), {map.id, destination.id});
    return api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'request-${DateTime.now().microsecondsSinceEpoch}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: selected.revision,
            idempotencyKey: 'key-${DateTime.now().microsecondsSinceEpoch}',
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
    api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  static Future<_Fixture> open(int unrelated,
      {bool reverseIds = false,
      bool simple = false,
      AuthoringTransactionFaultInjector? faultInjector}) async {
    final sourceId = reverseIds ? 'z-source' : 'source';
    final root = await Directory(
            '/Users/karim/Library/Caches/AveluneQA/hgss-mauville-maps/api')
        .create(recursive: true)
        .then((root) => root.createTemp('relations-'));
    final models = [
      for (final id in [
        'decoration',
        'door',
        for (var i = 0; i < unrelated; i++) 'unused-$i'
      ])
        ProjectModel3dEntry(
            id: id,
            name: id,
            sourceAssetId: '$id-source',
            relativePath: 'assets/models3d/$id.glb',
            inspection: Model3dInspection(
                bounds: Model3dBounds(
                    min: Model3dVector3.zero,
                    max: Model3dVector3(x: 1, y: 1, z: 1)),
                meshCount: 1,
                triangleCount: 1,
                animations: id == 'door'
                    ? [
                        Model3dAnimation(
                            index: 0, name: 'Open', durationSeconds: .2),
                        Model3dAnimation(
                            index: 1, name: 'Close', durationSeconds: .2)
                      ]
                    : []))
    ];
    final project = ProjectManifest(
        name: 'Warps',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        maps: [
          for (final id in [
            sourceId,
            'target',
            for (var i = 0; i < unrelated; i++) 'other-$i'
          ])
            ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json')
        ],
        tilesets: const [],
        models3d: simple ? [] : models);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'warps', project: project);
    const warp = MapWarp(
        id: 'entry',
        pos: GridPos(x: 2, y: 4),
        targetMapId: 'target',
        targetPos: GridPos(x: 2, y: 4));
    final map = MapData(
        id: sourceId,
        name: 'Source',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 6),
        properties: {'keep': 'graphics'},
        warps: const [warp],
        spatialScene: MapSpatialScene(
            width: 6,
            depth: 6,
            instances: simple
                ? []
                : [
                    SpatialModelInstance(
                        id: 'decorative-instance',
                        modelId: 'decoration',
                        position: Model3dVector3(x: 1, y: 0, z: 1)),
                    SpatialModelInstance(
                        id: 'door-instance',
                        modelId: 'door',
                        position: Model3dVector3(x: 2, y: 0, z: 4))
                  ]));
    final destination = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 6),
        spatialScene: MapSpatialScene(width: 6, depth: 6));
    await Directory('${root.path}/maps').create();
    final sourceBytes = utf8.encode(jsonEncode(map.toJson())),
        targetBytes = utf8.encode(jsonEncode(destination.toJson()));
    await File('${root.path}/maps/$sourceId.json').writeAsBytes(sourceBytes);
    await File('${root.path}/maps/target.json').writeAsBytes(targetBytes);
    final forbidden = <String>{};
    for (final id in [
      if (!simple) 'decoration',
      for (var i = 0; i < unrelated; i++) 'unused-$i'
    ]) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, id)))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      forbidden.add(path);
      await File('${root.path}/$path')
          .writeAsString('unrelated decorative definition must not be read');
    }
    if (!simple) {
      for (final field in ['newGame', 'pokemon']) {
        final key = CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
            jsonEncode(['projectAggregateHeader', field]));
        final entry = await working.catalog.snapshot.indexEntry(key);
        if (entry == null) continue;
        final path = 'catalog/objects/${entry.reference.sha256}.json';
        forbidden.add(path);
        await File('${root.path}/$path')
            .writeAsString('unrelated gameplay metadata must remain unread');
      }
    }
    for (var i = 0; i < unrelated; i++) {
      final entry = (await working.catalog.snapshot
          .indexEntry(CatalogMetadataDocuments.definitionKey('maps', i + 2)))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      forbidden.add(path);
      await File('${root.path}/$path')
          .writeAsString('foreign map entry must remain unread');
      await File('${root.path}/maps/other-$i.json')
          .writeAsString('unrelated map must not be decoded');
    }
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString('unrelated old history must remain unread\n' *
        (unrelated == 0 ? 100 : 10000));
    final reader = _Reader(), handles = WorkspaceHandleStore();
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
    return _Fixture(
        root,
        opened,
        handles,
        api,
        reader,
        forbidden,
        map,
        destination,
        warp,
        sourceBytes,
        targetBytes,
        await File('${root.path}/project.json').readAsBytes(),
        snapshots);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final probes = <String>[];
  final units = <String, int>{};
  void record(List<int> bytes) {
    try {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is Map && raw['key'] is Map) {
        final key = raw['key'] as Map;
        final identity = '${key["kind"]}:${key["id"]}';
        units.update(identity, (n) => n + 1, ifAbsent: () => 1);
      }
    } catch (_) {}
  }

  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
      {required String projectRoot, required String relativePath}) {
    probes.add(relativePath);
    return delegate.probeResource(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) async {
    paths.add(relativePath);
    final bytes = await delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
    record(bytes);
    return bytes;
  }

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    paths.add(relativePath);
    final bytes = await delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
    record(bytes);
    yield bytes;
  }
}
