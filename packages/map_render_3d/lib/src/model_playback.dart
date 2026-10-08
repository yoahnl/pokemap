import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

class ModelPlaybackState extends AnimationState {
  ModelPlaybackState();

  ModelPlaybackState.from(ModelPlaybackState source) {
    animationRef = source.animationRef;
    clock = source.clock;
    loop = source.loop;
    paused = source.paused;
    speed = source.speed;
  }
  bool loop = true;
  bool paused = false;
  double speed = 1;

  void play(ModelAnimation animation, {bool loop = true, double speed = 1}) {
    if (!speed.isFinite ||
        speed <= 0 ||
        speed > 16 ||
        !animation.lastTime.isFinite ||
        animation.lastTime <= 0) {
      throw ArgumentError('Invalid model animation playback.');
    }
    this.loop = loop;
    this.speed = speed;
    paused = false;
    startAnimation(animation);
  }

  void restart() {
    reset();
    paused = false;
  }

  void synchronizeClock(ModelPlaybackState visible) {
    if (identical(animationRef, visible.animationRef)) {
      clock = visible.clock;
      paused = visible.paused;
    }
  }

  void stop() {
    startAnimation(null);
    paused = false;
  }

  @override
  void update(double dt) {
    final animation = animationRef;
    if (animation == null || paused || !dt.isFinite || dt <= 0) return;
    final duration = animation.lastTime;
    clock = loop
        ? (clock + (dt % (duration / speed)) * speed) % duration
        : (clock + dt * speed).clamp(0, duration);
  }
}

class AnimatedModelComponent extends ModelComponent {
  AnimatedModelComponent({
    required super.model,
    super.position,
    super.rotation,
    super.scale,
    super.children,
    ModelPlaybackState? playback,
    ModelPlaybackState? runtimePoseBefore,
  }) : playback = playback ?? ModelPlaybackState(),
       _runtimePoseBefore = runtimePoseBefore == null
           ? null
           : ModelPlaybackState.from(runtimePoseBefore);

  final ModelPlaybackState playback;
  ModelPlaybackState? _runtimePoseBefore;
  ModelPlaybackState? get runtimePoseBefore => _runtimePoseBefore == null
      ? null
      : ModelPlaybackState.from(_runtimePoseBefore!);
  final _hiddenNodes = <int>{};

  @override
  void hideNodeByName(String name, {bool hidden = true}) {
    final node = model.nodes.entries.firstWhere(
      (entry) => entry.value.name == name,
    );
    if (hidden) {
      _hiddenNodes.add(node.key);
    } else {
      _hiddenNodes.remove(node.key);
    }
  }

  void play(int index, {bool loop = true, double speed = 1}) =>
      playback.play(model.animations[index], loop: loop, speed: speed);

  void bindAnimation(int? index, {bool loop = true, double speed = 1}) {
    final clip = index == null ? null : model.animations[index];
    if (!identical(playback.animationRef, clip)) {
      if (clip == null) {
        playback.stop();
      } else {
        playback.play(clip, loop: loop, speed: speed);
      }
    }
    playback
      ..loop = loop
      ..speed = speed;
  }

  @override
  void playAnimationByIndex(int index, {bool resetClock = true}) {
    final clock = playback.clock;
    play(index, loop: playback.loop, speed: playback.speed);
    if (!resetClock) playback.clock = clock;
  }

  void bindRuntimeState(
    SpatialModelRuntimeState? state, {
    int? authoredAnimationIndex,
    bool authoredLoop = true,
    double authoredSpeed = 1,
    bool paused = false,
  }) {
    if (state == null) {
      final before = _runtimePoseBefore;
      if (before != null) {
        playback
          ..animationRef = before.animationRef
          ..clock = before.clock
          ..loop = before.loop
          ..speed = before.speed;
        _runtimePoseBefore = null;
      }
      bindAnimation(
        authoredAnimationIndex,
        loop: authoredLoop,
        speed: authoredSpeed,
      );
      playback.paused = paused;
      return;
    }
    _runtimePoseBefore ??= ModelPlaybackState.from(playback);
    bindAnimation(state.animationIndex, loop: false);
    playback
      ..paused = true
      ..clock = state.normalizedTime * (playback.animationRef?.lastTime ?? 0);
  }

  @override
  void playAnimationByName(String name, {bool resetClock = true}) {
    final index = model.animations.indexWhere((clip) => clip.name == name);
    if (index < 0) throw ArgumentError('No animation with name $name');
    playAnimationByIndex(index, resetClock: resetClock);
  }

  @override
  void stopAnimation() => playback.stop();

  @override
  void update(double dt) {
    super.update(dt);
    playback.update(dt);
  }

  @override
  void draw(RenderContext3D context) {
    for (final entry in model.processNodes(playback).entries) {
      if (_hiddenNodes.contains(entry.key)) continue;
      final node = entry.value;
      final mesh = node.node.mesh;
      if (mesh != null) {
        context
          ..jointsInfo.jointTransformsPerSurface = node.jointTransforms
          ..model.setFrom(
            worldTransformMatrix.multiplied(node.combinedTransform),
          )
          ..drawMesh(mesh);
      }
    }
  }
}

class SpatialAnimationPreviewController extends ChangeNotifier {
  final _paused = <String, bool>{};
  final _restarts = <String, int>{};

  bool isPaused(String id) => _paused[id] ?? false;
  int restartVersion(String id) => _restarts[id] ?? 0;

  void togglePause(String id) {
    _paused[id] = !isPaused(id);
    notifyListeners();
  }

  void restart(String id) {
    _paused[id] = false;
    _restarts[id] = restartVersion(id) + 1;
    notifyListeners();
  }

  void clear() {
    _paused.clear();
    _restarts.clear();
    notifyListeners();
  }
}
