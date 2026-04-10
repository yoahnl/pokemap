import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/use_cases/collision_use_cases.dart';
import '../../../application/use_cases/entity_use_cases.dart';
import '../../../application/use_cases/gameplay_zone_use_cases.dart';
import '../../../application/use_cases/layer_use_cases.dart';
import '../../../application/use_cases/map_connection_use_cases.dart';
import '../../../application/use_cases/map_use_cases.dart';
import '../../../application/use_cases/paint_use_cases.dart';
import '../../../application/use_cases/path_layer_use_cases.dart';
import '../../../application/use_cases/project_tileset_use_cases.dart';
import '../../../application/use_cases/terrain_use_cases.dart';
import '../../../application/use_cases/trigger_use_cases.dart';
import '../../../application/use_cases/warp_use_cases.dart';
import '../core/repository_providers.dart';
import 'project_use_case_providers.dart';

part 'map_use_case_providers.g.dart';

/// Providers centrés sur le document map et ses mutations.
///
/// On sépare ici les use cases de document/mutation des bibliothèques projet
/// afin que la composition root reste navigable.
@riverpod
AddEntityToMapUseCase addEntityToMapUseCase(Ref ref) {
  return AddEntityToMapUseCase();
}

@riverpod
UpdateEntityOnMapUseCase updateEntityOnMapUseCase(
    Ref ref) {
  return UpdateEntityOnMapUseCase();
}

@riverpod
DeleteEntityFromMapUseCase deleteEntityFromMapUseCase(
    Ref ref) {
  return DeleteEntityFromMapUseCase();
}

@riverpod
AssignTilesetToMapUseCase assignTilesetToMapUseCase(
    Ref ref) {
  return AssignTilesetToMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(resolveAssignableTilesetsForMapUseCaseProvider),
  );
}

@riverpod
PaintTileOnMapUseCase paintTileOnMapUseCase(Ref ref) {
  return PaintTileOnMapUseCase();
}

@riverpod
PaintTilePatternOnMapUseCase paintTilePatternOnMapUseCase(
    Ref ref) {
  return PaintTilePatternOnMapUseCase();
}

@riverpod
EraseTileOnMapUseCase eraseTileOnMapUseCase(Ref ref) {
  return EraseTileOnMapUseCase();
}

@riverpod
EraseTilePatternOnMapUseCase eraseTilePatternOnMapUseCase(
    Ref ref) {
  return EraseTilePatternOnMapUseCase();
}

@riverpod
PaintCollisionOnMapUseCase paintCollisionOnMapUseCase(
    Ref ref) {
  return PaintCollisionOnMapUseCase();
}

@riverpod
PaintCollisionPatternOnMapUseCase paintCollisionPatternOnMapUseCase(
    Ref ref) {
  return PaintCollisionPatternOnMapUseCase();
}

@riverpod
EraseCollisionOnMapUseCase eraseCollisionOnMapUseCase(
    Ref ref) {
  return EraseCollisionOnMapUseCase();
}

@riverpod
EraseCollisionPatternOnMapUseCase eraseCollisionPatternOnMapUseCase(
    Ref ref) {
  return EraseCollisionPatternOnMapUseCase();
}

@riverpod
PaintTerrainOnMapUseCase paintTerrainOnMapUseCase(
    Ref ref) {
  return PaintTerrainOnMapUseCase();
}

@riverpod
PaintPathOnMapUseCase paintPathOnMapUseCase(Ref ref) {
  return PaintPathOnMapUseCase();
}

@riverpod
PaintPathPatternOnMapUseCase paintPathPatternOnMapUseCase(
    Ref ref) {
  return PaintPathPatternOnMapUseCase();
}

@riverpod
ErasePathOnMapUseCase erasePathOnMapUseCase(Ref ref) {
  return ErasePathOnMapUseCase();
}

@riverpod
ErasePathPatternOnMapUseCase erasePathPatternOnMapUseCase(
    Ref ref) {
  return ErasePathPatternOnMapUseCase();
}

@riverpod
AssignPathPresetToLayerUseCase assignPathPresetToLayerUseCase(
    Ref ref) {
  return AssignPathPresetToLayerUseCase();
}

@riverpod
SetPathLayerPropertiesUseCase setPathLayerPropertiesUseCase(
    Ref ref) {
  return SetPathLayerPropertiesUseCase();
}

@riverpod
PaintTerrainPatternOnMapUseCase paintTerrainPatternOnMapUseCase(
    Ref ref) {
  return PaintTerrainPatternOnMapUseCase();
}

@riverpod
EraseTerrainOnMapUseCase eraseTerrainOnMapUseCase(
    Ref ref) {
  return EraseTerrainOnMapUseCase();
}

@riverpod
EraseTerrainPatternOnMapUseCase eraseTerrainPatternOnMapUseCase(
    Ref ref) {
  return EraseTerrainPatternOnMapUseCase();
}

@riverpod
AddWarpToMapUseCase addWarpToMapUseCase(Ref ref) {
  return AddWarpToMapUseCase();
}

@riverpod
AddTriggerToMapUseCase addTriggerToMapUseCase(Ref ref) {
  return AddTriggerToMapUseCase();
}

@riverpod
UpdateTriggerOnMapUseCase updateTriggerOnMapUseCase(
    Ref ref) {
  return UpdateTriggerOnMapUseCase();
}

@riverpod
DeleteTriggerFromMapUseCase deleteTriggerFromMapUseCase(
    Ref ref) {
  return DeleteTriggerFromMapUseCase();
}

@riverpod
ResolveMapConnectionTargetUseCase resolveMapConnectionTargetUseCase(
    Ref ref) {
  return ResolveMapConnectionTargetUseCase();
}

@riverpod
UpsertMapConnectionUseCase upsertMapConnectionUseCase(
    Ref ref) {
  return UpsertMapConnectionUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(resolveMapConnectionTargetUseCaseProvider),
  );
}

@riverpod
DeleteMapConnectionUseCase deleteMapConnectionUseCase(
    Ref ref) {
  return DeleteMapConnectionUseCase();
}

@riverpod
UpdateWarpOnMapUseCase updateWarpOnMapUseCase(Ref ref) {
  return UpdateWarpOnMapUseCase();
}

@riverpod
DeleteWarpFromMapUseCase deleteWarpFromMapUseCase(
    Ref ref) {
  return DeleteWarpFromMapUseCase();
}

@riverpod
ValidateWarpTargetMapUseCase validateWarpTargetMapUseCase(
    Ref ref) {
  return ValidateWarpTargetMapUseCase();
}

@riverpod
CreateReciprocalWarpUseCase createReciprocalWarpUseCase(
    Ref ref) {
  return CreateReciprocalWarpUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
AddMapLayerUseCase addMapLayerUseCase(Ref ref) {
  return AddMapLayerUseCase();
}

@riverpod
RenameMapLayerUseCase renameMapLayerUseCase(Ref ref) {
  return RenameMapLayerUseCase();
}

@riverpod
DeleteMapLayerUseCase deleteMapLayerUseCase(Ref ref) {
  return DeleteMapLayerUseCase();
}

@riverpod
DeleteAllMapLayersUseCase deleteAllMapLayersUseCase(
    Ref ref) {
  return DeleteAllMapLayersUseCase();
}

@riverpod
MoveMapLayerUseCase moveMapLayerUseCase(Ref ref) {
  return MoveMapLayerUseCase();
}

@riverpod
ReorderMapLayersUseCase reorderMapLayersUseCase(
    Ref ref) {
  return ReorderMapLayersUseCase();
}

@riverpod
SetMapLayerVisibilityUseCase setMapLayerVisibilityUseCase(
    Ref ref) {
  return SetMapLayerVisibilityUseCase();
}

@riverpod
SetMapLayerOpacityUseCase setMapLayerOpacityUseCase(
    Ref ref) {
  return SetMapLayerOpacityUseCase();
}

@riverpod
SaveMapUseCase saveMapUseCase(Ref ref) {
  return SaveMapUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
CreateMapUseCase createMapUseCase(Ref ref) {
  return CreateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
LoadMapUseCase loadMapUseCase(Ref ref) {
  return LoadMapUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
ResizeMapUseCase resizeMapUseCase(Ref ref) {
  return ResizeMapUseCase();
}

@riverpod
UpdateMapMetadataUseCase updateMapMetadataUseCase(
    Ref ref) {
  return UpdateMapMetadataUseCase();
}

@riverpod
RenameMapUseCase renameMapUseCase(Ref ref) {
  return RenameMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeleteMapUseCase deleteMapUseCase(Ref ref) {
  return DeleteMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DuplicateMapUseCase duplicateMapUseCase(Ref ref) {
  return DuplicateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
AddGameplayZoneToMapUseCase addGameplayZoneToMapUseCase(
    Ref ref) {
  return AddGameplayZoneToMapUseCase();
}

@riverpod
UpdateGameplayZoneOnMapUseCase updateGameplayZoneOnMapUseCase(
    Ref ref) {
  return UpdateGameplayZoneOnMapUseCase();
}

@riverpod
DeleteGameplayZoneFromMapUseCase deleteGameplayZoneFromMapUseCase(
    Ref ref) {
  return DeleteGameplayZoneFromMapUseCase();
}
