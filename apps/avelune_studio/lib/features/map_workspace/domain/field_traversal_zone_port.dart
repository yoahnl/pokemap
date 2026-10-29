import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_workspace_port.dart';

final class FieldTraversalZoneReceipt {
  FieldTraversalZoneReceipt({
    required this.document,
    required this.receiptId,
    required this.actionId,
    required this.selectionZone,
    required Map<String, Object?> parameters,
  }) : parameters = Map.unmodifiable(parameters);
  final MapWorkspaceDocument document;
  final MapGameplayZone selectionZone;
  final String receiptId, actionId;
  final Map<String, Object?> parameters;
}

abstract interface class FieldTraversalZonePort {
  Future<FieldTraversalZoneReceipt> publishFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    String actionId,
    Map<String, Object?> parameters,
  );
  Future<FieldTraversalZoneReceipt> restoreFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    FieldTraversalZoneReceipt receipt, {
    required bool redo,
  });
}
