import 'dart:async';

import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

final class ProjectAudioTestDriver
    implements
        FlameCinematicAudioDriver,
        FlameCinematicAudioLoopDriver,
        FlameCinematicAudioPausableDriver {
  final paths = <String>[];
  final startingVolumes = <double>[];
  final volumes = <int, double>{};
  final completions = <int, StreamController<void>>{};
  final paused = <int>{}, stopped = <int>{};
  int replays = 0;
  bool failReplay = false, failStop = false;
  Completer<void>? gate;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    paths.add(path);
    startingVolumes.add(volume);
    final id = paths.length;
    completions[id] = StreamController<void>.broadcast(sync: true);
    volumes[id] = volume;
    await gate?.future;
    return id;
  }

  void complete(int id) => completions[id]!.add(null);
  @override
  Stream<void> onComplete(Object handle) => completions[handle as int]!.stream;
  @override
  Future<void> seekAndResume(Object handle, Duration position) async {
    replays++;
    if (failReplay) throw StateError('Replay failed');
  }

  @override
  Future<void> pause(Object handle) async {
    paused.add(handle as int);
  }

  @override
  Future<void> resume(Object handle) async {
    paused.remove(handle as int);
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    volumes[handle as int] = volume;
  }

  @override
  Future<void> stop(Object handle) async {
    stopped.add(handle as int);
    await completions[handle]!.close();
    if (failStop) throw StateError('Stop failed');
  }
}
