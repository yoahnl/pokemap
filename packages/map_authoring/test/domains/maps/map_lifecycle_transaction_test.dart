import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalMapAuthoringMutationApi lifecycle', () {
    test('plans, applies, records, and undoes map creation', () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'route_01',
          'name': 'Route 01',
          'width': 3,
          'height': 2,
        },
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      expect(planned['plan'], isA<Map<String, Object?>>());
      expect(
        (planned['receipt']! as Map<String, Object?>)['status'],
        'planned',
      );
      expect(
        await File('${setup.root.path}/maps/route_01.json').exists(),
        isFalse,
      );

      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_create_route_01',
      );
      final receipt = applied['receipt']! as Map<String, Object?>;
      expect(receipt['status'], 'applied');
      expect(applied['snapshotRevision'], startsWith('sha256:'));
      final mapFile = File('${setup.root.path}/maps/route_01.json');
      expect(await mapFile.exists(), isTrue);
      expect(
        MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        ).name,
        'Route 01',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps.single.id,
        'route_01',
      );

      final undone = await setup.mutations.undo(
        setup.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem_undo_route_01',
      );
      expect(
        (undone['receipt']! as Map<String, Object?>)['actionId'],
        'history.undo',
      );
      expect(await mapFile.exists(), isFalse);
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps,
        isEmpty,
      );
    });

    test('marks dry-run plans non-applicable before confirm or apply',
        () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'dry_run_map',
          'width': 2,
          'height': 2,
        },
        dryRun: true,
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      expect(planned['applicable'], isFalse);
      expect(
        (planned['plan']! as Map<String, Object?>)['applicable'],
        isFalse,
      );
      expect(
        (planned['plan']! as Map<String, Object?>)['nonApplicableReason'],
        'dry_run',
      );

      for (final attempt in <Future<Object?> Function()>[
        () => setup.mutations.confirm(
              setup.projectHandle,
              planId: planned['planId']! as String,
            ),
        () => setup.mutations.apply(
              setup.projectHandle,
              planId: planned['planId']! as String,
              operationId: 'operation_dry_run_must_not_apply',
            ),
      ]) {
        await expectLater(
          attempt,
          throwsA(
            isA<AuthoringPlanException>().having(
              (error) => error.code,
              'code',
              'plan.dry_run_not_applicable',
            ),
          ),
        );
      }
      expect(
        await File('${setup.root.path}/maps/dry_run_map.json').exists(),
        isFalse,
      );
    });

    test('requires one-use confirmation for destructive deletion', () async {
      final setup = await _Setup.create(
        maps: [_map('town')],
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.delete_apply',
        parameters: const {'mapId': 'town'},
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_delete_town_denied',
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'confirmation.required',
          ),
        ),
      );
      final confirmation = await setup.mutations.confirm(
        setup.projectHandle,
        planId: planned['planId']! as String,
      );
      final token = confirmation['confirmationToken']! as String;
      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_delete_town',
        confirmationToken: token,
      );
      expect(
        (applied['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      expect(await File('${setup.root.path}/maps/town.json').exists(), isFalse);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_delete_town_reuse',
          confirmationToken: token,
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'confirmation.used',
          ),
        ),
      );
    });

    test('recovers manifest plus map after a crash between promotions',
        () async {
      var crash = true;
      final setup = await _Setup.create(
        faultInjector: (context) {
          if (crash &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'recovered_map',
          'width': 2,
          'height': 2,
        },
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_recovered_map',
        ),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      expect(
        await File('${setup.root.path}/maps/recovered_map.json').exists(),
        isTrue,
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps,
        isEmpty,
      );

      crash = false;
      final recovered = await setup.mutations.recover(
        setup.projectHandle,
        operationId: 'operation_recovered_map',
      );
      expect(
        (recovered['receipt']! as Map<String, Object?>)['status'],
        'recovered',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps.single.id,
        'recovered_map',
      );
    });
  });
}

final class _Setup {
  _Setup._({
    required this.root,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
  });

  static Future<_Setup> create({
    List<MapData> maps = const [],
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final root = await Directory.systemTemp.createTemp('map-lifecycle-');
    final manifest = ProjectManifest(
      name: 'Lifecycle Transaction Fixture',
      version: ProjectVersion.v3,
      maps: [
        for (final map in maps)
          ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
      ],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    if (maps.isNotEmpty) {
      await Directory('${root.path}/maps').create();
      for (final map in maps) {
        await File('${root.path}/maps/${map.id}.json').writeAsBytes(
          encodeMapAuthoringDocument(map),
          flush: true,
        );
      }
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '${prefix}fixture',
    );
    final open = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await open.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      faultInjector: faultInjector,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Setup._(
      root: root,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;

  Future<AuthoringRequest> requestAsync({
    required String actionId,
    required Map<String, Object?> parameters,
    bool dryRun = false,
  }) async {
    final snapshot = await snapshots.load(projectHandle);
    return AuthoringRequest(
      requestId: 'request_${actionId.replaceAll('.', '_')}',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
      dryRun: dryRun,
    );
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tiles: List<int>.filled(4, 0),
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: List<TerrainType>.filled(4, TerrainType.none),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List<bool>.filled(4, false),
        ),
      ],
    );
