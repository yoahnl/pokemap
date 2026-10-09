import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'animated_render_model.dart';

class ModelPlaybackState extends AnimationState {
  ModelPlaybackState();

  ModelPlaybackState.from(ModelPlaybackState source) {
    animationRef = source.animationRef;
    materialAnimationRef = source.materialAnimationRef;
    _nodeClock = source._nodeClock;
    _materialElapsed = source._materialElapsed;
    clock = source.clock;
    loop = source.loop;
    paused = source.paused;
    speed = source.speed;
  }
  bool loop = true;
  bool paused = false;
  double speed = 1;
  Model3dMaterialAnimationClip? materialAnimationRef;
  double _nodeClock = 0;
  double _materialElapsed = 0;

  double get materialTimeSeconds => loop ? _materialElapsed : clock;

  double get durationSeconds =>
      materialAnimationRef?.durationSeconds ?? animationRef?.lastTime ?? 0;

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
    materialAnimationRef = null;
    startAnimation(animation);
  }

  void playMaterial(
    Model3dMaterialAnimationClip animation, {
    ModelAnimation? nodeAnimation,
    bool loop = true,
    double speed = 1,
  }) {
    if (!speed.isFinite || speed <= 0 || speed > 16) {
      throw ArgumentError('Invalid model animation playback.');
    }
    this.loop = loop;
    this.speed = speed;
    paused = false;
    startAnimation(nodeAnimation);
    materialAnimationRef = animation;
  }

  @override
  void reset() {
    super.reset();
    _nodeClock = 0;
    _materialElapsed = 0;
  }

  void restart() {
    reset();
    paused = false;
  }

  void synchronizeClock(ModelPlaybackState visible) {
    if (identical(animationRef, visible.animationRef) &&
        identical(materialAnimationRef, visible.materialAnimationRef)) {
      clock = visible.clock;
      _nodeClock = visible._nodeClock;
      _materialElapsed = visible._materialElapsed;
      paused = visible.paused;
    }
  }

  void stop() {
    materialAnimationRef = null;
    startAnimation(null);
    paused = false;
  }

  @override
  void update(double dt) {
    final duration = durationSeconds;
    if (duration <= 0 || paused || !dt.isFinite || dt <= 0) return;
    clock = loop
        ? (clock + (dt % (duration / speed)) * speed) % duration
        : (clock + dt * speed).clamp(0, duration);
    _materialElapsed = loop ? _materialElapsed + dt * speed : clock;
    if (!_materialElapsed.isFinite) _materialElapsed = clock;
    final nodeDuration = animationRef?.lastTime;
    if (materialAnimationRef != null &&
        nodeDuration != null &&
        nodeDuration > 0) {
      _nodeClock = loop
          ? (_nodeClock + (dt % (nodeDuration / speed)) * speed) % nodeDuration
          : (_nodeClock + dt * speed).clamp(0, nodeDuration);
    }
  }

  @override
  Matrix4 maybeTransform(int nodeIndex, Matrix4 transform) {
    if (materialAnimationRef == null) {
      return super.maybeTransform(nodeIndex, transform);
    }
    final animation = animationRef?.nodes[nodeIndex];
    if (animation == null) return transform;
    final result = transform.clone();
    animation.sampleInto(_nodeClock, result);
    return result;
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
  int get animationCount => model is AnimatedRenderModel
      ? (model as AnimatedRenderModel).animationCount
      : model.animations.length;

  Model3dMaterialAnimationClip? _materialClip(int index) =>
      model is AnimatedRenderModel && index >= model.animations.length
      ? (model as AnimatedRenderModel).materialAnimations.clips[index -
            model.animations.length]
      : null;

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

  void play(int index, {bool loop = true, double speed = 1}) {
    _checkAnimationIndex(index);
    final materialClip = _materialClip(index);
    if (materialClip == null) {
      playback.play(model.animations[index], loop: loop, speed: speed);
    } else {
      final nodeIndex = materialClip.nodeAnimationIndex;
      playback.playMaterial(
        materialClip,
        nodeAnimation: nodeIndex == null ? null : model.animations[nodeIndex],
        loop: loop,
        speed: speed,
      );
    }
  }

  void bindAnimation(int? index, {bool loop = true, double speed = 1}) {
    if (index != null) {
      _checkAnimationIndex(index);
    }
    final materialClip = index == null ? null : _materialClip(index);
    final nodeIndex = materialClip == null
        ? index
        : materialClip.nodeAnimationIndex;
    final clip = nodeIndex == null ? null : model.animations[nodeIndex];
    if (!identical(playback.animationRef, clip) ||
        !identical(playback.materialAnimationRef, materialClip)) {
      if (index == null) {
        playback.stop();
      } else {
        play(index, loop: loop, speed: speed);
      }
    }
    playback
      ..loop = loop
      ..speed = speed;
  }

  @override
  void playAnimationByIndex(int index, {bool resetClock = true}) {
    final clock = playback.clock;
    final nodeClock = playback.materialAnimationRef == null
        ? playback.clock
        : playback._nodeClock;
    final materialElapsed = playback.materialTimeSeconds;
    play(index, loop: playback.loop, speed: playback.speed);
    if (!resetClock) {
      playback
        ..clock = clock
        .._nodeClock = nodeClock
        .._materialElapsed = materialElapsed;
    }
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
          ..materialAnimationRef = before.materialAnimationRef
          .._nodeClock = before._nodeClock
          .._materialElapsed = before._materialElapsed
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
      ..clock = state.normalizedTime * playback.durationSeconds
      .._materialElapsed = state.normalizedTime * playback.durationSeconds
      .._nodeClock =
          state.normalizedTime * (playback.animationRef?.lastTime ?? 0);
  }

  @override
  void playAnimationByName(String name, {bool resetClock = true}) {
    for (var index = 0; index < animationCount; index++) {
      final clipName = model is AnimatedRenderModel
          ? (model as AnimatedRenderModel).animationName(index)
          : model.animations[index].name;
      if (clipName == name) {
        playAnimationByIndex(index, resetClock: resetClock);
        return;
      }
    }
    throw ArgumentError('No animation with name $name');
  }

  void _checkAnimationIndex(int index) {
    if (index < 0 || index >= animationCount) {
      throw RangeError.range(index, 0, animationCount - 1, 'index');
    }
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
    final animated = model is AnimatedRenderModel
        ? model as AnimatedRenderModel
        : null;
    animated?.applyMaterialPose(
      playback.materialAnimationRef,
      playback.materialTimeSeconds,
      loop: playback.loop,
    );
    try {
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
    } finally {
      animated?.resetMaterialPose();
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
