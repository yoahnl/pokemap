import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application/services/editor_map_session_coordinator.dart';
import '../../application/services/editor_map_mutation_coordinator.dart';
import '../../application/services/element_collision_profile_generator.dart';
import '../../application/services/entity_editing_coordinator.dart';
import '../../application/services/entity_editing_service.dart';
import '../../application/services/gameplay_zone_editing_coordinator.dart';
import '../../application/services/gameplay_zone_editing_service.dart';
import '../../application/services/map_history_coordinator.dart';
import '../../application/services/map_connection_editing_service.dart';
import '../../application/services/placed_element_instance_indexer.dart';
import '../../application/services/path_autotile_resolver.dart';
import '../../application/services/path_layer_editing_coordinator.dart';
import '../../application/services/terrain_painting_coordinator.dart';
import '../../application/services/terrain_preset_resolver.dart';
import '../../application/services/terrain_preset_selection_coordinator.dart';
import '../../application/services/trigger_editing_coordinator.dart';
import '../../application/services/trigger_editing_service.dart';
import '../../application/services/warp_editing_coordinator.dart';
import '../../application/services/warp_editing_service.dart';
import '../../application/use_cases/character_use_cases.dart';
import '../../application/use_cases/collision_use_cases.dart';
import '../../application/use_cases/encounter_table_use_cases.dart';
import '../../application/use_cases/trainer_use_cases.dart';
import '../../application/use_cases/entity_use_cases.dart';
import '../../application/use_cases/gameplay_zone_use_cases.dart';
import '../../application/use_cases/layer_use_cases.dart';
import '../../application/use_cases/map_connection_use_cases.dart';
import '../../application/use_cases/map_use_cases.dart';
import '../../application/use_cases/paint_use_cases.dart';
import '../../application/use_cases/path_layer_use_cases.dart';
import '../../application/use_cases/project_element_use_cases.dart';
import '../../application/use_cases/project_group_use_cases.dart';
import '../../application/use_cases/project_management_use_cases.dart';
import '../../application/use_cases/project_tileset_library_use_cases.dart';
import '../../application/use_cases/project_dialogue_use_cases.dart';
import '../../application/use_cases/project_dialogue_library_use_cases.dart';
import '../../application/use_cases/project_script_use_cases.dart';
import '../../application/use_cases/project_tileset_use_cases.dart';
import '../../application/use_cases/terrain_preset_use_cases.dart';
import '../../application/use_cases/terrain_use_cases.dart';
import '../../application/use_cases/trigger_use_cases.dart';
import '../../application/use_cases/warp_use_cases.dart';
import 'core_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
TerrainPresetResolver terrainPresetResolver(TerrainPresetResolverRef ref) {
  return const TerrainPresetResolver();
}

@riverpod
TerrainPresetSelectionCoordinator terrainPresetSelectionCoordinator(
    TerrainPresetSelectionCoordinatorRef ref) {
  return TerrainPresetSelectionCoordinator(
    resolver: ref.watch(terrainPresetResolverProvider),
  );
}

@riverpod
PathAutotileResolver pathAutotileResolver(PathAutotileResolverRef ref) {
  return const PathAutotileResolver();
}

@riverpod
EditorMapSessionCoordinator editorMapSessionCoordinator(
    EditorMapSessionCoordinatorRef ref) {
  return const EditorMapSessionCoordinator();
}

@riverpod
MapHistoryCoordinator mapHistoryCoordinator(MapHistoryCoordinatorRef ref) {
  return const MapHistoryCoordinator(maxEntries: 100);
}

@riverpod
ElementCollisionProfileGenerator elementCollisionProfileGenerator(
    ElementCollisionProfileGeneratorRef ref) {
  return const ElementCollisionProfileGenerator();
}

@riverpod
PlacedElementInstanceIndexer placedElementInstanceIndexer(
    PlacedElementInstanceIndexerRef ref) {
  return const PlacedElementInstanceIndexer();
}

@riverpod
EditorMapMutationCoordinator editorMapMutationCoordinator(
    EditorMapMutationCoordinatorRef ref) {
  return EditorMapMutationCoordinator(
    historyCoordinator: ref.watch(mapHistoryCoordinatorProvider),
    sessionCoordinator: ref.watch(editorMapSessionCoordinatorProvider),
  );
}

@riverpod
WarpEditingCoordinator warpEditingCoordinator(WarpEditingCoordinatorRef ref) {
  return const WarpEditingCoordinator();
}

@riverpod
EntityEditingCoordinator entityEditingCoordinator(
    EntityEditingCoordinatorRef ref) {
  return const EntityEditingCoordinator();
}

@riverpod
TriggerEditingCoordinator triggerEditingCoordinator(
    TriggerEditingCoordinatorRef ref) {
  return const TriggerEditingCoordinator();
}

@riverpod
WarpEditingService warpEditingService(WarpEditingServiceRef ref) {
  return WarpEditingService(
    addWarpToMapUseCase: ref.watch(addWarpToMapUseCaseProvider),
    updateWarpOnMapUseCase: ref.watch(updateWarpOnMapUseCaseProvider),
    deleteWarpFromMapUseCase: ref.watch(deleteWarpFromMapUseCaseProvider),
    validateWarpTargetMapUseCase:
        ref.watch(validateWarpTargetMapUseCaseProvider),
    createReciprocalWarpUseCase: ref.watch(createReciprocalWarpUseCaseProvider),
    warpEditingCoordinator: ref.watch(warpEditingCoordinatorProvider),
  );
}

@riverpod
TriggerEditingService triggerEditingService(TriggerEditingServiceRef ref) {
  return TriggerEditingService(
    addTriggerToMapUseCase: ref.watch(addTriggerToMapUseCaseProvider),
    updateTriggerOnMapUseCase: ref.watch(updateTriggerOnMapUseCaseProvider),
    deleteTriggerFromMapUseCase: ref.watch(deleteTriggerFromMapUseCaseProvider),
    triggerEditingCoordinator: ref.watch(triggerEditingCoordinatorProvider),
  );
}

@riverpod
EntityEditingService entityEditingService(EntityEditingServiceRef ref) {
  return EntityEditingService(
    addEntityToMapUseCase: ref.watch(addEntityToMapUseCaseProvider),
    updateEntityOnMapUseCase: ref.watch(updateEntityOnMapUseCaseProvider),
    deleteEntityFromMapUseCase: ref.watch(deleteEntityFromMapUseCaseProvider),
    entityEditingCoordinator: ref.watch(entityEditingCoordinatorProvider),
  );
}

@riverpod
MapConnectionEditingService mapConnectionEditingService(
    MapConnectionEditingServiceRef ref) {
  return MapConnectionEditingService(
    upsertMapConnectionUseCase: ref.watch(upsertMapConnectionUseCaseProvider),
    deleteMapConnectionUseCase: ref.watch(deleteMapConnectionUseCaseProvider),
    resolveMapConnectionTargetUseCase:
        ref.watch(resolveMapConnectionTargetUseCaseProvider),
  );
}

@riverpod
TerrainPaintingCoordinator terrainPaintingCoordinator(
    TerrainPaintingCoordinatorRef ref) {
  return TerrainPaintingCoordinator(
    paintTerrainOnMapUseCase: ref.watch(paintTerrainOnMapUseCaseProvider),
    paintTerrainPatternOnMapUseCase:
        ref.watch(paintTerrainPatternOnMapUseCaseProvider),
    eraseTerrainOnMapUseCase: ref.watch(eraseTerrainOnMapUseCaseProvider),
    eraseTerrainPatternOnMapUseCase:
        ref.watch(eraseTerrainPatternOnMapUseCaseProvider),
  );
}

@riverpod
PathLayerEditingCoordinator pathLayerEditingCoordinator(
    PathLayerEditingCoordinatorRef ref) {
  return PathLayerEditingCoordinator(
    paintPathOnMapUseCase: ref.watch(paintPathOnMapUseCaseProvider),
    paintPathPatternOnMapUseCase:
        ref.watch(paintPathPatternOnMapUseCaseProvider),
    erasePathOnMapUseCase: ref.watch(erasePathOnMapUseCaseProvider),
    erasePathPatternOnMapUseCase:
        ref.watch(erasePathPatternOnMapUseCaseProvider),
    assignPathPresetToLayerUseCase:
        ref.watch(assignPathPresetToLayerUseCaseProvider),
  );
}

@riverpod
CreateProjectUseCase createProjectUseCase(CreateProjectUseCaseRef ref) {
  return CreateProjectUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(projectWorkspaceFactoryProvider),
  );
}

@riverpod
AddEntityToMapUseCase addEntityToMapUseCase(AddEntityToMapUseCaseRef ref) {
  return AddEntityToMapUseCase();
}

@riverpod
UpdateEntityOnMapUseCase updateEntityOnMapUseCase(
    UpdateEntityOnMapUseCaseRef ref) {
  return UpdateEntityOnMapUseCase();
}

@riverpod
DeleteEntityFromMapUseCase deleteEntityFromMapUseCase(
    DeleteEntityFromMapUseCaseRef ref) {
  return DeleteEntityFromMapUseCase();
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
CreateTilesetLibraryFolderUseCase createTilesetLibraryFolderUseCase(
    CreateTilesetLibraryFolderUseCaseRef ref) {
  return CreateTilesetLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
RenameTilesetLibraryFolderUseCase renameTilesetLibraryFolderUseCase(
    RenameTilesetLibraryFolderUseCaseRef ref) {
  return RenameTilesetLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
MoveTilesetLibraryFolderUseCase moveTilesetLibraryFolderUseCase(
    MoveTilesetLibraryFolderUseCaseRef ref) {
  return MoveTilesetLibraryFolderUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTilesetLibraryFolderUseCase deleteTilesetLibraryFolderUseCase(
    DeleteTilesetLibraryFolderUseCaseRef ref) {
  return DeleteTilesetLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
AssignTilesetToLibraryFolderUseCase assignTilesetToLibraryFolderUseCase(
    AssignTilesetToLibraryFolderUseCaseRef ref) {
  return AssignTilesetToLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
MoveTilesetToLibraryRootUseCase moveTilesetToLibraryRootUseCase(
    MoveTilesetToLibraryRootUseCaseRef ref) {
  return MoveTilesetToLibraryRootUseCase(ref.watch(projectRepositoryProvider));
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
CreateTerrainPresetUseCase createTerrainPresetUseCase(
    CreateTerrainPresetUseCaseRef ref) {
  return CreateTerrainPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTerrainPresetUseCase updateTerrainPresetUseCase(
    UpdateTerrainPresetUseCaseRef ref) {
  return UpdateTerrainPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTerrainPresetUseCase deleteTerrainPresetUseCase(
    DeleteTerrainPresetUseCaseRef ref) {
  return DeleteTerrainPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreatePathPresetUseCase createPathPresetUseCase(
    CreatePathPresetUseCaseRef ref) {
  return CreatePathPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdatePathPresetUseCase updatePathPresetUseCase(
    UpdatePathPresetUseCaseRef ref) {
  return UpdatePathPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeletePathPresetUseCase deletePathPresetUseCase(
    DeletePathPresetUseCaseRef ref) {
  return DeletePathPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreatePresetCategoryUseCase createPresetCategoryUseCase(
    CreatePresetCategoryUseCaseRef ref) {
  return CreatePresetCategoryUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
RenamePresetCategoryUseCase renamePresetCategoryUseCase(
    RenamePresetCategoryUseCaseRef ref) {
  return RenamePresetCategoryUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeletePresetCategoryUseCase deletePresetCategoryUseCase(
    DeletePresetCategoryUseCaseRef ref) {
  return DeletePresetCategoryUseCase(
    ref.watch(projectRepositoryProvider),
  );
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
PaintPathOnMapUseCase paintPathOnMapUseCase(PaintPathOnMapUseCaseRef ref) {
  return PaintPathOnMapUseCase();
}

@riverpod
PaintPathPatternOnMapUseCase paintPathPatternOnMapUseCase(
    PaintPathPatternOnMapUseCaseRef ref) {
  return PaintPathPatternOnMapUseCase();
}

@riverpod
ErasePathOnMapUseCase erasePathOnMapUseCase(ErasePathOnMapUseCaseRef ref) {
  return ErasePathOnMapUseCase();
}

@riverpod
ErasePathPatternOnMapUseCase erasePathPatternOnMapUseCase(
    ErasePathPatternOnMapUseCaseRef ref) {
  return ErasePathPatternOnMapUseCase();
}

@riverpod
AssignPathPresetToLayerUseCase assignPathPresetToLayerUseCase(
    AssignPathPresetToLayerUseCaseRef ref) {
  return AssignPathPresetToLayerUseCase();
}

@riverpod
SetPathLayerPropertiesUseCase setPathLayerPropertiesUseCase(
    SetPathLayerPropertiesUseCaseRef ref) {
  return SetPathLayerPropertiesUseCase();
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
AddTriggerToMapUseCase addTriggerToMapUseCase(AddTriggerToMapUseCaseRef ref) {
  return AddTriggerToMapUseCase();
}

@riverpod
UpdateTriggerOnMapUseCase updateTriggerOnMapUseCase(
    UpdateTriggerOnMapUseCaseRef ref) {
  return UpdateTriggerOnMapUseCase();
}

@riverpod
DeleteTriggerFromMapUseCase deleteTriggerFromMapUseCase(
    DeleteTriggerFromMapUseCaseRef ref) {
  return DeleteTriggerFromMapUseCase();
}

@riverpod
ResolveMapConnectionTargetUseCase resolveMapConnectionTargetUseCase(
    ResolveMapConnectionTargetUseCaseRef ref) {
  return ResolveMapConnectionTargetUseCase();
}

@riverpod
UpsertMapConnectionUseCase upsertMapConnectionUseCase(
    UpsertMapConnectionUseCaseRef ref) {
  return UpsertMapConnectionUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(resolveMapConnectionTargetUseCaseProvider),
  );
}

@riverpod
DeleteMapConnectionUseCase deleteMapConnectionUseCase(
    DeleteMapConnectionUseCaseRef ref) {
  return DeleteMapConnectionUseCase();
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
ValidateWarpTargetMapUseCase validateWarpTargetMapUseCase(
    ValidateWarpTargetMapUseCaseRef ref) {
  return ValidateWarpTargetMapUseCase();
}

@riverpod
CreateReciprocalWarpUseCase createReciprocalWarpUseCase(
    CreateReciprocalWarpUseCaseRef ref) {
  return CreateReciprocalWarpUseCase(ref.watch(mapRepositoryProvider));
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
ReorderMapLayersUseCase reorderMapLayersUseCase(
    ReorderMapLayersUseCaseRef ref) {
  return ReorderMapLayersUseCase();
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
UpdateMapMetadataUseCase updateMapMetadataUseCase(
    UpdateMapMetadataUseCaseRef ref) {
  return UpdateMapMetadataUseCase();
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

// ---------------------------------------------------------------------------
// Gameplay zones
// ---------------------------------------------------------------------------

@riverpod
GameplayZoneEditingCoordinator gameplayZoneEditingCoordinator(
    GameplayZoneEditingCoordinatorRef ref) {
  return const GameplayZoneEditingCoordinator();
}

@riverpod
AddGameplayZoneToMapUseCase addGameplayZoneToMapUseCase(
    AddGameplayZoneToMapUseCaseRef ref) {
  return AddGameplayZoneToMapUseCase();
}

@riverpod
UpdateGameplayZoneOnMapUseCase updateGameplayZoneOnMapUseCase(
    UpdateGameplayZoneOnMapUseCaseRef ref) {
  return UpdateGameplayZoneOnMapUseCase();
}

@riverpod
DeleteGameplayZoneFromMapUseCase deleteGameplayZoneFromMapUseCase(
    DeleteGameplayZoneFromMapUseCaseRef ref) {
  return DeleteGameplayZoneFromMapUseCase();
}

@riverpod
GameplayZoneEditingService gameplayZoneEditingService(
    GameplayZoneEditingServiceRef ref) {
  return GameplayZoneEditingService(
    addGameplayZoneToMapUseCase: ref.watch(addGameplayZoneToMapUseCaseProvider),
    updateGameplayZoneOnMapUseCase:
        ref.watch(updateGameplayZoneOnMapUseCaseProvider),
    deleteGameplayZoneFromMapUseCase:
        ref.watch(deleteGameplayZoneFromMapUseCaseProvider),
    coordinator: ref.watch(gameplayZoneEditingCoordinatorProvider),
  );
}

// ---------------------------------------------------------------------------
// Project dialogues
// ---------------------------------------------------------------------------

@riverpod
CreateProjectDialogueUseCase createProjectDialogueUseCase(
    CreateProjectDialogueUseCaseRef ref) {
  return CreateProjectDialogueUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ImportProjectDialogueUseCase importProjectDialogueUseCase(
    ImportProjectDialogueUseCaseRef ref) {
  return ImportProjectDialogueUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectDialogueUseCase updateProjectDialogueUseCase(
    UpdateProjectDialogueUseCaseRef ref) {
  return UpdateProjectDialogueUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectDialogueUseCase deleteProjectDialogueUseCase(
    DeleteProjectDialogueUseCaseRef ref) {
  return DeleteProjectDialogueUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(mapRepositoryProvider),
  );
}

@riverpod
CreateDialogueLibraryFolderUseCase createDialogueLibraryFolderUseCase(
    CreateDialogueLibraryFolderUseCaseRef ref) {
  return CreateDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
RenameDialogueLibraryFolderUseCase renameDialogueLibraryFolderUseCase(
    RenameDialogueLibraryFolderUseCaseRef ref) {
  return RenameDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
MoveDialogueLibraryFolderUseCase moveDialogueLibraryFolderUseCase(
    MoveDialogueLibraryFolderUseCaseRef ref) {
  return MoveDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeleteDialogueLibraryFolderUseCase deleteDialogueLibraryFolderUseCase(
    DeleteDialogueLibraryFolderUseCaseRef ref) {
  return DeleteDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
AssignDialogueToLibraryFolderUseCase assignDialogueToLibraryFolderUseCase(
    AssignDialogueToLibraryFolderUseCaseRef ref) {
  return AssignDialogueToLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
MoveDialogueToLibraryRootUseCase moveDialogueToLibraryRootUseCase(
    MoveDialogueToLibraryRootUseCaseRef ref) {
  return MoveDialogueToLibraryRootUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

// ---------------------------------------------------------------------------
// Project scenario scripts
// ---------------------------------------------------------------------------

@riverpod
CreateProjectScriptUseCase createProjectScriptUseCase(
    CreateProjectScriptUseCaseRef ref) {
  return CreateProjectScriptUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
RenameProjectScriptUseCase renameProjectScriptUseCase(
    RenameProjectScriptUseCaseRef ref) {
  return RenameProjectScriptUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectScriptUseCase deleteProjectScriptUseCase(
    DeleteProjectScriptUseCaseRef ref) {
  return DeleteProjectScriptUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(mapRepositoryProvider),
  );
}

@riverpod
SetProjectScriptDefaultStartNodeUseCase setProjectScriptDefaultStartNodeUseCase(
    SetProjectScriptDefaultStartNodeUseCaseRef ref) {
  return SetProjectScriptDefaultStartNodeUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
AddProjectScriptNodeUseCase addProjectScriptNodeUseCase(
    AddProjectScriptNodeUseCaseRef ref) {
  return AddProjectScriptNodeUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
RenameProjectScriptNodeUseCase renameProjectScriptNodeUseCase(
    RenameProjectScriptNodeUseCaseRef ref) {
  return RenameProjectScriptNodeUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectScriptNodeUseCase deleteProjectScriptNodeUseCase(
    DeleteProjectScriptNodeUseCaseRef ref) {
  return DeleteProjectScriptNodeUseCase(ref.watch(projectRepositoryProvider));
}

// ---------------------------------------------------------------------------
// Encounter tables
// ---------------------------------------------------------------------------

@riverpod
CreateEncounterTableUseCase createEncounterTableUseCase(
    CreateEncounterTableUseCaseRef ref) {
  return CreateEncounterTableUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateEncounterTableUseCase updateEncounterTableUseCase(
    UpdateEncounterTableUseCaseRef ref) {
  return UpdateEncounterTableUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteEncounterTableUseCase deleteEncounterTableUseCase(
    DeleteEncounterTableUseCaseRef ref) {
  return DeleteEncounterTableUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
AddEncounterEntryUseCase addEncounterEntryUseCase(
    AddEncounterEntryUseCaseRef ref) {
  return AddEncounterEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateEncounterEntryUseCase updateEncounterEntryUseCase(
    UpdateEncounterEntryUseCaseRef ref) {
  return UpdateEncounterEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteEncounterEntryUseCase deleteEncounterEntryUseCase(
    DeleteEncounterEntryUseCaseRef ref) {
  return DeleteEncounterEntryUseCase(ref.watch(projectRepositoryProvider));
}

// ---------------------------------------------------------------------------
// Trainers
// ---------------------------------------------------------------------------

@riverpod
CreateTrainerUseCase createTrainerUseCase(CreateTrainerUseCaseRef ref) {
  return CreateTrainerUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTrainerUseCase updateTrainerUseCase(UpdateTrainerUseCaseRef ref) {
  return UpdateTrainerUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTrainerUseCase deleteTrainerUseCase(DeleteTrainerUseCaseRef ref) {
  return DeleteTrainerUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
AddTrainerPokemonUseCase addTrainerPokemonUseCase(
    AddTrainerPokemonUseCaseRef ref) {
  return AddTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTrainerPokemonUseCase updateTrainerPokemonUseCase(
    UpdateTrainerPokemonUseCaseRef ref) {
  return UpdateTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTrainerPokemonUseCase deleteTrainerPokemonUseCase(
    DeleteTrainerPokemonUseCaseRef ref) {
  return DeleteTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

// ---------------------------------------------------------------------------
// Characters
// ---------------------------------------------------------------------------

@riverpod
CreateCharacterUseCase createCharacterUseCase(CreateCharacterUseCaseRef ref) {
  return CreateCharacterUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateCharacterUseCase updateCharacterUseCase(UpdateCharacterUseCaseRef ref) {
  return UpdateCharacterUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteCharacterUseCase deleteCharacterUseCase(DeleteCharacterUseCaseRef ref) {
  return DeleteCharacterUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpsertCharacterAnimationUseCase upsertCharacterAnimationUseCase(
    UpsertCharacterAnimationUseCaseRef ref) {
  return UpsertCharacterAnimationUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
SetPlayerCharacterUseCase setPlayerCharacterUseCase(
    SetPlayerCharacterUseCaseRef ref) {
  return SetPlayerCharacterUseCase(ref.watch(projectRepositoryProvider));
}
