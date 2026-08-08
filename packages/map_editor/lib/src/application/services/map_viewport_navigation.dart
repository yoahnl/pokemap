import 'dart:math' as math;
import 'dart:ui';

/// Immutable camera transform for the world-map canvas.
///
/// World pixels are rendered with:
///
/// `viewportPoint = panOffset + worldPoint * zoom`
class MapViewport {
  const MapViewport({
    required this.zoom,
    required this.panOffset,
  }) : assert(zoom > 0);

  final double zoom;
  final Offset panOffset;
}

/// Pure desktop-navigation geometry shared by pointer events and UI controls.
abstract final class MapViewportNavigation {
  static const double minZoom = 0.1;
  static const double maxZoom = 5;
  static const double wheelZoomSensitivity = 0.002;

  static Offset worldPointAt({
    required MapViewport viewport,
    required Offset viewportPoint,
  }) {
    return (viewportPoint - viewport.panOffset) / viewport.zoom;
  }

  static MapViewport panBy({
    required MapViewport viewport,
    required Offset delta,
  }) {
    return MapViewport(
      zoom: viewport.zoom,
      panOffset: viewport.panOffset + delta,
    );
  }

  static MapViewport zoomAt({
    required MapViewport viewport,
    required Offset focalPoint,
    required double targetZoom,
  }) {
    final clampedZoom = _clampZoom(targetZoom);
    final worldAnchor = worldPointAt(
      viewport: viewport,
      viewportPoint: focalPoint,
    );
    return MapViewport(
      zoom: clampedZoom,
      panOffset: focalPoint - worldAnchor * clampedZoom,
    );
  }

  static MapViewport zoomFromScroll({
    required MapViewport viewport,
    required Offset focalPoint,
    required double scrollDeltaY,
  }) {
    if (scrollDeltaY.isNaN) {
      throw ArgumentError.value(scrollDeltaY, 'scrollDeltaY');
    }
    final factor = math.exp(-scrollDeltaY * wheelZoomSensitivity);
    return zoomAt(
      viewport: viewport,
      focalPoint: focalPoint,
      targetZoom: viewport.zoom * factor,
    );
  }

  /// Resolves a native trackpad gesture from its immutable start snapshot.
  ///
  /// Both [cumulativePan] and [scale] are absolute values for the gesture, not
  /// deltas. Recomputing from the start prevents drift and pinch jumps.
  static MapViewport panZoomFromStart({
    required MapViewport startViewport,
    required Offset startFocalPoint,
    required Offset cumulativePan,
    required double scale,
  }) {
    if (scale.isNaN || scale <= 0) {
      throw ArgumentError.value(scale, 'scale', 'must be positive');
    }
    final worldAnchor = worldPointAt(
      viewport: startViewport,
      viewportPoint: startFocalPoint,
    );
    final zoom = _clampZoom(startViewport.zoom * scale);
    final currentFocalPoint = startFocalPoint + cumulativePan;
    return MapViewport(
      zoom: zoom,
      panOffset: currentFocalPoint - worldAnchor * zoom,
    );
  }

  static MapViewport fitMap({
    required Size mapPixelSize,
    required Size viewportSize,
    double margin = 32,
  }) {
    _validateSize(mapPixelSize, 'mapPixelSize');
    _validateSize(viewportSize, 'viewportSize');
    if (!margin.isFinite || margin < 0) {
      throw ArgumentError.value(margin, 'margin', 'must be non-negative');
    }
    final availableWidth = viewportSize.width - margin * 2;
    final availableHeight = viewportSize.height - margin * 2;
    if (availableWidth <= 0 || availableHeight <= 0) {
      throw ArgumentError.value(
        margin,
        'margin',
        'must leave a positive viewport area',
      );
    }
    final zoom = _clampZoom(
      math.min(
        availableWidth / mapPixelSize.width,
        availableHeight / mapPixelSize.height,
      ),
    );
    return centerMap(
      mapPixelSize: mapPixelSize,
      viewportSize: viewportSize,
      zoom: zoom,
    );
  }

  static MapViewport fitBounds({
    required Rect contentBounds,
    required Size viewportSize,
    required Size tileSize,
  }) {
    _validateSize(viewportSize, 'viewportSize');
    _validateSize(tileSize, 'tileSize');
    if (!contentBounds.left.isFinite ||
        !contentBounds.top.isFinite ||
        !contentBounds.right.isFinite ||
        !contentBounds.bottom.isFinite ||
        contentBounds.width <= 0 ||
        contentBounds.height <= 0) {
      throw ArgumentError.value(
        contentBounds,
        'contentBounds',
        'must be finite with positive dimensions',
      );
    }
    const margin = 32.0;
    final availableWidth = viewportSize.width - margin * 2;
    final availableHeight = viewportSize.height - margin * 2;
    if (availableWidth <= 0 || availableHeight <= 0) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'must leave a positive viewport area',
      );
    }
    final pixelBounds = Rect.fromLTRB(
      contentBounds.left * tileSize.width,
      contentBounds.top * tileSize.height,
      contentBounds.right * tileSize.width,
      contentBounds.bottom * tileSize.height,
    );
    final zoom = _clampZoom(
      math.min(
        availableWidth / pixelBounds.width,
        availableHeight / pixelBounds.height,
      ),
    );
    return MapViewport(
      zoom: zoom,
      panOffset: viewportSize.center(Offset.zero) - pixelBounds.center * zoom,
    );
  }

  static MapViewport centerMap({
    required Size mapPixelSize,
    required Size viewportSize,
    required double zoom,
  }) {
    _validateSize(mapPixelSize, 'mapPixelSize');
    _validateSize(viewportSize, 'viewportSize');
    final clampedZoom = _clampZoom(zoom);
    return MapViewport(
      zoom: clampedZoom,
      panOffset: viewportSize.center(Offset.zero) -
          mapPixelSize.center(Offset.zero) * clampedZoom,
    );
  }

  static MapViewport actualSize({
    required MapViewport viewport,
    required Size viewportSize,
  }) {
    _validateSize(viewportSize, 'viewportSize');
    return zoomAt(
      viewport: viewport,
      focalPoint: viewportSize.center(Offset.zero),
      targetZoom: 1,
    );
  }

  static double _clampZoom(double zoom) {
    if (zoom.isNaN || zoom <= 0) {
      throw ArgumentError.value(zoom, 'zoom', 'must be positive');
    }
    return zoom.clamp(minZoom, maxZoom).toDouble();
  }

  static void _validateSize(Size size, String name) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(size, name, 'must be finite and positive');
    }
  }
}
