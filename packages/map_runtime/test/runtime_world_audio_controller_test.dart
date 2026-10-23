import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_world_audio_controller.dart';

void main() {
  test(
    'map audio captures both channels and restores explicit silence atomically',
    () async {
      final owner = Object();
      final published = <(String?, String?)>[];
      late RuntimeWorldAudioController controller;
      controller = RuntimeWorldAudioController(
        owner: owner,
        isOwnerCurrent: (candidate) => identical(candidate, owner),
        captureBaseline: (channel) => (
          route: channel == SceneMusicChannel.ambience
              ? RuntimeAudioRoute.ambience
              : RuntimeAudioRoute.overworld,
          path: channel == SceneMusicChannel.ambience ? null : '/map.ogg',
          volume: .5,
        ),
        onChanged: () async {
          published.add((
            controller.music.selection?.path,
            controller.ambience.selection?.path,
          ));
        },
      );
      expect(await controller.memorize(SceneMusicChannel.both), isTrue);
      await controller.play(
        channel: SceneMusicChannel.music,
        path: '/scene.ogg',
        volume: .8,
      );
      await controller.play(
        channel: SceneMusicChannel.ambience,
        path: '/rain.ogg',
        volume: .3,
      );
      final count = published.length;
      expect(await controller.restoreMemorized(SceneMusicChannel.both), isTrue);
      expect(published.length, count + 1);
      expect(controller.music.selection?.path, '/map.ogg');
      expect(controller.ambience.selection, isNotNull);
      expect(controller.ambience.selection?.path, isNull);
      await controller.close();
    },
  );

  test(
    'zero fade stops the actual source and baseline restore remains separate',
    () async {
      final owner = Object();
      final controller = RuntimeWorldAudioController(
        owner: owner,
        isOwnerCurrent: (_) => true,
        captureBaseline: (_) =>
            (route: RuntimeAudioRoute.overworld, path: '/map.ogg', volume: .5),
        onChanged: () async {},
      );
      await controller.play(
        channel: SceneMusicChannel.music,
        path: '/scene.ogg',
        volume: .8,
      );
      await controller.fadeOut(
        channel: SceneMusicChannel.music,
        duration: Duration.zero,
      );
      expect(controller.music.selection?.path, isNull);
      expect(controller.music.selection?.volume, 0);
      await controller.restore(SceneMusicChannel.music);
      expect(controller.music.selection?.path, '/map.ogg');
      await controller.close();
    },
  );

  test('checkpoint rollback restores both channels while a stale owner cannot publish', () async {
    final owner = Object();
    var current = true;
    var published = 0;
    final controller = RuntimeWorldAudioController(
      owner: owner,
      isOwnerCurrent: (_) => current,
      captureBaseline: (_) =>
          (route: RuntimeAudioRoute.overworld, path: '/map.ogg', volume: .5),
      onChanged: () async {
        published++;
      },
    );
    final checkpoint = controller.captureCheckpoint();
    await controller.play(
      channel: SceneMusicChannel.music,
      path: '/scene.ogg',
      volume: .8,
    );
    await controller.play(
      channel: SceneMusicChannel.ambience,
      path: '/rain.ogg',
      volume: .3,
    );
    await controller.restoreCheckpoint(checkpoint);
    expect(controller.music.selection, isNull);
    expect(controller.ambience.selection, isNull);
    final count = published;
    current = false;
    expect(await controller.stop(SceneMusicChannel.music), isFalse);
    expect(await controller.restoreMemorized(SceneMusicChannel.both), isFalse);
    expect(published, count);
    await controller.close();
  });
}
