import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final reads = <Map<String, int>>[];
  for (final unrelated in [0, 80]) {
    test(
        'warp.update writes one map and reads only its destination with $unrelated unrelated maps',
        () async {
      final f = await _Fixture.open(unrelated);
      addTearDown(f.close);
      f.reader.paths.clear();
      f.reader.units.clear();
      final plan = await f.plan(f.parameters());
      expect(plan.plan.changeSet.changes.map((c) => c.storageKey).toSet(),
          {'catalog/HEAD.json', 'maps/source.json'});
      await f.api.applyMutation(f.opened.projectHandle,
          planId: plan.planId, operationId: 'apply');
      final after = MapData.fromJson(
          jsonDecode(await f.source.readAsString()) as Map<String, dynamic>);
      expect(
          after.toJson(),
          f.map.copyWith(warps: [
            f.warp.copyWith(targetPos: const GridPos(x: 2, y: 3))
          ]).toJson());
      expect(await f.target.readAsBytes(), f.targetBytes);
      expect(await File('${f.root.path}/project.json').readAsBytes(),
          f.descriptor);
      expect(f.reader.paths.where(f.forbidden.contains), isEmpty);
      expect(
          f.reader.paths.where((p) =>
              p.startsWith('maps/') &&
              !{'maps/source.json', 'maps/target.json'}.contains(p)),
          isEmpty);
      reads.add(Map.of(f.reader.units));
      expect(f.reader.paths.length, lessThan(120));
      if (reads.length == 2) expect(reads.last, reads.first);
    });
  }
  test('warp.update retains source identity when destination sorts first',
      () async {
    final f = await _Fixture.open(0, reverseIds: true);
    addTearDown(f.close);
    final plan = await f.plan(f.parameters());
    await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId, operationId: 'reverse');
    final after = MapData.fromJson(
        jsonDecode(await f.source.readAsString()) as Map<String, dynamic>);
    expect(after.id, 'z-source');
    expect(after.warps.single.targetPos, const GridPos(x: 2, y: 3));
    expect(await f.target.readAsBytes(), f.targetBytes);
  });
  for (final destination in [false, true]) {
    test(
        'warp.update rejects a concurrent ${destination ? 'destination' : 'source'} write',
        () async {
      final f = await _Fixture.open(3);
      addTearDown(f.close);
      final plan = await f.plan(f.parameters());
      final file = destination ? f.target : f.source;
      final external = utf8.encode(jsonEncode(
          (destination ? f.destination : f.map)
              .copyWith(properties: {'external': 'preserve'}).toJson()));
      await file.writeAsBytes(external);
      await expectLater(
          f.api.applyMutation(f.opened.projectHandle,
              planId: plan.planId, operationId: 'stale'),
          throwsA(isA<Exception>()));
      expect(await file.readAsBytes(), external);
      if (destination) expect(await f.source.readAsBytes(), f.sourceBytes);
    });
  }
  test('warp.update rejects unknown top-level and nested fields without writes',
      () async {
    final f = await _Fixture.open(3);
    addTearDown(f.close);
    for (final nested in [false, true]) {
      final parameters = f.parameters();
      if (nested) {
        parameters['warp'] = {
          ...(parameters['warp'] as Map<String, dynamic>),
          'unknown': true
        };
      } else {
        parameters['unknown'] = true;
      }
      await expectLater(f.plan(parameters), throwsA(isA<Exception>()));
      expect(await f.source.readAsBytes(), f.sourceBytes);
    }
  });
  test(
      'warp.update rejects a missing or out-of-bounds destination without writes',
      () async {
    final f = await _Fixture.open(3);
    addTearDown(f.close);
    for (final missing in [false, true]) {
      final parameters = f.parameters(
          warp: f.warp.copyWith(
              targetMapId: missing ? 'missing' : 'target',
              targetPos: const GridPos(x: 99, y: 99)));
      await expectLater(f.plan(parameters), throwsA(isA<Exception>()));
      expect(await f.source.readAsBytes(), f.sourceBytes);
    }
  });
  test(
      'warp.update validates a newly bound door model without reading decorative models',
      () async {
    final f = await _Fixture.open(3);
    addTearDown(f.close);
    final door = MapWarpDoor(
        instanceId: 'door-instance',
        openAnimationIndex: 0,
        closeAnimationIndex: 1,
        exitPos: const GridPos(x: 2, y: 5));
    final parameters = f.parameters(warp: f.warp.copyWith(door: door));
    final plan = await f.plan(parameters);
    expect(plan.applicable, isTrue);
    expect(f.reader.paths.where(f.forbidden.contains), isEmpty);
    await expectLater(
        f.plan(f.parameters(
            warp:
                f.warp.copyWith(door: door.copyWith(closeAnimationIndex: 99)))),
        throwsA(isA<Exception>()));
    expect(await f.source.readAsBytes(), f.sourceBytes);
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
      this.descriptor);
  final Directory root;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi api;
  final _Reader reader;
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
      Map<String, Object?> parameters) async {
    final selected = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: 'warp.update', parameters: parameters);
    expect(selected.maps.map((m) => m.id).toSet(), {map.id, destination.id});
    return api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'request-${DateTime.now().microsecondsSinceEpoch}',
            actionId: 'warp.update',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: selected.revision,
            idempotencyKey: 'key-${DateTime.now().microsecondsSinceEpoch}',
            parameters: parameters));
  }

  static Future<_Fixture> open(int unrelated, {bool reverseIds = false}) async {
    final sourceId = reverseIds ? 'z-source' : 'source';
    final root = await Directory.systemTemp.createTemp('warp-selection-');
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
        models3d: models);
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
        spatialScene: MapSpatialScene(width: 6, depth: 6, instances: [
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
      'decoration',
      for (var i = 0; i < unrelated; i++) 'unused-$i'
    ]) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, id)))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      forbidden.add(path);
      await File('${root.path}/$path')
          .writeAsString('unrelated decorative definition must not be read');
    }
    for (var i = 0; i < unrelated; i++) {
      await File('${root.path}/maps/other-$i.json')
          .writeAsString('unrelated map must not be decoded');
    }
    final reader = _Reader(), handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
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
        await File('${root.path}/project.json').readAsBytes());
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
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
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
