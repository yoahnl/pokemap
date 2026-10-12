import 'dart:async';

import 'package:map_core/map_core.dart';

import '../../application/dialogue_feedback_playback_port.dart';
import '../../player/runtime_audio_mixer.dart';
import 'flame_cinematic_media_playback_adapter.dart';

final class FlameDialogueFeedbackPlaybackAdapter
    implements DialogueFeedbackPlaybackPort {
  FlameDialogueFeedbackPlaybackAdapter({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required this.resolvePath,
    FlameCinematicAudioDriver? audioDriver,
    RuntimeAudioMixer? mixer,
  }) : _media = {for (final asset in mediaAssets) asset.id: asset},
       _driver = audioDriver ?? FlameAudioCinematicRuntimeDriver(),
       _mixer = mixer ?? RuntimeAudioMixer() {
    if (_driver is! FlameCinematicAudioLoopDriver) {
      throw ArgumentError(
        'Dialogue audio driver must expose natural completion.',
      );
    }
  }

  final String Function(CinematicMediaAsset) resolvePath;
  final Map<String, CinematicMediaAsset> _media;
  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final Map<String, Future<void>> _starting = {};
  final Map<String, _DialogueSound> _active = {};
  bool _disposed = false;

  @override
  Future<void> playCue(DialogueAudioCue cue, {required String playbackId}) {
    if (_disposed) {
      return Future.error(StateError('Dialogue playback is disposed.'));
    }
    if (_active.containsKey(playbackId)) return Future.value();
    return _starting[playbackId] ??= _start(cue, playbackId).whenComplete(() {
      _starting.remove(playbackId);
    });
  }

  Future<void> _start(DialogueAudioCue cue, String playbackId) async {
    final asset = _media[cue.mediaAssetId];
    if (asset == null ||
        asset.kind != CinematicMediaAssetKind.sound ||
        asset.loopByDefault) {
      throw StateError('Dialogue cue requires a known non-looping sound.');
    }
    final handle = await _driver.play(
      resolvePath(asset),
      volume:
          cue.volume * _mixer.mix.volumeFor(RuntimeAudioRoute.cinematicEffects),
      loop: false,
    );
    if (_disposed) {
      await _driver.stop(handle);
      return;
    }
    final sound = _DialogueSound(handle);
    _active[playbackId] = sound;
    try {
      sound.completion = (_driver as FlameCinematicAudioLoopDriver)
          .onComplete(handle)
          .listen((_) {
            unawaited(_release(playbackId, sound));
          });
      await _mixer.register(
        channel: handle,
        route: RuntimeAudioRoute.cinematicEffects,
        setVolume: (volume) => _driver.setVolume(handle, cue.volume * volume),
      );
      if (_disposed || !identical(_active[playbackId], sound)) return;
    } on Object {
      await _release(playbackId, sound);
      rethrow;
    }
  }

  Future<void> _release(String playbackId, _DialogueSound sound) async {
    if (!identical(_active[playbackId], sound)) return;
    _active.remove(playbackId);
    await sound.completion?.cancel();
    _mixer.unregister(sound.handle);
    await _driver.stop(sound.handle);
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

final class _DialogueSound {
  _DialogueSound(this.handle);
  final Object handle;
  StreamSubscription<void>? completion;
}
