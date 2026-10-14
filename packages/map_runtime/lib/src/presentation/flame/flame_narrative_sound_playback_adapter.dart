import 'dart:async';

import 'package:map_core/map_core.dart';

import '../../application/dialogue_feedback_playback_port.dart';
import '../../application/scene_runtime/scene_sound_effect_playback_port.dart';
import '../../player/runtime_audio_mixer.dart';
import '../../player/runtime_music_service.dart';
import 'flame_cinematic_media_playback_adapter.dart';

final class FlameNarrativeSoundPlaybackAdapter
    implements DialogueFeedbackPlaybackPort, SceneSoundEffectPlaybackPort {
  FlameNarrativeSoundPlaybackAdapter({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required this.resolvePath,
    FlameCinematicAudioDriver? audioDriver,
    RuntimeAudioMixer? mixer,
    this._musicService,
  }) : _media = {for (final asset in mediaAssets) asset.id: asset},
       _driver = audioDriver ?? FlameAudioCinematicRuntimeDriver(),
       _mixer = mixer ?? RuntimeAudioMixer() {
    if (_driver is! FlameCinematicAudioLoopDriver) {
      throw ArgumentError(
        'Narrative audio driver must expose natural completion.',
      );
    }
  }

  final String Function(CinematicMediaAsset) resolvePath;
  final Map<String, CinematicMediaAsset> _media;
  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final RuntimeMusicService? _musicService;
  Object? lastFailure;
  final Map<String, Future<void>> _starting = {};
  final Map<String, _NarrativeSound> _active = {};
  bool _disposed = false;

  @override
  Future<void> playCue(DialogueAudioCue cue, {required String playbackId}) =>
      _queue(
        cue.mediaAssetId,
        volume: cue.volume,
        playbackId: playbackId,
        route: cue.role == DialogueAudioCueRole.musicEffect
            ? RuntimeAudioRoute.cinematicMusic
            : RuntimeAudioRoute.cinematicEffects,
        interruption: cue.bgmInterruption,
      );

  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    if (!volume.isFinite || volume < 0 || volume > 1) {
      throw ArgumentError.value(volume, 'volume', 'Expected a gain in [0, 1].');
    }
    if (playbackId.trim().isEmpty) {
      throw ArgumentError.value(playbackId, 'playbackId');
    }
    await _queue(
      mediaAssetId,
      volume: volume,
      playbackId: playbackId,
      route: RuntimeAudioRoute.cinematicEffects,
    );
    if (_disposed) {
      throw StateError('The runtime closed before the Scene sound started.');
    }
  }

  Future<void> _queue(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required RuntimeAudioRoute route,
    DialogueBgmInterruption? interruption,
  }) {
    if (_disposed) {
      return Future.error(StateError('Narrative sound playback is disposed.'));
    }
    if (_active.containsKey(playbackId)) return Future.value();
    return _starting[playbackId] ??= _start(
      mediaAssetId,
      volume: volume,
      playbackId: playbackId,
      route: route,
      interruption: interruption,
    ).whenComplete(() {
      _starting.remove(playbackId);
    });
  }

  Future<void> _start(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required RuntimeAudioRoute route,
    required DialogueBgmInterruption? interruption,
  }) async {
    final asset = _media[mediaAssetId];
    if (asset == null ||
        asset.kind != CinematicMediaAssetKind.sound ||
        asset.loopByDefault) {
      throw StateError('Narrative cue requires a known non-looping sound.');
    }
    Object? owner;
    if (interruption != null) {
      final music = _musicService;
      if (music == null) {
        throw StateError('Music effect interruption requires the BGM service.');
      }
      owner = Object();
      music.beginMusicEffect(
        owner: owner,
        fadeOut: Duration(milliseconds: interruption.fadeOutMs),
        fadeIn: Duration(milliseconds: interruption.fadeInMs),
      );
    }
    final Object handle;
    try {
      handle = await _driver.play(
        resolvePath(asset),
        volume: _mixer.mix.volumeFor(route, sourceVolume: volume),
        loop: false,
      );
    } on Object {
      if (owner != null) await _musicService!.endMusicEffect(owner);
      rethrow;
    }
    if (_disposed) {
      try {
        await _driver.stop(handle);
      } finally {
        if (owner != null) await _musicService!.endMusicEffect(owner);
      }
      return;
    }
    final sound = _NarrativeSound(handle, owner);
    _active[playbackId] = sound;
    try {
      sound.completion = (_driver as FlameCinematicAudioLoopDriver)
          .onComplete(handle)
          .listen(
            (_) {
              unawaited(
                _release(playbackId, sound).catchError((Object error) {
                  lastFailure = error;
                }),
              );
            },
            onError: (Object error, StackTrace _) {
              lastFailure = error;
              unawaited(
                _release(playbackId, sound).catchError((Object releaseError) {
                  lastFailure = releaseError;
                }),
              );
            },
          );
      await _mixer.register(
        channel: handle,
        route: route,
        sourceVolume: volume,
        setVolume: (volume) => _driver.setVolume(handle, volume),
      );
      if (_disposed || !identical(_active[playbackId], sound)) return;
    } on Object {
      await _release(playbackId, sound);
      rethrow;
    }
  }

  Future<void> _release(String playbackId, _NarrativeSound sound) async {
    if (!identical(_active[playbackId], sound)) return;
    _active.remove(playbackId);
    await sound.completion?.cancel();
    _mixer.unregister(sound.handle);
    try {
      await _driver.stop(sound.handle);
    } finally {
      final owner = sound.musicEffectOwner;
      if (owner != null) await _musicService!.endMusicEffect(owner);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await Future.wait(
      _starting.values.map((future) => future.catchError((Object _) {})),
    );
    for (final entry in _active.entries.toList(growable: false)) {
      await _release(entry.key, entry.value);
    }
  }
}

final class _NarrativeSound {
  _NarrativeSound(this.handle, this.musicEffectOwner);
  final Object handle;
  final Object? musicEffectOwner;
  StreamSubscription<void>? completion;
}
