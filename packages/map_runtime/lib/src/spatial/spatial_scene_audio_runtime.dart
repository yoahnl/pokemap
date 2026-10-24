import 'dart:async';

import 'package:map_core/map_core.dart';

import '../player/runtime_audio_mixer.dart';
import '../player/runtime_music_service.dart';
import '../player/runtime_scene_music_controller.dart';
import '../player/runtime_world_audio_controller.dart';
import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import '../presentation/flame/flame_narrative_sound_playback_adapter.dart';

final class SpatialSceneAudioRuntime {
  SpatialSceneAudioRuntime({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required String Function(CinematicMediaAsset) resolvePath,
    required RuntimeAudioMixer mixer,
    required RuntimeMusicService music,
    FlameCinematicAudioDriver Function()? driverFactory,
    this.captureMusicBaseline,
    this.onMusicChanged,
  }) : _mediaAssets = List.unmodifiable(mediaAssets),
       _resolvePath = resolvePath,
       _music = music,
       _create = (() => FlameNarrativeSoundPlaybackAdapter(
         mediaAssets: mediaAssets,
         resolvePath: resolvePath,
         mixer: mixer,
         musicService: music,
         audioDriver: driverFactory?.call(),
       )) {
    _player = _create();
  }

  final List<CinematicMediaAsset> _mediaAssets;
  final String Function(CinematicMediaAsset) _resolvePath;
  final RuntimeMusicService _music;
  final RuntimeSceneMusicSelection Function()? captureMusicBaseline;
  final Future<void> Function()? onMusicChanged;
  RuntimeWorldAudioController? _worldAudio;
  Object? _sceneOwner;
  RuntimeSceneMusicSelection? get musicSelection =>
      _worldAudio?.music.selection;

  RuntimeSceneMusicSelection _baseline() =>
      captureMusicBaseline?.call() ??
      (route: RuntimeAudioRoute.overworld, path: null, volume: .8);

  Future<void> _publishMusic() async {
    if (_disposed) return;
    if (onMusicChanged case final publish?) {
      await publish();
    } else {
      final selected = musicSelection ?? _baseline();
      await _music.update(
        route: selected.route,
        path: selected.path,
        volume: selected.volume,
      );
      if (_music.lastFailure case final failure?) throw failure;
    }
  }

  Future<String> _executeMusic(
    SceneMusicInteractiveCommand command,
    Object owner,
  ) async {
    if (command.channel != SceneMusicChannel.music ||
        command.scope != SceneMusicScope.scene ||
        _sceneOwner != null && !identical(_sceneOwner, owner)) {
      return 'blocked';
    }
    String? path;
    if (command.operation == SceneMusicOperation.play) {
      final matches = _mediaAssets
          .where(
            (asset) =>
                asset.id == command.mediaAssetId &&
                asset.kind == CinematicMediaAssetKind.music,
          )
          .toList();
      if (matches.length != 1) {
        throw StateError('Scene music requires a unique music asset.');
      }
      path = _resolvePath(matches.single);
    }
    _sceneOwner = owner;
    final controller = _worldAudio ??= RuntimeWorldAudioController(
      owner: owner,
      isOwnerCurrent: (candidate) =>
          !_disposed && identical(_sceneOwner, candidate),
      captureBaseline: (_) => _baseline(),
      onChanged: _publishMusic,
    );
    final applied = await switch (command.operation) {
      SceneMusicOperation.play => controller.play(
        channel: command.channel,
        path: path!,
        volume: command.volume!,
      ),
      SceneMusicOperation.stop => controller.stop(command.channel),
      SceneMusicOperation.restore => controller.restore(command.channel),
      SceneMusicOperation.memorize => controller.memorize(command.channel),
      SceneMusicOperation.restoreMemorized => controller.restoreMemorized(
        command.channel,
      ),
      SceneMusicOperation.fadeOut => controller.fadeOut(
        channel: command.channel,
        duration: Duration(milliseconds: command.durationMs!),
      ),
    };
    return applied && !_disposed ? 'completed' : 'blocked';
  }

  Future<void> releaseScene(Object owner) async {
    if (!identical(owner, _sceneOwner)) return;
    final controller = _worldAudio;
    try {
      await controller?.close();
      if (controller?.transactionFailure case final failure?) throw failure;
    } finally {
      if (identical(owner, _sceneOwner)) {
        _worldAudio = null;
        _sceneOwner = null;
      }
    }
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
      if (command is SceneMusicInteractiveCommand) {
        return await _executeMusic(command, sceneOwner);
      }
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
    await Future.wait([
      _releasing,
      _player.dispose(),
      if (_worldAudio != null) _worldAudio!.close(),
    ]);
    _worldAudio = null;
    _sceneOwner = null;
  }
}
