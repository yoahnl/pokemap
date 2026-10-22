import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

final class _RecordingAudioDriver implements FlameCinematicAudioDriver {
  final List<String> playedPaths = <String>[];
  final List<double> playedVolumes = <double>[];
  final Set<Object> activeHandles = {};

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    playedPaths.add(path);
    playedVolumes.add(volume);
    final handle = Object();
    activeHandles.add(handle);
    return handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async => activeHandles.remove(handle);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final hasMusic in [true, false]) {
    testWidgets(
      hasMusic
          ? 'V1 music excludes map BGM and restores it after completion'
          : 'V1 without music keeps map BGM uninterrupted',
      (tester) async {
        await tester.runAsync(
          () => _exerciseV1Music(tester, hasMusic: hasMusic),
        );
      },
    );
  }

  for (final termination in [
    'cancelled',
    'failed',
    'unknown',
    'removed',
    'padded',
  ]) {
    testWidgets(
      termination == 'padded'
          ? 'V1 padded Scene identifiers are rejected before music handoff'
          : 'V1 music ownership handles $termination playback',
      (tester) async {
        await tester.runAsync(
          () => _exerciseV1Music(
            tester,
            hasMusic: true,
            termination: termination,
          ),
        );
      },
    );
  }

  test(
    'la musique de carte démarre au chargement du runtime — BETA-BAT-015',
    () async {
      final driver = _RecordingAudioDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
        fadeDelay: (_) async {},
      );
      final game = PlayableMapGame(
        bundle: _bundle(musicPath: 'audio/town.ogg'),
        projectFilePath: '/tmp/test_runtime_music/project.json',
        musicService: service,
      );

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      await Future<void>.delayed(Duration.zero);

      expect(driver.playedPaths, ['/tmp/test_runtime_music/audio/town.ogg']);
      expect(service.playingPath, '/tmp/test_runtime_music/audio/town.ogg');
    },
  );

  test(
    'map music uses authored source volume and keeps the default fallback',
    () async {
      for (final volume in <double?>[.64, null]) {
        final driver = _RecordingAudioDriver();
        final service = RuntimeMusicService(
          driver: driver,
          mixer: RuntimeAudioMixer(),
          fadeDelay: (_) async {},
        );
        final game = PlayableMapGame(
          bundle: _bundle(musicPath: 'audio/town.ogg', musicVolume: volume),
          projectFilePath: '/tmp/test_runtime_music/project.json',
          musicService: service,
        );
        game.onGameResize(Vector2(320, 240));
        await game.onLoad();
        await Future<void>.delayed(Duration.zero);
        expect(driver.playedVolumes, [volume ?? .8]);
        game.onRemove();
        await service.dispose();
      }
    },
  );

  test('aucune musique authored : le runtime charge en silence', () async {
    final driver = _RecordingAudioDriver();
    final service = RuntimeMusicService(
      driver: driver,
      mixer: RuntimeAudioMixer(),
      fadeDelay: (_) async {},
    );
    final game = PlayableMapGame(
      bundle: _bundle(musicPath: null),
      projectFilePath: '/tmp/test_runtime_music/project.json',
      musicService: service,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await Future<void>.delayed(Duration.zero);

    expect(driver.playedPaths, isEmpty);
    expect(service.isPlaying, isFalse);
  });
}

Future<void> _exerciseV1Music(
  WidgetTester tester, {
  required bool hasMusic,
  String termination = 'completed',
}) async {
  final root = await Directory.systemTemp.createTemp('v1-music-owner-');
  final audio = _CinematicAudioProbe()..install();
  audio.failResume = termination == 'failed';
  final driver = _RecordingAudioDriver();
  final service = RuntimeMusicService(driver: driver, fadeDelay: (_) async {});
  final cinematic = CinematicAsset(
    id: 'movie',
    title: 'Music ownership',
    mapId: 'test_music_map',
    timeline: CinematicTimeline(
      steps: [
        if (hasMusic)
          CinematicTimelineStep(
            id: 'music',
            kind: CinematicTimelineStepKind.music,
            assetRef: 'cue',
            durationMs: 100,
            metadata: const {'media.loop': 'true', 'media.volume': '0.64'},
          ),
        CinematicTimelineStep(
          id: 'hold',
          kind: CinematicTimelineStepKind.dialogueLine,
          dialogueText: 'Wait for the music check.',
        ),
      ],
    ),
  );
  final scene = SceneAsset(
    id: 'scene',
    name: 'Music ownership',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'movie',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(
            cinematicId: termination == 'padded' ? ' movie ' : 'movie',
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'movie',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'done',
          fromNodeId: 'movie',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
  final base = _bundle(musicPath: 'town.ogg');
  final game = PlayableMapGame(
    bundle: base.copyWith(
      projectRootDirectory: root.path,
      manifest: base.manifest.copyWith(
        scenes: [scene],
        cinematics: [if (termination != 'unknown') cinematic],
        cinematicMediaAssets: [
          CinematicMediaAsset(
            id: 'cue',
            label: 'Cue',
            kind: CinematicMediaAssetKind.music,
            relativePath: 'cue.ogg',
          ),
        ],
      ),
    ),
    projectFilePath: '${root.path}/project.json',
    musicService: service,
  );
  var removed = false;
  try {
    await File('${root.path}/cue.ogg').writeAsBytes([0]);
    game.onGameResize(Vector2(320, 240));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    await game.loaded;
    await tester.pump();
    await _untilV1(game, () => !game.debugIsMapActivationDispatchInFlight);
    expect(service.playingPath, '${root.path}/town.ogg');
    final completion = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event',
        sceneId: 'scene',
        executionId: 'music-owner',
        gameState: game.gameStateSnapshot,
      ),
    );
    var completed = false;
    unawaited(
      completion.then((_) {
        completed = true;
      }),
    );
    if (termination == 'failed' ||
        termination == 'unknown' ||
        termination == 'padded') {
      await _untilV1(game, () => completed);
      expect(await completion, isNot(isA<NarrativeSceneExecutionCompleted>()));
      expect(audio.playing, isEmpty);
      expect(service.playingPath, '${root.path}/town.ogg');
      expect(driver.activeHandles, hasLength(1));
      expect(driver.playedPaths, hasLength(termination == 'failed' ? 2 : 1));
      return;
    }
    await _untilV1(game, () => game.debugCinematicDialogueLine != null);
    expect(audio.playing, hasLength(hasMusic ? 1 : 0));
    expect(
      driver.activeHandles.length + audio.playing.length,
      1,
      reason: 'Map and V1 music must not be audible simultaneously.',
    );
    expect(
      service.playingPath,
      hasMusic ? isNull : equals('${root.path}/town.ogg'),
    );
    if (termination == 'cancelled') {
      game.debugResetBattleForTest();
    } else if (termination == 'removed') {
      game.onRemove();
      removed = true;
    } else {
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      );
    }
    if (removed) {
      await completion;
      await Future<void>.delayed(Duration.zero);
      expect(audio.playing, isEmpty);
      expect(service.playingPath, isNull);
      expect(driver.activeHandles, isEmpty);
      expect(driver.playedPaths, hasLength(1));
      return;
    }
    await _untilV1(game, () => completed);
    expect(
      await completion,
      termination == 'completed' || termination == 'padded'
          ? isA<NarrativeSceneExecutionCompleted>()
          : isNot(isA<NarrativeSceneExecutionCompleted>()),
    );
    await _untilV1(game, () => service.playingPath == '${root.path}/town.ogg');
    expect(audio.playing, isEmpty);
    expect(driver.activeHandles, hasLength(1));
    expect(driver.playedPaths, hasLength(hasMusic ? 2 : 1));
  } finally {
    if (!removed) game.onRemove();
    await service.dispose();
    await Future<void>.delayed(Duration.zero);
    await root.delete(recursive: true);
  }
}

Future<void> _untilV1(PlayableMapGame game, bool Function() ready) async {
  for (var tick = 0; tick < 2000; tick++) {
    if (ready()) return;
    game.update(.02);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('V1 cinematic music state did not settle.');
}

final class _CinematicAudioProbe {
  final Set<String> playing = {};
  bool failResume = false;

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final sinks = <String, MockStreamHandlerEventSink>{};
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (call) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final args = call.arguments as Map;
        final id = args['playerId'] as String;
        switch (call.method) {
          case 'create':
            messenger.setMockStreamHandler(
              EventChannel('xyz.luan/audioplayers/events/$id'),
              MockStreamHandler.inline(
                onListen: (_, sink) {
                  sinks[id] = sink;
                },
                onCancel: (_) {
                  sinks.remove(id);
                },
              ),
            );
          case 'setSourceUrl' || 'setSourceBytes':
            sinks[id]?.success({'event': 'audio.onPrepared', 'value': true});
          case 'resume':
            if (failResume) throw PlatformException(code: 'test.audio.failure');
            playing.add(id);
          case 'pause' || 'stop' || 'dispose':
            playing.remove(id);
          case 'seek':
            sinks[id]?.success({'event': 'audio.onSeekComplete'});
          case 'getCurrentPosition' || 'getDuration':
            return 0;
        }
        return null;
      },
    );
  }
}

RuntimeMapBundle _bundle({required String? musicPath, double? musicVolume}) {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Runtime Music Integration Test',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'test_music_map',
          name: 'Music Map',
          relativePath: 'maps/test_music_map.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    ),
    map: MapData(
      id: 'test_music_map',
      name: 'Music Map',
      size: const GridSize(width: 3, height: 3),
      layers: const <MapLayer>[MapLayer.object(id: 'objects', name: 'Objects')],
      entities: const <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
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
        defaultSpawnId: 'spawn_start',
        musicPath: musicPath,
        musicVolume: musicVolume,
      ),
    ),
    projectRootDirectory: '/tmp/test_runtime_music',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}
