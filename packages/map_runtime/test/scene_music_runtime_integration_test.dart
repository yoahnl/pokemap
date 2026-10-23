import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final exit in ['sceneEnd', 'blocked']) {
    testWidgets('map ambience survives completion and rolls back on $exit', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final created = await Directory.systemTemp.createTemp('world-audio-');
        final root = Directory(await created.resolveSymbolicLinks());
        addTearDown(() => root.delete(recursive: true));
        for (final name in ['map', 'scene', 'broken']) {
          await File('${root.path}/$name.ogg').writeAsBytes([0]);
        }
        final wire = jsonDecode(
          jsonEncode(_scene(exit).toJson()),
        ) as Map<String, dynamic>;
        for (final node in (wire['graph'] as Map)['nodes'] as List) {
          final command = (node['payload'] as Map)['interactiveCommand'];
          if (command is Map && command['kind'] == 'sceneMusic') {
            command['scope'] = 'map';
            command['channel'] = 'ambience';
          }
        }
        final scene = SceneAsset.fromJson(wire);
        final musicDriver = _Driver();
        final ambienceDriver = _Driver();
        final music = RuntimeMusicService(
          driver: musicDriver,
          fadeDelay: (_) async {},
          fadeSteps: 1,
        );
        final ambience = RuntimeMusicService(
          driver: ambienceDriver,
          fadeDelay: (_) async {},
          fadeSteps: 1,
        );
        final game = PlayableMapGame(
          bundle: _bundle(root.path, scene),
          projectFilePath: '${root.path}/project.json',
          musicService: music,
          ambienceMusicService: ambience,
        );
        addTearDown(() async {
          game.onRemove();
          await music.dispose();
          await ambience.dispose();
        });
        game.onGameResize(Vector2(320, 240));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        await game.loaded;
        await tester.pump();
        await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
        var finished = false;
        final completion = game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'world-audio-test',
            sceneId: scene.id,
            executionId: exit,
            gameState: game.gameStateSnapshot,
          ),
        );
        unawaited(
          completion.then((_) {
            finished = true;
          }),
        );
        await _until(
          game,
          () => ambience.playingPath == '${root.path}/scene.ogg',
        );
        expect(music.playingPath, '${root.path}/map.ogg');
        await _until(game, () => finished);
        if (exit == 'sceneEnd') {
          expect(await completion, isA<NarrativeSceneExecutionCompleted>());
          expect(ambience.playingPath, '${root.path}/scene.ogg');
          game.didChangeAppLifecycleState(AppLifecycleState.paused);
          await _until(game, () => ambienceDriver.paused.isNotEmpty);
          game.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await _until(game, () => ambienceDriver.resumed.isNotEmpty);
          expect(ambienceDriver.loops, hasLength(1));
        } else {
          expect(
            await completion,
            isNot(isA<NarrativeSceneExecutionCompleted>()),
          );
          expect(ambience.playingPath, isNull);
        }
        expect(music.playingPath, '${root.path}/map.ogg');
        await tester.pumpWidget(const SizedBox());
      });
    });
  }

  testWidgets(
    'native battle owns BGM then returns to scoped music and map ambience',
    (tester) async {
      await tester.runAsync(() async {
        installConvertedQaHeadlessAudio();
        final created = await Directory.systemTemp.createTemp(
          'scene-music-battle-',
        );
        final root = Directory(await created.resolveSymbolicLinks());
        addTearDown(() => root.delete(recursive: true));
        final golden = Directory(
          path.normalize(
            path.join(
              Directory.current.path,
              '..',
              '..',
              'examples',
              'playable_runtime_host',
              'golden_battle_slice',
            ),
          ),
        );
        for (final entity
            in golden.listSync(recursive: true).whereType<File>()) {
          final target = File(
            path.join(root.path, path.relative(entity.path, from: golden.path)),
          );
          await target.parent.create(recursive: true);
          await entity.copy(target.path);
        }
        for (final species in ['sproutle', 'sparkitten']) {
          final evolution = File(
            '${root.path}/data/pokemon/evolutions/$species.json',
          );
          await evolution.parent.create(recursive: true);
          await evolution.writeAsString(
            jsonEncode({
              'schemaVersion': 1,
              'speciesId': species,
              'evolutions': [],
            }),
          );
        }
        for (final name in ['scene', 'map', 'battle', 'victory']) {
          await File('${root.path}/$name.ogg').writeAsBytes([0]);
        }
        final scene = _battleScene();
        final original = await loadRuntimeMapBundle(
          projectFilePath: '${root.path}/project.json',
          mapId: 'golden_field',
        );
        final bundle = original.copyWith(
          manifest: original.manifest.copyWith(
            scenes: [scene],
            battleAudio: const ProjectBattleAudioConfig(
              trainerBattleMusicPath: 'battle.ogg',
              trainerVictoryMusicPath: 'victory.ogg',
            ),
            cinematicMediaAssets: [
              CinematicMediaAsset(
                id: 'rival',
                label: 'Rival',
                kind: CinematicMediaAssetKind.music,
                relativePath: 'scene.ogg',
              ),
            ],
          ),
          map: original.map.copyWith(
            mapMetadata: original.map.mapMetadata.copyWith(
              musicPath: 'map.ogg',
              musicVolume: .4,
            ),
          ),
        );
        final save = SaveData.fromJson(
          jsonDecode(
            await File('${root.path}/runtime_host_launch_save.json')
                .readAsString(),
          ) as Map<String, dynamic>,
        ).normalized();
        final driver = _Driver();
        final service = RuntimeMusicService(
          driver: driver,
          fadeDelay: (_) async {},
          fadeSteps: 1,
        );
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: '${root.path}/project.json',
          saveData: save,
          musicService: service,
        );
        addTearDown(() async {
          game.onRemove();
          await service.dispose();
          await Future<void>.delayed(Duration.zero);
        });
        game.onGameResize(Vector2(640, 480));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        await game.loaded;
        await tester.pump();
        await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
        var finished = false;
        final completion = game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'music-battle-test',
            sceneId: scene.id,
            executionId: 'native-battle',
            gameState: game.gameStateSnapshot,
          ),
        );
        unawaited(
          completion.then((_) {
            finished = true;
          }),
        );
        var sawBattle = false;
        var sawReturnToScene = false;
        var sawNativeOutcome = false;
        var issued = 0;
        for (var i = 0; i < 18000 && !finished; i++) {
          final battle = game.debugBattleSessionSnapshot;
          if (battle != null) {
            sawBattle = true;
            if (game.debugFlowPhaseName == 'battle') {
              expect(service.playingPath, isNot('${root.path}/scene.ogg'));
            }
            sawNativeOutcome = sawNativeOutcome || battle.state.outcome != null;
          }
          if (sawBattle &&
              battle == null &&
              service.playingPath == '${root.path}/scene.ogg') {
            sawReturnToScene = true;
          }
          final snapshot = game.battleCommandOverlayListenable.value;
          if (snapshot != null && snapshot.interactionsEnabled) {
            final entry = snapshot.entries
                .where((entry) => entry.enabled)
                .first;
            final index = switch (snapshot.mode) {
              BattleCommandOverlayMode.root ||
              BattleCommandOverlayMode.fight => 0,
              BattleCommandOverlayMode.continueOnly ||
              BattleCommandOverlayMode.pokemon => entry.index,
              _ => throw StateError(
                'Unexpected music QA battle mode ${snapshot.mode}',
              ),
            };
            if (game.dispatchBattlePresentationCommand(
              BattleSelectEntryCommand(
                snapshotRevision: snapshot.revision,
                expectedMode: snapshot.mode,
                entryIndex: index,
              ),
            )) {
              issued++;
            }
          }
          if (game.debugPostBattleOverlayMounted) {
            game.debugValidatePostBattleChoice();
          }
          game.update(.1);
          await game.ready();
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(
          finished,
          isTrue,
          reason:
              'phase=${game.debugFlowPhaseName} prompt=${game.battleCommandOverlayListenable.value?.prompt}',
        );
        expect(await completion, isA<NarrativeSceneExecutionCompleted>());
        expect(sawBattle, isTrue);
        expect(sawNativeOutcome, isTrue);
        expect(issued, greaterThan(0));
        expect(sawReturnToScene, isTrue);
        expect(
          driver.loops.any((row) => row.$1 == '${root.path}/battle.ogg'),
          isTrue,
        );
        expect(service.playingPath, '${root.path}/map.ogg');
      });
    },
  );

  for (final exit in [
    'completed',
    'sceneEnd',
    'silentCinematic',
    'blocked',
    'removed',
  ]) {
    testWidgets('scoped music survives a wait then restores on $exit', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final created = await Directory.systemTemp.createTemp('scene-music-');
        final root = Directory(await created.resolveSymbolicLinks());
        addTearDown(() => root.delete(recursive: true));
        await File('${root.path}/scene.ogg').writeAsBytes([0]);
        await File('${root.path}/map.ogg').writeAsBytes([0]);
        await File('${root.path}/broken.ogg').writeAsBytes([0]);
        final driver = _Driver();
        final service = RuntimeMusicService(
          driver: driver,
          fadeDelay: (_) async {},
          fadeSteps: 1,
        );
        final scene = _scene(exit);
        final bundle = _bundle(root.path, scene);
        expect(
          diagnoseSceneAgainstProject(
                scene,
                bundle.manifest,
                mapsById: {bundle.map.id: bundle.map},
              ).diagnostics
              .where((d) => d.severity == SceneDiagnosticSeverity.error)
              .map((d) => '${d.code}: ${d.message}')
              .toList(),
          isEmpty,
        );
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: '${root.path}/project.json',
          musicService: service,
        );
        var removed = false;
        addTearDown(() async {
          if (!removed) game.onRemove();
          await service.dispose();
          await Future<void>.delayed(Duration.zero);
        });
        game.onGameResize(Vector2(320, 240));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        await game.loaded;
        await tester.pump();
        await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
        var finished = false;
        final completion = game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'test',
            sceneId: scene.id,
            executionId: exit,
            gameState: game.gameStateSnapshot,
          ),
        );
        unawaited(
          completion.then((_) {
            finished = true;
          }),
        );
        await _until(
          game,
          () => finished || service.playingPath == '${root.path}/scene.ogg',
        );
        expect(finished, isFalse);
        expect(service.playingPath, '${root.path}/scene.ogg');
        expect(
          driver.loops
              .where((row) => row.$1 == '${root.path}/scene.ogg')
              .single
              .$2,
          isTrue,
        );
        if (exit == 'silentCinematic') {
          await _until(game, () => game.debugIsCinematicPlaying);
          expect(service.playingPath, '${root.path}/scene.ogg');
        }
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        game.update(.1);
        await Future<void>.delayed(Duration.zero);
        expect(service.playingPath, '${root.path}/scene.ogg');
        if (exit == 'removed') {
          game.onRemove();
          removed = true;
        }
        await _until(game, () => finished, max: 2500);
        final result = await completion;
        if (exit == 'completed' ||
            exit == 'sceneEnd' ||
            exit == 'silentCinematic') {
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          expect(
            (result as NarrativeSceneExecutionCompleted)
                .updatedGameState
                .narrativeFactRuntimeState
                .valueFor('music_visited')
                ?.toJson(),
            const NarrativeValue.boolean(true).toJson(),
          );
        } else {
          expect(result, isNot(isA<NarrativeSceneExecutionCompleted>()));
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
              'music_visited',
            ),
            isNull,
          );
          if (exit == 'blocked') {
            expect(driver.failedPaths, ['${root.path}/broken.ogg']);
          }
        }
        if (!removed) {
          await _until(
            game,
            () => service.playingPath == '${root.path}/map.ogg',
          );
          expect(service.playingPath, '${root.path}/map.ogg');
          expect(game.debugIsGameplayInputLocked, isFalse);
        } else {
          await service.dispose();
          expect(service.isPlaying, isFalse);
        }
      });
    });
  }
}

Future<void> _until(
  PlayableMapGame game,
  bool Function() done, {
  int max = 1000,
}) async {
  for (var i = 0; i < max; i++) {
    if (done()) return;
    game.update(.02);
    await game.ready();
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Scene music condition did not settle.');
}

SceneAsset _scene(String exit) {
  final commands = <SceneInteractiveCommand>[
    SceneInteractiveCommand.sceneMusic(
      operation: SceneMusicOperation.play,
      mediaAssetId: 'rival',
      volume: .7,
    ),
    SceneInteractiveCommand.wait(durationMs: 400),
    if (exit == 'blocked')
      SceneInteractiveCommand.sceneMusic(
        operation: SceneMusicOperation.play,
        mediaAssetId: 'broken',
        volume: .5,
      ),
    if (exit == 'completed')
      SceneInteractiveCommand.sceneMusic(
        operation: SceneMusicOperation.restore,
      ),
  ];
  return SceneAsset(
    id: 'scene_music',
    name: 'Music',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'write_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'music_visited', value: true),
          ),
        ),
        for (var i = 0; i < commands.length; i++)
          SceneNode(
            id: 'command_$i',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(commands[i]),
          ),
        if (exit == 'silentCinematic')
          SceneNode(
            id: 'silent_clip',
            kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'silent_clip'),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_command',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'write_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_play',
          fromNodeId: 'write_fact',
          fromPortId: 'completed',
          toNodeId: 'command_0',
          kind: SceneEdgeKind.actionCompleted,
        ),
        if (exit == 'blocked')
          SceneEdge(
            id: 'broken_blocked_end',
            fromNodeId: 'command_2',
            fromPortId: 'blocked',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        if (exit == 'silentCinematic')
          SceneEdge(
            id: 'clip_wait',
            fromNodeId: 'silent_clip',
            fromPortId: 'completed',
            toNodeId: 'command_1',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        for (var i = 0; i < commands.length; i++)
          SceneEdge(
            id: 'command_${i}_next',
            fromNodeId: 'command_$i',
            fromPortId: 'completed',
            toNodeId: i == 0 && exit == 'silentCinematic'
                ? 'silent_clip'
                : i + 1 < commands.length
                ? 'command_${i + 1}'
                : 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}

RuntimeMapBundle _bundle(String root, SceneAsset scene) => RuntimeMapBundle(
  projectRootDirectory: root,
  tilesetAbsolutePathsById: const {},
  manifest: ProjectManifest(
    name: 'Scoped music',
    facts: [
      NarrativeFactDefinition(id: 'music_visited', label: 'Music visited'),
    ],
    maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'room.json'),
    ],
    tilesets: const [],
    scenes: [scene],
    cinematics: [
      CinematicAsset(
        id: 'silent_clip',
        title: 'Silent clip',
        mapId: 'room',
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'hold',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 300,
            ),
          ],
        ),
      ),
    ],
    cinematicMediaAssets: [
      CinematicMediaAsset(
        id: 'rival',
        label: 'Rival',
        kind: CinematicMediaAssetKind.music,
        relativePath: 'scene.ogg',
        durationMs: 20,
        loopByDefault: false,
      ),
      CinematicMediaAsset(
        id: 'broken',
        label: 'Broken',
        kind: CinematicMediaAssetKind.music,
        relativePath: 'broken.ogg',
      ),
    ],
  ),
  map: const MapData(
    id: 'room',
    name: 'Room',
    size: GridSize(width: 10, height: 10),
    layers: [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
      MapEntity(
        id: 'start',
        name: 'Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'start',
      musicPath: 'map.ogg',
      musicVolume: .4,
    ),
  ),
);

final class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  int next = 0;
  final loops = <(String, bool)>[];
  final failedPaths = <String>[];
  final paused = <Object>[];
  final resumed = <Object>[];
  @override
  Future<void> pause(Object handle) async => paused.add(handle);
  @override
  Future<void> resume(Object handle) async => resumed.add(handle);
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    if (path.endsWith('/broken.ogg')) {
      failedPaths.add(path);
      throw StateError('Failed scene track');
    }
    loops.add((path, loop));
    return 'handle_${next++}';
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}
  @override
  Future<void> stop(Object handle) async {}
}

SceneAsset _battleScene() => SceneAsset(
  id: 'scene_music_battle',
  name: 'Music battle QA',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'play',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.sceneMusic(
            operation: SceneMusicOperation.play,
            mediaAssetId: 'rival',
            volume: .7,
          ),
        ),
      ),
      SceneNode(
        id: 'battle',
        kind: SceneNodeKind.battle,
        payload: SceneBattlePayload(
          battleKind: 'trainer',
          trainerId: 'trainer_rookie',
          npcEntityId: 'npc_trainer_rookie',
          defeatRecovery: SceneBattleDefeatRecovery.continueScene,
        ),
      ),
      SceneNode(
        id: 'wait',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.wait(durationMs: 600),
        ),
      ),
      SceneNode(
        id: 'restore',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.sceneMusic(
            operation: SceneMusicOperation.restore,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_play',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'play',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'play_battle',
        fromNodeId: 'play',
        fromPortId: 'completed',
        toNodeId: 'battle',
        kind: SceneEdgeKind.actionCompleted,
      ),
      for (final result in ['victory', 'defeat'])
        SceneEdge(
          id: 'battle_$result',
          fromNodeId: 'battle',
          fromPortId: result,
          toNodeId: 'wait',
          kind: result == 'victory'
              ? SceneEdgeKind.battleVictory
              : SceneEdgeKind.battleDefeat,
        ),
      SceneEdge(
        id: 'wait_restore',
        fromNodeId: 'wait',
        fromPortId: 'completed',
        toNodeId: 'restore',
        kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(
        id: 'restore_end',
        fromNodeId: 'restore',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);
