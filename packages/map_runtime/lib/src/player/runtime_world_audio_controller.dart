import 'package:map_core/map_core.dart';

import 'runtime_audio_mixer.dart';
import 'runtime_scene_music_controller.dart';

final class RuntimeWorldAudioCheckpoint {
  RuntimeWorldAudioCheckpoint._(
    this.owner,
    this.music,
    this.ambience,
    Map<SceneMusicChannel, RuntimeSceneMusicSelection> memorized,
  ) : memorized = Map.unmodifiable(memorized);
  final RuntimeWorldAudioController owner;
  final RuntimeSceneMusicCheckpoint music;
  final RuntimeSceneMusicCheckpoint ambience;
  final Map<SceneMusicChannel, RuntimeSceneMusicSelection> memorized;
}

final class RuntimeWorldAudioController {
  RuntimeWorldAudioController({
    required this.owner,
    required this.isOwnerCurrent,
    required this.captureBaseline,
    required this.onChanged,
    RuntimeSceneMusicTimerFactory? timerFactory,
    int fadeSteps = 12,
  }) {
    music = RuntimeSceneMusicController(
      owner: owner,
      isOwnerCurrent: (_) => isCurrent,
      captureBaseline: () => captureBaseline(SceneMusicChannel.music),
      onChanged: _publish,
      timerFactory: timerFactory,
      fadeSteps: fadeSteps,
    );
    ambience = RuntimeSceneMusicController(
      owner: owner,
      isOwnerCurrent: (_) => isCurrent,
      captureBaseline: () => captureBaseline(SceneMusicChannel.ambience),
      onChanged: _publish,
      timerFactory: timerFactory,
      fadeSteps: fadeSteps,
      route: RuntimeAudioRoute.ambience,
    );
  }

  final Object owner;
  final bool Function(Object owner) isOwnerCurrent;
  final RuntimeSceneMusicSelection Function(SceneMusicChannel channel)
  captureBaseline;
  final Future<void> Function() onChanged;
  late final RuntimeSceneMusicController music;
  late final RuntimeSceneMusicController ambience;
  final Map<SceneMusicChannel, RuntimeSceneMusicSelection> _memorized = {};
  int _publicationHold = 0;
  bool _closed = false;
  Object? _transactionFailure;

  bool get isCurrent => !_closed && isOwnerCurrent(owner);
  Object? get transactionFailure =>
      _transactionFailure ??
      music.transactionFailure ??
      ambience.transactionFailure;

  RuntimeSceneMusicController _channel(SceneMusicChannel channel) =>
      switch (channel) {
        SceneMusicChannel.music => music,
        SceneMusicChannel.ambience => ambience,
        SceneMusicChannel.both => throw ArgumentError(
          'Select a single audio channel.',
        ),
      };

  Iterable<SceneMusicChannel> _channels(SceneMusicChannel channel) =>
      channel == SceneMusicChannel.both
      ? const [SceneMusicChannel.music, SceneMusicChannel.ambience]
      : [channel];

  Future<void> _publish() async {
    if (_publicationHold == 0 && isCurrent) await onChanged();
  }

  RuntimeWorldAudioCheckpoint captureCheckpoint() =>
      RuntimeWorldAudioCheckpoint._(
        this,
        music.captureCheckpoint(),
        ambience.captureCheckpoint(),
        _memorized,
      );

  Future<void> _restoreQuietly(RuntimeWorldAudioCheckpoint checkpoint) async {
    _publicationHold++;
    try {
      await music.restoreCheckpoint(checkpoint.music);
      await ambience.restoreCheckpoint(checkpoint.ambience);
      _memorized
        ..clear()
        ..addAll(checkpoint.memorized);
    } finally {
      _publicationHold--;
    }
  }

  Future<bool> _atomic(Future<bool> Function() action) async {
    if (!isCurrent) return false;
    final checkpoint = captureCheckpoint();
    try {
      _publicationHold++;
      final bool applied;
      try {
        applied = await action();
      } finally {
        _publicationHold--;
      }
      if (!applied || !isCurrent) return false;
      await onChanged();
      return isCurrent;
    } catch (error) {
      _transactionFailure ??= error;
      if (isCurrent) {
        await _restoreQuietly(checkpoint);
        try {
          await onChanged();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<bool> play({
    required SceneMusicChannel channel,
    required String path,
    required double volume,
  }) => _atomic(() => _channel(channel).play(path: path, volume: volume));

  Future<bool> stop(SceneMusicChannel channel) =>
      _atomic(() => _channel(channel).stop());

  Future<bool> restore(SceneMusicChannel channel) =>
      _atomic(() => _channel(channel).restore());

  Future<bool> fadeOut({
    required SceneMusicChannel channel,
    required Duration duration,
  }) => _atomic(() => _channel(channel).fadeOut(duration: duration));

  Future<bool> memorize(SceneMusicChannel channel) async {
    if (!isCurrent) return false;
    final selected = <SceneMusicChannel, RuntimeSceneMusicSelection>{
      for (final current in _channels(channel))
        current: _channel(current).selection ?? captureBaseline(current),
    };
    _memorized.addAll(selected);
    return true;
  }

  Future<bool> restoreMemorized(SceneMusicChannel channel) async {
    if (!isCurrent ||
        _channels(channel).any((current) => !_memorized.containsKey(current)))
      return false;
    return _atomic(() async {
      for (final current in _channels(channel)) {
        if (!await _channel(current).select(_memorized[current]!)) return false;
      }
      return true;
    });
  }

  Future<bool> restoreCheckpoint(RuntimeWorldAudioCheckpoint checkpoint) {
    if (!identical(checkpoint.owner, this))
      throw ArgumentError('World audio checkpoint belongs to another owner.');
    return _atomic(() async {
      await _restoreQuietly(checkpoint);
      return true;
    });
  }

  Future<void> close() async {
    if (_closed) return;
    final publish = isCurrent;
    _publicationHold++;
    try {
      await music.close();
      await ambience.close();
    } finally {
      _publicationHold--;
    }
    _closed = true;
    _memorized.clear();
    if (publish && isOwnerCurrent(owner)) {
      try {
        await onChanged();
      } catch (error) {
        _transactionFailure ??= error;
      }
    }
  }
}
