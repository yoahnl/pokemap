import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/domains/maps/spatial_map_actions.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

const actionId = 'map3d.instance.configure_field_obstacle';
final obstacleModel = ProjectModel3dEntry(
  id: 'oak',
  name: 'Oak',
  sourceAssetId: 'oak-source',
  relativePath: 'assets/models3d/oak.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
        min: Model3dVector3(x: -.4, y: 0, z: -.4),
        max: Model3dVector3(x: .4, y: 2, z: .4)),
    meshCount: 1,
    triangleCount: 4,
  ),
);
ProjectManifest obstacleProject() => ProjectManifest(
      name: 'Obstacles',
      tilesets: const [],
      version: ProjectVersion.v9,
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      maps: const [
        ProjectMapEntry(
            id: 'route', name: 'Route', relativePath: 'maps/route.json')
      ],
      models3d: [obstacleModel],
    );
MapData obstacleMap() => MapData(
      id: 'route',
      name: 'Route',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          heightLevels: List.filled(64, 0),
          instances: [
            SpatialModelInstance(
                id: 'oak-1',
                modelId: 'oak',
                position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
                blocksMovement: true),
          ]),
    );
AuthoringMutationDraft configureDraft(MapData map, Object? payload) =>
    const SpatialMapActions().build(
      catalogContext(
          catalogSnapshot([map], project: obstacleProject()),
          actionId,
          {'mapId': 'route', 'instanceId': 'oak-1', 'fieldObstacle': payload}),
    );
MapData resultMap(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);

void main() {
  test('native obstacle workshop reads only its selected map and model',
      () async {
    final root = Directory(
        '/Users/karim/Library/Caches/AveluneQA/field-actions-3d/authoring-native');
    await root.create(recursive: true);
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(obstacleProject().toJson()));
    final file = File('${root.path}/maps/route.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(obstacleMap().toJson()));
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: const LocalProjectFileReader(),
        handles: handles,
        catalogMetadataFields: const {},
        workshopScope: true);
    final opened = await opener.openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    addTearDown(() async {
      await api.detachWorkspace(opened.workspaceHandle);
      opener.closeWorkspace(opened.workspaceHandle);
    });
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: actionId,
        parameters: {
          'mapId': 'route',
          'instanceId': 'oak-1',
          'fieldObstacle': null
        });
    expect(snapshot.maps.single.id, 'route');
    expect(snapshot.manifest.models3d.single.id, 'oak');
  });

  for (final catalogStorage in [false, true]) {
    test(
        'model obstacle action is discoverable and persists through JSONL catalog=$catalogStorage',
        () async {
      final root = Directory(
          '/Users/karim/Library/Caches/AveluneQA/field-actions-3d/authoring-cli');
      await root.create(recursive: true);
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      if (catalogStorage) {
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        await WorkingProjectCatalog.create(
            store: store, projectId: 'field-cli', project: obstacleProject());
      } else {
        await File('${root.path}/project.json')
            .writeAsString(jsonEncode(obstacleProject().toJson()));
      }
      final file = File('${root.path}/maps/route.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(obstacleMap().toJson()));
      final process = await Process.start(
          'dart', ['run', 'bin/pokemap_authoring.dart', '--root', root.path]);
      final errors = process.stderr.transform(utf8.decoder).join();
      final lines = StreamIterator(process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter()));
      var sequence = 0;
      Future<Map<String, Object?>> send(
          String command, Map<String, Object?> args) async {
        process.stdin.writeln(jsonEncode({
          'id': 'field-cli-${sequence++}',
          'command': command,
          'args': args
        }));
        await process.stdin.flush();
        expect(await lines.moveNext().timeout(const Duration(seconds: 20)),
            isTrue);
        final result = AuthoringResult.fromJson(
            jsonDecode(lines.current) as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success,
            reason: result.toJson().toString());
        return result.data;
      }

      try {
        final catalog = await send('describe', {});
        expect(
            (catalog['mutationActions'] as List)
                .where((item) => item['id'] == actionId),
            hasLength(1));
        final opened = await send('open', {'projectRoot': root.path});
        final parameters = <String, Object?>{
          'mapId': 'route',
          'instanceId': 'oak-1',
          'fieldObstacle': {'kind': 'cutTree', 'resetPolicy': 'persistent'}
        };
        final snapshot = await send('workshop_snapshot', {
          'projectHandle': opened['projectHandle'],
          'actionId': actionId,
          'parameters': parameters
        });
        final planned = await send('plan', {
          'projectHandle': opened['projectHandle'],
          'request': AuthoringRequest(
              requestId: 'field-cli',
              actionId: actionId,
              actionVersion: 1,
              workspaceHandle: opened['workspaceHandle'] as String,
              expectedRevision: snapshot['snapshotRevision'] as String,
              idempotencyKey: 'field-cli',
              parameters: parameters,
              extensions: const {'workshopScope': true}).toJson()
        });
        await send('apply', {
          'projectHandle': opened['projectHandle'],
          'planId': planned['planId'],
          'operationId': 'field-cli'
        });
        final after = MapData.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>);
        expect(
            isValidSpatialFieldObstacle(after, after.entities.single), isTrue);
        expect(after.entities.single.fieldObstacle!.resetPolicy,
            FieldObstacleResetPolicy.persistent);
        await send('close', {'workspaceHandle': opened['workspaceHandle']});
      } finally {
        await process.stdin.close();
        await process.exitCode.timeout(const Duration(seconds: 20),
            onTimeout: () {
          process.kill();
          return -1;
        });
        await lines.cancel();
        expect(await errors, isEmpty);
      }
    });
  }
  test(
      'model obstacle action creates one bound canonical entity in one map change',
      () {
    final before = obstacleMap();
    final draft = configureDraft(
        before, {'kind': 'cutTree', 'resetPolicy': 'persistent'});
    final after = resultMap(draft);
    final entity = after.entities.single;
    expect(
        entity.fieldObstacle,
        const MapEntityFieldObstacleData(
            resetPolicy: FieldObstacleResetPolicy.persistent));
    expect(after.spatialScene!.instances.single.entityId, entity.id);
    expect(entity.pos, const GridPos(x: 2, y: 3));
    expect(isValidSpatialFieldObstacle(after, entity), isTrue);
    expect(draft.changeSet.changes.single.storageKey, 'maps/route.json');
    expect(
        resultMap(configureDraft(before, {
          'kind': 'rockSmashRock',
          'resetPolicy': 'mapInstance'
        })).entities.single.id,
        entity.id);
  });

  test(
      'model obstacle reuses a custom entity and clear retains its identity and data',
      () {
    var map = obstacleMap();
    map = map.copyWith(
        entities: [
          const MapEntity(
              id: 'custom',
              name: 'My tree',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 2, y: 3),
              properties: {'original': 'yes'})
        ],
        spatialScene: map.spatialScene!.copyWith(instances: [
          map.spatialScene!.instances.single.copyWith(entityId: 'custom')
        ]));
    final after = resultMap(configureDraft(
        map, {'kind': 'rockSmashRock', 'resetPolicy': 'mapInstance'}));
    expect(after.entities.single.id, 'custom');
    expect(after.entities.single.properties, {'original': 'yes'});
    expect(resultMap(configureDraft(after, null)), map);
  });

  test('entity obstacle action accepts an existing valid 3D binding', () {
    final map = resultMap(configureDraft(
        obstacleMap(), {'kind': 'cutTree', 'resetPolicy': 'mapInstance'}));
    final draft = const EntityActions().build(catalogContext(
        catalogSnapshot([map], project: obstacleProject()),
        'entity.set_field_obstacle', {
      'mapId': 'route',
      'entityId': map.entities.single.id,
      'fieldObstacle': {'kind': 'rockSmashRock', 'resetPolicy': 'persistent'}
    }));
    expect(resultMap(draft).entities.single.fieldObstacle!.kind,
        FieldObstacleKind.rockSmashRock);
  });

  for (final kind in ['strengthBoulder', 'iceBlock']) {
    test('3D model obstacle refuses $kind', () {
      expect(
          () => configureDraft(
              obstacleMap(), {'kind': kind, 'resetPolicy': 'mapInstance'}),
          throwsA(isA<MapAuthoringException>()));
    });
  }
  test(
      'model obstacle refuses animated or nonblocking instances and occupied bindings',
      () {
    final map = obstacleMap();
    for (final instance in [
      map.spatialScene!.instances.single.copyWith(blocksMovement: false),
      map.spatialScene!.instances.single.copyWith(animationIndex: 0)
    ]) {
      expect(
          () => configureDraft(
              map.copyWith(
                  spatialScene:
                      map.spatialScene!.copyWith(instances: [instance])),
              {'kind': 'cutTree', 'resetPolicy': 'mapInstance'}),
          throwsA(isA<MapAuthoringException>()));
    }
    final occupied = map.copyWith(
        entities: [
          const MapEntity(
              id: 'sign',
              name: 'Sign',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 2, y: 3),
              sign: MapEntitySignData(plainText: 'Hello'))
        ],
        spatialScene: map.spatialScene!.copyWith(instances: [
          map.spatialScene!.instances.single.copyWith(entityId: 'sign')
        ]));
    expect(
        () => configureDraft(
            occupied, {'kind': 'cutTree', 'resetPolicy': 'mapInstance'}),
        throwsA(isA<MapAuthoringException>()));
  });
}
