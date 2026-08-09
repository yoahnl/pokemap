import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/services/map_dependency_preflight_service.dart';
import '../../../application/use_cases/collision_use_cases.dart';
import '../../../application/use_cases/entity_use_cases.dart';
import '../../../application/use_cases/gameplay_zone_use_cases.dart';
import '../../../application/use_cases/layer_use_cases.dart';
import '../../../application/use_cases/map_connection_use_cases.dart';
import '../../../application/use_cases/map_use_cases.dart';
import '../../../application/use_cases/paint_use_cases.dart';
import '../../../application/use_cases/project_tileset_use_cases.dart';
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
UpdateEntityOnMapUseCase updateEntityOnMapUseCase(Ref ref) {
  return UpdateEntityOnMapUseCase();
}

@riverpod
DeleteEntityFromMapUseCase deleteEntityFromMapUseCase(Ref ref) {
  return DeleteEntityFromMapUseCase();
}

@riverpod
AssignTilesetToMapUseCase assignTilesetToMapUseCase(Ref ref) {
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
PaintTilePatternOnMapUseCase paintTilePatternOnMapUseCase(Ref ref) {
  return PaintTilePatternOnMapUseCase();
}

@riverpod
EraseTileOnMapUseCase eraseTileOnMapUseCase(Ref ref) {
  return EraseTileOnMapUseCase();
}

@riverpod
EraseTilePatternOnMapUseCase eraseTilePatternOnMapUseCase(Ref ref) {
  return EraseTilePatternOnMapUseCase();
}

@riverpod
PaintCollisionOnMapUseCase paintCollisionOnMapUseCase(Ref ref) {
  return PaintCollisionOnMapUseCase();
}

@riverpod
PaintCollisionPatternOnMapUseCase paintCollisionPatternOnMapUseCase(Ref ref) {
  return PaintCollisionPatternOnMapUseCase();
}

@riverpod
EraseCollisionOnMapUseCase eraseCollisionOnMapUseCase(Ref ref) {
  return EraseCollisionOnMapUseCase();
}

@riverpod
EraseCollisionPatternOnMapUseCase eraseCollisionPatternOnMapUseCase(Ref ref) {
  return EraseCollisionPatternOnMapUseCase();
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
UpdateTriggerOnMapUseCase updateTriggerOnMapUseCase(Ref ref) {
  return UpdateTriggerOnMapUseCase();
}

@riverpod
DeleteTriggerFromMapUseCase deleteTriggerFromMapUseCase(Ref ref) {
  return DeleteTriggerFromMapUseCase();
}

@riverpod
ResolveMapConnectionTargetUseCase resolveMapConnectionTargetUseCase(Ref ref) {
  return ResolveMapConnectionTargetUseCase();
}

@riverpod
UpdateWarpOnMapUseCase updateWarpOnMapUseCase(Ref ref) {
  return UpdateWarpOnMapUseCase();
}

@riverpod
DeleteWarpFromMapUseCase deleteWarpFromMapUseCase(Ref ref) {
  return DeleteWarpFromMapUseCase();
}

@riverpod
ValidateWarpTargetMapUseCase validateWarpTargetMapUseCase(Ref ref) {
  return ValidateWarpTargetMapUseCase();
}

@riverpod
CreateReciprocalWarpUseCase createReciprocalWarpUseCase(Ref ref) {
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
DeleteAllMapLayersUseCase deleteAllMapLayersUseCase(Ref ref) {
  return DeleteAllMapLayersUseCase();
}

@riverpod
MoveMapLayerUseCase moveMapLayerUseCase(Ref ref) {
  return MoveMapLayerUseCase();
}

@riverpod
ReorderMapLayersUseCase reorderMapLayersUseCase(Ref ref) {
  return ReorderMapLayersUseCase();
}

@riverpod
SetMapLayerVisibilityUseCase setMapLayerVisibilityUseCase(Ref ref) {
  return SetMapLayerVisibilityUseCase();
}

@riverpod
SetMapLayerOpacityUseCase setMapLayerOpacityUseCase(Ref ref) {
  return SetMapLayerOpacityUseCase();
}

@riverpod
SaveMapUseCase saveMapUseCase(Ref ref) {
  return SaveMapUseCase(
    ref.watch(mapRepositoryProvider),
    authoringMutations: ref.watch(authoringMutationAdapterProvider),
  );
}

@riverpod
CreateMapUseCase createMapUseCase(Ref ref) {
  return CreateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
    lifecycleTransactions:
        ref.watch(mapLifecycleTransactionCoordinatorProvider),
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
UpdateMapMetadataUseCase updateMapMetadataUseCase(Ref ref) {
  return UpdateMapMetadataUseCase();
}

@riverpod
RenameMapUseCase renameMapUseCase(Ref ref) {
  final mapRepository = ref.watch(mapRepositoryProvider);
  return RenameMapUseCase(
    mapRepository,
    ref.watch(projectRepositoryProvider),
    MapDependencyPreflightService(mapRepository: mapRepository),
    lifecycleTransactions:
        ref.watch(mapLifecycleTransactionCoordinatorProvider),
  );
}

@riverpod
DeleteMapUseCase deleteMapUseCase(Ref ref) {
  final mapRepository = ref.watch(mapRepositoryProvider);
  return DeleteMapUseCase(
    mapRepository,
    ref.watch(projectRepositoryProvider),
    MapDependencyPreflightService(mapRepository: mapRepository),
    lifecycleTransactions:
        ref.watch(mapLifecycleTransactionCoordinatorProvider),
  );
}

@riverpod
DuplicateMapUseCase duplicateMapUseCase(Ref ref) {
  return DuplicateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
    lifecycleTransactions:
        ref.watch(mapLifecycleTransactionCoordinatorProvider),
  );
}

@riverpod
AddGameplayZoneToMapUseCase addGameplayZoneToMapUseCase(Ref ref) {
  return AddGameplayZoneToMapUseCase();
}

@riverpod
UpdateGameplayZoneOnMapUseCase updateGameplayZoneOnMapUseCase(Ref ref) {
  return UpdateGameplayZoneOnMapUseCase();
}

@riverpod
DeleteGameplayZoneFromMapUseCase deleteGameplayZoneFromMapUseCase(Ref ref) {
  return DeleteGameplayZoneFromMapUseCase();
}
