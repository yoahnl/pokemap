import 'dart:math' as math;

import 'battle_spl_particle_motion.dart';
import 'battle_spl_vector.dart';

final class BattleGen5EmitterMotion {
  factory BattleGen5EmitterMotion({
    required BattleSplVector from,
    required BattleSplVector to,
    required int motionType,
    required int motionFramesFx32,
    required int offsetYFx32,
    required int heightFx32,
    required int turnsFx32,
  }) {
    if (!{1, 2, 5, 6}.contains(motionType) ||
        ((motionType == 5 || motionType == 6) && turnsFx32.abs() > 32768) ||
        (motionFramesFx32 != 0 && motionFramesFx32 < 4096) ||
        motionFramesFx32 > 0x7fffffff ||
        !_isSourceVector(from) ||
        !_isSourceVector(to) ||
        !_isSigned32(offsetYFx32) ||
        !_isSigned32(heightFx32) ||
        !_isSigned32(turnsFx32)) {
      throw const FormatException('Unsupported Gen 5 emitter motion');
    }
    final start = (
      x: _coordinate(from.x),
      y: _coordinate(from.y + offsetYFx32),
      z: _coordinate(from.z + 0x500),
    );
    final end = (
      x: _coordinate(to.x),
      y: _coordinate(to.y + offsetYFx32),
      z: _coordinate(to.z + 0x500),
    );
    final delta = (x: end.x - start.x, y: end.y - start.y, z: end.z - start.z);
    final direction = BattleSplVectorMath.normalize(delta);
    final cross = (x: 0, y: -direction.z, z: direction.y);
    final axis = cross.y == 0 && cross.z == 0
        ? (x: 0, y: 0, z: 0)
        : BattleSplVectorMath.normalize(cross);
    final angle = _acosIndex(direction.x);
    final sine = _sinIndex(angle);
    final rotation = (
      x: _sinIndex(angle + 0x4000),
      y: (sine * axis.z) >> 12,
      z: -((sine * axis.y) >> 12),
    );
    final heightRotation = (
      x: -rotation.y,
      y: rotation.x + ((axis.y * axis.y * (4096 - rotation.x)) >> 24),
      z: (axis.y * axis.z * (4096 - rotation.x)) >> 24,
    );
    final depthRotation = (
      x: -rotation.z,
      y: heightRotation.z,
      z: rotation.x + ((axis.z * axis.z * (4096 - rotation.x)) >> 24),
    );
    final squared =
        BigInt.from(delta.x) * BigInt.from(delta.x) +
        BigInt.from(delta.y) * BigInt.from(delta.y) +
        BigInt.from(delta.z) * BigInt.from(delta.z);
    final distance = ((_integerSquareRoot(squared << 2).toInt() + 1) >> 1);
    final division = motionFramesFx32 == 0
        ? 0
        : (((0x8000 * 4096) << 32) ~/ motionFramesFx32);
    final step = motionFramesFx32 == 0
        ? 0
        : math.max(1, (division + 0x80000) >> 20);
    final secondDivision = motionFramesFx32 == 0
        ? 0
        : (((0x10000 * 4096) << 32) ~/ motionFramesFx32);
    final secondStep = (secondDivision + 0x80000) >> 20;
    final turns = turnsFx32 == 0 ? 1 : turnsFx32;
    return BattleGen5EmitterMotion._(
      start: start,
      rotation: rotation,
      heightRotation: heightRotation,
      depthRotation: depthRotation,
      motionType: motionType,
      height: motionType == 1 ? 0 : heightFx32,
      radius: distance ~/ 2,
      angleStep: step,
      secondAngleStep: ((secondStep * turns + 2048) >> 12).toSigned(32),
      frames: motionFramesFx32 >> 12,
    );
  }

  BattleGen5EmitterMotion._({
    required BattleSplVector start,
    required this._rotation,
    required this._heightRotation,
    required this._depthRotation,
    required this._motionType,
    required this._height,
    required this._radius,
    required this._angleStep,
    required this._secondAngleStep,
    required int frames,
  }) : _start = start,
       _remainingFrames = frames,
       _position = start;

  final BattleSplVector _start;
  final BattleSplVector _rotation;
  final BattleSplVector _heightRotation;
  final BattleSplVector _depthRotation;
  final int _motionType;
  final int _height;
  final int _radius;
  final int _angleStep;
  final int _secondAngleStep;
  int _remainingFrames;
  int _angle = 0;
  int _secondAngle = 0;
  BattleSplVector _position;
  bool _cancelled = false;

  BattleSplVector get position => _position;
  bool get isComplete => _cancelled || _remainingFrames == 0;
  bool get isCancelled => _cancelled;

  BattleSplVector advance({bool active = true}) {
    if (isComplete || !active) return _position;
    _remainingFrames--;
    _angle += _angleStep;
    _secondAngle = (_secondAngle + _secondAngleStep).toSigned(32);
    final angleIndex = ((_angle >> 12) + 0xc000) & 0xffff;
    final waveAngleIndex = ((_secondAngle >> 12) + 0xc000) & 0xffff;
    final localX = ((_sinIndex(angleIndex) * _radius + 0x800) >> 12) + _radius;
    final waveAngle = _motionType == 5 || _motionType == 6
        ? waveAngleIndex : angleIndex;
    final wave = (_sinIndex(waveAngle + 0x4000) * _height + 0x800) >> 12;
    final localY = _motionType == 6 ? 0 : wave;
    final localZ = _motionType == 6 ? wave : 0;
    _position = (
      x: _start.x + ((localX * _rotation.x + localY * _heightRotation.x + localZ * _depthRotation.x) >> 12),
      y: _start.y + ((localX * _rotation.y + localY * _heightRotation.y + localZ * _depthRotation.y) >> 12),
      z: _start.z + ((localX * _rotation.z + localY * _heightRotation.z + localZ * _depthRotation.z) >> 12),
    );
    return _position;
  }

  void cancel() {
    _cancelled = true;
  }
}

bool _isSigned32(int value) => value >= -0x80000000 && value <= 0x7fffffff;

bool _isSourceVector(BattleSplVector value) =>
    _isSigned32(value.x) && _isSigned32(value.y) && _isSigned32(value.z);

int _coordinate(int value) {
  if (value < -0x800000 || value > 0x7fffff) {
    throw const FormatException(
      'Gen 5 emitter coordinate exceeds supported range',
    );
  }
  return value;
}

int _sinIndex(int angle) {
  final index = (angle & 0xffff) >> 4;
  return (math.sin(index * 2 * math.pi / 4096) * 4096).round();
}

int _acosIndex(int value) {
  var low = value >= 0 ? 0 : 1024;
  var high = value >= 0 ? 1024 : 2048;
  var middle = 0;
  while (low <= high) {
    middle = (low + high) ~/ 2;
    final cosine = _sinIndex((middle << 4) + 0x4000);
    if (value == cosine) break;
    if (cosine < value) {
      high = middle - 1;
    } else {
      low = middle + 1;
    }
  }
  return ((middle * 2 + 1) << 16) ~/ 0x2000;
}

BigInt _integerSquareRoot(BigInt value) {
  if (value < BigInt.two) return value;
  var current = BigInt.one << ((value.bitLength + 1) ~/ 2);
  while (true) {
    final next = (current + value ~/ current) >> 1;
    if (next >= current) return current;
    current = next;
  }
}
