import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('regional map semantic actions survive direct and JSONL transactions',
      () async {
    final setup = await _RegionalMapSetup.create();
    addTearDown(setup.dispose);
    final opened = await setup.readApi.openProject(setup.root.path);
    await setup.mutations.attachProject(
        projectRootPath: setup.root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() => setup.readApi.closeWorkspace(opened.workspaceHandle));
    var sequence = 0;
    Future<void> apply(String action, Map<String, Object?> parameters,
        {bool jsonl = false}) async {
      sequence += 1;
      final snapshot = await setup.snapshots.load(opened.projectHandle);
      final request = AuthoringRequest(
          requestId: 'region-$sequence',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'region-$sequence');
      if (jsonl) {
        final planned = await setup.request('plan', args: {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        });
        expect(planned.status, AuthoringResultStatus.success,
            reason: planned.toJson().toString());
        String? confirmation;
        if (action.endsWith('.delete')) {
          final confirmed = await setup.request('confirm', args: {
            'projectHandle': opened.projectHandle.value,
            'planId': planned.data['planId']
          });
          expect(confirmed.status, AuthoringResultStatus.success);
          confirmation = confirmed.data['confirmationToken'] as String;
        }
        final applied = await setup.request('apply', args: {
          'projectHandle': opened.projectHandle.value,
          'planId': planned.data['planId'],
          'operationId': 'region-operation-$sequence',
          if (confirmation != null) 'confirmationToken': confirmation
        });
        expect(applied.status, AuthoringResultStatus.success,
            reason: applied.toJson().toString());
      } else {
        final planned =
            await setup.mutations.planMutation(opened.projectHandle, request);
        final confirmation = action.endsWith('.delete')
            ? await setup.mutations.confirmMutation(opened.projectHandle,
                planId: planned.plan.planId)
            : null;
        final applied = await setup.mutations.applyMutation(
            opened.projectHandle,
            planId: planned.plan.planId,
            operationId: 'region-operation-$sequence',
            confirmationToken: confirmation?.confirmationToken);
        expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      }
    }

    final region = ProjectRegionDefinition(id: 'west', label: 'West');
    final point = ProjectRegionPointOfInterest(
        id: 'town-poi',
        regionId: 'west',
        label: 'Town',
        u: 0.2,
        v: 0.8,
        mapIds: const ['town']);
    await apply('regionalMap.region.upsert', {'region': region.toJson()});
    await apply('regionalMap.poi.upsert', {'poi': point.toJson()}, jsonl: true);
    final queried = await setup.request('query', args: {
      'projectHandle': opened.projectHandle.value,
      'request': AuthoringQueryRequest(
              resourceKind: 'regionalMapPoi',
              operation: AuthoringQueryOperation.get,
              ids: const ['town-poi'],
              view: AuthoringQueryView.detail)
          .toJson()
    });
    expect(queried.status, AuthoringResultStatus.success);
    expect((queried.data['items'] as List).single['mapIds'], ['town']);
    final validation =
        await setup.readApi.validateProject(opened.projectHandle);
    expect(
        validation.references.diagnostics
            .where((d) => d.code.startsWith('regional_map.')),
        isEmpty);
    final snapshot = await setup.snapshots.load(opened.projectHandle);
    await expectLater(
      setup.mutations.planMutation(
          opened.projectHandle,
          AuthoringRequest(
              requestId: 'referenced-map',
              actionId: 'map.delete_apply',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              parameters: const {'mapId': 'town'},
              expectedRevision: snapshot.revision,
              idempotencyKey: 'referenced-map')),
      throwsA(isA<MapAuthoringException>()
          .having((error) => error.code, 'code', 'map.references_blocking')),
    );
    await expectLater(
        setup.mutations.planMutation(
            opened.projectHandle,
            AuthoringRequest(
                requestId: 'invalid-region',
                actionId: 'regionalMap.region.delete',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                parameters: const {'regionId': 'west'},
                expectedRevision: snapshot.revision,
                idempotencyKey: 'invalid-region')),
        throwsA(isA<MapAuthoringException>()));
    await apply('regionalMap.poi.delete', const {'poiId': 'town-poi'},
        jsonl: true);
    await apply('regionalMap.region.delete', const {'regionId': 'west'},
        jsonl: true);
    await apply('regionalMap.region.upsert', {'region': region.toJson()},
        jsonl: true);
    await apply('regionalMap.poi.upsert', {'poi': point.toJson()});
    await apply('regionalMap.poi.delete', const {'poiId': 'town-poi'});
    await apply('regionalMap.region.delete', const {'regionId': 'west'});
    final reloaded = await setup.snapshots.load(opened.projectHandle);
    expect(reloaded.manifest.regionalMap, isNotNull);
    expect(reloaded.manifest.regionalMap!.regions, isEmpty);
  });

  for (final spawnId in ['arrival-entity', 'arrival-key']) {
    for (final jsonl in [false, true]) {
      test(
          'destination $spawnId protects entity mutations through ${jsonl ? 'JSONL' : 'direct API'}',
          () async {
        const spawn = MapEntity(
          id: 'arrival-entity',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          spawn: MapEntitySpawnData(spawnKey: 'arrival-key'),
        );
        final manifest = _manifest.copyWith(
            regionalMap: ProjectRegionalMapCatalog(
          regions: [ProjectRegionDefinition(id: 'west', label: 'West')],
          pointsOfInterest: [
            ProjectRegionPointOfInterest(
                id: 'town-poi',
                regionId: 'west',
                label: 'Town',
                u: .2,
                v: .8,
                mapIds: const ['town'],
                destination:
                    ProjectRegionDestination(mapId: 'town', spawnId: spawnId))
          ],
        ));
        final setup = await _RegionalMapSetup.create(manifest: manifest, maps: [
          _maps.single.copyWith(entities: [spawn])
        ]);
        addTearDown(setup.dispose);
        final opened = await setup.readApi.openProject(setup.root.path);
        addTearDown(() => setup.readApi.closeWorkspace(opened.workspaceHandle));
        await setup.mutations.attachProject(
            projectRootPath: setup.root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
        final before = await setup.snapshots.load(opened.projectHandle);
        final mapFile = File('${setup.root.path}/maps/town.json');
        final projectFile = File('${setup.root.path}/project.json');
        final beforeMap = await mapFile.readAsBytes();
        final beforeProject = await projectFile.readAsBytes();
        var sequence = 0;
        AuthoringRequest request(
            String action, Map<String, Object?> parameters) {
          sequence += 1;
          return AuthoringRequest(
              requestId: 'spawn-$sequence',
              actionId: action,
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              parameters: {'mapId': 'town', ...parameters},
              expectedRevision: before.revision,
              idempotencyKey: 'spawn-$sequence');
        }

        final invalidActions = <(String, Map<String, Object?>)>[
          ('entity.delete', {'entityId': spawn.id}),
          (
            'entity.update',
            {
              'entityId': spawn.id,
              'entity': spawn
                  .copyWith(
                      id: 'renamed',
                      spawn: const MapEntitySpawnData(spawnKey: 'renamed-key'))
                  .toJson()
            }
          ),
          (
            'entity.upsert',
            {
              'entity': spawn
                  .copyWith(kind: MapEntityKind.custom, spawn: null)
                  .toJson()
            }
          ),
          if (spawnId == 'arrival-key') ...[
            (
              'entity.set_spawn_payload',
              {
                'entityId': spawn.id,
                'payload':
                    const MapEntitySpawnData(spawnKey: 'renamed-key').toJson()
              }
            ),
            ('entity.clear_payload', {'entityId': spawn.id}),
          ],
        ];
        for (final (action, parameters) in invalidActions) {
          final mutation = request(action, parameters);
          if (jsonl) {
            final planned = await setup.request('plan', args: {
              'projectHandle': opened.projectHandle.value,
              'request': mutation.toJson()
            });
            expect(planned.status, AuthoringResultStatus.failure,
                reason: action);
            expect(planned.error?.details['domainCode'],
                'regional_map.destination_spawn_missing',
                reason: action);
          } else {
            await expectLater(
                setup.mutations.planMutation(opened.projectHandle, mutation),
                throwsA(isA<MapAuthoringException>().having(
                    (error) => error.code,
                    'code',
                    'regional_map.destination_spawn_missing')),
                reason: action);
          }
          expect((await setup.snapshots.load(opened.projectHandle)).revision,
              before.revision);
          expect(await mapFile.readAsBytes(), beforeMap);
          expect(await projectFile.readAsBytes(), beforeProject);
        }
        final move =
            request('entity.move', {'entityId': spawn.id, 'x': 1, 'y': 1});
        if (jsonl) {
          final planned = await setup.request('plan', args: {
            'projectHandle': opened.projectHandle.value,
            'request': move.toJson()
          });
          expect(planned.status, AuthoringResultStatus.success,
              reason: planned.toJson().toString());
          final applied = await setup.request('apply', args: {
            'projectHandle': opened.projectHandle.value,
            'planId': planned.data['planId'],
            'operationId': 'spawn-move'
          });
          expect(applied.status, AuthoringResultStatus.success,
              reason: applied.toJson().toString());
        } else {
          final planned =
              await setup.mutations.planMutation(opened.projectHandle, move);
          final applied = await setup.mutations.applyMutation(
              opened.projectHandle,
              planId: planned.plan.planId,
              operationId: 'spawn-move');
          expect(applied.receipt.status, AuthoringReceiptStatus.applied);
        }
        final after = await setup.snapshots.load(opened.projectHandle);
        expect(after.mapById('town')!.entities.single.pos,
            const GridPos(x: 1, y: 1));
        expect(after.revision, isNot(before.revision));
        expect(after.manifest.regionalMap!.toJson(),
            manifest.regionalMap!.toJson());
      });
    }
  }
}

final class _RegionalMapSetup {
  const _RegionalMapSetup({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_RegionalMapSetup> create(
      {ProjectManifest manifest = _manifest,
      List<MapData> maps = _maps}) async {
    final root = await Directory.systemTemp.createTemp('jsonl-regional-map-');
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    for (final map in maps) {
      await File('${root.path}/maps/${map.id}.json').writeAsBytes(
        encodeMapAuthoringDocument(map),
        flush: true,
      );
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _RegionalMapSetup(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<AuthoringResult> request(
    String command, {
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode(<String, Object?>{
          'id': 'jsonl-region-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    return AuthoringResult.fromJson(decoded);
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

const _manifest = ProjectManifest(name: 'Region transport fixture', maps: [
  ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json')
], tilesets: []);
const _maps = [
  MapData(
      id: 'town',
      name: 'Town',
      version: ProjectVersion.v6,
      visualStack: MapVisualStackConfig.canonicalV1,
      size: GridSize(width: 3, height: 3),
      layers: [])
];
