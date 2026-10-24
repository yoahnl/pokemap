import 'dart:async';

import 'package:map_core/map_core.dart';

import '../player/runtime_audio_mixer.dart';
import '../player/runtime_music_service.dart';
import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import '../presentation/flame/flame_narrative_sound_playback_adapter.dart';

final class SpatialSceneAudioRuntime {
  SpatialSceneAudioRuntime({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required String Function(CinematicMediaAsset) resolvePath,
    required RuntimeAudioMixer mixer,
    required RuntimeMusicService music,
    FlameCinematicAudioDriver Function()? driverFactory,
  }) : _create = (() => FlameNarrativeSoundPlaybackAdapter(
         mediaAssets: mediaAssets,
         resolvePath: resolvePath,
         mixer: mixer,
         musicService: music,
         audioDriver: driverFactory?.call(),
       )) {
    _player = _create();
  }

  final FlameNarrativeSoundPlaybackAdapter Function() _create;
  late FlameNarrativeSoundPlaybackAdapter _player;
  Object _mapOwner = Object();
  var _generation = 0;
  var _sequence = 0;
  var _disposed = false;
  Future<void> _releasing = Future.value();
  Object? lastFailure;

  Future<String> execute(
    SceneInteractiveCommand command, {
    required Object sceneOwner,
  }) async {
    if (_disposed) return 'blocked';
    final generation = _generation;
    final player = _player;
    final playbackId = 'spatial-audio:${_sequence++}';
    try {
      var waitForCompletion = false;
      if (command is ScenePlaySoundEffectInteractiveCommand) {
        waitForCompletion = command.waitForCompletion;
        await player.playOwnedSoundEffect(
          command.mediaAssetId,
          volume: command.volume,
          playbackId: playbackId,
          owner: _mapOwner,
          sceneOwner: sceneOwner,
        );
      } else if (command is ScenePlayMusicEffectInteractiveCommand) {
        waitForCompletion = command.waitForCompletion;
        await player.playOwnedCue(
          DialogueAudioCue(
            mediaAssetId: command.mediaAssetId,
            cueId: playbackId,
            volume: command.volume,
            role: DialogueAudioCueRole.musicEffect,
            bgmInterruption: command.bgmInterruption,
          ),
          playbackId: playbackId,
          owner: _mapOwner,
          sceneOwner: sceneOwner,
        );
      } else if (command is SceneStopSoundEffectsInteractiveCommand) {
        await player.stopOwnedSoundEffects(
          command.scope == SceneMusicScope.map ? _mapOwner : sceneOwner,
        );
      } else {
        return 'blocked';
      }
      if (waitForCompletion && !await player.waitForPlayback(playbackId)) {
        return 'blocked';
      }
      return !_disposed && generation == _generation ? 'completed' : 'blocked';
    } on Object catch (error) {
      lastFailure = error;
      return 'blocked';
    }
  }

  Future<void> reset() {
    if (_disposed) return _releasing;
    _generation++;
    final previous = _player;
    _mapOwner = Object();
    _player = _create();
    return _releasing = Future.wait([_releasing, previous.dispose()])
        .then((_) {});
  }

  Future<void> dispose() async {
    if (_disposed) return _releasing;
    _disposed = true;
    _generation++;
    await Future.wait([_releasing, _player.dispose()]);
  }
}
