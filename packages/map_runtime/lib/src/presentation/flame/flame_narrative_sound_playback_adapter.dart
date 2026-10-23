import 'dart:async';

import 'package:map_core/map_core.dart';

import '../../application/dialogue_feedback_playback_port.dart';
import '../../application/scene_runtime/scene_sound_effect_playback_port.dart';
import '../../player/runtime_audio_mixer.dart';
import '../../player/runtime_music_service.dart';
import 'flame_cinematic_media_playback_adapter.dart';

final class FlameNarrativeSoundPlaybackAdapter
    implements DialogueFeedbackPlaybackPort, SceneOwnedSoundEffectPlaybackPort {
  FlameNarrativeSoundPlaybackAdapter({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required this.resolvePath,
    FlameCinematicAudioDriver? audioDriver,
    RuntimeAudioMixer? mixer,
    this.maxConcurrentVoices,
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
  final Map<Object, int> _ownerGenerations = {};
  final Map<String, (Object?, Object?)> _startingOwners = {};
  bool _disposed = false;
  int? maxConcurrentVoices;

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

  @override
  Future<void> playOwnedSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required Object owner,
    Object? sceneOwner,
  }) async {
    if (!volume.isFinite ||
        volume < 0 ||
        volume > 1 ||
        playbackId.trim().isEmpty)
      throw ArgumentError('Invalid owned sound parameters.');
    await _queue(
      mediaAssetId,
      volume: volume,
      playbackId: playbackId,
      route: RuntimeAudioRoute.cinematicEffects,
      owner: owner,
      sceneOwner: sceneOwner,
    );
  }

  @override
  Future<void> stopOwnedSoundEffects(Object owner) async {
    _ownerGenerations[owner] = (_ownerGenerations[owner] ?? 0) + 1;
    for (final entry in _active.entries.toList(growable: false)) {
      if (entry.value.owner == owner || entry.value.sceneOwner == owner)
        await _release(entry.key, entry.value);
    }
    _pruneOwnerGenerations();
  }

  void _pruneOwnerGenerations() {
    final owners = <Object?>{
      for (final sound in _active.values) ...[sound.owner, sound.sceneOwner],
      for (final owner in _startingOwners.values) ...[owner.$1, owner.$2],
    };
    _ownerGenerations.removeWhere((owner, _) => !owners.contains(owner));
  }

  Future<void> _queue(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required RuntimeAudioRoute route,
    DialogueBgmInterruption? interruption,
    Object? owner,
    Object? sceneOwner,
  }) {
    if (_disposed) {
      return Future.error(StateError('Narrative sound playback is disposed.'));
    }
    if (_active.containsKey(playbackId)) return Future.value();
    if (route == RuntimeAudioRoute.cinematicEffects &&
        maxConcurrentVoices != null &&
        !_starting.containsKey(playbackId) &&
        {..._active.keys, ..._starting.keys}.length >= maxConcurrentVoices!) {
      return Future.value();
    }
    final starting = _starting[playbackId];
    if (starting != null) return starting;
    _startingOwners[playbackId] = (owner, sceneOwner);
    return _starting[playbackId] =
        _start(
          mediaAssetId,
          volume: volume,
          playbackId: playbackId,
          route: route,
          interruption: interruption,
          owner: owner,
          sceneOwner: sceneOwner,
        ).whenComplete(() {
          _starting.remove(playbackId);
          _startingOwners.remove(playbackId);
          _pruneOwnerGenerations();
        });
  }

  Future<void> _start(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required RuntimeAudioRoute route,
    required DialogueBgmInterruption? interruption,
    Object? owner,
    Object? sceneOwner,
  }) async {
    final asset = _media[mediaAssetId];
    if (asset == null ||
        asset.kind != CinematicMediaAssetKind.sound ||
        asset.loopByDefault) {
      throw StateError('Narrative cue requires a known non-looping sound.');
    }
    final ownerGeneration = _ownerGenerations[owner] ?? 0;
    final sceneGeneration = _ownerGenerations[sceneOwner] ?? 0;
    Object? musicOwner;
    if (interruption != null) {
      final music = _musicService;
      if (music == null) {
        throw StateError('Music effect interruption requires the BGM service.');
      }
      musicOwner = Object();
      music.beginMusicEffect(
        owner: musicOwner,
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
      if (musicOwner != null) await _musicService!.endMusicEffect(musicOwner);
      rethrow;
    }
    if (_disposed ||
        (_ownerGenerations[owner] ?? 0) != ownerGeneration ||
        (_ownerGenerations[sceneOwner] ?? 0) != sceneGeneration) {
      try {
        await _driver.stop(handle);
      } finally {
        if (musicOwner != null) await _musicService!.endMusicEffect(musicOwner);
      }
      return;
    }
    final sound = _NarrativeSound(handle, musicOwner, owner, sceneOwner);
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
      _pruneOwnerGenerations();
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
  _NarrativeSound(
    this.handle,
    this.musicEffectOwner,
    this.owner,
    this.sceneOwner,
  );
  final Object handle;
  final Object? musicEffectOwner;
  final Object? owner;
  final Object? sceneOwner;
  StreamSubscription<void>? completion;
}
