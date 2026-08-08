import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Owns the playable overworld camera projection in physical-pixel space.
///
/// The requested visible size remains an authoring/cinematic intent. The
/// effective camera zoom is derived from it and rounded to an integer number
/// of physical pixels per source pixel.
final class PixelPerfectOverworldCameraController {
  PixelPerfectOverworldCameraController({
    required CameraComponent camera,
    required double displayScale,
    required double Function() devicePixelRatioProvider,
  })  : _camera = camera,
        _displayScale = displayScale,
        _devicePixelRatioProvider = devicePixelRatioProvider {
    if (!displayScale.isFinite || displayScale <= 0) {
      throw ArgumentError.value(
        displayScale,
        'displayScale',
        'must be finite and greater than zero',
      );
    }
    _camera.viewfinder.visibleGameSize = null;
  }

  final CameraComponent _camera;
  final double _displayScale;
  final double Function() _devicePixelRatioProvider;

  Vector2? _requestedVisibleGameSize;
  Vector2? _logicalViewportSize;
  Vector2? _requestedWorldPosition;
  double? _devicePixelRatio;
  int? _physicalPixelsPerSourcePixel;
  double? _resolvedZoom;

  Vector2? get requestedVisibleGameSize => _requestedVisibleGameSize?.clone();

  int? get physicalPixelsPerSourcePixel => _physicalPixelsPerSourcePixel;

  double? get resolvedZoom => _resolvedZoom;

  Vector2? get effectiveVisibleGameSize {
    final viewport = _logicalViewportSize;
    final zoom = _resolvedZoom;
    if (viewport == null || zoom == null) {
      return null;
    }
    return viewport / zoom;
  }

  void setRequestedVisibleGameSize(Vector2? size) {
    _camera.viewfinder.visibleGameSize = null;
    if (!_isValidSize(size)) {
      _requestedVisibleGameSize = null;
      _physicalPixelsPerSourcePixel = null;
      _resolvedZoom = null;
      return;
    }
    _requestedVisibleGameSize = size!.clone();
    _reproject();
  }

  void onViewportResize(Vector2 logicalSize) {
    if (!_isValidSize(logicalSize)) {
      return;
    }
    _logicalViewportSize = logicalSize.clone();
    _reproject();
  }

  void refreshDevicePixelRatio() {
    final next = _readDevicePixelRatio();
    if (_devicePixelRatio == next) {
      return;
    }
    _devicePixelRatio = next;
    _reproject(readDevicePixelRatio: false);
  }

  void setPosition(Vector2 worldPosition) {
    _requestedWorldPosition = worldPosition.clone();
    _applySnappedPosition(worldPosition);
  }

  void _applySnappedPosition(Vector2 worldPosition) {
    final viewport = _logicalViewportSize;
    final zoom = _resolvedZoom;
    final dpr = _devicePixelRatio;
    if (viewport == null || zoom == null || dpr == null) {
      _camera.viewfinder.position = worldPosition.clone();
      return;
    }

    final physicalCenter = viewport * (dpr / 2);
    final worldToPhysical = zoom * dpr;
    final physicalWorldOrigin =
        physicalCenter - worldPosition * worldToPhysical;
    final snappedPhysicalOrigin = Vector2(
      physicalWorldOrigin.x.roundToDouble(),
      physicalWorldOrigin.y.roundToDouble(),
    );
    _camera.viewfinder.position =
        (physicalCenter - snappedPhysicalOrigin) / worldToPhysical;
  }

  Vector2 get position => _camera.viewfinder.position.clone();

  void _reproject({bool readDevicePixelRatio = true}) {
    final requested = _requestedVisibleGameSize;
    final viewport = _logicalViewportSize;
    if (requested == null || viewport == null) {
      return;
    }

    if (readDevicePixelRatio || _devicePixelRatio == null) {
      _devicePixelRatio = _readDevicePixelRatio();
    }
    final dpr = _devicePixelRatio!;
    final idealZoom = math.min(
      viewport.x / requested.x,
      viewport.y / requested.y,
    );
    final idealPhysicalScale = _displayScale * idealZoom * dpr;
    final physicalScale = math.max(1, idealPhysicalScale.round());
    final zoom = physicalScale / (_displayScale * dpr);

    _physicalPixelsPerSourcePixel = physicalScale;
    _resolvedZoom = zoom;
    _camera.viewfinder
      ..visibleGameSize = null
      ..zoom = zoom;
    _applySnappedPosition(
      _requestedWorldPosition ?? _camera.viewfinder.position,
    );
  }

  double _readDevicePixelRatio() {
    final value = _devicePixelRatioProvider();
    if (!value.isFinite || value <= 0) {
      return 1;
    }
    return value;
  }

  static bool _isValidSize(Vector2? size) {
    return size != null &&
        size.x.isFinite &&
        size.y.isFinite &&
        size.x > 0 &&
        size.y > 0;
  }
}

double defaultRuntimeDevicePixelRatio() {
  final value = ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio;
  if (value == null || !value.isFinite || value <= 0) {
    return 1;
  }
  return value;
}
