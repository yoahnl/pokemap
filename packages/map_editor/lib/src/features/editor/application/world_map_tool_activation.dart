import 'package:freezed_annotation/freezed_annotation.dart' show immutable;

import '../tools/editor_tool.dart';
import 'world_map_tool_family.dart';

sealed class WorldMapToolActivationRequest {
  const WorldMapToolActivationRequest();
}

final class ActivateWorldMapSelection extends WorldMapToolActivationRequest {
  const ActivateWorldMapSelection();
}

final class ActivateWorldMapPaint extends WorldMapToolActivationRequest {
  const ActivateWorldMapPaint(this.subtool);

  final WorldMapPaintSubtool subtool;
}

final class ActivateWorldMapErase extends WorldMapToolActivationRequest {
  const ActivateWorldMapErase();
}

final class ActivateWorldMapPlacement extends WorldMapToolActivationRequest {
  const ActivateWorldMapPlacement(this.subtool);

  final WorldMapPlacementSubtool subtool;
}

@immutable
final class WorldMapToolActivationResult {
  const WorldMapToolActivationResult({
    required this.accepted,
    this.resultingTool,
    this.rejectionReason,
  });

  final bool accepted;
  final EditorToolType? resultingTool;
  final String? rejectionReason;
}

typedef WorldMapToolActivationSessionSnapshot = ({
  String? activeMapId,
  String? activeLayerId,
  EditorToolType activeTool,
});

abstract interface class WorldMapToolActivationHost {
  WorldMapToolActivationSessionSnapshot
      get worldMapToolActivationSessionSnapshot;

  WorldMapToolActivationResult activateWorldMapTool(
    WorldMapToolActivationRequest request,
  );

  WorldMapToolActivationResult setActiveWorldMapLayer({
    required String layerId,
    required WorldMapToolActivationRequest toolRequest,
  });

  void setActiveLayer(String layerId);
}
