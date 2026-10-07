import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter/foundation.dart';

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
  }) : playback = playback ?? ModelPlaybackState();

  final ModelPlaybackState playback;
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
