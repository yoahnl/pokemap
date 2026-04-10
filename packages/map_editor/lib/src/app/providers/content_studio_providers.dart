import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/project_scenario_use_cases.dart';
import '../../features/editor/application/project_content_controller.dart';
import 'core_providers.dart';
import 'use_case_providers.dart';

/// Wiring thématique des workflows "contenu projet".
///
/// On garde ce fichier volontairement petit :
/// - pas de nouvelle couche magique ;
/// - pas de provider global fourre-tout ;
/// - juste l'assemblage des dépendances nécessaires aux sous-systèmes
///   dialogue + cutscene déjà existants.
final projectContentControllerProvider = Provider<ProjectContentController>(
  (ref) {
    final projectRepository = ref.watch(projectRepositoryProvider);
    return ProjectContentController(
      createProjectDialogueUseCase:
          ref.watch(createProjectDialogueUseCaseProvider),
      importProjectDialogueUseCase:
          ref.watch(importProjectDialogueUseCaseProvider),
      updateProjectDialogueUseCase:
          ref.watch(updateProjectDialogueUseCaseProvider),
      deleteProjectDialogueUseCase:
          ref.watch(deleteProjectDialogueUseCaseProvider),
      createDialogueLibraryFolderUseCase:
          ref.watch(createDialogueLibraryFolderUseCaseProvider),
      renameDialogueLibraryFolderUseCase:
          ref.watch(renameDialogueLibraryFolderUseCaseProvider),
      moveDialogueLibraryFolderUseCase:
          ref.watch(moveDialogueLibraryFolderUseCaseProvider),
      deleteDialogueLibraryFolderUseCase:
          ref.watch(deleteDialogueLibraryFolderUseCaseProvider),
      assignDialogueToLibraryFolderUseCase:
          ref.watch(assignDialogueToLibraryFolderUseCaseProvider),
      moveDialogueToLibraryRootUseCase:
          ref.watch(moveDialogueToLibraryRootUseCaseProvider),
      saveDialogueYarnBodyUseCase:
          ref.watch(saveDialogueYarnBodyUseCaseProvider),
      createProjectScenarioUseCase:
          CreateProjectScenarioUseCase(projectRepository),
      updateProjectScenarioUseCase:
          UpdateProjectScenarioUseCase(projectRepository),
      deleteProjectScenarioUseCase:
          DeleteProjectScenarioUseCase(projectRepository),
    );
  },
);
