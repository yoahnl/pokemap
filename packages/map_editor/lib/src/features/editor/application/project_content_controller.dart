import 'package:map_core/map_core.dart';

import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/project_dialogue_library_use_cases.dart';
import '../../../application/use_cases/project_dialogue_use_cases.dart';
import '../../../application/use_cases/project_scenario_use_cases.dart';
import '../state/editor_state.dart';

/// Contrôleur applicatif des sous-systèmes "contenu projet".
///
/// Périmètre volontairement limité :
/// - dialogues de bibliothèque + structure de dossiers ;
/// - scénarios/cutscenes du studio narratif ;
/// - persistance du corps `.yarn`.
///
/// Cette classe existe pour sortir de `EditorNotifier` une orchestration
/// secondaire qui n'appartient ni au coeur map, ni au coeur sélection/outils.
/// Le notifier reste façade UI ; ce contrôleur porte la mutation applicative
/// et la reconstruction cohérente de `EditorState`.
class ProjectContentController {
  const ProjectContentController({
    required CreateProjectDialogueUseCase createProjectDialogueUseCase,
    required ImportProjectDialogueUseCase importProjectDialogueUseCase,
    required UpdateProjectDialogueUseCase updateProjectDialogueUseCase,
    required DeleteProjectDialogueUseCase deleteProjectDialogueUseCase,
    required CreateDialogueLibraryFolderUseCase
        createDialogueLibraryFolderUseCase,
    required RenameDialogueLibraryFolderUseCase
        renameDialogueLibraryFolderUseCase,
    required MoveDialogueLibraryFolderUseCase
        moveDialogueLibraryFolderUseCase,
    required DeleteDialogueLibraryFolderUseCase
        deleteDialogueLibraryFolderUseCase,
    required AssignDialogueToLibraryFolderUseCase
        assignDialogueToLibraryFolderUseCase,
    required MoveDialogueToLibraryRootUseCase
        moveDialogueToLibraryRootUseCase,
    required SaveDialogueYarnBodyUseCase saveDialogueYarnBodyUseCase,
    required CreateProjectScenarioUseCase createProjectScenarioUseCase,
    required UpdateProjectScenarioUseCase updateProjectScenarioUseCase,
    required DeleteProjectScenarioUseCase deleteProjectScenarioUseCase,
  })  : _createProjectDialogueUseCase = createProjectDialogueUseCase,
        _importProjectDialogueUseCase = importProjectDialogueUseCase,
        _updateProjectDialogueUseCase = updateProjectDialogueUseCase,
        _deleteProjectDialogueUseCase = deleteProjectDialogueUseCase,
        _createDialogueLibraryFolderUseCase =
            createDialogueLibraryFolderUseCase,
        _renameDialogueLibraryFolderUseCase =
            renameDialogueLibraryFolderUseCase,
        _moveDialogueLibraryFolderUseCase = moveDialogueLibraryFolderUseCase,
        _deleteDialogueLibraryFolderUseCase =
            deleteDialogueLibraryFolderUseCase,
        _assignDialogueToLibraryFolderUseCase =
            assignDialogueToLibraryFolderUseCase,
        _moveDialogueToLibraryRootUseCase = moveDialogueToLibraryRootUseCase,
        _saveDialogueYarnBodyUseCase = saveDialogueYarnBodyUseCase,
        _createProjectScenarioUseCase = createProjectScenarioUseCase,
        _updateProjectScenarioUseCase = updateProjectScenarioUseCase,
        _deleteProjectScenarioUseCase = deleteProjectScenarioUseCase;

  final CreateProjectDialogueUseCase _createProjectDialogueUseCase;
  final ImportProjectDialogueUseCase _importProjectDialogueUseCase;
  final UpdateProjectDialogueUseCase _updateProjectDialogueUseCase;
  final DeleteProjectDialogueUseCase _deleteProjectDialogueUseCase;
  final CreateDialogueLibraryFolderUseCase _createDialogueLibraryFolderUseCase;
  final RenameDialogueLibraryFolderUseCase _renameDialogueLibraryFolderUseCase;
  final MoveDialogueLibraryFolderUseCase _moveDialogueLibraryFolderUseCase;
  final DeleteDialogueLibraryFolderUseCase _deleteDialogueLibraryFolderUseCase;
  final AssignDialogueToLibraryFolderUseCase
      _assignDialogueToLibraryFolderUseCase;
  final MoveDialogueToLibraryRootUseCase _moveDialogueToLibraryRootUseCase;
  final SaveDialogueYarnBodyUseCase _saveDialogueYarnBodyUseCase;
  final CreateProjectScenarioUseCase _createProjectScenarioUseCase;
  final UpdateProjectScenarioUseCase _updateProjectScenarioUseCase;
  final DeleteProjectScenarioUseCase _deleteProjectScenarioUseCase;

  /// Sélection UI pure : aucune lecture/écriture, aucune mutation projet.
  EditorState selectProjectDialogue(EditorState current, String? dialogueId) {
    return current.copyWithSelection(
      current.selection.copyWith(selectedProjectDialogueId: dialogueId),
    );
  }

  Future<EditorState> saveProjectDialogueYarnBody({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String dialogueId,
    required String yarnBody,
  }) async {
    final project = current.projectSession.project;
    if (workspace == null || project == null) {
      return current;
    }

    try {
      await _saveDialogueYarnBodyUseCase.execute(
        workspace,
        project,
        dialogueId: dialogueId,
        yarnBody: yarnBody,
      );
      return current.copyWithDocumentStatus(
        current.documentStatus.copyWith(
          statusMessage: 'Dialogue .yarn enregistré sur disque',
          errorMessage: null,
        ),
      );
    } catch (e) {
      return current.copyWithDocumentStatus(
        current.documentStatus.copyWith(
          errorMessage: 'Échec enregistrement dialogue: $e',
        ),
      );
    }
  }

  Future<EditorState> createProjectDialogue({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String name,
    String? folderId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _createProjectDialogueUseCase.execute(
        ws,
        project,
        name: name,
        folderId: folderId,
      ),
      statusMessage: 'Dialogue created',
      errorPrefix: 'Failed to create dialogue',
      updateSelection: (selection, updated) {
        return selection.copyWith(
          selectedProjectDialogueId:
              updated.dialogues.isNotEmpty ? updated.dialogues.last.id : null,
        );
      },
    );
  }

  Future<EditorState> importProjectDialogue({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _importProjectDialogueUseCase.execute(
        ws,
        project,
        absoluteSourcePath: absoluteSourcePath,
        displayName: displayName,
        folderId: folderId,
      ),
      statusMessage: 'Dialogue imported',
      errorPrefix: 'Failed to import dialogue',
      updateSelection: (selection, updated) {
        return selection.copyWith(
          selectedProjectDialogueId:
              updated.dialogues.isNotEmpty ? updated.dialogues.last.id : null,
        );
      },
    );
  }

  Future<EditorState> renameProjectDialogue({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String dialogueId,
    required String newName,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _updateProjectDialogueUseCase.execute(
        ws,
        project,
        dialogueId: dialogueId,
        name: newName,
      ),
      statusMessage: 'Dialogue renamed',
      errorPrefix: 'Failed to rename dialogue',
    );
  }

  Future<EditorState> deleteProjectDialogue({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String dialogueId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _deleteProjectDialogueUseCase.execute(
        ws,
        project,
        dialogueId: dialogueId,
        alsoScanUnsavedMap: current.projectSession.activeMap,
      ),
      statusMessage: 'Dialogue deleted',
      errorPrefix: 'Failed to delete dialogue',
      updateSelection: (selection, _) {
        return selection.copyWith(
          selectedProjectDialogueId:
              selection.selectedProjectDialogueId == dialogueId
                  ? null
                  : selection.selectedProjectDialogueId,
        );
      },
    );
  }

  Future<EditorState> createDialogueLibraryFolder({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String name,
    String? parentFolderId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _createDialogueLibraryFolderUseCase.execute(
        ws,
        project,
        name: name,
        parentFolderId: parentFolderId,
      ),
      statusMessage: 'Script folder created',
      errorPrefix: 'Failed to create script folder',
    );
  }

  Future<EditorState> renameDialogueLibraryFolder({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String folderId,
    required String name,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _renameDialogueLibraryFolderUseCase.execute(
        ws,
        project,
        folderId: folderId,
        name: name,
      ),
      statusMessage: 'Script folder renamed',
      errorPrefix: 'Failed to rename script folder',
    );
  }

  Future<EditorState> moveDialogueLibraryFolder({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String folderId,
    String? newParentFolderId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _moveDialogueLibraryFolderUseCase.execute(
        ws,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      ),
      statusMessage: 'Script folder moved',
      errorPrefix: 'Failed to move script folder',
    );
  }

  Future<EditorState> deleteDialogueLibraryFolder({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String folderId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _deleteDialogueLibraryFolderUseCase.execute(
        ws,
        project,
        folderId: folderId,
      ),
      statusMessage: 'Script folder deleted',
      errorPrefix: 'Failed to delete script folder',
    );
  }

  Future<EditorState> assignDialogueToLibraryFolder({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String dialogueId,
    required String folderId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _assignDialogueToLibraryFolderUseCase.execute(
        ws,
        project,
        dialogueId: dialogueId,
        folderId: folderId,
      ),
      statusMessage: 'Script moved to folder',
      errorPrefix: 'Failed to move script to folder',
    );
  }

  Future<EditorState> moveDialogueToLibraryRoot({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String dialogueId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _moveDialogueToLibraryRootUseCase.execute(
        ws,
        project,
        dialogueId: dialogueId,
      ),
      statusMessage: 'Script moved to library root',
      errorPrefix: 'Failed to move script to root',
    );
  }

  Future<EditorState> createProjectScenario({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required ScenarioAsset scenario,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _createProjectScenarioUseCase.execute(
        ws,
        project,
        scenario: scenario,
      ),
      statusMessage: 'Cutscene "${scenario.name}" created',
      errorPrefix: 'Failed to create cutscene',
    );
  }

  Future<EditorState> updateProjectScenario({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _updateProjectScenarioUseCase.execute(
        ws,
        project,
        scenarioId: scenarioId,
        nextScenario: scenario,
      ),
      statusMessage: 'Cutscene "${scenario.name}" saved',
      errorPrefix: 'Failed to save cutscene',
    );
  }

  Future<EditorState> deleteProjectScenario({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required String scenarioId,
  }) async {
    return _runProjectMutation(
      current: current,
      workspace: workspace,
      mutate: (ws, project) => _deleteProjectScenarioUseCase.execute(
        ws,
        project,
        scenarioId: scenarioId,
      ),
      statusMessage: 'Cutscene "$scenarioId" deleted',
      errorPrefix: 'Failed to delete cutscene',
    );
  }

  Future<EditorState> _runProjectMutation({
    required EditorState current,
    required ProjectWorkspace? workspace,
    required Future<ProjectManifest> Function(
      ProjectWorkspace workspace,
      ProjectManifest project,
    ) mutate,
    required String statusMessage,
    required String errorPrefix,
    EditorSelectionState Function(
      EditorSelectionState selection,
      ProjectManifest updatedProject,
    )? updateSelection,
  }) async {
    final project = current.projectSession.project;
    if (workspace == null || project == null) {
      return current;
    }

    try {
      final updatedProject = await mutate(workspace, project);
      var next = current
          .copyWithProjectSession(
            current.projectSession.copyWith(project: updatedProject),
          )
          .copyWithDocumentStatus(
            current.documentStatus.copyWith(
              statusMessage: statusMessage,
              errorMessage: null,
            ),
          );
      if (updateSelection != null) {
        next = next.copyWithSelection(
          updateSelection(next.selection, updatedProject),
        );
      }
      return next;
    } catch (e) {
      return current.copyWithDocumentStatus(
        current.documentStatus.copyWith(
          errorMessage: '$errorPrefix: $e',
        ),
      );
    }
  }
}
