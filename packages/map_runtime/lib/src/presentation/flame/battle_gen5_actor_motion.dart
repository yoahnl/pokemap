import 'dart:math' as math;

import 'battle_gen5_swing.dart';

typedef BattleGen5ActorPose = ({
  int offsetXFx32,
  int offsetYFx32,
  int offsetZFx32,
  bool spatialOffset,
  int scaleXFx32,
  int scaleYFx32,
  int rotationFx32,
});

enum BattleGen5ActorMotionChannel { position, scale, rotation }

final class BattleGen5ActorMotionController {
  BattleGen5ActorMotionController({
    required this.claim,
    required this.apply,
    required this.release,
  });

  static const int maxActors = 16;

  final bool Function(Object actor, Object owner) claim;
  final bool Function(Object actor, Object owner, BattleGen5ActorPose pose)
  apply;
  final void Function(Object actor, Object owner) release;
  final Object _owner = Object();
  final Map<Object, _ActorMotion> _actors = {};
  bool _ticking = false;

  bool get isBusy => _actors.values.any((state) => state.isBusy);

  bool isActorBusy(Object actor) => _actors[actor]?.isBusy ?? false;

  bool isChannelBusy(Object actor, BattleGen5ActorMotionChannel channel) =>
      (_actors[actor]?.jobs.containsKey(channel) ?? false) ||
      (channel == BattleGen5ActorMotionChannel.scale &&
          _actors[actor]?.scaleStep != null) ||
      (channel == BattleGen5ActorMotionChannel.position &&
          (_actors[actor]?.circle != null ||
              _actors[actor]?.positionStep != null));

  void start({
    required Object actor,
    required BattleGen5ActorMotionChannel channel,
    required int type,
    required int xFx32,
    required int yFx32,
    required int frames,
    required int wait,
    required int times,
    bool mirrorX = false,
  }) {
    _checkNotTicking();
    final validType = switch (channel) {
      BattleGen5ActorMotionChannel.position =>
        type == 1 || type == 2 || type == 3 || type == 5,
      BattleGen5ActorMotionChannel.scale => type == 1 || type == 2 || type == 3,
      BattleGen5ActorMotionChannel.rotation => type == 2 || type == 3,
    };
    if (!validType ||
        (channel == BattleGen5ActorMotionChannel.rotation && yFx32 != 0) ||
        (channel == BattleGen5ActorMotionChannel.scale && mirrorX)) {
      throw const FormatException('Unsupported Gen 5 actor motion mode');
    }
    var state = _actors[actor];
    if ((channel != BattleGen5ActorMotionChannel.position &&
            (state?.jobs.containsKey(channel) ?? false)) ||
        (channel == BattleGen5ActorMotionChannel.scale && state?.scaleStep != null) ||
        (channel == BattleGen5ActorMotionChannel.position &&
            state?.circle != null)) {
      throw StateError('Gen 5 actor motion channel is already active');
    }
    if (state == null && _actors.length >= maxActors) {
      throw StateError('Gen 5 actor motion limit exceeded');
    }
    final scaleStepMode = channel == BattleGen5ActorMotionChannel.scale && type == 1;
    final positionStepMode = channel == BattleGen5ActorMotionChannel.position &&
        (type == 1 || type == 5);
    final stepMode = scaleStepMode || positionStepMode;
    final startX = channel == BattleGen5ActorMotionChannel.scale
        ? (state?.scaleX ?? 4096)
        : channel == BattleGen5ActorMotionChannel.position
            ? (state?.offsetX ?? 0) : 0;
    final startY = channel == BattleGen5ActorMotionChannel.scale
        ? (state?.scaleY ?? 4096)
        : channel == BattleGen5ActorMotionChannel.position
            ? (state?.offsetY ?? 0) : 0;
    final step = stepMode ? _ActorStep(
      startX: startX, startY: startY,
      targetX: scaleStepMode ? xFx32 : type == 5 ? 0 :
          startX + (mirrorX ? -xFx32 : xFx32),
      targetY: scaleStepMode ? yFx32 : type == 5 ? 0 : startY + yFx32,
      frames: frames, wait: wait, times: times,
      minTarget: scaleStepMode ? 1 : -131072,
      maxTarget: scaleStepMode ? 32768 : 131072,
      maxDelta: scaleStepMode ? 65536 : 262144,
    ) : null;
    final swing = stepMode ? null : BattleGen5Swing(
      startX: channel == BattleGen5ActorMotionChannel.scale ? startX - 4096 : startX,
      startY: channel == BattleGen5ActorMotionChannel.scale ? startY - 4096 : startY,
      deltaX: xFx32,
      deltaY: yFx32,
      frames: frames,
      wait: wait,
      count: times,
      mirrorX: mirrorX,
      shake: type == 3,
      maxDelta: channel == BattleGen5ActorMotionChannel.rotation
          ? 268435456
          : 65536,
    );
    if (channel == BattleGen5ActorMotionChannel.scale && !scaleStepMode &&
        (!_validScale(xFx32, frames, start: startX, shake: type == 3) ||
            !_validScale(yFx32, frames, start: startY, shake: type == 3))) {
      throw const FormatException('Unsupported Gen 5 actor scale');
    }
    if (!claim(actor, _owner)) {
      if (state != null) {
        _actors.remove(actor);
        release(actor, _owner);
      }
      throw StateError('Gen 5 actor motion ownership conflict');
    }
    if (state == null) {
      state = _ActorMotion();
      _actors[actor] = state;
    }
    if (channel == BattleGen5ActorMotionChannel.position) {
      state.jobs.remove(channel);
      state.positionStep = null;
    }
    if (step != null) {
      if (positionStepMode) {
        state.positionStep = step;
      } else {
        state.scaleStep = step;
      }
    } else {
      state.jobs[channel] = swing!;
    }
  }

  void startCircle({
    required Object actor,
    required int mode,
    required int start,
    required int radius1Fx32,
    required int radius2Fx32,
    required int frames,
    required int wait,
    required int count,
    required int turnWait,
    bool mirror = false,
  }) {
    _checkNotTicking();
    var state = _actors[actor];
    if (state?.circle != null || state?.positionStep != null ||
        (state?.jobs.containsKey(BattleGen5ActorMotionChannel.position) ?? false)) {
      throw StateError('Gen 5 actor motion channel is already active');
    }
    if (state == null && _actors.length >= maxActors) {
      throw StateError('Gen 5 actor motion limit exceeded');
    }
    final circle = _ActorCircle(
      mode: mode,
      start: start,
      radius1: radius1Fx32,
      radius2: radius2Fx32,
      frames: frames,
      wait: wait,
      count: count,
      turnWait: turnWait,
      mirror: mirror,
    );
    if (!claim(actor, _owner)) {
      if (state != null) {
        _actors.remove(actor);
        release(actor, _owner);
      }
      throw StateError('Gen 5 actor motion ownership conflict');
    }
    if (state == null) {
      state = _ActorMotion();
      _actors[actor] = state;
    }
    state.circleOriginX = state.offsetX;
    state.circleOriginY = state.offsetY;
    state.circleOriginZ = state.offsetZ;
    state.circle = circle;
  }

  void tick() {
    _checkNotTicking();
    _ticking = true;
    try {
      for (final entry in _actors.entries.toList()) {
        final actor = entry.key;
        final state = entry.value;
        for (final job in state.jobs.entries.toList()) {
          final value = job.value.advance();
          switch (job.key) {
            case BattleGen5ActorMotionChannel.position:
              state.offsetX = value.x;
              state.offsetY = value.y;
            case BattleGen5ActorMotionChannel.scale:
              state.scaleX = 4096 + value.x;
              state.scaleY = 4096 + value.y;
            case BattleGen5ActorMotionChannel.rotation:
              state.rotation = value.x;
          }
          if (value.done) state.jobs.remove(job.key);
        }
        final scaleStep = state.scaleStep;
        if (scaleStep != null) {
          final value = scaleStep.advance();
          state.scaleX = value.x;
          state.scaleY = value.y;
          if (value.done) state.scaleStep = null;
        }
        final positionStep = state.positionStep;
        if (positionStep != null) {
          final value = positionStep.advance();
          state.offsetX = value.x;
          state.offsetY = value.y;
          if (value.done) state.positionStep = null;
        }
        final circle = state.circle;
        if (circle != null) {
          final value = circle.advance();
          state.offsetX = state.circleOriginX + value.x;
          state.offsetY = state.circleOriginY + value.y;
          state.offsetZ = state.circleOriginZ + value.z;
          state.spatialOffset = !value.done;
          if (value.done) state.circle = null;
        }
        if (!apply(actor, _owner, state.pose)) {
          throw StateError('Gen 5 actor motion target is no longer owned');
        }
        if (!state.isBusy && state.scaleX == 4096 && state.scaleY == 4096 &&
            state.offsetX == 0 && state.offsetY == 0 && state.offsetZ == 0 &&
            state.rotation == 0) {
          _actors.remove(actor);
          release(actor, _owner);
        }
      }
    } on Object catch (error, stack) {
      try {
        _releaseAll();
      } on Object catch (_) {}
      Error.throwWithStackTrace(error, stack);
    } finally {
      _ticking = false;
    }
  }

  void cancelActor(Object actor) {
    _checkNotTicking();
    final state = _actors.remove(actor);
    if (state != null) release(actor, _owner);
  }

  void cancel() {
    _checkNotTicking();
    _releaseAll();
  }

  void _checkNotTicking() {
    if (_ticking) throw StateError('Gen 5 actor motion tick is not reentrant');
  }

  void _releaseAll() {
    final actors = _actors.keys.toList();
    _actors.clear();
    Object? firstError;
    StackTrace? firstStack;
    for (final actor in actors) {
      try {
        release(actor, _owner);
      } on Object catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
  }
}

bool _validScale(int delta, int frames, {required int start, required bool shake}) {
  final peak = battleGen5SwingStep(delta, frames) * frames;
  final low = shake ? -peak.abs() : math.min(0, peak);
  final high = shake ? peak.abs() : math.max(0, peak);
  return start + low >= 1 && start + high <= 32768;
}

final class _ActorMotion {
  final Map<BattleGen5ActorMotionChannel, BattleGen5Swing> jobs = {};
  _ActorCircle? circle;
  _ActorStep? scaleStep;
  _ActorStep? positionStep;
  bool get isBusy => jobs.isNotEmpty || circle != null ||
      scaleStep != null || positionStep != null;
  int circleOriginX = 0;
  int circleOriginY = 0;
  int circleOriginZ = 0;
  int offsetX = 0;
  int offsetY = 0;
  int offsetZ = 0;
  bool spatialOffset = false;
  int scaleX = 4096;
  int scaleY = 4096;
  int rotation = 0;

  BattleGen5ActorPose get pose => (
    offsetXFx32: offsetX,
    offsetYFx32: offsetY,
    offsetZFx32: offsetZ,
    spatialOffset: spatialOffset,
    scaleXFx32: scaleX,
    scaleYFx32: scaleY,
    rotationFx32: rotation,
  );
}

final class _ActorStep {
  _ActorStep({required int startX, required int startY,
    required this.targetX, required this.targetY, required this.frames,
    required this.wait, required int times, required int minTarget,
    required int maxTarget, required int maxDelta}) : _x = startX, _y = startY {
    if (startX < minTarget || startX > maxTarget ||
        startY < minTarget || startY > maxTarget ||
        targetX < minTarget || targetX > maxTarget ||
        targetY < minTarget || targetY > maxTarget ||
        (targetX - startX).abs() > maxDelta ||
        (targetY - startY).abs() > maxDelta ||
        frames < 1 || frames > 600 || wait < 0 || wait > 600 ||
        times < 0 || times > 32) {
      throw const FormatException('Invalid Gen 5 actor step');
    }
    _stepX = _step(targetX - startX, frames, maxDelta);
    _stepY = _step(targetY - startY, frames, maxDelta);
    int axisTicks(int delta, int step) => delta == 0 ? 1 :
        (delta.abs() + step.abs() - 1) ~/ step.abs();
    final ticks = math.max(axisTicks(targetX - startX, _stepX),
        axisTicks(targetY - startY, _stepY));
    if (ticks * (wait + 1) - wait > 1800) {
      throw const FormatException('Gen 5 actor step is too long');
    }
  }

  final int targetX;
  final int targetY;
  final int frames;
  final int wait;
  int _x;
  int _y;
  late final int _stepX;
  late final int _stepY;
  int _remainingWait = 0;

  static int _step(int delta, int frames, int maxDelta) {
    final step = battleGen5SwingStep(delta, frames, maxDelta: maxDelta);
    return step == 0 && delta != 0 ? delta.sign : step;
  }

  BattleGen5SwingValue advance() {
    if (_remainingWait > 0) {
      _remainingWait--;
      return (x: _x, y: _y, done: false);
    }
    int next(int value, int step, int target) => step < 0
        ? math.max(target, value + step) : math.min(target, value + step);
    _x = next(_x, _stepX, targetX);
    _y = next(_y, _stepY, targetY);
    final done = _x == targetX && _y == targetY;
    _remainingWait = wait;
    return (x: _x, y: _y, done: done);
  }
}

final class _ActorCircle {
  _ActorCircle({
    required this.mode,
    required int start,
    required this.radius1,
    required this.radius2,
    required this.frames,
    required this.wait,
    required int count,
    required this.turnWait,
    required bool mirror,
  }) : start = mirror &&
               !({0, 1, 4, 5}.contains(mode) && (start == 2 || start == 3))
           ? start ^ 1
           : start,
       _remaining = count,
       _angle = mode.isOdd ? 65536 : 0 {
    if (mode < 0 || mode > 5 || start < 0 || start > 3 ||
        radius1.abs() > 32768 || radius2.abs() > 32768 ||
        frames < 1 || frames > 600 || wait < 0 || wait > 600 ||
        count < 1 || count > 32 || turnWait < 0 || turnWait > 600) {
      throw const FormatException('Invalid Gen 5 circular motion');
    }
    _speed = 65536 ~/ frames;
    if ((65536 ~/ _speed + 1) * count * (wait + 1) +
            (count - 1) * turnWait >
        1800) {
      throw const FormatException('Gen 5 circular motion is too long');
    }
  }

  final int mode;
  final int start;
  final int radius1;
  final int radius2;
  final int frames;
  final int wait;
  final int turnWait;
  late final int _speed;
  int _remaining;
  int _angle;
  int _waitCount = 0;
  int _turnWaitLeft = 0;
  int _x = 0;
  int _y = 0;
  int _z = 0;

  ({int x, int y, int z, bool done}) advance() {
    if (_remaining == 0) return (x: 0, y: 0, z: 0, done: true);
    if (_turnWaitLeft > 0) {
      _turnWaitLeft--;
      return (x: _x, y: _y, z: _z, done: false);
    }
    if (_waitCount != wait) {
      _waitCount++;
      return (x: _x, y: _y, z: _z, done: false);
    }
    _waitCount = 0;
    _angle += mode.isOdd ? -_speed : _speed;
    if (_angle < 0 || _angle >= 65536) {
      _angle &= 0xffff;
      _remaining--;
      _turnWaitLeft = turnWait;
    }
    if (_remaining == 0) return (x: 0, y: 0, z: 0, done: true);
    final index = (_angle + (start < 2 ? 0x4000 : 0)) & 0xffff;
    final radians = (index >> 4) * (2 * math.pi / 4096);
    final sine = (math.sin(radians) * 4096).round();
    final cosine = (math.cos(radians) * 4096).round();
    int mul(int a, int b) => (a * b + 2048) >> 12;
    final a = switch (start) {
      0 => -mul(sine, radius1) + radius1,
      1 => mul(sine, radius1) - radius1,
      2 => -mul(sine, radius1),
      _ => mul(sine, radius1),
    };
    final b = switch (start) {
      0 => -mul(cosine, radius2),
      1 => mul(cosine, radius2),
      2 => -mul(cosine, radius2) + radius2,
      _ => mul(cosine, radius2) - radius2,
    };
    switch ((mode & 7) >> 1) {
      case 1:
        _x = a;
        _y = 0;
        _z = b;
      case 2:
        _x = a;
        _y = b;
        _z = 0;
      default:
        _x = 0;
        _y = b;
        _z = a;
    }
    return (x: _x, y: _y, z: _z, done: false);
  }
}
