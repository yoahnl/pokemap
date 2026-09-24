import 'dart:math';

import 'package:map_authoring/map_authoring.dart'
    show PokemonMediaImportEntry, PokemonMediaImportRole;
import 'package:map_authoring/map_authoring_local.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_workspace_models.dart';

final class PokemonMenuMediaImport {
  const PokemonMenuMediaImport({
    required this.session,
    required this.mapAdapter,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  Future<String> run({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  }) => mapAdapter.withResourceMutation(
    () => _run(
      sourcePath: sourcePath,
      speciesId: speciesId,
      formId: formId,
      role: role,
    ),
  );

  Future<String> _run({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  }) async {
    final selectedRole = PokemonMediaImportRole.values
        .where((entry) => entry.name == role)
        .firstOrNull;
    if (selectedRole == null) {
      throw const PokemonWorkspaceFailure('Rôle média non pris en charge.');
    }
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: const LocalProjectFileReader(),
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: const LocalProjectFileReader(),
      handles: handles,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [session.directoryPath],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    );
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      await artifacts.authorizeSourceFile(sourcePath);
      final staged = await api.stageArtifactFile(
        sourcePath: sourcePath,
        declaredMediaType: 'image/png',
      );
      final snapshot = await snapshots.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      final operation =
          'pokemon_media_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final entry = PokemonMediaImportEntry(
        speciesId: speciesId,
        formId: formId,
        role: selectedRole,
        artifactHandle: staged.reference.handle,
      );
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'pokemon.media.import',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: {
            'entries': [entry.toJson()],
            'conflictPolicy': 'preserve',
          },
        ),
      );
      final preview = planned.plan.preview;
      if (planned.plan.changeSet.changes.isEmpty) {
        return (preview['preserved'] as List?)?.isNotEmpty == true
            ? 'Le média déjà choisi est conservé. Aucun remplacement effectué.'
            : 'Aucune association créée. Vérifiez les conflits du catalogue.';
      }
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: operation,
        );
      } on Object catch (failure) {
        try {
          await api.recoverMutation(
            opened.projectHandle,
            operationId: operation,
          );
        } on Object {
          throw PokemonWorkspaceFailure(
            'Import interrompu ; journal $operation conservé : $failure',
          );
        }
        rethrow;
      }
      return 'PNG associé à la forme $formId pour le rôle $role.';
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}
