import 'package:freezed_annotation/freezed_annotation.dart' show immutable;
import 'package:map_core/map_core.dart';

import '../state/editor_state.dart';
import '../tools/editor_tool.dart';
import 'world_map_tool_activation.dart';
import 'world_map_tool_family.dart';

enum WorldMapSubtoolBodyKind {
  tilesPalette,
  terrainPainter,
  pathPainter,
  surfacePainter,
  borderInspector,
  collisionInspector,
  elementsPalette,
  entityPlacement,
  eventPlacement,
  triggerPlacement,
  warpPlacement,
  gameplayZonePlacement,
}

enum WorldMapSubtoolBodyAccess {
  ready,
  setup,
  unavailable,
}

@immutable
final class WorldMapSubtoolBodyProjection {
  const WorldMapSubtoolBodyProjection({
    required this.bodyKind,
    required this.access,
    required this.activation,
  });

  final WorldMapSubtoolBodyKind bodyKind;
  final WorldMapSubtoolBodyAccess access;
  final WorldMapToolActivationAssessment activation;

  bool get isAvailable => access == WorldMapSubtoolBodyAccess.ready;
  bool get canRenderBody => access != WorldMapSubtoolBodyAccess.unavailable;
  String? get disabledReason => activation.rejectionReason;
  EditorToolType? get resultingTool => activation.resultingTool;
  EditorBrush? get resultingBrush => activation.resultingBrush;
}

final class WorldMapSubtoolBodyProjector {
  const WorldMapSubtoolBodyProjector();

  WorldMapSubtoolBodyProjection project({
    required WorldMapToolActivationSource source,
    required WorldMapSubtoolActivationRequest request,
    String? activeBorderFeatureId,
  }) {
    final bodyKind = switch (request) {
      ActivateWorldMapPaint(:final subtool) => switch (subtool) {
          WorldMapPaintSubtool.tile => WorldMapSubtoolBodyKind.tilesPalette,
          WorldMapPaintSubtool.terrain =>
            WorldMapSubtoolBodyKind.terrainPainter,
          WorldMapPaintSubtool.path => WorldMapSubtoolBodyKind.pathPainter,
          WorldMapPaintSubtool.surface =>
            WorldMapSubtoolBodyKind.surfacePainter,
          WorldMapPaintSubtool.border =>
            WorldMapSubtoolBodyKind.borderInspector,
          WorldMapPaintSubtool.collision =>
            WorldMapSubtoolBodyKind.collisionInspector,
        },
      ActivateWorldMapPlacement(:final subtool) => switch (subtool) {
          WorldMapPlacementSubtool.object =>
            WorldMapSubtoolBodyKind.elementsPalette,
          WorldMapPlacementSubtool.entity =>
            WorldMapSubtoolBodyKind.entityPlacement,
          WorldMapPlacementSubtool.event =>
            WorldMapSubtoolBodyKind.eventPlacement,
          WorldMapPlacementSubtool.trigger =>
            WorldMapSubtoolBodyKind.triggerPlacement,
          WorldMapPlacementSubtool.warp =>
            WorldMapSubtoolBodyKind.warpPlacement,
          WorldMapPlacementSubtool.gameplayZone =>
            WorldMapSubtoolBodyKind.gameplayZonePlacement,
        },
    };
    final activation = assessWorldMapToolActivation(
      source: source,
      request: request,
      activeBorderFeatureId: activeBorderFeatureId,
    );
    final access = activation.rejectionReason == null
        ? WorldMapSubtoolBodyAccess.ready
        : _isSetupCapablePaintRequest(source: source, request: request)
            ? WorldMapSubtoolBodyAccess.setup
            : WorldMapSubtoolBodyAccess.unavailable;
    return WorldMapSubtoolBodyProjection(
      bodyKind: bodyKind,
      access: access,
      activation: activation,
    );
  }
}

bool _isSetupCapablePaintRequest({
  required WorldMapToolActivationSource source,
  required WorldMapSubtoolActivationRequest request,
}) {
  final map = source.activeMap;
  final activeLayerId = source.activeLayerId;
  if (map == null || activeLayerId == null) {
    return false;
  }
  MapLayer? activeLayer;
  for (final layer in map.layers) {
    if (layer.id == activeLayerId) {
      activeLayer = layer;
      break;
    }
  }
  return switch (request) {
    ActivateWorldMapPaint(subtool: WorldMapPaintSubtool.surface) =>
      activeLayer is SurfaceLayer,
    ActivateWorldMapPaint(subtool: WorldMapPaintSubtool.border) =>
      activeLayer is BorderLayer,
    ActivateWorldMapPaint() || ActivateWorldMapPlacement() => false,
  };
}
