import 'package:map_core/map_core.dart';

final class WorldEnvironmentClock {
  WorldEnvironmentClock(
      {required DateTime Function() now, WorldEnvironmentState? initialState})
      : _now = now,
        _elapsedSeconds = initialState?.elapsedSeconds ?? 0,
        _used = initialState != null;

  final DateTime Function() _now;
  double _elapsedSeconds;
  bool _used;
  double get elapsedSeconds => _elapsedSeconds;
  WorldEnvironmentState? get checkpoint =>
      _used ? WorldEnvironmentState(elapsedSeconds: _elapsedSeconds) : null;

  void advance(double seconds, {bool paused = false}) {
    if (!seconds.isFinite || seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds');
    }
    if (!paused) _elapsedSeconds += seconds;
  }

  WorldEnvironmentFrame resolve(SpatialVisualPatch settings,
      {SpatialVisualPatch? overrides, SpatialWeatherKind? realWeatherKind}) {
    _used |= settings.requiresWorldEnvironment;
    return resolveWorldEnvironment(
      settings: settings,
      elapsedSeconds: _elapsedSeconds,
      overrides: overrides,
      realWeatherKind: realWeatherKind,
      localTime: settings.choice(SpatialVisualParameter.timeMode) ==
              WorldTimeMode.real.name
          ? _now()
          : null,
    );
  }
}
