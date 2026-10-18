import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'spatial cached neighbour admits the currently selected avatar',
    () async {
      final fixture = await _catalogFixture();
      final session = fixture.session;
      await session.loadConnectionNeighbor(fixture.source.connections.single);
      expect(fixture.loads(), 1);
      await session.presentPlayerAvatar('costume');
      await session.enterWarp(fixture.source.warps.single);
      expect(session.interactionError.value, isNull);
      expect(session.bundle.map.id, 'target');
      expect(session.character.id, 'costume');
      expect(
        session.bundle.manifest.characters.map((entry) => entry.id),
        contains('costume'),
      );
      expect(session.bundle.runtimeImageAbsolutePathsById, contains('costume'));
      expect(fixture.loads(), 1);
      expect(session.frame(0).texture, isNotNull);
    },
  );

  for (final failAfterOther in [false, true]) {
    test(
      'a Scene crosses filtered map bundles and restores on failure=$failAfterOther',
      () async {
        final fixture = await _catalogFixture(includeCostumeInTarget: true);
        final original = _scene();
        final scene = SceneAsset(
          id: original.id,
          name: original.name,
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              original.graph.nodes[0],
              original.graph.nodes[1],
              SceneNode(
                id: 'warp',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload(
                  interactiveCommand: SceneInteractiveCommand.warp(
                    destinationMapId: 'target',
                    warpId: 'arrival',
                    transition: SceneWarpTransition.none,
                  ),
                ),
              ),
              SceneNode(
                id: 'hero',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.setPlayerAvatar(characterId: 'other'),
                ),
              ),
              original.graph.nodes.last,
            ],
            edges: [
              original.graph.edges.first,
              SceneEdge(
                id: 'costume_warp',
                fromNodeId: 'costume',
                fromPortId: 'completed',
                toNodeId: 'warp',
                kind: SceneEdgeKind.actionCompleted,
              ),
              SceneEdge(
                id: 'warp_other',
                fromNodeId: 'warp',
                fromPortId: 'completed',
                toNodeId: 'hero',
                kind: SceneEdgeKind.actionCompleted,
              ),
              original.graph.edges.last,
            ],
          ),
        );
        final project = fixture.project.copyWith(scenes: [scene]);
        var state = const GameState(
          saveId: 'avatar',
          currentMapId: 'source',
          trainerProfile: TrainerProfile(
            name: 'Player',
            avatarCharacterId: 'hero',
          ),
        );
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'event',
            sceneId: scene.id,
            executionId: 'cross-map',
            gameState: state,
          ),
          project: project,
          mapsById: {'source': fixture.source, 'target': fixture.target},
          currentGameState: () => state,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) => 'completed',
            startBattle: (_) => 'completed',
            playCinematic: (_) => 'completed',
            presentPlayerAvatar: (id) async {
              await fixture.session.presentPlayerAvatar(id);
              if (id == 'other' && failAfterOther) {
                throw StateError('Scene cancelled after presentation');
              }
            },
            executeInteractiveCommand: (_) async {
              await fixture.session.enterWarp(fixture.source.warps.single);
              if (fixture.session.bundle.map.id != 'target') {
                throw StateError('Warp did not complete');
              }
              state = const GameStateMutations().warpPlayer(
                state,
                'target',
                3,
                3,
              );
              return 'completed';
            },
          ),
        );
        expect(
          result,
          failAfterOther
              ? isA<NarrativeSceneExecutionFailed>()
              : isA<NarrativeSceneExecutionCompleted>(),
          reason: result is NarrativeSceneExecutionFailed
              ? result.failure.toString()
              : null,
        );
        if (!failAfterOther) {
          expect(
            (result as NarrativeSceneExecutionCompleted)
                .updatedGameState
                .trainerProfile
                .avatarCharacterId,
            'other',
          );
        }
        expect(fixture.session.character.id, failAfterOther ? 'hero' : 'other');
        expect(fixture.session.bundle.map.id, 'target');
        expect(fixture.session.frame(0).texture, isNotNull);
        expect(
          fixture.session.frame(0).texture.texture.sourceData.getUint8(3),
          failAfterOther ? 255 : 0,
        );
      },
    );
  }

  test('map character dependencies include Scene avatar commands', () {
    final scene = _scene();
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 4, height: 4),
      events: [
        MapEventDefinition(
          id: 'event',
          position: const EventPosition(layerId: 'base', x: 0, y: 0),
          pages: [
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: scene.id),
            ),
          ],
        ),
      ],
    );
    expect(
      collectRuntimeMapCharacterIds(map, _project().copyWith(scenes: [scene])),
      containsAll(['hero', 'costume']),
    );
    expect(
      collectRuntimeMapCharacterIds(
        map.copyWith(events: const []),
        _project().copyWith(scenes: [scene]),
      ),
      isNot(contains('costume')),
    );
  });

  test(
    'avatar consequences preserve gameplay and survive a save round trip',
    () {
      final project = _project();
      final state = GameState(
        saveId: 'avatar',
        currentMapId: 'map',
        playerPosition: const GridPos(x: 2, y: 3),
        playerFacing: EntityFacing.west,
        trainerProfile: const TrainerProfile(
          name: 'Player',
          avatarCharacterId: 'hero',
        ),
      );
      final writer = SceneConsequenceRuntimeWriter(project: project);
      final result = writer.applyOne(
        state,
        SceneConsequence.setPlayerAvatar(characterId: 'costume'),
      );
      expect(result.success, isTrue);
      expect(result.gameState.trainerProfile.avatarCharacterId, 'costume');
      expect(result.gameState.playerPosition, state.playerPosition);
      expect(result.gameState.playerFacing, state.playerFacing);
      expect(result.gameState.party, state.party);
      expect(GameState.fromJson(result.gameState.toJson()), result.gameState);
      expect(state.trainerProfile.avatarCharacterId, 'hero');
      final restored = writer.applyOne(
        result.gameState,
        SceneConsequence.setPlayerAvatar(characterId: 'hero'),
      );
      expect(restored.gameState, state);
      final rejected = writer.applyAll(state, [
        SceneConsequence.setPlayerAvatar(characterId: 'costume'),
        SceneConsequence.setPlayerAvatar(characterId: 'missing'),
      ]);
      expect(rejected.success, isFalse);
      expect(rejected.gameState, state);
    },
  );

  for (final failSecond in [false, true]) {
    test(
      'Scene awaits avatar presentation and restores on failure=$failSecond',
      () async {
        final scene = _scene();
        final project = _project().copyWith(scenes: [scene]);
        const initial = GameState(
          saveId: 'avatar',
          trainerProfile: TrainerProfile(
            name: 'Player',
            avatarCharacterId: 'hero',
          ),
        );
        final ready = Completer<void>();
        final presented = <String?>[];
        final pending = executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'event',
            sceneId: scene.id,
            executionId: 'execution',
            gameState: initial,
          ),
          project: project,
          mapsById: const {},
          currentGameState: () => initial,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
            presentPlayerAvatar: (id) async {
              presented.add(id);
              if (presented.length == 1) {
                await ready.future;
              }
              if (failSecond && presented.length == 2) {
                throw StateError('Media unavailable');
              }
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(presented, ['costume']);
        ready.complete();
        final result = await pending;
        if (failSecond) {
          expect(result, isA<NarrativeSceneExecutionFailed>());
          expect(presented, ['costume', 'hero', 'hero']);
        } else {
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          expect(
            (result as NarrativeSceneExecutionCompleted).updatedGameState,
            initial,
          );
          expect(presented, ['costume', 'hero']);
        }
        expect(initial.trainerProfile.avatarCharacterId, 'hero');
      },
    );
  }

  test('Scene refuses an avatar change without a presentation port', () async {
    final scene = _scene();
    const initial = GameState(saveId: 'avatar');
    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: 'event',
        sceneId: scene.id,
        executionId: 'execution',
        gameState: initial,
      ),
      project: _project().copyWith(scenes: [scene]),
      mapsById: const {},
      currentGameState: () => initial,
      callbacks: SceneRuntimeHostCallbacks(
        evaluateCondition: (_) => 'true',
        showDialogue: (_) => 'completed',
        startBattle: (_) => 'completed',
        playCinematic: (_) => 'completed',
      ),
    );
    expect(result, isA<NarrativeSceneExecutionFailed>());
    expect(initial.trainerProfile.avatarCharacterId, isNull);
  });

  for (final failSecond in [false, true]) {
    test(
      'map event Scene presents and rolls back avatar failure=$failSecond',
      () async {
        final scene = _scene();
        final event = MapEventDefinition(
          id: 'avatar_event',
          position: const EventPosition(layerId: 'base', x: 0, y: 0),
          pages: [
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: scene.id),
            ),
          ],
        );
        final map = MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 4, height: 4),
          events: [event],
        );
        final project = _project().copyWith(
          scenes: [scene],
          maps: [
            ProjectMapEntry(
              id: 'map',
              name: 'Map',
              relativePath: 'maps/map.json',
            ),
          ],
        );
        const initial = GameState(
          saveId: 'avatar',
          trainerProfile: TrainerProfile(
            name: 'Player',
            avatarCharacterId: 'hero',
          ),
        );
        final presented = <String?>[];
        final result =
            await SceneEventRuntimeHook(
              callbacks: SceneRuntimeHostCallbacks(
                evaluateCondition: (_) => 'true',
                showDialogue: (_) => 'completed',
                startBattle: (_) => 'completed',
                playCinematic: (_) => 'completed',
                presentPlayerAvatar: (id) async {
                  presented.add(id);
                  if (failSecond && presented.length == 2) {
                    throw StateError('Media unavailable');
                  }
                },
              ),
            ).runForEventPage(
              project: project,
              map: map,
              event: event,
              page: event.pages.single,
              gameState: initial,
            );
        expect(result.success, !failSecond);
        expect(
          presented,
          failSecond ? ['costume', 'hero', 'hero'] : ['costume', 'hero'],
        );
        if (!failSecond) expect(result.updatedGameState, initial);
      },
    );
  }

  test(
    'spatial avatar replacement keeps movement and validates media atomically',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-avatar-');
      addTearDown(() => root.delete(recursive: true));
      final heroPath = '${root.path}/hero.png';
      final costumePath = '${root.path}/costume.png';
      final corruptPath = '${root.path}/corrupt.png';
      await File(heroPath)
          .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
      await File(costumePath)
          .writeAsBytes(img.encodePng(img.Image(width: 64, height: 48)));
      await File(corruptPath).writeAsBytes([1, 2, 3, 4]);
      final project = _project().copyWith(
        settings: const ProjectSettings(
          dimension: ProjectDimension.threeD,
          defaultPlayerCharacterId: 'hero',
        ),
        characters: [
          ..._project().characters,
          _character('broken', 32, 32),
          _character('corrupt', 32, 32),
          _character('oversized', 96, 48),
        ],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
        ),
      );
      final bundle = RuntimeMapBundle(
        manifest: project,
        map: map,
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {
          'hero': heroPath,
          'costume': costumePath,
          'corrupt': corruptPath,
          'oversized': costumePath,
        },
      );
      final session = await SpatialExplorationSession.load(bundle);
      addTearDown(session.dispose);
      final movement = session.movement;
      final position = movement.spatialPosition;
      final facing = movement.facing;
      final before = session.frame(0);
      await session.presentPlayerAvatar('costume');
      final after = session.frame(0);
      expect(session.character.id, 'costume');
      expect(after.frame, const Rect.fromLTWH(0, 0, 64, 48));
      expect(identical(after.texture, before.texture), isFalse);
      expect(identical(session.movement, movement), isTrue);
      expect(movement.spatialPosition, position);
      expect(movement.facing, facing);
      await expectLater(
        session.presentPlayerAvatar('missing'),
        throwsA(isA<FormatException>()),
      );
      expect(session.character.id, 'costume');
      await expectLater(
        session.presentPlayerAvatar('broken'),
        throwsA(isA<StateError>()),
      );
      expect(session.character.id, 'costume');
      expect(session.movement.spatialPosition, position);
      await expectLater(
        session.presentPlayerAvatar('corrupt'),
        throwsException,
      );
      expect(session.character.id, 'costume');
      await expectLater(
        session.presentPlayerAvatar('oversized'),
        throwsStateError,
      );
      expect(session.character.id, 'costume');
      final restoredState = GameState(
        saveId: 'avatar',
        currentMapId: 'map',
        playerPosition: GridPos(x: movement.x.floor(), y: movement.z.floor()),
        playerSpatialPosition: position,
        playerFacing: facing,
        trainerProfile: const TrainerProfile(
          name: 'Player',
          avatarCharacterId: 'hero',
        ),
      );
      await session.restoreGameState(restoredState, restorePlayerAvatar: false);
      expect(session.character.id, 'costume');
      await session.restoreGameState(restoredState);
      expect(session.character.id, 'hero');
      expect(session.frame(0).frame, before.frame);
    },
  );
}

Future<
  ({
    SpatialExplorationSession session,
    ProjectManifest project,
    MapData source,
    MapData target,
    int Function() loads,
  })
>
_catalogFixture({bool includeCostumeInTarget = false}) async {
  final root = await Directory.systemTemp.createTemp('runtime-avatar-catalog-');
  addTearDown(() => root.delete(recursive: true));
  final project = ProjectManifest(
    name: 'Avatar catalogue',
    version: ProjectVersion.v9,
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      defaultPlayerCharacterId: 'hero',
      spatialCamera: SpatialCameraProfile(),
    ),
    maps: [
      for (final id in ['source', 'target'])
        ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
    ],
    tilesets: [
      for (final id in ['hero', 'costume', 'other'])
        ProjectTilesetEntry(
          id: id,
          name: id,
          relativePath: '$id.png',
          transparentColor: id == 'other'
              ? TilesetTransparentColor(red: 255, green: 0, blue: 255)
              : null,
        ),
    ],
    characters: [
      for (final id in ['hero', 'costume', 'other'])
        ProjectCharacterEntry(
          id: id,
          name: id,
          tilesetId: id,
          animations: [
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: CharacterAnimationState.walk,
                direction: direction,
                frames: const [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                    durationMs: 100,
                  ),
                ],
              ),
          ],
        ),
    ],
  );
  for (final id in ['hero', 'costume', 'other']) {
    final image = img.Image(width: 32, height: 32);
    if (id == 'other') {
      img.fill(image, color: img.ColorRgba8(255, 0, 255, 255));
    }
    await File('${root.path}/$id.png').writeAsBytes(img.encodePng(image));
  }
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  final catalog = await RuntimeProjectCatalog.open('${root.path}/project.json');
  addTearDown(catalog.dispose);
  MapData map(String id) => MapData(
    id: id,
    name: id,
    size: const GridSize(width: 8, height: 8),
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
    ),
    connections: id == 'source'
        ? [
            MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: 'target',
            ),
          ]
        : const [],
    warps: [
      MapWarp(
        id: 'arrival',
        pos: const GridPos(x: 3, y: 3),
        targetMapId: 'target',
        targetPos: const GridPos(x: 3, y: 3),
        triggerMode: MapWarpTriggerMode.sceneOnly,
      ),
    ],
  );
  final source = map('source');
  final target = map('target');
  Future<RuntimeMapBundle> bundle(MapData map, {bool costume = false}) async =>
      RuntimeMapBundle(
        manifest: await catalog.manifestForMap(
          map,
          extraCharacterIds: [if (costume) 'costume'],
        ),
        map: map,
        projectCatalog: catalog,
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: {
          'hero': '${root.path}/hero.png',
          if (costume) 'costume': '${root.path}/costume.png',
        },
      );
  var loads = 0;
  final session = await SpatialExplorationSession.load(
    await bundle(source, costume: true),
    loadMap: (_) async {
      loads++;
      return bundle(target, costume: includeCostumeInTarget);
    },
  );
  addTearDown(session.dispose);
  return (
    session: session,
    project: project,
    source: source,
    target: target,
    loads: () => loads,
  );
}

ProjectManifest _project() => ProjectManifest(
  name: 'Avatar',
  maps: const [],
  tilesets: const [],
  characters: [_character('hero', 32, 32), _character('costume', 64, 48)],
);

ProjectCharacterEntry _character(String id, int width, int height) =>
    ProjectCharacterEntry(
      id: id,
      name: id,
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          for (final state in [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
          ])
            CharacterAnimation(
              state: state,
              direction: direction,
              sourceAssetId: id,
              frames: [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
      ],
    );

SceneAsset _scene() => SceneAsset(
  id: 'avatar',
  name: 'Avatar',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'costume',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setPlayerAvatar(characterId: 'costume'),
        ),
      ),
      SceneNode(
        id: 'hero',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setPlayerAvatar(characterId: 'hero'),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_costume',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'costume',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'costume_hero',
        fromNodeId: 'costume',
        fromPortId: 'completed',
        toNodeId: 'hero',
        kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(
        id: 'hero_end',
        fromNodeId: 'hero',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);
