import '../contracts/authoring_request.dart';
import '../workspace/workspace_handle_store.dart';

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

  Future<Map<String, Object?>> recover(
    ProjectHandle projectHandle, {
    required String operationId,
  });
}
