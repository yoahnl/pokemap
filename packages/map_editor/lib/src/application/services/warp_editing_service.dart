import 'package:map_core/map_core.dart';

import '../../infrastructure/filesystem/project_filesystem.dart';
import '../use_cases/project_use_cases.dart';
import 'warp_editing_coordinator.dart';

class WarpCreationResult {
  const WarpCreationResult({
    required this.updatedMap,
    required this.createdWarp,
  });

  final MapData updatedMap;
  final MapWarp createdWarp;
}

class WarpUpdateResult {
  const WarpUpdateResult({
    required this.updatedMap,
    required this.selectedWarpId,
  });

  final MapData updatedMap;
  final String selectedWarpId;
}

class WarpEditingService {
  const WarpEditingService({
    required AddWarpToMapUseCase addWarpToMapUseCase,
    required UpdateWarpOnMapUseCase updateWarpOnMapUseCase,
    required DeleteWarpFromMapUseCase deleteWarpFromMapUseCase,
    required ValidateWarpTargetMapUseCase validateWarpTargetMapUseCase,
    required CreateReciprocalWarpUseCase createReciprocalWarpUseCase,
    required WarpEditingCoordinator warpEditingCoordinator,
  })  : _addWarpToMapUseCase = addWarpToMapUseCase,
        _updateWarpOnMapUseCase = updateWarpOnMapUseCase,
        _deleteWarpFromMapUseCase = deleteWarpFromMapUseCase,
        _validateWarpTargetMapUseCase = validateWarpTargetMapUseCase,
        _createReciprocalWarpUseCase = createReciprocalWarpUseCase,
        _warpEditingCoordinator = warpEditingCoordinator;

  final AddWarpToMapUseCase _addWarpToMapUseCase;
  final UpdateWarpOnMapUseCase _updateWarpOnMapUseCase;
  final DeleteWarpFromMapUseCase _deleteWarpFromMapUseCase;
  final ValidateWarpTargetMapUseCase _validateWarpTargetMapUseCase;
  final CreateReciprocalWarpUseCase _createReciprocalWarpUseCase;
  final WarpEditingCoordinator _warpEditingCoordinator;

  MapWarp? findSelectedWarp(
    MapData? map,
    String? selectedWarpId,
  ) {
    if (map == null || selectedWarpId == null) return null;
    return _warpEditingCoordinator.findWarpById(map, selectedWarpId);
  }

  MapWarp? findWarpAtPos(
    MapData map,
    GridPos pos,
  ) {
    return _warpEditingCoordinator.findWarpAtPos(map, pos);
  }

  MapWarp requireSelectedWarp(
    MapData map,
    String? selectedWarpId,
  ) {
    if (selectedWarpId == null || selectedWarpId.trim().isEmpty) {
      throw const ValidationException('No warp selected');
    }
    final warp = _warpEditingCoordinator.findWarpById(map, selectedWarpId);
    if (warp == null) {
      throw ValidationException('Selected warp not found: $selectedWarpId');
    }
    return warp;
  }

  WarpCreationResult addWarpAt(
    MapData map,
    ProjectManifest project,
    GridPos pos,
  ) {
    final warp = _warpEditingCoordinator.createDefaultWarp(map, pos);
    _validateWarpTargetMapUseCase.execute(project, warp.targetMapId);
    final updated = _addWarpToMapUseCase.execute(map, warp: warp);
    return WarpCreationResult(
      updatedMap: updated,
      createdWarp: warp,
    );
  }

  WarpUpdateResult updateWarp(
    MapData map,
    ProjectManifest project, {
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
  }) {
    final currentWarp = _warpEditingCoordinator.findWarpById(map, warpId);
    final effectiveTargetMapId = targetMapId ?? currentWarp?.targetMapId;
    if (effectiveTargetMapId == null || effectiveTargetMapId.trim().isEmpty) {
      throw const ValidationException('Warp target map cannot be empty');
    }
    _validateWarpTargetMapUseCase.execute(project, effectiveTargetMapId);
    final updated = _updateWarpOnMapUseCase.execute(
      map,
      warpId: warpId,
      id: id,
      pos: pos,
      targetMapId: targetMapId?.trim(),
      targetPos: targetPos,
    );
    final nextSelectedWarpId =
        id?.trim().isNotEmpty == true ? id!.trim() : warpId;
    return WarpUpdateResult(
      updatedMap: updated,
      selectedWarpId: nextSelectedWarpId,
    );
  }

  MapData deleteWarp(
    MapData map, {
    required String warpId,
  }) {
    return _deleteWarpFromMapUseCase.execute(
      map,
      warpId: warpId,
    );
  }

  Future<CreateReciprocalWarpResult> createReciprocalWarp(
    ProjectFileSystem fs,
    ProjectManifest project, {
    required MapData sourceMap,
    required MapWarp sourceWarp,
  }) {
    return _createReciprocalWarpUseCase.execute(
      fs,
      project,
      sourceMap: sourceMap,
      sourceWarp: sourceWarp,
    );
  }
}
