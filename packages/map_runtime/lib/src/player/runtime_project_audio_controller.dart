import 'dart:async';
import 'dart:collection';

import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';

final class RuntimeProjectAudioFile {
  const RuntimeProjectAudioFile({required this.path, this.mimeType});
  final String path;
  final String? mimeType;
}

final class RuntimeResolvedProjectSound {
  const RuntimeResolvedProjectSound({
    required this.path,
    required this.gain,
    required this.loop,
    this.mimeType,
  });
  final String path;
  final double gain;
  final bool loop;
  final String? mimeType;
}

typedef RuntimeProjectAudioMediaResolver = RuntimeProjectAudioFile? Function(
  String mediaId,
);

final class RuntimeProjectAudioController {
  RuntimeProjectAudioController({
    required this.mixer,
    this.settings,
    this.resolveMedia,
    this.onPlaybackChanged,
    FlameCinematicAudioDriver? driver,
    this.voicesPerCue = 4,
  }) {
    if (voicesPerCue < 1) {
      throw ArgumentError.value(voicesPerCue, 'voicesPerCue');
    }
    _driver = driver ?? createDriver();
    if (_driver is! FlameCinematicAudioLoopDriver ||
        _driver is! FlameCinematicAudioPausableDriver) {
      throw ArgumentError(
        'Action sounds require completion, replay and lifecycle driver capabilities.',
      );
    }
  }

  static final _defaults = ProjectAudioSettings();
  final RuntimeAudioMixer mixer;
  final void Function()? onPlaybackChanged;
  bool isPlaying(ProjectSoundCue cue) =>
      _voices[cue]?.any((voice) => voice.busy) ?? false;
  int _epoch = 0;
  ProjectAudioSettings? settings;
  RuntimeProjectAudioMediaResolver? resolveMedia;
  final int voicesPerCue;
  late final FlameCinematicAudioDriver _driver;
  final _voices = <ProjectSoundCue, List<_ProjectSoundVoice>>{};
  final _mimeTypes = <String, String>{};
  final _eventIds = <String>{};
  final _eventOrder = Queue<String>();
  Future<void> _pending = Future.value();
  bool _disposed = false, _suspended = false;
  Object? lastFailure;

  FlameCinematicAudioDriver createDriver() => FlameAudioCinematicRuntimeDriver(
    playerFactory: () => AudioPlayer()..audioCache = AudioCache(prefix: ''),
    sourceFactory: (path) => path.startsWith('packages/map_runtime/')
        ? AssetSource(path)
        : DeviceFileSource(path, mimeType: _mimeTypes[path]),
  );

  RuntimeResolvedProjectSound? resolve(
    ProjectSoundCue cue, {
    String? builtinPath,
    ProjectSoundBinding? binding,
  }) {
    final selected =
        (binding ?? settings?.bindingFor(cue) ?? _defaults.bindingFor(cue))
            .validated();
    if (selected.source == ProjectSoundSource.silent || selected.gain == 0) {
      return null;
    }
    final RuntimeProjectAudioFile? file;
    if (selected.source == ProjectSoundSource.custom) {
      file = resolveMedia?.call(selected.mediaId!);
      if (file == null) {
        lastFailure = StateError(
          'Sound media is unavailable: ${selected.mediaId}',
        );
        return null;
      }
    } else {
      file = RuntimeProjectAudioFile(path: builtinPath ?? builtinPaths[cue]!);
    }
    if (file.mimeType case final type?) _mimeTypes[file.path] = type;
    return RuntimeResolvedProjectSound(
      path: file.path,
      gain: selected.gain,
      loop: ProjectSoundCueCatalog.forCue(cue).loop,
      mimeType: file.mimeType,
    );
  }

  Future<bool> play(
    ProjectSoundCue cue, {
    double sourceGain = 1,
    String? eventId,
    ProjectSoundBinding? binding,
  }) {
    if (_disposed || _suspended) return Future.value(false);
    if (!sourceGain.isFinite || sourceGain < 0 || sourceGain > 1) {
      return Future.error(ArgumentError.value(sourceGain, 'sourceGain'));
    }
    if (eventId != null) {
      if (!_eventIds.add(eventId)) return Future.value(false);
      _eventOrder.addLast(eventId);
      if (_eventOrder.length > 128) _eventIds.remove(_eventOrder.removeFirst());
    }
    final epoch = _epoch;
    final result = Completer<bool>();
    _pending = _pending.then((_) async {
      try {
        result.complete(await _play(cue, sourceGain, binding, epoch));
      } catch (error) {
        lastFailure = error;
        result.complete(false);
      }
    });
    return result.future;
  }

  Future<bool> _play(
    ProjectSoundCue cue,
    double sourceGain,
    ProjectSoundBinding? binding,
    int epoch,
  ) async {
    if (_disposed || _suspended || epoch != _epoch) return false;
    final selected = resolve(cue, binding: binding);
    if (selected == null) return false;
    final voices = _voices.putIfAbsent(cue, () => []);
    var voice = voices
        .where(
          (voice) => !voice.busy && voice.path == selected.path && !voice.loop,
        )
        .firstOrNull;
    if (voice == null && voices.length >= voicesPerCue) {
      final idle = voices.where((voice) => !voice.busy).firstOrNull;
      if (idle == null) return false;
      await _release(cue, idle);
    }
    final volume = selected.gain * sourceGain;
    final route =
        cue == ProjectSoundCue.weatherRain ||
            cue == ProjectSoundCue.weatherWind ||
            cue == ProjectSoundCue.weatherThunder ||
            cue == ProjectSoundCue.fireCrackle
        ? RuntimeAudioRoute.ambience
        : RuntimeAudioRoute.overworldEffects;
    if (voice == null) {
      final handle = await _driver.play(
        selected.path,
        volume: mixer.volumeFor(route, sourceVolume: volume),
        loop: selected.loop,
      );
      if (_disposed || _suspended || epoch != _epoch) {
        await _driver.stop(handle);
        return false;
      }
      voice = _ProjectSoundVoice(handle, selected.path, selected.loop);
      voices.add(voice);
      voice.busy = true;
      final current = voice;
      if (!selected.loop) {
        current.completion = (_driver as FlameCinematicAudioLoopDriver)
            .onComplete(handle)
            .listen(
              (_) {
                current.busy = false;
                onPlaybackChanged?.call();
              },
              onError: (Object error) {
                lastFailure = error;
                current.busy = false;
                onPlaybackChanged?.call();
              },
            );
      }
      try {
        await mixer.register(
          channel: current,
          route: route,
          sourceVolume: volume,
          setVolume: (volume) => _driver.setVolume(handle, volume),
        );
      } catch (_) {
        await _release(cue, current);
        rethrow;
      }
    } else {
      voice.busy = true;
      try {
        await mixer.updateSourceVolume(voice, volume);
        await (_driver as FlameCinematicAudioLoopDriver).seekAndResume(
          voice.handle,
          Duration.zero,
        );
      } catch (_) {
        await _release(cue, voice);
        rethrow;
      }
    }
    if (_disposed || _suspended || epoch != _epoch) {
      await _release(cue, voice);
      return false;
    }
    onPlaybackChanged?.call();
    lastFailure = null;
    return true;
  }

  Future<void> stopAll() {
    _epoch++;
    return _pending = _pending.then((_) => _releaseAll());
  }

  Future<void> stopCue(ProjectSoundCue cue) =>
      _pending = _pending.then((_) => _releaseAll(cue: cue));

  Future<void> _releaseAll({ProjectSoundCue? cue}) async {
    for (final key in cue == null ? _voices.keys.toList() : [cue]) {
      for (final voice in List<_ProjectSoundVoice>.of(
        _voices[key] ?? const [],
      )) {
        try {
          await _release(key, voice);
        } catch (error) {
          lastFailure = error;
        }
      }
    }
  }

  Future<void> setSuspended(bool suspended) {
    if (_disposed || _suspended == suspended) return _pending;
    _suspended = suspended;
    return _pending = _pending.then((_) async {
      final pausable = _driver as FlameCinematicAudioPausableDriver;
      try {
        for (final voices in _voices.values) {
          for (final voice in voices.where((voice) => voice.busy)) {
            if (_suspended) {
              await pausable.pause(voice.handle);
            } else {
              await pausable.resume(voice.handle);
            }
          }
        }
      } catch (error) {
        lastFailure = error;
        await _releaseAll();
      }
    });
  }

  Future<void> _release(ProjectSoundCue cue, _ProjectSoundVoice voice) async {
    _voices[cue]?.remove(voice);
    mixer.unregister(voice);
    try {
      await voice.completion?.cancel();
    } finally {
      try {
        await _driver.stop(voice.handle);
      } finally {
        onPlaybackChanged?.call();
      }
    }
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    return _pending = _pending.then((_) async {
      try {
        await _releaseAll();
      } finally {
        _voices.clear();
        _mimeTypes.clear();
        _eventIds.clear();
        _eventOrder.clear();
      }
    });
  }

  static const builtinPaths = <ProjectSoundCue, String>{
    ProjectSoundCue.fieldCut:
        'packages/map_runtime/assets/audio/battle/se/063-swing02.ogg',
    ProjectSoundCue.fieldFly:
        'packages/map_runtime/assets/audio/battle/se/132-wind01.ogg',
    ProjectSoundCue.fieldStrength:
        'packages/map_runtime/assets/audio/battle/se/045-push01.ogg',
    ProjectSoundCue.fieldFlash:
        'packages/map_runtime/assets/audio/battle/se/136-light02.ogg',
    ProjectSoundCue.fieldRockSmash:
        'packages/map_runtime/assets/audio/battle/se/131-earth03.ogg',
    ProjectSoundCue.fieldWaterfall:
        'packages/map_runtime/assets/audio/battle/se/126-water01.ogg',
    ProjectSoundCue.fieldWhirlpool:
        'packages/map_runtime/assets/audio/battle/se/128-water03.ogg',
    ProjectSoundCue.fieldDive:
        'packages/map_runtime/assets/audio/battle/se/021-dive01.ogg',
    ProjectSoundCue.fieldRockClimb:
        'packages/map_runtime/assets/audio/battle/se/045-push03.ogg',
    ProjectSoundCue.fieldDefog:
        'packages/map_runtime/assets/audio/battle/se/132-wind01.ogg',
    ProjectSoundCue.uiSelect:
        'packages/map_runtime/assets/audio/battle/se/001-system01.ogg',
    ProjectSoundCue.uiConfirm:
        'packages/map_runtime/assets/audio/battle/se/002-system02.ogg',
    ProjectSoundCue.uiCancel:
        'packages/map_runtime/assets/audio/battle/se/003-system03.ogg',
    ProjectSoundCue.uiError:
        'packages/map_runtime/assets/audio/battle/se/004-system04.ogg',
    ProjectSoundCue.dialogueAdvance:
        'packages/map_runtime/assets/audio/battle/se/001-system01.ogg',
    ProjectSoundCue.notification:
        'packages/map_runtime/assets/audio/battle/se/007-system07.ogg',
    ProjectSoundCue.overworldStep:
        'packages/map_runtime/assets/audio/battle/se/013-move01.ogg',
    ProjectSoundCue.overworldJump:
        'packages/map_runtime/assets/audio/overworld/jump.wav',
    ProjectSoundCue.doorOpen:
        'packages/map_runtime/assets/audio/battle/se/024-door01.ogg',
    ProjectSoundCue.doorClose:
        'packages/map_runtime/assets/audio/battle/se/025-door02.ogg',
    ProjectSoundCue.surfEnter:
        'packages/map_runtime/assets/audio/battle/se/021-dive01.ogg',
    ProjectSoundCue.surfExit:
        'packages/map_runtime/assets/audio/battle/se/022-dive02.ogg',
    ProjectSoundCue.weatherRain:
        'packages/map_runtime/assets/audio/weather/rain-loop.wav',
    ProjectSoundCue.weatherWind:
        'packages/map_runtime/assets/audio/weather/wind-loop.wav',
    ProjectSoundCue.weatherThunder:
        'packages/map_runtime/assets/audio/weather/thunder-recorded-0.wav',
    ProjectSoundCue.fireCrackle:
        'packages/map_runtime/assets/audio/fire/brazier-loop.wav',
  };
}

final class _ProjectSoundVoice {
  _ProjectSoundVoice(this.handle, this.path, this.loop);
  final Object handle;
  final String path;
  final bool loop;
  bool busy = false;
  StreamSubscription<void>? completion;
}
