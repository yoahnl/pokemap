import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application/use_cases/project_use_cases.dart';
import 'core_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
CreateProjectUseCase createProjectUseCase(CreateProjectUseCaseRef ref) {
  return CreateProjectUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
LoadProjectUseCase loadProjectUseCase(LoadProjectUseCaseRef ref) {
  return LoadProjectUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectSettingsUseCase updateProjectSettingsUseCase(
    UpdateProjectSettingsUseCaseRef ref) {
  return UpdateProjectSettingsUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ImportProjectTilesetUseCase importProjectTilesetUseCase(
    ImportProjectTilesetUseCaseRef ref) {
  return ImportProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectTilesetUseCase updateProjectTilesetUseCase(
    UpdateProjectTilesetUseCaseRef ref) {
  return UpdateProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ResolveAssignableTilesetsForMapUseCase resolveAssignableTilesetsForMapUseCase(
    ResolveAssignableTilesetsForMapUseCaseRef ref) {
  return ResolveAssignableTilesetsForMapUseCase();
}

@riverpod
AssignTilesetToMapUseCase assignTilesetToMapUseCase(
    AssignTilesetToMapUseCaseRef ref) {
  return AssignTilesetToMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(resolveAssignableTilesetsForMapUseCaseProvider),
  );
}

@riverpod
DeleteProjectTilesetUseCase deleteProjectTilesetUseCase(
    DeleteProjectTilesetUseCaseRef ref) {
  return DeleteProjectTilesetUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(mapRepositoryProvider),
  );
}

@riverpod
ReorderProjectTilesetUseCase reorderProjectTilesetUseCase(
    ReorderProjectTilesetUseCaseRef ref) {
  return ReorderProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateElementCategoryUseCase createElementCategoryUseCase(
    CreateElementCategoryUseCaseRef ref) {
  return CreateElementCategoryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateElementSubcategoryUseCase createElementSubcategoryUseCase(
    CreateElementSubcategoryUseCaseRef ref) {
  return CreateElementSubcategoryUseCase(
    ref.watch(createElementCategoryUseCaseProvider),
  );
}

@riverpod
RenameElementCategoryUseCase renameElementCategoryUseCase(
    RenameElementCategoryUseCaseRef ref) {
  return RenameElementCategoryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetElementGroupUseCase createTilesetElementGroupUseCase(
    CreateTilesetElementGroupUseCaseRef ref) {
  return CreateTilesetElementGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetElementSubgroupUseCase createTilesetElementSubgroupUseCase(
    CreateTilesetElementSubgroupUseCaseRef ref) {
  return CreateTilesetElementSubgroupUseCase(
    ref.watch(createTilesetElementGroupUseCaseProvider),
  );
}

@riverpod
RenameTilesetElementGroupUseCase renameTilesetElementGroupUseCase(
    RenameTilesetElementGroupUseCaseRef ref) {
  return RenameTilesetElementGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateProjectElementUseCase createProjectElementUseCase(
    CreateProjectElementUseCaseRef ref) {
  return CreateProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectElementUseCase updateProjectElementUseCase(
    UpdateProjectElementUseCaseRef ref) {
  return UpdateProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectElementUseCase deleteProjectElementUseCase(
    DeleteProjectElementUseCaseRef ref) {
  return DeleteProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ResolveVisibleProjectElementsUseCase resolveVisibleProjectElementsUseCase(
    ResolveVisibleProjectElementsUseCaseRef ref) {
  return ResolveVisibleProjectElementsUseCase();
}

@riverpod
ResolveTilesetElementsUseCase resolveTilesetElementsUseCase(
    ResolveTilesetElementsUseCaseRef ref) {
  return ResolveTilesetElementsUseCase();
}

@riverpod
UpsertTilesetPaletteEntryUseCase upsertTilesetPaletteEntryUseCase(
    UpsertTilesetPaletteEntryUseCaseRef ref) {
  return UpsertTilesetPaletteEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetPaletteEntryUseCase createTilesetPaletteEntryUseCase(
    CreateTilesetPaletteEntryUseCaseRef ref) {
  return CreateTilesetPaletteEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
PaintTileOnMapUseCase paintTileOnMapUseCase(PaintTileOnMapUseCaseRef ref) {
  return PaintTileOnMapUseCase();
}

@riverpod
PaintTilePatternOnMapUseCase paintTilePatternOnMapUseCase(
    PaintTilePatternOnMapUseCaseRef ref) {
  return PaintTilePatternOnMapUseCase();
}

@riverpod
EraseTileOnMapUseCase eraseTileOnMapUseCase(EraseTileOnMapUseCaseRef ref) {
  return EraseTileOnMapUseCase();
}

@riverpod
EraseTilePatternOnMapUseCase eraseTilePatternOnMapUseCase(
    EraseTilePatternOnMapUseCaseRef ref) {
  return EraseTilePatternOnMapUseCase();
}

@riverpod
PaintCollisionOnMapUseCase paintCollisionOnMapUseCase(
    PaintCollisionOnMapUseCaseRef ref) {
  return PaintCollisionOnMapUseCase();
}

@riverpod
PaintCollisionPatternOnMapUseCase paintCollisionPatternOnMapUseCase(
    PaintCollisionPatternOnMapUseCaseRef ref) {
  return PaintCollisionPatternOnMapUseCase();
}

@riverpod
EraseCollisionOnMapUseCase eraseCollisionOnMapUseCase(
    EraseCollisionOnMapUseCaseRef ref) {
  return EraseCollisionOnMapUseCase();
}

@riverpod
EraseCollisionPatternOnMapUseCase eraseCollisionPatternOnMapUseCase(
    EraseCollisionPatternOnMapUseCaseRef ref) {
  return EraseCollisionPatternOnMapUseCase();
}

@riverpod
PaintTerrainOnMapUseCase paintTerrainOnMapUseCase(
    PaintTerrainOnMapUseCaseRef ref) {
  return PaintTerrainOnMapUseCase();
}

@riverpod
PaintTerrainPatternOnMapUseCase paintTerrainPatternOnMapUseCase(
    PaintTerrainPatternOnMapUseCaseRef ref) {
  return PaintTerrainPatternOnMapUseCase();
}

@riverpod
EraseTerrainOnMapUseCase eraseTerrainOnMapUseCase(
    EraseTerrainOnMapUseCaseRef ref) {
  return EraseTerrainOnMapUseCase();
}

@riverpod
EraseTerrainPatternOnMapUseCase eraseTerrainPatternOnMapUseCase(
    EraseTerrainPatternOnMapUseCaseRef ref) {
  return EraseTerrainPatternOnMapUseCase();
}

@riverpod
AddWarpToMapUseCase addWarpToMapUseCase(AddWarpToMapUseCaseRef ref) {
  return AddWarpToMapUseCase();
}

@riverpod
UpdateWarpOnMapUseCase updateWarpOnMapUseCase(UpdateWarpOnMapUseCaseRef ref) {
  return UpdateWarpOnMapUseCase();
}

@riverpod
DeleteWarpFromMapUseCase deleteWarpFromMapUseCase(
    DeleteWarpFromMapUseCaseRef ref) {
  return DeleteWarpFromMapUseCase();
}

@riverpod
AddMapLayerUseCase addMapLayerUseCase(AddMapLayerUseCaseRef ref) {
  return AddMapLayerUseCase();
}

@riverpod
RenameMapLayerUseCase renameMapLayerUseCase(RenameMapLayerUseCaseRef ref) {
  return RenameMapLayerUseCase();
}

@riverpod
DeleteMapLayerUseCase deleteMapLayerUseCase(DeleteMapLayerUseCaseRef ref) {
  return DeleteMapLayerUseCase();
}

@riverpod
DeleteAllMapLayersUseCase deleteAllMapLayersUseCase(
    DeleteAllMapLayersUseCaseRef ref) {
  return DeleteAllMapLayersUseCase();
}

@riverpod
MoveMapLayerUseCase moveMapLayerUseCase(MoveMapLayerUseCaseRef ref) {
  return MoveMapLayerUseCase();
}

@riverpod
SetMapLayerVisibilityUseCase setMapLayerVisibilityUseCase(
    SetMapLayerVisibilityUseCaseRef ref) {
  return SetMapLayerVisibilityUseCase();
}

@riverpod
SetMapLayerOpacityUseCase setMapLayerOpacityUseCase(
    SetMapLayerOpacityUseCaseRef ref) {
  return SetMapLayerOpacityUseCase();
}

@riverpod
SaveMapUseCase saveMapUseCase(SaveMapUseCaseRef ref) {
  return SaveMapUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
CreateMapUseCase createMapUseCase(CreateMapUseCaseRef ref) {
  return CreateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
LoadMapUseCase loadMapUseCase(LoadMapUseCaseRef ref) {
  return LoadMapUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
ResizeMapUseCase resizeMapUseCase(ResizeMapUseCaseRef ref) {
  return ResizeMapUseCase();
}

@riverpod
RenameMapUseCase renameMapUseCase(RenameMapUseCaseRef ref) {
  return RenameMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeleteMapUseCase deleteMapUseCase(DeleteMapUseCaseRef ref) {
  return DeleteMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DuplicateMapUseCase duplicateMapUseCase(DuplicateMapUseCaseRef ref) {
  return DuplicateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
CreateGroupUseCase createGroupUseCase(CreateGroupUseCaseRef ref) {
  return CreateGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteGroupUseCase deleteGroupUseCase(DeleteGroupUseCaseRef ref) {
  return DeleteGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
MoveMapToGroupUseCase moveMapToGroupUseCase(MoveMapToGroupUseCaseRef ref) {
  return MoveMapToGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
RenameGroupUseCase renameGroupUseCase(RenameGroupUseCaseRef ref) {
  return RenameGroupUseCase(ref.watch(projectRepositoryProvider));
}
