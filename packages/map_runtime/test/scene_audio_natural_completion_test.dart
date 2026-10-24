import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'package:map_runtime/src/presentation/flame/flame_narrative_sound_playback_adapter.dart';

void main() {
  test(
    'waits for the driver completion rather than a guessed duration',
    () async {
      final driver = _Driver();
      final player = _player(driver);
      await player.playSoundEffect('cue', volume: .5, playbackId: 'one');
      var finished = false;
      final waiting =
          ((player as dynamic).waitForPlayback('one') as Future<bool>).then((
            value,
          ) {
            finished = true;
            return value;
          });
      await Future<void>.delayed(Duration.zero);
      expect(finished, false);
      driver.complete.add(null);
      expect(await waiting, true);
      await player.dispose();
      await driver.complete.close();
    },
  );
  test(
    'stopping an owned sound releases its waiter without reporting completion',
    () async {
      final driver = _Driver();
      final player = _player(driver);
      final owner = Object();
      await player.playOwnedSoundEffect(
        'cue',
        volume: 1,
        playbackId: 'one',
        owner: owner,
      );
      final waiting =
          (player as dynamic).waitForPlayback('one') as Future<bool>;
      await player.stopOwnedSoundEffects(owner);
      expect(await waiting, false);
      await player.dispose();
      await driver.complete.close();
    },
  );
  test(
    'retains natural completion delivered immediately before the wait',
    () async {
      final driver = _Driver();
      final player = _player(driver);
      await player.playSoundEffect('cue', volume: 1, playbackId: 'one');
      driver.complete.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(
        await ((player as dynamic).waitForPlayback('one') as Future<bool>),
        true,
      );
      await player.dispose();
      await driver.complete.close();
    },
  );
  test('disposal and unknown playback never leave a waiter pending', () async {
    final driver = _Driver();
    final player = _player(driver);
    expect(
      await ((player as dynamic).waitForPlayback('missing') as Future<bool>),
      false,
    );
    await player.playSoundEffect('cue', volume: 1, playbackId: 'one');
    final waiting = (player as dynamic).waitForPlayback('one') as Future<bool>;
    await player.dispose();
    expect(await waiting, false);
    await driver.complete.close();
  });
}

FlameNarrativeSoundPlaybackAdapter _player(_Driver driver) =>
    FlameNarrativeSoundPlaybackAdapter(
      mediaAssets: [
        CinematicMediaAsset(
          id: 'cue',
          label: 'Cue',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'assets/cue.wav',
        ),
      ],
      resolvePath: (asset) => asset.relativePath,
      audioDriver: driver,
    );

final class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioLoopDriver {
  final handle = Object();
  final complete = StreamController<void>.broadcast(sync: true);
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async => handle;
  @override
  Future<void> stop(Object handle) async {}
  @override
  Future<void> setVolume(Object handle, double volume) async {}
  @override
  Stream<void> onComplete(Object handle) => complete.stream;
  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
}
