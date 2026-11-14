part of 'studio_map_visual_widgets.dart';

extension _StudioMapVisualAnimationClock on _StudioMapVisualState {
  void _stopTicker() {
    _ticker.stop();
    _lastTick = Duration.zero;
  }

  bool _hasUsedAnimation() {
    final cached = _hasAnimations;
    if (cached != null) return cached;
    for (final layer in widget.map.layers) {
      if (!layer.isVisible ||
          layer.opacity <= 0 ||
          !mapLayerParticipatesInVisualComposition(layer)) {
        continue;
      }
      if (layer is TileLayer) {
        final animatedIndices = <int>{};
        for (var i = 0; i < layer.palette.length; i++) {
          if (_animationFor(layer.palette[i]) != null) {
            animatedIndices.add(i + 1);
          }
        }
        if (animatedIndices.isNotEmpty &&
            layer.cells.any(animatedIndices.contains)) {
          return _hasAnimations = true;
        }
      } else if (layer is ObjectLayer &&
          layer.tileObjects.any(
            (object) =>
                object.isVisible &&
                object.opacity > 0 &&
                _animationFor(object.tile) != null,
          )) {
        return _hasAnimations = true;
      }
    }
    return _hasAnimations = false;
  }

  void _waitForVisibleAnimation() {
    if (_waitingForVisibility || !_hasUsedAnimation()) return;
    _waitingForVisibility = true;
    void check(Duration _) {
      if (!mounted ||
          !_tickingEnabled ||
          _ticker.isActive ||
          !_hasUsedAnimation()) {
        _waitingForVisibility = false;
        return;
      }
      final viewport = _visibleViewport();
      if (viewport != _clockViewport) {
        _clockViewport = viewport;
        _visibleAnimations = _animationsIn(viewport);
      }
      if (_visibleAnimations.isNotEmpty) {
        _waitingForVisibility = false;
        _animationRepaint.value++;
      } else {
        WidgetsBinding.instance.addPostFrameCallback(check);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(check);
  }

  void _resetClock() {
    _stopTicker();
    _elapsed = Duration.zero;
    _rendererSeconds = 0;
    _paintViewport = null;
    _clockViewport = null;
    _visibleAnimations = {};
    _animations.clear();
    _objectIndices.clear();
    _objectAnimations.clear();
    _hasAnimations = null;
  }

  Rect _visibleViewport() {
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return Rect.zero;
    }
    var viewport = (Offset.zero & render.size);
    final view = View.of(context);
    viewport = viewport.intersect(
      MatrixUtils.inverseTransformRect(
        render.getTransformTo(null),
        Offset.zero & (view.physicalSize / view.devicePixelRatio),
      ),
    );
    RenderObject child = render;
    for (var parent = child.parent; parent != null; parent = child.parent) {
      if (parent is RenderOffstage && parent.offstage ||
          parent is RenderOpacity && parent.opacity == 0 ||
          parent is RenderAnimatedOpacity && parent.opacity.value == 0) {
        return Rect.zero;
      }
      final clip = parent.describeApproximatePaintClip(child);
      if (clip != null) {
        viewport = viewport.intersect(
          MatrixUtils.inverseTransformRect(render.getTransformTo(parent), clip),
        );
      }
      if (viewport.isEmpty) return Rect.zero;
      child = parent;
    }
    return viewport;
  }

  void _painted(Rect viewport) {
    _paintViewport = viewport;
    final visible = viewport.intersect(_visibleViewport());
    if (visible != _clockViewport) {
      _clockViewport = visible;
      _visibleAnimations = _animationsIn(visible);
    }
    if (!_tickingEnabled || _visibleAnimations.isEmpty) {
      _stopTicker();
      if (_tickingEnabled) _waitForVisibleAnimation();
    } else if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    if (!_tickingEnabled || !mounted) {
      _stopTicker();
      return;
    }
    final viewport = _visibleViewport().intersect(_paintViewport ?? Rect.zero);
    if (viewport != _clockViewport) {
      _clockViewport = viewport;
      _visibleAnimations = _animationsIn(viewport);
    }
    if (_visibleAnimations.isEmpty) {
      _stopTicker();
      _waitForVisibleAnimation();
      return;
    }
    final before = _elapsed.inMilliseconds;
    _elapsed += elapsed - _lastTick;
    _lastTick = elapsed;
    final seconds =
        (_elapsed.inMilliseconds + 0.5) / Duration.millisecondsPerSecond;
    renderer.update(seconds - _rendererSeconds);
    _rendererSeconds = seconds;
    final after = _elapsed.inMilliseconds;
    if (_visibleAnimations.any(
      (visual) => !identical(visual.frameAt(before), visual.frameAt(after)),
    )) {
      _animationRepaint.value++;
    }
  }
}
