import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

class AddWarpToMapUseCase {
  MapData execute(
    MapData map, {
    required MapWarp warp,
  }) {
    final updated = addWarpToMap(
      map,
      warp: warp,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class UpdateWarpOnMapUseCase {
  MapData execute(
    MapData map, {
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
  }) {
    final updated = updateWarpOnMap(
      map,
      warpId: warpId,
      id: id,
      pos: pos,
      targetMapId: targetMapId,
      targetPos: targetPos,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteWarpFromMapUseCase {
  MapData execute(
    MapData map, {
    required String warpId,
  }) {
    final updated = removeWarpFromMap(
      map,
      warpId: warpId,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class ValidateWarpTargetMapUseCase {
  ProjectMapEntry execute(
    ProjectManifest project,
    String targetMapId,
  ) {
    final normalizedTargetMapId = targetMapId.trim();
    if (normalizedTargetMapId.isEmpty) {
      throw const EditorValidationException('Warp target map cannot be empty');
    }
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedTargetMapId) {
        return mapEntry;
      }
    }
    throw EditorNotFoundException(
        'Warp target map not found in project: $normalizedTargetMapId');
  }
}

class CreateReciprocalWarpResult {
  const CreateReciprocalWarpResult({
    required this.updatedTargetMap,
    required this.reciprocalWarp,
    required this.targetIsSourceMap,
  });

  final MapData updatedTargetMap;
  final MapWarp reciprocalWarp;
  final bool targetIsSourceMap;
}

class CreateReciprocalWarpUseCase {
  CreateReciprocalWarpUseCase(this._mapRepo);

  final MapRepository _mapRepo;

  Future<CreateReciprocalWarpResult> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required MapData sourceMap,
    required MapWarp sourceWarp,
  }) async {
    final targetMapId = sourceWarp.targetMapId.trim();
    if (targetMapId.isEmpty) {
      throw const EditorValidationException('Warp target map cannot be empty');
    }
    final targetMapEntry = project.maps.firstWhere(
      (entry) => entry.id == targetMapId,
      orElse: () => throw EditorNotFoundException(
          'Warp target map not found in project: $targetMapId'),
    );

    final targetIsSourceMap = targetMapEntry.id == sourceMap.id;
    final targetMap = targetIsSourceMap
        ? sourceMap
        : await _mapRepo
            .loadMap(fs.resolveMapPath(targetMapEntry.relativePath));

    final destinationPos = sourceWarp.targetPos;
    if (destinationPos.x < 0 ||
        destinationPos.y < 0 ||
        destinationPos.x >= targetMap.size.width ||
        destinationPos.y >= targetMap.size.height) {
      throw EditorValidationException(
          'Warp destination is out of bounds in target map "${targetMap.id}" at (${destinationPos.x}, ${destinationPos.y})');
    }

    final hasWarpAtDestination =
        targetMap.warps.any((warp) => warp.pos == destinationPos);
    if (hasWarpAtDestination) {
      throw EditorConflictException(
          'A warp already exists in target map "${targetMap.id}" at (${destinationPos.x}, ${destinationPos.y})');
    }

    final reciprocalWarp = MapWarp(
      id: _generateUniqueWarpId(targetMap),
      pos: destinationPos,
      targetMapId: sourceMap.id,
      targetPos: sourceWarp.pos,
    );
    final updatedTargetMap = addWarpToMap(targetMap, warp: reciprocalWarp);
    MapValidator.validate(updatedTargetMap);

    if (!targetIsSourceMap) {
      final targetMapPath = fs.resolveMapPath(targetMapEntry.relativePath);
      await _mapRepo.saveMap(updatedTargetMap, targetMapPath);
    }

    return CreateReciprocalWarpResult(
      updatedTargetMap: updatedTargetMap,
      reciprocalWarp: reciprocalWarp,
      targetIsSourceMap: targetIsSourceMap,
    );
  }

  String _generateUniqueWarpId(MapData map) {
    final existingIds = map.warps.map((warp) => warp.id).toSet();
    if (!existingIds.contains('warp')) return 'warp';
    var index = 1;
    while (existingIds.contains('warp_$index')) {
      index++;
    }
    return 'warp_$index';
  }
}
