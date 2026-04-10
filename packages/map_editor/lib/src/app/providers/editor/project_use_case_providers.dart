import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/use_cases/character_use_cases.dart';
import '../../../application/use_cases/encounter_table_use_cases.dart';
import '../../../application/use_cases/project_element_use_cases.dart';
import '../../../application/use_cases/project_group_use_cases.dart';
import '../../../application/use_cases/project_management_use_cases.dart';
import '../../../application/use_cases/project_tileset_library_use_cases.dart';
import '../../../application/use_cases/project_tileset_use_cases.dart';
import '../../../application/use_cases/terrain_preset_use_cases.dart';
import '../../../application/use_cases/trainer_use_cases.dart';
import '../core/repository_providers.dart';

part 'project_use_case_providers.g.dart';

/// Providers centrés sur la gestion de projet et de ses bibliothèques.
///
/// Ils dépendent surtout des repositories projet/map, sans embarquer
/// l'orchestration plus haute qui vit ailleurs.
@riverpod
CreateProjectUseCase createProjectUseCase(Ref ref) {
  return CreateProjectUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(projectWorkspaceFactoryProvider),
  );
}

@riverpod
LoadProjectUseCase loadProjectUseCase(Ref ref) {
  return LoadProjectUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectSettingsUseCase updateProjectSettingsUseCase(
    Ref ref) {
  return UpdateProjectSettingsUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ImportProjectTilesetUseCase importProjectTilesetUseCase(
    Ref ref) {
  return ImportProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectTilesetUseCase updateProjectTilesetUseCase(
    Ref ref) {
  return UpdateProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ResolveAssignableTilesetsForMapUseCase resolveAssignableTilesetsForMapUseCase(
    Ref ref) {
  return ResolveAssignableTilesetsForMapUseCase();
}

@riverpod
DeleteProjectTilesetUseCase deleteProjectTilesetUseCase(
    Ref ref) {
  return DeleteProjectTilesetUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(mapRepositoryProvider),
  );
}

@riverpod
ReorderProjectTilesetUseCase reorderProjectTilesetUseCase(
    Ref ref) {
  return ReorderProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetLibraryFolderUseCase createTilesetLibraryFolderUseCase(
    Ref ref) {
  return CreateTilesetLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
RenameTilesetLibraryFolderUseCase renameTilesetLibraryFolderUseCase(
    Ref ref) {
  return RenameTilesetLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
MoveTilesetLibraryFolderUseCase moveTilesetLibraryFolderUseCase(
    Ref ref) {
  return MoveTilesetLibraryFolderUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTilesetLibraryFolderUseCase deleteTilesetLibraryFolderUseCase(
    Ref ref) {
  return DeleteTilesetLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
AssignTilesetToLibraryFolderUseCase assignTilesetToLibraryFolderUseCase(
    Ref ref) {
  return AssignTilesetToLibraryFolderUseCase(
      ref.watch(projectRepositoryProvider));
}

@riverpod
MoveTilesetToLibraryRootUseCase moveTilesetToLibraryRootUseCase(
    Ref ref) {
  return MoveTilesetToLibraryRootUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateElementCategoryUseCase createElementCategoryUseCase(
    Ref ref) {
  return CreateElementCategoryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateElementSubcategoryUseCase createElementSubcategoryUseCase(
    Ref ref) {
  return CreateElementSubcategoryUseCase(
    ref.watch(createElementCategoryUseCaseProvider),
  );
}

@riverpod
RenameElementCategoryUseCase renameElementCategoryUseCase(
    Ref ref) {
  return RenameElementCategoryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetElementGroupUseCase createTilesetElementGroupUseCase(
    Ref ref) {
  return CreateTilesetElementGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetElementSubgroupUseCase createTilesetElementSubgroupUseCase(
    Ref ref) {
  return CreateTilesetElementSubgroupUseCase(
    ref.watch(createTilesetElementGroupUseCaseProvider),
  );
}

@riverpod
RenameTilesetElementGroupUseCase renameTilesetElementGroupUseCase(
    Ref ref) {
  return RenameTilesetElementGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateProjectElementUseCase createProjectElementUseCase(
    Ref ref) {
  return CreateProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectElementUseCase updateProjectElementUseCase(
    Ref ref) {
  return UpdateProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectElementUseCase deleteProjectElementUseCase(
    Ref ref) {
  return DeleteProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTerrainPresetUseCase createTerrainPresetUseCase(
    Ref ref) {
  return CreateTerrainPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTerrainPresetUseCase updateTerrainPresetUseCase(
    Ref ref) {
  return UpdateTerrainPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTerrainPresetUseCase deleteTerrainPresetUseCase(
    Ref ref) {
  return DeleteTerrainPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreatePathPresetUseCase createPathPresetUseCase(
    Ref ref) {
  return CreatePathPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdatePathPresetUseCase updatePathPresetUseCase(
    Ref ref) {
  return UpdatePathPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeletePathPresetUseCase deletePathPresetUseCase(
    Ref ref) {
  return DeletePathPresetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreatePresetCategoryUseCase createPresetCategoryUseCase(
    Ref ref) {
  return CreatePresetCategoryUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
RenamePresetCategoryUseCase renamePresetCategoryUseCase(
    Ref ref) {
  return RenamePresetCategoryUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeletePresetCategoryUseCase deletePresetCategoryUseCase(
    Ref ref) {
  return DeletePresetCategoryUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
ResolveVisibleProjectElementsUseCase resolveVisibleProjectElementsUseCase(
    Ref ref) {
  return ResolveVisibleProjectElementsUseCase();
}

@riverpod
ResolveTilesetElementsUseCase resolveTilesetElementsUseCase(
    Ref ref) {
  return ResolveTilesetElementsUseCase();
}

@riverpod
UpsertTilesetPaletteEntryUseCase upsertTilesetPaletteEntryUseCase(
    Ref ref) {
  return UpsertTilesetPaletteEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetPaletteEntryUseCase createTilesetPaletteEntryUseCase(
    Ref ref) {
  return CreateTilesetPaletteEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateGroupUseCase createGroupUseCase(Ref ref) {
  return CreateGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteGroupUseCase deleteGroupUseCase(Ref ref) {
  return DeleteGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
MoveMapToGroupUseCase moveMapToGroupUseCase(Ref ref) {
  return MoveMapToGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
RenameGroupUseCase renameGroupUseCase(Ref ref) {
  return RenameGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateEncounterTableUseCase createEncounterTableUseCase(
    Ref ref) {
  return CreateEncounterTableUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateEncounterTableUseCase updateEncounterTableUseCase(
    Ref ref) {
  return UpdateEncounterTableUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteEncounterTableUseCase deleteEncounterTableUseCase(
    Ref ref) {
  return DeleteEncounterTableUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
AddEncounterEntryUseCase addEncounterEntryUseCase(
    Ref ref) {
  return AddEncounterEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateEncounterEntryUseCase updateEncounterEntryUseCase(
    Ref ref) {
  return UpdateEncounterEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteEncounterEntryUseCase deleteEncounterEntryUseCase(
    Ref ref) {
  return DeleteEncounterEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTrainerUseCase createTrainerUseCase(Ref ref) {
  return CreateTrainerUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTrainerUseCase updateTrainerUseCase(Ref ref) {
  return UpdateTrainerUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTrainerUseCase deleteTrainerUseCase(Ref ref) {
  return DeleteTrainerUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
AddTrainerPokemonUseCase addTrainerPokemonUseCase(
    Ref ref) {
  return AddTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTrainerPokemonUseCase updateTrainerPokemonUseCase(
    Ref ref) {
  return UpdateTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTrainerPokemonUseCase deleteTrainerPokemonUseCase(
    Ref ref) {
  return DeleteTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateCharacterUseCase createCharacterUseCase(Ref ref) {
  return CreateCharacterUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateCharacterUseCase updateCharacterUseCase(Ref ref) {
  return UpdateCharacterUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteCharacterUseCase deleteCharacterUseCase(Ref ref) {
  return DeleteCharacterUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpsertCharacterAnimationUseCase upsertCharacterAnimationUseCase(
    Ref ref) {
  return UpsertCharacterAnimationUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
SetPlayerCharacterUseCase setPlayerCharacterUseCase(
    Ref ref) {
  return SetPlayerCharacterUseCase(ref.watch(projectRepositoryProvider));
}
