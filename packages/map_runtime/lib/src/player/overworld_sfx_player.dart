import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'runtime_audio_mixer.dart';

abstract interface class OverworldSfxPlayer {
  Future<void> playJump();
  Future<void> dispose();
}

final class FlameAudioOverworldSfxPlayer implements OverworldSfxPlayer {
  FlameAudioOverworldSfxPlayer({
    this.mixer,
    AudioPlayer Function()? playerFactory,
  }) : _playerFactory = playerFactory ?? AudioPlayer.new;

  static const jumpAsset =
      'packages/map_runtime/assets/audio/overworld/jump.wav';
  static final _cache = AudioCache(prefix: '');
  final RuntimeAudioMixer? mixer;
  final AudioPlayer Function() _playerFactory;
  AudioPlayer? _player;
  var _disposed = false;
  var _reportedFailure = false;

  @override
  Future<void> playJump() async {
    if (_disposed) return;
    final player = _player ??= _playerFactory()..audioCache = _cache;
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      if (_disposed) return;
      await mixer?.register(
        channel: player,
        route: RuntimeAudioRoute.overworldEffects,
        setVolume: player.setVolume,
      );
      if (_disposed) return;
      await player.play(AssetSource(jumpAsset));
    } on Object catch (error) {
      if (!_disposed && !_reportedFailure) {
        _reportedFailure = true;
        debugPrint('[overworld-sfx] jump playback failed: $error');
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final player = _player;
    _player = null;
    if (player == null) return;
    mixer?.unregister(player);
    try {
      await player.stop();
    } on Object catch (error) {
      debugPrint('[overworld-sfx] stop failed during teardown: $error');
    }
    try {
      await player.dispose();
    } on Object catch (error) {
      debugPrint('[overworld-sfx] dispose failed during teardown: $error');
    }
  }
}
