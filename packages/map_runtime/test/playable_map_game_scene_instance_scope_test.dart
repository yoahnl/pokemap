import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_narrative_map_instances.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final value in [
    NarrativeValue.integer(2),
    const NarrativeValue.string('heartgold'),
  ]) {
    test(
      'typed event facts do not require a local instance: ${value.kind}',
      () {
        final project = ProjectManifest(
          name: 'Typed event state',
          maps: const [],
          tilesets: const [],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: const [],
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_01a20000-0000-7000-8000-000000000098',
                  name: 'Typed event',
                  source: NarrativeEventSourceRef.entityInteract(
                    'room',
                    'control',
                  ),
                  conditions: [
                    NarrativeEventCondition.factValue(
                      'story',
                      operator: NarrativeFactOperator.equals,
                      expectedValue: value,
                    ),
                  ],
                  sceneId: 'scene',
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
          ),
        );
        expect(hasNarrativeMapInstanceReferences(project, 'room'), isFalse);
      },
    );
  }

  for (final mode in ['write', 'condition', 'eventCondition', 'ordinary']) {
    testWidgets('local Scene instance scope without retention policy: $mode', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'scene-instance-scope-',
        );
        addTearDown(() => root.delete(recursive: true));
        final map = MapData(
          id: 'room',
          name: 'Room',
          size: const GridSize(width: 4, height: 4),
          layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
          entities: const [
            MapEntity(
              id: 'control',
              name: 'Control',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1),
              blocksMovement: false,
            ),
          ],
        );
        final scene = _scene(mode);
        final project = ProjectManifest(
          name: 'Local Scene state',
          maps: const [
            ProjectMapEntry(
              id: 'room',
              name: 'Room',
              relativePath: 'maps/room.json',
            ),
          ],
          tilesets: const [],
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: const [],
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_01a20000-0000-7000-8000-000000000099',
                  name: 'Operate control',
                  source: NarrativeEventSourceRef.entityInteract(
                    'room',
                    'control',
                  ),
                  conditions: [
                    if (mode == 'eventCondition')
                      NarrativeEventCondition.mapEventInstanceBoolean(
                        mapId: 'room',
                        eventId: 'control',
                        key: 'operated',
                        expectedValue: false,
                      ),
                  ],
                  sceneId: scene.id,
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
          ),
        );
        await Directory('${root.path}/maps').create();
        await File('${root.path}/maps/room.json')
            .writeAsString(jsonEncode(map.toJson()));
        await File('${root.path}/project.json')
            .writeAsString(jsonEncode(project.toJson()));
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: '${root.path}/project.json',
          mapId: 'room',
        );
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: '${root.path}/project.json',
          initialGameState: const GameState(
            saveId: 'local-scene',
            currentMapId: 'room',
            playerPosition: GridPos(x: 1, y: 2),
            playerFacing: EntityFacing.north,
          ),
        );
        addTearDown(game.onRemove);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        await game.loaded;
        await tester.pump();
        await game.ready();
        await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('room'),
          mode == 'ordinary' ? isNull : isNotNull,
        );
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        game.update(.016);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.primary),
        );
        await _until(
          game,
          () => game.gameStateSnapshot.trainerProfile.money == 1,
        );
        if (mode == 'write') {
          expect(
            game
                .gameStateSnapshot
                .mapInstanceWorldState
                .instancesByMapId['room']!
                .eventBooleans['control']!['operated'],
            isTrue,
          );
        }
        final restored = GameState.fromJson(game.gameStateSnapshot.toJson());
        expect(
          restored.mapInstanceWorldState,
          game.gameStateSnapshot.mapInstanceWorldState,
        );
      });
    });
  }
}

Future<void> _until(PlayableMapGame game, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}

SceneAsset _scene(String mode) => SceneAsset.fromJson({
  'id': 'operate-control',
  'name': 'Operate control',
  'graph': {
    'startNodeId': 'start',
    'nodes': [
      {
        'id': 'start',
        'kind': 'start',
        'payload': {'kind': 'start'},
      },
      if (mode == 'write')
        {
          'id': 'local',
          'kind': 'action',
          'payload': {
            'kind': 'action',
            'parameters': {},
            'consequence': {
              'kind': 'setMapEventInstanceBoolean',
              'mapId': 'room',
              'eventId': 'control',
              'key': 'operated',
              'value': true,
            },
          },
        },
      if (mode == 'condition')
        {
          'id': 'local',
          'kind': 'condition',
          'payload': {
            'kind': 'condition',
            'conditionSource': {
              'sourceKind': 'mapEventInstanceBoolean',
              'sourceId': 'control',
              'mapId': 'room',
              'key': 'operated',
              'operator': 'isFalse',
            },
          },
        },
      {
        'id': 'reward',
        'kind': 'action',
        'payload': {
          'kind': 'action',
          'parameters': {},
          'consequence': {'kind': 'giveMoney', 'amount': 1},
        },
      },
      {
        'id': 'end',
        'kind': 'end',
        'payload': {'kind': 'end'},
      },
    ],
    'edges': [
      {
        'id': 'start-next',
        'fromNodeId': 'start',
        'fromPortId': 'completed',
        'toNodeId': ['write', 'condition'].contains(mode) ? 'local' : 'reward',
        'kind': 'default',
      },
      if (mode == 'write')
        {
          'id': 'write-reward',
          'fromNodeId': 'local',
          'fromPortId': 'completed',
          'toNodeId': 'reward',
          'kind': 'actionCompleted',
        },
      if (mode == 'condition') ...[
        {
          'id': 'local-true',
          'fromNodeId': 'local',
          'fromPortId': 'true',
          'toNodeId': 'reward',
          'kind': 'conditionTrue',
        },
        {
          'id': 'local-false',
          'fromNodeId': 'local',
          'fromPortId': 'false',
          'toNodeId': 'end',
          'kind': 'conditionFalse',
        },
      ],
      {
        'id': 'reward-end',
        'fromNodeId': 'reward',
        'fromPortId': 'completed',
        'toNodeId': 'end',
        'kind': 'actionCompleted',
      },
    ],
  },
});
