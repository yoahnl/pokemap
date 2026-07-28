import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../../domain/models/map_document_persistence.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import '../services/project_map_id_policy.dart';

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
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final updated = updateWarpOnMap(
      map,
      warpId: warpId,
      id: id,
      pos: pos,
      targetMapId: targetMapId,
      targetPos: targetPos,
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
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

  static const ProjectMapIdPolicy _mapIdPolicy = ProjectMapIdPolicy();

  final MapRepository _mapRepo;

  Future<CreateReciprocalWarpResult> execute(
    ProjectWorkspace fs,
    ProjectManifest project, {
    required MapData sourceMap,
    required MapWarp sourceWarp,
  }) async {
    // This workflow can write a map other than the active document. Validate
    // both ends before resolving or loading either file so legacy read-only
    // maps cannot be modified through a reciprocal-warp side door.
    _mapIdPolicy.requireValid(sourceMap.id);
    final targetMapId = _mapIdPolicy.requireValid(sourceWarp.targetMapId);
    final targetMapEntry = project.maps.firstWhere(
      (entry) => entry.id == targetMapId,
      orElse: () => throw EditorNotFoundException(
          'Warp target map not found in project: $targetMapId'),
    );

    final targetIsSourceMap = targetMapEntry.id == sourceMap.id;
    String? targetRevision;
    final MapData targetMap;
    if (targetIsSourceMap) {
      targetMap = sourceMap;
    } else {
      final targetMapPath = fs.resolveMapPath(targetMapEntry.relativePath);
      if (_mapRepo case RevisionedMapRepository revisioned) {
        final document = await revisioned.loadMapDocument(targetMapPath);
        targetMap = document.map;
        targetRevision = document.revision;
      } else {
        targetMap = await _mapRepo.loadMap(targetMapPath);
      }
    }
    _mapIdPolicy.requireValid(targetMap.id);
    if (targetMap.id != targetMapEntry.id) {
      throw EditorValidationException(
        'Loaded map ID "${targetMap.id}" does not match manifest entry '
        '"${targetMapEntry.id}"',
      );
    }

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
      triggerMode: sourceWarp.triggerMode,
      allowedApproachFacings: sourceWarp.allowedApproachFacings
          .map(_oppositeFacing)
          .toList(growable: false),
      triggerPadding: sourceWarp.triggerPadding,
    );
    final updatedTargetMap = addWarpToMap(targetMap, warp: reciprocalWarp);
    MapValidator.validate(updatedTargetMap);

    if (!targetIsSourceMap) {
      final targetMapPath = fs.resolveMapPath(targetMapEntry.relativePath);
      if (_mapRepo case RevisionedMapRepository revisioned) {
        final expectedRevision = targetRevision;
        if (expectedRevision == null) {
          throw const EditorConflictException(
            'The reciprocal-warp target has no durable map revision.',
          );
        }
        await revisioned.saveMapDocument(
          updatedTargetMap,
          targetMapPath,
          precondition: MapDocumentWritePrecondition.revision(expectedRevision),
        );
      } else {
        await _mapRepo.saveMap(updatedTargetMap, targetMapPath);
      }
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

  EntityFacing _oppositeFacing(EntityFacing facing) {
    return switch (facing) {
      EntityFacing.north => EntityFacing.south,
      EntityFacing.south => EntityFacing.north,
      EntityFacing.east => EntityFacing.west,
      EntityFacing.west => EntityFacing.east,
    };
  }
}
