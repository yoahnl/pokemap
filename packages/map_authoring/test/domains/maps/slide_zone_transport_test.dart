import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

const _slide = MovementEffectZonePayload();
const _cost = MovementEffectZonePayload(
  effectKind: MovementEffectZoneKind.movementCost,
  movementCost: 3,
);
const _zone = MapGameplayZone(
  id: 'ice',
  name: 'Patinoire',
  kind: GameplayZoneKind.movementEffect,
  area: MapRect(
    pos: GridPos(x: 1, y: 1),
    size: GridSize(width: 4, height: 2),
  ),
  movementEffect: _cost,
);

void main() {
  test('slide parity references the semantic transport journeys', () {
    final evidence = AuthoringFullParityCatalog.canonical()
        .requireMutationAction('gameplay_zone.set_movement_effect_payload');
    const paths = {
      AuthoringTransport.directApi:
          'test/domains/maps/slide_zone_transport_test.dart',
      AuthoringTransport.cli:
          'test/domains/maps/slide_zone_transport_test.dart',
      AuthoringTransport.editor:
          '../../apps/avelune_studio/test/map_workspace/slide_zone_editing_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/sliding_block_stdio.test.ts',
    };
    expect(evidence.endToEndEvidence, paths);
    expect(evidence.endToEndVerifiedTransports, paths.keys.toSet());
    expect(evidence.contractTestPath, paths[AuthoringTransport.directApi]);
    for (final path in paths.values) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('slide is discoverable on the existing movement effect action', () {
    final descriptor = TriggerZoneActions.descriptors.singleWhere(
      (action) => action.id == 'gameplay_zone.set_movement_effect_payload',
    );
    final extension = descriptor.extensions['movementEffectZone'] as Map?;
    expect(extension, isNotNull);
    expect(extension!['effectKinds'],
        MovementEffectZoneKind.values.map((kind) => kind.name).toList());
    expect(extension['parameters'], ['mapId', 'zoneId', 'payload']);
    final slide = extension['slide'] as Map;
    expect(slide['mapMode'], '2d');
    expect(slide['affectedActors'], ['player', 'strengthBoulder']);
    expect(slide['direction'], 'entry');
    expect(slide['stops'], ['obstacle', 'zoneExit']);
    expect(slide['inputDuringTraversal'], false);
    expect(slide['saveDuringTraversal'], false);
    expect(slide['reload'], 'stationary');
    expect(slide['movementCostConsumed'], false);
  });

  for (final jsonl in [false, true]) {
    test(
        'sliding block ${jsonl ? 'JSONL' : 'direct API'} plans, applies, queries, '
        'undoes and cold reopens without changing unrelated content', () async {
      final root = await Directory.systemTemp.createTemp('slide-authoring-');
      addTearDown(() => root.delete(recursive: true));
      final initial = catalogMap('cave');
      final map = initial.copyWith(
        entities: const [
          MapEntity(
            id: 'rock',
            name: 'Rocher',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 1),
            editorVisual: MapEntityEditorVisual(elementId: 'rock-visual'),
            properties: {'preserved': 'yes'},
          ),
        ],
        layers: [
          initial.layers.first,
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: List.generate(30, (index) => index == 11),
          ),
        ],
      );
      final mapFile = File('${root.path}/maps/cave.json');
      await mapFile.parent.create();
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      const project = ProjectManifest(
        name: 'Slide transport',
        maps: [
          ProjectMapEntry(
            id: 'cave',
            name: 'Cave',
            relativePath: 'maps/cave.json',
          ),
        ],
        tilesets: [
          ProjectTilesetEntry(
              id: 'props', name: 'Props', relativePath: 'props.png'),
        ],
        elementCategories: [ProjectElementCategory(id: 'props', name: 'Props')],
        elements: [
          ProjectElementEntry(
            id: 'rock-visual',
            name: 'Rocher',
            tilesetId: 'props',
            categoryId: 'props',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
            ],
          ),
        ],
      );
      final projectFile = File('${root.path}/project.json');
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      final projectBefore = await projectFile.readAsBytes();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
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
      final worker = JsonlWorker(api: api, mutations: mutations);
      var sequence = 0;
      Future<AuthoringResult> wireResult(
        String command,
        Map<String, Object?> args,
      ) async =>
          AuthoringResult.fromJson(jsonDecode(
            await worker.processLine(jsonEncode({
              'id': 'slide-${sequence++}',
              'command': command,
              'args': args,
            })),
          ) as Map<String, dynamic>);
      Future<Map<String, Object?>> wire(
        String command,
        Map<String, Object?> args,
      ) async {
        final result = await wireResult(command, args);
        expect(result.status, AuthoringResultStatus.success,
            reason: '${result.toJson()}');
        return result.data;
      }

      final description = await wire('describe', {});
      final descriptor = (description['mutationActions'] as List)
          .cast<Map>()
          .singleWhere((action) =>
              action['id'] == 'gameplay_zone.set_movement_effect_payload');
      expect(
          (descriptor['extensions'] as Map)['movementEffectZone'], isNotNull);
      late ProjectHandle projectHandle;
      late WorkspaceHandle workspaceHandle;
      if (jsonl) {
        final opened = await wire('open', {'projectRoot': root.path});
        projectHandle = ProjectHandle(opened['projectHandle'] as String);
        workspaceHandle = WorkspaceHandle(opened['workspaceHandle'] as String);
      } else {
        final opened = await api.openProject(root.path);
        projectHandle = opened.projectHandle;
        workspaceHandle = opened.workspaceHandle;
        await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: workspaceHandle,
          projectHandle: projectHandle,
        );
      }
      Future<Map<String, Object?>> call(
        String command,
        Map<String, Object?> args,
      ) async {
        if (jsonl) {
          return wire(command, {'projectHandle': projectHandle.value, ...args});
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

      Future<AuthoringRequest> request(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final snapshot = await snapshots.load(projectHandle);
        return AuthoringRequest(
          requestId: 'slide-${sequence++}',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'slide-${sequence++}',
          parameters: Map<String, Object?>.from(
            jsonDecode(jsonEncode({'mapId': 'cave', ...parameters})) as Map,
          ),
        );
      }

      Future<void> apply(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final before = await mapFile.readAsBytes();
        final prepared = await call('plan', {
          'request': (await request(action, parameters)).toJson(),
        });
        expect(await mapFile.readAsBytes(), before);
        await call('apply', {
          'planId': prepared['planId'],
          'operationId': 'slide-${sequence++}',
        });
      }

      Future<MapData> query() async {
        final data = await call('query', {
          'request': AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['cave'],
          ).toJson(),
        });
        return MapData.fromJson(Map<String, dynamic>.from(
          (data['items'] as List).single as Map,
        ));
      }

      const obstacle =
          MapEntityFieldObstacleData(kind: FieldObstacleKind.strengthBoulder);
      await apply('entity.set_field_obstacle', {
        'entityId': 'rock',
        'fieldObstacle': obstacle.toJson(),
      });
      expect((await query()).entities.single.fieldObstacle, obstacle);
      await apply('gameplay_zone.create', {'zone': _zone.toJson()});
      expect((await query()).gameplayZones.single, _zone);
      await apply('gameplay_zone.set_movement_effect_payload', {
        'zoneId': 'ice',
        'payload': _slide.toJson(),
      });
      final expected = map.copyWith(
        entities: [map.entities.single.copyWith(fieldObstacle: obstacle)],
        gameplayZones: [_zone.copyWith(movementEffect: _slide)],
      );
      expect(await query(), expected);
      final beforeFailure = await mapFile.readAsBytes();
      for (final payload in [
        {...obstacle.toJson(), 'movementPolicy': 'untilBlocked'},
        {'kind': 'iceBlock', 'resetPolicy': 'mapInstance'},
      ]) {
        final invalid = await request('entity.set_field_obstacle', {
          'entityId': 'rock',
          'fieldObstacle': payload,
        });
        if (jsonl) {
          final result = await wireResult('plan', {
            'projectHandle': projectHandle.value,
            'request': invalid.toJson(),
          });
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.details['domainCode'],
              'entity.field_obstacle_invalid');
        } else {
          await expectLater(
              mutations.plan(projectHandle, invalid),
              throwsA(
                isA<MapAuthoringException>().having((error) => error.code,
                    'code', 'entity.field_obstacle_invalid'),
              ));
        }
        expect(await mapFile.readAsBytes(), beforeFailure);
      }
      for (final payload in [
        {..._slide.toJson(), 'direction': 'east'},
        {
          ..._slide.toJson(),
          'directedJump': {
            'direction': 'east',
            'distanceCells': 2,
            'durationMs': 500,
            'peakHeightPx': 24,
          }
        },
        {'effectKind': 'unknown', 'movementCost': 1},
        {'effectKind': 'slide', 'movementCost': 0},
      ]) {
        final invalid = await request(
          'gameplay_zone.set_movement_effect_payload',
          {'zoneId': 'ice', 'payload': payload},
        );
        if (jsonl) {
          final result = await wireResult('plan', {
            'projectHandle': projectHandle.value,
            'request': invalid.toJson(),
          });
          expect(result.status, AuthoringResultStatus.failure);
        } else {
          await expectLater(mutations.plan(projectHandle, invalid),
              throwsA(isA<MapAuthoringException>()));
        }
        expect(await mapFile.readAsBytes(), beforeFailure);
      }
      final history = await call('history', {'limit': 1});
      await call('undo', {
        'entryId': ((history['entries'] as List).first as Map)['entryId'],
        'idempotencyKey': 'undo-slide',
      });
      expect((await query()).gameplayZones.single.movementEffect, _cost);
      await apply('gameplay_zone.set_movement_effect_payload', {
        'zoneId': 'ice',
        'payload': _slide.toJson(),
      });
      await mutations.detachWorkspace(workspaceHandle);
      await api.close(workspaceHandle);
      final cold = await _coldRead(root, jsonl: jsonl);
      expect(cold, expected);
      _expectSlidingBlockMoves(cold);
      expect(await projectFile.readAsBytes(), projectBefore);
    });
  }
}

void _expectSlidingBlockMoves(MapData map) {
  final instances = MapInstanceWorldState(instancesByMapId: {
    map.id: MapInstanceRuntimeState(instanceId: 'cave-1', strengthActive: true),
  });
  var state = GameState(
    saveId: 'sliding-block',
    currentMapId: map.id,
    playerPosition: const GridPos(x: 1, y: 1),
    playerFacing: EntityFacing.east,
    party: PlayerParty(members: [
      PlayerPokemon(
        speciesId: 'machop',
        natureId: 'hardy',
        abilityId: 'guts',
        level: 20,
        currentHp: 30,
        knownMoveIds: [FieldAbility.strength.moveId],
      )
    ]),
    progression: const PlayerProgression(
        unlockedFieldAbilities: [FieldAbility.strength]),
    mapInstanceWorldState: instances,
  );
  final scope = instances.instanceRef(map.id)!;
  final world = GameplayWorldState.initial(
    map: map,
    playerPos: state.playerPosition,
    playerFacing: Direction.east,
  );
  final pushed = commitStrengthPush(
    ticket: FieldObstacleTicket(
      fieldAction: const FieldActionTicket(
          ability: FieldAbility.strength,
          targetCell: GridPos(x: 2, y: 1),
          issuedAtStateRevision: 7),
      instance: scope,
      entityId: 'rock',
      playerPosition: state.playerPosition,
      playerFacing: state.playerFacing,
    ),
    world: world,
    gameState: state,
    currentStateRevision: 7,
    authoringMap: map,
  ) as StrengthPushApplied;
  expect(pushed.slide, isNotNull);
  state = pushed.gameState;
  var current = pushed.movement.world;
  var slide = pushed.slide;
  for (var count = 0; slide != null && count < 10; count++) {
    final result = stepFieldObstacleSlide(
      slide: slide,
      world: current,
      gameState: state,
      authoringMap: map,
    );
    if (result is FieldObstacleSlideStopped) {
      expect(result.reason, FieldObstacleBlockReason.blockedDestination);
      slide = null;
    } else {
      expect(result, isA<FieldObstacleSlideMoved>());
      final moved = result as FieldObstacleSlideMoved;
      state = moved.gameState;
      current = moved.world;
      slide = moved.slide;
    }
  }
  expect(slide, isNull);
  expect(current.map.entities.single.pos, const GridPos(x: 4, y: 1));
  final restored = GameState.fromJson(state.toJson());
  expect(restored.mapInstanceWorldState.fieldObstaclePosition(scope, 'rock'),
      const GridPos(x: 4, y: 1));
  expect(map.entities.single.pos, const GridPos(x: 2, y: 1));
}

Future<MapData> _coldRead(Directory root, {required bool jsonl}) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ),
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  final request = AuthoringQueryRequest(
    resourceKind: 'map',
    operation: AuthoringQueryOperation.get,
    view: AuthoringQueryView.detail,
    ids: ['cave'],
  );
  late Map<String, Object?> data;
  if (jsonl) {
    final worker = JsonlWorker(api: api);
    Future<Map<String, Object?>> call(
      String command,
      Map<String, Object?> args,
    ) async {
      final result = AuthoringResult.fromJson(jsonDecode(
        await worker.processLine(jsonEncode({
          'id': 'cold-$command',
          'command': command,
          'args': args,
        })),
      ) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success);
      return result.data;
    }

    final opened = await call('open', {'projectRoot': root.path});
    data = await call('query', {
      'projectHandle': opened['projectHandle'],
      'request': request.toJson(),
    });
    await worker.close();
  } else {
    final opened = await api.openProject(root.path);
    data = await api.query(opened.projectHandle, request);
    await api.close(opened.workspaceHandle);
  }
  return MapData.fromJson(Map<String, dynamic>.from(
    (data['items'] as List).single as Map,
  ));
}
