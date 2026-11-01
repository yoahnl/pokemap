import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import '../battle_projection_contract.dart';

final class BattleStageCamera extends CameraComponent3D {
  BattleStageCamera() {
    setFrame(
      eye: Model3dVector3(x: 0, y: 0, z: 0),
      aim: Model3dVector3(x: 0, y: 0, z: -1),
      size: const Size(1, 1),
      focalLength: 1,
    );
  }

  final _projection = Matrix4.zero();
  final _nextProjection = Matrix4.zero();
  final _nextEye = Vector3.zero();
  final _nextAim = Vector3.zero();
  Size _frameSize = const Size(1, 1);
  double _focal = 1;
  Offset? _principalPoint;
  BattleProjectionCoordinates _sourceEye = (x: 0, y: 0, z: 0);
  BattleProjectionCoordinates _sourceAim = (x: 0, y: 0, z: -1);
  Size get frameSize => _frameSize;
  double get focal => _focal;
  double get centerY => .55;
  Offset? get principalPoint => _principalPoint;

  bool setFrame({
    required Model3dVector3 eye,
    required Model3dVector3 aim,
    required Size size,
    required double focalLength,
    Offset? projectionCenter,
  }) {
    final center =
        projectionCenter ?? Offset(size.width / 2, size.height * centerY);
    if (!BattleProjectionContract.isValidFrame(size, focalLength, center) ||
        !eye.x.isFinite ||
        !eye.y.isFinite ||
        !eye.z.isFinite ||
        !aim.x.isFinite ||
        !aim.y.isFinite ||
        !aim.z.isFinite ||
        !BattleProjectionContract.isValidDirection(
          aim.x - eye.x,
          aim.y - eye.y,
          aim.z - eye.z,
        )) {
      return false;
    }
    _nextEye.setValues(eye.x, eye.y, eye.z);
    _nextAim.setValues(aim.x, aim.y, aim.z);
    final direction = _nextAim - _nextEye;
    if (!_nextEye.storage.every((value) => value.isFinite) ||
        !_nextAim.storage.every((value) => value.isFinite) ||
        !BattleProjectionContract.isValidDirection(
          direction.x,
          direction.y,
          direction.z,
        )) {
      return false;
    }
    final fov = 2 * math.atan(size.height / (2 * focalLength)) * 180 / math.pi;
    _nextProjection
      ..setAsPerspective(
        fov,
        size.width / size.height,
        BattleProjectionContract.near,
        BattleProjectionContract.far,
      )
      ..setEntry(0, 2, 1 - center.dx * 2 / size.width)
      ..setEntry(1, 2, center.dy * 2 / size.height - 1);
    if (!_nextProjection.storage.every((value) => value.isFinite) ||
        _nextProjection.entry(0, 0) <= 0 ||
        _nextProjection.entry(1, 1) <= 0) {
      return false;
    }
    position.setFrom(_nextEye);
    target.setFrom(_nextAim);
    _frameSize = size;
    _focal = focalLength;
    _principalPoint = projectionCenter;
    _sourceEye = (x: eye.x, y: eye.y, z: eye.z);
    _sourceAim = (x: aim.x, y: aim.y, z: aim.z);
    _projection.setFrom(_nextProjection);
    return true;
  }

  @override
  Matrix4 get projectionMatrix => _projection;

  Offset? project(Model3dVector3 point) {
    if (!point.x.isFinite || !point.y.isFinite || !point.z.isFinite) {
      return null;
    }
    final depth = BattleProjectionContract.viewDepth(
      point: (x: point.x, y: point.y, z: point.z),
      eye: _sourceEye,
      aim: _sourceAim,
    );
    if (!BattleProjectionContract.containsDepth(depth)) return null;
    final clip = viewProjectionMatrix.transform(
      Vector4(point.x, point.y, point.z, 1),
    );
    if (!clip.storage.every((value) => value.isFinite) || clip.w <= 0) {
      return null;
    }
    final screen = Offset(
      (clip.x / clip.w + 1) * frameSize.width / 2,
      (1 - clip.y / clip.w) * frameSize.height / 2,
    );
    return screen.dx.isFinite && screen.dy.isFinite ? screen : null;
  }
}
