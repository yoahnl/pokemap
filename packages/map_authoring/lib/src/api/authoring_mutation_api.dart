import 'package:map_core/map_core.dart' show MapEditorState;

import '../documents/map_editor_authoring.dart';
import '../documents/map_element_order_authoring.dart';
import '../contracts/authoring_request.dart';
import '../transactions/recovery_service.dart';
import '../workspace/workspace_handle_store.dart';
import 'authoring_mutation_contracts.dart';

/// Mutation port consumed by protocol adapters alongside the read API.
abstract interface class AuthoringMutationApiPort {
  Map<String, Object?> describeMutations();

  Future<void> attachProject({
    required String projectRootPath,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
  });

  Future<bool> detachWorkspace(WorkspaceHandle workspaceHandle);

  Future<Map<String, Object?>> plan(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  );

  Future<Map<String, Object?>> confirm(
    ProjectHandle projectHandle, {
    required String planId,
  });

  Future<Map<String, Object?>> apply(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  });

  Future<Map<String, Object?>> undo(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> history(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  });

  Future<Map<String, Object?>> recover(
    ProjectHandle projectHandle, {
    required String operationId,
  });
}

/// Optional local-file staging capability used by protocol adapters.
abstract interface class AuthoringWorkshopPort {
  Future<Map<String, Object?>> readWorkshopDocument(ProjectHandle projectHandle,
      {required String actionId,
      Map<String, Object?> parameters = const {},
      Map<String, String> readDependencies = const {}});
  Future<Map<String, Object?>> prepareWorkshopDocument(
      ProjectHandle projectHandle);
}

abstract interface class AuthoringArtifactStagingPort {
  Future<Map<String, Object?>> stageArtifact({
    required String sourcePath,
    String? declaredMediaType,
  });
}

abstract interface class AuthoringRecoveryStatusPort {
  Future<Map<String, Object?>> recoveryStatus(
    ProjectHandle projectHandle, {
    required String operationId,
  });
}

abstract interface class AuthoringIncompletePreparationDiscardPort {
  Future<AuthoringIncompletePreparationDiscardResult>
      discardIncompletePreparation(
    ProjectHandle projectHandle, {
    required String operationId,
  });
}

/// Typed application boundary for direct Dart mutation consumers.
abstract interface class AuthoringMutationServicePort {
  AuthoringMutationDescription describeMutationContracts();

  Future<void> attachProject({
    required String projectRootPath,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
  });

  Future<bool> detachWorkspace(WorkspaceHandle workspaceHandle);

  Future<AuthoringMutationPlanResult> planMutation(
    ProjectHandle projectHandle,
    AuthoringRequest request,
  );

  Future<AuthoringMutationConfirmationResult> confirmMutation(
    ProjectHandle projectHandle, {
    required String planId,
  });

  Future<AuthoringMutationResult> applyMutation(
    ProjectHandle projectHandle, {
    required String planId,
    required String operationId,
    String? confirmationToken,
  });

  Future<AuthoringMutationResult> undoMutation(
    ProjectHandle projectHandle, {
    required String entryId,
    required String idempotencyKey,
  });

  Future<AuthoringMutationHistoryResult> listMutationHistory(
    ProjectHandle projectHandle, {
    required int limit,
    String? cursor,
  });

  Future<AuthoringMutationResult> recoverMutation(
    ProjectHandle projectHandle, {
    required String operationId,
  });
}

abstract interface class AuthoringArtifactStagingServicePort {
  Future<AuthoringArtifactStageResult> stageArtifactFile({
    required String sourcePath,
    String? declaredMediaType,
  });
}

abstract interface class AuthoringMapEditorStatePort {
  Future<MapEditorSnapshot> inspectMapEditor({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
  });

  Future<MapEditorMutation> setMapEditor({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required MapEditorState state,
    required String operationId,
  });

  Future<MapEditorMutation> undoMapEditor({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String receiptId,
    required String expectedRevision,
    required String operationId,
  });
}

abstract interface class AuthoringMapElementOrderPort {
  Future<MapElementOrderSnapshot> inspectMapElementOrder({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
  });

  Future<MapElementOrderMutation> reorderMapElements({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required String kind,
    required List<String> frontFirstIds,
    String? layerId,
    required String operationId,
  });

  Future<MapElementOrderMutation> undoMapElementOrder({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String receiptId,
    required String expectedRevision,
    required String operationId,
  });
}
