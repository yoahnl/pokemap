import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/spatial/spatial_lift_playback.dart';

void main() {
  late MapData map;
  late SpatialWorldState world;
  late SpatialLiftPlayback runtime;
  setUp(() {
    map = MapData(
      id: 'hall',
      name: 'Hall',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'deck',
            modelId: 'deck-model',
            position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
          ),
        ],
        lifts: [
          SpatialLiftDefinition(
            id: 'lift',
            name: 'Lift',
            instanceId: 'deck',
            x: 2,
            z: 2,
            width: 3,
            depth: 3,
            lowerHeight: 2,
            upperHeight: 31,
            durationMs: 1000,
          ),
        ],
      ),
    );
    world = const SpatialWorldState.empty();
    runtime = SpatialLiftPlayback(
      readMap: () => map,
      readWorld: () => world,
      writeWorld: (value) => world = value,
    );
  });
  test('standing player follows the platform and only exits at the matching floor', () async {
    final scene=MapSpatialScene(width:8,depth:8,heightLevels:[for(var z=0;z<8;z++)for(var x=0;x<8;x++)z<2?31:2],navigation:SpatialNavigationProfile(spawn:SpatialSpawn(x:3.5,z:3.5)));
    final movement=SpatialMovementController(scene:scene,models:[]);
    movement.terrainHeightOverride=(x,z)=>runtime.heightAt(map.id,x,z);
    final position=movement.spatialPosition;
    expect(movement.groundY,2);
    expect(movement.canTraverseActor(3.5,2.125,3.5,1.875),isFalse);
    final up=runtime.play(SceneInteractiveCommand.movePlatform(mapId:map.id,platformId:'lift',motion:MovingPlatformMotion.forward));
    runtime.update(.4,paused:false);
    expect(movement.groundY,closeTo(13.6,1e-6));
    expect(movement.spatialPosition,position);
    runtime.update(.6,paused:false);
    expect(await up,'moved');
    expect(movement.groundY,31);
    expect(movement.canTraverseActor(3.5,2.125,3.5,1.875),isTrue);
    final down=runtime.play(SceneInteractiveCommand.movePlatform(mapId:map.id,platformId:'lift',motion:MovingPlatformMotion.backward));
    runtime.update(.4,paused:false);
    runtime.cancel();
    expect(await down,'blocked');
    expect(movement.groundY,31);
    expect(movement.spatialPosition,position);
  });
  test(
    'model and standing terrain share one clock and persist only at endpoint',
    () async {
      final pending = runtime.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'hall',
          platformId: 'lift',
          motion: MovingPlatformMotion.forward,
        ),
      );
      runtime.update(.4, paused: false);
      expect(world.modelsByMap, isEmpty);
      expect(
        runtime.modelPose('hall', 'deck')!.translationY,
        closeTo(11.6, 1e-6),
      );
      expect(runtime.heightAt('hall', 3.5, 3.5), closeTo(13.6, 1e-6));
      runtime.update(.9, paused: true);
      expect(world.modelsByMap, isEmpty);
      runtime.update(.6, paused: false);
      expect(await pending, 'moved');
      expect(runtime.modelPose('hall', 'deck'), isNull);
      expect(runtime.heightAt('hall', 3.5, 3.5), 31);
      world = SpatialWorldState.fromJson(
        jsonDecode(jsonEncode(world.toJson())),
      );
      final down = runtime.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'hall',
          platformId: 'lift',
          motion: MovingPlatformMotion.backward,
        ),
      );
      runtime.update(1, paused: false);
      expect(await down, 'moved');
      expect(runtime.heightAt('hall', 3.5, 3.5), 2);
    },
  );
  test('cancelled or invalid motion cannot persist a partial height', () async {
    final before = world;
    final pending = runtime.play(
      SceneInteractiveCommand.movePlatform(
        mapId: 'hall',
        platformId: 'lift',
        motion: MovingPlatformMotion.forward,
      ),
    );
    runtime.update(.4, paused: false);
    runtime.cancel();
    expect(await pending, 'blocked');
    expect(world, before);
    expect(runtime.heightAt('hall', 3.5, 3.5), 2);
    expect(
      await runtime.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'hall',
          platformId: 'lift',
          motion: MovingPlatformMotion.rotateClockwise,
        ),
      ),
      'blocked',
    );
    expect(
      await runtime.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'other',
          platformId: 'lift',
          motion: MovingPlatformMotion.forward,
        ),
      ),
      'blocked',
    );
  });
  test(
    'commit detects a changed platform without overwriting foreign world state',
    () async {
      final pending = runtime.play(
        SceneInteractiveCommand.movePlatform(
          mapId: 'hall',
          platformId: 'lift',
          motion: MovingPlatformMotion.forward,
        ),
      );
      world = world.setModelState(
        'hall',
        'deck',
        SpatialModelRuntimeState(
          modelId: 'deck-model',
          animationIndex: null,
          normalizedTime: 0,
          blocksMovement: false,
          translationY: 29,
        ),
      );
      final foreign = world;
      final check = expectLater(pending, throwsStateError);
      runtime.update(1, paused: false);
      await check;
      expect(world, foreign);
      expect(runtime.isPlaying, isFalse);
    },
  );
}
