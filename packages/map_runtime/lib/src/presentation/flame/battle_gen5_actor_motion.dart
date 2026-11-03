import 'battle_gen5_swing.dart';

typedef BattleGen5ActorPose = ({
  int offsetXFx32,
  int offsetYFx32,
  int scaleXFx32,
  int scaleYFx32,
});

enum BattleGen5ActorMotionChannel { position, scale }

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

  bool get isBusy => _actors.isNotEmpty;

  bool isActorBusy(Object actor) => _actors.containsKey(actor);

  bool isChannelBusy(Object actor, BattleGen5ActorMotionChannel channel) =>
      _actors[actor]?.jobs.containsKey(channel) ?? false;

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
    if (type != 2 ||
        (channel == BattleGen5ActorMotionChannel.scale && mirrorX)) {
      throw const FormatException('Unsupported Gen 5 actor motion mode');
    }
    var state = _actors[actor];
    if (state?.jobs.containsKey(channel) ?? false) {
      throw StateError('Gen 5 actor motion channel is already active');
    }
    if (state == null && _actors.length >= maxActors) {
      throw StateError('Gen 5 actor motion limit exceeded');
    }
    final swing = BattleGen5Swing(
      startX: 0,
      startY: 0,
      deltaX: xFx32,
      deltaY: yFx32,
      frames: frames,
      wait: wait,
      count: times,
      mirrorX: mirrorX,
    );
    if (channel == BattleGen5ActorMotionChannel.scale &&
        (!_validScale(xFx32, frames) || !_validScale(yFx32, frames))) {
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
    state.jobs[channel] = swing;
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
          }
          if (value.done) state.jobs.remove(job.key);
        }
        if (!apply(actor, _owner, state.pose)) {
          throw StateError('Gen 5 actor motion target is no longer owned');
        }
        if (state.jobs.isEmpty) {
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

bool _validScale(int delta, int frames) {
  final peak = battleGen5SwingStep(delta, frames) * frames;
  return delta >= -4095 && delta <= 28672 && peak >= -4095 && peak <= 28672;
}

final class _ActorMotion {
  final Map<BattleGen5ActorMotionChannel, BattleGen5Swing> jobs = {};
  int offsetX = 0;
  int offsetY = 0;
  int scaleX = 4096;
  int scaleY = 4096;

  BattleGen5ActorPose get pose => (
    offsetXFx32: offsetX,
    offsetYFx32: offsetY,
    scaleXFx32: scaleX,
    scaleYFx32: scaleY,
  );
}
