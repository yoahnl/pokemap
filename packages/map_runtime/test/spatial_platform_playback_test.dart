import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_platform_playback.dart';

void main() {
  late MapData map;
  late GameState state;
  late SpatialPlatformPlayback playback;
  var blocked = false;
  setUp(() {
    blocked = false;
    map = MapData(
      id: 'hall',
      name: 'Hall',
      size: const GridSize(width: 10, height: 10),
      spatialScene: MapSpatialScene(
        width: 10,
        depth: 10,
        instances: [
          SpatialModelInstance(
            id: 'deck',
            modelId: 'deck-model',
            position: Model3dVector3(x: 2, y: 3, z: 2),
            blocksMovement: false,
          ),
        ],
        platforms: [
          SpatialPlatformDefinition(
            id: 'ride',
            name: 'Ride',
            instanceId: 'deck',
            x: 1,
            z: 1,
            width: 2,
            depth: 2,
            height: 3,
            durationMs: 1000,
            routes: [
              SpatialPlatformRoute(
                id: 'main',
                waypoints: [
                  SpatialPlatformStop(x: 0, z: 0),
                  SpatialPlatformStop(x: 1, z: 1),
                  SpatialPlatformStop(x: 4, z: 1),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    state = GameState(
      saveId: 'test',
      currentMapId: 'hall',
      playerPosition: const GridPos(x: 2, y: 2),
      playerSpatialPosition: PlayerSpatialPosition(x: 2, z: 2),
    );
    playback = SpatialPlatformPlayback(
      readMap: () => map,
      readState: () => state,
      writeState: (value) => state = value,
      readFact: (id) => false,
      canOccupy: (platform, x, z) =>
          !blocked || platform.x + x + platform.width < 4,
    );
  });
  test('transport previews player model and support with one clock then saves only a dock', () async {
    final original = state;
    final future = playback.play(
      SceneInteractiveCommand.movePlatform(
        mapId: 'hall',
        platformId: 'ride',
        motion: MovingPlatformMotion.forward,
      ),
    );
    playback.update(.5, paused: false);
    expect(state, original);
    expect(playback.playerPosition!.x, greaterThan(2));
    expect(
      playback.heightAt(
        'hall',
        playback.playerPosition!.x,
        playback.playerPosition!.z,
      ),
      3,
    );
    expect(playback.modelPose('hall', 'deck')!.translationX, greaterThan(0));
    playback.update(1, paused: true);
    expect(state, original);
    playback.update(.5, paused: false);
    expect(await future, 'moved');
    expect(state.playerSpatialPosition!.x, 6);
    expect(state.playerSpatialPosition!.z, 3);
    state = GameState.fromJson(jsonDecode(jsonEncode(state.toJson())));
    final backward = playback.play(
      SceneInteractiveCommand.movePlatform(
        mapId: 'hall',
        platformId: 'ride',
        motion: MovingPlatformMotion.backward,
      ),
    );
    playback.update(1, paused: false);
    expect(await backward, 'moved');
    expect(state.playerSpatialPosition!.x, 2);
  });
  test(
    'blocked or cancelled transport restores the original player and platform',
    () async {
      final original = state;
      blocked = true;
      final future = playback.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'hall',
          platformId: 'ride',
          motion: MovingPlatformMotion.forward,
        ),
      );
      playback.update(.9, paused: false);
      playback.update(1, paused: false);
      expect(await future, 'blocked');
      expect(state, original);
      blocked = false;
      final cancelled = playback.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'hall',
          platformId: 'ride',
          motion: MovingPlatformMotion.forward,
        ),
      );
      playback.update(.2, paused: false);
      playback.cancel();
      expect(await cancelled, 'blocked');
      expect(state, original);
      expect(
        await playback.play(
          SceneInteractiveCommand.movePlatform(
            mapId: 'hall',
            platformId: 'ride',
            motion: MovingPlatformMotion.rotateClockwise,
          ),
        ),
        'blocked',
      );
    },
  );
}
