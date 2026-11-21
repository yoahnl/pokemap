import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

final class SpatialRuntimeModelTransform {
  SpatialRuntimeModelTransform({required Vector3 position, required Model3dVector3 anchor})
      : _base = position.clone(), _anchor = anchor;

  final Vector3 _base;
  final _target = Vector3.zero();
  Model3dVector3 _anchor;
  bool _translatedHorizontally = false;

  double get initialPositionY => _base.y;
  set initialPositionY(double value) => _base.y = value;
  double get initialAnchorY => _anchor.y;

  void rebase({required Vector3 position, Model3dVector3? anchor}) {
    _base.setFrom(position);
    if (anchor != null) _anchor = anchor;
    _translatedHorizontally = false;
  }

  bool apply(Vector3 position, SpatialModelInstance instance, SpatialModelRuntimeState? state) {
    final dx = state?.translationX ?? 0;
    final dz = state?.translationZ ?? 0;
    final horizontal = dx != 0 || dz != 0;
    final targetY = _base.y + instance.position.y - _anchor.y + (state?.translationY ?? 0);
    final updateHorizontal = horizontal || _translatedHorizontally;
    _translatedHorizontally = horizontal;
    _target.setValues(
      updateHorizontal
          ? _base.x + instance.position.x - _anchor.x + dx
          : position.x,
      targetY,
      updateHorizontal
          ? _base.z + instance.position.z - _anchor.z + dz
          : position.z,
    );
    if (position == _target) return false;
    position.setFrom(_target);
    return true;
  }
}
