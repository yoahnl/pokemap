import 'dart:async';

import 'package:map_core/map_core.dart';

import '../../application/dialogue_feedback_playback_port.dart';
import '../../application/scene_runtime/scene_sound_effect_playback_port.dart';
import '../../player/runtime_audio_mixer.dart';
import '../../player/runtime_music_service.dart';
import 'flame_cinematic_media_playback_adapter.dart';

final class FlameNarrativeSoundPlaybackAdapter
    implements
        DialogueFeedbackPlaybackPort,
        SceneOwnedSoundEffectPlaybackPort,
        SceneSoundCompletionPort {
  FlameNarrativeSoundPlaybackAdapter({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required this.resolvePath,
    FlameCinematicAudioDriver? audioDriver,
    RuntimeAudioMixer? mixer,
    this.maxConcurrentVoices,
    RuntimeMusicService? musicService,
  }) : _media = {for (final asset in mediaAssets) asset.id: asset},
       _driver = audioDriver ?? FlameAudioCinematicRuntimeDriver(),
       _mixer = mixer ?? RuntimeAudioMixer(),
       _musicService = musicService {
    if (_driver is! FlameCinematicAudioLoopDriver) {
      throw ArgumentError(
        'Narrative audio driver must expose natural completion.',
      );
    }
  }

  final String Function(CinematicMediaAsset) resolvePath;
  final Map<String, CinematicMediaAsset> _media;
  final FlameCinematicAudioDriver _driver;
  final Map<String, bool> _completionResults = {};

  @override
  Future<bool> waitForPlayback(String playbackId) async =>
      _active[playbackId]?.finished.future ??
      _completionResults[playbackId] ??
      false;
  final RuntimeAudioMixer _mixer;
  final RuntimeMusicService? _musicService;
  Object? lastFailure;
  final Map<String, Future<void>> _starting = {};
  final Map<String, _NarrativeSound> _active = {};
  final Set<Future<void>> _releasing = {};
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

  Future<void> playOwnedCue(
    DialogueAudioCue cue, {
    required String playbackId,
    required Object owner,
    required Object sceneOwner,
  }) => _queue(
    cue.mediaAssetId,
    volume: cue.volume,
    playbackId: playbackId,
    route: cue.role == DialogueAudioCueRole.musicEffect
        ? RuntimeAudioRoute.cinematicMusic
        : RuntimeAudioRoute.cinematicEffects,
    interruption: cue.bgmInterruption,
    owner: owner,
    sceneOwner: sceneOwner,
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
        playbackId.trim().isEmpty) {
      throw ArgumentError('Invalid owned sound parameters.');
    }
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
      if (entry.value.route == RuntimeAudioRoute.cinematicEffects &&
          (entry.value.owner == owner || entry.value.sceneOwner == owner)) {
        await _release(entry.key, entry.value);
      }
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
    _completionResults.remove(playbackId);
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
        route == RuntimeAudioRoute.cinematicEffects &&
            ((_ownerGenerations[owner] ?? 0) != ownerGeneration ||
                (_ownerGenerations[sceneOwner] ?? 0) != sceneGeneration)) {
      try {
        await _driver.stop(handle);
      } finally {
        if (musicOwner != null) await _musicService!.endMusicEffect(musicOwner);
      }
      return;
    }
    final sound = _NarrativeSound(handle, musicOwner, owner, sceneOwner, route);
    _active[playbackId] = sound;
    try {
      sound.completion = (_driver as FlameCinematicAudioLoopDriver)
          .onComplete(handle)
          .listen(
            (_) {
              unawaited(
                _release(playbackId, sound, completed: true).catchError((
                  Object error,
                ) {
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

  Future<void> _release(
    String playbackId,
    _NarrativeSound sound, {
    bool completed = false,
  }) {
    if (!identical(_active[playbackId], sound)) return Future.value();
    late final Future<void> pending;
    pending = _releaseSound(playbackId, sound, completed: completed)
        .whenComplete(() => _releasing.remove(pending));
    _releasing.add(pending);
    return pending;
  }

  Future<void> _releaseSound(
    String playbackId,
    _NarrativeSound sound, {
    required bool completed,
  }) async {
    _active.remove(playbackId);
    _completionResults[playbackId] = completed;
    if (_completionResults.length > 128) {
      _completionResults.remove(_completionResults.keys.first);
    }
    await sound.completion?.cancel();
    _mixer.unregister(sound.handle);
    try {
      await _driver.stop(sound.handle);
    } finally {
      final owner = sound.musicEffectOwner;
      try {
        if (owner != null) await _musicService!.endMusicEffect(owner);
      } finally {
        _pruneOwnerGenerations();
        if (!sound.finished.isCompleted) sound.finished.complete(completed);
      }
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
    await Future.wait(_releasing.toList(growable: false));
  }
}

final class _NarrativeSound {
  _NarrativeSound(
    this.handle,
    this.musicEffectOwner,
    this.owner,
    this.sceneOwner,
    this.route,
  );
  final Object handle;
  final Object? musicEffectOwner;
  final Object? owner;
  final Object? sceneOwner;
  final RuntimeAudioRoute route;
  final Completer<bool> finished = Completer<bool>();
  StreamSubscription<void>? completion;
}
