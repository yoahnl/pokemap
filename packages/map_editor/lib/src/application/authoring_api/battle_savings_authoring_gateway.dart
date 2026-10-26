import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

final class BattleSavingsAuthoringGateway {
  BattleSavingsAuthoringGateway({ProjectFileReader? fileReader})
    : _fileReader = fileReader ?? const LocalProjectFileReader();

  final ProjectFileReader _fileReader;

  Future<ProjectManifest> save(
    String projectRoot, {
    required ProjectManifest project,
    required ProjectBattleSavingsConfig? configuration,
  }) async {
    configuration?.validate(project.facts);
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [projectRoot],
      fileReader: _fileReader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: _fileReader,
      handles: handles,
      workshopScope: true,
      catalogMetadataFields: {},
    ).openProject(projectRoot);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    try {
      await api.attachProject(
        projectRootPath: projectRoot,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      const action = 'campaign.battle_savings.update';
      final parameters = <String, Object?>{
        'battleSavings': configuration?.toJson(),
      };
      final before = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: action,
        parameters: parameters,
      );
      if (before.manifest.battleSavings != project.battleSavings ||
          before.manifest.facts.any((fact) => !project.facts.contains(fact))) {
        throw StateError(
          'La configuration ou ses indicateurs ont changé. Rechargez le projet avant de continuer.',
        );
      }
      final operation =
          'editor_battle_savings_${DateTime.now().microsecondsSinceEpoch}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: before.revision,
          idempotencyKey: operation,
          parameters: parameters,
          extensions: const {'workshopScope': true},
        ),
      );
      await api.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: operation,
      );
      return project.copyWith(battleSavings: configuration);
    } finally {
      await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}
