import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'map_catalog_fixture.dart';

MapData divePairMap(String id, DiveZoneRole role) =>
    catalogMap(id).copyWith(entities: [
      MapEntity(
          id: '$id-spawn',
          kind: MapEntityKind.spawn,
          pos: const GridPos(x: 2, y: 2),
          spawn: const MapEntitySpawnData())
    ], gameplayZones: [
      MapGameplayZone(
          id: 'terrain',
          kind: GameplayZoneKind.movement,
          area: const MapRect(
              pos: GridPos(x: 0, y: 0), size: GridSize(width: 6, height: 5)),
          movement: MovementZonePayload(
              requiredMode: role == DiveZoneRole.surface
                  ? MovementMode.surf
                  : MovementMode.dive)),
      MapGameplayZone(
          id: 'point',
          kind: GameplayZoneKind.fieldAction,
          area: const MapRect(
              pos: GridPos(x: 2, y: 2), size: GridSize(width: 1, height: 1)),
          fieldAction: FieldActionZonePayload(
              actionKind: FieldActionZoneKind.dive,
              dive: DiveZonePayload(role: role, arrivalSpawnId: '$id-spawn'))),
    ]);
List<MapData> coincidentDivePairMaps(DiveZoneRole role) {
  MapGameplayZone link(MapGameplayZone zone, String mapId, String zoneId) =>
      zone.copyWith(
          fieldAction: zone.fieldAction!.copyWith(
              dive: zone.fieldAction!.dive!
                  .copyWith(link: DiveZoneLink(mapId: mapId, zoneId: zoneId))));
  final source = divePairMap('sea', role);
  final opposite = role == DiveZoneRole.surface
      ? DiveZoneRole.underwater
      : DiveZoneRole.surface;
  final target = divePairMap('deep', opposite);
  final other = divePairMap('other', opposite);
  return [
    source.copyWith(gameplayZones: [
      source.gameplayZones.first,
      link(source.gameplayZones.last, 'deep', 'point'),
      link(source.gameplayZones.last.copyWith(id: 'second', priority: 10),
          'other', 'point')
    ]),
    target.copyWith(gameplayZones: [
      target.gameplayZones.first,
      link(target.gameplayZones.last, 'sea', 'point')
    ]),
    other.copyWith(gameplayZones: [
      other.gameplayZones.first,
      link(other.gameplayZones.last, 'sea', 'second')
    ]),
  ];
}

void main() {
  test(
      'publication explicitly rejects coincident Dive preparations on either endpoint',
      () {
    final sea = divePairMap('sea', DiveZoneRole.surface);
    final deep = divePairMap('deep', DiveZoneRole.underwater);
    for (final duplicateSource in [true, false]) {
      MapData duplicate(MapData map) => map.copyWith(gameplayZones: [
            ...map.gameplayZones,
            map.gameplayZones.last.copyWith(id: 'second', priority: 10)
          ]);
      final maps = [
        duplicateSource ? duplicate(sea) : sea,
        duplicateSource ? deep : duplicate(deep)
      ];
      final snapshot = catalogSnapshot(maps);
      for (final map in maps) {
        MapValidator.validate(map, projectDialogueContext: snapshot.manifest);
      }
      expect(
          () => const DivePairActions().build(catalogContext(
                  snapshot, 'gameplay_zone.dive.link_pair_apply', {
                'mapId': 'sea',
                'zoneId': 'point',
                'targetMapId': 'deep',
                'targetZoneId': 'point'
              })),
          throwsA(isA<MapAuthoringException>().having((error) => error.message,
              'message', contains('Plusieurs points de Plongée'))));
    }
  });
  test(
      'link and unlink publish exactly two reciprocal maps; clone stays preparation',
      () {
    final source = divePairMap('sea', DiveZoneRole.surface),
        target = divePairMap('deep', DiveZoneRole.underwater);
    final snapshot = catalogSnapshot([source, target]);
    final draft = const DivePairActions()
        .build(catalogContext(snapshot, 'gameplay_zone.dive.link_pair_apply', {
      'mapId': 'sea',
      'zoneId': 'point',
      'targetMapId': 'deep',
      'targetZoneId': 'point'
    }));
    expect(draft.changeSet.changes, hasLength(2));
    expect(draft.preview['multiMapGuarantee'], 'recoverable');
    final linked = projectedDiveMaps(draft);
    validateDiveZonePair(
        sourceMap: linked['sea']!,
        sourceZoneId: 'point',
        targetMap: linked['deep']!,
        targetZoneId: 'point');
    expect(diveZonePairDiagnostics(linked.values), isEmpty);
    final clone = const TriggerZoneActions().build(catalogContext(
        catalogSnapshot(linked.values.toList()),
        'gameplay_zone.clone',
        {'mapId': 'sea', 'zoneId': 'point', 'newId': 'copy', 'x': 3, 'y': 2}));
    final copied =
        projectedDiveMaps(clone)['sea']!.gameplayZones.last.fieldAction!.dive!;
    expect(copied.link, isNull);
    expect(copied.arrivalSpawnId, isNull);
    for (final action in [
      'gameplay_zone.delete',
      'gameplay_zone.clear_payload'
    ]) {
      expect(
          () => const TriggerZoneActions().build(catalogContext(
              catalogSnapshot(linked.values.toList()),
              action,
              {'mapId': 'sea', 'zoneId': 'point'})),
          throwsA(isA<MapAuthoringException>()));
    }
    final unlink = const DivePairActions().build(catalogContext(
        catalogSnapshot(linked.values.toList()),
        'gameplay_zone.dive.unlink_pair_apply',
        {'mapId': 'sea', 'zoneId': 'point'}));
    final preparations = projectedDiveMaps(unlink);
    expect(preparations['sea'], source);
    expect(preparations['deep'], target);
    expect(diveZonePairDiagnostics(preparations.values), hasLength(2));
  });
  test('pair refuses ambiguous, wrong-role, occupied and unsafe endpoints', () {
    final sea = divePairMap('sea', DiveZoneRole.surface),
        deep = divePairMap('deep', DiveZoneRole.underwater);
    for (final candidate in [
      deep.copyWith(entities: [deep.entities.single, deep.entities.single]),
      divePairMap('deep', DiveZoneRole.surface),
      deep.copyWith(entities: [
        ...deep.entities,
        const MapEntity(
            id: 'block',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 2, y: 2),
            sign: MapEntitySignData())
      ]),
      deep.copyWith(gameplayZones: [deep.gameplayZones.last])
    ]) {
      expect(
          () => const DivePairActions().build(catalogContext(
                  catalogSnapshot([sea, candidate]),
                  'gameplay_zone.dive.link_pair_apply', {
                'mapId': 'sea',
                'zoneId': 'point',
                'targetMapId': 'deep',
                'targetZoneId': 'point'
              })),
          throwsA(isA<MapAuthoringException>()));
    }
    expect(
        () => const TriggerZoneActions().setFieldActionPayload(sea,
            zoneId: 'point',
            payload: sea.gameplayZones.last.fieldAction!.copyWith(
                dive: sea.gameplayZones.last.fieldAction!.dive!.copyWith(
                    link: const DiveZoneLink(mapId: 'deep', zoneId: 'point')))),
        throwsA(isA<MapAuthoringException>()));
  });
  test('interrupted Dive publication resumes its exact second preimage',
      () async {
    final snapshot = catalogSnapshot([
      divePairMap('sea', DiveZoneRole.surface),
      divePairMap('deep', DiveZoneRole.underwater)
    ]);
    final request =
        catalogContext(snapshot, 'gameplay_zone.dive.link_pair_apply', {
      'mapId': 'sea',
      'zoneId': 'point',
      'targetMapId': 'deep',
      'targetZoneId': 'point'
    }).request;
    await proveDiveRecovery(snapshot, request);
  });
  test('Dive pair semantic actions are discoverable', () {
    final ids =
        MapMutationDispatcher.canonical().descriptors.map((entry) => entry.id);
    expect(
        ids,
        containsAll([
          'gameplay_zone.dive.link_pair_apply',
          'gameplay_zone.dive.unlink_pair_apply'
        ]));
  });
}

Map<String, MapData> projectedDiveMaps(AuthoringMutationDraft draft) => {
      for (final change in draft.changeSet.changes)
        change.resource.id: MapData.fromJson(
            jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>)
    };
Future<void> proveDiveRecovery(
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
    build: const DivePairActions().build,
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

  final alphaAfterCrash = await _readMap(directory, 'deep');
  final betaAfterCrash = await _readMap(directory, 'sea');
  expect(alphaAfterCrash.gameplayZones.last.fieldAction!.dive!.link, isNotNull);
  expect(betaAfterCrash.gameplayZones.last.fieldAction!.dive!.link, isNull);

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
  expect(
      (await _readMap(directory, 'deep'))
          .gameplayZones
          .last
          .fieldAction!
          .dive!
          .link!
          .mapId,
      'sea');
  expect(
      (await _readMap(directory, 'sea'))
          .gameplayZones
          .last
          .fieldAction!
          .dive!
          .link!
          .mapId,
      'deep');
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
