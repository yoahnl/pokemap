import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';
import 'runtime_project_audio_controller.dart';
import 'runtime_music_service.dart';
import 'runtime_weather_loop_driver.dart';

final class RuntimeBrazierAudioController {
  RuntimeBrazierAudioController({
    required RuntimeAudioMixer mixer,
    FlameCinematicAudioDriver? driver,
    this.projectAudio,
  }) : _audio = RuntimeMusicService(
         mixer: mixer,
         driver:
             driver ??
             RuntimeWeatherLoopDriver(
               projectAudio?.createDriver() ??
                   FlameAudioCinematicRuntimeDriver(
                     playerFactory: () =>
                         AudioPlayer()..audioCache = AudioCache(prefix: ''),
                     sourceFactory: AssetSource.new,
                   ),
               crossfadePath: (path) =>
                   path.startsWith('packages/map_runtime/'),
               duration: const Duration(seconds: 30),
               overlap: const Duration(milliseconds: 1500),
             ),
       );

  final RuntimeProjectAudioController? projectAudio;
  final RuntimeMusicService _audio;
  String? _path;
  double _gain = 0;
  bool _disposed = false;
  Future<void> _pending = Future.value();
  Object? get lastFailure => _audio.lastFailure;
  Map<String, Object?> get diagnostics => {
    'playing': _audio.isPlaying,
    'gain': _gain,
    'failure': lastFailure?.toString(),
  };

  Future<void> update(double gain) {
    if (_disposed) return _pending;
    final selected = projectAudio?.resolve(ProjectSoundCue.fireCrackle);
    final path = projectAudio == null
        ? 'packages/map_runtime/assets/audio/fire/brazier-loop.wav'
        : selected?.path;
    final next = gain.isFinite
        ? (gain.clamp(0.0, 1.0) * 50).round() /
              50 *
              (projectAudio == null ? 1 : selected?.gain ?? 0)
        : 0.0;
    if (_gain == next && _path == path) return _pending;
    _gain = next;
    _path = path;
    return _pending = _audio.update(
      route: RuntimeAudioRoute.ambience,
      path: next > 0 ? path : null,
      volume: next,
    );
  }

  Future<void> setSuspended(bool suspended) => _audio.setSuspended(suspended);
  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    return _pending = _audio.dispose();
  }
}
