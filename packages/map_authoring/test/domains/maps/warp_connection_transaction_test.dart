import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('WarpConnectionActions', () {
    test('reciprocal warp is one recoverable two-map change set', () async {
      final source = _map('alpha');
      final target = _map('beta');
      final snapshot = _snapshot([source, target]);
      final request = _request(
        snapshot,
        actionId: 'warp.create_reciprocal_apply',
        parameters: {
          'mapId': 'alpha',
          'warp': const MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'beta',
            targetPos: GridPos(x: 2, y: 1),
            allowedApproachFacings: [EntityFacing.east],
          ).toJson(),
          'reciprocalWarpId': 'to_alpha',
        },
      );
      final actions = const WarpConnectionActions();
      final draft = actions.build(_context(snapshot, request));

      expect(
        draft.changeSet.changes.map((change) => change.resource.id),
        ['alpha', 'beta'],
      );
      expect(draft.preview['multiMapGuarantee'], 'recoverable');
      final projected = _projectedMaps(draft);
      expect(projected['alpha']!.warps.single.id, 'to_beta');
      expect(
          projected['beta']!.warps.single,
          const MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 2, y: 1),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 1, y: 1),
            allowedApproachFacings: [EntityFacing.west],
          ));
      expect(
        actions.validateWarpPairs(projected.values.toList()),
        isEmpty,
      );

      await _proveRecovery(snapshot, request);
    });

    test('invalid warp target is rejected before a draft exists', () {
      final snapshot = _snapshot([_map('alpha')]);
      final request = _request(
        snapshot,
        actionId: 'warp.create',
        parameters: {
          'mapId': 'alpha',
          'warp': const MapWarp(
            id: 'missing',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'missing_map',
            targetPos: GridPos(x: 0, y: 0),
          ).toJson(),
        },
      );

      expect(
        () => const WarpConnectionActions().build(
          _context(snapshot, request),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'warp.target_map_missing',
          ),
        ),
      );
    });

    test('bidirectional connection updates both maps and previews overlap', () {
      final snapshot = _snapshot([
        _map('alpha', width: 4, height: 3),
        _map('beta', width: 3, height: 3),
      ]);
      final request = _request(
        snapshot,
        actionId: 'connection.create_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
          'targetMapId': 'beta',
          'offset': 1,
        },
      );

      final draft = const WarpConnectionActions().build(
        _context(snapshot, request),
      );
      final projected = _projectedMaps(draft);

      expect(
          projected['alpha']!.connections.single,
          const MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'beta',
            offset: 1,
          ));
      expect(
          projected['beta']!.connections.single,
          const MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'alpha',
            offset: -1,
          ));
      expect(draft.preview['overlapLength'], 2);
      expect(draft.changeSet.changes, hasLength(2));
    });

    test('pair update and delete keep reciprocal warp fields coherent', () {
      final source = _map('alpha').copyWith(
        warps: const [
          MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'beta',
            targetPos: GridPos(x: 2, y: 1),
            allowedApproachFacings: [EntityFacing.east],
          ),
        ],
      );
      final target = _map('beta').copyWith(
        warps: const [
          MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 2, y: 1),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 1, y: 1),
            allowedApproachFacings: [EntityFacing.west],
          ),
        ],
      );
      final snapshot = _snapshot([source, target]);
      final update = _request(
        snapshot,
        actionId: 'warp.update_pair_apply',
        parameters: {
          'mapId': 'alpha',
          'warpId': 'to_beta',
          'reciprocalWarpId': 'to_alpha',
          'warp': const MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 0, y: 1),
            targetMapId: 'beta',
            targetPos: GridPos(x: 1, y: 0),
            triggerMode: MapWarpTriggerMode.onBump,
            allowedApproachFacings: [EntityFacing.north],
          ).toJson(),
        },
      );
      final updated = _projectedMaps(
        const WarpConnectionActions().build(_context(snapshot, update)),
      );

      expect(
          updated['beta']!.warps.single,
          const MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 1, y: 0),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 0, y: 1),
            triggerMode: MapWarpTriggerMode.onBump,
            allowedApproachFacings: [EntityFacing.south],
          ));

      final updatedSnapshot = _snapshot(updated.values.toList());
      final deletion = _request(
        updatedSnapshot,
        actionId: 'warp.delete_pair_apply',
        parameters: const {
          'mapId': 'alpha',
          'warpId': 'to_beta',
          'reciprocalWarpId': 'to_alpha',
        },
      );
      final deleted = _projectedMaps(
        const WarpConnectionActions().build(
          _context(updatedSnapshot, deletion),
        ),
      );
      expect(deleted['alpha']!.warps, isEmpty);
      expect(deleted['beta']!.warps, isEmpty);
    });

    test('bidirectional update and delete keep inverse offsets coherent', () {
      final source = _map('alpha').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'beta',
          ),
        ],
      );
      final target = _map('beta').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'alpha',
          ),
        ],
      );
      final snapshot = _snapshot([source, target]);
      final update = _request(
        snapshot,
        actionId: 'connection.update_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
          'targetMapId': 'beta',
          'offset': 1,
        },
      );
      final updated = _projectedMaps(
        const WarpConnectionActions().build(_context(snapshot, update)),
      );
      expect(updated['alpha']!.connections.single.offset, 1);
      expect(updated['beta']!.connections.single.offset, -1);

      final updatedSnapshot = _snapshot(updated.values.toList());
      final deletion = _request(
        updatedSnapshot,
        actionId: 'connection.delete_bidirectional_apply',
        parameters: const {'mapId': 'alpha', 'direction': 'east'},
      );
      final deleted = _projectedMaps(
        const WarpConnectionActions().build(
          _context(updatedSnapshot, deletion),
        ),
      );
      expect(deleted['alpha']!.connections, isEmpty);
      expect(deleted['beta']!.connections, isEmpty);
    });

    test('dispatcher exposes canonical warp and connection mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        ids,
        containsAll({
          'warp.create',
          'warp.update',
          'warp.delete',
          'warp.create_reciprocal_apply',
          'warp.update_pair_apply',
          'warp.delete_pair_apply',
          'connection.upsert',
          'connection.delete',
          'connection.create_bidirectional_apply',
          'connection.update_bidirectional_apply',
          'connection.delete_bidirectional_apply',
        }),
      );
    });
  });

  group('WorldGraphQueries', () {
    test('is deterministic and keeps disconnected maps explicit', () {
      final alpha = _map('alpha').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'beta',
          ),
        ],
      );
      final beta = _map('beta').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'alpha',
          ),
        ],
        warps: const [
          MapWarp(
            id: 'to_gamma',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'gamma',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final snapshot = _snapshot([
        _map('isolated'),
        _map('gamma'),
        beta,
        alpha,
      ]);
      const queries = WorldGraphQueries();

      final first = queries.inspect(snapshot);
      final second = queries.inspect(snapshot);
      expect(second.toJson(), first.toJson());
      expect(first.nodes, ['alpha', 'beta', 'gamma', 'isolated']);
      expect(queries.listConnected(snapshot, fromMapId: 'alpha'),
          ['alpha', 'beta', 'gamma']);
      expect(
          queries.listDisconnected(snapshot, fromMapId: 'alpha'), ['isolated']);
      expect(
          queries.findPath(
            snapshot,
            sourceMapId: 'alpha',
            targetMapId: 'gamma',
          ),
          ['alpha', 'beta', 'gamma']);
      expect(queries.validateConsistency(snapshot), isEmpty);

      final renderModel = queries.render(snapshot).toJson();
      expect(renderModel['hasPersistentLayout'], isFalse);
      expect(renderModel.containsKey('worldLayout'), isFalse);
    });
  });

  test('map render requests require a revision-bound map resource', () {
    final map = _map('alpha');
    final snapshot = _snapshot([map]);
    final revision = snapshot.resourceFingerprints['map:alpha']!;
    final request = MapRenderRequest(
      mapResource: AuthoringResourceRef(
        kind: 'map',
        id: 'alpha',
        revision: revision,
      ),
      manifest: snapshot.manifest,
      map: map,
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 2),
      ),
      overlays: const {
        MapRenderOverlay.collision,
        MapRenderOverlay.zones,
        MapRenderOverlay.warps,
        MapRenderOverlay.entities,
      },
    );

    expect(request.revision, revision);
    expect(request.region.size, const GridSize(width: 2, height: 2));
    expect(
      () => MapRenderRequest(
        mapResource: AuthoringResourceRef(kind: 'map', id: 'alpha'),
        manifest: snapshot.manifest,
        map: map,
      ),
      throwsArgumentError,
    );
  });

  test('map render queries bind the exact snapshot revision and region',
      () async {
    final map = _map('alpha');
    final snapshot = _snapshot([map]);
    final port = _RecordingMapRenderPort();
    final result = await MapRenderQueries(port).renderRegion(
      snapshot: snapshot,
      mapId: 'alpha',
      region: const MapRect(
        pos: GridPos(x: 1, y: 0),
        size: GridSize(width: 2, height: 1),
      ),
      layerIds: const ['base'],
      overlays: const [MapRenderOverlay.warps],
      cellPixelSize: 3,
    );

    expect(
      port.request!.revision,
      snapshot.resourceFingerprints['map:alpha'],
    );
    expect(port.request!.region.pos, const GridPos(x: 1, y: 0));
    expect(result.sourceRevision, port.request!.revision);
  });

  test('map render queries reject a stale adapter result', () async {
    final map = _map('alpha');
    final snapshot = _snapshot([map]);
    final port = _RecordingMapRenderPort(sourceRevision: _fakeRevision('f'));

    await expectLater(
      () => MapRenderQueries(port).renderMap(
        snapshot: snapshot,
        mapId: 'alpha',
      ),
      throwsA(
        isA<ProjectSnapshotException>().having(
          (error) => error.code,
          'code',
          'map.render_revision_mismatch',
        ),
      ),
    );
  });
}

final class _RecordingMapRenderPort implements MapRenderPort {
  _RecordingMapRenderPort({this.sourceRevision});

  final String? sourceRevision;
  MapRenderRequest? request;

  @override
  Future<MapRenderResult> render(MapRenderRequest request) async {
    this.request = request;
    return MapRenderResult(
      mimeType: 'image/png',
      bytes: const [1],
      width: request.region.size.width * request.cellPixelSize,
      height: request.region.size.height * request.cellPixelSize,
      sourceRevision: sourceRevision ?? request.revision,
      region: request.region,
      layerIds: request.layerIds,
      overlays: request.overlays,
    );
  }
}

Future<void> _proveRecovery(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) async {
  final directory = await Directory.systemTemp.createTemp('pmcp_035_pair_');
  addTearDown(() => directory.delete(recursive: true));
  final mapsDirectory = await Directory(
    '${directory.path}${Platform.pathSeparator}maps',
  ).create();
  for (final map in snapshot.maps) {
    await File('${mapsDirectory.path}${Platform.pathSeparator}${map.id}.json')
        .writeAsBytes(snapshot.resourceBytes('map:${map.id}'));
  }

  final now = DateTime.utc(2026, 7, 31, 15);
  var token = 0;
  final store = AuthoringPlanStore(clock: () => now);
  final plan = await AuthoringActionPlanner(
    store: store,
    tokenFactory: (prefix) => '$prefix${token++}',
    seedFactory: () => 35,
  ).plan(
    request: request,
    snapshot: snapshot,
    build: const WarpConnectionActions().build,
  );
  final gateway = await LocalTransactionFileGateway.open(
    projectRoot: directory.path,
  );
  final ledgerPath = [
    directory.path,
    '.pokemap',
    'authoring',
    'idempotency.jsonl',
  ].join(Platform.pathSeparator);
  final scope = AuthoringIdempotencyScope(
    actorId: 'pmcp-035',
    projectId: 'pair-project',
    actionId: request.actionId,
    actionVersion: request.actionVersion,
    key: request.idempotencyKey!,
  );
  var crashed = false;
  final transaction = JournaledAuthoringTransaction(
    plans: store,
    gateway: gateway,
    idempotency: AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(filePath: ledgerPath),
      clock: () => now,
    ),
    clock: () => now,
    faultInjector: (context) {
      if (!crashed &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.promotionIndex == 0) {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );

  await expectLater(
    () => transaction.apply(
      planId: plan.planId,
      request: request,
      currentProjectRevision: snapshot.revision,
      scope: scope,
      operationId: 'operation-pmcp-035',
    ),
    throwsA(isA<AuthoringTransactionSimulatedCrash>()),
  );

  final alphaAfterCrash = await _readMap(directory, 'alpha');
  final betaAfterCrash = await _readMap(directory, 'beta');
  expect(alphaAfterCrash.warps, hasLength(1));
  expect(betaAfterCrash.warps, isEmpty);

  final recovery = AuthoringRecoveryService(
    gateway: await LocalTransactionFileGateway.open(
      projectRoot: directory.path,
    ),
    idempotency: AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(filePath: ledgerPath),
      clock: () => now,
    ),
    clock: () => now,
  );
  final receipt = await recovery.resume('operation-pmcp-035');
  expect(receipt.status, AuthoringReceiptStatus.recovered);
  expect((await _readMap(directory, 'alpha')).warps.single.id, 'to_beta');
  expect((await _readMap(directory, 'beta')).warps.single.id, 'to_alpha');
}

Future<MapData> _readMap(Directory root, String id) async {
  final bytes = await File([
    root.path,
    'maps',
    '$id.json',
  ].join(Platform.pathSeparator))
      .readAsBytes();
  return MapData.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );
}

Map<String, MapData> _projectedMaps(AuthoringMutationDraft draft) => {
      for (final change in draft.changeSet.changes)
        change.resource.id: MapData.fromJson(
          jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
        ),
    };

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: 'plan-pmcp-035',
      seed: 35,
    );

AuthoringRequest _request(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringRequest(
      requestId: 'request-$actionId',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace:pmcp-035',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idempotency-$actionId',
    );

ProjectSnapshot _snapshot(List<MapData> maps) {
  final entries = [
    for (final map in maps)
      ProjectMapEntry(
        id: map.id,
        name: map.name,
        relativePath: 'maps/${map.id}.json',
      ),
  ];
  final manifest = ProjectManifest(
    name: 'PMCP-035',
    maps: entries,
    tilesets: const [],
  );
  final bytes = <String, List<int>>{
    'project': utf8.encode(jsonEncode(manifest.toJson())),
    for (final map in maps) 'map:${map.id}': encodeMapAuthoringDocument(map),
  };
  final fingerprints = <String, String>{
    'project': computeAuthoringBytesFingerprint(
      bytes['project']!,
      logicalName: 'project.json',
    ),
    for (final map in maps)
      'map:${map.id}': computeAuthoringBytesFingerprint(
        bytes['map:${map.id}']!,
        logicalName: 'maps/${map.id}.json',
      ),
  };
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('project:pmcp-035'),
    revision: computeAuthoringJsonFingerprint(
      fingerprints,
      logicalName: 'pmcp-035-snapshot.json',
    ),
    manifest: manifest,
    maps: maps,
    resourceFingerprints: fingerprints,
    resourceBytes: bytes,
  );
}

MapData _map(
  String id, {
  int width = 4,
  int height = 3,
}) =>
    MapData(
      id: id,
      name: id,
      size: GridSize(width: width, height: height),
      layers: [
        MapLayer.tile(
          id: 'base',
          name: 'Base',
          cells: List<int>.filled(width * height, 0),
        ),
      ],
    );

String _fakeRevision(String digit) =>
    'sha256:${List<String>.filled(64, digit).join()}';
