import 'package:flame_3d/core.dart';

import 'spatial_point_light.dart';

final class SpatialFireflyLightBudget {
  final _ids = <int?>[null, null];
  final _strengths = [0.0, 0.0];
  double? _elapsed;
  void reset() {
    _ids.fillRange(0, 2, null);
    _strengths.fillRange(0, 2, 0);
    _elapsed = null;
  }

  List<SpatialPointLight> sample(
    List<(int, SpatialPointLight)> candidates,
    Vector3 anchor,
    double elapsedSeconds,
  ) {
    final dt = _elapsed == null
        ? 0.0
        : (elapsedSeconds - _elapsed!).clamp(0.0, .3);
    _elapsed = elapsedSeconds;
    if (candidates.isEmpty) {
      _ids.fillRange(0, 2, null);
      _strengths.fillRange(0, 2, 0);
      return const [];
    }
    double distance(SpatialPointLight light) =>
        (light.position.x - anchor.x) * (light.position.x - anchor.x) +
        (light.position.z - anchor.z) * (light.position.z - anchor.z);
    final ranked = candidates.toList()
      ..sort((a, b) {
        final order = distance(a.$2).compareTo(distance(b.$2));
        return order == 0 ? a.$1.compareTo(b.$1) : order;
      });
    final desired = ranked.take(2).map((v) => v.$1).toSet();
    final byId = {for (final c in candidates) c.$1: c.$2};
    for (var i = 0; i < 2; i++) {
      if (_ids[i] != null && !desired.contains(_ids[i])) {
        _strengths[i] = (_strengths[i] - dt / .3).clamp(0.0, 1.0);
        if (_strengths[i] == 0 || !byId.containsKey(_ids[i])) _ids[i] = null;
      }
      if (_ids[i] == null) {
        _ids[i] = desired.where((id) => !_ids.contains(id)).firstOrNull;
        _strengths[i] = 0;
      }
      if (desired.contains(_ids[i])) {
        _strengths[i] = (_strengths[i] + dt / .3).clamp(0.0, 1.0);
      }
    }
    return [
      for (var i = 0; i < 2; i++)
        if (byId[_ids[i]] case final light?)
          SpatialPointLight(
            position: light.position,
            radius: light.radius,
            color: light.color,
            intensity: light.intensity * _strengths[i],
          ),
    ];
  }
}
