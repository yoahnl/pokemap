import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

class ResolveMapConnectionTargetUseCase {
  ProjectMapEntry execute(
    ProjectManifest project,
    String targetMapId,
  ) {
    final normalizedTargetMapId = targetMapId.trim();
    if (normalizedTargetMapId.isEmpty) {
      throw const EditorValidationException(
        'Connected map cannot be empty',
      );
    }
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedTargetMapId) {
        return mapEntry;
      }
    }
    throw EditorNotFoundException(
      'Connected map not found in project: $normalizedTargetMapId',
    );
  }
}

class UpsertMapConnectionUseCase {
  UpsertMapConnectionUseCase(
    this._mapRepo,
    this._resolveMapConnectionTargetUseCase,
  );

  final MapRepository _mapRepo;
  final ResolveMapConnectionTargetUseCase _resolveMapConnectionTargetUseCase;

  Future<MapData> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required MapData sourceMap,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final normalizedTargetMapId = targetMapId.trim();
    if (normalizedTargetMapId.isEmpty) {
      throw const EditorValidationException(
        'Connected map cannot be empty',
      );
    }
    if (normalizedTargetMapId == sourceMap.id.trim()) {
      throw const EditorValidationException(
        'A map cannot connect to itself',
      );
    }

    final targetMapEntry = _resolveMapConnectionTargetUseCase.execute(
      project,
      normalizedTargetMapId,
    );

    final targetMapPath = fs.resolveMapPath(targetMapEntry.relativePath);
    final targetMap =
        await _loadTargetMap(targetMapPath, normalizedTargetMapId);

    final updatedMap = upsertMapConnectionOnMap(
      sourceMap,
      connection: MapConnection(
        direction: direction,
        targetMapId: normalizedTargetMapId,
        offset: offset,
      ),
    );
    MapValidator.validate(updatedMap);

    if (!hasMapConnectionOverlap(
      sourceSize: updatedMap.size,
      targetSize: targetMap.size,
      direction: direction,
      offset: offset,
    )) {
      throw EditorValidationException(
        'Connection ${direction.name} from "${sourceMap.id}" to "${targetMap.id}" has no overlapping border with offset $offset',
      );
    }

    final inverseConnection = findMapConnection(
      targetMap,
      direction.opposite,
    );
    if (inverseConnection != null) {
      if (inverseConnection.targetMapId.trim() != sourceMap.id.trim()) {
        throw EditorConflictException(
          'Map "${targetMap.id}" already has a ${direction.opposite.name} connection to "${inverseConnection.targetMapId}"',
        );
      }
      if (inverseConnection.offset != -offset) {
        throw EditorConflictException(
          'Map "${targetMap.id}" has a ${direction.opposite.name} connection back with offset ${inverseConnection.offset}; expected ${-offset}',
        );
      }
    }

    return updatedMap;
  }

  Future<MapData> _loadTargetMap(
    String targetMapPath,
    String targetMapId,
  ) async {
    try {
      return await _mapRepo.loadMap(targetMapPath);
    } on MapLoadException catch (error) {
      throw EditorNotFoundException(
        'Failed to load connected map "$targetMapId": ${error.message}',
      );
    }
  }
}

class DeleteMapConnectionUseCase {
  MapData execute(
    MapData map, {
    required MapConnectionDirection direction,
  }) {
    final updatedMap = removeMapConnectionFromMap(
      map,
      direction: direction,
    );
    MapValidator.validate(updatedMap);
    return updatedMap;
  }
}
