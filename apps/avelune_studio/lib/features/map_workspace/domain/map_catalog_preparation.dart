import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_catalog_port.dart';

final class MapCatalogIssue {
  const MapCatalogIssue({
    required this.code,
    required this.message,
    this.mapId,
  });

  final String code;
  final String message;
  final String? mapId;
}

final class MapCatalogPreparation {
  MapCatalogPreparation({
    required this.sessionId,
    required this.actionId,
    required Map<String, Object?> parameters,
    required this.targetMapId,
    required this.snapshotRevision,
    required this.sourceMap,
    required this.canApply,
    this.noChange = false,
    List<MapCatalogIssue> issues = const [],
    Map<String, Object?> details = const {},
  }) : parameters = Map.unmodifiable(parameters),
       issues = List.unmodifiable(issues),
       details = Map.unmodifiable(details);

  final String sessionId;
  final String actionId;
  final Map<String, Object?> parameters;
  final String targetMapId;
  final String snapshotRevision;
  final MapData sourceMap;
  final bool canApply;
  final bool noChange;
  final List<MapCatalogIssue> issues;
  final Map<String, Object?> details;

  MapCatalogPreparation withDuplicateDestination({
    required String name,
    String? groupId,
  }) {
    if (actionId != 'map.duplicate') {
      throw StateError('Seule la destination d’une copie est modifiable.');
    }
    return MapCatalogPreparation(
      sessionId: sessionId,
      actionId: actionId,
      parameters: {...parameters, 'name': name, 'groupId': groupId},
      targetMapId: targetMapId,
      snapshotRevision: snapshotRevision,
      sourceMap: sourceMap,
      canApply: canApply,
      noChange: noChange,
      issues: issues,
      details: details,
    );
  }
}

abstract interface class MapCatalogPreparationPort {
  Future<MapCatalogPreparation> prepare(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    ProjectManifest? expectedManifest,
  });

  Future<MapCatalogReceipt> applyPrepared(
    ProjectSession session,
    MapCatalogPreparation preparation, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
    String? Function()? validateBeforeApply,
  });
}
