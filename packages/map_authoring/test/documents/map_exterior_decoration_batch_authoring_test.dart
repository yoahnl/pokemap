import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late LocalMapExteriorDecorationAuthoring service;
  late String revision;
  late WorkspacePolicy policy;
  setUp(() async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring');
    await base.create(recursive: true);
    root = await base.createTemp('batch_');
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/route.json').writeAsString(jsonEncode(MapData(
            id: 'route',
            name: 'Route',
            version: ProjectVersion.v9,
            size: const GridSize(width: 8, height: 8),
            spatialScene: MapSpatialScene(width: 8, depth: 8))
        .toJson()));
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'route');
    final configured = await service.configure(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: before.revision,
        decoration: MapExteriorDecoration(
            mapId: 'route', playableWidth: 8, playableDepth: 8, west: 4),
        operationId: 'configure');
    revision = configured.afterRevision;
  });
  tearDown(() async => root.delete(recursive: true));
  ExteriorDecorationSector sector(String id, int x) => ExteriorDecorationSector(
      id: id,
      originX: x,
      originZ: 0,
      scene: MapSpatialScene(width: 2, depth: 4));
  test(
      'one stroke saves and undoes two sectors without changing playable bytes',
      () async {
    final before = await File('${root.path}/maps/route.json').readAsBytes();
    final api = service;
    final MapExteriorDecorationMutation changed = await api.setSectors(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        sectors: [sector('a', -4), sector('b', -2)],
        operationId: 'stroke');
    var snapshot =
        await service.inspect(projectRoot: root.path, mapId: 'route');
    expect(snapshot.sectorIds, ['a', 'b']);
    expect(await File('${root.path}/maps/route.json').readAsBytes(), before);
    await service.undo(
        projectRoot: root.path,
        mapId: 'route',
        mutation: changed,
        operationId: 'undo');
    snapshot = await service.inspect(projectRoot: root.path, mapId: 'route');
    expect(snapshot.sectorIds, isEmpty);
    expect(await File('${root.path}/maps/route.decoration/a.json').exists(),
        isFalse);
    expect(await File('${root.path}/maps/route.decoration/b.json').exists(),
        isFalse);
  });
  test('interrupted multi-document promotion recovers the complete stroke once',
      () async {
    final sectors = [sector('a', -4), sector('b', -2)];
    final failing = LocalMapExteriorDecorationAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        failing.setSectors(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: revision,
            sectors: sectors,
            operationId: 'crash-batch'),
        throwsA(anything));
    await expectLater(service.inspect(projectRoot: root.path, mapId: 'route'),
        throwsA(isA<FormatException>()));
    final recovered = await service.setSectors(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        sectors: sectors,
        operationId: 'crash-batch');
    final retry = await service.setSectors(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        sectors: sectors,
        operationId: 'crash-batch');
    expect(retry.receipt.receiptId, recovered.receipt.receiptId);
    final snapshot =
        await service.inspect(projectRoot: root.path, mapId: 'route');
    expect(snapshot.decoration!.sectors, sectors);
    expect(snapshot.revision, recovered.afterRevision);
  });
  test('invalid overlap and stale revision publish neither sector', () async {
    final api = service;
    await expectLater(
        api.setSectors(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: revision,
            sectors: [sector('a', -4), sector('b', -4)],
            operationId: 'overlap'),
        throwsA(isA<FormatException>()));
    expect(
        (await service.inspect(projectRoot: root.path, mapId: 'route'))
            .sectorIds,
        isEmpty);
    await expectLater(
        api.setSectors(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: 'stale',
            sectors: [sector('a', -4), sector('b', -2)],
            operationId: 'stale'),
        throwsA(anything));
    expect(
        (await service.inspect(projectRoot: root.path, mapId: 'route'))
            .sectorIds,
        isEmpty);
  });
}
