import 'package:flame/components.dart';

import 'battle_gen5_swing.dart';

final class BattleGen5MotionPose {
  const BattleGen5MotionPose({
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
  });

  static const neutral = BattleGen5MotionPose(
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 1,
  );
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;

  @override
  bool operator ==(Object other) =>
      other is BattleGen5MotionPose &&
      other.offsetX == offsetX &&
      other.offsetY == offsetY &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY;

  @override
  int get hashCode => Object.hash(offsetX, offsetY, scaleX, scaleY);
}

final class BattleGen5MotionBinding {
  const BattleGen5MotionBinding({
    required this.apply,
    required this.clear,
    required this.pause,
    required this.resume,
  });
  final bool Function(BattleGen5MotionPose) apply;
  final void Function() clear;
  final void Function() pause;
  final void Function() resume;
}

final class BattleGen5MotionSpec {
  const BattleGen5MotionSpec({
    required this.target,
    required this.channel,
    required this.x,
    required this.y,
    required this.frames,
    required this.wait,
    required this.count,
    this.mirrorX = false,
  });
  final String target;
  final String channel;
  final int x;
  final int y;
  final int frames;
  final int wait;
  final int count;
  final bool mirrorX;
}

final class _Job {
  _Job(this.binding, this.channel, this.swing);
  final BattleGen5MotionBinding binding;
  final String channel;
  final BattleGen5Swing swing;
  bool done = false;
}

final class _Pose {
  double offsetX = 0;
  double offsetY = 0;
  double scaleX = 1;
  double scaleY = 1;
  BattleGen5MotionPose get value => BattleGen5MotionPose(
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
  );
}

final class BattleGen5MotionPlayback {
  BattleGen5MotionPlayback({
    required Map<String, BattleGen5MotionBinding> bindings,
    required List<BattleGen5MotionSpec> swings,
    required Set<String> pausedTargets,
    required this.pixelsPerUnit,
    required this.onComplete,
    required this.onFailure,
  }) {
    if (swings.isEmpty ||
        swings.length > 4 ||
        !pixelsPerUnit.isFinite ||
        pixelsPerUnit <= 0 ||
        pixelsPerUnit > 200 ||
        pausedTargets.any((target) => !bindings.containsKey(target))) {
      throw const FormatException('Invalid Gen 5 motion playback');
    }
    final channels = <BattleGen5MotionBinding, Set<String>>{};
    for (final spec in swings) {
      final binding = bindings[spec.target];
      if (binding == null ||
          !{'position', 'scale'}.contains(spec.channel) ||
          !channels.putIfAbsent(binding, () => {}).add(spec.channel) ||
          (spec.channel == 'scale' &&
              ([spec.x, spec.y].any(
                (value) =>
                    value < -4095 ||
                    value > 28672 ||
                    (spec.frames > 0 &&
                        (battleGen5SwingStep(value, spec.frames) * spec.frames <
                                -4095 ||
                            battleGen5SwingStep(value, spec.frames) *
                                    spec.frames >
                                28672)),
              )))) {
        throw const FormatException('Invalid Gen 5 motion binding');
      }
      _jobs.add(
        _Job(
          binding,
          spec.channel,
          BattleGen5Swing(
            startX: 0,
            startY: 0,
            deltaX: spec.x,
            deltaY: spec.y,
            frames: spec.frames,
            wait: spec.wait,
            count: spec.count,
            mirrorX: spec.channel == 'position' && spec.mirrorX,
          ),
        ),
      );
      _poses.putIfAbsent(binding, _Pose.new);
    }
    _paused.addAll(pausedTargets.map((target) => bindings[target]!));
  }

  final double pixelsPerUnit;
  final void Function() onComplete;
  final void Function() onFailure;
  final List<_Job> _jobs = [];
  final Map<BattleGen5MotionBinding, _Pose> _poses = {};
  final Set<BattleGen5MotionBinding> _paused = {};
  final Set<BattleGen5MotionBinding> _claimed = {};
  bool _started = false;
  bool _disposed = false;
  bool _completed = false;
  double _accumulatedTicks = 0;
  double _completionWaitSeconds = 0;

  void start() {
    if (_started || _disposed) {
      throw StateError('Gen 5 motion already started or disposed');
    }
    _started = true;
    try {
      for (final binding in _paused) {
        binding.pause();
      }
    } on Object {
      _fail();
    }
  }

  void advance(double seconds) {
    if (!_started || _disposed || !seconds.isFinite || seconds <= 0) return;
    if (_completed) {
      _completionWaitSeconds += seconds;
      if (_completionWaitSeconds >= 30) _fail();
      return;
    }
    _accumulatedTicks += seconds * 60;
    if (!_accumulatedTicks.isFinite) {
      _fail();
      return;
    }
    while (_accumulatedTicks + 1e-9 >= 1 && !_disposed && !_completed) {
      _accumulatedTicks -= 1;
      for (final job in _jobs) {
        if (job.done) continue;
        final value = job.swing.advance();
        final pose = _poses[job.binding]!;
        if (job.channel == 'position') {
          pose.offsetX = value.x / 4096 * pixelsPerUnit;
          pose.offsetY = -value.y / 4096 * pixelsPerUnit;
        } else {
          pose.scaleX = 1 + value.x / 4096;
          pose.scaleY = 1 + value.y / 4096;
        }
        job.done = value.done;
      }
      try {
        for (final entry in _poses.entries) {
          _claimed.add(entry.key);
          if (!entry.key.apply(entry.value.value)) {
            _fail();
            return;
          }
        }
      } on Object {
        _fail();
        return;
      }
      if (_jobs.every((job) => job.done)) {
        _completed = true;
        _clearClaims();
        onComplete();
      }
    }
  }

  void _clearClaims() {
    for (final binding in _claimed) {
      binding.clear();
    }
    _claimed.clear();
  }

  void _fail() {
    if (_disposed) return;
    dispose();
    onFailure();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clearClaims();
    if (_started) {
      for (final binding in _paused) {
        binding.resume();
      }
    }
  }
}

final class BattleGen5MotionComponent extends Component {
  BattleGen5MotionComponent(this.playback);
  final BattleGen5MotionPlayback playback;
  bool _disposed = false;

  void begin() => playback.start();

  @override
  void update(double dt) {
    super.update(dt);
    if (!_disposed) playback.advance(dt);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    playback.dispose();
    removeFromParent();
  }

  @override
  void onRemove() {
    dispose();
    super.onRemove();
  }
}
