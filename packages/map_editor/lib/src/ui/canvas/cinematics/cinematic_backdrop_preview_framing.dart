import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import 'cinematic_map_backdrop_viewport_transform.dart';

enum CinematicBackdropPreviewFramingMode {
  fitMap,
  scene,
}

@immutable
final class CinematicBackdropPreviewFramingState {
  const CinematicBackdropPreviewFramingState({
    this.mode = CinematicBackdropPreviewFramingMode.fitMap,
    this.zoom = 1,
    this.panTiles = Offset.zero,
    this.showDetails = false,
    this.showGrid = false,
  });

  static const minZoom = 1.0;
  static const maxZoom = 4.0;
  static const zoomStep = 0.25;

  final CinematicBackdropPreviewFramingMode mode;
  final double zoom;
  final Offset panTiles;
  final bool showDetails;
  final bool showGrid;

  double get clampedZoom => clampZoom(zoom);

  CinematicBackdropPreviewFramingState copyWith({
    CinematicBackdropPreviewFramingMode? mode,
    double? zoom,
    Offset? panTiles,
    bool? showDetails,
    bool? showGrid,
  }) {
    return CinematicBackdropPreviewFramingState(
      mode: mode ?? this.mode,
      zoom: zoom ?? this.zoom,
      panTiles: panTiles ?? this.panTiles,
      showDetails: showDetails ?? this.showDetails,
      showGrid: showGrid ?? this.showGrid,
    );
  }

  static double clampZoom(double value) {
    if (!value.isFinite) {
      return minZoom;
    }
    return value.clamp(minZoom, maxZoom).toDouble();
  }
}

@immutable
final class CinematicBackdropPreviewFocus {
  const CinematicBackdropPreviewFocus({
    required this.tileCenter,
    required this.reason,
    this.actorId,
  });

  final Offset tileCenter;
  final String reason;
  final String? actorId;
}

@immutable
final class CinematicBackdropPreviewFramingResult {
  const CinematicBackdropPreviewFramingResult({
    required this.mode,
    required this.zoom,
    required this.panTiles,
    required this.focus,
    required this.transform,
  });

  final CinematicBackdropPreviewFramingMode mode;
  final double zoom;
  final Offset panTiles;
  final CinematicBackdropPreviewFocus focus;
  final CinematicMapBackdropViewportTransform transform;
}

CinematicBackdropPreviewFocus resolveCinematicBackdropPreviewFocus({
  required int mapWidth,
  required int mapHeight,
  CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  CinematicTimelineStep? selectedStep,
}) {
  final safeMapWidth = math.max(1, mapWidth);
  final safeMapHeight = math.max(1, mapHeight);
  final selectedActorId = selectedStep?.actorId;
  if (selectedActorId != null && actorDisplayPreviewModel != null) {
    final actor = actorDisplayPreviewModel.actorById(selectedActorId);
    if (_hasResolvedActorTile(actor, safeMapWidth, safeMapHeight)) {
      return CinematicBackdropPreviewFocus(
        tileCenter: _actorTileCenter(actor!),
        reason: 'selectedActor',
        actorId: actor.actorId,
      );
    }
  }

  final actors = actorDisplayPreviewModel?.actors.where((actor) {
    return _hasResolvedActorTile(actor, safeMapWidth, safeMapHeight);
  }).toList();
  if (actors != null && actors.isNotEmpty) {
    var minX = actors.first.position.x!.toDouble();
    var maxX = minX + 1;
    var minY = actors.first.position.y!.toDouble();
    var maxY = minY + 1;
    for (final actor in actors.skip(1)) {
      final x = actor.position.x!.toDouble();
      final y = actor.position.y!.toDouble();
      minX = math.min(minX, x);
      maxX = math.max(maxX, x + 1);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y + 1);
    }
    return CinematicBackdropPreviewFocus(
      tileCenter: Offset((minX + maxX) / 2, (minY + maxY) / 2),
      reason: 'actorBounds',
    );
  }

  return CinematicBackdropPreviewFocus(
    tileCenter: Offset(safeMapWidth / 2, safeMapHeight / 2),
    reason: 'mapCenter',
  );
}

CinematicBackdropPreviewFramingResult resolveCinematicBackdropPreviewFraming({
  required Size viewportSize,
  required Size mapPixelSize,
  required int mapWidth,
  required int mapHeight,
  required CinematicBackdropPreviewFramingState state,
  required CinematicBackdropPreviewFocus focus,
}) {
  if (viewportSize.isEmpty ||
      !viewportSize.isFinite ||
      mapPixelSize.width <= 0 ||
      mapPixelSize.height <= 0 ||
      mapWidth <= 0 ||
      mapHeight <= 0) {
    return CinematicBackdropPreviewFramingResult(
      mode: state.mode,
      zoom: state.clampedZoom,
      panTiles: Offset.zero,
      focus: focus,
      transform: CinematicMapBackdropViewportTransform(
        frame: Rect.zero,
        mapWidth: mapWidth,
        mapHeight: mapHeight,
      ),
    );
  }

  final fitFrame = fittedCinematicMapBackdropRect(
    availableSize: viewportSize,
    mapPixelSize: mapPixelSize,
  );
  if (state.mode == CinematicBackdropPreviewFramingMode.fitMap ||
      fitFrame.isEmpty) {
    return CinematicBackdropPreviewFramingResult(
      mode: CinematicBackdropPreviewFramingMode.fitMap,
      zoom: CinematicBackdropPreviewFramingState.minZoom,
      panTiles: Offset.zero,
      focus: focus,
      transform: CinematicMapBackdropViewportTransform(
        frame: fitFrame,
        mapWidth: mapWidth,
        mapHeight: mapHeight,
      ),
    );
  }

  final fitScale = fitFrame.width / mapPixelSize.width;
  final tilePixelWidth = mapPixelSize.width / mapWidth;
  final tilePixelHeight = mapPixelSize.height / mapHeight;
  const targetSceneTileWidth = 22.0;
  const targetSceneTileHeight = 14.0;
  final sceneBaseScale = math.max(
    viewportSize.width / (targetSceneTileWidth * tilePixelWidth),
    viewportSize.height / (targetSceneTileHeight * tilePixelHeight),
  );
  final scale = math.max(fitScale, sceneBaseScale) * state.clampedZoom;
  final frameSize = Size(
    mapPixelSize.width * scale,
    mapPixelSize.height * scale,
  );
  final focusTile = Offset(
    focus.tileCenter.dx.clamp(0.0, mapWidth.toDouble()).toDouble(),
    focus.tileCenter.dy.clamp(0.0, mapHeight.toDouble()).toDouble(),
  );
  final visibleTilesX = viewportSize.width / (tilePixelWidth * scale);
  final visibleTilesY = viewportSize.height / (tilePixelHeight * scale);
  final centerTile = Offset(
    _clampCenterTile(
      focusTile.dx + state.panTiles.dx,
      visibleTilesX / 2,
      mapWidth.toDouble(),
    ),
    _clampCenterTile(
      focusTile.dy + state.panTiles.dy,
      visibleTilesY / 2,
      mapHeight.toDouble(),
    ),
  );
  final clampedPanTiles = centerTile - focusTile;
  final focusPixel = Offset(
    centerTile.dx * tilePixelWidth,
    centerTile.dy * tilePixelHeight,
  );
  final desiredLeft = viewportSize.width / 2 - focusPixel.dx * scale;
  final desiredTop = viewportSize.height / 2 - focusPixel.dy * scale;
  final frame = Rect.fromLTWH(
    _clampFrameOffset(desiredLeft, viewportSize.width, frameSize.width),
    _clampFrameOffset(desiredTop, viewportSize.height, frameSize.height),
    frameSize.width,
    frameSize.height,
  );
  return CinematicBackdropPreviewFramingResult(
    mode: CinematicBackdropPreviewFramingMode.scene,
    zoom: state.clampedZoom,
    panTiles: clampedPanTiles,
    focus: focus,
    transform: CinematicMapBackdropViewportTransform(
      frame: frame,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    ),
  );
}

double _clampCenterTile(
  double desired,
  double halfVisibleTiles,
  double mapExtent,
) {
  if (mapExtent <= 0 || halfVisibleTiles * 2 >= mapExtent) {
    return mapExtent / 2;
  }
  return desired
      .clamp(halfVisibleTiles, mapExtent - halfVisibleTiles)
      .toDouble();
}

bool _hasResolvedActorTile(
  CinematicActorDisplayPreviewActor? actor,
  int mapWidth,
  int mapHeight,
) {
  final x = actor?.position.x;
  final y = actor?.position.y;
  if (actor == null || !actor.isRenderable || x == null || y == null) {
    return false;
  }
  return x >= 0 && y >= 0 && x < mapWidth && y < mapHeight;
}

Offset _actorTileCenter(CinematicActorDisplayPreviewActor actor) {
  return Offset(actor.position.x! + 0.5, actor.position.y! + 0.5);
}

double _clampFrameOffset(
  double desired,
  double viewportExtent,
  double frameExtent,
) {
  if (frameExtent <= viewportExtent) {
    return (viewportExtent - frameExtent) / 2;
  }
  return desired.clamp(viewportExtent - frameExtent, 0.0).toDouble();
}
