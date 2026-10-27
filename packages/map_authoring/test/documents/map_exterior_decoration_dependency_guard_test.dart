import 'dart:io';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionCheckpoint, AuthoringTransactionSimulatedCrash;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../support/exterior_decoration_fixture.dart';

void main() {
  late Directory root;
  late LocalMapExteriorDecorationAuthoring service;
  late String revision;
  late ExteriorDecorationSector original;
  setUp(() async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring');
    await base.create(recursive: true);
    root = await base.createTemp('dependency_');
    final fixture = await createExteriorDecorationFixture(root.path);
    service = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()));
    final border = await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: fixture['revision'] as String,
        expectedCatalogRevision: fixture['catalogRevision'] as String,
        operationId: 'native_border',
        edit: {
          'kind': 'border.draw',
          'blueprintId': 'fence',
          'borderId': 'fence_owner',
          'seed': '42',
          'points': [
            {'x': -12, 'z': 4},
            {'x': -4, 'z': 4}
          ]
        });
    revision = border.afterRevision;
    original = (await service.inspect(projectRoot: root.path, mapId: 'route'))
        .decoration!
        .sectors
        .single;
  });
  tearDown(() async => root.delete(recursive: true));

  ExteriorDecorationSector sector(
          {int? level,
          List<int>? levels,
          Iterable<SpatialModelInstance> instances = const [],
          SpatialTerrainSurfaceSet? surfaces,
          int? originX}) =>
      ExteriorDecorationSector(
        id: original.id,
        originX: originX ?? original.originX,
        originZ: original.originZ,
        layers: original.layers,
        scene: MapSpatialScene(
            width: 16,
            depth: 16,
            generateCliffs: false,
            heightLevels: levels ?? List.filled(256, level ?? 0),
            instances: instances,
            terrainSurfaces:
                surfaces ?? const SpatialTerrainSurfaceSet.empty()),
      );

  Future<Map<String, List<int>>> stored() async => {
        for (final path in [
          'maps/route.json',
          'maps/route.decoration.json',
          'maps/route.decoration/west.json',
          'maps/route.decoration/borders/fence_owner.json'
        ])
          path: await File('${root.path}/$path').readAsBytes()
      };

  for (final operation in [
    'set',
    'batch',
    'batch_remove',
    'remove',
    'bounds',
    'surface'
  ]) {
    test(
        '$operation refuses stale dependent Border before changing any document',
        () async {
      final before = await stored();
      final raised = sector(level: 3);
      final Future<Object?> mutation;
      switch (operation) {
        case 'batch':
          mutation = service.setSectors(
              projectRoot: root.path,
              mapId: 'route',
              expectedRevision: revision,
              sectors: [raised],
              operationId: 'raise_batch');
        case 'batch_remove':
          mutation = service.setSectors(
              projectRoot: root.path,
              mapId: 'route',
              expectedRevision: revision,
              sectors: const [],
              removeSectorIds: ['west'],
              operationId: 'remove_batch_support');
        case 'remove':
          mutation = service.removeSector(
              projectRoot: root.path,
              mapId: 'route',
              expectedRevision: revision,
              sectorId: 'west',
              operationId: 'remove_support');
        case 'bounds':
          mutation = service.setSector(
              projectRoot: root.path,
              mapId: 'route',
              expectedRevision: revision,
              sector: sector(originX: -4),
              operationId: 'move_support');
        case 'surface':
          mutation = service.setSector(
              projectRoot: root.path,
              mapId: 'route',
              expectedRevision: revision,
              sector: sector(
                  surfaces: SpatialTerrainSurfaceSet(surfaces: [
                SpatialTerrainSurface(
                    id: 'raised',
                    x: 0,
                    z: 0,
                    height: 3,
                    footprints: [
                      BorderGroundFootprint(points: [
                        BorderGroundPoint(x: 0, z: 0),
                        BorderGroundPoint(x: 16, z: 0),
                        BorderGroundPoint(x: 16, z: 16),
                        BorderGroundPoint(x: 0, z: 16)
                      ])
                    ])
              ])),
              operationId: 'raise_surface');
        default:
          mutation = service.setSector(
              projectRoot: root.path,
              mapId: 'route',
              expectedRevision: revision,
              sector: raised,
              operationId: 'raise_set');
      }
      await expectLater(
          mutation,
          throwsA(isA<FormatException>().having((error) => error.message,
              'message', contains('Border terrain dependency'))));
      expect(await stored(), before);
      expect(
          (await service.inspect(projectRoot: root.path, mapId: 'route'))
              .revision,
          revision);
    });
  }
  test('tree edits preserve Border bytes and remain undoable', () async {
    final before = await stored();
    final reader = _TrackingReader();
    service = LocalMapExteriorDecorationAuthoring(
        reader: reader,
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path], fileReader: reader));
    final changed = await service.setSector(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        operationId: 'tree',
        sector: sector(instances: [
          SpatialModelInstance(
              id: 'tree',
              modelId: 'oak',
              position: Model3dVector3(x: 2, y: 0, z: 2))
        ]));
    expect(
        await File(
                '${root.path}/maps/route.decoration/borders/fence_owner.json')
            .readAsBytes(),
        before['maps/route.decoration/borders/fence_owner.json']);
    expect(reader.paths.where((path) => path.contains('/borders/')), isEmpty);
    await service.undo(
        projectRoot: root.path,
        mapId: 'route',
        mutation: changed,
        operationId: 'undo_tree');
    expect(await stored(), before);
  });
  test('recovery rechecks original images after partial promotion', () async {
    final candidate = sector(levels: List.filled(256, 0)..[255] = 3);
    final failing = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()),
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        failing.setSector(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: revision,
            sector: candidate,
            operationId: 'crash_distant_relief'),
        throwsA(anything));
    await expectLater(service.inspect(projectRoot: root.path, mapId: 'route'),
        throwsA(isA<FormatException>()));
    final recovered = await service.setSector(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        sector: candidate,
        operationId: 'crash_distant_relief');
    final snapshot =
        await service.inspect(projectRoot: root.path, mapId: 'route');
    expect(snapshot.revision, recovered.afterRevision);
    expect(snapshot.decoration!.sectors.single.scene.heightLevels.last, 3);
    expect(snapshot.decoration!.borders.single.instances.first.position.y, 0);
  });
  test('an unsampled relief cell does not invalidate the Border', () async {
    final before = await stored();
    final levels = List.filled(256, 0)..[15 * 16 + 15] = 3;
    final changed = await service.setSector(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: revision,
        operationId: 'distant_relief',
        sector: sector(levels: levels));
    final snapshot =
        await service.inspect(projectRoot: root.path, mapId: 'route');
    expect(snapshot.revision, changed.afterRevision);
    expect(snapshot.decoration!.sectors.single.scene.heightLevels.last, 3);
    expect(
        await File(
                '${root.path}/maps/route.decoration/borders/fence_owner.json')
            .readAsBytes(),
        before['maps/route.decoration/borders/fence_owner.json']);
  });
}

final class _TrackingReader
    implements
        ProjectFileReader,
        ProjectResourceProbeReader,
        ProjectResourceStreamReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
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
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}
