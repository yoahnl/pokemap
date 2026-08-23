import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

final class _RecordingAudioDriver implements FlameCinematicAudioDriver {
  final List<String> playedPaths = <String>[];

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    playedPaths.add(path);
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la musique de carte démarre au chargement du runtime — BETA-BAT-015',
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
  });

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

RuntimeMapBundle _bundle({required String? musicPath}) {
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
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
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
      ),
    ),
    projectRootDirectory: '/tmp/test_runtime_music',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}
