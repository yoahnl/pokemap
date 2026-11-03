typedef Gen5CameraVector = ({int x, int y, int z});
typedef Gen5CameraPose = ({Gen5CameraVector position, Gen5CameraVector target});

enum Gen5CameraSlot { player, enemy }

enum Gen5CameraMoveType { immediate, step }

enum Gen5CameraPresetEffect { camera, setFlatActors }

final class Gen5CameraMotion {
  Gen5CameraMotion({Gen5CameraPose? initialPose})
    : _pose = initialPose ?? defaultPose {
    _validatePose(_pose);
  }

  static const Gen5CameraPose defaultPose = (
    position: (x: 27443, y: 27443, z: 70861),
    target: (x: 0, y: 10650, z: 0),
  );
  static const Gen5CameraPose playerPose = (
    position: (x: 0x5ca6, y: 24371, z: 0x13cc3),
    target: (x: -0xe8d, y: 7578, z: 0x27f6),
  );
  static const Gen5CameraPose enemyPose = (
    position: (x: 0x6994, y: 28467, z: 0x6e79),
    target: (x: -0x19f, y: 11674, z: -0xa654),
  );

  static const int _minInt32 = -0x80000000;
  static const int _maxInt32 = 0x7fffffff;
  static const int _maxFrames = 0x7ffff;
  static const Gen5CameraVector _zero = (x: 0, y: 0, z: 0);

  Gen5CameraPose _pose;
  Gen5CameraPose _goal = defaultPose;
  Gen5CameraVector _positionStep = _zero;
  Gen5CameraVector _targetStep = _zero;
  bool _positionMoving = false;
  bool _targetMoving = false;
  int _wait = 0;
  int _waitReset = 0;
  int _brake = 0;
  int _shakeCount = 0;
  int _shakeWait = 0;
  int _shakeWaitReset = 0;
  int _shakeStepY = 0;
  Gen5CameraVector _shakeOffset = _zero;

  Gen5CameraPose get pose => (
    position: (
      x: _pose.position.x + _shakeOffset.x,
      y: _pose.position.y + _shakeOffset.y,
      z: _pose.position.z + _shakeOffset.z,
    ),
    target: (
      x: _pose.target.x + _shakeOffset.x,
      y: _pose.target.y + _shakeOffset.y,
      z: _pose.target.z + _shakeOffset.z,
    ),
  );
  bool get isMoving => _positionMoving || _targetMoving || _shakeCount > 0;

  void shakeVertical({
    required int amplitude,
    required int wait,
    required int count,
  }) {
    _validateRange(amplitude, -28672, 28672, 'amplitude');
    _validateRange(wait, 0, 600, 'wait');
    _validateRange(count, 1, 64, 'count');
    _shakeStepY = amplitude;
    _shakeWait = 0;
    _shakeWaitReset = wait;
    _shakeCount = count * 4;
  }

  Gen5CameraPresetEffect applyPreset({
    required int preset,
    required Gen5CameraSlot attacker,
    required Gen5CameraSlot defender,
    required int frames,
    required int wait,
    required int brake,
    Gen5CameraMoveType moveType = Gen5CameraMoveType.step,
  }) {
    if (preset != 8 && preset != 9 && preset != 11 && preset != 20) {
      throw ArgumentError.value(preset, 'preset');
    }
    _validateRange(frames, 0, _maxFrames, 'frames');
    _validateRange(wait, 0, _maxInt32, 'wait');
    _validateRange(brake, 0, _maxInt32, 'brake');
    if (preset == 20) return Gen5CameraPresetEffect.setFlatActors;

    final goal = switch (preset) {
      8 => defaultPose,
      9 => _slotPose(attacker),
      11 => _slotPose(defender),
      _ => throw StateError('Unsupported camera preset'),
    };
    if (moveType == Gen5CameraMoveType.immediate) {
      _pose = goal;
      return Gen5CameraPresetEffect.camera;
    }

    final divisor = frames == 0 ? 1 : frames;
    final positionStep = _calculateStep(_pose.position, goal.position, divisor);
    final targetStep = _calculateStep(_pose.target, goal.target, divisor);
    _goal = goal;
    _positionStep = positionStep;
    _targetStep = targetStep;
    _wait = wait;
    _waitReset = wait;
    _brake = brake;
    _positionMoving = true;
    _targetMoving = true;
    return Gen5CameraPresetEffect.camera;
  }

  Gen5CameraPose tick() {
    if (!isMoving) return pose;
    if (_wait != 0) {
      _wait -= 1;
      return pose;
    }
    _wait = _waitReset;
    if (_brake != 0 && --_brake == 0) {
      _positionStep = _halveStep(_positionStep);
      _targetStep = _halveStep(_targetStep);
    }

    var position = _pose.position;
    var target = _pose.target;
    var done = true;
    if (_positionMoving) {
      final result = _advance(position, _positionStep, _goal.position);
      position = result.value;
      done = result.done;
      if (done) _positionMoving = false;
    }
    if (_targetMoving) {
      final result = _advance(target, _targetStep, _goal.target);
      target = result.value;
      done = done && result.done;
      if (done) _targetMoving = false;
    }
    _pose = (position: position, target: target);
    if (_shakeCount > 0) {
      if (_shakeWait == 0) {
        _shakeWait = _shakeWaitReset;
        _shakeOffset = (
          x: _shakeOffset.x,
          y: _shakeOffset.y + _shakeStepY,
          z: _shakeOffset.z,
        );
        _shakeCount--;
        if (_shakeCount.isOdd) _shakeStepY = -_shakeStepY;
        if (_shakeCount == 0) _shakeOffset = _zero;
      } else {
        _shakeWait--;
      }
    }
    return pose;
  }

  static Gen5CameraPose _slotPose(Gen5CameraSlot slot) => switch (slot) {
    Gen5CameraSlot.player => playerPose,
    Gen5CameraSlot.enemy => enemyPose,
  };

  static Gen5CameraVector _calculateStep(
    Gen5CameraVector start,
    Gen5CameraVector end,
    int frames,
  ) => (
    x: _calculateAxisStep(start.x, end.x, frames),
    y: _calculateAxisStep(start.y, end.y, frames),
    z: _calculateAxisStep(start.z, end.z, frames),
  );

  static int _calculateAxisStep(int start, int end, int frames) {
    final delta = end - start;
    _validateRange(delta, _minInt32, _maxInt32, 'delta');
    if (delta == 0) return 0;
    final quotient = (delta << 20) ~/ frames;
    final step = (quotient + 0x80000) >> 20;
    return step == 0 ? (delta > 0 ? 1 : -1) : step;
  }

  static Gen5CameraVector _halveStep(Gen5CameraVector step) {
    int halve(int value) => value >> 1 == 0 ? value : value >> 1;
    return (x: halve(step.x), y: halve(step.y), z: halve(step.z));
  }

  static ({Gen5CameraVector value, bool done}) _advance(
    Gen5CameraVector value,
    Gen5CameraVector step,
    Gen5CameraVector goal,
  ) {
    final x = _advanceAxis(value.x, step.x, goal.x);
    final y = _advanceAxis(value.y, step.y, goal.y);
    final z = _advanceAxis(value.z, step.z, goal.z);
    return (
      value: (x: x.value, y: y.value, z: z.value),
      done: x.done && y.done && z.done,
    );
  }

  static ({int value, bool done}) _advanceAxis(int value, int step, int goal) {
    final next = (value + step).toSigned(32);
    final done = step < 0 ? next <= goal : next >= goal;
    return (value: done ? goal : next, done: done);
  }

  static void _validatePose(Gen5CameraPose pose) {
    for (final point in [pose.position, pose.target]) {
      _validateRange(point.x, _minInt32, _maxInt32, 'x');
      _validateRange(point.y, _minInt32, _maxInt32, 'y');
      _validateRange(point.z, _minInt32, _maxInt32, 'z');
    }
  }

  static void _validateRange(int value, int min, int max, String name) {
    if (value < min || value > max) throw ArgumentError.value(value, name);
  }
}
