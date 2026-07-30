import 'package:freezed_annotation/freezed_annotation.dart' show immutable;

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

@immutable
final class WorldMapSubtoolBodyProjection {
  const WorldMapSubtoolBodyProjection({
    required this.bodyKind,
    required this.activation,
  });

  final WorldMapSubtoolBodyKind bodyKind;
  final WorldMapToolActivationAssessment activation;

  bool get isAvailable => activation.rejectionReason == null;
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
    return WorldMapSubtoolBodyProjection(
      bodyKind: bodyKind,
      activation: activation,
    );
  }
}
