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
    if (motionType != 1 ||
        motionFramesFx32 < 4096 ||
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
    final squared =
        BigInt.from(delta.x) * BigInt.from(delta.x) +
        BigInt.from(delta.y) * BigInt.from(delta.y) +
        BigInt.from(delta.z) * BigInt.from(delta.z);
    final distance = ((_integerSquareRoot(squared << 2).toInt() + 1) >> 1);
    final division = (((0x8000 * 4096) << 32) ~/ motionFramesFx32);
    final step = math.max(1, (division + 0x80000) >> 20);
    return BattleGen5EmitterMotion._(
      start: start,
      rotation: rotation,
      radius: distance ~/ 2,
      angleStep: step,
      frames: motionFramesFx32 >> 12,
    );
  }

  BattleGen5EmitterMotion._({
    required BattleSplVector start,
    required this._rotation,
    required this._radius,
    required this._angleStep,
    required int frames,
  }) : _start = start,
       _remainingFrames = frames,
       _position = start;

  final BattleSplVector _start;
  final BattleSplVector _rotation;
  final int _radius;
  final int _angleStep;
  int _remainingFrames;
  int _angle = 0;
  BattleSplVector _position;
  bool _cancelled = false;

  BattleSplVector get position => _position;
  bool get isComplete => _cancelled || _remainingFrames == 0;
  bool get isCancelled => _cancelled;

  BattleSplVector advance({bool active = true}) {
    if (isComplete || !active) return _position;
    _remainingFrames--;
    _angle += _angleStep;
    final angleIndex = ((_angle >> 12) + 0xc000) & 0xffff;
    final localX = ((_sinIndex(angleIndex) * _radius + 0x800) >> 12) + _radius;
    _position = (
      x: _start.x + ((localX * _rotation.x) >> 12),
      y: _start.y + ((localX * _rotation.y) >> 12),
      z: _start.z + ((localX * _rotation.z) >> 12),
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
