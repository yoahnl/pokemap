import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/authoring_api/encounter_table_persistence_gateway.dart';
import '../../../application/authoring_api/character_studio_authoring_gateway.dart';
import '../../../application/use_cases/character_use_cases.dart';
import '../../../application/use_cases/encounter_table_use_cases.dart';
import '../../../application/use_cases/project_element_use_cases.dart';
import '../../../application/use_cases/project_group_use_cases.dart';
import '../../../application/use_cases/project_management_use_cases.dart';
import '../../../application/use_cases/project_tileset_library_use_cases.dart';
import '../../../application/use_cases/project_tileset_use_cases.dart';
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
UpdateProjectSettingsUseCase updateProjectSettingsUseCase(Ref ref) {
  return UpdateProjectSettingsUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ImportProjectTilesetUseCase importProjectTilesetUseCase(Ref ref) {
  return ImportProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectTilesetUseCase updateProjectTilesetUseCase(Ref ref) {
  return UpdateProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ResolveAssignableTilesetsForMapUseCase resolveAssignableTilesetsForMapUseCase(
  Ref ref,
) {
  return ResolveAssignableTilesetsForMapUseCase();
}

@riverpod
DeleteProjectTilesetUseCase deleteProjectTilesetUseCase(Ref ref) {
  return DeleteProjectTilesetUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(mapRepositoryProvider),
  );
}

@riverpod
ReorderProjectTilesetUseCase reorderProjectTilesetUseCase(Ref ref) {
  return ReorderProjectTilesetUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetLibraryFolderUseCase createTilesetLibraryFolderUseCase(Ref ref) {
  return CreateTilesetLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
RenameTilesetLibraryFolderUseCase renameTilesetLibraryFolderUseCase(Ref ref) {
  return RenameTilesetLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
MoveTilesetLibraryFolderUseCase moveTilesetLibraryFolderUseCase(Ref ref) {
  return MoveTilesetLibraryFolderUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTilesetLibraryFolderUseCase deleteTilesetLibraryFolderUseCase(Ref ref) {
  return DeleteTilesetLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
AssignTilesetToLibraryFolderUseCase assignTilesetToLibraryFolderUseCase(
  Ref ref,
) {
  return AssignTilesetToLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
MoveTilesetToLibraryRootUseCase moveTilesetToLibraryRootUseCase(Ref ref) {
  return MoveTilesetToLibraryRootUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateElementCategoryUseCase createElementCategoryUseCase(Ref ref) {
  return CreateElementCategoryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateElementSubcategoryUseCase createElementSubcategoryUseCase(Ref ref) {
  return CreateElementSubcategoryUseCase(
    ref.watch(createElementCategoryUseCaseProvider),
  );
}

@riverpod
RenameElementCategoryUseCase renameElementCategoryUseCase(Ref ref) {
  return RenameElementCategoryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetElementGroupUseCase createTilesetElementGroupUseCase(Ref ref) {
  return CreateTilesetElementGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetElementSubgroupUseCase createTilesetElementSubgroupUseCase(
  Ref ref,
) {
  return CreateTilesetElementSubgroupUseCase(
    ref.watch(createTilesetElementGroupUseCaseProvider),
  );
}

@riverpod
RenameTilesetElementGroupUseCase renameTilesetElementGroupUseCase(Ref ref) {
  return RenameTilesetElementGroupUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateProjectElementUseCase createProjectElementUseCase(Ref ref) {
  return CreateProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectElementUseCase updateProjectElementUseCase(Ref ref) {
  return UpdateProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectElementUseCase deleteProjectElementUseCase(Ref ref) {
  return DeleteProjectElementUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ResolveVisibleProjectElementsUseCase resolveVisibleProjectElementsUseCase(
  Ref ref,
) {
  return ResolveVisibleProjectElementsUseCase();
}

@riverpod
ResolveTilesetElementsUseCase resolveTilesetElementsUseCase(Ref ref) {
  return ResolveTilesetElementsUseCase();
}

@riverpod
UpsertTilesetPaletteEntryUseCase upsertTilesetPaletteEntryUseCase(Ref ref) {
  return UpsertTilesetPaletteEntryUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateTilesetPaletteEntryUseCase createTilesetPaletteEntryUseCase(Ref ref) {
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

final encounterTablePersistenceGatewayProvider =
    Provider<EncounterTablePersistenceGateway>((ref) {
      return CanonicalEncounterTablePersistenceGateway(
        mutations: ref.watch(authoringMutationAdapterProvider),
        queries: ref.watch(authoringQueryAdapterProvider),
      );
    });

final characterStudioAuthoringGatewayProvider =
    Provider<CharacterStudioAuthoringGateway>((ref) {
      return CanonicalCharacterStudioAuthoringGateway(
        mutations: ref.watch(authoringMutationAdapterProvider),
        queries: ref.watch(authoringQueryAdapterProvider),
      );
    });

@riverpod
CreateEncounterTableUseCase createEncounterTableUseCase(Ref ref) {
  return CreateEncounterTableUseCase(
    ref.watch(encounterTablePersistenceGatewayProvider),
  );
}

@riverpod
UpdateEncounterTableUseCase updateEncounterTableUseCase(Ref ref) {
  return UpdateEncounterTableUseCase(
    ref.watch(encounterTablePersistenceGatewayProvider),
  );
}

@riverpod
DeleteEncounterTableUseCase deleteEncounterTableUseCase(Ref ref) {
  return DeleteEncounterTableUseCase(
    ref.watch(encounterTablePersistenceGatewayProvider),
  );
}

@riverpod
AddEncounterEntryUseCase addEncounterEntryUseCase(Ref ref) {
  return AddEncounterEntryUseCase(
    ref.watch(encounterTablePersistenceGatewayProvider),
  );
}

@riverpod
UpdateEncounterEntryUseCase updateEncounterEntryUseCase(Ref ref) {
  return UpdateEncounterEntryUseCase(
    ref.watch(encounterTablePersistenceGatewayProvider),
  );
}

@riverpod
DeleteEncounterEntryUseCase deleteEncounterEntryUseCase(Ref ref) {
  return DeleteEncounterEntryUseCase(
    ref.watch(encounterTablePersistenceGatewayProvider),
  );
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
AddTrainerPokemonUseCase addTrainerPokemonUseCase(Ref ref) {
  return AddTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateTrainerPokemonUseCase updateTrainerPokemonUseCase(Ref ref) {
  return UpdateTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteTrainerPokemonUseCase deleteTrainerPokemonUseCase(Ref ref) {
  return DeleteTrainerPokemonUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
CreateCharacterUseCase createCharacterUseCase(Ref ref) {
  return CreateCharacterUseCase(
    ref.watch(characterStudioAuthoringGatewayProvider),
  );
}

@riverpod
UpdateCharacterUseCase updateCharacterUseCase(Ref ref) {
  return UpdateCharacterUseCase(
    ref.watch(characterStudioAuthoringGatewayProvider),
  );
}

@riverpod
DeleteCharacterUseCase deleteCharacterUseCase(Ref ref) {
  return DeleteCharacterUseCase(
    ref.watch(characterStudioAuthoringGatewayProvider),
  );
}

@riverpod
UpsertCharacterAnimationUseCase upsertCharacterAnimationUseCase(Ref ref) {
  return UpsertCharacterAnimationUseCase(
    ref.watch(characterStudioAuthoringGatewayProvider),
  );
}

@riverpod
SetPlayerCharacterUseCase setPlayerCharacterUseCase(Ref ref) {
  return SetPlayerCharacterUseCase(
    ref.watch(characterStudioAuthoringGatewayProvider),
  );
}
