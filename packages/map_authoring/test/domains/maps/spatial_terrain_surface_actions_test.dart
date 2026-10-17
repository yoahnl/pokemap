import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';

void main() {
  test(
      'surface edits can explicitly preserve model heights through direct and JSONL',
      () async {
    for (final direct in [true, false]) {
      final host = await _fixture();
      addTearDown(host.dispose);
      final plan = await _plan(
          host,
          'map3d.terrain.surface.upsert_batch',
          {
            'mapId': 'map',
            'surfaces': [_surface().toJson()],
            'reanchorInstances': false,
          },
          direct);
      expect((plan['plan'] as Map)['preview'],
          containsPair('reanchorInstances', false));
      await _apply(host, plan, direct, 'preserve-create');
      expect((await _map(host)).spatialScene!.worldHeightAt(1.5, 1.5), 2.125);
      await _apply(
          host,
          await _plan(
              host,
              'map3d.terrain.surface.delete_batch',
              {
                'mapId': 'map',
                'surfaceIds': ['slope'],
                'reanchorInstances': false,
              },
              direct),
          direct,
          'preserve-delete');
      expect(
          (await _map(host)).spatialScene!.terrainSurfaces.surfaces, isEmpty);
    }
  });

  test(
      'continuous surfaces are created, edited and deleted atomically through direct and JSONL',
      () async {
    final persisted = <List<int>>[];
    for (final direct in [true, false]) {
      final host = await _fixture();
      addTearDown(host.dispose);
      final file = File('${host.root.path}/maps/map.json');
      final before = await file.readAsBytes();
      final manifestBefore =
          await File('${host.root.path}/project.json').readAsBytes();
      final surface = _surface();
      final parameters = {
        'mapId': 'map',
        'surfaces': [surface.toJson()]
      };
      final plan = await _plan(
          host, 'map3d.terrain.surface.upsert_batch', parameters, direct);
      expect(await file.readAsBytes(), before);
      expect(jsonEncode(plan).length, lessThan(16384));
      await _apply(host, plan, direct, 'create');
      var saved = await _map(host);
      expect(saved.spatialScene!.worldHeightAt(1.5, 1.5), 2.125);
      expect(saved.spatialScene!.worldHeightAt(.5, .5), 1);
      expect(saved.toJson()['spatialScene']['schemaVersion'], 2);
      persisted.add(await file.readAsBytes());
      await _apply(
          host,
          await _plan(
              host,
              'map3d.terrain.surface.upsert_batch',
              {
                'mapId': 'map',
                'surfaces': [surface.copyWith(height: 3).toJson()],
              },
              direct),
          direct,
          'edit');
      expect((await _map(host)).spatialScene!.worldHeightAt(1.5, 1.5), 3.125);
      await _apply(
          host,
          await _plan(
              host,
              'map3d.terrain.surface.delete_batch',
              {
                'mapId': 'map',
                'surfaceIds': ['slope'],
              },
              direct),
          direct,
          'delete');
      saved = await _map(host);
      expect(saved.spatialScene!.terrainSurfaces.surfaces, isEmpty);
      expect(saved.spatialScene!.worldHeightAt(1.5, 1.5), 1);
      expect(saved.toJson()['spatialScene']['schemaVersion'], 1);
      expect(await File('${host.root.path}/project.json').readAsBytes(),
          manifestBefore);
      final history = await host
          .command('history', {'projectHandle': host.project, 'limit': 1});
      expect(history.status, AuthoringResultStatus.success);
      final entry = (history.data['entries'] as List).single as Map;
      final undone = await host.command('undo', {
        'projectHandle': host.project,
        'entryId': entry['entryId'],
        'idempotencyKey': 'undo-delete',
      });
      expect(undone.status, AuthoringResultStatus.success,
          reason: undone.toJson().toString());
      expect((await _map(host)).spatialScene!.worldHeightAt(1.5, 1.5), 3.125);
    }
    expect(persisted[0], persisted[1]);
  });

  test(
      'invalid surface batches refuse all writes, including a valid first item',
      () async {
    final host = await _fixture();
    addTearDown(host.dispose);
    final file = File('${host.root.path}/maps/map.json');
    final before = await file.readAsBytes();
    for (final surfaces in [
      [],
      [_surface().toJson(), _surface().toJson()],
      [
        _surface().toJson(),
        _surface().copyWith(x: 3).toJson()..['id'] = 'outside'
      ],
      [
        _surface().toJson(),
        {'id': 'malformed'}
      ],
      [
        for (var i = 0; i < 129; i++) _surface().toJson()..['id'] = 'surface-$i'
      ],
    ]) {
      final rejected = await host.plan('map3d.terrain.surface.upsert_batch',
          {'mapId': 'map', 'surfaces': surfaces});
      expect(rejected.status, AuthoringResultStatus.failure);
      expect(rejected.error?.details['domainCode'],
          'map3d.terrain.surface.invalid');
      expect(await file.readAsBytes(), before);
    }
    await host.mutate('map3d.terrain.surface.upsert_batch', {
      'mapId': 'map',
      'surfaces': [_surface().toJson()]
    });
    final beforeDelete = await file.readAsBytes();
    for (final ids in [
      [],
      ['slope', 'missing'],
      ['slope', 'slope'],
      ['slope', 7]
    ]) {
      final rejected = await host.plan('map3d.terrain.surface.delete_batch',
          {'mapId': 'map', 'surfaceIds': ids});
      expect(rejected.status, AuthoringResultStatus.failure);
      expect(rejected.error?.details['domainCode'],
          'map3d.terrain.surface.invalid');
      expect(await file.readAsBytes(), beforeDelete);
    }
  });

  test(
      'terrain level configuration preserves continuous surfaces through direct and JSONL',
      () async {
    for (final direct in [true, false]) {
      final manifest = ProjectManifest(
          name: 'Terrain',
          maps: [],
          tilesets: [],
          version: ProjectVersion.v9,
          settings: ProjectSettings(
              dimension: ProjectDimension.threeD,
              spatialCamera: SpatialCameraProfile()));
      final host = await ResourceInformationFixture.create(manifest);
      addTearDown(host.dispose);
      final surface = SpatialTerrainSurface(
          id: 'slope',
          x: 1,
          z: 1,
          height: 2,
          gradientX: .25,
          footprints: [
            BorderGroundFootprint(points: [
              BorderGroundPoint(x: 0, z: 0),
              BorderGroundPoint(x: 1, z: 0),
              BorderGroundPoint(x: 1, z: 1),
              BorderGroundPoint(x: 0, z: 1),
            ])
          ]);
      final source = MapData(
          id: 'map',
          name: 'Terrain',
          version: ProjectVersion.v9,
          size: const GridSize(width: 3, height: 3),
          spatialScene: MapSpatialScene(
              width: 3,
              depth: 3,
              levelHeight: .25,
              heightLevels: List.filled(9, 4),
              terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [surface])));
      final file = File('${host.root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(source.toJson()));
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(manifest.copyWith(maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Terrain', relativePath: 'maps/map.json'),
      ]).toJson()));
      final before = await file.readAsBytes();
      const parameters = <String, Object?>{'mapId': 'map', 'levelHeight': .5};
      if (direct) {
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final plan = await host.mutations.plan(
            ProjectHandle(host.project),
            AuthoringRequest(
                requestId: 'height',
                actionId: 'map3d.terrain.configure_height',
                actionVersion: 1,
                workspaceHandle: host.workspace,
                expectedRevision: snapshot.revision,
                idempotencyKey: 'height',
                parameters: parameters));
        expect(await file.readAsBytes(), before);
        await host.mutations.apply(ProjectHandle(host.project),
            planId: plan['planId'] as String, operationId: 'height');
      } else {
        final plan =
            await host.plan('map3d.terrain.configure_height', parameters);
        expect(plan.status, AuthoringResultStatus.success,
            reason: plan.toJson().toString());
        expect(await file.readAsBytes(), before);
        final applied = await host.apply(plan);
        expect(applied.status, AuthoringResultStatus.success,
            reason: applied.toJson().toString());
      }
      final saved = MapData.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      expect(saved.spatialScene!.terrainSurfaces,
          source.spatialScene!.terrainSurfaces);
      expect(saved.spatialScene!.worldHeightAt(1.5, 1.5), 2.125);
      expect(saved.spatialScene!.worldHeightAt(.5, .5), 2);
      expect(saved.spatialScene!.navigation, source.spatialScene!.navigation);
    }
  });
}

SpatialTerrainSurface _surface() => SpatialTerrainSurface(
      id: 'slope',
      x: 1,
      z: 1,
      height: 2,
      gradientX: .25,
      footprints: [
        BorderGroundFootprint(points: [
          BorderGroundPoint(x: 0, z: 0),
          BorderGroundPoint(x: 1, z: 0),
          BorderGroundPoint(x: 1, z: 1),
          BorderGroundPoint(x: 0, z: 1),
        ])
      ],
    );

Future<ResourceInformationFixture> _fixture() async {
  final manifest = ProjectManifest(
      name: 'Terrain',
      maps: [],
      tilesets: [],
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()));
  final host = await ResourceInformationFixture.create(manifest);
  final map = MapData(
      id: 'map',
      name: 'Terrain',
      version: ProjectVersion.v9,
      size: const GridSize(width: 3, height: 3),
      spatialScene: MapSpatialScene(
          width: 3,
          depth: 3,
          levelHeight: .25,
          heightLevels: List.filled(9, 4)));
  final file = File('${host.root.path}/maps/map.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map.toJson()));
  await File('${host.root.path}/project.json')
      .writeAsString(jsonEncode(manifest.copyWith(maps: [
    const ProjectMapEntry(
        id: 'map', name: 'Terrain', relativePath: 'maps/map.json'),
  ]).toJson()));
  return host;
}

Future<MapData> _map(ResourceInformationFixture host) async => MapData.fromJson(
    jsonDecode(await File('${host.root.path}/maps/map.json').readAsString())
        as Map<String, dynamic>);

Future<Map<String, Object?>> _plan(ResourceInformationFixture host,
    String action, Map<String, Object?> parameters, bool direct) async {
  if (direct) {
    final snapshot = await host.snapshots.load(ProjectHandle(host.project));
    return host.mutations.plan(
        ProjectHandle(host.project),
        AuthoringRequest(
            requestId: 'request-${host.next++}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: host.workspace,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'key-${host.next++}',
            parameters: parameters));
  }
  final planned = await host.plan(action, parameters);
  expect(planned.status, AuthoringResultStatus.success,
      reason: planned.toJson().toString());
  return planned.data;
}

Future<void> _apply(ResourceInformationFixture host, Map<String, Object?> plan,
    bool direct, String operation) async {
  if (direct) {
    await host.mutations.apply(ProjectHandle(host.project),
        planId: plan['planId'] as String, operationId: operation);
  } else {
    final result = await host.command('apply', {
      'projectHandle': host.project,
      'planId': plan['planId'],
      'operationId': operation
    });
    expect(result.status, AuthoringResultStatus.success,
        reason: result.toJson().toString());
  }
}
