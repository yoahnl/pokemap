import 'package:map_core/map_core.dart';

import '../ports/project_workspace.dart';
import '../use_cases/map_connection_use_cases.dart';

class MapConnectionEditingService {
  const MapConnectionEditingService({
    required UpsertMapConnectionUseCase upsertMapConnectionUseCase,
    required DeleteMapConnectionUseCase deleteMapConnectionUseCase,
    required ResolveMapConnectionTargetUseCase
        resolveMapConnectionTargetUseCase,
  })  : _upsertMapConnectionUseCase = upsertMapConnectionUseCase,
        _deleteMapConnectionUseCase = deleteMapConnectionUseCase,
        _resolveMapConnectionTargetUseCase = resolveMapConnectionTargetUseCase;

  final UpsertMapConnectionUseCase _upsertMapConnectionUseCase;
  final DeleteMapConnectionUseCase _deleteMapConnectionUseCase;
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

  Future<MapData> upsertConnection(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required MapData sourceMap,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) {
    return _upsertMapConnectionUseCase.execute(
      fs,
      project,
      sourceMap: sourceMap,
      direction: direction,
      targetMapId: targetMapId,
      offset: offset,
    );
  }

  MapData deleteConnection(
    MapData map, {
    required MapConnectionDirection direction,
  }) {
    return _deleteMapConnectionUseCase.execute(
      map,
      direction: direction,
    );
  }

  ProjectMapEntry resolveTargetMapEntry(
    ProjectManifest project,
    String targetMapId,
  ) {
    return _resolveMapConnectionTargetUseCase.execute(project, targetMapId);
  }
}
