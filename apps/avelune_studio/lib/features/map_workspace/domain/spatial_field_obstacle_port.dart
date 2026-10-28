import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_workspace_port.dart';

final class SpatialFieldObstacleReceipt {
  const SpatialFieldObstacleReceipt({
    required this.document,
    required this.receiptId,
    required this.instanceId,
  });
  final MapWorkspaceDocument document;
  final String receiptId, instanceId;
}

abstract interface class SpatialFieldObstaclePort {
  Future<SpatialFieldObstacleReceipt> configureSpatialFieldObstacle(
    ProjectSession session,
    MapWorkspaceDocument base,
    String instanceId,
    MapEntityFieldObstacleData? fieldObstacle,
  );
  Future<SpatialFieldObstacleReceipt> undoSpatialFieldObstacle(
    ProjectSession session,
    MapWorkspaceDocument base,
    SpatialFieldObstacleReceipt receipt, {
    required bool redo,
  });
}
