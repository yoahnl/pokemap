import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

MapGameplayZone _fixture() => MapGameplayZone.fromJson(jsonDecode(File(
      '../map_core/test/fixtures/whirlpool_field_zone.json',
    ).readAsStringSync()) as Map<String, dynamic>);

MapData _map() => catalogMap('whirls', width: 8, height: 8).copyWith(
      gameplayZones: const [
        MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 0, y: 0), size: GridSize(width: 8, height: 8)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf))
      ],
    );

void main() {
  test('Whirlpool is discoverable through the existing field action contract',
      () {
    final action = TriggerZoneActions.descriptors.singleWhere(
        (entry) => entry.id == 'gameplay_zone.set_field_action_payload');
    final contract = action.extensions['fieldActionZone'] as Map;
    expect(contract['actionKinds'], contains('whirlpool'));
    expect(contract['whirlpool'], {
      'required': ['entry', 'path', 'exit', 'direction'],
      'requiresSurf': true,
      'fieldAbility': 'whirlpool',
      'gate': ['consciousPartyMove', 'unlockedFieldAbility', 'surfMode'],
      'coordinateSpace': 'zoneRelative',
      'pathMinCells': 1,
      'pathMaxCells': 256,
      'directions': ['north', 'south', 'east', 'west'],
      'contiguous': true,
      'stepDurationMs': 250,
      'lifetime': 'traversal',
      'zonePersistence': 'persistent',
      'saveDuringTraversal': false,
      'checkpointDuringTraversal': false,
      'interruption': 'rollbackEntry',
      'arrivalMovementMode': 'surf',
      'intermediateTriggers': false,
      'consumesPp': false,
    });
  });

  test('Whirlpool semantic action refuses 3D and preserves the closed payload',
      () {
    final zone = _fixture();
    final map = _map().copyWith(
        version: ProjectVersion.v9,
        layers: const [],
        visualStack: null,
        spatialScene: MapSpatialScene(width: 8, depth: 8),
        gameplayZones: [
          zone.copyWith(
              fieldAction: const FieldActionZonePayload(
                  actionKind: FieldActionZoneKind.darkness,
                  darkness: DarknessZonePayload(opacity: .7)))
        ]);
    expect(
        () => const TriggerZoneActions().setFieldActionPayload(map,
            zoneId: zone.id, payload: zone.fieldAction!),
        throwsA(isA<Exception>()));
  });

  for (final jsonl in [false, true]) {
    test(
        'Whirlpool ${jsonl ? 'JSONL' : 'direct API'} requery refusal stale undo and cold reopen feed real movement',
        () async {
      final root =
          await Directory.systemTemp.createTemp('whirlpool-authoring-');
      addTearDown(() => root.delete(recursive: true));
      final zone = _fixture();
      final seed = zone.copyWith(
          fieldAction: const FieldActionZonePayload(
              actionKind: FieldActionZoneKind.darkness,
              darkness: DarknessZonePayload(opacity: .7)));
      final map = _map();
      final file = File('${root.path}/whirls.json');
      final projectFile = File('${root.path}/project.json');
      await file.writeAsString(jsonEncode(map.toJson()));
      await projectFile.writeAsString(jsonEncode(const ProjectManifest(
          name: 'Tourbillon',
          tilesets: [],
          maps: [
            ProjectMapEntry(
                id: 'whirls', name: 'Tourbillon', relativePath: 'whirls.json')
          ]).toJson()));
      final projectBefore = await projectFile.readAsBytes();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final loader = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: loader);
      final mutations =
          LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
      final worker = JsonlWorker(api: api, mutations: mutations);
      var sequence = 0;
      Future<AuthoringResult> wire(
              String command, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
              jsonEncode({
            'id': 'whirlpool-${sequence++}',
            'command': command,
            'args': args
          }))) as Map<String, dynamic>);
      final opened =
          jsonl ? (await wire('open', {'projectRoot': root.path})).data : null;
      final direct = jsonl ? null : await api.openProject(root.path);
      final projectHandle = jsonl
          ? ProjectHandle(opened!['projectHandle'] as String)
          : direct!.projectHandle;
      final workspaceHandle = jsonl
          ? WorkspaceHandle(opened!['workspaceHandle'] as String)
          : direct!.workspaceHandle;
      if (!jsonl) {
        await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: workspaceHandle,
            projectHandle: projectHandle);
      }
      Future<Map<String, Object?>> call(
          String command, Map<String, Object?> args) async {
        if (jsonl) {
          final result = await wire(
              command, {'projectHandle': projectHandle.value, ...args});
          expect(result.status, AuthoringResultStatus.success,
              reason: '${result.toJson()}');
          return result.data;
        }
        return switch (command) {
          'plan' => mutations.plan(
              projectHandle,
              AuthoringRequest.fromJson(
                  Map<String, dynamic>.from(args['request'] as Map))),
          'apply' => mutations.apply(projectHandle,
              planId: args['planId'] as String,
              operationId: args['operationId'] as String),
          'history' => mutations.history(projectHandle, limit: 1),
          'undo' => mutations.undo(projectHandle,
              entryId: args['entryId'] as String,
              idempotencyKey: args['idempotencyKey'] as String),
          'query' => api.query(
              projectHandle,
              AuthoringQueryRequest.fromJson(
                  Map<String, dynamic>.from(args['request'] as Map))),
          _ => throw StateError(command),
        };
      }

      Future<AuthoringRequest> request(String action, Map<String, Object?> args,
              {String? revision}) async =>
          AuthoringRequest(
              requestId: 'whirlpool-${sequence++}',
              actionId: action,
              actionVersion: 1,
              workspaceHandle: workspaceHandle.value,
              expectedRevision:
                  revision ?? (await loader.load(projectHandle)).revision,
              idempotencyKey: 'whirlpool-${sequence++}',
              parameters: Map<String, Object?>.from(
                  jsonDecode(jsonEncode({'mapId': 'whirls', ...args})) as Map));
      Future<void> apply(String action, Map<String, Object?> args) async {
        final before = await file.readAsBytes();
        final plan = await call(
            'plan', {'request': (await request(action, args)).toJson()});
        expect(await file.readAsBytes(), before);
        await call('apply', {
          'planId': plan['planId'],
          'operationId': 'whirlpool-${sequence++}'
        });
      }

      Future<MapData> query() async {
        final data = await call('query', {
          'request': AuthoringQueryRequest(
              resourceKind: 'map',
              operation: AuthoringQueryOperation.get,
              view: AuthoringQueryView.detail,
              ids: ['whirls']).toJson()
        });
        return MapData.fromJson(
            Map<String, dynamic>.from((data['items'] as List).single as Map));
      }

      await apply('gameplay_zone.create', {'zone': seed.toJson()});
      final previousRevision = (await loader.load(projectHandle)).revision;
      await apply('gameplay_zone.set_field_action_payload',
          {'zoneId': zone.id, 'payload': zone.fieldAction!.toJson()});
      final expected =
          map.copyWith(gameplayZones: [...map.gameplayZones, zone]);
      expect(await query(), expected);
      final stable = await file.readAsBytes();
      final route = zone.fieldAction!.whirlpool!.toJson();
      for (final payload in [
        {
          'actionKind': 'whirlpool',
          'whirlpool': {...route, 'requiresSurf': false}
        },
        {
          'actionKind': 'whirlpool',
          'whirlpool': {...route, 'extra': true}
        },
        {
          'actionKind': 'whirlpool',
          'whirlpool': {...route, 'path': []}
        },
        {
          'actionKind': 'whirlpool',
          'whirlpool': {...route, 'direction': 'east'}
        },
        {
          'actionKind': 'whirlpool',
          'whirlpool': route,
          'darkness': {'opacity': .7}
        },
      ]) {
        final invalid = await request('gameplay_zone.set_field_action_payload',
            {'zoneId': zone.id, 'payload': payload});
        if (jsonl) {
          final result = await wire('plan', {
            'projectHandle': projectHandle.value,
            'request': invalid.toJson()
          });
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.code, isNot(AuthoringErrorCode.internal));
        } else {
          await expectLater(mutations.plan(projectHandle, invalid),
              throwsA(isA<Exception>()));
        }
        expect(await file.readAsBytes(), stable);
      }
      final stale = await request('gameplay_zone.set_field_action_payload',
          {'zoneId': zone.id, 'payload': seed.fieldAction!.toJson()},
          revision: previousRevision);
      if (jsonl) {
        final result = await wire('plan',
            {'projectHandle': projectHandle.value, 'request': stale.toJson()});
        expect(result.status, AuthoringResultStatus.failure);
        expect(result.error!.details['domainCode'], 'plan.stale');
      } else {
        await expectLater(
            mutations.plan(projectHandle, stale),
            throwsA(isA<AuthoringPlanException>()
                .having((error) => error.code, 'code', 'plan.stale')));
      }
      expect(await file.readAsBytes(), stable);
      final history = await call('history', {'limit': 1});
      await call('undo', {
        'entryId': ((history['entries'] as List).single as Map)['entryId'],
        'idempotencyKey': 'undo-whirlpool'
      });
      expect((await query()).gameplayZones.last, seed);
      await apply('gameplay_zone.set_field_action_payload',
          {'zoneId': zone.id, 'payload': zone.fieldAction!.toJson()});
      await mutations.detachWorkspace(workspaceHandle);
      await api.closeWorkspace(workspaceHandle);
      final cold = await _coldRead(root, jsonl: jsonl);
      expect(cold, expected);
      _verifyMovement(cold, zone);
      expect(await projectFile.readAsBytes(), projectBefore);
    });
  }
}

void _verifyMovement(MapData map, MapGameplayZone zone) {
  final state = GameState(
      saveId: 'whirlpool',
      currentMapId: map.id,
      playerPosition: const GridPos(x: 2, y: 4),
      playerFacing: EntityFacing.north,
      playerMovementMode: MovementMode.surf,
      party: PlayerParty(members: [
        PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'hardy',
            abilityId: 'water_absorb',
            level: 20,
            currentHp: 30,
            knownMoveIds: [FieldAbility.whirlpool.moveId],
            currentPpByMoveId: {'whirlpool': 0})
      ]),
      progression: const PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.whirlpool]));
  var world = GameplayWorldState.initial(
      map: map,
      playerPos: state.playerPosition,
      playerFacing: Direction.north,
      playerMovementMode: MovementMode.surf);
  final evaluation = evaluateWhirlpoolAttempt(
      map: map, gameState: state, zoneId: zone.id, world: world);
  expect(evaluation, isA<CanUseWhirlpool>());
  for (final cell in (evaluation as CanUseWhirlpool).cells) {
    final plan = planActorRouteMove(
        world: world,
        target: SceneActorTarget.player(mapId: map.id),
        direction: EntityFacing.north,
        through: false,
        fieldTraversalZone: zone);
    expect(plan?.to, cell);
    world = world.withPlayer(plan!.playerState!);
  }
  expect(world.player.pos, const GridPos(x: 2, y: 1));
  expect(world.player.movementMode, MovementMode.surf);
  final restored = GameState.fromJson(
      state.copyWith(playerPosition: world.player.pos).toJson());
  expect(restored.playerPosition, world.player.pos);
  expect(restored.playerMovementMode, MovementMode.surf);
}

Future<MapData> _coldRead(Directory root, {required bool jsonl}) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: ProjectSnapshotLoader(handles: handles));
  final query = AuthoringQueryRequest(
      resourceKind: 'map',
      operation: AuthoringQueryOperation.get,
      view: AuthoringQueryView.detail,
      ids: ['whirls']);
  late Map<String, Object?> data;
  if (jsonl) {
    final worker = JsonlWorker(api: api);
    Future<AuthoringResult> call(
            String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
                {'id': 'cold-$command', 'command': command, 'args': args})))
            as Map<String, dynamic>);
    final opened = await call('open', {'projectRoot': root.path});
    final result = await call('query', {
      'projectHandle': opened.data['projectHandle'],
      'request': query.toJson()
    });
    expect(result.status, AuthoringResultStatus.success);
    data = result.data;
    await worker.close();
  } else {
    final opened = await api.openProject(root.path);
    data = await api.query(opened.projectHandle, query);
    await api.closeWorkspace(opened.workspaceHandle);
  }
  return MapData.fromJson(
      Map<String, dynamic>.from((data['items'] as List).single as Map));
}
