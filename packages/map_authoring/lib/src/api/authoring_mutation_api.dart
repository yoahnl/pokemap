import '../contracts/authoring_request.dart';
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
abstract interface class AuthoringArtifactStagingPort {
  Future<Map<String, Object?>> stageArtifact({
    required String sourcePath,
    String? declaredMediaType,
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
