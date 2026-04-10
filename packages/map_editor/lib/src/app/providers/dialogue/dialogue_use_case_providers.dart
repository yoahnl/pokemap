import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/use_cases/project_dialogue_library_use_cases.dart';
import '../../../application/use_cases/project_dialogue_use_cases.dart';
import '../core/repository_providers.dart';

part 'dialogue_use_case_providers.g.dart';

/// Providers dédiés aux workflows de dialogues projet.
///
/// Ils restent isolés du reste de l'édition map pour que la composition root
/// rende les dépendances "contenu narratif" immédiatement visibles.
@riverpod
CreateProjectDialogueUseCase createProjectDialogueUseCase(
    Ref ref) {
  return CreateProjectDialogueUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
ImportProjectDialogueUseCase importProjectDialogueUseCase(
    Ref ref) {
  return ImportProjectDialogueUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
UpdateProjectDialogueUseCase updateProjectDialogueUseCase(
    Ref ref) {
  return UpdateProjectDialogueUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
DeleteProjectDialogueUseCase deleteProjectDialogueUseCase(
    Ref ref) {
  return DeleteProjectDialogueUseCase(
    ref.watch(projectRepositoryProvider),
    ref.watch(mapRepositoryProvider),
  );
}

@riverpod
CreateDialogueLibraryFolderUseCase createDialogueLibraryFolderUseCase(
    Ref ref) {
  return CreateDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
RenameDialogueLibraryFolderUseCase renameDialogueLibraryFolderUseCase(
    Ref ref) {
  return RenameDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
MoveDialogueLibraryFolderUseCase moveDialogueLibraryFolderUseCase(
    Ref ref) {
  return MoveDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeleteDialogueLibraryFolderUseCase deleteDialogueLibraryFolderUseCase(
    Ref ref) {
  return DeleteDialogueLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
AssignDialogueToLibraryFolderUseCase assignDialogueToLibraryFolderUseCase(
    Ref ref) {
  return AssignDialogueToLibraryFolderUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
MoveDialogueToLibraryRootUseCase moveDialogueToLibraryRootUseCase(
    Ref ref) {
  return MoveDialogueToLibraryRootUseCase(
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
SaveDialogueYarnBodyUseCase saveDialogueYarnBodyUseCase(
    Ref ref) {
  return SaveDialogueYarnBodyUseCase();
}
