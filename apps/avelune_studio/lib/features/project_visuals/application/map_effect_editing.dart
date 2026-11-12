import 'package:map_core/map_core_domain.dart';

import 'spatial_visual_editing.dart';

enum MapEffect {
  halos(SpatialVisualParameter.halosEnabled, [
    SpatialVisualParameter.haloStrength,
    SpatialVisualParameter.haloSpread,
  ]),
  fog(SpatialVisualParameter.depthFogEnabled, [
    SpatialVisualParameter.fogOpacity,
  ]),
  fireflies(SpatialVisualParameter.fireflies, [
    SpatialVisualParameter.fireflyDensity,
  ]),
  water(SpatialVisualParameter.waterAnimated, [
    SpatialVisualParameter.waterStrength,
    SpatialVisualParameter.waterSpeed,
  ]),
  windows(SpatialVisualParameter.windowsLit, [
    SpatialVisualParameter.windowStrength,
  ]);

  const MapEffect(this.toggle, this.levels);

  final SpatialVisualParameter toggle;
  final List<SpatialVisualParameter> levels;

  Iterable<SpatialVisualParameter> get parameters => [toggle, ...levels];
}

extension MapEffectEditing on SpatialVisualEditing {
  bool overridesEffect(MapEffect effect) =>
      effect.parameters.any((parameter) => patch.value(parameter) != null);

  void setEffectOverride(MapEffect effect, {required bool override}) {
    var next = patch.set(effect.toggle, override ? flag(effect.toggle) : null);
    for (final level in effect.levels) {
      next = next.set(level, override ? number(level) : null);
    }
    onChanged?.call(next);
  }
}
