import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../use_cases/map_connection_use_cases.dart';

final class MapConnectionMutationIntent {
  const MapConnectionMutationIntent({
    required this.actionId,
    required this.parameters,
  });

  final String actionId;
  final Map<String, Object?> parameters;
}

class MapConnectionEditingService {
  const MapConnectionEditingService({
    required ResolveMapConnectionTargetUseCase
        resolveMapConnectionTargetUseCase,
  }) : _resolveMapConnectionTargetUseCase = resolveMapConnectionTargetUseCase;

  final ResolveMapConnectionTargetUseCase _resolveMapConnectionTargetUseCase;

  MapConnection? findConnection(
    MapData? map,
    MapConnectionDirection direction,
  ) {
    if (map == null) {
      return null;
    }
    return findMapConnection(map, direction);
  }

  MapConnectionMutationIntent buildUpsertIntent({
    required MapData sourceMap,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    required bool reciprocal,
    required bool exactReciprocalPairExists,
  }) {
    final normalizedTargetMapId = targetMapId.trim();
    if (normalizedTargetMapId.isEmpty) {
      throw const EditorValidationException(
        'Connected map cannot be empty',
      );
    }
    if (normalizedTargetMapId == sourceMap.id) {
      throw const EditorValidationException(
        'A map cannot connect to itself',
      );
    }
    return MapConnectionMutationIntent(
      actionId: reciprocal
          ? exactReciprocalPairExists
              ? 'connection.update_bidirectional_apply'
              : 'connection.create_bidirectional_apply'
          : 'connection.upsert',
      parameters: Map<String, Object?>.unmodifiable({
        'mapId': sourceMap.id,
        'direction': direction.name,
        'targetMapId': normalizedTargetMapId,
        'offset': offset,
      }),
    );
  }

  MapConnectionMutationIntent buildDeleteIntent({
    required MapData sourceMap,
    required MapConnectionDirection direction,
    required bool exactReciprocalPairExists,
  }) {
    return MapConnectionMutationIntent(
      actionId: exactReciprocalPairExists
          ? 'connection.delete_bidirectional_apply'
          : 'connection.delete',
      parameters: Map<String, Object?>.unmodifiable({
        'mapId': sourceMap.id,
        'direction': direction.name,
      }),
    );
  }

  bool hasExactReciprocalPair({
    required MapData sourceMap,
    required MapData targetMap,
    required MapConnectionDirection direction,
  }) {
    final sourceConnection = findConnection(sourceMap, direction);
    if (sourceConnection == null ||
        sourceConnection.targetMapId != targetMap.id) {
      return false;
    }
    final targetConnection = findConnection(targetMap, direction.opposite);
    return targetConnection != null &&
        targetConnection.targetMapId == sourceMap.id &&
        targetConnection.offset == -sourceConnection.offset;
  }

  ProjectMapEntry resolveTargetMapEntry(
    ProjectManifest project,
    String targetMapId,
  ) {
    return _resolveMapConnectionTargetUseCase.execute(project, targetMapId);
  }
}
