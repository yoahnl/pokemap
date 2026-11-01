import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_workspace_port.dart';

final class SpatialModelVisibilityReceipt {
  const SpatialModelVisibilityReceipt({
    required this.document,
    required this.receiptId,
    required this.instanceId,
    this.condition,
  });
  final MapWorkspaceDocument document;
  final String receiptId, instanceId;
  final NarrativeEventConditionExpression? condition;
}

abstract interface class SpatialModelVisibilityPort {
  Future<SpatialModelVisibilityReceipt> configureSpatialModelVisibility(
    ProjectSession session,
    MapWorkspaceDocument base,
    String instanceId,
    NarrativeEventConditionExpression? condition,
  );
  Future<SpatialModelVisibilityReceipt> undoSpatialModelVisibility(
    ProjectSession session,
    MapWorkspaceDocument base,
    SpatialModelVisibilityReceipt receipt, {
    required bool redo,
  });
}
